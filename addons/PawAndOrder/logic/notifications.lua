--[[
  logic/notifications.lua
  Audio and Visual Notifications
  
  Handles custom notifications for game events:
  - Level 25 celebration popup with sound when a pet reaches max level
  - Future: other notification types
  
  Events Consumed:
  - CACHE:PETS_LEVELED → filters for level 25, queues celebration
  - CONSOLE_MESSAGE    → shows popup after battle UI closes (dynamic subscription)
  
  Dependencies: events, options, utils
  Exports: Addon.notifications
]]

local ADDON_NAME, Addon = ...

local notifications = {}

-- Module references (set in initialize)
local events, options, utils, dropdownLegacy, constants, actionButton, tooltip

-- ============================================================================
-- CONSTANTS
-- ============================================================================

-- Sound Kit IDs (not FDIDs - MoP Classic uses PlaySound)
local SOUNDS = {
  CELEBRATION = 8574,  -- Boss kill fanfare
}

-- Custom sound file paths 
local SOUND_FILES = {
  DUN_DUN = "Interface\\AddOns\\PawAndOrder\\sounds\\dun-dun.mp3",
}

-- Delay before dun-dun plays after fanfare (seconds)
-- Timed to punctuate after the fanfare's crescendo fades
local DUN_DUN_DELAY = 3.7

-- Layout constants
local LAYOUT = {
  POPUP_PADDING = 24,
  
  -- Header/flavor
  HEADER_HEIGHT = 32,
  FLAVOR_HEIGHT = 40,
  HEADER_TO_FLAVOR_GAP = 12,
  FLAVOR_TO_CONTENT_GAP = 4,
  
  -- Graduate display (celebration section)
  GRAD_MODEL_SIZE = 160,
  GRAD_ZONE_WIDTH = 200,
  GRAD_ZONE_HEIGHT = 230,  -- Increased to avoid top cutoff
  GRAD_GAP = 30,
  
  -- Separator between graduate and next-up sections
  SECTION_SEPARATOR_HEIGHT = 28,  -- Comfortable breathing room between sections
  
  -- Next-up display (action section)
  NEXTUP_ICON_SIZE = 44,
  NEXTUP_ZONE_HEIGHT = 72,  -- Slightly reduced
  NEXTUP_ZONE_WIDTH = 440,
  NEXTUP_PET_DISPLAY_WIDTH = 160,
  NEXTUP_SECTION_GAP = 10,
  NEXTUP_TO_BUTTON_GAP = 16,
  
  -- Buttons
  BUTTON_HEIGHT = 32,
  BUTTON_WIDTH = 120,
  BUTTON_GAP = 12,
  
  -- Carousel
  CAROUSEL_ADVANCE_TIME = 3,
  CAROUSEL_VISIBLE_RATIO = 2.5,
}

-- Sparkle effect configuration
local SPARKLE = {
  COUNT = 8,
  SIZE_MIN = 20,
  SIZE_MAX = 40,
  TEXTURES = {
    "Interface\\Cooldown\\star4",
    "Interface\\Cooldown\\starburst",
  },
}

-- Celebratory messages - single pet (Law & Order themed)
local FLAVOR_TEXTS_SINGLE = {
  "Your companion has reached their full potential!",
  "A true champion emerges!",
  "Battle-hardened and ready for anything!",
  "From humble beginnings to legendary status!",
  "The journey is complete... or is it?",
  "Case closed. This pet is now a certified champion.",
  "The verdict is in: Maximum battle readiness achieved!",
  "Order in the menagerie! A new legend rises.",
  "Investigation complete. Subject is fully battle-hardened.",
  "Justice has been served... to every opponent in their path.",
  "Another one for the files: Legendary companion confirmed.",
  "The evidence is clear: This pet means business.",
  "Max level achieved.",
  "Years of training, exposed in a single moment of glory.",
  "This pet has seen things. Battle things.",
}

-- Celebratory messages - multiple pets (Law & Order themed)
local FLAVOR_TEXTS_MULTIPLE = {
  "Your companions have reached their full potential!",
  "A team of champions emerges!",
  "Battle-hardened and ready for anything!",
  "From humble beginnings to legendary status!",
  "What a battle!",
  "Multiple cases closed simultaneously. Excellent work.",
  "The squad is fully deputized and ready for action!",
  "Order restored. The team is complete.",
  "All subjects confirmed battle-ready. Case closed.",
  "Justice served in bulk. The streets are safer.",
  "Multiple convictions... of excellence!",
  "These pets have formed a special victims unit. For enemies.",
}

-- Random headers for celebration popup (works for any count)
local CELEBRATION_HEADERS = {
  -- Generic celebratory (mix of punctuation)
  "Level 25",
  "Max Level",
  "Legendary",
  "Champions Rise",
  -- Law & Order themed
  "Case Closed",
  "Justice Served",
  "Verdict: Legendary",
  "Order Restored",
  "Maximum Sentence",
  -- Battle-focused
  "What a Battle",
  "Battle Hardened",
  "Victory!",  -- Keep one emphatic option
}

-- ============================================================================
-- STATE
-- ============================================================================

local pendingCelebrations = {}    -- Array of petIDs that hit 25
local consoleMessageSubId = nil   -- Subscription ID for CONSOLE_MESSAGE (temporary)
local celebrationFrame = nil      -- Lazy-initialized popup frame

-- Forward declarations
local showCelebration

-- ============================================================================
-- ANIMATION HELPERS
-- ============================================================================

--[[
  Hide all sparkle textures on the celebration frame
]]
local function hideSparkles()
  if not celebrationFrame or not celebrationFrame.sparkles then return end
  for _, sparkle in ipairs(celebrationFrame.sparkles) do
    sparkle:Hide()
  end
end

--[[
  Randomize sparkle properties for a fresh animation
  Called each time the popup shows.
]]
local function randomizeSparkles()
  if not celebrationFrame or not celebrationFrame.sparkles then return end
  for i, sparkle in ipairs(celebrationFrame.sparkles) do
    -- Random size
    local size = math.random(SPARKLE.SIZE_MIN, SPARKLE.SIZE_MAX)
    sparkle:SetSize(size, size)
    sparkle:SetTexture(SPARKLE.TEXTURES[math.random(#SPARKLE.TEXTURES)])
    sparkle.baseSize = size
    
    -- Random animation parameters
    sparkle.rotationSpeed = (math.random() - 0.5) * 4
    sparkle.pulseSpeed = 1.5 + math.random() * 1.5
    sparkle.pulsePhase = math.random() * math.pi * 2
    sparkle.orbitSpeed = 0.3 + math.random() * 0.3
    
    -- Distribute evenly around orbit with slight randomness
    sparkle.orbitAngle = (i - 1) * (2 * math.pi / SPARKLE.COUNT) + math.random() * 0.5
  end
end

--[[
  Fade-in OnUpdate handler (reusable, not recreated each show)
]]
local fadeInElapsed = 0
local function fadeInOnUpdate(self, dt)
  fadeInElapsed = fadeInElapsed + dt
  local alpha = math.min(1, fadeInElapsed / 0.3)
  self:SetAlpha(alpha)
  if alpha >= 1 then
    self:SetScript("OnUpdate", nil)
  end
end

--[[
  Sparkle animation OnUpdate handler
]]
local function sparkleOnUpdate(self, dt)
  local frame = celebrationFrame
  if not frame or not frame:IsVisible() then return end
  
  frame.sparkleElapsed = frame.sparkleElapsed + dt
  local t = frame.sparkleElapsed
  
  local centerX, centerY = frame:GetCenter()
  if not centerX then return end
  
  for _, sparkle in ipairs(frame.sparkles) do
    if sparkle:IsShown() then
      -- Update orbit position (elliptical to match popup shape)
      sparkle.orbitAngle = sparkle.orbitAngle + sparkle.orbitSpeed * dt
      local x = math.cos(sparkle.orbitAngle) * sparkle.orbitRadiusX
      local y = math.sin(sparkle.orbitAngle) * sparkle.orbitRadiusY
      sparkle:ClearAllPoints()
      sparkle:SetPoint("CENTER", frame, "CENTER", x, y)
      
      -- Pulse size
      local pulse = 0.7 + 0.3 * math.sin(t * sparkle.pulseSpeed + sparkle.pulsePhase)
      local newSize = sparkle.baseSize * pulse
      sparkle:SetSize(newSize, newSize)
      
      -- Rotate
      local rotation = t * sparkle.rotationSpeed
      sparkle:SetRotation(rotation)
      
      -- Fade alpha with pulse
      sparkle:SetAlpha(0.5 + 0.4 * pulse)
    end
  end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

--[[
  Handle console message to detect battle UI closed.
  Shows celebration popup when "---ClientPetBattleFinished---" received.
]]
local function onConsoleMessage(eventName, message)
  if utils then
    utils:debug(string.format("[CELEB] onConsoleMessage: %s", tostring(message)))
  end
  
  if message ~= "---ClientPetBattleFinished---" then 
    return 
  end
  
  if utils then
    utils:debug("[CELEB] Battle finished message received!")
  end
  
  -- Unsubscribe immediately - we only needed this one message
  if consoleMessageSubId then
    events:unsubscribe(consoleMessageSubId)
    consoleMessageSubId = nil
    if utils then
      utils:debug("[CELEB] Unsubscribed from CONSOLE_MESSAGE")
    end
  end
  
  if #pendingCelebrations > 0 then
    if utils then
      utils:debug(string.format("[CELEB] Showing celebration for %d pet(s)", #pendingCelebrations))
    end
    showCelebration(pendingCelebrations)
    pendingCelebrations = {}
  else
    if utils then
      utils:debug("[CELEB] No pending celebrations to show")
    end
  end
end

--[[
  Handle pets leveled event from cache.
  Filters for pets that hit max level (25) and queues celebration.
  
  @param eventName string - Event name
  @param payload table - { pets = {{petID, oldLevel, newLevel}, ...} }
]]
local function onPetsLeveled(eventName, payload)
  if utils then
    utils:debug("[CELEB] onPetsLeveled called")
  end
  
  local action = options:Get("level25Action")
  
  if utils then
    utils:debug(string.format("[CELEB] level25Action=%s", tostring(action)))
  end
  
  if action == "disabled" then 
    if utils then
      utils:debug("[CELEB] Celebrations disabled, returning")
    end
    return 
  end
  
  if not payload or not payload.pets then 
    if utils then
      utils:debug("[CELEB] No payload or pets, returning")
    end
    return 
  end
  
  if utils then
    utils:debug(string.format("[CELEB] Processing %d pet(s)", #payload.pets))
  end
  
  -- Filter for pets that hit level 25
  local count25 = 0
  for i, petInfo in ipairs(payload.pets) do
    if utils then 
      utils:debug(string.format("[CELEB] Pet %d: oldLevel=%d, newLevel=%d", i, petInfo.oldLevel, petInfo.newLevel))
    end
    if petInfo.newLevel == 25 then
      table.insert(pendingCelebrations, petInfo.petID)
      count25 = count25 + 1
      if utils then
        utils:debug(string.format("[CELEB] Pet hit 25! Added to pending, count=%d", count25))
      end
    end
  end
  
  if utils then
    utils:debug(string.format("[CELEB] Total pending celebrations: %d", #pendingCelebrations))
  end
  
  -- Subscribe to CONSOLE_MESSAGE to show popup after battle UI closes
  if #pendingCelebrations > 0 and not consoleMessageSubId then
    consoleMessageSubId = events:subscribe("CONSOLE_MESSAGE", onConsoleMessage)
    if utils then
      utils:debug("[CELEB] Subscribed to CONSOLE_MESSAGE")
    end
  end
end

-- ============================================================================
-- LEVEL 25 CELEBRATION POPUP
-- ============================================================================

--[[
  Create a graduate display zone (just the pet model and celebration focus)
  
  @param parent Frame - Parent container
  @param gradData table - Graduate pet data
  @return Frame - Graduate zone
]]
local function createGraduateZone(parent, gradData)
  local L = LAYOUT
  local zone = CreateFrame("Frame", nil, parent)
  zone:SetSize(L.GRAD_ZONE_WIDTH, L.GRAD_ZONE_HEIGHT)
  
  -- Graduate model
  local modelFactory = Addon.modelFactory
  local model, controls
  if modelFactory then
    model, controls = modelFactory:create(zone, L.GRAD_MODEL_SIZE, 180)
    model:SetPoint("TOP", 0, 0)
    
    -- Disable mouse on model so parent zone receives hover events (for carousel pause)
    model:EnableMouse(false)
    
    if gradData.petID and modelFactory:setPet(model, gradData.petID) then
      -- Normalize model scale for consistent sizing across different pets
      controls:normalizeScale(1.8)
      
      -- Enable periodic rotation for subtle life
      controls:enableRotation({
        minAngle = -20,
        maxAngle = 20,
        duration = {1.5, 2.5},
        mode = "periodic",
        initialDelay = {3, 8},
        interval = {5, 15},
      })
    end
  end
  
  -- Graduate name (with rarity color and breed)
  local gradColorCode = string.format("|cff%02x%02x%02x",
    math.floor(gradData.rarityColor.r * 255),
    math.floor(gradData.rarityColor.g * 255),
    math.floor(gradData.rarityColor.b * 255))
  local gradFullName = gradColorCode .. gradData.name
  if gradData.breed and gradData.breed ~= "" then
    local dimR = math.floor(gradData.rarityColor.r * 0.75 * 255)
    local dimG = math.floor(gradData.rarityColor.g * 0.75 * 255)
    local dimB = math.floor(gradData.rarityColor.b * 0.75 * 255)
    gradFullName = gradFullName .. string.format(" |cff%02x%02x%02x(%s)", dimR, dimG, dimB, gradData.breed)
  end
  gradFullName = gradFullName .. "|r"
  
  local name = zone:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  name:SetPoint("TOP", model, "BOTTOM", 0, -2)
  name:SetWidth(L.GRAD_ZONE_WIDTH + 40)  -- Wider to prevent breed wrapping
  name:SetFont(name:GetFont(), 16)  -- Notably larger than next-up names (12pt)
  name:SetText(gradFullName)
  
  -- Graduate details
  local details = zone:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  details:SetPoint("TOP", name, "BOTTOM", 0, -2)
  details:SetTextColor(0.7, 0.7, 0.7)
  details:SetFont(details:GetFont(), 12)  -- Proportional to larger name
  details:SetText(string.format("Level %d - %s", gradData.level, gradData.familyName))
  
  zone.model = model
  zone.modelControls = controls
  zone.name = name
  zone.details = details
  
  return zone
end

--[[
  Create a next-up display with split button
  
  @param parent Frame - Parent container
  @param nextData table - Next-up pet data
  @param targetSlot number - Target slot for quick slot
  @param gradName string - Name of graduate being replaced
  @param zoneWidth number|nil - Optional width override
  @return Frame - Next-up zone with embedded button
]]
local function createNextUpZone(parent, nextData, targetSlot, gradName, zoneWidth)
  local L = LAYOUT
  local ZONE_PADDING = 12
  local width = zoneWidth or L.NEXTUP_ZONE_WIDTH
  
  -- Main container with darker background for visual separation
  local zone = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  zone:SetSize(width, L.NEXTUP_ZONE_HEIGHT)
  zone:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  zone:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
  zone:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
  
  -- Horizontal layout: [padding][icon][gap][name/details][gap][button][padding]
  local iconSize = L.NEXTUP_ICON_SIZE
  
  -- Pet icon on left, vertically centered
  local icon = zone:CreateTexture(nil, "ARTWORK")
  icon:SetSize(iconSize, iconSize)
  icon:SetPoint("LEFT", zone, "LEFT", ZONE_PADDING, 0)
  icon:SetTexture(nextData.icon)
  
  -- Rarity border around icon
  local iconBorder = zone:CreateTexture(nil, "OVERLAY")
  iconBorder:SetSize(iconSize + 4, iconSize + 4)
  iconBorder:SetPoint("CENTER", icon, "CENTER", 0, 0)
  iconBorder:SetTexture("Interface\\Common\\WhiteIconFrame")
  iconBorder:SetVertexColor(nextData.rarityColor.r, nextData.rarityColor.g, nextData.rarityColor.b, 1)
  
  -- Next-up name (with rarity color and breed) - centered vertically on icon
  local nextColorCode = string.format("|cff%02x%02x%02x",
    math.floor(nextData.rarityColor.r * 255),
    math.floor(nextData.rarityColor.g * 255),
    math.floor(nextData.rarityColor.b * 255))
  local nextFullName = nextColorCode .. nextData.name
  if nextData.breed and nextData.breed ~= "" then
    local dimR = math.floor(nextData.rarityColor.r * 0.75 * 255)
    local dimG = math.floor(nextData.rarityColor.g * 0.75 * 255)
    local dimB = math.floor(nextData.rarityColor.b * 0.75 * 255)
    nextFullName = nextFullName .. string.format(" |cff%02x%02x%02x(%s)", dimR, dimG, dimB, nextData.breed)
  end
  nextFullName = nextFullName .. "|r"
  
  local name = zone:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  name:SetPoint("LEFT", icon, "RIGHT", 12, 8)  -- Offset up from icon center
  name:SetPoint("RIGHT", zone, "RIGHT", -175, 0)  -- Leave room for button
  name:SetJustifyH("LEFT")
  name:SetText(nextFullName)
  name:SetFont(name:GetFont(), 12)
  
  -- Next-up details - below name, still aligned with icon center area
  local details = zone:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  details:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
  details:SetJustifyH("LEFT")
  details:SetTextColor(0.6, 0.6, 0.6)
  details:SetText(string.format("Level %d - %s", nextData.level, nextData.familyName))
  details:SetFont(details:GetFont(), 11)
  
  -- Right side: Split button
  -- Build dropdown options showing all 3 team slots
  local dropdownOptions = {}
  for slot = 1, 3 do
    local slotPetID = C_PetJournal.GetPetLoadOutInfo(slot)
    if slotPetID then
      local _, customName, level, _, _, _, _, petName, petIcon, petType = C_PetJournal.GetPetInfoByPetID(slotPetID)
      local displayName = customName or petName or "Pet"
      local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(slotPetID)
      rarity = rarity or 2
      
      local breedText = ""
      if Addon.breedDetection then
        local breedID, confidence, detectedBreedName = Addon.breedDetection:detectBreedByPetID(slotPetID)
        if detectedBreedName then
          breedText = " (" .. detectedBreedName .. ")"
        end
      end
      
      local rarityColor = constants and constants:GetRarityColor(rarity) or {r=1, g=1, b=1}
      
      local familyName = "Unknown"
      if constants and constants.PET_FAMILY_NAMES and petType then
        familyName = constants.PET_FAMILY_NAMES[petType] or "Unknown"
      end
      
      table.insert(dropdownOptions, {
        value = slot,
        icon = petIcon,
        isGradSlot = (slot == targetSlot),
        text = string.format("Slot %d: %s", slot, displayName),  -- Fallback text
        -- Custom data for renderRow
        slot = slot,
        petName = displayName,
        breed = breedText,
        level = level,
        familyName = familyName,
        rarityColor = rarityColor,
      })
    end
  end
  
  -- Custom row renderer for slot dropdown
  local function renderSlotRow(row, option, isHighlighted)
    -- Clear existing custom elements
    if row.slotLabel then row.slotLabel:SetText("") end
    if row.petName then row.petName:SetText("") end
    if row.petDetails then row.petDetails:SetText("") end
    
    -- Create slot label if needed (left side, after icon)
    if not row.slotLabel then
      row.slotLabel = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      row.slotLabel:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
      row.slotLabel:SetJustifyH("LEFT")
    end
    
    -- Create pet name if needed (right of slot label, upper line)
    if not row.petName then
      row.petName = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      row.petName:SetPoint("LEFT", row.slotLabel, "RIGHT", 8, 7)
      row.petName:SetPoint("RIGHT", row, "RIGHT", -8, 0)
      row.petName:SetJustifyH("LEFT")
    end
    
    -- Create details line if needed (below pet name)
    if not row.petDetails then
      row.petDetails = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      row.petDetails:SetPoint("TOPLEFT", row.petName, "BOTTOMLEFT", 0, -2)
      row.petDetails:SetPoint("RIGHT", row, "RIGHT", -8, 0)
      row.petDetails:SetJustifyH("LEFT")
      row.petDetails:SetTextColor(0.6, 0.6, 0.6)
    end
    
    -- Hide default text and level overlay (we show level in details line)
    if row.text then row.text:Hide() end
    if row.levelBG then row.levelBG:Hide() end
    if row.levelText then row.levelText:Hide() end
    
    -- Set slot label
    local slotColor = option.isGradSlot and "|cffFFD700" or "|cff888888"
    row.slotLabel:SetText(slotColor .. "Slot " .. option.slot .. "|r")
    
    -- Set pet name with rarity color and breed
    local rarityCode = string.format("|cff%02x%02x%02x",
      math.floor(option.rarityColor.r * 255),
      math.floor(option.rarityColor.g * 255),
      math.floor(option.rarityColor.b * 255))
    row.petName:SetText(rarityCode .. option.petName .. option.breed .. "|r")
    
    -- Set details
    row.petDetails:SetText(string.format("Level %d - %s", option.level, option.familyName))
  end
  
  -- Create split button
  local splitBtn
  if dropdownLegacy then
    splitBtn = dropdownLegacy:createCustom({
      parent = zone,
      width = 150,
      height = 32,
      iconSize = 40,
      rowHeight = 48,
      splitButton = true,
      defaultValue = targetSlot,
      options = dropdownOptions,
      placeholder = "Quick Slot",
      renderRow = renderSlotRow,
      onClick = function(self, button)
        -- Main button: Quick slot into target slot
        C_PetJournal.SetPetLoadOutInfo(targetSlot, nextData.petID)
        if utils then
          utils:chat(string.format("%s slotted in position %d", nextData.name, targetSlot))
        end
        if Addon.events then
          Addon.events:emit("LOADOUT:CHANGED", { slot = targetSlot, petID = nextData.petID })
        end
        -- Close celebration popup
        local celebFrame = celebrationFrame
        if celebFrame then
          celebFrame:Hide()
        end
      end,
      onChange = function(chosenSlot)
        -- Dropdown selection: Slot into chosen slot
        C_PetJournal.SetPetLoadOutInfo(chosenSlot, nextData.petID)
        if utils then
          utils:chat(string.format("%s slotted in position %d", nextData.name, chosenSlot))
        end
        if Addon.events then
          Addon.events:emit("LOADOUT:CHANGED", { slot = chosenSlot, petID = nextData.petID })
        end
        -- Close celebration popup
        local celebFrame = celebrationFrame
        if celebFrame then
          celebFrame:Hide()
        end
      end,
    })
    
    -- Add tooltip with hover effects
    if splitBtn and splitBtn.mainBtn then
      splitBtn.mainBtn:SetScript("OnEnter", function(self)
        -- Apply hover style
        if self.bg then
          self.bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)
        end
        if splitBtn.border then
          splitBtn.border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        end
        
        if tooltip then
          tooltip:show(self, "ANCHOR_TOP")
          tooltip:header("Quick Slot")
          tooltip:space(6)
          tooltip:row("Replacing:", gradName)
          tooltip:row("With:", nextData.name)
          tooltip:row("In Slot:", tostring(targetSlot), {rightColor = {0.4, 0.8, 1}})
          tooltip:space(6)
          tooltip:text("Click to slot immediately", {color = {0.5, 0.5, 0.5}})
          tooltip:done()
        end
      end)
      splitBtn.mainBtn:SetScript("OnLeave", function(self)
        -- Reset hover style
        if self.bg then
          self.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        end
        if splitBtn.border then
          splitBtn.border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        end
        if tooltip then tooltip:hide() end
      end)
    end
    
    splitBtn:ClearAllPoints()
    splitBtn:SetPoint("RIGHT", zone, "RIGHT", -ZONE_PADDING, 0)
  end
  
  zone.icon = icon
  zone.name = name
  zone.details = details
  zone.splitBtn = splitBtn
  zone.nextData = nextData
  zone.targetSlot = targetSlot
  
  return zone
end

--[[
  Setup carousel animation for 3 graduates
  - Continuous infinite scroll (zones reposition when off-screen)
  - Smooth constant velocity
  - Pauses on mouse hover (anywhere in carousel area)
  
  @param container Frame - Container holding graduate zones
  @param graduates table - Array of 3 graduate zones
]]
local function setupCarousel(container, graduates)
  local L = LAYOUT
  local zoneWidth = L.GRAD_ZONE_WIDTH
  local zoneGap = 20
  local scrollSpeed = 40  -- Pixels per second
  
  -- Clean up any leftover content frame from previous carousel implementation
  if container.carouselContent then
    container.carouselContent:Hide()
    container.carouselContent:SetParent(nil)
    container.carouselContent = nil
  end
  
  -- Enable clipping so graduates outside visible area are hidden
  container:SetClipsChildren(true)
  
  -- Calculate total content width (3 zones + gaps, for wrap-around calculation)
  local totalWidth = #graduates * (zoneWidth + zoneGap)
  
  -- Position zones in a row, track their X offsets for repositioning
  local zonePositions = {}
  for i, zone in ipairs(graduates) do
    local startX = (i - 1) * (zoneWidth + zoneGap)
    zonePositions[i] = startX
    zone:ClearAllPoints()
    zone:SetPoint("LEFT", container, "LEFT", startX, 0)
    zone:Show()
    zone:EnableMouse(true)
  end
  
  -- Carousel state
  local state = {
    scrollOffset = 0,  -- How far we've scrolled total
    paused = false,
  }
  container.carouselState = state
  
  -- Pause handlers for container
  container:EnableMouse(true)
  container:SetScript("OnEnter", function()
    state.paused = true
  end)
  container:SetScript("OnLeave", function()
    state.paused = false
  end)
  
  -- Pause handlers for each zone (mouse over zone should also pause)
  for _, zone in ipairs(graduates) do
    zone:HookScript("OnEnter", function()
      state.paused = true
    end)
    zone:HookScript("OnLeave", function()
      state.paused = false
    end)
  end
  
  -- Animation update - continuous scroll with repositioning
  container:SetScript("OnUpdate", function(self, dt)
    if not self:IsVisible() then return end
    if state.paused then return end
    
    -- Advance scroll
    state.scrollOffset = state.scrollOffset + scrollSpeed * dt
    
    -- Update each zone's position
    for i, zone in ipairs(graduates) do
      local baseX = zonePositions[i]
      local currentX = baseX - state.scrollOffset
      
      -- If zone scrolled completely off the left, reposition to right
      while currentX < -zoneWidth do
        zonePositions[i] = zonePositions[i] + totalWidth
        currentX = zonePositions[i] - state.scrollOffset
      end
      
      zone:ClearAllPoints()
      zone:SetPoint("LEFT", self, "LEFT", currentX, 0)
    end
  end)
end

--[[
  Create the celebration popup frame (lazy initialization)
]]
local function createCelebrationFrame()
  if celebrationFrame then return celebrationFrame end
  
  local L = LAYOUT
  
  local frame = CreateFrame("Frame", "PAOLevel25Celebration", UIParent, "BackdropTemplate")
  frame:SetPoint("CENTER", 0, 80)
  frame:SetFrameStrata("DIALOG")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  
  -- Gold celebratory border
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 12, right = 12, top = 12, bottom = 12 }
  })
  
  -- Frame-level gold gradient (flows from top down)
  local frameSpotlight = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
  frameSpotlight:SetTexture("Interface\\BUTTONS\\WHITE8X8")
  frameSpotlight:SetBlendMode("ADD")
  frame.frameSpotlight = frameSpotlight
  
  -- Stylized "25" background (positioned behind graduate area)
  local level25bg = frame:CreateFontString(nil, "BACKGROUND")
  level25bg:SetFont("Fonts\\FRIZQT__.TTF", 120, "OUTLINE")
  level25bg:SetText("25")
  level25bg:SetTextColor(1, 0.84, 0, 0.10)  -- Gold, very subtle
  frame.level25bg = level25bg
  
  -- Sparkle container (holds all animated sparkles)
  local sparkleContainer = CreateFrame("Frame", nil, frame)
  sparkleContainer:SetAllPoints(frame)
  sparkleContainer:SetFrameLevel(frame:GetFrameLevel() + 10)
  frame.sparkleContainer = sparkleContainer
  
  -- Pre-create sparkle textures (sizes randomized on each show)
  frame.sparkles = {}
  for i = 1, SPARKLE.COUNT do
    local sparkle = sparkleContainer:CreateTexture(nil, "OVERLAY")
    sparkle:SetSize(SPARKLE.SIZE_MIN, SPARKLE.SIZE_MIN)
    sparkle:SetBlendMode("ADD")
    sparkle:SetVertexColor(1, 0.85, 0.4, 0.8)  -- Gold tint
    sparkle:Hide()
    
    -- Initialize animation state (randomized properly in randomizeSparkles)
    sparkle.baseSize = SPARKLE.SIZE_MIN
    sparkle.rotationSpeed = 0
    sparkle.pulseSpeed = 2
    sparkle.pulsePhase = 0
    sparkle.orbitAngle = 0
    sparkle.orbitRadiusX = 100
    sparkle.orbitRadiusY = 80
    sparkle.orbitSpeed = 0.4
    
    frame.sparkles[i] = sparkle
  end
  
  -- Stop sparkle animation and disable model controls when frame hides
  frame:SetScript("OnHide", function(self)
    sparkleContainer:SetScript("OnUpdate", nil)
    hideSparkles()
    
    -- Disable periodic rotation on graduate models
    if self.graduateZones then
      for _, zone in ipairs(self.graduateZones) do
        if zone.modelControls then
          zone.modelControls:disable()
        end
      end
    end
  end)
  
  -- Container for graduates (used for both single/multiple and carousel)
  local gradContainer = CreateFrame("Frame", nil, frame)
  frame.gradContainer = gradContainer
  
  -- Container for next-ups (stacked vertically below graduates)
  local nextUpContainer = CreateFrame("Frame", nil, frame)
  frame.nextUpContainer = nextUpContainer
  
  -- "Next Up" section header (gold to match celebration theme)
  local nextUpHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  nextUpHeader:SetText("|cffFFD700Next Up|r")
  nextUpHeader:SetJustifyH("LEFT")
  frame.nextUpHeader = nextUpHeader
  
  -- Storage for dynamically created zones
  frame.graduateZones = {}
  frame.nextUpZones = {}
  
  -- Main celebration header (randomized)
  local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  header:SetText("|cffFFD700Level 25!|r")
  header:SetFont(header:GetFont(), 20, "OUTLINE")
  frame.header = header
  
  -- Flavor text
  local flavor = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  flavor:SetTextColor(0.9, 0.85, 0.6)
  frame.flavor = flavor
  
  -- "Slot All" button (for 2+ grads with next-ups)
  local slotAllBtn
  if actionButton then
    slotAllBtn = actionButton:create(frame, {
      text = "Slot All",
      size = "medium",
      style = 3,  -- Rounded style
    })
    slotAllBtn:Hide()
  end
  frame.slotAllBtn = slotAllBtn
  
  -- Close button (PAO styled "Congratulations!")
  local closeBtn
  if actionButton then
    closeBtn = actionButton:create(frame, {
      text = "Congratulations!",
      size = "medium",
      style = 2,  -- Gradient style for prominence
    })
    closeBtn:setTooltip("Close celebration")
    closeBtn:SetScript("OnClick", function()
      frame:Hide()
    end)
  end
  frame.closeBtn = closeBtn
  
  -- ESC to close
  table.insert(UISpecialFrames, "PAOLevel25Celebration")
  
  frame:Hide()
  celebrationFrame = frame
  return frame
end

--[[
  Show the level 25 celebration popup
  
  @param petIDs table - Array of petIDs that reached level 25
]]
showCelebration = function(petIDs)
  if utils then
    utils:debug(string.format("[CELEB] showCelebration called with %d pet(s)", petIDs and #petIDs or 0))
  end
  
  local action = options:Get("level25Action")
  
  if action == "disabled" then 
    if utils then
      utils:debug("[CELEB] Action disabled, not showing")
    end
    return 
  end
  
  if not petIDs or #petIDs == 0 then 
    if utils then
      utils:debug("[CELEB] No petIDs, not showing")
    end
    return 
  end
  
  local frame = createCelebrationFrame()
  
  if not frame then
    if utils then
      utils:debug("[CELEB] Failed to create frame")
    end
    return
  end
  
  if utils then
    utils:debug("[CELEB] Frame created successfully, proceeding with display")
  end
  
  
  local L = LAYOUT
  local count = math.min(#petIDs, 3)
  
  -- ============================================================================
  -- PHASE 1: BUILD GRADUATE DATA
  -- ============================================================================
  
  local graduates = {}
  
  for i = 1, count do
    local petID = petIDs[i]
    
    -- Find which slot this graduate is in
    local gradSlot = nil
    for slot = 1, 3 do
      local slotPetID = C_PetJournal.GetPetLoadOutInfo(slot)
      if slotPetID == petID then
        gradSlot = slot
        break
      end
    end
    
    -- Default to slot i if not found in team
    if not gradSlot then
      gradSlot = i
    end
    
    -- Get graduate pet data
    local speciesID, customName, level, _, _, _, _, petName, petIcon, petType, creatureID = C_PetJournal.GetPetInfoByPetID(petID)
    local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
    rarity = rarity or 2
    
    local breedText = ""
    if Addon.breedDetection then
      local breedID, confidence, detectedBreedName = Addon.breedDetection:detectBreedByPetID(petID)
      if detectedBreedName then
        breedText = detectedBreedName
      end
    end
    
    local rarityColor = constants and constants:GetRarityColor(rarity) or {r=1, g=1, b=1}
    
    local familyName = "Unknown"
    if constants and constants.PET_FAMILY_NAMES and petType then
      familyName = constants.PET_FAMILY_NAMES[petType] or "Unknown"
    end
    
    table.insert(graduates, {
      petID = petID,
      name = customName or petName or "Pet",
      icon = petIcon,
      level = level or 25,
      rarity = rarity,
      rarityColor = rarityColor,
      breed = breedText,
      familyName = familyName,
      petType = petType,
      displayID = creatureID,
      slot = gradSlot,
    })
  end
  
  if utils then
    utils:debug(string.format("[CELEB] Built %d graduates", #graduates))
  end
  
  -- ============================================================================
  -- PHASE 2: BUILD NEXT-UP DATA (separate from graduates)
  -- ============================================================================
  
  local nextUps = {}
  local levelingCelebration = Addon.levelingCelebration
  
  if levelingCelebration and levelingCelebration:isEnabled() then
    -- Get up to count next-up pets (matching graduate count)
    for i = 1, count do
      local nextPetInfo = levelingCelebration:getNextPetInfo()
      if nextPetInfo then
        -- Get full pet data
        local nSpeciesID, nCustomName, nLevel, _, _, _, _, nPetName, nPetIcon, nPetType, nCreatureID = C_PetJournal.GetPetInfoByPetID(nextPetInfo.petID)
        local nHealth, nMaxHealth, nPower, nSpeed, nRarity = C_PetJournal.GetPetStats(nextPetInfo.petID)
        nRarity = nRarity or 2
        
        local nBreedText = ""
        if Addon.breedDetection then
          local nBreedID, nConfidence, nDetectedBreedName = Addon.breedDetection:detectBreedByPetID(nextPetInfo.petID)
          if nDetectedBreedName then
            nBreedText = nDetectedBreedName
          end
        end
        
        local nRarityColor = constants and constants:GetRarityColor(nRarity) or {r=1, g=1, b=1}
        local nFamilyName = nextPetInfo.familyName or "Unknown"
        
        table.insert(nextUps, {
          petID = nextPetInfo.petID,
          name = nCustomName or nPetName or nextPetInfo.name or "Pet",
          icon = nPetIcon or nextPetInfo.icon,
          level = nLevel or nextPetInfo.level or 1,
          rarity = nRarity,
          rarityColor = nRarityColor,
          breed = nBreedText,
          familyName = nFamilyName,
          petType = nPetType,
          displayID = nCreatureID,
          targetSlot = graduates[i].slot,  -- Associate with graduate's slot
        })
      else
        break  -- No more next-ups available
      end
    end
  end
  
  if utils then
    utils:debug(string.format("[CELEB] Built %d next-ups", #nextUps))
  end
  
  -- ============================================================================
  -- PHASE 3: CREATE AND LAYOUT GRADUATE DISPLAY
  -- ============================================================================
  
  -- Destroy old zones (not just hide - prevents accumulation)
  if frame.graduateZones then
    for _, zone in ipairs(frame.graduateZones) do
      if zone.modelControls then
        zone.modelControls:disable()
      end
      zone:Hide()
      zone:SetParent(nil)  -- Orphan for GC
    end
  end
  frame.graduateZones = {}
  
  -- Clear carousel state
  if frame.gradContainer.carouselState then
    frame.gradContainer:SetScript("OnUpdate", nil)
    frame.gradContainer:SetScript("OnEnter", nil)
    frame.gradContainer:SetScript("OnLeave", nil)
    frame.gradContainer.carouselState = nil
  end
  frame.gradContainer:SetClipsChildren(false)  -- Reset clipping
  
  -- Determine layout mode
  -- Frame width must accommodate both graduate display and next-up zone
  local minWidthForNextUp = L.NEXTUP_ZONE_WIDTH + L.POPUP_PADDING * 2
  local frameWidth
  local gradContainerWidth, gradContainerHeight = L.GRAD_ZONE_WIDTH, L.GRAD_ZONE_HEIGHT
  
  if #graduates == 1 then
    -- Single graduate: shrink-wrap to next-up section width
    if #nextUps > 0 then
      frameWidth = minWidthForNextUp
    else
      -- No next-ups: narrower frame for just the grad zone
      frameWidth = math.max(320, L.GRAD_ZONE_WIDTH + L.POPUP_PADDING * 2)
    end
    gradContainerWidth = L.GRAD_ZONE_WIDTH
  elseif #graduates == 2 then
    -- Two graduates: side by side
    frameWidth = math.max(550, minWidthForNextUp)
    gradContainerWidth = L.GRAD_ZONE_WIDTH * 2 + 40
  else
    -- Three graduates: carousel with 2.5 visible
    frameWidth = math.max(550, minWidthForNextUp)
    gradContainerWidth = L.GRAD_ZONE_WIDTH * L.CAROUSEL_VISIBLE_RATIO
  end
  
  frame.gradContainer:SetSize(gradContainerWidth, gradContainerHeight)
  frame.gradContainer:ClearAllPoints()
  frame.gradContainer:SetPoint("TOP", frame, "TOP", 0, -L.POPUP_PADDING - L.HEADER_HEIGHT - L.HEADER_TO_FLAVOR_GAP - L.FLAVOR_HEIGHT - L.FLAVOR_TO_CONTENT_GAP)
  
  -- Create graduate zones
  for i, gradData in ipairs(graduates) do
    local zone = createGraduateZone(frame.gradContainer, gradData)
    table.insert(frame.graduateZones, zone)
    
    -- Position based on count
    if #graduates == 1 then
      zone:SetPoint("CENTER", frame.gradContainer, "CENTER", 0, 0)
    elseif #graduates == 2 then
      if i == 1 then
        zone:SetPoint("RIGHT", frame.gradContainer, "CENTER", -20, 0)
      else
        zone:SetPoint("LEFT", frame.gradContainer, "CENTER", 20, 0)
      end
    else
      -- Carousel positioning (will be animated)
      zone:SetPoint("LEFT", frame.gradContainer, "LEFT", (i - 1) * (L.GRAD_ZONE_WIDTH + 20), 0)
    end
    
    zone:Show()
  end
  
  -- Setup carousel if 3 graduates
  if #graduates == 3 then
    setupCarousel(frame.gradContainer, frame.graduateZones)
  end
  
  -- ============================================================================
  -- PHASE 4: CREATE AND LAYOUT NEXT-UP DISPLAY
  -- ============================================================================
  
  -- Destroy old next-up zones
  if frame.nextUpZones then
    for _, zone in ipairs(frame.nextUpZones) do
      zone:Hide()
      zone:SetParent(nil)  -- Orphan for GC
    end
  end
  frame.nextUpZones = {}
  
  local nextUpSectionHeight = 0
  local NEXTUP_HEADER_HEIGHT = 16
  local NEXTUP_HEADER_GAP = 6
  
  if #nextUps > 0 then
    -- Use POPUP_PADDING for consistent side padding
    local nextUpLeftEdge = L.POPUP_PADDING
    local nextUpWidth = frameWidth - L.POPUP_PADDING * 2
    
    -- Calculate vertical position below grad container
    local nextUpTopOffset = L.POPUP_PADDING + L.HEADER_HEIGHT + L.HEADER_TO_FLAVOR_GAP + L.FLAVOR_HEIGHT + L.FLAVOR_TO_CONTENT_GAP + gradContainerHeight + L.SECTION_SEPARATOR_HEIGHT
    
    -- Position "Next Up" section header, left-aligned with padding
    frame.nextUpHeader:ClearAllPoints()
    frame.nextUpHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", nextUpLeftEdge, -nextUpTopOffset)
    frame.nextUpHeader:Show()
    
    -- Position next-up container below header, matching padding
    frame.nextUpContainer:ClearAllPoints()
    frame.nextUpContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", nextUpLeftEdge, -(nextUpTopOffset + NEXTUP_HEADER_HEIGHT + NEXTUP_HEADER_GAP))
    
    -- Create next-up zones (stacked vertically, full width minus padding)
    for i, nextData in ipairs(nextUps) do
      local gradName = graduates[i].name
      local zone = createNextUpZone(frame.nextUpContainer, nextData, nextData.targetSlot, gradName, nextUpWidth)
      table.insert(frame.nextUpZones, zone)
      
      zone:ClearAllPoints()
      if i == 1 then
        zone:SetPoint("TOPLEFT", frame.nextUpContainer, "TOPLEFT", 0, 0)
      else
        zone:SetPoint("TOPLEFT", frame.nextUpZones[i-1], "BOTTOMLEFT", 0, -L.NEXTUP_SECTION_GAP)
      end
      
      zone:Show()
    end
    
    nextUpSectionHeight = NEXTUP_HEADER_HEIGHT + NEXTUP_HEADER_GAP + #nextUps * L.NEXTUP_ZONE_HEIGHT + (#nextUps - 1) * L.NEXTUP_SECTION_GAP
    frame.nextUpContainer:SetSize(nextUpWidth, #nextUps * L.NEXTUP_ZONE_HEIGHT + (#nextUps - 1) * L.NEXTUP_SECTION_GAP)
    frame.nextUpContainer:Show()
  else
    frame.nextUpHeader:Hide()
    frame.nextUpContainer:Hide()
  end
  
  -- Select random header and flavor text
  local flavorPool = (#graduates == 1) and FLAVOR_TEXTS_SINGLE or FLAVOR_TEXTS_MULTIPLE
  local headerText = CELEBRATION_HEADERS[math.random(#CELEBRATION_HEADERS)]
  local flavorText = flavorPool[math.random(#flavorPool)]
  
  -- Re-roll if both contain "legend"
  local headerHasLegend = headerText:lower():find("legend")
  local flavorHasLegend = flavorText:lower():find("legend")
  if headerHasLegend and flavorHasLegend then
    for _ = 1, 10 do
      flavorText = flavorPool[math.random(#flavorPool)]
      if not flavorText:lower():find("legend") then
        break
      end
    end
  end
  
  frame.header:SetText("|cffFFD700" .. headerText .. "|r")
  frame.flavor:SetText(flavorText)
  
  -- Position header at top
  frame.header:ClearAllPoints()
  frame.header:SetPoint("TOP", frame, "TOP", 0, -L.POPUP_PADDING)
  
  -- Position flavor below header
  frame.flavor:ClearAllPoints()
  frame.flavor:SetPoint("TOP", frame.header, "BOTTOM", 0, -L.HEADER_TO_FLAVOR_GAP)
  frame.flavor:SetWidth(frameWidth - L.POPUP_PADDING * 2)
  
  local flavorHeight = frame.flavor:GetStringHeight() or L.FLAVOR_HEIGHT
  
  -- Position grad container
  local gradTopOffset = L.POPUP_PADDING + L.HEADER_HEIGHT + L.HEADER_TO_FLAVOR_GAP + flavorHeight + L.FLAVOR_TO_CONTENT_GAP
  frame.gradContainer:ClearAllPoints()
  frame.gradContainer:SetPoint("TOP", frame, "TOP", 0, -gradTopOffset)
  
  -- Recalculate next-up position if present
  if #nextUps > 0 then
    local NEXTUP_HEADER_HEIGHT = 16
    local NEXTUP_HEADER_GAP = 6
    local nextUpTopOffset = gradTopOffset + gradContainerHeight + L.SECTION_SEPARATOR_HEIGHT
    local nextUpWidth = frameWidth - L.POPUP_PADDING * 2
    
    frame.nextUpHeader:ClearAllPoints()
    frame.nextUpHeader:SetPoint("TOPLEFT", frame, "TOPLEFT", L.POPUP_PADDING, -nextUpTopOffset)
    
    frame.nextUpContainer:ClearAllPoints()
    frame.nextUpContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", L.POPUP_PADDING, -(nextUpTopOffset + NEXTUP_HEADER_HEIGHT + NEXTUP_HEADER_GAP))
  end
  
  -- Calculate frame height
  local contentHeight = gradTopOffset + gradContainerHeight
  if #nextUps > 0 then
    contentHeight = contentHeight + L.SECTION_SEPARATOR_HEIGHT + nextUpSectionHeight + L.NEXTUP_TO_BUTTON_GAP
  else
    contentHeight = contentHeight + 20  -- Space before button when no next-ups
  end
  contentHeight = contentHeight + L.BUTTON_HEIGHT + L.POPUP_PADDING
  
  -- Set frame size
  frame:SetSize(frameWidth, contentHeight)
  
  -- Position frame-level spotlight (starts at top, fades down through graduate area)
  -- Goes edge to edge (no padding) for full effect
  local spotlightHeight = gradTopOffset + gradContainerHeight
  frame.frameSpotlight:ClearAllPoints()
  frame.frameSpotlight:SetPoint("TOP", frame, "TOP", 0, -12)  -- Just inside border
  frame.frameSpotlight:SetSize(frameWidth - 24, spotlightHeight)  -- Full width minus border insets
  local goldTop = {r=1, g=0.84, b=0, a=0.18}
  local goldBottom = {r=1, g=0.84, b=0, a=0}
  frame.frameSpotlight:SetGradient("VERTICAL", goldBottom, goldTop)
  
  -- Position stylized "25" behind graduate area
  frame.level25bg:ClearAllPoints()
  frame.level25bg:SetPoint("CENTER", frame.gradContainer, "CENTER", 0, 10)
  
  -- Configure sparkle orbit radius
  local halfWidth = frameWidth / 2 + 15
  local halfHeight = contentHeight / 2 + 15
  for _, sparkle in ipairs(frame.sparkles) do
    sparkle.orbitRadiusX = halfWidth + 20 + math.random() * 15
    sparkle.orbitRadiusY = halfHeight + 20 + math.random() * 15
  end
  
  -- ============================================================================
  -- BUTTONS
  -- ============================================================================
  
  -- Position buttons at bottom
  -- Split buttons are already embedded in next-up zones
  
  if #nextUps == 0 then
    -- No next-ups: just show close button centered
    frame.slotAllBtn:Hide()
    frame.closeBtn:ClearAllPoints()
    frame.closeBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, L.POPUP_PADDING)
  else
    -- 1+ next-ups: show Slot All button + close button for consistency
    frame.slotAllBtn:Show()
    
    -- Setup Slot All handler
    frame.slotAllBtn:SetScript("OnClick", function()
      for _, zone in ipairs(frame.nextUpZones) do
        C_PetJournal.SetPetLoadOutInfo(zone.targetSlot, zone.nextData.petID)
        if utils then
          utils:chat(string.format("%s slotted in position %d", zone.nextData.name, zone.targetSlot))
        end
      end
      if Addon.events then
        local slots = {}
        for _, zone in ipairs(frame.nextUpZones) do
          table.insert(slots, { slot = zone.targetSlot, petID = zone.nextData.petID })
        end
        Addon.events:emit("LOADOUT:CHANGED", { slots = slots })
      end
      frame:Hide()
    end)
    
    -- Set styled tooltip based on count
    frame.slotAllBtn:SetScript("OnEnter", function(self)
      -- Apply hover style
      if self.bg then
        self.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
      end
      
      if tooltip then
        tooltip:show(self, "ANCHOR_TOP")
        tooltip:header("Slot All")
        tooltip:space(6)
        
        if #nextUps == 1 then
          local zone = frame.nextUpZones[1]
          tooltip:row("Slotting:", zone.nextData.name)
          tooltip:row("Into Slot:", tostring(zone.targetSlot), {rightColor = {0.4, 0.8, 1}})
        else
          for i, zone in ipairs(frame.nextUpZones) do
            tooltip:row(string.format("Slot %d:", zone.targetSlot), zone.nextData.name, {leftColor = {0.4, 0.8, 1}})
          end
        end
        
        tooltip:space(6)
        tooltip:text("Click to slot all at once", {color = {0.5, 0.5, 0.5}})
        tooltip:done()
      end
    end)
    
    frame.slotAllBtn:SetScript("OnLeave", function(self)
      -- Reset hover style
      if self.bg then
        self.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
      end
      if tooltip then tooltip:hide() end
    end)
    
    -- Position side by side
    frame.slotAllBtn:ClearAllPoints()
    frame.slotAllBtn:SetPoint("BOTTOM", frame, "BOTTOM", -60, L.POPUP_PADDING)
    frame.closeBtn:ClearAllPoints()
    frame.closeBtn:SetPoint("BOTTOM", frame, "BOTTOM", 60, L.POPUP_PADDING)
  end
  
  -- Play celebration sound
  PlaySound(SOUNDS.CELEBRATION, "SFX")
  
  -- Play "dun dun" sound after fanfare randomly (30% chance)
  if math.random() <= 0.30 then
    C_Timer.After(DUN_DUN_DELAY, function()
      PlaySoundFile(SOUND_FILES.DUN_DUN, "SFX")
    end)
  end
  
  -- Randomize sparkles for fresh animation
  randomizeSparkles()
  frame.sparkleElapsed = 0
  
  -- Position and show sparkles
  for _, sparkle in ipairs(frame.sparkles) do
    sparkle:ClearAllPoints()
    sparkle:SetPoint("CENTER", frame, "CENTER", 0, 0)
    sparkle:Show()
  end
  
  -- Start sparkle animation
  frame.sparkleContainer:SetScript("OnUpdate", sparkleOnUpdate)
  
  -- Show with fade in
  frame:SetAlpha(0)
  frame:Show()
  fadeInElapsed = 0
  frame:SetScript("OnUpdate", fadeInOnUpdate)
  
end

-- ============================================================================
-- PUBLIC API (FOR TESTING)
-- ============================================================================

function notifications:testCelebration(petCount)
  petCount = petCount or 1
  petCount = math.max(1, math.min(3, tonumber(petCount) or 1))
  
  -- Gather pet IDs from team slots
  local petIDs = {}
  for slot = 1, petCount do
    local slotPetID = C_PetJournal.GetPetLoadOutInfo(slot)
    if slotPetID then
      table.insert(petIDs, slotPetID)
    end
  end
  
  if #petIDs == 0 then
    if utils then
      utils:chat("No pets in team slots to test celebration")
    end
    return
  end
  
  if utils then
    utils:chat(string.format("Testing celebration with %d pet(s)", #petIDs))
  end
  
  -- Temporarily override leveling celebration methods for testing
  local levelingCelebration = Addon.levelingCelebration
  if levelingCelebration then
    local originalGetNextPet = levelingCelebration.getNextPetInfo
    local originalIsEnabled = levelingCelebration.isEnabled
    local originalGetRemaining = levelingCelebration.getRemainingCount
    
    -- Override to always return enabled
    levelingCelebration.isEnabled = function()
      return true
    end
    
    -- Override to always return a count
    levelingCelebration.getRemainingCount = function()
      return 100
    end
    
    levelingCelebration.getNextPetInfo = function()
      -- Find first available pet that's not in the test slots
      local testPetID = nil
      for slot = petCount + 1, 3 do
        testPetID = C_PetJournal.GetPetLoadOutInfo(slot)
        if testPetID then break end
      end
      
      -- Fallback: use slot 2 or 3 if available
      if not testPetID then
        testPetID = C_PetJournal.GetPetLoadOutInfo(2) or C_PetJournal.GetPetLoadOutInfo(3)
      end
      
      if not testPetID then return nil end
      
      local speciesID, customName, level, _, _, _, _, petName, petIcon, petType = C_PetJournal.GetPetInfoByPetID(testPetID)
      local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(testPetID)
      
      local familyNames = {"Humanoid", "Dragonkin", "Flying", "Undead", "Critter", "Magic", "Elemental", "Beast", "Aquatic", "Mechanical"}
      
      return {
        petID = testPetID,
        name = customName or petName or "Unknown",
        icon = petIcon,
        level = level or 1,
        familyName = familyNames[petType] or "Unknown",
        queueName = "Test Queue",
        isRare = (rarity == 4),
      }
    end
    
    showCelebration(petIDs)
    
    -- Restore original functions after a delay
    C_Timer.After(0.1, function()
      levelingCelebration.getNextPetInfo = originalGetNextPet
      levelingCelebration.isEnabled = originalIsEnabled
      levelingCelebration.getRemainingCount = originalGetRemaining
    end)
  else
    showCelebration(petIDs)
  end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

--[[
  Initialize notifications module.
  Subscribes to relevant events.
  
  @return boolean - true if successful
]]
function notifications:initialize()
  utils = Addon.utils
  events = Addon.events
  options = Addon.options
  dropdownLegacy = Addon.dropdownLegacy
  constants = Addon.constants
  actionButton = Addon.actionButton
  tooltip = Addon.tooltip
  local commands = Addon.commands
  
  if not utils or not events or not options or not constants then
    print("|cff33ff99PAO|r: |cffff4444notifications: Missing dependencies|r")
    return false
  end
  
  -- Register test command
  if commands then
    commands:register({
      command = "celeb",
      handler = function(args) 
        local petCount = args.count and tonumber(args.count) or 1
        notifications:testCelebration(petCount)
      end,
      help = "Test celebration popup with N pets (1-3)",
      usage = "celeb [count]",
      args = {
        {name = "count", required = false, description = "Number of graduating pets (1-3)"}
      },
      category = "Debug"
    })
    
    commands:register({
      command = "testevent",
      handler = function()
        local slot1PetID = C_PetJournal.GetPetLoadOutInfo(1)
        if not slot1PetID then
          utils:chat("No pet in slot 1")
          return
        end
        
        utils:chat("Firing CACHE:PETS_LEVELED event")
        events:emit("CACHE:PETS_LEVELED", {
          pets = {
            {petID = slot1PetID, oldLevel = 24, newLevel = 25}
          }
        })
      end,
      help = "Test PETS_LEVELED event",
      usage = "testevent",
      category = "Debug"
    })
  end
  
  -- Subscribe to cache event for leveled pets
  events:subscribe("CACHE:PETS_LEVELED", onPetsLeveled)
  
  -- CONSOLE_MESSAGE subscribed dynamically when a pet hits 25
  
  return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
  Addon.registerModule("notifications", {"utils", "events", "options", "dropdownLegacy", "constants", "modelFactory", "actionButton", "tooltip"}, function()
    return notifications:initialize()
  end)
end

Addon.notifications = notifications
return notifications