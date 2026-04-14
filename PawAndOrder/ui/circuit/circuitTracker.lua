--[[
  ui/circuit/circuitTracker.lua
  Circuit Progress Tracker Bar
  
  Provides a draggable progress tracker that displays current circuit status, target NPC,
  upcoming waypoints, and control buttons. Saves position between sessions and provides
  travel prompts for continent transitions.
  
  This is circuit-specific UI that communicates with the circuit logic layer via the
  persistence and constants modules, maintaining proper separation of concerns.
  
  Dependencies: utils, constants, petUtils, circuitPersistence, circuitConstants, 
                waypoint, location, npcUtils, tooltip
  Exports: Addon.circuitTracker
]]

local addonName, Addon = ...

Addon.circuitTracker = {}
local circuitTracker = Addon.circuitTracker


-- Tracker frame reference
local trackerFrame = nil

-- DMF status cache (avoids repeated API calls)
local dmfCache = {
  isActive = nil,
  activeExpiry = 0,       -- Unix timestamp when active cache expires (60s)
  nextFaire = nil,
  nextFaireExpiry = 0,    -- Unix timestamp when next faire cache expires (300s)
}

--[[
  Create the tracker frame
  Builds a draggable frame with progress text, current target, upcoming waypoints,
  and control buttons. Restores saved position from previous session.
  
  @return Frame - The created tracker frame
]]
function circuitTracker:create()
  -- Register for circuit events
  if Addon.events then
    Addon.events:subscribe("CIRCUIT:CANCELLED", function() self:hide() end, circuitTracker)
    Addon.events:subscribe("CIRCUIT:COMPLETED", function() self:hide() end, circuitTracker)
    Addon.events:subscribe("CIRCUIT:STATE_CHANGED", function() self:update() end, circuitTracker)
    
    -- Update buff icons when item info loads (handles login race condition)
    Addon.events:subscribe("GET_ITEM_INFO_RECEIVED", function()
      if trackerFrame and trackerFrame:IsShown() then
        self:updateBuffButtons()
      end
    end, circuitTracker)
    
    -- Update buff buttons when player buffs change (throttled to avoid spam)
    local lastBuffUpdate = 0
    Addon.events:subscribe("UNIT_AURA", function(event, unit)
      if unit == "player" and trackerFrame and trackerFrame:IsShown() then
        local now = GetTime()
        if now - lastBuffUpdate > 0.5 then
          lastBuffUpdate = now
          self:updateBuffButtons()
        end
      end
    end, circuitTracker)
    
    -- Update buff buttons when bags change (purchasing consumables)
    local lastBagUpdate = 0
    Addon.events:subscribe("BAG_UPDATE", function()
      if trackerFrame and trackerFrame:IsShown() then
        local now = GetTime()
        if now - lastBagUpdate > 0.5 then
          lastBagUpdate = now
          self:updateBuffButtons()
        end
      end
    end, circuitTracker)
    
    -- Update buff buttons when player auras change
    local lastAuraUpdate = 0
    Addon.events:subscribe("UNIT_AURA", function(unit)
      if unit == "player" and trackerFrame and trackerFrame:IsShown() then
        local now = GetTime()
        if now - lastAuraUpdate > 0.2 then
          lastAuraUpdate = now
          self:updateBuffButtons()
        end
      end
    end, circuitTracker)
  end
  
  -- Pre-request item info for buff items (triggers async load)
  if Addon.constants and Addon.constants.XP_BUFF then
    for _, itemId in pairs(Addon.constants.XP_BUFF.ITEM_IDS) do
      GetItemInfo(itemId)
    end
  end
  
  local constants = Addon.circuitConstants
  local persistence = Addon.circuitPersistence
  local ui = constants.UI
  local pad = ui.TRACKER_PADDING
  local rowH = ui.TRACKER_ROW_HEIGHT
  local rowGap = ui.TRACKER_ROW_GAP
  
  -- Calculate minimum width to fit lesser charm message on one line
  -- Uses same font as logger (GameFontNormalSmall) for accurate measurement
  local measureFrame = CreateFrame("Frame", nil, UIParent)
  local measureText = measureFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  measureText:SetText("Received [Lesser Charm of Good Fortune] x2")
  local textWidth = measureText:GetStringWidth()
  measureFrame:Hide()
  
  -- Required width = text + timestamp column (36) + log padding (16*2)
  local requiredWidth = textWidth + 68
  if requiredWidth > ui.TRACKER_WIDTH then
    ui.TRACKER_WIDTH = requiredWidth
  end
  
  -- Create frame
  trackerFrame = CreateFrame("Frame", "PAOCircuitTracker", UIParent, "BackdropTemplate")
  if not trackerFrame then
    Addon.utils:debug("circuitTracker:create - Failed to create tracker frame")
    return nil
  end
  
  trackerFrame:SetSize(ui.TRACKER_WIDTH, ui.TRACKER_HEIGHT)
  trackerFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
  })
  trackerFrame:SetBackdropColor(0, 0, 0, 1)
  trackerFrame:Hide()
  trackerFrame:SetMovable(true)
  trackerFrame:EnableMouse(true)
  trackerFrame:RegisterForDrag("LeftButton")
  trackerFrame:SetScript("OnDragStart", trackerFrame.StartMoving)
  trackerFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    persistence:saveTrackerPosition({ point = point, relativePoint = relativePoint, x = xOfs, y = yOfs })
  end)
  
  -- Position
  local savedPos = persistence:getTrackerPosition()
  if savedPos then
    trackerFrame:SetPoint(savedPos.point, UIParent, savedPos.relativePoint, savedPos.x, savedPos.y)
  else
    trackerFrame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", ui.TRACKER_DEFAULT_X, ui.TRACKER_DEFAULT_Y)
  end
  
  --
  -- ROW 1-2 LEFT: Family Icon (for fabled only, spans both rows)
  --
  local row1Top = -pad
  local twoRowHeight = (rowH * 2) + rowGap
  local familyIconY = row1Top - ((twoRowHeight - ui.FAMILY_ICON_SIZE) / 2)
  
  local familyIcon = trackerFrame:CreateTexture(nil, "ARTWORK")
  familyIcon:SetSize(ui.FAMILY_ICON_SIZE, ui.FAMILY_ICON_SIZE)
  familyIcon:SetPoint("TOPLEFT", trackerFrame, "TOPLEFT", pad, familyIconY)
  familyIcon:Hide()
  trackerFrame.familyIcon = familyIcon
  
  -- Store layout values for dynamic adjustment
  trackerFrame.layoutPad = pad
  trackerFrame.layoutRow1Top = row1Top
  trackerFrame.layoutRowH = rowH
  trackerFrame.familyIconSize = ui.FAMILY_ICON_SIZE
  trackerFrame.familyIconPad = 6  -- Gap after family icon before text
  
  --
  -- ROW 1: NPC Name + Mechanic Icons + Progress
  --
  local targetText = trackerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  targetText:SetPoint("TOPLEFT", trackerFrame, "TOPLEFT", pad, row1Top)
  targetText:SetHeight(rowH)
  targetText:SetJustifyH("LEFT")
  targetText:SetJustifyV("MIDDLE")
  trackerFrame.targetText = targetText
  
  local progressText = trackerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  progressText:SetPoint("TOPRIGHT", trackerFrame, "TOPRIGHT", -pad, row1Top)
  progressText:SetHeight(rowH)
  progressText:SetJustifyH("RIGHT")
  progressText:SetJustifyV("MIDDLE")
  progressText:SetTextColor(0.7, 0.7, 0.7)
  trackerFrame.progressText = progressText
  
  -- Mechanic icons (inline with name, anchored left of progress)
  trackerFrame.mechanicIcons = {}
  local mechanicIconY = row1Top - ((rowH - ui.MECHANIC_ICON_SIZE) / 2)
  for i = 1, 2 do
    local iconFrame = CreateFrame("Frame", nil, trackerFrame)
    iconFrame:SetSize(ui.MECHANIC_ICON_SIZE, ui.MECHANIC_ICON_SIZE)
    iconFrame:EnableMouse(true)
    iconFrame:Hide()
    
    local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
    iconTex:SetAllPoints()
    iconFrame.texture = iconTex
    
    -- Tooltip handlers
    iconFrame:SetScript("OnEnter", function(self)
      if self.abilityId then
        local _, abilityName, _, _, unparsedDesc = C_PetBattles.GetAbilityInfoByID(self.abilityId)
        if abilityName then
          local tip = Addon.tooltip
          tip:show(self, { anchor = "above" })
          tip:header(abilityName)
          if unparsedDesc and unparsedDesc ~= "" then
            local tooltipParser = Addon.tooltipParser
            if tooltipParser then
              local abilityInfo = tooltipParser:createAbilityInfo(self.abilityId, nil, self.speciesId)
              if abilityInfo and self.petPower then
                abilityInfo.power = self.petPower
              end
              local parsedDesc = tooltipParser:parseText(abilityInfo, unparsedDesc)
              if parsedDesc and parsedDesc ~= "" then
                tip:text(parsedDesc, {wrap = true})
              end
            end
          end
          tip:done()
        end
      end
    end)
    iconFrame:SetScript("OnLeave", function()
      if Addon.tooltip then Addon.tooltip:hide() end
    end)
    
    trackerFrame.mechanicIcons[i] = iconFrame
  end
  -- Icons will be positioned dynamically based on name text width
  
  trackerFrame.mechanicIconSize = ui.MECHANIC_ICON_SIZE
  trackerFrame.mechanicIconGap = 8  -- Gap between icons
  
  --
  -- ROW 2: Zone
  --
  local row2Top = row1Top - rowH - rowGap
  trackerFrame.layoutRow2Top = row2Top
  
  local zoneText = trackerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  zoneText:SetPoint("TOPLEFT", trackerFrame, "TOPLEFT", pad, row2Top)
  zoneText:SetHeight(rowH)
  zoneText:SetJustifyH("LEFT")
  zoneText:SetJustifyV("MIDDLE")
  zoneText:SetTextColor(0.5, 0.5, 0.5)
  trackerFrame.zoneText = zoneText
  
  --
  -- ROW 3: Buff Icons (left) + Buttons (right) - anchored from bottom
  --
  local controlRowBottom = pad  -- Same padding as all other edges
  
  -- Tooltip factory reference
  local tip = Addon.tooltip
  
  -- Buff buttons - uses shared XP_BUFF constants from core/constants.lua
  -- Uses SecureActionButtonTemplate for protected toy/item actions
  trackerFrame.buffButtons = {}
  local xpBuff = Addon.constants.XP_BUFF
  
  -- Button config: key matches XP_BUFF table keys
  -- duration: nil = permanent
  -- timeType: "game" = only counts while playing, "real" = counts while logged out
  local buffConfig = {
    {key = "SAFARI_HAT", name = "Safari Hat", duration = nil, desc = "Reward from Taming the World achievement"},
    {key = "LESSER_PET_TREAT", name = "Lesser Pet Treat", duration = "1 hour", timeType = "game", desc = "Sold by pet supply vendors for 5 Polished Pet Charms"},
    {key = "PET_TREAT", name = "Pet Treat", duration = "1 hour", timeType = "game", desc = "Sold by pet supply vendors for 10 Polished Pet Charms"},
    {key = "DARKMOON_TOP_HAT", name = "Darkmoon Top Hat", duration = "1 hour", timeType = "real", desc = "Sold during Darkmoon Faire for 10 Prize Tickets"},
  }
  
  for i, cfg in ipairs(buffConfig) do
    local itemId = xpBuff.ITEM_IDS[cfg.key]
    local itemType = xpBuff.ITEM_TYPES[cfg.key]
    
    -- SecureActionButtonTemplate required for toy/item use
    local btn = CreateFrame("Button", "PAOBuffBtn" .. i, trackerFrame, "SecureActionButtonTemplate")
    btn:SetSize(ui.BUFF_ICON_SIZE, ui.BUFF_ICON_SIZE)
    btn:SetPoint("BOTTOMLEFT", trackerFrame, "BOTTOMLEFT", pad + ((i-1) * (ui.BUFF_ICON_SIZE + 7)), controlRowBottom)
    
    -- Set secure attributes based on item type
    if itemType == "toy" then
      btn:SetAttribute("type", "toy")
      btn:SetAttribute("toy", itemId)
    else
      -- Consumable - use item by ID
      btn:SetAttribute("type", "item")
      btn:SetAttribute("item", "item:" .. itemId)
    end
    
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    btn.icon = icon
    
    -- Cooldown overlay - OmniCC and similar addons will auto-style this
    local cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    cooldown:SetDrawEdge(true)
    cooldown:SetDrawSwipe(true)
    btn.cooldown = cooldown
    
    -- Colored border for time remaining indicator
    local borderSize = 2
    local borders = {}
    for _, edge in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
      local border = btn:CreateTexture(nil, "OVERLAY")
      border:SetColorTexture(0.3, 0.3, 0.3, 1)  -- Default: dim gray
      if edge == "TOP" then
        border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        border:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
        border:SetHeight(borderSize)
      elseif edge == "BOTTOM" then
        border:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        border:SetHeight(borderSize)
      elseif edge == "LEFT" then
        border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        border:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        border:SetWidth(borderSize)
      elseif edge == "RIGHT" then
        border:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
        border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        border:SetWidth(borderSize)
      end
      borders[edge] = border
    end
    btn.borders = borders
    
    -- Highlight for buffed state - Blizzard-style glow with ADD blend
    local highlightFrame = CreateFrame("Frame", nil, trackerFrame)
    highlightFrame:SetPoint("TOPLEFT", btn, "TOPLEFT", -4, 4)
    highlightFrame:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 4, -4)
    highlightFrame:SetFrameLevel(btn:GetFrameLevel() + 5)  -- Draw on top
    
    local highlight = highlightFrame:CreateTexture(nil, "ARTWORK")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    highlight:SetBlendMode("ADD")
    highlight:SetVertexColor(0.2, 1.0, 0.2)  -- Green tint (default)
    highlightFrame:Hide()
    btn.highlight = highlightFrame
    btn.highlightTexture = highlight  -- Store texture reference for color changes
    
    -- Store config for tooltips
    btn.buffKey = cfg.key
    btn.itemId = itemId
    btn.spellId = xpBuff.SPELL_IDS[cfg.key]
    btn.itemName = cfg.name
    btn.itemDesc = cfg.desc
    btn.duration = cfg.duration
    btn.timeType = cfg.timeType
    btn.xpBonus = xpBuff.PERCENTAGES[cfg.key]
    btn.itemType = itemType
    
    -- Note: OnClick is handled by secure template, no manual handler needed
    btn:SetScript("OnEnter", function(self)
      circuitTracker:showBuffTooltip(self)
    end)
    btn:SetScript("OnLeave", function()
      tip:hide()
    end)
    
    trackerFrame.buffButtons[i] = btn
  end
  
  -- Control buttons using actionButton (style 1: Flat with 1px border)
  local actionButton = Addon.actionButton
  
  local cancelBtn = actionButton:create(trackerFrame, {
    text = "Cancel",
    size = "small",
    style = 1,
    onClick = function()
      if Addon.circuit then Addon.circuit:cancel() end
    end,
  })
  cancelBtn:SetPoint("BOTTOMRIGHT", trackerFrame, "BOTTOMRIGHT", -pad, controlRowBottom)
  cancelBtn:SetScript("OnEnter", function(self)
    tip:show(self, { anchor = "below" })
    tip:header("Cancel Circuit")
    tip:text("Stop and clear progress")
    tip:done()
  end)
  cancelBtn:SetScript("OnLeave", function() tip:hide() end)
  trackerFrame.cancelBtn = cancelBtn
  
  local toggleBtn = actionButton:create(trackerFrame, {
    text = "Suspend",
    size = "small",
    style = 1,
    onClick = function() end,  -- Set dynamically in update()
  })
  toggleBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -4, 0)
  trackerFrame.toggleBtn = toggleBtn
  
  -- Proximity check for waypoint visibility
  -- Throttled to every 0.5 seconds to avoid performance issues
  local tickElapsed = 0
  local TICK_INTERVAL = 0.5
  trackerFrame:SetScript("OnUpdate", function(self, elapsed)
    tickElapsed = tickElapsed + elapsed
    if tickElapsed >= TICK_INTERVAL then
      tickElapsed = 0
      if not self:IsShown() then return end
      
      if Addon.waypoint then
        Addon.waypoint:checkProximity()
      end
    end
  end)
  
  return trackerFrame
end

--[[
  Update buff button states (icon, ownership, active buff)
  Three visual states:
  - Unowned: Desaturated, 0.3 alpha
  - Owned/Unbuffed: Normal saturation, 0.7 alpha  
  - Buffed: Full brightness, green highlight
]]
function circuitTracker:updateBuffButtons()
  if not trackerFrame or not trackerFrame.buffButtons then return end
  
  local petUtils = Addon.petUtils
  if not petUtils then return end
  
  for _, btn in ipairs(trackerFrame.buffButtons) do
    local buffKey = btn.buffKey
    local itemId = btn.itemId
    
    -- Get item icon
    local _, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(itemId)
    if itemIcon then
      btn.icon:SetTexture(itemIcon)
    else
      -- Fallback - request item info and use placeholder
      btn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
      GetItemInfo(itemId)  -- Async load
    end
    
    -- Update cooldown to show buff duration remaining
    -- Check if player has this buff active and show its remaining time
    local buffFound = false
    local remainingTime = 0
    if btn.spellId then
      for i = 1, 40 do
        local name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff("player", i)
        if not name then break end
        if spellId == btn.spellId then
          if duration and duration > 0 and expirationTime then
            local start = expirationTime - duration
            btn.cooldown:SetCooldown(start, duration)
            remainingTime = expirationTime - GetTime()
            buffFound = true
          elseif expirationTime == 0 then
            -- Permanent buff (like Safari Hat aura)
            remainingTime = math.huge
            buffFound = true
          end
          break
        end
      end
    end
    if not buffFound then
      btn.cooldown:Clear()
    end
    
    -- Update border color based on remaining time
    -- Green: > 30 min, Yellow: 10-30 min, Salmon: < 10 min, Gray: no buff
    local highlightColor
    if not buffFound then
      highlightColor = {0.3, 0.3, 0.3}  -- Gray - no buff active
    elseif remainingTime == math.huge then
      highlightColor = {0.2, 1.0, 0.2}  -- Green - permanent buff
    elseif remainingTime > 1800 then  -- > 30 minutes
      highlightColor = {0.2, 1.0, 0.2}  -- Green
    elseif remainingTime > 600 then   -- 10-30 minutes
      highlightColor = {1.0, 0.85, 0.0}  -- Yellow
    else                              -- < 10 minutes
      highlightColor = {0.98, 0.5, 0.45}  -- Salmon
    end
    
    -- Update highlight glow color
    if btn.highlightTexture then
      btn.highlightTexture:SetVertexColor(highlightColor[1], highlightColor[2], highlightColor[3])
    end
    
    -- Update border edges color
    if btn.borders then
      for _, border in pairs(btn.borders) do
        border:SetColorTexture(highlightColor[1], highlightColor[2], highlightColor[3], 1)
      end
    end
    
    -- Check states
    local hasItem = petUtils:hasXpBuffItem(buffKey)
    local hasBuff = petUtils:hasXpBuff(buffKey)
    
    if hasBuff then
      -- State 3: Buffed - full brightness, green highlight
      btn.icon:SetDesaturated(false)
      btn:SetAlpha(1.0)
      btn.highlight:Show()
    elseif hasItem then
      -- State 2: Owned but not buffed - normal, slight dim
      btn.icon:SetDesaturated(false)
      btn:SetAlpha(0.7)
      btn.highlight:Hide()
    else
      -- State 1: Unowned - desaturated, very dim
      btn.icon:SetDesaturated(true)
      btn:SetAlpha(0.3)
      btn.highlight:Hide()
    end
  end
end

--[[
  Show tooltip for a buff button
  Uses tooltip factory's section() and cornerIcon() for consistent formatting.
  
  @param btn frame - The buff button being hovered
]]
function circuitTracker:showBuffTooltip(btn)
  local tip = Addon.tooltip
  local petUtils = Addon.petUtils
  local npcUtils = Addon.npcUtils
  local colors = Addon.constants.SEMANTIC
  local text = Addon.constants.TEXT
  if not tip or not petUtils then return end
  
  local buffKey = btn.buffKey
  local hasItem = petUtils:hasXpBuffItem(buffKey)
  local hasBuff = petUtils:hasXpBuff(buffKey)
  
  -- Consumable items use "None owned", Safari Hat uses "Not owned"
  local isConsumable = buffKey == "LESSER_PET_TREAT" or buffKey == "PET_TREAT" or buffKey == "DARKMOON_TOP_HAT"
  
  local _, _, _, _, _, _, _, _, _, itemIcon = GetItemInfo(btn.itemId)
  
  tip:show(btn, {anchor = "below"})
  tip:minWidth(300)
  tip:header(btn.itemName)
  
  -- Corner icon in content area
  if itemIcon then
    tip:cornerIcon(itemIcon, {size = 48, alpha = 0.8})
  end
  
  -- What it does - gold
  local bonusText
  if btn.duration then
    if btn.timeType == "game" then
      bonusText = string.format("Increases pet XP gained by %d%% for %s of game time.", btn.xpBonus, btn.duration)
    else
      bonusText = string.format("Increases pet XP gained by %d%% for %s.", btn.xpBonus, btn.duration)
    end
  else
    bonusText = string.format("Increases pet XP gained by %d%%.", btn.xpBonus)
  end
  tip:text(bonusText, {color = text.EMPHASIS, wrap = true})
  
  tip:space(4)
  
  -- Status - only show Active or Not/None Owned (no "Ready to use")
  if hasBuff then
    tip:text("Active", {color = colors.SUCCESS})
  elseif not hasItem then
    if isConsumable then
      tip:text("None owned", {color = text.MUTED})
    else
      tip:text("Not owned", {color = text.MUTED})
    end
  end
  
  -- Warnings section
  local hasWarnings = (buffKey == "SAFARI_HAT") or 
                      (buffKey == "LESSER_PET_TREAT" or buffKey == "PET_TREAT") or
                      (buffKey == "DARKMOON_TOP_HAT")
  
  if hasWarnings then
    tip:separator()
  end
  
  -- Warning icon texture ID (yellow caution triangle)
  local CAUTION_ICON = 134400
  
  -- Safari Hat
  if buffKey == "SAFARI_HAT" then
    tip:text("Lost on death.", {color = colors.DANGER})
    if hasItem and not hasBuff then
      tip:iconText(CAUTION_ICON, "Dismounts when used.", {color = colors.WARNING_SOFT, iconSize = 14})
    end
  end
  
  -- Pet Treats
  if buffKey == "LESSER_PET_TREAT" or buffKey == "PET_TREAT" then
    tip:text("Persists through death.", {color = colors.SUCCESS_SOFT})
  end
  
  -- Darkmoon Top Hat
  if buffKey == "DARKMOON_TOP_HAT" then
    tip:text("Lost on death.", {color = colors.DANGER})
    
    local currentTime = time()
    local dmfActive
    if dmfCache.activeExpiry > currentTime then
      dmfActive = dmfCache.isActive
    else
      dmfActive = npcUtils and npcUtils.isDarkmoonFaireActive and npcUtils:isDarkmoonFaireActive()
      dmfCache.isActive = dmfActive
      dmfCache.activeExpiry = currentTime + 60
    end
    
    if dmfActive then
      tip:text("Darkmoon Faire is active!", {color = colors.SUCCESS})
    else
      local nextFaire
      if dmfCache.nextFaireExpiry > currentTime then
        nextFaire = dmfCache.nextFaire
      else
        nextFaire = self:getNextDarkmoonFaire()
        dmfCache.nextFaire = nextFaire
        dmfCache.nextFaireExpiry = currentTime + 300
      end
      if nextFaire then
        tip:text(nextFaire, {color = text.SECONDARY})
      end
    end
    
    tip:space(4)
    tip:text("Timer runs while logged out.", {color = colors.DANGER_SOFT})
    tip:text("Note: Hat disappears when faire ends, but the buff persists.", {color = {0.6, 0.6, 0.6}, wrap = true, font = "small"})
  end
  
  -- How to obtain section
  -- Safari Hat: show only if not owned (one-time)
  -- Consumables: show if count <= 2 (running low or empty)
  local showHowToObtain, itemCount
  
  if buffKey == "SAFARI_HAT" then
    showHowToObtain = not hasItem
  else
    -- Consumables - check count
    itemCount = GetItemCount(btn.itemId) or 0
    showHowToObtain = itemCount <= 2
  end
  
  if showHowToObtain then
    tip:separator()
    tip:section("How to Obtain")
    
    if buffKey == "SAFARI_HAT" then
      -- Achievement-based item
      local TAMING_THE_WORLD_ID = 6622
      local achievementLink = GetAchievementLink(TAMING_THE_WORLD_ID)
      if achievementLink then
        tip:text("Reward from " .. achievementLink, {color = text.SECONDARY, wrap = true})
      else
        tip:text(btn.itemDesc, {color = text.SECONDARY, wrap = true})
      end
    else
      -- Consumable
      tip:text(btn.itemDesc, {color = text.SECONDARY, wrap = true})
      if itemCount > 0 then
        tip:text(string.format("You have %d remaining.", itemCount), {color = text.MUTED})
      end
    end
  end
  
  -- Click hint (only if owned but not active)
  if hasItem and not hasBuff then
    tip:hints({"Click to use"})
  end
  
  tip:done()
end

--[[
  Get a human-readable string for the next Darkmoon Faire.
  DMF runs first Sunday of each month through the following Saturday.
  
  @return string|nil - Description of next faire timing
]]
function circuitTracker:getNextDarkmoonFaire()
  -- Get current date info
  local currentTime = time()
  local currentDate = date("*t", currentTime)
  
  -- Find first Sunday of current month
  local firstOfMonth = time({year = currentDate.year, month = currentDate.month, day = 1})
  local firstOfMonthDate = date("*t", firstOfMonth)
  local daysUntilSunday = (7 - firstOfMonthDate.wday) % 7
  if firstOfMonthDate.wday == 1 then daysUntilSunday = 0 end  -- Sunday is 1 in Lua
  local firstSunday = firstOfMonth + (daysUntilSunday * 86400)
  local faireEnd = firstSunday + (6 * 86400)  -- Runs through Saturday
  
  -- Check if we're before this month's faire
  if currentTime < firstSunday then
    local daysUntil = math.ceil((firstSunday - currentTime) / 86400)
    if daysUntil == 1 then
      return "Starts tomorrow"
    else
      return string.format("Starts in %d days", daysUntil)
    end
  end
  
  -- Check if we're during this month's faire (shouldn't hit this if dmfActive works)
  if currentTime <= faireEnd then
    return "Currently active"
  end
  
  -- Calculate next month's faire
  local nextMonth = currentDate.month + 1
  local nextYear = currentDate.year
  if nextMonth > 12 then
    nextMonth = 1
    nextYear = nextYear + 1
  end
  
  local nextFirstOfMonth = time({year = nextYear, month = nextMonth, day = 1})
  local nextFirstDate = date("*t", nextFirstOfMonth)
  local nextDaysUntilSunday = (7 - nextFirstDate.wday) % 7
  if nextFirstDate.wday == 1 then nextDaysUntilSunday = 0 end
  local nextFirstSunday = nextFirstOfMonth + (nextDaysUntilSunday * 86400)
  
  local daysUntil = math.ceil((nextFirstSunday - currentTime) / 86400)
  if daysUntil <= 7 then
    return string.format("Starts in %d days", daysUntil)
  else
    local nextFaireDate = date("*t", nextFirstSunday)
    local monthNames = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
    return string.format("Next faire: %s %d", monthNames[nextFaireDate.month], nextFaireDate.day)
  end
end

--[[
  Update tracker display with current circuit state
  Refreshes progress counter, current target, and control button visibility
  based on circuit state from persistence layer.
]]
function circuitTracker:update()
  
  if not trackerFrame then
    Addon.utils:debug("[TRACKER UPDATE] ERROR - trackerFrame is nil")
    return
  end
  
  local persistence = Addon.circuitPersistence
  local state = persistence:getCircuitState()
  
  if not state or not state.active then
    trackerFrame:Hide()
    return
  end
  
  trackerFrame:Show()
  
  -- Update buff buttons
  self:updateBuffButtons()
  
  -- Update progress text
  local completed = #state.completedInCircuit
  local total = #state.selectedNpcIds
  trackerFrame.progressText:SetText(string.format("Circuit: %d/%d", completed, total))
  
  -- Reset optional elements
  trackerFrame.familyIcon:Hide()
  trackerFrame.zoneText:SetText("")
  for _, icon in ipairs(trackerFrame.mechanicIcons) do
    icon:Hide()
    icon.abilityId = nil
    icon.petPower = nil
    icon.speciesId = nil
  end
  
  -- Reset targetText and zoneText to default position (no mechanic icons)
  trackerFrame.targetText:ClearAllPoints()
  trackerFrame.targetText:SetPoint("TOPLEFT", trackerFrame, "TOPLEFT", 
    trackerFrame.layoutPad, trackerFrame.layoutRow1Top)
  trackerFrame.targetText:SetPoint("RIGHT", trackerFrame, "RIGHT", -70, 0)
  trackerFrame.zoneText:ClearAllPoints()
  trackerFrame.zoneText:SetPoint("TOPLEFT", trackerFrame, "TOPLEFT",
    trackerFrame.layoutPad, trackerFrame.layoutRow2Top)
  
  -- Update current target
  if state.suspended then
    -- Suspended for continent travel - show list of all continents with battle counts
    local continentQueue = persistence:getContinentQueue()
    local numContinents = #continentQueue
    local currentNpcId = state.currentNpcId
    
    -- Helper to get total battles for a continent (queue + current if applicable)
    local function getTotalBattles(continentData)
      local count = #continentData.npcIds
      -- Add 1 if currentNpc belongs to this continent
      if currentNpcId then
        local npc = Addon.npcUtils:getNpcData(currentNpcId)
        local npcContinent = npc and npc.locations and npc.locations[1] and npc.locations[1].continent
        if npcContinent and npcContinent == continentData.continent then
          count = count + 1
        end
      end
      return count
    end
    
    if numContinents == 0 then
      trackerFrame.targetText:SetText("No destinations remaining")
    elseif numContinents == 1 then
      -- Single continent: show name on row 1, count on row 2
      local continentName = "Unknown"
      if Addon.location then
        continentName = Addon.location:getContinentName(continentQueue[1].continent) or "Unknown"
      end
      local battleCount = getTotalBattles(continentQueue[1])
      local tamerText = battleCount == 1 and "tamer" or "tamers"
      trackerFrame.targetText:SetText("Travel to " .. continentName)
      trackerFrame.zoneText:SetText(string.format("%d %s", battleCount, tamerText))
    else
      -- Multiple continents: show list
      local lines = {"Visit any continent to continue:"}
      for i, continentData in ipairs(continentQueue) do
        local continentName = "Unknown"
        if Addon.location then
          continentName = Addon.location:getContinentName(continentData.continent) or "Unknown"
        end
        local battleCount = getTotalBattles(continentData)
        local tamerText = battleCount == 1 and "tamer" or "tamers"
        table.insert(lines, string.format("- %s (%d %s)", continentName, battleCount, tamerText))
      end
      local fullText = table.concat(lines, "\n")
      trackerFrame.targetText:SetText(fullText)
    end
  elseif state.currentNpcId then
    -- Active circuit with current NPC - show it
    local npc = Addon.npcUtils:getNpcData(state.currentNpcId)
    if npc then
      trackerFrame.targetText:SetText(npc.name)
      
      -- Show zone if available
      if npc.locations and npc.locations[1] then
        local loc = npc.locations[1]
        local zoneName = loc.subzone or ""
        if Addon.location and loc.mapID then
          local mapInfo = C_Map.GetMapInfo(loc.mapID)
          if mapInfo then
            zoneName = loc.subzone and (loc.subzone .. ", " .. mapInfo.name) or mapInfo.name
          end
        end
        trackerFrame.zoneText:SetText(zoneName)
      end
      
      -- Show family icon for fabled beasts (single pet encounters)
      -- When shown, shifts name/zone text to the right
      local NPC_TYPE = Addon.NPC_TYPE
      if npc.types and bit.band(npc.types, NPC_TYPE.FABLED) > 0 then
        if npc.pets and #npc.pets == 1 and npc.pets[1].familyType then
          local familyType = npc.pets[1].familyType
          -- Use PetIcon atlas with "strong" texcoords (bright bordered circular icon)
          local familyIconPath = "Interface\\PetBattles\\PetIcon-" .. PET_TYPE_SUFFIX[familyType]
          trackerFrame.familyIcon:SetTexture(familyIconPath)
          trackerFrame.familyIcon:SetTexCoord(0.796875, 0.492188, 0.503906, 0.65625)
          trackerFrame.familyIcon:SetVertexColor(1, 1, 1)
          trackerFrame.familyIcon:SetAlpha(1)
          trackerFrame.familyIcon:Show()
          
          -- Shift name and zone text right to make room for family icon
          local iconSpace = trackerFrame.familyIconSize + trackerFrame.familyIconPad
          trackerFrame.targetText:ClearAllPoints()
          trackerFrame.targetText:SetPoint("TOPLEFT", trackerFrame, "TOPLEFT", 
            trackerFrame.layoutPad + iconSpace, trackerFrame.layoutRow1Top)
          trackerFrame.zoneText:ClearAllPoints()
          trackerFrame.zoneText:SetPoint("TOPLEFT", trackerFrame, "TOPLEFT",
            trackerFrame.layoutPad + iconSpace, trackerFrame.layoutRow2Top)
        end
      end
      
      -- Show mechanic warning icons if this NPC has notable mechanics
      -- Icons positioned right after the NPC name
      local constants = Addon.circuitConstants
      local mechanics = constants.NOTABLE_MECHANICS[state.currentNpcId]
      if mechanics then
        -- Get pet power for tooltip calculations (use first pet as approximation)
        local petPower = npc.pets and npc.pets[1] and npc.pets[1].power or 0
        local speciesId = npc.pets and npc.pets[1] and npc.pets[1].speciesID or nil
        
        -- Calculate position: right after name text
        local nameWidth = trackerFrame.targetText:GetStringWidth()
        local baseX = trackerFrame.targetText:GetLeft() - trackerFrame:GetLeft() + nameWidth + 4
        local iconY = trackerFrame.layoutRow1Top - ((trackerFrame.layoutRowH - trackerFrame.mechanicIconSize) / 2)  -- Center in row
        
        local iconIndex = 1
        for mechanicType, abilityId in pairs(mechanics) do
          if iconIndex <= 2 then
            local _, _, abilityIcon = C_PetBattles.GetAbilityInfoByID(abilityId)
            if abilityIcon then
              local iconFrame = trackerFrame.mechanicIcons[iconIndex]
              iconFrame.texture:SetTexture(abilityIcon)
              iconFrame.abilityId = abilityId
              iconFrame.petPower = petPower
              iconFrame.speciesId = speciesId
              
              -- Position icon right after previous content
              iconFrame:ClearAllPoints()
              local xOffset = baseX + ((iconIndex - 1) * (trackerFrame.mechanicIconSize + trackerFrame.mechanicIconGap))
              iconFrame:SetPoint("TOPLEFT", trackerFrame, "TOPLEFT", xOffset, iconY)
              iconFrame:Show()
              iconIndex = iconIndex + 1
            end
          end
        end
      end
    else
      Addon.utils:debug("[TRACKER UPDATE] NPC data not found for ID: " .. tostring(state.currentNpcId))
      trackerFrame.targetText:SetText("Unknown NPC")
    end
  else
    -- No current NPC and not traveling
    trackerFrame.targetText:SetText("No current target")
  end
  
  -- Update button text and behavior based on suspended state
  local tip = Addon.tooltip
  
  if state.suspended then
    trackerFrame.toggleBtn:setText("Resume")
    trackerFrame.toggleBtn:SetScript("OnClick", function()
      if Addon.circuit then
        Addon.circuit:resume()
        Addon.circuitTracker:update()
      end
    end)
    trackerFrame.toggleBtn:SetScript("OnEnter", function(self)
      tip:show(self, { anchor = "below" })
      tip:header("Resume Circuit")
      tip:text("Continue where you left off")
      tip:done()
    end)
  else
    trackerFrame.toggleBtn:setText("Suspend")
    trackerFrame.toggleBtn:SetScript("OnClick", function()
      if Addon.circuit then
        Addon.circuit:suspend()
        Addon.circuitTracker:update()
      end
    end)
    trackerFrame.toggleBtn:SetScript("OnEnter", function(self)
      tip:show(self, { anchor = "below" })
      tip:header("Suspend Circuit")
      tip:text("Pause without canceling")
      tip:done()
    end)
  end
  trackerFrame.toggleBtn:SetScript("OnLeave", function() tip:hide() end)
  
end

--[[
  Show daily reset prompt
  Displays a prompt when daily quests reset during an active circuit,
  offering options to restart, truncate, or cancel.
]]
function circuitTracker:showDailyResetPrompt()
  StaticPopupDialogs["PAO_CIRCUIT_DAILY_RESET"] = {
    text = "Daily quests have reset!\n\nWhat would you like to do with your circuit?",
    button1 = "Restart All",
    button2 = "Skip Completed",
    button3 = "Cancel Circuit",
    OnAccept = function()
      -- Restart with new dailies
      if Addon.circuitBattleHandler then
        Addon.circuitBattleHandler:resetWithNewDailies()
      end
    end,
    OnCancel = function()
      -- Truncate to incomplete only
      if Addon.circuitBattleHandler then
        Addon.circuitBattleHandler:truncateToActiveQuests()
      end
    end,
    OnAlt = function()
      -- Cancel circuit
      if Addon.circuit then
        Addon.circuit:cancel()
      end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
  }
  
  StaticPopup_Show("PAO_CIRCUIT_DAILY_RESET")
end

--[[
  Show tracker frame
  Makes tracker visible without updating contents.
]]
function circuitTracker:show()
  if trackerFrame then
    trackerFrame:Show()
  end
end

--[[
  Hide tracker frame
  Conceals tracker without destroying it.
]]
function circuitTracker:hide()
  if trackerFrame then
    trackerFrame:Hide()
  end
end

--[[
  Get tracker frame reference
  Provides access to the frame for external positioning or manipulation.
  
  @return Frame - The tracker frame (may be nil if not created yet)
]]
function circuitTracker:getFrame()
  return trackerFrame
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("circuitTracker", {"utils", "constants", "petUtils", "circuitPersistence", "circuitConstants", "waypoint", "location", "npcUtils", "tooltip"}, function()
    return true
  end)
end


--[[
  Cleanup function to unregister all event listeners
  Should be called when addon is unloading or circuit tracker is being destroyed
]]
function circuitTracker:cleanup()
  -- Unregister all internal event listeners
  if Addon.events then
    Addon.events:offAll(self)
  end
  
  -- Hide and destroy tracker frame if it exists
  if trackerFrame then
    trackerFrame:Hide()
  end
end

return circuitTracker