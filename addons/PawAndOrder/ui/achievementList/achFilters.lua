--[[
  ui/achievementList/achFilters.lua
  Achievement Header Bar Component
  
  Provides the header bar for the achievement list matching pet tab style:
    - Filter dropdown (multi-select checkboxes: Completed, Incomplete, Special submenu)
    - Search box (searches title, description, reward text)
    - Trophy icon + completion count (right-justified)
  
  Uses shared components: ui/shared/dropdown, ui/shared/searchBox
  
  Dependencies: achievementData, achievementLogic, searchBox, dropdown
  Exports: Addon.achFilters (internal module)
]]

local ADDON_NAME, Addon = ...

local achFilters = {}

-- Module references
local achievementData, achievementLogic, searchBox, dropdown

-- UI elements
local headerFrame = nil
local filterDropdown = nil
local searchInput = nil
local trophyIcon = nil
local countText = nil

-- Layout constants
local HEADER_HEIGHT = 30
local DROPDOWN_WIDTH = 130
local SEARCH_WIDTH = 160
local SPACING = 8
local ICON_SIZE = 28

-- Current filter state (table of active filter values for checkbox mode)
local currentFilters = {"completed", "incomplete"}

-- Status filter values
local STATUS_VALUES = {
    completed = true,
    incomplete = true,
}

-- Specialty filter values (for detection)
local SPECIALTY_VALUES = {
    rewards_pet = true,
    rewards_title = true,
    has_reward = true,
    unlocks_quest = true,
}

-- Filter options - flat list for checkbox multi-select with Special submenu
local FILTER_OPTIONS = {
    { value = "completed", text = "Completed" },
    { value = "incomplete", text = "Incomplete" },
    { value = "special", text = "Special", submenu = {
        style = "checkbox",
        { value = "rewards_pet", text = "Rewards Pet" },
        { value = "rewards_title", text = "Rewards Title" },
        { value = "unlocks_quest", text = "Unlocks Quest" },
        { isSeparator = true },
        { value = "has_reward", text = "Has Any Reward" },
    }},
}

-- ============================================================================
-- FILTER APPLICATION
-- ============================================================================

local function applyFilters(selectedValues)
    if not achievementLogic then return end
    
    -- Clear all filters first (but preserve search text)
    local searchText = achievementLogic.getSearchText and achievementLogic:getSearchText() or ""
    achievementLogic:clearFilters()
    if searchText ~= "" then
        achievementLogic:setSearchText(searchText)
    end
    
    -- Apply each selected filter
    currentFilters = selectedValues or {}
    
    for _, value in ipairs(currentFilters) do
        if STATUS_VALUES[value] then
            achievementLogic:setStatusFilter(value, true)
        elseif SPECIALTY_VALUES[value] then
            achievementLogic:setSpecialtyFilter(value, true)
        end
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Create the header bar.
  @param parent frame
  @return frame
]]
function achFilters:createBar(parent)
    if headerFrame then return headerFrame end
    
    local PADDING = 8
    
    headerFrame = CreateFrame("Frame", nil, parent)
    headerFrame:SetHeight(HEADER_HEIGHT)
    headerFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, -PADDING)
    headerFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING, -PADDING)
    
    -- Filter dropdown (left) - multi-select with checkboxes
    filterDropdown = dropdown:create({
        parent = headerFrame,
        name = "PAOAchFilterDropdown",
        width = DROPDOWN_WIDTH,
        style = "checkbox",
        options = FILTER_OPTIONS,
        defaultValue = currentFilters,
        placeholder = "Filter",
        tooltip = "Filter Achievements\nSelect multiple filters to combine them",
        onChange = function(values)
            applyFilters(values)
        end,
    })
    filterDropdown:SetPoint("LEFT", headerFrame, "LEFT", 0, 0)
    
    -- Search box (center-left, after dropdown)
    searchInput = searchBox:create({
        parent = headerFrame,
        name = ADDON_NAME .. "AchSearchBox",
        width = SEARCH_WIDTH,
        placeholder = "Search...",
        showClearButton = true,
        onTextChanged = function(text)
            if achievementLogic then
                achievementLogic:setSearchText(text)
            end
        end,
        onClear = function()
            if achievementLogic then
                achievementLogic:setSearchText("")
            end
        end,
    })
    searchInput:SetPoint("LEFT", filterDropdown, "RIGHT", SPACING, 0)
    
    -- Count text (right-justified)
    countText = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countText:SetPoint("RIGHT", headerFrame, "RIGHT", 0, 0)
    countText:SetTextColor(1, 1, 1)
    countText:SetText("0 / 0")
    
    -- Trophy icon (left of count)
    trophyIcon = headerFrame:CreateTexture(nil, "ARTWORK")
    trophyIcon:SetSize(ICON_SIZE, ICON_SIZE)
    trophyIcon:SetPoint("RIGHT", countText, "LEFT", -4, 0)
    trophyIcon:SetTexture(235410)  -- Achievement shield
    trophyIcon:SetTexCoord(0, 0.5, 0, 0.5)  -- Gold shield quadrant
    
    return headerFrame
end

--[[
  Update the count display.
  @param completed number
  @param total number
]]
function achFilters:updateTotalCount(completed, total)
    if countText then
        countText:SetText(string.format("%d / %d", completed or 0, total or 0))
    end
end

--[[
  Get current filter values.
  @return table - Array of active filter values
]]
function achFilters:getCurrentFilters()
    local copy = {}
    for i, v in ipairs(currentFilters) do
        copy[i] = v
    end
    return copy
end

--[[
  Set filters programmatically.
  @param filterValues table - Array of filter values to activate
]]
function achFilters:setFilters(filterValues)
    applyFilters(filterValues)
    if filterDropdown then
        filterDropdown:SetValue(filterValues, true)
    end
end

--[[
  Clear all filters.
]]
function achFilters:clearFilters()
    applyFilters({})
    if filterDropdown then
        filterDropdown:SetValue({}, true)
    end
end

--[[
  Get search text.
  @return string
]]
function achFilters:getSearchText()
    if searchInput then
        return searchInput:GetSearchText()
    end
    return ""
end

--[[
  Set search text.
  @param text string
]]
function achFilters:setSearchText(text)
    if searchInput then
        searchInput:SetSearchText(text)
    end
end

--[[
  Clear all filters to defaults.
]]
function achFilters:clearAll()
    currentFilter = "all"
    if searchInput then
        searchInput:Clear()
    end
    if filterDropdown then
        filterDropdown:SetValue("all", true)
    end
    if achievementLogic then
        achievementLogic:clearFilters()
    end
end

--[[
  Get filter bar height.
  @return number
]]
function achFilters:getBarHeight()
    return HEADER_HEIGHT
end

--[[
  Get filter bar frame.
  @return frame
]]
function achFilters:getBar()
    return headerFrame
end

--[[
  Initialize the module with dependencies.
  @param deps table
]]
function achFilters:initialize(deps)
    achievementData = deps.achievementData
    achievementLogic = deps.achievementLogic
    searchBox = deps.searchBox or Addon.searchBox
    dropdown = deps.dropdown or Addon.dropdown
    
    -- Apply default filters (both completed and incomplete)
    if achievementLogic then
        for _, value in ipairs(currentFilters) do
            if STATUS_VALUES[value] then
                achievementLogic:setStatusFilter(value, true)
            end
        end
    end
end

-- Self-register
if Addon.registerModule then
    Addon.registerModule("_achFilters", {"searchBox", "dropdown"}, function()
        return true
    end)
end

Addon.achFilters = achFilters
return achFilters