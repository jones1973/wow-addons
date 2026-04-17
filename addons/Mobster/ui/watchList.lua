--[[
  ui/watchList.lua
  Watch list UI — the Mobster main window

  A draggable frame listing current watch patterns with add/remove controls
  and sound/mark toggles. ESC-closable via UISpecialFrames.

  Rows support hover highlighting and click-to-edit. Clicking a row loads
  its text into the edit box. Clicking the same row again or pressing Esc
  in the edit box cancels edit mode. The action button is always "Apply" —
  it adds a new entry when no row is being edited, or replaces the edited
  entry otherwise.

  As the user types, a typeahead dropdown (see ui/typeahead.lua) queries
  Questie for matching NPCs. Picking a result fills the edit box and
  attaches the NPC's zone to the pending entry, so the scanner will only
  match that mob when the player is in the chosen zone.

  Entries in mobster_character.watchList take one of two forms:
    - a string: freeform partial-match pattern, matches any mob name
      containing the string, in any zone;
    - a table { pattern = "...", zone = "..." }: produced when the user
      picks a Questie result, locking the match to that NPC's zone.

  The main frame is named (required for UISpecialFrames). All children are
  anonymous except the two checkboxes, which carry names because
  UICheckButtonTemplate has historically been finicky without them.

  Dependencies: constants, scanner, typeahead
  Exports: Addon.watchList
]]

local ADDON_NAME, Addon = ...

local watchList = {}

-- Module references (resolved at init)
local constants, scanner, typeahead

-- UI state
local ui
local scrollChild
local editBox       -- the text input
local actionBtn     -- Apply button (always "Apply")
local rowPool       -- Addon.pool instance, created in build()
local activeRows = {} -- rows currently on-screen; released each refresh
local editIndex     -- index being edited, or nil for add mode
local pendingZone   -- zone attached by a typeahead pick; nil otherwise.
                    -- Cleared whenever the user types (breaking the
                    -- NPC<->pattern association), and whenever edit mode
                    -- resets.

local FRAME_NAME = ADDON_NAME .. "UI"

-- ============================================================================
-- LAYOUT (file-local; overrides the tighter shared constants.ROW_* values
-- because this window needs two-line rows and generous padding that the
-- generic defaults don't account for).
-- ============================================================================

local WINDOW_W       = 360
local WINDOW_H       = 460
local WINDOW_PAD     = 16   -- breathing room inside the dialog border
local SCROLL_TOP_Y   = -52  -- below the title
local SCROLL_BOT_Y   = 132  -- above the input area + checkboxes

local ROW_H          = 40   -- uniform; fits name + optional zone line
local ROW_NAME_TOP   = 8    -- name fontstring y-offset from row top
local ROW_ZONE_TOP   = 24   -- zone fontstring y-offset from row top
local ROW_PAD_LEFT   = 12
local ROW_PAD_RIGHT  = 36   -- delete button lives in this gutter
local ROW_ZONE_INDENT = 4   -- zone is indented a touch under the name

local DEL_SIZE       = 22
local DEL_RIGHT_PAD  = 8

local INPUT_W        = 220
local INPUT_H        = 28
local INPUT_BOTTOM_Y = 84
local BTN_W          = 64
local BTN_H          = 28
local BTN_GAP        = 10   -- between edit box and Apply button

local CHECK_BOTTOM_Y = 40
local CHECK_H_GAP    = 28   -- between the two checkboxes

local HOVER_R, HOVER_G, HOVER_B, HOVER_A = 1, 1, 1, 0.1
local EDIT_R,  EDIT_G,  EDIT_B,  EDIT_A  = 0.3, 0.6, 1, 0.2

-- ============================================================================
-- EDIT MODE
-- ============================================================================

local function enterEditMode(index)
    editIndex = index
    local entry = mobster_character.watchList[index]

    -- Freeform entries are strings; Questie-picked entries are tables.
    local pattern = (type(entry) == "string") and entry or entry.pattern or ""
    pendingZone = (type(entry) == "table") and entry.zone or nil

    -- SetText fires OnTextChanged with userInput=false, which our handler
    -- ignores — so loading a pattern here won't pop the typeahead dropdown.
    editBox:SetText(pattern)
    editBox:SetCursorPosition(#pattern)
    editBox:SetFocus()

    if typeahead then typeahead:hide() end
    watchList:refresh()
end

local function exitEditMode()
    editIndex   = nil
    pendingZone = nil
    editBox:SetText("")
    editBox:ClearFocus()

    if typeahead then typeahead:hide() end
    watchList:refresh()
end

-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

local function doSubmit()
    local text = (editBox:GetText() or ""):trim()
    if text == "" then return end

    -- Freeform input stays as a plain string; only a Questie-picked entry
    -- (with a zone stashed from the typeahead) becomes a structured table.
    local entry
    if pendingZone then
        entry = { pattern = text, zone = pendingZone }
    else
        entry = text
    end

    if editIndex then
        -- Replace existing entry
        mobster_character.watchList[editIndex] = entry
    else
        -- Add new entry
        table.insert(mobster_character.watchList, entry)
    end

    if typeahead then typeahead:hide() end
    scanner:resetTracking()
    exitEditMode()
end

local function onRemoveEntry(index)
    table.remove(mobster_character.watchList, index)
    -- If we were editing this or a later row, cancel edit mode
    if editIndex then
        exitEditMode()
    end
    scanner:resetTracking()
    watchList:refresh()
end

local function makeRow(parent)
    -- Button base so we get OnClick, OnEnter, OnLeave for free
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_H)
    -- Width is set by anchoring in refresh() (full scroll-child width).

    -- Hover/edit highlight background
    local highlight = row:CreateTexture(nil, "BACKGROUND")
    highlight:SetAllPoints()
    highlight:SetColorTexture(HOVER_R, HOVER_G, HOVER_B, HOVER_A)
    highlight:Hide()
    row.highlight = highlight

    -- Name (always shown). Anchored top with left/right padding so it
    -- flexes with the row width and clamps before hitting the delete button.
    local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    name:SetPoint("TOPLEFT", ROW_PAD_LEFT, -ROW_NAME_TOP)
    name:SetPoint("TOPRIGHT", -ROW_PAD_RIGHT, -ROW_NAME_TOP)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    row.name = name

    -- Zone (shown only when the entry has one). Smaller, gray, indented.
    local zone = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    zone:SetPoint("TOPLEFT", ROW_PAD_LEFT + ROW_ZONE_INDENT, -ROW_ZONE_TOP)
    zone:SetPoint("TOPRIGHT", -ROW_PAD_RIGHT, -ROW_ZONE_TOP)
    zone:SetJustifyH("LEFT")
    zone:SetWordWrap(false)
    row.zone = zone

    local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    del:SetSize(DEL_SIZE, DEL_SIZE)
    del:SetPoint("RIGHT", -DEL_RIGHT_PAD, 0)
    del:SetText("X")
    del:SetScript("OnClick", function(self)
        onRemoveEntry(self.index)
    end)
    row.del = del

    row:SetScript("OnEnter", function(self)
        if self.index ~= editIndex then
            self.highlight:SetColorTexture(HOVER_R, HOVER_G, HOVER_B, HOVER_A)
            self.highlight:Show()
        end
    end)

    row:SetScript("OnLeave", function(self)
        if self.index ~= editIndex then
            self.highlight:Hide()
        end
    end)

    row:SetScript("OnClick", function(self)
        if self.index == editIndex then
            exitEditMode()
        else
            enterEditMode(self.index)
        end
    end)

    return row
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Toggle the watch list window visibility.
]]
function watchList:toggle()
    if not ui then return end
    if ui:IsShown() then ui:Hide() else ui:Show() end
end

--[[
  Rebuild the watch list rows from mobster_character.watchList.
  Each refresh releases all current rows and re-acquires from the pool,
  so rows recycle naturally as the list grows and shrinks.
  The currently-edited row gets a persistent highlight.
]]
function watchList:refresh()
    local list = mobster_character.watchList

    rowPool:releaseAll(activeRows)

    for i, entry in ipairs(list) do
        local row = rowPool:acquire()

        -- Entries are strings (freeform) or tables (zone-locked).
        local pattern, zone
        if type(entry) == "string" then
            pattern, zone = entry, nil
        else
            pattern, zone = entry.pattern or "", entry.zone
        end

        row.name:SetText(pattern)
        if zone and zone ~= "" then
            row.zone:SetText("(" .. zone .. ")")
            row.zone:Show()
        else
            row.zone:SetText("")
            row.zone:Hide()
        end

        row.del.index = i
        row.index = i
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
        row:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_H)
        row:Show()

        -- Persistent highlight on the row being edited
        if i == editIndex then
            row.highlight:SetColorTexture(EDIT_R, EDIT_G, EDIT_B, EDIT_A)
            row.highlight:Show()
        else
            row.highlight:Hide()
        end

        activeRows[#activeRows + 1] = row
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

    -- Restore saved position
    if mobster_character.framePos then
        local p = mobster_character.framePos
        ui:ClearAllPoints()
        ui:SetPoint(p[1], UIParent, p[1], p[2], p[3])
    end

    ui:Hide()

    -- ESC-to-close
    tinsert(UISpecialFrames, FRAME_NAME)

    -- Title
    local title = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -WINDOW_PAD)
    title:SetText("Mobster")

    -- Close button
    local close = CreateFrame("Button", nil, ui, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    -- Scroll area — generous top clearance below title; bottom stops well
    -- above the input row so the input area has its own breathing room.
    local scroll = CreateFrame("ScrollFrame", nil, ui, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", WINDOW_PAD, SCROLL_TOP_Y)
    scroll:SetPoint("BOTTOMRIGHT", -WINDOW_PAD - 20, SCROLL_BOT_Y)

    scrollChild = CreateFrame("Frame", nil, scroll)
    -- Width is set from the scroll frame's width; rows anchor to scrollChild's
    -- left/right so they flex automatically.
    scrollChild:SetWidth(WINDOW_W - WINDOW_PAD * 2 - 20)
    scrollChild:SetHeight(1)
    scroll:SetScrollChild(scrollChild)

    -- Initialize the shared row pool. The factory closes over scrollChild
    -- (as the parent for new rows), so the pool cannot be constructed at
    -- module load time.
    rowPool = Addon.pool:new(function() return makeRow(scrollChild) end)

    -- Separator above the input area (not pinned to scroll bottom; sits
    -- in the gap between the scroll area and the input row).
    local sep = ui:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("LEFT", WINDOW_PAD, 0)
    sep:SetPoint("RIGHT", -WINDOW_PAD, 0)
    sep:SetPoint("BOTTOM", 0, INPUT_BOTTOM_Y + INPUT_H + 12)
    sep:SetColorTexture(0.4, 0.4, 0.4, 0.6)

    -- Edit box + action button
    editBox = CreateFrame("EditBox", nil, ui, "InputBoxTemplate")
    editBox:SetSize(INPUT_W, INPUT_H)
    -- InputBoxTemplate renders decorative caps outside its box; inset the
    -- left anchor a bit so those caps don't clip the window border.
    editBox:SetPoint("BOTTOMLEFT", WINDOW_PAD + 8, INPUT_BOTTOM_Y)
    editBox:SetAutoFocus(false)
    editBox:SetMaxLetters(60)
    editBox:SetTextInsets(4, 4, 2, 2)

    actionBtn = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    actionBtn:SetSize(BTN_W, BTN_H)
    actionBtn:SetPoint("LEFT", editBox, "RIGHT", BTN_GAP, 0)
    actionBtn:SetText("Apply")

    actionBtn:SetScript("OnClick", doSubmit)
    editBox:SetScript("OnEnterPressed", doSubmit)
    editBox:SetScript("OnEscapePressed", function()
        if editIndex then
            exitEditMode()
        else
            if typeahead then typeahead:hide() end
            editBox:ClearFocus()
        end
    end)

    -- User-driven text changes: clear any zone stashed by a prior typeahead
    -- pick (since the pattern no longer corresponds to that NPC), and ask
    -- the typeahead to refresh. Programmatic SetText arrives with
    -- userInput=false and is ignored here.
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        pendingZone = nil
        if typeahead then typeahead:onQuery(self:GetText()) end
    end)

    -- Typeahead picks fill the edit box without firing our OnTextChanged
    -- (we use SetText which passes userInput=false), so pendingZone remains
    -- set until either Apply commits or the user types something.
    local function onTypeaheadPick(name, zone)
        editBox:SetText(name)
        editBox:SetCursorPosition(#name)
        editBox:SetFocus()
        pendingZone = zone
    end

    -- Typeahead dropdown covers the scroll area while the user types; width
    -- matches the scrollChild so it lines up visually with the rows it's
    -- suggesting alternatives for.
    if Addon.typeahead then
        Addon.typeahead:attach(editBox, ui, scrollChild:GetWidth(), onTypeaheadPick)
    end

    -- Sound checkbox
    local soundCB = CreateFrame("CheckButton", FRAME_NAME .. "SoundCB", ui, "UICheckButtonTemplate")
    soundCB:SetPoint("BOTTOMLEFT", WINDOW_PAD, CHECK_BOTTOM_Y)
    soundCB:SetSize(24, 24)
    soundCB:SetChecked(mobster_character.soundEnabled)
    soundCB:SetScript("OnClick", function(self)
        mobster_character.soundEnabled = self:GetChecked() and true or false
    end)
    local soundLbl = soundCB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    soundLbl:SetPoint("LEFT", soundCB, "RIGHT", 4, 0)
    soundLbl:SetText("Sound")

    -- Mark checkbox
    local markCB = CreateFrame("CheckButton", FRAME_NAME .. "MarkCB", ui, "UICheckButtonTemplate")
    markCB:SetPoint("LEFT", soundLbl, "RIGHT", CHECK_H_GAP, 0)
    markCB:SetSize(24, 24)
    markCB:SetChecked(mobster_character.markEnabled)
    markCB:SetScript("OnClick", function(self)
        mobster_character.markEnabled = self:GetChecked() and true or false
    end)
    local markLbl = markCB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    markLbl:SetPoint("LEFT", markCB, "RIGHT", 4, 0)
    markLbl:SetText("Mark (solo only)")
end

function watchList:initialize()
    constants = Addon.constants
    scanner   = Addon.scanner
    typeahead = Addon.typeahead

    if not constants or not scanner then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444watchList: Missing dependencies|r")
        return false
    end

    -- Typeahead is optional. If it's not loaded, the addon still works;
    -- the dropdown just never appears.
    if not typeahead then
        print("|cff33ff99" .. ADDON_NAME .. "|r: typeahead unavailable; continuing without it")
    end

    buildFrame()
    watchList:refresh()
    return true
end

Addon.watchList = watchList
return watchList
