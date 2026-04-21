--[[
  logic/sort.lua
  Row Sorting

  Pure row-list sorter. Does not own rows, does not own sort state. Caller
  provides:
    - the row list to sort (mutated in place)
    - the column key and direction (or nil for default)
    - the scale-index resolver (so this module never touches the tracked
      scale list; caller owns that)

  Primary sort is always by slotRank. Secondary sort is the user's column
  choice, or best-upgrade-% descending if no column chosen.

  Sort state (current column, current direction) lives in Addon.options as
  per-character settings: options:Get("sortColumn"), options:Get("sortDir").
  The UI reads/writes these via options, not directly here.

  Dependencies: utils
  Exports: Addon.sort
]]

local ADDON_NAME, Addon = ...

local sort = {}

-- Module references
local utils

-- ============================================================================
-- ROW VALUE EXTRACTION
-- ============================================================================

--[[
  Pure helper: extract the sort value for a row on a given column.

  columnKey is one of:
    "name"     -> item name string
    "buyout"   -> copper price number
    "time"     -> time-left enum number
    "lvl"      -> minimum level number (max of MH/OH levels for pairs)
    "scale_N"  -> percent on the Nth tracked scale, 0 if absent

  For "scale_N", the caller supplies scaleAtIndex(N) that returns the
  internal scale name for that column. This keeps sort decoupled from
  scale-tracking state ownership.

  @param a table - row
  @param columnKey string - column identifier
  @param scaleAtIndex function(n) - returns internal scale name for column N, or nil
  @return any - primary sort value
]]
local function rowSortValue(a, columnKey, scaleAtIndex)
    if columnKey == "name"   then return a.name or "" end
    if columnKey == "buyout" then return a.buyout or 0 end
    if columnKey == "time"   then return a.timeLeft or 0 end
    if columnKey == "lvl" then
        -- Pair rows sort by max of their two items' levels (same as displayed).
        if a.isPair then
            return math.max(
                (a.mhEntry and a.mhEntry.minLevel) or 0,
                (a.ohEntry and a.ohEntry.minLevel) or 0)
        end
        return a.minLevel or 0
    end

    -- scale_N: percent on the Nth tracked scale, 0 if this item doesn't upgrade it
    local idx = columnKey and tonumber(columnKey:match("^scale_(%d+)$"))
    if idx and scaleAtIndex then
        local targetScale = scaleAtIndex(idx)
        if targetScale and a.upgrades then
            for _, u in ipairs(a.upgrades) do
                if u.scale == targetScale then return u.percent end
            end
        end
        return 0
    end

    return 0
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Sort a row list in place.

  Primary sort: slotRank ascending (keeps slots grouped).
  Secondary:
    - If column+dir provided: by column value in direction, tie-broken by
      sortKey (best upgrade %) descending.
    - Otherwise: by sortKey (best upgrade %) descending.

  @param rows table - array of row tables (mutated in place)
  @param columnKey string|nil - column to sort by, or nil for default
  @param direction string|nil - "asc" or "desc", defaults to "asc"
  @param scaleAtIndex function|nil - see rowSortValue, required only if
                                      columnKey matches scale_N
]]
function sort:apply(rows, columnKey, direction, scaleAtIndex)
    if not rows then return end
    local dir = direction or "asc"

    table.sort(rows, function(x, y)
        local xr = x.slotRank or 99
        local yr = y.slotRank or 99
        if xr ~= yr then return xr < yr end

        if columnKey then
            local xv = rowSortValue(x, columnKey, scaleAtIndex)
            local yv = rowSortValue(y, columnKey, scaleAtIndex)
            if xv ~= yv then
                if dir == "asc" then return xv < yv end
                return xv > yv
            end
            -- Tie-break by best % desc so equal values still order sensibly.
            return (x.sortKey or 0) > (y.sortKey or 0)
        end

        -- Default: best upgrade % descending.
        return (x.sortKey or 0) > (y.sortKey or 0)
    end)
end

--[[
  Compute the next (column, direction) pair for a click on a header.
  Same-column click toggles direction; different-column click resets to asc.

  Pure function; caller decides what to do with the result (typically
  writes to options, fires a redraw).

  @param currentCol string|nil - current sort column
  @param currentDir string|nil - current direction
  @param clickedCol string - column the user clicked
  @return string, string - new (column, direction)
]]
function sort:cycle(currentCol, currentDir, clickedCol)
    if currentCol ~= clickedCol then
        return clickedCol, "asc"
    end
    local newDir = (currentDir == "asc") and "desc" or "asc"
    return clickedCol, newDir
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function sort:initialize()
    utils = Addon.utils
    if not utils then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444sort: Missing utils|r")
        return false
    end
    return true
end

if Addon.registerModule then
    Addon.registerModule("sort", {"utils"}, function()
        return sort:initialize()
    end)
end

Addon.sort = sort
return sort
