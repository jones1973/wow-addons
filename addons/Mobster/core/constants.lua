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

    -- SavedVariable schema versions, independent per SV so a schema
    -- change to one doesn't wipe the other.
    --
    -- Rule: do NOT bump these during development. Schema changes
    -- during active development are handled by wiping the SV
    -- manually (mobster_character = nil mobster_settings = nil
    -- ReloadUI). The version mechanism is reserved for release-time
    -- bumps where actual users would otherwise have stale shapes on
    -- disk.
    CHARACTER_SV_VERSION = 1,
    SETTINGS_SV_VERSION  = 1,

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
