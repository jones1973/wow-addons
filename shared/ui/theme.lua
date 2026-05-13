--[[
  ui/shared/theme.lua
  Theme System — unified visual design tokens, brand identity, skinning
  dispatcher, chat output builder, and tooltip-token foundation for the
  addon family.

  Provides:
    theme.tokens       Token tables (Tier 1 primitives, Tier 2 roles, Tier 3 contextual)
    theme.derive       Helper functions (inline color codes, runtime resolution, etc.)
    theme.brand        Per-addon brand configuration API
    theme.chat         Chat output builder
    theme.style        Skinning dispatcher (strategies live in separate files)
    theme.backdrops    Pre-built backdrop tables for direct SetBackdrop use

  Skinning strategies are separate modules:
    theme/style/stock.lua    — always-available stock Blizzard strategy
    theme/style/elvui.lua    — ElvUI strategy

  Strategy files declare {"theme"} as a dependency so theme always
  initializes first. Strategies register themselves at file-load time
  via theme.style.strategies.<name> = strategy.

  Per-addon configuration goes in themeConfig.lua, which runs after this
  module loads and calls theme.brand.set / theme.chat.set to install the
  addon's choices.

  Dependencies: none — foundational module
  Exports: Addon.theme
]]

local ADDON_NAME, Addon = ...

local theme = {}
theme.tokens    = {}
theme.derive    = {}
theme.brand     = {}
theme.chat      = {}
theme.style     = { strategies = {} }
theme.backdrops = {}

-- ============================================================================
-- COLOR MATH HELPERS
-- ============================================================================

-- Convert an RGB channel value (0-1) to a two-character hex string.
local function channelToHex(c)
    local v = math.floor(c * 255 + 0.5)
    if v < 0 then v = 0 elseif v > 255 then v = 255 end
    return string.format("%02x", v)
end

-- Compute the inline-code form of a token: "ffRRGGBB" (alpha first per WoW).
local function computeCode(r, g, b, a)
    local alpha = math.floor((a or 1) * 255 + 0.5)
    if alpha < 0 then alpha = 0 elseif alpha > 255 then alpha = 255 end
    return string.format("%02x%s%s%s", alpha, channelToHex(r), channelToHex(g), channelToHex(b))
end

-- Create a token record. Tokens are immutable once created.
-- The .code field is populated eagerly so consumers can use it inline
-- without invoking a function.
local function makeToken(r, g, b, a)
    a = a or 1.0
    return {
        r = r,
        g = g,
        b = b,
        a = a,
        code = computeCode(r, g, b, a),
    }
end

-- Convert RGB (0-1 each channel) to HSL (h: 0-360, s/l: 0-1).
local function rgbToHsl(r, g, b)
    local maxC = math.max(r, g, b)
    local minC = math.min(r, g, b)
    local h, s, l = 0, 0, (maxC + minC) / 2

    if maxC ~= minC then
        local d = maxC - minC
        s = (l > 0.5) and (d / (2 - maxC - minC)) or (d / (maxC + minC))
        if maxC == r then
            h = (g - b) / d
            if g < b then h = h + 6 end
        elseif maxC == g then
            h = (b - r) / d + 2
        else
            h = (r - g) / d + 4
        end
        h = h * 60
    end

    return h, s, l
end

-- Convert HSL back to RGB.
local function hslToRgb(h, s, l)
    if s == 0 then return l, l, l end

    local function hue2rgb(p, q, t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < 1/6 then return p + (q - p) * 6 * t end
        if t < 1/2 then return q end
        if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
        return p
    end

    local q = (l < 0.5) and (l * (1 + s)) or (l + s - l * s)
    local p = 2 * l - q
    local hk = h / 360

    return hue2rgb(p, q, hk + 1/3),
           hue2rgb(p, q, hk),
           hue2rgb(p, q, hk - 1/3)
end

-- Lift a token's lightness by deltaL (in HSL space, 0-1).
local function liftLightness(token, deltaL)
    local h, s, l = rgbToHsl(token.r, token.g, token.b)
    l = math.min(1, math.max(0, l + deltaL))
    local r, g, b = hslToRgb(h, s, l)
    return makeToken(r, g, b, token.a)
end

-- Set a token's lightness to a target value (in HSL space, 0-1),
-- preserving hue and saturation.
local function setLightness(token, targetL)
    local h, s = rgbToHsl(token.r, token.g, token.b)
    targetL = math.min(1, math.max(0, targetL))
    local r, g, b = hslToRgb(h, s, targetL)
    return makeToken(r, g, b, token.a)
end

-- Apply a new alpha to a token, preserving RGB.
local function withAlpha(token, alpha)
    return makeToken(token.r, token.g, token.b, alpha)
end

-- ============================================================================
-- TIER 1 — PRIMITIVES
-- ============================================================================

-- 9-step neutral ramp, perceptually-spaced via OKLCH.
-- Cool tint baked in: blue channel slightly elevated at the dark end,
-- fading to neutral at the light end.
theme.tokens.NEUTRAL = {
    L0 = makeToken(0.039, 0.039, 0.043),  -- deepest — popup overlays, modal backdrops
    L1 = makeToken(0.075, 0.075, 0.086),  -- panel base
    L2 = makeToken(0.110, 0.110, 0.125),  -- panel raised
    L3 = makeToken(0.149, 0.149, 0.169),  -- row alt-stripe
    L4 = makeToken(0.212, 0.212, 0.255),  -- borders, dividers (saturated)
    L5 = makeToken(0.353, 0.353, 0.400),  -- disabled text, dim labels
    L6 = makeToken(0.541, 0.541, 0.573),  -- tertiary text
    L7 = makeToken(0.737, 0.737, 0.757),  -- secondary text
    L8 = makeToken(0.922, 0.922, 0.929),  -- primary text
}

-- Reserve hue palette — fallbacks for tokens that need a "neutral identity"
-- color when an addon hasn't defined a brand component.
theme.tokens.HUE = {
    GOLD       = makeToken(1.000, 0.820, 0.000),  -- canonical Blizzard gold
    PURPLE_500 = makeToken(0.550, 0.450, 0.750),  -- fallback for PROGRESS.GATED
    TEAL_500   = makeToken(0.300, 0.700, 0.650),  -- used by BRANCH.DECISION
    AMBER_500  = makeToken(0.850, 0.650, 0.300),  -- warm fallback
}

-- ============================================================================
-- TIER 2 — SURFACES
-- ============================================================================

-- Six surface tokens. Three fixed alpha values: 0.95 panels, 0.40-0.50 row
-- washes, 0.97 overlay. ROW_BASE is transparent by design.
theme.tokens.SURFACE = {
    PANEL_BASE   = makeToken(0.075, 0.075, 0.086, 0.95),  -- L1 @ 0.95
    PANEL_RAISED = makeToken(0.110, 0.110, 0.125, 0.95),  -- L2 @ 0.95
    ROW_BASE     = makeToken(0.000, 0.000, 0.000, 0.00),  -- transparent
    ROW_ALT      = makeToken(0.149, 0.149, 0.169, 0.40),  -- L3 @ 0.40
    ROW_HOVER    = makeToken(0.212, 0.212, 0.255, 0.50),  -- L4 @ 0.50
    OVERLAY      = makeToken(0.039, 0.039, 0.043, 0.97),  -- L0 @ 0.97
}

-- ============================================================================
-- TIER 2 — TEXT HIERARCHY
-- ============================================================================

-- Text tokens alias to neutral stops. Same Lua reference; same .code field.
-- Renaming is for self-documentation at call sites.
theme.tokens.TEXT = {
    PRIMARY       = theme.tokens.NEUTRAL.L8,
    SECONDARY     = theme.tokens.NEUTRAL.L7,
    TERTIARY      = theme.tokens.NEUTRAL.L6,
    MUTED         = theme.tokens.NEUTRAL.L5,  -- WCAG-exempt: disabled text
    EMPHASIS      = theme.tokens.HUE.GOLD,
    EMPHASIS_SOFT = makeToken(0.900, 0.800, 0.500),  -- cream/parchment
    EMPHASIS_DIM  = makeToken(0.625, 0.500, 0.250),  -- locked-but-warm
    MAX           = makeToken(1.000, 1.000, 1.000),  -- pure white, rare cases
}

-- ============================================================================
-- TIER 2 — SEMANTIC STATES
-- ============================================================================

-- Four base states, each with _SOFT and _TINT variants. _TINT is α=0.15
-- background tint; the role is documented in the token name so consumer
-- code doesn't ad-lib alpha.
theme.tokens.STATE = {
    SUCCESS      = makeToken(0.30, 0.85, 0.30),
    SUCCESS_SOFT = makeToken(0.55, 0.85, 0.55),
    SUCCESS_TINT = makeToken(0.30, 0.85, 0.30, 0.15),

    WARNING      = makeToken(1.00, 0.78, 0.20),  -- distinct from EMPHASIS gold
    WARNING_SOFT = makeToken(0.95, 0.85, 0.55),
    WARNING_TINT = makeToken(1.00, 0.78, 0.20, 0.15),

    DANGER       = makeToken(0.95, 0.40, 0.35),
    DANGER_SOFT  = makeToken(0.95, 0.65, 0.55),
    DANGER_TINT  = makeToken(0.95, 0.40, 0.35, 0.15),

    INFO         = makeToken(0.45, 0.75, 1.00),  -- distinct from QUALITY.RARE
    INFO_SOFT    = makeToken(0.65, 0.85, 1.00),
    INFO_TINT    = makeToken(0.45, 0.75, 1.00, 0.15),
}

-- ============================================================================
-- TIER 2 — CURRENCY
-- ============================================================================

-- Match Blizzard's currency display values exactly.
theme.tokens.CURRENCY = {
    GOLD   = makeToken(1.000, 0.843, 0.000),
    SILVER = makeToken(0.780, 0.780, 0.812),
    COPPER = makeToken(0.929, 0.647, 0.373),
}

-- ============================================================================
-- BLIZZARD-ALIGNED TOKENS — lazy resolution
-- ============================================================================

-- Tokens that delegate to Blizzard runtime tables resolve at access time,
-- not at module-load time. RAID_CLASS_COLORS, ITEM_QUALITY_COLORS, etc.
-- may not exist at file-load (this is a verified specific failure mode).
-- Cache after first access since these tables don't change post-init.

local function makeBlizzardLazyGroup(resolveFn)
    local cache = {}
    return setmetatable({}, {
        __index = function(_, key)
            if cache[key] then return cache[key] end
            local color = resolveFn(key)
            if not color then return nil end
            cache[key] = makeToken(color.r, color.g, color.b, color.a or 1.0)
            return cache[key]
        end,
    })
end

theme.tokens.QUALITY = makeBlizzardLazyGroup(function(key)
    local QUALITY_INDEX = {
        POOR = 0, COMMON = 1, UNCOMMON = 2, RARE = 3,
        EPIC = 4, LEGENDARY = 5, ARTIFACT = 6, HEIRLOOM = 7,
    }
    if key == "RARE_BRIGHT" then
        -- PAO override for dim contexts where Blizzard's RARE blue
        -- desaturates badly when dimmed to 75% opacity.
        return { r = 0.20, g = 0.55, b = 0.87 }
    end
    local idx = QUALITY_INDEX[key]
    if not idx then return nil end
    return _G.ITEM_QUALITY_COLORS and _G.ITEM_QUALITY_COLORS[idx] or nil
end)

theme.tokens.CLASS = makeBlizzardLazyGroup(function(key)
    -- DEATH_KNIGHT in our tokens maps to DEATHKNIGHT in Blizzard's table.
    local lookup = (key == "DEATH_KNIGHT") and "DEATHKNIGHT" or key
    return _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[lookup] or nil
end)

theme.tokens.FACTION = makeBlizzardLazyGroup(function(key)
    local FACTION_INDEX = {
        HATED = 1, HOSTILE = 2, UNFRIENDLY = 3, NEUTRAL = 4,
        FRIENDLY = 5, HONORED = 6, REVERED = 7, EXALTED = 8,
    }
    local idx = FACTION_INDEX[key]
    if not idx then return nil end
    return _G.FACTION_BAR_COLORS and _G.FACTION_BAR_COLORS[idx] or nil
end)

theme.tokens.POWER = makeBlizzardLazyGroup(function(key)
    local POWER_INDEX = {
        MANA = 0, RAGE = 1, FOCUS = 2, ENERGY = 3,
        HAPPINESS = 4, RUNES = 5, RUNIC_POWER = 6,
    }
    local idx = POWER_INDEX[key]
    if not idx then return nil end
    return _G.PowerBarColor and _G.PowerBarColor[idx] or nil
end)

-- ============================================================================
-- TIER 3 — PROGRESSION STATES (composed)
-- ============================================================================

-- Each PROGRESS token has BG/BORDER/TEXT sub-keys that always go together.
-- Tokens that reference BRAND.SECONDARY (GATED) are populated/refreshed
-- when theme.brand.set is called; until then GATED falls back to PURPLE_500.

local function buildProgressTokens()
    local n = theme.tokens.NEUTRAL
    local s = theme.tokens.STATE
    local t = theme.tokens.TEXT
    local h = theme.tokens.HUE

    -- GATED uses BRAND.SECONDARY when defined; otherwise reserve purple.
    local secondaryBorder = (theme.tokens.BRAND and theme.tokens.BRAND.SECONDARY_BORDER) or withAlpha(h.PURPLE_500, 0.85)
    local secondaryText   = (theme.tokens.BRAND and theme.tokens.BRAND.SECONDARY_TEXT)   or h.PURPLE_500
    local secondaryTint   = (theme.tokens.BRAND and theme.tokens.BRAND.SELECTION_TINT_LOW) or withAlpha(h.PURPLE_500, 0.15)

    theme.tokens.PROGRESS = {
        COMPLETE = {
            BG     = withAlpha(n.L2, 0.80),
            BORDER = withAlpha(s.SUCCESS_SOFT, 0.40),
            TEXT   = t.MUTED,
        },
        IN_PROGRESS = {
            BG     = s.SUCCESS_TINT,
            BORDER = s.SUCCESS,
            TEXT   = t.PRIMARY,
        },
        AVAILABLE = {
            BG     = s.WARNING_TINT,
            BORDER = s.WARNING,
            TEXT   = t.PRIMARY,
        },
        LOCKED = {
            BG     = withAlpha(n.L2, 0.90),
            BORDER = n.L4,
            TEXT   = t.MUTED,
        },
        GATED = {
            BG     = secondaryTint,
            BORDER = secondaryBorder,
            TEXT   = secondaryText,
        },
        EXCLUDED = {
            BG     = s.DANGER_TINT,
            BORDER = s.DANGER_SOFT,
            TEXT   = t.MUTED,
        },
    }
end

-- ============================================================================
-- TIER 3 — DATA VIZ: HEATMAP
-- ============================================================================

-- Composed from existing tokens. Stays in lockstep with QUALITY.LEGENDARY.
-- HOT references QUALITY.LEGENDARY which resolves lazily; the metatable
-- forwards at access time.
theme.tokens.HEATMAP = setmetatable({
    COLD = theme.tokens.STATE.SUCCESS_SOFT,
    WARM = theme.tokens.TEXT.EMPHASIS,
}, {
    __index = function(_, key)
        if key == "HOT" then
            return theme.tokens.QUALITY.LEGENDARY
        end
        return nil
    end,
})

-- ============================================================================
-- TIER 3 — DATA VIZ: CHART SERIES
-- ============================================================================

-- 7-color categorical palette. Order is deliberate — adjacent pairs maintain
-- perceptual distance under deuteranopia and protanopia.
theme.tokens.CHART = {
    SERIES_1 = makeToken(0.30, 0.65, 0.90),  -- blue
    SERIES_2 = makeToken(0.85, 0.45, 0.30),  -- orange
    SERIES_3 = makeToken(0.45, 0.75, 0.40),  -- green
    SERIES_4 = makeToken(0.75, 0.40, 0.75),  -- magenta
    SERIES_5 = makeToken(0.95, 0.75, 0.30),  -- yellow-gold
    SERIES_6 = makeToken(0.45, 0.55, 0.85),  -- indigo
    SERIES_7 = makeToken(0.70, 0.70, 0.70),  -- neutral
}

-- ============================================================================
-- TIER 3 — DATA VIZ: BRANCH AND CONNECTOR
-- ============================================================================

-- DECISION on TEAL_500 deliberately — distinct from any STATE hue and from
-- the purple used for PROGRESS.GATED. This resolves NowWhat's audit-found
-- collision where the same purple meant both "decision" and "rep-gated."
theme.tokens.BRANCH = {
    DECISION         = theme.tokens.HUE.TEAL_500,
    CONNECTOR        = withAlpha(theme.tokens.NEUTRAL.L4, 0.5),
    CONNECTOR_ACTIVE = withAlpha(theme.tokens.STATE.SUCCESS, 0.6),
}

-- ============================================================================
-- TIER 3 — DATA VIZ: BARS
-- ============================================================================

-- BAR.FILL_BRAND and BAR.OVERFLOW resolve lazily — BRAND is set after
-- this module loads, OVERFLOW chains to QUALITY.LEGENDARY (lazy).
theme.tokens.BAR = setmetatable({
    BACKGROUND   = theme.tokens.NEUTRAL.L2,
    FILL_DEFAULT = theme.tokens.STATE.SUCCESS_SOFT,
    MARKER       = withAlpha(theme.tokens.NEUTRAL.L5, 0.8),
}, {
    __index = function(_, key)
        if key == "FILL_BRAND" then
            return theme.tokens.BRAND and theme.tokens.BRAND.PRIMARY or nil
        elseif key == "OVERFLOW" then
            return theme.tokens.QUALITY.LEGENDARY
        end
        return nil
    end,
})

-- ============================================================================
-- TIER 3 — TAB GROUP
-- ============================================================================

-- Tab tokens compose from existing surfaces and brand. Used by skinTab.
theme.tokens.TAB = setmetatable({
    INACTIVE_BG     = theme.tokens.SURFACE.PANEL_RAISED,
    INACTIVE_TEXT   = theme.tokens.TEXT.SECONDARY,
    INACTIVE_BORDER = theme.tokens.NEUTRAL.L4,
    HOVER_BG        = theme.tokens.SURFACE.ROW_HOVER,
    HOVER_TEXT      = theme.tokens.TEXT.PRIMARY,
    ACTIVE_TEXT     = theme.tokens.TEXT.EMPHASIS,
}, {
    __index = function(_, key)
        if key == "ACTIVE_BG" then
            return theme.tokens.BRAND and theme.tokens.BRAND.SELECTION_TINT_HIGH or theme.tokens.SURFACE.PANEL_BASE
        elseif key == "ACTIVE_BORDER" then
            return theme.tokens.BRAND and theme.tokens.BRAND.PRIMARY_BORDER or theme.tokens.HUE.GOLD
        end
        return nil
    end,
})

-- ============================================================================
-- TIER 3 — TOOLTIP TOKENS
-- ============================================================================

-- The unified tooltip system (separate module) consumes these.
theme.tokens.TOOLTIP = {
    BACKGROUND     = theme.tokens.SURFACE.OVERLAY,
    HEADER         = theme.tokens.TEXT.EMPHASIS,
    SECTION_HEADER = theme.tokens.TEXT.EMPHASIS_SOFT,
    ROW_LABEL      = theme.tokens.TEXT.SECONDARY,
    ROW_VALUE      = theme.tokens.TEXT.PRIMARY,
    HINT           = theme.tokens.TEXT.TERTIARY,
}

-- ============================================================================
-- TIER 3 — SEPARATOR AND HEADER
-- ============================================================================

theme.tokens.SEPARATOR = setmetatable({
    DEFAULT = withAlpha(theme.tokens.NEUTRAL.L4, 0.6),
}, {
    __index = function(_, key)
        if key == "BRAND" then
            local p = theme.tokens.BRAND and theme.tokens.BRAND.PRIMARY
            return p and withAlpha(p, 0.4) or withAlpha(theme.tokens.HUE.GOLD, 0.4)
        end
        return nil
    end,
})

theme.tokens.HEADER = setmetatable({
    LABEL = theme.tokens.TEXT.EMPHASIS_SOFT,
}, {
    __index = function(_, key)
        if key == "BG" then
            return theme.tokens.SURFACE.ROW_ALT
        end
        return nil
    end,
})

-- ============================================================================
-- BRAND CONFIGURATION API
-- ============================================================================

-- Brand variants are derived from one or two anchor colors. The derivation
-- rules are deterministic; per-addon overrides are permitted via
-- theme.brand.override when a derived value visibly fails.

local brandOverrides = {}

local function deriveBrandVariants(anchor, prefix, isSecondary)
    local p = prefix or "PRIMARY"
    local b = theme.tokens.BRAND

    -- Normalize input: themeConfig may pass either a raw RGB table or an
    -- existing token (e.g., theme.tokens.CLASS.WARLOCK). Both go through
    -- makeToken so the anchor itself has a valid .code and .a field.
    anchor = makeToken(anchor.r, anchor.g, anchor.b, anchor.a or 1.0)

    b[p]              = anchor
    b[p .. "_HOVER"]  = liftLightness(anchor, 0.08)
    b[p .. "_ACTIVE"] = liftLightness(anchor, -0.06)
    b[p .. "_BORDER"] = withAlpha(anchor, 0.85)

    -- PRIMARY_TEXT must clear AA on dark surfaces. If anchor's lightness
    -- is already ≥0.6, the variant is the anchor itself; otherwise lift
    -- to 0.6 lightness preserving hue and saturation.
    local _, _, l = rgbToHsl(anchor.r, anchor.g, anchor.b)
    if l >= 0.6 then
        b[p .. "_TEXT"] = anchor
    else
        b[p .. "_TEXT"] = setLightness(anchor, 0.6)
    end

    if not isSecondary then
        b.SELECTION_TINT_LOW  = withAlpha(anchor, 0.08)
        b.SELECTION_TINT_MID  = withAlpha(anchor, 0.15)
        b.SELECTION_TINT_HIGH = withAlpha(anchor, 0.25)
        b.HOVER_WASH          = withAlpha(anchor, 0.12)
    end
end

local function applyBrandOverrides()
    for variantName, value in pairs(brandOverrides) do
        theme.tokens.BRAND[variantName] = value
    end
end

-- Install the addon's brand anchors. Computes the full variant ramp.
function theme.brand.set(config)
    theme.tokens.BRAND = {}

    if config.primary then
        deriveBrandVariants(config.primary, "PRIMARY", false)
    end
    if config.secondary then
        deriveBrandVariants(config.secondary, "SECONDARY", true)
    end

    applyBrandOverrides()

    -- PROGRESS depends on BRAND.SECONDARY; rebuild after brand changes.
    buildProgressTokens()
end

-- Override a specific derived variant. Used when derivation produces a
-- poor result for a specific anchor. Each override should be commented
-- in the calling themeConfig with the reason.
function theme.brand.override(variantName, token)
    brandOverrides[variantName] = token
    if theme.tokens.BRAND then
        theme.tokens.BRAND[variantName] = token
    end
end

-- Initialize PROGRESS with no-brand defaults so consumers can reference
-- PROGRESS.GATED before themeConfig runs (and for no-brand addons that
-- never call brand.set).
buildProgressTokens()

-- ============================================================================
-- DERIVE HELPERS
-- ============================================================================

-- Build an inline color code: "|cffRRGGBB<text>|r"
function theme.derive.inline(token, text)
    return "|c" .. token.code .. (text or "") .. "|r"
end

-- Resolve a quality integer (0-7) to a QUALITY token.
function theme.derive.qualityFor(qualityInt)
    local names = {
        [0] = "POOR", [1] = "COMMON", [2] = "UNCOMMON", [3] = "RARE",
        [4] = "EPIC", [5] = "LEGENDARY", [6] = "ARTIFACT", [7] = "HEIRLOOM",
    }
    local name = names[qualityInt]
    if not name then return nil end
    return theme.tokens.QUALITY[name]
end

-- Map a quality integer to its token-key name.
function theme.derive.qualityName(qualityInt)
    local names = {
        [0] = "POOR", [1] = "COMMON", [2] = "UNCOMMON", [3] = "RARE",
        [4] = "EPIC", [5] = "LEGENDARY", [6] = "ARTIFACT", [7] = "HEIRLOOM",
    }
    return names[qualityInt]
end

-- Resolve a class identifier (token-key like "WARLOCK") to a CLASS token.
function theme.derive.classFor(classKey)
    if not classKey then return nil end
    return theme.tokens.CLASS[classKey]
end

-- Resolve a faction-standing integer (1-8) to a FACTION token.
function theme.derive.factionFor(standingInt)
    local names = {
        [1] = "HATED", [2] = "HOSTILE", [3] = "UNFRIENDLY", [4] = "NEUTRAL",
        [5] = "FRIENDLY", [6] = "HONORED", [7] = "REVERED", [8] = "EXALTED",
    }
    local name = names[standingInt]
    if not name then return nil end
    return theme.tokens.FACTION[name]
end

-- Resolve a percentage value to HEATMAP COLD/WARM/HOT based on thresholds.
function theme.derive.heatmap(value, warmThreshold, hotThreshold)
    if value >= hotThreshold then
        return theme.tokens.HEATMAP.HOT
    elseif value >= warmThreshold then
        return theme.tokens.HEATMAP.WARM
    end
    return theme.tokens.HEATMAP.COLD
end

-- Interpolate between heatmap stops. Returns a new token with values
-- linearly interpolated based on where value falls relative to thresholds.
function theme.derive.heatmapInterpolated(value, warmThreshold, hotThreshold)
    local cold = theme.tokens.HEATMAP.COLD
    local warm = theme.tokens.HEATMAP.WARM
    local hot  = theme.tokens.HEATMAP.HOT

    local function lerp(a, b, t)
        return a + (b - a) * t
    end

    local function lerpToken(t1, t2, t)
        return makeToken(
            lerp(t1.r, t2.r, t),
            lerp(t1.g, t2.g, t),
            lerp(t1.b, t2.b, t),
            lerp(t1.a, t2.a, t)
        )
    end

    if value <= warmThreshold then
        local t = (warmThreshold > 0) and (value / warmThreshold) or 0
        return lerpToken(cold, warm, math.min(1, math.max(0, t)))
    end

    local t = (hotThreshold > warmThreshold)
        and ((value - warmThreshold) / (hotThreshold - warmThreshold))
        or 1
    return lerpToken(warm, hot, math.min(1, math.max(0, t)))
end

-- Format a copper amount as a colored gold/silver/copper string.
function theme.derive.formatMoney(copper)
    copper = copper or 0
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100

    local parts = {}
    if g > 0 then
        parts[#parts + 1] = theme.derive.inline(theme.tokens.CURRENCY.GOLD, g) .. "g"
    end
    if s > 0 or g > 0 then
        parts[#parts + 1] = theme.derive.inline(theme.tokens.CURRENCY.SILVER, s) .. "s"
    end
    parts[#parts + 1] = theme.derive.inline(theme.tokens.CURRENCY.COPPER, c) .. "c"

    return table.concat(parts, " ")
end

-- Resolve a numeric pet-type ID (1-10) to a PAO_FAMILY token.
-- Returns nil if PAO_FAMILY is not installed (called by a non-PAO addon).
function theme.derive.petFamilyColor(petType)
    if not theme.tokens.PAO_FAMILY then return nil end
    local names = {
        [1] = "HUMANOID", [2] = "DRAGONKIN", [3] = "FLYING", [4] = "UNDEAD",
        [5] = "CRITTER",  [6] = "MAGIC",     [7] = "ELEMENTAL", [8] = "BEAST",
        [9] = "AQUATIC",  [10] = "MECHANICAL",
    }
    local name = names[petType]
    if not name then return nil end
    return theme.tokens.PAO_FAMILY[name]
end

-- Strategy-side helpers — exposed for stock and ElvUI strategy files.
-- These let strategies build derived tokens (lighter/darker variants,
-- alpha-modified versions) without duplicating the math.
theme.derive.makeToken     = makeToken
theme.derive.withAlpha     = withAlpha
theme.derive.liftLightness = liftLightness
theme.derive.setLightness  = setLightness

-- ============================================================================
-- CHAT API
-- ============================================================================

-- Per-addon chat configuration. Set by themeConfig.lua.
local chatConfig = {
    prefix      = nil,
    prefixColor = nil,
}

function theme.chat.set(config)
    chatConfig.prefix      = config.prefix
    chatConfig.prefixColor = config.prefixColor
end

local function buildPrefix(colorOverride)
    local color = colorOverride or chatConfig.prefixColor or theme.tokens.TEXT.EMPHASIS
    local prefix = chatConfig.prefix or "?"
    return theme.derive.inline(color, prefix .. ":")
end

-- Produce a chat line with the addon's prefix, accepting strings and
-- {token, text} pairs that get colored inline.
function theme.chat:line(...)
    local parts = { buildPrefix(), " " }
    for i = 1, select("#", ...) do
        local arg = select(i, ...)
        if type(arg) == "string" then
            parts[#parts + 1] = arg
        elseif type(arg) == "table" and arg[1] and arg[2] then
            parts[#parts + 1] = theme.derive.inline(arg[1], arg[2])
        end
    end
    print(table.concat(parts))
end

-- Produce an alarm-prefixed chat line. The prefix is the addon's name in
-- alarm color (not brand) so failure messages read as failure regardless
-- of which addon produced them.
function theme.chat:alarm(message)
    local danger = theme.tokens.STATE.DANGER
    local prefix = buildPrefix(danger)
    print(prefix .. " " .. theme.derive.inline(danger, message or ""))
end

-- ============================================================================
-- BACKDROPS — pre-built tables for direct SetBackdrop use
-- ============================================================================

theme.backdrops.PANEL = {
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile     = true,
    tileSize = 32,
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
}

theme.backdrops.POPUP = {
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile     = true,
    tileSize = 32,
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
}

theme.backdrops.TOOLTIP = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true,
    tileSize = 16,
    edgeSize = 16,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
}

theme.backdrops.CARD = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = false,
    edgeSize = 8,
    insets   = { left = 2, right = 2, top = 2, bottom = 2 },
}

-- ============================================================================
-- SKINNING DISPATCHER
-- ============================================================================

-- The dispatcher walks registered strategies (excluding stock) and calls
-- detect() on each. Exactly one match → use that strategy. Zero or 2+
-- matches → use stock. Stock is always the floor.

local activeStrategy = nil

-- Public: re-run strategy detection. Called by strategy files after
-- they register, and by theme's own module-init function.
function theme.style.refreshSelection()
    local matches = {}
    for name, strat in pairs(theme.style.strategies) do
        if name ~= "stock" and strat.detect and strat.detect() then
            matches[#matches + 1] = strat
        end
    end

    if #matches == 1 then
        activeStrategy = matches[1]
    else
        activeStrategy = theme.style.strategies.stock
    end
end

-- Method-level fallback to stock for any method a non-stock strategy omits.
-- This is part of the architecture, not a backward-compat shim.
local function dispatch(methodName, ...)
    if activeStrategy and activeStrategy[methodName] then
        return activeStrategy[methodName](activeStrategy, ...)
    end
    local stock = theme.style.strategies.stock
    if stock and stock[methodName] then
        return stock[methodName](stock, ...)
    end
end

-- Public API methods — one per skinning concern.
function theme.style:skinPanel(frame, options)       dispatch("skinPanel", frame, options) end
function theme.style:skinTab(button, isActive, opts) dispatch("skinTab", button, isActive, opts) end
function theme.style:skinHeader(frame, options)      dispatch("skinHeader", frame, options) end
function theme.style:skinTitlebar(frame, text)       dispatch("skinTitlebar", frame, text) end
function theme.style:skinPopup(frame, options)       dispatch("skinPopup", frame, options) end
function theme.style:skinTooltip(frame, options)     dispatch("skinTooltip", frame, options) end
function theme.style:skinCard(frame, options)        dispatch("skinCard", frame, options) end
function theme.style:skinScrollbar(bar, options)     dispatch("skinScrollbar", bar, options) end
function theme.style:skinDropdown(frame, options)    dispatch("skinDropdown", frame, options) end
function theme.style:skinEditBox(box, options)       dispatch("skinEditBox", box, options) end
function theme.style:skinButton(button, options)     dispatch("skinButton", button, options) end
function theme.style:skinCheckbox(checkbox, options) dispatch("skinCheckbox", checkbox, options) end
function theme.style:skinSeparator(line, options)    dispatch("skinSeparator", line, options) end
function theme.style:skinProgressBar(bar, options)   dispatch("skinProgressBar", bar, options) end
function theme.style:skinStatusBar(bar, options)     dispatch("skinStatusBar", bar, options) end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("theme", {}, function()
        -- All strategy files have loaded by now (file-load is synchronous
        -- and completes before init functions run). Run detection.
        theme.style.refreshSelection()
        return true
    end)
end

Addon.theme = theme
return theme
