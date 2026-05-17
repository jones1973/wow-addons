--[[
  core/expansion.lua
  Expansion / ItemVersion Soft-Dependency Wrapper

  Provides a clean Mobster-facing API over the ItemVersion addon.
  ItemVersion is optional (listed in Mobster.toc OptionalDeps); when
  it isn't loaded, isAvailable() returns false and callers branch on
  that to hide expansion-dependent UI.

  Major-number convention (ItemVersion):
    1 = Vanilla
    2 = Burning Crusade
    3 = Wrath of the Lich King
    4 = Cataclysm
    5 = Mists of Pandaria

  Note this is ItemVersion's own "major" number, which is the
  expansion ordinal +1 — distinct from Blizzard's GetExpansionLevel()
  which is 0-based (TBC = 1). We use ItemVersion's convention
  externally since the data we filter against is keyed that way.

  API:
    expansion.isAvailable()       → bool
    expansion.getCurrentMajor()   → int    (1..N, derived from GetExpansionLevel + 1)
    expansion.getMajorForItem(id) → int|nil  (nil if ItemVersion can't resolve)
    expansion.listAvailable()     → { {major=int, shortName=str}, ... }
                                     Sorted by major ascending, up to current.

  Dependencies: none (lazily probes _G.ItemVersion at call time)
  Exports: Addon.expansion
]]

local _, Addon = ...

local expansion = {}

-- ============================================================================
-- INTERNAL — ItemVersion access
-- ============================================================================

--[[
  Resolve ItemVersion's public API. Returns nil if ItemVersion isn't
  loaded or hasn't initialized yet. Probed every call so we tolerate
  late initialization without needing a registration handshake.
]]
local function getAPI()
    local iv = _G.ItemVersion
    if not iv or not iv.API then return nil end
    return iv.API
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function expansion.isAvailable()
    return getAPI() ~= nil
end

function expansion.getCurrentMajor()
    -- Blizzard's GetExpansionLevel is 0-based (Vanilla=0, TBC=1, ...);
    -- ItemVersion's major is 1-based (Vanilla=1, TBC=2, ...). Add 1.
    return (_G.GetExpansionLevel and _G.GetExpansionLevel() or 0) + 1
end

function expansion.getMajorForItem(itemId)
    local api = getAPI()
    if not api then return nil end
    local v = api.GetItemVersion(itemId, true)  -- apply corrections
    if not v or not v.expansion then return nil end
    return v.expansion.major
end

--[[
  Short-name lookup. ItemVersion's Expansion module owns these but
  isn't part of the public API; pull them from a probe call. If
  GetItemVersion gives us back an expansion record we cache its
  shortName. As a fallback for expansions we haven't probed, return
  a sensible English short.
]]
local SHORT_FALLBACK = {
    [1] = "Vanilla",
    [2] = "TBC",
    [3] = "WotLK",
    [4] = "Cata",
    [5] = "MoP",
}

function expansion.listAvailable()
    local current = expansion.getCurrentMajor()
    local out = {}
    for major = 1, current do
        out[#out + 1] = {
            major     = major,
            shortName = SHORT_FALLBACK[major] or ("Exp" .. major),
        }
    end
    return out
end

Addon.expansion = expansion
return expansion
