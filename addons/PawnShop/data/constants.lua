--[[
  data/constants.lua
  Layout and Eval Constants

  File-local constant values used across the addon. Things that should be
  tunable in one place: column widths, row heights, padding, tolerances,
  caps, etc.

  Attaches to Addon.constants so every module can read without a dep chain.

  Dependencies: none (pure data)
  Exports: Addon.constants
]]

local ADDON_NAME, Addon = ...

local constants = {
    -- Grid layout
    ROW_HEIGHT       = 28,
    ROW_HEIGHT_PAIR  = 48,
    HEADER_HEIGHT    = 18,
    SLOT_HEADER_HEIGHT = 20,
    ICON_SIZE        = 18,

    -- Column widths
    COL_SCALE_WIDTH  = 70,
    COL_BUYOUT_WIDTH = 90,
    COL_TIME_WIDTH   = 50,
    COL_LEVEL_WIDTH  = 32,
    COL_PADDING      = 6,

    -- Scale column cap (panel width = 800px, 5 cols fit comfortably)
    MAX_SCALE_COLUMNS = 5,

    -- Hard cap for eval. math.huge = process everything. Settable lower
    -- for dev/debug to cut short a long eval on a huge scan.
    EVAL_LIMIT = math.huge,

    -- Blizzard item classID constants (TBC). Gear filter keeps only these.
    ITEM_CLASS_WEAPON = 2,
    ITEM_CLASS_ARMOR  = 4,

    -- Pair row cap
    PAIR_ROW_CAP = 50,

    -- Eval pacing (ms budget per Tick, seconds between ticks)
    EVAL_BUDGET_MS = 10,
    EVAL_YIELD_SEC = 0.05,

    -- Pending item resolver debounce (seconds)
    PENDING_RESOLVE_DEBOUNCE = 0.1,

    -- Status display strings
    TAB_LABEL = "Pawn Shop",
}

Addon.constants = constants

-- Self-register so modules can declare "constants" in their dependency list.
-- No actual init work needed - the table is populated at file-load.
if Addon.registerModule then
    Addon.registerModule("constants", {}, function()
        return true
    end)
end

return constants
