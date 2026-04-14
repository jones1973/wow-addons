--[[
  logic/petFilters/filters/locationFilter.lua
  Location Filter
  
  Matches pets by location keywords. The special keyword "here" matches
  pets found in the player's current zone or subzone.
  
  Examples:
    here      → Pets found in current zone
    !here     → Pets NOT found in current zone
  
  Dependencies: FilterType, FilterRegistry
]]

local ADDON_NAME, Addon = ...

-- Wait for dependencies
if not Addon.filterType or not Addon.filterRegistry then
    error("locationFilter: Dependencies not loaded")
end

local filterType = Addon.filterType

-- Cache for current location (refreshed when filter runs)
local locationCache = {
    zone = nil,
    subZone = nil,
    timestamp = 0,
}

-- How long to cache location (seconds)
local CACHE_DURATION = 1

--[[
  Get current zone and subzone names.
  Uses a short cache to avoid repeated API calls during filtering.
  
  @return string, string - zone, subZone (lowercase)
]]
local function getCurrentLocation()
    local now = GetTime()
    
    if now - locationCache.timestamp < CACHE_DURATION then
        return locationCache.zone, locationCache.subZone
    end
    
    -- Get current zone info
    local zone = GetZoneText() or ""
    local subZone = GetSubZoneText() or ""
    
    -- Normalize to lowercase for matching
    locationCache.zone = zone:lower()
    locationCache.subZone = subZone:lower()
    locationCache.timestamp = now
    
    return locationCache.zone, locationCache.subZone
end

local locationFilter = filterType:new({
    id = "location",
    category = "location",
    patterns = {"^here$"},  -- Only matches "here" exactly
    priority = 60,  -- Higher priority than source (70) and text (100)
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        -- "here" is the only supported keyword for now
        if term:lower() == "here" then
            return "here"
        end
        return nil
    end,
    
    matcher = function(pet, locationKeyword)
        if locationKeyword ~= "here" then
            return false
        end
        
        -- Get current zone/subzone
        local zone, subZone = getCurrentLocation()
        
        if not zone or zone == "" then
            return false
        end
        
        -- Check pet's source text for zone match
        if not pet.sourceText then
            return false
        end
        
        local source = pet.sourceText:lower()
        
        -- Match on zone name
        if zone ~= "" and source:find(zone, 1, true) then
            return true
        end
        
        -- Match on subzone name (if different and non-empty)
        if subZone ~= "" and subZone ~= zone and source:find(subZone, 1, true) then
            return true
        end
        
        return false
    end,
})

-- Self-register
Addon.filterRegistry:register(locationFilter)

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterLocation", {"filterType", "filterRegistry"}, function()
        return true
    end)
end

return locationFilter
