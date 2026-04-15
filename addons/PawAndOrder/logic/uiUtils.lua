--[[
  core/uiUtils.lua
  UI Utilities and Factories
  
  Provides reusable UI building blocks and factory functions for creating
  common UI elements across the addon. Includes clickable elements, hover effects,
  and other UI primitives.
  
  Dependencies: utils
  Exports: Addon.uiUtils
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in uiUtils.lua.|r")
    return {}
end

local utils = Addon.utils
local uiUtils = {}

-- Family icon texcoord styles (from Blizzard UI definitions)
local STYLE_TEXCOORDS = {
  -- NOTE: "large" coords are suspect - derived from Blizzard XML but may be for different atlas
  ["large"]       = {0.007813, 0.710938, 0.746094, 0.917969},  -- Horizontal banner (90x44)
  ["strong"]      = {0.796875, 0.492188, 0.503906, 0.65625},   -- Bordered circular (30x30)
  ["faded-color"] = {0.18, 0.9062, 0.0000, 0.3906},            -- Transparent colored
  ["faded-dark"]  = {0.007813, 0.476563, 0.503906, 0.738281},  -- Transparent dark (60x60)
}

-- Mechanical (10) needs flipped texcoords for faded-color style
local FADED_COLOR_FLIPPED = {0.18, 0.9062, 0.3906, 0.0000}

-- Hidden helper fontstring for measuring space width (created once, reused)
local spaceWidthHelper = nil

-- Hidden helper fontstring for measuring wrapped text height (created once, reused)
local textMeasureHelper = nil

--[[
  Get the width of a single space character in GameFontNormal
  Caches the result using a hidden helper fontstring.
  
  @return number - Width of a space in pixels
]]
local function getSpaceWidth()
    if not spaceWidthHelper then
        spaceWidthHelper = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        spaceWidthHelper:SetText(" ")
        spaceWidthHelper:Hide()
    end
    return spaceWidthHelper:GetStringWidth()
end

function uiUtils:getSpaceWidth()
    return getSpaceWidth()
end

--[[
  Measure the rendered height of wrapped text at a given width.
  Uses a cached hidden fontstring to avoid repeated allocations.

  @param text string - Text to measure
  @param width number - Wrap width in pixels
  @return number - Rendered height in pixels
]]
local function measureTextHeight(text, width)
    if not textMeasureHelper then
        textMeasureHelper = UIParent:CreateFontString(nil, "OVERLAY", "GameTooltipText")
        textMeasureHelper:Hide()
    end
    textMeasureHelper:SetWidth(width)
    textMeasureHelper:SetWordWrap(true)
    textMeasureHelper:SetText(text or "")
    return textMeasureHelper:GetStringHeight()
end

--[[
  Check if a filter token exists in the current filter text.
  Handles both simple tokens and prefix:value tokens.
  
  @param filterText string - Current filter text
  @param token string - Token to search for
  @return boolean - true if token is in filter
]]
local function filterContainsToken(filterText, token)
    if not filterText or filterText == "" or not token then return false end
    
    local lowerFilter = filterText:lower()
    local lowerToken = token:lower()
    
    -- Check for exact match as whole word
    -- Pattern: start or space, token, space or end
    if lowerFilter == lowerToken then return true end
    if lowerFilter:match("^" .. lowerToken:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1") .. "%s") then return true end
    if lowerFilter:match("%s" .. lowerToken:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1") .. "$") then return true end
    if lowerFilter:match("%s" .. lowerToken:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1") .. "%s") then return true end
    
    return false
end

--[[
  Remove a filter token from the filter text.
  
  @param filterText string - Current filter text
  @param token string - Token to remove
  @return string - Filter text with token removed
]]
local function removeTokenFromFilter(filterText, token)
    if not filterText or filterText == "" or not token then return filterText or "" end
    
    local lowerToken = token:lower()
    
    -- Parse terms respecting quoted strings (e.g. "Emerald Bite", source:"in-game shop")
    local terms = {}
    local i = 1
    local len = #filterText
    while i <= len do
        while i <= len and filterText:sub(i, i) == " " do i = i + 1 end
        if i > len then break end
        
        local term
        if filterText:sub(i, i) == '"' then
            -- Starts with quote: read until closing quote
            local closeQuote = filterText:find('"', i + 1)
            if closeQuote then
                term = filterText:sub(i, closeQuote)
                i = closeQuote + 1
            else
                term = filterText:sub(i)
                i = len + 1
            end
        else
            -- Starts with non-quote: read until space, but if we hit a quote
            -- mid-token (e.g., source:"...), continue until closing quote
            local start = i
            while i <= len and filterText:sub(i, i) ~= " " do
                if filterText:sub(i, i) == '"' then
                    -- Found opening quote mid-token, scan to closing quote
                    local closeQuote = filterText:find('"', i + 1)
                    if closeQuote then
                        i = closeQuote + 1
                    else
                        i = len + 1
                    end
                    break
                end
                i = i + 1
            end
            term = filterText:sub(start, i - 1)
        end
        
        if term:lower() ~= lowerToken then
            table.insert(terms, term)
        end
    end
    
    return table.concat(terms, " ")
end

--[[
  Create a clickable text element that toggles a filter term when clicked
  
  Creates a button frame with:
  - Hover background highlight
  - Dynamic sizing based on text width
  - Tooltip showing filter action hints
  - Click: Toggle filter token (add if missing, remove if present)
  - Shift-Click: Isolate (clear filter and set only this token)
  - Proper spacing (space before + text + space after)
  
  @param parent frame - Parent frame to attach button to
  @param displayText string - Text to display (e.g., "Cageable", "Magic")
  @param filterToken string|nil - Token to add to filter (defaults to displayText:lower())
  @param colorCode string|nil - Optional color code for text (e.g., "|cff0070dd")
  @return frame - Configured button frame ready to position
]]
function uiUtils:createClickableFilterTerm(parent, displayText, filterToken, colorCode)
    if not parent or not displayText then
        utils:error("createClickableFilterTerm: parent and displayText required")
        return nil
    end
    
    -- Default filter token to lowercase display text
    filterToken = filterToken or displayText:lower()
    
    -- Create button frame
    local frame = CreateFrame("Button", nil, parent)
    frame.filterToken = filterToken
    
    -- Hover highlight background
    frame.hoverBg = frame:CreateTexture(nil, "BACKGROUND")
    frame.hoverBg:SetAllPoints()
    frame.hoverBg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
    frame.hoverBg:Hide()
    
    -- Text element
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.text:SetJustifyH("LEFT")
    
    -- Apply color code if provided
    local finalText = displayText
    if colorCode then
        finalText = colorCode .. displayText .. "|r"
    end
    frame.text:SetText(finalText)
    frame.text:SetTextColor(1, 1, 1)
    
    -- Calculate dynamic sizing
    local spaceWidth = getSpaceWidth()
    local textWidth = frame.text:GetStringWidth()
    local frameWidth = textWidth + (spaceWidth * 2)  -- space + text + space
    
    frame:SetSize(frameWidth, 16)
    
    -- Position text with one space offset inside frame
    frame.text:SetPoint("LEFT", frame, "LEFT", spaceWidth, 0)
    
    -- Hover handlers with tooltip
    frame:SetScript("OnEnter", function(self)
        self.hoverBg:Show()
        
        local tip = Addon.tooltip
        if tip then
            local petList = Addon.petList
            local currentFilter = petList and petList.getFilterText and petList:getFilterText() or ""
            local isInFilter = filterContainsToken(currentFilter, self.filterToken)
            
            local hints
            if isInFilter then
                hints = {"Click to remove from filter"}
            else
                hints = {"Click to add to filter", "Shift-Click to isolate"}
            end
            
            tip:showWithHints(self, displayText, hints)
        end
    end)
    
    frame:SetScript("OnLeave", function(self)
        self.hoverBg:Hide()
        if Addon.tooltip then
            Addon.tooltip:hide()
        end
    end)
    
    -- Click handler - toggle or isolate filter token
    frame:SetScript("OnClick", function(self)
        local petList = Addon.petList
        if not petList or not petList.setFilterTextAndChips then return end
        
        local currentFilter = petList.getFilterText and petList:getFilterText() or ""
        local newFilter
        
        if IsShiftKeyDown() then
            -- Shift-click: Isolate (clear and set only this token)
            newFilter = self.filterToken
        else
            -- Normal click: Toggle
            local isInFilter = filterContainsToken(currentFilter, self.filterToken)
            if isInFilter then
                newFilter = removeTokenFromFilter(currentFilter, self.filterToken)
            else
                if currentFilter ~= "" then
                    newFilter = currentFilter .. " " .. self.filterToken
                else
                    newFilter = self.filterToken
                end
            end
        end
        
        petList:setFilterTextAndChips(newFilter)
        
        -- Refresh tooltip to show updated state
        if self:IsMouseOver() then
            self:GetScript("OnEnter")(self)
        end
    end)
    
    return frame
end

--[[
  Check if a filter token exists in the current filter text.
  Exported for use by other modules (e.g., infoSection).
  
  @param filterText string - Current filter text
  @param token string - Token to search for
  @return boolean - true if token is in filter
]]
function uiUtils:filterContainsToken(filterText, token)
    return filterContainsToken(filterText, token)
end

--[[
  Remove a filter token from the filter text.
  Exported for use by other modules (e.g., infoSection).
  
  @param filterText string - Current filter text
  @param token string - Token to remove
  @return string - Filter text with token removed
]]
function uiUtils:removeTokenFromFilter(filterText, token)
    return removeTokenFromFilter(filterText, token)
end

--[[
  Get dynamic filter hint strings based on whether a token is already in the filter.
  
  @param token string - Filter token to check
  @return table - Array of hint strings for tooltip display
]]
function uiUtils:getFilterHints(token)
    local petList = Addon.petList
    local currentFilter = petList and petList.getFilterText and petList:getFilterText() or ""
    if filterContainsToken(currentFilter, token) then
        return {"Click to remove from filter"}
    end
    return {"Click to add to filter", "Shift-Click to isolate"}
end

--[[
  Attach standard filter toggle/isolate click behavior to any frame.
  
  Click: Toggle token in filter (add if absent, remove if present)
  Shift-Click: Isolate (clear filter and set only this token)
  After click: Re-fires OnEnter to refresh tooltip with updated hints
  
  @param frame frame - Button frame to attach click handler to
  @param getToken function - Returns the filter token string for the current state.
                             Receives the frame as argument. Return nil to abort click.
]]
function uiUtils:attachFilterClick(frame, getToken, modifierCallbacks)
    frame:SetScript("OnClick", function(self)
        -- Modifier overrides take priority over filter logic
        if modifierCallbacks then
            if IsControlKeyDown() and modifierCallbacks.ctrl then
                modifierCallbacks.ctrl(self)
                return
            end
            if IsAltKeyDown() and modifierCallbacks.alt then
                modifierCallbacks.alt(self)
                return
            end
        end

        local token = getToken(self)
        if not token or token == "" then return end
        
        local petList = Addon.petList
        if not petList or not petList.setFilterTextAndChips then return end
        
        local currentFilter = petList.getFilterText and petList:getFilterText() or ""
        local newFilter
        
        if IsShiftKeyDown() then
            newFilter = token
        else
            if filterContainsToken(currentFilter, token) then
                newFilter = removeTokenFromFilter(currentFilter, token)
            else
                if currentFilter ~= "" then
                    newFilter = currentFilter .. " " .. token
                else
                    newFilter = token
                end
            end
        end
        
        petList:setFilterTextAndChips(newFilter)
        
        -- Re-fire OnEnter to refresh tooltip with updated hint state
        if self:IsMouseOver() and self:GetScript("OnEnter") then
            self:GetScript("OnEnter")(self)
        end
    end)
end

--[[
  Create a border around a frame using 4 edge textures
  
  Creates a visual border with:
  - 4 edge textures (top, bottom, left, right)
  - Configurable thickness and color
  - Show/hide/setColor methods for dynamic updates
  
  @param frame frame - Frame to add border to
  @param config table - Configuration options:
    - thickness number (default 2) - Border thickness in pixels
    - color table (default white) - {r, g, b, a} color values (0-1)
    - layer string (default "BORDER") - Draw layer for textures
    - hidden boolean (default false) - Start hidden if true
  @return table - Border object with show(), hide(), setColor(r,g,b,a) methods
]]
function uiUtils:createBorder(frame, config)
    if not frame then
        utils:error("createBorder: frame required")
        return nil
    end
    
    config = config or {}
    local thickness = config.thickness or 2
    local color = config.color or {r = 1, g = 1, b = 1, a = 1}
    local layer = config.layer or "BORDER"
    local hidden = config.hidden or false
    
    -- Normalize color format (support both {r,g,b,a} and {1,2,3,4} arrays)
    local r = color.r or color[1] or 1
    local g = color.g or color[2] or 1
    local b = color.b or color[3] or 1
    local a = color.a or color[4] or 1
    
    -- Create border object to return
    local border = {}
    
    -- Top edge
    border.top = frame:CreateTexture(nil, layer)
    border.top:SetHeight(thickness)
    border.top:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    border.top:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    border.top:SetColorTexture(r, g, b, a)
    
    -- Bottom edge
    border.bottom = frame:CreateTexture(nil, layer)
    border.bottom:SetHeight(thickness)
    border.bottom:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    border.bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border.bottom:SetColorTexture(r, g, b, a)
    
    -- Left edge
    border.left = frame:CreateTexture(nil, layer)
    border.left:SetWidth(thickness)
    border.left:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    border.left:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    border.left:SetColorTexture(r, g, b, a)
    
    -- Right edge
    border.right = frame:CreateTexture(nil, layer)
    border.right:SetWidth(thickness)
    border.right:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    border.right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    border.right:SetColorTexture(r, g, b, a)
    
    -- Apply initial visibility
    if hidden then
        border.top:Hide()
        border.bottom:Hide()
        border.left:Hide()
        border.right:Hide()
    end
    
    --[[
      Show all border edges
    ]]
    function border:show()
        self.top:Show()
        self.bottom:Show()
        self.left:Show()
        self.right:Show()
    end
    
    --[[
      Hide all border edges
    ]]
    function border:hide()
        self.top:Hide()
        self.bottom:Hide()
        self.left:Hide()
        self.right:Hide()
    end
    
    --[[
      Set border color
      @param r number - Red (0-1)
      @param g number - Green (0-1)
      @param b number - Blue (0-1)
      @param a number|nil - Alpha (0-1, default 1)
    ]]
    function border:setColor(r, g, b, a)
        a = a or 1
        self.top:SetColorTexture(r, g, b, a)
        self.bottom:SetColorTexture(r, g, b, a)
        self.left:SetColorTexture(r, g, b, a)
        self.right:SetColorTexture(r, g, b, a)
    end
    
    --[[
      Check if border is currently visible
      @return boolean - True if any edge is shown
    ]]
    function border:isShown()
        return self.top:IsShown()
    end
    
    return border
end


--[[
  ============================================================================
  COLOR UTILITIES
  ============================================================================
]]

--[[ 
  Convert RGB values (0-1 range) to WoW color code
  @param r number - Red (0-1)
  @param g number - Green (0-1)
  @param b number - Blue (0-1)
  @return string - Color code "|cffRRGGBB"
]]
function uiUtils:rgbToCode(r, g, b)
  return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

--[[
  Dim a color by a factor
  @param color table - {r, g, b, a} where values are 0-1
  @param factor number - Dimming factor (0-1, where 0.5 = 50% brightness)
  @return table - New color {r, g, b, a}
]]
function uiUtils:dimColor(color, factor)
  return {
    r = color.r * factor,
    g = color.g * factor,
    b = color.b * factor,
    a = color.a or 1
  }
end

--[[
  Get color code from rarity index
  @param rarity number - Rarity index (0=Poor, 1=Common, 2=Uncommon, 3=Rare)
  @return string - Color code "|cffRRGGBB"
]]
function uiUtils:rarityToCode(rarity)
  local constants = Addon.constants
  if not constants or not constants.RARITY_COLORS then
    return "|cffffffff"  -- White fallback
  end
  
  local color = constants.RARITY_COLORS[rarity] or {r=1, g=1, b=1}
  return self:rgbToCode(color.r, color.g, color.b)
end

--[[
  Strip WoW color codes from text.
  Removes |cAARRGGBB and |r sequences, returning plain text.
  
  @param text string - Text potentially containing color codes
  @return string - Clean text without color codes
]]
function uiUtils:stripColorCodes(text)
  if type(text) ~= "string" then return "" end
  return text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

--[[
  ============================================================================
  ELEMENT VISIBILITY
  ============================================================================
]]

--[[
  Hide multiple elements safely
  @param elements table - Array of frames/regions to hide
]]
function uiUtils:hideElements(elements)
  for _, element in ipairs(elements) do
    if element then
      element:Hide()
    else
      if Addon.utils then
        Addon.utils:debug("hideElements: nil element encountered")
      end
    end
  end
end

--[[
  Show multiple elements safely
  @param elements table - Array of frames/regions to show
]]
function uiUtils:showElements(elements)
  for _, element in ipairs(elements) do
    if element then
      element:Show()
    else
      if Addon.utils then
        Addon.utils:debug("showElements: nil element encountered")
      end
    end
  end
end

--[[
  ============================================================================
  FRAME CLEANUP
  ============================================================================
]]

--[[
  Clear all children from a frame
  @param frame frame - Parent frame
]]
function uiUtils:clearChildren(frame)
  local children = {frame:GetChildren()}
  for _, child in ipairs(children) do
    child:Hide()
    child:SetParent(nil)
  end
end

--[[
  Clear all regions from a frame
  @param frame frame - Parent frame
  @param skipSelf boolean - If true, don't remove the frame itself
]]
function uiUtils:clearRegions(frame, skipSelf)
  local regions = {frame:GetRegions()}
  for _, region in ipairs(regions) do
    if not skipSelf or region ~= frame then
      region:Hide()
      region:SetParent(nil)
    end
  end
end

--[[
  ============================================================================
  INFO PANEL HELPERS
  ============================================================================
]]

--[[
  Create a standard info icon
  @param parent frame - Parent frame
  @param size number - Icon size (default 16)
  @return texture - Icon texture
]]
function uiUtils:createInfoIcon(parent, size)
  local iconSize = size or 16
  local icon = parent:CreateTexture(nil, "ARTWORK")
  icon:SetSize(iconSize, iconSize)
  icon:SetTexture("Interface\\Common\\help-i")
  return icon
end

--[[
  Create wrapped text with icon spacing
  @param parent frame - Parent frame
  @param yOffset number - Y offset from top
  @param hasIcon boolean - If true, add spacing for icon (26px), else 4px
  @return fontstring - Text element
]]
function uiUtils:createWrappedText(parent, yOffset, hasIcon)
  local xOffset = hasIcon and 26 or 4  -- Icon (16) + spacing (10) = 26
  local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
  text:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, yOffset)
  text:SetJustifyH("LEFT")
  text:SetWordWrap(true)
  return text
end

--[[
  ============================================================================
  POSITIONING
  ============================================================================
]]

--[[
  Clear all points and set a new position
  @param frame frame - Frame to position
  @param ... - Arguments for SetPoint
]]
function uiUtils:setPosition(frame, ...)
  frame:ClearAllPoints()
  frame:SetPoint(...)
end

--[[
  ============================================================================
  LAYOUT
  ============================================================================
]]

--[[
  Distribute width across columns with proper remainder handling
  @param totalWidth number - Total width to distribute
  @param numColumns number - Number of columns
  @param gaps number - Total gap width to subtract
  @return table - Array of column widths
]]
function uiUtils:distributeWidth(totalWidth, numColumns, gaps)
  local contentWidth = totalWidth - gaps
  local baseWidth = math.floor(contentWidth / numColumns)
  local remainder = contentWidth - (baseWidth * numColumns)
  
  local widths = {}
  for i = 1, numColumns do
    widths[i] = baseWidth
  end
  
  -- Distribute remainder:
  -- 1px: add to middle column
  -- 2px: add to 1st and 3rd columns
  if remainder == 1 then
    widths[math.ceil(numColumns / 2)] = baseWidth + 1
  elseif remainder == 2 then
    widths[1] = baseWidth + 1
    widths[numColumns] = baseWidth + 1
  end
  
  return widths
end

--[[
  Show family matchup tooltip with passive, damage taken, and damage dealt
  Used by team section coverage icons and info section family name hover.
  
  @param petType number - Pet family type ID (1-10)
  @param anchorFrame frame - Frame to anchor tooltip to
  @param opts table - Optional settings: {showClickHints = boolean (default true)}
]]
function uiUtils:showFamilyMatchupTooltip(petType, anchorFrame, opts)
  local familyUtils = Addon.familyUtils
  local tip = Addon.tooltip
  local constants = Addon.constants
  if not petType or not familyUtils or not tip or not constants then return end

  opts = opts or {}
  local showClickHints = opts.showClickHints ~= false  -- default true

  local displayName = _G["BATTLE_PET_NAME_" .. petType] or familyUtils:getFamilyNameFromType(petType) or "Unknown"
  displayName = familyUtils:capitalize(displayName)

  -- Layout constants
  local INLINE_ICON_SIZE = 18
  local ICON_PADDING_RIGHT = 8
  local ICON_TEXT_GAP = 8
  local ICON_ALPHA = 0.6
  local MIN_ICON_SIZE = 48
  local TIP_WIDTH = 340
  local TIP_PADDING_LEFT = 12

  -- Tooltip internal padding (mirrors ui/shared/tooltips.lua)
  local TIP_PADDING_TOP = 12
  local HEADER_HEIGHT_EST = 14

  -- Calculate passive max width: from left padding to icon left edge minus gap
  -- Icon left edge = TIP_WIDTH - ICON_PADDING_RIGHT - iconSize
  -- Use MIN_ICON_SIZE for initial calculation (conservative)
  local passiveMaxWidth = TIP_WIDTH - TIP_PADDING_LEFT - ICON_PADDING_RIGHT - MIN_ICON_SIZE - ICON_TEXT_GAP

  -- Arrow texture strings (14px inline, -2 y offset to center with text)
  local ARROW_UP = "|TInterface\\Buttons\\UI-MicroStream-Green:14:14:0:-2:32:32:0:32:32:0|t"
  local ARROW_DOWN = "|TInterface\\Buttons\\UI-MicroStream-Red:14:14:0:-2|t"

  -- Get texcoords for inline matchup icons
  local strongCoords = STYLE_TEXCOORDS["strong"]

  -- Helper to build inline icon string with strong texcoords
  local function inlineIcon(familyId)
    local iconPath = constants.FAMILY_ICON_PATHS and constants.FAMILY_ICON_PATHS[familyId]
    if not iconPath then return "" end
    return string.format("|T%s:%d:%d:0:0:128:256:%d:%d:%d:%d|t",
      iconPath, INLINE_ICON_SIZE, INLINE_ICON_SIZE,
      math.floor(strongCoords[1] * 128), math.floor(strongCoords[2] * 128),
      math.floor(strongCoords[3] * 256), math.floor(strongCoords[4] * 256))
  end

  -- Get passive text early for icon height measurement
  local passive = familyUtils:getPassive(petType)
  local iconFileID = constants.PET_FAMILY_ICON_IDS and constants.PET_FAMILY_ICON_IDS[petType]

  -- Calculate icon height: spans just the passive text
  -- Add buffer for line spacing (spacing=2, estimate ~2 line breaks)
  local iconHeight = 0
  local LINE_SPACING_BUFFER = 6
  if iconFileID and passive then
    local passiveTextHeight = measureTextHeight(passive, passiveMaxWidth)
    iconHeight = passiveTextHeight + LINE_SPACING_BUFFER
    iconHeight = math.max(iconHeight, MIN_ICON_SIZE)
    
    -- Recalculate passiveMaxWidth based on actual icon size
    passiveMaxWidth = TIP_WIDTH - TIP_PADDING_LEFT - ICON_PADDING_RIGHT - iconHeight - ICON_TEXT_GAP
  end

  tip:show(anchorFrame)

  -- Header: just the family name, no inline icon
  tip:header(displayName, {color = {1, 0.82, 0}})

  -- Ensure tooltip is wide enough for icon + text
  tip:minWidth(iconFileID and TIP_WIDTH or 200)

  -- Passive section (no caption - header establishes context)
  if passive then
    tip:text(passive, {wrap = true, color = {1, 1, 1}, maxWidth = iconFileID and passiveMaxWidth or 260})
  end

  -- Clean up legacy textures from previous tooltip approaches
  local tipFrame = tip:frame()
  if tipFrame.passiveBg then tipFrame.passiveBg:Hide() end
  if tipFrame.customSeparator then tipFrame.customSeparator:Hide() end
  if tipFrame.familyLargeIcon then tipFrame.familyLargeIcon:Hide() end

  -- Damage Taken: (defensive)
  -- Arrow colors are semantic: red = bad (more damage), green = good (less damage)
  local RED_ARROW_UP = "|TInterface\\Buttons\\UI-MicroStream-Red:14:14:0:-2:32:32:0:32:32:0|t"
  local GREEN_ARROW_DOWN = "|TInterface\\Buttons\\UI-MicroStream-Green:14:14:0:-2|t"

  local weakTo = familyUtils:getWeakAgainstFamily(petType)
  local resistsTo = familyUtils:getResistantToFamily(petType)
  tip:space(16)
  tip:text("Damage Taken:", {color = {1, 0.82, 0}, font = "header"})
  tip:space(5)

  if resistsTo then
    local resistName = _G["BATTLE_PET_NAME_" .. resistsTo] or familyUtils:getFamilyNameFromType(resistsTo) or "Unknown"
    tip:text(GREEN_ARROW_DOWN .. " |cff4dff4d33% less|r from " .. inlineIcon(resistsTo) .. " " .. familyUtils:capitalize(resistName) .. " abilities", {color = {1, 1, 1}})
  end

  if weakTo then
    local weakName = _G["BATTLE_PET_NAME_" .. weakTo] or familyUtils:getFamilyNameFromType(weakTo) or "Unknown"
    tip:text(RED_ARROW_UP .. " |cffff4d4d50% more|r from " .. inlineIcon(weakTo) .. " " .. familyUtils:capitalize(weakName) .. " abilities", {color = {1, 1, 1}})
  end

  -- Damage Dealt: (offensive)
  local strongVs = familyUtils:getStrongVsTarget(petType)
  local weakOffense = familyUtils:getWeakOffenseTarget(petType)
  tip:space(11)
  tip:text("Damage Dealt:", {color = {1, 0.82, 0}, font = "header"})
  tip:space(5)

  if strongVs then
    local strongName = _G["BATTLE_PET_NAME_" .. strongVs] or familyUtils:getFamilyNameFromType(strongVs) or "Unknown"
    tip:text(ARROW_UP .. " |cff4dff4d50% more|r to " .. inlineIcon(strongVs) .. " " .. familyUtils:capitalize(strongName) .. " pets", {color = {1, 1, 1}})
  end

  if weakOffense then
    local weakOffName = _G["BATTLE_PET_NAME_" .. weakOffense] or familyUtils:getFamilyNameFromType(weakOffense) or "Unknown"
    tip:text(ARROW_DOWN .. " |cffff4d4d33% less|r to " .. inlineIcon(weakOffense) .. " " .. familyUtils:capitalize(weakOffName) .. " pets", {color = {1, 1, 1}})
  end

  -- Click hints section (optional)
  if showClickHints then
    local familyName = familyUtils:getFamilyNameFromType(petType) or "unknown"
    local filterToken = "family:" .. familyName
    tip:hints(uiUtils:getFilterHints(filterToken), {separator = true})
  end

  tip:done()

  -- Post-done: add family portrait icon
  -- Done after tip:done() so the frame is sized and anchoring is deterministic.
  if iconFileID and passive then
    local familyIcon = tip:texture("familyMatchupIcon")
    familyIcon:ClearAllPoints()
    familyIcon:SetSize(iconHeight, iconHeight)
    familyIcon:SetTexture(iconFileID)
    familyIcon:SetAlpha(ICON_ALPHA)
    -- Position at passive text start: header + some offset
    local iconY = -(TIP_PADDING_TOP + HEADER_HEIGHT_EST + 9)
    familyIcon:SetPoint("TOPRIGHT", tipFrame, "TOPRIGHT", -ICON_PADDING_RIGHT, iconY)
    familyIcon:Show()
  end
end

--[[
  Set family icon texture with correct texcoords for the specified style.
  
  @param texture texture - The texture object to configure
  @param petType number - Pet family type ID (1-10)
  @param style string - Required. One of: "large", "strong", "faded-color", "faded-dark"
  @return boolean - true if texture was set successfully
]]
function uiUtils:setFamilyIcon(texture, petType, style)
  local constants = Addon.constants
  if not texture or not petType or not constants then return false end
  if not style or not STYLE_TEXCOORDS[style] then return false end
  
  local iconPath = constants.FAMILY_ICON_PATHS and constants.FAMILY_ICON_PATHS[petType]
  if not iconPath then return false end
  
  texture:SetTexture(iconPath)
  
  -- Select texcoords based on style
  -- Mechanical (10) needs flipped texcoords for faded-color style only
  local texCoord
  if style == "faded-color" and petType == 10 then
    texCoord = FADED_COLOR_FLIPPED
  else
    texCoord = STYLE_TEXCOORDS[style]
  end
  
  texture:SetTexCoord(unpack(texCoord))
  texture:SetVertexColor(1, 1, 1)
  
  return true
end

-- Amber color for caged-pet badge icons
local BADGE_CAGE_COLOR = {0.9, 0.6, 0.1}

--[[
  Render badge icons into pre-created badge icon frames.

  Clears all badge frames first, then positions, textures, colors, and shows
  whichever entries are in the buffer. Callers are responsible for building
  the buffer; this function owns only the presentation.

  Positioning rules:
    1 badge  — identity badges (unique/duplicate) anchor LEFT; cage anchors RIGHT
    2 badges — badge[1] anchors LEFT, badge[2] anchors RIGHT

  Coloring rule: tooltip == "Caged" -> amber; everything else -> white.

  @param badgeIcons table  - Array of 2 pre-created icon frames (each with .icon texture child)
  @param badgeFrame frame  - Parent badge frame used as anchor
  @param buffer    table  - Array of {texture=string, tooltip=string} entries (0-2 entries)
]]
function uiUtils:renderBadges(badgeIcons, badgeFrame, buffer)
    -- Always clear first so stale frames from previous renders don't linger
    for i = 1, 2 do
        badgeIcons[i]:Hide()
        badgeIcons[i].tooltipText = nil
    end

    local count = #buffer
    if count == 0 then return end

    if count == 1 then
        local badge = buffer[1]
        local icon = badgeIcons[1]
        icon.icon:SetTexture(badge.texture)
        icon.tooltipText = badge.tooltip
        icon:ClearAllPoints()
        -- Identity badges (unique diamond / duplicate dot) sit on the left;
        -- cage icon sits on the right so the two slots never visually swap.
        if badge.tooltip == "Unique" or badge.tooltip:find("of this breed") then
            icon:SetPoint("LEFT", badgeFrame, "LEFT", 2, 0)
        else
            icon:SetPoint("RIGHT", badgeFrame, "RIGHT", -2, 0)
        end
        if badge.tooltip == "Caged" then
            icon.icon:SetVertexColor(unpack(BADGE_CAGE_COLOR))
        else
            icon.icon:SetVertexColor(1, 1, 1)
        end
        icon:Show()
    else
        -- Slot 1: always LEFT (identity badge)
        local b1 = buffer[1]
        local i1 = badgeIcons[1]
        i1.icon:SetTexture(b1.texture)
        i1.tooltipText = b1.tooltip
        i1:ClearAllPoints()
        i1:SetPoint("LEFT", badgeFrame, "LEFT", 2, 0)
        if b1.tooltip == "Caged" then
            i1.icon:SetVertexColor(unpack(BADGE_CAGE_COLOR))
        else
            i1.icon:SetVertexColor(1, 1, 1)
        end
        i1:Show()

        -- Slot 2: always RIGHT (cage badge)
        local b2 = buffer[2]
        local i2 = badgeIcons[2]
        i2.icon:SetTexture(b2.texture)
        i2.tooltipText = b2.tooltip
        i2:ClearAllPoints()
        i2:SetPoint("RIGHT", badgeFrame, "RIGHT", -2, 0)
        if b2.tooltip == "Caged" then
            i2.icon:SetVertexColor(unpack(BADGE_CAGE_COLOR))
        else
            i2.icon:SetVertexColor(1, 1, 1)
        end
        i2:Show()
    end
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("uiUtils", {"utils"}, function()
        return true
    end)
end

Addon.uiUtils = uiUtils
return uiUtils