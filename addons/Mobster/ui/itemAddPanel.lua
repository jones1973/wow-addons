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
local PANEL_H           = 520
local PANEL_PAD         = 16

local TITLE_TOP_Y       = -18
local SEARCH_LBL_Y      = -56
local LABEL_HEIGHT      = 18
local LABEL_GAP         = 4
local INPUT_H           = 24

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

-- Panel tint: dark amber. The edit panel stays dark/cool; this panel
-- gets a warm tint to mark it as a different operation at a glance.
-- All colors will be replaced when the theme module lands.
local TINT_R, TINT_G, TINT_B = 0.12, 0.08, 0.05

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
local stagingContainer
local stagingScroll
local stagingContent

local searchPicker

-- Picked items, in pick order. itemId → true map keeps O(1) lookup
-- for dedup; orderedIds preserves order for the chips strip render.
local pickedItemIds    = {}   -- {[itemId] = true}
local orderedPickedIds = {}   -- {itemId, ...}

-- Per-NPC opt-out, keyed by "name|zone" (zone may be empty string).
-- Persisted across pick/remove operations within a single panel
-- session; cleared on panel close.
local optedOut = {}

-- Staged entries computed from pickedItemIds via resolveStaging.
-- Re-derived on every pick/remove; re-rendered after each derive.
local stagedEntries = {}

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

-- Forward declarations for cross-referencing renderers
local renderChips
local renderStaging
local recomputeStaging

local function checkedCount()
    local n = 0
    for _, entry in ipairs(stagedEntries) do
        if not optedOut[stagedEntryKey(entry)] then n = n + 1 end
    end
    return n
end

local function refreshAddButton()
    if not addBtn then return end
    local n = checkedCount()
    if n == 0 then
        addBtn:SetText("Add")
        addBtn:Disable()
    elseif n == 1 then
        addBtn:SetText("Add 1 Entry")
        addBtn:Enable()
    else
        addBtn:SetText("Add " .. n .. " Entries")
        addBtn:Enable()
    end
end

-- ============================================================================
-- STAGING
-- ============================================================================

recomputeStaging = function()
    stagedEntries = Addon.itemDropIndex:resolveStaging(
        orderedPickedIds, getCurrentWatchList())
    renderStaging()
    refreshAddButton()
end

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
    chip:SetBackdropColor(0.18, 0.14, 0.10, 1.0)

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

    for _, itemId in ipairs(orderedPickedIds) do
        local fullName = Addon.itemDropIndex:itemName(itemId) or ("#" .. itemId)
        local displayName = truncate(fullName, CHIP_MAX_TEXT)

        local chip = chipPool:acquire()
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

        -- Wire close button: capture itemId for the click.
        chip.closeBtn:SetScript("OnClick", function()
            pickedItemIds[itemId] = nil
            -- Rebuild orderedPickedIds preserving order without this id.
            local newOrder = {}
            for _, id in ipairs(orderedPickedIds) do
                if id ~= itemId then newOrder[#newOrder + 1] = id end
            end
            orderedPickedIds = newOrder
            renderChips()
            recomputeStaging()
        end)

        x = x + chipW + CHIP_GAP
    end
end

-- ============================================================================
-- STAGING ROWS
-- ============================================================================

local stageRowPool

local function stageRowFactory(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(STAGE_ROW_H)

    -- Checkbox on the left
    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(20, 20)
    cb:SetPoint("LEFT", 2, 0)
    row.cb = cb

    -- Name + zone, two-line stack at top
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
    row:EnableMouse(true)
    Mixin(row, Addon.overflowTooltipMixin)
    row:InitOverflowTooltip()

    return row
end

renderStaging = function()
    if not stagingContent then return end
    if not stageRowPool then
        stageRowPool = Addon.pool:new(function() return stageRowFactory(stagingContent) end)
    end
    stageRowPool:releaseAll()

    if #stagedEntries == 0 then
        stagingContent:SetHeight(1)
        return
    end

    local y = 0

    for _, entry in ipairs(stagedEntries) do
        local row = stageRowPool:acquire()
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT",  0, y)
        row:SetPoint("TOPRIGHT", 0, y)

        row.nameFS:SetText(entry.name .. (entry.isConflict and "  |cffffd44e(existing)|r" or ""))
        row.zoneFS:SetText(entry.zone and ("(" .. entry.zone .. ")") or "(no zone)")

        row:SetOverflowText(row.reasonFS, entry.reason or "")

        -- Initial checked state from opt-out map. Wire onClick to
        -- toggle the opt-out membership (capture entry by closure).
        local key = stagedEntryKey(entry)
        row.cb:SetChecked(not optedOut[key])
        row.cb:SetScript("OnClick", function(self)
            if self:GetChecked() then
                optedOut[key] = nil
            else
                optedOut[key] = true
            end
            refreshAddButton()
        end)

        row:Show()
        y = y - STAGE_ROW_H
    end

    -- Scroll content height = total row stack height (positive).
    stagingContent:SetHeight(math.max(1, -y))
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
    local ids = Addon.itemDropIndex:searchItems(text, TYPEAHEAD_MAX)
    if #ids == 0 then return {} end

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
            data = { itemId = itemId, itemName = Addon.itemDropIndex:itemName(itemId) },
        }
    end
    return results
end

local function searchRowFactory(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(TYPEAHEAD_ROW_H)
    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fs:SetPoint("TOPLEFT", 10, -5)
    fs:SetPoint("TOPRIGHT", -10, -5)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    row.fs = fs

    Mixin(row, Addon.overflowTooltipMixin)
    row:InitOverflowTooltip()

    return row
end

local function searchRowRender(row, item)
    local name = item.data.itemName or ("#" .. (item.data.itemId or "?"))
    row:SetOverflowText(row.fs, name)
end

local function addAllRowFactory(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(TYPEAHEAD_ROW_H)
    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", 10, -5)
    fs:SetPoint("TOPRIGHT", -10, -5)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    row.fs = fs
    return row
end

local function addAllRowRender(row, item)
    row.fs:SetText("Add all " .. item.data.count .. " matches")
end

local function addPickedItem(itemId)
    if pickedItemIds[itemId] then return end
    pickedItemIds[itemId] = true
    orderedPickedIds[#orderedPickedIds + 1] = itemId
end

-- ============================================================================
-- PANEL CHROME
-- ============================================================================

local function doCancel()
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

    for _, entry in ipairs(stagedEntries) do
        local key = stagedEntryKey(entry)
        if not optedOut[key] then
            local newRow = {
                name   = entry.name,
                zone   = entry.zone,
                reason = entry.reason,
            }
            local idx = existingIndex[key]
            if idx then
                sv.watchList[idx] = newRow
            else
                table.insert(sv.watchList, newRow)
                existingIndex[key] = #sv.watchList
            end
        end
    end

    if Addon.watchList and Addon.watchList.refresh then
        Addon.watchList:refresh()
    end

    itemAddPanel:close()
end

local function buildFrame()
    panelFrame = Addon.panel:opaque(UIParent, {
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 32,
        insets   = { left = 11, right = 12, top = 12, bottom = 11 },
        r = TINT_R, g = TINT_G, b = TINT_B,
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

    -- Chips container — fixed-height region below the search field.
    local chipsTop = SEARCH_LBL_Y - LABEL_HEIGHT - LABEL_GAP
                  - INPUT_H - CHIPS_TOP_GAP
    chipsContainer = CreateFrame("Frame", nil, panelFrame)
    chipsContainer:SetPoint("TOPLEFT", PANEL_PAD, chipsTop)
    chipsContainer:SetPoint("TOPRIGHT", -PANEL_PAD, chipsTop)
    chipsContainer:SetHeight(CHIPS_AREA_H)

    -- Staging area: scroll frame + content frame inside.
    local stagingTop = chipsTop - CHIPS_AREA_H - STAGING_TOP_GAP
    stagingContainer = CreateFrame("Frame", nil, panelFrame)
    stagingContainer:SetPoint("TOPLEFT", PANEL_PAD, stagingTop)
    stagingContainer:SetPoint("BOTTOMRIGHT", -PANEL_PAD, STAGING_BOTTOM)

    stagingScroll = CreateFrame("ScrollFrame", STAGING_SCROLL_NAME,
        stagingContainer, "UIPanelScrollFrameTemplate")
    stagingScroll:SetPoint("TOPLEFT")
    stagingScroll:SetPoint("BOTTOMRIGHT", -22, 0)  -- room for scrollbar

    stagingContent = CreateFrame("Frame", nil, stagingScroll)
    stagingContent:SetSize(PANEL_W - PANEL_PAD * 2 - 22, 1)
    stagingScroll:SetScrollChild(stagingContent)

    -- Buttons along the bottom edge: Add (with dynamic count) and
    -- Cancel. Same convention as edit panel: primary action LEFT of
    -- cancel, cancel rightmost.
    local cancelBtn = CreateFrame("Button", nil, panelFrame, "UIPanelButtonTemplate")
    cancelBtn:SetSize(BTN_W, BTN_H)
    cancelBtn:SetPoint("BOTTOMRIGHT", -PANEL_PAD, BTN_BOTTOM_Y)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", doCancel)

    addBtn = CreateFrame("Button", nil, panelFrame, "UIPanelButtonTemplate")
    addBtn:SetSize(BTN_W + 20, BTN_H)   -- a touch wider for "Add N Entries"
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

    -- Reset session state. Each open is a clean slate.
    pickedItemIds    = {}
    orderedPickedIds = {}
    optedOut         = {}
    stagedEntries    = {}

    searchBox:SetBoxText("")
    renderChips()
    renderStaging()
    refreshAddButton()

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
       or not Addon.pool or not Addon.itemDropIndex then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444itemAddPanel: missing dependencies|r")
        return false
    end

    buildFrame()

    -- Attach the typeahead picker to the search field. Two kinds:
    -- "addAll" (special row at top) and "row" (per-item).
    searchPicker = Addon.typeaheadPicker:create({
        runQuery = buildSearchResults,

        factories = {
            addAll = addAllRowFactory,
            row    = searchRowFactory,
        },
        renderers = {
            addAll = addAllRowRender,
            row    = searchRowRender,
        },
        heights = {
            addAll = TYPEAHEAD_ROW_H,
            row    = TYPEAHEAD_ROW_H,
        },

        -- Both kinds are clickable. The addAll row triggers batch
        -- staging of every match; the row entries trigger single
        -- item staging.
        pickableKinds = {
            addAll = true,
            row    = true,
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
                    addPickedItem(itemId)
                end
                -- After Add All, the user is unlikely to want more
                -- from the same query. Hide explicitly.
                searchPicker:hide()
            elseif item.kind == "row" then
                addPickedItem(item.data.itemId)
            end
            renderChips()
            recomputeStaging()
        end,
    })

    local dropdownWidth = PANEL_W - PANEL_PAD * 2
    searchPicker:attach(searchBox, UIParent, dropdownWidth,
        { growDownward = true, strata = "DIALOG" })

    return true
end

Addon.itemAddPanel = itemAddPanel
return itemAddPanel
