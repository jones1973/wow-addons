--[[
  logic/eval.lua
  Upgrade Evaluation Pipeline

  Chunked, time-budgeted evaluation of scanned auctions. For each deduped
  auction: decide whether it's gear, whether the class can equip it (both
  via proficiency tables and via a tooltip-red-line scan that catches
  professions, race/faction, and other runtime restrictions), whether it
  meets the level gate, and whether Pawn flags it as an upgrade. Items
  Pawn can't yet evaluate (GetItemInfo or PawnGetItemData pending) are
  parked in a pending set and re-examined when GET_ITEM_INFO_RECEIVED
  fires.

  Multi-instance slots (rings, trinkets) are handled specially: Pawn's
  native upgrade verdict compares the candidate to the WORSE of the two
  equipped items, and surfaces a single "Finger" or "Trinket" row. That
  hides which of the two equipped slots the candidate actually beats. For
  these slots, after Pawn says "yes this is an upgrade", we recompute
  percent vs each equipped slot independently and emit one row per slot
  the candidate actually improves -- "Ring 1" and "Ring 2" become
  distinct filter tabs.

  At the end of the main pass, MH/OH pair candidates (collected during the
  pass regardless of Pawn's single-item verdict, since Pawn short-circuits
  1H vs 2H comparisons) are synthesized into pair rows.

  State ownership: evalState (file-local). Other modules read rows/scales
  via getters. Cross-module signaling via events.

  Events emitted:
    EVAL:STARTED              { total }
    EVAL:ROWS_CHANGED         { }
    EVAL:PROGRESS             { index, total, tickMs, tickFates }
    EVAL:PAIR_BASELINE        { baselineByScale, scaleOrder }
    EVAL:PAIR_RESULT          { mhCount, ohCount, combinations, kept, elapsedMs }
    EVAL:COMPLETE             { rows, fates, slotDiag, timing }
    EVAL:CANCELLED            { }
    EVAL:PENDING_RESOLVED     { resolved, promoted, totalRows, allDrained }

  Events consumed:
    SCAN:AUCTIONS_INGESTED    kick off eval automatically after a scan

  Dependencies: utils, events, pawnIntegration, equipCheck, sort, scan,
                constants
  Exports: Addon.eval
]]

local ADDON_NAME, Addon = ...

local eval = {}

-- Module references
local utils, events, pawnIntegration, equipCheck, sort, scan, constants

-- ============================================================================
-- CONSTANTS
-- ============================================================================

-- Fate bucket keys. Defined once so tickFates and totalFates stay in sync.
local FATE_KEYS = {
    "not_gear", "wrong_type", "too_high", "pending",
    "not_upgrade", "pawn_pending", "no_pawn", "upgrade",
    "resolved_promoted",
}

local function newFateTable()
    local t = {}
    for _, k in ipairs(FATE_KEYS) do t[k] = 0 end
    return t
end

-- ============================================================================
-- MODULE STATE
-- ============================================================================

local evalState = {
    -- Output: display rows (survives across ticks; mutated in place).
    rows              = {},

    -- Set-keyed map of entries whose data was uncached at eval time.
    -- Drained by ResolvePendingNow when GET_ITEM_INFO_RECEIVED fires.
    pending           = {},

    -- Progress tracking for the chunked tick loop.
    evalQueue         = nil,   -- array of entries to process (nil = idle)
    evalIndex         = nil,   -- 1-based next index into evalQueue
    evalEpoch         = 0,     -- incremented on cancel so stale timers bail

    -- Scale registry. trackedScales[internalName] = column index (1..N).
    -- scaleOrder[i] is the internal name (for API calls).
    -- scaleDisplayOrder[i] is the localized name (for UI).
    trackedScales     = {},
    scaleOrder        = {},
    scaleDisplayOrder = {},

    -- Debounce state for the pending resolver.
    resolveScheduled       = false,
    resolveSummaryPrinted  = false,

    -- Running fate totals across the whole eval.
    totalFates        = newFateTable(),

    -- Per-slot diagnostic counters. reachedPawn is keyed by equipLoc
    -- (what the server returns), finalBySlot by display slot name.
    slotDiag = {
        reachedPawn = {},
        finalBySlot = {},
    },

    -- MH/OH candidates used by SynthesizePairs.
    pairCandidates = { mh = {}, oh = {} },

    -- Class-filtered multi-instance table for the current eval run.
    -- Rebuilt in eval:start from Addon.data.multiInstanceSlots plus
    -- Addon.data.weaponsDualWield (merged only when the player's class
    -- can dual wield). All Tick/ResolvePendingNow lookups go through
    -- this instead of the static data table so weapon handling is
    -- class-aware.
    activeMultiInstanceSlots = {},

    -- Snapshotted at eval start so mid-eval option changes don't cause
    -- inconsistent gating decisions.
    levelTolerance = 0,

    -- Timing.
    tEvalDone = nil,
}

-- ============================================================================
-- GETTERS
-- ============================================================================

function eval:getRows()              return evalState.rows              end
function eval:getScaleOrder()        return evalState.scaleOrder        end
function eval:getScaleDisplayOrder() return evalState.scaleDisplayOrder end
function eval:getTrackedScales()     return evalState.trackedScales     end

-- ============================================================================
-- PERSISTENCE
-- ============================================================================

--[[
  Snapshot enough state for an instant restore on next AH open. Stores
  the displayable rows and the scale registry; everything else (fates,
  diagnostics, pair candidates, pending resolver) is only meaningful
  during a live eval and is rebuilt fresh on the next scan.

  @return table
]]
function eval:serialize()
    return {
        rows              = evalState.rows,
        scaleOrder        = evalState.scaleOrder,
        scaleDisplayOrder = evalState.scaleDisplayOrder,
        trackedScales     = evalState.trackedScales,
    }
end

--[[
  Restore evalState from a serialized blob and emit EVAL:COMPLETE so
  panel renders. Used on AH open when scan data was persisted by a
  prior session and we want display without burning the cooldown.

  @param blob table - shape returned by eval:serialize()
]]
function eval:hydrate(blob)
    if not blob or type(blob.rows) ~= "table" then return end

    evalState.rows              = blob.rows
    evalState.scaleOrder        = blob.scaleOrder        or {}
    evalState.scaleDisplayOrder = blob.scaleDisplayOrder or {}
    evalState.trackedScales     = blob.trackedScales     or {}

    events:emit("EVAL:COMPLETE", {
        rows     = #evalState.rows,
        fates    = nil,        -- not tracked across restore
        slotDiag = nil,
        timing   = nil,
        restored = true,
    })
end

--[[
  Return the internal scale name for a 1-based column index, or nil if
  out of range. Used by sort.lua as the scaleAtIndex callback.

  Delegates to panel:getDisplayedScaleAt(n) if the panel is loaded, since
  the panel (not eval) owns which of the tracked scales are mapped to
  which visible columns via the scale-picker dropdowns. Falls back to
  scaleOrder[n] during very early load before the panel is available.

  @param n number
  @return string|nil
]]
function eval:scaleAtIndex(n)
    if Addon.panel and Addon.panel.getDisplayedScaleAt then
        local s = Addon.panel:getDisplayedScaleAt(n)
        if s then return s end
    end
    return evalState.scaleOrder[n]
end

function eval:isRunning()
    return evalState.evalQueue ~= nil
end

-- ============================================================================
-- TOOLTIP-BASED REQUIREMENT SCAN
-- ============================================================================

-- Hidden tooltip frame used to probe items for unmet requirements that
-- the proficiency table doesn't model (professions, race, faction, etc.).
-- We use tooltip scanning rather than IsUsableItem because the latter has
-- known reliability issues for profession-gated items (see Blizzard forum
-- thread "Issue with IsUsableItem" -- returns usable for some items the
-- character can't actually use).
local reqScanner

--[[
  Lazy getter for the scanner tooltip. The frame is anchored to WorldFrame
  with ANCHOR_NONE so it never displays visually.
]]
local function getReqScanner()
    if not reqScanner then
        reqScanner = CreateFrame("GameTooltip", "PawnShopReqScanner",
                                 nil, "GameTooltipTemplate")
        reqScanner:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    return reqScanner
end

--[[
  Check an item for any red tooltip line. In WoW, red requirement lines
  (approximately (1, 0.125, 0.125) in 0-1 RGB) mean "the character does
  not meet this requirement". Non-level gates (profession, class, race,
  faction, reputation) all use red lines.

  This is scoped to callers that have already cleared the level gate
  (minLevel <= playerLevel), so any red line encountered here is a
  non-level blocker and we reject the item.

  @param link string - item link (must be GetItemInfo-cached)
  @return boolean - true if any red line present (item is blocked)
]]
local function hasUnmetRequirement(link)
    local tip = getReqScanner()
    tip:SetOwner(WorldFrame, "ANCHOR_NONE")  -- re-owner in case of bleed
    tip:ClearLines()
    tip:SetHyperlink(link)

    -- Line 1 is the item name; requirements start at line 2+.
    for i = 2, tip:NumLines() do
        local fs = _G["PawnShopReqScannerTextLeft" .. i]
        if fs then
            local r, g, b = fs:GetTextColor()
            if r > 0.9 and g < 0.2 and b < 0.2 then
                return true
            end
        end
    end
    return false
end

-- ============================================================================
-- INTERNAL HELPERS (not part of public API)
-- ============================================================================

--[[
  Stamp slot rank and display name on an auction entry for grouping.
  Not used for multi-instance slots (rings/trinkets); those get stamped
  directly in splitToMultiInstanceRows with per-slot metadata.
  @param a table - auction entry (mutated)
  @param equipLoc string - from GetItemInfoInstant
]]
local function stampSlot(a, equipLoc)
    local def = Addon.data.slotOrder[equipLoc or ""] or Addon.data.slotDefault
    a.slotRank = def[1]
    a.slotName = def[2]
end

--[[
  Classify where an equipLoc can go for pair sourcing:
    "mh"   : main-hand only (INVTYPE_WEAPONMAINHAND)
    "oh"   : off-hand only (INVTYPE_WEAPONOFFHAND, INVTYPE_HOLDABLE, INVTYPE_SHIELD)
    "both" : INVTYPE_WEAPON (1H that can go either hand for dual-wielders)
    nil    : not a pair candidate
  Dual-wield gating (class can/can't DW two weapons) is applied by the caller.
]]
local function classifyWeaponRole(equipLoc)
    if equipLoc == "INVTYPE_WEAPONMAINHAND" then return "mh"   end
    if equipLoc == "INVTYPE_WEAPON"         then return "both" end
    if equipLoc == "INVTYPE_WEAPONOFFHAND"  then return "oh"   end
    if equipLoc == "INVTYPE_HOLDABLE"       then return "oh"   end
    if equipLoc == "INVTYPE_SHIELD"         then return "oh"   end
    return nil
end

--[[
  Given a Pawn upgrade list (entries have .scale=internal, .scaleDisplay=
  localized, .percent), filter to scales we're tracking. New scales are
  always appended to the tracking list -- there is no cap on discovered
  scales. The grid only displays DISPLAYED_SCALE_COLUMNS at a time, but
  the user can swap which tracked scales show via the dropdowns above
  the grid. Mutates evalState.trackedScales / scaleOrder / scaleDisplayOrder.

  Returns:
    kept - list of entries for tracked scales only, or nil if nothing kept
]]
local function filterToTrackedScales(upgradeList)
    local kept = {}
    for _, u in ipairs(upgradeList) do
        if not evalState.trackedScales[u.scale] then
            table.insert(evalState.scaleOrder, u.scale)
            table.insert(evalState.scaleDisplayOrder, u.scaleDisplay or u.scale)
            evalState.trackedScales[u.scale] = #evalState.scaleOrder
        end
        table.insert(kept, u)
    end
    if #kept == 0 then return nil end
    return kept
end

--[[
  Add row to the output, stamp slot, update diagnostics.
  Shared path between Tick and ResolvePendingNow for single-instance slots.
  Multi-instance slots (rings/trinkets/DW 1H weapons) use
  splitToMultiInstanceRows instead.

  When the equipped slot is empty (GetInventoryItemLink returns nil),
  every upgrade entry on this row gets flagged isEmptySlotUpgrade so the
  UI can render "NEW" instead of Pawn's artificial 10000%-style score.
  splitToMultiInstanceRows does the equivalent flagging per-slot for the
  multi-instance case; this keeps the two code paths symmetric.
  @param a table - auction entry already annotated with upgrades/sortKey
  @param equipLoc string
]]
local function promoteToRows(a, equipLoc)
    stampSlot(a, equipLoc)

    -- Stamp equippedLink from the corresponding inventory slot so the
    -- panel can show "<equipped item name>" in the slot-tab tooltip.
    -- Multi-instance slots don't reach here (they're handled upstream).
    local invSlot = Addon.data.equipLocToInvSlot[equipLoc or ""]
    if invSlot then
        a.equippedLink = GetInventoryItemLink("player", invSlot)
    end

    -- If the slot is empty, every upgrade on this row is an empty-slot
    -- upgrade. Pawn's percent against a nil equipped item is a canned
    -- placeholder (identical for every candidate -- typically +10000%),
    -- which would make every NEW row show the same score and prevent
    -- the user from telling candidates apart. Recompute percent as the
    -- candidate's raw score on each tracked scale, using the same
    -- logic as splitToMultiInstanceRows' empty-slot branch. sortKey
    -- updates to the max raw score so NEW rows sort strongest-first.
    --
    -- Upgrades that round to 0.0 at one decimal place are dropped --
    -- the scale doesn't meaningfully value this item (e.g. pure
    -- stamina item for a Rogue agility scale). If every upgrade
    -- filters out, the whole row is skipped.
    if a.upgrades and not a.equippedLink then
        local scaleNames = {}
        for _, u in ipairs(a.upgrades) do
            table.insert(scaleNames, u.scale)
        end
        local candidateValues = pawnIntegration:getScaleValues(a.link, scaleNames) or {}
        local kept = {}
        local maxScore = 0
        for _, u in ipairs(a.upgrades) do
            local score = candidateValues[u.scale] or 0
            -- Filter anything that rounds to 0 at integer precision --
            -- matches the "NEW %d" display so users never see "NEW 0"
            -- for items the scale doesn't meaningfully value.
            if math.floor(score + 0.5) > 0 then
                u.percent            = score
                u.isEmptySlotUpgrade = true
                table.insert(kept, u)
                if score > maxScore then maxScore = score end
            end
        end
        if #kept == 0 then
            -- No surviving upgrades on any tracked scale; skip this row
            -- entirely. The item is a "nothing" for this character.
            return
        end
        a.upgrades = kept
        a.sortKey  = maxScore
    elseif a.upgrades and a.equippedLink then
        -- Occupied slot: defend against Pawn's epsilon division.
        --
        -- When the equipped item raw-scores zero on a scale, Pawn computes
        -- PercentUpgrade = Difference / (BestValue + 1e-10), which blows
        -- up to a meaningless number on the order of 1e9. Detect this
        -- case by computing equipScore ourselves and override Pawn's
        -- nonsense value with the 9999 sentinel splitToMultiInstanceRows
        -- uses for the same scenario ("massive improvement, magnitude
        -- uncomputable").
        --
        -- This is safe for promoteToRows specifically because Pawn's
        -- PawnIsItemAnUpgrade pre-filters apples-to-oranges weapon
        -- comparisons (1H vs equipped 2H, 2H vs equipped 1H) by setting
        -- SkipScoreBasedUpgrades. Anything that reaches here is a 1:1
        -- slot comparison where equippedLink is the correct baseline.
        local scaleNames = {}
        for _, u in ipairs(a.upgrades) do
            table.insert(scaleNames, u.scale)
        end
        local equippedValues = pawnIntegration:getScaleValues(a.equippedLink, scaleNames) or {}
        local maxPct = 0
        for _, u in ipairs(a.upgrades) do
            local equipScore = equippedValues[u.scale] or 0
            if equipScore == 0 and (u.percent or 0) > 0 then
                u.percent = 9999
            end
            if (u.percent or 0) > maxPct then maxPct = u.percent end
        end
        a.sortKey = maxPct
    end

    table.insert(evalState.rows, a)
    evalState.slotDiag.finalBySlot[a.slotName or "?"] =
        (evalState.slotDiag.finalBySlot[a.slotName or "?"] or 0) + 1
end

--[[
  For multi-instance slots (rings, trinkets), split the candidate into one
  row per equipped slot it actually improves.

  Pawn's PawnIsItemAnUpgrade compares a candidate ring/trinket against the
  WORSE of the two equipped items -- the one the player would replace
  under a best-case swap. That's mathematically correct but produces a
  single "Finger" row whose percent is relative to the worse ring, hiding
  whether the candidate would also upgrade the better ring. We recompute
  per-slot: a candidate that beats only the worse ring produces one row
  (e.g. "Ring 2" tab, ~5%); a candidate that beats both produces two rows
  with independent percents. A candidate that beats neither (can happen
  when Pawn's worse-ring verdict is barely positive and our recompute
  drops it) produces zero rows.

  @param a table - auction entry (not mutated; shallow-copied per slot row)
  @param keptUpgrades table - upgrade entries filtered to tracked scales
  @param multi table - array of {slotID, rank, name} from multiInstanceSlots
  @return number - count of rows added (0, 1, or 2)
]]
local function splitToMultiInstanceRows(a, keptUpgrades, multi)
    -- Gather the scale names we need values for.
    local scaleNames = {}
    for _, u in ipairs(keptUpgrades) do
        table.insert(scaleNames, u.scale)
    end

    local candidateValues = pawnIntegration:getScaleValues(a.link, scaleNames) or {}
    local added = 0

    for _, slotInfo in ipairs(multi) do
        local equippedLink = GetInventoryItemLink("player", slotInfo.slotID)

        -- Resolve equipped values once. Distinguish three cases:
        --   * No equipped item:        equippedValues = {}   (treat as empty slot)
        --   * Equipped, Pawn cached:   equippedValues = real per-scale table
        --   * Equipped, Pawn pending:  skip slot this pass; next eval picks it up
        --
        -- The pending case used to fall through to "equipScore = 0,"
        -- which incorrectly made every candidate show as +9999%
        -- against an equipped ring whose data hadn't loaded yet.
        local equippedValues
        local skipSlot = false
        if not equippedLink then
            equippedValues = {}
        else
            equippedValues = pawnIntegration:getScaleValues(equippedLink, scaleNames)
            if not equippedValues then
                skipSlot = true
            end
        end

        if not skipSlot then
            local slotUpgrades = {}
            local maxPct = 0
            for _, u in ipairs(keptUpgrades) do
                local candScore  = candidateValues[u.scale] or 0
                local equipScore = equippedValues[u.scale] or 0
                local pct = nil
                local isEmpty = false
                if not equippedLink then
                    -- Slot literally empty: any candidate score that
                    -- rounds to > 0 at integer precision is an upgrade.
                    -- Filters out items the scale doesn't meaningfully
                    -- value (e.g. pure stamina items for a Rogue
                    -- agility scale). Display precision in panel.lua
                    -- matches: "NEW %d".
                    if math.floor(candScore + 0.5) > 0 then
                        pct = candScore
                        isEmpty = true
                    end
                elseif equipScore > 0 and candScore > equipScore then
                    pct = ((candScore / equipScore) - 1) * 100
                elseif equipScore == 0 and candScore > 0 then
                    -- Occupied slot but equipped genuinely scores 0
                    -- on this scale (common when the equipped item
                    -- has no relevant stats for this scale -- e.g.,
                    -- a quest ring with stamina against a Rogue
                    -- agility scale). Can't compute a meaningful
                    -- ratio; use a sentinel percent so the display
                    -- is honest: "massive improvement, magnitude
                    -- uncomputable." NOT flagged as empty -- the
                    -- slot has an item in it, it just scores zero.
                    --
                    -- Still filtered by the round-to-0 rule so a
                    -- candidate with a trivial score doesn't show
                    -- as +9999%.
                    if math.floor(candScore + 0.5) > 0 then
                        pct = 9999
                    end
                end
                if pct and pct > 0 then
                    table.insert(slotUpgrades, {
                        scale              = u.scale,
                        scaleDisplay       = u.scaleDisplay,
                        percent            = pct,
                        isEmptySlotUpgrade = isEmpty,
                    })
                    if pct > maxPct then maxPct = pct end
                end
            end

            if #slotUpgrades > 0 then
                -- Shallow clone so this slot's row has its own stamp
                -- without mutating the original auction entry (which
                -- may still be referenced by other slots in the same
                -- pass).
                local rowEntry = {}
                for k, v in pairs(a) do rowEntry[k] = v end
                rowEntry.slotRank     = slotInfo.rank
                rowEntry.slotName     = slotInfo.name
                rowEntry.upgrades     = slotUpgrades
                rowEntry.sortKey      = maxPct
                rowEntry.equippedLink = equippedLink
                table.insert(evalState.rows, rowEntry)
                evalState.slotDiag.finalBySlot[slotInfo.name] =
                    (evalState.slotDiag.finalBySlot[slotInfo.name] or 0) + 1
                added = added + 1
            end
        end
    end

    return added
end

--[[
  Apply the current user sort to evalState.rows and emit a redraw signal.
  Sort reads from options for column/direction; falls back to defaults.
]]
local function sortAndRedraw()
    local col = Addon.options and Addon.options:Get("sortColumn") or nil
    local dir = Addon.options and Addon.options:Get("sortDir")    or "asc"
    sort:apply(evalState.rows, col, dir, function(n) return eval:scaleAtIndex(n) end)
    events:emit("EVAL:ROWS_CHANGED", {})
end

-- ============================================================================
-- START
-- ============================================================================

--[[
  Begin a new evaluation over scan's deduped auction list. Wipes prior
  eval output and kicks off the tick loop.
]]
function eval:start()
    if evalState.evalQueue then return end

    -- Reset output state.
    wipe(evalState.rows)
    wipe(evalState.pending)
    wipe(evalState.trackedScales)
    wipe(evalState.scaleOrder)
    wipe(evalState.scaleDisplayOrder)
    wipe(evalState.slotDiag.reachedPawn)
    wipe(evalState.slotDiag.finalBySlot)
    wipe(evalState.pairCandidates.mh)
    wipe(evalState.pairCandidates.oh)
    evalState.totalFates = newFateTable()
    evalState.resolveSummaryPrinted = false

    -- Snapshot the level tolerance so mid-eval changes are inert.
    evalState.levelTolerance = (Addon.options and Addon.options:Get("levelTolerance")) or 2

    -- Build the class-filtered multi-instance table. Base table (rings
    -- and trinkets) applies to every class. Weapon entries merge in
    -- only when the current class can dual wield -- for non-DW classes,
    -- INVTYPE_WEAPON is single-instance (compared against slot 16 only)
    -- and falls through to the equipLocToInvSlot path.
    wipe(evalState.activeMultiInstanceSlots)
    for equipLoc, slots in pairs(Addon.data.multiInstanceSlots) do
        evalState.activeMultiInstanceSlots[equipLoc] = slots
    end
    local _, playerClass = UnitClass("player")
    if Addon.data.canDualWield[playerClass] then
        for equipLoc, slots in pairs(Addon.data.weaponsDualWield) do
            evalState.activeMultiInstanceSlots[equipLoc] = slots
        end
    end

    -- Build the queue from scan's deduped map. Wipe stale upgrade/sort/slot
    -- data from prior evals.
    local cheapestByLink = scan:getCheapestByLink()
    evalState.evalQueue = {}
    for _, entry in pairs(cheapestByLink) do
        entry.upgrades = nil
        entry.sortKey  = nil
        entry.slotRank = nil
        entry.slotName = nil
        table.insert(evalState.evalQueue, entry)
    end
    evalState.evalIndex = 1
    evalState.evalEpoch = evalState.evalEpoch + 1

    events:emit("EVAL:STARTED", { total = #evalState.evalQueue })

    if #evalState.evalQueue == 0 then
        eval:finalize()
        return
    end

    local myEpoch = evalState.evalEpoch
    C_Timer.After(0, function() eval:tickIfValid(myEpoch) end)
end

-- ============================================================================
-- TICK LOOP
-- ============================================================================

--[[
  Guard around Tick to catch epoch mismatches (cancel) and AH closure.
  @param epoch number
]]
function eval:tickIfValid(epoch)
    if epoch ~= evalState.evalEpoch then return end
    if not AuctionFrame or not AuctionFrame:IsShown() then
        eval:cancel()
        return
    end
    eval:tick()
end

--[[
  Process as many queue items as fit in EVAL_BUDGET_MS. Each item runs
  through the gear/proficiency/level/usable/pawn stages; pair candidates
  are collected in parallel. Budget exhausted or queue drained -> reschedule
  or finalize.
]]
function eval:tick()
    local q = evalState.evalQueue
    if not q then return end

    local total        = #q
    local tickStart    = debugprofilestop()
    local itemsThisTick = 0
    local playerLevel  = UnitLevel("player") or 70
    local _, playerClass = UnitClass("player")
    local levelTol     = evalState.levelTolerance
    local canDW        = Addon.data.canDualWield[playerClass] or false

    local tickFates = newFateTable()

    while evalState.evalIndex <= total do
        local a = q[evalState.evalIndex]
        local link = a and a.link or "?"

        -- Stage 1: gear class (sync, cheap).
        local _itemID, _itemType, _itemSubType, equipLoc, _icon, classID, subclassID =
            GetItemInfoInstant(link)
        local isGear = (classID == constants.ITEM_CLASS_ARMOR
                      or classID == constants.ITEM_CLASS_WEAPON)

        local fate
        if not isGear then
            fate = "not_gear"
        elseif not equipCheck:canEquipType(playerClass, classID, subclassID) then
            fate = "wrong_type"
        else
            -- Stage 3: level (needs GetItemInfo; may be async).
            local _n, _l, _q, _iLvl, minLevel = GetItemInfo(link)
            if not minLevel then
                fate = "pending"
                evalState.pending[a] = true
            elseif minLevel > playerLevel + levelTol then
                fate = "too_high"
            elseif minLevel <= playerLevel and hasUnmetRequirement(link) then
                -- Item is at or below our current level but has an unmet
                -- requirement in its tooltip (profession, race, faction,
                -- class, reputation). We only probe the tooltip when
                -- minLevel <= playerLevel; above-current-level items in
                -- the grow-into window accept proficiency-only gating
                -- since their tooltips would also show red "Requires
                -- Level X" lines we'd have to exempt.
                fate = "wrong_type"
            else
                local name, _lvl, quality = GetItemInfo(link)
                a.minLevel    = minLevel
                a.equipLoc    = equipLoc
                a.classID     = classID
                a.subclassID  = subclassID
                a.quality     = quality
                if name and not a.name then a.name = name end
                evalState.slotDiag.reachedPawn[equipLoc or "?"] =
                    (evalState.slotDiag.reachedPawn[equipLoc or "?"] or 0) + 1

                -- Collect 1H/OH pair candidates INDEPENDENT of Pawn's single-
                -- item upgrade verdict. Pawn short-circuits 1H vs equipped-2H
                -- comparisons (returns nil), so relying on PawnIsItemAnUpgrade
                -- would drop every candidate we need for pair scoring. Value
                -- scoring happens in SynthesizePairs once scaleOrder is stable.
                local role = classifyWeaponRole(equipLoc)
                if role then
                    local rec = { entry = a, equipLoc = equipLoc }
                    -- MH bucket: INVTYPE_WEAPON and INVTYPE_WEAPONMAINHAND.
                    if role == "mh" or role == "both" then
                        table.insert(evalState.pairCandidates.mh, rec)
                    end
                    -- OH bucket depends on role AND class DW ability:
                    --   "oh" INVTYPE_WEAPONOFFHAND: only if class can DW
                    --   "oh" holdable/shield:       always OH-eligible
                    --   "both" (INVTYPE_WEAPON):    only if class can DW
                    if role == "oh" then
                        if equipLoc == "INVTYPE_WEAPONOFFHAND" then
                            if canDW then
                                table.insert(evalState.pairCandidates.oh, rec)
                            end
                        else
                            table.insert(evalState.pairCandidates.oh, rec)
                        end
                    elseif role == "both" and canDW then
                        table.insert(evalState.pairCandidates.oh, rec)
                    end
                end

                local upgrades, reason = pawnIntegration:checkUpgrade(link)
                if upgrades then
                    local kept = filterToTrackedScales(upgrades)
                    if kept then
                        -- Multi-instance slots (rings, trinkets; 1H
                        -- weapons for DW classes) split the candidate
                        -- into per-equipped-slot rows. Single-instance
                        -- slots use the original stamp.
                        local multi = evalState.activeMultiInstanceSlots[equipLoc or ""]
                        if multi then
                            local added = splitToMultiInstanceRows(a, kept, multi)
                            if added > 0 then
                                fate = "upgrade"
                            else
                                -- Pawn said "upgrade vs worse slot" but
                                -- per-slot recompute dropped it on both
                                -- slots. Rare floating-point edge case.
                                fate = "not_upgrade"
                            end
                        else
                            fate = "upgrade"
                            local maxPct = 0
                            for _, u in ipairs(kept) do
                                if u.percent > maxPct then maxPct = u.percent end
                            end
                            a.upgrades = kept
                            a.sortKey  = maxPct
                            promoteToRows(a, equipLoc)
                        end
                    end
                else
                    fate = reason
                    if reason == "pending" then
                        evalState.pending[a] = true
                        fate = "pawn_pending"
                    end
                end
            end
        end

        tickFates[fate] = (tickFates[fate] or 0) + 1
        evalState.evalIndex = evalState.evalIndex + 1
        itemsThisTick = itemsThisTick + 1

        if (debugprofilestop() - tickStart) > constants.EVAL_BUDGET_MS then
            break
        end
    end

    local tickMs = debugprofilestop() - tickStart

    for k, v in pairs(tickFates) do
        evalState.totalFates[k] = (evalState.totalFates[k] or 0) + v
    end

    sortAndRedraw()

    events:emit("EVAL:PROGRESS", {
        index     = evalState.evalIndex - 1,
        total     = total,
        tickMs    = tickMs,
        tickFates = tickFates,
    })

    if evalState.evalIndex > total then
        eval:finalize()
        return
    end

    local myEpoch = evalState.evalEpoch
    C_Timer.After(constants.EVAL_YIELD_SEC, function() eval:tickIfValid(myEpoch) end)
end

-- ============================================================================
-- SYNTHESIZE PAIRS
-- ============================================================================

--[[
  Generate synthetic pair rows from MH x OH combinations that beat the
  equipped baseline on at least one tracked scale. Caps at PAIR_ROW_CAP
  rows (top N by best percent).
]]
function eval:synthesizePairs()
    local mhList = evalState.pairCandidates.mh
    local ohList = evalState.pairCandidates.oh
    local nScales = #evalState.scaleOrder

    if nScales == 0 or #mhList == 0 or #ohList == 0 then return end

    local baseline = pawnIntegration:computeEquippedBaseline(evalState.scaleOrder)

    events:emit("EVAL:PAIR_BASELINE", {
        baselineByScale = baseline,
        scaleOrder      = evalState.scaleOrder,
    })

    -- Capture what's currently equipped in MH/OH slots so every pair row
    -- can carry the links for the two-line "vs MH / vs OH" tab tooltip.
    -- Slot 16 = INVSLOT_MAINHAND, 17 = INVSLOT_OFFHAND. nil is fine when
    -- nothing is equipped; the UI falls back to "(empty)" in that case.
    local mhEquippedLink = GetInventoryItemLink("player", 16)
    local ohEquippedLink = GetInventoryItemLink("player", 17)

    local pairStart = debugprofilestop()
    local candidates = {}

    for _, mhRec in ipairs(mhList) do
        for _, ohRec in ipairs(ohList) do
            -- Same-entry check: an INVTYPE_WEAPON can end up in both buckets
            -- if the class can dual-wield. Don't pair it with itself.
            if mhRec.entry ~= ohRec.entry then
                -- Build a synthetic 2H by merging MH+OH stat tables and
                -- score it via Pawn's own PawnGetItemValue. More correct
                -- than summing two single-item scores: scale features
                -- like SpeedBaseline subtraction and unusable-stat traps
                -- get applied to the combined stats once, the way Pawn
                -- intends. For pure linear scales (typical caster) the
                -- result equals the additive sum.
                local combinedValues = pawnIntegration:getCombinedScaleValues(
                    mhRec.entry.link, ohRec.entry.link, evalState.scaleOrder)

                if combinedValues then
                    local kept = nil
                    local maxPct = 0
                    for _, scaleName in ipairs(evalState.scaleOrder) do
                        local combined = combinedValues[scaleName] or 0
                        local base = baseline[scaleName] or 0
                        local pct = nil
                        if base > 0 then
                            if combined > base then
                                pct = ((combined / base) - 1) * 100
                            end
                        elseif combined > 0 then
                            -- Baseline is 0 (empty slot, or equipped item Pawn
                            -- can't score). Any positive combined score counts.
                            -- Use raw combined as the "percent" so sort still
                            -- works and the largest pair still wins.
                            pct = combined
                        end

                        if pct and pct > 0 then
                            kept = kept or {}
                            table.insert(kept, {
                                scale        = scaleName,
                                scaleDisplay = evalState.scaleDisplayOrder[evalState.trackedScales[scaleName]] or scaleName,
                                percent      = pct,
                            })
                            if pct > maxPct then maxPct = pct end
                        end
                    end

                    if kept then
                        table.insert(candidates, {
                            isPair          = true,
                            mhEntry         = mhRec.entry,
                            ohEntry         = ohRec.entry,
                            name            = mhRec.entry.name .. " + " .. ohRec.entry.name,
                            buyout          = (mhRec.entry.buyout or 0) + (ohRec.entry.buyout or 0),
                            timeLeft        = math.min(mhRec.entry.timeLeft or 0, ohRec.entry.timeLeft or 0),
                            upgrades        = kept,
                            sortKey         = maxPct,
                            slotRank        = Addon.data.pairSlotRank,
                            slotName        = Addon.data.pairSlotName,
                            mhEquippedLink  = mhEquippedLink,
                            ohEquippedLink  = ohEquippedLink,
                        })
                    end
                end
            end
        end
    end

    -- Sort by best per-scale percent descending, keep top N.
    table.sort(candidates, function(x, y) return (x.sortKey or 0) > (y.sortKey or 0) end)
    local added = math.min(#candidates, constants.PAIR_ROW_CAP)
    for i = 1, added do
        table.insert(evalState.rows, candidates[i])
    end
    evalState.slotDiag.finalBySlot[Addon.data.pairSlotName] = added

    events:emit("EVAL:PAIR_RESULT", {
        mhCount      = #mhList,
        ohCount      = #ohList,
        combinations = #mhList * #ohList,
        qualified    = #candidates,
        kept         = added,
        elapsedMs    = debugprofilestop() - pairStart,
    })
end

-- ============================================================================
-- FINALIZE / CANCEL
-- ============================================================================

function eval:finalize()
    evalState.tEvalDone = debugprofilestop()

    self:synthesizePairs()

    evalState.evalQueue = nil
    evalState.evalIndex = nil

    sortAndRedraw()

    local scanTiming = scan:getTiming() or {}

    events:emit("EVAL:COMPLETE", {
        rows      = #evalState.rows,
        fates     = evalState.totalFates,
        slotDiag  = evalState.slotDiag,
        timing    = {
            tScanClick   = scanTiming.tScanClick,
            tDataArrived = scanTiming.tDataArrived,
            tIngestDone  = scanTiming.tIngestDone,
            tEvalDone    = evalState.tEvalDone,
        },
    })
end

function eval:cancel()
    if not evalState.evalQueue then return end
    evalState.evalQueue = nil
    evalState.evalIndex = nil
    evalState.evalEpoch = evalState.evalEpoch + 1
    events:emit("EVAL:CANCELLED", {})
end

-- ============================================================================
-- PENDING RESOLVER (GET_ITEM_INFO_RECEIVED handler)
-- ============================================================================

--[[
  Debounce wrapper. GET_ITEM_INFO_RECEIVED fires once per item; a burst of
  resolutions coalesces into one drain pass via a 0.1s timer.
]]
function eval:scheduleResolve()
    if evalState.resolveScheduled then return end
    evalState.resolveScheduled = true
    C_Timer.After(constants.PENDING_RESOLVE_DEBOUNCE, function()
        evalState.resolveScheduled = false
        eval:resolvePendingNow()
    end)
end

--[[
  Re-examine every pending entry. Items whose GetItemInfo has now resolved
  get re-gated and (if they qualify) promoted to rows.
]]
function eval:resolvePendingNow()
    if next(evalState.pending) == nil then return end

    local playerLevel = UnitLevel("player") or 70
    local _, playerClass = UnitClass("player")
    local levelTol = evalState.levelTolerance
    local resolved, promoted = 0, 0

    for a, _ in pairs(evalState.pending) do
        local name, _l, quality, _iLvl, minLevel = GetItemInfo(a.link)
        if minLevel then
            resolved = resolved + 1
            evalState.pending[a] = nil
            if minLevel <= playerLevel + levelTol then
                local _id, _t, _st, equipLoc, _ic, classID, subclassID =
                    GetItemInfoInstant(a.link)
                if equipCheck:canEquipType(playerClass, classID, subclassID)
                   and not (minLevel <= playerLevel and hasUnmetRequirement(a.link))
                then
                    -- Stamp minLevel onto the entry -- mirrors what Tick
                    -- does on the non-pending path. Without this, items
                    -- that were cold-cached at scan time and promoted via
                    -- resolvePendingNow would render with an empty Lvl
                    -- column because data.minLevel never got set.
                    a.minLevel    = minLevel
                    a.equipLoc    = equipLoc
                    a.classID     = classID
                    a.subclassID  = subclassID
                    a.quality     = quality
                    if name and not a.name then a.name = name end

                    evalState.slotDiag.reachedPawn[equipLoc or "?"] =
                        (evalState.slotDiag.reachedPawn[equipLoc or "?"] or 0) + 1
                    local upgrades, reason = pawnIntegration:checkUpgrade(a.link)
                    if upgrades then
                        local kept = filterToTrackedScales(upgrades)
                        if kept then
                            local multi = evalState.activeMultiInstanceSlots[equipLoc or ""]
                            if multi then
                                local added = splitToMultiInstanceRows(a, kept, multi)
                                promoted = promoted + added
                            else
                                local maxPct = 0
                                for _, u in ipairs(kept) do
                                    if u.percent > maxPct then maxPct = u.percent end
                                end
                                a.upgrades = kept
                                a.sortKey  = maxPct
                                promoteToRows(a, equipLoc)
                                promoted = promoted + 1
                            end
                        end
                    elseif reason == "pending" then
                        -- Pawn data still not cached; keep waiting.
                        evalState.pending[a] = true
                    end
                end
            end
        end
    end

    if promoted > 0 then
        evalState.totalFates.resolved_promoted = evalState.totalFates.resolved_promoted + promoted
        sortAndRedraw()
    end

    local allDrained = (next(evalState.pending) == nil)
    events:emit("EVAL:PENDING_RESOLVED", {
        resolved   = resolved,
        promoted   = promoted,
        totalRows  = #evalState.rows,
        allDrained = allDrained,
    })
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function eval:initialize()
    utils            = Addon.utils
    events           = Addon.events
    pawnIntegration  = Addon.pawnIntegration
    equipCheck       = Addon.equipCheck
    sort             = Addon.sort
    scan             = Addon.scan
    constants        = Addon.constants

    if not utils or not events or not pawnIntegration or not equipCheck
       or not sort or not scan or not constants then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444eval: Missing dependencies|r")
        return false
    end

    if not Addon.data or not Addon.data.canDualWield or not Addon.data.slotOrder
       or not Addon.data.multiInstanceSlots or not Addon.data.weaponsDualWield
       or not Addon.data.equipLocToInvSlot then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444eval: Missing data tables|r")
        return false
    end

    -- Auto-start eval after a successful scan ingest.
    events:subscribe("SCAN:AUCTIONS_INGESTED", function()
        eval:start()
    end)

    return true
end

if Addon.registerModule then
    Addon.registerModule("eval", {
        "utils", "events", "pawnIntegration", "equipCheck", "sort", "scan", "constants",
    }, function()
        return eval:initialize()
    end)
end

Addon.eval = eval
return eval
