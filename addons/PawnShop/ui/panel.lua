--[[
  ui/panel.lua
  Pawn Shop Panel - The Grid

  The main UI hosted inside the AuctionFrame. Renders a scrollable list of
  upgrade rows grouped by equip slot, with per-scale percent columns.

  Owns: the panel Frame, the row frame pool, column header state, slot
  collapse state. Everything else is consumed via event subscriptions and
  getter calls on eval/scan.

  Event subscriptions:
    SCAN:STARTED              -> disable scan button, status "Waiting..."
    SCAN:AUCTIONS_INGESTED    -> status "Scan done: N. Starting eval..."
    SCAN:EMPTY                -> status "Scan returned 0 items", re-enable button
    SCAN:CANCELLED            -> re-enable scan button
    EVAL:STARTED              -> status "Eval: N items"
    EVAL:PROGRESS             -> (future progress indicator)
    EVAL:ROWS_CHANGED         -> redraw
    EVAL:COMPLETE             -> status "Done. N items", re-enable button
    EVAL:CANCELLED            -> re-enable scan button
    SETTING:DISPLAY_CHANGED   -> redraw (sort column/direction may have changed)

  NOTE: per-slot tabs inside the panel are planned but not yet implemented.
  This file preserves the existing collapsible-slot-header UI as-is for
  parity with AHUpgrades. The tab-based redesign is a separate pass.

  Dependencies: utils, events, options, constants
  Exports: Addon.panel
]]

local ADDON_NAME, Addon = ...

local panel = {}

-- Module references
local utils, events, options, constants
local eval, scan, sort, auctionatorIntegration

-- Frames and child widget references (populated in createPanel).
local panelFrame, scanButton, evalCachedButton, statusLabel
local headerFrame, headerItem, headerLvl, headerBuyout, headerTime
local scaleHeaders = {}
local listFrame, scrollFrame, rowFrames = nil, nil, {}
local scrollbarGutter = 22
local lastScaleCount = nil

-- Session-only slot collapse state. Will be removed when we switch to
-- per-slot tabs; keeping for parity with AHUpgrades for now.
local collapsedSlots = {}

-- ============================================================================
-- FORMATTERS
-- ============================================================================

local TIME_LEFT_TEXT = { [1] = "<30m", [2] = "<2h", [3] = "<12h", [4] = "<48h" }
local function formatTimeLeft(t) return TIME_LEFT_TEXT[t] or "?" end

--[[
  Copper -> colored money string. "-- " when zero.
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
  Scale cell: "+12%" green, empty when nil/non-positive.
  @param pct number|nil
  @return string
]]
local function formatScalePercent(pct)
    if not pct or pct <= 0 then return "" end
    return string.format("|cff40ff40+%.0f%%|r", pct)
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
  Plain click: echo link to chat.
]]
local function nameBtnOnClick(self)
    if IsControlKeyDown() then
        auctionatorIntegration:sendNames(collectNames(self))
    elseif self.link and ChatEdit_InsertLink and IsShiftKeyDown() then
        ChatEdit_InsertLink(self.link)
    elseif self.link then
        DEFAULT_CHAT_FRAME:AddMessage(self.link)
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
-- SORT CYCLE (user clicked a column header)
-- ============================================================================

local function cycleSort(columnKey)
    local curCol = options:Get("sortColumn")
    local curDir = options:Get("sortDir") or "asc"
    local newCol, newDir = sort:cycle(curCol, curDir, columnKey)
    options:Set("sortColumn", newCol)
    options:Set("sortDir",    newDir)

    -- Re-apply sort to eval's rows (eval owns them; sort mutates in place).
    local rows = eval:getRows()
    sort:apply(rows, newCol, newDir, function(n) return eval:scaleAtIndex(n) end)

    panel:updateSortIndicators()
    panel:redraw()
end

--[[
  Update header text to show a direction indicator on the active sort
  column. Uses ASCII caret/v (no Unicode glyphs).
]]
function panel:updateSortIndicators()
    local curCol = options:Get("sortColumn")
    local curDir = options:Get("sortDir") or "asc"
    local indicator = (curDir == "asc") and " ^" or " v"
    local function set(btn, base, columnKey)
        if not btn or not btn.text then return end
        if curCol == columnKey then
            btn.text:SetText(base .. indicator)
        else
            btn.text:SetText(base)
        end
    end
    set(headerItem,   "Item",   "name")
    set(headerLvl,    "Lvl",    "lvl")
    set(headerBuyout, "Buyout", "buyout")
    set(headerTime,   "Time",   "time")
    for _, btn in ipairs(scaleHeaders) do
        set(btn, "Scale " .. (btn.scaleIndex or "?"), btn.columnKey)
    end
end

-- ============================================================================
-- PANEL CREATION
-- ============================================================================

local function createPanel()
    if panelFrame then return end

    panelFrame = CreateFrame("Frame", "PawnShopPanel", AuctionFrame)
    panelFrame:SetPoint("TOPLEFT",     AuctionFrame, "TOPLEFT",      20, -65)
    panelFrame:SetPoint("BOTTOMRIGHT", AuctionFrame, "BOTTOMRIGHT", -20,  35)
    panelFrame:Hide()

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

    -- Eval Cached button (re-run eval on the already-loaded auction cache)
    evalCachedButton = CreateFrame("Button", nil, panelFrame, "UIPanelButtonTemplate")
    evalCachedButton:SetSize(110, 22)
    evalCachedButton:SetPoint("LEFT", scanButton, "RIGHT", 8, 0)
    evalCachedButton:SetText("Eval Cached")
    evalCachedButton:SetScript("OnClick", function()
        if #scan:getAuctions() == 0 then
            setStatus("No cached auctions. Run Scan All first.")
            return
        end
        eval:start()
    end)

    -- Status label
    statusLabel = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusLabel:SetPoint("LEFT",  evalCachedButton, "RIGHT", 12, 0)
    statusLabel:SetPoint("RIGHT", panelFrame,       "RIGHT", -20, 0)
    statusLabel:SetJustifyH("LEFT")
    statusLabel:SetText("Idle.")

    -- Header row
    headerFrame = CreateFrame("Frame", nil, panelFrame)
    headerFrame:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", 0, -32)
    headerFrame:SetPoint("RIGHT",   panelFrame, "RIGHT",   0,   0)
    headerFrame:SetHeight(constants.HEADER_HEIGHT)

    --[[
      Create a clickable header cell.
      @param columnKey string - stable identifier used by sort
      @param label string - display text
      @param justify string - "LEFT" / "CENTER" / "RIGHT"
      @return Button
    ]]
    local function makeHeaderCell(columnKey, label, justify)
        local btn = CreateFrame("Button", nil, headerFrame)
        btn.columnKey = columnKey
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetAllPoints(btn)
        btn.text:SetJustifyH(justify or "CENTER")
        btn.text:SetJustifyV("MIDDLE")
        btn.text:SetText(label)
        btn:SetScript("OnClick", function(self) cycleSort(self.columnKey) end)
        return btn
    end

    headerTime   = makeHeaderCell("time",   "Time",   "CENTER")
    headerBuyout = makeHeaderCell("buyout", "Buyout", "RIGHT")
    headerLvl    = makeHeaderCell("lvl",    "Lvl",    "CENTER")
    headerItem   = makeHeaderCell("name",   "Item",   "LEFT")

    headerTime:SetHeight(constants.HEADER_HEIGHT);   headerTime:SetWidth(constants.COL_TIME_WIDTH)
    headerBuyout:SetHeight(constants.HEADER_HEIGHT); headerBuyout:SetWidth(constants.COL_BUYOUT_WIDTH)
    headerLvl:SetHeight(constants.HEADER_HEIGHT);    headerLvl:SetWidth(constants.COL_LEVEL_WIDTH)
    headerItem:SetHeight(constants.HEADER_HEIGHT)

    -- List frame + scroll
    listFrame = CreateFrame("Frame", nil, panelFrame)
    listFrame:SetPoint("TOPLEFT",     headerFrame, "BOTTOMLEFT", 0, -2)
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
        - slot header: centered label ("Head", etc.)
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
        nameBtn2:SetScript("OnEnter", nameBtnOnEnter)
        nameBtn2:SetScript("OnLeave", nameBtnOnLeave)
        nameBtn2:SetScript("OnClick", nameBtnOnClick)
        row.nameBtn2 = nameBtn2

        row.buyoutText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.buyoutText:SetJustifyH("RIGHT")
        row.buyoutText:SetJustifyV("MIDDLE")
        row.buyoutText:SetWidth(constants.COL_BUYOUT_WIDTH)

        row.timeText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.timeText:SetJustifyH("CENTER")
        row.timeText:SetJustifyV("MIDDLE")
        row.timeText:SetWidth(constants.COL_TIME_WIDTH)

        row.levelText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.levelText:SetJustifyH("CENTER")
        row.levelText:SetJustifyV("MIDDLE")
        row.levelText:SetWidth(constants.COL_LEVEL_WIDTH)

        -- Per-scale cells; positioned by relayoutColumns.
        row.scaleCells = {}
        for s = 1, constants.MAX_SCALE_COLUMNS do
            local cell = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            cell:SetJustifyH("CENTER")
            cell:SetJustifyV("MIDDLE")
            cell:SetWidth(constants.COL_SCALE_WIDTH)
            cell:Hide()
            row.scaleCells[s] = cell
        end

        -- Slot header fontstring (used when the row renders as a group header)
        row.slotHeaderText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.slotHeaderText:SetPoint("LEFT", row, "LEFT", 8, 0)
        row.slotHeaderText:SetJustifyH("LEFT")
        row.slotHeaderText:SetJustifyV("MIDDLE")

        -- Overlay button for slot-header mode; toggles collapse.
        local headerBtn = CreateFrame("Button", nil, row)
        headerBtn:SetAllPoints(row)
        headerBtn:Hide()
        headerBtn:SetScript("OnClick", function(self)
            if self.slotName then
                collapsedSlots[self.slotName] = not collapsedSlots[self.slotName]
                panel:redraw()
            end
        end)
        row.headerBtn = headerBtn

        rowFrames[i] = row
    end
end

-- ============================================================================
-- COLUMN LAYOUT
-- ============================================================================

--[[
  Position header cells and per-row cells for the currently tracked scale
  count. Rebuilds the scale header buttons.
]]
local function relayoutColumns()
    local scaleOrder        = eval:getScaleOrder()
    local scaleDisplayOrder = eval:getScaleDisplayOrder()
    local n      = #scaleOrder
    local gutter = scrollbarGutter

    -- Headers anchor to panel-right (headerFrame spans full panel) so we
    -- pay the gutter once here. Row cells anchor to scroll-right which
    -- already excludes the gutter, so rrx starts at 0 below.
    local rx = gutter
    headerTime:ClearAllPoints()
    headerTime:SetPoint("RIGHT", headerFrame, "RIGHT", -rx, 0)
    rx = rx + constants.COL_TIME_WIDTH + constants.COL_PADDING

    headerBuyout:ClearAllPoints()
    headerBuyout:SetPoint("RIGHT", headerFrame, "RIGHT", -rx, 0)
    rx = rx + constants.COL_BUYOUT_WIDTH + constants.COL_PADDING

    -- Rebuild scale-column headers.
    for _, btn in ipairs(scaleHeaders) do btn:Hide() end
    wipe(scaleHeaders)
    for i = n, 1, -1 do
        local btn = CreateFrame("Button", nil, headerFrame)
        btn:SetPoint("RIGHT", headerFrame, "RIGHT", -rx, 0)
        btn:SetSize(constants.COL_SCALE_WIDTH, constants.HEADER_HEIGHT)
        btn.columnKey  = "scale_" .. i
        btn.scaleName  = scaleDisplayOrder[i] or scaleOrder[i]
        btn.scaleIndex = i
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetAllPoints(btn)
        btn.text:SetJustifyH("CENTER")
        btn.text:SetJustifyV("MIDDLE")
        btn.text:SetText("Scale " .. i)
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:SetText(self.scaleName or "?")
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function(self) cycleSort(self.columnKey) end)
        table.insert(scaleHeaders, btn)
        rx = rx + constants.COL_SCALE_WIDTH + constants.COL_PADDING
    end

    -- Lvl sits between scales (rightward) and Item (leftward).
    headerLvl:ClearAllPoints()
    headerLvl:SetPoint("RIGHT", headerFrame, "RIGHT", -rx, 0)
    rx = rx + constants.COL_LEVEL_WIDTH + constants.COL_PADDING

    -- Item header flexes between icon and the Lvl column.
    headerItem:ClearAllPoints()
    headerItem:SetPoint("LEFT",  headerFrame, "LEFT",  constants.ICON_SIZE + 8, 0)
    headerItem:SetPoint("RIGHT", headerFrame, "RIGHT", -rx, 0)

    -- Per-row cells. Rows anchor to scroll-right which already excludes
    -- the gutter, so rrx starts at 0.
    for _, row in ipairs(rowFrames) do
        local rrx = 0
        row.timeText:ClearAllPoints()
        row.timeText:SetPoint("RIGHT", row, "RIGHT", -rrx, 0)
        rrx = rrx + constants.COL_TIME_WIDTH + constants.COL_PADDING

        row.buyoutText:ClearAllPoints()
        row.buyoutText:SetPoint("RIGHT", row, "RIGHT", -rrx, 0)
        rrx = rrx + constants.COL_BUYOUT_WIDTH + constants.COL_PADDING

        for i = 1, constants.MAX_SCALE_COLUMNS do
            local cell = row.scaleCells[i]
            cell:ClearAllPoints()
            if i <= n then
                cell:SetPoint("RIGHT", row, "RIGHT",
                    -(rrx + (n - i) * (constants.COL_SCALE_WIDTH + constants.COL_PADDING)), 0)
                cell:SetHeight(constants.ROW_HEIGHT)
            else
                cell:Hide()
            end
        end
        rrx = rrx + n * (constants.COL_SCALE_WIDTH + constants.COL_PADDING)

        row.levelText:ClearAllPoints()
        row.levelText:SetPoint("RIGHT", row, "RIGHT", -rrx, 0)
        rrx = rrx + constants.COL_LEVEL_WIDTH + constants.COL_PADDING

        row.nameBtn:ClearAllPoints()
        row.nameBtn:SetPoint("LEFT",  row.icon, "RIGHT", 4, 0)
        row.nameBtn:SetPoint("RIGHT", row,      "RIGHT", -rrx, 0)
    end
end

-- ============================================================================
-- BUILD DISPLAY ROWS
-- ============================================================================

--[[
  Build the flat display list from eval's grouped rows, interleaving slot
  headers. Collapsed slots contribute only the header row.
  @return table - array of { kind, ... }
]]
local function buildDisplayRows()
    local rows = eval:getRows()

    -- Pre-count items per slot so headers display the count even when collapsed.
    local counts = {}
    for _, a in ipairs(rows) do
        local s = a.slotName or "Other"
        counts[s] = (counts[s] or 0) + 1
    end

    -- Default new slots to collapsed on first sighting. User clicks override.
    for slotName in pairs(counts) do
        if collapsedSlots[slotName] == nil then
            collapsedSlots[slotName] = true
        end
    end

    local out = {}
    local curRank = nil
    local curCollapsed = false
    for _, a in ipairs(rows) do
        if a.slotRank ~= curRank then
            curRank = a.slotRank
            local slotName = a.slotName or "Other"
            curCollapsed = collapsedSlots[slotName] or false
            table.insert(out, {
                kind      = "header",
                slotName  = slotName,
                count     = counts[slotName] or 0,
                collapsed = curCollapsed,
                height    = constants.ROW_HEIGHT,
            })
        end
        if not curCollapsed then
            table.insert(out, {
                kind   = "item",
                data   = a,
                height = a.isPair and constants.ROW_HEIGHT_PAIR or constants.ROW_HEIGHT,
            })
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

    local scaleOrder = eval:getScaleOrder()
    local n = #scaleOrder
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
            if row.headerBtn then row.headerBtn:Hide() end

        elseif dr.kind == "header" then
            -- Slot header: hide item elements, show label + count + caret.
            row:Show()
            row.nameBtn.link     = nil
            row.nameBtn.pairData = nil
            row.nameBtn.itemName = nil
            row.nameBtn:Hide()
            row.icon:Hide()
            row.icon2:Hide()
            row.nameBtn2:Hide()
            row.nameBtn2.pairData = nil
            row.buyoutText:SetText("")
            row.timeText:SetText("")
            row.levelText:SetText("")
            for _, cell in ipairs(row.scaleCells) do cell:SetText("") end

            local caret = dr.collapsed and "[+]" or "[-]"
            row.slotHeaderText:SetText(string.format("|cffffd700%s %s (%d)|r",
                caret, dr.slotName, dr.count))
            row.slotHeaderText:Show()
            row.headerBtn.slotName = dr.slotName
            row.headerBtn:Show()

        else
            -- Item row (single or pair).
            local data = dr.data
            row:Show()
            row.slotHeaderText:Hide()
            row.headerBtn:Hide()

            local pctByScale = {}
            if data.upgrades then
                for _, u in ipairs(data.upgrades) do
                    pctByScale[u.scale] = u.percent
                end
            end

            if data.isPair then
                -- PAIR: two-line layout, height = ROW_HEIGHT_PAIR.
                local mhE, ohE = data.mhEntry, data.ohEntry

                -- Name button right edge must stop before the first data
                -- column. Row stops at scroll-right, so no gutter here.
                local nameRightPad = constants.COL_TIME_WIDTH
                    + constants.COL_BUYOUT_WIDTH
                    + #scaleOrder * (constants.COL_SCALE_WIDTH + constants.COL_PADDING)
                    + constants.COL_PADDING * 2

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
                row.timeText:SetText(formatTimeLeft(data.timeLeft))

                -- Pair level = the higher of the two (both must be equippable).
                local mhLvl = (mhE.minLevel) or 0
                local ohLvl = (ohE.minLevel) or 0
                local pairLvl = math.max(mhLvl, ohLvl)
                row.levelText:SetText(pairLvl > 0 and tostring(pairLvl) or "")
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
                row.nameBtn:SetPoint("RIGHT",  row,      "RIGHT",
                    -(constants.COL_TIME_WIDTH + constants.COL_BUYOUT_WIDTH
                      + #scaleOrder * (constants.COL_SCALE_WIDTH + constants.COL_PADDING)
                      + constants.COL_PADDING * 2), 0)
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
                local stackSuffix = (data.count and data.count > 1) and (" x" .. data.count) or ""
                row.nameBtn.text:SetText(colorStart .. data.name .. stackSuffix .. "|r")

                row.buyoutText:SetText(formatMoney(data.buyout))
                row.timeText:SetText(formatTimeLeft(data.timeLeft))
                row.levelText:SetText(data.minLevel and tostring(data.minLevel) or "")
            end

            -- Scale cells (same for both modes)
            for s = 1, constants.MAX_SCALE_COLUMNS do
                local cell = row.scaleCells[s]
                if s <= n then
                    cell:SetText(formatScalePercent(pctByScale[scaleOrder[s]]))
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

function panel:show()
    createPanel()
    if panelFrame then panelFrame:Show() end
    setStatus("Ready. Click Scan All.")
end

function panel:hide()
    if panelFrame then panelFrame:Hide() end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

local function onScanStarted()
    disableScanButton()
    setStatus("Waiting for server...")
end

local function onScanIngested(_, payload)
    setStatus(string.format("Scan done: %d auctions. Starting eval...", payload.count or 0))
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
    panel:redraw()
end

local function onEvalComplete(_, payload)
    enableScanButton()
    setStatus(string.format("Done. %d items processed.", payload.rows or 0))
end

local function onEvalCancelled()
    enableScanButton()
    setStatus("Eval cancelled.")
end

local function onDisplaySettingChanged()
    -- Sort column/direction may have changed via options API. Re-sort and redraw.
    local rows = eval:getRows()
    sort:apply(rows, options:Get("sortColumn"), options:Get("sortDir"),
        function(n) return eval:scaleAtIndex(n) end)
    panel:updateSortIndicators()
    panel:redraw()
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function panel:initialize()
    utils     = Addon.utils
    events    = Addon.events
    options   = Addon.options
    constants = Addon.constants

    eval                   = Addon.eval
    scan                   = Addon.scan
    sort                   = Addon.sort
    auctionatorIntegration = Addon.auctionatorIntegration

    if not utils or not events or not options or not constants
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

    return true
end

if Addon.registerModule then
    Addon.registerModule("panel", {
        "utils", "events", "options", "constants",
        "eval", "scan", "sort", "auctionatorIntegration",
    }, function()
        return panel:initialize()
    end)
end

Addon.panel = panel
return panel
