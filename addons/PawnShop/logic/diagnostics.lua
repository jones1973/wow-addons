--[[
  logic/diagnostics.lua
  Event-Driven Debug Logging

  Subscribes to scan/eval events and translates them into chat output.
  This replaces the inline log() calls that were scattered throughout the
  old monolithic Core.lua -- now the business-logic modules emit structured
  events and only this module produces human-readable output.

  All output goes through utils:debug() which is gated by options:Get
  ("debugMode"). If debug is off, all of this is silent. If on, you see
  the same phase-marker stream the old addon printed.

  Dependencies: utils, events, options
  Exports: Addon.diagnostics
]]

local ADDON_NAME, Addon = ...

local diagnostics = {}

-- Module references
local utils, events, options

-- ============================================================================
-- FORMATTERS
-- ============================================================================

--[[
  Format key=value pairs from a table with sorted keys.
  @param tbl table
  @return string
]]
local function formatCounts(tbl)
    local keys = {}
    for k in pairs(tbl) do table.insert(keys, k) end
    table.sort(keys)
    local parts = {}
    for _, k in ipairs(keys) do
        table.insert(parts, string.format("%s=%d", k, tbl[k]))
    end
    return table.concat(parts, " ")
end

--[[
  Format the elapsed time between two debugprofilestop marks.
  @param a number|nil
  @param b number|nil
  @return string
]]
local function formatMs(a, b)
    if not a or not b then return "--" end
    return string.format("%.0fms", b - a)
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

local function onScanStarted()
    utils:debug("scan: started")
end

local function onScanIngested(_, payload)
    utils:debug(string.format(
        "scan: ingest complete in %.0fms, stored %d auctions, %d unique",
        payload.ingestMs or 0, payload.count or 0, payload.unique or 0))
end

local function onScanEmpty()
    utils:debug("scan: zero items returned")
end

local function onScanCancelled(_, payload)
    utils:debug("scan: cancelled (" .. (payload.reason or "?") .. ")")
end

local function onEvalStarted(_, payload)
    utils:debug(string.format("eval: queue built, %d items", payload.total or 0))
end

local function onEvalPairBaseline(_, payload)
    local parts = {}
    for i, s in ipairs(payload.scaleOrder or {}) do
        table.insert(parts, string.format("scale%d=%.2f", i,
            (payload.baselineByScale and payload.baselineByScale[s]) or 0))
    end
    utils:debug("eval: pair baseline: " .. table.concat(parts, " "))
end

local function onEvalPairResult(_, payload)
    utils:debug(string.format(
        "eval: pair search %d MH x %d OH = %d combos, %d qualified, kept top %d (%.0fms)",
        payload.mhCount or 0, payload.ohCount or 0,
        payload.combinations or 0, payload.qualified or 0,
        payload.kept or 0, payload.elapsedMs or 0))
end

local function onEvalComplete(_, payload)
    local f = payload.fates or {}
    utils:debug(string.format("eval: Finalize: %d rows in grid", payload.rows or 0))
    utils:debug(string.format(
        "  Fates: not_gear=%d wrong_type=%d too_high=%d pending=%d not_upgrade=%d pawn_pending=%d upgrade=%d overflow=%d resolved=%d%s",
        f.not_gear or 0, f.wrong_type or 0, f.too_high or 0, f.pending or 0,
        f.not_upgrade or 0, f.pawn_pending or 0, f.upgrade or 0,
        f.scale_overflow or 0, f.resolved_promoted or 0,
        ((f.no_pawn or 0) > 0) and (" no_pawn=" .. f.no_pawn) or ""))

    local sd = payload.slotDiag or {}
    utils:debug("  ReachedPawn: " .. formatCounts(sd.reachedPawn or {}))
    utils:debug("  InGrid:      " .. formatCounts(sd.finalBySlot or {}))

    local t = payload.timing or {}
    utils:debug("=== Timing ===")
    utils:debug(string.format("  Click -> data arrived:     %s", formatMs(t.tScanClick,   t.tDataArrived)))
    utils:debug(string.format("  Data arrived -> ingest:    %s", formatMs(t.tDataArrived, t.tIngestDone)))
    utils:debug(string.format("  Ingest -> eval done:       %s", formatMs(t.tIngestDone,  t.tEvalDone)))
    utils:debug(string.format("  Total (click -> done):     %s", formatMs(t.tScanClick,   t.tEvalDone)))
end

local function onEvalCancelled()
    utils:debug("eval: cancelled")
end

local function onEvalPendingResolved(_, payload)
    -- Only noisy when something actually landed. Quiet "resolved 5 promoted 0".
    if (payload.promoted or 0) > 0 then
        utils:debug(string.format("eval: resolved pending, promoted %d (total rows: %d)",
            payload.promoted, payload.totalRows or 0))
    end
    -- One-time summary when all pending has drained and something made it
    -- to the grid after the main eval finished.
    if payload.allDrained and (payload.promoted or 0) > 0 then
        utils:debug("eval: all pending drained")
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function diagnostics:initialize()
    utils   = Addon.utils
    events  = Addon.events
    options = Addon.options

    if not utils or not events then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444diagnostics: Missing dependencies|r")
        return false
    end

    events:subscribe("SCAN:STARTED",            onScanStarted)
    events:subscribe("SCAN:AUCTIONS_INGESTED",  onScanIngested)
    events:subscribe("SCAN:EMPTY",              onScanEmpty)
    events:subscribe("SCAN:CANCELLED",          onScanCancelled)

    events:subscribe("EVAL:STARTED",            onEvalStarted)
    events:subscribe("EVAL:PAIR_BASELINE",      onEvalPairBaseline)
    events:subscribe("EVAL:PAIR_RESULT",        onEvalPairResult)
    events:subscribe("EVAL:COMPLETE",           onEvalComplete)
    events:subscribe("EVAL:CANCELLED",          onEvalCancelled)
    events:subscribe("EVAL:PENDING_RESOLVED",   onEvalPendingResolved)

    return true
end

if Addon.registerModule then
    Addon.registerModule("diagnostics", {"utils", "events"}, function()
        return diagnostics:initialize()
    end)
end

Addon.diagnostics = diagnostics
return diagnostics
