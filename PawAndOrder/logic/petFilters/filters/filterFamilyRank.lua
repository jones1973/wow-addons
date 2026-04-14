--[[
  logic/petFilters/filters/filterFamilyRank.lua
  Family Rank Filter
  
  Filters pets by whether their family is in the top or bottom N
  families by count in the player's collection.
  
  Tokens:
    family-bottom:3  → Pets from your 3 smallest families (by levelable count)
    family-top:3     → Pets from your 3 largest families
  
  Dependencies: filterType, filterRegistry, levelingLogic
  Exports: Registers with filterRegistry
]]

local ADDON_NAME, Addon = ...

local filterType = Addon.filterType
local filterRegistry = Addon.filterRegistry

if not filterType or not filterRegistry then
    error("filterFamilyRank: Dependencies not loaded")
end

-- Lazy-load levelingLogic (not available at filter load time)
local function getLevelingLogic()
    return Addon.levelingLogic
end

-- ============================================================================
-- FAMILY BOTTOM FILTER (by total count)
-- ============================================================================

local familyBottomFilter = filterType:new({
    id = "familyBottom",
    category = "familyBottom",
    patterns = {
        "^family%-bottom[:=](%d+)$",
    },
    priority = 15,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        local num = tonumber(captures[1])
        if num and num > 0 then
            return { n = num, byRare = false }
        end
        return nil
    end,
    
    matcher = function(pet, filterData)
        if not pet.owned or not pet.petType then return false end
        
        local levelingLogic = getLevelingLogic()
        if not levelingLogic then return false end
        
        local ranked = levelingLogic:getRankedFamilies(filterData.byRare)
        if not ranked or #ranked == 0 then return false end
        
        -- Check if pet's family is in bottom N (smallest counts first)
        for i = 1, math.min(filterData.n, #ranked) do
            if ranked[i].familyId == pet.petType then
                return true
            end
        end
        
        return false
    end,
})

filterRegistry:register(familyBottomFilter)

-- ============================================================================
-- FAMILY TOP FILTER (by total count)
-- ============================================================================

local familyTopFilter = filterType:new({
    id = "familyTop",
    category = "familyTop",
    patterns = {
        "^family%-top[:=](%d+)$",
    },
    priority = 15,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        local num = tonumber(captures[1])
        if num and num > 0 then
            return { n = num, byRare = false }
        end
        return nil
    end,
    
    matcher = function(pet, filterData)
        if not pet.owned or not pet.petType then return false end
        
        local levelingLogic = getLevelingLogic()
        if not levelingLogic then return false end
        
        local ranked = levelingLogic:getRankedFamilies(filterData.byRare)
        
        -- Check if pet's family is in top N (from end of sorted list)
        local startIdx = math.max(1, #ranked - filterData.n + 1)
        for i = startIdx, #ranked do
            if ranked[i].familyId == pet.petType then
                return true
            end
        end
        
        return false
    end,
})

filterRegistry:register(familyTopFilter)

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("filterFamilyRank", {"filterType", "filterRegistry"}, function()
        return true
    end)
end

return true