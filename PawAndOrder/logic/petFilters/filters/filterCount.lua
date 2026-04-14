--[[
  logic/petFilters/filters/filterCount.lua
  Count Filter (Owned Count)
  
  Matches pets by how many of that species are owned.
  Supports exact count, ranges, and operators.
  Multiple count filters use OR logic (match ANY).
  
  Examples:
    count:3      -> Species where you own exactly 3
    count:2-3    -> Species where you own 2 or 3
    count:>1     -> Species where you own more than 1
    count:>=3    -> Species where you own 3 or more
    !count:1     -> Species where you DON'T own exactly 1
  
  Dependencies: FilterType, FilterRegistry
]]

local ADDON_NAME, Addon = ...

-- Wait for dependencies
if not Addon.filterType or not Addon.filterRegistry then
    error("filterCount: Dependencies not loaded")
end

local filterType = Addon.filterType

local countFilter = filterType:new({
    id = "count",
    category = "count",
    patterns = {"^count[:=](.+)$"},
    priority = 10,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        -- Check for operator (>N, >=N, <N, <=N)
        local op, num = value:match("^([<>]=?)(%d+)$")
        if op and num then
            return {op = op, value = tonumber(num)}
        end
        
        -- Check for range (N-M)
        local minNum, maxNum = value:match("^(%d+)%-(%d+)$")
        if minNum and maxNum then
            return {min = tonumber(minNum), max = tonumber(maxNum)}
        end
        
        -- Check for exact number
        local exactNum = tonumber(value)
        if exactNum then
            return {min = exactNum, max = exactNum}
        end
        
        return nil
    end,
    
    matcher = function(pet, countFilter)
        if not pet.owned then return false end
        
        local numCollected = pet.speciesCount or 1
        
        if countFilter.op then
            -- Operator match
            local op, filterValue = countFilter.op, countFilter.value
            if op == ">" then
                return numCollected > filterValue
            elseif op == ">=" then
                return numCollected >= filterValue
            elseif op == "<" then
                return numCollected < filterValue
            elseif op == "<=" then
                return numCollected <= filterValue
            end
        elseif countFilter.min and countFilter.max then
            -- Range match
            return numCollected >= countFilter.min and numCollected <= countFilter.max
        end
        
        return false
    end,
})

-- Self-register
Addon.filterRegistry:register(countFilter)

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterCount", {"filterType", "filterRegistry"}, function()
        return true
    end)
end

return countFilter
