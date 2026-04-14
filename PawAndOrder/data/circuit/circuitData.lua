--[[
  data/circuit/circuitData.lua
  Circuit Data Schema Definitions
  
  Defines the canonical structure for circuit-related SavedVariables (pao_circuit
  and pao_settings.circuit). Provides schema documentation and default value
  factories for initializing new circuit data. This module serves as the single
  source of truth for circuit data structure.
  
  Dependencies: circuitConstants
  Exports: Addon.circuitData
]]

local addonName, Addon = ...

Addon.circuitData = {}
local circuitData = Addon.circuitData

--[[
  Create default circuit state structure
  Returns a fresh circuit state with all fields initialized to default values.
  This is the canonical schema for the pao_circuit SavedVariable.
  
  @return table - Default circuit state structure
]]
function circuitData:createDefaultCircuitState()
  return {
    -- Circuit active state
    active = false,           -- Whether a circuit is currently running
    suspended = false,        -- Whether circuit is paused (awaiting continent travel)
    
    -- Current progress
    currentContinent = nil,   -- Continent ID currently being routed
    currentNpcId = nil,       -- NPC ID player is currently traveling to
    continentQueue = {},      -- Array of {continent=num, npcIds={...}} for remaining route
    completedInCircuit = {},  -- Array of NPC IDs completed in this circuit run
    
    -- Circuit configuration (preserved for resume/reset)
    selectedNpcIds = {},      -- Original array of selected NPC IDs
    lastContinent = nil,      -- Continent player was on when circuit started
    lastReturnType = "none",  -- Last selected return type ("none", "current", "questgiver")
    
    -- Return location data
    returnLocation = {
      type = "none",          -- "none", "current", or "questgiver"
      continent = nil,        -- Continent ID of return location
      zone = nil,             -- Zone name
      mapID = nil,            -- Map ID for waypoint
      x = nil,                -- X coordinate (0-100)
      y = nil,                -- Y coordinate (0-100)
      name = nil,             -- Display name for return location
    },
    
    -- Timing and session data
    circuitStartTime = nil,   -- Unix timestamp when circuit started
    lastDailyResetTime = nil, -- Last known daily reset time (for change detection)
    
    -- Location tracking for re-optimization
    lastKnownCharacter = nil, -- Character name who last modified circuit
    lastKnownContinent = nil, -- Continent ID of last known location
    lastKnownPosition = nil,  -- {x, y, mapID} of last position
    
    -- UI state
    waypointHidden = false,   -- Whether waypoint arrow is currently hidden
  }
end

--[[
  Create default circuit settings structure
  Returns fresh circuit settings with all fields initialized to default values.
  This is the canonical schema for pao_settings.circuit.
  
  @return table - Default circuit settings structure
]]
function circuitData:createDefaultCircuitSettings()
  local constants = Addon.circuitConstants
  
  return {
    -- Daily reset warnings
    resetWarningEnabled = true,
    resetWarningTime = constants.TIMING.DEFAULT_RESET_WARNING_TIME,
    resetWarningInterval = constants.TIMING.DEFAULT_RESET_WARNING_INTERVAL,
    lastResetWarning = 0,  -- Unix timestamp of last warning shown
    
    -- UI state persistence
    trackerPosition = nil,  -- {point, relativePoint, x, y} - saved tracker position
  }
end

--[[
  Create a return location data structure
  Factory for creating return location objects with consistent schema.
  
  @param locationType string - "none", "current", or "questgiver"
  @param locationData table - Optional. Location-specific data (continent, zone, mapID, x, y, name)
  @return table - Return location structure
]]
function circuitData:createReturnLocation(locationType, locationData)
  local location = {
    type = locationType or "none",
    continent = nil,
    zone = nil,
    mapID = nil,
    x = nil,
    y = nil,
    name = nil,
  }
  
  if locationData then
    location.continent = locationData.continent
    location.zone = locationData.zone
    location.mapID = locationData.mapID
    location.x = locationData.x
    location.y = locationData.y
    location.name = locationData.name
  end
  
  return location
end

--[[
  Create a continent route data structure
  Factory for creating continent queue entries with consistent schema.
  
  @param continent number - Continent ID
  @param npcIds table - Array of NPC IDs to visit on this continent
  @return table - Continent route structure
]]
function circuitData:createContinentRoute(continent, npcIds)
  return {
    continent = continent,
    npcIds = npcIds or {},
  }
end

--[[
  Validate circuit state structure
  Checks if a circuit state object has all required fields and valid data types.
  Used for detecting corruption or migration needs.
  
  @param state table - Circuit state to validate
  @return boolean - true if valid, false if missing fields or invalid types
  @return string - Error message if invalid, nil if valid
]]
function circuitData:validateCircuitState(state)
  if not state then
    return false, "Circuit state is nil"
  end
  
  -- Check required boolean fields
  local requiredBools = {"active", "suspended", "waypointHidden"}
  for _, field in ipairs(requiredBools) do
    if type(state[field]) ~= "boolean" then
      return false, "Field '" .. field .. "' must be boolean"
    end
  end
  
  -- Check required table fields
  local requiredTables = {"continentQueue", "completedInCircuit", "selectedNpcIds", "returnLocation"}
  for _, field in ipairs(requiredTables) do
    if type(state[field]) ~= "table" then
      return false, "Field '" .. field .. "' must be table"
    end
  end
  
  -- Check return location structure
  if not state.returnLocation.type then
    return false, "returnLocation.type is required"
  end
  
  return true, nil
end

--[[
  Get schema documentation
  Returns human-readable documentation of the circuit data structures.
  Useful for debugging and understanding the data model.
  
  @return string - Multi-line documentation string
]]
function circuitData:getSchemaDocumentation()
  return [[
Circuit Data Schema Documentation
==================================

pao_circuit (SavedVariable - Character)
  .active (boolean) - Circuit is running
  .suspended (boolean) - Circuit paused for travel
  .currentContinent (number|nil) - Current continent ID
  .currentNpcId (number|nil) - Current target NPC ID
  .continentQueue (array) - Remaining route
    [n].continent (number) - Continent ID
    [n].npcIds (array) - NPC IDs on this continent
  .completedInCircuit (array) - Completed NPC IDs
  .selectedNpcIds (array) - Original selection
  .lastContinent (number|nil) - Starting continent
  .lastReturnType (string) - "none", "current", "questgiver"
  .returnLocation (table) - Return waypoint data
    .type (string) - "none", "current", "questgiver"
    .continent (number|nil)
    .zone (string|nil)
    .mapID (number|nil)
    .x (number|nil) - 0-100
    .y (number|nil) - 0-100
    .name (string|nil)
  .circuitStartTime (number|nil) - Unix timestamp
  .lastDailyResetTime (number|nil) - GetQuestResetTime()
  .lastKnownCharacter (string|nil) - Last character name
  .lastKnownContinent (number|nil) - Last continent ID
  .lastKnownPosition (table|nil) - Last position {x, y, mapID}
  .waypointHidden (boolean) - Arrow visibility state

pao_settings.circuit (SavedVariable - Global)
  .resetWarningEnabled (boolean)
  .resetWarningTime (number) - Seconds before reset
  .resetWarningInterval (number) - Seconds between warnings
  .lastResetWarning (number) - Unix timestamp
  .trackerPosition (table|nil) - Saved UI position
    .point (string)
    .relativePoint (string)
    .x (number)
    .y (number)
]]
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("circuitData", {"circuitConstants"}, function()
    -- No initialization needed - just schema definitions
    return true
  end)
end

return circuitData