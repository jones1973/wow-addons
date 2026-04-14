--[[
  ui/shared/menuRenderer.lua
  Unified Menu Rendering Engine
  
  Core rendering engine for all popup menus (dropdowns, context menus).
  Single source of truth for menu visuals and behavior.
  
  Features:
  - Frame pooling for performance
  - Standard item rendering (text, icon, checkmark, arrow)
  - Custom item rendering via renderRow callback
  - Lavender hover highlight
  - Separators
  - Submenus with hover activation
  - Checkbox mode (keepOpenOnClick)
  - Auto-close on outside click
  - Auto-close on timeout (1.5s after mouse leaves)
  - Escape key closes menu
  
  Dependencies: None
  Exports: Addon.menuRenderer
]]

local ADDON_NAME, Addon = ...

local menuRenderer = {}

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local STYLE = {
    -- Colors
    bgColor = {0.08, 0.08, 0.08, 0.95},
    borderColor = {0.4, 0.4, 0.4, 1},
    hoverColor = {0.4, 0.3, 0.6, 0.7},  -- Lavender
    textColor = {1, 1, 1, 1},
    disabledColor = {0.5, 0.5, 0.5, 1},
    separatorColor = {0.4, 0.4, 0.4, 1},
    titleColor = {1, 0.82, 0, 1},       -- Gold for menu title
    titleBgColor = {0.15, 0.12, 0.1, 0.9}, -- Dark brown/sepia, distinct from lavender hover
    sectionColor = {0.7, 0.7, 0.7, 1},  -- Light gray for section headers
    
    -- Dimensions
    itemHeight = 22,       -- Total height including padding
    itemPaddingV = 3,      -- Vertical padding per item (highlight encompasses this)
    titleHeight = 26,      -- Taller for title
    separatorHeight = 8,
    paddingH = 12,
    paddingV = 10,
    spacing = 0,
    minWidth = 120,
    iconSize = 14,
    iconPadding = 4,
    arrowWidth = 16,
    checkSize = 14,
}

local TIMEOUT = 1.5          -- Seconds before menu auto-closes when mouse leaves
local SUBMENU_TIMEOUT = 0.75 -- Seconds before submenu auto-closes when mouse leaves

-- Expose style for external reference if needed
menuRenderer.STYLE = STYLE

-- ============================================================================
-- STATE
-- ============================================================================

local menuPool = {}           -- Pool of reusable menu frames
local activeMenus = {}        -- Currently visible menus (root first, submenus after)
local currentConfig = nil     -- Current menu configuration
local anchorFrame = nil       -- Frame the menu is anchored to (for dropdown hover check)

-- ============================================================================
-- FORWARD DECLARATIONS
-- ============================================================================

local closeAllMenus
local buildMenu

-- ============================================================================
-- FRAME POOL
-- ============================================================================

--[[
  Get or create a menu frame from the pool
]]
local function acquireMenuFrame()
    local frame = table.remove(menuPool)
    if not frame then
        frame = CreateFrame("Frame", nil, UIParent)
        frame:SetFrameStrata("FULLSCREEN_DIALOG")
        frame:SetClampedToScreen(true)
        frame:EnableMouse(true)  -- Block clicks from passing through gaps
        
        -- Background as plain texture
        frame.bg = frame:CreateTexture(nil, "BACKGROUND")
        frame.bg:SetAllPoints()
        frame.bg:SetColorTexture(unpack(STYLE.bgColor))
        
        -- Border as separate frame with only edgeFile
        frame.border = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        frame.border:SetAllPoints()
        frame.border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        frame.border:SetBackdropBorderColor(unpack(STYLE.borderColor))
        
        frame.items = {}
        frame.isSubmenu = false
    else
        -- Clear any stale anchors from previous use
        frame:ClearAllPoints()
    end
    
    frame:Show()
    table.insert(activeMenus, frame)
    return frame
end

--[[
  Return a menu frame to the pool
]]
local function releaseMenuFrame(frame)
    frame:Hide()
    frame:ClearAllPoints()
    frame:SetScript("OnUpdate", nil)
    
    -- Hide all item frames and clear handlers
    for _, item in ipairs(frame.items) do
        item:Hide()
        item:SetScript("OnEnter", nil)
        item:SetScript("OnLeave", nil)
        item:SetScript("OnClick", nil)
        if item.submenuFrame then
            releaseMenuFrame(item.submenuFrame)
            item.submenuFrame = nil
        end
    end
    
    -- Remove from active list
    for i, m in ipairs(activeMenus) do
        if m == frame then
            table.remove(activeMenus, i)
            break
        end
    end
    
    table.insert(menuPool, frame)
end

-- ============================================================================
-- MOUSE/TIMEOUT DETECTION
-- ============================================================================

--[[
  Check if mouse is over any active menu or the anchor frame
]]
local function isMouseOverMenus()
    for _, menu in ipairs(activeMenus) do
        if menu:IsMouseOver() then
            return true
        end
    end
    -- Also check anchor frame (dropdown button)
    if anchorFrame and anchorFrame:IsMouseOver() then
        return true
    end
    return false
end

--[[
  Setup OnUpdate for timeout and click-outside detection
  Only runs on root menu
]]
local function setupMenuWatcher(menu)
    local timeOff = 0
    
    menu:SetScript("OnUpdate", function(self, elapsed)
        local mouseOver = isMouseOverMenus()
        
        -- Timeout logic
        if mouseOver then
            timeOff = 0
        else
            timeOff = timeOff + elapsed
            if timeOff >= TIMEOUT then
                closeAllMenus()
                return
            end
        end
        
        -- Click-outside detection
        if IsMouseButtonDown("LeftButton") and not mouseOver then
            closeAllMenus()
        end
    end)
end

-- ============================================================================
-- CLOSE ALL MENUS
-- ============================================================================

closeAllMenus = function()
    -- Release all menus (copy list since releaseMenuFrame modifies it)
    local toRelease = {}
    for _, menu in ipairs(activeMenus) do
        table.insert(toRelease, menu)
    end
    for _, menu in ipairs(toRelease) do
        releaseMenuFrame(menu)
    end
    
    currentConfig = nil
    anchorFrame = nil
end

-- ============================================================================
-- ITEM CREATION
-- ============================================================================

--[[
  Get or create a standard item frame for a menu
]]
local function acquireItemFrame(menuFrame, index)
    local item = menuFrame.items[index]
    if not item then
        item = CreateFrame("Button", nil, menuFrame)
        item:SetHeight(STYLE.itemHeight)
        
        -- Highlight texture (solid lavender)
        item.highlight = item:CreateTexture(nil, "BACKGROUND")
        item.highlight:SetAllPoints()
        item.highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
        item.highlight:SetGradient("HORIZONTAL",
            CreateColor(0.4, 0.3, 0.6, 0.8),
            CreateColor(0.4, 0.3, 0.6, 0.1))
        item.highlight:Hide()
        
        -- Icon
        item.icon = item:CreateTexture(nil, "ARTWORK")
        item.icon:SetSize(STYLE.iconSize, STYLE.iconSize)
        item.icon:SetPoint("LEFT", item, "LEFT", 0, 0)
        item.icon:Hide()
        
        -- Check mark
        item.check = item:CreateTexture(nil, "ARTWORK")
        item.check:SetSize(STYLE.checkSize, STYLE.checkSize)
        item.check:SetPoint("LEFT", item, "LEFT", 0, 0)
        item.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        item.check:Hide()
        
        -- Text
        item.text = item:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        item.text:SetPoint("LEFT", item, "LEFT", 0, 0)
        item.text:SetJustifyH("LEFT")
        
        -- Submenu arrow
        item.arrow = item:CreateTexture(nil, "ARTWORK")
        item.arrow:SetSize(16, 16)
        item.arrow:SetPoint("RIGHT", item, "RIGHT", 0, 0)
        item.arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
        item.arrow:Hide()
        
        -- Separator line (created but hidden by default)
        item.separator = item:CreateTexture(nil, "ARTWORK")
        item.separator:SetHeight(1)
        item.separator:SetPoint("LEFT", item, "LEFT", 0, 0)
        item.separator:SetPoint("RIGHT", item, "RIGHT", 0, 0)
        item.separator:SetColorTexture(unpack(STYLE.separatorColor))
        item.separator:Hide()
        
        menuFrame.items[index] = item
    end
    
    -- Reset state
    item:Show()
    item:EnableMouse(true)
    item:SetHeight(STYLE.itemHeight)
    item.highlight:Hide()
    item.icon:Hide()
    item.check:Hide()
    item.arrow:Hide()
    item.separator:Hide()
    if item.headerBg then
        item.headerBg:Hide()
    end
    if item.titleSeparator then
        item.titleSeparator:Hide()
    end
    item.text:SetText("")
    item.text:SetFontObject("GameFontHighlightSmall")  -- Reset to default font
    item.text:SetTextColor(unpack(STYLE.textColor))
    item.text:ClearAllPoints()
    item.text:SetPoint("LEFT", item, "LEFT", 0, 0)
    item.isDisabled = false
    item.submenuDef = nil
    item.submenuFrame = nil
    item.itemDef = nil
    item.keepOpen = false
    
    return item
end

--[[
  Render a separator item
]]
local function renderSeparator(menuFrame, index, yOffset)
    local item = acquireItemFrame(menuFrame, index)
    item:SetHeight(STYLE.separatorHeight)
    item:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", STYLE.paddingH, -yOffset)
    item:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -STYLE.paddingH, -yOffset)
    item:EnableMouse(false)
    item.separator:Show()
    
    return STYLE.separatorHeight
end

--[[
  Render a header item (title or section header)
  @param isTitle boolean - True if this is the menu title (first header)
]]
local function renderHeader(menuFrame, index, itemDef, yOffset, isTitle)
    local item = acquireItemFrame(menuFrame, index)
    local itemHeight = isTitle and STYLE.titleHeight or STYLE.itemHeight
    
    item:SetHeight(itemHeight)
    item:EnableMouse(false)  -- Non-interactive
    
    if isTitle then
        -- Title spans full menu width (no horizontal padding)
        item:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 0, -yOffset)
        item:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", 0, -yOffset)
        
        -- Background for title
        if not item.headerBg then
            item.headerBg = item:CreateTexture(nil, "BACKGROUND", nil, 1)
            item.headerBg:SetAllPoints()
        end
        item.headerBg:SetColorTexture(unpack(STYLE.titleBgColor))
        item.headerBg:Show()
        
        -- Separator line at bottom of title
        if not item.titleSeparator then
            item.titleSeparator = item:CreateTexture(nil, "ARTWORK")
            item.titleSeparator:SetHeight(1)
            item.titleSeparator:SetPoint("BOTTOMLEFT", item, "BOTTOMLEFT", 0, 0)
            item.titleSeparator:SetPoint("BOTTOMRIGHT", item, "BOTTOMRIGHT", 0, 0)
            item.titleSeparator:SetColorTexture(unpack(STYLE.borderColor))
        end
        item.titleSeparator:Show()
        
        -- Text with padding (matches item text position)
        item.text:ClearAllPoints()
        item.text:SetPoint("LEFT", item, "LEFT", STYLE.paddingH, 0)
        item.text:SetFontObject("GameFontNormal")
        item.text:SetTextColor(unpack(STYLE.titleColor))
    else
        -- Section header uses normal item padding
        item:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", STYLE.paddingH, -yOffset)
        item:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -STYLE.paddingH, -yOffset)
        
        if item.headerBg then
            item.headerBg:Hide()
        end
        if item.titleSeparator then
            item.titleSeparator:Hide()
        end
        
        item.text:ClearAllPoints()
        item.text:SetPoint("LEFT", item, "LEFT", 0, 0)
        item.text:SetFontObject("GameFontHighlightSmall")
        item.text:SetTextColor(unpack(STYLE.sectionColor))
    end
    item.text:SetText(itemDef.text or "")
    
    -- No hover, no click
    item:SetScript("OnEnter", nil)
    item:SetScript("OnLeave", nil)
    item:SetScript("OnClick", nil)
    
    return itemHeight
end

--[[
  Render a menu item (standard or custom)
  Handles both built-in rendering and custom renderRow callback
]]
local function renderItem(menuFrame, index, itemDef, yOffset, width, menuConfig)
    local item = acquireItemFrame(menuFrame, index)
    local context = currentConfig and currentConfig.context or {}
    local itemHeight = menuConfig.rowHeight or STYLE.itemHeight
    local hasCustomRender = menuConfig.renderRow ~= nil
    
    -- Common setup
    item:SetHeight(itemHeight)
    item:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 0, -yOffset)
    item:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", 0, -yOffset)
    item.itemDef = itemDef
    item.keepOpen = menuConfig.keepOpenOnClick or false
    
    -- Disabled state
    local disabled = itemDef.disabled
    if type(disabled) == "function" then
        disabled = disabled(context)
    end
    item.isDisabled = disabled
    
    -- Content rendering
    if hasCustomRender then
        -- Custom: delegate to callback
        local isHighlighted = itemDef.value == menuConfig.highlightValue
        menuConfig.renderRow(item, itemDef, isHighlighted)
    else
        -- Standard: icon, check, text, arrow
        local textOffset = STYLE.paddingH
        
        -- Icon
        if itemDef.icon then
            item.icon:ClearAllPoints()
            item.icon:SetPoint("LEFT", item, "LEFT", STYLE.paddingH, 0)
            item.icon:SetTexture(itemDef.icon)
            if itemDef.iconCoords then
                item.icon:SetTexCoord(unpack(itemDef.iconCoords))
            else
                item.icon:SetTexCoord(0, 1, 0, 1)
            end
            item.icon:Show()
            textOffset = STYLE.paddingH + STYLE.iconSize + STYLE.iconPadding
        end
        
        -- Checkmark
        if itemDef.checkable or itemDef.checked ~= nil then
            local checked = itemDef.checked
            if type(checked) == "function" then
                checked = checked(context)
            end
            if checked then
                item.check:ClearAllPoints()
                item.check:SetPoint("LEFT", item, "LEFT", STYLE.paddingH, 0)
                item.check:Show()
            end
            textOffset = STYLE.paddingH + STYLE.checkSize + STYLE.iconPadding
        end
        
        -- Text positioning
        item.text:ClearAllPoints()
        item.text:SetPoint("LEFT", item, "LEFT", textOffset, 0)
        item.text:SetText(itemDef.text or "")
        
        if disabled then
            item.text:SetTextColor(unpack(STYLE.disabledColor))
        end
        
        -- Submenu arrow
        if itemDef.submenu then
            item.arrow:ClearAllPoints()
            item.arrow:SetPoint("RIGHT", item, "RIGHT", -STYLE.paddingH, 0)
            item.arrow:Show()
            item.submenuDef = itemDef.submenu
            item.text:SetPoint("RIGHT", item.arrow, "LEFT", -4, 0)
        else
            item.text:SetPoint("RIGHT", item, "RIGHT", -STYLE.paddingH, 0)
        end
    end
    
    -- Hover behavior
    item:SetScript("OnEnter", function(self)
        if not self.isDisabled then
            self.highlight:Show()
        end
        
        -- Close any sibling submenus
        for _, otherItem in ipairs(menuFrame.items) do
            if otherItem ~= self and otherItem.submenuFrame then
                releaseMenuFrame(otherItem.submenuFrame)
                otherItem.submenuFrame = nil
            end
        end
        
        -- Open submenu if this item has one
        if self.submenuDef and not self.isDisabled then
            local submenuFrame = buildMenu({
                items = self.submenuDef,
                spacing = menuConfig.spacing,
                rowHeight = menuConfig.rowHeight,
                renderRow = menuConfig.renderRow,
                keepOpenOnClick = menuConfig.keepOpenOnClick,
            }, true)  -- true = is submenu
            submenuFrame:ClearAllPoints()
            submenuFrame:SetPoint("TOPLEFT", self, "TOPRIGHT", 2, STYLE.paddingV)
            self.submenuFrame = submenuFrame
            
            -- Setup submenu timeout watcher
            local parentItem = self
            local submenuTimeOff = 0
            submenuFrame:SetScript("OnUpdate", function(subFrame, elapsed)
                -- Stay open if mouse is over submenu OR the parent item that opened it
                if subFrame:IsMouseOver() or parentItem:IsMouseOver() then
                    submenuTimeOff = 0
                else
                    submenuTimeOff = submenuTimeOff + elapsed
                    if submenuTimeOff >= SUBMENU_TIMEOUT then
                        releaseMenuFrame(subFrame)
                        parentItem.submenuFrame = nil
                    end
                end
            end)
        end
    end)
    
    item:SetScript("OnLeave", function(self)
        self.highlight:Hide()
    end)
    
    -- Click behavior
    item:SetScript("OnClick", function(self)
        if self.isDisabled then return end
        if self.submenuDef then return end  -- Submenus don't trigger on click
        
        local def = self.itemDef
        local ctx = currentConfig and currentConfig.context or {}
        
        -- Call item callback
        if def.func then
            def.func(ctx)
        end
        
        -- Call menu-level callback
        if currentConfig and currentConfig.onItemClick then
            currentConfig.onItemClick(def, ctx)
        end
        
        -- Close unless keepOpenOnClick is set
        if not self.keepOpen then
            closeAllMenus()
        else
            -- Refresh checkmark state for checkbox mode
            if def.checked ~= nil then
                local checked = def.checked
                if type(checked) == "function" then
                    checked = checked(ctx)
                end
                if checked then
                    self.check:Show()
                else
                    self.check:Hide()
                end
            end
        end
    end)
    
    return itemHeight
end

-- ============================================================================
-- WIDTH CALCULATION
-- ============================================================================

--[[
  Calculate required width for menu items
]]
local function calculateMenuWidth(items, config)
    -- If explicit width provided, use it
    if config.menuWidth then
        return config.menuWidth
    end
    
    -- Create temporary font string for measurement
    local measureFrame = CreateFrame("Frame", nil, UIParent)
    local measureText = measureFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    
    local maxWidth = config.minWidth or STYLE.minWidth
    
    for _, item in ipairs(items) do
        if not item.separator and not item.isSeparator then
            measureText:SetText(item.text or "")
            local textWidth = measureText:GetStringWidth()
            
            -- Add icon space if needed
            if item.icon or item.checkable or item.checked ~= nil then
                textWidth = textWidth + STYLE.iconSize + STYLE.iconPadding
            end
            
            -- Add arrow space if submenu
            if item.submenu then
                textWidth = textWidth + STYLE.arrowWidth
            end
            
            maxWidth = math.max(maxWidth, textWidth)
        end
    end
    
    measureFrame:Hide()
    
    return maxWidth + (STYLE.paddingH * 2)
end

-- ============================================================================
-- MENU BUILDING
-- ============================================================================

--[[
  Build a menu frame from configuration
  
  @param config table - Menu configuration
  @param isSubmenu boolean - True if this is a submenu
  @return frame - The menu frame
]]
buildMenu = function(config, isSubmenu)
    local frame = acquireMenuFrame()
    frame.isSubmenu = isSubmenu or false
    
    local items = config.items or {}
    local spacing = config.spacing
    if spacing == nil then
        spacing = STYLE.spacing
    end
    
    -- Calculate width
    local width = calculateMenuWidth(items, config)
    
    -- Check if first item is a title header (starts at top edge)
    local firstIsTitle = items[1] and items[1].isHeader
    
    -- Build items
    local yOffset = firstIsTitle and 0 or STYLE.paddingV
    local itemIndex = 0
    local firstContentSeen = false  -- Track if we've seen first non-separator item
    
    for i, itemDef in ipairs(items) do
        itemIndex = itemIndex + 1
        
        -- Add spacing before item (except first and separators)
        if i > 1 and not itemDef.separator and not itemDef.isSeparator and spacing > 0 then
            yOffset = yOffset + spacing
        end
        
        local itemHeight
        if itemDef.separator or itemDef.isSeparator then
            itemHeight = renderSeparator(frame, itemIndex, yOffset)
        elseif itemDef.isHeader then
            -- First header = title, subsequent headers = section headers
            local isTitle = not firstContentSeen
            itemHeight = renderHeader(frame, itemIndex, itemDef, yOffset, isTitle)
            firstContentSeen = true
        else
            itemHeight = renderItem(frame, itemIndex, itemDef, yOffset, width, config)
            firstContentSeen = true
        end
        
        yOffset = yOffset + itemHeight
    end
    
    -- Hide unused items
    for j = itemIndex + 1, #frame.items do
        frame.items[j]:Hide()
    end
    
    -- Set frame size
    local height = yOffset + STYLE.paddingV
    frame:SetSize(width, height)
    
    -- Setup escape key handler
    frame:EnableKeyboard(true)
    frame:SetPropagateKeyboardInput(true)
    frame:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            closeAllMenus()
            self:SetPropagateKeyboardInput(false)
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)
    
    return frame
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Show a menu
  
  @param config table - Menu configuration:
    {
      anchor = frame or "cursor",       -- Where to anchor the menu
      anchorPoint = "TOPLEFT",          -- Anchor point (default TOPLEFT->BOTTOMLEFT)
      items = { ... },                  -- Menu items
      context = {},                     -- Context passed to callbacks
      spacing = 2,                      -- Pixels between items
      minWidth = 120,                   -- Minimum menu width
      menuWidth = nil,                  -- Explicit menu width (overrides calculation)
      rowHeight = 16,                   -- Height of each row
      renderRow = function(btn, item, isHighlighted),  -- Custom rendering
      highlightValue = any,             -- Value to highlight (for current selection)
      keepOpenOnClick = false,          -- For checkbox mode
      onItemClick = function(item, ctx),-- Called when any item clicked
      onClose = function(),             -- Called when menu closes
    }
  @return frame - The root menu frame
]]
function menuRenderer:show(config)
    -- Close any existing menus
    closeAllMenus()
    
    -- Store configuration
    currentConfig = config
    
    -- Store anchor frame for hover detection
    if config.anchor and config.anchor ~= "cursor" then
        anchorFrame = config.anchor
    else
        anchorFrame = nil
    end
    
    -- Build the menu
    local frame = buildMenu(config, false)
    
    -- Position menu
    if config.anchor == "cursor" then
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    elseif config.anchor then
        local point = config.anchorPoint or "TOPLEFT"
        local relPoint = config.anchorRelPoint or "BOTTOMLEFT"
        local xOff = config.anchorX or 0
        local yOff = config.anchorY or 0
        frame:SetPoint(point, config.anchor, relPoint, xOff, yOff)
    end
    
    -- Raise menu above normal UI
    frame:SetFrameStrata("TOOLTIP")
    
    -- Setup timeout and click-outside watcher
    setupMenuWatcher(frame)
    
    return frame
end

--[[
  Hide all menus
]]
function menuRenderer:hideAll()
    local config = currentConfig
    closeAllMenus()
    
    -- Call onClose callback if provided
    if config and config.onClose then
        config.onClose()
    end
end

--[[
  Check if mouse is over any active menu
  
  @return boolean
]]
function menuRenderer:isMouseOver()
    return isMouseOverMenus()
end

--[[
  Check if any menu is currently visible
  
  @return boolean
]]
function menuRenderer:isVisible()
    return #activeMenus > 0
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("menuRenderer", {}, function()
        return true
    end)
end

Addon.menuRenderer = menuRenderer
return menuRenderer