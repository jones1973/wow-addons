--[[
  data/settingDefaults.lua
  Setting Defaults and Categories

  Declares the account-wide default values for every setting and groups
  them by category (categories map to SETTING:<CATEGORY>_CHANGED events in
  the options system).

  Consumed by persistence.lua which registers these with Addon.options
  at file-load time, before ADDON_LOADED fires.

  Account-wide defaults live here. Per-character overrides are stored in
  ps_character and read/written by the code using the override pattern
  (character value wins if set, else fall back to default).

  Dependencies: none (pure data)
  Exports: Addon.data.settingDefaults, Addon.data.settingCategories
]]

local ADDON_NAME, Addon = ...

Addon.data = Addon.data or {}

-- ============================================================================
-- DEFAULTS
-- ============================================================================

Addon.data.settingDefaults = {
    -- Debug mode: account-wide. Per-character override NOT supported.
    debugMode = false,

    -- Scale column selection: account-wide default.
    -- Empty means "show all enabled Pawn scales up to MAX_SCALE_COLUMNS cap."
    -- Per-character override lives in ps_character.enabledScales.
    enabledScales = {},  -- { [internalScaleName] = true, ... }

    -- Filters. All account-wide defaults; per-character overrides in ps_character.

    -- The "filter scale" -- the single Pawn scale used to decide which
    -- rows appear in the panel and what percent the upgrade math is
    -- computed against. nil means "no choice yet"; on first scan the
    -- panel auto-selects scaleOrder[1] (the first scale Pawn returned
    -- upgrades for) and persists it so subsequent sessions stick to it.
    scale          = nil,

    -- The "companion scale" -- a second scale displayed as an extra
    -- column alongside the filter scale's column. Decorative: does not
    -- influence row membership, sorting, or pill scoring. nil means
    -- "(none)" -- no companion column shown.
    companionScale = nil,

    levelTolerance = 2,     -- show items with minLevel <= playerLevel + N
    minUpgradePct  = 0,     -- hide single-item rows below this %; 0 = no filter
    maxPrice       = 0,     -- hide items with buyout > this; 0 = no filter (in copper)

    -- Sort column. "scale_1" means first tracked scale.
    sortColumn     = "scale_1",
    sortDir        = "desc",
}

-- ============================================================================
-- CATEGORIES
-- ============================================================================

-- When a setting is written via options:SetCharacter or options:SetAccount,
-- a SETTING:<CATEGORY>_CHANGED event fires for handlers to react. Modules
-- subscribe to the category they care about rather than every key individually.
Addon.data.settingCategories = {
    general = { "debugMode" },
    display = { "enabledScales", "sortColumn", "sortDir" },
    filter  = { "scale", "companionScale", "levelTolerance", "minUpgradePct", "maxPrice" },
}

return Addon.data.settingDefaults
