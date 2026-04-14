--[[
  logic/circuit/portalManager.lua
  Portal Finding and Availability Checking System
  
  Provides smart portal lookup functions that find the best portal from source to
  destination, handling bidirectional portals and faction-specific routing.
  
  Checks portal availability based on:
  - Event activity (Darkmoon Faire via npcUtils:isDarkmoonFaireActive())
  - Quest completion (Cataclysm unlocks via questTracker)
  - Faction eligibility
  
  Used by circuit routing to insert portal waypoints when NPCs require portal travel.
  
  Dependencies: utils, portalDatabase, questTracker, npcUtils
  Exports: Addon.portals
]]

local addonName, Addon = ...

Addon.portals = {}
local portals = Addon.portals

--[[
  Check if a portal is currently available to the player
  Validates event activity and quest completion requirements
  
  @param portal table - Portal record from database
  @return boolean - True if portal is usable
  @return string|nil - Reason if unavailable
]]
function portals:isPortalAvailable(portal)
  if not portal then
    return false, "Portal not found"
  end
  
  -- Check faction eligibility
  local playerFaction = UnitFactionGroup("player")
  if portal.faction ~= "both" and portal.faction ~= playerFaction then
    return false, "Wrong faction"
  end
  
  -- Check requirements
  if not portal.requirements then
    return true
  end
  
  -- Check event requirement (Darkmoon Faire)
  if portal.requirements.event then
    if portal.requirements.event == "DARKMOON_FAIRE" then
      if not Addon.npcUtils or not Addon.npcUtils.isDarkmoonFaireActive then
        return false, "Cannot check Darkmoon Faire status"
      end
      
      if not Addon.npcUtils:isDarkmoonFaireActive() then
        return false, "Darkmoon Faire is not active"
      end
    end
  end
  
  -- Check quest requirement (Cataclysm portals)
  if portal.requirements.quest then
    if not Addon.questTracker then
      return false, "Quest tracker not available"
    end
    
    local questId = portal.requirements.quest
    if not Addon.questTracker:isQuestCompleted(questId) then
      local quest = Addon.questTracker:getQuestData(questId)
      local questName = quest and quest.name or "Unknown Quest"
      return false, string.format("Quest '%s' not completed", questName)
    end
  end
  
  return true
end

--[[
  Find portal from source map to destination map
  Handles bidirectional portals automatically - will return reversed portal data
  if traveling in opposite direction
  
  @param fromMapID number - Current map ID
  @param toMapID number - Destination map ID
  @param playerFaction string - "Alliance" or "Horde" (optional, uses player if nil)
  @return table|nil - Portal record or nil if none found
  @return string|nil - Reason if no portal found
]]
function portals:findPortalTo(fromMapID, toMapID, playerFaction)
  if not fromMapID or not toMapID then
    return nil, "Invalid map IDs"
  end
  
  playerFaction = playerFaction or UnitFactionGroup("player")
  local db = Addon.portalDatabase
  
  -- Check forward direction portals
  local sourcePortals = db.indices.bySourceMap[fromMapID] or {}
  for _, portal in ipairs(sourcePortals) do
    -- Check faction
    if portal.faction == playerFaction or portal.faction == "both" then
      -- Check destination
      if portal.destination.mapID == toMapID then
        local available, reason = self:isPortalAvailable(portal)
        if available then
          return portal
        end
      end
    end
  end
  
  -- Check reverse direction (bidirectional portals)
  local destPortals = db.indices.byDestinationMap[fromMapID] or {}
  for _, portal in ipairs(destPortals) do
    -- Check if bidirectional
    if portal.bidirectional then
      -- Check faction
      if portal.faction == playerFaction or portal.faction == "both" then
        -- Check if portal leads from our target back to our source
        if portal.location.mapID == toMapID then
          local available, reason = self:isPortalAvailable(portal)
          if available then
            -- Return reversed portal data
            return {
              id = portal.id .. "_reversed",
              portalType = portal.portalType,
              location = portal.destination,  -- Swap
              destination = portal.location,  -- Swap
              faction = portal.faction,
              bidirectional = portal.bidirectional,
              requirements = portal.requirements,
            }
          end
        end
      end
    end
  end
  
  return nil, "No portal route found"
end

--[[
  Get all portals on a specific map
  Used for finding available portals when player is on a map
  
  @param mapID number - Map ID to search
  @param playerFaction string - Optional faction filter ("Alliance"/"Horde")
  @return table - Array of portal records
]]
function portals:getPortalsOnMap(mapID, playerFaction)
  playerFaction = playerFaction or UnitFactionGroup("player")
  local db = Addon.portalDatabase
  local results = {}
  
  local portalsOnMap = db.indices.bySourceMap[mapID] or {}
  for _, portal in ipairs(portalsOnMap) do
    if portal.faction == playerFaction or portal.faction == "both" then
      local available, reason = self:isPortalAvailable(portal)
      if available then
        table.insert(results, portal)
      end
    end
  end
  
  return results
end

--[[
  Get all portals leading TO a specific map
  Used for finding how to reach a destination
  
  @param mapID number - Destination map ID
  @param playerFaction string - Optional faction filter
  @return table - Array of portal records
]]
function portals:getPortalsToMap(mapID, playerFaction)
  playerFaction = playerFaction or UnitFactionGroup("player")
  local db = Addon.portalDatabase
  local results = {}
  
  local portalsToMap = db.indices.byDestinationMap[mapID] or {}
  for _, portal in ipairs(portalsToMap) do
    if portal.faction == playerFaction or portal.faction == "both" then
      local available, reason = self:isPortalAvailable(portal)
      if available then
        table.insert(results, portal)
      end
    end
  end
  
  return results
end

--[[
  Find nearest available portal that leads to destination map
  Useful when player is not on a map with a direct portal
  
  @param currentMapID number - Player's current map
  @param toMapID number - Destination map
  @param playerFaction string - Optional faction
  @return table|nil - Portal record or nil
  @return number|nil - Distance to portal in yards (if found)
]]
function portals:findNearestPortalTo(currentMapID, toMapID, playerFaction)
  -- Get player position
  if not Addon.location or not Addon.location.getCurrentPlayerLocation then
    return nil, nil
  end
  
  local playerLoc = Addon.location:getCurrentPlayerLocation()
  if not playerLoc.x or not playerLoc.y or not playerLoc.mapID then
    return nil, nil
  end
  
  -- Get all portals that lead to destination
  local portalsToDestination = self:getPortalsToMap(toMapID, playerFaction)
  
  if #portalsToDestination == 0 then
    return nil, nil
  end
  
  -- Find nearest portal
  local HBD = LibStub("HereBeDragons-2.0")
  if not HBD then
    -- Fallback: just return first portal
    return portalsToDestination[1], nil
  end
  
  local nearestPortal = nil
  local nearestDistance = math.huge
  
  for _, portal in ipairs(portalsToDestination) do
    local x, y, z = HBD:GetZoneDistance(
      playerLoc.mapID, playerLoc.x / 100, playerLoc.y / 100,
      portal.location.mapID, portal.location.x / 100, portal.location.y / 100
    )
    
    if x then
      local dist = math.sqrt(x*x + (y or 0)*(y or 0) + (z or 0)*(z or 0))
      if dist < nearestDistance then
        nearestDistance = dist
        nearestPortal = portal
      end
    end
  end
  
  return nearestPortal, nearestDistance
end

--[[
  Check if an NPC requires portal travel
  Used by circuit routing to determine if portal waypoints are needed
  
  @param npcId number - NPC ID
  @return boolean - True if NPC requires portal
  @return number|nil - Destination map ID if portal required
]]
function portals:doesNpcRequirePortal(npcId)
  -- Portal-required NPCs (from circuitConstants or npcData)
  local PORTAL_REQUIRED_NPCS = {
    [67370] = 407,  -- Jeremy Feasel → Darkmoon Island
    [66815] = 640,  -- Bordin Steadyfist → Deepholm
  }
  
  return PORTAL_REQUIRED_NPCS[npcId] ~= nil, PORTAL_REQUIRED_NPCS[npcId]
end

if Addon.registerModule then
  Addon.registerModule("portalManager", {"utils", "portals", "questTracker", "npcUtils"}, function()
    return true
  end)
end

return portals