--[[
  core/tooltipUtils.lua
  Centralized Tooltip Management
  
  Provides consistent tooltip setup/teardown to prevent state bleed between
  different tooltip uses. Manages custom textures, padding, and minimum width.
  
  Usage:
    tooltipUtils:show(owner, anchor)     -- Setup with clean state
    tooltipUtils:addLine(text, r, g, b)  -- Add content
    tooltipUtils:addHint(text)           -- Add gray hint line
    tooltipUtils:finish()                -- Call Show()
    tooltipUtils:hide()                  -- Clean teardown
  
  Dependencies: none (core module)
  Exports: Addon.tooltipUtils
]]

local ADDON_NAME, Addon = ...

local tooltipUtils = {}

-- Track custom textures we've added to GameTooltip
local customTextures = {}

-- Cache default font height (captured once from unmodified tooltip line)
local defaultFontHeight = nil

-- Track pending separator lines (line indices where separators should appear)
local pendingSeparators = {}

--[[
  Get default tooltip font height.
  Captures from actual tooltip line on first call.
  
  @return number - Default font height
]]
local function getDefaultFontHeight()
    if defaultFontHeight then
        return defaultFontHeight
    end
    
    -- Get from first tooltip line before any modifications
    local leftLine = _G["GameTooltipTextLeft1"]
    if leftLine and leftLine.GetFont then
        local _, size = leftLine:GetFont()
        defaultFontHeight = size or 12
    else
        defaultFontHeight = 12  -- Fallback
    end
    
    return defaultFontHeight
end

--[[
  Register a custom texture attached to GameTooltip.
  These will be hidden on tooltip hide.
  
  @param name string - Identifier for the texture
  @param texture texture - The texture object
]]
function tooltipUtils:registerTexture(name, texture)
    customTextures[name] = texture
end

--[[
  Get or create a custom texture on GameTooltip.
  Automatically registers it for cleanup.
  
  @param name string - Identifier for the texture
  @param layer string - Draw layer (default "ARTWORK")
  @return texture
]]
function tooltipUtils:getTexture(name, layer)
    if GameTooltip[name] then
        return GameTooltip[name]
    end
    
    local texture = GameTooltip:CreateTexture(nil, layer or "ARTWORK")
    GameTooltip[name] = texture
    customTextures[name] = texture
    return texture
end

--[[
  Reset tooltip to clean state.
  Clears lines, hides custom textures, resets padding/width/font heights.
]]
function tooltipUtils:reset()
    -- Hide all registered custom textures
    for name, texture in pairs(customTextures) do
        if texture and texture.Hide then
            texture:Hide()
        end
    end
    
    -- Also check for known textures that might exist
    if GameTooltip.abilityFamilyIcon then
        GameTooltip.abilityFamilyIcon:Hide()
    end
    if GameTooltip.swapFamilyIcon then
        GameTooltip.swapFamilyIcon:Hide()
    end
    
    -- Clear pending separator lines
    wipe(pendingSeparators)
    
    -- Reset sizing
    GameTooltip:SetMinimumWidth(0)
    GameTooltip:SetPadding(0, 0)
    
    -- Reset font heights on all tooltip lines (they persist after ClearLines)
    local defaultHeight = getDefaultFontHeight()
    for i = 1, 30 do
        local leftLine = _G["GameTooltipTextLeft" .. i]
        local rightLine = _G["GameTooltipTextRight" .. i]
        
        if leftLine and leftLine.SetFontHeight then
            leftLine:SetFontHeight(defaultHeight)
        end
        if rightLine and rightLine.SetFontHeight then
            rightLine:SetFontHeight(defaultHeight)
        end
    end
    
    -- Clear content
    GameTooltip:ClearLines()
end

--[[
  Show tooltip with clean state.
  Always call this before adding content.
  
  @param owner frame - Frame that owns the tooltip
  @param anchor string - Anchor point (default "ANCHOR_RIGHT")
]]
function tooltipUtils:show(owner, anchor)
    self:reset()
    GameTooltip:SetOwner(owner, anchor or "ANCHOR_RIGHT")
end

--[[
  Add a line of text.
  
  @param text string - Line text
  @param r number - Red (0-1, default 1)
  @param g number - Green (0-1, default 1)
  @param b number - Blue (0-1, default 1)
  @param wrap boolean - Word wrap (default false)
]]
function tooltipUtils:addLine(text, r, g, b, wrap)
    GameTooltip:AddLine(text, r or 1, g or 1, b or 1, wrap or false)
end

--[[
  Add a title line (white, prominent).
  
  @param text string - Title text
]]
function tooltipUtils:addTitle(text)
    GameTooltip:AddLine(text, 1, 1, 1)
end

--[[
  Add a hint line (gray, instructional).
  
  @param text string - Hint text
]]
function tooltipUtils:addHint(text)
    GameTooltip:AddLine(text, 0.7, 0.7, 0.7)
end

--[[
  Add a small vertical spacer.
  Uses SetFontHeight to create precise spacing.
  Note: Font heights are reset by reset() on next tooltip show.
  
  @param height number - Spacer height in pixels (default 3)
]]
function tooltipUtils:addSmallSpacer(height)
    height = height or 3
    GameTooltip:AddLine(" ", 1, 1, 1)
    local numLines = GameTooltip:NumLines()
    local fontString = _G["GameTooltipTextLeft" .. numLines]
    if fontString then
        fontString:SetFontHeight(height)
    end
end

--[[
  Add a blank separator line.
  Uses a space character for standard line height.
]]
function tooltipUtils:addSeparator()
    GameTooltip:AddLine(" ")
end

--[[
  Add a thin horizontal line separator.
  Adds a placeholder line and tracks it for texture creation in finish().
]]
function tooltipUtils:addThinLine()
    -- Add placeholder line (will be overlaid with texture in finish)
    GameTooltip:AddLine(" ")
    
    -- Track which line number this is
    local numLines = GameTooltip:NumLines()
    table.insert(pendingSeparators, numLines)
end

--[[
  Set tooltip header text (clears existing and sets first line).
  Use SetText for single-line tooltips or as first line before AddLine.
  
  @param text string - Header text
  @param r number - Red (0-1, default 1)
  @param g number - Green (0-1, default 1)  
  @param b number - Blue (0-1, default 1)
]]
function tooltipUtils:setText(text, r, g, b)
    GameTooltip:SetText(text, r or 1, g or 1, b or 1)
end

--[[
  Set minimum width for tooltip.
  
  @param width number - Minimum width in pixels
]]
function tooltipUtils:setMinWidth(width)
    GameTooltip:SetMinimumWidth(width or 0)
end

--[[
  Set padding around tooltip content.
  
  @param left number - Left padding
  @param right number - Right padding  
  @param top number - Top padding
  @param bottom number - Bottom padding
]]
--[[
  Set tooltip padding.
  
  @param width number - Right side padding in pixels
  @param height number - Bottom padding in pixels
]]
function tooltipUtils:setPadding(width, height)
    GameTooltip:SetPadding(width or 0, height or 0)
end

--[[
  Finalize and display the tooltip.
  Creates separator line textures at tracked positions.
  Call after adding all content.
]]
function tooltipUtils:finish()
    GameTooltip:Show()
    
    -- Create separator textures at tracked line positions
    if #pendingSeparators > 0 then
        for i, lineNum in ipairs(pendingSeparators) do
            local texName = "separatorLine" .. i
            local tex = self:getTexture(texName, "ARTWORK")
            
            -- Position at the text line location, matching text width
            local textLine = _G["GameTooltipTextLeft" .. lineNum]
            if textLine then
                tex:ClearAllPoints()
                tex:SetHeight(1)
                tex:SetTexture("Interface\\Buttons\\WHITE8X8")
                tex:SetVertexColor(0.4, 0.4, 0.4, 1)
                -- Anchor to text line edges to match content width
                tex:SetPoint("LEFT", textLine, "LEFT", 0, 0)
                tex:SetPoint("RIGHT", GameTooltip, "RIGHT", -12, 0)
                tex:Show()
            end
        end
    end
end

--[[
  Hide tooltip with full cleanup.
  Resets all state to prevent bleed into next tooltip.
]]
function tooltipUtils:hide()
    self:reset()
    GameTooltip:Hide()
end

--[[
  Convenience: Simple one-line tooltip.
  
  @param owner frame - Frame that owns the tooltip
  @param text string - Tooltip text
  @param anchor string - Anchor point (default "ANCHOR_RIGHT")
]]
function tooltipUtils:showSimple(owner, text, anchor)
    self:show(owner, anchor)
    self:addLine(text)
    self:finish()
end

--[[
  Convenience: Tooltip with title and hints.
  
  @param owner frame - Frame that owns the tooltip
  @param title string - Title line
  @param hints table - Array of hint strings
  @param anchor string - Anchor point (default "ANCHOR_RIGHT")
]]
function tooltipUtils:showWithHints(owner, title, hints, anchor)
    self:show(owner, anchor)
    self:addTitle(title)
    
    if hints and #hints > 0 then
        for _, hint in ipairs(hints) do
            self:addHint(hint)
        end
    end
    
    self:finish()
end

--[[
  Get raw GameTooltip for advanced usage.
  Caller is responsible for cleanup via tooltipUtils:hide().
  
  @return frame - GameTooltip
]]
function tooltipUtils:raw()
    return GameTooltip
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("tooltipUtils", {}, function()
    return true
  end)
end

Addon.tooltipUtils = tooltipUtils
return tooltipUtils