--[[
  ui/achievementList/achHeader.lua
  Achievement Section Header Component (Animated Accordion)
  
  Provides clickable section headers for achievement list groupings:
    - Click to expand/collapse section
    - Animated expand/collapse indicator
    - Category name display
    - Completion count (X / Y)
  
  Dependencies: achievementData
  Exports: Addon._achHeader (internal module)
]]

local ADDON_NAME, Addon = ...

local achHeader = {}

-- Module references
local achievementData

-- Layout constants
local HEADER_HEIGHT = 28
local PADDING = 8
local ARROW_SIZE = 16
local ANIMATION_DURATION = 0.15

-- Track collapsed state per group (by name)
local collapsedGroups = {}

-- Callback for when collapse state changes
local onCollapseChanged = nil

-- ============================================================================
-- HEADER CREATION
-- ============================================================================

function achHeader:createHeader(parent)
    local header = CreateFrame("Button", nil, parent)
    header:SetHeight(HEADER_HEIGHT)
    
    -- Background
    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(achievementData.COLORS.HEADER_BG))
    header.background = bg
    
    -- Highlight on hover
    local highlight = header:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.1)
    
    -- Expand/collapse arrow container (for animation)
    local arrowFrame = CreateFrame("Frame", nil, header)
    arrowFrame:SetSize(ARROW_SIZE, ARROW_SIZE)
    arrowFrame:SetPoint("LEFT", header, "LEFT", PADDING, 0)
    header.arrowFrame = arrowFrame
    
    -- Arrow texture
    local arrow = arrowFrame:CreateTexture(nil, "ARTWORK")
    arrow:SetAllPoints()
    arrow:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
    header.arrow = arrow
    
    -- Section name
    local nameText = header:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    nameText:SetPoint("LEFT", arrowFrame, "RIGHT", 4, 0)
    nameText:SetTextColor(unpack(achievementData.COLORS.HEADER_TEXT))
    header.nameText = nameText
    
    -- Count text
    local countText = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    countText:SetPoint("RIGHT", header, "RIGHT", -PADDING, 0)
    countText:SetTextColor(0.8, 0.8, 0.8)
    header.countText = countText
    
    -- Animation group for smooth transitions
    local animGroup = arrowFrame:CreateAnimationGroup()
    header.animGroup = animGroup
    
    local rotation = animGroup:CreateAnimation("Rotation")
    rotation:SetDuration(ANIMATION_DURATION)
    rotation:SetSmoothing("IN_OUT")
    rotation:SetOrigin("CENTER", 0, 0)
    header.rotationAnim = rotation
    
    -- Click handler
    header:SetScript("OnClick", function(self)
        if self.groupName then
            local wasCollapsed = achHeader:isCollapsed(self.groupName)
            achHeader:toggleCollapsed(self.groupName)
            achHeader:updateArrow(self, true)
            
            -- Trigger lazy loading when expanding
            if wasCollapsed and self.categoryId then
                local achievementLogic = Addon.achievementLogic
                if achievementLogic then
                    achievementLogic:loadCategoryDetails(self.categoryId)
                end
            end
            
            if onCollapseChanged then
                onCollapseChanged(self.groupName)
            end
        end
    end)
    
    return header
end

--[[
  Update arrow texture based on collapsed state.
  @param header frame
  @param animate boolean - Whether to animate the transition
]]
function achHeader:updateArrow(header, animate)
    if not header or not header.arrow or not header.groupName then return end
    
    local isCollapsed = collapsedGroups[header.groupName]
    
    if isCollapsed then
        header.arrow:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
    else
        header.arrow:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
    end
end

--[[
  Set header data.
  @param header frame
  @param name string - Section name
  @param completed number
  @param total number
  @param categoryId number|string - Category ID for lazy loading
]]
function achHeader:setData(header, name, completed, total, categoryId)
    header.groupName = name
    header.categoryId = categoryId
    
    if header.nameText then
        header.nameText:SetText(name)
    end
    if header.countText then
        header.countText:SetText(string.format("%d / %d", completed or 0, total or 0))
    end
    
    -- Initialize collapsed state (default to collapsed)
    if collapsedGroups[name] == nil then
        collapsedGroups[name] = true
    end
    
    self:updateArrow(header)
end

--[[
  Check if a group is collapsed.
  @param groupName string
  @return boolean
]]
function achHeader:isCollapsed(groupName)
    if collapsedGroups[groupName] == nil then
        collapsedGroups[groupName] = true
    end
    return collapsedGroups[groupName]
end

--[[
  Toggle collapsed state for a group.
  Closes all other groups when expanding one.
  @param groupName string
]]
function achHeader:toggleCollapsed(groupName)
    local wasCollapsed = self:isCollapsed(groupName)
    
    if wasCollapsed then
        -- Opening this group - close all others first
        for name, _ in pairs(collapsedGroups) do
            collapsedGroups[name] = true
        end
    end
    
    -- Toggle the target group
    collapsedGroups[groupName] = not wasCollapsed
end

--[[
  Set collapsed state for a group.
  @param groupName string
  @param collapsed boolean
]]
function achHeader:setCollapsed(groupName, collapsed)
    collapsedGroups[groupName] = collapsed
end

--[[
  Collapse all groups.
]]
function achHeader:collapseAll()
    for name, _ in pairs(collapsedGroups) do
        collapsedGroups[name] = true
    end
end

--[[
  Expand all groups.
]]
function achHeader:expandAll()
    for name, _ in pairs(collapsedGroups) do
        collapsedGroups[name] = false
    end
end

--[[
  Set callback for when collapse state changes.
  @param callback function
]]
function achHeader:setOnCollapseChanged(callback)
    onCollapseChanged = callback
end

--[[
  Get the header height constant.
  @return number
]]
function achHeader:getHeaderHeight()
    return HEADER_HEIGHT
end

--[[
  Initialize the module with dependencies.
  @param deps table
]]
function achHeader:initialize(deps)
    achievementData = deps.achievementData
end

-- Self-register
if Addon.registerModule then
    Addon.registerModule("_achHeader", {}, function()
        return true
    end)
end

Addon.achHeader = achHeader
return achHeader