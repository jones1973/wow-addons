--[[
  ui/persistentBar.lua
  Persistent Status Bar (Footer)
  
  Displays status information in footer layout:
  - Collection stats: filtered / owned / total (with pet icon)
  - Achievement stats: completed / total / points (with trophy icon)
  - Battle stats: W-L record + queue status (with battle icon)
  
  Layout: [Pet] 234 / 891 / 1832 | [Trophy] 23 / 45 / 847 | [Swords] 12 - 5 / 7 of 10 • Queued 2:34
  
  Dependencies: constants, utils, events, teamManagement, statsManager, options, achievementLogic, tabs
  Exports: Addon.persistentBar
]]

local ADDON_NAME, Addon = ...

local persistentBar = {}

-- Module references
local constants, utils, events, teamManagement, statsManager, options, achievementLogic, tabs

-- UI state
local barFrame = nil

-- Pet collection stats
local petCountOwned = 0
local petCountTotal = 0

-- Achievement stats
local achievementCompleted = 0
local achievementTotal = 0
local achievementPoints = 0

-- Update timer
local updateTimer = nil

-- Proposal timer state
local PROPOSAL_TIMEOUT = 30  -- Seconds to accept/decline a match
local proposalTimerFrame = nil
local proposalExpires = 0
local acceptButtonHooked = false
local waitingFrame = nil

-- Icon IDs/paths (same as header where applicable)
local ICON_PET = 613074
local ICON_TROPHY = 235410
local ICON_BATTLE = 136435  -- Interface\Minimap\ObjectIcons
local ICON_BATTLE_TEXCOORD = {0.505, 0.62, 0.65, 0.74}  -- Crossed swords (tight crop)

-- ============================================================================
-- FOOTER LAYOUT
-- ============================================================================

--[[
  Create footer layout
  Status bar with three icon+text groups distributed across the width.
  
  @param parent frame - Parent frame (main window)
  @return frame
]]
local function createFooter(parent)
  local L = constants.LAYOUT
  local footer = CreateFrame("Frame", nil, parent)
  footer:SetHeight(L.PERSISTENT_BAR_FOOTER_HEIGHT)
  
  -- Background
  local bg = footer:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.08, 0.08, 0.08, 0.95)
  footer.bg = bg
  
  -- Top border
  local border = footer:CreateTexture(nil, "BORDER")
  border:SetHeight(2)
  border:SetPoint("TOPLEFT")
  border:SetPoint("TOPRIGHT")
  border:SetColorTexture(0.3, 0.3, 0.3, 1)
  
  local iconSize = 20
  local groupSpacing = 24  -- Space between divider and next group
  local edgePadding = 12
  
  -- ========================================
  -- Group 1: Collection (left side)
  -- [Pet Icon] filtered / owned / total
  -- ========================================
  
  local petIcon = footer:CreateTexture(nil, "ARTWORK")
  petIcon:SetSize(iconSize, iconSize)
  petIcon:SetPoint("LEFT", footer, "LEFT", edgePadding, -1)
  petIcon:SetTexture(ICON_PET)
  footer.petIcon = petIcon
  
  local petCountText = footer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  petCountText:SetPoint("LEFT", petIcon, "RIGHT", 6, 0)
  petCountText:SetText("0 / 0 / 0")
  petCountText:SetTextColor(0.8, 0.8, 0.8)
  footer.petCountText = petCountText
  
  -- Tooltip frame for collection group
  local petCountFrame = CreateFrame("Frame", nil, footer)
  petCountFrame:SetPoint("LEFT", petIcon, "LEFT", -4, 0)
  petCountFrame:SetHeight(L.PERSISTENT_BAR_FOOTER_HEIGHT - 4)
  petCountFrame:EnableMouse(true)
  footer.petCountFrame = petCountFrame
  
  local function updatePetCountFrameWidth()
    local iconWidth = iconSize + 6
    local textWidth = petCountText:GetStringWidth()
    petCountFrame:SetWidth(iconWidth + textWidth + 8)
  end
  footer.updatePetCountFrameWidth = updatePetCountFrameWidth
  
  petCountFrame:SetScript("OnEnter", function(self)
    local tip = Addon.tooltip
    if tip then
      tip:show(self, {anchor = "TOPLEFT", relPoint = "BOTTOMLEFT", offsetY = -5})
      tip:header("Collection Status", {color = {1, 0.82, 0}})
      tip:space(4)
      tip:text(string.format("|cff88ccff%d|r - Pets you own", petCountOwned), {wrap = true})
      tip:space(2)
      tip:text(string.format("|cffcccccc%d|r - Total collectible pets", petCountTotal), {wrap = true})
      tip:done()
    end
  end)
  
  petCountFrame:SetScript("OnLeave", function()
    if Addon.tooltip then
      Addon.tooltip:hide()
    end
  end)
  
  -- Check if achievements tab is enabled
  local achievementsEnabled = tabs and tabs:isEnabled("achievements")
  
  -- ========================================
  -- Group 2: Achievements (center) - only if enabled
  -- [Trophy Icon] completed / total / points
  -- ========================================
  
  if achievementsEnabled then
    -- Divider 1 (after collection, before achievements)
    local div1 = footer:CreateTexture(nil, "ARTWORK")
    div1:SetWidth(1)
    div1:SetHeight(L.PERSISTENT_BAR_FOOTER_HEIGHT - 8)
    div1:SetPoint("LEFT", petCountText, "RIGHT", groupSpacing, 0)
    div1:SetColorTexture(0.3, 0.3, 0.3, 1)
    footer.div1 = div1
    
    local trophyIcon = footer:CreateTexture(nil, "ARTWORK")
    trophyIcon:SetSize(iconSize, iconSize)
    trophyIcon:SetPoint("LEFT", div1, "RIGHT", groupSpacing, 0)
    trophyIcon:SetTexture(ICON_TROPHY)
    trophyIcon:SetTexCoord(0, 0.5, 0, 0.44)  -- Crop to left shield only
    footer.trophyIcon = trophyIcon
    
    local achievementText = footer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    achievementText:SetPoint("LEFT", trophyIcon, "RIGHT", 6, 0)
    achievementText:SetText("0 / 0 / 0")
    achievementText:SetTextColor(0.8, 0.8, 0.8)
    footer.achievementText = achievementText
    
    -- Clickable frame for achievement group
    local achievementFrame = CreateFrame("Button", nil, footer)
    achievementFrame:SetPoint("LEFT", trophyIcon, "LEFT", -4, 0)
    achievementFrame:SetHeight(L.PERSISTENT_BAR_FOOTER_HEIGHT - 4)
    achievementFrame:EnableMouse(true)
    footer.achievementFrame = achievementFrame
    
    -- Hover background
    local achievementHoverBg = achievementFrame:CreateTexture(nil, "BACKGROUND")
    achievementHoverBg:SetAllPoints()
    achievementHoverBg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
    achievementHoverBg:Hide()
    achievementFrame.hoverBg = achievementHoverBg
    
    local function updateAchievementFrameWidth()
      local iconWidth = iconSize + 6
      local textWidth = achievementText:GetStringWidth()
      achievementFrame:SetWidth(iconWidth + textWidth + 8)
    end
    footer.updateAchievementFrameWidth = updateAchievementFrameWidth
    
    achievementFrame:SetScript("OnEnter", function(self)
      self.hoverBg:Show()
      
      local tip = Addon.tooltip
      if tip then
        tip:show(self, {anchor = "TOPLEFT", relPoint = "BOTTOMLEFT", offsetY = -5})
        tip:header("Pet Battle Achievements", {color = {1, 0.82, 0}})
        tip:space(4)
        tip:text(string.format("|cff88ff88%d|r - Achievements completed", achievementCompleted), {wrap = true})
        tip:space(2)
        tip:text(string.format("|cff88ccff%d|r - Total achievements", achievementTotal), {wrap = true})
        tip:space(2)
        tip:text(string.format("|cffffcc00%d|r - Achievement points earned", achievementPoints), {wrap = true})
        tip:space(4)
        tip:text("|cff888888Click to view achievements|r")
        tip:done()
      end
    end)
    
    achievementFrame:SetScript("OnLeave", function(self)
      self.hoverBg:Hide()
      if Addon.tooltip then
        Addon.tooltip:hide()
      end
    end)
    
    achievementFrame:SetScript("OnClick", function()
      if tabs then
        tabs:select("achievements")
      end
    end)
    
    -- Divider 2 (after achievements, before battle)
    local div2 = footer:CreateTexture(nil, "ARTWORK")
    div2:SetWidth(1)
    div2:SetHeight(L.PERSISTENT_BAR_FOOTER_HEIGHT - 8)
    div2:SetPoint("LEFT", achievementText, "RIGHT", groupSpacing, 0)
    div2:SetColorTexture(0.3, 0.3, 0.3, 1)
    footer.div2 = div2
  end
  
  -- ========================================
  -- Group 3: Battle (right side)
  -- [Battle Icon] W - L • Status
  -- ========================================
  
  -- Queue timer (fixed-width, rightmost element when queued)
  local queueTimer = footer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  queueTimer:SetPoint("RIGHT", footer, "RIGHT", -edgePadding, -1)
  -- Fixed width prevents jitter from changing digits — fits "999:59"
  queueTimer:SetWidth(48)
  queueTimer:SetJustifyH("RIGHT")
  queueTimer:SetText("")
  queueTimer:SetTextColor(0, 1, 0)
  queueTimer:Hide()
  footer.timerText = queueTimer
  
  -- Queue status text (rightmost when not queued, left of timer when queued)
  local queueStatus = footer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  queueStatus:SetPoint("RIGHT", footer, "RIGHT", -edgePadding, -1)
  queueStatus:SetText("Not Queued")
  queueStatus:SetTextColor(0.6, 0.6, 0.6)
  footer.statusText = queueStatus
  
  -- Queue dot (left of status text)
  local queueDot = footer:CreateTexture(nil, "OVERLAY")
  queueDot:SetSize(8, 8)
  queueDot:SetPoint("RIGHT", queueStatus, "LEFT", -4, 0)
  queueDot:SetTexture("Interface\\Common\\Indicator-Gray")
  footer.queueDot = queueDot
  
  -- W-L record (left of queue dot)
  local recordText = footer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  recordText:SetPoint("RIGHT", queueDot, "LEFT", -8, 0)
  recordText:SetText("0 - 0")
  recordText:SetTextColor(0.8, 0.8, 0.8)
  footer.recordText = recordText
  
  -- Battle icon (left of record)
  local battleIcon = footer:CreateTexture(nil, "ARTWORK")
  battleIcon:SetSize(iconSize, iconSize)
  battleIcon:SetPoint("RIGHT", recordText, "LEFT", -6, 0)
  battleIcon:SetTexture(ICON_BATTLE)
  battleIcon:SetTexCoord(unpack(ICON_BATTLE_TEXCOORD))
  footer.battleIcon = battleIcon
  
  -- Tooltip frame for battle group (clickable to toggle queue)
  local battleFrame = CreateFrame("Button", nil, footer)
  battleFrame:SetPoint("LEFT", battleIcon, "LEFT", -4, 0)
  battleFrame:SetPoint("RIGHT", footer, "RIGHT", 0, 0)
  battleFrame:SetHeight(L.PERSISTENT_BAR_FOOTER_HEIGHT - 4)
  battleFrame:RegisterForClicks("LeftButtonUp")
  footer.battleFrame = battleFrame
  
  -- Hover background for visual feedback
  local battleHoverBg = battleFrame:CreateTexture(nil, "BACKGROUND")
  battleHoverBg:SetAllPoints()
  battleHoverBg:SetColorTexture(0.3, 0.3, 0.3, 0.3)
  battleHoverBg:Hide()
  battleFrame.hoverBg = battleHoverBg
  
  battleFrame:SetScript("OnEnter", function(self)
    self.hoverBg:Show()
    local tip = Addon.tooltip
    if tip then
      tip:show(self, {anchor = "TOPRIGHT", relPoint = "BOTTOMRIGHT", offsetY = -5})
      tip:header("Battle Status", {color = {1, 0.82, 0}})
      tip:space(4)
      
      local wins, losses = 0, 0
      if statsManager then
        wins, losses = statsManager:getRecord()
      end
      tip:text(string.format("|cff88ff88%d|r Wins  |cffff8888%d|r Losses", wins, losses), {wrap = true})
      
      -- Opponent history (session, most recent first)
      if statsManager then
        local history = statsManager:getOpponentHistory()
        if #history > 0 then
          tip:space(4)
          for _, entry in ipairs(history) do
            local nameStr = entry.name or entry.guid or "Unknown"
            if entry.realm and entry.realm ~= "" then
              nameStr = nameStr .. "-" .. entry.realm
            end
            if entry.forfeit then
              nameStr = nameStr .. " |cffcccccc(F)|r"
            end
            local resultColor = entry.result == "win" and "|cff88ff88W|r" or "|cffff8888L|r"
            local timeStr = date("%H:%M", entry.timestamp)
            tip:text(string.format("|cff888888%s|r  %s  %s", timeStr, resultColor, nameStr))
          end
        end
      end
      
      -- Weekly quest progress
      if statsManager then
        local hasQuest, numWins, numRequired, isComplete = statsManager:getWeeklyQuestProgress()
        if hasQuest then
          tip:space(4)
          if isComplete then
            tip:text(string.format("|cffffcc00Weekly:|r |cff88ff88%d / %d|r (Ready to turn in!)", numWins, numRequired), {wrap = true})
          else
            tip:text(string.format("|cffffcc00Weekly:|r %d / %d PVP wins", numWins, numRequired), {wrap = true})
          end
        end
      end
      
      -- PVP achievement progress (only if achievements tab is enabled)
      if statsManager and tabs and tabs:isEnabled("achievements") then
        local pvpAchievements = statsManager:getPvpAchievementProgress()
        if #pvpAchievements > 0 then
          tip:space(4)
          for _, achieve in ipairs(pvpAchievements) do
            tip:text(string.format("|cffffcc00%s:|r %d / %d", achieve.name, achieve.current, achieve.required), {wrap = true})
          end
        end
      end
      
      -- Queue status and duration info
      local isQueued = teamManagement and teamManagement:getQueueState()
      tip:space(4)
      if isQueued then
        tip:text("|cff00ff00Currently queued for PvP battle|r")
        -- Show last completed queue duration as reference
        if statsManager then
          local lastDuration = statsManager:getLastQueueDuration()
          if lastDuration then
            local durMin = math.floor(lastDuration / 60)
            local durSec = math.floor(lastDuration % 60)
            tip:text(string.format("|cff888888Last wait: %d:%02d|r", durMin, durSec))
          end
        end
        -- Queue event log
        if statsManager then
          local log = statsManager:getQueueEventLog()
          if #log > 0 then
            tip:space(4)
            for _, entry in ipairs(log) do
              local min = math.floor(entry.elapsed / 60)
              local sec = math.floor(entry.elapsed % 60)
              tip:text(string.format("|cff888888%d:%02d|r  %s", min, sec, entry.text))
            end
          end
        end
        tip:space(4)
        tip:text("Click to leave queue", {color = {0.5, 1, 0.5}})
        local isAutoRequeue = statsManager and statsManager:getAutoRequeue()
        if isAutoRequeue then
          tip:text("|cff00ff00Auto-requeue enabled|r")
        else
          tip:text("Shift-click to auto-requeue after battles", {color = {0.5, 1, 0.5}})
        end
      else
        tip:text("|cff888888Not currently queued|r")
        -- Show last queue duration if available
        if statsManager then
          local lastDuration = statsManager:getLastQueueDuration()
          if lastDuration then
            local durMin = math.floor(lastDuration / 60)
            local durSec = math.floor(lastDuration % 60)
            tip:text(string.format("|cff888888Last wait: %d:%02d|r", durMin, durSec))
          end
        end
        tip:space(4)
        tip:text("Click to find battle", {color = {0.5, 1, 0.5}})
        local isAutoRequeue = statsManager and statsManager:getAutoRequeue()
        if isAutoRequeue then
          tip:text("|cff00ff00Auto-requeue enabled|r")
        else
          tip:text("Shift-click to auto-requeue after battles", {color = {0.5, 1, 0.5}})
        end
      end
      tip:done()
    end
  end)
  
  battleFrame:SetScript("OnLeave", function(self)
    self.hoverBg:Hide()
    if Addon.tooltip then
      Addon.tooltip:hide()
    end
  end)
  
  battleFrame:SetScript("OnClick", function()
    if IsShiftKeyDown() then
      -- Shift-click: enable auto-requeue and queue if not already
      if statsManager then
        statsManager:setAutoRequeue(true)
      end
      if teamManagement and not teamManagement:getQueueState() then
        teamManagement:findBattle()
      end
    else
      -- Normal click: disable auto-requeue if on, then toggle queue
      if statsManager and statsManager:getAutoRequeue() then
        statsManager:setAutoRequeue(false)
      end
      if teamManagement and teamManagement.findBattle then
        teamManagement:findBattle()
      end
    end
  end)
  
  return footer
end

-- ============================================================================
-- PROPOSAL COUNTDOWN BAR & AUTO-DISMOUNT
-- Attached below PetBattleQueueReadyFrame, created lazily on first proposal.
-- Auto-dismounts on proposal to prevent match cancellation.
-- ============================================================================

local function createProposalBar()
  local readyFrame = PetBattleQueueReadyFrame
  if not readyFrame then return nil end
  
  local bar = CreateFrame("Frame", nil, readyFrame)
  bar:SetHeight(4)
  bar:SetPoint("TOPLEFT", readyFrame, "BOTTOMLEFT", 0, -2)
  bar:SetPoint("TOPRIGHT", readyFrame, "BOTTOMRIGHT", 0, -2)
  bar:Hide()
  
  -- Background track
  local bg = bar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0.6)
  
  local fill = bar:CreateTexture(nil, "OVERLAY")
  fill:SetHeight(4)
  fill:SetPoint("LEFT")
  fill:SetColorTexture(0.2, 0.8, 0.2, 1)
  bar.fill = fill
  
  -- Dismount notice text (below the countdown bar)
  local dismountText = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  dismountText:SetPoint("TOP", bar, "BOTTOM", 0, -4)
  dismountText:SetText("|cffffcc00You are mounted — Accept will dismount|r")
  dismountText:Hide()
  bar.dismountText = dismountText
  
  bar:SetScript("OnUpdate", function(self)
    local remaining = proposalExpires - GetTime()
    if remaining <= 0 then
      self:Hide()
      self.dismountText:Hide()
      return
    end
    local ratio = remaining / PROPOSAL_TIMEOUT
    local barWidth = readyFrame:GetWidth() * ratio
    fill:SetWidth(math.max(barWidth, 1))
  end)
  
  return bar
end

-- ============================================================================
-- WAITING FOR OPPONENT FRAME
-- Shown after we accept, hidden when battle starts or opponent declines.
-- ============================================================================

local function createWaitingFrame()
  local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  frame:SetSize(260, 50)
  frame:SetPoint("TOP", UIParent, "TOP", 0, -135)
  frame:SetFrameStrata("DIALOG")
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  frame:SetBackdropColor(0, 0, 0, 0.8)
  frame:Hide()
  
  local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("CENTER", frame, "CENTER", 0, 8)
  text:SetText("Waiting for opponent...")
  
  -- Countdown bar
  local barBg = frame:CreateTexture(nil, "ARTWORK")
  barBg:SetHeight(6)
  barBg:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 10)
  barBg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 10)
  barBg:SetColorTexture(0, 0, 0, 0.4)
  
  local barFill = frame:CreateTexture(nil, "OVERLAY")
  barFill:SetHeight(6)
  barFill:SetPoint("LEFT", barBg, "LEFT")
  barFill:SetColorTexture(0.2, 0.8, 0.2, 1)
  frame.barFill = barFill
  frame.barBg = barBg
  
  frame:SetScript("OnUpdate", function(self)
    local remaining = proposalExpires - GetTime()
    if remaining <= 0 then
      self:Hide()
      return
    end
    local ratio = remaining / PROPOSAL_TIMEOUT
    local barWidth = barBg:GetWidth() * ratio
    barFill:SetWidth(math.max(barWidth, 1))
  end)
  
  return frame
end

-- ============================================================================
-- UPDATE FUNCTIONS
-- ============================================================================

--[[
  Update Stats Display
  Refreshes W/L record text. Appends weekly quest progress when active.
  Format: "3 - 1" or "3 - 1 / 7 of 10" when quest is in log
]]
function persistentBar:updateStats()
  if not barFrame or not barFrame.recordText then return end
  if not statsManager then return end
  
  local wins, losses = statsManager:getRecord()
  local recordStr = string.format("%d - %d", wins, losses)
  
  -- Append weekly quest progress if active
  local hasQuest, numWins, numRequired = statsManager:getWeeklyQuestProgress()
  if hasQuest then
    recordStr = string.format("%s / %d of %d", recordStr, numWins, numRequired)
  end
  
  barFrame.recordText:SetText(recordStr)
end

--[[
  Update Queue Status
  Refreshes queue status indicator. Shows elapsed time in fixed-width
  timer to prevent layout jitter from changing digit widths.
]]
function persistentBar:updateQueueStatus()
  if not barFrame or not barFrame.statusText then return end
  if not teamManagement then return end
  
  local isQueued = teamManagement:getQueueState()
  
  if isQueued then
    -- Timer: show elapsed time in fixed-width element
    if barFrame.timerText then
      local _, _, queuedTime = C_PetBattles.GetPVPMatchmakingInfo()
      if queuedTime and queuedTime > 0 then
        local elapsed = GetTime() - queuedTime
        local minutes = math.floor(elapsed / 60)
        local seconds = math.floor(elapsed % 60)
        barFrame.timerText:SetText(string.format("%d:%02d", minutes, seconds))
      else
        barFrame.timerText:SetText("0:00")
      end
      barFrame.timerText:Show()
    end
    
    -- Status: re-anchor left of timer
    barFrame.statusText:ClearAllPoints()
    barFrame.statusText:SetPoint("RIGHT", barFrame.timerText, "LEFT", -4, 0)
    barFrame.statusText:SetText("Queued")
    barFrame.statusText:SetTextColor(0, 1, 0)
    if barFrame.queueDot then
      barFrame.queueDot:SetTexture("Interface\\Common\\Indicator-Green")
    end
  else
    -- Timer: hide and clear
    if barFrame.timerText then
      barFrame.timerText:Hide()
      barFrame.timerText:SetText("")
    end
    
    -- Hide proposal countdown if still visible
    if proposalTimerFrame then proposalTimerFrame:Hide() end
    
    -- Status: anchor to right edge
    barFrame.statusText:ClearAllPoints()
    barFrame.statusText:SetPoint("RIGHT", barFrame, "RIGHT", -12, -1)
    barFrame.statusText:SetText("Not Queued")
    barFrame.statusText:SetTextColor(0.6, 0.6, 0.6)
    if barFrame.queueDot then
      barFrame.queueDot:SetTexture("Interface\\Common\\Indicator-Gray")
    end
  end
end

--[[
  Update Pet Counts (owned/total)
  Called when COLLECTION:COUNTS event fires.
  
  @param owned number - Number of owned pets
  @param total number - Total available pets
]]
function persistentBar:updatePetCounts(owned, total)
  petCountOwned = owned or 0
  petCountTotal = total or 0
  self:updatePetCountDisplay()
end

--[[
  Update Pet Count Display
  Updates the display text with current count values.
  Format: "owned / total"
]]
function persistentBar:updatePetCountDisplay()
  if not barFrame or not barFrame.petCountText then return end
  
  local displayText = string.format("%d / %d", petCountOwned, petCountTotal)
  barFrame.petCountText:SetText(displayText)
  
  -- Update tooltip frame width to match text
  if barFrame.updatePetCountFrameWidth then
    barFrame.updatePetCountFrameWidth()
  end
  
  -- Reposition divider with consistent spacing
  if barFrame.div1 then
    barFrame.div1:ClearAllPoints()
    barFrame.div1:SetPoint("LEFT", barFrame.petCountText, "RIGHT", 24, 0)
  end
end

--[[
  Update Achievement Stats
  Fetches and displays current achievement progress.
]]
function persistentBar:updateAchievements()
  if not barFrame or not barFrame.achievementText then return end
  
  -- Get completed/total from achievementLogic
  if achievementLogic then
    achievementCompleted, achievementTotal = achievementLogic:getTotalCounts()
  end
  
  -- Get points from API (15117 = Pet Battles category ID)
  achievementPoints = GetCategoryAchievementPoints(15117, true) or 0
  
  local displayText = string.format("%d / %d / %d", achievementCompleted, achievementTotal, achievementPoints)
  barFrame.achievementText:SetText(displayText)
  
  -- Update frame width and reposition divider
  if barFrame.updateAchievementFrameWidth then
    barFrame.updateAchievementFrameWidth()
  end
  
  if barFrame.div2 then
    barFrame.div2:ClearAllPoints()
    barFrame.div2:SetPoint("LEFT", barFrame.achievementText, "RIGHT", 24, 0)
  end
end

--[[
  Refresh All
  Updates all dynamic elements.
]]
function persistentBar:refresh()
  self:updateStats()
  self:updateQueueStatus()
  self:updateAchievements()
end

-- ============================================================================
-- CREATION & DESTRUCTION
-- ============================================================================

--[[
  Create Persistent Bar
  Creates footer status bar.
  
  @param parent frame - Parent frame (main window)
  @return frame
]]
function persistentBar:create(parent)
  if barFrame then
    self:destroy()
  end
  
  barFrame = createFooter(parent)
  
  -- Initial data refresh
  self:refresh()
  
  -- Start update timer (1 second updates for queue elapsed time and quest progress)
  updateTimer = C_Timer.NewTicker(1, function()
    persistentBar:updateQueueStatus()
    persistentBar:updateStats()
  end)
  
  -- Subscribe to events
  if events then
    events:subscribe("STATS:UPDATED", function() persistentBar:updateStats() end)
    events:subscribe("PET_BATTLE_QUEUE_STATUS", function()
      persistentBar:updateQueueStatus()
      -- Hide waiting frame if we left the queue
      if waitingFrame and teamManagement and not teamManagement:getQueueState() then
        waitingFrame:Hide()
      end
    end)
    events:subscribe("PET_BATTLE_PVP_DUEL_REQUESTED", function() persistentBar:updateQueueStatus() end)
    events:subscribe("COLLECTION:COUNTS", function(eventName, payload) 
      persistentBar:updatePetCounts(payload.owned, payload.total) 
    end)
    events:subscribe("ACHIEVEMENTS:DATA_REFRESHED", function()
      persistentBar:updateAchievements()
    end)
    events:subscribe("ACHIEVEMENT_EARNED", function()
      persistentBar:updateAchievements()
    end)
    
    -- Proposal countdown timer and auto-dismount on accept
    events:subscribe("PET_BATTLE_QUEUE_PROPOSE_MATCH", function()
      if not proposalTimerFrame then
        proposalTimerFrame = createProposalBar()
      end
      if proposalTimerFrame then
        proposalExpires = GetTime() + PROPOSAL_TIMEOUT
        proposalTimerFrame:Show()
        -- Show mounted warning proactively
        if proposalTimerFrame.dismountText then
          if IsMounted() or IsFlying() then
            proposalTimerFrame.dismountText:Show()
          else
            proposalTimerFrame.dismountText:Hide()
          end
        end
      end
      
      -- Hook Accept button (once)
      local readyFrame = PetBattleQueueReadyFrame
      if readyFrame and readyFrame.AcceptButton and not acceptButtonHooked then
        -- PreClick: dismount if grounded
        readyFrame.AcceptButton:HookScript("PreClick", function()
          if IsMounted() and not IsFlying() then
            Dismount()
          end
        end)
        -- PostClick: show waiting frame
        readyFrame.AcceptButton:HookScript("PostClick", function()
          if proposalTimerFrame then
            proposalTimerFrame:Hide()
            if proposalTimerFrame.dismountText then proposalTimerFrame.dismountText:Hide() end
          end
          if not waitingFrame then
            waitingFrame = createWaitingFrame()
          end
          if waitingFrame then
            waitingFrame:Show()
          end
        end)
        acceptButtonHooked = true
      end
    end)
    events:subscribe("PET_BATTLE_QUEUE_PROPOSAL_ACCEPTED", function()
      -- Both players accepted — battle starting, clean up
      if proposalTimerFrame then
        proposalTimerFrame:Hide()
        if proposalTimerFrame.dismountText then proposalTimerFrame.dismountText:Hide() end
      end
      if waitingFrame then waitingFrame:Hide() end
    end)
    events:subscribe("PET_BATTLE_QUEUE_PROPOSAL_DECLINED", function()
      if proposalTimerFrame then
        proposalTimerFrame:Hide()
        if proposalTimerFrame.dismountText then proposalTimerFrame.dismountText:Hide() end
      end
      if waitingFrame then waitingFrame:Hide() end
    end)
    events:subscribe("PET_BATTLE_OPENING_START", function()
      if waitingFrame then waitingFrame:Hide() end
    end)
  end
  
  return barFrame
end

--[[
  Destroy Persistent Bar
  Tears down current bar completely.
]]
function persistentBar:destroy()
  if updateTimer then
    updateTimer:Cancel()
    updateTimer = nil
  end
  
  proposalTimerFrame = nil
  
  if waitingFrame then
    waitingFrame:Hide()
    waitingFrame = nil
  end
  
  if barFrame then
    barFrame:Hide()
    barFrame:SetParent(nil)
    barFrame = nil
  end
end

--[[
  Get Required Space
  Returns width/height consumed by footer layout.
  
  @return table - {width, height}
]]
function persistentBar:getRequiredSpace()
  return {
    width = 0,
    height = constants.LAYOUT.PERSISTENT_BAR_FOOTER_HEIGHT,
  }
end

--[[
  Get Frame
  Returns the persistent bar frame.
  
  @return frame|nil
]]
function persistentBar:getFrame()
  return barFrame
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

Addon.persistentBar = persistentBar

if Addon.registerModule then
  Addon.registerModule("persistentBar", {
    "constants", "utils", "events", "teamManagement", "statsManager", "options", "achievementLogic", "tabs"
  }, function()
    constants = Addon.constants
    utils = Addon.utils
    events = Addon.events
    teamManagement = Addon.teamManagement
    statsManager = Addon.statsManager
    options = Addon.options
    achievementLogic = Addon.achievementLogic
    tabs = Addon.tabs
    return true
  end)
end

return persistentBar