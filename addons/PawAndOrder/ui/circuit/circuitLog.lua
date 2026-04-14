--[[
  ui/circuit/circuitLog.lua
  Circuit Log

  Displays a running log of events during circuit runs:
  XP gains, level-ups, victories, captures, rewards. Anchored below the
  circuit tracker, same width, scrollable with last few entries visible.

  Persisted in pao_circuit.log across reloads/relogs. Cleared only when
  a new circuit starts, so the previous circuit's log is available for
  review until then.

  Event sources:
  - CIRCUIT:STARTED / COMPLETED / CANCELLED - circuit lifecycle
  - CIRCUIT:PROGRESS_UPDATED - victory (NPC defeated)
  - PET_BATTLE_OPENING_START - snapshot team XP/levels
  - PET_BATTLE_OVER - diff snapshots for XP gains and level-ups
  - PETS:NEW_ACQUISITION - pet captured during circuit
  - QUEST_TURNED_IN / QUEST_COMPLETE - opens reward capture window
  - CHAT_MSG_LOOT - item rewards (buffered until trigger)
  - CHAT_MSG_CURRENCY - currency rewards (buffered until trigger)
  - CHAT_MSG_MONEY - gold rewards (buffered until trigger)
  - UNIT_AURA - XP buff gain/loss tracking

  Dependencies: utils, events, circuitPersistence, circuitConstants, circuitTracker
  Exports: Addon.circuitLog
]]

local ADDON_NAME, Addon = ...

local circuitLog = {}
Addon.circuitLog = circuitLog


-- Module references
local utils, events, persistence

-- UI
local logFrame = nil
local scrollFrame = nil
local scrollChild = nil
local logLines = {}       -- Array of {stamp, msg} font string pairs (pool)
local LINE_HEIGHT = 14
local VISIBLE_LINES = 5
local MAX_ENTRIES = 200
local LOG_PADDING = 16            -- Match tracker padding for consistent edges
local TIMESTAMP_WIDTH = 36        -- Fixed column width for "HH:MM"

-- Battle tracking: accumulate XP gains and level changes from events.
-- inCircuitBattle tracks whether XP accumulators are active for the current battle.
-- This is distinct from circuitBattleHandler.inBattle which gates event processing;
-- this flag gates accumulator flush in logBattleResults().
local battleXP = {}       -- {[petIndex] = totalXP}
local battleLevels = {}   -- {[petIndex] = {from, to}}
local battleNames = {}    -- {[petIndex] = name}
local inCircuitBattle = false

-- Reward capture: buffer loot/currency messages, flush on trigger
-- Solves timing issue where CHAT_MSG_LOOT fires milliseconds before QUEST_TURNED_IN
local REWARD_WINDOW = 5       -- seconds after trigger to capture
local REWARD_LOOKBACK = 2     -- seconds before trigger to retroactively capture
local lastRewardTriggerTime = 0
local pendingRewards = {}     -- {text, colorKey, gameTime} — buffered until trigger

-- Post-completion: keep capturing rewards until summary popup shows
local postCompletionCapture = false

-- XP buff tracking for gain/loss logging
local activeBuffs = {}        -- {[spellID] = true} — currently active XP buffs

-- ============================================================================
-- COLORS
-- ============================================================================

local COLORS = {
  victory   = { 0.2, 1.0, 0.2 },     -- Green
  defeat    = { 0.8, 0.3, 0.3 },     -- Soft red
  levelup   = { 1.0, 0.85, 0.0 },     -- Gold
  xp        = { 0.7, 0.7, 0.7 },      -- Grey
  capture   = { 0.4, 0.8, 1.0 },      -- Light blue
  reward    = { 0.9, 0.6, 1.0 },      -- Purple
  gold      = { 1.0, 0.84, 0.0 },     -- Gold
  circuit   = { 1.0, 0.82, 0.0 },     -- Yellow
  timestamp = { 0.4, 0.4, 0.4 },      -- Dark grey
}

-- ============================================================================
-- PERSISTENT STORAGE
-- ============================================================================

--[[
  Get the log entries array from SavedVariables.
  Initializes pao_circuit.log if needed.
  @return table - Array of {text, colorKey, timestamp}
]]
local function getEntries()
  if not pao_circuit then pao_circuit = {} end
  if not pao_circuit.log then pao_circuit.log = {} end
  return pao_circuit.log
end

-- ============================================================================
-- ENTRY MANAGEMENT
-- ============================================================================

--[[
  Add a log entry.
  @param text string - Message text
  @param colorKey string - Key into COLORS table (e.g. "victory", "xp")
]]
local function addEntry(text, colorKey)
  local entries = getEntries()
  -- Store with seconds precision; display truncates to HH:MM
  local stamp = date("%H:%M:%S")
  table.insert(entries, {
    text = text,
    colorKey = colorKey or "circuit",
    timestamp = stamp,
  })

  -- Cap entries
  if #entries > MAX_ENTRIES then
    table.remove(entries, 1)
  end

  -- Show and render (creates frame if needed)
  circuitLog:show()
end

--[[
  Clear all entries.
]]
local function clearEntries()
  if pao_circuit then
    pao_circuit.log = {}
  end
  if logFrame and logFrame:IsShown() then
    circuitLog:render()
  end
end

-- ============================================================================
-- REWARD BUFFERING
-- ============================================================================

--[[
  Add a reward message to the pending buffer.
  Messages are held until a trigger (quest turn-in, battle over) confirms
  they're circuit-related.
  @param text string
  @param colorKey string
]]
local function bufferReward(text, colorKey)
  table.insert(pendingRewards, {
    text = text,
    colorKey = colorKey,
    gameTime = GetTime(),
  })
  -- Prune old entries (>30s)
  local cutoff = GetTime() - 30
  for i = #pendingRewards, 1, -1 do
    if pendingRewards[i].gameTime < cutoff then
      table.remove(pendingRewards, i)
    end
  end
end

--[[
  Flush pending rewards within the lookback window.
  Called when a reward trigger fires. Also opens the forward capture window.
]]
local function flushPendingRewards()
  local now = GetTime()
  lastRewardTriggerTime = now
  local cutoff = now - REWARD_LOOKBACK

  for i = #pendingRewards, 1, -1 do
    local pending = pendingRewards[i]
    if pending.gameTime >= cutoff then
      addEntry(pending.text, pending.colorKey)
      table.remove(pendingRewards, i)
    end
  end
end

--[[
  Check if within the forward reward capture window.
  @return boolean
]]
local function inRewardWindow()
  return (GetTime() - lastRewardTriggerTime) <= REWARD_WINDOW
end

--[[
  Check if we should be capturing rewards.
  True during active circuit OR during post-completion capture window.
]]
local function shouldCaptureRewards()
  if postCompletionCapture then return true end
  local persistence = Addon.circuitPersistence
  return persistence and persistence:isCircuitActive()
end

-- ============================================================================
-- BUFF TRACKING
-- ============================================================================

--[[
  Get XP buff spell IDs from constants.
  @return table - {[spellID] = buffKey}
]]
local function getXPBuffSpells()
  local result = {}
  local xpBuff = Addon.constants and Addon.constants.XP_BUFF
  if xpBuff and xpBuff.SPELL_IDS then
    for key, spellID in pairs(xpBuff.SPELL_IDS) do
      result[spellID] = key
    end
  end
  return result
end

--[[
  Get display name for a buff key.
  @param buffKey string - e.g. "SAFARI_HAT"
  @return string
]]
local function getBuffDisplayName(buffKey)
  local names = {
    SAFARI_HAT = "Safari Hat",
    LESSER_PET_TREAT = "Lesser Pet Treat",
    PET_TREAT = "Pet Treat",
    DARKMOON_TOP_HAT = "Darkmoon Top Hat",
  }
  return names[buffKey] or buffKey
end

--[[
  Get remaining duration string for a buff.
  @param expirationTime number - GetTime()-based expiration
  @param duration number - Total duration
  @return string - e.g. "47m remaining" or "permanent"
]]
local function getBuffDurationStr(expirationTime, duration)
  if not expirationTime or expirationTime == 0 then
    return "permanent"
  end
  local remaining = expirationTime - GetTime()
  if remaining <= 0 then return "expired" end
  local minutes = math.floor(remaining / 60)
  if minutes >= 60 then
    return string.format("%dh %dm remaining", math.floor(minutes / 60), minutes % 60)
  end
  return string.format("%dm remaining", minutes)
end

--[[
  Scan currently active XP buffs.
  @return table - {[spellID] = {buffKey, expirationTime, duration}}
]]
local function scanActiveXPBuffs()
  local xpSpells = getXPBuffSpells()
  local found = {}
  for i = 1, 40 do
    local name, _, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff("player", i)
    if not name then break end
    if spellId and xpSpells[spellId] then
      found[spellId] = {
        buffKey = xpSpells[spellId],
        expirationTime = expirationTime,
        duration = duration,
      }
    end
  end
  return found
end

--[[
  Log all currently active XP buffs (called at circuit start).
]]
local function logActiveBuffs()
  local found = scanActiveXPBuffs()
  wipe(activeBuffs)
  for spellID, info in pairs(found) do
    activeBuffs[spellID] = true
    local name = getBuffDisplayName(info.buffKey)
    local durStr = getBuffDurationStr(info.expirationTime, info.duration)
    addEntry(name .. " active (" .. durStr .. ")", "circuit")
  end
end

--[[
  Check for XP buff changes (gain or loss).
  Called on UNIT_AURA for player.
]]
local function checkBuffChanges()
  local xpSpells = getXPBuffSpells()
  local current = scanActiveXPBuffs()

  -- Check for new buffs (gained)
  for spellID, info in pairs(current) do
    if not activeBuffs[spellID] then
      activeBuffs[spellID] = true
      local name = getBuffDisplayName(info.buffKey)
      addEntry(name .. " activated", "circuit")
    end
  end

  -- Check for lost buffs
  for spellID in pairs(activeBuffs) do
    if not current[spellID] then
      activeBuffs[spellID] = nil
      local buffKey = xpSpells[spellID]
      if buffKey then
        local name = getBuffDisplayName(buffKey)
        addEntry(name .. " expired", "circuit")
      end
    end
  end
end

-- ============================================================================
-- BATTLE TRACKING
-- ============================================================================

--[[
  Reset battle accumulators at battle start.
  Captures pet names and starting levels for each slot.
]]
local function resetBattleTracking()
  wipe(battleXP)
  wipe(battleLevels)
  wipe(battleNames)
  for slot = 1, 3 do
    battleXP[slot] = 0
    local ok, name = pcall(C_PetBattles.GetName, Enum.BattlePetOwner.Ally, slot)
    battleNames[slot] = (ok and name) or ("Pet " .. slot)
    local okL, level = pcall(C_PetBattles.GetLevel, Enum.BattlePetOwner.Ally, slot)
    if okL and level then
      battleLevels[slot] = { from = level, to = level }
    end
  end
  inCircuitBattle = true
end

--[[
  Log accumulated XP and level changes at battle end.
]]
local function logBattleResults()
  if not inCircuitBattle then return end
  inCircuitBattle = false

  for slot = 1, 3 do
    local name = battleNames[slot] or ("Pet " .. slot)
    local xp = battleXP[slot] or 0
    local levels = battleLevels[slot]

    if levels and levels.to > levels.from then
      if xp > 0 then
        addEntry(string.format("%s +%d XP (%d -> %d)", name, xp, levels.from, levels.to), "levelup")
      else
        addEntry(string.format("%s leveled (%d -> %d)", name, levels.from, levels.to), "levelup")
      end
    elseif xp > 0 then
      addEntry(string.format("%s +%d XP", name, xp), "xp")
    end
  end
end

-- ============================================================================
-- UI CREATION
-- ============================================================================

--[[
  Create the log frame, anchored below the tracker.
]]
function circuitLog:createFrame()
  if logFrame then return logFrame end

  local tracker = Addon.circuitTracker:getFrame()
  if not tracker then
    utils:debug("circuitLog: tracker frame not available")
    return nil
  end

  local constants = Addon.circuitConstants
  local width = constants.UI.TRACKER_WIDTH

  -- Visible area height: visible lines + padding
  local contentHeight = (VISIBLE_LINES * LINE_HEIGHT) + (LOG_PADDING * 2)

  logFrame = CreateFrame("Frame", "PAOCircuitLog", UIParent, "BackdropTemplate")
  logFrame:SetSize(width, contentHeight)
  logFrame:SetPoint("TOPLEFT", tracker, "BOTTOMLEFT", 0, 2)
  logFrame:SetFrameStrata(tracker:GetFrameStrata())
  logFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  })
  logFrame:SetBackdropColor(0, 0, 0, 0.9)
  logFrame:Hide()

  -- Scroll frame for log content
  scrollFrame = CreateFrame("ScrollFrame", "PAOCircuitLogScroll", logFrame)
  scrollFrame:SetPoint("TOPLEFT", logFrame, "TOPLEFT", LOG_PADDING, -LOG_PADDING)
  scrollFrame:SetPoint("BOTTOMRIGHT", logFrame, "BOTTOMRIGHT", -LOG_PADDING, LOG_PADDING)
  scrollFrame:EnableMouseWheel(true)
  scrollFrame:SetScript("OnMouseWheel", function(self, delta)
    local current = self:GetVerticalScroll()
    local maxScroll = self:GetVerticalScrollRange()
    local newScroll = current - (delta * LINE_HEIGHT * 2)
    newScroll = math.max(0, math.min(newScroll, maxScroll))
    self:SetVerticalScroll(newScroll)
  end)

  scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetWidth(scrollFrame:GetWidth())
  scrollChild:SetHeight(1)
  scrollFrame:SetScrollChild(scrollChild)

  logFrame.scrollFrame = scrollFrame
  logFrame.scrollChild = scrollChild

  return logFrame
end

-- ============================================================================
-- RENDERING
-- ============================================================================

--[[
  Render all log entries and scroll to bottom.
]]
function circuitLog:render()
  if not scrollChild or not scrollFrame then return end

  local entries = getEntries()
  local availWidth = scrollFrame:GetWidth()
  local messageWidth = availWidth - TIMESTAMP_WIDTH

  -- Ensure enough line pairs (timestamp + message)
  while #logLines < #entries do
    local idx = #logLines + 1
    local stamp = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    stamp:SetJustifyH("LEFT")
    stamp:SetWidth(TIMESTAMP_WIDTH)
    local msg = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    msg:SetJustifyH("LEFT")
    msg:SetWordWrap(true)
    msg:SetWidth(messageWidth)
    logLines[idx] = { stamp = stamp, msg = msg }
  end

  -- Position and fill
  local stampColor = COLORS.timestamp
  local stampColorStr = string.format("|cff%02x%02x%02x",
    stampColor[1] * 255, stampColor[2] * 255, stampColor[3] * 255)

  local yOffset = 0
  for i, entry in ipairs(entries) do
    local line = logLines[i]
    local color = COLORS[entry.colorKey] or COLORS.circuit

    -- Display HH:MM (stored as HH:MM:SS for export precision)
    local displayStamp = (entry.timestamp or ""):sub(1, 5)
    line.stamp:SetText(stampColorStr .. displayStamp .. "|r")
    line.stamp:ClearAllPoints()
    line.stamp:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
    line.stamp:Show()

    line.msg:SetText(entry.text)
    line.msg:SetTextColor(color[1], color[2], color[3])
    line.msg:SetWidth(messageWidth)
    line.msg:ClearAllPoints()
    line.msg:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", TIMESTAMP_WIDTH, -yOffset)
    line.msg:Show()

    yOffset = yOffset + math.max(line.msg:GetStringHeight(), LINE_HEIGHT)
  end

  -- Hide excess
  for i = #entries + 1, #logLines do
    logLines[i].stamp:Hide()
    logLines[i].msg:Hide()
  end

  -- Update scroll child height
  scrollChild:SetHeight(math.max(yOffset, 1))

  -- Scroll to bottom (newest visible)
  -- Force layout update then scroll after frame processes the new height
  scrollFrame:UpdateScrollChildRect()
  C_Timer.After(0.05, function()
    if scrollFrame then
      scrollFrame:SetVerticalScroll(scrollFrame:GetVerticalScrollRange())
    end
  end)
end

-- ============================================================================
-- SHOW / HIDE
-- ============================================================================

function circuitLog:show()
  if not logFrame then
    self:createFrame()
  end
  if logFrame then
    local entries = getEntries()
    if #entries > 0 then
      logFrame:Show()
      self:render()
    end
  end
end

function circuitLog:hide()
  if logFrame then
    logFrame:Hide()
  end
end

--[[
  Check if log has entries worth showing.
  @return boolean
]]
function circuitLog:hasEntries()
  local entries = getEntries()
  return #entries > 0
end

--[[
  End post-completion reward capture.
  Called by circuitSummary when it's ready to show.
]]
function circuitLog:endPostCompletionCapture()
  postCompletionCapture = false
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

function circuitLog:initialize()
  utils = Addon.utils
  events = Addon.events
  persistence = Addon.circuitPersistence

  if not utils or not events or not persistence then
    print("|cff33ff99PAO|r: |cffff4444circuitLog: Missing dependencies|r")
    return false
  end

  events:subscribe("CIRCUIT:STARTED", function(eventName, payload)
    clearEntries()
    postCompletionCapture = false
    wipe(pendingRewards)
    -- State machine wraps context: payload.context.selectedNpcIds
    local count = "?"
    if payload and payload.context and payload.context.selectedNpcIds then
      count = #payload.context.selectedNpcIds
    end
    addEntry("Circuit started (" .. tostring(count) .. " battles)", "circuit")
    -- Log any active XP buffs
    logActiveBuffs()
    circuitLog:show()
  end, circuitLog)

  events:subscribe("CIRCUIT:COMPLETED", function()
    postCompletionCapture = true
    -- Add entry directly without triggering show()
    local entries = getEntries()
    table.insert(entries, {
      text = "Circuit completed!",
      colorKey = "circuit",
      timestamp = date("%H:%M:%S"),
    })
    -- Log stays visible until summary popup replaces it
    if logFrame and logFrame:IsShown() then
      circuitLog:render()
    end
  end, circuitLog)

  events:subscribe("CIRCUIT:CANCELLED", function()
    postCompletionCapture = false
    -- Add entry directly without triggering show()
    local entries = getEntries()
    table.insert(entries, {
      text = "Circuit cancelled",
      colorKey = "circuit",
      timestamp = date("%H:%M:%S"),
    })
    circuitLog:hide()
  end, circuitLog)

  -- Log battle outcomes during circuit (victories, losses, forfeits)
  -- XP and level-up entries follow the outcome entry for correct ordering:
  -- Defeated X → Pet +XP → Pet leveled → rewards
  events:subscribe("CIRCUIT:BATTLE_RESULT", function(eventName, payload)
    if not payload then return end
    local npcName = payload.npcName or "Unknown"
    local outcome = payload.outcome
    
    if outcome == "won" then
      addEntry("Defeated " .. npcName, "victory")
      logBattleResults()
    elseif outcome == "lost" then
      addEntry("Lost to " .. npcName, "defeat")
      logBattleResults()
    elseif outcome == "forfeit" then
      -- No logBattleResults() for forfeit: no XP or level-ups occur on forfeit,
      -- so the accumulators are empty and would produce no entries.
      addEntry("Forfeited vs " .. npcName, "defeat")
    end
  end, circuitLog)

  -- Battle start: reset accumulators, capture names and starting levels
  events:subscribe("PET_BATTLE_OPENING_START", function()
    if persistence:isCircuitActive() then
      resetBattleTracking()
    end
  end, circuitLog)

  -- XP gained during battle (fires per XP award, may fire multiple times)
  events:subscribe("PET_BATTLE_XP_CHANGED", function(eventName, owner, petIndex, xpAmount)
    if not inCircuitBattle then return end
    if owner ~= Enum.BattlePetOwner.Ally then return end
    if petIndex and xpAmount then
      battleXP[petIndex] = (battleXP[petIndex] or 0) + xpAmount
    end
  end, circuitLog)

  -- Level changed during battle
  events:subscribe("PET_BATTLE_LEVEL_CHANGED", function(eventName, owner, petIndex, newLevel)
    if not inCircuitBattle then return end
    if owner ~= Enum.BattlePetOwner.Ally then return end
    if petIndex and newLevel and battleLevels[petIndex] then
      battleLevels[petIndex].to = newLevel
    end
  end, circuitLog)

  -- Battle end: flush pending rewards
  events:subscribe("PET_BATTLE_OVER", function()
    if shouldCaptureRewards() then
      flushPendingRewards()
    end
  end, circuitLog)

  -- Pet captured during circuit
  events:subscribe("PETS:NEW_ACQUISITION", function(eventName, payload)
    if persistence:isCircuitActive() and payload then
      local name = payload.speciesName or payload.name or "Unknown"
      addEntry("Captured " .. name, "capture")
    end
  end, circuitLog)

  -- Reward triggers: flush pending buffer and open forward window
  events:subscribe("QUEST_TURNED_IN", function()
    if shouldCaptureRewards() then
      flushPendingRewards()
    end
  end, circuitLog)

  events:subscribe("QUEST_COMPLETE", function()
    if shouldCaptureRewards() then
      flushPendingRewards()
    end
  end, circuitLog)

  -- Loot/currency/gold: buffer if no active window, add directly if within window
  local lootMultiPattern, lootSinglePattern
  if LOOT_ITEM_SELF_MULTIPLE then
    lootMultiPattern = LOOT_ITEM_SELF_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
  end
  if LOOT_ITEM_SELF then
    lootSinglePattern = LOOT_ITEM_SELF:gsub("%%s", "(.+)")
  end

  events:subscribe("CHAT_MSG_LOOT", function(eventName, message)
    if not shouldCaptureRewards() then return end
    if not message then return end
    local link, count
    if lootMultiPattern then
      link, count = message:match(lootMultiPattern)
    end
    if not link and lootSinglePattern then
      link = message:match(lootSinglePattern)
      count = 1
    end
    if link then
      local text = "Received " .. link .. " x" .. (count or 1)
      if inRewardWindow() then
        addEntry(text, "reward")
      else
        bufferReward(text, "reward")
      end
    end
  end, circuitLog)

  local currMultiPattern, currSinglePattern
  if CURRENCY_GAINED_MULTIPLE then
    currMultiPattern = CURRENCY_GAINED_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
  end
  if CURRENCY_GAINED then
    currSinglePattern = CURRENCY_GAINED:gsub("%%s", "(.+)")
  end

  events:subscribe("CHAT_MSG_CURRENCY", function(eventName, message)
    if not shouldCaptureRewards() then return end
    if not message then return end
    local link, count
    if currMultiPattern then
      link, count = message:match(currMultiPattern)
    end
    if not link and currSinglePattern then
      link = message:match(currSinglePattern)
      count = 1
    end
    if link then
      local text = "Received " .. link .. " x" .. (count or 1)
      if inRewardWindow() then
        addEntry(text, "reward")
      else
        bufferReward(text, "reward")
      end
    end
  end, circuitLog)

  events:subscribe("CHAT_MSG_MONEY", function(eventName, message)
    if not shouldCaptureRewards() then return end
    if not message then return end
    local gold = message:match("(%d+) Gold") or 0
    local silver = message:match("(%d+) Silver") or 0
    gold, silver = tonumber(gold) or 0, tonumber(silver) or 0
    if gold > 0 or silver > 0 then
      local parts = {}
      if gold > 0 then table.insert(parts, gold .. "g") end
      if silver > 0 then table.insert(parts, silver .. "s") end
      local text = "Received " .. table.concat(parts, " ")
      if inRewardWindow() then
        addEntry(text, "gold")
      else
        bufferReward(text, "gold")
      end
    end
  end, circuitLog)

  -- Buff tracking: log XP buff gain/loss during circuit
  local lastBuffCheck = 0
  events:subscribe("UNIT_AURA", function(eventName, unit)
    if unit ~= "player" then return end
    if not persistence:isCircuitActive() then return end
    -- Throttle to 1 check per second
    local now = GetTime()
    if now - lastBuffCheck < 1 then return end
    lastBuffCheck = now
    checkBuffChanges()
  end, circuitLog)

  -- Show log when tracker shows and entries exist (only during active circuit)
  events:subscribe("CIRCUIT:STATE_CHANGED", function()
    local state = persistence:getCircuitState()
    if not state.active then return end
    local entries = getEntries()
    if #entries > 0 then
      circuitLog:show()
    end
  end, circuitLog)

  -- Restore log on init if circuit is active and entries exist
  -- Deferred so tracker frame is created first
  C_Timer.After(4, function()
    if not persistence:isCircuitActive() and not persistence:isCircuitSuspended() then
      return
    end
    local entries = getEntries()
    if #entries > 0 then
      circuitLog:show()
    end
  end)

  return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
  Addon.registerModule("circuitLog", {
    "utils", "events", "circuitPersistence", "circuitConstants", "circuitTracker"
  }, function()
    return circuitLog:initialize()
  end)
end

return circuitLog