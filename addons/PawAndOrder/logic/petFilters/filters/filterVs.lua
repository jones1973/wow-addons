--[[
  logic/petFilters/filters/vsFilter.lua
  VS Filter (Strong Against)
  
  Matches pets with abilities that are strong against a target family.
  Multiple vs filters use OR logic (match ANY).
  
  Examples:
    vs:beast     -> Pets with abilities strong vs Beast
    vs:critter   -> Pets with abilities strong vs Critter
    !vs:beast    -> Pets WITHOUT abilities strong vs Beast
  
  Dependencies: familyUtils, FilterType, FilterRegistry
]]

local ADDON_NAME, Addon = ...

-- Wait for dependencies
if not Addon.filterType or not Addon.filterRegistry then
    error("vsFilter: Dependencies not loaded")
end

local filterType = Addon.filterType

local vsFilter = filterType:new({
    id = "vs",
    category = "vs",
    patterns = {"^vs[:=](.+)$"},
    priority = 10,
    logicType = "OR",
    supportsNegation = true,
    
    resolver = filterType.createFamilyResolver(),
    
    matcher = function(pet, targetFamilyId)
        if not pet.abilities then 
            return false 
        end
        
        local familyUtils = filterType.getFamilyUtils()
        if not familyUtils then 
            return false 
        end
        
        -- Get ability database
        local abilityDB = Addon.data and Addon.data.abilities
        if not abilityDB then
            return false
        end
        
        -- Check each ability
        for _, ability in ipairs(pet.abilities) do
            if ability.abilityID then
                local abilityData = abilityDB[ability.abilityID]
                
                if abilityData and abilityData.familyType then
                    if familyUtils:isStrongAgainst(abilityData.familyType, targetFamilyId) then
                        return true
                    end
                end
            end
        end
        
        return false
    end,
})

-- Self-register
Addon.filterRegistry:register(vsFilter)

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterVs", {"familyUtils", "filterType", "filterRegistry"}, function()
        return true
    end)
end

return vsFilter
