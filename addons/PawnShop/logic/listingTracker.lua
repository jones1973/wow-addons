--[[
  logic/listingTracker.lua
  Per-Listing Observation and Time-Bucket Transition Tracking

  The auction API only exposes time-left as a coarse 4-bucket enum:
    1 = Short    (< 30 min)
    2 = Medium   (30 min - 2 hr)
    3 = Long     (2 hr - 12 hr)
    4 = VeryLong (12 hr - 48 hr)

  When we see the same listing across multiple scans and its bucket
  drops (e.g. Medium -> Short), we know the auction crossed that
  boundary somewhere between the previous and current scan -- giving
  us a tighter upper bound on remaining time than the bucket alone.
  We anchor at the transition timestamp and count down from the
  bucket's max-remaining (e.g. Short -> 30 min).

  Listing identity uses link + owner + minBid + buyout; these are
  stable over a listing's life. Two listings from the same seller
  with identical pricing are indistinguishable via the API and
  collapse to one tracked entry -- acceptable, since they were
  posted together and cross bucket boundaries together.

  Public API:
    listingTracker:observe(auctions)
        Update tracked state from a fresh scan's auction list. Skips
        rows lacking owner data (incomplete metadata).

    listingTracker:getRemaining(entry)
        Return (seconds, isAnchored) for a row. seconds is an
        upper-bound estimate; isAnchored is true when we have a
        bucket-transition anchor (more precise than the raw bucket).
        Returns (nil, false) if no estimate is available.

  Dependencies: utils
  Exports: Addon.listingTracker
]]

local ADDON_NAME, Addon = ...

local listingTracker = {}

-- Bucket index -> max remaining seconds (the "best case" within that
-- bucket). When a listing transitions DOWN to bucket B at time T, we
-- know remaining is at most BUCKET_MAX[B] seconds from T.
local BUCKET_MAX = {
    [1] = 30 * 60,           -- Short
    [2] = 2  * 60 * 60,      -- Medium
    [3] = 12 * 60 * 60,      -- Long
    [4] = 48 * 60 * 60,      -- VeryLong
}

-- Map of listingKey -> { highestBucket, transitionAt, transitionToBucket,
--                        lastSeenAt }
local tracked = {}

-- ============================================================================
-- KEY COMPOSITION
-- ============================================================================

local function listingKey(entry)
    if not entry or not entry.link or not entry.owner then return nil end
    if entry.owner == "?" then return nil end   -- incomplete metadata
    return string.format("%s|%s|%d|%d",
        entry.link,
        entry.owner,
        entry.minBid or 0,
        entry.buyout or 0)
end

-- ============================================================================
-- OBSERVE
-- ============================================================================

--[[
  Walk a fresh scan's auction list. For each listing we can identify,
  detect a bucket downgrade vs the last time we saw it and anchor the
  remaining-time estimate at the transition.

  Annotates each entry with:
    entry.listingKey         -- string identity (or nil if unidentifiable)
    entry.transitionAt       -- when bucket last dropped (or nil)
    entry.transitionToBucket -- bucket the listing dropped INTO (or nil)
]]
function listingTracker:observe(auctions)
    if type(auctions) ~= "table" then return end
    local now = time()

    for _, entry in ipairs(auctions) do
        local key = listingKey(entry)
        if key then
            entry.listingKey = key
            local prior = tracked[key]
            local bucket = entry.timeLeft

            if not prior then
                tracked[key] = {
                    highestBucket       = bucket,
                    transitionAt        = nil,
                    transitionToBucket  = nil,
                    lastSeenAt          = now,
                }
            else
                -- Bucket only decreases over a listing's life. If we
                -- see it lower than highestBucket, that's a transition.
                if bucket < (prior.highestBucket or bucket) then
                    prior.transitionAt       = now
                    prior.transitionToBucket = bucket
                    prior.highestBucket      = bucket
                end
                prior.lastSeenAt = now

                -- Decorate the entry with anchor info so renderers can
                -- compute remaining without needing direct access to us.
                entry.transitionAt       = prior.transitionAt
                entry.transitionToBucket = prior.transitionToBucket
            end
        end
    end
end

-- ============================================================================
-- ESTIMATE
-- ============================================================================

--[[
  Compute remaining-time estimate for an observed listing.
  @param entry table  -- a row decorated by observe()
  @return number|nil, boolean
      seconds      -- upper-bound estimate (nil if none)
      isAnchored   -- true if computed from a bucket transition
]]
function listingTracker:getRemaining(entry)
    if not entry then return nil, false end
    if entry.transitionAt and entry.transitionToBucket then
        local cap = BUCKET_MAX[entry.transitionToBucket]
        if cap then
            local elapsed = time() - entry.transitionAt
            local remaining = cap - elapsed
            if remaining < 0 then remaining = 0 end
            return remaining, true
        end
    end
    -- No anchor -- just the bucket's max as an upper bound.
    local cap = BUCKET_MAX[entry.timeLeft or 0]
    if cap then return cap, false end
    return nil, false
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function listingTracker:initialize()
    return true
end

if Addon.registerModule then
    Addon.registerModule("listingTracker", {"utils"}, function()
        return listingTracker:initialize()
    end)
end

Addon.listingTracker = listingTracker
return listingTracker
