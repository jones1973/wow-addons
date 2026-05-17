--[[
  ui/watchList.lua
  Watch list UI — the Mobster main window

  A draggable, ESC-closable frame listing the current watch entries with
  add/edit/delete controls and sound/mark toggles. Editing happens in the
  slide-out edit panel (ui/editPanel.lua); this file owns the list view,
  the Add button, and the click semantics that drive the panel.

  Click semantics on a watch list row:

    Single click       -> select (visual highlight, persistent until
                          another row is clicked or until the panel opens
                          with a different entry)
    Double click       -> open the edit panel populated with this row's
                          data
    Right click        -> context menu (Edit / Delete) at cursor

  Selection vs. edit-target. activeIndex serves both roles: it's the row
  showing the active tint, and (when the panel is open) it's the entry
  the panel is editing. Single-click while the panel is open is
  suppressed so the visual stays in sync with the panel's edit target;
  to switch entries while editing, double-click another row (silently
  discarding panel changes) or use the right-click menu.

  Reason is rendered as an (i) icon at the right edge of any row that
  has one. Hover the icon to see the reason text via the shared
  tooltip. Rows without a reason have no icon. All rows are uniform
  height regardless of zone or reason presence.

  Watch entry storage. Entries in mobster_character.watchList may be
  either a freeform string (legacy / slash-command-added) or a table
  { pattern, zone?, reason? }. Edits saved through the panel always
  write the table form. The panel's UI-facing field name is "name",
  which maps to `pattern` in storage; pattern is the more descriptive
  name from the matcher's perspective (substring against UnitName).

  Dependencies: constants, scanner, editPanel, contextMenu, tooltip
  Exports: Addon.watchList
]]

local ADDON_NAME, Addon = ...

local watchList = {}

-- Module references (resolved at init)
local constants, scanner, editPanel, contextMenu, tooltip

-- Main UI state
local ui
local scrollChild
local rowPool       -- Addon.pool instance, created in build()

-- The single "active" index used both for selection visual and for the
-- row the edit panel is operating on. nil = nothing highlighted.
local activeIndex

-- Double-click detection. WoW Button frames don't expose OnDoubleClick
-- in TBC Classic, so we track click time + last-clicked-row manually.
local DOUBLE_CLICK_INTERVAL = 0.4
local lastClickTime = 0
local lastClickedRow

local FRAME_NAME = ADDON_NAME .. "UI"

-- ============================================================================
-- LAYOUT
-- ============================================================================

local WINDOW_W       = 360
local WINDOW_H       = 460
local WINDOW_PAD     = 16
local SCROLL_TOP_Y   = -52   -- below the title
-- SCROLL_BOT_Y is derived from SEP_Y below to ensure they stay in
-- sync. Defined here as a forward-declared variable so the layout
-- block reads naturally; assigned after SEP_Y.
local SCROLL_BOT_Y

-- Uniform row height. Two text lines fit comfortably (name on line 1,
-- zone on line 2 if present); reason is shown via hover icon, not text.
local ROW_H          = 40
local ROW_NAME_TOP   = 6
local ROW_ZONE_TOP   = 22
local ROW_PAD_LEFT   = 12
local ROW_PAD_RIGHT_NOICON = 12  -- when no reason icon
local ROW_PAD_RIGHT_ICON   = 40  -- room for the reason icon (24 + padding)

-- Reason hover-icon. Square (i) icon at the top-right of rows that
-- have a reason. 24px keeps the icon inside the 40px row with
-- breathing room above and below; larger sizes would require growing
-- the row.
--
-- ICON_PAD_TOP is empirical, not just matching ROW_NAME_TOP. The
-- Interface\Common\help-i texture has transparent padding at its top
-- edge — the visible "i" glyph sits maybe 4px below the texture's
-- frame top. Anchoring at top with a positive top inset matching the
-- name's top inset (6) would make the visible icon sit visibly LOWER
-- than the name's top edge. We pull the texture's frame upward by
-- about that texture-padding amount so the visible icon top aligns
-- with the name's visual top.
local ICON_SIZE      = 24
local ICON_PAD_RIGHT = 8
local ICON_PAD_TOP   = 2

local ADD_BTN_W      = 96
local ADD_BTN_H      = 28

-- Footer Y offsets (measured from window's BOTTOM edge upward).
-- Two stacked items per column: top row sits above the bottom row by
-- exactly one button-row stride (button height + a small gap).
-- The same stride is used for the checkbox column even though
-- checkboxes are shorter; that produces a slightly larger visual gap
-- in the checkbox column, which is fine because checkboxes feel more
-- spread out as a group than buttons do.
local FOOTER_BOTTOM_Y    = 18  -- Mark checkbox / Close button
local FOOTER_TOP_GAP     = 6
local FOOTER_TOP_Y       = FOOTER_BOTTOM_Y + ADD_BTN_H + FOOTER_TOP_GAP
                            -- Sound checkbox / Add Entry button

local SEP_Y          = FOOTER_TOP_Y + ADD_BTN_H + 8

-- Scroll bottom sits a few pixels above the separator. Derived rather
-- than hardcoded so it tracks any future footer-layout changes.
SCROLL_BOT_Y = SEP_Y + 4

-- Tints. Active = persistent (selected, or panel's edit target).
-- Hover = lighter overlay; both ride the same texture.
local HOVER_R, HOVER_G, HOVER_B, HOVER_A     = 1, 1, 1, 0.10
local ACTIVE_R, ACTIVE_G, ACTIVE_B, ACTIVE_A = 0.30, 0.60, 1.00, 0.22

-- ============================================================================
-- INTERNAL HELPERS — entry shape
-- ============================================================================

--[[
  Read name / zone / reason from an entry, regardless of whether it's
  stored as a string (legacy) or a table.

  @param entry string|table
  @return string name, string|nil zone, string|nil reason
]]
local function entryView(entry)
    if type(entry) == "string" then
        return entry, nil, nil
    end
    if type(entry) == "table" then
        return entry.name or "", entry.zone, entry.reason
    end
    return "", nil, nil
end

--[[
  Build a {name, zone, reason} table for the edit panel from a saved entry.
  Storage and panel both use "name" — no translation needed for table
  entries; string entries get materialized into table shape.
]]
local function entryToPanelData(entry)
    local name, zone, reason = entryView(entry)
    return { name = name, zone = zone, reason = reason }
end

-- ============================================================================
-- INTERNAL HELPERS — actions
-- ============================================================================

-- Forward declarations: openEditFor and onDelete are referenced by the
-- context menu's item callbacks built in showRowMenu, but defined below.
local openEditFor
local onDelete

openEditFor = function(index)
    activeIndex = index
    local entry = mobster_character.watchList[index]
    if not entry then return end

    editPanel:open(ui, entryToPanelData(entry), function(newData)
        -- Save callback: replace the entry with the panel's table form.
        mobster_character.watchList[index] = {
            name   = newData.name,
            zone   = newData.zone,
            reason = newData.reason,
        }
        scanner:resetTracking()
        watchList:refresh()
    end)
    watchList:refresh()
end

local function openAddFor()
    activeIndex = nil  -- nothing tinted while in add mode
    editPanel:open(ui, nil, function(newData)
        local newEntry = {
            name   = newData.name,
            zone   = newData.zone,
            reason = newData.reason,
        }
        table.insert(mobster_character.watchList, newEntry)
        activeIndex = #mobster_character.watchList  -- highlight the new row
        scanner:resetTracking()
        watchList:refresh()
    end)
    watchList:refresh()
end

onDelete = function(index)
    table.remove(mobster_character.watchList, index)
    -- Adjust activeIndex for the shift.
    if activeIndex == index then
        activeIndex = nil
    elseif activeIndex and activeIndex > index then
        activeIndex = activeIndex - 1
    end
    -- Always close the panel when a delete happens, even if the panel was
    -- editing a different entry. The save callback closure captures the
    -- editing index by value; once the list shifts, that captured index
    -- could refer to a different entry, and a subsequent Save would
    -- silently overwrite the wrong row. Closing the panel cancels the
    -- pending callback and avoids the hazard. Cost: unsaved edits to an
    -- unrelated entry are lost. Acceptable tradeoff for the simplicity.
    if editPanel:isOpen() then
        editPanel:close()
    end
    scanner:resetTracking()
    watchList:refresh()
end

--[[
  Build and show the per-row context menu via the shared contextMenu
  module. The menu auto-closes on outside click, ESC, or timeout, all
  handled by menuRenderer. The Delete item is rendered red as a
  destructive-action affordance — color support comes from
  menuRenderer's per-item color field.
]]
local DELETE_RED = { 1, 0.4, 0.4 }

local function showRowMenu(index)
    if not contextMenu then return end
    contextMenu:show({
        items = {
            { text = "Edit",   func = function(ctx) openEditFor(ctx.index) end },
            { separator = true },
            { text = "Delete", func = function(ctx) onDelete(ctx.index) end,
              color = DELETE_RED },
        },
    }, { index = index })
end

-- ============================================================================
-- INTERNAL HELPERS — row factory
-- ============================================================================

local function makeRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    -- Width via TOPLEFT/TOPRIGHT in :refresh().

    -- Tint (hover or active)
    local tint = row:CreateTexture(nil, "BACKGROUND")
    tint:SetAllPoints()
    tint:SetColorTexture(HOVER_R, HOVER_G, HOVER_B, HOVER_A)
    tint:Hide()
    row.tint = tint

    -- Name (top line). Right-edge anchor swaps in :refresh() depending
    -- on whether the reason icon is present.
    local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameFS:SetPoint("TOPLEFT", ROW_PAD_LEFT, -ROW_NAME_TOP)
    nameFS:SetJustifyH("LEFT")
    nameFS:SetWordWrap(false)
    row.nameFS = nameFS

    -- Zone (second line, optional). Left-justified to the same X as
    -- name (no indent) per current design.
    local zoneFS = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    zoneFS:SetPoint("TOPLEFT", ROW_PAD_LEFT, -ROW_ZONE_TOP)
    zoneFS:SetJustifyH("LEFT")
    zoneFS:SetWordWrap(false)
    row.zoneFS = zoneFS

    -- Reason hover icon. Built once; Show/Hide in :refresh().
    --
    -- A Frame with EnableMouse(true) for OnEnter/OnLeave (tooltip), plus
    -- SetPropagateMouseClicks(true) so clicks pass through to the row
    -- beneath it in the mouse focus stack. WoW's mouse model is
    -- focus-stack-based, not parent-bubble-based, so without this flag
    -- the icon would swallow clicks that the user expects to hit the row.
    -- With propagation on, left-click selects the row, right-click opens
    -- the context menu, and double-click edits — all identical to
    -- clicking the row body.
    --
    -- Position: top-right of the row, top inset matching the name text's
    -- top inset so the icon visually aligns with the name's top edge
    -- rather than floating mid-row.
    local icon = CreateFrame("Frame", nil, row)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("TOPRIGHT", -ICON_PAD_RIGHT, -ICON_PAD_TOP)
    icon:EnableMouse(true)
    icon:SetPropagateMouseClicks(true)
    icon:Hide()

    -- Stock Blizzard help-i texture matches what infoTip uses for a
    -- consistent "this has more info" affordance across the addon.
    local iconTex = icon:CreateTexture(nil, "ARTWORK")
    iconTex:SetAllPoints()
    iconTex:SetTexture("Interface\\Common\\help-i")
    icon.iconTex = iconTex

    icon:SetScript("OnEnter", function(self)
        -- Keep the row tint visible while the cursor is on the icon.
        -- Entering the icon fires the row's OnLeave (mouse focus stack
        -- semantics — entering a child counts as leaving the parent),
        -- which hides the hover tint. Re-show it here so the row reads
        -- as still hovered while the user is over the (i).
        if row.index ~= activeIndex then
            row.tint:SetColorTexture(HOVER_R, HOVER_G, HOVER_B, HOVER_A)
            row.tint:Show()
        end
        if tooltip and self.reasonText then
            tooltip:showSimple(self, self.reasonText)
        end
    end)
    icon:SetScript("OnLeave", function()
        if tooltip then tooltip:hide() end
        -- If the cursor moved off the row entirely (icon-leave coincided
        -- with leaving the row), the row's own OnLeave already hid the
        -- tint. If the cursor is still over the row body, the row's
        -- OnEnter fires next and re-shows it. Either way no action
        -- needed here — checking IsMouseOver and re-hiding would cause
        -- a one-frame flicker we don't want.
    end)
    row.icon = icon

    -- Hover/leave on the row itself
    row:SetScript("OnEnter", function(self)
        if self.index ~= activeIndex then
            self.tint:SetColorTexture(HOVER_R, HOVER_G, HOVER_B, HOVER_A)
            self.tint:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        if self.index ~= activeIndex then
            self.tint:Hide()
        end
    end)

    row:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            -- Right-click only shows the menu; doesn't change activeIndex.
            showRowMenu(self.index)
            return
        end

        -- Left-click: detect double-click against last click on same row.
        local now = GetTime()
        local isDouble = (self == lastClickedRow)
            and ((now - lastClickTime) < DOUBLE_CLICK_INTERVAL)

        if isDouble then
            lastClickTime = 0
            lastClickedRow = nil
            openEditFor(self.index)
        else
            lastClickTime = now
            lastClickedRow = self
            -- Single-click semantics depend on whether the panel is
            -- open. Closed: just select (highlight tint). Open: switch
            -- the panel's edit target to this row, silently discarding
            -- whatever in-flight edits the panel held — consistent with
            -- the double-click-to-switch behavior we already had, just
            -- without requiring two clicks. openEditFor handles both
            -- the activeIndex update and re-opening the panel for the
            -- new row.
            if editPanel:isOpen() then
                if self.index ~= activeIndex then
                    openEditFor(self.index)
                end
            else
                activeIndex = self.index
                watchList:refresh()
            end
        end
    end)

    return row
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Toggle the watch list window visibility. Closes the edit panel
  alongside the main window when hiding (the panel's OnHide hook on the
  main window handles that, plus context menus auto-close on the
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
  Rebuild the watch list rows from mobster_character.watchList. Uniform
  ROW_H per row.
]]
function watchList:refresh()
    local list = mobster_character.watchList

    rowPool:releaseAll()

    for i, entry in ipairs(list) do
        local row = rowPool:acquire()
        local name, zone, reason = entryView(entry)
        local hasReason = reason and reason ~= ""

        -- Anchor name's right edge based on whether the icon is present.
        -- ClearAllPoints + re-anchor each refresh so a recycled row that
        -- previously held an iconned entry doesn't keep the wrong inset.
        row.nameFS:ClearAllPoints()
        row.nameFS:SetPoint("TOPLEFT", ROW_PAD_LEFT, -ROW_NAME_TOP)
        row.nameFS:SetPoint("TOPRIGHT",
            -(hasReason and ROW_PAD_RIGHT_ICON or ROW_PAD_RIGHT_NOICON),
            -ROW_NAME_TOP)

        row.zoneFS:ClearAllPoints()
        row.zoneFS:SetPoint("TOPLEFT", ROW_PAD_LEFT, -ROW_ZONE_TOP)
        row.zoneFS:SetPoint("TOPRIGHT",
            -(hasReason and ROW_PAD_RIGHT_ICON or ROW_PAD_RIGHT_NOICON),
            -ROW_ZONE_TOP)

        row.nameFS:SetText(name)
        if zone and zone ~= "" then
            row.zoneFS:SetText(zone)
            row.zoneFS:Show()
        else
            row.zoneFS:Hide()
        end

        if hasReason then
            row.icon.reasonText = reason
            row.icon:Show()
        else
            row.icon.reasonText = nil
            row.icon:Hide()
        end

        row.index = i
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
        row:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_H)
        row:Show()

        if i == activeIndex then
            row.tint:SetColorTexture(ACTIVE_R, ACTIVE_G, ACTIVE_B, ACTIVE_A)
            row.tint:Show()
        else
            row.tint:Hide()
        end
    end
    scrollChild:SetHeight(math.max(1, #list * ROW_H))
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
        mobster_character.framePos = { point, x, y }
    end)

    if mobster_character.framePos then
        local p = mobster_character.framePos
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

    local scroll = CreateFrame("ScrollFrame", nil, ui, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", WINDOW_PAD, SCROLL_TOP_Y)
    scroll:SetPoint("BOTTOMRIGHT", -WINDOW_PAD - 20, SCROLL_BOT_Y)

    scrollChild = CreateFrame("Frame", nil, scroll)
    scrollChild:SetWidth(WINDOW_W - WINDOW_PAD * 2 - 20)
    scrollChild:SetHeight(1)
    scroll:SetScrollChild(scrollChild)

    rowPool = Addon.pool:new(function() return makeRow(scrollChild) end)

    -- Separator above the Add row
    local sep = ui:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("LEFT", WINDOW_PAD, 0)
    sep:SetPoint("RIGHT", -WINDOW_PAD, 0)
    sep:SetPoint("BOTTOM", 0, SEP_Y)
    sep:SetColorTexture(0.4, 0.4, 0.4, 0.6)

    -- Footer layout. Two columns:
    --   Left column:  Sound checkbox (top) / Mark checkbox (bottom)
    --   Right column: Add Entry button (top) / Close button (bottom)

    -- Sound checkbox (top-left of footer)
    local soundCB = CreateFrame("CheckButton", FRAME_NAME .. "SoundCB", ui, "UICheckButtonTemplate")
    soundCB:SetPoint("BOTTOMLEFT", WINDOW_PAD, FOOTER_TOP_Y)
    soundCB:SetSize(24, 24)
    soundCB:SetChecked(mobster_character.soundEnabled)
    soundCB:SetScript("OnClick", function(self)
        mobster_character.soundEnabled = self:GetChecked() and true or false
    end)
    local soundLbl = soundCB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    soundLbl:SetPoint("LEFT", soundCB, "RIGHT", 4, 0)
    soundLbl:SetText("Sound")

    -- Mark checkbox (bottom-left of footer)
    local markCB = CreateFrame("CheckButton", FRAME_NAME .. "MarkCB", ui, "UICheckButtonTemplate")
    markCB:SetPoint("BOTTOMLEFT", WINDOW_PAD, FOOTER_BOTTOM_Y)
    markCB:SetSize(24, 24)
    markCB:SetChecked(mobster_character.markEnabled)
    markCB:SetScript("OnClick", function(self)
        mobster_character.markEnabled = self:GetChecked() and true or false
    end)
    local markLbl = markCB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    markLbl:SetPoint("LEFT", markCB, "RIGHT", 4, 0)
    markLbl:SetText("Mark (solo only)")

    -- Add buttons (top-right of footer). Two flavors: "Add by NPC"
    -- opens the per-entry edit panel; "Add by Item" opens the
    -- item-drop search panel. Each has a 3px colored stripe on its
    -- left edge to tie visually to its panel's tint.
    --
    -- (Stripe colors mirror the panels' background tints. When the
    -- theme module lands these will move to theme tokens.)
    local STRIPE_W = 3
    local NPC_TINT_R,  NPC_TINT_G,  NPC_TINT_B  = 0.40, 0.55, 0.85  -- cool/blue
    local ITEM_TINT_R, ITEM_TINT_G, ITEM_TINT_B = 0.85, 0.65, 0.30  -- warm/amber

    local addItemBtn = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    addItemBtn:SetSize(ADD_BTN_W, ADD_BTN_H)
    addItemBtn:SetPoint("BOTTOMRIGHT", -WINDOW_PAD, FOOTER_TOP_Y)
    addItemBtn:SetText("Add by Item")
    addItemBtn:SetScript("OnClick", function()
        editPanel:close()
        if Addon.itemAddPanel then Addon.itemAddPanel:open(ui) end
    end)
    local itemStripe = addItemBtn:CreateTexture(nil, "OVERLAY")
    itemStripe:SetColorTexture(ITEM_TINT_R, ITEM_TINT_G, ITEM_TINT_B, 1.0)
    itemStripe:SetPoint("TOPLEFT",    addItemBtn, "TOPLEFT",    1, -1)
    itemStripe:SetPoint("BOTTOMLEFT", addItemBtn, "BOTTOMLEFT", 1,  1)
    itemStripe:SetWidth(STRIPE_W)

    local addNpcBtn = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    addNpcBtn:SetSize(ADD_BTN_W, ADD_BTN_H)
    addNpcBtn:SetPoint("RIGHT", addItemBtn, "LEFT", -8, 0)
    addNpcBtn:SetText("Add by NPC")
    addNpcBtn:SetScript("OnClick", function()
        if Addon.itemAddPanel then Addon.itemAddPanel:close() end
        openAddFor()
    end)
    local npcStripe = addNpcBtn:CreateTexture(nil, "OVERLAY")
    npcStripe:SetColorTexture(NPC_TINT_R, NPC_TINT_G, NPC_TINT_B, 1.0)
    npcStripe:SetPoint("TOPLEFT",    addNpcBtn, "TOPLEFT",    1, -1)
    npcStripe:SetPoint("BOTTOMLEFT", addNpcBtn, "BOTTOMLEFT", 1,  1)
    npcStripe:SetWidth(STRIPE_W)

    -- Close button (bottom-right of footer). Same size as Add Entry.
    -- Hides the main window via the same path as the title-bar X
    -- (UI:Hide → OnHide → propagates editPanel close, etc.).
    local closeBtn = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    closeBtn:SetSize(ADD_BTN_W, ADD_BTN_H)
    closeBtn:SetPoint("BOTTOMRIGHT", -WINDOW_PAD, FOOTER_BOTTOM_Y)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function() ui:Hide() end)

    -- Closing the main window propagates to the panel.
    -- Context menus auto-close via menuRenderer's outside-click watcher.
    ui:SetScript("OnHide", function()
        editPanel:close()
        if Addon.itemAddPanel then Addon.itemAddPanel:close() end
    end)
end

function watchList:initialize()
    constants   = Addon.constants
    scanner     = Addon.scanner
    editPanel   = Addon.editPanel
    contextMenu = Addon.contextMenu
    tooltip     = Addon.tooltip

    if not constants or not scanner or not editPanel then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444watchList: Missing dependencies|r")
        return false
    end

    -- contextMenu and tooltip are technically optional; the addon
    -- works without them (no menus, no reason hover) but the UX is
    -- incomplete. Warn rather than fail.
    if not contextMenu then
        print("|cff33ff99" .. ADDON_NAME .. "|r: watchList: contextMenu unavailable; right-click menus disabled")
    end
    if not tooltip then
        print("|cff33ff99" .. ADDON_NAME .. "|r: watchList: tooltip unavailable; reason hover disabled")
    end

    buildFrame()
    watchList:refresh()
    return true
end

Addon.watchList = watchList
return watchList
