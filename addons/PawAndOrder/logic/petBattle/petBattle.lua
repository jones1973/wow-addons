--[[
  logic/petBattle/petBattle.lua
  Wild Pet Battle Management
  
  Handles two complementary features for wild pet battles:
  1. Raid Icon Marking: Automatically marks wild pets with configurable raid icons
  2. Macro Creation: Creates/updates a targeting macro after battle withdrawal
  
  Marking Modes:
  - Fixed: Always use the same raid icon (user-selected in settings)
  - Random: Shuffle icons 1-8 once at mode start, then cycle sequentially through shuffled order
  - Sequential: Cycle through icons 1→2→3→4→5→6→7→8→1 without randomization
  
  Design Notes:
  - Marking occurs on PLAYER_TARGET_CHANGED (before battle starts) to avoid target invalidation
  - Generic "already marked" check prevents remarking regardless of which icon is present
  - Icon state resets immediately on mode changes via callback (no reload needed)
  - Macro creation uses 0.5s delay to allow UI state to stabilize after battle end
  
  Dependencies: utils, options, events
  Exports: Addon.petBattle
]]

local ADDON_NAME, Addon = ...
if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in petBattle.lua.|r")
    return {}
end

local utils = Addon.utils
local petBattle = {}

-- Raid target icon indices (Blizzard API uses 1-8 directly, no constants provided)
local RAID_ICON_STAR = 1
local RAID_ICON_CIRCLE = 2
local RAID_ICON_DIAMOND = 3
local RAID_ICON_TRIANGLE = 4
local RAID_ICON_MOON = 5
local RAID_ICON_SQUARE = 6
local RAID_ICON_CROSS = 7
local RAID_ICON_SKULL = 8

-- Macro creation constants
local MACRO_CREATE_DELAY = 0.5  -- Delay after battle end to allow UI state to stabilize
local MACRO_NAME = "PAO_Target_Pet"
local MACRO_ICON = "INV_Box_PetCarrier_01"
local MAX_ACCOUNT_MACROS = 120

-- State tracking for macro creation
local wildBattleTarget = {
    name   = nil,
    isWild = false,
}
local battleEndProcessed = false

-- Icon state for random/sequential marking modes
local iconState = {
    currentIndex = 1,
    iconOrder = nil,  -- Lazy-initialized for random mode
    lastMode = nil    -- Track mode changes to reset state
}

--[[
  Get next raid icon index based on current marking mode
  
  Handles fixed, random, and sequential icon selection with state management.
  Random mode shuffles order once at mode start, then cycles through that order.
  State resets automatically when mode changes.
  
  @return number|nil - Icon index (1-8) to apply, or nil if marking disabled
]]
local function getNextIcon()
    if not Addon.options or not Addon.options:Get("wildPetMarkEnabled") then
        return nil
    end
    
    local mode = Addon.options:Get("wildPetMarkMode") or "fixed"
    
    -- Reset state if mode changed
    if iconState.lastMode ~= mode then
        iconState.currentIndex = 1
        iconState.iconOrder = nil
        iconState.lastMode = mode
    end
    
    if mode == "fixed" then
        return Addon.options:Get("wildPetMarkIcon") or RAID_ICON_SKULL
        
    elseif mode == "random" then
        -- Lazy initialization: shuffle order once on first use in random mode
        if not iconState.iconOrder then
            iconState.iconOrder = {1, 2, 3, 4, 5, 6, 7, 8}
            -- Fisher-Yates shuffle
            for i = 8, 2, -1 do
                local j = math.random(1, i)
                iconState.iconOrder[i], iconState.iconOrder[j] = 
                    iconState.iconOrder[j], iconState.iconOrder[i]
            end
        end
        
        local icon = iconState.iconOrder[iconState.currentIndex]
        iconState.currentIndex = iconState.currentIndex + 1
        if iconState.currentIndex > 8 then
            iconState.currentIndex = 1
        end
        return icon
        
    elseif mode == "sequential" then
        local icon = iconState.currentIndex
        iconState.currentIndex = iconState.currentIndex + 1
        if iconState.currentIndex > 8 then
            iconState.currentIndex = 1
        end
        return icon
    end
    
    return RAID_ICON_SKULL -- Fallback
end

--[[
  Handle target changes - mark wild pets with raid icons
  
  Fires on PLAYER_TARGET_CHANGED event. Checks if target is a wild pet via
  UnitCreatureType, skips if already marked with any icon, then applies the
  next icon from the current marking mode.
]]
function petBattle:onTargetChanged()
    if not UnitExists("target") then
        return
    end
    
    local creatureType = UnitCreatureType("target")
    if creatureType ~= "Wild Pet" then
        return
    end
    
    -- Skip if already marked with any icon (prevents remarking)
    local currentMark = GetRaidTargetIndex("target")
    if currentMark then
        return
    end
    
    -- Get icon from mode-based selection
    local iconIndex = getNextIcon()
    if not iconIndex then
        return  -- Marking disabled
    end
    
    SetRaidTarget("target", iconIndex)
end

--[[
  Handle battle start - capture pet name for macro creation
  
  Fires on PET_BATTLE_OPENING_START event. Captures the battle pet's name
  for use in macro creation after battle ends (if user withdraws).
]]
function petBattle:onBattleStart()
    -- Reset state
    wildBattleTarget.name   = nil
    wildBattleTarget.isWild = false
    battleEndProcessed      = false

    if not UnitExists("target") then
        return
    end

    local name = UnitName("target")
    if not name then
        return
    end

    -- Capture name for any battle pet (useful for both wild and trainer battles)
    wildBattleTarget.name   = name
    wildBattleTarget.isWild = true
end

--[[
  Handle battle end - create targeting macro if enabled
  
  Fires on PET_BATTLE_CLOSE event. If autoTargetAfterWithdraw setting is enabled
  and a pet name was captured, creates/updates the targeting macro after a short
  delay to allow UI state to stabilize.
]]
function petBattle:onBattleFinished()
    if battleEndProcessed
    or not wildBattleTarget.isWild
    or not wildBattleTarget.name
    or not Addon.options
    or not Addon.options.Get
    or not Addon.options:Get("autoTargetAfterWithdraw")
    then
        return
    end

    battleEndProcessed = true

    -- Delay to allow UI to clear before macro creation
    C_Timer.After(MACRO_CREATE_DELAY, function()
        petBattle:createTargetMacro()
        petBattle:clearBattleData()
    end)
end

-- Pending macro data (if we couldn't create due to combat lockdown)
local pendingMacro = nil

--[[
  Create or update the account-wide targeting macro
  
  Creates a macro named PAO_Target_Pet that targets the last wild pet battled.
  Uses [nodead] conditional to prevent targeting dead creatures. If macro already
  exists, updates its target. If account macro slots are full, displays error.
  If in combat lockdown, queues for when combat ends.
]]
function petBattle:createTargetMacro()
    local name = wildBattleTarget.name
    if not name then return end

    -- Protected functions can't be called during combat lockdown
    if InCombatLockdown() then
        pendingMacro = name
        utils:debug("petBattle: Macro creation queued (in combat)")
        return
    end

    local macroText = "/target [nodead] " .. name

    local idx = GetMacroIndexByName(MACRO_NAME)
    if idx == 0 then
        local numAccount = select(1, GetNumMacros())
        if numAccount < MAX_ACCOUNT_MACROS then
            CreateMacro(MACRO_NAME, MACRO_ICON, macroText, nil)
            utils:notify("PAO: Created macro to target '" .. name .. "'")
            if PlaySound then 
                pcall(PlaySound, "ReadyCheck")
            end
        else
            utils:error("PAO: Cannot create macro—account macro slots full (" .. numAccount .. "/" .. MAX_ACCOUNT_MACROS .. ")")
        end
    else
        EditMacro(idx, MACRO_NAME, MACRO_ICON, macroText)
    end
end

--[[
  Process pending macro after combat ends
  Called on PLAYER_REGEN_ENABLED if we had a queued macro.
]]
function petBattle:processPendingMacro()
    if not pendingMacro then return end
    
    local name = pendingMacro
    pendingMacro = nil
    
    local macroText = "/target [nodead] " .. name

    local idx = GetMacroIndexByName(MACRO_NAME)
    if idx == 0 then
        local numAccount = select(1, GetNumMacros())
        if numAccount < MAX_ACCOUNT_MACROS then
            CreateMacro(MACRO_NAME, MACRO_ICON, macroText, nil)
            utils:notify("PAO: Created macro to target '" .. name .. "'")
        else
            utils:error("PAO: Cannot create macro—account macro slots full")
        end
    else
        EditMacro(idx, MACRO_NAME, MACRO_ICON, macroText)
    end
end

--[[
  Clear battle state data
  
  Resets all battle-related state after macro creation. Called after the
  macro creation delay completes.
]]
function petBattle:clearBattleData()
    wildBattleTarget.name   = nil
    wildBattleTarget.isWild = false
    battleEndProcessed      = false
end

--[[
  Initialize the pet battle module
  
  Registers event handlers for target changes, battle start, and battle end.
  Sets up callback for marking mode changes to reset icon state reactively.
  
  @return boolean - true if initialization succeeded
]]
function petBattle:initialize()
    if not Addon.events then
        utils:error("petBattle: Addon.events not available")
        return false
    end

    -- Register target changed to mark battle pets immediately
    Addon.events:subscribe("PLAYER_TARGET_CHANGED", function()
        petBattle:onTargetChanged()
    end)
    
    -- Register battle start to capture pet name
    Addon.events:subscribe("PET_BATTLE_OPENING_START", function()
        petBattle:onBattleStart()
    end)
    
    -- Register battle end for macro creation
    Addon.events:subscribe("PET_BATTLE_CLOSE", function()
        petBattle:onBattleFinished()
    end)

    -- Register callback for marking mode changes to reset icon state
    if Addon.options and Addon.options.RegisterCallback then
        Addon.options:RegisterCallback("wildPetMarkMode", function()
            iconState.currentIndex = 1
            iconState.iconOrder = nil
        end)
    end

    -- Process pending macro when combat ends
    Addon.events:subscribe("PLAYER_REGEN_ENABLED", function()
        petBattle:processPendingMacro()
    end)

    return true
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("petBattle", {"utils", "options"}, function()
        if petBattle.initialize then
            return petBattle:initialize()
        end
        return true
    end)
end

Addon.petBattle = petBattle
return petBattle