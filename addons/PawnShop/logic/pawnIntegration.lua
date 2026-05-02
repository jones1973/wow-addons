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

--[[
  Score a synthetic "2H" formed by merging the stats of a MH 1H and an
  OH 1H. Used by pair synthesis (eval.lua synthesizePairs) so the pair
  is valued by Pawn's full PawnGetItemValue pipeline rather than as a
  naive sum of two single-item scores.

  Why this matters:
    Pawn scales can be non-purely-additive. Examples:
      - SpeedBaseline subtracts a baseline from weapon speed before
        applying its weight. Summing two pre-baseline scores
        double-subtracts the baseline; merging stats first applies it
        once, which is what Pawn intends.
      - Unusable-stat traps (ScaleValues[stat] <= PawnIgnoreStatValue)
        zero the whole item. Single-item scores already handle this,
        but merging means a forbidden stat on either weapon zeros the
        synthetic pair -- a stricter, more honest verdict.
      - Stat caps (rare in user scales, more common in mainline) get
        applied to combined totals.

    For pure linear caster scales (typical for spell-power scales),
    merged result equals additive sum -- no behavioral difference. The
    synthetic-stats path is a no-op for those callers. It's correctness
    insurance for the cases where the scale isn't purely additive.

  @param mhLink string - main-hand item link
  @param ohLink string - off-hand item link
  @param scaleNames table - array of internal scale names to score against
  @return table|nil, string|nil
          byScale[internalScaleName] = combined value (0 if scale doesn't apply)
          nil, "no_pawn"  - Pawn API missing
          nil, "pending"  - One or both items don't have Pawn data yet
]]
function pawnIntegration:getCombinedScaleValues(mhLink, ohLink, scaleNames)
    if not PawnGetItemData or not PawnGetItemValue then
        return nil, "no_pawn"
    end
    local mh = PawnGetItemData(mhLink)
    local oh = PawnGetItemData(ohLink)
    if not mh or not oh then return nil, "pending" end

    -- Merge the unenchanted stats tables -- summing per-stat keys. Pawn's
    -- Stats field is a {[statName] = quantity} map. Two items with the
    -- same stat have their quantities added; a stat present on only one
    -- carries through unchanged.
    --
    -- We use UnenchantedStats (the base item without temp enchants /
    -- buffs) for parity with how PawnGetSingleValueFromItem's "value"
    -- return is fed elsewhere -- consistent baseline keeps comparisons
    -- honest. (Pawn's Stats and UnenchantedStats are typically the same
    -- on AH-listed items since they're not enchanted yet.)
    local combinedStats = {}
    local mhStats = mh.UnenchantedStats or mh.Stats or {}
    local ohStats = oh.UnenchantedStats or oh.Stats or {}
    for stat, qty in pairs(mhStats) do
        combinedStats[stat] = (combinedStats[stat] or 0) + qty
    end
    for stat, qty in pairs(ohStats) do
        combinedStats[stat] = (combinedStats[stat] or 0) + qty
    end

    -- Item level: max of the two. PawnGetItemValue uses level for
    -- socket-value scaling; for non-socketed weapons (the common case)
    -- it doesn't matter. Max keeps us conservative on the upside.
    local combinedLevel = math.max(mh.Level or 0, oh.Level or 0)

    -- Socket bonus stats: same merge as primary stats. Both nil is fine
    -- (PawnGetItemValue handles nil).
    local combinedSocketBonus
    local mhSB = mh.UnenchantedSocketBonusStats or mh.SocketBonusStats
    local ohSB = oh.UnenchantedSocketBonusStats or oh.SocketBonusStats
    if mhSB or ohSB then
        combinedSocketBonus = {}
        if mhSB then
            for stat, qty in pairs(mhSB) do
                combinedSocketBonus[stat] = (combinedSocketBonus[stat] or 0) + qty
            end
        end
        if ohSB then
            for stat, qty in pairs(ohSB) do
                combinedSocketBonus[stat] = (combinedSocketBonus[stat] or 0) + qty
            end
        end
    end

    local byScale = {}
    for _, scaleName in ipairs(scaleNames) do
        -- DebugMessages=false, NoNormalization=false, NoReforging=true
        -- mirrors how PawnGetSingleValueFromItem invokes it for the
        -- enchanted-value return.
        local v = PawnGetItemValue(combinedStats, combinedLevel, combinedSocketBonus,
                                   scaleName, false, false, true)
        byScale[scaleName] = v or 0
    end
    return byScale
end

-- ============================================================================
-- ENABLED SCALES
-- ============================================================================

--[[
  Returns the list of Pawn scales currently visible (enabled) for THIS
  character, sorted alphabetically by localized name.

  Pawn's PawnGetAllScalesEx returns every scale Pawn knows about, including
  ones the player has hidden. We filter to IsVisible == true so callers
  see only the user's active set. Each character has independent visibility
  state -- a Druid's enabled scales differ from the same account's Mage.

  Used by the side panel to populate the filter-scale and companion-scale
  dropdowns. Called at scan time (eval:start) and on first AH open before
  any scan -- it's cheap, no caching needed.

  Returns:
    list, nil     -- array of { internalName, localizedName }, alpha-sorted
                     by localizedName. May be empty if no scales are visible.
    nil, "no_pawn" -- Pawn API missing
    nil, "not_ready" -- Pawn loaded but not initialized yet (early bootstrap)
]]
function pawnIntegration:getEnabledScales()
    if not PawnGetAllScalesEx then
        return nil, "no_pawn"
    end

    -- PawnGetAllScalesEx fails internally (VgerCore.Fail) if Pawn isn't
    -- initialized yet. Wrap in pcall to convert that into a clean
    -- "not_ready" signal callers can handle.
    local ok, all = pcall(PawnGetAllScalesEx)
    if not ok or type(all) ~= "table" then
        return nil, "not_ready"
    end

    local out = {}
    for _, entry in ipairs(all) do
        if entry.IsVisible then
            table.insert(out, {
                internalName  = entry.Name,
                localizedName = entry.LocalizedName or entry.Name,
            })
        end
    end

    -- Alphabetical by localized name. Pawn's own ordering groups by
    -- header (e.g., "<character>'s scales", "Wowhead scales") but for
    -- the visible-only subset all entries share one header anyway, so
    -- a flat alpha sort is what the user actually sees.
    table.sort(out, function(a, b)
        return a.localizedName < b.localizedName
    end)

    return out, nil
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
