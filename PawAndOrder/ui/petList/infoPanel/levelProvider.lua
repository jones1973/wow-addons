--[[
  ui/infoPanel/levelProvider.lua
  Info Panel Provider - Level Filter Hints
  
  Two functions:
  1. Detects impossible level constraints (e.g., >20 <10) - shows error
  2. Detects multiple operators that could be a range - shows hint
  
  Dependencies: utils, uiUtils, infoPanel
  Exports: Registered with infoPanel
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in levelProvider.lua.|r")
    return
end

local utils = Addon.utils
local uiUtils = Addon.uiUtils
local infoPanel

--[[
  Analyze level operators for conflicts and suggestions
  
  @param operators table - Array of {type="op", op=string, level=number}
  @return boolean - hasConflict
  @return string|nil - suggestion (range syntax)
  @return number, number - calculated min/max
]]
local function analyzeLevelOperators(operators)
    if #operators < 2 then
        return false, nil, nil, nil
    end
    
    local minLevel, maxLevel = 1, 25
    
    for _, op in ipairs(operators) do
        if op.op == ">" then
            minLevel = math.max(minLevel, op.level + 1)
        elseif op.op == ">=" then
            minLevel = math.max(minLevel, op.level)
        elseif op.op == "<" then
            maxLevel = math.min(maxLevel, op.level - 1)
        elseif op.op == "<=" then
            maxLevel = math.min(maxLevel, op.level)
        end
    end
    
    local hasConflict = minLevel > maxLevel
    local suggestion = nil
    
    if not hasConflict and minLevel <= maxLevel then
        suggestion = string.format("%d-%d", minLevel, maxLevel)
    end
    
    return hasConflict, suggestion, minLevel, maxLevel
end

--[[
  Evaluate filter for level issues
  
  @param filterText string - Raw filter text
  @param filterCategories table - Parsed categories from compiled filter
  @return boolean - True if should show panel
  @return table - Content data
]]
local function evaluate(filterText, filterCategories)
    if not filterCategories or not filterCategories.level then
        return false, nil
    end
    
    local levelValues = filterCategories.level
    if type(levelValues) ~= "table" then
        return false, nil
    end
    
    -- Extract operator-type values
    local operators = {}
    for _, value in ipairs(levelValues) do
        if type(value) == "table" and value.type == "op" then
            table.insert(operators, value)
        end
    end
    
    -- Need at least 2 operators
    if #operators < 2 then
        return false, nil
    end
    
    local hasConflict, suggestion, minLevel, maxLevel = analyzeLevelOperators(operators)
    
    return true, {
        hasConflict = hasConflict,
        suggestion = suggestion,
        minLevel = minLevel,
        maxLevel = maxLevel,
        operatorCount = #operators,
    }
end

--[[
  Render level hint or error
  
  @param container frame - Content container
  @param contentData table - Data from evaluate
  @param yOffset number - Y position
  @return number - Height used
]]
local function render(container, contentData, yOffset)
    if not contentData then return 0 end
    
    local text = uiUtils:createWrappedText(container, yOffset, true)
    local message
    local r, g, b
    
    if contentData.hasConflict then
        -- Impossible constraints - error
        message = string.format(
            "Invalid: Level must be >= %d and <= %d (impossible range).",
            contentData.minLevel or 1,
            contentData.maxLevel or 25
        )
        r, g, b = 1.0, 0.6, 0.6  -- Light red
    else
        -- Valid but bad form - hint
        if contentData.suggestion then
            message = string.format(
                "Hint: Multiple operators use OR logic. For a range, use: %s",
                contentData.suggestion
            )
        else
            message = "Hint: Multiple level operators use OR logic. Use range syntax (e.g., 6-9) instead."
        end
        r, g, b = 0.9, 0.8, 0.5  -- Warm yellow
    end
    
    text:SetText(message)
    text:SetTextColor(r, g, b)
    
    local textHeight = text:GetStringHeight()
    local totalHeight = math.max(textHeight, infoPanel.LINE_HEIGHT)
    
    return totalHeight
end

--[[
  Initialize and register provider
]]
local function initialize()
    if not Addon.infoPanel then
        utils:error("levelProvider: infoPanel not available")
        return false
    end
    
    infoPanel = Addon.infoPanel
    
    infoPanel:registerProvider({
        id = "levelHint",
        priority = 95,  -- High priority
        evaluate = evaluate,
        render = render
    })
    
    return true
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("levelConflictProvider", {"utils", "uiUtils", "infoPanel"}, initialize)
end

return true