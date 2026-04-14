--[[
  logic/petActions.lua
  Pet Actions Module
  
  Handles player actions affecting the entire pet collection:
  - Heal all pets (spell + bandage fallback)
  - Summon random companion
  - Cooldown queries
  
  Dependencies: utils, events
  Exports: Addon.petActions
]]

local ADDON_NAME, Addon = ...

local petActions = {}

-- Revive Battle Pets spell ID
local HEAL_SPELL_ID = 125439

-- Battle Pet Bandage item ID
local BANDAGE_ITEM_ID = 86143

-- Bandage confirmation frame (created once)
local bandageConfirmFrame = nil

-- Module references
local utils, events

-- ============================================================================
-- BANDAGE CONFIRMATION POPUP
-- ============================================================================

--[[
  Create bandage confirmation popup.
  Uses SecureActionButtonTemplate for protected item use.
  
  @return frame
]]
local function createBandageConfirmFrame()
  if bandageConfirmFrame then
    return bandageConfirmFrame
  end
  
  local frame = CreateFrame("Frame", "PAO_BandageConfirm", UIParent, "BackdropTemplate")
  frame:SetSize(300, 145)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:Hide()
  
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  })
  frame:SetBackdropColor(0, 0, 0, 0.9)
  
  -- Title
  frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  frame.title:SetPoint("TOP", 0, -16)
  frame.title:SetText("Use Bandages?")
  
  -- Message
  frame.message = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  frame.message:SetPoint("TOP", frame.title, "BOTTOM", 0, -12)
  frame.message:SetWidth(260)
  frame.message:SetJustifyH("CENTER")
  
  -- Secure Use Bandage button (required for protected item use)
  frame.useButton = CreateFrame("Button", "PAO_BandageConfirmUseButton", frame, "SecureActionButtonTemplate")
  frame.useButton:SetSize(100, 24)
  frame.useButton:SetPoint("BOTTOM", -54, 16)
  frame.useButton:SetAttribute("type", "macro")
  frame.useButton:SetAttribute("macrotext", "/use item:" .. BANDAGE_ITEM_ID)
  
  -- Style use button
  frame.useButton.bg = frame.useButton:CreateTexture(nil, "BACKGROUND")
  frame.useButton.bg:SetAllPoints()
  frame.useButton.bg:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
  frame.useButton.bg:SetTexCoord(0, 0.625, 0, 0.6875)
  
  frame.useButton.text = frame.useButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.useButton.text:SetPoint("CENTER")
  frame.useButton.text:SetText("Use Bandages")
  
  -- Cancel button
  frame.cancelButton = CreateFrame("Button", nil, frame)
  frame.cancelButton:SetSize(100, 24)
  frame.cancelButton:SetPoint("BOTTOM", 54, 16)
  
  frame.cancelButton.bg = frame.cancelButton:CreateTexture(nil, "BACKGROUND")
  frame.cancelButton.bg:SetAllPoints()
  frame.cancelButton.bg:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
  frame.cancelButton.bg:SetTexCoord(0, 0.625, 0, 0.6875)
  
  frame.cancelButton.text = frame.cancelButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.cancelButton.text:SetPoint("CENTER")
  frame.cancelButton.text:SetText("Cancel")
  
  frame.cancelButton:SetScript("OnClick", function()
    frame:Hide()
  end)
  
  -- Close button
  frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  frame.closeButton:SetPoint("TOPRIGHT", 2, 2)
  frame.closeButton:SetScript("OnClick", function()
    frame:Hide()
  end)
  
  -- Hide after using bandage and emit internal event
  frame.useButton:SetScript("PostClick", function()
    frame:Hide()
    -- Bandages don't trigger Blizzard's PET_JOURNAL_PETS_HEALED, emit our own
    C_Timer.After(0.5, function()
      if Addon.events then
        Addon.events:emit("TEAM:PETS_HEALED")
      end
    end)
  end)
  
  bandageConfirmFrame = frame
  return frame
end

-- ============================================================================
-- HEAL SPELL UTILITIES
-- ============================================================================

--[[
  Check if heal spell is known and available.
  
  @return boolean
]]
local function isHealSpellKnown()
  local spellName = GetSpellInfo(HEAL_SPELL_ID)
  if not spellName then
    return false
  end
  
  -- Check spellbook
  if C_SpellBook and C_SpellBook.IsSpellInSpellBook then
    local spellBank = Enum.SpellBookSpellBank.Player
    return C_SpellBook.IsSpellInSpellBook(HEAL_SPELL_ID, spellBank, false)
  end
  
  -- Fallback: iterate spellbook
  local i = 1
  while true do
    local spell, _, _, _, _, _, id = GetSpellInfo(i, BOOKTYPE_SPELL)
    if not spell then break end
    if id == HEAL_SPELL_ID then return true end
    i = i + 1
  end
  
  return false
end

-- NOTE: Spell casting now handled via SecureActionButtonTemplate in headerBar.lua
-- The heal button uses secure attributes to cast the spell directly.

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Heal all battle pets.
  NOTE: Direct spell casting requires a secure button (headerBar's Heal button).
  This function handles the bandage fallback when on cooldown.
  
  If spell is ready, shows a message directing user to use the UI button.
  If on cooldown with bandages, shows bandage confirmation popup.
  If on cooldown without bandages, shows cooldown message.
]]
function petActions:heal()
  if not isHealSpellKnown() then
    if utils then utils:chat("Revive Battle Pets spell not available.") end
    return
  end
  
  local start, duration = self:getHealCooldown()
  local isOnCooldown = start > 0 and duration > 0 and (GetTime() < start + duration)
  
  if not isOnCooldown then
    -- Spell ready but can't cast from addon code - direct to UI
    if utils then 
      utils:chat("Use the Heal button in the header bar to cast Revive Battle Pets.") 
    end
  else
    -- On cooldown - offer bandage if available
    if self:hasBandages() then
      self:showBandageConfirmation()
    else
      local remaining = (start + duration) - GetTime()
      local minutes = math.floor(remaining / 60)
      local seconds = math.floor(remaining % 60)
      if utils then
        utils:chat(string.format("Revive Battle Pets on cooldown (%d:%02d). No bandages available.", minutes, seconds))
      end
    end
  end
end

--[[
  Summon a random companion pet.
  
  @param favoritesOnly boolean - Only summon from favorites (default false)
]]
function petActions:summonRandom(favoritesOnly)
  if C_PetJournal and C_PetJournal.SummonRandomPet then
    C_PetJournal.SummonRandomPet(favoritesOnly or false)
  end
end

--[[
  Get heal spell cooldown info.
  
  @return number, number - start time, duration (0, 0 if ready)
]]
function petActions:getHealCooldown()
  local start, duration = GetSpellCooldown(HEAL_SPELL_ID)
  return start or 0, duration or 0
end

--[[
  Check if heal spell is on cooldown.
  
  @return boolean
]]
function petActions:isHealOnCooldown()
  local start, duration = self:getHealCooldown()
  if start == 0 or duration == 0 then
    return false
  end
  return GetTime() < (start + duration)
end

--[[
  Get remaining cooldown time in seconds.
  
  @return number - Seconds remaining, 0 if ready
]]
function petActions:getHealCooldownRemaining()
  local start, duration = self:getHealCooldown()
  if start == 0 or duration == 0 then
    return 0
  end
  local remaining = (start + duration) - GetTime()
  return math.max(0, remaining)
end

--[[
  Check if player has pet bandages in inventory.
  
  @return boolean
]]
function petActions:hasBandages()
  local count = GetItemCount(BANDAGE_ITEM_ID)
  return count and count > 0
end

--[[
  Get bandage count.
  
  @return number
]]
function petActions:getBandageCount()
  return GetItemCount(BANDAGE_ITEM_ID) or 0
end

--[[
  Show bandage confirmation popup.
  Updates message with current cooldown info.
]]
function petActions:showBandageConfirmation()
  local frame = createBandageConfirmFrame()
  
  local start, duration = self:getHealCooldown()
  if start > 0 and duration > 0 then
    local remaining = (start + duration) - GetTime()
    local minutes = math.floor(remaining / 60)
    local seconds = math.floor(remaining % 60)
    frame.message:SetFormattedText(
      "Revive Battle Pets is on cooldown\n(%d:%02d remaining).\n\nUse bandages to heal your pets?",
      minutes, seconds
    )
  else
    frame.message:SetText("Use bandages to heal your pets?")
  end
  
  frame:Show()
end

--[[
  Get list of injured pets.
  
  @return table - Array of {petID, name, health, maxHealth, healthPercent}
]]
function petActions:getInjuredPets()
  local injured = {}
  local numPets, numOwned = C_PetJournal.GetNumPets()
  
  for i = 1, numOwned do
    local petID = C_PetJournal.GetPetInfoByIndex(i)
    if petID then
      local health, maxHealth = C_PetJournal.GetPetStats(petID)
      if health and maxHealth and health < maxHealth then
        local _, customName, _, _, _, _, _, petName = C_PetJournal.GetPetInfoByPetID(petID)
        local displayName = customName or petName or "Unknown"
        local healthPercent = math.floor((health / maxHealth) * 100)
        
        table.insert(injured, {
          petID = petID,
          name = displayName,
          health = health,
          maxHealth = maxHealth,
          healthPercent = healthPercent
        })
      end
    end
  end
  
  return injured
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
  Addon.registerModule("petActions", {"utils"}, function()
    utils = Addon.utils
    events = Addon.events
    return true
  end)
end

Addon.petActions = petActions
return petActions