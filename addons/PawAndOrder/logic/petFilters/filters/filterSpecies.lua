--[[
  logic/petFilters/filters/speciesFilter.lua
  Species Filter
  
  Matches pets by species name or ID.
  Supports partial name matching (fuzzy) by default.
  Quoted strings enable exact matching.
  
  Examples:
    species:spider       -> Species with "spider" in name (partial)
    species:"Snow Cub"   -> Species exactly named "Snow Cub" (exact)
    species:258          -> Species ID 258 (exact)
    !species:rat         -> Species WITHOUT "rat" in name
  
  Dependencies: FilterType, FilterRegistry
]]

local ADDON_NAME, Addon = ...

-- Wait for dependencies
if not Addon.filterType or not Addon.filterRegistry then
    error("speciesFilter: Dependencies not loaded")
end

local filterType = Addon.filterType

local speciesFilter = filterType:new({
    id = "species",
    category = "species",
    patterns = {"^species[:=](.+)$"},
    priority = 10,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures, wasQuoted)
        -- wasQuoted = true means exact match, false means partial/fuzzy
        return {
            value = value:lower(),
            exact = wasQuoted,
        }
    end,
    
    matcher = function(pet, speciesData)
        local value = speciesData.value
        local exact = speciesData.exact
        
        -- Try as species ID first
        local speciesID = tonumber(value)
        if speciesID and pet.speciesID == speciesID then
            return true
        end
        
        -- Try name match
        if not pet.speciesName then return false end
        
        if exact then
            return pet.speciesName:lower() == value
        else
            return pet.speciesName:lower():find(value, 1, true) ~= nil
        end
    end,
})

-- Self-register
Addon.filterRegistry:register(speciesFilter)

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterSpecies", {"filterType", "filterRegistry"}, function()
        return true
    end)
end

return speciesFilter