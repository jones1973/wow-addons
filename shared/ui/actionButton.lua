--[[
  ui/shared/actionButton.lua
  Action Button Component
  
  Professional action buttons with icon + text, cooldown support,
  and multiple aesthetic styles.
  
  Features:
  - Horizontal layout (icon + text)
  - Icon on left or right
  - Cooldown spiral on icon
  - 4 aesthetic styles
  - Size presets
  
  Styles:
  1. Flat - Solid color, no gradients
  2. Soft Gradient - Subtle top-to-bottom gradient
  3. Dark Pro - Dark bg with lavender accent border
  4. Outlined - Transparent bg, colored border
  
  Usage:
    local btn = actionButton:create(parent, {
      text = "Heal",
      icon = 136243,
      iconSide = "left",  -- or "right"
      onClick = function() ... end,
      tooltip = "Heal all pets",
      size = "medium",    -- or "small", "large", "xl"
      style = 3,          -- 1-4
    })
    
    btn:setCooldown(start, duration)
    btn:setStyle(2)
    btn:setSize("large")
  
  Dependencies: none (self-contained)
  Exports: Addon.actionButton
]]

local ADDON_NAME, Addon = ...

local actionButton = {}

-- ============================================================================
-- STYLE DEFINITIONS
-- ============================================================================

-- Lavender palette
local COLORS = {
  lavender = { 0.608, 0.541, 0.651 },        -- #9b8aa6
  lavenderLight = { 0.769, 0.718, 0.816 },   -- #c4b7d0
  lavenderText = { 0.910, 0.878, 0.929 },    -- #e8e0ed
  darkBg = { 0.102, 0.102, 0.180 },          -- #1a1a2e
  darkBgHover = { 0.150, 0.150, 0.220 },     -- slightly lighter
  flatBg = { 0.180, 0.180, 0.200 },          -- neutral dark gray
  flatBgHover = { 0.250, 0.250, 0.270 },
  white = { 1, 1, 1 },
  gray = { 0.7, 0.7, 0.7 },
}

-- Style configurations
local STYLES = {
  -- Style 1: Flat with diagonal gradient texture
  {
    name = "Flat",
    bgTexture = "Interface\\AddOns\\PawAndOrder\\textures\\button-gradient.png",
    bgHoverTexture = "Interface\\AddOns\\PawAndOrder\\textures\\button-gradient-hover.png",
    border = { 0.38, 0.38, 0.42 },
    borderHover = { 0.55, 0.55, 0.60 },
    borderSize = 1,
    textColor = COLORS.white,
    textHover = COLORS.white,
    cornerRadius = 2,
    useTexture = true,
  },
  -- Style 2: Soft Gradient (uses averaged color for runtime switching)
  {
    name = "Soft Gradient",
    bg = { 0.20, 0.20, 0.22 },
    bgHover = { 0.28, 0.28, 0.30 },
    border = { 0.35, 0.35, 0.38 },
    borderHover = { 0.45, 0.45, 0.48 },
    borderSize = 1,
    textColor = COLORS.white,
    cornerRadius = 3,
  },
  -- Style 3: Dark Pro (lavender accent)
  {
    name = "Dark Pro",
    bg = COLORS.darkBg,
    bgHover = COLORS.darkBgHover,
    border = COLORS.lavender,
    borderHover = COLORS.lavenderLight,
    borderSize = 2,
    textColor = COLORS.lavenderText,
    cornerRadius = 2,
  },
  -- Style 4: Outlined
  {
    name = "Outlined",
    bg = { 0, 0, 0, 0 },  -- transparent
    bgHover = { 0.15, 0.15, 0.18, 0.5 },
    border = COLORS.lavender,
    borderHover = COLORS.lavenderLight,
    borderSize = 2,
    textColor = COLORS.lavenderLight,
    textHover = COLORS.white,
    cornerRadius = 2,
    transparent = true,
  },
}

-- Size presets: { iconSize, height, textPadding, minWidth }
local SIZES = {
  small  = { icon = 20, height = 26, padding = 6, minWidth = 70 },
  medium = { icon = 26, height = 32, padding = 8, minWidth = 90 },
  large  = { icon = 32, height = 40, padding = 10, minWidth = 110 },
  xl     = { icon = 40, height = 50, padding = 12, minWidth = 130 },
}

-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

--[[
  Create a texture, optionally with solid color.
]]
local function createSolidTexture(frame, layer, r, g, b, a)
  local tex = frame:CreateTexture(nil, layer or "BACKGROUND")
  if r and g and b then
    tex:SetColorTexture(r, g, b, a or 1)
  end
  return tex
end

--[[
  Apply style to button.
]]
local function applyStyle(button, styleNum, isHover)
  local style = STYLES[styleNum] or STYLES[1]
  
  if style.useTexture then
    -- Texture-based style (diagonal gradient images)
    local texturePath = isHover and style.bgHoverTexture or style.bgTexture
    if button.bg then
      button.bg:SetTexture(texturePath)
      button.bg:SetVertexColor(1, 1, 1, 1)  -- Full brightness, texture has the colors
    end
  elseif style.gradient then
    -- Gradient style (two solid blocks)
    local topColor = isHover and style.bgHoverTop or style.bgTop
    local bottomColor = isHover and style.bgHoverBottom or style.bgBottom
    
    if button.bgTop then
      button.bgTop:SetColorTexture(topColor[1], topColor[2], topColor[3], 1)
    end
    if button.bgBottom then
      button.bgBottom:SetColorTexture(bottomColor[1], bottomColor[2], bottomColor[3], 1)
    end
  else
    -- Solid style
    local bgColor = isHover and style.bgHover or style.bg
    local alpha = bgColor[4] or 1
    if button.bg then
      button.bg:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], alpha)
    end
  end
  
  -- Border
  if style.borderSize > 0 and button.borderTextures then
    local borderColor = isHover and style.borderHover or style.border
    if borderColor then
      for _, tex in ipairs(button.borderTextures) do
        tex:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], 1)
        tex:Show()
      end
    end
  elseif button.borderTextures then
    for _, tex in ipairs(button.borderTextures) do
      tex:Hide()
    end
  end
  
  -- Text color
  if button.text then
    local textColor = (isHover and style.textHover) or style.textColor or COLORS.white
    button.text:SetTextColor(textColor[1], textColor[2], textColor[3])
  end
end

--[[
  Create border textures (4 edges).
]]
local function createBorder(button, thickness)
  local borders = {}
  
  -- Top
  local top = button:CreateTexture(nil, "BORDER")
  top:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
  top:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
  top:SetHeight(thickness)
  table.insert(borders, top)
  
  -- Bottom
  local bottom = button:CreateTexture(nil, "BORDER")
  bottom:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
  bottom:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
  bottom:SetHeight(thickness)
  table.insert(borders, bottom)
  
  -- Left
  local left = button:CreateTexture(nil, "BORDER")
  left:SetPoint("TOPLEFT", button, "TOPLEFT", 0, -thickness)
  left:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, thickness)
  left:SetWidth(thickness)
  table.insert(borders, left)
  
  -- Right
  local right = button:CreateTexture(nil, "BORDER")
  right:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, -thickness)
  right:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, thickness)
  right:SetWidth(thickness)
  table.insert(borders, right)
  
  return borders
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Create an action button.
  
  @param parent frame - Parent frame
  @param config table - Button configuration:
    text      string - Button label (optional, icon-only if omitted)
    icon      number|string - Icon texture ID or path (optional, text-only if omitted)
    iconSide  string - "left" or "right" (default "left")
    onClick   function - Click handler
    onRightClick function - Right-click handler (optional)
    tooltip   string - Tooltip text
    size      string - "small", "medium", "large", "xl" (default "medium")
    style     number - 1-4 (default 3)
    secure    boolean - Use SecureActionButtonTemplate (auto-set if secureType provided)
    secureName string - Global name for secure button
    secureType string - "spell", "toy", "item", or "macro" (implies secure=true)
    secureId   number|string - ID for secureType (spell ID, toy ID, item ID, or macro text)
    preClick  function - PreClick handler for secure buttons
    postClick function - PostClick handler for secure buttons
  @return frame - The button
]]
function actionButton:create(parent, config)
  config = config or {}
  
  local sizePreset = SIZES[config.size or "medium"]
  local styleNum = config.style or 3
  local style = STYLES[styleNum]
  local iconSide = config.iconSide or "left"
  
  -- secureType implies secure=true
  local isSecure = config.secure or config.secureType
  
  -- Create button frame (secure template if requested)
  local button
  if isSecure then
    button = CreateFrame("Button", config.secureName, parent, "SecureActionButtonTemplate")
  else
    button = CreateFrame("Button", nil, parent)
  end
  button:SetHeight(sizePreset.height)
  
  -- Store config for later updates
  button._config = config
  button._sizePreset = sizePreset
  button._styleNum = styleNum
  button._iconSide = iconSide
  button._isSecure = isSecure
  
  -- Set secure attributes based on secureType/secureId
  if config.secureType and config.secureId then
    local secType = config.secureType
    local secId = config.secureId
    
    if secType == "spell" then
      button:SetAttribute("type", "spell")
      button:SetAttribute("spell", secId)
    elseif secType == "toy" then
      button:SetAttribute("type", "toy")
      button:SetAttribute("toy", secId)
    elseif secType == "item" then
      button:SetAttribute("type", "item")
      button:SetAttribute("item", "item:" .. secId)
    elseif secType == "macro" then
      button:SetAttribute("type", "macro")
      button:SetAttribute("macrotext", secId)
    end
  end
  
  -- Background
  if style.useTexture then
    -- Texture-based background (diagonal gradient image)
    button.bg = button:CreateTexture(nil, "BACKGROUND")
    button.bg:SetAllPoints()
    button.bg:SetTexture(style.bgTexture)
  elseif style.gradient then
    -- Two-part gradient background
    button.bgTop = createSolidTexture(button, "BACKGROUND")
    button.bgTop:SetPoint("TOPLEFT")
    button.bgTop:SetPoint("TOPRIGHT")
    button.bgTop:SetHeight(sizePreset.height / 2)
    
    button.bgBottom = createSolidTexture(button, "BACKGROUND")
    button.bgBottom:SetPoint("BOTTOMLEFT")
    button.bgBottom:SetPoint("BOTTOMRIGHT")
    button.bgBottom:SetHeight(sizePreset.height / 2)
  else
    -- Solid background
    button.bg = createSolidTexture(button, "BACKGROUND", 0.1, 0.1, 0.1, 1)
    button.bg:SetAllPoints()
  end
  
  -- Border
  button.borderTextures = createBorder(button, style.borderSize or 1)
  
  -- Icon container (for cooldown frame)
  button.iconFrame = CreateFrame("Frame", nil, button)
  button.iconFrame:SetSize(sizePreset.icon, sizePreset.icon)
  
  -- Icon texture
  button.icon = button.iconFrame:CreateTexture(nil, "ARTWORK")
  button.icon:SetAllPoints()
  if config.icon then
    if type(config.icon) == "number" then
      button.icon:SetTexture(config.icon)
    else
      button.icon:SetTexture(config.icon)
    end
  end
  
  -- Cooldown frame
  button.cooldown = CreateFrame("Cooldown", nil, button.iconFrame, "CooldownFrameTemplate")
  button.cooldown:SetAllPoints()
  button.cooldown:SetDrawEdge(true)
  button.cooldown:SetHideCountdownNumbers(false)
  
  -- Text
  button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  button.text:SetText(config.text or "")
  
  -- Determine button mode: text-only, icon-only, or icon+text
  local hasIcon = config.icon ~= nil
  local hasText = config.text and config.text ~= ""
  
  -- Position icon and text
  local iconPad = sizePreset.padding
  local textPad = sizePreset.padding
  local gap = 4
  local textWidth = button.text:GetStringWidth()
  
  if not hasIcon then
    -- Text-only button: center text, hide icon
    button.iconFrame:Hide()
    button.text:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.text:SetJustifyH("CENTER")
    
    -- Calculate width
    if config.fixedWidth then
      button:SetWidth(config.fixedWidth)
      button._fixedWidth = config.fixedWidth
    else
      local totalWidth = textPad * 2 + textWidth
      button:SetWidth(math.max(totalWidth, sizePreset.minWidth))
    end
  elseif not hasText then
    -- Icon-only button: center icon, hide text
    button.text:Hide()
    button.iconFrame:SetPoint("CENTER", button, "CENTER", 0, 0)
    
    -- For icon-only, width = height (square) unless fixedWidth specified
    if config.fixedWidth then
      button:SetWidth(config.fixedWidth)
      button._fixedWidth = config.fixedWidth
    else
      button:SetWidth(sizePreset.height)
    end
  else
    -- Icon + text button: position as centered unit
    local contentWidth = sizePreset.icon + gap + textWidth
    local iconOffset = -(contentWidth / 2) + (sizePreset.icon / 2)
    
    if iconSide == "right" then
      -- Text on left, icon on right, centered as unit
      button.text:SetPoint("CENTER", button, "CENTER", -((sizePreset.icon + gap) / 2), 0)
      button.iconFrame:SetPoint("LEFT", button.text, "RIGHT", gap, 0)
    else
      -- Icon on left, text on right, centered as unit
      button.iconFrame:SetPoint("CENTER", button, "CENTER", iconOffset, 0)
      button.text:SetPoint("LEFT", button.iconFrame, "RIGHT", gap, 0)
    end
    
    button.text:SetJustifyH("LEFT")
    
    -- Calculate width
    if config.fixedWidth then
      button:SetWidth(config.fixedWidth)
      button._fixedWidth = config.fixedWidth
    else
      local totalWidth = iconPad + sizePreset.icon + gap + textWidth + textPad
      button:SetWidth(math.max(totalWidth, sizePreset.minWidth))
    end
  end
  
  -- Apply initial style
  applyStyle(button, styleNum, false)
  
  -- Hover handlers
  button:SetScript("OnEnter", function(self)
    applyStyle(self, self._styleNum, true)
    
    -- Tooltip (use dynamic _tooltip if set, otherwise original config.tooltip)
    local tooltipText = self._tooltip or config.tooltip
    if tooltipText then
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      GameTooltip:SetText(tooltipText, 1, 1, 1)
      GameTooltip:Show()
    end
  end)
  
  button:SetScript("OnLeave", function(self)
    applyStyle(self, self._styleNum, false)
    GameTooltip:Hide()
  end)
  
  -- Click handlers
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  
  if isSecure then
    -- Secure button: use PreClick for conditional setup, PostClick for cleanup
    if config.preClick then
      button:SetScript("PreClick", function(self, mouseButton)
        config.preClick(self, mouseButton)
      end)
    end
    
    if config.postClick then
      button:SetScript("PostClick", function(self, mouseButton)
        config.postClick(self, mouseButton)
      end)
    end
    
    -- Also support regular onClick for non-secure actions (runs in PostClick context)
    if config.onClick and not config.postClick then
      button:SetScript("PostClick", function(self, mouseButton)
        if mouseButton == "LeftButton" then
          config.onClick(self)
        elseif mouseButton == "RightButton" and config.onRightClick then
          config.onRightClick(self)
        end
      end)
    end
  else
    -- Regular button: use OnClick directly
    button:SetScript("OnClick", function(self, mouseButton)
      if mouseButton == "LeftButton" and config.onClick then
        config.onClick(self)
      elseif mouseButton == "RightButton" and config.onRightClick then
        config.onRightClick(self)
      end
    end)
  end
  
  -- ========================================
  -- BUTTON METHODS
  -- ========================================
  
  --[[
    Set cooldown display.
    @param start number - GetTime() when cooldown started
    @param duration number - Total duration in seconds
  ]]
  function button:setCooldown(start, duration)
    if start and duration and duration > 0 then
      self.cooldown:SetCooldown(start, duration)
    else
      self.cooldown:Clear()
    end
  end
  
  --[[
    Set button style.
    @param styleNum number - 1-4
  ]]
  function button:setStyle(styleNum)
    self._styleNum = styleNum
    applyStyle(self, styleNum, false)
  end
  
  --[[
    Set button size.
    @param sizeName string - "small", "medium", "large", "xl"
  ]]
  function button:setSize(sizeName)
    local preset = SIZES[sizeName]
    if not preset then return end
    
    self._sizePreset = preset
    self:SetHeight(preset.height)
    
    -- Update icon
    self.iconFrame:SetSize(preset.icon, preset.icon)
    
    -- Reposition as centered unit
    local iconPad = preset.padding
    local textPad = preset.padding
    local gap = 4
    
    self.iconFrame:ClearAllPoints()
    self.text:ClearAllPoints()
    
    local textWidth = self.text:GetStringWidth()
    local contentWidth = preset.icon + gap + textWidth
    local iconOffset = -(contentWidth / 2) + (preset.icon / 2)
    
    if self._iconSide == "right" then
      self.text:SetPoint("CENTER", self, "CENTER", -((preset.icon + gap) / 2), 0)
      self.iconFrame:SetPoint("LEFT", self.text, "RIGHT", gap, 0)
    else
      self.iconFrame:SetPoint("CENTER", self, "CENTER", iconOffset, 0)
      self.text:SetPoint("LEFT", self.iconFrame, "RIGHT", gap, 0)
    end
    
    self.text:SetJustifyH("LEFT")
    
    -- Recalculate width (for non-fixed-width buttons)
    local totalWidth = iconPad + preset.icon + gap + textWidth + textPad
    self:SetWidth(math.max(totalWidth, preset.minWidth))
  end
  
  --[[
    Set button text.
    @param text string
  ]]
  function button:setText(text)
    self.text:SetText(text or "")
    
    local preset = self._sizePreset
    local gap = 4
    local textWidth = self.text:GetStringWidth()
    
    -- Reposition
    self.iconFrame:ClearAllPoints()
    self.text:ClearAllPoints()
    
    if not self._config.icon then
      -- Text-only button
      self.text:SetPoint("CENTER", self, "CENTER", 0, 0)
      
      if not self._fixedWidth then
        local textPad = preset.padding
        local totalWidth = textPad * 2 + textWidth
        self:SetWidth(math.max(totalWidth, preset.minWidth))
      end
    else
      -- Button with icon
      local contentWidth = preset.icon + gap + textWidth
      local iconOffset = -(contentWidth / 2) + (preset.icon / 2)
      
      if self._iconSide == "right" then
        self.text:SetPoint("CENTER", self, "CENTER", -((preset.icon + gap) / 2), 0)
        self.iconFrame:SetPoint("LEFT", self.text, "RIGHT", gap, 0)
      else
        self.iconFrame:SetPoint("CENTER", self, "CENTER", iconOffset, 0)
        self.text:SetPoint("LEFT", self.iconFrame, "RIGHT", gap, 0)
      end
      
      if not self._fixedWidth then
        local iconPad = preset.padding
        local textPad = preset.padding
        local totalWidth = iconPad + preset.icon + gap + textWidth + textPad
        self:SetWidth(math.max(totalWidth, preset.minWidth))
      end
    end
  end
  
  --[[
    Set button icon.
    @param icon number|string
  ]]
  function button:setIcon(icon)
    if type(icon) == "number" then
      self.icon:SetTexture(icon)
    else
      self.icon:SetTexture(icon)
    end
  end
  
  --[[
    Enable or disable button.
    @param enabled boolean
  ]]
  function button:setEnabled(enabled)
    if enabled then
      self:Enable()
      self.icon:SetDesaturated(false)
      self.text:SetTextColor(unpack(STYLES[self._styleNum].textColor or COLORS.white))
    else
      self:Disable()
      self.icon:SetDesaturated(true)
      self.text:SetTextColor(0.5, 0.5, 0.5)
    end
  end
  
  --[[
    Set tooltip text.
    @param tooltip string
  ]]
  function button:setTooltip(tooltip)
    self._tooltip = tooltip
  end
  
  --[[
    Get current style number.
    @return number
  ]]
  function button:getStyle()
    return self._styleNum
  end
  
  --[[
    Get current size name.
    @return string
  ]]
  function button:getSizeName()
    for name, preset in pairs(SIZES) do
      if preset == self._sizePreset then
        return name
      end
    end
    return "medium"
  end
  
  --[[
    Set or update secure action attributes.
    Only works if button was created with secure=true or secureType.
    
    @param secureType string - "spell", "toy", "item", or "macro"
    @param secureId number|string - ID for the action type
  ]]
  function button:setSecureAction(secureType, secureId)
    if not self._isSecure then return end
    
    -- Clear existing attributes
    self:SetAttribute("type", nil)
    self:SetAttribute("spell", nil)
    self:SetAttribute("toy", nil)
    self:SetAttribute("item", nil)
    self:SetAttribute("macrotext", nil)
    
    if not secureType or not secureId then return end
    
    if secureType == "spell" then
      self:SetAttribute("type", "spell")
      self:SetAttribute("spell", secureId)
    elseif secureType == "toy" then
      self:SetAttribute("type", "toy")
      self:SetAttribute("toy", secureId)
    elseif secureType == "item" then
      self:SetAttribute("type", "item")
      self:SetAttribute("item", "item:" .. secureId)
    elseif secureType == "macro" then
      self:SetAttribute("type", "macro")
      self:SetAttribute("macrotext", secureId)
    end
  end
  
  return button
end

--[[
  Get style name.
  @param styleNum number
  @return string
]]
function actionButton:getStyleName(styleNum)
  local style = STYLES[styleNum]
  return style and style.name or "Unknown"
end

--[[
  Get all size names.
  @return table
]]
function actionButton:getSizeNames()
  return { "small", "medium", "large", "xl" }
end

--[[
  Get number of styles.
  @return number
]]
function actionButton:getStyleCount()
  return #STYLES
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
  Addon.registerModule("actionButton", {}, function()
    return true
  end)
end

Addon.actionButton = actionButton
return actionButton