--[[
  core/tabs.lua
  Tab Registration and State Management System
  
  Provides a centralized registration system for UI tabs. Modules register
  their tabs during initialization, and the tab bar queries this registry
  to render available tabs.
  
  Features:
    - Order-based sorting
    - Dynamic enable/disable per tab
    - Settings persistence for hidden tabs
    - Event-driven state changes
    - Content frame management
  
  Events Emitted:
    - TABS:REGISTERED      - New tab registered
    - TABS:STATE_CHANGED   - Tab enabled/disabled
    - TABS:SELECTED        - Tab selection changed (immediate)
    - TABS:CONTENT_SHOWN   - Tab content visible and laid out (deferred one frame)
  
  Dependencies: events, utils
  Exports: Addon.tabs
]]

local ADDON_NAME, Addon = ...

local tabs = {}

-- Internal state
local registry = {}           -- id -> tab config
local contentFrames = {}      -- id -> content frame created by tab
local sortedTabs = nil        -- Cached sorted array, invalidated on register
local currentTabId = nil      -- Currently selected tab ID
local contentArea = nil       -- Parent frame for all tab content
local initialized = false
local sessionTabStates = nil  -- Snapshot of tab states at startup (survives pao_settings changes)

-- Module references (resolved at init)
local events, utils

--[[
  Tab configuration schema:
  {
    id = "pets",              -- Unique identifier (required)
    name = "Pets",            -- Display name (required)
    icon = 132599,            -- Texture ID or path (optional)
    order = 10,               -- Sort order, lower = leftmost (required)
    default = true,           -- Default enabled state (optional, default true)
    alwaysEnabled = false,    -- Cannot be disabled by user (optional)
    createContent = function(contentArea) end,  -- Creates and returns content frame (required)
  }
]]

-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

--[[
  Invalidate sorted cache.
  Forces re-sort on next getEnabled() call.
]]
local function invalidateSortCache()
    sortedTabs = nil
end

--[[
  Get setting key for tab visibility.
  @param tabId string
  @return string
]]
local function getSettingKey(tabId)
    return "tab_" .. tabId .. "_enabled"
end

--[[
  Check if tab is enabled in settings.
  Uses sessionTabStates snapshot to ignore runtime changes to pao_settings.tabs.
  @param tabId string
  @return boolean
]]
local function isTabEnabledInSettings(tabId)
    local config = registry[tabId]
    if not config then
        return false
    end
    
    -- Always-enabled tabs ignore settings
    if config.alwaysEnabled then
        return true
    end
    
    -- Check session snapshot (captured at startup, ignores runtime changes)
    if sessionTabStates and sessionTabStates[tabId] ~= nil then
        return sessionTabStates[tabId]
    end
    
    -- Fall back to default (tab registered after snapshot taken)
    return config.default ~= false
end

--[[
  Save tab enabled state to settings.
  @param tabId string
  @param enabled boolean
]]
local function saveTabEnabledState(tabId, enabled)
    if not pao_settings then pao_settings = {} end
    if not pao_settings.tabs then pao_settings.tabs = {} end
    pao_settings.tabs[tabId] = enabled
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Register a tab.
  Called by modules during their initialization to add tabs.
  
  @param config table - Tab configuration (see schema above)
  @return boolean - Success
]]
function tabs:register(config)
    -- Validate required fields
    if not config.id then
        if utils then utils:error("tabs:register - missing id") end
        return false
    end
    if not config.name then
        if utils then utils:error("tabs:register - missing name for tab: " .. config.id) end
        return false
    end
    if not config.order then
        if utils then utils:error("tabs:register - missing order for tab: " .. config.id) end
        return false
    end
    if not config.createContent or type(config.createContent) ~= "function" then
        if utils then utils:error("tabs:register - missing or invalid createContent for tab: " .. config.id) end
        return false
    end
    
    -- Check for duplicate (silently replace)
    -- If config with same ID exists, it will be replaced
    
    -- Store config
    registry[config.id] = {
        id = config.id,
        name = config.name,
        icon = config.icon,
        order = config.order,
        default = config.default ~= false,  -- Default to true
        alwaysEnabled = config.alwaysEnabled or false,
        createContent = config.createContent,
    }
    
    -- Invalidate cache
    invalidateSortCache()
    
    -- Fire event
    if events then
        events:emit("TABS:REGISTERED", { id = config.id, name = config.name })
    end
    
    return true
end

--[[
  Unregister a tab.
  @param tabId string
  @return boolean - Success
]]
function tabs:unregister(tabId)
    if not registry[tabId] then
        return false
    end
    
    -- If this was the selected tab, clear selection
    if currentTabId == tabId then
        currentTabId = nil
    end
    
    -- Clean up content frame
    if contentFrames[tabId] then
        contentFrames[tabId]:Hide()
        contentFrames[tabId]:SetParent(nil)
        contentFrames[tabId] = nil
    end
    
    registry[tabId] = nil
    invalidateSortCache()
    
    return true
end

--[[
  Get all enabled tabs, sorted by order.
  @return table - Array of tab configs
]]
function tabs:getEnabled()
    if sortedTabs then
        -- Filter cached list for currently enabled
        local enabled = {}
        for _, tab in ipairs(sortedTabs) do
            if isTabEnabledInSettings(tab.id) then
                table.insert(enabled, tab)
            end
        end
        return enabled
    end
    
    -- Build sorted list
    sortedTabs = {}
    for _, config in pairs(registry) do
        table.insert(sortedTabs, config)
    end
    table.sort(sortedTabs, function(a, b)
        return a.order < b.order
    end)
    
    -- Filter for enabled
    local enabled = {}
    for _, tab in ipairs(sortedTabs) do
        if isTabEnabledInSettings(tab.id) then
            table.insert(enabled, tab)
        end
    end
    
    return enabled
end

--[[
  Get all registered tabs (including disabled), sorted by order.
  Used by settings panel to show all available tabs.
  @return table - Array of tab configs with enabled state
]]
function tabs:getAll()
    local all = {}
    for _, config in pairs(registry) do
        local entry = {}
        for k, v in pairs(config) do
            entry[k] = v
        end
        entry.enabled = isTabEnabledInSettings(config.id)
        table.insert(all, entry)
    end
    table.sort(all, function(a, b)
        return a.order < b.order
    end)
    return all
end

--[[
  Get a specific tab config by ID.
  @param tabId string
  @return table|nil
]]
function tabs:get(tabId)
    return registry[tabId]
end

--[[
  Check if a tab is enabled.
  @param tabId string
  @return boolean
]]
function tabs:isEnabled(tabId)
    return isTabEnabledInSettings(tabId)
end

--[[
  Enable or disable a tab.
  @param tabId string
  @param enabled boolean
]]
function tabs:setEnabled(tabId, enabled)
    local config = registry[tabId]
    if not config then
        if utils then utils:error("tabs:setEnabled - unknown tab: " .. tabId) end
        return
    end
    
    if config.alwaysEnabled then
        return
    end
    
    local wasEnabled = isTabEnabledInSettings(tabId)
    if wasEnabled == enabled then return end
    
    -- Prevent disabling the last enabled tab
    if not enabled then
        local enabledTabs = self:getEnabled()
        if #enabledTabs <= 1 then
            if utils then utils:chat("Cannot hide the last tab.") end
            return
        end
    end
    
    saveTabEnabledState(tabId, enabled)
    invalidateSortCache()
    
    -- Fire event
    if events then
        events:emit("TABS:STATE_CHANGED", {
            id = tabId,
            enabled = enabled,
        })
    end
    
    -- If disabling the current tab, need to select another
    if not enabled and currentTabId == tabId then
        self:selectFirst()
    end
end

--[[
  Select a tab by ID.
  Hides previous tab's content frame, shows new tab's content frame.
  
  Emits:
    - TABS:SELECTED (immediate) - for non-layout-dependent reactions
    - TABS:CONTENT_SHOWN (deferred one frame) - for layout-dependent operations
  
  @param tabId string
  @return boolean - Success
]]
function tabs:select(tabId)
    local config = registry[tabId]
    if not config then
        if utils then utils:error("tabs:select - unknown tab: " .. tabId) end
        return false
    end
    
    if not isTabEnabledInSettings(tabId) then
        return false
    end
    
    -- Hide previous tab's content
    if currentTabId and currentTabId ~= tabId then
        local oldFrame = contentFrames[currentTabId]
        if oldFrame then
            oldFrame:Hide()
        end
    end
    
    -- Show new tab's content
    currentTabId = tabId
    local newFrame = contentFrames[tabId]
    if newFrame then
        newFrame:Show()
    end
    
    -- Fire immediate event (for non-layout-dependent reactions)
    if events then
        events:emit("TABS:SELECTED", {
            id = tabId,
            name = config.name,
        })
        
        -- Fire deferred event after one frame (for layout-dependent operations)
        -- WoW needs a frame to complete layout calculations after Show()
        C_Timer.After(0, function()
            events:emit("TABS:CONTENT_SHOWN", {
                id = tabId,
                name = config.name,
                frame = newFrame,
            })
        end)
    end
    
    return true
end

--[[
  Select the first enabled tab.
  @return boolean - Success
]]
function tabs:selectFirst()
    local enabled = self:getEnabled()
    if #enabled > 0 then
        return self:select(enabled[1].id)
    end
    return false
end

--[[
  Get the currently selected tab ID.
  @return string|nil
]]
function tabs:getSelected()
    return currentTabId
end

--[[
  Check if a specific tab is currently selected.
  @param tabId string
  @return boolean
]]
function tabs:isSelected(tabId)
    return currentTabId == tabId
end

--[[
  Check if a tab can be hidden.
  Returns false if it's the last enabled tab or if it's alwaysEnabled.
  @param tabId string
  @return boolean
]]
function tabs:canHide(tabId)
    local config = registry[tabId]
    if not config then return false end
    if config.alwaysEnabled then return false end
    
    local enabledTabs = self:getEnabled()
    return #enabledTabs > 1
end

--[[
  Get count of enabled tabs.
  @return number
]]
function tabs:getEnabledCount()
    return #self:getEnabled()
end

--[[
  Set the content area frame.
  All tab content frames will be parented to this.
  
  @param area frame - Content area frame
]]
function tabs:setContentArea(area)
    contentArea = area
end

--[[
  Get the content area frame.
  @return frame|nil
]]
function tabs:getContentArea()
    return contentArea
end

--[[
  Initialize content frames for all enabled tabs.
  Called by mainFrame after content area is created.
  
  @param area frame - Content area frame (optional, uses stored if not provided)
  @return boolean - Success
]]
function tabs:initializeContent(area)
    if area then
        contentArea = area
    end
    
    if not contentArea then
        if utils then utils:error("tabs:initializeContent - no content area set") end
        return false
    end
    
    local enabledTabs = self:getEnabled()
    
    for _, config in ipairs(enabledTabs) do
        if not contentFrames[config.id] then
            -- pcall: Plugin pattern - tab createContent functions may error, errors logged below
            local ok, result = pcall(config.createContent, contentArea)
            if ok and result then
                contentFrames[config.id] = result
                result:Hide()
            else
                if utils then 
                    utils:error("tabs:initializeContent - failed to create content for: " .. config.id .. " - " .. tostring(result))
                end
            end
        end
    end
    
    return true
end

--[[
  Get the content frame for a specific tab.
  @param tabId string
  @return frame|nil
]]
function tabs:getContentFrame(tabId)
    return contentFrames[tabId]
end

--[[
  Check if a tab's content has been initialized.
  @param tabId string
  @return boolean
]]
function tabs:hasContent(tabId)
    return contentFrames[tabId] ~= nil
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

--[[
  Initialize the tab system.
  Resolves module references and sets up settings structure.
  
  @return boolean
]]
function tabs:initialize()
    if initialized then return true end
    
    events = Addon.events
    utils = Addon.utils
    
    if not events then
        print("|cff33ff99PAO|r: |cffff4444Error - tabs: events not available|r")
        return false
    end
    
    -- Ensure settings structure exists
    if not pao_settings then pao_settings = {} end
    if not pao_settings.tabs then pao_settings.tabs = {} end
    
    -- Snapshot current tab states (survives runtime changes to pao_settings.tabs)
    sessionTabStates = {}
    for tabId, enabled in pairs(pao_settings.tabs) do
        sessionTabStates[tabId] = enabled
    end
    
    initialized = true
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("tabs", {"events", "utils"}, function()
        return tabs:initialize()
    end)
end

Addon.tabs = tabs
return tabs