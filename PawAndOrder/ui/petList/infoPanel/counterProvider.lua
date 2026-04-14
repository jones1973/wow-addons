--[[
  ui/infoPanel/counterProvider.lua
  Counter Filter Info Provider
  
  Provides contextual information for counter:family filters. Explains the double-counter
  mechanic: pets that deal bonus damage TO a family but also take bonus damage FROM that
  family's abilities.
  
  Display Formats:
  - Single counter: "Beast Counters: Deals +50% damage to Beast | Takes +50% damage from Beast abilities"
  - Multiple counters: "Invalid: Multiple counter filters active. Remove one to see valid results."
  
  Dependencies: utils, familyUtils, infoPanel
  Exports: Registered provider with infoPanel
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in counterProvider.lua.|r")
    return {}
end

local utils = Addon.utils
local uiUtils = Addon.uiUtils
local familyUtils = Addon.familyUtils
local infoPanel = Addon.infoPanel

local counterProvider = {}

--[[
  Evaluate if counter provider should show content
  
  @param filterText string - Current filter text
  @param filterCategories table - Parsed filter categories
  @return boolean - true if should show content
  @return table|nil - Content data for rendering
]]
local function evaluate(filterText, filterCategories)
    if not filterText then
        return false, nil
    end
    
    -- Count occurrences of "counter:" in raw filter text
    local counterCount = 0
    local loweredText = filterText:lower()
    local startPos = 1
    
    while true do
        local pos = loweredText:find("counter:", startPos, true)
        if not pos then break end
        counterCount = counterCount + 1
        startPos = pos + 1
    end
    
    if counterCount == 0 then
        return false, nil
    end
    
    -- Multiple "counter:" = invalid immediately (even if incomplete)
    if counterCount > 1 then
        return true, {
            type = "multiple"
        }
    end
    
    -- Single counter: validate the family name
    if filterCategories and filterCategories.counterTypes and #filterCategories.counterTypes == 1 then
        local partialFamily = filterCategories.counterTypes[1]
        
        -- Resolve partial family name to full name
        local fullFamily = familyUtils:resolveFamily(partialFamily)
        if not fullFamily then
            -- Invalid family name - don't show panel
            return false, nil
        end
        
        return true, {
            type = "single",
            family = fullFamily
        }
    end
    
    -- Has "counter:" but no valid parsed family yet - don't show anything
    return false, nil
end

--[[
  Render counter info content
  
  @param container frame - Content container frame
  @param contentData table - Data from evaluate function
  @param yOffset number - Y position to start rendering
  @return number - Height used by this content
]]
local function render(container, contentData, yOffset)
    if not contentData then return 0 end
    
    if contentData.type == "single" then
        return renderSingleCounter(container, contentData.family, yOffset)
    elseif contentData.type == "multiple" then
        return renderMultipleCounter(container, yOffset)
    end
    
    return 0
end

--[[
  Render single counter info
  Shows offensive and defensive mechanics for one counter filter
  
  @param container frame - Content container
  @param family string - Counter family name
  @param yOffset number - Y position
  @return number - Height used
]]
function renderSingleCounter(container, family, yOffset)
    if not familyUtils then
        utils:error("counterProvider: familyUtils not available")
        return 0
    end
    
    -- Capitalize family name
    local familyName = familyUtils:capitalize(family)
    

    -- Create text
    local text = uiUtils:createWrappedText(container, yOffset, true)
    
    local displayText = string.format(
        "%s Counters: Deals +50%% damage to %s | Takes +33%% damage from %s",
        familyName, familyName, familyName
    )
    
    text:SetText(displayText)
    text:SetTextColor(0.9, 0.9, 0.9)
    
    -- Calculate height used (text may wrap)
    local textHeight = text:GetStringHeight()
    local totalHeight = math.max(textHeight, infoPanel.LINE_HEIGHT)
    
    return totalHeight
end

--[[
  Render multiple counter warning
  Shows warning that multiple counter filters are invalid
  
  @param container frame - Content container
  @param yOffset number - Y position
  @return number - Height used
]]
function renderMultipleCounter(container, yOffset)

    -- Create warning text
    local text = uiUtils:createWrappedText(container, yOffset, true)
    
    text:SetText("Invalid: Multiple counter filters active. Remove one to see valid results.")
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
    if not infoPanel or not infoPanel.registerProvider then
        utils:error("counterProvider: infoPanel not available")
        return false
    end
    
    if not familyUtils then
        utils:error("counterProvider: familyUtils not available")
        return false
    end
    
    -- Register provider with info panel
    infoPanel:registerProvider({
        id = "counter",
        priority = 100,
        evaluate = evaluate,
        render = render
    })
    
    return true
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("counterProvider", {"utils", "familyUtils", "infoPanel"}, function()
        return initialize()
    end)
end

counterProvider.initialize = initialize
Addon.counterProvider = counterProvider
return counterProvider