--[[
  logic/petFilters/filters/familyFilter.lua
  Family Filter
  
  Matches pets by family using explicit family: prefix or bare family name.
  Resolves partial family names (e.g., "dra" -> "Dragonkin").
  Multiple families use OR logic (match ANY).
  
  Examples:
    family:beast     -> Beast family pets
    family:dra       -> Dragonkin pets (partial match)
    beast            -> Beast family pets (bare name)
    !family:beast    -> NOT beast pets
  
  Dependencies: familyUtils, FilterType, FilterRegistry
]]

local ADDON_NAME, Addon = ...

-- Wait for dependencies
if not Addon.filterType or not Addon.filterRegistry then
    error("familyFilter: Dependencies not loaded")
end

local filterType = Addon.filterType

local familyFilter = filterType:new({
    id = "family",
    category = "family",
    patterns = {
        "^family[:=](.+)$",  -- Explicit: family:beast
        "^([a-z]+)$",        -- Bare: beast (resolver validates, returns nil for non-family)
    },
    priority = 10,
    logicType = "OR",
    supportsNegation = true,
    
    resolver = filterType.createFamilyResolver(),
    
    matcher = function(pet, familyId)
        -- Compare pet.petType (number) to resolved familyId (number)
        return pet.petType == familyId
    end,
})

-- Self-register
Addon.filterRegistry:register(familyFilter)

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterFamily", {"familyUtils", "filterType", "filterRegistry"}, function()
        return true
    end)
end

return familyFilter
