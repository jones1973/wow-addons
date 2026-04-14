--[[
  ui/infoPanel/binaryConflictProvider.lua
  Info Panel Provider - Binary Conflict Detection
  
  Detects conflicting binary flags in filter text and displays warning.
  Handles: owned/!owned, unique/!unique, duplicate/!duplicate, tradable/!tradable, conditional/!conditional
  
  Dependencies: utils, infoPanel
  Exports: Registered with infoPanel
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in binaryConflictProvider.lua.|r")
    return
end

local utils = Addon.utils
local uiUtils = Addon.uiUtils
local infoPanel

-- Binary flags to check (owned removed - handled by headerBar dropdown)
local BINARY_FLAGS = {
    {positive = "unique", negative = "notUnique", display = "Unique"},
    {positive = "duplicate", negative = "notDuplicate", display = "Duplicate"},
    {positive = "tradable", negative = "notTradable", display = "Tradable"},
    {positive = "conditional", negative = "notConditional", display = "Conditional"}
}

--[[
  Evaluate filter for binary conflicts
  Checks if any binary flag is set to both true and its negation.
  
  @param filterText string - Raw filter text
  @param filterCategories table - Parsed categories from petFilters
  @return boolean - True if conflict detected
  @return table - Content data with conflict details
]]
local function evaluate(filterText, filterCategories)
    if not filterCategories then return false, nil end
    
    local conflicts = {}
    
    -- Check each binary flag for conflicts
    for _, flag in ipairs(BINARY_FLAGS) do
        local hasPositive = filterCategories[flag.positive] == true
        local hasNegative = filterCategories[flag.negative] == true
        
        if hasPositive and hasNegative then
            table.insert(conflicts, flag.display)
        end
    end
    
    if #conflicts == 0 then
        return false, nil
    end
    
    return true, {
        conflicts = conflicts
    }
end

--[[
  Render binary conflict warning
  Shows which binary flags are in conflict.
  
  @param container frame - Content container
  @param contentData table - Data from evaluate
  @param yOffset number - Y position
  @return number - Height used
]]
local function render(container, contentData, yOffset)
    if not contentData or not contentData.conflicts then return 0 end
    

    -- Create warning text
    local text = uiUtils:createWrappedText(container, yOffset, true)
    
    local conflictList = table.concat(contentData.conflicts, ", ")
    local displayText = string.format(
        "Invalid: Conflicting filters detected (%s). Remove one side of each conflict.",
        conflictList
    )
    
    text:SetText(displayText)
    text:SetTextColor(1.0, 0.6, 0.6) -- Light red for warning
    
    -- Calculate height used
    local textHeight = text:GetStringHeight()
    local totalHeight = math.max(textHeight, infoPanel.LINE_HEIGHT)
    
    return totalHeight
end

--[[
  Initialize and register provider
  Called during module initialization
]]
local function initialize()
    if not Addon.infoPanel then
        utils:error("binaryConflictProvider: infoPanel not available")
        return false
    end
    
    infoPanel = Addon.infoPanel
    
    infoPanel:registerProvider({
        id = "binaryConflict",
        priority = 100, -- High priority to show conflicts prominently
        evaluate = evaluate,
        render = render
    })
    
    return true
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("binaryConflictProvider", {"utils", "infoPanel"}, initialize)
end

return true