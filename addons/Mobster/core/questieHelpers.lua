--[[
  core/questieHelpers.lua
  Questie-data-interpretation primitives

  Centralizes how Mobster reads Questie's data shapes. Consumers
  (nameTypeahead, itemDropIndex, anything else that touches
  Questie-derived NPC/zone data) call into this module instead of
  re-implementing the readers.

  Public API:
    questieHelpers:stripNumericSuffix(name)
        Strip Questie's "(N)" heroic-variant suffix, where N is any
        integer. Returns (baseName, wasSuffixed).

    questieHelpers:zoneDisplayName(zoneId)
        Resolve a Questie zone ID to its localized display name.
        Returns string on success, nil if Questie is unavailable or
        the zone can't be resolved.

    questieHelpers:isHeroicVariant(normalHealth, heroicHealth)
        Returns true if heroicHealth indicates a real heroic boss
        scaled from normalHealth, rather than a data artifact.
        Real heroics scale boss health UP from normal (typically
        125-150%); artifacts tend to have placeholder values like
        5000 regardless of the normal-variant's health.
        Threshold: heroic must be at least 50% of normal.

  Caching:
    QuestieJourneyUtils and l10n module references are looked up
    once and cached at module scope. Per-zoneId resolutions are
    also cached after first lookup.
]]

local _, Addon = ...

local questieHelpers = {}

-- ============================================================================
-- INTERNAL STATE
-- ============================================================================

local qju             -- QuestieJourneyUtils module (cached on first need)
local l10n            -- l10n module (cached on first need)
local modulesResolved -- true once we've attempted resolution, regardless of
                     -- success — avoids retrying every call if Questie's
                     -- absent at the time of first use

local zoneNameCache = {}   -- {[zoneId] = string|false}, false = unresolvable

local function ensureModules()
    if modulesResolved then return qju ~= nil and l10n ~= nil end
    modulesResolved = true

    local loader = _G.QuestieLoader
    if not loader or not loader.ImportModule then return false end

    local _, _qju  = pcall(loader.ImportModule, loader, "QuestieJourneyUtils")
    local _, _l10n = pcall(loader.ImportModule, loader, "l10n")
    qju  = _qju
    l10n = _l10n
    return qju ~= nil and l10n ~= nil
end

-- ============================================================================
-- API
-- ============================================================================

function questieHelpers:stripNumericSuffix(name)
    local stripped = name:match("^(.-)%s*%(%d+%)$")
    if stripped then return stripped, true end
    return name, false
end

function questieHelpers:zoneDisplayName(zoneId)
    local cached = zoneNameCache[zoneId]
    if cached ~= nil then
        if cached == false then return nil end
        return cached
    end

    if not ensureModules() then
        zoneNameCache[zoneId] = false
        return nil
    end

    local ok, raw = pcall(qju.GetZoneName, qju, zoneId)
    if not ok or not raw then
        zoneNameCache[zoneId] = false
        return nil
    end

    -- l10n is a table with a __call metamethod; call it to localize.
    local ok2, localized = pcall(l10n, raw)
    local result = (ok2 and localized) or raw
    zoneNameCache[zoneId] = result
    return result
end

function questieHelpers:isHeroicVariant(normalHealth, heroicHealth)
    -- Real heroic dungeon NPCs in Questie's data scale health UP
    -- from normal (typically 125-150%). Data artifacts (battleground
    -- NPCs with stray "(1)" entries) use placeholder health like
    -- 5000 regardless of the normal-variant's actual stats.
    --
    -- Threshold of 50% catches the artifacts while keeping real
    -- heroics. If either side is missing/zero, fall back to
    -- accepting the pair — better to surface a possibly-bogus row
    -- than drop a real heroic.
    if not normalHealth or not heroicHealth then return true end
    if normalHealth <= 0 then return true end
    return heroicHealth >= normalHealth * 0.5
end

function questieHelpers:initialize()
    return true
end

Addon.questieHelpers = questieHelpers
return questieHelpers
