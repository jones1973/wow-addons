--[[
  logic/petFilters/filters/filterLevel.lua
  Level Filter (Consolidated)
  
  Matches pets by level: exact, range, or comparison.
  All level terms use OR logic within category.
  
  Supported forms:
    Exact:
      5           → Pets at level 5
      level:5     → Same
      level=5     → Same
    
    Range:
      1-10        → Pets with level 1 to 10 (inclusive)
      level:1-10  → Same
    
    Comparison:
      <10         → Pets with level < 10
      level:<10   → Same
      >=15        → Pets with level >= 15
      >5          → Pets with level > 5
      <=20        → Pets with level <= 20
    
    Negation:
      !25         → Pets NOT at level 25
      !1-10       → Pets NOT in range 1-10
      !<10        → Pets NOT below level 10
  
  Note: For ranges, use explicit range syntax (6-9) rather than
  combining operators (>5 <10). Combining terms uses OR logic.
  
  Dependencies: FilterType, FilterRegistry
]]

local ADDON_NAME, Addon = ...

-- Wait for dependencies
if not Addon.filterType or not Addon.filterRegistry then
    error("levelFilter: Dependencies not loaded")
end

local filterType = Addon.filterType

local levelFilter = filterType:new({
    id = "level",
    category = "level",
    patterns = {
        -- Range patterns (must come before exact to match first)
        "^level[:=](%d+)%-(%d+)$",    -- level:1-10
        "^(%d+)%-(%d+)$",              -- 1-10
        -- Operator patterns
        "^level[:=]([<>]=?)(%d+)$",   -- level:<10, level:>=15
        "^([<>]=?)(%d+)$",             -- <10, >=15
        -- Exact patterns (last - most general)
        "^level[:=](%d+)$",            -- level:5
        "^(%d+)$",                     -- 5
    },
    priority = 30,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        -- Determine type from captures
        if #captures == 2 then
            -- Either range (two numbers) or operator (op + number)
            local first, second = captures[1], captures[2]
            
            if first:match("^[<>]=?$") then
                -- Operator: <10, >=15, etc.
                local level = tonumber(second)
                if not level or level < 1 or level > 25 then
                    return nil
                end
                return {type = "op", op = first, level = level}
            else
                -- Range: 1-10
                local min, max = tonumber(first), tonumber(second)
                if not min or not max then return nil end
                if min < 1 or max > 25 then return nil end
                if min > max then return nil end
                return {type = "range", min = min, max = max}
            end
        elseif #captures == 1 then
            -- Exact level
            local level = tonumber(captures[1])
            if not level or level < 1 or level > 25 then
                return nil
            end
            return {type = "exact", level = level}
        end
        
        return nil
    end,
    
    matcher = function(pet, filterData)
        local petLevel = pet.level or 1
        
        if filterData.type == "exact" then
            return petLevel == filterData.level
            
        elseif filterData.type == "range" then
            return petLevel >= filterData.min and petLevel <= filterData.max
            
        elseif filterData.type == "op" then
            local op = filterData.op
            local target = filterData.level
            
            if op == ">" then
                return petLevel > target
            elseif op == ">=" then
                return petLevel >= target
            elseif op == "<" then
                return petLevel < target
            elseif op == "<=" then
                return petLevel <= target
            end
        end
        
        return false
    end,
})

-- Self-register
Addon.filterRegistry:register(levelFilter)

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterLevel", {"filterType", "filterRegistry"}, function()
        return true
    end)
end

return levelFilter