--[[
  ui/petList/infoPanel/infoPanel.lua
  Dynamic Info Panel Component
  
  Displays contextual information about active filters between filter chips and pet list.
  Uses a content provider system for extensibility - different filter types can register
  their own info display logic.
  
  Behavior:
  - Hidden by default (height 0)
  - Shows when any registered provider returns shouldShow = true
  - Dynamically adjusts height based on provider content
  - Controlled by setting: showFilterInfoPanels (default: enabled)
  - NO user dismiss button - purely settings-driven
  
  Integration:
  - Listens to FILTER:CHANGED internal event from mainFrame
  - Emits FILTER:HEIGHT_CHANGED when panel height changes
  - Works alongside filterChips for combined offset calculation
  
  Dependencies: utils, events, options
  Exports: Addon.infoPanel
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in infoPanel.lua.|r")
    return {}
end

local utils = Addon.utils
local events, options

local infoPanel = {}

-- UI State
local panelFrame = nil
local contentFrame = nil
local filterBoxRef = nil
local registeredProviders = {}
local currentHeight = 0
local chipsHeight = 0

-- Layout constants
local FILTER_HEIGHT = 26  -- Height of filter edit box
local PADDING_TOP = 5
local PADDING_BOTTOM = 5
local PADDING_LEFT = 0
local PADDING_RIGHT = 0
local INFO_ICON_SIZE = 16
local INFO_ICON_SPACING = 6
local LINE_HEIGHT = 20
local LINE_SPACING = 4

--[[
  Notify coordinator of height change via event
  Emits FILTER:HEIGHT_CHANGED for petList to handle.
]]
local function notifyHeightChanged()
    if events then
        events:emit("FILTER:HEIGHT_CHANGED", {
            totalHeight = FILTER_HEIGHT + chipsHeight + currentHeight,
            chipsHeight = chipsHeight,
            panelHeight = currentHeight
        })
    end
end

--[[
  Register a content provider
  Providers evaluate filter state and render content when active.
  
  @param provider table - Provider object with:
    - id: string (unique identifier)
    - priority: number (for future stacking, higher = shown first)
    - evaluate: function(filterText, filterCategories) -> shouldShow, contentData
    - render: function(container, contentData, yOffset) -> heightUsed
]]
function infoPanel:registerProvider(provider)
    if not provider or not provider.id then
        utils:error("infoPanel: Invalid provider - missing id")
        return
    end
    
    if not provider.evaluate or type(provider.evaluate) ~= "function" then
        utils:error("infoPanel: Invalid provider - evaluate must be a function")
        return
    end
    
    if not provider.render or type(provider.render) ~= "function" then
        utils:error("infoPanel: Invalid provider - render must be a function")
        return
    end
    
    -- Check for duplicate ID
    for _, existing in ipairs(registeredProviders) do
        if existing.id == provider.id then
            utils:error("infoPanel: Provider ID already registered: " .. provider.id)
            return
        end
    end
    
    provider.priority = provider.priority or 100
    table.insert(registeredProviders, provider)
    
    -- Sort by priority (higher first)
    table.sort(registeredProviders, function(a, b)
        return a.priority > b.priority
    end)
    
end

--[[
  Create info icon texture
  Standard info icon (i) for panel content
  
  @param parent frame - Parent frame
  @param x number - X offset
  @param y number - Y offset
  @return texture - Info icon texture
]]

--[[
  Clear all content from panel
  Hides and removes all dynamically created content
]]
local function clearContent()
    if not contentFrame then return end
    
    -- Hide all children (frames)
    local children = {contentFrame:GetChildren()}
    for _, child in ipairs(children) do
        child:Hide()
        child:SetParent(nil)
    end
    
    -- Hide all regions (font strings, textures)
    local regions = {contentFrame:GetRegions()}
    for _, region in ipairs(regions) do
        if region ~= contentFrame and region ~= contentIcon then  -- Don't remove frame or icon
            region:Hide()
            region:SetParent(nil)
        end
    end
    
    -- Hide icon (but don't orphan it - it's owned by infoPanel)
    if contentIcon then
        contentIcon:Hide()
    end
end

--[[
  Update panel display based on current filter state
  Evaluates all providers and renders active content
  
  @param filterText string - Current filter text
  @param filterCategories table - Parsed filter categories
]]
local function updatePanel(filterText, filterCategories)
    if not panelFrame or not contentFrame then return end
    
    -- Check if feature is enabled
    if options and options.Get and not options:Get("showFilterInfoPanels") then
        panelFrame:Hide()
        currentHeight = 0
        notifyHeightChanged()
        return
    end
    
    clearContent()
    
    -- Evaluate all providers
    local activeProviders = {}
    for _, provider in ipairs(registeredProviders) do
        local shouldShow, contentData = provider.evaluate(filterText, filterCategories)
        if shouldShow then
            table.insert(activeProviders, {
                provider = provider,
                contentData = contentData
            })
        end
    end
    
    -- No active providers = hide panel
    if #activeProviders == 0 then
        panelFrame:Hide()
        currentHeight = 0
        notifyHeightChanged()
        return
    end
    
    -- Render active providers
    local yOffset = -PADDING_TOP
    for _, active in ipairs(activeProviders) do
        -- Position and show info icon
        contentIcon:ClearAllPoints()
        contentIcon:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", 4, yOffset)
        contentIcon:Show()
        
        local heightUsed = active.provider.render(contentFrame, active.contentData, yOffset)
        yOffset = yOffset - heightUsed - LINE_SPACING
    end
    
    -- Calculate total height needed
    local totalHeight = math.abs(yOffset) - LINE_SPACING + PADDING_BOTTOM
    currentHeight = totalHeight
    panelFrame:SetHeight(totalHeight)
    panelFrame:Show()
    
    -- Notify coordinator of height change
    notifyHeightChanged()
    
    utils:debug(string.format("infoPanel: Updated - height=%d, activeProviders=%d", 
        totalHeight, #activeProviders))
end

--[[
  Handle filter change event
  Called when mainFrame fires FILTER:CHANGED internal event
  
  @param eventName string - Event name
  @param payload table - {filterText, categories}
]]
local function onFilterChanged(eventName, payload)
    if not payload then return end
    
    local filterText = payload.filterText or ""
    local categories = payload.categories or {}
    
    updatePanel(filterText, categories)
end

--[[
  Set chips height for combined offset calculation
  Called by filterChips when its height changes
  
  @param height number - Current chips height
]]
function infoPanel:setChipsHeight(height)
    chipsHeight = height or 0
    
    -- Reposition panel below chips with small gap
    if panelFrame and filterBoxRef then
        panelFrame:ClearAllPoints()
        local gap = (chipsHeight > 0) and 3 or 0  -- 3px gap if chips exist
        panelFrame:SetPoint("TOPLEFT", filterBoxRef, "BOTTOMLEFT", 0, -(chipsHeight + gap))
    end
    
    -- Notify coordinator of height change
    notifyHeightChanged()
end

--[[
  Get current panel height
  
  @return number - Current panel height in pixels
]]
function infoPanel:getHeight()
    return currentHeight
end

--[[
  Initialize info panel component
  Creates the panel frame and registers for filter change events.
  
  @param parentFrame frame - Parent frame to attach to
  @param filterBox frame - Filter box frame for positioning
  @param width number - Width of panel
]]
function infoPanel:initialize(parentFrame, filterBox, width)
    if panelFrame then return end
    
    events = Addon.events
    options = Addon.options
    filterBoxRef = filterBox
    
    if not events then
        utils:error("infoPanel: events not available")
        return
    end
    
    -- Create main panel frame
    panelFrame = CreateFrame("Frame", nil, parentFrame)
    panelFrame:SetPoint("TOPLEFT", filterBox, "BOTTOMLEFT", 0, 0)
    panelFrame:SetSize(width, 0)
    panelFrame:Hide()
    
    -- Background
    local bg = panelFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.15, 0.15, 0.2, 0.7)
    
    -- Content container
    contentFrame = CreateFrame("Frame", nil, panelFrame)
    contentFrame:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", PADDING_LEFT, 0)
    contentFrame:SetPoint("BOTTOMRIGHT", panelFrame, "BOTTOMRIGHT", -PADDING_RIGHT, 0)
    
    -- Create info icon (shared by all providers)
    contentIcon = contentFrame:CreateTexture(nil, "ARTWORK")
    contentIcon:SetSize(INFO_ICON_SIZE, INFO_ICON_SIZE)
    contentIcon:SetTexture("Interface\\Common\\help-i")
    contentIcon:Hide()
    
    -- Register for filter change events
    events:subscribe("LISTING:FILTER_CHANGED", onFilterChanged)
    
end

--[[
  Show panel
  Makes the panel visible
]]
function infoPanel:show()
    if panelFrame then
        panelFrame:Show()
    end
end

--[[
  Hide panel
  Conceals the panel
]]
function infoPanel:hide()
    if panelFrame then
        panelFrame:Hide()
        currentHeight = 0
        notifyHeightChanged()
    end
end


-- Export constants for providers
infoPanel.INFO_ICON_SIZE = INFO_ICON_SIZE
infoPanel.INFO_ICON_SPACING = INFO_ICON_SPACING
infoPanel.LINE_HEIGHT = LINE_HEIGHT

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("infoPanel", {"utils", "events"}, function()
        return true
    end)
end

Addon.infoPanel = infoPanel
return infoPanel