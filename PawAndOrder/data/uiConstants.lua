--[[
  data/uiConstants.lua
  Shared UI Constants and Spacing Scale
  
  Centralized UI values for consistent visual design across all addon frames.
  Based on 8pt grid system. All UI code should reference these values
  rather than using arbitrary numbers.
  
  Dependencies: none
  Exports: Addon.uiConstants
]]

local addonName, Addon = ...

Addon.uiConstants = {}
local ui = Addon.uiConstants

--[[
  Spacing Scale (8pt Grid)
  All spacing values should come from this scale.
  Use the semantic names, not raw numbers.
]]
ui.SPACING = {
  NONE    = 0,   -- Flush alignment
  MICRO   = 2,   -- Hairline adjustments (rare)
  TINY    = 4,   -- Icon-to-text gaps, tight inline elements
  SMALL   = 8,   -- Related items, list item internal padding
  MEDIUM  = 12,  -- Between related text lines, button padding
  BASE    = 16,  -- Default content padding, between form fields
  LARGE   = 24,  -- Section separation, card padding
  XLARGE  = 32,  -- Major section breaks
  XXLARGE = 48,  -- Page-level margins, hero spacing
}

--[[
  Standard Padding Presets
  Common padding configurations for different frame types
]]
ui.PADDING = {
  -- Minimal padding for compact elements
  COMPACT = {
    TOP = 8,
    RIGHT = 8,
    BOTTOM = 8,
    LEFT = 8,
  },
  
  -- Standard padding for most frames
  STANDARD = {
    TOP = 16,
    RIGHT = 16,
    BOTTOM = 16,
    LEFT = 16,
  },
  
  -- Comfortable padding for primary content areas
  COMFORTABLE = {
    TOP = 20,
    RIGHT = 20,
    BOTTOM = 20,
    LEFT = 20,
  },
  
  -- Spacious padding for dialogs and popups
  SPACIOUS = {
    TOP = 24,
    RIGHT = 24,
    BOTTOM = 24,
    LEFT = 24,
  },
}

--[[
  Button Dimensions
  Standard button sizes for consistency
]]
ui.BUTTON = {
  -- Small buttons (icon buttons, compact controls)
  SMALL = {
    WIDTH = 60,
    HEIGHT = 20,
    PADDING_H = 8,
    PADDING_V = 4,
  },
  
  -- Standard buttons (most actions)
  STANDARD = {
    WIDTH = 80,
    HEIGHT = 24,
    PADDING_H = 12,
    PADDING_V = 6,
  },
  
  -- Large buttons (primary actions, CTAs)
  LARGE = {
    WIDTH = 120,
    HEIGHT = 30,
    PADDING_H = 16,
    PADDING_V = 8,
  },
  
  -- Between buttons in a button group
  GAP = 8,
}

--[[
  Icon Sizes
  Standard icon dimensions
]]
ui.ICON = {
  TINY   = 14,  -- Inline with small text
  SMALL  = 18,  -- Inline with body text
  MEDIUM = 24,  -- Standard icons
  LARGE  = 32,  -- Feature icons
  XLARGE = 48,  -- Hero/display icons
}

--[[
  Typography Spacing
  Vertical spacing between text elements
]]
ui.TEXT = {
  -- Space after title before body
  TITLE_GAP = 8,
  
  -- Space between body paragraphs
  PARAGRAPH_GAP = 8,
  
  -- Space between list items
  LIST_ITEM_GAP = 4,
  
  -- Space between label and input
  LABEL_GAP = 4,
  
  -- Space between sections
  SECTION_GAP = 16,
  
  -- Maximum comfortable line width (characters)
  MAX_LINE_WIDTH = 70,
}

--[[
  Frame Defaults
  Standard frame configurations
]]
ui.FRAME = {
  -- Minimum frame dimensions
  MIN_WIDTH = 200,
  MIN_HEIGHT = 100,
  
  -- Standard dialog backdrop (solid dark)
  BACKDROP_DARK = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
  },
  
  -- Lighter backdrop for nested panels
  BACKDROP_PANEL = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  },
  
  -- Border insets (the visual border takes up space)
  -- Content should be offset by at least this much from frame edge
  BORDER_INSET = 12,
}

--[[
  Color Presets
  Common colors for consistent styling
]]
ui.COLOR = {
  -- Text colors (r, g, b)
  TEXT_NORMAL = { 1.0, 1.0, 1.0 },
  TEXT_MUTED = { 0.7, 0.7, 0.7 },
  TEXT_DISABLED = { 0.5, 0.5, 0.5 },
  TEXT_HIGHLIGHT = { 1.0, 0.82, 0 },  -- Gold
  TEXT_SUCCESS = { 0.0, 1.0, 0.0 },
  TEXT_ERROR = { 1.0, 0.0, 0.0 },
  TEXT_WARNING = { 1.0, 0.5, 0.0 },
  
  -- Background colors (r, g, b, a)
  BG_SOLID = { 0, 0, 0, 1 },
  BG_OVERLAY = { 0, 0, 0, 0.5 },
  
  -- Separator line
  SEPARATOR = { 0.4, 0.4, 0.4, 0.8 },
}

--[[
  Helper: Apply standard padding to a region
  @param region Frame/Region - The region to pad content within
  @param padding table - Padding preset from ui.PADDING
  @return number, number, number, number - left, right, top, bottom offsets
]]
function ui:getPaddingOffsets(padding)
  padding = padding or self.PADDING.STANDARD
  return padding.LEFT, padding.RIGHT, padding.TOP, padding.BOTTOM
end

--[[
  Helper: Get content area dimensions
  Given a frame size and padding, returns the usable content dimensions.
  @param frameWidth number - Total frame width
  @param frameHeight number - Total frame height
  @param padding table - Padding preset (optional, defaults to STANDARD)
  @return number, number - Content width and height
]]
function ui:getContentSize(frameWidth, frameHeight, padding)
  padding = padding or self.PADDING.STANDARD
  local contentWidth = frameWidth - padding.LEFT - padding.RIGHT - (self.FRAME.BORDER_INSET * 2)
  local contentHeight = frameHeight - padding.TOP - padding.BOTTOM - (self.FRAME.BORDER_INSET * 2)
  return contentWidth, contentHeight
end

--[[
  Helper: Create a horizontal separator line
  @param parent Frame - Parent frame
  @param width number - Line width
  @param yOffset number - Vertical offset from anchor
  @param anchor string - Anchor point (default "TOP")
  @return Texture - The separator line
]]
function ui:createSeparator(parent, width, yOffset, anchor)
  anchor = anchor or "TOP"
  local sep = parent:CreateTexture(nil, "ARTWORK")
  sep:SetSize(width, 1)
  sep:SetPoint(anchor, parent, anchor, 0, yOffset or 0)
  sep:SetColorTexture(unpack(self.COLOR.SEPARATOR))
  return sep
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("uiConstants", {}, function()
    return true
  end)
end

return ui
