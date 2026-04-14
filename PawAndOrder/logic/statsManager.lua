--[[
  logic/statsManager.lua
  PvP Battle Statistics Tracking
  
  Tracks win/loss record for PvP pet battles with automatic detection
  via console messages (same proven pattern as circuitBattleHandler).
  Also tracks queue duration (session-only) and "What We've Been
  Training For" weekly quest progress.
  
  Session-only W/L record (achievements track lifetime wins).
  
  Dependencies: utils, events
  Exports: Addon.statsManager
]]

local ADDON_NAME, Addon = ...

local statsManager = {}

-- Module references
local utils, events

-- Session-only queue tracking (not persisted)
local lastQueueDuration = nil   -- Seconds the last completed queue took
local wasQueued = false         -- Previous tick's queue state for edge detection
local cachedQueueStartTime = 0  -- GetTime() value when queue began
local queueEventLog = {}        -- Array of {elapsed, text} per queue session

-- PVP battle state (for console message win/loss detection)
local inPvpBattle = false
local selfForfeited = false  -- Set by ForfeitGame hook, consumed by BattleAbandoned
local autoRequeue = false    -- Shift-click toggle: auto-queue after battle ends
local pendingRequeue = false -- Set on battle end, consumed by PLAYER_ENTERING_WORLD

-- Opponent tracking (session-only)
local opponentHistory = {}        -- Array of { guid, name, realm, result, timestamp }
local pendingOpponent = nil       -- GUID captured at battle start, committed on result

-- "What We've Been Training For" - weekly PVP pet battle quest
local WEEKLY_PVP_QUEST_ID = 32863

-- Session W/L record (not persisted — achievements track lifetime)
local sessionWins = 0
local sessionLosses = 0

--[[
  Get Win/Loss Record
  Returns current session W/L statistics.
  
  @return number, number - wins, losses
]]
function statsManager:getRecord()
  return sessionWins, sessionLosses
end

--[[
  Record Win
  Increments win counter and fires event.
]]
function statsManager:recordWin()
  sessionWins = sessionWins + 1
  
  if events then
    events:emit("STATS:UPDATED", {
      wins = sessionWins,
      losses = sessionLosses,
    })
  end
  
  if utils then
    utils:debug(string.format("PvP Win recorded. Record: %d-%d", sessionWins, sessionLosses))
  end
end

--[[
  Record Loss
  Increments loss counter and fires event.
]]
function statsManager:recordLoss()
  sessionLosses = sessionLosses + 1
  
  if events then
    events:emit("STATS:UPDATED", {
      wins = sessionWins,
      losses = sessionLosses,
    })
  end
  
  if utils then
    utils:debug(string.format("PvP Loss recorded. Record: %d-%d", sessionWins, sessionLosses))
  end
end

--[[
  Reset Stats
  Clears W/L record to 0-0.
]]
function statsManager:reset()
  sessionWins = 0
  sessionLosses = 0
  
  if events then
    events:emit("STATS:UPDATED", {
      wins = 0,
      losses = 0,
    })
  end
  
  if utils then
    utils:debug("PvP stats reset to 0-0")
  end
end

--[[
  Toggle Auto-Requeue
  When enabled, automatically queues for next PVP battle after current one ends.
  
  @param enabled boolean
]]
function statsManager:setAutoRequeue(enabled)
  autoRequeue = enabled and true or false
end

--[[
  Get Auto-Requeue State
  
  @return boolean
]]
function statsManager:getAutoRequeue()
  return autoRequeue
end

--[[
  Request auto-requeue after battle ends.
  Sets flag consumed by LOADING_SCREEN_DISABLED after world transfer.
]]
local function tryAutoRequeue()
  if not autoRequeue then return end
  pendingRequeue = true
end

--[[
  Get Last Queue Duration
  Returns how long the last completed queue wait took (session only).
  
  @return number|nil - Seconds, or nil if no queue has completed this session
]]
function statsManager:getLastQueueDuration()
  return lastQueueDuration
end

--[[
  Log a queue event with elapsed time relative to queue start.
  
  @param text string - Event description
]]
local function logQueueEvent(text)
  local elapsed = 0
  if cachedQueueStartTime > 0 then
    elapsed = GetTime() - cachedQueueStartTime
  end
  table.insert(queueEventLog, { elapsed = elapsed, text = text })
end

--[[
  Get Queue Event Log
  Returns the current queue session's event log.
  
  @return table - Array of { elapsed, text }
]]
function statsManager:getQueueEventLog()
  return queueEventLog
end

--[[
  Commit pending opponent to history with result.
  Lazily resolves name from GUID. Called on BattleFinished.
  
  @param result string - "win" or "loss"
]]
local function commitOpponent(result, forfeit)
  if not pendingOpponent then return end
  
  local entry = {
    guid = pendingOpponent,
    result = result,
    forfeit = forfeit or false,
    timestamp = time(),
  }
  
  local _, _, _, _, _, name, realm = GetPlayerInfoByGUID(pendingOpponent)
  if name then
    entry.name = name
    entry.realm = realm or ""
  end
  
  -- Print opponent name in chat (delayed to allow GUID resolution)
  local capturedGuid = pendingOpponent
  C_Timer.After(1, function()
    if not entry.name and capturedGuid then
      local _, _, _, _, _, delayedName, delayedRealm = GetPlayerInfoByGUID(capturedGuid)
      if delayedName then
        entry.name = delayedName
        entry.realm = delayedRealm or ""
      end
    end
    if utils then
      local displayName = entry.name or capturedGuid
      if entry.realm and entry.realm ~= "" then
        displayName = displayName .. "-" .. entry.realm
      end
      utils:chat(string.format("Opponent: %s", displayName), true)
    end
  end)
  
  table.insert(opponentHistory, 1, entry)  -- Most recent first
  pendingOpponent = nil
end

--[[
  Get Opponent History
  Returns session opponent history (most recent first).
  Lazily resolves names for any entries that failed initial lookup.
  
  @return table - Array of { guid, name, realm, result, timestamp }
]]
function statsManager:getOpponentHistory()
  for _, entry in ipairs(opponentHistory) do
    if not entry.name and entry.guid then
      local _, _, _, _, _, name, realm = GetPlayerInfoByGUID(entry.guid)
      if name then
        entry.name = name
        entry.realm = realm or ""
      end
    end
  end
  return opponentHistory
end

--[[
  Get Weekly PVP Quest Progress
  Checks "What We've Been Training For" (quest 32863) status.
  
  @return boolean, number, number, boolean - hasQuest, numWins, numRequired, isComplete
]]
function statsManager:getWeeklyQuestProgress()
  -- Already turned in this week — nothing to show
  if C_QuestLog.IsQuestFlaggedCompleted(WEEKLY_PVP_QUEST_ID) then
    return false, 0, 0, true
  end
  
  -- Check if quest is in the log
  local questLogIndex = GetQuestLogIndexByID(WEEKLY_PVP_QUEST_ID)
  if not questLogIndex or questLogIndex == 0 then
    return false, 0, 0, false
  end
  
  -- Parse objective progress via C_QuestLog (consistent with npcUtils pattern)
  local objectives = C_QuestLog.GetQuestObjectives(WEEKLY_PVP_QUEST_ID)
  if objectives and #objectives > 0 then
    local obj = objectives[1]
    if obj.numFulfilled and obj.numRequired then
      return true, obj.numFulfilled, obj.numRequired, obj.finished
    end
  end
  
  -- Quest in log but can't parse objectives — show as 0/10
  return true, 0, 10, false
end

-- PVP achievement chains (ordered by progression)
-- Each chain is walked first-to-last; first incomplete entry is shown.
local PVP_ACHIEVEMENT_CHAINS = {
  -- Basic PVP wins (any level)
  { 6595, 6596, 6597, 6598, 6599 },
  -- Level 25 Find Battle wins (added 5.3)
  { 8298, 8300, 8301 },
}

--[[
  Get PVP Achievement Progress
  Walks each PVP chain, returns the first incomplete achievement per chain.
  Uses GetAchievementInfo for completion, GetAchievementCriteriaInfo for progress.
  
  @return table - Array of { name, current, required, icon } for each active chain
]]
function statsManager:getPvpAchievementProgress()
  local active = {}
  
  for _, chain in ipairs(PVP_ACHIEVEMENT_CHAINS) do
    for _, achieveId in ipairs(chain) do
      local id, name, _, completed, _, _, _, _, _, icon = GetAchievementInfo(achieveId)
      if not id then
        break  -- Achievement doesn't exist in this client
      end
      if not completed then
        -- First incomplete in this chain — get criteria progress
        local _, _, _, quantity, reqQuantity = GetAchievementCriteriaInfo(achieveId, 1)
        table.insert(active, {
          name = name,
          current = quantity or 0,
          required = reqQuantity or 0,
          icon = icon,
        })
        break
      end
    end
  end
  
  return active
end

-- Register with addon
Addon.statsManager = statsManager

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("statsManager", {"utils", "events"}, function()
    utils = Addon.utils
    events = Addon.events
    
    -- Track PVP battle start — set flag when enemy is a player, not NPC
    events:subscribe("PET_BATTLE_OPENING_START", function()
      if not C_PetBattles.IsPlayerNPC(Enum.BattlePetOwner.Enemy) then
        inPvpBattle = true
        selfForfeited = false
      end
    end)
    
    -- Hook ForfeitGame to distinguish self-forfeit from opponent forfeit
    hooksecurefunc(C_PetBattles, "ForfeitGame", function()
      utils:debug("PVP ForfeitGame hook fired, inPvpBattle=" .. tostring(inPvpBattle))
      if inPvpBattle then
        selfForfeited = true
      end
    end)
    
    -- Capture opponent GUID from console messages
    -- Runs on ALL console messages — pattern is specific enough to never false-match.
    -- Must not be gated on inPvpBattle: initial update can arrive before PET_BATTLE_OPENING_START.
    events:subscribe("CONSOLE_MESSAGE", function(_, message)
      if not message then return end
      
      -- Capture opponent GUID from initial update
      -- Player index (0 or 1) is NOT fixed — either side can be self
      -- Also sets inPvpBattle here: the initial update always precedes any
      -- BattleFinished/BattleAbandoned message, and arrives before
      -- PET_BATTLE_OPENING_START in fast-forfeit scenarios.
      local _, guid = message:match("Player (%d) (Player%-%d+%-%x+)")
      if guid then
        if not pendingOpponent and guid ~= UnitGUID("player") then
          pendingOpponent = guid
          inPvpBattle = true
          selfForfeited = false
        end
      end
      
      -- Battle result handling requires inPvpBattle
      if not inPvpBattle then return end
      
      if message:find("BattleFinished") then
        if message:find("You Won") then
          commitOpponent("win")
          statsManager:recordWin()
        elseif message:find("You Lost") then
          commitOpponent("loss")
          statsManager:recordLoss()
        end
        inPvpBattle = false
        tryAutoRequeue()
      elseif message:find("BattleAbandoned") then
        utils:debug("PVP BattleAbandoned: selfForfeited=" .. tostring(selfForfeited))
        if selfForfeited then
          commitOpponent("loss", true)
          statsManager:recordLoss()
        else
          commitOpponent("win", true)
          statsManager:recordWin()
        end
        selfForfeited = false
        inPvpBattle = false
        tryAutoRequeue()
      end
    end)
    
    
    -- Track queue start/end transitions for duration measurement and event log
    events:subscribe("PET_BATTLE_QUEUE_STATUS", function()
      local queueState, _, queuedTime = C_PetBattles.GetPVPMatchmakingInfo()
      local isQueued = (queueState == "queued" or queueState == "proposal" or queueState == "suspended")
      
      if isQueued and not wasQueued then
        -- Queue just started — clear log and capture start time
        wipe(queueEventLog)
        cachedQueueStartTime = queuedTime or GetTime()
        logQueueEvent("Joined queue")
      elseif not isQueued and wasQueued then
        -- Queue just ended (match found or cancelled)
        if cachedQueueStartTime > 0 then
          lastQueueDuration = GetTime() - cachedQueueStartTime
        end
        logQueueEvent("Left queue")
        cachedQueueStartTime = 0
      end
      
      wasQueued = isQueued
    end)
    
    -- Queue proposal events
    events:subscribe("PET_BATTLE_QUEUE_PROPOSE_MATCH", function()
      logQueueEvent("Match found")
    end)
    
    events:subscribe("PET_BATTLE_QUEUE_PROPOSAL_ACCEPTED", function()
      logQueueEvent("Match accepted")
    end)
    
    events:subscribe("PET_BATTLE_QUEUE_PROPOSAL_DECLINED", function()
      logQueueEvent("Opponent declined")
    end)
    
    -- Auto-requeue after loading screen from world transfer completes
    -- Short delay lets the client fully settle before re-queuing
    events:subscribe("LOADING_SCREEN_DISABLED", function()
      if pendingRequeue then
        pendingRequeue = false
        if autoRequeue then
          C_Timer.After(2, function()
            if autoRequeue then
              C_PetBattles.StartPVPMatchmaking()
            end
          end)
        end
      end
    end)
    
    return true
  end)
end

return statsManager