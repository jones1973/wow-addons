--[[
  ui/nameTypeahead.lua
  NPC-name typeahead, backed by Questie's database

  Search backend for the Name field in the edit panel. Wraps a
  typeaheadPicker instance with NPC-specific query and rendering:

    - Search Questie's NPC pointers by substring
    - Group by base name; emit (N) and (H) variants when both
      a normal and heroic record exist
    - Filter [DND] and [PH] internals
    - Drop suffixed orphans (no UnitName match possible)
    - Partition results into "in your zone" and "elsewhere" with
      section headers
    - Gold accent stripe on rows whose zone matches GetZoneText()

  This file owns NPC-specific concerns. The dropdown chrome (scroll,
  pool, debounce, anchoring, hover) lives in the shared
  typeaheadPicker. Compare ui/zoneTypeahead.lua, which uses the same
  chrome with a far simpler backend.

  Public API mirrors what editPanel expects:
    nameTypeahead:attach(editBox, parent, width, onPick, opts)
    nameTypeahead:onQuery(text)
    nameTypeahead:hide()

  Where onPick(name, zone) — note the two args, since picking an NPC
  also conveys the zone Questie has for that NPC.

  Dependencies: typeaheadPicker, panel, pool
  Exports: Addon.nameTypeahead
]]

local ADDON_NAME, Addon = ...

local nameTypeahead = {}

-- ============================================================================
-- FILE-LOCAL CONSTANTS
-- ============================================================================

local MAX_RESULTS    = 100
local DEBOUNCE       = 0.2
local MIN_QUERY_LEN  = 2
local VISIBLE_ROWS   = 7
local ROW_HEIGHT     = 36
local HEADER_HEIGHT  = 24

local SCROLL_FRAME_NAME = ADDON_NAME .. "NameTypeaheadScroll"

-- Row layout
local ROW_NAME_TOP    = 6
local ROW_ZONE_TOP    = 20
local ROW_INSET       = 10
local ROW_ZONE_INDENT = 4

-- Header layout
local HEADER_INSET    = 10

-- Color palette (current-zone accent + gold band on headers)
local GOLD_R, GOLD_G, GOLD_B = 1.00, 0.82, 0.00
local ACCENT_W                = 3
local HEADER_BG_ALPHA         = 0.10

local function resolveQuestie()
    local loader = _G.QuestieLoader
    if not loader or not loader.ImportModule then
        return nil
    end
    local ok, qdb = pcall(loader.ImportModule, loader, "QuestieDB")
    local _,  qs  = pcall(loader.ImportModule, loader, "QuestieSearch")

    if not ok or not qdb or not qs then return nil end
    if not qdb.NPCPointers then return nil end
    return qdb, qs
end

-- ============================================================================
-- SEARCH (returns flat item list + grouping)
-- ============================================================================

--[[
  Walk Questie matches, bucket by base name, emit (N)/(H) rows.
  See typeahead.lua's previous header for the full rationale on why
  this works the way it does — short version: the (1) suffix in
  Questie data is a heroic-variant marker, but the WoW client never
  returns it from UnitName, so we strip it for matching purposes
  while still surfacing the variant to the user.
]]
local function buildResults(text)
    local qdb, qs = resolveQuestie()
    if not qdb then return {} end

    local ok, ids = pcall(qs.Search, qs, text, "npc", "chars")
    if not ok or not ids then return {} end

    -- Group by base name. Each group records whether a normal and/or
    -- heroic NPC was seen, plus zones from the unsuffixed sibling.
    local groups = {}

    local function getGroup(baseName)
        local g = groups[baseName]
        if not g then
            g = {
                hasNormal       = false,
                hasHeroic       = false,
                sawSuffixed     = false,
                normalHealth    = nil,
                suffixedHealth  = nil,
                zones           = {},
            }
            groups[baseName] = g
        end
        return g
    end

    -- First pass: collect variant flags + per-variant health (used
    -- later to validate the heroic claim) + zones from the normal
    -- variant's spawns. Heroic validity is resolved after, so we
    -- don't depend on the order Questie's IDs arrive.
    for id in pairs(ids) do
        local name = qdb.QueryNPCSingle(id, "name")
        if name and not Addon.npcNameFilter:isJunk(name) then
            local baseName, wasSuffixed = Addon.questieHelpers:stripNumericSuffix(name)
            local group = getGroup(baseName)
            local health = qdb.QueryNPCSingle(id, "maxLevelHealth")

            if wasSuffixed then
                group.sawSuffixed    = true
                group.suffixedHealth = health
            else
                group.hasNormal    = true
                group.normalHealth = health
                local spawns = qdb.QueryNPCSingle(id, "spawns")
                if spawns then
                    for zoneId in pairs(spawns) do
                        local zone = Addon.questieHelpers:zoneDisplayName(zoneId)
                        if zone then group.zones[zone] = true end
                    end
                end
            end
        end
    end

    -- Second pass: only promote to hasHeroic if the suffixed
    -- variant's health is proportional to the normal-variant's.
    -- Data-artifact "(1)" entries (BG NPCs, dev placeholders) have
    -- placeholder health that fails this check.
    for _, group in pairs(groups) do
        if group.sawSuffixed
           and Addon.questieHelpers:isHeroicVariant(
                  group.normalHealth, group.suffixedHealth)
        then
            group.hasHeroic = true
        end
    end

    -- Emit rows. Each row is {kind="row", data={name=..., zone=...}}.
    -- Orphans (heroic-only with no normal sibling) are dropped — they
    -- can't match UnitName anyway.
    local rows = {}
    local function pushRow(displayName, zone)
        if #rows >= MAX_RESULTS then return false end
        rows[#rows + 1] = {
            kind = "row",
            data = { name = displayName, zone = zone },
        }
        return true
    end

    local function emitForZone(baseName, zone, group)
        if group.hasHeroic then
            if not pushRow(baseName .. " (N)", zone) then return false end
            if not pushRow(baseName .. " (H)", zone) then return false end
        else
            if not pushRow(baseName, zone) then return false end
        end
        return true
    end

    for baseName, group in pairs(groups) do
        if group.hasNormal then
            local hasAnyZone = next(group.zones) ~= nil
            if hasAnyZone then
                for zone in pairs(group.zones) do
                    if not emitForZone(baseName, zone, group) then break end
                end
            else
                emitForZone(baseName, nil, group)
            end
        end
        if #rows >= MAX_RESULTS then break end
    end

    -- Sort by base name → tier (bare<N<H) → zone.
    local function sortKey(name)
        local base, marker = name:match("^(.-)%s*%(([NH])%)$")
        if base then
            return base, (marker == "N") and 1 or 2
        end
        return name, 0
    end

    table.sort(rows, function(a, b)
        local aBase, aTier = sortKey(a.data.name)
        local bBase, bTier = sortKey(b.data.name)
        if aBase ~= bBase then return aBase < bBase end
        if aTier ~= bTier then return aTier < bTier end
        if a.data.zone == b.data.zone then return false end
        if a.data.zone == nil then return true  end
        if b.data.zone == nil then return false end
        return a.data.zone < b.data.zone
    end)

    return rows
end

--[[
  Partition rows into the current zone and elsewhere, and intersperse
  section headers. Returns the final flat item list to feed the
  picker chrome.
]]
local function withHeaders(rows)
    local currentZone = GetZoneText() or ""
    local here, elsewhere = {}, {}
    for _, item in ipairs(rows) do
        if currentZone ~= "" and item.data.zone == currentZone then
            here[#here + 1] = item
            item.data.here = true
        else
            elsewhere[#elsewhere + 1] = item
            item.data.here = false
        end
    end

    -- No headers if only one group has content — single-group lists
    -- with a lone header just look noisy.
    if #here == 0 or #elsewhere == 0 then
        return rows
    end

    local out = {}
    out[#out + 1] = { kind = "header", text = "In " .. currentZone }
    for _, item in ipairs(here) do out[#out + 1] = item end
    out[#out + 1] = { kind = "header", text = "Other Zones" }
    for _, item in ipairs(elsewhere) do out[#out + 1] = item end
    return out
end

-- ============================================================================
-- ROW + HEADER FACTORIES & RENDERERS (consumed by typeaheadPicker)
-- ============================================================================

-- Forward decl — picker is created after factories below.
local picker

local function rowFactory(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    -- Current-zone accent stripe (gold), shown only when the row's
    -- entry has data.here=true. Sits in front of the chrome's hover
    -- texture (which is BACKGROUND).
    local accent = row:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", 0, 0)
    accent:SetWidth(ACCENT_W)
    accent:SetColorTexture(GOLD_R, GOLD_G, GOLD_B, 0.9)
    accent:Hide()
    row.accent = accent

    local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameFS:SetPoint("TOPLEFT", ROW_INSET, -ROW_NAME_TOP)
    nameFS:SetPoint("TOPRIGHT", -ROW_INSET, -ROW_NAME_TOP)
    nameFS:SetJustifyH("LEFT")
    nameFS:SetWordWrap(false)
    row.nameFS = nameFS

    local zoneFS = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    zoneFS:SetPoint("TOPLEFT", ROW_INSET + ROW_ZONE_INDENT, -ROW_ZONE_TOP)
    zoneFS:SetPoint("TOPRIGHT", -ROW_INSET, -ROW_ZONE_TOP)
    zoneFS:SetJustifyH("LEFT")
    zoneFS:SetWordWrap(false)
    row.zoneFS = zoneFS

    -- Long names get clipped by the row's right edge; the mixin
    -- shows the full text on hover when that happens. Configured
    -- per-render via :SetOverflowText.
    Mixin(row, Addon.overflowTooltipMixin)
    row:InitOverflowTooltip()

    return row
end

local function rowRender(row, item)
    local data = item.data
    if data.zone then
        row.zoneFS:SetText("(" .. data.zone .. ")")
        row.zoneFS:Show()
    else
        row.zoneFS:Hide()
    end
    row.accent:SetShown(data.here == true)

    row:SetOverflowText(row.nameFS, data.name)
end

local function headerFactory(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetHeight(HEADER_HEIGHT)

    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(GOLD_R, GOLD_G, GOLD_B, HEADER_BG_ALPHA)

    local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", HEADER_INSET, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    header.text = text

    return header
end

local function headerRender(header, item)
    header.text:SetText(item.text)
end

-- ============================================================================
-- PUBLIC API — wraps the shared picker
-- ============================================================================

local onUserPick   -- caller-supplied callback set in :attach

function nameTypeahead:onQuery(text)
    if not picker then return end
    picker:onQuery(text)
end

function nameTypeahead:hide()
    if not picker then return end
    picker:hide()
end

function nameTypeahead:isShown()
    return picker ~= nil and picker:isShown()
end

function nameTypeahead:moveHighlight(dir)
    if not picker then return end
    picker:moveHighlight(dir)
end

function nameTypeahead:commitHighlight()
    if not picker then return false end
    return picker:commitHighlight()
end

--[[
  Wire to an editbox. onPick is called as onPick(name, zone) when the
  user picks a result; zone may be nil for zoneless picks (NPCs whose
  Questie data has no resolvable zone).

  @param editBox Frame
  @param parent Frame
  @param width number
  @param onPick function(name, zone)
  @param opts table|nil { growDownward = bool }
]]
function nameTypeahead:attach(editBox, parent, width, onPick, opts)
    onUserPick = onPick

    picker = Addon.typeaheadPicker:create({
        runQuery = function(text)
            return withHeaders(buildResults(text))
        end,

        factories = {
            row    = rowFactory,
            header = headerFactory,
        },
        renderers = {
            row    = rowRender,
            header = headerRender,
        },
        heights = {
            row    = ROW_HEIGHT,
            header = HEADER_HEIGHT,
        },

        debounce        = DEBOUNCE,
        minQueryLen     = MIN_QUERY_LEN,
        maxResults      = MAX_RESULTS,
        visibleMaxRows  = VISIBLE_ROWS,
        scrollFrameName = SCROLL_FRAME_NAME,

        onPick = function(item)
            -- Adapt the picker's single-item callback to our caller's
            -- (name, zone) signature.
            if onUserPick and item.kind == "row" then
                onUserPick(item.data.name, item.data.zone)
            end
        end,
    })

    picker:attach(editBox, parent, width, opts)
end

function nameTypeahead:initialize()
    return true
end

Addon.nameTypeahead = nameTypeahead
return nameTypeahead
