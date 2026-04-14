--[[
  ui/mainFrame.lua
  Main Application Window
  
  Container hierarchy (anchoring handles all positioning):
    mainFrame (window, PortraitFrameTemplate)
      └── tabBar (created by tabBar module, height 32 or 0)
      └── contentArea (anchors to tabBar bottom - auto-adjusts)
            └── [tab content fills parent]
      └── persistentBar (footer or sidebar - created last)
  
  Tab content is managed by individual tab modules (petsTab, achievementsTab)
  which register with the tabs system and provide their content frames.
  
  Dependencies: constants, commands, utils, tabs, tabBar, persistentBar
  Exports: Addon.mainFrame
]]

local ADDON_NAME, Addon = ...

-- Deferred module references (loaded in initialize)
local constants, commands, utils, events, options
local tabs, tabBar, persistentBar, petCache

-- Subscription ID for pet cache initialization
local petCacheInitSubId = nil

-- UI elements
local frame = nil
local contentArea = nil  -- Parent frame for all tab content

local mainFrame = {}

-- Default size for reset (double-click resize grip)
local DEFAULT_WIDTH = 1100
local DEFAULT_HEIGHT = 662

-- Portrait icon path (in textures folder - PNG requires extension)
local PORTRAIT_ICON = "Interface\\AddOns\\PawAndOrder\\textures\\pao-icon.png"

-- Content area padding
local CONTENT_PADDING = 4

-- ============================================================================
-- WINDOW CREATION
-- ============================================================================

--[[
  Create main window frame.
  Builds the resizable, draggable main frame using PortraitFrameTemplate.
]]
local function createWindow()
    frame = CreateFrame("Frame", ADDON_NAME .. "MainFrame", UIParent, "PortraitFrameTemplate")
    
    -- Load saved dimensions or use defaults
    local savedW = pao_settings and pao_settings.windowWidth
    local savedH = pao_settings and pao_settings.windowHeight
    local w = savedW or constants.WINDOW_WIDTH or DEFAULT_WIDTH
    local h = savedH or constants.WINDOW_HEIGHT or DEFAULT_HEIGHT
    frame:SetSize(w, h)
    frame:SetPoint("CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetResizable(true)
    
    -- Make frame come to front when clicked
    frame:SetToplevel(true)
    frame:SetScript("OnMouseDown", function(self) self:Raise() end)
    
    -- Register frame for ESC key handling
    table.insert(UISpecialFrames, ADDON_NAME .. "MainFrame")
    
    -- MoP Classic: min/max setters may not exist
    if frame.SetMinResize and frame.SetMaxResize then
        frame:SetMinResize(1000, 662)
        frame:SetMaxResize(1400, 1062)
    else
        frame._minWidth, frame._minHeight = 1000, 662
        frame._maxWidth, frame._maxHeight = 1400, 1062
    end
    
    frame:SetScript("OnSizeChanged", function(self)
        local width, height = self:GetSize()
        mainFrame:onResize(width, height)
    end)
    
    -- Set title using template method
    frame:SetTitle("Paw and Order")
    
    -- Set portrait icon using template method
    if frame.SetPortraitTextureRaw then
        frame:SetPortraitTextureRaw(PORTRAIT_ICON)
    elseif frame.portrait then
        -- Fallback: set texture directly on portrait
        frame.portrait:SetTexture(PORTRAIT_ICON)
    end
    
    -- Increase portrait size (default is ~60x60)
    if frame.portrait then
        frame.portrait:SetSize(72, 72)
    end
    
    -- Resize handle
    local resize = CreateFrame("Frame", nil, frame)
    resize:SetSize(16, 16)
    resize:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)
    resize:EnableMouse(true)
    
    local resizeTexture = resize:CreateTexture(nil, "ARTWORK")
    resizeTexture:SetAllPoints()
    resizeTexture:SetTexture("Interface\\ChatFrame\\UI\\ChatIM-SizeGrabber-Up")
    resize.texture = resizeTexture
    
    resize:SetScript("OnEnter", function(self)
        self.texture:SetTexture("Interface\\ChatFrame\\UI\\ChatIM-SizeGrabber-Highlight")
    end)
    resize:SetScript("OnLeave", function(self)
        self.texture:SetTexture("Interface\\ChatFrame\\UI\\ChatIM-SizeGrabber-Up")
    end)
    
    -- Track for double-click detection
    local lastClickTime = 0
    local DOUBLE_CLICK_THRESHOLD = 0.3
    
    resize:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            local now = GetTime()
            if (now - lastClickTime) < DOUBLE_CLICK_THRESHOLD then
                -- Double-click: reset to default size
                frame:SetSize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
                mainFrame:onResize(DEFAULT_WIDTH, DEFAULT_HEIGHT)
                if pao_settings then
                    pao_settings.windowWidth = DEFAULT_WIDTH
                    pao_settings.windowHeight = DEFAULT_HEIGHT
                end
                lastClickTime = 0  -- Reset to prevent triple-click triggering
            else
                -- Single-click: start sizing
                frame:StartSizing("BOTTOMRIGHT")
                lastClickTime = now
            end
            self.texture:SetTexture("Interface\\ChatFrame\\UI\\ChatIM-SizeGrabber-Down")
        end
    end)
    resize:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            frame:StopMovingOrSizing()
            -- Save new dimensions
            if pao_settings then
                pao_settings.windowWidth = math.floor(frame:GetWidth() + 0.5)
                pao_settings.windowHeight = math.floor(frame:GetHeight() + 0.5)
            end
            self.texture:SetTexture("Interface\\ChatFrame\\UI\\ChatIM-SizeGrabber-Highlight")
        end
    end)
    
    -- NOTE: Don't hide here. Children need to be created while parent is visible
    -- so anchor-based dimensions resolve. Hide at end of initialize().
end

--[[
  Update Content Area Anchors
  Adjusts content area size based on persistent bar layout.
]]
local function updateContentAreaAnchors()
    if not contentArea or not persistentBar then return end
    
    local space = persistentBar:getRequiredSpace()
    local tabBarFrame = tabBar and tabBar:getFrame()
    
    contentArea:ClearAllPoints()
    
    -- Top anchor (to tab bar)
    if tabBarFrame then
        contentArea:SetPoint("TOPLEFT", tabBarFrame, "BOTTOMLEFT", 0, 0)
    else
        contentArea:SetPoint("TOPLEFT", frame, "TOPLEFT", CONTENT_PADDING, -28)
    end
    
    -- Bottom anchor (adjust for footer + padding on both sides)
    local bottomOffset = CONTENT_PADDING + space.height + (space.height > 0 and CONTENT_PADDING or 0)
    contentArea:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CONTENT_PADDING, bottomOffset)
    
    -- Right anchor (adjust for sidebar + padding on both sides)
    local rightOffset = -(CONTENT_PADDING + space.width + (space.width > 0 and CONTENT_PADDING or 0))
    contentArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", rightOffset, bottomOffset)
    
    -- Update width explicitly (MoP doesn't derive synchronously)
    local frameWidth = frame:GetWidth()
    contentArea:SetWidth(frameWidth - 2 * CONTENT_PADDING - space.width - (space.width > 0 and CONTENT_PADDING or 0))
end

--[[
  Create the content area frame.
  Anchors to tabBar bottom for vertical positioning.
  Initial anchors will be updated by updateContentAreaAnchors.
]]
local function createContentArea()
    contentArea = CreateFrame("Frame", nil, frame)
    
    -- Initial anchors (will be updated by updateContentAreaAnchors)
    local tabBarFrame = tabBar and tabBar:getFrame()
    if tabBarFrame then
        contentArea:SetPoint("TOPLEFT", tabBarFrame, "BOTTOMLEFT", 0, 0)
    else
        contentArea:SetPoint("TOPLEFT", frame, "TOPLEFT", CONTENT_PADDING, -28)
    end
    contentArea:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CONTENT_PADDING, CONTENT_PADDING)
    contentArea:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)
    
    -- Explicit width calculation
    contentArea:SetWidth(frame:GetWidth() - 2 * CONTENT_PADDING)
    
    -- Hook frame resize to update width
    frame:HookScript("OnSizeChanged", function(self, w, h)
        if contentArea then
            local space = persistentBar and persistentBar:getRequiredSpace() or {width = 0, height = 0}
            local sidebarPadding = space.width > 0 and CONTENT_PADDING or 0
            contentArea:SetWidth(w - 2 * CONTENT_PADDING - space.width - sidebarPadding)
        end
    end)
    
    -- Background that matches active tab color for seamless tab illusion
    local bg = contentArea:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.12, 0.12, 0.12, 0.85)  -- Must match tabBar COLORS.activeBg
    contentArea.background = bg
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Get the main frame.
  @return frame|nil
]]
function mainFrame:getFrame()
    return frame
end

--[[
  Get the content area.
  @return frame|nil
]]
function mainFrame:getContentArea()
    return contentArea
end

--[[
  Handle window resize.
  Enforces size constraints and fires event for tabs.
  No positioning updates needed - anchoring handles it.
  
  @param width number - New width
  @param height number - New height
]]
function mainFrame:onResize(width, height)
    if not frame then return end
    
    local minW = frame._minWidth or 1000
    local maxW = frame._maxWidth or 1400
    local minH = frame._minHeight or 662
    local maxH = frame._maxHeight or 1062
    
    width = math.max(minW, math.min(width, maxW))
    height = math.max(minH, math.min(height, maxH))
    frame:SetSize(width, height)
    
    -- Fire resize event for tabs to handle internal layout
    if events then
        events:emit("MAINFRAME:RESIZED", {
            width = width,
            height = height,
        })
    end
end

--[[
  Toggle main window visibility.
  Shows the window if hidden, hides if shown. Initializes on first call.
  Gates on pet cache - waits for pet data before showing UI.
]]
function mainFrame:toggle()
    -- Get petCache reference if needed
    if not petCache then
        petCache = Addon.petCache
    end
    
    -- Gate: wait for pet data before showing UI
    if petCache and not petCache:isInitialized() then
        -- Subscribe to initialization event (only once)
        if not petCacheInitSubId and Addon.events then
            petCacheInitSubId = Addon.events:subscribe("CACHE:INITIALIZED", function()
                -- Unsubscribe
                if petCacheInitSubId then
                    Addon.events:unsubscribe(petCacheInitSubId)
                    petCacheInitSubId = nil
                end
                -- Now show UI
                mainFrame:toggle()
            end)
        end
        -- Trigger data load
        petCache:ensureReady()
        return
    end
    
    if not frame then
        self:initialize()
    end
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end

--[[
  Initialize main frame.
  Creates window, tab bar, content area, persistent bar, and initializes tab content.
]]
function mainFrame:initialize()
    if frame then return end
    
    -- Load module dependencies
    constants = Addon.constants
    commands = Addon.commands
    utils = Addon.utils
    events = Addon.events
    options = Addon.options
    tabs = Addon.tabs
    tabBar = Addon.tabBar
    persistentBar = Addon.persistentBar
    
    -- Create window
    createWindow()
    
    -- Create tab bar (positions itself below title bar, offset for portrait)
    if tabBar then
        tabBar:create(frame)
    end
    
    -- Create content area (anchors to tab bar bottom - adjusts automatically)
    createContentArea()
    
    -- Tell tabs system about the content area
    if tabs then
        tabs:setContentArea(contentArea)
    end
    
    -- Initialize all tab content frames
    if tabs then
        tabs:initializeContent(contentArea)
    end
    
    -- Refresh tab bar to show registered tabs (sets its height)
    if tabBar then
        tabBar:refresh()
    end
    
    -- Create persistent bar (footer or sidebar based on settings)
    if persistentBar then
        persistentBar:create(frame)
        
        -- Position based on layout
        local barFrame = persistentBar:getFrame()
        local space = persistentBar:getRequiredSpace()
        
        if barFrame then
            barFrame:ClearAllPoints()
            if space.height > 0 then
                -- Footer layout
                barFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CONTENT_PADDING, CONTENT_PADDING)
                barFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)
            elseif space.width > 0 then
                -- Sidebar layout
                barFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -CONTENT_PADDING, -60)
                barFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)
            end
        end
        
        -- Adjust content area for persistent bar
        updateContentAreaAnchors()
        
        -- Re-emit COLLECTION:COUNTS now that persistentBar is subscribed
        -- (headerBar emitted it during tabs init, before persistentBar existed)
        if Addon.headerBar and Addon.headerBar.refreshPetCount then
            Addon.headerBar:refreshPetCount()
        end
    end
    
    -- Subscribe to persistent bar layout changes
    if events then
        events:subscribe("PERSISTENT_BAR:LAYOUT_CHANGED", function(eventName, payload)
            if persistentBar then
                local barFrame = persistentBar:getFrame()
                local space = payload or persistentBar:getRequiredSpace()
                
                if barFrame then
                    barFrame:ClearAllPoints()
                    if space.height > 0 then
                        -- Footer layout
                        barFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", CONTENT_PADDING, CONTENT_PADDING)
                        barFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)
                    elseif space.width > 0 then
                        -- Sidebar layout
                        barFrame:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -CONTENT_PADDING, -60)
                        barFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -CONTENT_PADDING, CONTENT_PADDING)
                    end
                end
                
                updateContentAreaAnchors()
            end
        end)
    end
    
    -- Subscribe to filter text change requests from components
    if events then
        events:subscribe("FILTER:SET_TEXT", function(eventName, payload)
            if payload and payload.filterText ~= nil then
                mainFrame:setFilterTextAndChips(payload.filterText)
            end
        end)
    end
    
    -- OnShow: Select first tab if none selected
    frame:SetScript("OnShow", function()
        if tabs and not tabs:getSelected() then
            tabs:selectFirst()
        end
        
        -- Fire resize event to ensure proper layout
        local width, height = frame:GetSize()
        mainFrame:onResize(width, height)
    end)
    
    -- OnHide: Clean up any open dropdown menus
    frame:SetScript("OnHide", function()
        CloseDropDownMenus()
    end)
    
    -- Now hide the frame (children have been created with proper anchoring)
    frame:Hide()
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("mainFrame", {
        "constants", "commands", "utils", "events", "options", "tabs", "tabBar",
        "persistentBar", "petsTab", "achievementsTab", "petCache"
    }, function()
        if Addon.commands then
            Addon.commands:register({
                command = "show",
                aliases = {"toggle", "ui"},
                handler = function()
                    mainFrame:toggle()
                end,
                help = "Show/hide the main window",
                usage = "show",
                detailedHelp = "Toggle the Paw and Order main window on/off.",
                category = "General"
            })
        end
        return true
    end)
end

Addon.mainFrame = mainFrame
return mainFrame