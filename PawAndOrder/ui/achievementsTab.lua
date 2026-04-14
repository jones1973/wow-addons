--[[
  ui/achievementsTab.lua
  Achievements Tab Content
  
  Manages the achievements tab content:
    - Creates wrapper frame containing achievement list
    - Registers "achievements" tab with tabs system
    - Initializes achievement UI on tab creation
  
  Dependencies: constants, utils, events, tabs, achievementList
  Exports: Addon.achievementsTab
]]

local ADDON_NAME, Addon = ...

local achievementsTab = {}

-- Module references (resolved at init)
local constants, utils, events, tabs
local achievementList, achievementLogic

-- UI elements
local wrapperFrame = nil

-- ============================================================================
-- CONTENT CREATION
-- ============================================================================

--[[
  Create the achievements tab content.
  Called by tabs system during initializeContent.
  
  @param contentArea frame - Parent frame from tabs system
  @return frame - The wrapper frame containing achievements content
]]
local function createContent(contentArea)
    if wrapperFrame then return wrapperFrame end
    
    -- Create wrapper frame that fills content area
    wrapperFrame = CreateFrame("Frame", ADDON_NAME .. "AchievementsContent", contentArea)
    wrapperFrame:SetAllPoints(contentArea)
    
    -- Create achievement list within wrapper
    if achievementList and achievementList.createFrame then
        achievementList:createFrame(wrapperFrame)
    end
    
    -- Tab selected - load data and refresh
    local dataLoadedOnce = false
    events:subscribe("TABS:CONTENT_SHOWN", function(eventName, payload)
        if payload.id ~= "achievements" then return end
        
        -- Load data only on first tab selection
        if not dataLoadedOnce and achievementLogic then
            achievementLogic:ensureLoaded()
            dataLoadedOnce = true
        end
        
        if achievementList and achievementList.refresh then
            achievementList:refresh()
        end
    end)
    
    return wrapperFrame
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Get wrapper frame.
  @return frame|nil
]]
function achievementsTab:getFrame()
    return wrapperFrame
end

--[[
  Refresh the achievement list.
]]
function achievementsTab:refresh()
    if achievementList and achievementList.refresh then
        achievementList:refresh()
    end
end

-- ============================================================================
-- TAB REGISTRATION
-- ============================================================================

--[[
  Register the achievements tab with the tabs system.
]]
local function registerTab()
    if not tabs then
        if utils then utils:error("achievementsTab: tabs system not available") end
        return
    end
    
    tabs:register({
        id = "achievements",
        name = "Achievements",
        icon = 136243,  -- Achievement icon
        order = 20,
        default = true,
        alwaysEnabled = false,
        createContent = createContent,
    })
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

--[[
  Initialize the achievements tab module.
  @return boolean
]]
function achievementsTab:initialize()
    -- Load module dependencies
    constants = Addon.constants
    utils = Addon.utils
    events = Addon.events
    tabs = Addon.tabs
    achievementList = Addon.achievementList
    achievementLogic = Addon.achievementLogic
    
    if not constants then
        print("|cff33ff99PAO|r: |cffff4444Error - achievementsTab: constants not available|r")
        return false
    end
    
    if not tabs then
        print("|cff33ff99PAO|r: |cffff4444Error - achievementsTab: tabs system not available|r")
        return false
    end
    
    -- Register the tab (content created later by tabs:initializeContent)
    registerTab()
    
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("achievementsTab", {
        "constants", "utils", "events", "tabs", "achievementList", "achievementLogic"
    }, function()
        return achievementsTab:initialize()
    end)
end

Addon.achievementsTab = achievementsTab
return achievementsTab