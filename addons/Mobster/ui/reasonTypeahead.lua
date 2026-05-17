--[[
  ui/reasonTypeahead.lua
  Reason-field typeahead, backed by the item-drop index

  Search backend for the Reason field in the edit panel. Suggests
  items dropped by the NPC the user named in the Name field, so a
  user can quickly fill Reason with something like "Ironshield Potion
  Recipe" instead of typing it out.

  Companion to nameTypeahead and zoneTypeahead, but with a wrinkle:
  reason results depend on which NPC is currently named, which means
  this module needs an external "context" (the NPC name from the
  Name field). The caller sets that via :setNpcContext(name).

  The Questie data lookups live in core/itemDropIndex.lua. This
  module owns the picker UI and the context state; the index owns
  the caches and the heroic-aware aggregation.

  Public API:
    reasonTypeahead:attach(editBox, parent, width, onPick, opts)
    reasonTypeahead:onQuery(text)
    reasonTypeahead:hide()
    reasonTypeahead:isShown()
    reasonTypeahead:moveHighlight(dir)
    reasonTypeahead:commitHighlight()
    reasonTypeahead:setNpcContext(npcName)  -- nil clears

  Where onPick(itemName, itemId) — the itemId lets callers stamp the
  picked entry with provenance so the rich item tooltip becomes
  available on hover.

  Dependencies: typeaheadPicker, panel, pool, itemDropIndex
  Exports: Addon.reasonTypeahead
]]

local ADDON_NAME, Addon = ...

local reasonTypeahead = {}

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

local SCROLL_FRAME_NAME = ADDON_NAME .. "ReasonTypeaheadScroll"

-- ============================================================================
-- NPC CONTEXT — set by caller via :setNpcContext
-- ============================================================================
--
-- contextItemIds is the deduped list of itemIds the user can pick
-- from given the current NPC name. Rebuilt whenever the context
-- changes. nil means "no context set" — queries return nothing.

local contextItemIds

-- ============================================================================
-- SEARCH
-- ============================================================================

local function buildResults(text)
    if not contextItemIds or #contextItemIds == 0 then return {} end

    local lower = text:lower()
    local results = {}
    for _, itemId in ipairs(contextItemIds) do
        local name = Addon.itemDropIndex:itemName(itemId)
        if name and name:lower():find(lower, 1, true) then
            results[#results + 1] = {
                kind = "row",
                data = {
                    itemId   = itemId,
                    itemName = name,
                    quality  = Addon.itemDropIndex:itemQuality(itemId),
                },
            }
            if #results >= MAX_RESULTS then break end
        end
    end

    -- Sort alphabetically for stable display.
    table.sort(results, function(a, b)
        return a.data.itemName < b.data.itemName
    end)
    return results
end

-- ============================================================================
-- PUBLIC API — wraps the shared picker
-- ============================================================================

local picker
local onUserPick

function reasonTypeahead:onQuery(text)
    if not picker then return end
    picker:onQuery(text)
end

function reasonTypeahead:hide()
    if not picker then return end
    picker:hide()
end

function reasonTypeahead:isShown()
    return picker ~= nil and picker:isShown()
end

function reasonTypeahead:moveHighlight(dir)
    if not picker then return end
    picker:moveHighlight(dir)
end

function reasonTypeahead:commitHighlight()
    if not picker then return false end
    return picker:commitHighlight()
end

--[[
  Set the NPC context for subsequent queries. Pass the name string
  the user has in the Name field (with or without (N)/(H) marker —
  the index strips the marker). Pass nil to clear, after which
  queries return no results.

  This is JIT — typically called when the user focuses the Reason
  field, so we resolve only when actually needed. The index handles
  the Questie walk on first call; subsequent calls hit cache.
]]
function reasonTypeahead:setNpcContext(npcName)
    contextItemIds = Addon.itemDropIndex:itemsForNpc(npcName)
    -- Warm the quality cache for these items. GetItemInfo on a not-
    -- yet-cached item triggers a server fetch; doing this on context-
    -- set means the round-trip can complete before the user reaches
    -- the chevron, so the dropdown opens with full quality coloring
    -- the common case. Late arrivals come in via the
    -- "MOBSTER:QUALITY_RESOLVED" event subscribed in attach().
    if contextItemIds and #contextItemIds > 0 then
        Addon.itemDropIndex:prefetchQualitiesFor(contextItemIds)
    end
end

--[[
  @param editBox Frame
  @param parent Frame
  @param width number
  @param onPick function(itemName)
  @param opts table|nil { growDownward = bool, strata = string }
]]
function reasonTypeahead:attach(editBox, parent, width, onPick, opts)
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
                    row:SetOverflowText(row.nameFS, item.data.itemName)
                    -- Quality coloring: standard Blizzard quality token if
                    -- quality is known. Nil → leave font at its default
                    -- (GameFontHighlight white), which renders pre-resolution
                    -- items as neutral until GET_ITEM_INFO_RECEIVED backfills.
                    local q = item.data.quality
                    local token = q and Addon.theme.derive.qualityFor(q)
                    if token then
                        row.nameFS:SetTextColor(token.r, token.g, token.b)
                    else
                        -- Reset to the font object's default (white) in case
                        -- this row was recycled from a colored entry.
                        row.nameFS:SetTextColor(1, 1, 1)
                    end
                end,
            },
        },

        debounce        = DEBOUNCE,
        minQueryLen     = MIN_QUERY_LEN,
        maxResults      = MAX_RESULTS,
        visibleMaxRows  = VISIBLE_ROWS,
        scrollFrameName = SCROLL_FRAME_NAME,
        showChevron     = true,

        onPick = function(item)
            if onUserPick and item.kind == "row" then
                onUserPick(item.data.itemName, item.data.itemId)
            end
        end,
    })

    picker:attach(editBox, parent, width, opts)

    -- Late-arriving quality data: when GetItemInfo backfills an
    -- itemId we care about (or any other; the publisher already
    -- filters to indexed items), refresh the dropdown if it's
    -- currently open. The refresh re-runs buildResults, which picks
    -- up the new quality and re-renders rows with the correct
    -- color. Cheap because the result set is bounded by the current
    -- NPC's drops (typically <20 items).
    Addon.events:subscribe("MOBSTER:QUALITY_RESOLVED", function()
        if picker and picker:isShown() then
            picker:onQuery(editBox:GetText() or "")
        end
    end)
end

function reasonTypeahead:initialize()
    return true
end

Addon.reasonTypeahead = reasonTypeahead
return reasonTypeahead
