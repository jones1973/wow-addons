--[[
  data/circuit/circuitPersistence.lua
  Circuit SavedVariable Persistence Layer (State Machine Integrated)
  
  Provides a clean abstraction layer for all circuit-related SavedVariable operations.
  Handles initialization, validation, reading, and writing of pao_circuit and
  pao_settings.circuit data.
  
  CRITICAL ARCHITECTURAL CHANGE: State manipulation has been extracted to circuitStateMachine.
  This module now provides read-only access to circuit state and a single write method
  (updateCircuitState) that ONLY the state machine should call. This ensures all state
  changes are validated and tracked through the state machine.
  
  Dependencies: circuitData, circuitConstants, utils
  Exports: Addon.circuitPersistence
]]

local addonName, Addon = ...

Addon.circuitPersistence = {}
local persistence = Addon.circuitPersistence

--[[
  Initialize circuit SavedVariables if they don't exist
  Creates pao_circuit and pao_settings.circuit with default values.
  Safe to call multiple times - will only initialize if needed.
  
  @return boolean - true if initialized successfully
]]
function persistence:initialize()
  local circuitData = Addon.circuitData
  
  -- pao_circuit and pao_settings created by svRegistry before module init.
  
  -- Initialize pao_settings.circuit sub-table if needed
  -- (svRegistry manages pao_settings as a whole, sub-structures are module responsibility)
  if not pao_settings.circuit then
    pao_settings.circuit = circuitData:createDefaultCircuitSettings()
    Addon.utils:debug("circuitPersistence: Created default pao_settings.circuit")
  end
  
  -- Validate existing circuit data
  local valid, err = circuitData:validateCircuitState(pao_circuit)
  if not valid then
    Addon.utils:debug("circuitPersistence: Validation failed - " .. err)
    Addon.utils:debug("circuitPersistence: Resetting to defaults")
    local savedVersion = pao_circuit._svVersion
    wipe(pao_circuit)
    local fresh = circuitData:createDefaultCircuitState()
    for k, v in pairs(fresh) do
        pao_circuit[k] = v
    end
    pao_circuit._svVersion = savedVersion
  end
  
  return true
end

--[[
  Get circuit state (read-only access)
  Returns the current circuit state. Callers should not modify directly.
  
  @return table - Current pao_circuit state
]]
function persistence:getCircuitState()
  self:initialize()
  return pao_circuit
end

--[[
  Get circuit settings (read-only access)
  Returns the current circuit settings. Callers should not modify directly.
  
  @return table - Current pao_settings.circuit settings
]]
function persistence:getCircuitSettings()
  self:initialize()
  return pao_settings.circuit
end

--[[
  Check if a circuit is currently active
  @return boolean - true if circuit is running (active and not suspended)
]]
function persistence:isCircuitActive()
  self:initialize()
  return pao_circuit.active and not pao_circuit.suspended
end

--[[
  Check if a circuit exists but is suspended
  @return boolean - true if circuit is paused
]]
function persistence:isCircuitSuspended()
  self:initialize()
  return pao_circuit.active and pao_circuit.suspended
end

--[[
  Update circuit state (STATE MACHINE ONLY)
  This is the ONLY method that modifies circuit state flags. Should only be
  called by the circuitStateMachine module. All other code should use the
  state machine to trigger state changes.
  
  @param newState string - New state value (from circuitStateMachine.STATES)
  @param context table - State-specific context data:
    For "active" (start):
      .selectedNpcIds (array) - NPC IDs to visit
      .continentQueue (array) - Route data
      .returnLocation (table) - Return waypoint data
      .lastContinent (number|nil) - Starting continent
      .lastReturnType (string) - Return type
    For "completed":
      (context optional, just marks completion)
    For "cancelled"/"suspended":
      (context optional)
]]
function persistence:updateCircuitState(newState, context)
  self:initialize()
  context = context or {}
  
  if newState == "active" then
    -- Starting or resuming circuit
    if context.selectedNpcIds then
      -- New circuit start
      pao_circuit.active = true
      pao_circuit.suspended = false
      pao_circuit.currentContinent = nil
      pao_circuit.currentNpcId = nil
      pao_circuit.continentQueue = context.continentQueue or {}
      pao_circuit.completedInCircuit = {}
      pao_circuit.selectedNpcIds = context.selectedNpcIds or {}
      pao_circuit.lastContinent = context.lastContinent
      pao_circuit.lastReturnType = context.lastReturnType or "none"
      pao_circuit.returnLocation = context.returnLocation or Addon.circuitData:createReturnLocation("none")
      pao_circuit.circuitStartTime = time()
      pao_circuit.lastDailyResetTime = GetQuestResetTime()
      pao_circuit.waypointHidden = false
    else
      -- Resume from suspended
      pao_circuit.suspended = false
    end
    
  elseif newState == "suspended" then
    pao_circuit.suspended = true
    
  elseif newState == "completed" then
    pao_circuit.active = false
    pao_circuit.suspended = false
    pao_circuit.currentNpcId = nil
    
  elseif newState == "cancelled" then
    pao_circuit.active = false
    pao_circuit.suspended = false
    pao_circuit.currentNpcId = nil
    pao_circuit.currentContinent = nil
    
  else
    Addon.utils:error("circuitPersistence: Unknown state '" .. tostring(newState) .. "'")
  end
end

--[[
  Mark an NPC as completed in the current circuit
  @param npcId number - NPC ID to mark as completed
]]
function persistence:markNpcCompleted(npcId)
  self:initialize()
  
  if not pao_circuit.active then
    return
  end
  
  -- Check for duplicate (rebattling already-completed NPC)
  for _, completedId in ipairs(pao_circuit.completedInCircuit) do
    if completedId == npcId then
      return
    end
  end
  
  table.insert(pao_circuit.completedInCircuit, npcId)
end

--[[
  Set the current target NPC
  @param npcId number|nil - NPC ID to set as current, or nil to clear
]]
function persistence:setCurrentNpc(npcId)
  self:initialize()
  pao_circuit.currentNpcId = npcId
end

--[[
  Get the current target NPC
  @return number|nil - Current NPC ID or nil
]]
function persistence:getCurrentNpc()
  self:initialize()
  return pao_circuit.currentNpcId
end

--[[
  Set the current continent
  @param continent number - Continent ID
]]
function persistence:setCurrentContinent(continent)
  self:initialize()
  pao_circuit.currentContinent = continent
end

--[[
  Get the current continent
  @return number|nil - Current continent ID or nil
]]
function persistence:getCurrentContinent()
  self:initialize()
  return pao_circuit.currentContinent
end

--[[
  Update the continent queue
  @param queue table - New continent queue array
]]
function persistence:updateContinentQueue(queue)
  self:initialize()
  pao_circuit.continentQueue = queue or {}
end

--[[
  Get the continent queue
  @return table - Array of continent route data
]]
function persistence:getContinentQueue()
  self:initialize()
  return pao_circuit.continentQueue
end

--[[
  Get the selected NPC IDs from the original circuit configuration
  @return table - Array of NPC IDs
]]
function persistence:getSelectedNpcIds()
  self:initialize()
  return pao_circuit.selectedNpcIds
end

--[[
  Get the return location configuration
  @return table - Return location data
]]
function persistence:getReturnLocation()
  self:initialize()
  return pao_circuit.returnLocation
end

--[[
  Get the completed NPC list for the current circuit
  @return table - Array of completed NPC IDs
]]
function persistence:getCompletedNpcs()
  self:initialize()
  return pao_circuit.completedInCircuit
end

--[[
  Get circuit start time
  @return number|nil - Unix timestamp or nil
]]
function persistence:getStartTime()
  self:initialize()
  return pao_circuit.circuitStartTime
end

--[[
  Set waypoint hidden flag
  @param hidden boolean - true if waypoint arrow is hidden
]]
function persistence:setWaypointHidden(hidden)
  self:initialize()
  pao_circuit.waypointHidden = hidden
end

--[[
  Get waypoint hidden flag
  @return boolean - true if waypoint arrow is hidden
]]
function persistence:isWaypointHidden()
  self:initialize()
  return pao_circuit.waypointHidden
end

--[[
  Update last daily reset time
  @param resetTime number - GetQuestResetTime() value
]]
function persistence:updateLastDailyResetTime(resetTime)
  self:initialize()
  pao_circuit.lastDailyResetTime = resetTime
end

--[[
  Get last daily reset time
  @return number|nil - Last recorded reset time or nil
]]
function persistence:getLastDailyResetTime()
  self:initialize()
  return pao_circuit.lastDailyResetTime
end

--[[
  Save tracker UI position
  @param position table - {point, relativePoint, x, y}
]]
function persistence:saveTrackerPosition(position)
  self:initialize()
  pao_settings.circuit.trackerPosition = position
end

--[[
  Get saved tracker UI position
  @return table|nil - {point, relativePoint, x, y} or nil if not saved
]]
function persistence:getTrackerPosition()
  self:initialize()
  return pao_settings.circuit.trackerPosition
end

--[[
  Update last reset warning timestamp
  @param timestamp number - Unix timestamp
]]
function persistence:updateLastResetWarning(timestamp)
  self:initialize()
  pao_settings.circuit.lastResetWarning = timestamp
end

--[[
  Get last reset warning timestamp
  @return number - Unix timestamp
]]
function persistence:getLastResetWarning()
  self:initialize()
  return pao_settings.circuit.lastResetWarning or 0
end

--[[
  Update last known character
  @param characterName string - Character name
]]
function persistence:updateLastKnownCharacter(characterName)
  self:initialize()
  pao_circuit.lastKnownCharacter = characterName
end

--[[
  Get last known character
  @return string|nil - Character name or nil
]]
function persistence:getLastKnownCharacter()
  self:initialize()
  return pao_circuit.lastKnownCharacter
end

--[[
  Update last known continent
  @param continent number - Continent ID
]]
function persistence:updateLastKnownContinent(continent)
  self:initialize()
  pao_circuit.lastKnownContinent = continent
end

--[[
  Get last known continent
  @return number|nil - Continent ID or nil
]]
function persistence:getLastKnownContinent()
  self:initialize()
  return pao_circuit.lastKnownContinent
end

--[[
  Update last known position
  @param position table - {x, y, mapID}
]]
function persistence:updateLastKnownPosition(position)
  self:initialize()
  pao_circuit.lastKnownPosition = position
end

--[[
  Get last known position
  @return table|nil - {x, y, mapID} or nil
]]
function persistence:getLastKnownPosition()
  self:initialize()
  return pao_circuit.lastKnownPosition
end

--[[
  Reset circuit state to defaults (for debugging or full reset)
  Preserves settings but clears active circuit data.
]]
function persistence:reset()
  local circuitData = Addon.circuitData
  pao_circuit = circuitData:createDefaultCircuitState()
  Addon.utils:debug("circuitPersistence: Circuit state reset to defaults")
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("circuitPersistence", {"utils", "circuitData", "circuitConstants"}, function()
    if persistence.initialize then
      return persistence:initialize()
    end
    return true
  end)
end

return persistence