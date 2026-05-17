--[[
  ui/shared/theme/style/stock.lua
  Stock skinning strategy — the always-available reference implementation.

  Implements all 15 skinning methods using Blizzard textures, BackdropTemplate,
  and direct token application. Always detects true; serves as the floor that
  every other strategy can fall back to method-by-method.

  Dependencies: theme
  Exports: registers itself onto Addon.theme.style.strategies.stock
]]

local ADDON_NAME, Addon = ...

-- theme is a hard dependency declared via registerModule. The dependency
-- resolver guarantees theme initializes before this strategy's init runs,
-- but the file-load body below executes immediately when this file loads —
-- which is also after theme.lua's file-load (per .toc / files.xml order).
local theme = Addon.theme

local stock = {
    detect = function() return true end,  -- always available
}

function stock:skinPanel(frame, options)
    if not frame.SetBackdrop then return end
    local s = (options and options.level == "RAISED")
        and theme.tokens.SURFACE.PANEL_RAISED
        or theme.tokens.SURFACE.PANEL_BASE

    if not (options and options.noBorder) then
        frame:SetBackdrop(theme.backdrops.PANEL)
        if frame.SetBackdropColor then
            frame:SetBackdropColor(s.r, s.g, s.b, s.a)
        end
    else
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            tile   = false,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        if frame.SetBackdropColor then
            frame:SetBackdropColor(s.r, s.g, s.b, s.a)
        end
    end
end

function stock:skinTab(button, isActive, options)
    if not button then return end
    local t = theme.tokens.TAB

    if not button._themeBg then
        button._themeBg = button:CreateTexture(nil, "BACKGROUND")
        button._themeBg:SetAllPoints()
    end

    local bg = isActive and t.ACTIVE_BG or t.INACTIVE_BG
    button._themeBg:SetColorTexture(bg.r, bg.g, bg.b, bg.a or 1.0)

    local fs = button.GetFontString and button:GetFontString()
    if fs then
        local tc = isActive and t.ACTIVE_TEXT or t.INACTIVE_TEXT
        fs:SetTextColor(tc.r, tc.g, tc.b)
    end

    if options and options.selectedAccent and isActive then
        if not button._themeAccent then
            button._themeAccent = button:CreateTexture(nil, "OVERLAY")
            button._themeAccent:SetHeight(2)
            button._themeAccent:SetPoint("BOTTOMLEFT")
            button._themeAccent:SetPoint("BOTTOMRIGHT")
        end
        local ac = t.ACTIVE_BORDER
        button._themeAccent:SetColorTexture(ac.r, ac.g, ac.b, ac.a or 1.0)
        button._themeAccent:Show()
    elseif button._themeAccent then
        button._themeAccent:Hide()
    end
end

function stock:skinHeader(frame, options)
    if not frame.SetBackdrop then return end

    local bg = theme.tokens.HEADER.BG
    local label = theme.tokens.HEADER.LABEL

    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        tile   = false,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    if frame.SetBackdropColor then
        frame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a or 1.0)
    end

    if frame.label and frame.label.SetTextColor then
        frame.label:SetTextColor(label.r, label.g, label.b)
    end

    if options and options.brandTinted and theme.tokens.BRAND and theme.tokens.BRAND.SELECTION_TINT_LOW then
        if not frame._themeBrandOverlay then
            frame._themeBrandOverlay = frame:CreateTexture(nil, "BORDER")
            frame._themeBrandOverlay:SetAllPoints()
        end
        local tint = theme.tokens.BRAND.SELECTION_TINT_LOW
        frame._themeBrandOverlay:SetColorTexture(tint.r, tint.g, tint.b, tint.a)
    end
end

function stock:skinTitlebar(frame, text)
    if not frame then return end
    if not frame._themeTitle then
        frame._themeTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame._themeTitle:SetPoint("TOP", 0, -18)
    end
    frame._themeTitle:SetText(text or "")
end

function stock:skinPopup(frame, options)
    if not frame.SetBackdrop then return end
    local s = theme.tokens.SURFACE.OVERLAY

    if options and options.solidBackground then
        s = theme.derive.makeToken(s.r, s.g, s.b, 1.0)
    end

    frame:SetBackdrop(theme.backdrops.POPUP)
    if frame.SetBackdropColor then
        frame:SetBackdropColor(s.r, s.g, s.b, s.a)
    end
    frame:SetFrameStrata((options and options.strata) or "DIALOG")
end

function stock:skinTooltip(frame, options)
    if not frame.SetBackdrop then return end
    local s = theme.tokens.SURFACE.OVERLAY
    frame:SetBackdrop(theme.backdrops.TOOLTIP)
    if frame.SetBackdropColor then
        frame:SetBackdropColor(s.r, s.g, s.b, s.a)
    end
end

function stock:skinCard(frame, options)
    if not frame.SetBackdrop then return end
    local s = theme.tokens.SURFACE.PANEL_RAISED
    local edge = theme.tokens.NEUTRAL.L4

    frame:SetBackdrop(theme.backdrops.CARD)
    if frame.SetBackdropColor then
        frame:SetBackdropColor(s.r, s.g, s.b, s.a)
    end
    if frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(edge.r, edge.g, edge.b, edge.a or 1.0)
    end

    if options and options.selected and theme.tokens.BRAND and theme.tokens.BRAND.SELECTION_TINT_HIGH then
        local tint = theme.tokens.BRAND.SELECTION_TINT_HIGH
        if frame.SetBackdropColor then
            frame:SetBackdropColor(tint.r, tint.g, tint.b, tint.a)
        end
    end
end

function stock:skinScrollbar(bar, options)
    if not bar then return end
    local thumb = bar.GetThumbTexture and bar:GetThumbTexture()
    if thumb and thumb.SetVertexColor then
        local n = theme.tokens.NEUTRAL.L4
        thumb:SetVertexColor(n.r, n.g, n.b, 0.8)
    end
end

function stock:skinDropdown(frame, options)
    if not frame then return end
    if frame.SetBackdrop then
        local s = theme.tokens.SURFACE.PANEL_RAISED
        frame:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = false,
            edgeSize = 8,
            insets   = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        if frame.SetBackdropColor then
            frame:SetBackdropColor(s.r, s.g, s.b, s.a)
        end
    end
end

function stock:skinEditBox(box, options)
    -- Stock leaves the textBox widget's BackdropTemplate alone — designed
    -- to match stock parchment. Intentional no-op.
end

function stock:skinButton(button, options)
    -- Stock leaves UIPanelButtonTemplate alone — already matches stock parchment.
    -- For non-template buttons with an explicit style, future expansion handles
    -- the FLAT/GRADIENT/DARK_PRO/OUTLINED styles.
end

function stock:skinCheckbox(checkbox, options)
    if not checkbox then return end
    local label = _G[checkbox:GetName() .. "Text"]
    if label and label.SetTextColor then
        local t = theme.tokens.TEXT.PRIMARY
        label:SetTextColor(t.r, t.g, t.b)
    end
end

function stock:skinSeparator(line, options)
    if not line or not line.SetColorTexture then return end
    local s = (options and options.tint == "BRAND")
        and theme.tokens.SEPARATOR.BRAND
        or theme.tokens.SEPARATOR.DEFAULT
    line:SetColorTexture(s.r, s.g, s.b, s.a)
end

function stock:skinProgressBar(bar, options)
    if not bar then return end
    options = options or {}

    local bg = theme.tokens.BAR.BACKGROUND
    if bar.SetStatusBarColor then
        local fill
        local fillTokenName = options.fillToken or "DEFAULT"
        if fillTokenName == "FACTION" and options.factionStanding then
            fill = theme.derive.factionFor(options.factionStanding)
        elseif fillTokenName == "BRAND" then
            fill = theme.tokens.BAR.FILL_BRAND or theme.tokens.BAR.FILL_DEFAULT
        else
            fill = theme.tokens.BAR.FILL_DEFAULT
        end
        if fill then
            bar:SetStatusBarColor(fill.r, fill.g, fill.b, fill.a or 1.0)
        end
    end

    if bar.bg and bar.bg.SetColorTexture then
        bar.bg:SetColorTexture(bg.r, bg.g, bg.b, bg.a or 1.0)
    end
end

function stock:skinStatusBar(bar, options)
    self:skinProgressBar(bar, options)
end

-- Register the strategy at file-load time. theme.style.strategies is
-- created by theme.lua, which loads first per the .toc / files.xml order.
theme.style.strategies.stock = stock

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("theme.style.stock", { "theme" }, function()
        -- Trigger detection in case other strategies registered after us.
        theme.style.refreshSelection()
        return true
    end)
end

return stock
