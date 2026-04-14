--[[
  logic/circuit/circuitStateMachine.lua
  Circuit State Machine
  
  Defines the circuit's states, valid transitions, and guard conditions using
  the generic state machine framework. This module is the ONLY way to change
  circuit state, ensuring all transitions are validated and tracked.
  
  Circuit States:
    - INACTIVE: No circuit running
    - ACTIVE: Circuit running, player routing through NPCs
    - SUSPENDED: Circuit paused (waiting for continent travel)
    - COMPLETED: Circuit finished successfully
    - CANCELLED: Circuit terminated by user
  
  Valid Transitions:
    INACTIVE → ACTIVE (start circuit)
    ACTIVE → SUSPENDED (pause for travel)
    ACTIVE → COMPLETED (finish all NPCs)
    ACTIVE → CANCELLED (user cancels)
    SUSPENDED → ACTIVE (resume after travel)
    SUSPENDED → CANCELLED (user cancels while suspended)
    COMPLETED → INACTIVE (reset for new circuit)
    CANCELLED → INACTIVE (reset for new circuit)
  
  Dependencies: stateMachine, circuitPersistence, utils
  Exports: Addon.circuitStateMachine
]]

local addonName, Addon = ...

Addon.circuitStateMachine = {}
local circuitStateMachine = Addon.circuitStateMachine

-- State constants
local STATES = {
  INACTIVE = "inactive",
  ACTIVE = "active",
  SUSPENDED = "suspended",
  COMPLETED = "completed",
  CANCELLED = "cancelled",
}

-- Export states for external use
circuitStateMachine.STATES = STATES

-- State machine instance (created during initialization)
local stateMachineInstance = nil

--[[
  Initialize circuit state machine
  Creates the state machine instance with circuit-specific configuration.
  Called automatically during module registration.
  
  @return boolean - true if initialized successfully
]]
function circuitStateMachine:initialize()
  if stateMachineInstance then
    return true  -- Already initialized
  end
  
  local persistence = Addon.circuitPersistence
  persistence:initialize()
  
  -- Determine initial state from persistence
  local state = persistence:getCircuitState()
  local initialState = STATES.INACTIVE
  
  if state.active and state.suspended then
    initialState = STATES.SUSPENDED
  elseif state.active then
    initialState = STATES.ACTIVE
  end
  
  -- Create state machine instance
  stateMachineInstance = Addon.stateMachine:create({
    name = "Circuit",
    
    states = STATES,
    
    initialState = initialState,
    
    transitions = {
      -- INACTIVE → ACTIVE (start circuit)
      {
        from = STATES.INACTIVE,
        to = STATES.ACTIVE,
        guards = {"hasSelectedNpcs", "hasContinentQueue"},
        on = "CIRCUIT:STARTED"
      },
      
      -- ACTIVE → SUSPENDED (pause for travel)
      {
        from = STATES.ACTIVE,
        to = STATES.SUSPENDED,
        guards = {"isCircuitActive"},
        on = "CIRCUIT:SUSPENDED"
      },
      
      -- ACTIVE → COMPLETED (finish all NPCs)
      {
        from = STATES.ACTIVE,
        to = STATES.COMPLETED,
        guards = {"isCircuitActive"},
        on = "CIRCUIT:COMPLETED"
      },
      
      -- ACTIVE → CANCELLED (user cancels)
      {
        from = STATES.ACTIVE,
        to = STATES.CANCELLED,
        guards = {"isCircuitActive"},
        on = "CIRCUIT:CANCELLED"
      },
      
      -- SUSPENDED → ACTIVE (resume after travel)
      {
        from = STATES.SUSPENDED,
        to = STATES.ACTIVE,
        guards = {"isCircuitSuspended"},
        on = "CIRCUIT:RESUMED"
      },
      
      -- SUSPENDED → CANCELLED (user cancels while suspended)
      {
        from = STATES.SUSPENDED,
        to = STATES.CANCELLED,
        guards = {"isCircuitSuspended"},
        on = "CIRCUIT:CANCELLED"
      },
      
      -- COMPLETED/CANCELLED → INACTIVE (reset for new circuit)
      {
        from = {STATES.COMPLETED, STATES.CANCELLED},
        to = STATES.INACTIVE,
        on = "CIRCUIT:RESET"
      },
    },
    
    guards = {
      -- Guard: Circuit must have selected NPCs
      hasSelectedNpcs = function(context)
        return context.selectedNpcIds and #context.selectedNpcIds > 0
      end,
      
      -- Guard: Circuit must have continent queue
      hasContinentQueue = function(context)
        return context.continentQueue and #context.continentQueue > 0
      end,
      
      -- Guard: Circuit must be active (not suspended)
      isCircuitActive = function(context)
        local persistence = Addon.circuitPersistence
        return persistence:isCircuitActive()
      end,
      
      -- Guard: Circuit must be suspended
      isCircuitSuspended = function(context)
        local persistence = Addon.circuitPersistence
        return persistence:isCircuitSuspended()
      end,
    },
    
    -- State entry callbacks
    onEnter = {
      [STATES.ACTIVE] = function(context)
        Addon.utils:debug("Circuit state machine: Entered ACTIVE state")
      end,
      
      [STATES.SUSPENDED] = function(context)
        Addon.utils:debug("Circuit state machine: Entered SUSPENDED state")
      end,
      
      [STATES.COMPLETED] = function(context)
        Addon.utils:debug("Circuit state machine: Entered COMPLETED state")
      end,
      
      [STATES.CANCELLED] = function(context)
        Addon.utils:debug("Circuit state machine: Entered CANCELLED state")
      end,
      
      [STATES.INACTIVE] = function(context)
        Addon.utils:debug("Circuit state machine: Entered INACTIVE state")
      end,
    },
    
    -- State exit callbacks
    onExit = {
      [STATES.ACTIVE] = function(context)
        Addon.utils:debug("Circuit state machine: Exited ACTIVE state")
      end,
    },
  })
  
  if not stateMachineInstance then
    Addon.utils:error("Failed to create circuit state machine instance")
    return false
  end
  
  return true
end

--[[
  Reset state machine to INACTIVE
  Transitions from COMPLETED or CANCELLED states back to INACTIVE, allowing
  a new circuit to be started. This is the ONLY way to clear a finished/cancelled
  circuit and prepare for a new one.
  
  @return boolean - true if transition succeeded
  @return string - Error message if transition failed
]]
function circuitStateMachine:reset()
  if not stateMachineInstance then
    return false, "State machine not initialized"
  end
  
  local currentState = stateMachineInstance:getCurrentState()
  
  -- Only reset from terminal states
  if currentState ~= STATES.COMPLETED and currentState ~= STATES.CANCELLED then
    return false, "Can only reset from COMPLETED or CANCELLED states (current: " .. currentState .. ")"
  end
  
  local success, error = stateMachineInstance:transitionTo(STATES.INACTIVE, {})
  
  if success then
    -- Clear persistence data when resetting to inactive
    local persistence = Addon.circuitPersistence
    persistence:reset()
  end
  
  return success, error
end

--[[
  Start a new circuit
  Transitions from INACTIVE to ACTIVE state.
  
  @param context table - Circuit start context:
    {
      selectedNpcIds = table,
      continentQueue = table,
      returnLocation = table,
      lastContinent = number,
      lastReturnType = string
    }
  @return boolean - true if transition succeeded
  @return string - Error message if transition failed
]]
function circuitStateMachine:start(context)
  if not stateMachineInstance then
    return false, "State machine not initialized"
  end
  
  local success, error = stateMachineInstance:transitionTo(STATES.ACTIVE, context)
  
  if success then
    -- Update persistence with new circuit data
    local persistence = Addon.circuitPersistence
    persistence:updateCircuitState("active", context)
  end
  
  return success, error
end

--[[
  Suspend the current circuit
  Transitions from ACTIVE to SUSPENDED state.
  
  @return boolean - true if transition succeeded
  @return string - Error message if transition failed
]]
function circuitStateMachine:suspend()
  if not stateMachineInstance then
    return false, "State machine not initialized"
  end
  
  local success, error = stateMachineInstance:transitionTo(STATES.SUSPENDED, {})
  
  if success then
    local persistence = Addon.circuitPersistence
    persistence:updateCircuitState("suspended", {})
  end
  
  return success, error
end

--[[
  Resume a suspended circuit
  Transitions from SUSPENDED to ACTIVE state.
  
  @return boolean - true if transition succeeded
  @return string - Error message if transition failed
]]
function circuitStateMachine:resume()
  if not stateMachineInstance then
    return false, "State machine not initialized"
  end
  
  local success, error = stateMachineInstance:transitionTo(STATES.ACTIVE, {})
  
  if success then
    local persistence = Addon.circuitPersistence
    persistence:updateCircuitState("active", {})
  end
  
  return success, error
end

--[[
  Complete the current circuit
  Transitions from ACTIVE to COMPLETED state.
  
  @param context table - Completion context (totalBattles, duration, etc.)
  @return boolean - true if transition succeeded
  @return string - Error message if transition failed
]]
function circuitStateMachine:complete(context)
  if not stateMachineInstance then
    return false, "State machine not initialized"
  end
  
  local success, error = stateMachineInstance:transitionTo(STATES.COMPLETED, context or {})
  
  if success then
    local persistence = Addon.circuitPersistence
    persistence:updateCircuitState("completed", context or {})
  end
  
  return success, error
end

--[[
  Cancel the current circuit
  Transitions from ACTIVE or SUSPENDED to CANCELLED state.
  
  @param context table|nil - Optional cancellation context (completedCount, totalCount)
  @return boolean - true if transition succeeded
  @return string - Error message if transition failed
]]
function circuitStateMachine:cancel(context)
  if not stateMachineInstance then
    return false, "State machine not initialized"
  end
  
  local success, error = stateMachineInstance:transitionTo(STATES.CANCELLED, context or {})
  
  if success then
    local persistence = Addon.circuitPersistence
    persistence:updateCircuitState("cancelled", context or {})
  end
  
  return success, error
end

--[[
  Get current circuit state
  @return string - Current state value
]]
function circuitStateMachine:getCurrentState()
  if not stateMachineInstance then
    return STATES.INACTIVE
  end
  
  return stateMachineInstance:getCurrentState()
end

--[[
  Check if circuit is in a specific state
  @param state string - State value to check (use STATES constants)
  @return boolean - true if in specified state
]]
function circuitStateMachine:isInState(state)
  if not stateMachineInstance then
    return state == STATES.INACTIVE
  end
  
  return stateMachineInstance:isInState(state)
end

--[[
  Check if circuit can transition to a specific state
  @param toState string - Target state value
  @param context table - Optional context for guard validation
  @return boolean - true if transition is valid
  @return string - Error message if transition is invalid
]]
function circuitStateMachine:canTransitionTo(toState, context)
  if not stateMachineInstance then
    return false, "State machine not initialized"
  end
  
  return stateMachineInstance:canTransitionTo(toState, context)
end

--[[
  Get valid transitions from current state
  @return table - Array of valid target state values
]]
function circuitStateMachine:getValidTransitions()
  if not stateMachineInstance then
    return {}
  end
  
  return stateMachineInstance:getValidTransitions()
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("circuitStateMachine", {"stateMachine", "circuitPersistence", "utils"}, function()
    return circuitStateMachine:initialize()
  end)
end

return circuitStateMachine