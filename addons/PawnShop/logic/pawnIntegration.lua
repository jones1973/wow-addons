--[[
  logic/pawnIntegration.lua
  Pawn Addon Integration

  Wraps Pawn's API to answer the questions Pawn Shop asks:

    1. "Is this link an upgrade?" -- normalizes Pawn's internal vs localized
       scale names so callers get a uniform shape.

    2. "What are the per-scale values for this link?" -- used for pair
       synthesis and equipped-baseline computation. Iterates a caller-
       supplied scale list and returns values keyed by internal scale name.

    3. "What's the equipped baseline?" -- sums MH + OH Pawn values per
       scale for pair scoring.

    4. Diagnostic: dump everything Pawn knows about an item, for the
       /ps pawn slash command.

  Proficiency checks (can this class equip this item) live in equipCheck.lua
  since they're independent of Pawn.

  Key API note on scale names: Pawn's upgrade list carries BOTH an internal
  ScaleName (like "Classic":DRUID1) and a LocalizedScaleName (like
  "Druid: Balance"). API calls like PawnGetSingleValueFromItem require the
  internal name -- passing the localized name produces the error
  "ScaleName must be the name of an existing scale, and is case-sensitive."
  So we store both: internal for API, localized for display.

  Dependencies: utils
  Exports: Addon.pawnIntegration
]]

local ADDON_NAME, Addon = ...

local pawnIntegration = {}

-- Module references (resolved in initialize)
local utils

-- ============================================================================
-- UPGRADE CHECK
-- ============================================================================

--[[
  Asks Pawn whether this item is an upgrade on any scale.

  Returns one of:
    upgradeList, nil         -- array of { scale, scaleDisplay, percent }
    nil, "pending"           -- Pawn data not cached yet; caller should retry
    nil, "not_upgrade"       -- Pawn says no scale is improved
    nil, "no_pawn"           -- Pawn addon not loaded

  The upgradeList entries carry BOTH the internal scale name (for later
  PawnGetSingleValueFromItem calls) and the localized name (for column
  headers and tooltips).

  percent is a real percentage (multiplied by 100 from Pawn's decimal form):
  a 12% upgrade comes back as 12, not 0.12.

  @param link string - full item link
  @return table|nil, string|nil
]]
function pawnIntegration:checkUpgrade(link)
    if not PawnGetItemData or not PawnIsItemAnUpgrade then
        return nil, "no_pawn"
    end
    local item = PawnGetItemData(link)
    if not item then
        return nil, "pending"
    end
    local upgrades = PawnIsItemAnUpgrade(item)
    if not upgrades or #upgrades == 0 then
        return nil, "not_upgrade"
    end
    local out = {}
    for _, u in ipairs(upgrades) do
        table.insert(out, {
            scale        = u.ScaleName or "?",
            scaleDisplay = u.LocalizedScaleName or u.ScaleName or "?",
            percent      = (u.PercentUpgrade or 0) * 100,
        })
    end
    return out
end

-- ============================================================================
-- PER-SCALE VALUES
-- ============================================================================

--[[
  Pulls enchanted Pawn values for a link across a given set of scales,
  forcing lazy calculation as needed.

  Pawn's `item.Values` array isn't guaranteed to contain every enabled
  scale until something calls PawnGetSingleValueFromItem -- which triggers
  Pawn's lazy value computation.

  Returns:
    byScale, nil, item    -- byScale[internalScaleName] = value (0 if scale doesn't apply)
    nil, "pending"        -- PawnGetItemData returned nil; retry
    nil, "no_pawn"        -- Pawn API missing

  @param link string - item link
  @param scaleNames table - array of internal scale names to value against
  @return table|nil, string|nil, table|nil  -- (values, error, pawnItem)
]]
function pawnIntegration:getScaleValues(link, scaleNames)
    if not PawnGetItemData or not PawnGetSingleValueFromItem then
        return nil, "no_pawn"
    end
    local item = PawnGetItemData(link)
    if not item then return nil, "pending" end

    local byScale = {}
    for _, scaleName in ipairs(scaleNames) do
        local v = PawnGetSingleValueFromItem(item, scaleName)
        byScale[scaleName] = v or 0
    end
    return byScale, nil, item
end

-- ============================================================================
-- EQUIPPED BASELINE
-- ============================================================================

--[[
  Compute the sum of MH + OH Pawn values for each tracked scale. This is
  the baseline that pair combinations must beat to be flagged as an upgrade.

  Empty slots contribute 0 (the byScale call simply returns nil and we add
  nothing). If Pawn returns nil for a slot (pending data), we also add
  nothing for that slot -- worst case, baseline is lower than reality for
  a tick, and a pair shows as "more of an upgrade" than it really is. Next
  eval pass (after Pawn catches up) corrects it.

  @param scaleNames table - array of internal scale names
  @return table - out[scaleName] = baseline value
]]
function pawnIntegration:computeEquippedBaseline(scaleNames)
    local out = {}
    for _, scaleName in ipairs(scaleNames) do out[scaleName] = 0 end

    -- INVSLOT_MAINHAND = 16, INVSLOT_OFFHAND = 17
    local slots = { 16, 17 }
    for _, slotID in ipairs(slots) do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local byScale = self:getScaleValues(link, scaleNames)
            if byScale then
                for _, scaleName in ipairs(scaleNames) do
                    out[scaleName] = out[scaleName] + (byScale[scaleName] or 0)
                end
            end
        end
    end
    return out
end

-- ============================================================================
-- DIAGNOSTIC DUMP (used by /ps pawn)
-- ============================================================================

--[[
  Print everything we can learn about Pawn's assessment of a single item.
  Shows: item data table keys, Values array (per-scale scores), upgrade
  check. Used by the /ps pawn slash command for debugging.

  @param link string - item link, or nil
  @param label string - label prefix for log output
]]
function pawnIntegration:dumpForLink(link, label)
    if not link then
        utils:chat(label .. ": no link")
        return
    end
    if not PawnGetItemData then
        utils:chat(label .. ": Pawn not loaded (PawnGetItemData missing)")
        return
    end

    utils:chat(string.format("=== %s: %s ===", label, link))

    local item = PawnGetItemData(link)
    if not item then
        utils:chat("  PawnGetItemData returned nil (not cached / invalid)")
        return
    end

    -- What fields does the item table have?
    local keys = {}
    for k in pairs(item) do table.insert(keys, k) end
    table.sort(keys)
    utils:chat("  item table keys: " .. table.concat(keys, ", "))

    -- item.Level / item.InvType give us slot context
    utils:chat(string.format("  Level=%s  InvType=%s",
        tostring(item.Level), tostring(item.InvType)))

    -- item.Values is the canonical per-scale scoring (from Pawn source).
    -- Shape: array of { ScaleName, Value, UnenchantedValue, ..., LocalizedScaleName }
    if item.Values then
        utils:chat(string.format("  Values[] has %d entries:", #item.Values))
        for i, v in ipairs(item.Values) do
            local parts = {}
            for j = 1, #v do
                table.insert(parts, tostring(v[j]))
            end
            utils:chat(string.format("    [%d] %s", i, table.concat(parts, " | ")))
        end
    else
        utils:chat("  item.Values = nil")
    end

    if PawnIsItemAnUpgrade then
        local upgrades = PawnIsItemAnUpgrade(item)
        if not upgrades then
            utils:chat("  PawnIsItemAnUpgrade: nil (not an upgrade)")
        else
            utils:chat(string.format("  PawnIsItemAnUpgrade: %d upgrade entries:", #upgrades))
            for i, u in ipairs(upgrades) do
                utils:chat(string.format("    [%d] scale=%s  pct=%.3f  existing=%s",
                    i, tostring(u.LocalizedScaleName or u.ScaleName),
                    u.PercentUpgrade or 0,
                    tostring(u.ExistingItemLink)))
            end
        end
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function pawnIntegration:initialize()
    utils = Addon.utils

    if not utils then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444pawnIntegration: Missing utils|r")
        return false
    end

    return true
end

if Addon.registerModule then
    Addon.registerModule("pawnIntegration", {"utils"}, function()
        return pawnIntegration:initialize()
    end)
end

Addon.pawnIntegration = pawnIntegration
return pawnIntegration
