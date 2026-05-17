--[[
  ui/shared/theme/style/elvui.lua
  ElvUI skinning strategy.

  Implements all 15 skinning methods using ElvUI's Skins module where it
  provides analogous handlers, and falling through to ElvUI's template
  system (SetTemplate) where it doesn't.

  ElvUI's Skins API is not stable across ElvUI versions; every method that
  calls into S:Handle* checks existence first.

  When falling back to stock for a method (skinTooltip, skinSeparator,
  skinProgressBar, skinStatusBar in some cases), we reach for the stock
  strategy via theme.style.strategies.stock.

  Dependencies: theme
  Exports: registers itself onto Addon.theme.style.strategies.elvui
]]

local ADDON_NAME, Addon = ...

local theme = Addon.theme

-- Defensive lookup of ElvUI's Skins module. Returns nil if ElvUI isn't
-- loaded or if the Skins module isn't registered. The Skins API surface
-- is verified at the call site (existence checks per method name).
local function elvuiSkins()
    if not _G.ElvUI then return nil end
    local E = _G.ElvUI[1]
    if not E or not E.GetModule then return nil end
    return E:GetModule("Skins", true)  -- silent: returns nil if not registered
end

local elvui = {
    detect = function() return _G.ElvUI ~= nil end,
}

function elvui:skinPanel(frame, options)
    if frame.SetTemplate then
        frame:SetTemplate("Transparent")
    end
end

function elvui:skinTab(button, isActive, options)
    local S = elvuiSkins()
    if S and S.HandleTab then
        S:HandleTab(button)
    elseif S and S.HandleButton then
        S:HandleButton(button)
    end
end

function elvui:skinHeader(frame, options)
    if frame.SetTemplate then
        frame:SetTemplate("Default")
    end
end

function elvui:skinTitlebar(frame, text)
    -- ElvUI strips chrome; nowhere conventional to anchor a titlebar.
    -- Intentional no-op.
end

function elvui:skinPopup(frame, options)
    if frame.SetTemplate then
        frame:SetTemplate("Transparent")
    end
    frame:SetFrameStrata((options and options.strata) or "DIALOG")
end

function elvui:skinTooltip(frame, options)
    -- ElvUI's tooltip module skins tooltips itself when registered.
    -- Stock fallback if the module isn't present.
    local S = elvuiSkins()
    if not S then
        local stock = theme.style.strategies.stock
        if stock and stock.skinTooltip then
            stock:skinTooltip(frame, options)
        end
    end
end

function elvui:skinCard(frame, options)
    if frame.SetTemplate then
        frame:SetTemplate("Default")
    end
end

function elvui:skinScrollbar(bar, options)
    local S = elvuiSkins()
    if S and S.HandleScrollBar then
        S:HandleScrollBar(bar)
    end
end

function elvui:skinDropdown(frame, options)
    local S = elvuiSkins()
    if S and S.HandleDropDownBox then
        S:HandleDropDownBox(frame)
    elseif frame.SetTemplate then
        frame:SetTemplate("Default")
    end
end

function elvui:skinEditBox(box, options)
    -- PawnShop's existing behavior: leave the textBox widget alone.
    -- ElvUI's HandleEditBox doesn't expect BackdropTemplate, so the
    -- fall-through here is intentional.
end

function elvui:skinButton(button, options)
    local S = elvuiSkins()
    if S and S.HandleButton then
        S:HandleButton(button)
    end
end

function elvui:skinCheckbox(checkbox, options)
    local S = elvuiSkins()
    if S and S.HandleCheckBox then
        S:HandleCheckBox(checkbox)
    end
end

function elvui:skinSeparator(line, options)
    -- ElvUI separators are typically too small for ElvUI to have strong
    -- opinions about; behave as stock.
    local stock = theme.style.strategies.stock
    if stock and stock.skinSeparator then
        stock:skinSeparator(line, options)
    end
end

function elvui:skinProgressBar(bar, options)
    local S = elvuiSkins()
    if S and S.HandleStatusBar then
        S:HandleStatusBar(bar)
    else
        local stock = theme.style.strategies.stock
        if stock and stock.skinProgressBar then
            stock:skinProgressBar(bar, options)
        end
    end
end

function elvui:skinStatusBar(bar, options)
    local S = elvuiSkins()
    if S and S.HandleStatusBar then
        S:HandleStatusBar(bar)
    else
        local stock = theme.style.strategies.stock
        if stock and stock.skinStatusBar then
            stock:skinStatusBar(bar, options)
        end
    end
end

theme.style.strategies.elvui = elvui

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("theme.style.elvui", { "theme" }, function()
        theme.style.refreshSelection()
        return true
    end)
end

return elvui
