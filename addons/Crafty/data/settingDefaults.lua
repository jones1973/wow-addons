--[[
  data/settingDefaults.lua
  Setting Defaults and Categories

  Account-wide default values for every setting, grouped by category.
  Categories map to SETTING:<CATEGORY>_CHANGED events in the options system.
  Consumed by persistence.lua, which registers these with Addon.options at
  file-load time before ADDON_LOADED.

  Dependencies: none (pure data)
  Exports: Addon.data.settingDefaults, Addon.data.settingCategories
]]

local ADDON_NAME, Addon = ...

Addon.data = Addon.data or {}

-- ============================================================================
-- DEFAULTS
-- ============================================================================

Addon.data.settingDefaults = {
    debugMode = false,
}

-- ============================================================================
-- CATEGORIES
-- ============================================================================

Addon.data.settingCategories = {
    general = { "debugMode" },
}

return Addon.data.settingDefaults
