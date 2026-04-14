--[[
  logic/petFilters/filterRegistry.lua
  Filter Registry
  
  Central registry for all filter types. Filters self-register during load.
  Provides sorted access to all registered filters by priority.
  
  Dependencies: None (registry pattern)
  Exports: Addon.filterRegistry
]]

local ADDON_NAME, Addon = ...

local filterRegistry = {}

-- Internal storage
local registeredFilters = {}  -- [id] = FilterType
local sortedFilters = nil     -- Cached sorted array

--[[
  Register a filter type
  
  @param filterType FilterType - Filter type instance to register
]]
function filterRegistry:register(filterType)
    if not filterType or not filterType.id then
        error("filterRegistry: Invalid filter type")
    end
    
    if registeredFilters[filterType.id] then
        error("filterRegistry: Filter already registered: " .. filterType.id)
    end
    
    registeredFilters[filterType.id] = filterType
    sortedFilters = nil  -- Invalidate cache
    
    if Addon.utils then
        Addon.utils:debug("filterRegistry: Registered " .. filterType.id)
    end
end

--[[
  Get all registered filters sorted by priority
  
  @return table - Array of FilterType instances, sorted by priority (low to high)
]]
function filterRegistry:getAllFilters()
    if sortedFilters then
        return sortedFilters
    end
    
    -- Build sorted array
    local filters = {}
    for _, filter in pairs(registeredFilters) do
        table.insert(filters, filter)
    end
    
    table.sort(filters, function(a, b)
        if a.priority == b.priority then
            -- Same priority: sort by id for deterministic order
            return a.id < b.id
        end
        return a.priority < b.priority
    end)
    
    sortedFilters = filters
    
    if Addon.utils and #filters == 0 then
        Addon.utils:debug("WARNING: filterRegistry has NO registered filters!")
    end
    
    return sortedFilters
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

Addon.filterRegistry = filterRegistry

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterRegistry", {}, function()
        return true
    end)
end

return filterRegistry