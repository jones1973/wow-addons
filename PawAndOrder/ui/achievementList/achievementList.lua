--[[
  ui/achievementList/achievementList.lua
  Achievement List UI Coordinator
  
  Coordinates the achievement tab content:
    - achFilters: Multi-select filter bar
    - achRow: Expandable achievement rows
    - achHeader: Section headers
    - Recent achievements section
    - Scroll frame and list rendering
  
  Events Subscribed:
    - ACHIEVEMENTS:DATA_REFRESHED
    - ACHIEVEMENTS:FILTER_CHANGED
  
  Dependencies: achievementLogic, achievementData, events, utils
  Sub-modules: achRow, achHeader, achFilters
  Exports: Addon.achievementList
]]

local ADDON_NAME, Addon = ...

local achievementList = {}

-- ============================================================================
-- STATE
-- ============================================================================

local listFrame = nil
local scrollFrame = nil
local scrollChild = nil
local recentSection = nil
local initialized = false

-- Row pools
local headerPool = {}
local rowPool = {}
local activeHeaders = {}
local activeRows = {}

-- Module references
local achievementLogic, achievementData, events, utils

-- Sub-modules
local achRow, achHeader, achFilters

-- Layout
local ROW_SPACING = 2
local PADDING = 8
local RECENT_HEADER_HEIGHT = 24

-- ============================================================================
-- RECENT ACHIEVEMENTS SECTION
-- ============================================================================

local function createRecentSection(parent)
    local section = CreateFrame("Frame", nil, parent)
    section:SetHeight(RECENT_HEADER_HEIGHT)
    
    -- Header
    local header = CreateFrame("Button", nil, section)
    header:SetHeight(RECENT_HEADER_HEIGHT)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    
    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(0.2, 0.15, 0.1, 0.9)
    
    local headerHighlight = header:CreateTexture(nil, "HIGHLIGHT")
    headerHighlight:SetAllPoints()
    headerHighlight:SetColorTexture(1, 1, 1, 0.05)
    
    -- Arrow
    local arrow = header:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(14, 14)
    arrow:SetPoint("LEFT", 8, 0)
    arrow:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
    section.arrow = arrow
    
    -- Title
    local title = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("LEFT", arrow, "RIGHT", 4, 0)
    title:SetText("Recent Achievements")
    title:SetTextColor(1, 0.8, 0.4)
    section.title = title
    
    -- Count
    local count = header:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    count:SetPoint("RIGHT", header, "RIGHT", -8, 0)
    count:SetTextColor(0.7, 0.7, 0.7)
    section.countText = count
    
    -- Content container
    local content = CreateFrame("Frame", nil, section)
    content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    content:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -2)
    content:SetHeight(1)
    section.content = content
    
    -- State
    section.isCollapsed = false
    section.contentHeight = 0
    section.recentRows = {}
    
    -- Toggle
    header:SetScript("OnClick", function()
        section.isCollapsed = not section.isCollapsed
        if section.isCollapsed then
            arrow:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
            content:Hide()
        else
            arrow:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
            content:Show()
        end
        achievementList:refresh()
    end)
    
    return section
end

local function populateRecentSection()
    if not recentSection then return 0 end
    
    local recent = achievementLogic:getRecentAchievements()
    
    if #recent == 0 then
        recentSection:Hide()
        return 0
    end
    
    recentSection:Show()
    recentSection.countText:SetText(#recent .. " this week")
    
    if recentSection.isCollapsed then
        recentSection:SetHeight(RECENT_HEADER_HEIGHT)
        return RECENT_HEADER_HEIGHT + ROW_SPACING
    end
    
    -- Hide existing rows
    for _, row in ipairs(recentSection.recentRows) do
        row:Hide()
    end
    
    local yOffset = 0
    local rowHeight = achRow:getRowHeight()
    
    for i, ach in ipairs(recent) do
        local row = recentSection.recentRows[i]
        if not row then
            row = achRow:createRow(recentSection.content)
            recentSection.recentRows[i] = row
        end
        
        row:SetPoint("TOPLEFT", recentSection.content, "TOPLEFT", 0, -yOffset)
        row:SetPoint("TOPRIGHT", recentSection.content, "TOPRIGHT", 0, -yOffset)
        row:SetAchievement(ach)
        row:Show()
        
        yOffset = yOffset + row:GetTotalHeight() + ROW_SPACING
    end
    
    recentSection.content:SetHeight(math.max(yOffset, 1))
    recentSection.contentHeight = yOffset
    recentSection.content:Show()
    
    local totalHeight = RECENT_HEADER_HEIGHT + 2 + yOffset
    recentSection:SetHeight(totalHeight)
    
    return totalHeight + PADDING
end

-- ============================================================================
-- OBJECT POOLS
-- ============================================================================

local function acquireRow()
    local row = table.remove(rowPool)
    if not row then
        row = achRow:createRow(scrollChild)
    end
    -- Reset state (SetAchievement will handle expansion state based on tracked ID)
    row.isExpanded = false
    row.expansionHeight = 0
    if row.expansion then
        row.expansion:Hide()
    end
    if row.petNameDisplay then
        row.petNameDisplay:Hide()
    end
    row:Show()
    table.insert(activeRows, row)
    return row
end

local function acquireHeader()
    local header = table.remove(headerPool)
    if not header then
        header = achHeader:createHeader(scrollChild)
    end
    header:Show()
    table.insert(activeHeaders, header)
    return header
end

local function releaseAllRows()
    for _, row in ipairs(activeRows) do
        row:Hide()
        row:ClearAllPoints()
        -- Reset visual state without triggering Collapse() which clears tracked ID
        row.isExpanded = false
        row.expansionHeight = 0
        if row.expansion then
            row.expansion:Hide()
        end
        if row.petNameDisplay then
            row.petNameDisplay:Hide()
        end
        row.achievement = nil
        table.insert(rowPool, row)
    end
    wipe(activeRows)
end

local function releaseAllHeaders()
    for _, header in ipairs(activeHeaders) do
        header:Hide()
        header:ClearAllPoints()
        table.insert(headerPool, header)
    end
    wipe(activeHeaders)
end

--[[
  Ensure an element (row or header) remains visible in the scroll frame.
  Call this after populateList() with a slight delay to let layout settle.
  @param element Frame - the frame to keep visible
]]
local function ensureElementVisible(element)
    if not element or not scrollFrame then return end
    
    local scrollHeight = scrollFrame:GetHeight()
    local currentScroll = scrollFrame:GetVerticalScroll()
    local maxScroll = math.max(0, scrollChild:GetHeight() - scrollHeight)
    
    -- Get element position relative to scroll child
    local elementTop = -element:GetTop() + scrollChild:GetTop()
    local elementBottom = elementTop + element:GetHeight()
    
    -- Check if element is fully visible
    local viewTop = currentScroll
    local viewBottom = currentScroll + scrollHeight
    
    if elementTop < viewTop then
        -- Element is above viewport - scroll up to show it
        scrollFrame:SetVerticalScroll(math.max(0, elementTop - 8))
    elseif elementBottom > viewBottom then
        -- Element is below viewport - scroll down to show it
        -- But try to keep the top of the element visible
        local targetScroll = elementTop - 8
        scrollFrame:SetVerticalScroll(math.min(maxScroll, targetScroll))
    end
    -- else: element is already fully visible, do nothing
end

-- ============================================================================
-- LIST RENDERING
-- ============================================================================

local function populateList()
    if not scrollChild then return end
    
    -- Release existing elements
    releaseAllRows()
    releaseAllHeaders()
    
    -- Start with recent section
    local yOffset = populateRecentSection()
    
    -- Get filtered data
    local groups = achievementLogic:getFilteredAchievements()
    
    local rowHeight = achRow:getRowHeight()
    local headerHeight = achHeader:getHeaderHeight()
    
    for _, group in ipairs(groups) do
        -- Section header
        local header = acquireHeader()
        header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
        header:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOffset)
        achHeader:setData(header, group.name, group.completed, group.total, group.id)
        
        yOffset = yOffset + headerHeight + ROW_SPACING
        
        -- Achievement rows (only if section is expanded)
        if not achHeader:isCollapsed(group.name) then
            for _, achievement in ipairs(group.achievements) do
                local row = acquireRow()
                row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
                row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOffset)
                row:SetAchievement(achievement)
                
                yOffset = yOffset + row:GetTotalHeight() + ROW_SPACING
            end
            
            yOffset = yOffset + PADDING
        else
            yOffset = yOffset + 2
        end
    end
    
    scrollChild:SetHeight(math.max(yOffset, 1))
end

local function scrollToAchievement(achievementId)
    if not scrollFrame or not achievementId then return end
    
    -- First, find which group/category this achievement is in
    local groups = achievementLogic:getFilteredAchievements()
    local targetGroup = nil
    local targetAchievement = nil
    
    for _, group in ipairs(groups) do
        for _, ach in ipairs(group.achievements) do
            if ach.id == achievementId then
                targetGroup = group
                targetAchievement = ach
                break
            end
        end
        if targetAchievement then break end
    end
    
    if not targetAchievement then
        -- Achievement not in filtered list - might be in a different category
        -- Try to find it in all achievements
        local allGroups = achievementLogic:getGroupedAchievements()
        for _, group in ipairs(allGroups) do
            for _, ach in ipairs(group.achievements) do
                if ach.id == achievementId then
                    targetGroup = group
                    targetAchievement = ach
                    break
                end
            end
            if targetAchievement then break end
        end
    end
    
    if not targetGroup or not targetAchievement then
        return  -- Achievement not found
    end
    
    -- Expand the category if collapsed
    if achHeader:isCollapsed(targetGroup.name) then
        achHeader:toggleCollapsed(targetGroup.name)
    end
    
    -- Repopulate to ensure the achievement row exists
    populateList()
    
    -- Find the header and row for this achievement and scroll to show both
    C_Timer.After(0.05, function()
        local headerRow = nil
        local targetRow = nil
        
        -- Find the header for this group
        for _, header in ipairs(activeHeaders) do
            if header.groupName == targetGroup.name then
                headerRow = header
                break
            end
        end
        
        -- Find the target achievement row
        for _, row in ipairs(activeRows) do
            if row.achievement and row.achievement.id == achievementId then
                targetRow = row
                break
            end
        end
        
        if targetRow then
            local scrollHeight = scrollFrame:GetHeight()
            local maxScroll = scrollChild:GetHeight() - scrollHeight
            local targetScroll
            
            if headerRow then
                -- Scroll to show header at top
                local headerTop = -headerRow:GetTop() + scrollChild:GetTop()
                targetScroll = math.max(0, math.min(headerTop - 8, maxScroll))
            else
                -- No header found, scroll to row
                local rowTop = -targetRow:GetTop() + scrollChild:GetTop()
                targetScroll = math.max(0, math.min(rowTop - 50, maxScroll))
            end
            
            scrollFrame:SetVerticalScroll(targetScroll)
            
            -- Expand the achievement
            targetRow:Expand()
        end
    end)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function achievementList:show()
    if listFrame and listFrame:IsVisible() then
        populateList()
    end
end

function achievementList:hide()
    -- Wrapper frame handles visibility
end

function achievementList:createFrame(parent)
    if listFrame then return listFrame end
    
    listFrame = CreateFrame("Frame", nil, parent)
    listFrame:SetAllPoints()
    
    -- Create filter bar
    achFilters:createBar(listFrame)
    local filterBar = achFilters:getBar()
    
    -- Scroll frame below filter bar
    scrollFrame = CreateFrame("ScrollFrame", nil, listFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", filterBar, "BOTTOMLEFT", 0, -PADDING)
    scrollFrame:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -26, PADDING)
    
    -- Scroll child
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
    -- Recent section (at top of scroll child)
    recentSection = createRecentSection(scrollChild)
    recentSection:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
    recentSection:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, 0)
    
    -- Update scroll child width on resize
    scrollFrame:SetScript("OnSizeChanged", function(self)
        scrollChild:SetWidth(self:GetWidth())
        -- Delay repopulate slightly to ensure frame dimensions are fully updated
        C_Timer.After(0.01, function()
            populateList()
        end)
    end)
    
    return listFrame
end

function achievementList:refresh()
    populateList()
    
    if achFilters then
        -- Show filtered counts (reflects current filter state)
        local completed, total = achievementLogic:getFilteredCounts()
        achFilters:updateTotalCount(completed, total)
    end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

local function onDataRefreshed(eventName, payload)
    if listFrame and listFrame:IsVisible() then
        achievementList:refresh()
    end
end

local function onFilterChanged(eventName, payload)
    if listFrame and listFrame:IsVisible() then
        populateList()
        -- Update counts to reflect filtered results
        if achFilters then
            local completed, total = achievementLogic:getFilteredCounts()
            achFilters:updateTotalCount(completed, total)
        end
    end
end

local function onRowExpansionChanged(row, isExpanded)
    -- Re-layout the list when a row expands/collapses
    if listFrame and listFrame:IsVisible() then
        local achievementId = row.achievement and row.achievement.id
        populateList()
        
        -- After layout, ensure the row stays visible
        if achievementId then
            C_Timer.After(0.01, function()
                -- Find the row again (it may have been recycled)
                for _, r in ipairs(activeRows) do
                    if r.achievement and r.achievement.id == achievementId then
                        ensureElementVisible(r)
                        break
                    end
                end
            end)
        end
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function achievementList:initialize()
    if initialized then return true end
    
    -- Load main dependencies
    achievementLogic = Addon.achievementLogic
    achievementData = Addon.achievementData
    events = Addon.events
    utils = Addon.utils
    
    if not achievementLogic then
        print("|cff33ff99PAO|r: |cffff4444Error - achievementList: achievementLogic not available|r")
        return false
    end
    
    if not events then
        print("|cff33ff99PAO|r: |cffff4444Error - achievementList: events not available|r")
        return false
    end
    
    -- Load sub-modules
    achRow = Addon.achRow
    achHeader = Addon.achHeader
    achFilters = Addon.achFilters
    
    if not achRow or not achHeader or not achFilters then
        print("|cff33ff99PAO|r: |cffff4444Error - achievementList: sub-modules not available|r")
        return false
    end
    
    -- Initialize sub-modules
    achRow:initialize({
        achievementData = achievementData,
        achievementLogic = achievementLogic,
    })
    
    achHeader:initialize({
        achievementData = achievementData,
    })
    
    -- Set up callbacks
    achHeader:setOnCollapseChanged(function(groupName)
        populateList()
        
        -- After layout, ensure the header stays visible
        if groupName then
            C_Timer.After(0.01, function()
                for _, header in ipairs(activeHeaders) do
                    if header.groupName == groupName then
                        ensureElementVisible(header)
                        break
                    end
                end
            end)
        end
    end)
    
    achRow:setOnExpansionChanged(onRowExpansionChanged)
    
    achRow:setOnNavigateToAchievement(scrollToAchievement)
    
    achFilters:initialize({
        achievementData = achievementData,
        achievementLogic = achievementLogic,
        searchBox = Addon.searchBox,
    })
    
    -- Subscribe to events
    events:subscribe("ACHIEVEMENTS:DATA_REFRESHED", onDataRefreshed)
    events:subscribe("ACHIEVEMENTS:FILTER_CHANGED", onFilterChanged)
    
    initialized = true
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("achievementList", {
        "achievementLogic", 
        "achievementData", 
        "events", 
        "utils",
        "searchBox",
        "_achRow",
        "_achHeader",
        "_achFilters",
    }, function()
        return achievementList:initialize()
    end)
end

Addon.achievementList = achievementList
return achievementList