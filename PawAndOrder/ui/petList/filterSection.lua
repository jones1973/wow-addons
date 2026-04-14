--[[
  ui/petList/filterSection.lua
  Filter Section Component
  
  Manages the filter input area including:
  - Filter text box (using shared searchBox component)
  - Filter help icon (?)
  - Filter chips display
  - Info panel coordination
  
  Emits events:
  - FILTER:TEXT_CHANGED - When filter text changes
  - FILTER:HEIGHT_CHANGED - When chips/panel change total height
  
  Dependencies: utils, constants, events, searchBox, filterChips, filterHelp, infoPanel
  Exports: Addon.filterSection
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in filterSection.lua.|r")
    return {}
end

local utils = Addon.utils
local constants, events, petFilters
local searchBox, filterChips, filterHelp, infoPanel

local filterSection = {}

-- UI elements
local sectionFrame = nil
local filterBox = nil
local lastFilterText = ""
local chipsHeight = 0
local panelHeight = 0

-- Layout constants
local FILTER_HEIGHT = 26
local FILTER_LEFT_MARGIN = 6

--[[
  Get total height of filter section including chips and panel
  
  @return number - Total height in pixels
]]
function filterSection:getHeight()
    return FILTER_HEIGHT + chipsHeight + panelHeight
end

--[[
  Get current filter text
  
  @return string - Current filter text
]]
function filterSection:getFilterText()
    return lastFilterText or ""
end

--[[
  Set filter text programmatically
  Updates filter box which triggers OnTextChanged for refresh and chips render.
  
  @param text string - New filter text
]]
function filterSection:setFilterText(text)
    lastFilterText = text or ""
    if filterBox then
        if filterBox.SetSearchText then
            filterBox:SetSearchText(lastFilterText)
        elseif filterBox.SetText then
            filterBox:SetText(lastFilterText)
        end
        filterBox:ClearFocus()
    end
    -- Note: SetText triggers OnTextChanged which handles refresh + chips
end

--[[
  Handle chips height change
  Called by filterChips when chip rows change.
  
  @param height number - New chips height
]]
function filterSection:setChipsHeight(height)
    chipsHeight = height or 0
    
    -- Update info panel position
    if infoPanel then
        infoPanel:setChipsHeight(chipsHeight)
    end
    
    -- Fire height changed event
    if events then
        events:emit("FILTER:HEIGHT_CHANGED", {
            totalHeight = self:getHeight(),
            chipsHeight = chipsHeight,
            panelHeight = panelHeight
        })
    end
end

--[[
  Handle filter text change
  Called by searchBox onTextChanged callback.
  
  @param filterText string - New filter text
]]
local function onFilterTextChanged(filterText)
    lastFilterText = filterText
    
    -- Render filter chips
    if filterChips then
        filterChips:render(filterText)
    end
    
    -- Fire filter changed event with compiled filter
    if events and petFilters and petFilters.parse then
        local compiled = petFilters:parse(filterText)
        
        events:emit("FILTER:TEXT_CHANGED", {
            filterText = filterText,
            compiled = compiled
        })
    end
end

--[[
  Create filter section UI
  Builds filter box using shared searchBox, help icon, and initializes chips/panel.
  
  @param parent frame - Parent frame to attach to
  @param width number - Width of filter section
]]
function filterSection:createFrame(parent, width)
    local L = constants.LAYOUT
    local filterWidth = width - FILTER_LEFT_MARGIN
    
    -- Container frame
    sectionFrame = CreateFrame("Frame", nil, parent)
    sectionFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -L.INNER_PADDING)
    sectionFrame:SetSize(width, FILTER_HEIGHT)
    
    -- Create filter box using shared searchBox component
    filterBox = searchBox:create({
        parent = sectionFrame,
        name = "PAOFilterBox",
        width = filterWidth,
        height = FILTER_HEIGHT,
        placeholder = "",  -- Pet filter doesn't use placeholder
        showClearButton = true,
        enableWordSelection = true,
        maxLetters = 200,
        onTextChanged = onFilterTextChanged,
        onClear = function()
            filterSection:setFilterText("")
        end,
    })
    filterBox:SetPoint("TOPLEFT", sectionFrame, "TOPLEFT", FILTER_LEFT_MARGIN, 0)
    
    -- Customize clear button tooltip
    if filterBox.clearButton and Addon.tooltip then
        filterBox.clearButton:SetScript("OnEnter", function(self)
            Addon.tooltip:showSimple(self, "Clear all filters")
        end)
        filterBox.clearButton:SetScript("OnLeave", function()
            Addon.tooltip:hide()
        end)
    end
    
    -- Create help icon (?) next to clear button
    if filterHelp then
        local helpIcon = filterHelp:createHelpIcon(filterBox)
        helpIcon:SetSize(22, 22)
    end
    
    -- Initialize filter chips component
    if filterChips then
        filterChips:initialize(parent, filterBox, filterWidth, function(newFilterText)
            filterSection:setFilterText(newFilterText)
        end)
    end
    
    -- Initialize info panel component
    if infoPanel then
        infoPanel:initialize(parent, filterBox, filterWidth)
        infoPanel:setChipsHeight(0)
    end
end

--[[
  Get the filter box frame
  Used by external code that needs to reference the filter box position.
  
  @return frame - Filter box EditBox frame
]]
function filterSection:getFilterBox()
    return filterBox
end

--[[
  Initialize filter section
  Loads dependencies and creates UI.
  
  @param parent frame - Parent frame
  @param width number - Section width
]]
function filterSection:initialize(parent, width)
    if sectionFrame then return end
    
    constants = Addon.constants
    events = Addon.events
    petFilters = Addon.petFilters
    searchBox = Addon.searchBox
    
    -- Optional modules
    filterChips = Addon.filterChips
    filterHelp = Addon.filterHelp
    infoPanel = Addon.infoPanel
    
    if not constants then
        utils:error("filterSection: constants not available")
        return
    end
    
    if not searchBox then
        utils:error("filterSection: searchBox component not available")
        return
    end
    
    self:createFrame(parent, width)
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("filterSection", {"utils", "constants", "events", "searchBox"}, function()
        return true
    end)
end

Addon.filterSection = filterSection
return filterSection