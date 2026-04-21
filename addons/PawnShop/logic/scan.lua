--[[
  logic/scan.lua
  Auction House Scanning

  Owns the "Scan All" pipeline end to end: query the server, ingest the
  batch from the "list" buffer, dedupe by stable link key, persist the
  result to ps_scanCache for dev-iteration reload-safety.

  State ownership: this module owns scanState (file-local). Callers read
  via getters; writers go through public methods. Cross-module reactivity
  is via events, not shared state access.

  Events emitted:
    SCAN:STARTED               { }
    SCAN:AUCTIONS_INGESTED     { count, unique, ingestMs }
    SCAN:CANCELLED             { reason }
    SCAN:EMPTY                 { } -- server returned 0 items

  Events consumed: none (the ADDON_LOADED restore and AH event wiring
  happens in ui/ahTab.lua, which calls scan:start / scan:onListUpdate
  directly).

  Dependencies: utils, events, linkKey
  Exports: Addon.scan
]]

local ADDON_NAME, Addon = ...

local scan = {}

-- Module references (resolved in initialize)
local utils, events, linkKey

-- ============================================================================
-- MODULE STATE (owned exclusively by this module)
-- ============================================================================

local scanState = {
    -- Array of raw auctions seen in latest scan (order = server order).
    -- Entry shape: { link, name, count, buyout, owner, timeLeft }
    auctions       = {},

    -- Dedup: cheapestByLink[stableKey] = the entry with the lowest buyout
    -- among all listings sharing that stable link key.
    cheapestByLink = {},

    -- Flag flipped when we fire the query and cleared on first list-update.
    -- Used to ignore spurious AUCTION_ITEM_LIST_UPDATE events from AH
    -- browsing activity we didn't initiate.
    isScanning     = false,

    -- Timing milestones (ms, from debugprofilestop). Downstream (eval's
    -- Finalize summary) reads these through scan:getTiming().
    tScanClick     = nil,
    tDataArrived   = nil,
    tIngestDone    = nil,
}

-- ============================================================================
-- GETTERS (read-only access for other modules)
-- ============================================================================

function scan:getAuctions()
    return scanState.auctions
end

function scan:getCheapestByLink()
    return scanState.cheapestByLink
end

function scan:isScanning()
    return scanState.isScanning
end

function scan:getTiming()
    return {
        tScanClick   = scanState.tScanClick,
        tDataArrived = scanState.tDataArrived,
        tIngestDone  = scanState.tIngestDone,
    }
end

--[[
  Count unique entries in cheapestByLink. O(n) over the dedup map.
  Cached? Not worth it: this is only called at status/summary points.
  @return number
]]
function scan:uniqueCount()
    local n = 0
    for _ in pairs(scanState.cheapestByLink) do n = n + 1 end
    return n
end

-- ============================================================================
-- RESET (called before a new scan, or when scrapping restored data)
-- ============================================================================

--[[
  Clear all scan state in place. In-place wipe (not reassignment) so any
  references other modules hold stay valid.
]]
function scan:reset()
    wipe(scanState.auctions)
    wipe(scanState.cheapestByLink)
    scanState.isScanning   = false
    scanState.tScanClick   = nil
    scanState.tDataArrived = nil
    scanState.tIngestDone  = nil
end

-- ============================================================================
-- RESTORE FROM SAVEDVARIABLE (dev-iteration convenience)
-- ============================================================================

--[[
  Rehydrate scan state from the ps_scanCache SV. Rebuilds the dedup map
  from the stored auction list using the same stable-key logic as ingest,
  so a restored scan is indistinguishable from a fresh one at eval time.

  Safe to call when the SV is empty or missing; no-op in that case.

  Returns the age of the restored data in seconds, or nil if nothing
  restored.
  @return number|nil, number|nil - (auction count, age seconds)
]]
function scan:restoreFromCache()
    if not ps_scanCache or not ps_scanCache.auctions then return nil end
    local cached = ps_scanCache.auctions
    if #cached == 0 then return nil end

    -- Replace auctions in place.
    wipe(scanState.auctions)
    for _, entry in ipairs(cached) do
        table.insert(scanState.auctions, entry)
    end

    -- Rebuild dedup from restored auctions (stable key, not raw link).
    wipe(scanState.cheapestByLink)
    for _, entry in ipairs(scanState.auctions) do
        if entry.buyout and entry.buyout > 0 then
            local key = linkKey:compute(entry.link)
            local existing = scanState.cheapestByLink[key]
            if not existing or entry.buyout < existing.buyout then
                scanState.cheapestByLink[key] = entry
            end
        end
    end

    local age = ps_scanCache.scannedAt and (time() - ps_scanCache.scannedAt) or nil
    return #scanState.auctions, age
end

-- ============================================================================
-- START SCAN
-- ============================================================================

--[[
  Kick off a full-AH "getAll" query.

  Returns one of:
    true            -- query fired
    false, reason   -- couldn't start; reason is a short string

  Reasons: "already_scanning", "ah_closed", "cooldown"
]]
function scan:start()
    if scanState.isScanning then
        return false, "already_scanning"
    end
    if not AuctionFrame or not AuctionFrame:IsShown() then
        return false, "ah_closed"
    end

    local _canQ, canQAll = CanSendAuctionQuery()
    if not canQAll then
        return false, "cooldown"
    end

    -- Fresh state for the new scan.
    self:reset()

    scanState.tScanClick = debugprofilestop()
    scanState.isScanning = true

    events:emit("SCAN:STARTED", {})

    -- The 10-arg QueryAuctionItems with getAll=true is the TBC/MoP-Classic
    -- "full scan" form: blank name, zero-filter, page 0, getAll=true.
    QueryAuctionItems("", nil, nil, 0, 0, 0, 0, 1, 0, true)

    return true
end

-- ============================================================================
-- CANCEL SCAN
-- ============================================================================

--[[
  Abort an in-flight scan (e.g., AH closed before data arrived). Does NOT
  touch auctions/cheapestByLink -- those may contain valid data from a
  prior completed scan that the UI still wants to show.

  @param reason string|nil
]]
function scan:cancel(reason)
    if not scanState.isScanning then return end
    scanState.isScanning = false
    events:emit("SCAN:CANCELLED", { reason = reason or "unspecified" })
end

-- ============================================================================
-- INGEST (triggered by AUCTION_ITEM_LIST_UPDATE)
-- ============================================================================

--[[
  Read every listing from the "list" buffer into scanState.auctions, track
  the cheapest per stable link key, persist to SV.

  The server occasionally sends a second AUCTION_ITEM_LIST_UPDATE for the
  same getAll (observed empirically); we clear isScanning immediately to
  make the second one a no-op and avoid double-ingesting.

  If the batch is empty, emit SCAN:EMPTY and return without clearing
  auctions. This preserves any prior-scan data for the UI to keep showing.
]]
function scan:onListUpdate()
    -- Silently ignore updates that aren't for our query.
    if not scanState.isScanning then return end

    -- Flip the flag up front so a second fire is a no-op.
    scanState.isScanning = false
    scanState.tDataArrived = debugprofilestop()

    local batchCount = GetNumAuctionItems("list")

    if not batchCount or batchCount == 0 then
        events:emit("SCAN:EMPTY", {})
        return
    end

    local ingestStart = debugprofilestop()

    for i = 1, batchCount do
        local name, _texture, count, _quality, _canUse, _level, _levelCol,
              _minBid, _minInc, buyout, _bidAmt, _highBidder, _bidderFull,
              owner = GetAuctionItemInfo("list", i)
        local link = GetAuctionItemLink("list", i)
        local timeLeft = GetAuctionItemTimeLeft("list", i)

        if link and name then
            local entry = {
                link     = link,
                name     = name,
                count    = count or 1,
                buyout   = buyout or 0,
                owner    = owner or "?",
                timeLeft = timeLeft or 0,
            }
            table.insert(scanState.auctions, entry)

            -- Dedup on stable key so auctions that differ only in uniqueID
            -- collapse to one entry. Only track buyout>0 (skip bid-only).
            if buyout and buyout > 0 then
                local key = linkKey:compute(link)
                local existing = scanState.cheapestByLink[key]
                if not existing or buyout < existing.buyout then
                    scanState.cheapestByLink[key] = entry
                end
            end
        end
    end

    local ingestMs = debugprofilestop() - ingestStart
    scanState.tIngestDone = debugprofilestop()

    -- Persist for dev iteration. Reload-safe; survives until next scan.
    ps_scanCache = ps_scanCache or {}
    ps_scanCache.auctions  = scanState.auctions
    ps_scanCache.scannedAt = time()

    events:emit("SCAN:AUCTIONS_INGESTED", {
        count    = #scanState.auctions,
        unique   = self:uniqueCount(),
        ingestMs = ingestMs,
    })
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function scan:initialize()
    utils   = Addon.utils
    events  = Addon.events
    linkKey = Addon.linkKey

    if not utils or not events or not linkKey then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444scan: Missing dependencies|r")
        return false
    end

    return true
end

if Addon.registerModule then
    Addon.registerModule("scan", {"utils", "events", "linkKey"}, function()
        return scan:initialize()
    end)
end

Addon.scan = scan
return scan
