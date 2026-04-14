--[[
  logic/circuit/circuitBattleHandler.lua
  Pet Battle Event Handling and Daily Reset Monitoring
  
  Centralizes all battle-related logic including battle state tracking, victory detection,
  waypoint visibility management, and daily reset monitoring. Extracted from circuit.lua
  and circuitPopup.lua to maintain clean separation of concerns.
  
  This module acts as the bridge between WoW's pet battle events and the circuit system,
  ensuring circuit progression only occurs on confirmed victories and handling daily
  quest reset scenarios.
  
  Event wiring is self-contained: the module subscribes to its own WoW events
  during initialization rather than relying on external modules to wire them.
  
  Dependencies: utils, events, circuitPersistence, waypoint, npcUtils, entityDetector, quests
  Exports: Addon.circuitBattleHandler
]]

local addonName, Addon = ...

Addon.circuitBattleHandler = {}
local handler = Addon.circuitBattleHandler

-- Battle state tracking
local inBattle = false
local battleNpcId = nil            -- Circuit NPC ID from entityDetector (GUID-based, authoritative)
local battleNpcName = nil          -- NPC name from entityDetector
local battleOutcome = nil          -- "won", "lost", "forfeit" from console engine token
local battleResultEmitted = false  -- Prevents double-emit of CIRCUIT:BATTLE_RESULT
local pendingReconciliation = false
local reconciliationTimer = nil

-- Reconciliation waits for UNIT_QUEST_LOG_CHANGED because quest completion flags
-- update ~1s after PET_BATTLE_OVER. This timeout is a safety net for battles
-- that don't trigger quest updates (wild battles, repeat kills, fabled beasts
-- without active quest log entries).
local RECONCILIATION_TIMEOUT = 3.0

--[[
  Clear per-battle state after reconciliation or non-circuit battle.
]]
local function clearBattleState()
  battleNpcId = nil
  battleNpcName = nil
  battleOutcome = nil
  battleResultEmitted = false
end

--[[
  Check if currently in a pet battle
  @return boolean - true if in battle
]]
function handler:isInBattle()
  return inBattle
end

--[[
  Reset battle state flags
  Called when advancing to next NPC to clear previous battle state.
]]
function handler:resetBattleState()
  inBattle = false
  clearBattleState()
  pendingReconciliation = false
  if reconciliationTimer then
    reconciliationTimer:Cancel()
    reconciliationTimer = nil
  end
end

--[[
  Handle pet battle start event
  Hides waypoint during battle, marks battle as in progress, and identifies
  the opponent from entityDetector's pre-battle capture (GUID-based npcID).
]]
function handler:onPetBattleStart()
  local persistence = Addon.circuitPersistence
  
  if persistence:isCircuitActive() then
    Addon.waypoint:hide()
    inBattle = true
    battleNpcId = nil
    battleNpcName = nil
    
    -- entityDetector captures target info pre-battle via GUID parsing.
    -- Check if the captured NPC is in the circuit.
    local detector = Addon.entityDetector
    if detector and detector.pendingEntity and detector.pendingEntity.info then
      local info = detector.pendingEntity.info
      battleNpcName = info.name
      
      -- Check if this NPC ID is in the circuit
      local npcId = info.npcID
      if npcId then
        local selectedNpcIds = persistence:getSelectedNpcIds()
        if selectedNpcIds then
          for _, selectedId in ipairs(selectedNpcIds) do
            if selectedId == npcId then
              battleNpcId = npcId
              break
            end
          end
        end
      end
    end
  end
end

--[[
  Handle console message event
  Captures battle outcome from engine tokens. These are internal strings
  (not localized) that fire when the game determines the result, which
  may be before the battle animation completes.
  
  @param message string - Console message text
]]
function handler:onConsoleMessage(message)
  if not inBattle or not message then
    return
  end
  
  if message:find("You Won") then
    battleOutcome = "won"
  elseif message:find("You Lost") then
    battleOutcome = "lost"
  elseif message:find("BattleAbandoned") then
    battleOutcome = "forfeit"
  else
    return
  end
  
  -- Emit early result if setting enabled and circuit is active
  if Addon.circuitPersistence:isCircuitActive() then
    if Addon.options and Addon.options:Get("earlyBattleResults") then
      self:emitBattleResult()
    end
  end
end

--[[
  Emit CIRCUIT:BATTLE_RESULT event exactly once per battle.
  Carries outcome ("won"/"lost"/"forfeit") and NPC identity.
  Fired from console message handler (if early results enabled) or
  PET_BATTLE_OVER (default), whichever comes first.
]]
function handler:emitBattleResult()
  if battleResultEmitted or not battleOutcome then return end
  battleResultEmitted = true
  
  if not Addon.events then return end
  
  Addon.events:emit("CIRCUIT:BATTLE_RESULT", {
    outcome = battleOutcome,
    npcId = battleNpcId,
    npcName = battleNpcName or "Unknown",
  })
end

--[[
  Handle pet battle over event
  Emits battle result for logging, then defers circuit reconciliation until
  UNIT_QUEST_LOG_CHANGED fires (quest completion flags update ~1s after this event).
]]
function handler:onPetBattleOver()
  local persistence = Addon.circuitPersistence
  
  inBattle = false
  
  -- Emit result event if not already emitted by early results setting
  if persistence:isCircuitActive() and battleOutcome then
    self:emitBattleResult()
  end
  
  if battleOutcome == "won" and persistence:isCircuitActive() then
    -- Defer reconciliation: quest flags aren't updated yet at PET_BATTLE_OVER time.
    -- UNIT_QUEST_LOG_CHANGED fires ~1s later when flags are current.
    pendingReconciliation = true
    
    -- Safety timeout for battles that don't trigger quest updates
    -- (wild battles, repeat kills, fabled beasts without active quest)
    reconciliationTimer = C_Timer.After(RECONCILIATION_TIMEOUT, function()
      reconciliationTimer = nil
      if pendingReconciliation then
        pendingReconciliation = false
        local found = self:reconcileCompletions()
        if not found then
          Addon.waypoint:restore()
        end
        clearBattleState()
      end
    end)
  else
    -- Loss, forfeit, or non-circuit battle
    Addon.waypoint:restore()
    clearBattleState()
  end
end

--[[
  Handle quest log change event
  Runs deferred reconciliation once quest completion flags are current.
  UNIT_QUEST_LOG_CHANGED fires once per change (unlike QUEST_LOG_UPDATE which spams).
  If reconciliation finds nothing, we leave pendingReconciliation set so the next
  event retries. The safety timeout handles genuine no-ops (repeat kills, wild battles).
]]
function handler:onQuestLogChanged()
  if not pendingReconciliation then return end
  
  local found = self:reconcileCompletions()
  
  if found then
    pendingReconciliation = false
    if reconciliationTimer then
      reconciliationTimer:Cancel()
      reconciliationTimer = nil
    end
    clearBattleState()
  end
end

--[[
  Handle quest turn-in during active circuit
  Catches quest completions that happen outside of battle — e.g., talking to a tamer
  whose daily quest auto-accepts and auto-turns-in because the battle was already won.
  
  Uses the quest ID from the event directly — no flag scanning needed. Looks up
  which NPC(s) the quest belongs to and checks them against the circuit.
  
  @param questId number - Quest ID from QUEST_TURNED_IN event
]]
function handler:onQuestTurnedIn(questId)
  local persistence = Addon.circuitPersistence
  
  -- Only act during active circuit, outside of battle
  if not persistence:isCircuitActive() then return end
  if inBattle or pendingReconciliation then return end
  
  if not questId then return end
  
  -- Look up which NPC(s) this quest belongs to
  local questDB = Addon.questDatabase
  if not questDB then return end
  
  local quest = questDB.QUESTS[questId]
  if not quest then return end
  
  -- Collect NPC IDs from quest (single npcId or multiple npcIds)
  local questNpcIds = {}
  if quest.npcId then
    questNpcIds[quest.npcId] = true
  end
  if quest.npcIds then
    for _, npcId in ipairs(quest.npcIds) do
      questNpcIds[npcId] = true
    end
  end
  
  -- Check if any of the quest's NPCs are in the circuit and not yet completed
  local selectedNpcIds = persistence:getSelectedNpcIds()
  local completedNpcs = persistence:getCompletedNpcs()
  
  if not selectedNpcIds or not completedNpcs then return end
  
  local completedSet = {}
  for _, id in ipairs(completedNpcs) do
    completedSet[id] = true
  end
  
  local currentNpcId = persistence:getCurrentNpc()
  local currentTargetCompleted = false
  local offCourseCompleted = false
  
  for _, npcId in ipairs(selectedNpcIds) do
    if not completedSet[npcId] and questNpcIds[npcId] then
      local npc = Addon.npcUtils:getNpcData(npcId)
      local npcName = npc and npc.name or "Unknown"
      
      -- Emit result for logging — quest turn-in counts as a win
      if Addon.events then
        Addon.events:emit("CIRCUIT:BATTLE_RESULT", {
          outcome = "won",
          npcId = npcId,
          npcName = npcName,
        })
      end
      
      if npcId == currentNpcId then
        currentTargetCompleted = true
      else
        persistence:markNpcCompleted(npcId)
        offCourseCompleted = true
      end
    end
  end
  
  if currentTargetCompleted then
    Addon.circuit:advanceToNextNpc()
  elseif offCourseCompleted then
    Addon.utils:notify("Circuit updated for quest completion.")
    Addon.circuit:reoptimizeFromCurrent()
  end
end

--[[
  Reconcile completions with circuit state
  Sole mechanism for circuit advancement after battle victory. Two detection paths:
  1. Target identity: NPC ID captured at battle start via entityDetector (GUID-based).
     Authoritative — we know exactly who was fought, regardless of quest state.
  2. Quest API: supplementary scan catches additional out-of-band completions
     (e.g., a Beasts of Fable umbrella quest auto-completing when all beasts are done).
  
  Outcomes:
  - Current target completed → advance to next NPC
  - Off-course NPC completed → mark it, reoptimize remaining route
  - Nothing detected → caller decides (retry or restore waypoint)
  
  @return boolean - true if any completions were detected and acted on
]]
function handler:reconcileCompletions()
  local persistence = Addon.circuitPersistence
  local npcUtils = Addon.npcUtils
  
  local selectedNpcIds = persistence:getSelectedNpcIds()
  local completedNpcs = persistence:getCompletedNpcs()
  
  if not selectedNpcIds or not completedNpcs then
    return false
  end
  
  -- Build lookup of already-tracked completions
  local completedSet = {}
  for _, id in ipairs(completedNpcs) do
    completedSet[id] = true
  end
  
  local newlyCompleted = {}
  local newlyCompletedSet = {}
  
  -- Primary: NPC identified at battle start via entityDetector (GUID-based).
  -- Authoritative — we know exactly who was fought.
  if battleNpcId and not completedSet[battleNpcId] then
    table.insert(newlyCompleted, battleNpcId)
    newlyCompletedSet[battleNpcId] = true
  end
  
  -- Supplementary: quest API scan catches additional out-of-band completions
  -- (e.g., a quest auto-completing when all Beasts of Fable in a book are done)
  for _, npcId in ipairs(selectedNpcIds) do
    if not completedSet[npcId] and not newlyCompletedSet[npcId] and npcUtils:isNpcCompletedToday(npcId) then
      table.insert(newlyCompleted, npcId)
      newlyCompletedSet[npcId] = true
    end
  end
  
  -- Nothing detected — caller decides whether to retry or restore waypoint
  if #newlyCompleted == 0 then
    return false
  end
  
  -- Check if current target is among the newly completed
  local currentNpcId = persistence:getCurrentNpc()
  local currentTargetCompleted = false
  for _, npcId in ipairs(newlyCompleted) do
    if npcId == currentNpcId then
      currentTargetCompleted = true
    else
      persistence:markNpcCompleted(npcId)
    end
  end
  
  if currentTargetCompleted then
    Addon.circuit:advanceToNextNpc()
  else
    -- Off-course only — reoptimize from current position
    Addon.utils:notify("Circuit updated for off-course victory.")
    Addon.circuit:reoptimizeFromCurrent()
  end
  
  return true
end

--[[
  Check for daily reset and warn user
  Monitors GetQuestResetTime() for changes and shows warnings.
]]
function handler:checkDailyReset()
  local persistence = Addon.circuitPersistence
  local settings = persistence:getCircuitSettings()
  
  if not persistence:getCircuitState().active then return end
  if not settings.resetWarningEnabled then return end
  
  local timeUntilReset = GetQuestResetTime()
  local lastResetTime = persistence:getLastDailyResetTime()
  
  -- Check if reset occurred
  if lastResetTime and timeUntilReset > lastResetTime then
    -- Reset happened!
    self:handleDailyReset()
    persistence:updateLastDailyResetTime(timeUntilReset)
    return
  end
  
  -- Check if we should warn about upcoming reset
  if timeUntilReset <= settings.resetWarningTime then
    local now = time()
    local lastWarning = persistence:getLastResetWarning()
    local timeSinceLastWarning = now - lastWarning
    
    if timeSinceLastWarning >= settings.resetWarningInterval then
      local minutes = math.floor(timeUntilReset / 60)
      Addon.utils:notify(string.format("Daily reset in %d minutes! %d battles remaining in circuit.", 
        minutes, Addon.circuit:getRemainingBattleCount()))
      persistence:updateLastResetWarning(now)
    end
  end
  
  persistence:updateLastDailyResetTime(timeUntilReset)
end

--[[
  Handle daily reset during active circuit
  Fires event for UI to show prompt for user decision.
]]
function handler:handleDailyReset()
  -- Fire event for UI to show daily reset prompt
  if Addon.events then
    Addon.events:emit("CIRCUIT:DAILY_RESET_DETECTED", {
      remaining = Addon.circuit:getRemainingBattleCount()
    })
  end
end

--[[
  Reset circuit with new dailies
  Re-validates NPCs and restarts circuit after daily reset.
]]
function handler:resetWithNewDailies()
  local persistence = Addon.circuitPersistence
  local state = persistence:getCircuitState()
  
  -- Re-validate all NPCs and restart
  local validNpcs = Addon.npcUtils:validateNpcs(state.selectedNpcIds)
  Addon.circuit:start(validNpcs, state.lastReturnType)
end

--[[
  Truncate circuit to only active quest NPCs
  Removes completed NPCs from remaining queue after daily reset.
]]
function handler:truncateToActiveQuests()
  local persistence = Addon.circuitPersistence
  local continentQueue = persistence:getContinentQueue()
  local newQueue = {}
  
  for _, continentData in ipairs(continentQueue) do
    local validNpcs = {}
    for _, npcId in ipairs(continentData.npcIds) do
      if not Addon.npcUtils:isNpcCompletedToday(npcId) then
        table.insert(validNpcs, npcId)
      end
    end
    
    if #validNpcs > 0 then
      table.insert(newQueue, {
        continent = continentData.continent,
        npcIds = validNpcs
      })
    end
  end
  
  persistence:updateContinentQueue(newQueue)
  
  if #newQueue == 0 then
    Addon.utils:chat("No incomplete quests remaining. Circuit complete!")
    Addon.circuit:complete()
  else
    Addon.utils:chat("Circuit truncated to incomplete quests only.")
    Addon.circuit:startNextContinent()
  end
end

--[[
  Initialize event subscriptions
  Self-wires all WoW events needed for battle tracking and quest completion detection.
  Called from registerModule init function.
]]
function handler:initialize()
  local events = Addon.events
  
  events:subscribe("PET_BATTLE_OPENING_START", function()
    handler:onPetBattleStart()
  end)
  
  events:subscribe("CONSOLE_MESSAGE", function(event, message)
    handler:onConsoleMessage(message)
  end)
  
  events:subscribe("PET_BATTLE_OVER", function()
    handler:onPetBattleOver()
  end)
  
  events:subscribe("UNIT_QUEST_LOG_CHANGED", function(event, unit)
    if unit == "player" then
      handler:onQuestLogChanged()
    end
  end)
  
  events:subscribe("QUEST_TURNED_IN", function(event, questId)
    handler:onQuestTurnedIn(questId)
  end)
  
  return true
end

-- Self-register with dependency system
-- Note: circuit is NOT declared as a dependency to avoid circular dependency
-- (circuit depends on circuitBattleHandler). The battle handler calls circuit
-- functions at runtime (during pet battles), by which point circuit is already
-- initialized. This is safe because these calls only happen via event handlers,
-- never during module initialization.
if Addon.registerModule then
  Addon.registerModule("circuitBattleHandler",
    {"utils", "events", "circuitPersistence", "waypoint", "npcUtils", "entityDetector", "quests"},
    function()
      return handler:initialize()
    end)
end

return handler