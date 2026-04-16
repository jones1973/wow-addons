--[[
  ui/shared/dropdownLegacy.lua
  Legacy Dropdown with Split Button Support
  
  Preserved for notifications.lua celebration popup which uses splitButton mode
  with custom renderRow and mainBtn access. Will be consolidated into main 
  dropdown.lua later.
  
  Dependencies: none
  Exports: Addon.dropdownLegacy
]]

local ADDON_NAME, Addon = ...

local dropdownLegacy = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local DEFAULTS = {
    width = 120,
    height = 30,
    style = "none",  -- "checkbox" | "radio" | "none"
}

-- Visual style (single source of truth)
local STYLE = {
    bgColor = { 0.1, 0.1, 0.1, 0.8 },
    bgColorHover = { 0.15, 0.15, 0.15, 0.9 },
    borderColor = { 0.4, 0.4, 0.4, 1 },
    borderColorHover = { 0.5, 0.5, 0.5, 1 },
    textColor = { 1, 1, 1, 1 },
    iconSize = 16,
    arrowSize = 14,
    padding = 4,
    textPadding = 6,
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

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
  
  @param config table - See module header for full documentation
  @return frame - Dropdown button with methods
]]
function dropdownLegacy:create(config)
    if not config or not config.parent then
        error("dropdownLegacy:create requires config.parent")
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
    
    -- Background (for hover effects)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(STYLE.bgColor))
    btn.background = bg
    
    -- Border with background (BackdropTemplate - matches textBox style)
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
    btn._menu = nil
    btn._enabled = true
    btn._splitButton = splitButton
    btn._iconSize = iconSize
    
    -- ========================================================================
    -- DISPLAY UPDATE
    -- ========================================================================
    
    local function updateDisplay()
        -- Split button mode OR alwaysShowPlaceholder: Always show placeholder (primary action text)
        if splitButton or alwaysShowPlaceholder then
            text:SetText(config.placeholder or "Action")
            if hasIcon and btn.icon then
                btn.icon:Hide()  -- No icon in split/placeholder mode
            end
            return
        end
        
        if style == "checkbox" then
            local count = #btn._currentValue
            if count == 0 then
                text:SetText(config.placeholder or "Select...")
            elseif count == 1 then
                local opt = findOptionByValue(btn._options, btn._currentValue[1])
                text:SetText(opt and opt.text or "1 selected")
            else
                text:SetText(count .. " selected")
            end
            -- No icon update for checkbox style
        else
            local opt = findOptionByValue(btn._options, btn._currentValue)
            if opt then
                text:SetText(opt.text)
                if hasIcon and btn.icon then
                    if opt.icon then
                        btn.icon:SetTexture(opt.icon)
                        btn.icon:Show()
                    else
                        btn.icon:Hide()
                    end
                end
            end
        end
    end
    
    -- ========================================================================
    -- MENU CREATION
    -- ========================================================================
    
    local function initializeMenu(frame, level, menuList)
        level = level or 1
        local opts = menuList or btn._options
        
        for _, opt in ipairs(opts) do
            -- Handle separators
            if opt.isSeparator then
                UIDropDownMenu_AddSeparator(level)
            else
                local info = UIDropDownMenu_CreateInfo()
                info.text = opt.text
                info.value = opt.value
                
                -- Icon
                if opt.icon then
                    info.icon = opt.icon
                    info.tCoordLeft = 0
                    info.tCoordRight = 1
                    info.tCoordTop = 0
                    info.tCoordBottom = 1
                end
                
                -- Submenu
                if opt.submenu then
                    info.hasArrow = true
                    info.menuList = opt.submenu
                    info.notCheckable = true
                else
                    -- Selection style
                    if style == "checkbox" then
                        info.isNotRadio = true
                        info.checked = tableContains(btn._currentValue, opt.value)
                        info.keepShownOnClick = true
                        info.func = function(self)
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
                    elseif style == "radio" then
                        info.isNotRadio = false
                        info.checked = (btn._currentValue == opt.value)
                        info.func = function()
                            btn._currentValue = opt.value
                            updateDisplay()
                            CloseDropDownMenus()
                            if config.onChange then
                                config.onChange(opt.value, opt)
                            end
                        end
                    else -- "none"
                        info.notCheckable = true
                        info.func = function()
                            btn._currentValue = opt.value
                            updateDisplay()
                            CloseDropDownMenus()
                            if config.onChange then
                                config.onChange(opt.value, opt)
                            end
                        end
                    end
                end
                
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end
    
    local function showMenu()
        local menuName = name .. "Menu"
        
        -- If our menu is already open, close it
        if UIDROPDOWNMENU_OPEN_MENU and UIDROPDOWNMENU_OPEN_MENU:GetName() == menuName then
            CloseDropDownMenus()
            return
        end
        
        if not btn._menu then
            btn._menu = CreateFrame("Frame", menuName, UIParent, "UIDropDownMenuTemplate")
        end
        
        UIDropDownMenu_Initialize(btn._menu, initializeMenu, "MENU")
        ToggleDropDownMenu(1, nil, btn._menu, btn, 0, 0)
        
        -- Auto-close after 1 second if cursor not over menu OR button
        if btn._autoCloseTimer then
            btn._autoCloseTimer:Cancel()
        end
        btn._autoCloseTimer = C_Timer.NewTimer(1, function()
            if UIDROPDOWNMENU_OPEN_MENU and UIDROPDOWNMENU_OPEN_MENU:GetName() == menuName then
                -- Only close if mouse not over the menu or button
                local menu = _G["DropDownList1"]
                if menu and not menu:IsMouseOver() and not btn:IsMouseOver() then
                    CloseDropDownMenus()
                end
            end
        end)
    end
    
    -- ========================================================================
    -- EVENT HANDLERS
    -- ========================================================================
    
    btn:SetScript("OnClick", function(self, button)
        if not btn._enabled then return end
        
        -- Split button mode: Detect which area was clicked
        if splitButton then
            -- Calculate arrow area bounds (right side of button)
            local arrowAreaWidth = STYLE.arrowSize + (STYLE.padding * 2) + 4  -- Arrow + padding + margin
            local buttonWidth = self:GetWidth()
            local cursorX = GetCursorPosition()
            local scale = self:GetEffectiveScale()
            local left = self:GetLeft()
            
            -- Convert UI coordinates to pixels for comparison
            local leftPixels = left * scale
            local buttonWidthPixels = buttonWidth * scale
            local clickX = cursorX - leftPixels
            
            -- Check if click is in arrow area (right side)
            local inArrowArea = clickX > (buttonWidthPixels - arrowAreaWidth)
            
            if not inArrowArea and config.onClick then
                -- Clicked main button area - execute primary action
                config.onClick(self, button)
                return  -- Don't show menu
            end
            -- Clicked arrow area - fall through to show menu
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
      @return any - Single value for radio/none, table of values for checkbox
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
            text:SetTextColor(0.5, 0.5, 0.5, 1)
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
-- CUSTOM DROPDOWN (No UIDropDownMenu)
-- ============================================================================

function dropdownLegacy:createCustom(config)
  local parent = config.parent
  local width = config.width or 120
  local height = config.height or 24
  local maxRows = config.maxRows or 10
  local rowHeight = config.rowHeight or 32
  local iconSize = config.iconSize or 24
  local options = config.options or {}
  local defaultValue = config.defaultValue
  local placeholder = config.placeholder or "Select..."
  local onChange = config.onChange
  local onShiftClick = config.onShiftClick
  local onClick = config.onClick
  local splitButton = config.splitButton or false
  local renderRow = config.renderRow
  local configMenuWidth = config.menuWidth  -- Explicit menu width override
  
  -- Container frame (what gets returned)
  local container = CreateFrame("Frame", nil, parent)
  container:SetSize(width, height)
  
  local mainBtn, arrowBtn, text
  
  if splitButton then
    -- SPLIT BUTTON MODE: Two separate buttons
    
    local arrowWidth = 26
    local dividerWidth = 1
    local dividerGap = 2  -- Gap on each side of divider
    local mainWidth = width - arrowWidth - dividerWidth - (dividerGap * 2)
    
    -- Main button (left side) - triggers primary action
    mainBtn = CreateFrame("Button", nil, container)
    mainBtn:SetSize(mainWidth, height)
    mainBtn:SetPoint("LEFT", container, "LEFT", 0, 0)
    
    local mainBg = mainBtn:CreateTexture(nil, "BACKGROUND")
    mainBg:SetAllPoints()
    mainBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    mainBtn.bg = mainBg
    
    local mainHighlight = mainBtn:CreateTexture(nil, "HIGHLIGHT")
    mainHighlight:SetAllPoints()
    mainHighlight:SetColorTexture(1, 1, 1, 0.1)
    
    mainBtn:SetScript("OnClick", function(self, button)
      if IsShiftKeyDown() and onShiftClick then
        onShiftClick()
      elseif onClick then
        onClick(self, button)
      end
    end)
    
    -- Divider (visual separator)
    local divider = container:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.7, 0.7, 0.7, 1)
    divider:SetSize(dividerWidth, height - 4)
    divider:SetPoint("LEFT", mainBtn, "RIGHT", dividerGap, 0)  -- Gap on left side
    container.divider = divider
    
    -- Arrow button (right side) - opens menu
    arrowBtn = CreateFrame("Button", nil, container)
    arrowBtn:SetSize(arrowWidth, height)
    arrowBtn:SetPoint("LEFT", divider, "RIGHT", dividerGap, 0)  -- Gap on right side
    
    local arrowBg = arrowBtn:CreateTexture(nil, "BACKGROUND")
    arrowBg:SetAllPoints()
    arrowBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    arrowBtn.bg = arrowBg
    
    local arrowHighlight = arrowBtn:CreateTexture(nil, "HIGHLIGHT")
    arrowHighlight:SetAllPoints()
    arrowHighlight:SetColorTexture(1, 1, 1, 0.1)
    
    local arrow = arrowBtn:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(20, 20)
    arrow:SetPoint("CENTER", arrowBtn, "CENTER", 0, 0)
    arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    arrow:SetTexCoord(0.25, 0.75, 0.25, 0.75)
    arrowBtn.arrow = arrow
    
    -- Shared border around both buttons
    local border = CreateFrame("Frame", nil, container, "BackdropTemplate")
    border:SetAllPoints()
    border:SetBackdrop({
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    container.border = border
    
    -- Text on main button (centered)
    text = mainBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", mainBtn, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetTextColor(1, 1, 1, 1)
    text:SetText(placeholder)
    
    container.mainBtn = mainBtn
    container.arrowBtn = arrowBtn
    
  else
    -- REGULAR DROPDOWN MODE: Single button
    
    mainBtn = CreateFrame("Button", nil, container)
    mainBtn:SetAllPoints()
    
    local bg = mainBtn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    mainBtn.bg = bg
    
    local border = CreateFrame("Frame", nil, container, "BackdropTemplate")
    border:SetAllPoints()
    border:SetBackdrop({
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    container.border = border
    
    text = mainBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", mainBtn, "LEFT", 6, 0)
    text:SetPoint("RIGHT", mainBtn, "RIGHT", -18, 0)
    text:SetJustifyH("LEFT")
    text:SetTextColor(1, 1, 1, 1)
    text:SetText(placeholder)
    
    local arrow = mainBtn:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(14, 14)
    arrow:SetPoint("RIGHT", mainBtn, "RIGHT", -3, 0)
    arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
    arrow:SetTexCoord(0.25, 0.75, 0.25, 0.75)
    mainBtn.arrow = arrow
    
    local highlight = mainBtn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.05)
    
    container.mainBtn = mainBtn
  end
  
  -- Create dropdown menu (shared by both modes)
  local menu = CreateFrame("Frame", nil, parent)
  menu:SetFrameStrata("DIALOG")
  menu:SetFrameLevel(parent:GetFrameLevel() + 20)
  
  -- Calculate menu width
  local menuWidth
  if configMenuWidth then
    -- Explicit width provided - use it directly
    menuWidth = configMenuWidth
  else
    -- Auto-calculate from content
    menuWidth = width  -- Start with button width as minimum
    if #options > 0 then
      -- Create temporary FontStrings to measure text
      local tempText = menu:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      local tempSmall = menu:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      local maxContentWidth = 0
      
      for _, option in ipairs(options) do
        local contentWidth = 0
        
        -- Check if this option has custom slot data (for renderRow)
        if option.petName then
          -- Custom slot format: "Slot X" + "Pet Name (Breed)" + "Level X - Family"
          -- Measure slot label
          tempSmall:SetText("Slot " .. (option.slot or "X"))
          local slotWidth = tempSmall:GetStringWidth()
          
          -- Measure pet name line (name + breed)
          local nameText = option.petName .. (option.breed or "")
          tempText:SetText(nameText)
          local nameWidth = tempText:GetStringWidth()
          
          -- Measure details line
          tempSmall:SetText(string.format("Level %d - %s", option.level or 25, option.familyName or "Unknown"))
          local detailsWidth = tempSmall:GetStringWidth()
          
          -- Content width = icon + slot label + gap + max(name, details) + padding
          contentWidth = (option.icon and (iconSize + 8) or 4)  -- Icon + padding
          contentWidth = contentWidth + slotWidth + 8  -- Slot label + gap
          contentWidth = contentWidth + math.max(nameWidth, detailsWidth)  -- Wider of the two lines
          contentWidth = contentWidth + 16  -- Right padding
        else
          -- Standard format: just use option.text
          local displayText = option.text or tostring(option.value)
          
          -- Add breed text if present
          if option.breed and option.breed ~= "" then
            displayText = displayText .. " (" .. option.breed .. ")"
          end
          
          tempText:SetText(displayText)
          local textWidth = tempText:GetStringWidth()
          
          contentWidth = textWidth
          contentWidth = contentWidth + (option.icon and (iconSize + 8) or 8)  -- Icon + padding or just padding
          contentWidth = contentWidth + 60  -- Right padding for family icon and level overlay
          contentWidth = contentWidth + 16  -- Left/right margins
        end
        
        if contentWidth > maxContentWidth then
          maxContentWidth = contentWidth
        end
      end
      
      menuWidth = math.max(width, maxContentWidth)  -- Use larger of button width or content width
    end
  end
  
  local menuHeight = math.min(#options, maxRows) * rowHeight + 4
  menu:SetSize(menuWidth, menuHeight)
  menu:Hide()
  container.menu = menu
  
  local menuBg = menu:CreateTexture(nil, "BACKGROUND")
  menuBg:SetAllPoints()
  menuBg:SetColorTexture(0.08, 0.08, 0.08, 0.95)
  
  local menuBorder = CreateFrame("Frame", nil, menu, "BackdropTemplate")
  menuBorder:SetAllPoints()
  menuBorder:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  menuBorder:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
  
  local rows = {}
  for i, option in ipairs(options) do
    local row = CreateFrame("Button", nil, menu)
    row:SetSize(menuWidth - 4, rowHeight)
    row:SetPoint("TOPLEFT", menu, "TOPLEFT", 2, -2 - ((i - 1) * rowHeight))
    
    local rowBg = row:CreateTexture(nil, "BACKGROUND")
    rowBg:SetAllPoints()
    rowBg:SetColorTexture(0, 0, 0, 0)
    row.bg = rowBg
    
    -- Pet icon
    if option.icon then
      local icon = row:CreateTexture(nil, "ARTWORK")
      icon:SetSize(iconSize, iconSize)
      icon:SetPoint("LEFT", row, "LEFT", 4, 0)
      icon:SetTexture(option.icon)
      row.icon = icon
      
      -- Level background
      local levelBG = row:CreateTexture(nil, "OVERLAY", nil, 0)
      levelBG:SetSize(20, 20)
      levelBG:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -1, 1)
      levelBG:SetColorTexture(0, 0, 0)
      levelBG:SetAlpha(0.7)
      row.levelBG = levelBG
      
      -- Level text
      local levelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      levelText:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -3, 3)
      levelText:SetTextColor(1, 1, 1)
      levelText:SetShadowOffset(1, -1)
      if option.level then
        levelText:SetText(option.level)
      end
      row.levelText = levelText
    end
    
    -- Family icon background (desaturated, right side)
    if option.familyIcon then
      local familyIcon = row:CreateTexture(nil, "OVERLAY", nil, 2)
      familyIcon:SetSize(rowHeight * 0.3, rowHeight * 0.375)  -- 20:25 aspect ratio
      familyIcon:SetPoint("RIGHT", row, "RIGHT", -8, 0)
      local uiUtils = Addon.uiUtils
      if uiUtils and uiUtils.setFamilyIcon then
        if uiUtils:setFamilyIcon(familyIcon, option.familyIcon, "faded-color") then
          familyIcon:SetAlpha(0.3)
        end
      end
      row.familyIcon = familyIcon
    end
    
    -- Name text (single line with breed appended)
    local rowText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local textLeft = option.icon and (iconSize + 8) or 8
    rowText:SetPoint("LEFT", row, "LEFT", textLeft, 0)
    rowText:SetPoint("RIGHT", row, "RIGHT", -40, 0)  -- Padding for family icon
    rowText:SetJustifyH("LEFT")
    rowText:SetJustifyV("MIDDLE")
    rowText:SetWordWrap(false)
    row.text = rowText
    
    local isHighlighted = (option.value == defaultValue)
    if renderRow then
      renderRow(row, option, isHighlighted)
    else
      local displayText = option.text or tostring(option.value)
      if option.color then
        displayText = option.color .. displayText .. "|r"
      end
      rowText:SetText(displayText)
      
      if isHighlighted then
        rowBg:SetColorTexture(0.4, 0.3, 0.6, 0.7)
      end
    end
    
    row:SetScript("OnEnter", function(self)
      self.bg:SetColorTexture(0.4, 0.3, 0.6, 0.7)
    end)
    
    row:SetScript("OnLeave", function(self)
      self.bg:SetColorTexture(0, 0, 0, 0)
    end)
    
    row:SetScript("OnClick", function(self)
      menu:Hide()
      if onChange then
        onChange(option.value, option)
      end
    end)
    
    rows[i] = row
  end
  
  -- Click handlers based on mode
  if splitButton then
    -- Arrow button toggles menu
    arrowBtn:SetScript("OnClick", function(self, button)
      if menu:IsShown() then
        menu:Hide()
      else
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, 0)
        menu:Show()
      end
    end)
    
    -- Main button already has onClick handler set above
    
  else
    -- Regular mode: clicking anywhere toggles menu
    mainBtn:SetScript("OnClick", function(self, button)
      if IsShiftKeyDown() and onShiftClick then
        onShiftClick()
        return
      end
      
      if menu:IsShown() then
        menu:Hide()
      else
        menu:ClearAllPoints()
        menu:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, 0)
        menu:Show()
      end
    end)
  end
  
  -- Hover handlers and tooltip
  if splitButton then
    -- Both buttons get hover effects
    mainBtn:SetScript("OnEnter", function(self)
      self.bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)
      container.border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
      if config.tooltip then
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(config.tooltip, 1, 1, 1, 1, true)
        GameTooltip:Show()
      end
    end)
    
    mainBtn:SetScript("OnLeave", function(self)
      self.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
      container.border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
      GameTooltip:Hide()
    end)
    
    arrowBtn:SetScript("OnEnter", function(self)
      self.bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)
      container.border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    end)
    
    arrowBtn:SetScript("OnLeave", function(self)
      self.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
      container.border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    end)
  else
    -- Single button hover
    mainBtn:SetScript("OnEnter", function(self)
      self.bg:SetColorTexture(0.15, 0.15, 0.15, 0.9)
      container.border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
      if config.tooltip then
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(config.tooltip, 1, 1, 1, 1, true)
        GameTooltip:Show()
      end
    end)
    
    mainBtn:SetScript("OnLeave", function(self)
      self.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
      container.border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
      GameTooltip:Hide()
    end)
  end
  
  -- Menu auto-hide and click-outside detection
  menu:SetScript("OnHide", function(self)
    self:SetScript("OnUpdate", nil)
  end)
  
  menu:SetScript("OnShow", function(self)
    local timeOff = 0
    self:SetScript("OnUpdate", function(self, elapsed)
      local mouseOver = MouseIsOver(self) or MouseIsOver(container)
      
      if mouseOver then
        timeOff = 0
      else
        timeOff = timeOff + elapsed
        if timeOff >= 1.5 then
          self:Hide()
          return
        end
      end
      
      if GetMouseButtonClicked() and not mouseOver then
        self:Hide()
      end
    end)
  end)
  
  -- Escape key closes menu
  menu:SetPropagateKeyboardInput(true)
  menu:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
      self:Hide()
      self:SetPropagateKeyboardInput(false)
    end
  end)
  
  -- Public API methods on container
  function container:SetText(newText)
    text:SetText(newText)
  end
  
  function container:GetMenu()
    return menu
  end
  
  function container:CloseMenu()
    menu:Hide()
  end
  
  container:Show()
  return container
end
-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("dropdownLegacy", {}, function()
        return true
    end)
end

Addon.dropdownLegacy = dropdownLegacy
return dropdownLegacy