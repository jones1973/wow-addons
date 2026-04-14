--[[
  logic/petFilters/filters/binaryFilters.lua
  Binary Flag Filters
  
  Matches pets by boolean flags: owned, unowned, unique, duplicate, tradable, conditional, upgradeable
  Each is a simple true/false check.
  
  Examples:
    owned        -> Only owned pets
    unowned      -> Only unowned pets
    !owned       -> Only unowned pets (same as unowned)
    unique       -> Only unique pets
    duplicate    -> Only duplicate pets (duplicateCount > 1)
    dupl         -> Same as duplicate
    tradable     -> Only tradable pets
    trad         -> Same as tradable
    cageable     -> Same as tradable
    conditional  -> Only conditional spawn pets
    cond         -> Same as conditional
    upgradeable  -> Pets upgradeable with family-specific battle stones in bags
  
  Dependencies: FilterType, FilterRegistry
]]

local ADDON_NAME, Addon = ...

-- Wait for dependencies
if not Addon.filterType or not Addon.filterRegistry then
    error("binaryFilters: Dependencies not loaded")
end

local filterType = Addon.filterType

-- Owned filter
local ownedFilter = filterType:new({
    id = "owned",
    category = "owned",
    patterns = {"^(owned)$"},
    priority = 20,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        return true
    end,
    
    matcher = function(pet, value)
        return pet.owned == true
    end,
})
Addon.filterRegistry:register(ownedFilter)

-- Unowned filter (inverse of owned)
local unownedFilter = filterType:new({
    id = "unowned",
    category = "unowned",
    patterns = {"^(unowned)$"},
    priority = 20,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        return true
    end,
    
    matcher = function(pet, value)
        return not pet.owned
    end,
})
Addon.filterRegistry:register(unownedFilter)

-- Unique filter
local uniqueFilter = filterType:new({
    id = "unique",
    category = "unique",
    patterns = {"^(unique)$"},
    priority = 20,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        return true
    end,
    
    matcher = function(pet, value)
        return pet.unique == true
    end,
})
Addon.filterRegistry:register(uniqueFilter)

-- Tradable filter with abbreviations
local tradableFilter = filterType:new({
    id = "tradable",
    category = "tradable",
    patterns = {"^(tradable)$", "^(trad)$", "^(cageable)$", "^(cage)$"},
    priority = 20,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        return true
    end,
    
    matcher = function(pet, value)
        return pet.tradable == true
    end,
})
Addon.filterRegistry:register(tradableFilter)

-- Duplicate filter with abbreviation
local duplicateFilter = filterType:new({
    id = "duplicate",
    category = "duplicate",
    patterns = {"^(duplicate)$", "^(dupl)$"},
    priority = 20,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        return true
    end,
    
    matcher = function(pet, value)
        return pet.duplicateCount and pet.duplicateCount > 1
    end,
})
Addon.filterRegistry:register(duplicateFilter)

-- Conditional filter with abbreviation
-- Matches pets with conditional spawn requirements (weather, time, season, faction, event)
local conditionalFilter = filterType:new({
    id = "conditional",
    category = "conditional",
    patterns = {"^(conditional)$", "^(cond)$"},
    priority = 20,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        return true
    end,
    
    matcher = function(pet, value)
        if not pet.sourceText then return false end
        
        local source = pet.sourceText:lower()
        
        -- Check for conditional spawn indicators (with |n newline prefix)
        if source:find("|nweather:", 1, true) then return true end
        if source:find("|ntime:", 1, true) then return true end
        if source:find("|nseason:", 1, true) then return true end
        if source:find("|nfaction:", 1, true) then return true end
        if source:find("|nevent:", 1, true) then return true end
        
        -- Also check without |n prefix in case format varies
        if source:find("weather:", 1, true) then return true end
        if source:find("time:", 1, true) then return true end
        if source:find("season:", 1, true) then return true end
        if source:find("faction:", 1, true) then return true end
        if source:find("event:", 1, true) then return true end
        
        return false
    end,
})
Addon.filterRegistry:register(conditionalFilter)

-- Upgradeable filter (special logic)
-- Matches pets that can be upgraded with a family-specific battle stone in bags
local upgradeableFilter = filterType:new({
    id = "upgradeable",
    category = "upgradeable",
    patterns = {"^(upgrade?able)$", "^(upgrade)$", "^(battle%-?stone)$"},
    priority = 20,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        return true
    end,
    
    matcher = function(pet, value)
        -- Must be owned, not caged, and below Rare quality (4=Rare in 1-based system)
        if not pet.owned or pet.isCaged or not pet.rarity or pet.rarity >= 4 then
            return false
        end
        
        -- Check if we have a battle stone for this pet
        local petUtils = Addon.petUtils
        if not petUtils or not petUtils.scanBattleStones then
            return false
        end
        
        local stones = petUtils:scanBattleStones(pet.petType, pet.rarity)
        if not stones or #stones == 0 then
            return false
        end
        
        -- Filter to only family-specific stones (not universal)
        local constants = Addon.constants
        if not constants or not constants.UNIVERSAL_STONE_IDS then
            return false
        end
        
        for _, stone in ipairs(stones) do
            if not constants.UNIVERSAL_STONE_IDS[stone.itemID] then
                return true  -- Has at least one family-specific stone
            end
        end
        
        return false  -- Only universal stones (excluded by design)
    end,
})
Addon.filterRegistry:register(upgradeableFilter)

-- Wild filter
-- Matches wild pets (pets captured in pet battles)
local wildFilter = filterType:new({
    id = "wild",
    category = "wild",
    patterns = {"^(wild)$"},
    priority = 20,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        return true
    end,
    
    matcher = function(pet, value)
        return pet.isWild == true
    end,
})
Addon.filterRegistry:register(wildFilter)

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterBinary", {"filterType", "filterRegistry"}, function()
        return true
    end)
end

return true