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
    HEADER_HEIGHT    = 24,
    SLOT_HEADER_HEIGHT = 20,
    ICON_SIZE        = 18,

    -- Column widths
    COL_SCALE_WIDTH      = 80,    -- Primary "Scale" column with sort arrow
    COL_SECONDARY_WIDTH  = 70,    -- Secondary column: no sort, just label
    COL_BUYOUT_WIDTH     = 90,
    COL_TIME_WIDTH   = 50,
    COL_LEVEL_WIDTH      = 92,
    COL_PADDING      = 6,

    -- Number of scale columns shown in the grid. Eval tracks as many
    -- scales as Pawn returns (no cap), but the user can only see this
    -- many at a time; the scale-picker dropdowns above the grid select
    -- which of the tracked scales map to column 1 and column 2.
    DISPLAYED_SCALE_COLUMNS = 2,

    -- Dropdown sizing (scale pickers above the grid).
    DROPDOWN_HEIGHT      = 22,
    DROPDOWN_MIN_WIDTH   = 70,   -- matches COL_SCALE_WIDTH as a floor
    DROPDOWN_MAX_WIDTH   = 250,  -- hard cap per user spec

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
