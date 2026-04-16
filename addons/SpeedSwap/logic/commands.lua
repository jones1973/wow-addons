--[[
  logic/commands.lua
  SpeedSwap Slash Command Handler

  All functionality is exposed through a single slash command (/speedswap
  or /ss) with subcommands. The dispatcher is flat rather than using a
  command registry - there are only four subcommands and the registration
  overhead wouldn't pay off.

  Dependencies: Addon.gearSwap, Addon.gearState
  Exports: Addon.commands
]]

local ADDON_NAME, Addon = ...

local commands = {}

-- ============================================================================
-- OUTPUT
-- ============================================================================

local function msg(...)
    print("|cff00ccffSpeedSwap:|r", ...)
end

-- ============================================================================
-- SUBCOMMANDS
-- ============================================================================

local function cmdEquip()
    speedswap_character.autoEquip = not speedswap_character.autoEquip
    if speedswap_character.autoEquip then
        msg("Auto-equip speed gear |cff00ff00ON|r.")
    else
        msg("Auto-equip speed gear |cffff0000OFF|r.")
    end
end

local function cmdSwim()
    speedswap_character.swimBelt = not speedswap_character.swimBelt
    if speedswap_character.swimBelt then
        msg("Swim belt auto-equip |cff00ff00ON|r.")
    else
        msg("Swim belt auto-equip |cffff0000OFF|r.")
    end
end

local function cmdDebug()
    speedswap_character.debug = not speedswap_character.debug
    if speedswap_character.debug then
        msg("Debug mode |cff00ff00ON|r.")
    else
        msg("Debug mode |cffff0000OFF|r.")
    end
end

local function cmdStatus()
    local state = Addon.gearState:status()
    local gearSwap = Addon.gearSwap

    msg("Trinket: " .. state.trinketSummary)
    msg("Pending mount: " .. tostring(state.pendingMount))
    msg("Pending swim: "  .. tostring(state.pendingSwim))
    msg(string.format("Mounted: %s  Taxi: %s  Instance: %s",
        tostring(IsMounted()),
        tostring(UnitOnTaxi("player")),
        tostring(IsInInstance())))
    msg("Spurs boots in bags: " .. (gearSwap:hasSpursBoots() and "yes" or "no"))
    msg("Riding gloves in bags: " .. (gearSwap:hasRidingGloves() and "yes" or "no"))
    msg("Swim belt saved: " .. gearSwap:getItemNameByID(speedswap_character.savedWaistID))
end

local function cmdHelp()
    msg("commands:")
    print("  /ss equip - Toggle auto-equip speed gear on mount")
    print("  /ss swim - Toggle auto-equip Azure Silk Belt while swimming")
    print("  /ss status - Show current swap state and gear info")
    print("  /ss debug - Toggle debug output")
end

-- ============================================================================
-- DISPATCH
-- ============================================================================

--[[
  Handle a slash command invocation.

  @param input string - The raw argument string from the slash command
]]
function commands:dispatch(input)
    input = strtrim(input or ""):lower()

    if     input == "equip"  then cmdEquip()
    elseif input == "swim"   then cmdSwim()
    elseif input == "debug"  then cmdDebug()
    elseif input == "status" then cmdStatus()
    elseif input == ""       then cmdHelp()
    else                          msg("Unknown command. Type /ss for help.")
    end
end

-- ============================================================================
-- EXPORT
-- ============================================================================

Addon.commands = commands
