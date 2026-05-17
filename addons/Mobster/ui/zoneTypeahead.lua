--[[
  ui/zoneTypeahead.lua
  Zone-name typeahead, backed by Questie's spawn data

  Search backend for the Zone field in the edit panel. Wraps a
  typeaheadPicker instance with a zone-specific query and rendering.

  Zones are simpler than NPCs: just strings, no name+zone pairs, no
  variants, no current-zone partition. The dropdown chrome (scroll,
  pool, debounce, anchoring, hover) lives in the shared
  typeaheadPicker. Compare ui/nameTypeahead.lua for a more complex
  consumer of the same chrome.

  The zone list is built lazily on first query: walks every NPC's
  spawn data once via Questie, dedupes zone IDs, resolves each via
  QuestieJourneyUtils + l10n. Sourced from Questie (rather than a
  hardcoded TBC zone list) so the strings exactly match what
  GetZoneText() returns at scan time and what the NPC typeahead
  pre-fills when a user picks a Questie NPC — no string-mismatch
  bugs between picker and matcher.

  Public API:
    zoneTypeahead:attach(editBox, parent, width, onPick, opts)
    zoneTypeahead:onQuery(text)
    zoneTypeahead:hide()

  Where onPick(zoneName) — single arg.

  Dependencies: typeaheadPicker, panel, pool
  Exports: Addon.zoneTypeahead
]]

local ADDON_NAME, Addon = ...

local zoneTypeahead = {}

-- ============================================================================
-- FILE-LOCAL CONSTANTS
-- ============================================================================

local MAX_RESULTS    = 100
local DEBOUNCE       = 0.2
local MIN_QUERY_LEN  = 1
local VISIBLE_ROWS   = 7
local ROW_HEIGHT     = 24
local ROW_TEXT_TOP   = 5
local ROW_INSET      = 10

local SCROLL_FRAME_NAME = ADDON_NAME .. "ZoneTypeaheadScroll"

-- ============================================================================
-- ZONE LIST CACHE
-- ============================================================================

local zoneList   -- sorted array of unique zone strings, lazy-built

local function resolveQuestie()
    local loader = _G.QuestieLoader
    if not loader or not loader.ImportModule then
        return nil
    end
    local ok, qdb     = pcall(loader.ImportModule, loader, "QuestieDB")
    local _,  qju     = pcall(loader.ImportModule, loader, "QuestieJourneyUtils")
    local _,  qlocale = pcall(loader.ImportModule, loader, "l10n")
    if not ok or not qdb or not qju or not qlocale then return nil end
    if not qdb.NPCPointers then return nil end
    return qdb, qju, qlocale
end

--[[
  Build the zone cache by walking every NPC's spawn data. Idempotent;
  subsequent calls short-circuit if already built. Returns true on
  success, false if Questie is unavailable.
]]
local function ensureZoneCache()
    if zoneList then return true end

    local qdb, qju, l10n = resolveQuestie()
    if not qdb then return false end

    local zoneSet = {}
    for id, _ in pairs(qdb.NPCPointers) do
        local spawns = qdb.QueryNPCSingle(id, "spawns")
        if spawns then
            for zoneId in pairs(spawns) do
                local ok, raw = pcall(qju.GetZoneName, qju, zoneId)
                if ok and raw then
                    local ok2, localized = pcall(l10n, raw)
                    local zoneName = (ok2 and localized) or raw
                    if zoneName and zoneName ~= "" then
                        zoneSet[zoneName] = true
                    end
                end
            end
        end
    end

    zoneList = {}
    for zoneName in pairs(zoneSet) do
        zoneList[#zoneList + 1] = zoneName
    end
    table.sort(zoneList)

    return true
end

-- ============================================================================
-- SEARCH
-- ============================================================================

local function buildResults(text)
    if not ensureZoneCache() then return {} end

    local lower = text:lower()
    local results = {}
    for _, zoneName in ipairs(zoneList) do
        if zoneName:lower():find(lower, 1, true) then
            results[#results + 1] = { kind = "row", data = { zone = zoneName } }
            if #results >= MAX_RESULTS then break end
        end
    end
    return results
end

-- ============================================================================
-- PUBLIC API — wraps the shared picker
-- ============================================================================

local picker
local onUserPick

function zoneTypeahead:onQuery(text)
    if not picker then return end
    picker:onQuery(text)
end

function zoneTypeahead:hide()
    if not picker then return end
    picker:hide()
end

function zoneTypeahead:isShown()
    return picker ~= nil and picker:isShown()
end

function zoneTypeahead:moveHighlight(dir)
    if not picker then return end
    picker:moveHighlight(dir)
end

function zoneTypeahead:commitHighlight()
    if not picker then return false end
    return picker:commitHighlight()
end

--[[
  Wire to an editbox. onPick is called as onPick(zoneName) when the
  user picks a zone.

  @param editBox Frame
  @param parent Frame
  @param width number
  @param onPick function(zoneName)
  @param opts table|nil { growDownward = bool }
]]
function zoneTypeahead:attach(editBox, parent, width, onPick, opts)
    onUserPick = onPick

    picker = Addon.typeaheadPicker:create({
        runQuery = buildResults,

        rows = {
            row = {
                pickable = true,
                height   = ROW_HEIGHT,
                texts = {
                    { key = "nameFS", font = "GameFontHighlight",
                      points = {
                        { "TOPLEFT",   ROW_INSET, -ROW_TEXT_TOP },
                        { "TOPRIGHT", -ROW_INSET, -ROW_TEXT_TOP },
                      } },
                },
                overflowTooltip = true,
                render = function(row, item)
                    row:SetOverflowText(row.nameFS, item.data.zone)
                end,
            },
        },

        debounce        = DEBOUNCE,
        minQueryLen     = MIN_QUERY_LEN,
        maxResults      = MAX_RESULTS,
        visibleMaxRows  = VISIBLE_ROWS,
        scrollFrameName = SCROLL_FRAME_NAME,

        onPick = function(item)
            if onUserPick and item.kind == "row" then
                onUserPick(item.data.zone)
            end
        end,
    })

    picker:attach(editBox, parent, width, opts)
end

function zoneTypeahead:initialize()
    return true
end

Addon.zoneTypeahead = zoneTypeahead
return zoneTypeahead
