--[[
  core/theme/craftyTheme.lua
  Crafty's semantic theme layer

  The shared theme (core/shared/theme) is the vocabulary: raw values (NEUTRAL
  L0-L8, HUE) and generic semantic tokens (TEXT.PRIMARY, STATE.SUCCESS,
  SURFACE.*). This file is Crafty's DICTIONARY on top of it: named tokens for
  what things MEAN in Crafty - a section heading, a reagent that is satisfied,
  a selected activity row - each resolving to a shared value.

  Two levels, deliberately. The shared layer says what "gold" or "L7" is; this
  layer says a section heading IS gold, everywhere, in one place. UI code reads
  only this layer (theme.crafty.*), never a raw token - so a colour decision is
  one edit here, not a hunt through call sites, and the hierarchy is legible as
  a single table instead of scattered across the panels.

  Grouped, not flat, and composition-capable: TEXT is a real ladder (title down
  to disabled, each tier a distinct weight so colour does work and the panel
  reads as hierarchy rather than a wall of one shade); SURFACE names the bars by
  their role; REAGENT is the three-state satisfied/short/vendor; SELECTION and
  ACTIVITY carry the row treatments as sets. PROFESSION is reserved for the
  per-profession identity (§2) - a composite of tint + accent + selected surface
  that shifts by profession - and is where that work will land without
  disturbing consumers, because they already speak roles.

  What is NOT here: tokens that already carry a single meaning in the shared
  layer - CONTROL metrics, BAR fills, DIFFICULTY colours, EFFECT glows. Those
  are one-fact-one-place already; wrapping them would add indirection with no
  semantic gain. This layer normalises what was CONFLATED (one raw token
  standing for several Crafty meanings), not everything.

  Loads after the shared theme (core/files.xml, after the shared include), at
  file-load, before any UI. Installs onto the shared theme object as
  theme.crafty.

  Dependencies: theme (loaded immediately before this file)
  Exports: nothing - installs theme.crafty onto Addon.theme
]]

local ADDON_NAME, Addon = ...
local theme = Addon.theme
local T = theme.tokens

theme.crafty = {}

-- ============================================================================
-- TEXT - the readable hierarchy
-- ============================================================================

-- A ladder from loudest to quietest. The failure this fixes: PRIMARY was doing
-- the job of TITLE, BODY, VALUE and LABEL all at once, so the detail panel had
-- no hierarchy - every line the same near-white. Each tier here is a distinct
-- weight, and warmth (cream/gold) carries the structural tiers so headings feel
-- of-the-forge rather than printed.
theme.crafty.TEXT = {
    -- The hero line - a recipe/detail name. The brightest text; the eye lands
    -- here first. (Quality-coloured at runtime when the output has a quality;
    -- this is the neutral default.)
    TITLE       = T.TEXT.PRIMARY,

    -- Section headings within a panel: "Reagents", conversion column captions.
    -- Gold - the strongest structural marker.
    HEADING     = T.TEXT.EMPHASIS,

    -- Lighter structural labels: list group headers (Pinned / All), the rail's
    -- group captions (PROFESSIONS / SECONDARY). Cream - present but below a
    -- gold section heading.
    SUBHEADING  = T.TEXT.EMPHASIS_SOFT,

    -- Readable running content: a recipe description. A step below TITLE so the
    -- name still leads, but fully legible - warm off-white, not dimmed.
    BODY        = T.TEXT.PRIMARY,

    -- Supporting text that should not compete: "Requires: <tool>", the info
    -- line under the name, cooldown notes. Warm and quiet - dimmer than BODY,
    -- but NEVER the disabled grey. This is the tier grey kept getting misused
    -- for.
    LABEL       = T.TEXT.EMPHASIS_SOFT,

    -- A number or short value sitting inline in text (a bag count that is not
    -- itself a satisfied/short state). Cream, so data reads as data.
    VALUE       = T.TEXT.EMPHASIS_SOFT,

    -- Genuinely inactive: the "vendor" tag on a reagent, an unavailable
    -- conversion row, a skill-locked line. The ONE true grey - disabled only.
    DISABLED    = T.TEXT.MUTED,
}

-- ============================================================================
-- SURFACE - the bars and bands, by role
-- ============================================================================

-- Named by what the surface IS, so a bar's colour is chosen once. The list's
-- top bands read dark-warm against the panel; the gold captions on them carry
-- the "this is a header" signal, not a light chrome slab.
theme.crafty.SURFACE = {
    PANEL         = T.SURFACE.PANEL_BASE,     -- a pane's base fill
    FILTER_BAR    = T.SURFACE.PANEL_RAISED,   -- the filter strip: barely raised
    COLUMN_HEADER = T.SURFACE.ROW_SELECTED,   -- the sort-header band: a step up
    INSET         = T.SURFACE.OVERLAY,        -- sunken wells (rail rows, tool shelf)
    DIVIDER       = T.NEUTRAL.L4,             -- borders, warm hairlines
}

-- The panel's material: the backdrop SHAPE (tile + tooltip-style border) shared
-- by every pane so the rail, the drawer, and the panels are cut from the same
-- cloth. Coloured with SURFACE.PANEL. One shape, referenced everywhere, rather
-- than a literal repeated per frame.
theme.crafty.PANEL_BACKDROP = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

-- Edit mode: while Customize is open, the rail and drawer take a cool tint that
-- sets the editing surface apart from the (dimmed, warm) rest of the window - a
-- temperature shift reads as "a different state" at a glance while staying muted
-- enough to sit with the palette. PROVISIONAL: a placeholder slate-blue chosen
-- to be distinct-but-harmonious against the current fantasy warmth; it will be
-- reconciled when the palette is reworked. FILL is the surface, BORDER its edge.
theme.crafty.EDIT = {
    FILL   = { r = 0.10, g = 0.13, b = 0.18, a = 0.97 },  -- muted slate-blue
    BORDER = { r = 0.28, g = 0.36, b = 0.48, a = 1 },     -- cooler edge
}

-- ============================================================================
-- REAGENT - the three states of a required material
-- ============================================================================

-- Not two states but three: holding enough reads satisfied (green); a real
-- shortage reads danger (red); a vendor reagent does not gate the craft, so its
-- count stays quiet and a tag says where to get it. Green-for-satisfied matches
-- the status vocabulary (green = available/satisfied), and keeps "have enough"
-- off the grey it was using.
theme.crafty.REAGENT = {
    SATISFIED = T.STATE.SUCCESS,
    SHORT     = T.STATE.DANGER,
    VENDOR    = T.TEXT.SECONDARY,   -- quiet, not an alarm and not disabled-grey
}

-- ============================================================================
-- SELECTION / ACTIVITY - row treatments as sets
-- ============================================================================

-- A selected row is a composite: fill + border + how its text reads. Named as a
-- set so a selection's whole look is chosen together, not reassembled per
-- consumer. (The per-profession identity in PROFESSION, when built, overrides
-- FILL/BORDER by active profession; text tiers stay put.)
theme.crafty.SELECTION = {
    FILL    = T.BRAND.SELECTION_TINT_HIGH,
    BORDER  = T.BRAND.PRIMARY,
    WASH    = T.BRAND.SELECTION_TINT_LOW,   -- hover, pre-selection
}

-- The rail's activity-row states, as sets. REST is an unselected row; ARRIVED
-- is a profession that learned something while unviewed (gold until looked at).
theme.crafty.ACTIVITY = {
    REST_FILL     = T.SURFACE.OVERLAY,
    REST_BORDER   = T.NEUTRAL.L4,
    ARRIVED       = T.TEXT.EMPHASIS,   -- the gold mark, used for fill+border at alpha
}

-- ============================================================================
-- PROFESSION - per-profession colour identity (reserved)
-- ============================================================================

-- The §2 identity: Enchanting arcane-violet, Inscription ink-teal, Cooking
-- warm-amber, applied across the active surfaces (rail selection, headings,
-- accents) so the workspace feels of the chosen profession. Composite per
-- profession (tint + accent + selected fill), which is why this layer is
-- grouped and composition-capable rather than a flat alias table. Left as the
-- documented seam until the palette decision is made; consumers reading
-- SELECTION/ACTIVITY today adopt it here without changing their call sites.
theme.crafty.PROFESSION = nil

return theme.crafty
