--[[
  ui/shared/tooltips.lua
  Unified Tooltip System
  
  Single tooltip frame with sequential content building.
  Supports vertical stacking and horizontal layouts.
  
  Usage:
    tooltip:show(owner, opts)
    tooltip:header("Title")
    tooltip:text("Content line")
    tooltip:section("Section Header")  -- Yellow mid-tooltip header
    tooltip:space(6)
    tooltip:row("Label", "Value")
    tooltip:row("Health", {text = "152", color = GREEN})
    tooltip:iconText(texture, "Beast", {iconSize = 20})
    tooltip:cornerIcon(textureID, {size = 32})  -- Decorative top-right icon
    tooltip:hints({"Click to...", "Shift-click to..."})
    tooltip:done()
    
    tooltip:hide()
  
  Dependencies: none (agnostic)
  Exports: Addon.tooltip
]]

local ADDON_NAME, Addon = ...

local tooltip = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local EDGE_PADDING = 20

local PADDING_LEFT = 12
local PADDING_RIGHT = 12
local PADDING_TOP = 12
local PADDING_BOTTOM = 12
local HEADER_HEIGHT_EST = 14

local DEFAULT_MAX_WIDTH = 300

local FONT_HEADER = "GameTooltipHeaderText"
local FONT_NORMAL = "GameTooltipText"
local FONT_SMALL = "GameTooltipTextSmall"

local COLOR_DEFAULT = {1, 0.82, 0}  -- Golden yellow
local COLOR_WHITE = {1, 1, 1}

-- ============================================================================
-- STATE
-- ============================================================================

local frame = nil

-- Element pools
local fontStrings = {}
local textures = {}
local backgroundFrames = {}

-- Backdrop-derived spacing (updated by syncAppearance from GameTooltip)
-- Edge inset = backdrop inset + 1px margin from border
local backdropEdge = 6  -- Default for Blizzard's 4px inset + 2
local backdropInset = 4  -- Default for Blizzard's backdrop

-- Build state
local cursor = {
  anchor = nil,
  anchorPoint = nil,
  offsetY = 0,
  index = 0,
  maxWidth = 0,
  totalHeight = 0,
  headerBackground = false,
}

-- ============================================================================
-- FRAME CREATION
-- ============================================================================

local function createFrame()
  local f = CreateFrame("Frame", "PAOTooltip", UIParent, "BackdropTemplate")
  f:SetFrameStrata("TOOLTIP")
  f:SetFrameLevel(100)
  f:SetClampedToScreen(true)
  f:Hide()
  
  f:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  
  return f
end

-- Mirror GameTooltip's backdrop and colors onto our frame.
-- Called each show() so we pick up whatever ElvUI/ToxiUI has applied.
local function syncAppearance(f)
  local backdrop = GameTooltip:GetBackdrop()
  if backdrop then
    f:SetBackdrop(backdrop)
    local insets = backdrop.insets
    if insets then
      backdropInset = insets.left or 4
      backdropEdge = backdropInset + 2
    end
  end
  f:SetBackdropColor(GameTooltip:GetBackdropColor())
  f:SetBackdropBorderColor(GameTooltip:GetBackdropBorderColor())
end

local function getFrame()
  if not frame then
    frame = createFrame()
  end
  return frame
end

-- ============================================================================
-- ELEMENT POOLS
-- ============================================================================

local function getFontString(id, fontObj)
  local key = "fs" .. id
  if fontStrings[key] then
    local fs = fontStrings[key]
    fs:SetFontObject(fontObj or FONT_NORMAL)
    fs:SetSpacing(2)  -- Reset to default line spacing
    fs:SetJustifyH("LEFT")  -- Reset alignment
    fs:Show()
    return fs
  end
  
  local fs = getFrame():CreateFontString(nil, "ARTWORK", fontObj or FONT_NORMAL)
  fontStrings[key] = fs
  return fs
end

local function getTexture(id)
  local key = "tex" .. id
  if textures[key] then
    local tex = textures[key]
    tex:Show()
    return tex
  end
  
  local tex = getFrame():CreateTexture(nil, "ARTWORK")
  textures[key] = tex
  return tex
end

local function hideAllElements()
  for _, fs in pairs(fontStrings) do
    if fs and fs.Hide then
      fs:Hide()
      fs:SetText("")
      fs:SetWidth(0)
      fs:SetWordWrap(false)
    end
  end
  for _, tex in pairs(textures) do
    if tex and tex.Hide then
      tex:Hide()
    end
  end
end

-- ============================================================================
-- POSITIONING
-- ============================================================================

-- Anchor modes for tooltip placement:
-- "topright" (default) - Bottom-left of tooltip at owner's top-right, grows up+right
-- "right"              - Top-left of tooltip at owner's top-right, grows down+right
-- "left"               - Top-right of tooltip at owner's top-left, grows down+left
-- "above"              - Bottom-center of tooltip at owner's top-center, grows up
-- "below"              - Top-left of tooltip at owner's bottom-left, grows down

local DEFAULT_GAP = 2

local function computePosition(owner, tooltipWidth, tooltipHeight, opts)
  opts = opts or {}
  local gap = opts.gap or DEFAULT_GAP
  local screenW = GetScreenWidth()
  local screenH = GetScreenHeight()
  
  local ownerLeft = owner:GetLeft() or 0
  local ownerRight = owner:GetRight() or 0
  local ownerTop = owner:GetTop() or 0
  
  local x, y
  local anchor = opts.anchor or "topright"
  
  if anchor == "right" then
    x = ownerRight + gap
    y = ownerTop - tooltipHeight
  elseif anchor == "left" then
    x = ownerLeft - gap - tooltipWidth
    y = ownerTop - tooltipHeight
  elseif anchor == "above" then
    x = (ownerLeft + ownerRight) / 2 - tooltipWidth / 2
    y = ownerTop + gap
  elseif anchor == "below" then
    local ownerBottom = owner:GetBottom() or 0
    x = ownerLeft
    y = ownerBottom - gap - tooltipHeight
  else
    x = ownerRight + gap
    y = ownerTop
  end
  
  -- Slide Y: keep top below screen top edge
  if y + tooltipHeight > screenH - EDGE_PADDING then
    y = (screenH - EDGE_PADDING) - tooltipHeight
  end
  if y < EDGE_PADDING then
    y = EDGE_PADDING
  end
  
  -- Slide X: keep within screen width
  if x + tooltipWidth > screenW - EDGE_PADDING then
    x = (screenW - EDGE_PADDING) - tooltipWidth
  end
  if x < EDGE_PADDING then
    x = EDGE_PADDING
  end
  
  return x, y
end

--[[
  Position any frame relative to owner using the standard algorithm.
  Unlike tooltip:show/done, uses the frame's current dimensions.
  
  @param targetFrame frame - Frame to position
  @param owner frame - Anchor reference
  @param opts table - {anchor, gap}
]]
function tooltip:position(targetFrame, owner, opts)
  if not targetFrame or not owner then return end
  opts = opts or {}
  local width = targetFrame:GetWidth() or 100
  local height = targetFrame:GetHeight() or 30
  local x, y = computePosition(owner, width, height, opts)
  targetFrame:ClearAllPoints()
  targetFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
end

-- ============================================================================
-- CURSOR HELPERS
-- ============================================================================

local function advanceCursor(element, height)
  cursor.anchor = element
  cursor.anchorPoint = "BOTTOMLEFT"
  cursor.offsetY = 0
  cursor.totalHeight = cursor.totalHeight + math.abs(cursor.offsetY) + height
end

local function getAnchorX()
  local f = getFrame()
  if cursor.anchor == f then
    return PADDING_LEFT
  end
  return 0
end

-- ============================================================================
-- LIFECYCLE
-- ============================================================================

--[[
  Reset tooltip state.
]]
function tooltip:reset()
  hideAllElements()
  
  cursor.anchor = nil
  cursor.anchorPoint = nil
  cursor.offsetY = 0
  cursor.index = 0
  cursor.maxWidth = 0
  cursor.totalHeight = 0
  cursor.headerBackground = false
  cursor.headerHeight = nil
  cursor.headerIcon = nil
  cursor.headerIconSpacing = nil
  cursor.headerIconSize = nil
  cursor.reservedRight = nil
  cursor.owner = nil
  cursor.posOpts = nil
  cursor.cornerIcon = nil
  cursor.minWidth = nil
  cursor.pendingBackgrounds = nil
  
  getFrame():SetSize(100, 30)
end

--[[
  Show tooltip anchored to owner.
  Positioning is deferred until done() when final dimensions are known.
  
  @param owner frame - Frame to anchor to
  @param opts table - {anchor = "topright"|"right"|"left"|"above", gap = number, atCursor = boolean}
]]
function tooltip:show(owner, opts)
  self:reset()
  
  local f = getFrame()
  opts = opts or {}
  
  -- Store for deferred positioning in done()
  cursor.owner = owner
  cursor.posOpts = opts
  
  -- Place off-screen during content building (font strings need a visible frame to measure)
  f:ClearAllPoints()
  f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -9999, 9999)
  
  syncAppearance(f)
  
  -- Initialize cursor
  cursor.anchor = f
  cursor.anchorPoint = "TOPLEFT"
  cursor.offsetY = -PADDING_TOP
  cursor.index = 0
  cursor.totalHeight = PADDING_TOP
  
  f:Show()
end

--[[
  Finalize tooltip sizing.
]]
function tooltip:done()
  local f = getFrame()
  
  local width = math.max(cursor.maxWidth, 100)
  local height = math.max(cursor.totalHeight + PADDING_BOTTOM, 30)
  
  f:SetSize(width, height)

  -- Apply deferred background bands now that frame width is final
  if cursor.pendingBackgrounds then
    for i, entry in ipairs(cursor.pendingBackgrounds) do
      local bgPad = entry.bgPad
      local x1 = PADDING_LEFT
      local x2 = -PADDING_RIGHT
      local y1 = -(entry.startHeight - bgPad)
      local y2 = -(entry.endHeight   + bgPad)

      -- Fill
      local bg = self:texture("noteBand_" .. i)
      bg:ClearAllPoints()
      bg:SetDrawLayer("BACKGROUND", 2)
      bg:SetTexture("Interface\\Buttons\\WHITE8X8")
      local c = entry.color
      bg:SetVertexColor(c[1], c[2], c[3], c[4] or 0.15)
      bg:SetPoint("TOPLEFT",     f, "TOPLEFT",  x1, y1)
      bg:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", x2, y2)
      bg:Show()

      -- Border: dark shadow (top + left edges)
      local bTop = self:texture("noteBandBorderTop_" .. i)
      bTop:ClearAllPoints()
      bTop:SetDrawLayer("BACKGROUND", 3)
      bTop:SetTexture("Interface\\Buttons\\WHITE8X8")
      bTop:SetVertexColor(0, 0, 0, 0.5)
      bTop:SetPoint("TOPLEFT",     f, "TOPLEFT",  x1,     y1)
      bTop:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", x2, y1 - 1)
      bTop:Show()

      local bLeft = self:texture("noteBandBorderLeft_" .. i)
      bLeft:ClearAllPoints()
      bLeft:SetDrawLayer("BACKGROUND", 3)
      bLeft:SetTexture("Interface\\Buttons\\WHITE8X8")
      bLeft:SetVertexColor(0, 0, 0, 0.5)
      bLeft:SetPoint("TOPLEFT",     f, "TOPLEFT", x1,     y1)
      bLeft:SetPoint("BOTTOMRIGHT", f, "TOPLEFT", x1 + 1, y2)
      bLeft:Show()

      -- Border: lighter highlight (bottom + right edges)
      local bBot = self:texture("noteBandBorderBot_" .. i)
      bBot:ClearAllPoints()
      bBot:SetDrawLayer("BACKGROUND", 3)
      bBot:SetTexture("Interface\\Buttons\\WHITE8X8")
      bBot:SetVertexColor(1, 1, 1, 0.15)
      bBot:SetPoint("TOPLEFT",     f, "TOPLEFT",  x1, y2 + 1)
      bBot:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", x2, y2)
      bBot:Show()

      local bRight = self:texture("noteBandBorderRight_" .. i)
      bRight:ClearAllPoints()
      bRight:SetDrawLayer("BACKGROUND", 3)
      bRight:SetTexture("Interface\\Buttons\\WHITE8X8")
      bRight:SetVertexColor(1, 1, 1, 0.15)
      bRight:SetPoint("TOPLEFT",     f, "TOPRIGHT", x2 - 1, y1)
      bRight:SetPoint("BOTTOMRIGHT", f, "TOPRIGHT", x2,     y2)
      bRight:Show()
    end
  else
    for key, bg in pairs(backgroundFrames) do
      bg:Hide()
    end
  end
  
  -- Final positioning now that dimensions are known
  if cursor.posOpts and cursor.posOpts.atCursor then
    local cx, cy = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    f:ClearAllPoints()
    f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", cx / scale + 10, cy / scale + 10)
  elseif cursor.owner then
    local x, y = computePosition(cursor.owner, width, height, cursor.posOpts)
    f:ClearAllPoints()
    f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
  end
  
  -- Add header background bar if requested
  if cursor.headerBackground then
    local bg = self:texture("headerBackground")
    bg:SetDrawLayer("BACKGROUND", 1)
    bg:ClearAllPoints()
    bg:SetPoint("TOPLEFT", f, "TOPLEFT", backdropInset, -3)
    bg:SetPoint("RIGHT", f, "RIGHT", -backdropInset, 0)
    -- headerHeight = distance from frame top to separator line
    -- bg starts at -3 (1px higher than default -4), extends 1px past separator
    local bgH = cursor.headerHeight and (cursor.headerHeight - 2) or (PADDING_TOP + HEADER_HEIGHT_EST - 2)
    bg:SetHeight(bgH)
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.15, 0.12, 0.08, 0.9)
    bg:Show()
  else
    -- Hide if previously shown
    if textures["custom_headerBackground"] then
      textures["custom_headerBackground"]:Hide()
    end
  end
  
  -- Place stored corner icon (set during build for text wrapping)
  if cursor.cornerIcon then
    local cfg = cursor.cornerIcon
    local icon = self:texture("cornerIcon")
    
    icon:ClearAllPoints()
    icon:SetSize(cfg.size, cfg.size)
    icon:SetTexture(cfg.texture)
    icon:SetAlpha(cfg.alpha)
    icon:SetDrawLayer("ARTWORK", 2)
    
    if cfg.coords then
      icon:SetTexCoord(unpack(cfg.coords))
    else
      icon:SetTexCoord(0, 1, 0, 1)
    end
    
    icon:SetPoint("TOPRIGHT", f, "TOPRIGHT", -(cfg.iconRightOffset or 4), cfg.iconY)
    icon:Show()
  end
end

--[[
  Hide tooltip.
]]
function tooltip:hide()
  self:reset()
  getFrame():Hide()
end

-- ============================================================================
-- CONTENT API
-- ============================================================================

--[[
  Add header text (large, white by default).
  
  @param text string
  @param opts table - {color = {r, g, b}, background = boolean (default true)}
    When background = true: adds background bar, full-width separator, and spacing
]]
function tooltip:header(text, opts)
  opts = opts or {}
  
  cursor.index = cursor.index + 1
  local fs = getFontString(cursor.index, FONT_HEADER)
  fs:ClearAllPoints()
  fs:SetPoint("TOPLEFT", cursor.anchor, cursor.anchorPoint, getAnchorX(), cursor.offsetY)
  
  local color = opts.color or COLOR_WHITE
  fs:SetTextColor(color[1], color[2], color[3])
  fs:SetText(text)
  fs:Show()
  
  local textHeight = fs:GetStringHeight()
  local width = fs:GetStringWidth() + PADDING_LEFT + PADDING_RIGHT
  cursor.maxWidth = math.max(cursor.maxWidth, width)
  
  advanceCursor(fs, textHeight)
  
  -- Full header treatment: background bar + separator + spacing (default true)
  if opts.background ~= false then
    cursor.headerBackground = true
    self:separator({fullWidth = true})
    
    -- Separator Y from frame top
    local sepY = PADDING_TOP + textHeight + 4
    cursor.headerHeight = sepY
    
    -- Vertically center text within header background
    local f = getFrame()
    local bgTop = 3
    local bgH = sepY - 2
    local textY = -(bgTop + (bgH - textHeight) / 2) + 1
    
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", f, "TOPLEFT", getAnchorX(), textY)
    
    self:space(4)
  end
end

--[[
  Add text line.
  
  @param text string
  @param opts table - {color, wrap, maxWidth, font, spacing}
]]
function tooltip:text(text, opts)
  opts = opts or {}
  
  local fontObj = FONT_NORMAL
  if opts.font == "small" then fontObj = FONT_SMALL
  elseif opts.font == "header" then fontObj = FONT_HEADER
  end
  
  local indent = opts.indent or 0
  local rightReserve = cursor.reservedRight or 0
  
  -- Use minWidth if set, otherwise DEFAULT_MAX_WIDTH
  -- This ensures wrap calculations match actual frame width
  local effectiveWidth = cursor.minWidth or DEFAULT_MAX_WIDTH
  local baseWrapWidth = opts.maxWidth or (effectiveWidth - PADDING_LEFT - PADDING_RIGHT - indent - rightReserve)
  
  -- Check if corner icon is active and we're in its zone
  local iconReserve = 0
  local iconBottom = nil
  if cursor.cornerIcon then
    iconBottom = cursor.cornerIcon.iconBottom
    -- totalHeight and iconBottom are both positive (distance from top)
    if cursor.totalHeight < iconBottom then
      -- Still in icon zone - reserve space
      iconReserve = cursor.cornerIcon.iconRight
    end
  end
  
  local wrapWidth = baseWrapWidth - iconReserve
  local color = opts.color or COLOR_DEFAULT
  local justify = opts.justify or "LEFT"
  
  -- If wrapping and we have an icon zone, check if text will overflow the zone
  if opts.wrap and iconReserve > 0 and iconBottom then
    -- Measure how tall the text would be at narrow width
    cursor.index = cursor.index + 1
    local measureFs = getFontString(cursor.index, fontObj)
    measureFs:SetWidth(wrapWidth)
    measureFs:SetWordWrap(true)
    measureFs:SetSpacing(opts.spacing or 2)
    measureFs:SetText(text)
    local narrowHeight = measureFs:GetStringHeight()
    
    -- Measure single-line height (no wrapping) to detect actual multi-line text
    measureFs:SetWidth(0)
    measureFs:SetWordWrap(false)
    local singleLineHeight = measureFs:GetStringHeight()
    measureFs:SetText("")
    measureFs:Hide()
    cursor.index = cursor.index - 1  -- Reuse this index
    
    -- totalHeight + narrowHeight = where text would end (absolute from top)
    local textEndPosition = cursor.totalHeight + narrowHeight
    
    -- Only split if text actually wraps at narrow width AND extends past icon zone.
    -- A single line that straddles the zone boundary renders fine without splitting.
    if textEndPosition > iconBottom and narrowHeight > singleLineHeight then
      -- Text overflows - need to split
      self:renderSplitText(text, opts, fontObj, wrapWidth, baseWrapWidth, iconBottom)
      return
    end
  end
  
  -- Normal render (no split needed)
  cursor.index = cursor.index + 1
  local fs = getFontString(cursor.index, fontObj)
  fs:ClearAllPoints()
  fs:SetPoint("TOPLEFT", cursor.anchor, cursor.anchorPoint, getAnchorX() + indent, cursor.offsetY)
  
  fs:SetTextColor(color[1], color[2], color[3])
  fs:SetSpacing(opts.spacing or 2)
  fs:SetJustifyH(justify)
  
  if justify == "CENTER" then
    fs:SetPoint("RIGHT", getFrame(), "RIGHT", -PADDING_RIGHT, 0)
    fs:SetWordWrap(opts.wrap or false)
  elseif opts.wrap then
    fs:SetWidth(wrapWidth)
    fs:SetWordWrap(true)
  else
    fs:SetWidth(0)
    fs:SetWordWrap(false)
  end
  
  fs:SetText(text)
  fs:Show()
  
  local width
  if opts.wrap then
    width = baseWrapWidth + PADDING_LEFT + PADDING_RIGHT + indent + rightReserve
  else
    width = fs:GetStringWidth() + PADDING_LEFT + PADDING_RIGHT + indent
  end
  local height = fs:GetStringHeight()
  cursor.maxWidth = math.max(cursor.maxWidth, width)
  
  local preOffsetY = cursor.offsetY
  local wasFrameAnchored = (cursor.anchor == getFrame())
  
  advanceCursor(fs, height)
  
  if indent > 0 then
    cursor.anchor = getFrame()
    cursor.anchorPoint = "TOPLEFT"
    if wasFrameAnchored then
      cursor.offsetY = preOffsetY - height
    else
      cursor.offsetY = -(cursor.totalHeight)
    end
  end
end

--[[
  Render text that splits at the icon boundary.
  First part renders narrow (in icon zone), second part renders full width.
  
  @param text string - Full text to render
  @param opts table - Original options
  @param fontObj string - Font object name
  @param narrowWidth number - Width while in icon zone
  @param fullWidth number - Width after clearing icon
  @param iconBottom number - Y position where icon zone ends
]]
function tooltip:renderSplitText(text, opts, fontObj, narrowWidth, fullWidth, iconBottom)
  local color = opts.color or COLOR_DEFAULT
  local spacing = opts.spacing or 2
  local indent = opts.indent or 0
  
  -- Binary search to find how many words fit in the narrow zone
  local words = {}
  for word in text:gmatch("%S+") do
    table.insert(words, word)
  end
  
  if #words <= 1 then
    -- Single word - just render narrow, let it overflow
    self:text(text, opts)
    return
  end
  
  -- Measure function: how tall is N words at narrow width?
  local function measureWords(n)
    cursor.index = cursor.index + 1
    local fs = getFontString(cursor.index, fontObj)
    fs:SetWidth(narrowWidth)
    fs:SetWordWrap(true)
    fs:SetSpacing(spacing)
    fs:SetText(table.concat(words, " ", 1, n))
    local h = fs:GetStringHeight()
    fs:SetText("")
    fs:Hide()
    cursor.index = cursor.index - 1
    return h
  end
  
  -- Find max words that fit in icon zone
  -- zoneHeight = remaining space in icon zone (iconBottom - current position)
  local zoneHeight = iconBottom - cursor.totalHeight
  local lo, hi = 1, #words
  local splitAt = 1
  
  while lo <= hi do
    local mid = math.floor((lo + hi) / 2)
    local h = measureWords(mid)
    if h <= zoneHeight then
      splitAt = mid
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  
  -- Render first part (narrow)
  if splitAt >= 1 then
    local narrowText = table.concat(words, " ", 1, splitAt)
    cursor.index = cursor.index + 1
    local fs1 = getFontString(cursor.index, fontObj)
    fs1:ClearAllPoints()
    fs1:SetPoint("TOPLEFT", cursor.anchor, cursor.anchorPoint, getAnchorX() + indent, cursor.offsetY)
    fs1:SetTextColor(color[1], color[2], color[3])
    fs1:SetSpacing(spacing)
    fs1:SetJustifyH("LEFT")
    fs1:SetWidth(narrowWidth)
    fs1:SetWordWrap(true)
    fs1:SetText(narrowText)
    fs1:Show()
    
    local h1 = fs1:GetStringHeight()
    cursor.maxWidth = math.max(cursor.maxWidth, fullWidth + PADDING_LEFT + PADDING_RIGHT + indent)
    advanceCursor(fs1, h1)
  end
  
  -- Render second part (full width) if there are remaining words
  if splitAt < #words then
    local fullText = table.concat(words, " ", splitAt + 1)
    cursor.index = cursor.index + 1
    local fs2 = getFontString(cursor.index, fontObj)
    fs2:ClearAllPoints()
    fs2:SetPoint("TOPLEFT", cursor.anchor, cursor.anchorPoint, getAnchorX() + indent, cursor.offsetY)
    fs2:SetTextColor(color[1], color[2], color[3])
    fs2:SetSpacing(spacing)
    fs2:SetJustifyH("LEFT")
    fs2:SetWidth(fullWidth)
    fs2:SetWordWrap(true)
    fs2:SetText(fullText)
    fs2:Show()
    
    local h2 = fs2:GetStringHeight()
    cursor.maxWidth = math.max(cursor.maxWidth, fullWidth + PADDING_LEFT + PADDING_RIGHT + indent)
    advanceCursor(fs2, h2)
  end
  
  -- Reset anchor if indented
  if indent > 0 then
    cursor.anchor = getFrame()
    cursor.anchorPoint = "TOPLEFT"
    cursor.offsetY = -(cursor.totalHeight)
  end
end

--[[
  Add vertical space.
  
  @param pixels number (default 3)
]]
function tooltip:space(pixels)
  pixels = pixels or 3
  cursor.offsetY = cursor.offsetY - pixels
  cursor.totalHeight = cursor.totalHeight + pixels
end

--[[
  Add horizontal separator line.
  
  @param opts table - {color = {r, g, b, a}, fullWidth = boolean}
]]
function tooltip:separator(opts)
  opts = opts or {}
  cursor.index = cursor.index + 1
  
  local f = getFrame()
  local tex = getTexture(cursor.index)
  tex:ClearAllPoints()
  
  -- Check if we're in icon zone (use visual bottom for separators)
  local iconVisualBottom = cursor.cornerIcon and cursor.cornerIcon.iconVisualBottom
  local inIconZone = iconVisualBottom and cursor.totalHeight < iconVisualBottom
  
  -- Calculate insets
  local leftInset, rightInset
  if opts.fullWidth then
    -- Full width: extend to backdrop edges with 1px margin
    if cursor.anchor == f then
      leftInset = backdropEdge
    else
      -- Anchored to an element at PADDING_LEFT from frame edge
      leftInset = backdropEdge - PADDING_LEFT
    end
    
    -- If in icon zone, stop before icon; otherwise go to edge
    if inIconZone then
      rightInset = -(cursor.cornerIcon.iconRightOffset + cursor.cornerIcon.size + 4)
    else
      rightInset = -backdropEdge
    end
  else
    leftInset = getAnchorX()
    
    -- If in icon zone, stop before icon; otherwise normal padding
    if inIconZone then
      rightInset = -(cursor.cornerIcon.iconRightOffset + cursor.cornerIcon.size + 4)
    else
      rightInset = -PADDING_RIGHT
    end
  end
  
  tex:SetPoint("TOPLEFT", cursor.anchor, cursor.anchorPoint, leftInset, cursor.offsetY - 4)
  tex:SetPoint("RIGHT", f, "RIGHT", rightInset, 0)
  tex:SetHeight(1)
  tex:SetTexture("Interface\\Buttons\\WHITE8X8")
  
  local color = opts.color or {0.4, 0.4, 0.4, 1}
  tex:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
  tex:Show()
  
  -- 4px above + 1px line + 4px below
  cursor.totalHeight = cursor.totalHeight + 4 + 1 + 4
  
  if opts.fullWidth then
    -- Anchor back to frame so subsequent content gets proper PADDING_LEFT
    cursor.anchor = f
    cursor.anchorPoint = "TOPLEFT"
    cursor.offsetY = -(cursor.totalHeight)
  else
    cursor.anchor = tex
    cursor.anchorPoint = "BOTTOMLEFT"
    cursor.offsetY = -4
  end
end

--[[
  Add icon with text on same line.
  
  @param texture string|number - Texture path or ID
  @param text string
  @param opts table - {iconSize, iconCoords, color, spacing}
]]
function tooltip:iconText(texture, text, opts)
  opts = opts or {}
  cursor.index = cursor.index + 1
  
  local iconW = opts.iconWidth or opts.iconSize or 16
  local iconH = opts.iconHeight or opts.iconSize or 16
  local spacing = opts.spacing or 4
  
  -- Icon
  local icon = getTexture(cursor.index)
  icon:ClearAllPoints()
  local iconYOffset = opts.iconOffsetY or 0
  icon:SetPoint("TOPLEFT", cursor.anchor, cursor.anchorPoint, getAnchorX(), cursor.offsetY + iconYOffset)
  icon:SetSize(iconW, iconH)
  icon:SetTexture(texture)
  
  if opts.iconCoords then
    icon:SetTexCoord(unpack(opts.iconCoords))
  else
    icon:SetTexCoord(0, 1, 0, 1)
  end
  if opts.iconColor then
    icon:SetVertexColor(opts.iconColor[1], opts.iconColor[2], opts.iconColor[3], opts.iconColor[4] or 1)
  else
    icon:SetVertexColor(1, 1, 1, 1)
  end
  icon:Show()
  
  -- Text
  cursor.index = cursor.index + 1
  local fs = getFontString(cursor.index, FONT_NORMAL)
  fs:ClearAllPoints()
  local textYOffset = opts.textOffsetY or 0
  fs:SetPoint("LEFT", icon, "RIGHT", spacing, textYOffset)
  
  local color = opts.color or COLOR_WHITE
  fs:SetTextColor(color[1], color[2], color[3])
  fs:SetText(text)
  fs:Show()
  
  local width = PADDING_LEFT + iconW + spacing + fs:GetStringWidth() + PADDING_RIGHT
  -- Subtract upward icon offset from height: the icon's bottom is higher than
  -- a non-offset icon, so the effective row advance is smaller.
  local effectiveH = math.max(iconH - math.max(iconYOffset, 0), fs:GetStringHeight())
  cursor.maxWidth = math.max(cursor.maxWidth, width)
  
  advanceCursor(icon, effectiveH)
end

--[[
  Add horizontal row of cells.
  
  @param ... - Cell definitions. Each can be:
    - string: plain text, left-aligned
    - table: {text, color, icon, iconSize, iconCoords, rightAlign, background}
      rightAlign: anchors cell to tooltip's right edge
      background: {r,g,b,a} on FIRST cell only - renders full-width row background
  
  Examples:
    tooltip:row("Label", "Value")
    tooltip:row("Health", {text = "152", color = {0,1,0}})
    tooltip:row(
      {text = "Zone Name", color = WHITE, background = {0.15, 0.15, 0.15, 0.4}},
      {text = "25", color = GREEN, rightAlign = true}
    )
]]
function tooltip:row(...)
  local cells = {...}
  if #cells == 0 then return end
  
  cursor.index = cursor.index + 1
  local baseIndex = cursor.index
  
  local rowElements = {}
  local totalWidth = PADDING_LEFT
  local maxHeight = 0
  local f = getFrame()
  
  for i, cell in ipairs(cells) do
    local cellDef = type(cell) == "string" and {text = cell} or cell
    local iconSize = cellDef.iconSize or 16
    local spacing = 4
    local cellWidth = 0
    
    -- Create icon if specified
    local icon = nil
    if cellDef.icon then
      cursor.index = cursor.index + 1
      icon = getTexture(cursor.index)
      icon:SetSize(iconSize, iconSize)
      
      if type(cellDef.icon) == "number" then
        icon:SetTexture(cellDef.icon)
      else
        icon:SetTexture(cellDef.icon)
      end
      
      if cellDef.iconCoords then
        icon:SetTexCoord(unpack(cellDef.iconCoords))
      else
        icon:SetTexCoord(0, 1, 0, 1)
      end
      icon:Show()
      
      cellWidth = cellWidth + iconSize + spacing
      maxHeight = math.max(maxHeight, iconSize)
    end
    
    -- Create text
    cursor.index = cursor.index + 1
    local fs = getFontString(cursor.index, FONT_NORMAL)
    
    local color = cellDef.color or COLOR_DEFAULT
    fs:SetTextColor(color[1], color[2], color[3])
    fs:SetText(cellDef.text or "")
    fs:Show()
    
    cellWidth = cellWidth + fs:GetStringWidth()
    maxHeight = math.max(maxHeight, fs:GetStringHeight())
    
    -- Position elements
    if i == 1 then
      if icon then
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", cursor.anchor, cursor.anchorPoint, getAnchorX(), cursor.offsetY)
        fs:ClearAllPoints()
        fs:SetPoint("LEFT", icon, "RIGHT", spacing, 0)
      else
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", cursor.anchor, cursor.anchorPoint, getAnchorX(), cursor.offsetY)
      end
    else
      if cellDef.rightAlign then
        -- Right-align to tooltip frame edge, vertically match first cell
        local firstElem = rowElements[1].icon or rowElements[1].text
        fs:ClearAllPoints()
        fs:SetPoint("TOP", firstElem, "TOP")
        fs:SetPoint("RIGHT", f, "RIGHT", -PADDING_RIGHT, 0)
        if icon then
          icon:ClearAllPoints()
          icon:SetPoint("TOP", firstElem, "TOP")
          icon:SetPoint("RIGHT", fs, "LEFT", -spacing, 0)
        end
      else
        local prevElem = rowElements[#rowElements].text
        local gap = 12  -- gap between cells
        if icon then
          icon:ClearAllPoints()
          icon:SetPoint("LEFT", prevElem, "RIGHT", gap, 0)
          fs:ClearAllPoints()
          fs:SetPoint("LEFT", icon, "RIGHT", spacing, 0)
        else
          fs:ClearAllPoints()
          fs:SetPoint("LEFT", prevElem, "RIGHT", gap, 0)
        end
        totalWidth = totalWidth + gap
      end
    end
    
    table.insert(rowElements, {icon = icon, text = fs})
    totalWidth = totalWidth + cellWidth
  end
  
  totalWidth = totalWidth + PADDING_RIGHT
  cursor.maxWidth = math.max(cursor.maxWidth, totalWidth)
  
  -- Row background (zebra striping, highlights, etc.)
  if cells[1] then
    local firstCellDef = type(cells[1]) == "string" and {} or cells[1]
    if firstCellDef.background then
      cursor.index = cursor.index + 1
      local bg = getTexture(cursor.index)
      local firstElem = rowElements[1].icon or rowElements[1].text
      bg:SetDrawLayer("BACKGROUND", 2)
      bg:ClearAllPoints()
      bg:SetPoint("TOPLEFT", firstElem, "TOPLEFT", -4, 1)
      bg:SetPoint("RIGHT", f, "RIGHT", -backdropEdge, 0)
      bg:SetHeight(maxHeight + 4)
      bg:SetTexture("Interface\\Buttons\\WHITE8X8")
      local bgColor = firstCellDef.background
      bg:SetVertexColor(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 0.4)
      bg:Show()
    end
  end
  
  -- Advance cursor (anchor to first element)
  local firstElem = rowElements[1].icon or rowElements[1].text
  advanceCursor(firstElem, maxHeight)
end

--[[
  Set minimum tooltip width.
  
  @param width number
]]
function tooltip:minWidth(width)
  if width then
    cursor.maxWidth = math.max(cursor.maxWidth, width)
    cursor.minWidth = width  -- Store for wrap width calculations
  end
end

--[[
  Reserve right-side space for a post-done icon.
  Wrapped text() calls will reduce their width to avoid the icon area.
  Call after show(), before any text content.
  
  @param iconSize number - Icon width in pixels
  @param rightOffset number - X offset from frame's right edge (same value used in SetPoint, e.g. -8)
]]
function tooltip:reserveIcon(iconSize, rightOffset)
  local GAP = 4  -- minimum breathing room between text and icon
  local iconLeftFromRight = math.abs(rightOffset or 8) + (iconSize or 32)
  cursor.reservedRight = math.max(0, iconLeftFromRight + GAP - PADDING_RIGHT)
end

--[[
  Add a progress bar with optional label.
  Matches team slot XP bar styling: 6px fill over 3px gray track.
  
  @param current number - Current value
  @param max number - Maximum value
  @param opts table - {label, color, height}
    - label: string - Text shown after the bar (e.g., "12")
    - color: table - Bar fill color {r, g, b} (default purple)
    - height: number - Bar height in pixels (default 6)
]]
function tooltip:progressBar(current, max, opts)
  opts = opts or {}
  local barHeight = opts.height or 6  -- Match team slot XP bar fill
  local bgHeight = 3  -- Match team slot background track
  local fillColor = opts.color or {0.8, 0.7, 1}  -- Purple like team slots
  local label = opts.label
  
  local f = getFrame()
  
  -- Measure label first to calculate bar width
  local labelWidth = 0
  local lblText
  if label then
    local lblKey = "progressLbl_" .. cursor.index
    lblText = fontStrings[lblKey]
    if not lblText then
      lblText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      fontStrings[lblKey] = lblText
    end
    lblText:SetText(label)
    lblText:SetTextColor(1, 1, 1)
    labelWidth = lblText:GetStringWidth()
  end
  
  -- Calculate bar width: fill available space, leave room for label
  local contentWidth = (cursor.maxWidth > 0 and cursor.maxWidth or DEFAULT_MAX_WIDTH) - PADDING_LEFT - PADDING_RIGHT
  local gap = label and 4 or 0  -- Tight gap like team slots
  local barWidth = contentWidth - labelWidth - gap
  barWidth = math.max(barWidth, 60)  -- Minimum bar width
  
  -- Background texture (3px gray track, centered vertically)
  local bgKey = "progressBg_" .. cursor.index
  local bg = textures[bgKey]
  if not bg then
    bg = f:CreateTexture(nil, "ARTWORK", nil, 1)
    textures[bgKey] = bg
  end
  bg:SetColorTexture(0.4, 0.4, 0.4, 1)  -- Match team slot gray
  bg:SetSize(barWidth, bgHeight)
  bg:ClearAllPoints()
  -- Center the 3px track vertically within the 6px bar space
  local bgOffsetY = cursor.offsetY - (barHeight - bgHeight) / 2
  bg:SetPoint("TOPLEFT", cursor.anchor, cursor.anchorPoint, getAnchorX(), bgOffsetY)
  bg:Show()
  
  -- Fill texture (6px colored portion)
  local fillKey = "progressFill_" .. cursor.index
  local fill = textures[fillKey]
  if not fill then
    fill = f:CreateTexture(nil, "ARTWORK", nil, 2)
    textures[fillKey] = fill
  end
  local percent = max > 0 and (current / max) or 0
  local fillWidth = math.max(barWidth * percent, 1)
  fill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
  fill:SetVertexColor(fillColor[1], fillColor[2], fillColor[3], 1)
  fill:SetSize(fillWidth, barHeight)
  fill:ClearAllPoints()
  fill:SetPoint("TOPLEFT", cursor.anchor, cursor.anchorPoint, getAnchorX(), cursor.offsetY)
  fill:Show()
  
  -- Percentage text centered on bar
  local pctKey = "progressPct_" .. cursor.index
  local pctText = fontStrings[pctKey]
  if not pctText then
    pctText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fontStrings[pctKey] = pctText
  end
  pctText:SetText(math.floor(percent * 100) .. "%")
  pctText:SetTextColor(1, 1, 1)
  pctText:ClearAllPoints()
  pctText:SetPoint("CENTER", fill, "LEFT", barWidth / 2, 0)
  pctText:Show()
  
  -- Position label at right edge
  if lblText then
    lblText:ClearAllPoints()
    lblText:SetPoint("LEFT", fill, "LEFT", barWidth + gap, 0)
    lblText:Show()
  end
  
  -- Update width tracking
  local totalWidth = PADDING_LEFT + barWidth + gap + labelWidth + PADDING_RIGHT
  cursor.maxWidth = math.max(cursor.maxWidth, totalWidth)
  
  -- Advance cursor
  cursor.offsetY = cursor.offsetY - barHeight
  cursor.totalHeight = cursor.totalHeight + barHeight
end

--[[
  Get a managed texture for custom positioning.
  
  @param id string - Unique identifier
  @return texture
]]
function tooltip:texture(id)
  local key = "custom_" .. id
  if textures[key] then
    textures[key]:Show()
    return textures[key]
  end
  
  local tex = getFrame():CreateTexture(nil, "ARTWORK")
  textures[key] = tex
  return tex
end

--[[
  Get the tooltip frame for advanced usage.
  
  @return frame
]]
function tooltip:frame()
  return getFrame()
end

--[[
  Get a cursor field value. Used by callers that need to capture
  build state (e.g. totalHeight) for deferred background placement.
  @param field string - cursor field name
  @return any
]]
function tooltip:getCursor(field)
  return cursor[field]
end

--[[
  Queue a background band for placement in done() once frame width is known.
  @param entry table - {startHeight, endHeight, bgPad, color}
]]
function tooltip:queueBackground(entry)
  cursor.pendingBackgrounds = cursor.pendingBackgrounds or {}
  table.insert(cursor.pendingBackgrounds, entry)
end

--[[
  Track an element for bounds (advanced usage).
  Currently a no-op since we track via cursor.
]]
function tooltip:track(element)
  -- Reserved for future use
end

-- ============================================================================
-- CONVENIENCE METHODS
-- ============================================================================

--[[
  Render a block of text lines with a vertically-centered icon to the left.
  Core pattern used by hints, requirements, etc.
  
  @param lines table - Array of line definitions, each either:
    - string: plain text with default color
    - table: {text = string, color = {r,g,b}}
  @param opts table - Required options:
    - icon: texture path or ID
    - iconSize: icon dimensions (default 14)
    - iconSpacing: gap between icon and text (default 6)
    - textureName: unique name for texture reuse
    Optional:
    - iconAlpha: icon opacity (default 1)
    - iconColor: {r,g,b} vertex color (default white)
    - iconCoords: {left,right,top,bottom} texcoords
    - lineSpacing: pixels between lines (default 2)
]]
function tooltip:iconBlock(lines, opts)
  if not lines or #lines == 0 then return end
  
  opts = opts or {}
  local iconSize = opts.iconSize or 14
  local iconSpacing = opts.iconSpacing or 6
  local lineSpacing = opts.lineSpacing or 2
  local indent = iconSize + iconSpacing
  local f = self:frame()
  
  -- Track height before rendering block
  local startHeight = cursor.totalHeight

  local prevWasText = false
  for _, line in ipairs(lines) do
    -- Spacer element: {space = N}
    if type(line) == "table" and line.space then
      self:space(line.space)
      prevWasText = false
    else
      if prevWasText then
        self:space(lineSpacing)
      end

      local text, color, font, wrap
      if type(line) == "string" then
        text = line
        color = COLOR_DEFAULT
        font = nil
        wrap = false
      else
        text = line.text
        color = line.color or COLOR_DEFAULT
        font = line.font
        wrap = line.wrap or false
      end

      self:text(text, {color = color, indent = indent, font = font, wrap = wrap})
      prevWasText = true
    end
  end
  
  local endHeight = cursor.totalHeight
  
  -- Place icon vertically centered against block (skip if no icon or iconSize=0)
  if opts.icon and iconSize > 0 then
    local icon = self:texture(opts.textureName or "iconBlockIcon")
    icon:ClearAllPoints()
    icon:SetSize(iconSize, iconSize)
    icon:SetDrawLayer("OVERLAY")
    icon:SetTexture(opts.icon)

    if opts.iconCoords then
      icon:SetTexCoord(unpack(opts.iconCoords))
    else
      icon:SetTexCoord(0, 1, 0, 1)
    end

    icon:SetAlpha(opts.iconAlpha or 1)

    if opts.iconColor then
      icon:SetVertexColor(opts.iconColor[1], opts.iconColor[2], opts.iconColor[3])
    else
      icon:SetVertexColor(1, 1, 1)
    end

    local blockHeight = endHeight - startHeight
    local iconY = -(startHeight + (blockHeight - iconSize) / 2)
    icon:SetPoint("TOPLEFT", f, "TOPLEFT", PADDING_LEFT, iconY)
    icon:Show()
  end
end

--[[
  Add yellow section header for mid-tooltip content grouping.
  Standardized spacing and color - no options.
  
  @param text string - Section header text
]]
function tooltip:section(text)
  self:space(8)
  self:text(text, {color = COLOR_DEFAULT})
  self:space(2)
end

--[[
  Add decorative icon in top-right corner, below header.
  
  Timing determines behavior:
  - Called during build (before done()): stores bounds, text() wraps around icon
  - Called after done(): places immediately, no wrapping (legacy behavior)
  
  @param texture number|string - Texture ID or path
  @param opts table - Optional:
    - size: Icon dimensions (default 32)
    - alpha: Opacity (default 0.8)
    - coords: {left, right, top, bottom} texcoords
]]
function tooltip:cornerIcon(texture, opts)
  opts = opts or {}
  local size = opts.size or 32
  local alpha = opts.alpha or 0.8
  local padding = 4  -- Gap between icon and wrapped text
  
  -- Check if we're still building (done() not yet called)
  local f = getFrame()
  local point = f:GetPoint()
  local isMidBuild = cursor.owner and (not point or point == "TOPLEFT")
  
  if isMidBuild then
    -- Use totalHeight for absolute positioning (always positive, distance from top)
    -- Icon top is at current totalHeight, bottom is totalHeight + size
    local iconTop = cursor.totalHeight
    local iconBottom = iconTop + size
    
    -- Store for deferred placement and text wrapping
    cursor.cornerIcon = {
      texture = texture,
      size = size,
      alpha = alpha,
      coords = opts.coords,
      iconY = -iconTop,  -- Negative for SetPoint offset
      iconBottom = iconBottom,  -- Absolute distance from top where icon ends (for text wrap)
      iconVisualBottom = iconBottom,  -- Same as iconBottom for content-area icons
      iconRightOffset = PADDING_RIGHT,  -- Distance from frame right edge
      iconRight = size + padding,  -- How much to reserve from right for text wrap
    }
  else
    -- Legacy: place immediately (called after done())
    local icon = self:texture("cornerIcon")
    local iconY = -(PADDING_TOP + HEADER_HEIGHT_EST + 9)
    
    icon:ClearAllPoints()
    icon:SetSize(size, size)
    icon:SetTexture(texture)
    icon:SetAlpha(alpha)
    icon:SetDrawLayer("ARTWORK", 2)
    
    if opts.coords then
      icon:SetTexCoord(unpack(opts.coords))
    else
      icon:SetTexCoord(0, 1, 0, 1)
    end
    
    icon:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PADDING_RIGHT, iconY)
    icon:Show()
  end
end

--[[
  Render click hint lines with consistent formatting.
  Handles separator, spacing, gray text, and bottom padding.
  
  @param hintStrings table - Array of hint strings to display
  @param opts table - Options:
    - separator: boolean - Show separator before hints (default true)
]]
function tooltip:hints(hintStrings, opts)
  if not hintStrings or #hintStrings == 0 then return end
  
  opts = opts or {}
  local showSeparator = opts.separator ~= false  -- Default true
  
  if showSeparator then
    self:space(8)
    self:separator()
    self:space(4)
  else
    self:space(4)
  end

  -- Build lines array — {space=N} elements pass through to iconBlock as spacers
  local lines = {}
  for _, hint in ipairs(hintStrings) do
    if type(hint) == "table" and hint.space then
      table.insert(lines, hint)
    else
      table.insert(lines, {text = hint, color = {0.7, 0.7, 0.7}})
    end
  end

  self:iconBlock(lines, {
    icon = 648208,  -- Interface/Icons/PetBattle_Speed
    iconSize = 14,
    iconSpacing = 6,
    iconAlpha = 0.5,
    iconColor = {0.3, 0.8, 0.3},
    iconCoords = {0.15, 0.85, 0.15, 0.85},
    textureName = "hintIcon",
    lineSpacing = 2,
  })
end

--[[
  Simple one-line tooltip.
  
  @param owner frame
  @param text string
  @param opts table - Position options
]]
function tooltip:showSimple(owner, text, opts)
  self:show(owner, opts)
  self:text(text)
  self:done()
end

--[[
  Show tooltip with title and hint lines.
  
  @param owner frame
  @param title string - Header text
  @param hints table - Array of hint strings
  @param opts table - Position options
]]
function tooltip:showWithHints(owner, title, hints, opts)
  self:show(owner, opts)
  self:header(title)
  
  if hints and #hints > 0 then
    self:hints(hints)
  end
  
  self:done()
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
  Addon.registerModule("tooltip", {}, function()
    return true
  end)
end

Addon.tooltip = tooltip
return tooltip