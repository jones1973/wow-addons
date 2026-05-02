--[[
  logic/scan.lua
  Auction House Scanning

  Owns the "Scan All" pipeline end to end: query the server, ingest the
  batch from the "list" buffer, dedupe by stable link key.

  Harvests any successful getAll on the AH, regardless of which addon
  fired it. We hook QueryAuctionItems to detect getAll calls; whether
  the call came from us or another addon (Auctionator etc.), the server
  reply lands in the same "list" buffer and we ingest it.

  State ownership: this module owns scanState (file-local). Callers read
  via getters; writers go through public methods. Cross-module reactivity
  is via events, not shared state access.

  Events emitted:
    SCAN:STARTED               { source = "self" | "external" }
    SCAN:AUCTIONS_INGESTED     { count, unique, ingestMs, source }
    SCAN:CANCELLED             { reason }
    SCAN:EMPTY                 { source }

  Events consumed: none (the AH event wiring happens in ui/ahTab.lua,
  which calls scan:onListUpdate; scan:start fires our own getAll).

  Dependencies: utils, events, linkKey
  Exports: Addon.scan
]]

local ADDON_NAME, Addon = ...

local scan = {}

local utils, events, linkKey

-- AH getAll cooldown is 15 minutes per character (TBC Classic).
local GETALL_COOLDOWN_SECONDS = 15 * 60

local scanState = {
    -- Array of raw auctions seen in latest scan (server order).
    -- Entry shape: { link, name, count, buyout, minBid, owner, timeLeft }
    auctions       = {},

    -- Dedup: cheapestByLink[stableKey] = lowest-buyout entry for that key.
    cheapestByLink = {},

    -- True from the moment a getAll query is fired (by us or anyone we
    -- detect via the QueryAuctionItems hook) until we ingest the reply.
    -- Cleared on first AUCTION_ITEM_LIST_UPDATE we accept.
    expectingResults = false,

    -- "self" if our scan:start fired the query, "external" if we're
    -- harvesting another addon's getAll. Used in events for telemetry.
    pendingSource = nil,

    tScanClick     = nil,
    tDataArrived   = nil,
    tIngestDone    = nil,
}

-- ============================================================================
-- GETTERS
-- ============================================================================

function scan:getAuctions()       return scanState.auctions end
function scan:getCheapestByLink() return scanState.cheapestByLink end
function scan:isScanning()        return scanState.expectingResults end

function scan:getTiming()
    return {
        tScanClick   = scanState.tScanClick,
        tDataArrived = scanState.tDataArrived,
        tIngestDone  = scanState.tIngestDone,
    }
end

function scan:uniqueCount()
    local n = 0
    for _ in pairs(scanState.cheapestByLink) do n = n + 1 end
    return n
end

--[[
  Last successful scan timestamp (UNIX seconds), or nil if never scanned
  this session. Read from ps_tools so it survives reloads.
  @return number|nil
]]
function scan:getLastScanAt()
    return ps_tools and ps_tools.lastScanAt or nil
end

--[[
  Seconds remaining on the getAll cooldown, or 0 if ready. Computed from
  ps_tools.lastScanAt; if that's missing or older than the cooldown
  window, returns 0.
  @return number
]]
function scan:getCooldownRemaining()
    local last = self:getLastScanAt()
    if not last then return 0 end
    local elapsed = time() - last
    if elapsed >= GETALL_COOLDOWN_SECONDS then return 0 end
    return GETALL_COOLDOWN_SECONDS - elapsed
end

-- ============================================================================
-- RESET
-- ============================================================================

function scan:reset()
    wipe(scanState.auctions)
    wipe(scanState.cheapestByLink)
    scanState.expectingResults = false
    scanState.pendingSource    = nil
    scanState.tScanClick   = nil
    scanState.tDataArrived = nil
    scanState.tIngestDone  = nil
end

-- ============================================================================
-- START SCAN (our own getAll)
-- ============================================================================

--[[
  Kick off our own getAll query. Returns:
    true            -- query fired
    false, reason   -- couldn't start
  Reasons: "already_scanning", "ah_closed", "cooldown"
]]
function scan:start()
    if scanState.expectingResults then return false, "already_scanning" end
    if not AuctionFrame or not AuctionFrame:IsShown() then
        return false, "ah_closed"
    end

    local _canQ, canQAll = CanSendAuctionQuery()
    if not canQAll then return false, "cooldown" end

    self:reset()
    scanState.tScanClick      = debugprofilestop()
    scanState.expectingResults = true
    scanState.pendingSource   = "self"

    events:emit("SCAN:STARTED", { source = "self" })

    QueryAuctionItems("", nil, nil, 0, 0, 0, 0, 1, 0, true)
    return true
end

-- ============================================================================
-- CANCEL
-- ============================================================================

function scan:cancel(reason)
    if not scanState.expectingResults then return end
    scanState.expectingResults = false
    scanState.pendingSource    = nil
    events:emit("SCAN:CANCELLED", { reason = reason or "unspecified" })
end

-- ============================================================================
-- INGEST (triggered by AUCTION_ITEM_LIST_UPDATE)
-- ============================================================================

--[[
  Ingest the AH's "list" buffer into scanState. Called on every
  AUCTION_ITEM_LIST_UPDATE; only acts when expectingResults is true
  (i.e., a getAll fired and we haven't ingested yet). Rows where
  hasAllInfo=false (server hasn't streamed metadata yet) are skipped
  -- they'll arrive in a subsequent update.
]]
function scan:onListUpdate()
    if not scanState.expectingResults then return end

    local source = scanState.pendingSource or "external"
    scanState.expectingResults = false
    scanState.pendingSource    = nil
    scanState.tDataArrived     = debugprofilestop()

    local batchCount = GetNumAuctionItems("list")
    if not batchCount or batchCount == 0 then
        events:emit("SCAN:EMPTY", { source = source })
        return
    end

    local ingestStart = debugprofilestop()
    local skippedIncomplete = 0

    for i = 1, batchCount do
        local name, _texture, _count, _quality, _canUse, _level, _levelCol,
              minBid, _minInc, buyout, _bidAmt, _highBidder, _bidderFull,
              owner, _ownerFull, _saleStatus, _itemId, hasAllInfo
              = GetAuctionItemInfo("list", i)
        local link = GetAuctionItemLink("list", i)
        local timeLeft = GetAuctionItemTimeLeft("list", i)

        if not hasAllInfo then
            skippedIncomplete = skippedIncomplete + 1
        elseif link and name then
            local entry = {
                link     = link,
                name     = name,
                buyout   = buyout or 0,
                minBid   = minBid or 0,
                owner    = owner or "?",
                timeLeft = timeLeft or 0,
            }
            table.insert(scanState.auctions, entry)

            if buyout and buyout > 0 then
                local key = linkKey:compute(link)
                local existing = scanState.cheapestByLink[key]
                if not existing or buyout < existing.buyout then
                    scanState.cheapestByLink[key] = entry
                end
            end
        end
    end

    -- Stamp the cooldown timestamp. Survives reload via ps_tools SV.
    ps_tools = ps_tools or {}
    ps_tools.lastScanAt = time()

    -- Per-listing tracking (for time-bucket transitions etc.). The
    -- listingTracker module holds the map keyed by listing identity;
    -- it's a no-op if the module isn't loaded.
    if Addon.listingTracker and Addon.listingTracker.observe then
        Addon.listingTracker:observe(scanState.auctions)
    end

    local ingestMs = debugprofilestop() - ingestStart
    scanState.tIngestDone = debugprofilestop()

    events:emit("SCAN:AUCTIONS_INGESTED", {
        count             = #scanState.auctions,
        unique            = self:uniqueCount(),
        ingestMs          = ingestMs,
        source            = source,
        skippedIncomplete = skippedIncomplete,
    })
end

-- ============================================================================
-- QUERY HOOK (detect external getAll calls)
-- ============================================================================

local function installQueryHook()
    if not QueryAuctionItems then return end
    hooksecurefunc("QueryAuctionItems", function(_name, _minLvl, _maxLvl, _page,
                                                _usable, _rarity, _getAllArg1,
                                                _exact, _filterData, getAll)
        -- Only care about getAll=true queries; per-page browses don't
        -- harvest cleanly and aren't what we evaluate against.
        if not getAll then return end
        -- If we initiated, scan:start already set pendingSource = "self".
        if scanState.expectingResults then return end
        scanState.expectingResults = true
        scanState.pendingSource    = "external"
        events:emit("SCAN:STARTED", { source = "external" })
    end)
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

    installQueryHook()
    return true
end

if Addon.registerModule then
    Addon.registerModule("scan", {"utils", "events", "linkKey"}, function()
        return scan:initialize()
    end)
end

Addon.scan = scan
return scan
