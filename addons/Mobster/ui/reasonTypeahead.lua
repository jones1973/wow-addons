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

  Where onPick(itemName) — single arg.

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
            results[#results + 1] = { kind = "row", data = { itemName = name } }
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
-- ROW FACTORY & RENDERER
-- ============================================================================

local function rowFactory(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameFS:SetPoint("TOPLEFT", ROW_INSET, -ROW_TEXT_TOP)
    nameFS:SetPoint("TOPRIGHT", -ROW_INSET, -ROW_TEXT_TOP)
    nameFS:SetJustifyH("LEFT")
    nameFS:SetWordWrap(false)
    row.nameFS = nameFS

    Mixin(row, Addon.overflowTooltipMixin)
    row:InitOverflowTooltip()

    return row
end

local function rowRender(row, item)
    row:SetOverflowText(row.nameFS, item.data.itemName)
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

        factories = { row = rowFactory },
        renderers = { row = rowRender },
        heights   = { row = ROW_HEIGHT },

        debounce        = DEBOUNCE,
        minQueryLen     = MIN_QUERY_LEN,
        maxResults      = MAX_RESULTS,
        visibleMaxRows  = VISIBLE_ROWS,
        scrollFrameName = SCROLL_FRAME_NAME,

        onPick = function(item)
            if onUserPick and item.kind == "row" then
                onUserPick(item.data.itemName)
            end
        end,
    })

    picker:attach(editBox, parent, width, opts)
end

function reasonTypeahead:initialize()
    return true
end

Addon.reasonTypeahead = reasonTypeahead
return reasonTypeahead
