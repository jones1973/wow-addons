--[[
  ui/levelingQueue/levelingTab.lua
  Leveling Tab Content
  
  Manages the leveling queue tab:
    - Split panel: queue list (left) + preview (right)
    - Queue list with drag/drop reordering
    - Preview panel showing next pets
    - Pin/override display
  
  Dependencies: constants, utils, events, tabs, levelingLogic, levelingDefaults
  Exports: Addon.levelingTab
]]

local ADDON_NAME, Addon = ...

local levelingTab = {}

-- Module references (resolved at init)
local constants, utils, events, tabs
local levelingLogic, levelingDefaults
local levelingQueue, levelingPreview

-- UI elements
local wrapperFrame = nil
local queueListPanel = nil
local previewPanel = nil

-- Layout constants
local LAYOUT = {
    QUEUE_PANEL_WIDTH = 550,
    PANEL_GAP = 12,
    EDGE_PADDING = 8,    -- Side padding (half standard)
    VERTICAL_PADDING = 8,
    HEADER_HEIGHT = 24,
}

-- ============================================================================
-- CONTENT CREATION
-- ============================================================================

--[[
  Create the leveling tab content.
  Called by tabs system during initializeContent.
  
  @param contentArea frame - Parent frame from tabs system
  @return frame - The wrapper frame
]]
local function createContent(contentArea)
    if wrapperFrame then return wrapperFrame end
    
    -- Create wrapper frame
    wrapperFrame = CreateFrame("Frame", ADDON_NAME .. "LevelingContent", contentArea)
    wrapperFrame:SetAllPoints(contentArea)
    
    -- Left panel: Queue list
    queueListPanel = CreateFrame("Frame", nil, wrapperFrame, "BackdropTemplate")
    queueListPanel:SetPoint("TOPLEFT", wrapperFrame, "TOPLEFT", LAYOUT.EDGE_PADDING, -LAYOUT.VERTICAL_PADDING)
    queueListPanel:SetPoint("BOTTOMLEFT", wrapperFrame, "BOTTOMLEFT", LAYOUT.EDGE_PADDING, LAYOUT.VERTICAL_PADDING)
    queueListPanel:SetWidth(LAYOUT.QUEUE_PANEL_WIDTH)
    queueListPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    queueListPanel:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
    queueListPanel:SetBackdropBorderColor(0.3, 0.3, 0.4, 0.8)
    
    -- Right panel: Preview
    previewPanel = CreateFrame("Frame", nil, wrapperFrame, "BackdropTemplate")
    previewPanel:SetPoint("TOPLEFT", queueListPanel, "TOPRIGHT", LAYOUT.PANEL_GAP, 0)
    previewPanel:SetPoint("BOTTOMRIGHT", wrapperFrame, "BOTTOMRIGHT", -LAYOUT.EDGE_PADDING, LAYOUT.VERTICAL_PADDING)
    previewPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    previewPanel:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
    previewPanel:SetBackdropBorderColor(0.3, 0.3, 0.4, 0.8)
    
    -- Initialize queue list component
    if levelingQueue then
        levelingQueue:createContent(queueListPanel)
    end
    
    -- Initialize preview component
    if levelingPreview then
        levelingPreview:createContent(previewPanel)
    end
    
    -- Subscribe to tab shown event
    events:subscribe("TABS:CONTENT_SHOWN", function(eventName, payload)
        if payload.id ~= "leveling" then return end
        levelingTab:refresh()
    end)
    
    -- Subscribe to queue changes (full refresh for visual feedback)
    events:subscribe("LEVELING:QUEUE_CHANGED", function()
        levelingTab:refresh()
    end)
    
    events:subscribe("LEVELING:PIN_CHANGED", function()
        levelingTab:refreshPreview()
    end)
    
    return wrapperFrame
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Refresh both panels.
]]
function levelingTab:refresh()
    if levelingQueue then
        levelingQueue:refresh()
    end
    self:refreshPreview()
end

--[[
  Refresh preview panel only.
]]
function levelingTab:refreshPreview()
    if levelingPreview then
        levelingPreview:refresh()
    end
end

--[[
  Set editing queue (shows that queue's pets in preview).
  @param queueId string|nil - Queue ID or nil for combined view
]]
function levelingTab:setEditingQueue(queueId)
    if levelingPreview then
        levelingPreview:setEditingQueue(queueId)
    end
    
    -- Update preview panel background to match editing state
    if previewPanel then
        if queueId then
            -- Match editing card's lavender tint exactly
            previewPanel:SetBackdropColor(0.20, 0.18, 0.25, 1)
        else
            -- Normal background
            previewPanel:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
        end
    end
end

--[[
  Get wrapper frame.
  @return frame|nil
]]
function levelingTab:getFrame()
    return wrapperFrame
end

-- ============================================================================
-- TAB REGISTRATION
-- ============================================================================

local function registerTab()
    if not tabs then
        if utils then utils:error("levelingTab: tabs system not available") end
        return
    end
    
    tabs:register({
        id = "leveling",
        name = "Leveling",
        icon = 236566,  -- Achievement_Level_25 texture ID
        order = 25,
        default = true,
        alwaysEnabled = false,
        createContent = createContent,
    })
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function levelingTab:initialize()
    constants = Addon.constants
    utils = Addon.utils
    events = Addon.events
    tabs = Addon.tabs
    levelingLogic = Addon.levelingLogic
    levelingDefaults = Addon.levelingDefaults
    levelingQueue = Addon.levelingQueue
    levelingPreview = Addon.levelingPreview
    
    if not constants or not tabs then
        print("|cff33ff99PAO|r: |cffff4444levelingTab: Missing dependencies|r")
        return false
    end
    
    registerTab()
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("levelingTab", {
        "constants", "utils", "events", "tabs",
        "levelingLogic", "levelingDefaults",
        "levelingQueue", "levelingPreview"
    }, function()
        return levelingTab:initialize()
    end)
end

Addon.levelingTab = levelingTab
return levelingTab