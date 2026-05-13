--[[
  ui/editPanel.lua
  Slide-out edit panel — name, zone, and reason fields

  Anchored to the right edge of the main window with the panel's left
  border superimposed on the main window's right border, this panel is
  the single editor for watch list entries. Both "Add" and "Edit" route
  through here: the main window opens it empty for adds, populated for
  edits. Save commits the entry via a caller-provided callback; Cancel
  discards.

  Field semantics:
    name    - Required. The (case-insensitive) substring matched against
              UnitName at scan time. May carry a trailing " (N)" or " (H)"
              difficulty marker; the scanner strips it.
    zone    - Optional. When set, the entry only matches in that zone.
              Has its own typeahead backed by Questie's zone list.
    reason  - Optional. Free-form note shown in the watch list as a
              hover-icon. Single-line, capped at 200 characters.

  The name field has the NPC name typeahead (nameTypeahead) attached.
  Picking from it fills name and auto-fills zone if the picked NPC
  has zone data, but never touches reason. The zone field has the
  zone typeahead (zoneTypeahead) attached, which presents zones from
  Questie's spawn data.

  Save button is disabled while name is empty (or whitespace-only),
  preventing the most common invalid entry without needing a separate
  validation message. Cancel and Save sit in the bottom-right per
  Blizzard convention (Save left of Cancel, mirroring StaticPopup's
  button1=ACCEPT/button2=CANCEL layout).

  Dependencies: searchBox (which depends on textBox), panel,
                nameTypeahead, zoneTypeahead, reasonTypeahead
  Exports: Addon.editPanel
]]

local ADDON_NAME, Addon = ...

local editPanel = {}

-- Module references (resolved at init)
local nameTypeahead
local zoneTypeahead
local reasonTypeahead

-- ============================================================================
-- LAYOUT
-- ============================================================================

local PANEL_W       = 280
local PANEL_H       = 460   -- matches main window height
local PANEL_PAD     = 16

-- Both the main window and this panel use UI-DialogBox-Border with insets
-- {left=11, right=12, top=12, bottom=11}. The panel's outer-left
-- aligns exactly with the main window's outer-right (anchor x=0)
-- so the two borders sit adjacent. The animation controller's
-- anchor configuration (in :open) carries this convention.

local LABEL_HEIGHT  = 14    -- approximate GameFontNormal cap height
local LABEL_GAP     = 4     -- space between label baseline and edit box top
local FIELD_GAP     = 18    -- vertical space between adjacent fields

local INPUT_H       = 26    -- textBox default height for GameFontNormalSmall
local TITLE_TOP_Y   = -16
local NAME_LBL_Y    = -56

-- Vertical step between consecutive label-Y anchors. One row =
-- label + gap + box + gap.
local FIELD_STEP    = LABEL_HEIGHT + LABEL_GAP + INPUT_H + FIELD_GAP

local BTN_W         = 72
local BTN_H         = 28
local BTN_BOTTOM_Y  = 20
local BTN_GAP       = 8

local REASON_MAX_LETTERS = 200
local NAME_MAX_LETTERS   = 80
local ZONE_MAX_LETTERS   = 64

-- ============================================================================
-- UI STATE
-- ============================================================================

local panelFrame
local titleFS
local nameBox
local zoneBox
local reasonBox
local saveBtn

-- The watchList-supplied callback fired when Save is clicked. Receives a
-- {name, zone, reason} table; nil-or-empty zone/reason dropped by the
-- caller before save.
local onSubmitFn

-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

local function trim(s)
    if not s then return "" end
    return s:match("^%s*(.-)%s*$") or ""
end

local function refreshSaveEnabled()
    if not saveBtn or not nameBox then return end
    local hasContent = trim(nameBox:GetText() or "") ~= ""
    saveBtn:SetEnabled(hasContent)
end

--[[
  Apply a {name, zone, reason} table to the panel's fields, or clear all
  fields when entryData is nil (add mode). textBox provides SetBoxText
  which also updates placeholder visibility.

  @param entryData table|nil
]]
local function loadFields(entryData)
    entryData = entryData or {}
    nameBox:SetBoxText(entryData.name or "")
    zoneBox:SetBoxText(entryData.zone or "")
    reasonBox:SetBoxText(entryData.reason or "")
    nameBox:SetCursorPosition(#(entryData.name or ""))
    nameBox:SetFocus()
    refreshSaveEnabled()
end

local function doSave()
    if not onSubmitFn then
        editPanel:close()
        return
    end

    local name = trim(nameBox:GetText() or "")
    if name == "" then return end  -- defense in depth

    local zone   = trim(zoneBox:GetText() or "")
    local reason = trim(reasonBox:GetText() or "")

    onSubmitFn({
        name   = name,
        zone   = (zone   ~= "") and zone   or nil,
        reason = (reason ~= "") and reason or nil,
    })

    editPanel:close()
end

local function doCancel()
    editPanel:close()
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- ============================================================================
-- ANIMATION
-- ============================================================================
--
-- Animation is owned by panel.lua. We hold one controller per parent;
-- :open() builds it on first use (and rebuilds if the caller passes a
-- different parent next time, though in practice the parent doesn't
-- change). Show/hide just delegate to the controller.

local ANIM_DURATION = 0.2

local panelController     -- nil until first :open
local controllerParent    -- the parent the current controller is bound to

local function ensureController(parent)
    if panelController and controllerParent == parent then
        return
    end
    -- Tear down the old controller before replacing it. destroy() runs
    -- the per-transform reset chain and restores controller-level
    -- frame state (parent, level, clipsChildren) so the new controller
    -- starts from a clean slate. Without this, the panel inherits
    -- whatever the old controller's last animation left behind.
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
            -- Wipe (width grow) — anchor stays at main's right edge,
            -- width animates from 0 to full. With clipsChildren on
            -- the panel, contents reveal left-to-right as width grows.
            -- Visual effect: panel grows out of main's right edge,
            -- retracts back into it on close.
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

--[[
  Open the panel, populated for editing or empty for adding.

  @param parent Frame    - Frame whose right edge the panel anchors to.
  @param entryData table|nil - {name, zone, reason} to pre-fill, or nil
                               for add mode.
  @param onSave function  - Called with {name, zone, reason} when Save
                            is clicked. Not called on Cancel.
]]
function editPanel:open(parent, entryData, onSave)
    if not panelFrame then return end

    onSubmitFn = onSave
    titleFS:SetText(entryData and "Edit Entry" or "Add Entry")

    ensureController(parent)
    loadFields(entryData)
    panelController:show()
end

function editPanel:close()
    if not panelFrame then return end
    onSubmitFn = nil
    if nameTypeahead then nameTypeahead:hide() end
    if zoneTypeahead then zoneTypeahead:hide() end
    if reasonTypeahead then reasonTypeahead:hide() end
    if panelController then panelController:hide() end
end

function editPanel:isOpen()
    if not panelController then return false end
    return panelController:isOpen()
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

--[[
  Create one labeled searchBox at the given Y. searchBox is textBox + a
  clear-button affordance, so users can wipe a field with one click. We
  use it for all three editPanel fields since the clear button is
  always-applicable polish, not field-specific.

  @param parent Frame
  @param labelText string
  @param labelY number   - Y of the label's TOP, negative offset from parent top
  @param maxLetters number
  @param placeholder string|nil
  @param onTextChanged function|nil
  @return EditBox
]]
local function buildField(parent, labelText, labelY, maxLetters, placeholder, onTextChanged)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", PANEL_PAD, labelY)
    label:SetText(labelText)

    local box = Addon.searchBox:create({
        parent          = parent,
        width           = PANEL_W - PANEL_PAD * 2,
        height          = INPUT_H,
        placeholder     = placeholder or "",
        maxLetters      = maxLetters,
        onTextChanged   = onTextChanged,
        onEnterPressed  = doSave,
        onEscapePressed = doCancel,
    })
    box:ClearAllPoints()
    box:SetPoint("TOPLEFT", PANEL_PAD, labelY - LABEL_HEIGHT - LABEL_GAP)

    return box
end

local function buildFrame()
    panelFrame = Addon.panel:opaque(UIParent, {
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 32,
        insets   = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    panelFrame:SetSize(PANEL_W, PANEL_H)
    panelFrame:SetFrameStrata("DIALOG")
    panelFrame:EnableMouse(true)
    panelFrame:Hide()

    -- Title
    titleFS = panelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleFS:SetPoint("TOP", 0, TITLE_TOP_Y)
    titleFS:SetText("Add Entry")

    -- Name field. Wires its text-change handler to the nameTypeahead and to
    -- save-button enable state.
    nameBox = buildField(panelFrame, "Name", NAME_LBL_Y, NAME_MAX_LETTERS,
        "Captain Skarloc",
        function(text, userInput)
            refreshSaveEnabled()
            if userInput and nameTypeahead then
                nameTypeahead:onQuery(text)
            end
        end)

    zoneBox = buildField(panelFrame, "Zone (optional)",
        NAME_LBL_Y - FIELD_STEP, ZONE_MAX_LETTERS,
        "Old Hillsbrad Foothills",
        function(text, userInput)
            if userInput and zoneTypeahead then
                zoneTypeahead:onQuery(text)
            end
        end)

    reasonBox = buildField(panelFrame, "Reason (optional)",
        NAME_LBL_Y - 2 * FIELD_STEP, REASON_MAX_LETTERS,
        "Ironshield Potion Recipe",
        function(text, userInput)
            if userInput and reasonTypeahead then
                reasonTypeahead:onQuery(text)
            end
        end)

    -- Save / Cancel along the bottom edge. Convention in this monorepo
    -- (and Blizzard's StaticPopup): primary action LEFT of cancel.
    -- PawAndOrder's bandage confirm follows the same pattern.
    -- Layout: ... [Save] [Cancel] ] — Cancel rightmost, Save to its left.
    local cancelBtn = CreateFrame("Button", nil, panelFrame, "UIPanelButtonTemplate")
    cancelBtn:SetSize(BTN_W, BTN_H)
    cancelBtn:SetPoint("BOTTOMRIGHT", -PANEL_PAD, BTN_BOTTOM_Y)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", doCancel)

    saveBtn = CreateFrame("Button", nil, panelFrame, "UIPanelButtonTemplate")
    saveBtn:SetSize(BTN_W, BTN_H)
    saveBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -BTN_GAP, 0)
    saveBtn:SetText("Save")
    saveBtn:SetScript("OnClick", doSave)

    -- Hide the nameTypeahead when the name field loses focus, so a quick
    -- click on Save (which steals focus) doesn't leave the dropdown
    -- floating after the panel hides.
    nameBox:HookScript("OnEditFocusLost", function()
        if nameTypeahead then nameTypeahead:hide() end
    end)
    zoneBox:HookScript("OnEditFocusLost", function()
        if zoneTypeahead then zoneTypeahead:hide() end
    end)

    -- Reason field: when focus is gained, set the NPC context for
    -- the reason typeahead from the current Name field. This is JIT —
    -- we only resolve drops when the user is actually about to use
    -- them. When focus is lost, hide the dropdown along the same
    -- pattern as name/zone.
    reasonBox:HookScript("OnEditFocusGained", function()
        if reasonTypeahead then
            local nameText = nameBox:GetText() or ""
            reasonTypeahead:setNpcContext(nameText)
        end
    end)
    reasonBox:HookScript("OnEditFocusLost", function()
        if reasonTypeahead then reasonTypeahead:hide() end
    end)

    -- Two-stage Escape / Enter for typeahead-aware fields. The shared
    -- searchBox wires Escape to doCancel and Enter to doSave directly,
    -- which is fine for plain text fields but wrong here: pressing
    -- those keys while a typeahead dropdown is showing should act on
    -- the dropdown first, the form second. SetScript replaces the
    -- searchBox handler entirely. If no dropdown is showing, fall
    -- through to the original behavior (cancel/save).
    local function escapeTwoStage(typeaheadModule)
        return function()
            if typeaheadModule and typeaheadModule:isShown() then
                typeaheadModule:hide()
            else
                doCancel()
            end
        end
    end
    local function enterTwoStage(typeaheadModule)
        return function(self)
            -- Enter while a dropdown is up commits the highlighted
            -- row if the user navigated to one with the arrow keys;
            -- if nothing's highlighted, treat Enter as "I'm done
            -- with this dropdown, keep what I typed" — dismiss the
            -- dropdown without submitting the form. When the
            -- dropdown isn't up at all, Enter submits as before.
            if typeaheadModule and typeaheadModule:isShown() then
                if not typeaheadModule:commitHighlight() then
                    typeaheadModule:hide()
                end
            else
                doSave()
            end
        end
    end
    nameBox:SetScript("OnEscapePressed", escapeTwoStage(nameTypeahead))
    zoneBox:SetScript("OnEscapePressed", escapeTwoStage(zoneTypeahead))
    reasonBox:SetScript("OnEscapePressed", escapeTwoStage(reasonTypeahead))
    nameBox:SetScript("OnEnterPressed",  enterTwoStage(nameTypeahead))
    zoneBox:SetScript("OnEnterPressed",  enterTwoStage(zoneTypeahead))
    reasonBox:SetScript("OnEnterPressed", enterTwoStage(reasonTypeahead))

    -- Up/Down arrow nav for the typeahead dropdown. On UP/DOWN,
    -- consume the key (so it doesn't bubble to the game) and move
    -- the picker highlight. For every other key, do nothing — the
    -- EditBox's default key handling takes care of typing, cursor
    -- movement, etc. Calling SetPropagateKeyboardInput(true) here
    -- would broadcast the keystroke to the game world (S → walk
    -- backward, C → character pane, etc.), which is the bug r5.15
    -- shipped with. Touching propagation only when we handle the
    -- key is the right scope.
    local function keyNav(typeaheadModule)
        return function(self, key)
            if not typeaheadModule or not typeaheadModule:isShown() then return end
            if key == "UP" then
                typeaheadModule:moveHighlight(-1)
                self:SetPropagateKeyboardInput(false)
            elseif key == "DOWN" then
                typeaheadModule:moveHighlight(1)
                self:SetPropagateKeyboardInput(false)
            end
        end
    end
    nameBox:SetScript("OnKeyDown",   keyNav(nameTypeahead))
    zoneBox:SetScript("OnKeyDown",   keyNav(zoneTypeahead))
    reasonBox:SetScript("OnKeyDown", keyNav(reasonTypeahead))

    -- Click on the panel's empty background dismisses any visible
    -- typeahead. Clicks on child widgets (fields, buttons, the
    -- dropdown itself which is parented to UIParent) don't bubble
    -- to this handler, so it only fires for genuinely empty panel
    -- area. Without this, the user has no way to dismiss a dropdown
    -- short of submitting, canceling, or moving focus to another
    -- field.
    panelFrame:SetScript("OnMouseDown", function()
        if nameTypeahead   and nameTypeahead:isShown()   then nameTypeahead:hide()   end
        if zoneTypeahead   and zoneTypeahead:isShown()   then zoneTypeahead:hide()   end
        if reasonTypeahead and reasonTypeahead:isShown() then reasonTypeahead:hide() end
    end)

    -- NPC nameTypeahead. Name field sits near the top of the panel; the
    -- dropdown grows downward to avoid clipping outside.
    local function onTypeaheadPick(name, zone)
        nameBox:SetBoxText(name)
        nameBox:SetCursorPosition(#name)
        nameBox:SetFocus()
        if zone then
            zoneBox:SetBoxText(zone)
        end
        refreshSaveEnabled()
    end

    if Addon.nameTypeahead then
        local dropdownWidth = PANEL_W - PANEL_PAD * 2
        -- Parent the dropdown to UIParent (not the panel) so the
        -- panel's SetClipsChildren(true) doesn't clip the dropdown
        -- where it extends below the panel's bottom edge. The
        -- dropdown is still positionally anchored to the editbox
        -- (handled inside picker:attach) so it visually tracks the
        -- panel; only its parenting differs.
        Addon.nameTypeahead:attach(nameBox, UIParent, dropdownWidth,
            onTypeaheadPick, { growDownward = true, strata = "DIALOG" })
    end

    -- Zone typeahead, attached to the zone field. Picks fill the zone
    -- box only — they don't move focus, since the user typically goes
    -- on to the reason field next.
    local function onZonePick(zoneName)
        zoneBox:SetBoxText(zoneName)
        zoneBox:SetCursorPosition(#zoneName)
    end

    if Addon.zoneTypeahead then
        local dropdownWidth = PANEL_W - PANEL_PAD * 2
        Addon.zoneTypeahead:attach(zoneBox, UIParent, dropdownWidth,
            onZonePick, { growDownward = true, strata = "DIALOG" })
    end

    -- Reason typeahead, attached to the reason field. Picks fill the
    -- reason box only — final field, no need to chain focus.
    local function onReasonPick(itemName)
        reasonBox:SetBoxText(itemName)
        reasonBox:SetCursorPosition(#itemName)
    end

    if Addon.reasonTypeahead then
        local dropdownWidth = PANEL_W - PANEL_PAD * 2
        Addon.reasonTypeahead:attach(reasonBox, UIParent, dropdownWidth,
            onReasonPick, { growDownward = true, strata = "DIALOG" })
    end
end

function editPanel:initialize()
    nameTypeahead     = Addon.nameTypeahead
    zoneTypeahead     = Addon.zoneTypeahead
    reasonTypeahead   = Addon.reasonTypeahead

    if not Addon.panel then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444editPanel: Missing dependency 'panel'|r")
        return false
    end
    if not Addon.searchBox then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444editPanel: Missing dependency 'searchBox'|r")
        return false
    end

    -- All three typeaheads are optional; the panel still functions
    -- without them, just without autocomplete on those fields.
    if not nameTypeahead then
        print("|cff33ff99" .. ADDON_NAME .. "|r: editPanel: nameTypeahead unavailable; name field will be plain text")
    end
    if not zoneTypeahead then
        print("|cff33ff99" .. ADDON_NAME .. "|r: editPanel: zoneTypeahead unavailable; zone field will be plain text")
    end
    if not reasonTypeahead then
        print("|cff33ff99" .. ADDON_NAME .. "|r: editPanel: reasonTypeahead unavailable; reason field will be plain text")
    end

    buildFrame()
    return true
end

Addon.editPanel = editPanel
return editPanel
