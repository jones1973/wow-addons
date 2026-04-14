--[[
  ui/tabBar.lua
  Horizontal Tab Bar UI Component
  
  Renders horizontal tabs at the top of the main frame, below the title bar.
  Uses traditional tab styling where the active tab merges into the content
  area below (no bottom border, shared background).
  
  Features:
    - Horizontal tabs with icon + text
    - Active tab visually merges into content (tab illusion)
    - Inactive tabs appear slightly recessed
    - Hide button on hover (for non-alwaysEnabled tabs)
    - Reactive updates via events
    - Auto-hides when only one tab enabled
    - Accounts for PortraitFrameTemplate portrait in top-left
  
  Dependencies: tabs, events, utils, constants
  Exports: Addon.tabBar
]]

local ADDON_NAME, Addon = ...

local tabBar = {}

-- UI State
local tabBarFrame = nil
local tabContainer = nil   -- Holds the tab buttons
local tabButtons = {}      -- tabId -> button frame
local initialized = false

-- Module references
local tabs, events, utils, constants

-- Layout constants
local TAB_HEIGHT = 32
local TAB_MIN_WIDTH = 90
local TAB_PADDING_H = 14      -- Horizontal padding inside tab
local TAB_SPACING = 2         -- Gap between tabs
local TAB_OFFSET_Y = -28      -- Below title bar
local ICON_SIZE = 18
local ICON_TEXT_GAP = 6

-- Portrait clearance (PortraitFrameTemplate portrait extends ~55px from left)
local PORTRAIT_CLEARANCE = 50  -- Extra left offset to clear portrait icon

-- Colors
local COLORS = {
    -- Active tab (must match content background for seamless illusion)
    activeBg = { 0.12, 0.12, 0.12, 0.85 },
    activeBorder = { 0.35, 0.35, 0.40, 1 },
    activeText = { 1.0, 0.82, 0.0, 1 },  -- Gold
    
    -- Inactive tab
    inactiveBg = { 0.08, 0.08, 0.10, 0.9 },
    inactiveBorder = { 0.25, 0.25, 0.30, 1 },
    inactiveText = { 0.6, 0.6, 0.6, 1 },
    
    -- Hover state
    hoverBg = { 0.15, 0.15, 0.18, 0.95 },
    hoverText = { 0.9, 0.9, 0.9, 1 },
    
    -- Content area border (tab bar draws this, active tab interrupts it)
    contentBorder = { 0.35, 0.35, 0.40, 1 },
}

-- ============================================================================
-- TAB BUTTON CREATION
-- ============================================================================

--[[
  Create border textures for a tab (top, left, right only - no bottom for active)
  @param button frame
  @return table - { top, left, right, bottom }
]]
local function createTabBorders(button)
    local borders = {}
    local thickness = 1
    
    -- Top border
    borders.top = button:CreateTexture(nil, "BORDER")
    borders.top:SetHeight(thickness)
    borders.top:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    borders.top:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    
    -- Left border
    borders.left = button:CreateTexture(nil, "BORDER")
    borders.left:SetWidth(thickness)
    borders.left:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    borders.left:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    
    -- Right border
    borders.right = button:CreateTexture(nil, "BORDER")
    borders.right:SetWidth(thickness)
    borders.right:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    borders.right:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    
    -- Bottom border (only shown for inactive tabs)
    borders.bottom = button:CreateTexture(nil, "BORDER")
    borders.bottom:SetHeight(thickness)
    borders.bottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    borders.bottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    
    return borders
end

--[[
  Apply visual state to a tab button
  @param button frame
  @param state string - "active", "inactive", or "hover"
]]
local function applyTabState(button, state)
    local bg, border, text
    
    if state == "active" then
        bg = COLORS.activeBg
        border = COLORS.activeBorder
        text = COLORS.activeText
        -- Active tab: no bottom border (merges with content)
        if button.borders then
            button.borders.bottom:Hide()
        end
        -- Show line cover to hide the borderLine under this tab
        -- Use opaque version of bg color to fully cover the borderLine
        if button.lineCover then
            button.lineCover:SetColorTexture(bg[1], bg[2], bg[3], 1.0)
            button.lineCover:Show()
        end
    elseif state == "hover" then
        bg = COLORS.hoverBg
        border = COLORS.inactiveBorder
        text = COLORS.hoverText
        if button.borders then
            button.borders.bottom:Show()
        end
        -- Hide line cover
        if button.lineCover then
            button.lineCover:Hide()
        end
    else -- inactive
        bg = COLORS.inactiveBg
        border = COLORS.inactiveBorder
        text = COLORS.inactiveText
        if button.borders then
            button.borders.bottom:Show()
        end
        -- Hide line cover
        if button.lineCover then
            button.lineCover:Hide()
        end
    end
    
    -- Apply background
    if button.background then
        button.background:SetColorTexture(bg[1], bg[2], bg[3], bg[4])
    end
    
    -- Apply borders
    if button.borders then
        button.borders.top:SetColorTexture(border[1], border[2], border[3], border[4])
        button.borders.left:SetColorTexture(border[1], border[2], border[3], border[4])
        button.borders.right:SetColorTexture(border[1], border[2], border[3], border[4])
        button.borders.bottom:SetColorTexture(border[1], border[2], border[3], border[4])
    end
    
    -- Apply text color
    if button.label then
        button.label:SetTextColor(text[1], text[2], text[3], text[4])
    end
    
    -- Icon saturation
    if button.icon then
        if state == "active" then
            button.icon:SetDesaturated(false)
            button.icon:SetAlpha(1)
        elseif state == "hover" then
            button.icon:SetDesaturated(false)
            button.icon:SetAlpha(0.9)
        else
            button.icon:SetDesaturated(true)
            button.icon:SetAlpha(0.7)
        end
    end
end

--[[
  Create a single tab button
  @param parent frame
  @param config table - Tab configuration { id, name, icon }
  @return frame
]]
local function createTabButton(parent, config)
    local button = CreateFrame("Button", nil, parent)
    button:SetHeight(TAB_HEIGHT)
    
    -- Background
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    button.background = bg
    
    -- Line cover - specifically covers the parent's borderLine under this tab
    -- Uses BORDER layer sublevel 1 to draw on top of the borderLine (sublevel 0)
    local lineCover = button:CreateTexture(nil, "BORDER", nil, 1)
    lineCover:SetHeight(1)
    lineCover:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    lineCover:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    lineCover:Hide()  -- Only shown for active tab
    button.lineCover = lineCover
    
    -- Borders
    button.borders = createTabBorders(button)
    
    -- Icon
    local icon = nil
    if config.icon then
        icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetPoint("LEFT", button, "LEFT", TAB_PADDING_H, 0)
        
        if type(config.icon) == "number" then
            icon:SetTexture(config.icon)
        else
            icon:SetTexture(config.icon)
        end
        button.icon = icon
    end
    
    -- Label
    local label = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    if icon then
        label:SetPoint("LEFT", icon, "RIGHT", ICON_TEXT_GAP, 0)
    else
        label:SetPoint("LEFT", button, "LEFT", TAB_PADDING_H, 0)
    end
    label:SetText(config.name)
    button.label = label
    
    -- Calculate width based on content
    local textWidth = label:GetStringWidth()
    local totalWidth = TAB_PADDING_H + (icon and (ICON_SIZE + ICON_TEXT_GAP) or 0) + textWidth + TAB_PADDING_H
    button:SetWidth(math.max(totalWidth, TAB_MIN_WIDTH))
    
    -- Store config
    button.tabConfig = config
    button._isSelected = false
    
    -- Event handlers
    button:SetScript("OnEnter", function(self)
        if not self._isSelected then
            applyTabState(self, "hover")
        end
    end)
    
    button:SetScript("OnLeave", function(self)
        if self._isSelected then
            applyTabState(self, "active")
        else
            applyTabState(self, "inactive")
        end
    end)
    
    button:SetScript("OnClick", function(self)
        tabs:select(self.tabConfig.id)
    end)
    
    -- Initial state
    applyTabState(button, "inactive")
    
    return button
end

-- ============================================================================
-- TAB BAR MANAGEMENT
-- ============================================================================

--[[
  Rebuild all tab buttons.
  Called when tabs are registered/unregistered or enabled/disabled.
  Uses height 0 vs TAB_HEIGHT for visibility - frame always exists for anchoring.
]]
local function rebuildTabs()
    
    if not tabBarFrame or not tabContainer then
        return
    end
    
    -- Clear existing buttons
    for id, button in pairs(tabButtons) do
        button:Hide()
        button:SetParent(nil)
    end
    wipe(tabButtons)
    
    -- Get enabled tabs
    local enabledTabs = tabs:getEnabled()
    
    for i, tab in ipairs(enabledTabs) do
    end
    
    -- Collapse tab bar if only one tab (height 0, hide children)
    if #enabledTabs <= 1 then
        tabBarFrame:SetHeight(0)
        tabContainer:Hide()
        if tabBarFrame.borderLine then
            tabBarFrame.borderLine:Hide()
        end
        
        -- Still select the tab even if bar is collapsed
        if #enabledTabs == 1 and not tabs:getSelected() then
            tabs:select(enabledTabs[1].id)
        end
        return
    end
    
    -- Expand tab bar (show with full height)
    tabBarFrame:SetHeight(TAB_HEIGHT)
    tabContainer:Show()
    if tabBarFrame.borderLine then
        tabBarFrame.borderLine:Show()
    end
    
    -- Create buttons and position them
    -- Start offset includes portrait clearance so tabs don't overlap corner icon
    local xOffset = 8 + PORTRAIT_CLEARANCE
    
    for index, config in ipairs(enabledTabs) do
        local button = createTabButton(tabContainer, config)
        button:SetPoint("BOTTOMLEFT", tabContainer, "BOTTOMLEFT", xOffset, 0)
        button._xOffset = xOffset  -- Store for repositioning when active
        
        tabButtons[config.id] = button
        
        -- Update offset for next tab
        xOffset = xOffset + button:GetWidth() + TAB_SPACING
        
        -- Apply selection state
        local isSelected = tabs:isSelected(config.id)
        button._isSelected = isSelected
        applyTabState(button, isSelected and "active" or "inactive")
    end
    
    
    -- If no tab selected, select first
    if not tabs:getSelected() and #enabledTabs > 0 then
        tabs:select(enabledTabs[1].id)
    end
end

--[[
  Update selection state on all buttons.
]]
local function updateSelectionState()
    local selectedId = tabs:getSelected()
    for id, button in pairs(tabButtons) do
        local isSelected = (id == selectedId)
        button._isSelected = isSelected
        applyTabState(button, isSelected and "active" or "inactive")
    end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

local function onTabRegistered(eventName, payload)
    rebuildTabs()
end

local function onTabStateChanged(eventName, payload)
    rebuildTabs()
end

local function onTabSelected(eventName, payload)
    updateSelectionState()
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Create the tab bar frame.
  Positions below title bar, offset right to clear PortraitFrameTemplate portrait.
  Frame always exists (for anchoring) but height is 0 when collapsed.
  
  @param parent frame - Parent frame (main window)
  @return frame
]]
function tabBar:create(parent)
    if tabBarFrame then
        return tabBarFrame
    end
    
    -- Tight padding for tab bar edges
    local tabBarPadding = 4
    
    -- Main tab bar frame (contains tabs + bottom border line)
    -- Use two-point anchor for guaranteed symmetric padding
    -- Tab buttons inside are offset to clear portrait
    tabBarFrame = CreateFrame("Frame", nil, parent)
    tabBarFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", tabBarPadding, TAB_OFFSET_Y)
    tabBarFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -tabBarPadding, TAB_OFFSET_Y)
    tabBarFrame:SetHeight(TAB_HEIGHT)  -- Will be set to 0 if collapsed
    
    -- Tab container (holds the actual tab buttons)
    tabContainer = CreateFrame("Frame", nil, tabBarFrame)
    tabContainer:SetAllPoints()
    
    -- Bottom border line (runs full width, active tab's lineCover covers it)
    -- Uses BACKGROUND layer so button's lineCover (BORDER layer) draws on top
    local borderLine = tabBarFrame:CreateTexture(nil, "BACKGROUND", nil, 7)
    borderLine:SetHeight(1)
    borderLine:SetPoint("BOTTOMLEFT", tabBarFrame, "BOTTOMLEFT", 0, 0)
    borderLine:SetPoint("BOTTOMRIGHT", tabBarFrame, "BOTTOMRIGHT", 0, 0)
    borderLine:SetColorTexture(COLORS.contentBorder[1], COLORS.contentBorder[2], COLORS.contentBorder[3], COLORS.contentBorder[4])
    tabBarFrame.borderLine = borderLine
    
    -- Register for events
    if events then
        events:subscribe("TABS:REGISTERED", onTabRegistered)
        events:subscribe("TABS:STATE_CHANGED", onTabStateChanged)
        events:subscribe("TABS:SELECTED", onTabSelected)
    end
    
    
    return tabBarFrame
end

--[[
  Initialize tab buttons after all tabs are registered.
]]
function tabBar:refresh()
    rebuildTabs()
end

--[[
  Get the tab bar frame.
  @return frame|nil
]]
function tabBar:getFrame()
    return tabBarFrame
end

--[[
  Check if the tab bar is currently expanded (showing tabs).
  @return boolean
]]
function tabBar:isVisible()
    return tabBarFrame and tabBarFrame:GetHeight() > 0
end

--[[
  Get the tab bar width (horizontal tabs don't consume width).
  @return number - Always 0 for horizontal tabs
]]
function tabBar:getWidth()
    return 0
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function tabBar:initialize()
    if initialized then return true end
    
    tabs = Addon.tabs
    events = Addon.events
    utils = Addon.utils
    constants = Addon.constants
    
    if not tabs then
        print("|cff33ff99PAO|r: |cffff4444Error - tabBar: tabs not available|r")
        return false
    end
    
    if not events then
        print("|cff33ff99PAO|r: |cffff4444Error - tabBar: events not available|r")
        return false
    end
    
    initialized = true
    
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("tabBar", {"tabs", "events", "utils"}, function()
        return tabBar:initialize()
    end)
end

Addon.tabBar = tabBar
return tabBar