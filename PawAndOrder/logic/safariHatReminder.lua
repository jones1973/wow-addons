--[[
  logic/safariHatReminder.lua
  Safari Hat Reminder
  
  Shows a warning popup when entering a wild pet battle without the Safari Hat buff.
  Provides a protected button to use the Safari Hat toy and forfeit in one action,
  allowing the player to re-engage with the buff active.
  
  Dependencies: events, utils, constants, petUtils
  Exports: Addon.safariHatReminder
]]

local ADDON_NAME, Addon = ...

local safariHatReminder = {}

-- Module references (resolved at init)
local events, utils, constants, petUtils

-- State
local initialized = false
local reminderFrame = nil

-- ============================================================================
-- SAFARI HAT CHECKS
-- ============================================================================

local function hasSafariHatBuff()
  return petUtils:hasXpBuff("SAFARI_HAT")
end

local function hasSafariHat()
  return petUtils:hasXpBuffItem("SAFARI_HAT")
end

local function isWildBattle()
  if not C_PetBattles.IsInBattle() then return false end
  return C_PetBattles.IsWildBattle()
end

-- ============================================================================
-- POPUP CREATION
-- ============================================================================

local function createReminderFrame()
  local frame = CreateFrame("Frame", "PAOSafariHatReminder", UIParent, "BackdropTemplate")
  frame:SetSize(340, 160)
  frame:SetPoint("TOP", UIParent, "TOP", 0, -120)
  frame:SetFrameStrata("DIALOG")
  frame:SetFrameLevel(100)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  })
  frame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
  
  -- Close button
  local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
  closeBtn:SetScript("OnClick", function() frame:Hide() end)
  
  -- Warning icon
  local icon = frame:CreateTexture(nil, "ARTWORK")
  icon:SetSize(42, 42)
  icon:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -20)
  icon:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
  
  -- Title
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -4)
  title:SetText("|cffff9900Safari Hat Missing|r")
  
  -- Subtitle
  local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  subtitle:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -24)
  subtitle:SetText("You're missing the 10% XP bonus!")
  subtitle:SetTextColor(0.9, 0.9, 0.9)
  
  -- Explainer text
  local explainer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  explainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -75)
  explainer:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
  explainer:SetJustifyH("LEFT")
  explainer:SetText("Click below to equip the Safari Hat and forfeit.\nThe wild pet will respawn for you to re-engage.")
  explainer:SetTextColor(0.8, 0.8, 0.8)
  explainer:SetSpacing(2)
  
  -- Protected button: Use Hat & Forfeit
  local hatBtn = CreateFrame("Button", "PAOSafariHatUseButton", frame, "SecureActionButtonTemplate, UIPanelButtonTemplate")
  hatBtn:SetSize(150, 28)
  hatBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 18)
  hatBtn:SetText("Use Hat & Forfeit")
  hatBtn:SetAttribute("type", "toy")
  hatBtn:SetAttribute("toy", constants.XP_BUFF.ITEM_IDS.SAFARI_HAT)
  
  -- After the protected toy use, forfeit
  hatBtn:HookScript("OnClick", function()
    frame:Hide()
    -- Small delay to let the toy action complete
    C_Timer.After(0.15, function()
      if C_PetBattles.IsInBattle() then
        C_PetBattles.ForfeitGame()
      end
    end)
  end)
  frame.hatBtn = hatBtn
  
  -- Dismiss button
  local dismissBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  dismissBtn:SetSize(120, 28)
  dismissBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 18)
  dismissBtn:SetText("Continue Battle")
  dismissBtn:SetScript("OnClick", function() frame:Hide() end)
  frame.dismissBtn = dismissBtn
  
  -- ESC to close
  table.insert(UISpecialFrames, "PAOSafariHatReminder")
  
  frame:Hide()
  return frame
end

-- ============================================================================
-- SHOW/HIDE LOGIC
-- ============================================================================

local function showReminder()
  if not reminderFrame then
    reminderFrame = createReminderFrame()
  end
  
  -- Update button state based on toy ownership
  if reminderFrame.hatBtn then
    if hasSafariHat() then
      reminderFrame.hatBtn:Enable()
      reminderFrame.hatBtn:SetText("Use Hat & Forfeit")
    else
      reminderFrame.hatBtn:Disable()
      reminderFrame.hatBtn:SetText("No Safari Hat")
    end
  end
  
  reminderFrame:Show()
end

local function hideReminder()
  if reminderFrame then
    reminderFrame:Hide()
  end
end

-- ============================================================================
-- BATTLE START HANDLER
-- ============================================================================

local function onBattleStart()
  -- Only for wild battles
  if not isWildBattle() then
    return
  end
  
  -- Already have the buff - all good
  if hasSafariHatBuff() then
    return
  end
  
  -- Show the reminder
  showReminder()
  
  if utils then
    utils:debug("SafariHatReminder: Wild battle started without Safari Hat buff")
  end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function safariHatReminder:initialize()
  if initialized then return true end
  
  events = Addon.events
  utils = Addon.utils
  constants = Addon.constants
  petUtils = Addon.petUtils
  
  if not events then
    print("|cff33ff99PAO|r: |cffff4444safariHatReminder: Missing events dependency|r")
    return false
  end
  
  if not constants or not constants.XP_BUFF then
    print("|cff33ff99PAO|r: |cffff4444safariHatReminder: Missing constants.XP_BUFF|r")
    return false
  end
  
  if not petUtils then
    print("|cff33ff99PAO|r: |cffff4444safariHatReminder: Missing petUtils dependency|r")
    return false
  end
  
  -- Check when battle starts
  events:subscribe("PET_BATTLE_OPENING_DONE", function()
    onBattleStart()
  end)
  
  -- Hide when battle ends
  events:subscribe("PET_BATTLE_CLOSE", function()
    hideReminder()
  end)
  
  initialized = true
  if utils then
    utils:debug("SafariHatReminder: Initialized")
  end
  return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
  Addon.registerModule("safariHatReminder", {"events", "utils", "constants", "petUtils"}, function()
    return safariHatReminder:initialize()
  end)
end

Addon.safariHatReminder = safariHatReminder
return safariHatReminder