-- core/location.lua
local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in location.lua. This is a critical initialization error.|r")
    return {}
end
local utils = Addon.utils

local location = {}

--[[
    Get the current continent map ID using map hierarchy
    
    Returns:
    - continentMapID (number): The continent's map ID (e.g., 870=Pandaria, 13=Eastern Kingdoms, 12=Kalimdor, 466=Outland)
    - 0 if unable to determine
]]
function location:getCurrentContinent()
    -- Get player's current map
    local currentMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
    if not currentMapID then
        utils:debug("getCurrentContinent: Could not get player map ID - using fallback")
        -- Fallback to zone-based detection (returns best-guess continent IDs)
        local zone = GetZoneText()
        if zone then
            -- Pandaria zones
            if zone:find("Jade Forest") or zone:find("Valley of") or zone:find("Kun-Lai") or 
               zone:find("Townlong") or zone:find("Dread Wastes") or zone:find("Vale of Eternal") or 
               zone:find("Krasarang") or zone:find("Timeless Isle") then
                return 424  -- Pandaria
            -- Outland zones
            elseif zone:find("Hellfire") or zone:find("Zangarmarsh") or zone:find("Terokkar") or 
                   zone:find("Nagrand") or zone:find("Blade's Edge") or zone:find("Netherstorm") or 
                   zone:find("Shadowmoon Valley") then
                return 1467  -- Outland
            -- Northrend zones
            elseif zone:find("Borean") or zone:find("Howling Fjord") or zone:find("Dragonblight") or
                   zone:find("Grizzly Hills") or zone:find("Zul'Drak") or zone:find("Sholazar") or
                   zone:find("Storm Peaks") or zone:find("Icecrown") or zone:find("Crystalsong") then
                return 113  -- Northrend
            end
        end
        return 0  -- Unknown
    end
    
    -- Walk up the map hierarchy to find the continent
    local mapInfo = C_Map.GetMapInfo(currentMapID)
    if not mapInfo then
        utils:debug("getCurrentContinent: Could not get map info for " .. tostring(currentMapID))
        return 0
    end
    
    -- Traverse up to continent level
    local maxIterations = 10  -- Safety limit
    local iterations = 0
    while mapInfo and mapInfo.parentMapID and iterations < maxIterations do
        iterations = iterations + 1
        
        local parentInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
        if not parentInfo then
            break
        end
        
        -- Check if we've reached Cosmic (946) or Azeroth (947) level
        if parentInfo.mapID == 946 or parentInfo.mapID == 947 then
            -- Current map is the continent level - return its ID
            return mapInfo.mapID
        end
        
        -- Move up one level
        mapInfo = parentInfo
    end
    
    -- If we didn't find a proper continent, use what we have
    if mapInfo then
        utils:debug(string.format("getCurrentContinent: Using map ID %d ('%s') as continent (no parent found)", 
                   mapInfo.mapID, mapInfo.name or "Unknown"))
        return mapInfo.mapID
    end
    
    utils:debug("getCurrentContinent: Failed to determine continent after " .. iterations .. " iterations")
    return 0
end

--[[
    Get localized continent name from continent map ID
    Uses Blizzard's localization via C_Map.GetMapInfo()
    
    @param continentID (number): The continent map ID
    @return (string): Localized continent name, or "Unknown" if not found
]]
function location:getContinentName(continentID)
    if not continentID or continentID == 0 then
        return "Unknown"
    end
    
    local mapInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(continentID)
    if mapInfo and mapInfo.name then
        return mapInfo.name
    end
    
    -- Fallback for common continents if GetMapInfo fails
    local FALLBACK_NAMES = {
        [12] = "Kalimdor",
        [13] = "Eastern Kingdoms",
        [113] = "Northrend",
        [424] = "Pandaria",
        [1467] = "Outland",
    }
    
    return FALLBACK_NAMES[continentID] or "Unknown"
end

-- Get current player location (MoP compatible)
function location:getCurrentPlayerLocation()
    -- Use the legacy coordinate system that works in MoP
    local function getPlayerCoordinates()
        local uiMapID = C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player")
        if not uiMapID then
            return nil, 0, 0
        end
        
        local x, y = 0, 0
        if C_Map.GetPlayerMapPosition then
            local pos = C_Map.GetPlayerMapPosition(uiMapID, "player")
            if pos and pos.GetXY then
                local px, py = pos:GetXY()
                x, y = px * 100, py * 100
            end
        end
        
        return uiMapID, x, y
    end
    
    -- Get coordinates using the working legacy method
    local mapID, x, y = getPlayerCoordinates()
    
    if not mapID then
        utils:debug("getCurrentPlayerLocation: Could not get map ID via C_Map")
        -- No valid map ID available - use 0 and zone text only
        mapID = 0
        x, y = 50, 50 -- Default center coordinates
    end
    
    local zoneText = GetZoneText() or "Unknown"
    local subzoneText = GetSubZoneText() or ""
    
    -- Get continent using new hierarchy method (returns map ID)
    local continentID = self:getCurrentContinent()
    
    return {
        mapID = mapID,
        zone = zoneText,
        subzone = subzoneText,
        x = x,
        y = y,
        continent = continentID  -- Store the map ID (number), not the name
    }
end

function location:coordDistance(x1, y1, x2, y2)
    if not x1 or not y1 or not x2 or not y2 then
        return math.huge
    end
    
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx*dx + dy*dy)
end

function location:locationChanged(a, b, tolerance)
    tolerance = tolerance or 5
    local changed = {}
    
    -- Enhanced parameter validation
    if not a or type(a) ~= "table" then
        utils:debug("LocationChanged: Invalid first parameter - expected table, got " .. type(a) .. ".")
        return changed
    end
    
    if not b or type(b) ~= "table" then
        utils:debug("LocationChanged: Invalid second parameter - expected table, got " .. type(b) .. ".")
        return changed
    end
    
    -- Zone comparison
    if a.zone ~= b.zone then
        changed.zone = {a.zone or "Unknown", b.zone or "Unknown"}
    end
    
    -- Subzone comparison
    if a.subzone ~= b.subzone then
        changed.subzone = {a.subzone or "", b.subzone or ""}
    end
    
    -- Map ID comparison
    if a.mapID ~= b.mapID then
        changed.mapID = {a.mapID or 0, b.mapID or 0}
    end
    
    -- Continent comparison (numeric ID)
    if a.continent ~= b.continent then
        changed.continent = {a.continent or 0, b.continent or 0}
    end
    
    -- Faction comparison
    if a.faction ~= b.faction then
        changed.faction = {a.faction or "Unknown", b.faction or "Unknown"}
    end
    
    -- IMPROVED: Coordinate comparison with safety checks and finite distance validation
    local hasValidOldCoords = a.x and a.y and type(a.x) == "number" and type(a.y) == "number" and a.x > 0 and a.y > 0
    local hasValidNewCoords = b.x and b.y and type(b.x) == "number" and type(b.y) == "number" and b.x > 0 and b.y > 0
    
    if hasValidOldCoords and hasValidNewCoords then
        local dist = self:coordDistance(a.x, a.y, b.x, b.y)
        -- Only report coordinate changes if distance is finite and above tolerance
        if dist ~= math.huge and dist > tolerance then
            changed.coords = {a.x, a.y, b.x, b.y, dist}
        end
    elseif hasValidNewCoords and not hasValidOldCoords then
        -- Case: Old coordinates were invalid/missing, new ones are valid
        -- Don't report as movement since old position was unknown
        utils:debug("LocationChanged: Updated from invalid coordinates to valid position (" .. b.x .. ", " .. b.y .. ").")
    elseif hasValidOldCoords and not hasValidNewCoords then
        -- Case: Had valid coordinates, now they're invalid (shouldn't happen but handle gracefully)
        utils:debug("LocationChanged: Coordinates became invalid - keeping old position")
    end
    
    return changed
end

--[[
    Get zone name from map ID
    Uses Blizzard's C_Map API to resolve zone name.
    
    @param mapID number - Map ID
    @return string - Zone name, or "Unknown" if not found
]]
function location:getZoneByMapID(mapID)
    if not mapID or mapID == 0 then
        return "Unknown"
    end
    
    local mapInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    if mapInfo and mapInfo.name then
        return mapInfo.name
    end
    
    return "Unknown"
end

--[[
    Get continent ID from map ID by walking the map hierarchy.
    
    @param mapID number - Map ID (zone level)
    @return number - Continent map ID, or 0 if not found
]]
function location:getContinentByMapID(mapID)
    if not mapID or mapID == 0 then
        return 0
    end
    
    local mapInfo = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(mapID)
    if not mapInfo then
        return 0
    end
    
    -- Walk up hierarchy to find continent
    local maxIterations = 10
    local iterations = 0
    while mapInfo and mapInfo.parentMapID and iterations < maxIterations do
        iterations = iterations + 1
        
        local parentInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
        if not parentInfo then
            break
        end
        
        -- Cosmic (946) or Azeroth (947) = we're at continent level
        if parentInfo.mapID == 946 or parentInfo.mapID == 947 then
            return mapInfo.mapID
        end
        
        mapInfo = parentInfo
    end
    
    return mapInfo and mapInfo.mapID or 0
end

--[[
    Get the primary location from an NPC's locations array.
    Returns the first location entry.
    
    @param npc table - NPC record with locations array
    @return table|nil - Location object { mapID, continent, x, y } or nil
]]
function location:getNpcLocation(npc)
    if not npc then return nil end
    
    local locs = npc.locations
    if not locs or #locs == 0 then return nil end
    
    return locs[1]
end

--[[
    Get NPC location on a specific continent.
    For multi-location NPCs (vendors), finds the location matching the continent.
    Returns first location if no match found.
    
    @param npc table - NPC record with locations array
    @param continentID number - Target continent ID
    @return table|nil - Location object { mapID, continent, x, y } or nil
]]
function location:getNpcLocationOnContinent(npc, continentID)
    if not npc then return nil end
    
    local locs = npc.locations
    if not locs or #locs == 0 then return nil end
    
    -- Single location - just return it
    if #locs == 1 then
        return locs[1]
    end
    
    -- Multi-location - find matching continent
    for _, loc in ipairs(locs) do
        if loc.continent == continentID then
            return loc
        end
    end
    
    -- No match - return first
    return locs[1]
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("location", {"utils"}, function()
        return true -- No initialization needed, module is ready
    end)
end

Addon.location = location
return location