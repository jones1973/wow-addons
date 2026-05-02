--[[
  ui/shared/panel.lua   [SHARED: sync with monorepo shared/ui/panel.lua]
  Panel frame factories

  Common panel patterns that would otherwise get copy-pasted across addons.
  Right now there's one factory: :opaque(), which creates a backdrop-framed
  frame with a solid (non-textured) fill color.

  Why opaque() exists: SetBackdropColor alpha has no effect on the stock
  UI-Tooltip-Background texture because that texture has per-pixel alpha
  baked into it. Replacing the bgFile with Interface\Buttons\WHITE8X8 (a
  solid 1x1 texture) makes the tint the whole fill, which is how you
  actually get a fully opaque panel.

  Dependencies: none
  Exports: Addon.panel
]]

local ADDON_NAME, Addon = ...

local panel = {}

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Create an opaque-fill panel with a decorative border.

  @param parent Frame - parent frame
  @param opts table|nil - options table:
      r, g, b, a   = fill color          (default 0.05, 0.05, 0.07, 1.0)
      edgeFile     = border texture path (default tooltip border)
      edgeSize     = border edge size    (default 12)
      insets       = backdrop insets     (default {3,3,3,3}); pass a table
                     with left/right/top/bottom keys to override per side
      name         = frame name          (default nil / anonymous)
      strata       = frame strata        (default inherited from parent)
      level        = frame level         (default parent level + 10)
      parentStrata = if true, copy parent:GetFrameStrata() onto the panel.
                     Useful when the panel is a child but needs to render
                     above siblings at the same strata.
  @return Frame - the panel frame
]]
function panel:opaque(parent, opts)
    opts = opts or {}

    local insets = opts.insets or {
        left = 3, right = 3, top = 3, bottom = 3,
    }

    local frame = CreateFrame("Frame", opts.name, parent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = opts.edgeFile or "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false,
        edgeSize = opts.edgeSize or 12,
        insets   = insets,
    })

    frame:SetBackdropColor(
        opts.r or 0.05,
        opts.g or 0.05,
        opts.b or 0.07,
        opts.a or 1.0
    )

    if opts.strata then
        frame:SetFrameStrata(opts.strata)
    elseif opts.parentStrata and parent and parent.GetFrameStrata then
        frame:SetFrameStrata(parent:GetFrameStrata())
    end

    if opts.level then
        frame:SetFrameLevel(opts.level)
    elseif parent and parent.GetFrameLevel then
        frame:SetFrameLevel(parent:GetFrameLevel() + 10)
    end

    return frame
end

Addon.panel = panel
return panel
