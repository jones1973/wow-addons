--[[
  ui/itemAddPanel.lua
  Item-first batch entry creation panel

  An alternative to the per-entry edit panel: the user types item
  keywords ("recipe", "pattern", "tome"), picks one or more items
  from the typeahead, and the panel stages every NPC in the game
  that drops those items. The user reviews the staged list, unchecks
  any NPCs they don't plan to kill, and commits a batch of watch-list
  entries in one click.

  Layout (top to bottom):
    - Title
    - Search field (item-name substring, MIN_QUERY_LEN = 3)
    - Chips strip (wraps; each chip = a picked item with X to remove)
    - Staging area (scrolling list; checkbox + NPC name + zone + reason)
    - "Add N Entries" / "Cancel" buttons

  Picking flow:
    1. User types into search → typeahead shows up to 100 matching items.
    2. Picking a regular row adds that item to the picked-items list.
    3. Picking the "Add all N matches" row at top of the dropdown adds
       every visible result to the picked-items list.
    4. Each pick recomputes the staged NPC list (via itemDropIndex's
       resolveStaging), then re-renders the staging area.

  Per-NPC opt-out:
    Unchecking a row in the staging area adds (name, zone) to a session
    opt-out set. Re-checking removes it. Across picks/removes, the
    opt-out set persists: if you uncheck Boss X for item A, picking
    item B that also stages Boss X leaves it unchecked.

  Conflict handling:
    NPCs already in the watch list (matched by name+zone) get an
    "(existing)" suffix in the row. If user keeps them checked, on
    commit their reason is replaced with the new concatenated reason.
    If user unchecks, the existing entry is left alone.

  Public API:
    itemAddPanel:initialize()
    itemAddPanel:open(parent)
    itemAddPanel:close()
    itemAddPanel:isOpen()

  Dependencies: panel, textBox, searchBox, typeaheadPicker, pool,
                itemDropIndex
  Exports: Addon.itemAddPanel
]]

local ADDON_NAME, Addon = ...

local itemAddPanel = {}

-- ============================================================================
-- FILE-LOCAL CONSTANTS
-- ============================================================================

local PANEL_W           = 360
local PANEL_H           = 570    -- 50px taller for filter strip
local PANEL_PAD         = 16

local TITLE_TOP_Y       = -18
local SEARCH_LBL_Y      = -56
local LABEL_HEIGHT      = 18
local LABEL_GAP         = 4
local INPUT_H           = 24

-- Filter strip below the search input. Two rows: checkbox row, then
-- expansion dropdown row. Sized to fit comfortably without crowding
-- the search input above or chips below.
local FILTER_TOP_GAP    = 8
local FILTER_ROW_H      = 22
local FILTER_GAP        = 16     -- horizontal gap between filter controls
local FILTER_DROPDOWN_W = 100
local FILTER_STRIP_H    = FILTER_ROW_H * 2 + 4   -- two rows of ~22px

local CHIPS_TOP_GAP     = 8
local CHIPS_AREA_H      = 56     -- vertical space allocated for chip flow
local CHIP_H            = 20
local CHIP_PAD_X        = 8
local CHIP_GAP          = 6
local CHIP_MAX_TEXT     = 22     -- chars before truncation + ellipsis

local STAGING_TOP_GAP   = 10
local STAGING_BOTTOM    = 60     -- room for action buttons + margin
local STAGE_ROW_H       = 52     -- name + zone + reason
local STAGE_TEXT_INSET  = 6
local CHECKBOX_W        = 24

local BTN_W             = 80
local BTN_H             = 22
local BTN_BOTTOM_Y      = 16
local BTN_GAP           = 8

local SEARCH_MAX_LETTERS = 60
local TYPEAHEAD_MAX      = 100
local TYPEAHEAD_DEBOUNCE = 0.2
local TYPEAHEAD_MIN_LEN  = 3
local TYPEAHEAD_ROWS_VIS = 7
local TYPEAHEAD_ROW_H    = 24

local ANIM_DURATION     = 0.2

-- Panel uses the standard SURFACE.PANEL_BASE chrome.

local SCROLL_FRAME_NAME = ADDON_NAME .. "ItemAddSearchScroll"
local STAGING_SCROLL_NAME = ADDON_NAME .. "ItemAddStagingScroll"

-- ============================================================================
-- STATE
-- ============================================================================

local panelFrame
local panelController
local controllerParent

local searchBox
local titleFS
local addBtn
local chipsContainer
local stagingLV       -- listView instance for the staging list

local searchPicker

-- Filter strip widgets; populated in buildFrame. Held in module scope
-- so refreshFilterControls can re-read state from saved-variables
-- after open() reads the latest filter values.
local hideOwnedLT       -- labeledToggle: "Hide owned"
local hideKnownLT       -- labeledToggle: "Hide known recipes"
local expansionDD       -- dropdown: expansion multi-select (may be nil
                        -- when ItemVersion absent)

-- ============================================================================
-- STATE — inputs only. No derived data lives here.
-- ============================================================================
--
-- Two fields; everything else is computed on demand. The "is picked?"
-- lookup is a linear scan over pickedOrder rather than a parallel set,
-- since real-world pick counts are small (typically 1-22) and keeping
-- two representations in sync invited drift bugs.

local pickedOrder = {}   -- ordered itemIds
local optedOut    = {}   -- {[name|zone] = true}  per-NPC opt-out

-- Filter state is read from mobster_settings.filters (account-wide
-- preference). Bootstrapped in getFilters() to defaults if absent.

-- ============================================================================
-- HELPERS
-- ============================================================================

local function truncate(text, maxLen)
    if not text or #text <= maxLen then return text end
    return text:sub(1, maxLen - 1) .. "..."
end

local function stagedEntryKey(entry)
    return (entry.name or "") .. "|" .. (entry.zone or "")
end

--[[
  Read the current watch list. Returns the array stored in the
  saved-variable, or an empty list if no save exists yet.
]]
local function getCurrentWatchList()
    local sv = _G.mobster_character
    if not sv or not sv.watchList then return {} end
    return sv.watchList
end

-- ============================================================================
-- FILTERS — state, defaults, and the filter pipeline.
-- ============================================================================
--
-- Filter state lives on mobster_settings.filters (account-wide). The
-- toggle states ("hide things I already have") are a player
-- preference; the data those filters consult (GetItemCount, spell
-- book) is character-specific, but the preference itself travels
-- with the player.
--
-- Defaults: hide-known ON, hide-owned ON, expansions = current only.
-- These reflect the most useful starting state for finding items the
-- user doesn't already have access to.

local function getFilters()
    local sv = _G.mobster_settings
    if not sv then return nil end
    if not sv.filters then
        sv.filters = {
            hideKnownRecipes = true,
            hideOwnedItems   = true,
            -- expansions: nil → resolves to current-only at filter time.
            -- An explicit table is the active set keyed by major number.
            expansions       = nil,
        }
    end
    return sv.filters
end

--[[
  Return the active expansion set as a {[major]=true} table. nil
  filters.expansions means "current expansion only." If ItemVersion
  isn't available, returns nil (filter is a no-op since we can't
  classify items by expansion anyway).
]]
local function getEffectiveExpansions()
    if not Addon.expansion.isAvailable() then return nil end
    local f = getFilters()
    if not f then return nil end
    if f.expansions then return f.expansions end
    return { [Addon.expansion.getCurrentMajor()] = true }
end

--[[
  Apply all active filters to a list of itemIds. Returns the filtered
  list. Each pass is conditional on the relevant filter being ON;
  pipeline order is cheap-first (no-op early outs for off filters).
]]
local function applyFilters(itemIds)
    if #itemIds == 0 then return itemIds end
    local f = getFilters()
    if not f then return itemIds end

    -- Pass 1: hide owned. Live GetItemCount per id. Cheap (bag lookup).
    if f.hideOwnedItems then
        local kept = {}
        for i = 1, #itemIds do
            local id = itemIds[i]
            if (GetItemCount(id, true) or 0) <= 0 then
                kept[#kept + 1] = id
            end
        end
        itemIds = kept
    end

    -- Pass 2: hide known recipes. Only recipe-style items (those that
    -- teach a spell) have a cached spellId; non-recipes pass through.
    if f.hideKnownRecipes then
        local kept = {}
        for i = 1, #itemIds do
            local id = itemIds[i]
            local spellId = Addon.itemDropIndex:teachesSpell(id)
            if not spellId or not IsSpellKnown(spellId) then
                kept[#kept + 1] = id
            end
        end
        itemIds = kept
    end

    -- Pass 3: expansion filter. Requires ItemVersion; if absent,
    -- getEffectiveExpansions returns nil and we skip.
    local activeExp = getEffectiveExpansions()
    if activeExp then
        local kept = {}
        for i = 1, #itemIds do
            local id = itemIds[i]
            local major = Addon.expansion.getMajorForItem(id)
            -- Items ItemVersion can't classify pass through. Better
            -- to show an unclassifiable item than hide it spuriously.
            if (not major) or activeExp[major] then
                kept[#kept + 1] = id
            end
        end
        itemIds = kept
    end

    return itemIds
end

-- Mutations: each takes a value, writes through to saved-vars, and
-- triggers a re-query so the visible results match the new filter
-- state immediately. The re-query is wired in initialize() once
-- searchPicker exists.
--
-- reissueQuery only re-fetches when the dropdown is currently shown.
-- Toggling a filter is "adjust how my next search behaves," not
-- "trigger a search now" — opening the dropdown on filter toggle
-- would be surprising and intrusive. If the user has search text in
-- the box but the dropdown is dismissed (e.g., they clicked elsewhere
-- to inspect the panel), they'll re-engage the search themselves.

local function reissueQuery()
    if not searchPicker or not searchBox then return end
    if not searchPicker:isShown() then return end
    searchPicker:onQuery(searchBox:GetText())
end

local function setHideOwned(value)
    local f = getFilters(); if not f then return end
    f.hideOwnedItems = value and true or false
    reissueQuery()
end

local function setHideKnown(value)
    local f = getFilters(); if not f then return end
    f.hideKnownRecipes = value and true or false
    reissueQuery()
end

local function setExpansions(set)
    local f = getFilters(); if not f then return end
    -- Empty set is meaningful (filter everything out); nil is reset
    -- to "current only" default. Callers pass an explicit table to set
    -- a specific configuration; pass nil to revert to default.
    f.expansions = set
    reissueQuery()
end

-- ============================================================================
-- DERIVE — pure functions of state.
-- ============================================================================

local function isPicked(itemId)
    for i = 1, #pickedOrder do
        if pickedOrder[i] == itemId then return true end
    end
    return false
end

local function getStagedEntries()
    return Addon.itemDropIndex:resolveStaging(
        pickedOrder, getCurrentWatchList())
end

local function countChecked(staged)
    local n = 0
    for i = 1, #staged do
        if not optedOut[stagedEntryKey(staged[i])] then n = n + 1 end
    end
    return n
end

-- ============================================================================
-- MUTATE — one entry point per state field. No rendering here.
-- ============================================================================

local function pickItem(itemId)
    if isPicked(itemId) then return end
    pickedOrder[#pickedOrder + 1] = itemId
end

local function unpickItem(itemId)
    for i = 1, #pickedOrder do
        if pickedOrder[i] == itemId then
            table.remove(pickedOrder, i)
            return
        end
    end
end

local function toggleOptOut(key)
    -- nil ↔ true; explicit so the table doesn't accumulate `false`s.
    if optedOut[key] then
        optedOut[key] = nil
    else
        optedOut[key] = true
    end
end

local function resetSession()
    pickedOrder = {}
    optedOut    = {}
end

-- ============================================================================
-- RENDER — entry points called by mutation sites.
-- ============================================================================
--
-- Two tiers:
--   renderAll()       — after picks/unpicks: chips, staging, button all change.
--   refreshCounts()   — after opt-out toggle: only the Add button caption.
--                       Avoiding a listView refresh here keeps Blizzard's
--                       CheckButton template visually stable (no flicker)
--                       and preserves the row the user just clicked.

-- Forward declarations: chip close handler and stage-row click
-- handler reference renderAll/refreshCounts as upvalues. They're
-- invoked at click time, by which point both are bound.
local renderAll
local refreshCounts
local renderChips
local refreshAddButton

-- ============================================================================
-- CHIPS STRIP
-- ============================================================================

local chipPool

local function chipFactory(parent)
    local chip = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    chip:SetHeight(CHIP_H)
    chip:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    local chipBg = Addon.theme.tokens.SURFACE.PANEL_RAISED
    chip:SetBackdropColor(chipBg.r, chipBg.g, chipBg.b, chipBg.a)

    local label = chip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", CHIP_PAD_X, 0)
    chip.label = label

    local closeBtn = CreateFrame("Button", nil, chip)
    closeBtn:SetSize(14, 14)
    closeBtn:SetPoint("RIGHT", -4, 0)
    local xfs = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    xfs:SetPoint("CENTER")
    xfs:SetText("×")
    closeBtn.xfs = xfs
    chip.closeBtn = closeBtn

    -- Click handler installed once. Reads chip._itemId set by render.
    closeBtn:SetScript("OnClick", function()
        if not chip._itemId then return end
        unpickItem(chip._itemId)
        renderAll()
    end)

    -- Tooltip on hover shows the full (untruncated) item name.
    chip:SetScript("OnEnter", function(self)
        if not self._fullText or self._fullText == self.label:GetText() then return end
        Addon.tooltip:showSimple(self, self._fullText, { anchor = "above" })
    end)
    chip:SetScript("OnLeave", function() Addon.tooltip:hide() end)

    return chip
end

renderChips = function()
    if not chipsContainer then return end
    if not chipPool then
        chipPool = Addon.pool:new(function() return chipFactory(chipsContainer) end)
    end
    chipPool:releaseAll()

    -- Layout: left-to-right wrapping, top-aligned. Each chip's width
    -- = label-width + padding + X button width.
    local x, y = 0, 0
    local rowHeight = CHIP_H + 4  -- small inter-row gap
    local maxX = chipsContainer:GetWidth()

    for _, itemId in ipairs(pickedOrder) do
        local fullName = Addon.itemDropIndex:itemName(itemId) or ("#" .. itemId)
        local displayName = truncate(fullName, CHIP_MAX_TEXT)

        local chip = chipPool:acquire()
        chip._itemId  = itemId      -- read by the close handler
        chip._fullText = fullName
        chip.label:SetText(displayName)

        -- Size chip to fit its label + close button. Label's
        -- string width depends on the font; use label:GetStringWidth.
        local labelW = chip.label:GetStringWidth()
        local chipW = labelW + CHIP_PAD_X * 2 + 14 + 4
        chip:SetWidth(chipW)

        -- Wrap if this chip would overflow the current line.
        if x + chipW > maxX and x > 0 then
            x = 0
            y = y - rowHeight
        end

        chip:ClearAllPoints()
        chip:SetPoint("TOPLEFT", x, y)
        chip:Show()

        x = x + chipW + CHIP_GAP
    end
end

-- ============================================================================
-- STAGING ROWS
-- ============================================================================

--[[
  Staging row factory and render — invoked by listView via the
  `kinds.row` spec wired up in buildFrame. Identity for each staging
  row is its stagedEntryKey ("name|zone"), which is stable across
  refreshes because the source data is reconstructed from picks each
  time and the same NPC dropped by the same item resolves to the
  same name+zone tuple.

  Toggle UX. Both row-body click and checkbox click flip the entry's
  opt-out state. Row-body click goes through listView's onClick →
  the consumer hook in buildFrame, which calls toggleOptOut and
  refreshes. Checkbox click stays direct (the CheckButton is a child
  frame; listView's row click wiring on the parent doesn't intercept
  it).
]]

local function stageRowFactory(parent)
    local row = CreateFrame("Button", nil, parent)
    -- Height set by listView from spec.height.

    -- Hover wash. Uses the family-standard SURFACE.ROW_HOVER token.
    -- Cursor traversal from row body onto the checkbox normally fires
    -- the row's OnLeave (mouse focus stack: entering a child counts
    -- as leaving the parent); re-show on cb:OnEnter so the row reads
    -- as continuously hovered.
    local hover = row:CreateTexture(nil, "BACKGROUND")
    hover:SetAllPoints()
    do
        local h = Addon.theme.tokens.SURFACE.ROW_HOVER
        hover:SetColorTexture(h.r, h.g, h.b, h.a)
    end
    hover:Hide()
    row._hover = hover

    -- Checkbox on the left
    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(20, 20)
    cb:SetPoint("LEFT", 2, 0)
    row.cb = cb

    -- Name + zone + reason, three-line stack at top
    local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameFS:SetPoint("TOPLEFT", CHECKBOX_W + STAGE_TEXT_INSET, -STAGE_TEXT_INSET)
    nameFS:SetPoint("TOPRIGHT", -STAGE_TEXT_INSET, -STAGE_TEXT_INSET)
    nameFS:SetJustifyH("LEFT")
    nameFS:SetWordWrap(false)
    row.nameFS = nameFS

    local zoneFS = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    zoneFS:SetPoint("TOPLEFT", nameFS, "BOTTOMLEFT", 0, -2)
    zoneFS:SetPoint("TOPRIGHT", nameFS, "BOTTOMRIGHT", 0, -2)
    zoneFS:SetJustifyH("LEFT")
    zoneFS:SetWordWrap(false)
    row.zoneFS = zoneFS

    local reasonFS = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    reasonFS:SetPoint("TOPLEFT", zoneFS, "BOTTOMLEFT", 0, -2)
    reasonFS:SetPoint("TOPRIGHT", zoneFS, "BOTTOMRIGHT", 0, -2)
    reasonFS:SetJustifyH("LEFT")
    reasonFS:SetWordWrap(false)
    row.reasonFS = reasonFS

    -- Overflow tooltip: shows full reason on hover when clipped.
    Mixin(row, Addon.overflowTooltipMixin)
    row:InitOverflowTooltip()

    -- Hover wash. HookScript so it coexists with the mixin's OnEnter/
    -- OnLeave (the mixin handles the truncated-text tooltip).
    row:HookScript("OnEnter", function() row._hover:Show() end)
    row:HookScript("OnLeave", function() row._hover:Hide() end)
    cb:HookScript("OnEnter",  function() row._hover:Show() end)

    -- Checkbox's own click handler. The row body's click is wired by
    -- listView and routes through the onClick handler in buildFrame.
    cb:SetScript("OnClick", function()
        if not row._stagedKey then return end
        toggleOptOut(row._stagedKey)
        refreshCounts()
    end)

    return row
end

local function stageRowRender(frame, entry)
    local existingMark = entry.isConflict
        and ("  " .. Addon.theme.derive.inline(
                Addon.theme.tokens.TEXT.EMPHASIS_SOFT, "(existing)"))
        or ""
    frame.nameFS:SetText(entry.name .. existingMark)
    frame.zoneFS:SetText(entry.zone and ("(" .. entry.zone .. ")") or "(no zone)")
    frame:SetOverflowText(frame.reasonFS, entry.reason or "")

    local key = stagedEntryKey(entry)
    frame._stagedKey = key                          -- read by cb's OnClick
    frame.cb:SetChecked(not optedOut[key])
end

-- ============================================================================
-- SEARCH TYPEAHEAD
-- ============================================================================
--
-- The picker emits two kinds:
--   "addAll" — single special row at top when there are matches,
--              labeled "Add all N matches". Picking it stages every
--              currently-matching item.
--   "row"    — one per matching item. Picking it stages that item.

local function buildSearchResults(text)
    local ids = Addon.itemDropIndex:searchItems(text)
    ids = applyFilters(ids)
    if #ids == 0 then return {} end

    -- Warm the quality cache for the visible set. GetItemInfo for a
    -- cached item resolves synchronously; misses trigger fetches
    -- that the GET_ITEM_INFO_RECEIVED backfill will pick up, firing
    -- "MOBSTER:QUALITY_RESOLVED" — re-render handled below.
    Addon.itemDropIndex:prefetchQualitiesFor(ids)

    local results = {}
    -- The "Add all" row carries the full id list so the pick handler
    -- can use it without re-querying.
    results[#results + 1] = {
        kind = "addAll",
        data = { itemIds = ids, count = #ids },
    }
    for _, itemId in ipairs(ids) do
        results[#results + 1] = {
            kind = "row",
            data = {
                itemId   = itemId,
                itemName = Addon.itemDropIndex:itemName(itemId),
                quality  = Addon.itemDropIndex:itemQuality(itemId),
            },
        }
    end
    return results
end

-- refreshAddButton takes the count as argument — pure view function,
-- no hidden globals. Width auto-fits the caption so 3-digit counts
-- ("Add 999 Entries") don't crowd the edges.
function refreshAddButton(n)
    if not addBtn then return end
    local text
    if n == 0 then
        text = "Add"
        addBtn:Disable()
    elseif n == 1 then
        text = "Add 1 Entry"
        addBtn:Enable()
    else
        text = "Add " .. n .. " Entries"
        addBtn:Enable()
    end
    addBtn:SetText(text)

    -- Size to text + horizontal padding. UIPanelButtonTemplate's font
    -- string is the button's whole-area label; add 24px (~12 each side)
    -- of breathing room around it. Floor at BTN_W so the "Add"
    -- single-word case doesn't get tiny.
    local fs = addBtn:GetFontString()
    if fs then
        addBtn:SetWidth(math.max(BTN_W, fs:GetStringWidth() + 24))
    end
end

-- Render orchestration. renderAll is the full re-render after a pick
-- mutation; refreshCounts is the cheap update after an opt-out toggle.
function renderAll()
    local staged = getStagedEntries()
    renderChips()
    if stagingLV then stagingLV:refresh() end
    refreshAddButton(countChecked(staged))
end

function refreshCounts()
    refreshAddButton(countChecked(getStagedEntries()))
end

-- ============================================================================
-- PANEL CHROME
-- ============================================================================
--
-- Session-lifecycle policy:
--   * open()   — does NOT reset state. State persists across mode-switch
--                close (e.g., user clicks "Add by NPC" mid-flow, then
--                comes back). The watch-list window's own lifecycle is
--                the implicit boundary.
--   * close()  — just hides; preserves state for mode-switch return.
--   * Cancel   — explicit abandonment: resets, then closes.
--   * Add      — explicit commit: writes entries, resets, then closes.

local function doCancel()
    resetSession()
    if searchBox then searchBox:SetBoxText("") end
    itemAddPanel:close()
end

local function doAdd()
    local sv = _G.mobster_character
    if not sv then return end
    sv.watchList = sv.watchList or {}

    -- Build a (name|zone) → index map of existing entries so we can
    -- replace in-place rather than appending duplicates.
    local existingIndex = {}
    for i, e in ipairs(sv.watchList) do
        existingIndex[(e.name or "") .. "|" .. (e.zone or "")] = i
    end

    for _, entry in ipairs(getStagedEntries()) do
        local key = stagedEntryKey(entry)
        if not optedOut[key] then
            local idx = existingIndex[key]
            if idx then
                -- Mutate existing entry in place to preserve its _id.
                local existing = sv.watchList[idx]
                existing.name          = entry.name
                existing.zone          = entry.zone
                existing.reason        = entry.reason
                existing.sourceItemIds = entry.sourceItemIds
            else
                local newRow = Addon.newEntry({
                    name          = entry.name,
                    zone          = entry.zone,
                    reason        = entry.reason,
                    sourceItemIds = entry.sourceItemIds,
                })
                table.insert(sv.watchList, newRow)
                existingIndex[key] = #sv.watchList
            end
        end
    end

    if Addon.watchList and Addon.watchList.refresh then
        Addon.watchList:refresh()
    end

    resetSession()
    if searchBox then searchBox:SetBoxText("") end
    itemAddPanel:close()
end

local function buildFrame()
    local s = Addon.theme.tokens.SURFACE.PANEL_BASE
    panelFrame = Addon.panel:opaque(UIParent, {
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 32,
        insets   = { left = 11, right = 12, top = 12, bottom = 11 },
        r = s.r, g = s.g, b = s.b, a = s.a,
    })
    panelFrame:SetSize(PANEL_W, PANEL_H)
    panelFrame:SetFrameStrata("DIALOG")
    panelFrame:EnableMouse(true)
    panelFrame:Hide()

    -- Title
    titleFS = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFS:SetPoint("TOP", 0, TITLE_TOP_Y)
    titleFS:SetText("Add by Item Drop")

    -- Search field
    local searchLbl = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLbl:SetPoint("TOPLEFT", PANEL_PAD, SEARCH_LBL_Y)
    searchLbl:SetText("Search items")

    searchBox = Addon.searchBox:create({
        parent          = panelFrame,
        width           = PANEL_W - PANEL_PAD * 2,
        height          = INPUT_H,
        placeholder     = "recipe, pattern, tome...",
        maxLetters      = SEARCH_MAX_LETTERS,
        onTextChanged   = function(text, userInput)
            if userInput and searchPicker then
                searchPicker:onQuery(text)
            end
        end,
        -- searchBox's clear button bypasses onTextChanged (WoW's
        -- SetText doesn't fire OnTextChanged from script), so the
        -- picker would never learn the field is empty. Hide
        -- explicitly here.
        onClear = function()
            if searchPicker then searchPicker:hide() end
        end,
        onEnterPressed  = function() end,    -- handled by two-stage below
        onEscapePressed = function() end,    -- handled by two-stage below
    })
    searchBox:ClearAllPoints()
    searchBox:SetPoint("TOPLEFT", PANEL_PAD,
        SEARCH_LBL_Y - LABEL_HEIGHT - LABEL_GAP)

    -- Filter strip below the search input. Two rows:
    --   Row 1: hide-owned checkbox, hide-known-recipes checkbox
    --   Row 2: expansion dropdown (only when ItemVersion is loaded)
    --
    -- All filter controls share visible state — no popups, no hidden
    -- menus. Glancing at the panel shows exactly what's being filtered.
    local filterTop = SEARCH_LBL_Y - LABEL_HEIGHT - LABEL_GAP
                    - INPUT_H - FILTER_TOP_GAP
    local f = getFilters()

    hideOwnedLT = Addon.labeledToggle:create({
        parent   = panelFrame,
        style    = "checkbox",
        label    = "Hide owned",
        checked  = f and f.hideOwnedItems,
        onChange = setHideOwned,
    })
    hideOwnedLT.toggle:SetPoint("TOPLEFT", PANEL_PAD, filterTop)

    hideKnownLT = Addon.labeledToggle:create({
        parent   = panelFrame,
        style    = "checkbox",
        label    = "Hide known recipes",
        checked  = f and f.hideKnownRecipes,
        onChange = setHideKnown,
    })
    -- Place to the right of "Hide owned" with FILTER_GAP between the
    -- label of one and the toggle of the next.
    hideKnownLT.toggle:SetPoint("LEFT", hideOwnedLT.label, "RIGHT", FILTER_GAP, 0)

    -- Expansion dropdown sits on row 2. Only built when ItemVersion is
    -- loaded; without it there's nothing meaningful to choose from.
    if Addon.expansion.isAvailable() then
        local available = Addon.expansion.listAvailable()
        local options = {}
        local activeSet = getEffectiveExpansions() or {}
        local defaultValueArray = {}
        for _, exp in ipairs(available) do
            options[#options + 1] = {
                value = exp.major,
                text  = exp.shortName,
            }
            if activeSet[exp.major] then
                defaultValueArray[#defaultValueArray + 1] = exp.major
            end
        end

        expansionDD = Addon.dropdown:create({
            parent       = panelFrame,
            width        = FILTER_DROPDOWN_W,
            style        = "checkbox",
            options      = options,
            defaultValue = defaultValueArray,
            onChange     = function(currentValueArray)
                -- Convert array of selected majors back to a {[major]=true}
                -- set. An empty selection is meaningful (filter everything
                -- out) and distinct from nil (which would default to
                -- current-only) — pass the explicit set through.
                local set = {}
                for _, major in ipairs(currentValueArray) do
                    set[major] = true
                end
                setExpansions(set)
            end,
        })
        expansionDD:SetPoint("TOPLEFT", PANEL_PAD, filterTop - FILTER_ROW_H)
    end

    -- Chips container — fixed-height region below the filter strip.
    local chipsTop = filterTop - FILTER_STRIP_H - CHIPS_TOP_GAP
    chipsContainer = CreateFrame("Frame", nil, panelFrame)
    chipsContainer:SetPoint("TOPLEFT", PANEL_PAD, chipsTop)
    chipsContainer:SetPoint("TOPRIGHT", -PANEL_PAD, chipsTop)
    chipsContainer:SetHeight(CHIPS_AREA_H)

    -- Staging area: listView wraps scroll + content + pool + layout.
    -- Anchored TOPLEFT below the chips strip and sized to the
    -- remaining vertical space above the button row. Dimensions
    -- computed from layout constants rather than the live frame
    -- bounds — listView takes numeric width/height at create time.
    local stagingTop = chipsTop - CHIPS_AREA_H - STAGING_TOP_GAP
    local stagingW   = PANEL_W - PANEL_PAD * 2
    -- Height = vertical span from stagingTop (negative offset from
    -- panel TOPLEFT) down to STAGING_BOTTOM above the panel's bottom.
    local stagingH   = PANEL_H - (-stagingTop) - STAGING_BOTTOM

    stagingLV = Addon.listView:create({
        parent = panelFrame,
        width  = stagingW,
        height = stagingH,
        scrollFrameName = STAGING_SCROLL_NAME,

        -- Data comes from itemDropIndex's resolveStaging. Identity is
        -- the entry's stagedEntryKey (name|zone) — stable across
        -- refreshes since resolveStaging produces the same key for
        -- the same NPC across multiple pick recomputes.
        dataFn     = function() return getStagedEntries() end,
        identityFn = function(entry) return stagedEntryKey(entry) end,

        kinds = {
            row = {
                height  = STAGE_ROW_H,
                factory = stageRowFactory,
                render  = stageRowRender,
            },
        },

        -- Row-body click toggles opt-out. Checkbox-direct clicks go
        -- through the cb's own OnClick (installed in stageRowFactory)
        -- and don't reach this handler. Both paths converge on
        -- toggleOptOut + refreshCounts; the row-body path additionally
        -- refreshes so the checkbox visual flips on the next render.
        onClick = function(item)
            local key = stagedEntryKey(item)
            toggleOptOut(key)
            refreshCounts()
            stagingLV:refresh()
        end,
    })

    stagingLV:getFrame():SetPoint("TOPLEFT", PANEL_PAD, stagingTop)

    -- Buttons along the bottom edge: Add (with dynamic count) and
    -- Cancel. Same convention as edit panel: primary action LEFT of
    -- cancel, cancel rightmost.
    local cancelBtn = CreateFrame("Button", nil, panelFrame, "UIPanelButtonTemplate")
    cancelBtn:SetSize(BTN_W, BTN_H)
    cancelBtn:SetPoint("BOTTOMRIGHT", -PANEL_PAD, BTN_BOTTOM_Y)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", doCancel)

    addBtn = CreateFrame("Button", nil, panelFrame, "UIPanelButtonTemplate")
    addBtn:SetSize(BTN_W, BTN_H)        -- width updated dynamically by refreshAddButton
    addBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -BTN_GAP, 0)
    addBtn:SetText("Add")
    addBtn:SetScript("OnClick", doAdd)
    addBtn:Disable()

    -- Two-stage Escape on the search box: hide dropdown first,
    -- close panel on second press. Two-stage Enter: if a row is
    -- highlighted in the dropdown, pick it; if dropdown is up
    -- without a highlight, hide it; otherwise no-op (Add button
    -- is the commit action, not Enter on the search field).
    searchBox:SetScript("OnEscapePressed", function(self)
        if searchPicker and searchPicker:isShown() then
            searchPicker:hide()
        else
            doCancel()
        end
        self:ClearFocus()
    end)
    searchBox:SetScript("OnEnterPressed", function()
        if searchPicker and searchPicker:isShown() then
            if not searchPicker:commitHighlight() then
                searchPicker:hide()
            end
        end
    end)
    searchBox:SetScript("OnKeyDown", function(self, key)
        if not searchPicker or not searchPicker:isShown() then return end
        if key == "UP" then
            searchPicker:moveHighlight(-1)
            self:SetPropagateKeyboardInput(false)
        elseif key == "DOWN" then
            searchPicker:moveHighlight(1)
            self:SetPropagateKeyboardInput(false)
        end
    end)

    -- Click on empty panel area dismisses the search dropdown.
    panelFrame:SetScript("OnMouseDown", function()
        if searchPicker and searchPicker:isShown() then
            searchPicker:hide()
        end
    end)
end

local function ensureController(parent)
    if panelController and controllerParent == parent then return end
    if panelController then
        panelController:destroy()
        panelController = nil
    end
    panelController = panelFrame:withAnimation({
        anchor = {
            relativeTo    = parent,
            point         = "TOPLEFT",
            relativePoint = "TOPRIGHT",
            x = 0, y = 0,
        },
        transforms = {
            {
                type = "wipe",
                axis = "x",
                from = 0,
                to   = PANEL_W,
            },
        },
        clipsChildren = true,
        duration      = ANIM_DURATION,
    })
    controllerParent = parent
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function itemAddPanel:open(parent)
    if not panelFrame then return end

    -- State persists across mode-switch close. First open finds it
    -- empty (initial values); subsequent opens after Cancel or Add
    -- find it empty (those handlers resetSession explicitly); opens
    -- after mode-switch close find prior state and pick up where the
    -- user left off.
    renderAll()

    ensureController(parent)
    panelController:show()
end

function itemAddPanel:close()
    if not panelFrame then return end
    if searchPicker then searchPicker:hide() end
    if panelController then panelController:hide() end
end

function itemAddPanel:isOpen()
    if not panelController then return false end
    return panelController:isOpen()
end

function itemAddPanel:initialize()
    if not Addon.panel or not Addon.searchBox or not Addon.typeaheadPicker
       or not Addon.pool or not Addon.itemDropIndex
       or not Addon.labeledToggle or not Addon.dropdown
       or not Addon.expansion then
        Addon.theme.chat:alarm("itemAddPanel: missing dependencies")
        return false
    end

    buildFrame()

    -- Attach the typeahead picker to the search field. Two kinds:
    -- "addAll" (special row at top) and "row" (per-item).
    searchPicker = Addon.typeaheadPicker:create({
        runQuery = buildSearchResults,

        rows = {
            row = {
                pickable = true,
                height   = TYPEAHEAD_ROW_H,
                texts = {
                    { key = "fs", font = "GameFontHighlight",
                      points = {
                        { "TOPLEFT",   10, -5 },
                        { "TOPRIGHT", -10, -5 },
                      } },
                },
                overflowTooltip = true,
                render = function(row, item)
                    local name = item.data.itemName or ("#" .. (item.data.itemId or "?"))
                    row:SetOverflowText(row.fs, name)
                    -- Quality coloring: same pattern as reasonTypeahead.
                    -- Nil quality (item not yet resolved client-side) →
                    -- reset to white; the GET_ITEM_INFO_RECEIVED event
                    -- will trigger a re-render with the correct color.
                    local q = item.data.quality
                    local token = q and Addon.theme.derive.qualityFor(q)
                    if token then
                        row.fs:SetTextColor(token.r, token.g, token.b)
                    else
                        row.fs:SetTextColor(1, 1, 1)
                    end
                end,
            },
            addAll = {
                pickable = true,
                height   = TYPEAHEAD_ROW_H,
                texts = {
                    { key = "fs", font = "GameFontNormal",
                      points = {
                        { "TOPLEFT",   10, -5 },
                        { "TOPRIGHT", -10, -5 },
                      } },
                },
                render = function(row, item)
                    row.fs:SetText("Add all " .. item.data.count .. " matches")
                end,
            },
        },

        debounce        = TYPEAHEAD_DEBOUNCE,
        minQueryLen     = TYPEAHEAD_MIN_LEN,
        maxResults      = TYPEAHEAD_MAX + 1,   -- +1 for the addAll row
        visibleMaxRows  = TYPEAHEAD_ROWS_VIS,
        scrollFrameName = SCROLL_FRAME_NAME,

        -- Multi-pick mode: dropdown stays open and search text is
        -- preserved after each pick so the user can rapid-fire add
        -- several items matching the same query (e.g. type "design",
        -- pick three Designs without re-typing).
        hideOnPick = false,

        onPick = function(item)
            if item.kind == "addAll" then
                for _, itemId in ipairs(item.data.itemIds) do
                    pickItem(itemId)
                end
                -- After Add All, the user is unlikely to want more
                -- from the same query. Hide explicitly.
                searchPicker:hide()
            elseif item.kind == "row" then
                pickItem(item.data.itemId)
            end
            renderAll()
        end,
    })

    local dropdownWidth = PANEL_W - PANEL_PAD * 2
    searchPicker:attach(searchBox, UIParent, dropdownWidth,
        { growDownward = true })

    -- Late-arriving quality data: re-run the visible search query so
    -- rows pick up the new quality colors. Only acts when the
    -- dropdown is currently open; chips and other surfaces aren't
    -- affected here (chips don't render quality today).
    Addon.events:subscribe("MOBSTER:QUALITY_RESOLVED", function()
        if searchPicker and searchPicker:isShown() and searchBox then
            searchPicker:onQuery(searchBox:GetText() or "")
        end
    end)

    return true
end

Addon.itemAddPanel = itemAddPanel
return itemAddPanel
