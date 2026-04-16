--[[
  ui/shared/dropdown.lua
  Dropdown Button Factory
  
  Creates dropdown buttons with popup menus.
  Supports single-select and multi-select (checkbox) modes.
  Uses menuRenderer for consistent popup styling.
  
  Usage:
    local dd = dropdown:create({
        parent = frame,
        width = 120,
        options = {
            { value = "a", text = "Option A", icon = 12345 },
            { value = "b", text = "Option B" },
            { isSeparator = true },
            { text = "Submenu", submenu = { ... } },
        },
        style = "none",  -- "checkbox" | "none"
        defaultValue = "a",
        onChange = function(value, option) end,
    })
    
    -- Split button mode (main action + dropdown)
    local split = dropdown:create({
        parent = frame,
        splitButton = true,
        onClick = function(btn) ... end,  -- Main button action
        onChange = function(value, opt) ... end,  -- Dropdown selection
        ...
    })
    
    -- Custom row rendering
    local custom = dropdown:create({
        parent = frame,
        renderRow = function(btn, option, isHighlighted) ... end,
        rowHeight = 48,
        ...
    })
  
  Dependencies: menuRenderer
  Exports: Addon.dropdown
]]

local ADDON_NAME, Addon = ...

local dropdown = {}

-- Module reference
local menuRenderer

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local DEFAULTS = {
    width = 120,
    height = 30,
    style = "none",  -- "checkbox" | "none"
}

local STYLE = {
    bgColor = {0.15, 0.15, 0.18, 1.0},        -- Slightly lighter, fully opaque
    bgColorHover = {0.2, 0.2, 0.23, 1.0},
    borderColor = {0.5, 0.5, 0.55, 1},        -- Brighter border for visibility
    borderColorHover = {0.6, 0.6, 0.65, 1},
    textColor = {1, 1, 1, 1},
    disabledTextColor = {0.5, 0.5, 0.5, 1},
    iconSize = 16,
    arrowSize = 14,
    padding = 4,
    textPadding = 6,
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function getRenderer()
    if not menuRenderer then
        menuRenderer = Addon.menuRenderer
        if not menuRenderer then
            error("dropdown requires menuRenderer module")
        end
    end
    return menuRenderer
end

local function findOptionByValue(options, value)
    for _, opt in ipairs(options) do
        if opt.value == value then
            return opt
        end
        if opt.submenu then
            local found = findOptionByValue(opt.submenu, value)
            if found then return found end
        end
    end
    return nil
end

local function tableContains(tbl, value)
    if not tbl then return false end
    for _, v in ipairs(tbl) do
        if v == value then return true end
    end
    return false
end

local function tableRemove(tbl, value)
    for i, v in ipairs(tbl) do
        if v == value then
            table.remove(tbl, i)
            return
        end
    end
end

local function shallowCopy(tbl)
    if not tbl then return {} end
    local copy = {}
    for i, v in ipairs(tbl) do
        copy[i] = v
    end
    return copy
end

-- ============================================================================
-- DROPDOWN CREATION
-- ============================================================================

--[[
  Create a dropdown button.
  
  @param config table - Configuration:
    parent          frame (required)  Parent frame
    name            string            Optional frame name
    width           number            Button width (default 120)
    height          number            Button height (default 30)
    options         table             Array of option items
    style           string            "none" or "checkbox" (default "none")
    defaultValue    any               Initial value (or table for checkbox)
    placeholder     string            Text when no selection
    alwaysShowPlaceholder boolean     Always show placeholder (ignore selection)
    icon            boolean           Show icon in button
    iconSize        number            Icon size (default 16)
    tooltip         string            Button tooltip
    splitButton     boolean           Split button mode
    onClick         function(btn)     Main button click (splitButton mode)
    onChange        function(value, option)  Selection changed
    renderRow       function(btn, option, isHighlighted)  Custom row rendering
    rowHeight       number            Row height for custom rendering
    menuWidth       number            Explicit menu width
    maxRows         number            Max visible rows (unused, for API compat)
    
  @return frame - Dropdown button with methods
]]
function dropdown:create(config)
    if not config or not config.parent then
        error("dropdown:create requires config.parent")
    end
    
    local width = config.width or DEFAULTS.width
    local height = config.height or DEFAULTS.height
    local style = config.style or DEFAULTS.style
    local hasIcon = config.icon == true
    local iconSize = config.iconSize or STYLE.iconSize
    local splitButton = config.splitButton == true
    local alwaysShowPlaceholder = config.alwaysShowPlaceholder == true
    local options = config.options or {}
    
    -- Initialize value based on style
    local currentValue
    if style == "checkbox" then
        currentValue = config.defaultValue and shallowCopy(config.defaultValue) or {}
    else
        currentValue = config.defaultValue or (options[1] and options[1].value)
    end
    
    -- Create button frame
    local name = config.name or (ADDON_NAME .. "Dropdown" .. tostring(math.random(100000)))
    local btn = CreateFrame("Button", name, config.parent)
    btn:SetSize(width, height)
    
    -- Background
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(STYLE.bgColor))
    btn.background = bg
    
    -- Border
    local border = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    border:SetAllPoints()
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    border:SetBackdropBorderColor(unpack(STYLE.borderColor))
    btn.border = border
    
    -- Calculate text position
    local textLeft = STYLE.textPadding
    local textRight = -(STYLE.arrowSize + STYLE.padding)
    
    -- Icon (optional)
    if hasIcon then
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(iconSize, iconSize)
        icon:SetPoint("LEFT", btn, "LEFT", STYLE.padding, 0)
        btn.icon = icon
        textLeft = STYLE.padding + iconSize + 4
    end
    
    -- Text
    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", btn, "LEFT", textLeft, 0)
    text:SetPoint("RIGHT", btn, "RIGHT", textRight, 0)
    text:SetJustifyH("LEFT")
    text:SetTextColor(unpack(STYLE.textColor))
    btn.text = text
    
    -- Arrow
    local arrow = btn:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(STYLE.arrowSize, STYLE.arrowSize)
    arrow:SetPoint("RIGHT", btn, "RIGHT", -STYLE.padding + 1, 0)
    arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    arrow:SetTexCoord(0.25, 0.75, 0.25, 0.75)
    btn.arrow = arrow
    
    -- Highlight overlay
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.05)
    
    -- ========================================================================
    -- STATE
    -- ========================================================================
    
    btn._options = options
    btn._style = style
    btn._currentValue = currentValue
    btn._config = config
    btn._enabled = true
    btn._splitButton = splitButton
    btn._iconSize = iconSize
    
    -- ========================================================================
    -- DISPLAY UPDATE
    -- ========================================================================
    
    local function updateDisplay()
        -- Split button mode OR alwaysShowPlaceholder: Always show placeholder
        if splitButton or alwaysShowPlaceholder then
            text:SetText(config.placeholder or "Select...")
            if hasIcon and btn.icon then
                btn.icon:Hide()
            end
            return
        end
        
        if style == "checkbox" then
            local count = #btn._currentValue
            if count == 0 then
                text:SetText(config.placeholder or "Select...")
            elseif count == 1 then
                local opt = findOptionByValue(btn._options, btn._currentValue[1])
                text:SetText(opt and (opt.displayText or opt.text) or "1 selected")
            else
                text:SetText(count .. " selected")
            end
        else
            local opt = findOptionByValue(btn._options, btn._currentValue)
            if opt then
                text:SetText(opt.displayText or opt.text)
                if hasIcon and btn.icon then
                    if opt.icon then
                        btn.icon:SetTexture(opt.icon)
                        btn.icon:Show()
                    else
                        btn.icon:Hide()
                    end
                end
            else
                text:SetText(config.placeholder or "Select...")
                if hasIcon and btn.icon then
                    btn.icon:Hide()
                end
            end
        end
    end
    
    -- ========================================================================
    -- MENU DISPLAY
    -- ========================================================================
    
    local function buildMenuItems(optionsList, levelStyle)
        local items = {}
        local opts = optionsList or btn._options
        local currentStyle = levelStyle or style  -- Use passed style or top-level default
        local isTopLevel = (optionsList == nil)
        
        -- Prepend title header at top level if config.title is set
        if isTopLevel and config.title then
            table.insert(items, {
                text = config.title,
                isHeader = true,
            })
        end
        
        for _, opt in ipairs(opts) do
            local item = {
                text = opt.text,
                value = opt.value,
                icon = opt.icon,
                iconCoords = opt.iconCoords,
                disabled = opt.disabled,
                color = opt.color,
                -- For custom renderRow
                petName = opt.petName,
                breed = opt.breed,
                level = opt.level,
                familyName = opt.familyName,
                familyIcon = opt.familyIcon,
                slot = opt.slot,
            }
            
            -- Handle separator
            if opt.isSeparator then
                item.separator = true
            end
            
            -- Handle submenu - use submenu's declared style or default to "none"
            if opt.submenu then
                local submenuStyle = opt.submenu.style or "none"
                item.submenu = buildMenuItems(opt.submenu, submenuStyle)
            end
            
            -- Handle checkbox style (for items without submenus)
            if currentStyle == "checkbox" and not opt.submenu and not opt.isSeparator then
                item.checkable = true
                item.checked = function()
                    return tableContains(btn._currentValue, opt.value)
                end
                item.func = function()
                    if tableContains(btn._currentValue, opt.value) then
                        tableRemove(btn._currentValue, opt.value)
                    else
                        table.insert(btn._currentValue, opt.value)
                    end
                    updateDisplay()
                    if config.onChange then
                        config.onChange(shallowCopy(btn._currentValue), opt)
                    end
                end
            elseif not opt.submenu and not opt.isSeparator then
                -- Standard selection (for non-checkbox or submenu parent)
                item.func = function()
                    btn._currentValue = opt.value
                    updateDisplay()
                    if config.onChange then
                        config.onChange(opt.value, opt)
                    end
                end
            end
            -- Note: submenu parents have no func - clicking just opens submenu
            
            table.insert(items, item)
        end
        
        return items
    end
    
    local function showMenu()
        local renderer = getRenderer()
        
        -- Close if already open
        if renderer:isVisible() then
            renderer:hideAll()
            return
        end
        
        local menuConfig = {
            anchor = btn,
            anchorPoint = "TOPLEFT",
            anchorRelPoint = "BOTTOMLEFT",
            anchorX = 0,
            anchorY = 0,
            items = buildMenuItems(),
            spacing = 2,
            menuWidth = config.menuWidth,
            rowHeight = config.rowHeight,
            renderRow = config.renderRow,
            highlightValue = btn._currentValue,
            keepOpenOnClick = (style == "checkbox"),
        }
        
        renderer:show(menuConfig)
    end
    
    -- ========================================================================
    -- EVENT HANDLERS
    -- ========================================================================
    
    btn:SetScript("OnClick", function(self, button)
        if not btn._enabled then return end
        
        -- Split button mode: Detect which area was clicked
        if splitButton then
            local arrowAreaWidth = STYLE.arrowSize + (STYLE.padding * 2) + 4
            local buttonWidth = self:GetWidth()
            local cursorX = GetCursorPosition()
            local scale = self:GetEffectiveScale()
            local left = self:GetLeft()
            
            local leftPixels = left * scale
            local buttonWidthPixels = buttonWidth * scale
            local clickX = cursorX - leftPixels
            
            local inArrowArea = clickX > (buttonWidthPixels - arrowAreaWidth)
            
            if not inArrowArea and config.onClick then
                config.onClick(self, button)
                return
            end
        else
            -- Non-split mode: Check custom click handler
            if config.onClick then
                local showMenuResult = config.onClick(self, button)
                if showMenuResult == false then
                    return
                end
            end
        end
        
        showMenu()
    end)
    
    btn:SetScript("OnEnter", function(self)
        if not btn._enabled then return end
        bg:SetColorTexture(unpack(STYLE.bgColorHover))
        border:SetBackdropBorderColor(unpack(STYLE.borderColorHover))
        
        if config.tooltip then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(config.tooltip, 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    
    btn:SetScript("OnLeave", function(self)
        bg:SetColorTexture(unpack(STYLE.bgColor))
        border:SetBackdropBorderColor(unpack(STYLE.borderColor))
        
        if config.tooltip then
            GameTooltip:Hide()
        end
    end)
    
    -- ========================================================================
    -- PUBLIC METHODS
    -- ========================================================================
    
    --[[
      Get current value.
      @return any - Single value for none style, table of values for checkbox
    ]]
    function btn:GetValue()
        if btn._style == "checkbox" then
            return shallowCopy(btn._currentValue)
        end
        return btn._currentValue
    end
    
    --[[
      Set value programmatically.
      @param value any - Single value or table for checkbox
      @param silent boolean - If true, don't trigger onChange
    ]]
    function btn:SetValue(value, silent)
        if btn._style == "checkbox" then
            btn._currentValue = value and shallowCopy(value) or {}
        else
            btn._currentValue = value
        end
        updateDisplay()
        
        if not silent and config.onChange then
            if btn._style == "checkbox" then
                config.onChange(shallowCopy(btn._currentValue), nil)
            else
                local opt = findOptionByValue(btn._options, value)
                config.onChange(value, opt)
            end
        end
    end
    
    --[[
      Replace options list.
      @param newOptions table - New options array
    ]]
    function btn:SetOptions(newOptions)
        btn._options = newOptions or {}
        
        -- Validate current value still exists
        if btn._style == "checkbox" then
            local validValues = {}
            for _, v in ipairs(btn._currentValue) do
                if findOptionByValue(btn._options, v) then
                    table.insert(validValues, v)
                end
            end
            btn._currentValue = validValues
        else
            if not findOptionByValue(btn._options, btn._currentValue) then
                btn._currentValue = btn._options[1] and btn._options[1].value
            end
        end
        
        updateDisplay()
    end
    
    --[[
      Enable or disable the dropdown.
      @param enabled boolean
    ]]
    function btn:SetEnabled(enabled)
        btn._enabled = enabled
        if enabled then
            btn:Enable()
            text:SetTextColor(unpack(STYLE.textColor))
            arrow:SetDesaturated(false)
            arrow:SetAlpha(1)
        else
            btn:Disable()
            text:SetTextColor(unpack(STYLE.disabledTextColor))
            arrow:SetDesaturated(true)
            arrow:SetAlpha(0.5)
        end
    end
    
    --[[
      Refresh display from current value.
    ]]
    function btn:Refresh()
        updateDisplay()
    end
    
    -- Initial display
    updateDisplay()
    
    return btn
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("dropdown", {"menuRenderer"}, function()
        return true
    end)
end

Addon.dropdown = dropdown
return dropdown