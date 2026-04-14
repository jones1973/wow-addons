--[[
  logic/petFilters/filters/rarityFilter.lua
  Rarity Filter
  
  Matches pets by rarity using keywords: poor, common, uncommon, rare
  Multiple rarities use OR logic (match ANY).
  
  Examples:
    rare          → Rare pets
    uncommon rare → Uncommon OR rare pets
    !rare         → NOT rare pets
  
  Dependencies: constants, filterType, FilterRegistry
]]

local ADDON_NAME, Addon = ...

-- Wait for dependencies
if not Addon.filterType or not Addon.filterRegistry then
    error("rarityFilter: Dependencies not loaded")
end

local filterType = Addon.filterType

-- Lazy-load constants
local function getConstants()
    return Addon.constants
end

local rarityFilter = filterType:new({
    id = "rarity",
    category = "rarity",
    patterns = {"^(.+)$"},  -- Match anything, check in parser
    priority = 60,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        local constants = getConstants()
        if not constants or not constants.RARITY_KEYWORDS then
            return nil
        end
        
        -- Direct lookup in RARITY_KEYWORDS
        local rarityValue = constants.RARITY_KEYWORDS[term:lower()]
        
        -- Return nil if not a rarity keyword (let other filters handle it)
        return rarityValue
    end,
    
    matcher = function(pet, rarityValue)
        return pet.owned and pet.rarity == rarityValue
    end,
})

-- Self-register
Addon.filterRegistry:register(rarityFilter)

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterRarity", {"constants", "filterType", "filterRegistry"}, function()
        return true
    end)
end

return rarityFilter
