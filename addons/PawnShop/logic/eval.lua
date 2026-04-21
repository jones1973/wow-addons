--[[
  logic/eval.lua
  Upgrade Evaluation Pipeline

  Chunked, time-budgeted evaluation of scanned auctions. For each deduped
  auction: decide whether it's gear, whether the class can equip it,
  whether it meets the level gate, and whether Pawn flags it as an
  upgrade. Items Pawn can't yet evaluate (GetItemInfo or PawnGetItemData
  pending) are parked in a pending set and re-examined when
  GET_ITEM_INFO_RECEIVED fires.

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
    "scale_overflow", "resolved_promoted",
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

--[[
  Return the internal scale name for a 1-based column index, or nil if out
  of range. Used by sort.lua as the scaleAtIndex callback.
  @param n number
  @return string|nil
]]
function eval:scaleAtIndex(n)
    return evalState.scaleOrder[n]
end

function eval:isRunning()
    return evalState.evalQueue ~= nil
end

-- ============================================================================
-- INTERNAL HELPERS (not part of public API)
-- ============================================================================

--[[
  Stamp slot rank and display name on an auction entry for grouping.
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
  localized, .percent), filter to scales we're tracking, adding new ones
  up to MAX_SCALE_COLUMNS. Mutates evalState.trackedScales /
  scaleOrder / scaleDisplayOrder.

  Returns:
    kept     - list of entries for tracked scales only, or nil if nothing kept
    overflow - true if the item upgraded a scale beyond our column cap
]]
local function filterToTrackedScales(upgradeList)
    local kept = {}
    local sawUntracked = false
    for _, u in ipairs(upgradeList) do
        if evalState.trackedScales[u.scale] then
            table.insert(kept, u)
        elseif #evalState.scaleOrder < constants.MAX_SCALE_COLUMNS then
            table.insert(evalState.scaleOrder, u.scale)
            table.insert(evalState.scaleDisplayOrder, u.scaleDisplay or u.scale)
            evalState.trackedScales[u.scale] = #evalState.scaleOrder
            table.insert(kept, u)
        else
            sawUntracked = true
        end
    end
    if #kept == 0 then
        return nil, sawUntracked
    end
    return kept, sawUntracked
end

--[[
  Add row to the output, stamp slot, update diagnostics.
  Shared path between Tick and ResolvePendingNow.
  @param a table - auction entry already annotated with upgrades/sortKey
  @param equipLoc string
]]
local function promoteToRows(a, equipLoc)
    stampSlot(a, equipLoc)
    table.insert(evalState.rows, a)
    evalState.slotDiag.finalBySlot[a.slotName or "?"] =
        (evalState.slotDiag.finalBySlot[a.slotName or "?"] or 0) + 1
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

    -- Reset user sort selection; scale columns are rebuilt from scratch.
    -- UI will re-apply its own preference on next redraw if desired.
    if Addon.options then
        Addon.options:Set("sortColumn", nil)
        Addon.options:Set("sortDir",    "asc")
    end

    -- Snapshot the level tolerance so mid-eval changes are inert.
    evalState.levelTolerance = (Addon.persistence
        and Addon.persistence:getCharacterSetting("levelTolerance"))
        or (Addon.options and Addon.options:Get("levelTolerance"))
        or 2

    -- Build the queue from scan's deduped map. Wipe stale upgrade/sort/slot
    -- data from prior evals (entries persist via ps_scanCache across reloads).
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
  through the gear/proficiency/level/pawn stages; pair candidates are
  collected in parallel. Budget exhausted or queue drained -> reschedule
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
            else
                a.minLevel = minLevel
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
                    local kept, _sawUntracked = filterToTrackedScales(upgrades)
                    if not kept then
                        fate = "scale_overflow"
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

    -- Pre-score each candidate now that scaleOrder is finalized. Doing this
    -- here rather than inside the MxO loop means (M + O) Pawn calls instead
    -- of (M * O).
    for _, rec in ipairs(mhList) do
        if not rec.values then
            rec.values = pawnIntegration:getScaleValues(rec.entry.link, evalState.scaleOrder) or {}
        end
    end
    for _, rec in ipairs(ohList) do
        if not rec.values then
            rec.values = pawnIntegration:getScaleValues(rec.entry.link, evalState.scaleOrder) or {}
        end
    end

    local baseline = pawnIntegration:computeEquippedBaseline(evalState.scaleOrder)

    events:emit("EVAL:PAIR_BASELINE", {
        baselineByScale = baseline,
        scaleOrder      = evalState.scaleOrder,
    })

    local pairStart = debugprofilestop()
    local candidates = {}

    for _, mhRec in ipairs(mhList) do
        for _, ohRec in ipairs(ohList) do
            -- Same-entry check: an INVTYPE_WEAPON can end up in both buckets
            -- if the class can dual-wield. Don't pair it with itself.
            if mhRec.entry ~= ohRec.entry then
                local kept = nil
                local maxPct = 0
                for _, scaleName in ipairs(evalState.scaleOrder) do
                    local combined = (mhRec.values[scaleName] or 0)
                                   + (ohRec.values[scaleName] or 0)
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
                        isPair   = true,
                        mhEntry  = mhRec.entry,
                        ohEntry  = ohRec.entry,
                        name     = mhRec.entry.name .. " + " .. ohRec.entry.name,
                        buyout   = (mhRec.entry.buyout or 0) + (ohRec.entry.buyout or 0),
                        timeLeft = math.min(mhRec.entry.timeLeft or 0, ohRec.entry.timeLeft or 0),
                        upgrades = kept,
                        sortKey  = maxPct,
                        slotRank = Addon.data.pairSlotRank,
                        slotName = Addon.data.pairSlotName,
                    })
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
        local _n, _l, _q, _iLvl, minLevel = GetItemInfo(a.link)
        if minLevel then
            resolved = resolved + 1
            evalState.pending[a] = nil
            if minLevel <= playerLevel + levelTol then
                local _id, _t, _st, equipLoc, _ic, classID, subclassID =
                    GetItemInfoInstant(a.link)
                if equipCheck:canEquipType(playerClass, classID, subclassID) then
                    evalState.slotDiag.reachedPawn[equipLoc or "?"] =
                        (evalState.slotDiag.reachedPawn[equipLoc or "?"] or 0) + 1
                    local upgrades, reason = pawnIntegration:checkUpgrade(a.link)
                    if upgrades then
                        local kept = filterToTrackedScales(upgrades)
                        if kept then
                            local maxPct = 0
                            for _, u in ipairs(kept) do
                                if u.percent > maxPct then maxPct = u.percent end
                            end
                            a.upgrades = kept
                            a.sortKey  = maxPct
                            promoteToRows(a, equipLoc)
                            promoted = promoted + 1
                        end
                        -- else: scale_overflow, drop silently
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

    if not Addon.data or not Addon.data.canDualWield or not Addon.data.slotOrder then
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
