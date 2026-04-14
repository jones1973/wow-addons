--[[
  logic/teamManagement.lua
  Team Management Logic
  
  Handles battle team operations:
  - Queue management (Find Battle / Leave Queue)
  - Pet healing (spell + bandage prompt)
  - Team clearing
  - Random team generation
  
  Dependencies: utils, events
  Exports: Addon.teamManagement
]]

local ADDON_NAME, Addon = ...

-- Dependency checks
if not Addon.utils then
  print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in teamManagement.lua|r")
  return {}
end


local utils = Addon.utils
local events = Addon.events

local teamManagement = {}

-- Heal spell ID (Revive Battle Pets)
local HEAL_SPELL_ID = 125439

-- Bandage confirmation frame (created once)
local bandageConfirmFrame = nil

--[[
  Create Bandage Confirmation Frame
  Creates a popup with a secure button that uses bandages.
]]
local function createBandageConfirmFrame()
  if bandageConfirmFrame then
    return bandageConfirmFrame
  end
  
  -- Main frame
  local frame = CreateFrame("Frame", "PAO_BandageConfirm", UIParent, "BackdropTemplate")
  frame:SetSize(300, 120)
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
  
  -- Secure Use Bandage button
  frame.useButton = CreateFrame("Button", "PAO_BandageConfirmUseButton", frame, "SecureActionButtonTemplate")
  frame.useButton:SetSize(100, 24)
  frame.useButton:SetPoint("BOTTOM", -54, 16)
  frame.useButton:SetAttribute("type", "macro")
  frame.useButton:SetAttribute("macrotext", "/use item:86143")
  
  -- Style use button
  frame.useButton.bg = frame.useButton:CreateTexture(nil, "BACKGROUND")
  frame.useButton.bg:SetAllPoints()
  frame.useButton.bg:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
  frame.useButton.bg:SetTexCoord(0, 0.625, 0, 0.6875)
  
  frame.useButton.text = frame.useButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.useButton.text:SetPoint("CENTER")
  frame.useButton.text:SetText("Use Bandages")
  
  -- Insecure Cancel button  
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
  
  -- Post-click handler to hide frame after using bandage
  frame.useButton:SetScript("PostClick", function()
    frame:Hide()
  end)
  
  bandageConfirmFrame = frame
  return frame
end

--[[
  Get Queue State
  Returns current PvP matchmaking queue state.
  
  @return boolean - True if queued, false otherwise
]]
function teamManagement:getQueueState()
  local queueState = C_PetBattles.GetPVPMatchmakingInfo()
  return (queueState == "queued" or queueState == "proposal" or queueState == "suspended")
end

--[[
  Find Battle
  Toggles PvP matchmaking queue. Starts queue if not queued, stops if queued.
]]
function teamManagement:findBattle()
  if self:getQueueState() then
    C_PetBattles.StopPVPMatchmaking()
  else
    C_PetBattles.StartPVPMatchmaking()
  end
end

--[[
  Check if heal spell is available
  
  @return boolean - True if spell is in spellbook and usable
]]
local function isHealSpellAvailable()
  -- Check if spell is in spellbook
  local spellName = GetSpellInfo(HEAL_SPELL_ID)
  if not spellName then
    return false
  end
  
  -- Check if spell is known (in spellbook)
  local spellBank = Enum.SpellBookSpellBank.Player
  if not C_SpellBook then
    -- Fallback for older API
    local i = 1
    while true do
      local spell, _, _, _, _, _, id = GetSpellInfo(i, BOOKTYPE_SPELL)
      if not spell then
        break
      end
      if id == HEAL_SPELL_ID then
        return true
      end
      i = i + 1
    end
    return false
  end
  
  -- MoP Classic uses newer API
  local includeOverrides = false
  return C_SpellBook.IsSpellInSpellBook(HEAL_SPELL_ID, spellBank, includeOverrides)
end

--[[
  Cast heal spell
  Attempts to cast the Revive Battle Pets spell.
]]
local function castHealSpell()
  local spellName = GetSpellInfo(HEAL_SPELL_ID)
  if spellName then
    CastSpellByName(spellName)
  end
end

--[[
  Heal Pets
  Attempts to heal pets using Revive Battle Pets spell. If unavailable, prompts for bandage use.
]]
function teamManagement:healPets()
  if isHealSpellAvailable() then
    castHealSpell()
  else
    StaticPopup_Show("PAO_USE_BANDAGE")
  end
end

--[[
  Get Injured Pets
  Scans all owned pets and returns list of injured pets with details.
  
  @return table - Array of {petID, name, health, maxHealth, healthPercent}
]]
function teamManagement:getInjuredPets()
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

--[[
  Check if player has bandages
  Scans bags for pet bandages.
  
  @return boolean - True if bandages found
]]
function teamManagement:hasBandages()
  -- Pet bandage item IDs (add more as needed)
  local bandageItems = {
    86143, -- Battle Pet Bandage
    -- Add other bandage item IDs if they exist
  }
  
  for _, itemID in ipairs(bandageItems) do
    local count = GetItemCount(itemID)
    if count and count > 0 then
      return true
    end
  end
  
  return false
end

--[[
  Get Heal Spell Cooldown
  Returns cooldown info for Revive Battle Pets spell.
  
  @return number, number - start, duration (0, 0 if ready)
]]
function teamManagement:getHealCooldown()
  local start, duration = GetSpellCooldown(HEAL_SPELL_ID)
  return start or 0, duration or 0
end

--[[
  Get Random Level 25 Rare Pets
  
  @param count number - Number of random pets to get
  @return table - Array of petIDs
]]
local function getRandomLevel25Rares(count)
  local eligiblePets = {}
  
  -- Scan all pets
  local numPets, numOwned = C_PetJournal.GetNumPets()
  for i = 1, numOwned do
    local petID, speciesID, owned, customName, level, favorite, isRevoked, speciesName,
          icon, petType, companionID, tooltip, description, isWild, canBattle, isTradeable,
          isUnique, obtainable = C_PetJournal.GetPetInfoByIndex(i)
    
    if petID and owned and level == 25 and canBattle then
      -- Get rarity (0-3, need rare or better which is 2+)
      local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
      -- rarity is 1-4 in MoP, convert to 0-3 and check >= 2 (rare)
      local rarityValue = (rarity or 1) - 1
      if rarityValue >= 2 then
        table.insert(eligiblePets, petID)
      end
    end
  end
  
  -- Shuffle and take first 'count' pets
  local selected = {}
  for i = 1, math.min(count, #eligiblePets) do
    local randIndex = math.random(1, #eligiblePets)
    table.insert(selected, eligiblePets[randIndex])
    table.remove(eligiblePets, randIndex)
  end
  
  return selected
end

--[[
  Random Team
  Fills loadout with 3 random level 25 rare pets.
]]
function teamManagement:randomTeam()
  local randomPets = getRandomLevel25Rares(3)
  
  -- Can't clear with nil - just set what we have
  -- If we have fewer than 3, remaining slots stay as-is
  for i, petID in ipairs(randomPets) do
    C_PetJournal.SetPetLoadOutInfo(i, petID)
  end
  
  if events then
    events:emit("LOADOUT:CHANGED")
  end
end

--[[
  Show Bandage Confirmation
  Displays confirmation dialog for using bandages.
]]
function teamManagement:showBandageConfirmation()
  local frame = createBandageConfirmFrame()
  
  -- Update message with current cooldown
  local start, duration = self:getHealCooldown()
  if start > 0 and duration > 0 then
    local remaining = duration - (GetTime() - start)
    local minutes = math.floor(remaining / 60)
    local seconds = math.floor(remaining % 60)
    frame.message:SetFormattedText("Revive Battle Pets is on cooldown\n(%d:%02d remaining).\n\nUse bandages to heal your pets?", minutes, seconds)
  else
    frame.message:SetText("Revive Battle Pets is on cooldown.\n\nUse bandages to heal your pets?")
  end
  
  frame:Show()
end

-- Register with addon
Addon.teamManagement = teamManagement

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("teamManagement", {"utils", "events"}, function()
    return true
  end)
end

return teamManagement