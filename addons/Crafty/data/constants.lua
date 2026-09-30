--[[
  data/constants.lua
  Crafty Constants

  Static constants: ledger SV schema versions (consumed by svRegistry
  registrations in main.lua) and shared addon-event name strings. No runtime
  data, no logic.

  Dependencies: none
  Exports: Addon.constants
]]

local ADDON_NAME, Addon = ...

local constants = {}

-- ============================================================================
-- LEDGER SAVED-VARIABLE VERSIONS
-- ============================================================================
-- Passed to svRegistry:register. Bump when the stored shape changes; svRegistry
-- then wipes-and-recreates (no migration defined) or runs a migration chain if
-- one is provided.

constants.CHARACTER_SV_VERSION = 1
constants.SETTINGS_SV_VERSION = 1
constants.CONFIG_SV_VERSION = 1

-- ============================================================================
-- ADDON EVENT NAMES (NAMESPACE:NAME)
-- ============================================================================

constants.EVENT = {
    RECIPES_SCANNED = "LEDGER:RECIPES_SCANNED",
    BAGS_SCANNED    = "LEDGER:BAGS_SCANNED",
    RECIPE_SELECTED = "UI:RECIPE_SELECTED"   -- { id, kind = "recipe"|"convert" },
}

Addon.constants = constants
return constants
