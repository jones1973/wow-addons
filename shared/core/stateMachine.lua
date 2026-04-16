--[[
  core/stateMachine.lua
  Generic State Machine Framework
  
  Provides a reusable factory for creating validated, event-driven state machines
  for any addon feature. State machines ensure that only valid state transitions
  occur, provide guard conditions for transition validation, and fire events on
  every state change for UI updates.
  
  This framework eliminates scattered state manipulation, provides a single source
  of truth for state changes, and makes state-dependent logic testable and maintainable.
  
  Usage Example:
    local sm = Addon.stateMachine:create({
      name = "CircuitStateMachine",
      states = {INACTIVE = "inactive", ACTIVE = "active"},
      initialState = "inactive",
      transitions = {
        {from = "inactive", to = "active", guards = {"hasValidData"}, on = "start"},
        {from = "active", to = "inactive", on = "stop"}
      },
      guards = {
        hasValidData = function(context) return context.data ~= nil end
      }
    })
  
  Dependencies: utils, events
  Exports: Addon.stateMachine
]]

local addonName, Addon = ...

Addon.stateMachine = {}
local stateMachine = Addon.stateMachine

--[[
  Create a new state machine instance
  Factory method that returns a configured state machine with validation,
  guards, and event firing.
  
  @param config table - State machine configuration:
    {
      name = string,                -- State machine name (for events and debugging)
      states = table,               -- State constants: {STATE_NAME = "state_value"}
      initialState = string,        -- Initial state value
      transitions = table,          -- Array of transition definitions
      guards = table,               -- Guard functions: {guardName = function(context)}
      onEnter = table (optional),   -- State entry callbacks: {state = function(context)}
      onExit = table (optional)     -- State exit callbacks: {state = function(context)}
    }
  
  @return table - State machine instance with API methods
]]
function stateMachine:create(config)
  -- Validate configuration
  if not config.name or type(config.name) ~= "string" then
    Addon.utils:error("stateMachine:create - 'name' is required and must be a string")
    return nil
  end
  
  if not config.states or type(config.states) ~= "table" then
    Addon.utils:error("stateMachine:create - 'states' is required and must be a table")
    return nil
  end
  
  if not config.initialState or type(config.initialState) ~= "string" then
    Addon.utils:error("stateMachine:create - 'initialState' is required and must be a string")
    return nil
  end
  
  if not config.transitions or type(config.transitions) ~= "table" then
    Addon.utils:error("stateMachine:create - 'transitions' is required and must be a table")
    return nil
  end
  
  -- Build transition map for fast lookups
  local transitionMap = {}
  for _, transition in ipairs(config.transitions) do
    local fromStates = type(transition.from) == "table" and transition.from or {transition.from}
    
    for _, fromState in ipairs(fromStates) do
      if not transitionMap[fromState] then
        transitionMap[fromState] = {}
      end
      
      transitionMap[fromState][transition.to] = {
        guards = transition.guards or {},
        event = transition.on or nil
      }
    end
  end
  
  -- Create instance
  local instance = {
    name = config.name,
    states = config.states,
    currentState = config.initialState,
    transitionMap = transitionMap,
    guards = config.guards or {},
    onEnter = config.onEnter or {},
    onExit = config.onExit or {},
  }
  
  --[[
    Get current state
    @return string - Current state value
  ]]
  function instance:getCurrentState()
    return self.currentState
  end
  
  --[[
    Check if state machine is in a specific state
    @param state string - State value to check
    @return boolean - true if in specified state
  ]]
  function instance:isInState(state)
    return self.currentState == state
  end
  
  --[[
    Validate guard conditions
    Checks if all guards for a transition pass.
    
    @param guards table - Array of guard function names
    @param context table - Context data passed to guard functions
    @return boolean - true if all guards pass
    @return string - Error message if any guard fails
  ]]
  function instance:validateGuards(guards, context)
    for _, guardName in ipairs(guards) do
      local guardFunc = self.guards[guardName]
      
      if not guardFunc then
        return false, "Guard function '" .. guardName .. "' not found"
      end
      
      local success, result = pcall(guardFunc, context)
      
      if not success then
        return false, "Guard '" .. guardName .. "' threw error: " .. tostring(result)
      end
      
      if not result then
        return false, "Guard '" .. guardName .. "' failed"
      end
    end
    
    return true, nil
  end
  
  --[[
    Check if transition is valid
    Validates that a transition from current state to target state is allowed
    and that all guard conditions pass.
    
    @param toState string - Target state value
    @param context table - Context data for guard validation
    @return boolean - true if transition is valid
    @return string - Error message if transition is invalid
  ]]
  function instance:canTransitionTo(toState, context)
    local fromState = self.currentState
    
    -- Check if transition exists
    if not self.transitionMap[fromState] then
      return false, "No transitions defined from state '" .. fromState .. "'"
    end
    
    local transition = self.transitionMap[fromState][toState]
    if not transition then
      return false, "Transition from '" .. fromState .. "' to '" .. toState .. "' not allowed"
    end
    
    -- Validate guards
    if #transition.guards > 0 then
      local guardsPass, guardError = self:validateGuards(transition.guards, context or {})
      if not guardsPass then
        return false, guardError
      end
    end
    
    return true, nil
  end
  
  --[[
    Transition to new state
    Validates transition, executes exit/entry callbacks, updates state,
    and fires event. This is the ONLY way to change state.
    
    @param toState string - Target state value
    @param context table - Context data for guards and callbacks
    @return boolean - true if transition succeeded
    @return string - Error message if transition failed
  ]]
  function instance:transitionTo(toState, context)
    context = context or {}
    local fromState = self.currentState
    
    -- Validate transition
    local canTransition, error = self:canTransitionTo(toState, context)
    if not canTransition then
      Addon.utils:debug(string.format("%s: Transition blocked - %s", self.name, error))
      return false, error
    end
    
    -- Execute exit callback for current state
    if self.onExit[fromState] then
      local success, exitError = pcall(self.onExit[fromState], context)
      if not success then
        Addon.utils:error(string.format("%s: Exit callback failed - %s", self.name, tostring(exitError)))
      end
    end
    
    -- Update state
    self.currentState = toState
    
    -- Execute entry callback for new state
    if self.onEnter[toState] then
      local success, enterError = pcall(self.onEnter[toState], context)
      if not success then
        Addon.utils:error(string.format("%s: Entry callback failed - %s", self.name, tostring(enterError)))
      end
    end
    
    -- Fire event
    local transition = self.transitionMap[fromState][toState]
    local eventName = transition.event or string.format("STATE_CHANGED:%s", self.name)
    
    if Addon.events then
      Addon.events:emit(eventName, {
        stateMachine = self.name,
        fromState = fromState,
        toState = toState,
        context = context
      })
    end
    
    Addon.utils:debug(string.format("%s: Transitioned from '%s' to '%s'", 
      self.name, fromState, toState))
    
    return true, nil
  end
  
  --[[
    Get valid transitions from current state
    Returns array of states that can be transitioned to from current state.
    
    @return table - Array of valid target state values
  ]]
  function instance:getValidTransitions()
    local fromState = self.currentState
    local validStates = {}
    
    if self.transitionMap[fromState] then
      for toState, _ in pairs(self.transitionMap[fromState]) do
        table.insert(validStates, toState)
      end
    end
    
    return validStates
  end
  
  --[[
    Reset state machine to initial state
    Forces state back to initial without validation. Use with caution.
  ]]
  function instance:reset()
    local oldState = self.currentState
    self.currentState = config.initialState
    
    Addon.utils:debug(string.format("%s: Reset from '%s' to '%s'", 
      self.name, oldState, self.currentState))
    
    if Addon.events then
      Addon.events:emit("STATE_RESET:" .. self.name, {
        stateMachine = self.name,
        oldState = oldState,
        newState = self.currentState
      })
    end
  end
  
  return instance
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("stateMachine", {"utils", "events"}, function()
    return true
  end)
end

return stateMachine
