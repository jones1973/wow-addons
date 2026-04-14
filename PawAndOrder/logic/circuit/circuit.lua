--[[
  logic/circuit/circuit.lua
  Pet Battle Circuit Planning and Routing Logic
  
  Core business logic for circuit management including route planning, progress tracking,
  NPC advancement, and continent transitions. Now uses the state machine for all
  state transitions, ensuring validated state changes.
  
  Dependencies: waypoint, location, npcUtils, routeOptimizer, circuitPersistence, circuitConstants, circuitData, circuitStateMachine
  Exports: Addon.circuit
]]

local addonName, Addon = ...

Addon.circuit = {}
local circuit = Addon.circuit

-- Convenience wrapper — Addon.location is guaranteed by registerModule dependencies
local function getPlayerLocation()
    return Addon.location:getCurrentPlayerLocation()
end

-- Find which index in the continent queue matches a given continent ID
-- Returns index or nil
local function findContinentInQueue(queue, continent)
    for i, entry in ipairs(queue) do
        if entry.continent == continent then
            return i
        end
    end
    return nil
end

-- Move a continent to the front of the queue (if not already there)
-- Mutates the queue in place and persists the change
local function promoteContinent(continentQueue, index, continent)
    if index <= 1 then return end
    local entry = table.remove(continentQueue, index)
    table.insert(continentQueue, 1, entry)
    Addon.circuitPersistence:updateContinentQueue(continentQueue)
    Addon.circuitPersistence:setCurrentContinent(continent)
end

--[[
  Re-optimize route for a continent from the player's current position.
  Called when player arrives on a circuit continent with no active NPC target.
  Handles queue reordering, user messaging, and advancing to the first NPC.
]]
local function reoptimizeForContinent(continentData, continentIndex, continentQueue, position, continent)
    local persistence = Addon.circuitPersistence
    local startX, startY, startMapID = position.x, position.y, position.mapID

    -- Build NPC list the same way a fresh circuit would:
    -- Original selection minus completed, filtered to this continent
    local selectedNpcIds = persistence:getSelectedNpcIds()
    local completedNpcs = persistence:getCompletedNpcs()
    
    -- Build completed lookup
    local completedLookup = {}
    for _, id in ipairs(completedNpcs) do
        completedLookup[id] = true
    end
    
    -- Filter to: selected, not completed, on this continent
    local npcIds = {}
    for _, npcId in ipairs(selectedNpcIds) do
        if not completedLookup[npcId] then
            local npc = Addon.npcUtils:getNpcData(npcId)
            local loc = npc and Addon.location:getNpcLocation(npc)
            if loc and loc.continent == continent then
                table.insert(npcIds, npcId)
            end
        end
    end
    
    Addon.utils:debug(string.format("[REOPT] Built NPC list: %d selected, %d completed, %d remaining on continent %d",
        #selectedNpcIds, #completedNpcs, #npcIds, continent))

    local nnRoute = Addon.routeOptimizer:generateNearestNeighborRoute(
        npcIds, startX, startY, startMapID)
    local nnDistance = Addon.routeOptimizer:calculateRouteDistance(
        nnRoute, startX, startY, startMapID)

    local optimizedRoute = Addon.routeOptimizer:generateOptimizedRoute(
        npcIds, startX, startY, startMapID, nil, nil, nil, true)
    local optimizedDistance = Addon.routeOptimizer:calculateRouteDistance(
        optimizedRoute, startX, startY, startMapID)

    continentData.npcIds = optimizedRoute

    local improvement = nnDistance > 0
        and ((nnDistance - optimizedDistance) / nnDistance) * 100
        or nil
    local continentName = Addon.location:getContinentName(continent) or "current continent"

    if continentIndex > 1 then
        -- Arrived on a non-front continent — promote it and start fresh
        promoteContinent(continentQueue, continentIndex, continent)
        persistence:setCurrentNpc(nil)

        if improvement then
            Addon.utils:notify(string.format(
                "Circuit adapted to %s. %.1f%% shorter distance than nearest neighbor. %d battles remaining.",
                continentName, improvement, #continentData.npcIds))
        else
            Addon.utils:notify(string.format(
                "Circuit adapted to %s. %d battles remaining.",
                continentName, #continentData.npcIds))
        end

        circuit:startNextContinent()
    else
        -- Already the front continent — just re-optimize in place
        persistence:updateContinentQueue(continentQueue)

        if improvement and improvement > 1 then
            Addon.utils:notify(string.format(
                "Circuit optimized for current location. %.1f%% shorter distance than nearest neighbor.",
                improvement))
        elseif not improvement or improvement <= 1 then
            Addon.utils:notify("No circuit optimizations found from current location.")
        end

        persistence:setCurrentNpc(nil)
        circuit:advanceToNextNpc()
    end

    -- Auto-resume if we just optimized onto the continent the player is on
    if persistence:isCircuitSuspended() and continent == persistence:getCurrentContinent() then
        Addon.utils:debug("Auto-resuming suspended circuit after adapting to arrival on correct continent")
        circuit:resume()
    end
end

--[[
  Check for location changes and adapt circuit if needed
  Called on character login, continent changes, and suspended circuit checks.
  
  Behavior:
  - Different character OR different continent -> Re-optimize current continent route
  - Different continent in circuit -> Reorder queue, re-optimize that continent  
  - Different continent not in circuit -> Suspend with travel prompt
  - Zone changes within the same continent are intentionally ignored.
    The optimized route should be followed as planned. Use /pao circuit reroute
    or the tracker button to manually reoptimize from current position.
  
  @return boolean - true if adaptation occurred
]]
function circuit:checkAndAdaptToLocation()
  local persistence = Addon.circuitPersistence
  
  -- Only adapt if circuit is active
  if not persistence:isCircuitActive() and not persistence:isCircuitSuspended() then
    return false
  end
  
  -- Get current location
  local currentCharacter = UnitName("player")
  local playerLoc = getPlayerLocation()
  local currentContinent = playerLoc.continent
  local currentPosition = {
    x = playerLoc.x,
    y = playerLoc.y,
    mapID = playerLoc.mapID
  }
  
  -- Get saved location
  local savedCharacter = persistence:getLastKnownCharacter()
  local savedContinent = persistence:getLastKnownContinent()
  local savedPosition = persistence:getLastKnownPosition()
  
  -- First time tracking (fresh login/reload) — no saved state to compare against.
  -- If a currentNpc exists, force through adaptation logic to restore waypoint/state.
  local forceAdaptation = false
  if not savedCharacter or not savedContinent then
    local currentNpcId = persistence:getCurrentNpc()
    if not currentNpcId then
      -- No active NPC, just save and return
      persistence:updateLastKnownCharacter(currentCharacter)
      persistence:updateLastKnownContinent(currentContinent)
      persistence:updateLastKnownPosition(currentPosition)
      return false
    end
    -- Active NPC exists — need to adapt (restore waypoint, check continent, etc.)
    forceAdaptation = true
  end
  
  -- Check if location changed
  local characterChanged = (currentCharacter ~= savedCharacter)
  local continentChanged = (currentContinent ~= savedContinent)
  local isSuspended = persistence:isCircuitSuspended()
  
  -- Only adapt on continent change, character change, suspended state check,
  -- or forced adaptation (fresh login with active NPC).
  -- Zone changes within the same continent do NOT trigger rerouting — the optimized
  -- route should be followed as planned. Players can manually reroute if desired.
  if not forceAdaptation and not characterChanged and not continentChanged and not isSuspended then
    return false
  end
  
  if characterChanged or continentChanged then
    Addon.utils:debug(string.format("Location change detected: char=%s->%s, continent=%s->%s",
      tostring(savedCharacter), tostring(currentCharacter),
      tostring(savedContinent), tostring(currentContinent)))
  elseif isSuspended then
    Addon.utils:debug("Checking suspended circuit for adaptation (no location change)")
  end
  
  -- Update saved location FIRST before any logic that might return early
  persistence:updateLastKnownCharacter(currentCharacter)
  persistence:updateLastKnownContinent(currentContinent)
  persistence:updateLastKnownPosition(currentPosition)
  
  local continentQueue = persistence:getContinentQueue()
  
  if #continentQueue == 0 then
    return false
  end
  
  -- Is the player's continent part of this circuit?
  local continentIndex = findContinentInQueue(continentQueue, currentContinent)
  
  if not continentIndex then
    -- Current continent not in circuit - suspend and prepare for travel
    -- DON'T clear currentNpc — we need it to resume when player returns to circuit continent
    Addon.utils:debug("Current continent not in circuit - suspending")
    if not isSuspended then
      Addon.waypoint:clear()
      persistence:setCurrentContinent(continentQueue[1].continent)
      self:suspend()
    end
    return false
  end
  
  local continentData = continentQueue[continentIndex]

  -- Does the circuit have an active NPC target?
  local currentNpcId = persistence:getCurrentNpc()
  local currentNpc = currentNpcId and Addon.npcUtils:getNpcData(currentNpcId)
  local currentNpcLoc = currentNpc and Addon.location:getNpcLocation(currentNpc)
  local currentNpcContinent = currentNpcLoc and currentNpcLoc.continent
  
  -- Continent changed and current NPC is on this continent — reoptimize route
  -- from player's new position. No hysteresis: a continent change means the player
  -- meaningfully relocated, so a fresh optimization is always appropriate.
  if continentChanged and currentNpc and currentNpcContinent == currentContinent then
    Addon.utils:debug(string.format("Continent change: reoptimizing route from current position on %s",
      Addon.location:getContinentName(currentContinent) or "continent"))
    reoptimizeForContinent(continentData, continentIndex, continentQueue, currentPosition, currentContinent)
    
    if isSuspended then
      self:resume()
    end
    
    if Addon.events then
      Addon.events:emit("CIRCUIT:STATE_CHANGED", {
        adapted = true,
        continent = currentContinent
      })
    end
    
    return true
  end
  
  if currentNpc and currentNpcContinent == currentContinent then
    -- Active NPC is on this continent — resume with it
    Addon.utils:debug(string.format("Resuming circuit on %s with current NPC: %s", 
      Addon.location:getContinentName(currentContinent) or "continent", currentNpc.name))
    
    promoteContinent(continentQueue, continentIndex, currentContinent)
    
    if currentNpcLoc then
      local zoneName = Addon.location:getZoneByMapID(currentNpcLoc.mapID)
      Addon.waypoint:set(currentNpcLoc.mapID, currentNpcLoc.x, currentNpcLoc.y, currentNpc.name, zoneName)
    end
    
    if isSuspended then
      self:resume()
    end
    
    if Addon.events then
      Addon.events:emit("CIRCUIT:PROGRESS_UPDATED", {
        npcId = currentNpcId,
        npcName = currentNpc.name,
        remaining = self:getRemainingBattleCount()
      })
    end
    
    return true
    
  elseif currentNpc and currentNpcContinent then
    -- Active NPC is on a different continent — suspend for travel
    Addon.utils:debug(string.format("Player on %s but currentNpc is on %s - suspending for travel",
      Addon.location:getContinentName(currentContinent) or "continent",
      Addon.location:getContinentName(currentNpcContinent) or "continent"))
    
    if not isSuspended then
      persistence:setCurrentContinent(currentNpcContinent)
      Addon.waypoint:clear()
      self:suspend()
    end
    
    return false
  end
  
  -- No active NPC (or NPC data missing) — reoptimize from current position
  reoptimizeForContinent(continentData, continentIndex, continentQueue, currentPosition, currentContinent)
  
  if Addon.events then
    Addon.events:emit("CIRCUIT:STATE_CHANGED", {
      adapted = true,
      continent = currentContinent
    })
  end
  
  return true
end

--[[
  Start a new circuit
  Validates NPCs, builds optimized route, and initializes circuit state via state machine.
  Resets state machine if in terminal state (CANCELLED/COMPLETED).
  If a circuit is already ACTIVE or SUSPENDED, cancels it first before starting the new one.
  
  @param selectedNpcIds table - Array of selected NPC IDs to visit
  @param returnLocationType string - "none", "current", "questgiver"
]]
function circuit:start(selectedNpcIds, returnLocationType)
  local persistence = Addon.circuitPersistence
  local stateMachine = Addon.circuitStateMachine
  
  -- Initialize persistence layer
  persistence:initialize()
  
  -- Handle existing circuit state
  if stateMachine then
    local currentState = stateMachine:getCurrentState()
    
    -- If ACTIVE or SUSPENDED, cancel the existing circuit first
    if currentState == stateMachine.STATES.ACTIVE or currentState == stateMachine.STATES.SUSPENDED then
      Addon.utils:debug(string.format("Circuit: Cancelling existing circuit in state '%s' before starting new one", currentState))
      Addon.utils:notify("Cancelled existing circuit. Starting new circuit.")
      self:cancel()
      -- After cancel, state should be CANCELLED
      currentState = stateMachine:getCurrentState()
    end
    
    -- If in terminal state (CANCELLED/COMPLETED), reset to INACTIVE
    if currentState == stateMachine.STATES.CANCELLED or currentState == stateMachine.STATES.COMPLETED then
      Addon.utils:debug(string.format("Circuit: Resetting state machine from '%s' to 'inactive'", currentState))
      
      -- Clear persistence data FIRST
      persistence:reset()
      
      -- Then reset state machine
      stateMachine:reset()
      
      -- Verify state actually changed
      local newState = stateMachine:getCurrentState()
      if newState ~= stateMachine.STATES.INACTIVE then
        Addon.utils:error(string.format("State machine reset failed: still in '%s' instead of 'inactive'", newState))
        Addon.utils:chat("Failed to start circuit: Circuit is in invalid state. Try /reload")
        return
      end
      
      Addon.utils:debug("Circuit: State machine successfully reset to 'inactive'")
    end
  end
  
  -- Validate NPCs are still available
  local validNpcs = Addon.npcUtils:validateNpcs(selectedNpcIds)
  
  if #validNpcs == 0 then
    Addon.utils:chat("No valid NPCs selected for circuit.")
    return
  end
  
  -- Group by continent
  local npcsByContinent = Addon.routeOptimizer:groupNpcsByContinent(validNpcs)
  
  -- Get player's current continent
  local playerContinent = getPlayerLocation().continent
  
  -- Order continents (player's current first)
  local continentQueue = Addon.routeOptimizer:buildContinentQueue(npcsByContinent, playerContinent)
  
  -- Capture return location
  local returnLoc = self:captureReturnLocation(returnLocationType)
  
  -- Start circuit via state machine
  local context = {
    selectedNpcIds = validNpcs,
    continentQueue = continentQueue,
    returnLocation = returnLoc,
    lastContinent = playerContinent,
    lastReturnType = returnLocationType,
  }
  
  local success, err = stateMachine:start(context)
  
  if not success then
    Addon.utils:chat("Failed to start circuit: " .. (err or "Unknown error"))
    return
  end
  
  -- Start first continent
  self:startNextContinent()
  
  -- Initialize location tracking
  local currentCharacter = UnitName("player")
  local playerLoc = getPlayerLocation()
  persistence:updateLastKnownCharacter(currentCharacter)
  persistence:updateLastKnownContinent(playerLoc.continent)
  persistence:updateLastKnownPosition({
    x = playerLoc.x,
    y = playerLoc.y,
    mapID = playerLoc.mapID
  })
  
  Addon.utils:notify(string.format("Circuit started with %d battles across %d continent(s)!", 
    #validNpcs, #continentQueue))
end

--[[
  Capture return location based on type
  Uses circuitConstants for quest giver coordinates.
  
  @param locationType string - "none", "current", "questgiver"
  @return table - Location data structure from circuitData
]]
function circuit:captureReturnLocation(locationType)
  local circuitData = Addon.circuitData
  local constants = Addon.circuitConstants
  local locationData = nil
  
  if locationType == constants.RETURN_TYPES.CURRENT then
    local playerLoc = getPlayerLocation()
    locationData = {
      continent = playerLoc.continent,
      zone = playerLoc.zone,
      mapID = playerLoc.mapID,
      x = playerLoc.x,
      y = playerLoc.y,
      name = "Starting Location",
    }
    
  elseif locationType == constants.RETURN_TYPES.QUEST_GIVER then
    local questGiver = constants:getQuestGiverForFaction()
    locationData = {
      continent = questGiver.continent,
      zone = questGiver.zone,
      mapID = questGiver.mapID,
      x = questGiver.x,
      y = questGiver.y,
      name = questGiver.name,
    }
  end
  
  return circuitData:createReturnLocation(locationType, locationData)
end

--[[
  Reoptimize circuit from current position after off-course victory
  Filters out completed NPCs and rebuilds route from player's current location.
  Called when user defeats a circuit NPC out of order.
]]
function circuit:reoptimizeFromCurrent()
  local persistence = Addon.circuitPersistence
  
  -- Get remaining NPCs (selected minus completed)
  local selectedNpcIds = persistence:getSelectedNpcIds()
  local completedNpcs = persistence:getCompletedNpcs()
  
  -- Validate we have the data we need
  if not selectedNpcIds or not completedNpcs then
    Addon.utils:debug("Cannot reoptimize: missing circuit data")
    return
  end
  
  local completedSet = {}
  for _, npcId in ipairs(completedNpcs) do
    completedSet[npcId] = true
  end
  
  local remainingNpcs = {}
  for _, npcId in ipairs(selectedNpcIds) do
    if not completedSet[npcId] then
      table.insert(remainingNpcs, npcId)
    end
  end
  
  if #remainingNpcs == 0 then
    -- Circuit complete!
    self:complete()
    return
  end
  
  Addon.utils:debug(string.format("Reoptimizing circuit: %d remaining NPCs", #remainingNpcs))
  
  -- Group by continent
  local npcsByContinent = Addon.routeOptimizer:groupNpcsByContinent(remainingNpcs)
  
  -- Get player's current continent
  local playerContinent = getPlayerLocation().continent
  
  -- Build new continent queue from current position
  local continentQueue = Addon.routeOptimizer:buildContinentQueue(npcsByContinent, playerContinent)
  
  -- Update persistence with new queue
  persistence:updateContinentQueue(continentQueue)
  
  -- Start the next continent (will be current continent if we're still on it)
  self:startNextContinent()
end

--[[
  User-initiated route recalculation from current position.
  Reoptimizes the remaining circuit route without canceling or losing progress.
  Called via /pao circuit reroute or the tracker reroute button.
]]
function circuit:reroute()
  local persistence = Addon.circuitPersistence
  
  if not persistence:isCircuitActive() and not persistence:isCircuitSuspended() then
    Addon.utils:chat("No active circuit to reroute.")
    return
  end
  
  Addon.utils:notify("Rerouting circuit from current location...")
  self:reoptimizeFromCurrent()
end

--[[
  Start routing the next continent in queue
  Handles continent transitions, travel suspension, and route optimization.
  
  CRITICAL FIXES:
  1. Check if player is on correct continent BEFORE setting waypoints
  2. Only use player position for optimization if on same continent
  3. Suspend and show travel prompt if on wrong continent
]]
function circuit:startNextContinent()
  local persistence = Addon.circuitPersistence
  local continentQueue = persistence:getContinentQueue()
  
  if #continentQueue == 0 then
    self:complete()
    return
  end
  
  local continentData = continentQueue[1]
  local nextContinent = continentData.continent
  
  -- CRITICAL: Check if player is on correct continent FIRST
  local playerContinent = getPlayerLocation().continent
  
  if playerContinent ~= nextContinent then
    -- Player is on WRONG continent - suspend circuit and request travel
    Addon.utils:debug(string.format("Circuit: Player on continent %s, but next NPCs are on continent %s - suspending for travel", 
      tostring(playerContinent), tostring(nextContinent)))
    
    persistence:setCurrentContinent(nextContinent)
    persistence:setCurrentNpc(nil)  -- Clear so resume knows this is continent transition
    self:suspend()
    
    return  -- Exit early - don't set waypoints yet
  end
  
  -- Player is on CORRECT continent - proceed with routing
  persistence:setCurrentContinent(continentData.continent)
  
  -- Get start position with mapID for route optimization
  -- Since we verified player is on correct continent, use their actual position
  local startX, startY, startMapID = 50, 50, 0 -- Default fallback
  local playerLoc = getPlayerLocation()
  if playerLoc.x and playerLoc.y and playerLoc.mapID then
    startX, startY, startMapID = playerLoc.x, playerLoc.y, playerLoc.mapID
  end
  
  -- Calculate return location for this continent (if applicable)
  local returnLocation = persistence:getReturnLocation()
  local endX, endY, endMapID = nil, nil, nil
  
  if returnLocation.type == "questgiver" and 
     returnLocation.continent == continentData.continent then
    endX = returnLocation.x
    endY = returnLocation.y
    endMapID = returnLocation.mapID
  elseif returnLocation.type == "current" and
         returnLocation.continent == continentData.continent then
    endX = returnLocation.x
    endY = returnLocation.y
    endMapID = returnLocation.mapID
  end
  
  -- Generate optimized route with HereBeDragons distance calculation
  local optimizedRoute = Addon.routeOptimizer:generateOptimizedRoute(
    continentData.npcIds, startX, startY, startMapID, endX, endY, endMapID
  )
  
  -- Store optimized route back in continent data
  continentData.npcIds = optimizedRoute
  persistence:updateContinentQueue(continentQueue)
  
  Addon.utils:debug(string.format("Starting continent routing with %d NPCs", #optimizedRoute))
  
  -- Fire event for UI to update
  if Addon.events then
    Addon.events:emit("CIRCUIT:CONTINENT_STARTED", {
      continent = continentData.continent,
      npcCount = #optimizedRoute
    })
  end
  
  -- Set first waypoint
  self:advanceToNextNpc()
end

--[[
  Advance to next NPC in current continent
  Removes current NPC from queue and sets waypoint to next target.
]]
function circuit:advanceToNextNpc()
  local persistence = Addon.circuitPersistence
  
  -- Mark current as completed if exists
  local currentNpcId = persistence:getCurrentNpc()
  if currentNpcId then
    persistence:markNpcCompleted(currentNpcId)
  end
  
  -- Clear old waypoint
  Addon.waypoint:clear()
  
  -- Get current continent data
  local continentQueue = persistence:getContinentQueue()
  if #continentQueue == 0 then
    self:complete()
    return
  end
  
  local continentData = continentQueue[1]
  
  -- Pop NPCs until we find a valid, incomplete one or exhaust the queue
  local npc, nextNpcId
  while #continentData.npcIds > 0 do
    nextNpcId = table.remove(continentData.npcIds, 1)
    npc = Addon.npcUtils:getNpcData(nextNpcId)
    if not npc then
      Addon.utils:debug("Skipping invalid NPC " .. tostring(nextNpcId) .. " - not found in database")
      npc = nil
    elseif Addon.npcUtils:isNpcCompletedToday(nextNpcId) then
      -- Quest already complete (exploit scenario or manually completed)
      Addon.utils:debug("Skipping NPC " .. tostring(nextNpcId) .. " (" .. (npc.name or "?") .. ") - quest already completed today")
      persistence:markNpcCompleted(nextNpcId)
      npc = nil
    else
      break
    end
  end
  
  persistence:updateContinentQueue(continentQueue)
  
  if not npc then
    -- Exhausted all NPCs on this continent (all invalid or empty)
    persistence:setCurrentNpc(nil)
    self:completeContinent()
    return
  end
  
  persistence:setCurrentNpc(nextNpcId)
  
  -- Check if this NPC requires portal travel
  local needsPortal = false
  local portalLocation = nil
  
  if Addon.portalManager then
    local requiresPortal, destMapID = Addon.portalManager:doesNpcRequirePortal(nextNpcId)
    if requiresPortal and destMapID then
      -- Get player's current location
      local playerMapID = getPlayerLocation().mapID or 0
      
      -- Only need portal if not already at destination
      if playerMapID ~= destMapID then
        needsPortal = true
        -- Find the portal
        local portal = Addon.portalManager:findNearestPortalTo(destMapID, UnitFactionGroup("player"))
        if portal then
          portalLocation = portal.location
        end
      end
    end
  end
  
  -- Set appropriate waypoint
  local loc = Addon.location:getNpcLocation(npc)
  local zoneName = loc and Addon.location:getZoneByMapID(loc.mapID) or "Destination"
  
  if needsPortal and portalLocation then
    -- Set waypoint to portal first
    local portalZoneName = Addon.location:getZoneByMapID(portalLocation.mapID)
    local portalName = "Portal to " .. zoneName
    Addon.waypoint:set(portalLocation.mapID, portalLocation.x, portalLocation.y, portalName, portalZoneName)
    Addon.utils:debug(string.format("Set portal waypoint for %s", npc.name))
  elseif loc then
    -- Set waypoint directly to tamer
    Addon.waypoint:set(loc.mapID, loc.x, loc.y, npc.name, zoneName)
  end
  
  -- Fire event for UI to update tracker
  if Addon.events then
    Addon.events:emit("CIRCUIT:PROGRESS_UPDATED", {
      npcId = nextNpcId,
      npcName = npc.name,
      remaining = self:getRemainingBattleCount()
    })
  end
end
--[[
  Complete current continent and move to next
  Advances to next continent or completes circuit if this was the last continent.
]]
function circuit:completeContinent()
  local persistence = Addon.circuitPersistence
  
  -- Remove completed continent
  local continentQueue = persistence:getContinentQueue()
  table.remove(continentQueue, 1)
  persistence:updateContinentQueue(continentQueue)
  
  if #continentQueue == 0 then
    -- Circuit complete!
    self:complete()
  else
    -- Check if player on next continent
    local nextContinent = continentQueue[1].continent
    local playerContinent = getPlayerLocation().continent
    
    if playerContinent == nextContinent then
      -- Already there, continue
      self:startNextContinent()
    else
      -- Need to travel - clear current NPC and suspend
      persistence:setCurrentContinent(nextContinent)  -- Set for tracker display
      persistence:setCurrentNpc(nil)  -- Clear so resume knows this is continent transition
      Addon.waypoint:clear()  -- Clear waypoint
      self:suspend()
    end
  end
end

--[[
  Set return waypoint
  Uses return location data from persistence layer.
]]
function circuit:setReturnWaypoint()
  local persistence = Addon.circuitPersistence
  local loc = persistence:getReturnLocation()
  
  if loc.x and loc.y and loc.mapID then
    -- Use clearDistance=40 so TomTom auto-clears waypoint when player reaches destination
    Addon.waypoint:set(loc.mapID, loc.x, loc.y, loc.name, loc.zone, 40)
  end
end

--[[
  Complete entire circuit
  Sets final return waypoint if configured, shows completion message.
  Uses state machine for transition.
]]
function circuit:complete()
  local persistence = Addon.circuitPersistence
  local stateMachine = Addon.circuitStateMachine
  local returnLocation = persistence:getReturnLocation()
  
  -- Set final return waypoint if needed
  if returnLocation.type == "current" or returnLocation.type == "questgiver" then
    self:setReturnWaypoint()
  end
  
  local completedNpcs = persistence:getCompletedNpcs()
  local startTime = persistence:getStartTime()
  local totalBattles = #completedNpcs
  local duration = time() - (startTime or time())
  local minutes = math.floor(duration / 60)
  
  Addon.utils:notify(string.format("Circuit complete! %d battles in %d minutes.", 
    totalBattles, minutes))
  
  -- Complete via state machine (fires CIRCUIT:COMPLETED event automatically)
  stateMachine:complete({
    totalBattles = totalBattles,
    duration = duration,
    minutes = minutes,
    completedNpcs = completedNpcs,
    selectedNpcIds = persistence:getSelectedNpcIds(),
  })
end

--[[
  Resume a suspended circuit
  Reactivates circuit via state machine. Handles two cases:
  1. Mid-continent resume: Restores waypoint to current NPC
  2. Continent transition resume: Starts next continent routing
]]
function circuit:resume()
  local persistence = Addon.circuitPersistence
  local stateMachine = Addon.circuitStateMachine
  
  if not persistence:isCircuitSuspended() then
    Addon.utils:chat("No suspended circuit to resume.")
    return
  end
  
  -- Resume via state machine
  local success, err = stateMachine:resume()
  
  if not success then
    Addon.utils:chat("Failed to resume circuit: " .. (err or "Unknown error"))
    return
  end
  
  -- Check if this is mid-continent or continent transition
  local currentNpcId = persistence:getCurrentNpc()
  
  if currentNpcId then
    -- Mid-continent resume: just restore waypoint to current NPC
    local npc = Addon.npcUtils:getNpcData(currentNpcId)
    if npc then
      local loc = Addon.location:getNpcLocation(npc)
      if loc then
        local zoneName = Addon.location:getZoneByMapID(loc.mapID)
        Addon.waypoint:set(loc.mapID, loc.x, loc.y, npc.name, zoneName)
      end
      Addon.utils:debug("Restored waypoint to current NPC after resume")
    end
  else
    -- Continent transition: start routing the next continent
    Addon.utils:debug("Starting next continent after resume")
    self:startNextContinent()
  end
  
  Addon.utils:chat("Circuit resumed.")
end

--[[
  Suspend the current circuit
  Pauses circuit temporarily without canceling via state machine.
]]
function circuit:suspend()
  local persistence = Addon.circuitPersistence
  local stateMachine = Addon.circuitStateMachine
  
  if not persistence:isCircuitActive() then
    Addon.utils:chat("No active circuit to suspend.")
    return
  end
  
  -- Suspend via state machine
  local success, err = stateMachine:suspend()
  
  if not success then
    Addon.utils:chat("Failed to suspend circuit: " .. (err or "Unknown error"))
    return
  end
  
  Addon.waypoint:clear()
  
  Addon.utils:chat("Circuit suspended. Use /pao circuit resume to continue.")
end

--[[
  Cancel the current circuit
  Clears all circuit state and stops routing via state machine.
]]
function circuit:cancel()
  local persistence = Addon.circuitPersistence
  local stateMachine = Addon.circuitStateMachine
  
  if not persistence:getCircuitState().active then
    Addon.utils:chat("No active circuit to cancel.")
    return
  end
  
  -- Cancel via state machine
  local completedNpcs = persistence:getCompletedNpcs() or {}
  local selectedNpcIds = persistence:getSelectedNpcIds() or {}
  local success, err = stateMachine:cancel({
    completedCount = #completedNpcs,
    totalCount = #selectedNpcIds,
  })
  
  if not success then
    Addon.utils:chat("Failed to cancel circuit: " .. (err or "Unknown error"))
    return
  end
  
  Addon.waypoint:clear()
  
  Addon.utils:chat("Circuit cancelled.")
end

--[[
  Get remaining battle count
  Counts NPCs remaining in continent queue plus current NPC.
  
  @return number - Number of battles remaining in circuit
]]
function circuit:getRemainingBattleCount()
  local persistence = Addon.circuitPersistence
  local continentQueue = persistence:getContinentQueue()
  local count = 0
  
  for _, continentData in ipairs(continentQueue) do
    count = count + #continentData.npcIds
  end
  
  -- Add 1 if there's a current NPC
  if persistence:getCurrentNpc() then
    count = count + 1
  end
  
  return count
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("circuit", {"utils", "location", "waypoint", "npcUtils", "routeOptimizer", "circuitPersistence", "circuitConstants", "circuitData", "circuitStateMachine", "circuitBattleHandler"}, function()
    return true
  end)
end

return circuit