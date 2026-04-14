--[[
  logic/circuit/waypoint.lua
  Waypoint management for circuit navigation using TomTom addon integration
  
  Provides waypoint creation, clearing, and visibility control for circuit navigation.
  Integrates with TomTom addon for directional arrows and map markers. Falls back to
  coordinate printing when TomTom is unavailable. Uses HereBeDragons for coordinate
  validation and translation.
  
  Dependencies: utils, location, HereBeDragons-2.0 (lib)
  Exports: Addon.waypoint
]]

local addonName, Addon = ...

Addon.waypoint = {}
local waypoint = Addon.waypoint

-- Module state
local currentWaypointUid = nil
local currentWaypointData = nil  -- Store data to recreate waypoint after battle
local WAYPOINT_THRESHOLD = 40 -- yards (legacy, for isPlayerNear coordinate check)
local PROXIMITY_HIDE_YARDS = 7 -- Hide waypoint arrow when within this distance
local isHiddenByProximity = false -- Track if hidden due to proximity (vs battle)

-- Load HereBeDragons library for coordinate validation
local HBD = LibStub("HereBeDragons-2.0")

--[[
  Check if TomTom addon is available and loaded
  @return boolean - true if TomTom is loaded and accessible
]]
function waypoint:isAvailable()
  return _G["TomTom"] ~= nil
end

--[[
  Set a waypoint using TomTom with HBD coordinate validation
  @param mapID number - WoW map ID for the zone
  @param x number - x coordinate (0-100 scale)
  @param y number - y coordinate (0-100 scale)
  @param npcName string - NPC name for waypoint title
  @param zoneName string - zone name for fallback message (optional)
  @param clearDistance number - Distance in yards at which TomTom auto-clears waypoint (optional, default 0 = don't auto-clear)
  @return boolean - true if waypoint was set successfully
]]
function waypoint:set(mapID, x, y, npcName, zoneName, clearDistance)
  if not self:isAvailable() then
    self:printFallback(zoneName or "Unknown Zone", x, y, npcName)
    return false
  end
  
  -- Validate coordinates using HBD
  if not HBD then
    Addon.utils:debug("HBD not available, proceeding without validation")
  else
    -- Validate map ID exists
    if not mapID or mapID == 0 then
      Addon.utils:debug("Invalid mapID provided: " .. tostring(mapID))
      self:printFallback(zoneName or "Unknown Zone", x, y, npcName)
      return false
    end
    
    -- Validate coordinate ranges
    if not x or not y or x < 0 or x > 100 or y < 0 or y > 100 then
      Addon.utils:debug(string.format("Invalid coordinates: %.2f, %.2f", x or -1, y or -1))
      self:printFallback(zoneName or "Unknown Zone", x, y, npcName)
      return false
    end
  end
  
  -- Clear any existing PAO waypoint
  self:clear()
  
  -- Convert 0-100 coordinates to 0-1 for TomTom
  local tomX = x / 100
  local tomY = y / 100
  
  -- Default clearDistance to 0 (don't auto-clear) for circuit NPCs
  clearDistance = clearDistance or 0
  
  -- Format title with zone - colorized for better appearance
  -- Orange for name, white for zone
  local title = "|cFFFF8800" .. npcName .. "|r"
  if zoneName and zoneName ~= "" then
    title = "|cFFFF8800" .. npcName .. "|r\n|cFFFFFFFF" .. zoneName .. "|r"
  end
  
  -- Get default callbacks from TomTom if clearDistance is set
  local callbacks = nil
  if clearDistance > 0 then
    callbacks = TomTom:DefaultCallbacks({
      cleardistance = clearDistance,
      arrivaldistance = 15
    })
  end
  
  -- Create waypoint with CORRECT TomTom API signature
  -- TomTom:AddWaypoint(mapID, x, y, options)
  currentWaypointUid = TomTom:AddWaypoint(mapID, tomX, tomY, {
    title = title,
    source = "PawAndOrder",
    persistent = false,
    minimap = true,
    world = true,
    crazy = true, -- enables directional arrow
    clearable = false, -- prevent manual clearing
    silent = true, -- suppress arrival notifications
    cleardistance = clearDistance, -- TomTom auto-clears when within this distance (0 = disabled)
    arrivaldistance = 15, -- arrow changes to "down" when within 15 yards (keeps arrow visible)
    callbacks = callbacks, -- Use default callbacks if clearDistance > 0
  })
  
  if currentWaypointUid then
    -- Store data for potential recreation after battle
    currentWaypointData = {
      mapID = mapID,
      x = x,
      y = y,
      npcName = npcName,
      zoneName = zoneName,
      clearDistance = clearDistance
    }
    
    -- Reset proximity hidden flag since we just created/recreated the waypoint
    isHiddenByProximity = false
    
    return true
  else
    Addon.utils:debug("Failed to create waypoint using TomTom, falling back to coordinates")
    self:printFallback(zoneName or "Unknown Zone", x, y, npcName)
    return false
  end
end

--[[
  Clear the current PAO waypoint
  Removes the active waypoint marker from TomTom
]]
function waypoint:clear()
  if currentWaypointUid and self:isAvailable() then
    TomTom:RemoveWaypoint(currentWaypointUid)
    currentWaypointUid = nil
    currentWaypointData = nil
    isHiddenByProximity = false
  end
end

--[[
  Hide waypoint arrow during pet battles
  Uses TomTom API to clear the waypoint entirely (including arrow), stores data for recreation.
]]
function waypoint:hide()
  if not self:isAvailable() then return end
  
  if currentWaypointUid then
    -- Clear waypoint using TomTom API (removes arrow, minimap, worldmap)
    TomTom:ClearWaypoint(currentWaypointUid)
    
    if pao_circuit then
      pao_circuit.waypointHidden = true
    end
  end
end

--[[
  Restore waypoint after battle loss/forfeit
  Recreates the waypoint using stored data. Only call this when the player needs to 
  retry the same NPC (i.e., didn't win). If they won, advanceToNextNpc() will create 
  a new waypoint automatically.
  
  Checks quest completion status first - if quest is already done (exploit detection),
  triggers circuit advancement instead of restoring.
]]
function waypoint:restore()
  if not self:isAvailable() then return end
  
  if currentWaypointData then
    -- Check if current NPC's quest is already completed (exploit/out-of-band completion)
    local persistence = Addon.circuitPersistence
    local npcUtils = Addon.npcUtils
    if persistence and npcUtils then
      local currentNpcId = persistence:getCurrentNpc()
      if currentNpcId and npcUtils:isNpcCompletedToday(currentNpcId) then
        Addon.utils:debug("Quest already completed for NPC " .. currentNpcId .. " - advancing instead of restoring")
        if Addon.circuit and Addon.circuit.advanceToNextNpc then
          Addon.circuit:advanceToNextNpc()
        end
        return
      end
    end
    
    -- Recreate waypoint using stored data
    local data = currentWaypointData
    self:set(data.mapID, data.x, data.y, data.npcName, data.zoneName, data.clearDistance)
    
    if pao_circuit then
      pao_circuit.waypointHidden = false
    end
  end
end

--[[
  Print coordinate fallback when TomTom unavailable
  Outputs a /way command to chat that users can copy/paste
  @param zoneName string - zone name
  @param x number - x coordinate
  @param y number - y coordinate
  @param npcName string - NPC name
]]
function waypoint:printFallback(zoneName, x, y, npcName)
  Addon.utils:notify(string.format("Next waypoint: /way %s %.1f %.1f %s", 
    zoneName, x, y, npcName))
end

--[[
  Check if player is near target coordinates
  @param targetX number - target x coordinate
  @param targetY number - target y coordinate
  @param threshold number - distance threshold (optional, default 40)
  @return boolean - true if player is within threshold
]]
function waypoint:isPlayerNear(targetX, targetY, threshold)
  threshold = threshold or WAYPOINT_THRESHOLD
  
  local playerX, playerY = nil, nil
  
  if Addon.location and Addon.location.getCurrentPlayerLocation then
    local playerLoc = Addon.location:getCurrentPlayerLocation()
    playerX = playerLoc.x
    playerY = playerLoc.y
  end
  
  if not playerX or not playerY then 
    return false 
  end
  
  local distance = math.sqrt((playerX - targetX)^2 + (playerY - targetY)^2)
  return distance <= threshold
end

--[[
  Get yard distance from player to current waypoint target
  Uses HereBeDragons for accurate cross-zone distance calculation.
  @return number|nil - Distance in yards, or nil if cannot calculate
]]
function waypoint:getDistanceToTarget()
  if not currentWaypointData then return nil end
  if not HBD then return nil end
  
  local playerLoc = Addon.location and Addon.location:getCurrentPlayerLocation()
  if not playerLoc or not playerLoc.mapID then return nil end
  
  local targetMapID = currentWaypointData.mapID
  local targetX = currentWaypointData.x / 100  -- Convert to 0-1 for HBD
  local targetY = currentWaypointData.y / 100
  local playerX = playerLoc.x / 100
  local playerY = playerLoc.y / 100
  
  local dx, dy = HBD:GetZoneDistance(playerLoc.mapID, playerX, playerY, targetMapID, targetX, targetY)
  if not dx then return nil end
  
  return math.sqrt(dx * dx + (dy or 0) * (dy or 0))
end

--[[
  Check proximity and hide/show waypoint accordingly
  Hides waypoint when player is within PROXIMITY_HIDE_YARDS of target
  or when player has the NPC targeted.
  Re-shows when player moves beyond that distance (unless in battle).
  Called periodically by circuit tracker OnUpdate.
  
  @return boolean - true if waypoint is currently visible
]]
function waypoint:checkProximity()
  if not currentWaypointData then return false end
  if not self:isAvailable() then return false end
  
  -- Never restore during pet battle
  if C_PetBattles and C_PetBattles.IsInBattle and C_PetBattles.IsInBattle() then
    return false
  end
  
  -- Check if player has the target NPC selected
  if UnitExists("target") then
    local targetName = UnitName("target")
    if targetName and currentWaypointData.npcName and 
       targetName:find(currentWaypointData.npcName, 1, true) then
      -- Target matches - hide waypoint
      if not isHiddenByProximity and currentWaypointUid then
        TomTom:ClearWaypoint(currentWaypointUid)
        isHiddenByProximity = true
      end
      return false
    end
  end
  
  local distance = self:getDistanceToTarget()
  if not distance then return not isHiddenByProximity end
  
  if distance <= PROXIMITY_HIDE_YARDS then
    -- Within proximity - hide if not already hidden
    if not isHiddenByProximity and currentWaypointUid then
      TomTom:ClearWaypoint(currentWaypointUid)
      isHiddenByProximity = true
    end
    return false
  else
    -- Beyond proximity - show if was hidden by proximity
    if isHiddenByProximity then
      -- Recreate waypoint
      local data = currentWaypointData
      self:set(data.mapID, data.x, data.y, data.npcName, data.zoneName, data.clearDistance)
      isHiddenByProximity = false
    end
    return true
  end
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("waypoint", {"utils", "location"}, function()
    return true
  end)
end

return waypoint