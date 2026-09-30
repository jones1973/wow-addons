--[[
  ui/activityRail.lua
  Activity Rail Component

  The window's left navigation: a fixed-width vertical rail of activities the
  character has, grouped and headed (Professions / Processing / Secondary /
  Gathering), driven by logic/activityModel. Selecting a row reports out
  through config.onSelect(activity); the composer owns what a selection does
  and calls back into refresh(). The rail holds no view state - the viewed
  activity is read through config.viewed().

  The selected profession's tool actions (anvil, campfire, vellum target) live
  in a SHELF that slides out under its row: tools belong to a profession, and
  hanging them off its row says so. The shelf's height pushes the rows below it
  down through the same one-variable discipline the discovery tray uses. A
  profession with no tools has no shelf; the absence is meaningful.

  Customize Activities is a button pinned to the rail's bottom; its editor is a
  later phase. The button exists now because the rail's structure is complete
  now - hidden/reordered state is already honored by the model this reads from.

  The composer drives the rail through this contract:

    rail:getFrame()            anchor into the window (left edge)
    rail:refresh()             lay out from the model + current viewed()
    rail:retire(profID, onDone) a profession was unlearned; onDone fires when
                               the row is gone (the composer's unlearn handoff
                               waits on it)
    rail:arrived(profID)       mark a profession that learned something while
                               unviewed; the mark clears when it is viewed
    rail:nodTools()            the guidance nod when a craft hit a missing tool
    rail:repaintTools()        refresh tool availability + cooldown + counts

  UI only: frames and rendering. Activity truth comes from activityModel; tool
  facts from profTools; nothing here scans or computes skill.

  Dependencies: motion, theme, tooltip, activityModel, profTools, professionHarvester,
                recipeView
  Exports: Addon.activityRail
]]

local ADDON_NAME, Addon = ...

local activityRail = {}

-- Rail geometry. Fixed width - navigation does not stretch; the resize grip
-- grows the workspace to its right. Rows are tall enough for icon + name +
-- skill stacked, on the 8pt grid.
local RAIL_WIDTH   = 210
local ROW_H        = 44
local ROW_GAP      = 4
local ICON_SIZE    = 32
local EYE_SIZE     = 16   -- the edit-mode hide/show toggle swatch
local HEADING_H    = 20
local GROUP_GAP    = 12
local EDGE_PAD     = 12
local TOP_PAD      = 12
local TEXT_INSET   = ICON_SIZE + 20   -- left of the name/skill text
local TOOL_SIZE    = 34
local TOOL_GAP     = 6
local SHELF_PAD    = 6                 -- shelf inset from the row's left text edge
local CUSTOMIZE_H  = 28

-- Group headings, resolved to display text. The model's keys are stable
-- ids; the labels are the rail's to choose (and to localize later against
-- GlobalStrings where they exist - PROFESSIONS_ARCHAEOLOGY has no "Processing"
-- sibling, so these stay Crafty's strings for now).
local GROUP_LABEL = {
    professions = "PROFESSIONS",
    processing  = "PROCESSING",
    secondary   = "SECONDARY",
    gathering   = "GATHERING",
}

-- A processing verb's display name. The conversion engine keys on the lower
-- verb ("milling"); the row shows it titled. Not the spell name ("Milling" is
-- the ability, but "Disenchanting" has no spell name at all - it is an action
-- the client never surfaces as a castable), so these are Crafty's.
local VERB_LABEL = {
    milling      = "Milling",
    prospecting  = "Prospecting",
    disenchanting = "Disenchanting",
}

-- Processing rows need an icon; there is no profession-info icon for a verb.
-- The verb's own spell/ability icon where one exists, chosen by hand because
-- the ability id is not in Crafty's data and deriving it would be a lookup
-- with no table behind it.
local VERB_ICON = {
    milling       = "Interface\\Icons\\INV_Inscription_Tradeskill01",
    prospecting   = "Interface\\Icons\\INV_Misc_Gem_BloodGem_01",
    disenchanting = "Interface\\Icons\\Spell_Holy_RemoveCurse",
}

function activityRail:create(config)
    local motion = Addon.motion
    local theme  = Addon.theme
    local tint   = theme.derive.tint
    local model  = Addon.activityModel

    local viewed   = config.viewed        -- () -> activity id currently viewed
    local onSelect = config.onSelect      -- (activity) -> composer navigates
    local onContext = config.onContext    -- (activity, rowFrame) -> menu
    local onCustomize = config.onCustomize
    local onToolTargeted   = config.onToolTargeted
    local onToolIdleTarget = config.onToolIdleTarget

    local rail = CreateFrame("Frame", nil, config.parent, "BackdropTemplate")
    rail:SetWidth(RAIL_WIDTH)
    -- Input reaches a child button only through frames that take mouse: the
    -- rail enables it so the rows and the customize button below are hittable.
    rail:EnableMouse(true)
    if config.backdrop then
        rail:SetBackdrop(config.backdrop)
        local pb = theme.crafty.SURFACE.PANEL
        rail:SetBackdropColor(pb.r, pb.g, pb.b, pb.a)
    end

    -- Row frames, keyed by activity id and reused across refreshes: a rail
    -- with a stable membership (the character's professions) creates each row
    -- once and re-seats it. Group headings are pooled the same way by group key.
    local rows = {}       -- activityId -> row frame
    local editMode = false  -- Customize open: show hidden rows (dimmed) + eyes
    local headings = {}   -- groupKey  -> heading fontstring
    local arrived = {}    -- profID    -> true, learned-while-unviewed mark

    -- Tool shelf state. The shelf is a child of the rail, re-anchored under the
    -- viewed profession's row on each layout; its buttons are pooled and armed
    -- exactly as the band armed them (secure attributes, edge-matched clicks).
    local shelf = CreateFrame("Frame", nil, rail)
    shelf:SetHeight(0)
    shelf:Hide()
    local toolPool = {}       -- index -> secure button, created once
    local toolButtons = {}    -- the buttons shown this layout

    -- ------------------------------------------------------------------
    -- Row construction
    -- ------------------------------------------------------------------

    local function skinRow(row, active)
        if active then
            local t = theme.crafty.SELECTION.FILL
            row:SetBackdropColor(t.r, t.g, t.b, t.a)
            local b = theme.crafty.SELECTION.BORDER
            row:SetBackdropBorderColor(b.r, b.g, b.b, 1)
            tint(row.name, theme.crafty.TEXT.BODY)
            tint(row.skill, theme.crafty.TEXT.VALUE)
        elseif arrived[row.profID] then
            -- Learned something while you were elsewhere: gold until you look.
            local g = theme.crafty.ACTIVITY.ARRIVED
            row:SetBackdropColor(g.r, g.g, g.b, 0.15)
            row:SetBackdropBorderColor(g.r, g.g, g.b, 0.9)
            tint(row.name, theme.crafty.TEXT.BODY)
            tint(row.skill, theme.crafty.TEXT.VALUE)
        else
            local fill = theme.crafty.ACTIVITY.REST_FILL
            row:SetBackdropColor(fill.r, fill.g, fill.b, 1)
            local nb = theme.crafty.ACTIVITY.REST_BORDER
            row:SetBackdropBorderColor(nb.r, nb.g, nb.b, 1)
            tint(row.name, theme.crafty.TEXT.BODY)
            tint(row.skill, theme.crafty.TEXT.VALUE)
        end
    end

    -- In edit mode a hidden activity still shows so it can be brought back, but
    -- faded to read as "off"; its eye takes the muted tint, a shown row's eye
    -- the gold accent. Outside edit mode this is never applied (eye is hidden).
    -- Forward declaration: the eye toggles and setEditMode call layout(), which
    -- is defined further down. One upvalue, assigned there, referenced here.
    local layout

    local function setRowDim(row, dimmed)
        local a = dimmed and 0.35 or 1
        row.icon:SetAlpha(a)
        row.name:SetAlpha(a)
        row.skill:SetAlpha(a)
        -- The eye reads its own state: full-colour when the activity shows,
        -- desaturated and faded when it is hidden.
        row.eye.tex:SetDesaturated(dimmed)
        row.eye.tex:SetAlpha(dimmed and 0.5 or 1)
    end

    local function ensureRow(activity)
        local row = rows[activity.id]
        if not row then
            row = CreateFrame("Button", nil, rail, "BackdropTemplate")
            row:SetBackdrop(config.backdrop)
            row:SetHeight(ROW_H)

            local icon = row:CreateTexture(nil, "ARTWORK")
            icon:SetSize(ICON_SIZE, ICON_SIZE)
            icon:SetPoint("LEFT", row, "LEFT", 8, 0)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            row.icon = icon

            local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            name:SetPoint("TOPLEFT", row, "TOPLEFT", TEXT_INSET, -6)
            name:SetPoint("RIGHT", row, "RIGHT", -8, 0)
            name:SetJustifyH("LEFT")
            name:SetWordWrap(false)
            row.name = name

            local skill = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            skill:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
            skill:SetJustifyH("LEFT")
            skill:SetWordWrap(false)
            row.skill = skill

            row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            row:SetScript("OnClick", function(self, mouseButton)
                if mouseButton == "RightButton" then
                    if onContext then onContext(self.activity, self) end
                    return
                end
                if self.activity.id ~= viewed() then
                    onSelect(self.activity)
                else
                    motion:hop(self, function(dy)
                        self:SetPoint("TOPLEFT", rail, "TOPLEFT", EDGE_PAD, self._y + dy)
                    end)
                end
            end)
            row:SetScript("OnEnter", function(self)
                if self.activity.id == viewed() then return end
                local wash = theme.crafty.SELECTION.WASH
                self:SetBackdropColor(wash.r, wash.g, wash.b, wash.a)
                local b = theme.crafty.SELECTION.BORDER
                self:SetBackdropBorderColor(b.r, b.g, b.b, 0.7)
            end)
            row:SetScript("OnLeave", function(self)
                if self.activity.id == viewed() then return end
                skinRow(self, false)
            end)

            -- Edit-mode affordance: an eye that hides/shows this activity. Shown
            -- only while Customize is open (layout toggles it). Sits at the far
            -- right, above the row's own click so toggling never selects.
            local eye = CreateFrame("Button", nil, row)
            eye:SetSize(EYE_SIZE, EYE_SIZE)
            eye:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            eye:SetFrameLevel(row:GetFrameLevel() + 2)
            local eyeTex = eye:CreateTexture(nil, "OVERLAY")
            eyeTex:SetAllPoints()
            eyeTex:SetTexture("Interface\\Icons\\INV_Misc_Eye_01")
            eyeTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            eye.tex = eyeTex
            eye:SetScript("OnClick", function()
                model:setHidden(row.activity.id, not model:isHidden(row.activity.id))
                layout()
            end)
            eye:Hide()
            row.eye = eye

            rows[activity.id] = row
        end

        row.activity = activity
        row.profID = activity.profID

        -- Icon: a profession/gathering activity has a live profession icon; a
        -- processing activity has none, so the verb's chosen icon stands in.
        if activity.kind == "processing" then
            row.icon:SetTexture(VERB_ICON[activity.verb]
                or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name:SetText(VERB_LABEL[activity.verb] or activity.verb)
            row.skill:SetText("")
        else
            local info = Addon.professionHarvester:enumerate()
            local icon
            for _, p in ipairs(info) do
                if p.profID == activity.profID then icon = p.icon break end
            end
            row.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            row.name:SetText(activity.name)
            if activity.rank and activity.maxRank then
                row.skill:SetText(activity.rank .. " / " .. activity.maxRank)
            else
                row.skill:SetText("")
            end
        end
        return row
    end

    local function ensureHeading(groupKey)
        local fs = headings[groupKey]
        if not fs then
            fs = rail:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetJustifyH("LEFT")
            tint(fs, theme.crafty.TEXT.SUBHEADING)
            fs:SetText(GROUP_LABEL[groupKey] or groupKey:upper())
            headings[groupKey] = fs
        end
        return fs
    end

    -- ------------------------------------------------------------------
    -- Tool shelf: the viewed profession's tools, under its row
    -- ------------------------------------------------------------------

    -- Build/refresh the shelf's secure buttons for a profession. The secure
    -- mechanics are the band's, unchanged: attributes carry what is cast,
    -- clicks are edge-matched to ActionButtonUseKeyDown, availability paints
    -- the texture and badge. Only the home changed - a shelf under a rail row,
    -- not a cluster beside a card.
    local function buildTools(profID)
        for _, b in ipairs(toolButtons) do b:Hide() end
        wipe(toolButtons)

        local tools = profID and Addon.profTools:forProfession(profID) or {}
        local x = 0
        for i, tool in ipairs(tools) do
            local btn = toolPool[i]
            if not btn then
                btn = CreateFrame("Button", "CraftyToolButton" .. i, shelf,
                                  "SecureActionButtonTemplate")
                btn:EnableMouse(true)
                btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
                local function matchKeyDirection()
                    btn:RegisterForClicks(
                        C_CVar.GetCVarBool("ActionButtonUseKeyDown")
                        and "AnyDown" or "AnyUp")
                end
                matchKeyDirection()
                btn:RegisterEvent("CVAR_UPDATE")
                btn:SetScript("OnEvent", function(_, _, cvar)
                    if cvar == "ActionButtonUseKeyDown" then matchKeyDirection() end
                end)
                btn:SetSize(TOOL_SIZE, TOOL_SIZE)
                btn.tex = btn:CreateTexture(nil, "ARTWORK")
                btn.tex:SetAllPoints()
                btn.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                btn.countFS = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
                btn.countFS:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
                btn.cd = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
                btn.cd:SetAllPoints(btn.tex)
                btn.cd:SetDrawEdge(false)
                toolPool[i] = btn
            end
            btn:Show()
            btn:ClearAllPoints()
            btn:SetPoint("LEFT", shelf, "LEFT", x, 0)
            btn:SetAlpha(1)
            x = x + TOOL_SIZE + TOOL_GAP

            local tex, countFS = btn.tex, btn.countFS
            tex:SetTexture(Addon.profTools:icon(tool)
                or "Interface\\Icons\\INV_Misc_QuestionMark")

            local function arm()
                if InCombatLockdown() then return end
                if tool.kind == "spell" then
                    btn:SetAttribute("type", "spell")
                    btn:SetAttribute("spell", tool.id)
                else
                    btn:SetAttribute("type", "item")
                    btn:SetAttribute("item", "item:" .. tool.id)
                end
            end
            arm()

            local function paint()
                local ok = Addon.profTools:isAvailable(tool)
                tex:SetDesaturated(not ok)
                tex:SetAlpha(ok and 1 or 0.5)
                local n = Addon.profTools:count(tool)
                countFS:SetText((n and n > 0) and tostring(n) or "")
                local start, duration = Addon.profTools:cooldown(tool)
                if start then
                    btn.cd:SetCooldown(start, duration)
                else
                    btn.cd:Clear()
                end
            end
            paint()

            local function nod()
                motion:hop(btn, function(dy)
                    btn:ClearAllPoints()
                    btn:SetPoint("LEFT", shelf, "LEFT", btn._x, dy)
                end)
            end
            btn._x = x - TOOL_SIZE - TOOL_GAP

            btn:SetScript("PostClick", function()
                if tool.kind ~= "target" then return end
                if SpellCanTargetItem() then
                    nod()
                    if onToolTargeted then onToolTargeted(tool) end
                elseif onToolIdleTarget then
                    onToolIdleTarget(tool)
                end
            end)
            btn:SetScript("OnEnter", function(self)
                Addon.tooltip:show(self, { anchor = "bottom" })
                Addon.tooltip:header(Addon.profTools:name(tool))
                if not Addon.profTools:isAvailable(tool) then
                    Addon.tooltip:row("", Addon.profTools:unavailableReason(tool))
                end
                local start, duration = Addon.profTools:cooldown(tool)
                if start then
                    Addon.tooltip:row("Ready in", Addon.recipeView:formatDuration(
                        math.floor(start + duration - GetTime())))
                end
                Addon.tooltip:done()
            end)
            btn:SetScript("OnLeave", function() Addon.tooltip:hide() end)
            btn._paint = paint

            toolButtons[#toolButtons + 1] = btn
        end

        return #toolButtons
    end

    -- ------------------------------------------------------------------
    -- Customize Activities (button; editor is a later phase)
    -- ------------------------------------------------------------------

    local customize = CreateFrame("Button", nil, rail, "BackdropTemplate")
    customize:SetHeight(CUSTOMIZE_H)
    customize:SetPoint("BOTTOMLEFT", rail, "BOTTOMLEFT", EDGE_PAD, EDGE_PAD)
    customize:SetPoint("BOTTOMRIGHT", rail, "BOTTOMRIGHT", -EDGE_PAD, EDGE_PAD)
    customize:SetBackdrop(config.backdrop)
    do
        local fill = theme.crafty.ACTIVITY.REST_FILL
        customize:SetBackdropColor(fill.r, fill.g, fill.b, 1)
        local nb = theme.crafty.ACTIVITY.REST_BORDER
        customize:SetBackdropBorderColor(nb.r, nb.g, nb.b, 1)
    end
    local customizeLabel = customize:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    customizeLabel:SetPoint("CENTER")
    customizeLabel:SetText("Customize Activities")
    tint(customizeLabel, theme.crafty.TEXT.HEADING)
    customize:SetScript("OnEnter", function(self)
        local wash = theme.crafty.SELECTION.WASH
        self:SetBackdropColor(wash.r, wash.g, wash.b, wash.a)
    end)
    customize:SetScript("OnLeave", function(self)
        local fill = theme.crafty.ACTIVITY.REST_FILL
        self:SetBackdropColor(fill.r, fill.g, fill.b, 1)
    end)
    customize:SetScript("OnClick", function()
        if onCustomize then onCustomize() end
    end)

    -- ------------------------------------------------------------------
    -- Layout
    -- ------------------------------------------------------------------

    local instance = {}

    -- Seat every row and heading from the model, top to bottom, inserting the
    -- tool shelf under the viewed profession's row. Called by refresh and after
    -- the shelf's tool count changes.
    function layout()
        local activeId = viewed()

        -- Hide all pooled rows/headings; the layout re-shows those in the model.
        for _, row in pairs(rows) do row:Hide() end
        for _, fs in pairs(headings) do fs:Hide() end

        local y = -TOP_PAD
        local shelfShown = false

        for _, group in ipairs(model:enumerate(editMode)) do
            local heading = ensureHeading(group.key)
            heading:ClearAllPoints()
            heading:SetPoint("TOPLEFT", rail, "TOPLEFT", EDGE_PAD, y)
            heading:Show()
            y = y - HEADING_H

            for _, activity in ipairs(group.activities) do
                local row = ensureRow(activity)
                local isHidden = model:isHidden(activity.id)
                row._y = y
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", rail, "TOPLEFT", EDGE_PAD, y)
                row:SetPoint("RIGHT", rail, "RIGHT", -EDGE_PAD, 0)
                skinRow(row, activity.id == activeId)
                -- Edit mode: the eye toggles this row's hidden state; a hidden
                -- row still shows (dimmed) so it can be brought back. Outside
                -- edit mode the eye is gone and hidden rows never reach here
                -- (enumerate(false) drops them).
                row.eye:SetShown(editMode)
                setRowDim(row, editMode and isHidden)
                row:Show()
                y = y - ROW_H - ROW_GAP

                -- The tool shelf hangs under the viewed profession's row, when
                -- that profession has tools. Its height pushes everything below
                -- it down - the one-variable discipline the tray and journey
                -- strip use, here reading the running y cursor.
                if activity.id == activeId and activity.kind == "profession" then
                    local n = buildTools(activity.profID)
                    if n > 0 then
                        shelf:ClearAllPoints()
                        shelf:SetPoint("TOPLEFT", rail, "TOPLEFT",
                            EDGE_PAD + SHELF_PAD, y)
                        shelf:SetWidth(RAIL_WIDTH - 2 * EDGE_PAD - SHELF_PAD)
                        shelf:SetHeight(TOOL_SIZE)
                        shelf:Show()
                        shelfShown = true
                        y = y - TOOL_SIZE - ROW_GAP
                    end
                end
            end
            y = y - GROUP_GAP + ROW_GAP
        end

        if not shelfShown then shelf:Hide() end
    end

    function instance:refresh()
        -- Looking at a profession is the acknowledgment: its arrived-mark
        -- clears here, the same moment the band cleared it.
        local activeId = viewed()
        for _, row in pairs(rows) do
            if row.activity and row.activity.id == activeId then
                arrived[row.profID] = nil
            end
        end
        layout()
    end

    -- A profession learned something while unviewed. Mark its row gold and
    -- keep the mark until that profession is viewed (the model's row for it
    -- exists because it is a known profession).
    function instance:arrived(profID)
        for _, group in ipairs(model:enumerate(false)) do
            for _, activity in ipairs(group.activities) do
                if activity.kind == "profession" and activity.profID == profID
                    and activity.id ~= viewed() then
                    arrived[profID] = true
                    layout()
                    return
                end
            end
        end
    end

    -- A profession was unlearned. The rail has no card-flight to play out, but
    -- the composer's unlearn handoff waits on onDone before swapping the viewed
    -- profession, so the contract is preserved: the row is dropped from the
    -- next layout, then onDone fires. Any in-flight tool references to the gone
    -- profession clear because layout rebuilds the shelf from the new viewed().
    function instance:retire(profID, onDone)
        arrived[profID] = nil
        local row = rows["prof:" .. profID]
        if row then
            row:Hide()
            rows["prof:" .. profID] = nil
        end
        layout()
        if onDone then onDone() end
    end

    -- Nod the shelf's tools: the guidance gesture when a craft hit a missing
    -- station. Usually one tool; the whole shelf answers when there are several.
    function instance:nodTools()
        for _, b in ipairs(toolButtons) do
            motion:hop(b, function(dy)
                b:ClearAllPoints()
                b:SetPoint("LEFT", shelf, "LEFT", b._x, dy)
            end)
        end
    end

    function instance:repaintTools()
        for _, b in ipairs(toolButtons) do
            if b._paint then b._paint() end
        end
    end

    function instance:getFrame() return rail end
    function instance:width() return RAIL_WIDTH end

    -- Enter/leave edit mode: the rail takes the cool edit tint so it reads as
    -- part of the editing surface (with the drawer) rather than the passive nav.
    -- Restores the panel fill on exit. Row-level affordances (grips, eyes) are a
    -- later piece; this is the surface's mode colour.
    function instance:setEditMode(on)
        editMode = on
        local fill = on and theme.crafty.EDIT.FILL or theme.crafty.SURFACE.PANEL
        rail:SetBackdropColor(fill.r, fill.g, fill.b, fill.a)
        local border = on and theme.crafty.EDIT.BORDER or theme.crafty.SURFACE.DIVIDER
        rail:SetBackdropBorderColor(border.r, border.g, border.b, border.a)
        layout()
    end

    return instance
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("activityRail",
        {"motion", "theme", "tooltip", "activityModel", "profTools",
         "professionHarvester", "recipeView"})
end

Addon.activityRail = activityRail
return activityRail
