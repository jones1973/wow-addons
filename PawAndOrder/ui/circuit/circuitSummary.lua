--[[
  ui/circuit/circuitSummary.lua
  Circuit Completion Summary Popup

  Displays a polished summary when a circuit finishes, showing stats
  (battles, duration) and an embedded scrollable battle log. Replaces
  the orphaned circuitLog frame after the tracker hides.

  Shown on CIRCUIT:COMPLETED, dismissed by user via Close button.
  Log data persists in pao_circuit.log until next circuit starts.

  Dependencies: utils, events, circuitPersistence, circuitConstants,
                popupFactory, actionButton, circuitLog
  Exports: Addon.circuitSummary
]]

local ADDON_NAME, Addon = ...

local circuitSummary = {}
Addon.circuitSummary = circuitSummary

-- Module references
local events

-- Frame reference
local summaryFrame = nil

-- Layout
local FRAME_WIDTH = 400
local PADDING = 16
local CONTENT_WIDTH = FRAME_WIDTH - (PADDING * 2) - 24  -- Account for border insets
local LOG_LINE_HEIGHT = 14
local LOG_VISIBLE_LINES = 12
local TIMESTAMP_WIDTH = 36

-- Colors
local COLORS = {
  victory   = { 0.2, 1.0, 0.2 },
  levelup   = { 1.0, 0.85, 0.0 },
  xp        = { 0.7, 0.7, 0.7 },
  capture   = { 0.4, 0.8, 1.0 },
  reward    = { 0.9, 0.6, 1.0 },
  gold      = { 1.0, 0.84, 0.0 },
  circuit   = { 1.0, 0.82, 0.0 },
  timestamp = { 0.4, 0.4, 0.4 },
}

-- ============================================================================
-- STAT HELPERS
-- ============================================================================

--[[
  Format duration into human-readable string.
  @param seconds number
  @return string
]]
local function formatDuration(seconds)
  if not seconds or seconds <= 0 then return "0m" end
  local hours = math.floor(seconds / 3600)
  local minutes = math.floor((seconds % 3600) / 60)
  if hours > 0 then
    return string.format("%dh %dm", hours, minutes)
  end
  return string.format("%dm", minutes)
end

--[[
  Count events of a specific type from log entries.
  @param entries table - Log entries
  @param colorKey string - Color key to count
  @return number
]]
local function countByType(entries, colorKey)
  local count = 0
  for _, entry in ipairs(entries) do
    if entry.colorKey == colorKey then
      count = count + 1
    end
  end
  return count
end

-- ============================================================================
-- FRAME CREATION
-- ============================================================================

--[[
  Create or reconfigure the summary popup.
  @param payload table - {totalBattles, duration, minutes} from CIRCUIT:COMPLETED
]]
local function createFrame(payload)
  payload = payload or {}

  -- Extract stats
  local totalBattles = payload.totalBattles or 0
  local duration = payload.duration or 0

  -- Get log entries
  local entries = {}
  if pao_circuit and pao_circuit.log then
    entries = pao_circuit.log
  end

  -- Count secondary stats from log
  local levelUps = countByType(entries, "levelup")
  local captures = countByType(entries, "capture")

  -- Calculate frame height dynamically
  local HEADER_HEIGHT = 72     -- popupFactory header
  local STATS_HEIGHT = 64      -- Stats card
  local LABEL_HEIGHT = 24      -- "Battle Log" label
  local CLOSE_HEIGHT = 44      -- Close button area
  local RETURN_LINE_HEIGHT = 20
  local LOG_HEIGHT = math.min(#entries, LOG_VISIBLE_LINES) * LOG_LINE_HEIGHT
  LOG_HEIGHT = math.max(LOG_HEIGHT, LOG_VISIBLE_LINES * LOG_LINE_HEIGHT) -- Minimum size

  -- Check if return waypoint message will be shown
  local returnLocation = Addon.circuitPersistence:getReturnLocation()
  local hasReturnLine = returnLocation and returnLocation.type and returnLocation.type ~= "none"
  local returnHeight = hasReturnLine and RETURN_LINE_HEIGHT or 0

  local FRAME_HEIGHT = HEADER_HEIGHT + STATS_HEIGHT + returnHeight + LABEL_HEIGHT + LOG_HEIGHT + CLOSE_HEIGHT + (PADDING * 3)

  -- Destroy previous if exists
  if summaryFrame then
    summaryFrame:Hide()
    summaryFrame = nil
  end

  -- Create via popupFactory
  summaryFrame = Addon.popupFactory:create({
    title = "Circuit Complete",
    icon = 136814,  -- Achievement icon
    width = FRAME_WIDTH,
    height = FRAME_HEIGHT,
    closeable = true,
  })

  if not summaryFrame then return end

  -- Hook close to also hide the circuitLog
  summaryFrame:HookScript("OnHide", function()
    if Addon.circuitLog then
      Addon.circuitLog:hide()
    end
  end)

  local anchor = summaryFrame.contentAnchor
  local yOffset = -PADDING

  -- ========================================================================
  -- STATS CARD
  -- ========================================================================
  local statsCard = CreateFrame("Frame", nil, summaryFrame, "BackdropTemplate")
  statsCard:SetPoint("TOPLEFT", anchor, "TOPLEFT", PADDING, yOffset)
  statsCard:SetPoint("RIGHT", summaryFrame, "RIGHT", -PADDING, 0)
  statsCard:SetHeight(STATS_HEIGHT)
  statsCard:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  statsCard:SetBackdropColor(0.08, 0.08, 0.08, 1)
  statsCard:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

  -- Primary stat line: "21 battles  ·  47 minutes"
  local primaryLine = statsCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  primaryLine:SetPoint("TOP", statsCard, "TOP", 0, -12)
  primaryLine:SetJustifyH("CENTER")

  local battleWord = totalBattles == 1 and "battle" or "battles"
  local durationStr = formatDuration(duration)
  primaryLine:SetText(string.format(
    "|cffffffff%d|r |cffbbbbbb%s|r    |cff666666:|r    |cffffffff%s|r",
    totalBattles, battleWord, durationStr
  ))

  -- Secondary stat line: level-ups and captures if any
  local secondaryParts = {}
  if levelUps > 0 then
    local word = levelUps == 1 and "level-up" or "level-ups"
    table.insert(secondaryParts, string.format("|cffffff00%d|r |cffbbbbbb%s|r", levelUps, word))
  end
  if captures > 0 then
    local word = captures == 1 and "capture" or "captures"
    table.insert(secondaryParts, string.format("|cff66ccff%d|r |cffbbbbbb%s|r", captures, word))
  end

  if #secondaryParts > 0 then
    local secondaryLine = statsCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    secondaryLine:SetPoint("TOP", primaryLine, "BOTTOM", 0, -6)
    secondaryLine:SetJustifyH("CENTER")
    secondaryLine:SetText(table.concat(secondaryParts, "    |cff666666:|r    "))
  end

  yOffset = yOffset - STATS_HEIGHT - PADDING

  -- ========================================================================
  -- RETURN WAYPOINT MESSAGE (if configured)
  -- ========================================================================
  if hasReturnLine then
    local returnLine = summaryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    returnLine:SetPoint("TOPLEFT", anchor, "TOPLEFT", PADDING, yOffset)
    returnLine:SetPoint("RIGHT", summaryFrame, "RIGHT", -PADDING, 0)
    returnLine:SetJustifyH("CENTER")
    
    local returnName = returnLocation.name or "return point"
    returnLine:SetText("|cff88ff88Waypoint set for " .. returnName .. "|r")
    
    yOffset = yOffset - RETURN_LINE_HEIGHT
  end

  -- ========================================================================
  -- LOG SECTION
  -- ========================================================================

  -- Label with separator lines
  local labelFrame = CreateFrame("Frame", nil, summaryFrame)
  labelFrame:SetPoint("TOPLEFT", anchor, "TOPLEFT", PADDING, yOffset)
  labelFrame:SetPoint("RIGHT", summaryFrame, "RIGHT", -PADDING, 0)
  labelFrame:SetHeight(LABEL_HEIGHT)

  local labelText = labelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  labelText:SetPoint("CENTER", labelFrame, "CENTER", 0, 0)
  labelText:SetText("|cff888888Battle Log|r")

  -- Left separator line (from left edge to label)
  local sepLeft = labelFrame:CreateTexture(nil, "ARTWORK")
  sepLeft:SetHeight(1)
  sepLeft:SetPoint("LEFT", labelFrame, "LEFT", 0, 0)
  sepLeft:SetPoint("RIGHT", labelText, "LEFT", -8, 0)
  sepLeft:SetColorTexture(0.3, 0.3, 0.3, 0.6)

  -- Right separator line (from label to right edge)
  local sepRight = labelFrame:CreateTexture(nil, "ARTWORK")
  sepRight:SetHeight(1)
  sepRight:SetPoint("LEFT", labelText, "RIGHT", 8, 0)
  sepRight:SetPoint("RIGHT", labelFrame, "RIGHT", 0, 0)
  sepRight:SetColorTexture(0.3, 0.3, 0.3, 0.6)

  yOffset = yOffset - LABEL_HEIGHT

  -- Scroll frame for log entries
  local scrollFrame = CreateFrame("ScrollFrame", "PAOCircuitSummaryScroll", summaryFrame)
  scrollFrame:SetPoint("TOPLEFT", anchor, "TOPLEFT", PADDING, yOffset)
  scrollFrame:SetPoint("RIGHT", summaryFrame, "RIGHT", -PADDING, 0)
  scrollFrame:SetHeight(LOG_HEIGHT)
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local newScroll = current - (delta * LOG_LINE_HEIGHT * 3)
    newScroll = math.max(0, math.min(newScroll, maxScroll))
    self:SetVerticalScroll(newScroll)
  end)

  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetWidth(scrollFrame:GetWidth())
  scrollChild:SetHeight(1)
  scrollFrame:SetScrollChild(scrollChild)

  -- Render log entries
  local stampColor = COLORS.timestamp
  local stampColorStr = string.format("|cff%02x%02x%02x",
    stampColor[1] * 255, stampColor[2] * 255, stampColor[3] * 255)

  local messageWidth = CONTENT_WIDTH - TIMESTAMP_WIDTH
  local logY = 0

  for _, entry in ipairs(entries) do
    local color = COLORS[entry.colorKey] or COLORS.circuit

    local stamp = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stamp:SetJustifyH("LEFT")
    stamp:SetWidth(TIMESTAMP_WIDTH)
    stamp:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -logY)
    -- Display HH:MM (stored as HH:MM:SS for export precision)
    local displayStamp = (entry.timestamp or ""):sub(1, 5)
    stamp:SetText(stampColorStr .. displayStamp .. "|r")

    local msg = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msg:SetJustifyH("LEFT")
    msg:SetWordWrap(true)
    msg:SetWidth(messageWidth)
    msg:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", TIMESTAMP_WIDTH, -logY)
    msg:SetText(entry.text or "")
    msg:SetTextColor(color[1], color[2], color[3])

    logY = logY + math.max(msg:GetStringHeight(), LOG_LINE_HEIGHT)
  end

  scrollChild:SetHeight(math.max(logY, 1))

  -- Scroll to bottom
  scrollFrame:UpdateScrollChildRect()
  C_Timer.After(0.05, function()
    if scrollFrame then
      scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange())
    end
  end)

  -- ========================================================================
  -- CLOSE BUTTON
  -- ========================================================================
  local actionButton = Addon.actionButton
  local closeBtn = actionButton:create(summaryFrame, {
    text = "Close",
    size = "medium",
    style = 1,
    fixedWidth = 100,
    onClick = function()
      summaryFrame:Hide()
    end,
  })
  closeBtn:SetPoint("BOTTOM", summaryFrame, "BOTTOM", 0, PADDING + 4)

  summaryFrame:Show()
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function circuitSummary:show(payload)
  createFrame(payload)
end

function circuitSummary:hide()
  if summaryFrame then
    summaryFrame:Hide()
  end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function circuitSummary:initialize()
  events = Addon.events

  -- Show summary on circuit completion
  -- Short delay for final rewards, then show
  events:subscribe("CIRCUIT:COMPLETED", function(eventName, payload)
    -- Extract completion data from state machine payload format
    local data = payload
    if payload and payload.context then
      data = payload.context
    end

    -- Brief delay for any final reward messages, then show
    C_Timer.After(2, function()
      -- Hide the live log now that summary is taking over
      if Addon.circuitLog then
        Addon.circuitLog:endPostCompletionCapture()
        Addon.circuitLog:hide()
      end
      circuitSummary:show(data)
    end)
  end, circuitSummary)

  return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
  Addon.registerModule("circuitSummary", {
    "utils", "events", "circuitPersistence", "circuitConstants",
    "popupFactory", "actionButton", "circuitLog"
  }, function()
    return circuitSummary:initialize()
  end)
end

return circuitSummary