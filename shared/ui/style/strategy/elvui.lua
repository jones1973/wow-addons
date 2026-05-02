--[[
  shared/style/strategy/elvui.lua
  ElvUI Strategy

  Detection: _G.ElvUI is set when ElvUI is loaded. ElvUI mixes its own
  methods (SetTemplate, StripTextures, CreateBackdrop) into every
  frame's metatable on load, so frames we create automatically have
  those methods available.

  Frame skinning: SetTemplate("Transparent") gives the dark, flat,
  borderless look ElvUI uses for its panels. This matches the styled
  AuctionFrame the user sees with ElvUI loaded.

  Button skinning: ElvUI's Skins module exposes HandleButton which
  strips the Blizzard textures and applies ElvUI's button look.

  EditBox skinning: deliberately omitted. ElvUI's HandleEditBox is
  designed for Blizzard EditBox templates (InputBoxTemplate, etc.).
  Our shared textBox widget uses its own BackdropTemplate-based
  backdrop, which ElvUI's handler doesn't expect. Falling through
  to stock (which is also a no-op for editboxes, since textBox's
  backdrop is good as-is) leaves the textBox alone and avoids
  visual breakage.

  Dependencies: none (pure data registration at file-load time)
  Exports: Addon.style.strategies.elvui
]]

local ADDON_NAME, Addon = ...

Addon.style = Addon.style or {}
Addon.style.strategies = Addon.style.strategies or {}

--[[
  Get ElvUI's Skins module. Returns nil if ElvUI is loaded but the
  module isn't accessible (e.g., very early init). Callers tolerate
  nil and no-op.
]]
local function elvuiSkins()
    if not _G.ElvUI then return nil end
    local E = _G.ElvUI[1]
    if not E or not E.GetModule then return nil end
    -- Second arg `true` means "silent" -- returns nil if module
    -- isn't registered yet rather than erroring.
    return E:GetModule("Skins", true)
end

Addon.style.strategies.elvui = {
    detect = function()
        return _G.ElvUI ~= nil
    end,

    skinFrame = function(frame)
        if frame.SetTemplate then
            frame:SetTemplate("Transparent")
        end
    end,

    skinButton = function(button)
        local S = elvuiSkins()
        if S and S.HandleButton then
            S:HandleButton(button)
        end
    end,

    -- ElvUI strips frame chrome, so there's no chrome titlebar area
    -- to anchor a centered title against. Explicit no-op rather than
    -- falling through to stock (which would place text floating on
    -- ElvUI's flat dark frame, looking out of place).
    skinTitlebar = function(frame, text) end,

    -- skinEditBox intentionally omitted. See file header for rationale.
}
