--[[
  logic/petFilters/filters/counterFilter.lua
  Counter Filter (Double-Counter)
  
  Matches pets that counter their own weakness.
  A pet is a double-counter if:
  1. Pet's family is weak against target family
  2. Pet has an ability strong against target family
  
  Multiple counter filters use OR logic (match ANY).
  
  Examples:
    counter:beast   -> Pets weak vs Beast but have abilities strong vs Beast
    !counter:beast  -> Pets that are NOT double-counters vs Beast
  
  Dependencies: familyUtils, FilterType, FilterRegistry
]]

local ADDON_NAME, Addon = ...

-- Wait for dependencies
if not Addon.filterType or not Addon.filterRegistry then
    error("counterFilter: Dependencies not loaded")
end

local filterType = Addon.filterType

local counterFilter = filterType:new({
    id = "counter",
    category = "counter",
    patterns = {"^counter[:=](.+)$"},
    priority = 10,
    logicType = "OR",
    supportsNegation = true,
    
    resolver = filterType.createFamilyResolver(),
    
    matcher = function(pet, targetFamilyId)
        if not pet.abilities or not pet.petType then return false end
        
        local familyUtils = filterType.getFamilyUtils()
        if not familyUtils then return false end
        
        -- Check if pet is weak against target family
        if not familyUtils:isWeakAgainst(pet.petType, targetFamilyId) then
            return false  -- Not weak, can't be a double-counter
        end
        
        -- Get ability database
        local abilityDB = Addon.data and Addon.data.abilities
        if not abilityDB then return false end
        
        -- Check if pet has ability strong vs target family
        for _, ability in ipairs(pet.abilities) do
            if ability.abilityID then
                local abilityData = abilityDB[ability.abilityID]
                if abilityData and abilityData.familyType then
                    if familyUtils:isStrongAgainst(abilityData.familyType, targetFamilyId) then
                        return true  -- Found counter ability
                    end
                end
            end
        end
        
        return false  -- No counter ability found
    end,
})

-- Self-register
Addon.filterRegistry:register(counterFilter)

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterCounter", {"familyUtils", "filterType", "filterRegistry"}, function()
        return true
    end)
end

return counterFilter
