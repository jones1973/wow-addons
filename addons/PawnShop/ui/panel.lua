--[[
  ui/panel.lua
  Pawn Shop Panel - The Grid

  The main UI hosted inside the AuctionFrame. Renders a scrollable list of
  upgrade rows filtered by the currently selected equip-slot tab, with
  per-scale percent columns.

  Owns: the panel Frame, the row frame pool, column header state, slot
  tab strip state. Everything else is consumed via event subscriptions and
  getter calls on eval/scan.

  Layout:
    Top:    Scan button + status label
    Left:   Vertical slot tab strip (auto-sized to widest slot label)
    Right:  Column headers (Item / scales / Lvl / Buyout / Time) above
            the scrollable list of item rows for the selected slot

  Heatmap: scale percents and the slot-tab pills are tri-colored by
  warmThresholdPct / hotThresholdPct settings.
    pct <  warm  -> muted green (cold)
    warm <= pct < hot -> gold (warm)
    pct >= hot   -> legendary orange (hot)

  Event subscriptions:
    SCAN:STARTED              -> disable scan button, status "Waiting..."
    SCAN:AUCTIONS_INGESTED    -> status "Scan done: N. Starting eval..."
    SCAN:EMPTY                -> status "Scan returned 0 items", re-enable button
    SCAN:CANCELLED            -> re-enable scan button
    EVAL:STARTED              -> status "Eval: N items"
    EVAL:PROGRESS             -> (future progress indicator)
    EVAL:ROWS_CHANGED         -> rebuild slot tabs + redraw
    EVAL:COMPLETE             -> status "Done. N items", re-enable button
    EVAL:CANCELLED            -> re-enable scan button
    SETTING:DISPLAY_CHANGED   -> re-sort + rebuild slot tabs + redraw

  Dependencies: utils, events, options, constants, filterTabStrip
  Exports: Addon.panel
]]

local ADDON_NAME, Addon = ...

local panel = {}

-- Module references
local utils, events, options, constants, filterTabStrip, dropdown
local eval, scan, sort, auctionatorIntegration

-- Frames and child widget references (populated in createPanel).
local panelFrame, scanButton, statusLabel
local slotTabStrip
local headerFrame, headerItem, headerLvl, headerBuyout, headerTime
local scaleHeaders = {}
-- Widget instances keyed by columnKey (e.g., "lvl", "scale_1"). Used
-- to invoke widget methods like setActiveSort and redrawIndicator.
-- Their underlying frames are stored in headerItem/headerLvl/etc and
-- in scaleHeaders[i] for layout code that operates on Frame objects.
local headerWidgets = {}
local listFrame, scrollFrame, rowFrames = nil, nil, {}
local scrollbarGutter = 22
local lastScaleCount = nil

-- Scale-picker state. displayedScales[n] is the internal Pawn scale name
-- currently assigned to column n (n = 1 or 2). nil means "column n shows
-- nothing", which only happens when eval has fewer than n scales tracked.
-- Owned by panel.lua -- eval:scaleAtIndex delegates here so sort uses
-- the same mapping the user sees.
local displayedScales = { nil, nil }

-- Prior-session CVar value for alwaysCompareItems. Captured in panel:show
-- and restored in panel:hide / AUCTION_HOUSE_CLOSED so our "force both
-- tooltips on hover" change doesn't persist after the user closes the AH.
local savedAlwaysCompareCVar = nil

-- Per-column rendered widths. Scale columns stay fixed at COL_SCALE_WIDTH
-- (content is bounded: "+999%" or "NEW 9999"). Time/Buyout/Level flex
-- based on actual scan content, floored by their header-text widths so
-- the column never gets narrower than its own caption. recomputeColWidths
-- updates these after EVAL:COMPLETE; relayoutColumns and the redraw path
-- read from here instead of constants.COL_*_WIDTH directly.
local colWidths = {
    time   = nil,  -- populated at panel create from header minimums
    buyout = nil,
    level  = nil,
}

-- Level-cell coloring. White for equippable (reqLvl <= playerLvl, same
-- as default font color), magenta for gated (reqLvl > playerLvl). The
-- three-color grading we initially discussed (distinguishing below /
-- equal / above player level) was dropped because a lower required
-- level says nothing about item quality -- a reqLvl=58 item can be a
-- straight upgrade at 65.
local LEVEL_GATED_COLOR = { 1.0, 0.4, 0.9 }

-- Minimum column widths derived from the header caption's rendered text
-- width, plus a pad for the sort indicator (" ^"/" v") that appears on
-- the active sort column. Measured once at panel creation when the
-- header fontstrings exist; used as the floor for every column width
-- recompute.
local headerMinWidths = {
    time   = nil,
    buyout = nil,
    level  = nil,
}

-- Shared throwaway fontstring for measuring text widths. Created lazily.
local measureFS = nil

-- ============================================================================
-- HEATMAP
-- ============================================================================

--[[
  Return the tier color for a percent value based on user-configured
  thresholds. Three tiers: cold < warm <= hot.
  @param pct number - percent (e.g. 12 for "+12%")
  @return number, number, number - r, g, b in 0-1 range
]]
local function heatmapColor(pct)
    local warm = options:Get("warmThresholdPct") or 15
    local hot  = options:Get("hotThresholdPct")  or 50
    if pct >= hot then
        return 1.00, 0.50, 0.00   -- legendary orange (hot)
    elseif pct >= warm then
        return 1.00, 0.84, 0.00   -- gold (warm)
    else
        return 0.40, 0.80, 0.40   -- muted green (cold)
    end
end

-- ============================================================================
-- FORMATTERS
-- ============================================================================

local TIME_LEFT_TEXT = { [1] = "<30m", [2] = "<2h", [3] = "<12h", [4] = "<48h" }
local function formatTimeLeft(t) return TIME_LEFT_TEXT[t] or "?" end

-- Format an "anchored" remaining-seconds estimate from listingTracker.
-- Renders compact ("12m", "1h45m", "8h", "2d") for the time column.
local function formatAnchoredRemaining(seconds)
    if not seconds or seconds < 0 then return "?" end
    if seconds < 60 then         return string.format("%ds", seconds) end
    if seconds < 60 * 60 then    return string.format("%dm", math.floor(seconds / 60)) end
    if seconds < 24 * 60 * 60 then
        local h = math.floor(seconds / 3600)
        local m = math.floor((seconds % 3600) / 60)
        if m > 0 then return string.format("%dh%dm", h, m) end
        return string.format("%dh", h)
    end
    return string.format("%dd", math.floor(seconds / 86400))
end

-- Set the time cell text + color for a row's data entry. Uses the
-- listingTracker for anchored estimates when available; falls back to
-- the raw bucket label otherwise.
--   White:  raw bucket (no anchor)
--   Yellow: anchored estimate (computed from a transition timestamp)
local function setTimeCell(fs, data)
    if not fs then return end
    local tracker = Addon.listingTracker
    if tracker and tracker.getRemaining and data.listingKey then
        local seconds, anchored = tracker:getRemaining(data)
        if seconds and anchored then
            fs:SetText(formatAnchoredRemaining(seconds))
            fs:SetTextColor(1.0, 0.82, 0.0, 1)   -- gold/yellow
            return
        end
    end
    fs:SetText(formatTimeLeft(data.timeLeft))
    fs:SetTextColor(1, 1, 1, 1)                  -- white
end

--[[
  Set the level cell's text and color. White for reqLvl <= player
  level (equippable, default rendering), magenta for reqLvl > player
  level (gated -- cannot equip yet). Passing nil/<=0 blanks the cell
  and resets color so pooled rows don't leak a stale magenta state
  into a subsequent single/pair-row reuse.

  @param fontString FontString - row.levelText
  @param reqLvl number|nil - required level, or nil/0 for "no level"
]]
local function setLevelCell(fontString, reqLvl)
    if not reqLvl or reqLvl <= 0 then
        fontString:SetText("")
        fontString:SetTextColor(1, 1, 1)
        return
    end
    fontString:SetText(tostring(reqLvl))
    if reqLvl > (UnitLevel("player") or 0) then
        fontString:SetTextColor(unpack(LEVEL_GATED_COLOR))
    else
        fontString:SetTextColor(1, 1, 1)
    end
end

--[[
  Copper -> colored money string. "--" when zero.
  @param copper number|nil
  @return string
]]
local function formatMoney(copper)
    if not copper or copper == 0 then return "|cff888888--|r" end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    if g > 0 then
        return string.format("%d|cffffd700g|r %d|cffc7c7cfs|r", g, s)
    elseif s > 0 then
        return string.format("%d|cffc7c7cfs|r %d|cffeda55fc|r", s, c)
    else
        return string.format("%d|cffeda55fc|r", c)
    end
end

--[[
  Scale cell: "+12%" tier-colored via heatmap, or "NEW N" when the
  underlying upgrade was against an empty equipped slot. In the
  empty-slot case, the `percent` field actually carries the raw Pawn
  score (candidate's absolute score on that scale) rather than a real
  percent, because there's no baseline to percent-against. Showing the
  score alongside NEW lets the user compare multiple empty-slot
  candidates within the same tab -- sorting already orders them
  highest-first, but the label makes the ranking visible.
  @param upgrade table|nil - upgrade entry {percent, isEmptySlotUpgrade, ...}
  @return string
]]
local function formatScaleCell(upgrade)
    if not upgrade then return "" end
    if upgrade.isEmptySlotUpgrade then
        local raw = upgrade.percent or 0
        return string.format("|cff40ff40NEW %d|r", math.floor(raw + 0.5))
    end
    local pct = upgrade.percent
    if not pct or pct <= 0 then return "" end
    local r, g, b = heatmapColor(pct)
    return string.format("|cff%02x%02x%02x%.0f%%|r",
        r * 255, g * 255, b * 255, pct)
end

-- ============================================================================
-- STATUS AND BUTTON STATE
-- ============================================================================

local function setStatus(msg)
    if statusLabel then statusLabel:SetText(msg) end
end

local function enableScanButton()
    if scanButton then scanButton:Enable() end
end

local function disableScanButton()
    if scanButton then scanButton:Disable() end
end

-- ============================================================================
-- NAME-BUTTON CLICK BEHAVIOR
-- ============================================================================

--[[
  Collect item names from a name-button click target.
  For pair rows, returns both MH and OH names; for singles, one name.
  @param btn table - nameBtn frame with pairData/itemName attached
  @return table - array of name strings (possibly empty)
]]
local function collectNames(btn)
    local names = {}
    if btn.pairData then
        if btn.pairData.mhEntry and btn.pairData.mhEntry.name then
            table.insert(names, btn.pairData.mhEntry.name)
        end
        if btn.pairData.ohEntry and btn.pairData.ohEntry.name then
            table.insert(names, btn.pairData.ohEntry.name)
        end
    elseif btn.itemName then
        table.insert(names, btn.itemName)
    end
    return names
end

--[[
  Shared OnClick handler for name buttons.
  Ctrl-click: send to Auctionator. Shift-click: insert link into chat edit.
  Plain click: nothing -- bare clicks happen accidentally all the time
  and printing the link to chat every time is just noise.
]]
local function nameBtnOnClick(self)
    if IsControlKeyDown() then
        auctionatorIntegration:sendNames(collectNames(self))
    elseif self.link and ChatEdit_InsertLink and IsShiftKeyDown() then
        ChatEdit_InsertLink(self.link)
    end
end

local function nameBtnOnEnter(self)
    if self.link then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    end
end

local function nameBtnOnLeave()
    GameTooltip:Hide()
end

-- ============================================================================
-- SORT INDICATORS (driven by header widget events; see panel:initialize)
-- ============================================================================

function panel:updateSortIndicators()
    local curCol = options:Get("sortColumn")
    local curDir = options:Get("sortDir") or "asc"
    for key, w in pairs(headerWidgets) do
        if w.setActiveSort then
            if key == curCol then
                w:setActiveSort(curDir)
            else
                w:setActiveSort(nil)
            end
        end
    end
end

-- ============================================================================
-- SLOT TAB STRIP
-- ============================================================================

--[[
  Slot name is "Pair" in the data layer; the UI presents it as "Two-Piece"
  on the tab. Long weapon slot names get abbreviated for tab labels
  (full names appear in tab tooltips, see buildSlotTabList).
  Data stays as-is (see data/slotOrder.lua comment).
  @param slotName string
  @return string
]]
local SLOT_ABBREV = {
    ["Two-Hand"]  = "2H",
    ["Main Hand"] = "MH",
    ["Off Hand"]  = "OH",
}

local function slotDisplayName(slotName)
    if slotName == Addon.data.pairSlotName then
        return "Two-Piece"
    end
    return SLOT_ABBREV[slotName] or slotName
end

--[[
  Build the colored-name line for a tab tooltip entry. Returns a line
  table of {text, r, g, b} for the filterTabStrip tooltip-array format.
  Rarity color falls back to white if the item isn't cached yet.
  Empty link (unequipped slot) returns an italic-gray "(empty)".
  @param link string|nil
  @return table - {text, r, g, b}
]]
local function tooltipLineForEquipped(link)
    if not link or link == "" then
        return { "(empty)", 0.6, 0.6, 0.6 }
    end
    local name, _, quality = GetItemInfo(link)
    if not name then
        -- GetItemInfo miss; use the raw link text (has color codes but
        -- won't render inside GameTooltip:AddLine reliably). Strip codes
        -- by taking whatever GetItemInfo produces next scan; for now,
        -- fall back to a neutral label.
        return { link, 1, 1, 1 }
    end
    local r, g, b = 1, 1, 1
    if quality then r, g, b = GetItemQualityColor(quality) end
    return { name, r, g, b }
end

--[[
  Return true if a scale name is currently shown in one of the two grid
  columns. Used to filter rows and upgrade pill computations.
]]
local function isDisplayedScale(scaleName)
    return scaleName and (scaleName == displayedScales[1]
                       or scaleName == displayedScales[2])
end

--[[
  Read filter settings (filter scale, level tolerance, min upgrade %)
  from the persistence layer in one shot. Returns a table that
  rowPassesFilters can consult repeatedly without re-reading per row.

  Defaults match data/settingDefaults.lua: levelTolerance = 2,
  minUpgradePct = 0. Filter scale is whatever displayedScales[1]
  currently holds (which is sourced from the `scale` setting in
  initializeDisplayedScales).
]]
local function readFilterSettings()
    return {
        filterScale     = displayedScales[1],
        playerLevel     = UnitLevel("player") or 0,
        levelTolerance  = (Addon.options and Addon.options:Get("levelTolerance")) or 2,
        minUpgradePct   = (Addon.options and Addon.options:Get("minUpgradePct"))  or 0,
    }
end

--[[
  The single source of truth for "is this row visible right now."
  buildDisplayRows uses it to decide which rows render in the grid;
  buildSlotTabList uses it to decide which rows count toward each
  slot tab's pill (count and best %). Keeping both paths consistent
  is essential -- otherwise tabs show counts that don't match the
  visible row set, which is exactly the bug we're fixing.

  Three gates:
    1. Filter scale: row must have an upgrade on the filter scale.
    2. Level cap: row.minLevel <= playerLevel + levelTolerance.
    3. Min upgrade %: filter-scale percent rounds to >= threshold.
       NEW (empty-slot) rows bypass this gate -- their percent is
       a raw scale value, not a percentage, so the threshold doesn't
       semantically apply.

  Returns:
    passes  bool      -- whether the row should be visible
    matchPct number?  -- the row's percent on the filter scale (or nil)
    isEmpty bool      -- whether the matching upgrade is an empty-slot one
]]
local function rowPassesFilters(a, s)
    if not s.filterScale then return false end

    -- Level gate
    local minLvl = a.minLevel or 0
    if minLvl > s.playerLevel + s.levelTolerance then return false end

    -- Filter scale membership + min %
    if not a.upgrades then return false end
    for _, u in ipairs(a.upgrades) do
        if u.scale == s.filterScale then
            if u.isEmptySlotUpgrade then
                return true, u.percent, true
            end
            if math.floor((u.percent or 0) + 0.5) >= (s.minUpgradePct or 0) then
                return true, u.percent, false
            end
            return false
        end
    end
    return false
end

--[[
  Build the tab config list for the slot tab strip from the current eval
  rows. Tab order follows slotRank (natural gear order). A tab only
  appears when at least one of its rows has an upgrade on a displayed
  scale -- otherwise the tab would be empty in the grid.

  The pill shows the best regular (non-empty-slot) upgrade percent among
  displayed scales. If every displayed-scale upgrade in the slot is an
  empty-slot case (player has nothing equipped in that slot), the pill
  shows "NEW" in bright green instead.

  The tooltip is an array of rarity-colored lines with the equipped item
  name(s): one line for single-instance slots, two lines for pair rows
  (MH on top, OH on bottom).
  @return table - array of tab configs suitable for filterTabStrip:setTabs
]]
local function buildSlotTabList()
    local rows = eval:getRows() or {}
    local s    = readFilterSettings()

    -- Accumulate per-slot: count, rank, best regular %, empty-slot flag,
    -- equipped link(s). We only count rows that PASS the same filters
    -- buildDisplayRows applies, so tab counts always equal the visible
    -- row count for each slot.
    local bySlot = {}   -- [slotName] = { rank, count, bestPct, hasEmpty, equippedLink, mhEquippedLink, ohEquippedLink, isPair }
    local order  = {}   -- stable array of slot names in rank order

    for _, a in ipairs(rows) do
        local slotName = a.slotName or "Other"
        local passes, matchPct, isEmpty = rowPassesFilters(a, s)

        if passes then
            local bucket = bySlot[slotName]
            if not bucket then
                bucket = {
                    rank            = a.slotRank or 99,
                    count           = 0,
                    bestPct         = 0,
                    hasEmpty        = false,
                    equippedLink    = a.equippedLink,
                    mhEquippedLink  = a.mhEquippedLink,
                    ohEquippedLink  = a.ohEquippedLink,
                    isPair          = a.isPair or false,
                }
                bySlot[slotName] = bucket
                table.insert(order, slotName)
            end
            bucket.count = bucket.count + 1
            -- Pill best %: only NON-empty matches contribute.
            if not isEmpty and matchPct and matchPct > bucket.bestPct then
                bucket.bestPct = matchPct
            end
            if isEmpty then
                bucket.hasEmpty = true
            end
        end
    end

    table.sort(order, function(x, y) return bySlot[x].rank < bySlot[y].rank end)

    local tabs = {}
    for _, slotName in ipairs(order) do
        local bucket = bySlot[slotName]
        local entry = {
            id    = slotName,  -- keep raw name as id (stable across renames)
            label = slotDisplayName(slotName),
            count = bucket.count,
        }

        -- Pill: best regular % beats NEW; only show NEW if EVERY
        -- displayed-scale upgrade in this slot was empty-slot.
        if bucket.bestPct > 0 then
            local r, g, b = heatmapColor(bucket.bestPct)
            entry.extraText  = string.format("+%.0f%%", bucket.bestPct)
            entry.extraColor = { r, g, b }
        elseif bucket.hasEmpty then
            entry.extraText  = "NEW"
            entry.extraColor = { 0.25, 1.0, 0.25 }
        end

        -- Tooltip lines: optional full-slot-name header (when the visible
        -- label was abbreviated), then rarity-colored equipped-item names.
        -- Pair slots emit two equipped lines (MH first, OH second).
        local tipLines = {}
        if entry.label ~= slotName and slotName ~= Addon.data.pairSlotName then
            table.insert(tipLines, { slotName, 1, 0.82, 0 })   -- gold header
        end
        if bucket.isPair then
            table.insert(tipLines, tooltipLineForEquipped(bucket.mhEquippedLink))
            table.insert(tipLines, tooltipLineForEquipped(bucket.ohEquippedLink))
        elseif bucket.equippedLink then
            table.insert(tipLines, tooltipLineForEquipped(bucket.equippedLink))
        end
        if #tipLines > 0 then
            entry.tooltip = tipLines
        end

        table.insert(tabs, entry)
    end
    return tabs
end

--[[
  Refresh the tab strip from current eval state. If the previously
  selected slot still has items, selection is preserved. Otherwise the
  first slot tab is selected. Callers follow with panel:redraw(); this
  function does not redraw on its own except via the onSelect callback.
]]
local function refreshSlotTabs()
    if not slotTabStrip then return end
    slotTabStrip:setTabs(buildSlotTabList())
    if slotTabStrip:getSelected() == nil then
        slotTabStrip:selectFirst()  -- fires onSelect -> panel:redraw
    end
end

-- ============================================================================
-- DISPLAYED SCALES (scale-picker dropdowns above the grid)
-- ============================================================================

--[[
  Panel owns which tracked scales are mapped to which visible columns.
  eval:scaleAtIndex delegates here so the sort key "scale_1" refers to
  whatever the user picked in dropdown 1 at the current moment.
  @param n number - 1-based column index
  @return string|nil - internal Pawn scale name, or nil if column is empty
]]
function panel:getDisplayedScaleAt(n)
    return displayedScales[n]
end

--[[
  On fresh eval completion, snap displayedScales to valid scales.

  Rules:
    - Persisted picks win if they're still in the discovered scaleOrder
      (user's explicit choice, "stay put" across re-scans).
    - Gaps get filled from scaleOrder in order, skipping any scale
      already assigned to another column so the two columns never show
      the same scale.
    - With fewer than DISPLAYED_SCALE_COLUMNS scales discovered, later
      slots are left nil and the grid simply hides those columns.

  Called after EVAL:COMPLETE or an explicit restore (reload). Persisted
  values read via options:Get so the picks carry across logins and
  reloads.
]]
local function initializeDisplayedScales()
    -- displayedScales[1] = filter scale, displayedScales[2] = companion.
    -- Both come from settings via the options module's per-char-then-
    -- account lookup. The auto-pop in onEvalComplete ensures `scale`
    -- is non-nil after the first eval -- so the user always sees a
    -- column without having to interact with anything.
    if Addon.options then
        local s1 = Addon.options:Get("scale")
        local s2 = Addon.options:Get("companionScale")
        if s1 and s1 ~= "" then displayedScales[1] = s1 else displayedScales[1] = nil end
        if s2 and s2 ~= "" and s2 ~= s1 then
            displayedScales[2] = s2
        else
            displayedScales[2] = nil
        end
    else
        displayedScales[1] = nil
        displayedScales[2] = nil
    end

    -- Defensive: if the saved scale isn't present in the current
    -- scaleOrder (e.g., user disabled it in Pawn since last run),
    -- displayedScales[1] is kept as-is so column rendering knows
    -- what the user wanted -- formatScaleCell will simply find no
    -- entry and render an empty cell. Tab counts naturally drop to 0.
end

--[[
  Anchor slot strip + header.

  headerFrame sits at panelFrame.TOP - 44, leaving the top band of
  the panel for the scan/eval row (left) and the Scale/Secondary
  filter row (right). Below the header, the slot strip and table
  rows fill the rest of the panel.

  Called once at panel creation, and again when eval completes so
  layout is reasserted after data changes. Idempotent.
]]
local function applyTableLayout()
    if not slotTabStrip then return end

    if headerFrame then
        headerFrame:SetPoint("TOP", panelFrame, "TOP", 0, -23)
    end

    slotTabStrip:SetPoint("LEFT",   panelFrame,  "LEFT",   0, 0)
    slotTabStrip:SetPoint("BOTTOM", panelFrame,  "BOTTOM", 0, 0)
    slotTabStrip:SetPoint("TOP",    headerFrame, "BOTTOM", 0, 0)

    -- Strip backdrop covers the same vertical range as the strip itself.
    if panel._stripBgFrame then
        panel._stripBgFrame:SetPoint("TOP", headerFrame, "BOTTOM", 0, 0)
    end
end

-- ============================================================================
-- FLUID COLUMN SIZING
-- ============================================================================

--[[
  Get/create a shared hidden fontstring used to measure rendered text
  widths without affecting visible layout. Reused across measurement
  calls to avoid repeated fontstring allocation.
  @param font string - Blizzard font object name (e.g. "GameFontNormalSmall")
  @return FontString
]]
local function getMeasureFS(font)
    if not measureFS then
        measureFS = UIParent:CreateFontString(nil, "BACKGROUND")
        measureFS:Hide()
    end
    measureFS:SetFontObject(font or "GameFontNormalSmall")
    return measureFS
end

--[[
  Measure the pixel width of a text string under a given font.
  @param text string
  @param font string - font object name
  @return number - pixel width (GetStringWidth returns 0 for empty text)
]]
local function measureText(text, font)
    local fs = getMeasureFS(font)
    fs:SetText(text or "")
    return fs:GetStringWidth() or 0
end

--[[
  Populate headerMinWidths once at panel creation, after header buttons
  exist. Each column's floor = header caption width + a padding for
  the sort-indicator glyph that appears on the active column (" ^" or
  " v"). Uses the header button's font, which is GameFontNormalSmall.
]]
local function initHeaderMinWidths()
    -- Template arrow (9px) + breathing room on both sides of the
    -- arrow so it doesn't crowd the text on the left or sit flush
    -- against the column boundary on the right.
    local ARROW_PAD = 30
    -- Header labels have to match makeHeaderCell's SetText calls.
    headerMinWidths.time   = math.ceil(measureText("Time",   "GameFontNormalSmall")) + ARROW_PAD
    headerMinWidths.buyout = math.ceil(measureText("Buyout", "GameFontNormalSmall")) + ARROW_PAD
    headerMinWidths.level  = math.ceil(measureText("Lvl",    "GameFontNormalSmall")) + ARROW_PAD
    -- Seed colWidths with the floor so an initial relayout has valid
    -- widths even before the first recomputeColWidths call.
    colWidths.time   = headerMinWidths.time
    colWidths.buyout = headerMinWidths.buyout
    colWidths.level  = headerMinWidths.level
end

--[[
  Walk current eval rows, measure the widest rendered text for each
  fluid column, then set each colWidth = max(naturalMax, headerMin).
  Result: columns hug their content but never collapse below their
  own caption. Left columns (Name) get whatever horizontal space the
  fluid columns relinquished.

  Called on EVAL:COMPLETE. Does nothing useful if rows is empty --
  in that case colWidths stays at header-min floors from init.
]]
local function recomputeColWidths()
    if not headerMinWidths.time then return end  -- init not run yet

    local rows = eval:getRows() or {}
    local maxTime, maxBuyout, maxLevel = 0, 0, 0

    for _, r in ipairs(rows) do
        if r.timeLeft then
            local w = measureText(formatTimeLeft(r.timeLeft), "GameFontHighlightSmall")
            if w > maxTime then maxTime = w end
        end
        -- Pair rows use a combined buyout; format the same way the
        -- cell will, so measurement matches render.
        if r.buyout then
            local w = measureText(formatMoney(r.buyout), "GameFontHighlightSmall")
            if w > maxBuyout then maxBuyout = w end
        end
        -- Level column: single rows use r.minLevel directly; pair rows
        -- use max(mh.minLevel, oh.minLevel) computed at render time.
        local lvl
        if r.isPair then
            lvl = math.max(r.mhEntry and r.mhEntry.minLevel or 0,
                           r.ohEntry and r.ohEntry.minLevel or 0)
        else
            lvl = r.minLevel or 0
        end
        if lvl > 0 then
            local w = measureText(tostring(lvl), "GameFontHighlightSmall")
            if w > maxLevel then maxLevel = w end
        end
    end

    -- Apply floors. math.ceil on measurement output, then max against
    -- header minimum. Add a small trailing pad so text doesn't sit
    -- flush against the column boundary.
    local CELL_PAD = 4
    colWidths.time   = math.max(math.ceil(maxTime)   + CELL_PAD, headerMinWidths.time)
    colWidths.buyout = math.max(math.ceil(maxBuyout) + CELL_PAD, headerMinWidths.buyout)
    colWidths.level  = math.max(math.ceil(maxLevel)  + CELL_PAD, headerMinWidths.level)
end

-- ============================================================================
-- PANEL CREATION
-- ============================================================================

local function createPanel()
    if panelFrame then return end

    panelFrame = CreateFrame("Frame", "PawnShopPanel", AuctionFrame, "BackdropTemplate")
    -- Panel top offset 32: AH title bar clears at ~28px; 32 leaves a
    -- small breathing gap without wasting vertical space.
    -- Panel right offset 10: leaves room for Blizzard's AH frame
    -- texture edge without eating 20px of usable area like before.
    -- panelFrame TOP at -58: leaves the AH chrome's full titlebar
    -- region visible above (parchment ribbon + dark separator at the
    -- bottom of the titlebar, all part of the AH frame's top texture).
    -- Our content area starts cleanly below the titlebar.
    panelFrame:SetPoint("TOPLEFT",     AuctionFrame, "TOPLEFT",      20, -58)
    panelFrame:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT",  -10,  35)

    -- No panelFrame backdrop: on our tab activate we swap the AH frame's
    -- chrome textures to Browse's set (in ahTab.lua), which provides
    -- parchment top + dark bottom. The chrome IS our panel background,
    -- same model Blizzard uses for its own tabs.
    panelFrame:Hide()

    if Addon.style and Addon.style.skinTitlebar then
        Addon.style:skinTitlebar(panelFrame, "Pawn Shop: Auction Upgrades")
    end

    -- Scan button
    scanButton = CreateFrame("Button", nil, panelFrame, "UIPanelButtonTemplate")
    scanButton:SetSize(110, 22)
    scanButton:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", 0, 0)
    scanButton:SetText("Scan All")
    scanButton:SetScript("OnClick", function()
        local ok, reason = scan:start()
        if not ok then
            if     reason == "already_scanning" then setStatus("Scan already in progress")
            elseif reason == "ah_closed"         then setStatus("AH not open")
            elseif reason == "cooldown"          then setStatus("getAll on cooldown")
            else                                     setStatus("Scan failed: " .. tostring(reason))
            end
        end
    end)

    -- Cooldown countdown. Re-checks scan:getCooldownRemaining once per
    -- second while the panel is shown. When > 0, button reads "Wait
    -- N:NN" and is disabled; when 0, it returns to "Scan All" (status
    -- label and SCAN:STARTED handlers re-enable as appropriate).
    do
        local accum = 0
        scanButton:SetScript("OnUpdate", function(self, elapsed)
            accum = accum + elapsed
            if accum < 1 then return end
            accum = 0

            local remaining = (scan.getCooldownRemaining and scan:getCooldownRemaining()) or 0
            if remaining > 0 then
                local m = math.floor(remaining / 60)
                local s = remaining % 60
                self:SetText(string.format("Wait %d:%02d", m, s))
                self:Disable()
            else
                if self:GetText() ~= "Scan All" then
                    self:SetText("Scan All")
                    self:Enable()
                end
            end
        end)
    end

    -- Status label
    statusLabel = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusLabel:SetPoint("LEFT",  scanButton, "RIGHT", 12, 0)
    statusLabel:SetJustifyH("LEFT")
    statusLabel:SetText("Idle.")

    -- ============================================================
    -- TOP FILTER ROW
    -- ============================================================
    -- Scale + Companion dropdowns, right-justified to panel-right.
    -- Labels sit on the scan button's y-axis; controls below labels.
    --
    -- These are the global filter selectors -- they decide WHICH
    -- scales drive the table's content. Per-column gear filters
    -- below handle row-level gates (level cap, min upgrade %).
    local DROPDOWN_W = 176
    local DROPDOWN_H = 22
    local LABEL_H    = 12
    local FILTER_GAP = 8
    local FILTER_PADRIGHT = 12

    local function refreshScaleOptions(dd, includeNone)
        local list, _err = Addon.pawnIntegration:getEnabledScales()
        local opts = {}
        if includeNone then
            table.insert(opts, { value = "", text = "(none)" })
        end
        for _, s in ipairs(list or {}) do
            table.insert(opts, { value = s.internalName, text = s.localizedName })
        end
        if dd.SetOptions then dd:SetOptions(opts) end
    end

    local function readSetting(key)
        return options:Get(key)
    end

    local function writeSetting(key, value)
        options:SetCharacter(key, value)
    end

    -- Companion dropdown (rightmost)
    local companionDropdown = dropdown:create({
        parent       = panelFrame,
        width        = DROPDOWN_W,
        height       = DROPDOWN_H,
        placeholder  = "(none)",
        options      = {},
        defaultValue = readSetting("companionScale") or "",
        onChange     = function(value)
            if value == "" then value = nil end
            writeSetting("companionScale", value)
        end,
    })
    companionDropdown:SetPoint("BOTTOMRIGHT", scanButton, "BOTTOMRIGHT",
        0, 0)  -- placeholder; reanchored after positioning
    companionDropdown:ClearAllPoints()
    companionDropdown:SetPoint("RIGHT", panelFrame,  "RIGHT", -FILTER_PADRIGHT, 0)
    companionDropdown:SetPoint("TOP",   scanButton,  "BOTTOM", 0, -LABEL_H - 2)
    -- Anchor to RIGHT edge: setting both LEFT and RIGHT would stretch;
    -- we want fixed width so only the right side matters. Re-anchor with
    -- only TOP and RIGHT; ClearAllPoints first so the BOTTOMRIGHT
    -- placeholder doesn't conflict.
    companionDropdown:ClearAllPoints()
    -- Anchor to AuctionFrame so the filter row sits near the chrome
    -- titlebar (-30 from AH top), independent of panelFrame's content
    -- inset. Closer to titlebar than Browse's filter row, but not
    -- flush -- breathing room between titlebar text and label.
    companionDropdown:SetPoint("TOPRIGHT", AuctionFrame, "TOPRIGHT", -FILTER_PADRIGHT - 10, -40 - LABEL_H - 2)

    local companionLabel = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    companionLabel:SetText("Secondary scale")
    companionLabel:SetPoint("BOTTOMLEFT", companionDropdown, "TOPLEFT", 6, 2)

    -- Scale dropdown (just left of Companion)
    local scaleDropdown = dropdown:create({
        parent       = panelFrame,
        width        = DROPDOWN_W,
        height       = DROPDOWN_H,
        placeholder  = "(pick a scale)",
        options      = {},
        defaultValue = readSetting("scale") or "",
        onChange     = function(value)
            writeSetting("scale", value)
        end,
    })
    scaleDropdown:ClearAllPoints()
    scaleDropdown:SetPoint("TOPRIGHT", companionDropdown, "TOPLEFT", -FILTER_GAP, 0)

    local scaleLabel = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleLabel:SetText("Scale")
    scaleLabel:SetPoint("BOTTOMLEFT", scaleDropdown, "TOPLEFT", 6, 2)

    -- Status label right edge: stop before the scale dropdown.
    statusLabel:SetPoint("RIGHT", scaleDropdown, "LEFT", -FILTER_GAP, 0)

    -- Stash for later: refresh after eval populates Pawn.
    panel.scaleDropdown     = scaleDropdown
    panel.companionDropdown = companionDropdown
    panel.refreshScaleOptions = function()
        refreshScaleOptions(scaleDropdown,     false)
        refreshScaleOptions(companionDropdown, true)
        if scaleDropdown.SetValue then
            scaleDropdown:SetValue(readSetting("scale") or "", true)
        end
        if companionDropdown.SetValue then
            companionDropdown:SetValue(readSetting("companionScale") or "", true)
        end
    end

    -- Slot tab strip: fixed-width vertical column down the panel's left
    -- edge. Strip width matches the chrome's vertical divider bar
    -- position. The header row's LEFT edge sits 8px to the left of the
    -- bar (intentional slight overlap into the strip side), matching
    -- where the stock AH chrome's column dividers visually begin.
    local STRIP_WIDTH = 138
    local HEADER_LEFT = STRIP_WIDTH + 35

    -- Strip background: dark backdrop covering the slot-strip column.
    -- Layered on top of panelFrame's parchment; strip tabs render on
    -- top of this. Sized to fill the column from just below the
    -- scan-button row down to panel bottom.
    local stripBgFrame = CreateFrame("Frame", nil, panelFrame, "BackdropTemplate")
    stripBgFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
    })
    stripBgFrame:SetBackdropColor(0, 0, 0, 0.55)
    stripBgFrame:SetPoint("LEFT",   panelFrame, "LEFT",   0, 0)
    stripBgFrame:SetPoint("BOTTOM", panelFrame, "BOTTOM", 0, 0)
    stripBgFrame:SetWidth(STRIP_WIDTH)

    slotTabStrip = filterTabStrip:create({
        parent      = panelFrame,
        orientation = "vertical",
        tabHeight   = 26,
        spacing     = 2,
        width       = STRIP_WIDTH,
        onSelect    = function(_tabId)
            panel:redraw()
        end,
    })

    -- Strip geometry: LEFT and BOTTOM pinned to panelFrame here. TOP
    -- anchor is set later by applyTableLayout once headerFrame exists.
    slotTabStrip:SetPoint("LEFT",   panelFrame, "LEFT",   0, 0)
    slotTabStrip:SetPoint("BOTTOM", panelFrame, "BOTTOM", 0, 0)

    -- Header row: anchored to push the table area down into the AH
    -- frame's dark-texture region (y=-105 from AuctionFrame top, which
    -- is y=-47 from panelFrame top given panelFrame's 58px top inset).
    -- This is the same y-position Blizzard uses for the Browse tab's
    -- scroll frame, so our table sits on the same dark background.
    headerFrame = CreateFrame("Frame", nil, panelFrame)
    headerFrame:SetPoint("TOP",   panelFrame, "TOP",   0, -23)
    headerFrame:SetPoint("LEFT",  panelFrame, "LEFT",  HEADER_LEFT, 0)
    headerFrame:SetPoint("RIGHT", panelFrame, "RIGHT", 0, 0)
    headerFrame:SetHeight(constants.HEADER_HEIGHT)

    -- Table background: dark backdrop covering the table area.
    local tableBgFrame = CreateFrame("Frame", nil, panelFrame, "BackdropTemplate")
    tableBgFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        tile = false,
    })
    tableBgFrame:SetBackdropColor(0, 0, 0, 0.92)
    tableBgFrame:SetPoint("TOPLEFT",     headerFrame, "BOTTOMLEFT", 0, 0)
    tableBgFrame:SetPoint("BOTTOMRIGHT", panelFrame,  "BOTTOMRIGHT", 0, 0)
    panel._stripBgFrame = stripBgFrame
    panel._tableBgFrame = tableBgFrame
    -- Hide both: AH chrome's own dark stone textures (applied to
    -- AuctionFrameTopLeft/Top/TopRight/BotLeft/Bot/BotRight in
    -- ahTab.lua's applyOurTabChrome) provide the background. Same
    -- model Blizzard uses -- BrowseFilterScrollFrame and
    -- BrowseScrollFrame have no backdrops in the AH XML.
    stripBgFrame:Hide()
    tableBgFrame:Hide()

    -- Tint frames behind each scale column (header + table area).
    -- A subtle parchment-tinted overlay marks Scale 1 / Scale 2 as
    -- "ours" -- they're our concept (Pawn upgrade %s), not stock AH
    -- data. Positioned by relayoutColumns to match the moving header
    -- columns. Layered above tableBgFrame, below content.
    panel._scaleTints = {}
    for i = 1, constants.DISPLAYED_SCALE_COLUMNS do
        local tint = CreateFrame("Frame", nil, panelFrame, "BackdropTemplate")
        tint:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            tile = false,
        })
        -- Slight warm tint with low alpha so cell text + headers
        -- still read clearly. Distinctive but not shouty.
        tint:SetBackdropColor(0.45, 0.35, 0.15, 0.18)
        tint:SetFrameLevel(tableBgFrame:GetFrameLevel() + 1)
        tint:Hide()
        panel._scaleTints[i] = tint
    end

    -- ============================================================
    -- HEADER WIDGETS
    -- ============================================================
    -- AH-themed style: parchment-on-dark via WhoFrame-ColumnTabs
    -- 3-slice texture, our white PNG arrows, AH-style hover glow.
    -- Builds on the BASIC style with overrides for the AH context.
    local AH_HEADER_STYLE = Addon.header.extend(Addon.header.styles.BASIC, {
        background = {
            texture    = "Interface\\FriendsFrame\\WhoFrame-ColumnTabs",
            leftWidth  = 5,
            rightWidth = 4,
            -- The texture file's top region (0..0.59375 V) is the
            -- 19px-tall slice; we use TexCoord (0..0.75) for the
            -- 24px-tall slice that matches our HEADER_HEIGHT.
            texCoords = {
                left   = { 0,        0.078125, 0, 0.75 },
                middle = { 0.078125, 0.90625,  0, 0.75 },
                right  = { 0.90625,  0.96875,  0, 0.75 },
            },
        },
        highlight = {
            file      = "Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight",
            blendMode = "ADD",
        },
        font           = "GameFontHighlightSmall",
        textInsetLeft  = 8,
        arrow = {
            up   = "Interface\\AddOns\\PawnShop\\textures\\arrow-up",
            down = "Interface\\AddOns\\PawnShop\\textures\\arrow-down",
            size = { 9, 8 },
            color = nil,    -- our PNGs are already white
        },
    })

    -- Create stock-data headers (Item/Lvl/Buyout/Time). All sortable.
    -- Lvl additionally has a filter gear (level cap).
    local function createHeader(cfg)
        cfg.parent = headerFrame
        cfg.height = constants.HEADER_HEIGHT
        cfg.style  = AH_HEADER_STYLE
        cfg.group  = "ahHeaders"
        local w = Addon.header:create(cfg)
        headerWidgets[cfg.columnKey] = w
        return w:getFrame()
    end

    headerItem   = createHeader({
        columnKey = "name",  label = "Item",   width = 200,  -- width re-set by relayout
        sortable = true,
    })
    headerLvl    = createHeader({
        columnKey = "lvl",   label = "Lvl",    width = constants.COL_LEVEL_WIDTH,
        sortable = true,
        filterable     = true,
        filterValue    = function() return options:Get("levelTolerance") or 2 end,
        filterCommit   = function(v) options:SetCharacter("levelTolerance", v) end,
        popup = { kind = "number", title = "Level Tolerance", helper = "Show this many levels above yours", placeholder = "e.g. 5", min = 0, max = 100 },
    })
    headerBuyout = createHeader({
        columnKey = "buyout", label = "Buyout", width = constants.COL_BUYOUT_WIDTH,
        sortable = true,
    })
    headerTime   = createHeader({
        columnKey = "time",   label = "Time",   width = constants.COL_TIME_WIDTH,
        sortable = true,
    })

    -- Scale headers (Scale 1 / Secondary). Scale 1 sortable + filterable
    -- with min upgrade %. Secondary not sortable. Both use white arrow
    -- via PNG textures (already-white file means no state-machine fight).
    do
        local s1Cfg = {
            columnKey = "scale_1", label = "Scale", width = constants.COL_SCALE_WIDTH,
            sortable = true,
            preSort  = function() return true, "desc" end,   -- always desc
            filterable     = true,
            filterValue    = function() return options:Get("minUpgradePct") or 0 end,
            filterCommit   = function(v) options:SetCharacter("minUpgradePct", v) end,
            popup = { kind = "number", title = "Min Upgrade %", helper = "Hide items below this upgrade %", placeholder = "e.g. 100", min = 0, max = 999 },
        }
        s1Cfg.parent = headerFrame
        s1Cfg.height = constants.HEADER_HEIGHT
        s1Cfg.style  = AH_HEADER_STYLE
        s1Cfg.group  = "ahHeaders"
        local w1 = Addon.header:create(s1Cfg)
        headerWidgets["scale_1"] = w1
        scaleHeaders[1] = w1:getFrame()
        scaleHeaders[1].columnKey  = "scale_1"
        scaleHeaders[1].scaleIndex = 1

        local s2Cfg = {
            columnKey = "scale_2", label = "Secondary", width = constants.COL_SECONDARY_WIDTH,
            sortable = false,
        }
        s2Cfg.parent = headerFrame
        s2Cfg.height = constants.HEADER_HEIGHT
        s2Cfg.style  = AH_HEADER_STYLE
        s2Cfg.group  = "ahHeaders"
        local w2 = Addon.header:create(s2Cfg)
        headerWidgets["scale_2"] = w2
        scaleHeaders[2] = w2:getFrame()
        scaleHeaders[2].columnKey  = "scale_2"
        scaleHeaders[2].scaleIndex = 2
    end

    -- Hover tooltips on scale headers (which scale is in this column?)
    for i = 1, constants.DISPLAYED_SCALE_COLUMNS do
        local sb = scaleHeaders[i]
        sb:HookScript("OnEnter", function(self)
            local sName = displayedScales[self.scaleIndex]
            local idx   = sName and eval:getTrackedScales()[sName] or nil
            local label = idx and eval:getScaleDisplayOrder()[idx] or sName or "?"
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(label)
            GameTooltip:Show()
        end)
        sb:HookScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- List frame + scroll
    listFrame = CreateFrame("Frame", nil, panelFrame)
    listFrame:SetPoint("TOPLEFT",     headerFrame, "BOTTOMLEFT", 0, 0)
    listFrame:SetPoint("BOTTOMRIGHT", panelFrame,  "BOTTOMRIGHT", 0, 0)

    scrollFrame = CreateFrame("ScrollFrame", "PawnShopScroll", listFrame, "FauxScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     listFrame, "TOPLEFT",     0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -scrollbarGutter, 0)
    scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, constants.ROW_HEIGHT, function() panel:redraw() end)
    end)

    --[[
      Preallocate row frames. Each row can render as:
        - item row: icon + name + per-scale cells + buyout + time
        - pair row: two-line layout with MH on top, OH below
      redraw() decides which mode based on display row kind.

      TODO: future cleanup -- use Addon.pool for dynamic allocation instead
      of fixed 30. Parity migration preserves the current approach.
    ]]
    rowFrames = {}
    for i = 1, 30 do
        local row = CreateFrame("Frame", nil, listFrame)
        row:SetHeight(constants.ROW_HEIGHT)
        row:SetPoint("LEFT",  listFrame,   "LEFT",  0, 0)
        row:SetPoint("RIGHT", scrollFrame, "RIGHT", 0, 0)
        if i == 1 then
            row:SetPoint("TOP", listFrame, "TOP", 0, 0)
        else
            row:SetPoint("TOP", rowFrames[i - 1], "BOTTOM", 0, 0)
        end

        -- Alternating row background
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(row)
        if i % 2 == 0 then
            bg:SetColorTexture(1, 1, 1, 0.04)
        else
            bg:SetColorTexture(0, 0, 0, 0.08)
        end
        row.bg = bg

        -- Primary icon (MH icon in pair mode, item icon in single mode)
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(constants.ICON_SIZE, constants.ICON_SIZE)
        row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)

        -- Secondary icon (OH in pair mode). Hidden in single mode.
        row.icon2 = row:CreateTexture(nil, "ARTWORK")
        row.icon2:SetSize(constants.ICON_SIZE - 4, constants.ICON_SIZE - 4)
        row.icon2:Hide()

        -- Primary name button
        local nameBtn = CreateFrame("Button", nil, row)
        nameBtn:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
        nameBtn:SetHeight(constants.ROW_HEIGHT)
        nameBtn.text = nameBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameBtn.text:SetAllPoints(nameBtn)
        nameBtn.text:SetJustifyH("LEFT")
        nameBtn.text:SetJustifyV("MIDDLE")
        -- Prevent text from rendering past the fontstring's bounded
        -- region. Without this, long item names overflow and overlap
        -- adjacent columns (Lvl in particular).
        nameBtn.text:SetWordWrap(false)
        nameBtn:SetScript("OnEnter", nameBtnOnEnter)
        nameBtn:SetScript("OnLeave", nameBtnOnLeave)
        nameBtn:SetScript("OnClick", nameBtnOnClick)
        row.nameBtn = nameBtn

        -- Secondary name button (OH line in pair mode)
        local nameBtn2 = CreateFrame("Button", nil, row)
        nameBtn2:Hide()
        nameBtn2.text = nameBtn2:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameBtn2.text:SetAllPoints(nameBtn2)
        nameBtn2.text:SetJustifyH("LEFT")
        nameBtn2.text:SetJustifyV("MIDDLE")
        nameBtn2.text:SetWordWrap(false)
        nameBtn2:SetScript("OnEnter", nameBtnOnEnter)
        nameBtn2:SetScript("OnLeave", nameBtnOnLeave)
        nameBtn2:SetScript("OnClick", nameBtnOnClick)
        row.nameBtn2 = nameBtn2

        row.buyoutText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.buyoutText:SetJustifyH("LEFT")
        row.buyoutText:SetJustifyV("MIDDLE")
        row.buyoutText:SetWidth(constants.COL_BUYOUT_WIDTH)

        row.timeText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.timeText:SetJustifyH("LEFT")
        row.timeText:SetJustifyV("MIDDLE")
        row.timeText:SetWidth(constants.COL_TIME_WIDTH)

        row.levelText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.levelText:SetJustifyH("LEFT")
        row.levelText:SetJustifyV("MIDDLE")
        row.levelText:SetWidth(constants.COL_LEVEL_WIDTH)

        -- Per-scale cells; positioned by relayoutColumns. Width depends
        -- on column: Scale 1 (sortable) wider than Scale 2 (Secondary).
        row.scaleCells = {}
        for s = 1, constants.DISPLAYED_SCALE_COLUMNS do
            local cell = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            cell:SetJustifyH("CENTER")
            cell:SetJustifyV("MIDDLE")
            cell:SetWidth(s == 1 and constants.COL_SCALE_WIDTH or constants.COL_SECONDARY_WIDTH)
            cell:Hide()
            row.scaleCells[s] = cell
        end

        rowFrames[i] = row
    end

    -- Seed fluid column widths from header-text minimums. Once eval
    -- completes with actual rows, recomputeColWidths may grow them
    -- to fit content; until then the floor is the caption width.
    initHeaderMinWidths()
end

-- ============================================================================
-- COLUMN LAYOUT
-- ============================================================================

--[[
  Position header cells and per-row cells for the currently displayed
  scale count. displayedScales drives how many scale columns render
  (1 or 2 depending on what's been picked / discovered).

  Scale headers use positional labels ("Scale 1" / "Scale 2"), matching
  the sort key format. The tooltip on hover shows the localized name of
  the scale currently assigned to that column by the dropdown picker.
]]
local function relayoutColumns()
    -- Adjacent header textures overlap by 2px so the AuctionSortButtonTemplate
    -- left/right edge textures merge into a continuous parchment header
    -- bar, matching Browse's header look. Row cells still use COL_PADDING
    -- for visual separation.
    local HEADER_GAP = -2

    -- How many scale columns have a scale assigned?
    local n = 0
    for i = 1, constants.DISPLAYED_SCALE_COLUMNS do
        if displayedScales[i] then n = n + 1 end
    end

    local gutter = scrollbarGutter
    local scaleDisplayOrder = eval:getScaleDisplayOrder()
    local trackedScales     = eval:getTrackedScales()

    -- Fluid column widths (time/buyout/level) come from colWidths, which
    -- is recomputed per eval to fit actual content with a header-width
    -- floor. Scale columns stay fixed at COL_SCALE_WIDTH since their
    -- content is bounded ("+999%" or "NEW 9999").
    local wTime   = colWidths.time   or constants.COL_TIME_WIDTH
    local wBuyout = colWidths.buyout or constants.COL_BUYOUT_WIDTH
    local wLevel  = colWidths.level  or constants.COL_LEVEL_WIDTH

    -- Apply widths to the per-row fontstrings so text clipping works
    -- correctly once SetWordWrap(false) is in play.
    for _, row in ipairs(rowFrames) do
        row.timeText:SetWidth(wTime)
        row.buyoutText:SetWidth(wBuyout)
        row.levelText:SetWidth(wLevel)
    end

    -- Headers anchor to panel-right (headerFrame spans full panel) so we
    -- pay the gutter once here. Row cells anchor to scroll-right which
    -- already excludes the gutter, so rrx starts at 0 below.
    --
    -- Right-to-left order: Scale 2, Scale 1, Time, Buyout, Lvl, Item.
    -- Scale columns are rightmost so they're visually sequestered as
    -- "ours" -- they're our concept (Pawn upgrade %s), not stock AH
    -- data, and tinted backgrounds reinforce that separation.
    local rx = gutter

    -- Scale columns first (rightmost). Walk in reverse so Scale 1 ends
    -- up to the LEFT of Scale 2 visually.
    -- Width depends on column: Scale 1 needs space for sort arrow, Scale 2
    -- (Secondary) doesn't sort and uses a narrower width.
    local function scaleColWidth(idx)
        return idx == 1 and constants.COL_SCALE_WIDTH or constants.COL_SECONDARY_WIDTH
    end
    for i = n, 1, -1 do
        local w = scaleColWidth(i)
        local btn = scaleHeaders[i]
        btn:ClearAllPoints()
        btn:SetPoint("RIGHT", headerFrame, "RIGHT", -rx, 0)
        btn:Show()

        -- Position the matching tint frame: full vertical span (header
        -- + table area), width = this scale column's width.
        local tint = panel._scaleTints and panel._scaleTints[i]
        if tint then
            tint:ClearAllPoints()
            tint:SetPoint("TOP",    headerFrame, "TOP",    0, 0)
            tint:SetPoint("BOTTOM", panelFrame,  "BOTTOM", 0, 0)
            tint:SetPoint("RIGHT",  panelFrame,  "RIGHT", -rx, 0)
            tint:SetWidth(w)
            tint:Show()
        end

        rx = rx + w + HEADER_GAP
    end
    -- Hide any header beyond `n` (when fewer scales are active than max).
    for i = n + 1, constants.DISPLAYED_SCALE_COLUMNS do
        if scaleHeaders[i] then scaleHeaders[i]:Hide() end
        if panel._scaleTints and panel._scaleTints[i] then
            panel._scaleTints[i]:Hide()
        end
    end

    headerTime:ClearAllPoints()
    headerTime:SetPoint("RIGHT", headerFrame, "RIGHT", -rx, 0)
    headerTime:SetWidth(wTime)
    rx = rx + wTime + HEADER_GAP

    headerBuyout:ClearAllPoints()
    headerBuyout:SetPoint("RIGHT", headerFrame, "RIGHT", -rx, 0)
    headerBuyout:SetWidth(wBuyout)
    rx = rx + wBuyout + HEADER_GAP

    headerLvl:ClearAllPoints()
    headerLvl:SetPoint("RIGHT", headerFrame, "RIGHT", -rx, 0)
    headerLvl:SetWidth(wLevel)
    rx = rx + wLevel + HEADER_GAP

    headerItem:ClearAllPoints()
    headerItem:SetPoint("LEFT",  headerFrame, "LEFT",  -8, 0)
    headerItem:SetPoint("RIGHT", headerFrame, "RIGHT", -rx, 0)

    -- Per-row cells. Rows anchor to scroll-right which already excludes
    -- the gutter, so rrx starts at 0. Right-to-left order matches the
    -- header walk above: Scale 2, Scale 1, Time, Buyout, Lvl, Item.
    -- Cells use the same HEADER_GAP as headers so column edges align
    -- vertically between header and row content.
    local TEXT_INSET = 8  -- matches AuctionSortButtonTemplate's $parentText x=8
    for _, row in ipairs(rowFrames) do
        local rrx = 0

        -- Build per-index right-offset table: cumulative width sum from
        -- rightmost (i=n) walking inward to i=1. cellRightOffset[i] = total
        -- pixels from row's RIGHT to the RIGHT edge of column i.
        local cellRightOffset = {}
        local accum = 0
        for i = n, 1, -1 do
            cellRightOffset[i] = accum
            accum = accum + scaleColWidth(i) + HEADER_GAP
        end
        -- accum is now total width occupied by all n scale columns.
        local totalScaleWidth = accum

        for i = 1, constants.DISPLAYED_SCALE_COLUMNS do
            local cell = row.scaleCells[i]
            cell:ClearAllPoints()
            if i <= n then
                cell:SetPoint("RIGHT", row, "RIGHT", -(rrx + cellRightOffset[i]), 0)
                cell:SetWidth(scaleColWidth(i))
                cell:SetHeight(constants.ROW_HEIGHT)
                cell:Show()
            else
                cell:Hide()
            end
        end
        rrx = rrx + totalScaleWidth

        row.timeText:ClearAllPoints()
        row.timeText:SetPoint("LEFT", row, "RIGHT", -(rrx + wTime) + TEXT_INSET, 0)
        rrx = rrx + wTime + HEADER_GAP

        row.buyoutText:ClearAllPoints()
        row.buyoutText:SetPoint("LEFT", row, "RIGHT", -(rrx + wBuyout) + TEXT_INSET, 0)
        rrx = rrx + wBuyout + HEADER_GAP

        row.levelText:ClearAllPoints()
        row.levelText:SetPoint("LEFT", row, "RIGHT", -(rrx + wLevel) + TEXT_INSET, 0)
        rrx = rrx + wLevel + HEADER_GAP

        row.nameBtn:ClearAllPoints()
        row.nameBtn:SetPoint("LEFT",  row.icon, "RIGHT", 4, 0)
        row.nameBtn:SetPoint("RIGHT", row,      "RIGHT", -rrx, 0)
    end
end

-- ============================================================================
-- BUILD DISPLAY ROWS
-- ============================================================================

--[[
  Build the flat display list from eval's rows, filtered to the currently
  selected slot tab AND to rows that have at least one upgrade on a
  displayed scale. The displayed-scale filter keeps rows out of the grid
  when they'd render with all scale columns empty (the upgrade exists on
  a non-displayed scale). If no tab is selected, returns empty.
  @return table - array of { kind = "item", data = entry, height = px }
]]
local function buildDisplayRows()
    local rows = eval:getRows()
    local selectedSlot = slotTabStrip and slotTabStrip:getSelected() or nil
    if not selectedSlot then return {} end

    local s = readFilterSettings()
    local out = {}
    for _, a in ipairs(rows) do
        if (a.slotName or "Other") == selectedSlot then
            if rowPassesFilters(a, s) then
                table.insert(out, {
                    kind   = "item",
                    data   = a,
                    height = a.isPair and constants.ROW_HEIGHT_PAIR or constants.ROW_HEIGHT,
                })
            end
        end
    end
    return out
end

-- ============================================================================
-- REDRAW
-- ============================================================================

--[[
  Build the display list from current eval state and paint every row frame.
  Rebuilds column layout first if the tracked-scale count has changed.
]]
function panel:redraw()
    if not rowFrames or #rowFrames == 0 then return end

    -- `n` is the number of populated display columns, not discovered
    -- scales. relayoutColumns is driven by this count so it matches what
    -- the user picked in the dropdowns.
    local n = 0
    for i = 1, constants.DISPLAYED_SCALE_COLUMNS do
        if displayedScales[i] then n = n + 1 end
    end

    if lastScaleCount ~= n then
        relayoutColumns()
        self:updateSortIndicators()
        lastScaleCount = n
    end

    local display = buildDisplayRows()
    local total   = #display
    local offset  = FauxScrollFrame_GetOffset(scrollFrame) or 0
    local panelH  = listFrame:GetHeight() or 0

    -- Count how many display rows fit given their individual heights.
    -- Pair rows are taller than singles.
    local rowsVisible = 0
    do
        local y = 0
        for i = offset + 1, total do
            local h = display[i].height or constants.ROW_HEIGHT
            if y + h > panelH then break end
            y = y + h
            rowsVisible = rowsVisible + 1
            if rowsVisible >= #rowFrames then break end
        end
    end

    -- Scroll math uses ROW_HEIGHT as the unit step. Thumb is a close
    -- approximation with mixed-height rows, not pixel-perfect.
    FauxScrollFrame_Update(scrollFrame, total, rowsVisible, constants.ROW_HEIGHT)

    for i = 1, #rowFrames do
        local row = rowFrames[i]
        local dr  = (i <= rowsVisible) and display[i + offset] or nil

        if dr and dr.height then
            row:SetHeight(dr.height)
        else
            row:SetHeight(constants.ROW_HEIGHT)
        end

        if not dr then
            row:Hide()
            row.nameBtn.link = nil
            row.nameBtn.pairData = nil
            row.nameBtn.itemName = nil
            if row.nameBtn2 then
                row.nameBtn2:Hide()
                row.nameBtn2.link = nil
                row.nameBtn2.pairData = nil
            end
            if row.icon2 then row.icon2:Hide() end

        else
            -- Item row (single or pair).
            local data = dr.data
            row:Show()

            local upgradeByScale = {}
            if data.upgrades then
                for _, u in ipairs(data.upgrades) do
                    upgradeByScale[u.scale] = u
                end
            end

            if data.isPair then
                -- PAIR: two-line layout, height = ROW_HEIGHT_PAIR.
                local mhE, ohE = data.mhEntry, data.ohEntry

                -- Name button right edge must stop at the same x as
                -- relayoutColumns' rrx total: all non-name columns plus
                -- their inter-column paddings. Missing Level here was
                -- why long item names overlapped the Lvl cell.
                local wTime   = colWidths.time   or constants.COL_TIME_WIDTH
                local wBuyout = colWidths.buyout or constants.COL_BUYOUT_WIDTH
                local wLevel  = colWidths.level  or constants.COL_LEVEL_WIDTH
                local nameRightPad =
                      wTime                                                       + constants.COL_PADDING
                    + wBuyout                                                     + constants.COL_PADDING
                    + n * (constants.COL_SCALE_WIDTH + constants.COL_PADDING)
                    + wLevel                                                      + constants.COL_PADDING

                -- Top half (MH)
                row.icon:SetSize(constants.ICON_SIZE - 4, constants.ICON_SIZE - 4)
                row.icon:ClearAllPoints()
                row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 2, -2)
                row.nameBtn:ClearAllPoints()
                row.nameBtn:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
                row.nameBtn:SetPoint("TOP",   row, "TOP",   0, 0)
                row.nameBtn:SetPoint("RIGHT", row, "RIGHT", -nameRightPad, 0)
                row.nameBtn:SetHeight(constants.ROW_HEIGHT_PAIR / 2)
                row.nameBtn.link     = mhE.link
                row.nameBtn.pairData = data
                row.nameBtn.itemName = nil
                row.nameBtn:Show()

                -- Bottom half (OH)
                row.icon2:ClearAllPoints()
                row.icon2:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 2, 2)
                row.icon2:Show()
                row.nameBtn2:ClearAllPoints()
                row.nameBtn2:SetPoint("LEFT", row.icon2, "RIGHT", 4, 0)
                row.nameBtn2:SetPoint("BOTTOM", row, "BOTTOM", 0, 0)
                row.nameBtn2:SetPoint("RIGHT",  row, "RIGHT", -nameRightPad, 0)
                row.nameBtn2:SetHeight(constants.ROW_HEIGHT_PAIR / 2)
                row.nameBtn2.link     = ohE.link
                row.nameBtn2.pairData = data
                row.nameBtn2:Show()

                local function colored(link, name)
                    local _n, _lk, quality, _iLvl, _rLvl, _class, _subclass, _stack,
                          _equip, texture = GetItemInfo(link)
                    local colorStart = ""
                    if quality then
                        local r, g, b = GetItemQualityColor(quality)
                        colorStart = string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
                    end
                    return colorStart .. (name or "?") .. "|r", texture
                end

                local mhStr, mhTex = colored(mhE.link, mhE.name)
                local ohStr, ohTex = colored(ohE.link, ohE.name)
                row.icon:SetTexture(mhTex  or "Interface\\Icons\\INV_Misc_QuestionMark")
                row.icon2:SetTexture(ohTex or "Interface\\Icons\\INV_Misc_QuestionMark")
                row.nameBtn.text:SetText(mhStr)
                row.nameBtn2.text:SetText(ohStr)
                row.icon:Show()

                row.buyoutText:SetText(formatMoney(data.buyout))
                setTimeCell(row.timeText, data)

                -- Pair level = the higher of the two (both must be equippable).
                local mhLvl = (mhE.minLevel) or 0
                local ohLvl = (ohE.minLevel) or 0
                local pairLvl = math.max(mhLvl, ohLvl)
                setLevelCell(row.levelText, pairLvl)
            else
                -- SINGLE item row. Reset anchors so pair-mode state doesn't leak.
                row.icon2:Hide()
                row.nameBtn2:Hide()

                row.icon:SetSize(constants.ICON_SIZE, constants.ICON_SIZE)
                row.icon:ClearAllPoints()
                row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
                row.icon:Show()

                row.nameBtn:ClearAllPoints()
                row.nameBtn:SetPoint("LEFT",   row.icon, "RIGHT",  4, 0)
                row.nameBtn:SetPoint("TOP",    row,      "TOP",    0, 0)
                row.nameBtn:SetPoint("BOTTOM", row,      "BOTTOM", 0, 0)
                do
                    local wTime   = colWidths.time   or constants.COL_TIME_WIDTH
                    local wBuyout = colWidths.buyout or constants.COL_BUYOUT_WIDTH
                    local wLevel  = colWidths.level  or constants.COL_LEVEL_WIDTH
                    row.nameBtn:SetPoint("RIGHT", row, "RIGHT",
                        -(  wTime   + constants.COL_PADDING
                          + wBuyout + constants.COL_PADDING
                          + n * (constants.COL_SCALE_WIDTH + constants.COL_PADDING)
                          + wLevel  + constants.COL_PADDING), 0)
                end
                row.nameBtn.link     = data.link
                row.nameBtn.itemName = data.name
                row.nameBtn.pairData = nil
                row.nameBtn:Show()

                local _n, _lk, quality, _iLvl, _rLvl, _class, _subclass, _stack,
                      _equip, texture = GetItemInfo(data.link)
                row.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")

                local colorStart = ""
                if quality then
                    local r, g, b = GetItemQualityColor(quality)
                    colorStart = string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
                end
                row.nameBtn.text:SetText(colorStart .. data.name .. "|r")

                row.buyoutText:SetText(formatMoney(data.buyout))
                setTimeCell(row.timeText, data)
                setLevelCell(row.levelText, data.minLevel)
            end

            -- Scale cells (same for both modes). Cell s shows the upgrade
            -- on whichever scale the dropdown assigned to column s. If
            -- the row has no upgrade on that scale, the cell is empty.
            for s = 1, constants.DISPLAYED_SCALE_COLUMNS do
                local cell = row.scaleCells[s]
                if s <= n then
                    cell:SetText(formatScaleCell(upgradeByScale[displayedScales[s]]))
                    cell:Show()
                else
                    cell:Hide()
                end
            end
        end
    end
end

-- ============================================================================
-- PUBLIC ACCESS FROM ahTab
-- ============================================================================

function panel:ensureCreated()
    createPanel()
end

--[[
  Called by ahTab after persistence restored cached eval rows. Surfaces
  data age in the status label, and a scale-mismatch warning when the
  user's currently-selected filter scale isn't in the cached scale set.

  Both the data and the panel may not yet be fully wired (this fires
  from AUCTION_HOUSE_SHOW, before panel:show); we just stash the data
  and let panel:show pick it up.
]]
function panel:onScanRestored(scannedAt, cachedVisibleScales)
    panel._restoredScannedAt = scannedAt
    panel._restoredVisibleScales = cachedVisibleScales
end

function panel:show()
    createPanel()
    if panelFrame then panelFrame:Show() end

    -- Pre-hydrate displayed scales from settings (scale + companionScale)
    -- so the grid renders correct columns during the upcoming eval's
    -- incremental redraws. On first run, displayedScales[1] auto-pops
    -- to scaleOrder[1] on first EVAL:COMPLETE; until then both are
    -- nil and columns render as empty placeholders.
    initializeDisplayedScales()

    -- Hydrate the scale dropdowns from Pawn now so the saved scale shows
    -- in the dropdown immediately (without waiting for the first eval).
    -- Pawn is normally loaded by AH-open time; if not, the dropdowns stay
    -- empty and onEvalComplete will refresh them after the first scan.
    if panel.refreshScaleOptions then panel.refreshScaleOptions() end

    -- Refresh the slot tabs and redraw with the current filter
    -- settings. On a fresh AH open with eval rows already cached,
    -- nothing else triggers a slot-tab rebuild -- so previously-
    -- persisted min upgrade %, level tolerance, etc. wouldn't apply
    -- until the user touched a setting. This makes filters take
    -- effect immediately on every panel show.
    lastScaleCount = nil    -- force relayoutColumns next redraw
    refreshSlotTabs()
    panel:redraw()

    -- Force Blizzard's "always compare items" so hovering an auction
    -- shows the equipped comparison tooltips without needing Shift.
    -- We cache the prior value and restore it in panel:hide /
    -- AUCTION_HOUSE_CLOSED (see ahTab) so the user's out-of-addon
    -- setting survives. pcall to tolerate API surface differences.
    if savedAlwaysCompareCVar == nil then
        local ok, val = pcall(GetCVar, "alwaysCompareItems")
        if ok then savedAlwaysCompareCVar = val end
    end
    pcall(SetCVar, "alwaysCompareItems", "1")

    -- Status: if we restored cached data, surface its age (and a scale
    -- mismatch warning if the user's current filter scale isn't in the
    -- cached set). Otherwise the standard "Ready" prompt.
    local restoredAt   = panel._restoredScannedAt
    local cachedScales = panel._restoredVisibleScales
    if restoredAt then
        local ageMin = math.max(0, math.floor((time() - restoredAt) / 60))
        local ageStr = (ageMin == 0) and "just now" or (ageMin .. " min ago")
        local msg = "Showing data from " .. ageStr .. "."

        local currentScale = displayedScales[1]
        if currentScale and cachedScales then
            local found = false
            for _, s in ipairs(cachedScales) do
                if s == currentScale then found = true; break end
            end
            if not found then
                msg = msg .. " Selected scale isn't in cached data; rescan to refresh."
            end
        end
        setStatus(msg)
        panel._restoredScannedAt     = nil
        panel._restoredVisibleScales = nil
    else
        setStatus("Ready. Click Scan All.")
    end
end

function panel:hide()
    if panelFrame then panelFrame:Hide() end
    -- Close any open header popups so they don't reappear on tab return
    if Addon.header and Addon.header.closeAllInGroup then
        Addon.header:closeAllInGroup("ahHeaders")
    end
    panel:restoreCompareTooltipCVar()
end

--[[
  Restore the saved alwaysCompareItems CVar if we overrode it. Split
  out so ahTab can call it defensively on AUCTION_HOUSE_CLOSED in
  case the panel's hide path didn't run (e.g. unusual AH close sequence).
]]
function panel:restoreCompareTooltipCVar()
    if savedAlwaysCompareCVar ~= nil then
        pcall(SetCVar, "alwaysCompareItems", savedAlwaysCompareCVar)
        savedAlwaysCompareCVar = nil
    end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

local function onScanStarted()
    disableScanButton()
    setStatus("Waiting for server...")
end

local function onScanIngested(_, payload)
    local n = payload.count or 0
    if payload.source == "external" then
        setStatus(string.format("Picked up scan from another addon: %d auctions. Starting eval...", n))
    else
        setStatus(string.format("Scan done: %d auctions. Starting eval...", n))
    end
end

local function onScanEmpty()
    enableScanButton()
    setStatus("Scan returned 0 items")
end

local function onScanCancelled()
    enableScanButton()
end

local function onEvalStarted(_, payload)
    setStatus(string.format("Eval: %d items...", payload.total or 0))
end

local function onEvalRowsChanged()
    refreshSlotTabs()
    panel:redraw()
end

local function onEvalComplete(_, payload)
    enableScanButton()
    setStatus(string.format("Done. %d items processed.", payload.rows or 0))

    -- Auto-populate `scale` to the first scale Pawn returned upgrades
    -- for, if it isn't set yet. Without this, first-run users see empty
    -- columns until they pick a scale.
    if Addon.options then
        local saved = Addon.options:Get("scale")
        if not saved or saved == "" then
            local tracked = eval:getTrackedScales() or {}
            local first
            for internalName, idx in pairs(tracked) do
                if idx == 1 then first = internalName; break end
            end
            if first then
                Addon.options:SetCharacter("scale", first)
            end
        end
    end

    -- Scale set and row set are now stable.
    --  1. Refresh top-filter dropdown options now that Pawn has reported
    --     enabled scales.
    --  2. Hydrate displayed scale picks from persisted per-character
    --     settings (validated against scaleOrder).
    --  3. Recompute fluid column widths from actual row content.
    --  4. Force a relayout (lastScaleCount = nil) so the new widths
    --     apply to headers and row cells.
    --  5. Refresh slot tabs and redraw.
    if panel.refreshScaleOptions then panel.refreshScaleOptions() end
    initializeDisplayedScales()
    applyTableLayout()
    recomputeColWidths()
    lastScaleCount = nil    -- force relayoutColumns on next redraw
    refreshSlotTabs()
    panel:redraw()
end

local function onEvalCancelled()
    enableScanButton()
    setStatus("Eval cancelled.")
end

local function onDisplaySettingChanged()
    -- Sort column/direction or heatmap thresholds may have changed via
    -- options API. Re-sort rows, rebuild the tab strip (pill colors
    -- depend on thresholds), and redraw.
    local rows = eval:getRows()
    sort:apply(rows, options:Get("sortColumn"), options:Get("sortDir"),
        function(n) return eval:scaleAtIndex(n) end)
    refreshSlotTabs()
    panel:updateSortIndicators()
    panel:redraw()
end

local function onFilterSettingChanged(_, payload)
    -- Filter scale, companion, level tolerance, or min upgrade % changed.
    -- Re-pull displayedScales[] from settings (scale + companionScale),
    -- rebuild slot tabs (counts depend on filter membership), and
    -- redraw. Side-panel "Reset" emits this with name = "*reset*";
    -- a single Set emits with name = the actual key.
    initializeDisplayedScales()
    -- Force a relayout next redraw in case the displayed-column count
    -- changed (e.g. companion went on or off).
    lastScaleCount = nil
    refreshSlotTabs()
    panel:redraw()
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function panel:initialize()
    utils           = Addon.utils
    events          = Addon.events
    options         = Addon.options
    constants       = Addon.constants
    filterTabStrip  = Addon.filterTabStrip
    dropdown        = Addon.dropdown

    eval                   = Addon.eval
    scan                   = Addon.scan
    sort                   = Addon.sort
    auctionatorIntegration = Addon.auctionatorIntegration

    if not utils or not events or not options or not constants
       or not filterTabStrip or not dropdown
       or not eval or not scan or not sort or not auctionatorIntegration then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444panel: Missing dependencies|r")
        return false
    end

    events:subscribe("SCAN:STARTED",           onScanStarted)
    events:subscribe("SCAN:AUCTIONS_INGESTED", onScanIngested)
    events:subscribe("SCAN:EMPTY",             onScanEmpty)
    events:subscribe("SCAN:CANCELLED",         onScanCancelled)

    events:subscribe("EVAL:STARTED",           onEvalStarted)
    events:subscribe("EVAL:ROWS_CHANGED",      onEvalRowsChanged)
    events:subscribe("EVAL:COMPLETE",          onEvalComplete)
    events:subscribe("EVAL:CANCELLED",         onEvalCancelled)

    events:subscribe("SETTING:DISPLAY_CHANGED", onDisplaySettingChanged)
    events:subscribe("SETTING:FILTER_CHANGED",  onFilterSettingChanged)

    -- Header widget events (from /shared/header.lua). Forward to our
    -- existing sort/filter handling.
    events:subscribe("HEADER:SORT_CHANGED", function(payload)
        if not payload or not payload.columnKey then return end
        options:SetCharacter("sortColumn", payload.columnKey)
        options:SetCharacter("sortDir",    payload.direction)
        local rows = eval:getRows()
        sort:apply(rows, payload.columnKey, payload.direction,
            function(n) return eval:scaleAtIndex(n) end)
        panel:updateSortIndicators()
        panel:redraw()
    end)

    events:subscribe("HEADER:FILTER_CHANGED", function(payload)
        if not payload or not payload.columnKey then return end
        -- Both supported header filters live in the FILTER category;
        -- options:SetCharacter in filterCommit fires SETTING:FILTER_CHANGED
        -- which already triggers refreshSlotTabs + redraw via
        -- onFilterSettingChanged. Nothing more to do here.
    end)

    return true
end

if Addon.registerModule then
    Addon.registerModule("panel", {
        "utils", "events", "options", "constants", "filterTabStrip", "dropdown",
        "eval", "scan", "sort", "auctionatorIntegration", "pawnIntegration",
        "header", "textBox",
    }, function()
        return panel:initialize()
    end)
end

Addon.panel = panel
return panel
