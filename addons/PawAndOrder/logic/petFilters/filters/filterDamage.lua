--[[
  logic/petFilters/filters/damageFilter.lua
  Damage Type Filter
  
  Matches pets with abilities of a specific damage type.
  Supports both "family:damage" and "damage:family" syntax.
  Multiple damage types use OR logic (match ANY).
  
  Examples:
    beast:damage  -> Pets with Beast damage abilities
    damage:flying -> Pets with Flying damage abilities
    !beast:damage -> Pets WITHOUT Beast damage abilities
  
  Dependencies: familyUtils, FilterType, FilterRegistry
]]

local ADDON_NAME, Addon = ...

-- Wait for dependencies
if not Addon.filterType or not Addon.filterRegistry then
    error("damageFilter: Dependencies not loaded")
end

local filterType = Addon.filterType

local damageFilter = filterType:new({
    id = "damage",
    category = "damage",
    patterns = {
        "^(.+)[:=]damage$",   -- family:damage
        "^damage[:=](.+)$",   -- damage:family
    },
    priority = 10,
    logicType = "OR",
    supportsNegation = true,
    
    resolver = filterType.createFamilyResolver(),
    
    matcher = function(pet, damageFamilyId)
        if not pet.abilities then return false end
        
        -- Get ability database
        local abilityDB = Addon.data and Addon.data.abilities
        if not abilityDB then return false end
        
        for _, ability in ipairs(pet.abilities) do
            if ability.abilityID then
                local abilityData = abilityDB[ability.abilityID]
                if abilityData and abilityData.familyType == damageFamilyId then
                    return true
                end
            end
        end
        
        return false
    end,
})

-- Self-register
Addon.filterRegistry:register(damageFilter)

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterDamage", {"familyUtils", "filterType", "filterRegistry"}, function()
        return true
    end)
end

return damageFilter
