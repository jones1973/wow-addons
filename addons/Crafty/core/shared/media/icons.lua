--[[
  core/shared/media/icons.lua
  Shared icon atlas — named glyph access with runtime tinting.

  A single 640x512 atlas (5x4 grid of 128px cells) holds the family's
  button glyphs as GRAYSCALE art. Because the source is neutral, each
  consumer tints glyphs at runtime via SetVertexColor — so one atlas
  serves every addon, colored to whatever that addon wants. Glyphs are
  theme-agnostic content; the button frame around them is theme-provided.

  Default tint is gold (a complementary metallic that contrasts against
  branded chrome rather than melting into it — the brand color stays in
  the chrome, not the buttons). Close is the conventional exception: red.

  Consumers reference glyphs BY NAME, never raw coordinates.

  Dependencies: none (pure data + setters)
  Exports: Addon.icons
]]

local ADDON_NAME, Addon = ...

-- Texture path MUST include the .png extension. (Unlike legacy .tga/.blp,
-- PNG textures are not found without it — a missing extension renders
-- nothing, silently.)
local PATH = "Interface\\AddOns\\" .. ADDON_NAME .. "\\core\\shared\\media\\icons.png"

-- SetTexCoord normalized rects: { left, right, top, bottom }
local COORDS = {
    info             = { 0.0, 0.2, 0.0,  0.25 },
    help             = { 0.2, 0.4, 0.0,  0.25 },
    settings         = { 0.4, 0.6, 0.0,  0.25 },
    close            = { 0.6, 0.8, 0.0,  0.25 },
    clear            = { 0.8, 1.0, 0.0,  0.25 },
    filter           = { 0.0, 0.2, 0.25, 0.5  },
    sort             = { 0.2, 0.4, 0.25, 0.5  },
    search           = { 0.4, 0.6, 0.25, 0.5  },
    refresh          = { 0.6, 0.8, 0.25, 0.5  },
    expand           = { 0.8, 1.0, 0.25, 0.5  },
    about            = { 0.0, 0.2, 0.5,  0.75 },
    reset            = { 0.2, 0.4, 0.5,  0.75 },
    export           = { 0.4, 0.6, 0.5,  0.75 },
    pushpin          = { 0.6, 0.8, 0.5,  0.75 },
    padlock_locked   = { 0.8, 1.0, 0.5,  0.75 },
    padlock_unlocked = { 0.0, 0.2, 0.75, 1.0  },
    scan             = { 0.2, 0.4, 0.75, 1.0  },
    sound            = { 0.4, 0.6, 0.75, 1.0  },
    -- Cooldown clock/stopwatch. Glyph art to be added to this cell; coords
    -- reserve the next open slot in the atlas grid.
    cooldown         = { 0.6, 0.8, 0.75, 1.0  },
}

-- Default tints. Grayscale art multiplies cleanly under SetVertexColor.
local TINT_GOLD = { r = 1.00, g = 0.82, b = 0.30 }
local TINT_RED  = { r = 0.85, g = 0.20, b = 0.18 }

-- Per-glyph default tint overrides (most fall through to gold).
local DEFAULT_TINT = {
    close = TINT_RED,
}

local icons = {
    path = PATH,
    coords = COORDS,
    GOLD = TINT_GOLD,
    RED = TINT_RED,
}

-- Apply a named glyph to a Texture, tinted. Fails loud on unknown name.
--   color: optional {r,g,b}; defaults to the glyph's DEFAULT_TINT, else gold.
function icons.apply(texture, name, color)
    local c = COORDS[name]
    if not c then
        error("icons.apply: unknown glyph '" .. tostring(name) .. "'")
    end
    texture:SetTexture(PATH)
    texture:SetTexCoord(c[1], c[2], c[3], c[4])
    local t = color or DEFAULT_TINT[name] or TINT_GOLD
    texture:SetVertexColor(t.r, t.g, t.b)
end

Addon.icons = icons
