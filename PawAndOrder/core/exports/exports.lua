-- core/exports/exports.lua - Export Data Registry System
-- Allows data sources to self-register for export window
local ADDON_NAME, Addon = ...

local exports = {}
exports._registry = {}
exports._sortedNamesCache = nil

-- Register a data source for export
-- @param name string - Export identifier (e.g., "species", "abilities")
-- @param dataFunction function - Function that returns the data to export
function exports:register(name, dataFunction)
    assert(type(name) == "string", "Export name must be a string")
    assert(type(dataFunction) == "function", "Export dataFunction must be a function")
    
    self._registry[name] = dataFunction
    self._sortedNamesCache = nil  -- Invalidate cache
end

-- Get data for a specific export type
-- @param name string - Export identifier
-- @return table|nil - The data to export, or nil if not found
function exports:get(name)
    local fn = self._registry[name]
    if not fn then
        return nil
    end
    
    local success, result = pcall(fn)
    if not success then
        if Addon.utils and Addon.utils.error then
            Addon.utils:error(string.format("Error getting export data for '%s': %s", name, tostring(result)))
        end
        return nil
    end
    
    return result
end

-- Get list of all registered export names
-- @return table - Sorted array of export names
function exports:getAllNames()
    if self._sortedNamesCache then
        return self._sortedNamesCache
    end
    
    local names = {}
    for name in pairs(self._registry) do
        table.insert(names, name)
    end
    table.sort(names)
    self._sortedNamesCache = names
    return names
end

-- Check if an export type is registered
-- @param name string - Export identifier
-- @return boolean
function exports:isRegistered(name)
    return self._registry[name] ~= nil
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("exports", {}, function()
        return true
    end)
end

Addon.exports = exports
return exports