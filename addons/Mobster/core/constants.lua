--[[
  core/constants.lua
  Shared constants for Mobster

  Dependencies: none
  Exports: Addon.constants
]]

local ADDON_NAME, Addon = ...

Addon.constants = {
    -- Scanner
    SCAN_INTERVAL      = 0.5,
    ALERT_SOUND        = 8959, -- Raid Warning
    SOUND_COOLDOWN     = 5,    -- Minimum seconds between alert sounds
    ICON_ORDER         = { 8, 7, 6, 5, 4, 3, 2, 1 }, -- skull first, then down

    -- SavedVariable schema version. Bumped only at release time when the
    -- schema changes between versions shipped to users. During development
    -- we leave it alone and wipe manually if needed.
    SV_VERSION = 1,

    -- 8pt grid spacing
    PADDING_TINY   = 4,
    PADDING_SMALL  = 8,
    PADDING_MEDIUM = 12,
    PADDING_BASE   = 16,
    PADDING_LARGE  = 24,

    -- Watch list row metrics
    ROW_HEIGHT = 24,
    ROW_WIDTH  = 218,
}
