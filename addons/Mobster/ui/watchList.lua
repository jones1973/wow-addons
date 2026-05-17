--[[
  ui/watchList.lua
  Watch list UI — the Mobster main window

  A draggable, ESC-closable frame listing the current watch entries with
  add/edit/delete controls and sound/mark toggles. Editing happens in the
  slide-out edit panel (ui/editPanel.lua); this file owns the list view,
  the Add buttons, and the click semantics that drive the panel.

  Rendering is delegated to the shared listView widget: this file
  declares row + group-header kinds and lets listView own pooling,
  scrolling, layout, selection, click dispatch, and double-click
  timing. The work here is the kinds spec, the action handlers
  (openEditFor / openAddFor / onDelete / showRowMenu), the window
  chrome, and the data-pipeline hook-ups (sort, group, refresh on
  zone change).

  Click semantics on a watch-list row:
    Single click       -> select (visual highlight, persistent until
                          another row is clicked or until the panel opens
                          with a different entry). When the edit panel
                          is already open, single-click switches its
                          target instead of merely selecting.
    Double click       -> open the edit panel populated with this row's
                          data.
    Right click        -> context menu (Edit / Delete) at cursor.

  Grouping. Rows are grouped by whether their stored zone matches the
  player's current zone: "In Zone" (matches) vs "Other Zones" (no zone
  or different zone). When every entry falls into a single group the
  header is suppressed by listView, so a watch list with no zoned
  entries (or with all entries in the current zone) renders flat.
  Refresh on ZONE_CHANGED / ZONE_CHANGED_NEW_AREA keeps the buckets
  current as the player moves.

  Reason is rendered as an (i) icon at the right edge of any row that
  has one. Hover the icon to see the reason text via the shared
  tooltip. Rows without a reason have no icon. All rows are uniform
  height.

  Watch entry storage. Entries in mobster_character.watchList are
  tables: { name, zone?, reason?, _id }. The _id is an 8-char hex
  assigned at creation time and stable across the entry's lifetime —
  used by listView for identity-based selection. All creation paths
  (slash command, edit panel save, itemAddPanel batch commit) go
  through Addon.newEntry; the SV is wiped on schema-version mismatch
  rather than migrated in place.

  Dependencies: constants, scanner, editPanel, contextMenu, tooltip,
                listView, panel, labeledToggle
  Exports: Addon.watchList
]]

local ADDON_NAME, Addon = ...

local watchList = {}

-- Module references (resolved at init)
local constants, scanner, editPanel, contextMenu, tooltip

-- Main UI state
local ui
local lv              -- listView instance

-- Cached current zone. Read at scan time inside the group key fn,
-- refreshed on ZONE_CHANGED events. Initialized at module load.
local currentZone = ""

local FRAME_NAME = ADDON_NAME .. "UI"

-- ============================================================================
-- LAYOUT
-- ============================================================================

local WINDOW_W       = 360
local WINDOW_H       = 460
local WINDOW_PAD     = 16

-- Vertical anchors of the list area inside the window. SCROLL_TOP_Y
-- is the inset from the window's top edge for the list-area's top.
-- SCROLL_BOTTOM_Y is the inset upward from the window's bottom edge
-- for the list-area's bottom. Both expressed positive.
local SCROLL_TOP_Y    = 52

-- Uniform row height. Two text lines fit comfortably (name on line 1,
-- zone on line 2 if present); reason is shown via hover icon, not text.
local ROW_H          = 40
local ROW_NAME_TOP   = 6
local ROW_ZONE_TOP   = 22
local ROW_PAD_LEFT   = 12
local ROW_PAD_RIGHT_NOICON = 12
local ROW_PAD_RIGHT_ICON   = 40

-- Group header
local HEADER_H        = 22
local HEADER_PAD_LEFT = 4

-- Reason hover-icon. Square (i) icon at the top-right of rows that
-- have a reason. ICON_PAD_TOP is empirical — Interface\Common\help-i
-- has transparent padding at its top edge.
local ICON_SIZE      = 24
local ICON_PAD_RIGHT = 8
local ICON_PAD_TOP   = 2

local ADD_BTN_W      = 96
local ADD_BTN_H      = 28

-- Footer Y offsets (measured from window's BOTTOM edge upward).
local FOOTER_BOTTOM_Y = 18
local FOOTER_TOP_GAP  = 6
local FOOTER_TOP_Y    = FOOTER_BOTTOM_Y + ADD_BTN_H + FOOTER_TOP_GAP
local SEP_Y           = FOOTER_TOP_Y + ADD_BTN_H + 8

-- The list area sits between SCROLL_TOP_Y (from top) and a few px
-- above the separator. Width = window inner width minus paddings.
-- These are the dimensions handed to listView.
local LIST_FRAME_W = WINDOW_W - WINDOW_PAD * 2
local LIST_FRAME_H = WINDOW_H - SCROLL_TOP_Y - (SEP_Y + 4)

-- ============================================================================
-- INTERNAL HELPERS — entry shape
-- ============================================================================

--[[
  Read name / zone / reason from an entry.

  @param entry table
  @return string name, string|nil zone, string|nil reason
]]
local function entryView(entry)
    if type(entry) == "table" then
        return entry.name or "", entry.zone, entry.reason
    end
    return "", nil, nil
end

--[[
  Build a {name, zone, reason, sourceItemIds} table for the edit
  panel from a saved entry. sourceItemIds (when present, set by
  Add by Item commit) drives the rich item tooltip on hover; it
  passes through unchanged on Save when the user didn't edit the
  reason field, and is cleared by editPanel on first user-initiated
  reason edit.
]]
local function entryToPanelData(entry)
    local name, zone, reason = entryView(entry)
    return {
        name           = name,
        zone           = zone,
        reason         = reason,
        sourceItemIds  = entry.sourceItemIds,
    }
end

-- ============================================================================
-- INTERNAL HELPERS — actions
-- ============================================================================

-- Forward declarations: openEditFor is referenced by the context menu
-- and the click handlers, but defined below.
local openEditFor
local onDelete

openEditFor = function(entry)
    if not entry then return end
    lv:setSelected(entry._id)

    editPanel:open(ui, entryToPanelData(entry), function(newData)
        -- Mutate the entry in place so its identity (_id) survives
        -- the save. The list reference is the same object across the
        -- closure capture, so position-by-index shifts can't corrupt
        -- which entry we end up writing to.
        entry.name           = newData.name
        entry.zone           = newData.zone
        entry.reason         = newData.reason
        entry.sourceItemIds  = newData.sourceItemIds
        scanner:resetTracking()
        watchList:refresh()
    end)
    watchList:refresh()
end

local function openAddFor()
    lv:clearSelection()
    editPanel:open(ui, nil, function(newData)
        local entry = Addon.newEntry({
            name           = newData.name,
            zone           = newData.zone,
            reason         = newData.reason,
            sourceItemIds  = newData.sourceItemIds,
        })
        table.insert(mobster_character.watchList, entry)
        lv:setSelected(entry._id)
        scanner:resetTracking()
        watchList:refresh()
    end)
    watchList:refresh()
end

onDelete = function(entry)
    if not entry then return end
    local list = mobster_character.watchList
    for i = 1, #list do
        if list[i] == entry then
            table.remove(list, i)
            break
        end
    end
    if lv:getSelected() == entry._id then
        lv:clearSelection()
    end
    -- Close the panel if it was editing the deleted (or any) row —
    -- the save callback closure captures the entry reference; with
    -- the entry now removed, the callback would re-insert it via
    -- mutation on Save. Closing cancels that hazard.
    if editPanel:isOpen() then
        editPanel:close()
    end
    scanner:resetTracking()
    watchList:refresh()
end

--[[
  Per-row context menu. The Delete item is rendered red as a
  destructive-action affordance — color support comes from
  menuRenderer's per-item color field.
]]
local DELETE_RED = { 1, 0.4, 0.4 }

local function showRowMenu(entry)
    if not contextMenu or not entry then return end
    contextMenu:show({
        items = {
            { text = "Edit",   func = function() openEditFor(entry) end },
            { separator = true },
            { text = "Delete", func = function() onDelete(entry) end,
              color = DELETE_RED },
        },
    }, {})
end

-- ============================================================================
-- INTERNAL HELPERS — kinds spec
-- ============================================================================

local function rowFactory(parent)
    local row = CreateFrame("Button", nil, parent)
    -- Height is set by listView from spec.height.

    -- Tint (hover or active). Single texture, color switched between
    -- hover and selection at render/hover time. listView passes
    -- ctx.isSelected to render; the factory installs OnEnter/OnLeave
    -- for hover. The two states are mutually exclusive: hover doesn't
    -- override selection.
    local tint = row:CreateTexture(nil, "BACKGROUND")
    tint:SetAllPoints()
    tint:Hide()
    row.tint = tint

    -- Name (top line). Right-edge anchor swaps in render() depending
    -- on whether the reason icon is present.
    local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameFS:SetJustifyH("LEFT")
    nameFS:SetWordWrap(false)
    row.nameFS = nameFS

    -- Zone (second line, optional). Left-justified to the same X as
    -- name (no indent) per current design.
    local zoneFS = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    zoneFS:SetJustifyH("LEFT")
    zoneFS:SetWordWrap(false)
    row.zoneFS = zoneFS

    -- Reason hover icon. Built once; Show/Hide in render.
    --
    -- A Frame with EnableMouse(true) for OnEnter/OnLeave (tooltip), plus
    -- SetPropagateMouseClicks(true) so clicks pass through to the row
    -- beneath it in the mouse focus stack. WoW's mouse model is
    -- focus-stack-based; without this flag the icon would swallow clicks
    -- that the user expects to hit the row.
    local icon = CreateFrame("Frame", nil, row)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("TOPRIGHT", -ICON_PAD_RIGHT, -ICON_PAD_TOP)
    icon:EnableMouse(true)
    icon:SetPropagateMouseClicks(true)
    icon:Hide()

    local iconTex = icon:CreateTexture(nil, "ARTWORK")
    iconTex:SetAllPoints()
    iconTex:SetTexture("Interface\\Common\\help-i")
    icon.iconTex = iconTex

    icon:SetScript("OnEnter", function(self)
        -- Keep the row tint visible while the cursor is on the icon
        -- (cursor moving from row body onto the icon fires the row's
        -- OnLeave). Re-show hover here so the row reads as
        -- continuously hovered while the user is over the (i).
        if not row._isSelected then
            local h = Addon.theme.tokens.SURFACE.ROW_HOVER
            row.tint:SetColorTexture(h.r, h.g, h.b, h.a)
            row.tint:Show()
        end
        -- Tooltip selection:
        --   - Single sourceItemId AND the user hasn't edited the
        --     reason → rich item tooltip via GameTooltip.
        --   - Otherwise → plain reason text via the shared tooltip.
        -- The two tooltips are distinct frames (GameTooltip is
        -- Blizzard's; tooltip is the addon's shared one), so OnLeave
        -- hides both unconditionally.
        local ids = self.sourceItemIds
        if ids and #ids == 1 then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(ids[1])
            GameTooltip:Show()
        elseif tooltip and self.reasonText then
            tooltip:showSimple(self, self.reasonText)
        end
    end)
    icon:SetScript("OnLeave", function()
        GameTooltip:Hide()
        if tooltip then tooltip:hide() end
    end)
    row.icon = icon

    -- Hover/leave on the row itself. listView wires OnClick separately
    -- via SetScript; OnEnter/OnLeave are factory-installed so listView's
    -- click wiring doesn't clobber them. Selection state is consulted
    -- (mirrored from render onto row._isSelected) so hover doesn't
    -- override active selection.
    row:SetScript("OnEnter", function(self)
        if not self._isSelected then
            local h = Addon.theme.tokens.SURFACE.ROW_HOVER
            self.tint:SetColorTexture(h.r, h.g, h.b, h.a)
            self.tint:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        if not self._isSelected then
            self.tint:Hide()
        end
    end)

    return row
end

local function rowRender(frame, item, ctx)
    local name, zone, reason = entryView(item)
    local hasReason = reason and reason ~= ""

    -- Anchor the name FontString based on whether the reason icon is
    -- present. ClearAllPoints first so a recycled row that previously
    -- held an iconned entry doesn't keep the wrong inset.
    frame.nameFS:ClearAllPoints()
    frame.nameFS:SetPoint("TOPLEFT", ROW_PAD_LEFT, -ROW_NAME_TOP)
    frame.nameFS:SetPoint("TOPRIGHT",
        -(hasReason and ROW_PAD_RIGHT_ICON or ROW_PAD_RIGHT_NOICON),
        -ROW_NAME_TOP)

    frame.zoneFS:ClearAllPoints()
    frame.zoneFS:SetPoint("TOPLEFT", ROW_PAD_LEFT, -ROW_ZONE_TOP)
    frame.zoneFS:SetPoint("TOPRIGHT",
        -(hasReason and ROW_PAD_RIGHT_ICON or ROW_PAD_RIGHT_NOICON),
        -ROW_ZONE_TOP)

    frame.nameFS:SetText(name)
    if zone and zone ~= "" then
        frame.zoneFS:SetText(zone)
        frame.zoneFS:Show()
    else
        frame.zoneFS:Hide()
    end

    if hasReason then
        frame.icon.reasonText     = reason
        frame.icon.sourceItemIds  = item.sourceItemIds
        frame.icon:Show()
    else
        frame.icon.reasonText     = nil
        frame.icon.sourceItemIds  = nil
        frame.icon:Hide()
    end

    -- Mirror selection state onto the frame so the hover handlers can
    -- consult it without going through listView.
    frame._isSelected = ctx.isSelected
    if ctx.isSelected then
        local a = Addon.theme.tokens.BRAND.SELECTION_TINT_HIGH
        frame.tint:SetColorTexture(a.r, a.g, a.b, a.a)
        frame.tint:Show()
    else
        frame.tint:Hide()
    end
end

local function groupFactory(parent)
    local header = CreateFrame("Frame", nil, parent)
    -- Height set by listView from spec.headerHeight.

    local fs = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("LEFT", HEADER_PAD_LEFT, 0)
    fs:SetJustifyH("LEFT")
    header.fs = fs

    return header
end

local function groupRender(frame, key)
    -- Two keys only: "current" and "other". The labels are display
    -- only; the keys themselves are the data.
    if key == "current" then
        frame.fs:SetText("In Zone")
    else
        frame.fs:SetText("Other Zones")
    end
end

-- ============================================================================
-- INTERNAL HELPERS — pipeline functions for listView
-- ============================================================================

local function listSort(a, b)
    local an = (a and a.name) or ""
    local bn = (b and b.name) or ""
    return an:lower() < bn:lower()
end

local function groupKey(item)
    local _, zone = entryView(item)
    if zone and zone ~= "" and zone == currentZone then
        return "current"
    end
    return "other"
end

local function groupSort(a, b)
    if a == b then return false end
    return a == "current"
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Toggle the watch list window visibility. Closes the edit panel
  alongside the main window when hiding (the panel's OnHide hook on
  the main window handles that; context menus auto-close via the
  shared menuRenderer's outside-click watcher).
]]
function watchList:toggle()
    if not ui then return end
    if ui:IsShown() then
        ui:Hide()
    else
        ui:Show()
    end
end

--[[
  Rebuild the watch list rows from mobster_character.watchList.
  Delegated to listView, which pulls fresh data via dataFn.
]]
function watchList:refresh()
    if lv then lv:refresh() end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function buildFrame()
    ui = Addon.panel:opaque(UIParent, {
        name     = FRAME_NAME,
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 32,
        insets   = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    ui:SetSize(WINDOW_W, WINDOW_H)
    ui:SetPoint("CENTER")
    ui:SetMovable(true)
    ui:SetClampedToScreen(true)
    ui:EnableMouse(true)
    ui:SetFrameStrata("DIALOG")
    ui:RegisterForDrag("LeftButton")
    ui:SetScript("OnDragStart", ui.StartMoving)
    ui:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        mobster_settings.framePos = { point, x, y }
    end)

    if mobster_settings.framePos then
        local p = mobster_settings.framePos
        ui:ClearAllPoints()
        ui:SetPoint(p[1], UIParent, p[1], p[2], p[3])
    end

    ui:Hide()
    tinsert(UISpecialFrames, FRAME_NAME)

    local title = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -WINDOW_PAD)
    title:SetText("Mobster")

    local close = CreateFrame("Button", nil, ui, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    -- ListView ------------------------------------------------------------
    --
    -- Wraps the entire scrolling-list area. Anchored TOPLEFT just below
    -- the title and sized to fit between SCROLL_TOP_Y and the
    -- separator. Width includes scrollbar reserve (listView handles
    -- the -20 internally).

    lv = Addon.listView:create({
        parent = ui,
        width  = LIST_FRAME_W,
        height = LIST_FRAME_H,
        scrollFrameName = FRAME_NAME .. "ListViewScroll",

        dataFn     = function() return mobster_character.watchList end,
        identityFn = function(item) return item._id end,

        sort  = listSort,
        group = {
            key  = groupKey,
            sort = groupSort,
        },

        kinds = {
            row = {
                height  = ROW_H,
                factory = rowFactory,
                render  = rowRender,
            },
            group = {
                headerHeight = HEADER_H,
                factory      = groupFactory,
                render       = groupRender,
                -- No body slot → ornamental header. Singleton
                -- suppression collapses the list to flat when all
                -- entries fall in one bucket (e.g., player is in a
                -- zone with no watch entries, or none of the entries
                -- have zones).
            },
        },

        onClick = function(item, kind, identity)
            -- Group headers click-fire too (listView routes them
            -- through onClick after handling expand-state). Ignore
            -- here since we have no body.
            if kind == "group" then return end

            if editPanel:isOpen() then
                if identity ~= lv:getSelected() then
                    openEditFor(item)
                end
            else
                lv:setSelected(identity)
            end
        end,

        onDoubleClick = function(item, kind)
            if kind == "group" then return end
            openEditFor(item)
        end,

        onContextMenu = function(item, kind)
            if kind == "group" then return end
            showRowMenu(item)
        end,
    })

    lv:getFrame():SetPoint("TOPLEFT", WINDOW_PAD, -SCROLL_TOP_Y)

    -- Separator above the Add row
    local sep = ui:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("LEFT", WINDOW_PAD, 0)
    sep:SetPoint("RIGHT", -WINDOW_PAD, 0)
    sep:SetPoint("BOTTOM", 0, SEP_Y)
    do
        local s = Addon.theme.tokens.SEPARATOR.DEFAULT
        sep:SetColorTexture(s.r, s.g, s.b, s.a)
    end

    -- Footer layout. Two columns:
    --   Left column:  Sound checkbox (top) / Mark checkbox (bottom)
    --   Right column: Add by Item / Add by NPC (top) / Close (bottom)
    --
    -- Sound and Mark write to mobster_settings (account-wide
    -- preferences); the scanner reads them at scan time.

    local soundLT = Addon.labeledToggle:create({
        parent   = ui,
        style    = "checkbox",
        label    = "Sound",
        checked  = mobster_settings.soundEnabled,
        onChange = function(checked) mobster_settings.soundEnabled = checked end,
    })
    soundLT.toggle:SetPoint("BOTTOMLEFT", WINDOW_PAD, FOOTER_TOP_Y)

    local markLT = Addon.labeledToggle:create({
        parent   = ui,
        style    = "checkbox",
        label    = "Mark (solo only)",
        checked  = mobster_settings.markEnabled,
        onChange = function(checked) mobster_settings.markEnabled = checked end,
    })
    markLT.toggle:SetPoint("BOTTOMLEFT", WINDOW_PAD, FOOTER_BOTTOM_Y)

    local addItemBtn = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    addItemBtn:SetSize(ADD_BTN_W, ADD_BTN_H)
    addItemBtn:SetPoint("BOTTOMRIGHT", -WINDOW_PAD, FOOTER_TOP_Y)
    addItemBtn:SetText("Add by Item")
    addItemBtn:SetScript("OnClick", function()
        editPanel:close()
        if Addon.itemAddPanel then Addon.itemAddPanel:open(ui) end
    end)

    local addNpcBtn = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    addNpcBtn:SetSize(ADD_BTN_W, ADD_BTN_H)
    addNpcBtn:SetPoint("RIGHT", addItemBtn, "LEFT", -8, 0)
    addNpcBtn:SetText("Add by NPC")
    addNpcBtn:SetScript("OnClick", function()
        if Addon.itemAddPanel then Addon.itemAddPanel:close() end
        openAddFor()
    end)

    local closeBtn = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    closeBtn:SetSize(ADD_BTN_W, ADD_BTN_H)
    closeBtn:SetPoint("BOTTOMRIGHT", -WINDOW_PAD, FOOTER_BOTTOM_Y)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() ui:Hide() end)

    ui:SetScript("OnHide", function()
        editPanel:close()
        if Addon.itemAddPanel then Addon.itemAddPanel:close() end
    end)
end

--[[
  Zone-change handler. Refresh the list so the "In Zone" / "Other
  Zones" buckets reflect the new current zone. Uses GetZoneText to
  match the scanner's matching API (which also uses GetZoneText).
]]
local function buildZoneWatcher()
    currentZone = GetZoneText() or ""
    local zw = CreateFrame("Frame")
    zw:RegisterEvent("ZONE_CHANGED")
    zw:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    zw:RegisterEvent("ZONE_CHANGED_INDOORS")
    zw:RegisterEvent("PLAYER_ENTERING_WORLD")
    zw:SetScript("OnEvent", function()
        currentZone = GetZoneText() or ""
        if lv then lv:refresh() end
    end)
end

function watchList:initialize()
    constants   = Addon.constants
    scanner     = Addon.scanner
    editPanel   = Addon.editPanel
    contextMenu = Addon.contextMenu
    tooltip     = Addon.tooltip

    if not constants or not scanner or not editPanel then
        Addon.theme.chat:alarm("watchList: Missing dependencies")
        return false
    end

    if not Addon.listView then
        Addon.theme.chat:alarm("watchList: listView dependency missing")
        return false
    end

    if not contextMenu then
        Addon.utils:chat("watchList: contextMenu unavailable; right-click menus disabled")
    end
    if not tooltip then
        Addon.utils:chat("watchList: tooltip unavailable; reason hover disabled")
    end

    buildFrame()
    buildZoneWatcher()
    watchList:refresh()
    return true
end

Addon.watchList = watchList
return watchList
