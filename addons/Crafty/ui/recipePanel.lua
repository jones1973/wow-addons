--[[
  ui/recipePanel.lua
  Recipe Panel Component

  The left panel's contents: the search input across the top, the filter bar
  (quick-filter toggles), the column-header sort bar, and the recipe list. All
  are filters over the list, so their wiring lives here together.

  Selection is owned here and flows OUT on the events bus: every selection
  change (click, repopulate maintenance) emits EVENT.RECIPE_SELECTED with the
  recipeID (nil when nothing is selectable). The detail panel renders from
  that event; this panel never reaches into it.

  List items carry ONLY identity (recipeID) - no derived or volatile values.
  Name, difficulty band, cooldown, and pinned state are all derived LIVE at
  render (and in the sort/group pipeline) from the ledger / difficulty /
  cooldownData, keyed by id. Baking those in would make the model hold stale
  snapshots and force a full re-pull on every input change (rank, cooldown,
  pin); deriving live means the held model is never stale and changes can be
  surgical.

  Usage:
    local panel = Addon.recipePanel:create({
        parent = panelFrame,
        viewed = function() return profID end,
        search = { parent = bandFrame, width = 240 },  -- the band's left slot
    })
    panel:repopulate()        -- wholesale rebuild for the viewed profession
    panel:addRecipe(id)       -- insert one just-learned recipe, sorted into place
    panel:select(id)          -- select a row (tray clicks route here)
    panel:selected()          -- the current selection (recipeID or nil)
    panel:frameFor(id)        -- the row frame for a recipe, if rendered
    panel:syncToRegistry()    -- push registry filter/sort state into the
                              -- controls and the list (after a restore)
    panel:redrawVisible()     -- re-render visible rows in place (skill-ups)
    panel:recipeRowKind()     -- the row kind table, for lists that share it
    panel:listFrame()         -- the list's frame, for outside anchoring
    panel:liftBottom(lift)    -- seat the list's bottom above the panel bottom

  Dependencies: reactiveList, filterTextbox, filterRegistry, contextMenu,
                ledger, recipeCatalog, recipeView, difficulty, cooldownData,
                theme, tooltip, events
  Exports: Addon.recipePanel
]]

local ADDON_NAME, Addon = ...

local recipePanel = {}

-- The default recipe order when a character-profession has no saved sort:
-- highest skill first (the recipes being worked toward sit on top).
local DEFAULT_SORT_FIELD = "difficulty"
local DEFAULT_SORT_DIR   = "desc"

-- Rows are tall enough to hold a two-line wrapped name with comfortable
-- vertical spacing; single-line names are vertically centered within this
-- height. Section-group headers (Pinned / All) are shorter than recipe rows.
local ROW_HEIGHT    = 40
local HEADER_HEIGHT = 22

-- Cooldown icon size, fixed independent of row height so taller rows don't
-- inflate the glyph.
local ICON_SIZE = 16

-- Column layout for the recipe list. Skill (learn level) and Makes (yield) are
-- fixed-width numeric columns; Name flexes to fill the remainder. These are the
-- three near-universal catalog progression fields. Cooldown / has-materials are
-- not universal, so they stay as inline icons in the Name column's gutter, not
-- columns. The clickable column-header bar sits above the list and drives sort.
-- Skill is caption-bound: the caption is wider than its data ("600").
--
-- There is no Makes column: a yield belongs to the item, not to a quantity the
-- eye has to correlate back across a row, and Blizzard already writes it into
-- 14 spell names ("Large Copper Bomb (2-4)"). Putting every yield there makes
-- the whole catalog consistent with the names the game itself uses, and frees
-- the width for the Name column, which is the one that truncates.
local COL_SKILL_W  = 46
local COL_GAP      = 10
local COL_HEADER_H = 26

-- The list's scrollbar reserves this gutter on the right (BAR_GUTTER in
-- scrollBox). The header bar must inset its right edge by the same amount so
-- the Makes column header sits over the Makes data, not over the scrollbar,
-- and the header and row right edges align.
local LIST_BAR_GUTTER = 8

-- Left lane reserved for the cooldown clock icon. The recipe name column
-- always starts at this X, so names align whether or not a row shows a CD
-- icon. Sized to clear the icon (ICON_SIZE wide) plus its 4px inset and a
-- small gap.
local CD_GUTTER = ICON_SIZE + 10

function recipePanel:create(config)
    local theme        = Addon.theme
    local icons        = Addon.icons
    local tint         = theme.derive.tint
    local ledger       = Addon.ledger
    local recipeCatalog = Addon.recipeCatalog
    local recipeView   = Addon.recipeView
    local difficulty   = Addon.difficulty
    local cooldownData = Addon.cooldownData
    local registry     = Addon.filterRegistry
    local events       = Addon.events
    local EVT_SELECTED = Addon.constants.EVENT.RECIPE_SELECTED

    local viewed    = config.viewed
    local panelLeft = config.parent

    local instance = {}
    local selectedID, selectedKind
    local recipeList
    local toggleControls = {}
    local sortHeaders = {}   -- field -> { btn, label, caret }

    -- ------------------------------------------------------------------
    -- Row / header factories (consumed by reactiveList, shared with the tray)
    -- ------------------------------------------------------------------

    -- Build a recipe row frame. Layout is column-stable: the name always starts
    -- at the same left X (CD_GUTTER), and the cooldown clock lives in a fixed
    -- gutter to the left of that column - shown or hidden without ever moving
    -- the name.
    local function makeRecipeRow(parent)
        local row = CreateFrame("Button", nil, parent)
        row:SetHeight(ROW_HEIGHT)
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        -- Skill column: the recipe's learn level, right-aligned, left-fixed width.
        local skillFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        skillFS:SetPoint("LEFT", row, "LEFT", 4, 0)
        skillFS:SetWidth(COL_SKILL_W - 4)
        skillFS:SetJustifyH("RIGHT")
        skillFS:SetJustifyV("MIDDLE")
        row.skill = skillFS

        -- Cooldown clock icon, fixed in a gutter at the start of the Name column,
        -- vertically centered. Always occupies its slot; shown only when on cooldown.
        local cd = CreateFrame("Frame", nil, row)
        cd:SetSize(ICON_SIZE, ICON_SIZE)
        cd:SetPoint("LEFT", row, "LEFT", COL_SKILL_W + COL_GAP, 0)
        cd:EnableMouse(true)
        cd:SetPropagateMouseClicks(true)
        local cdTex = cd:CreateTexture(nil, "ARTWORK")
        cdTex:SetAllPoints()
        icons.apply(cdTex, "cooldown", theme.tokens.STATE.INFO)
        cd:Hide()
        row.cdIcon = cd
        row.cdTex = cdTex

        -- Name column: flexes between the Skill column (plus cooldown gutter) and
        -- the Makes column. Difficulty-colored, single line (columns read cleaner
        -- than wrapped names), truncated by width.
        local fs = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("LEFT", row, "LEFT", COL_SKILL_W + COL_GAP + CD_GUTTER, 0)
        fs:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        fs:SetJustifyH("LEFT")
        fs:SetJustifyV("MIDDLE")
        fs:SetWordWrap(false)
        fs:SetMaxLines(1)
        row.text = fs

        return row
    end

    -- Fill a recipe row for an item: difficulty-colored name, cooldown clock with
    -- a tooltip when on cooldown. All display is DERIVED LIVE from item.id (the
    -- item carries only identity) so a held row is never stale: a skill-up
    -- re-derives the band, a cooldown sweep re-derives the clock, with no re-pull.
    local function renderRecipeRow(row, item)
        local recipeID = item.id

        -- Skill column: the learn level.
        row.skill:SetText(recipeCatalog:learn(recipeID) or "")

        -- Name, yield and skill-up as one string - see recipeView:displayName.
        row.text:SetText(recipeView:displayName(recipeID))

        -- Difficulty band derived live (current rank vs static thresholds), via
        -- the one derivation source. Default color if unknown.
        local band = recipeView:band(recipeID)

        local dr, dg, db
        if band then
            dr, dg, db = difficulty:colorForBand(band)
        end
        if dr then
            row.text:SetTextColor(dr, dg, db)
        else
            row.text:SetTextColor(0.9, 0.9, 0.9)
        end

        -- Cooldown clock + tooltip, derived live. Shows when actively cooling
        -- down (ledger cooldown) OR a cooldown recipe by nature (DB2) currently
        -- ready - the live API can't tell us the latter, so static data fills the
        -- gap. The gutter is reserved either way, so showing/hiding does not move
        -- the name.
        local expiry       = ledger:getCooldown(recipeID)
        local isDailyReset = cooldownData:isDailyReset(recipeID)
        local isShared     = cooldownData:isShared(recipeID)

        if expiry then
            local w = theme.tokens.STATE.WARNING
            row.cdTex:SetVertexColor(w.r, w.g, w.b)
            row.cdIcon:Show()
            row.cdIcon:SetScript("OnEnter", function(self)
                Addon.tooltip:show(self, { anchor = "right" })
                Addon.tooltip:header("On cooldown")
                Addon.tooltip:row(isDailyReset and "Resets in" or "Ready in", recipeView:formatDuration(expiry - time()))
                Addon.tooltip:row(isDailyReset and "Resets at" or "Ready at", recipeView:formatReadyClock(expiry))
                if isShared then Addon.tooltip:row("Shared", "with related recipes") end
                Addon.tooltip:done()
            end)
            row.cdIcon:SetScript("OnLeave", function() Addon.tooltip:hide() end)
        elseif cooldownData:hasCooldown(recipeID) then
            local secs = cooldownData:durationSeconds(recipeID)
            local s = theme.tokens.STATE.SUCCESS
            row.cdTex:SetVertexColor(s.r, s.g, s.b)
            row.cdIcon:Show()
            row.cdIcon:SetScript("OnEnter", function(self)
                Addon.tooltip:show(self, { anchor = "right" })
                Addon.tooltip:header("Cooldown ready")
                if isDailyReset then
                    Addon.tooltip:row("Resets", "Daily")
                elseif secs then
                    Addon.tooltip:row("Cooldown", recipeView:formatDuration(secs))
                end
                if isShared then Addon.tooltip:row("Shared", "with related recipes") end
                Addon.tooltip:done()
            end)
            row.cdIcon:SetScript("OnLeave", function() Addon.tooltip:hide() end)
        else
            row.cdIcon:Hide()
            row.cdIcon:SetScript("OnEnter", nil)
            row.cdIcon:SetScript("OnLeave", nil)
        end
    end

    -- Build a group header frame (Pinned / All boundary).
    local function makeGroupHeader(parent)
        local header = CreateFrame("Frame", nil, parent)
        -- Height is set by reactiveList from kinds.group.headerHeight.
        local fs = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", header, "LEFT", 6, 0)
        tint(fs, theme.crafty.TEXT.SUBHEADING)
        header.text = fs
        return header
    end

    -- Render a group header. key 0 = pinned, 1 = all.
    local function renderGroupHeader(header, key)
        header.text:SetText(key == 0 and "Pinned" or "All")
    end

    -- The recipe row kind: also consumed by lists that must render identical
    -- recipe rows (the newly-learned tray), so both stay one definition.
    local recipeRowKind = {
        height  = ROW_HEIGHT,
        factory = makeRecipeRow,
        render  = renderRecipeRow,
        -- Alternating row stripe (plus the default hover/selection), so the
        -- columnar list reads as a table.
        chrome  = { stripe = true },
    }

    -- ------------------------------------------------------------------
    -- Selection
    -- ------------------------------------------------------------------

    -- Select a recipe (nil clears): the list highlights it and the selection
    -- flows out on the events bus for the detail panel to render.
    --
    -- A selection has a KIND. Recipes are the default; a conversion target (a
    -- pigment or gem, reached by clicking a reagent no recipe produces) is a
    -- selection in every sense the window cares about - the detail panel
    -- renders it, the journey arrives at it, wandering off it converts an
    -- errand to a crumb - so it travels the one selection path rather than a
    -- shadow state beside it. The list highlights only recipes: a conversion
    -- target has no row (the list keeps showing the profession's recipes,
    -- which is what makes wandering off the target possible).
    function instance:select(id, kind)
        kind = kind or "recipe"
        selectedID, selectedKind = id, kind
        recipeList:setSelected(kind == "recipe" and id or nil)
        -- The selection travels as one payload: the bus carries a single
        -- payload by contract, and a selection IS one thing - an identity
        -- with a kind - not two scalars sharing a channel.
        events:emit(EVT_SELECTED, { id = id, kind = kind })
    end

    -- The selected id, and its kind (second return; "recipe" unless a
    -- conversion target is showing).
    function instance:selected() return selectedID, selectedKind end

    -- Forget the selection without emitting or touching the list: the
    -- selection belongs to an outgoing profession, and the repopulate that
    -- follows the incoming profession's scan establishes (and emits) the new
    -- one. Emitting nil here would blank the detail panel mid-swap for no
    -- reason; the stale detail is replaced the moment the scan lands.
    function instance:resetSelection()
        selectedID, selectedKind = nil, nil
    end

    -- ------------------------------------------------------------------
    -- Search input: the top of the list pane (a list filter belongs with the
    -- list it shapes; it moved here when the profession band it used to sit in
    -- became the activity rail)
    -- ------------------------------------------------------------------

    local searchId
    for _, spec in ipairs(registry:list()) do
        if spec.kind == "search" then searchId = spec.id break end
    end
    -- Restore persisted filter/sort state before seeding the controls.
    registry:restore()
    local savedSearch = searchId and registry:getState(searchId) or ""
    local searchInput = Addon.filterTextbox:create({
        parent      = panelLeft,
        width       = 200,
        placeholder = "Search recipes...",
        text        = savedSearch,  -- seeded at construction (no change event);
                                    -- the persisted filter is already in the
                                    -- registry (restore() above), so the
                                    -- reactiveList's initial activeFilter() renders
                                    -- it on the first draw
        onTextChanged = function(text)
            if searchId then
                -- Reconcile filter state to the box text. If it already matches
                -- (e.g. a layout/show-driven OnTextChanged firing with the
                -- restored value), there is nothing to apply and nothing to
                -- redraw - a reconcile with no delta is a no-op.
                if registry:getState(searchId) == text then return end
                registry:setState(searchId, text)
                recipeList:setFilter(registry:activeFilter())
            end
        end,
        onClear = function()
            if searchId then
                registry:setState(searchId, "")
                recipeList:setFilter(registry:activeFilter())
            end
        end,
    })
    -- Anchored ONCE at creation (re-anchoring after create detaches the clear
    -- button - that was the clear-does-nothing bug): across the top of the list
    -- pane, with the filter bar and list stacked below it.
    searchInput:SetPoint("TOPLEFT", panelLeft, "TOPLEFT", 8, -8)
    searchInput:SetPoint("RIGHT", panelLeft, "RIGHT", -8, 0)

    -- ------------------------------------------------------------------
    -- Filter bar
    -- ------------------------------------------------------------------

    -- Filter bar atop the list: the quick-filter toggles, a deliberately framed
    -- control group - a recessed surface with a "Filters" label and internal
    -- padding - so it reads as an intentional toolbar, not loose checkboxes
    -- floating on the panel. Registry-driven.
    local ROW_H = 28
    local filterBar = CreateFrame("Frame", nil, panelLeft)
    filterBar:SetPoint("TOPLEFT", searchInput, "BOTTOMLEFT", 0, -8)
    filterBar:SetPoint("RIGHT", panelLeft, "RIGHT", -8, 0)
    filterBar:SetHeight(ROW_H)

    -- Recessed background band with a hairline top/bottom edge, grouping the
    -- filter controls into one deliberate strip. Uses the raised chrome surface
    -- (clearly lighter than the panel) so the strip actually reads as a band, not
    -- a near-invisible tint.
    local filterBg = filterBar:CreateTexture(nil, "BACKGROUND")
    filterBg:SetAllPoints()
    local fbc = theme.crafty.SURFACE.FILTER_BAR
    filterBg:SetColorTexture(fbc.r, fbc.g, fbc.b, fbc.a)

    local function applyFilters()
        recipeList:setFilter(registry:activeFilter())
    end

    -- Filter toggles, left to right across the strip with internal padding. No
    -- caption - a checkbox labelled "Skill-ups" is self-evidently a filter.
    local prevToggle
    for _, spec in ipairs(registry:list()) do
        if spec.kind == "toggle" then
            local lt = Addon.labeledToggle:create({
                parent  = filterBar,
                style   = "checkbox",
                label   = spec.label,
                value   = registry:getState(spec.id) == true,
                onChange = function(checked)
                    registry:setState(spec.id, checked)
                    applyFilters()
                end,
            })
            if prevToggle then
                lt:SetPoint("LEFT", prevToggle.label, "RIGHT", 14, 0)
            else
                lt:SetPoint("LEFT", filterBar, "LEFT", 8, 0)
            end
            prevToggle = lt
            toggleControls[spec.id] = lt
        end
    end

    -- ------------------------------------------------------------------
    -- Column-header sort bar
    -- ------------------------------------------------------------------

    -- One clickable label per column (Skill / Name / Makes), aligned to the row
    -- columns below. Click a header to sort by it; click the active header again
    -- to reverse. A caret on the active header shows direction.
    local headerBar = CreateFrame("Frame", nil, panelLeft)
    headerBar:SetPoint("TOPLEFT", filterBar, "BOTTOMLEFT", 0, -6)
    -- Inset the right edge by the list's scrollbar gutter so the Makes header
    -- lands over the Makes data (not over the scrollbar), and the header and row
    -- right edges align.
    headerBar:SetPoint("RIGHT", filterBar, "RIGHT", -LIST_BAR_GUTTER, 0)
    headerBar:SetHeight(COL_HEADER_H)

    -- Recessed, opaque header band: distinct from every row surface (which are
    -- lighter and semi-transparent), so the header reads as structural chrome and
    -- the rows sit visually on it.
    local headerBg = headerBar:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    -- A dark-warm band a step above the filter strip; the gold header captions
    -- carry the "this is the grid header" signal, so the surface stays dark
    -- rather than the light chrome slab COLUMN_HEADER would paint.
    local hbc = theme.crafty.SURFACE.COLUMN_HEADER
    headerBg:SetColorTexture(hbc.r, hbc.g, hbc.b, hbc.a)

    -- Paint the caret/emphasis on the active sort header, clearing the others.
    local function updateSortHeaders()
        local field, dir = registry:savedSort()
        field = field or DEFAULT_SORT_FIELD
        dir = dir or DEFAULT_SORT_DIR
        for f, h in pairs(sortHeaders) do
            if f == field then
                h.caret:SetText(dir == "desc" and "v" or "^")
            else
                h.caret:SetText("")
            end
        end
    end

    local function makeSortHeader(field, text, justify)
        local btn = CreateFrame("Button", nil, headerBar)
        btn:SetHeight(COL_HEADER_H)
        -- Standard hover: a faint HIGHLIGHT overlay, matching the dropdown's
        -- hover treatment (the codebase's standard clickable-hover affordance).
        local hl = btn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.05)
        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetAllPoints(btn)
        label:SetJustifyH(justify)
        label:SetJustifyV("MIDDLE")  -- caption breathes vertically in the taller bar
        label:SetText(text)
        tint(label, theme.crafty.TEXT.HEADING)
        local caret = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        caret:SetJustifyH("CENTER")
        caret:SetJustifyV("MIDDLE")
        tint(caret, theme.crafty.TEXT.HEADING)
        -- Caret sits just outside the label's text edge (right for left-justified
        -- headers, left for right-justified numeric headers).
        if justify == "RIGHT" then
            caret:SetPoint("RIGHT", btn, "LEFT", -1, 0)
        else
            caret:SetPoint("LEFT", btn, "RIGHT", 1, 0)
        end
        btn:SetScript("OnClick", function()
            local curField, curDir = registry:savedSort()
            local newDir
            if curField == field then
                newDir = (curDir == "desc") and "asc" or "desc"  -- re-click reverses
            else
                newDir = registry:sortDirFor(field)              -- new column: its default
            end
            registry:setSort(field, newDir)
            recipeList:setSort(registry:sortComparator(field, newDir))
            updateSortHeaders()
        end)
        sortHeaders[field] = { btn = btn, label = label, caret = caret }
        return btn
    end

    -- Headers aligned to the row columns: Skill (left-fixed), Name (flex).
    -- Skill maps to the difficulty sort, by learn level.
    local hSkill = makeSortHeader("difficulty", "Skill", "RIGHT")
    hSkill:SetPoint("LEFT", headerBar, "LEFT", 4, 0)
    hSkill:SetWidth(COL_SKILL_W - 4)



    local hName = makeSortHeader("name", "Name", "LEFT")
    hName:SetPoint("LEFT", headerBar, "LEFT", COL_SKILL_W + COL_GAP + CD_GUTTER, 0)
    hName:SetPoint("RIGHT", headerBar, "RIGHT", -4, 0)

    -- ------------------------------------------------------------------
    -- The recipe list
    -- ------------------------------------------------------------------

    -- A shared reactiveList below the column-header bar. Recipes are grouped
    -- into Pinned / All, difficulty-colored, columnar (Skill / Name / Makes),
    -- with a cooldown clock on recipes currently cooling down.
    recipeList = Addon.reactiveList:create({
        parent = panelLeft,
        width  = panelLeft:GetWidth() - 20,
        height = 400,  -- overridden by getFrame() two-corner anchoring below

        sort = function(a, b) return recipeView:name(a.id) < recipeView:name(b.id) end,

        -- Filters come from the registry: an array of active predicates, ANDed.
        -- Registering a new filter makes it apply here with no change to this
        -- config.
        filter = registry:activeFilter(),

        -- Pinned recipes group to the top under a "Pinned" header; the rest
        -- under "All". Pinned is derived live from the ledger (not stored on the
        -- item). reactiveList suppresses a lone group's header, so when nothing
        -- is pinned no header shows.
        group = {
            key  = function(item) return ledger:isPinned(item.id) and 0 or 1 end,
            sort = function(a, b) return a < b end,
        },

        kinds = {
            row = recipeRowKind,
            -- A group header is just another kind, same {height, factory,
            -- render} shape as any row; its render gets (key, items, expanded).
            header = {
                height  = HEADER_HEIGHT,
                factory = makeGroupHeader,
                render  = renderGroupHeader,
            },
        },

        onClick = function(item)
            instance:select(item.id)
        end,
        onContextMenu = function(item)
            local pinned = ledger:isPinned(item.id)
            Addon.contextMenu:show({
                items = {
                    {
                        text = pinned and "Unpin" or "Pin",
                        func = function()
                            ledger:togglePin(item.id)
                            -- Pinning moves the recipe between the Pinned and All
                            -- groups - a change in grouped structure, not a single
                            -- row's content. That is a full pipeline pass.
                            recipeList:refreshAll()
                        end,
                    },
                },
            })
        end,
    })

    -- Anchor the list's left to the header bar's edge so row columns line up
    -- under their headers. The right extends PAST the header by the list's
    -- internal scrollbar gutter: the header insets that gutter so its captions
    -- sit over row data, and the list's own scrollbar consumes the same gutter
    -- inside its frame - extending the frame makes the two cancel, so rows end
    -- exactly at the header's right edge and the scrollbar fills the gutter out
    -- to the filter bar's line. (Anchoring both frames to the inset edge paid
    -- the gutter twice: rows and tray stopped a gutter short of the panel's
    -- content line.) The bottom is seated by liftBottom (the composer drives
    -- the lift as the newly-learned tray springs).
    recipeList:getFrame():SetPoint("TOPLEFT", headerBar, "BOTTOMLEFT", 0, -4)
    recipeList:getFrame():SetPoint("TOPRIGHT", headerBar, "BOTTOMRIGHT", LIST_BAR_GUTTER, -4)

    -- Seat the list's bottom edge `lift` above the panel bottom.
    function instance:liftBottom(lift)
        recipeList:getFrame():SetPoint("BOTTOM", panelLeft, "BOTTOM", 0, lift)
    end
    instance:liftBottom(6)

    -- Apply the persisted sort - or the default order when this
    -- character-profession has never chosen one - and paint the matching
    -- column header.
    local initField, initDir = registry:savedSort()
    recipeList:setSort(registry:sortComparator(
        initField or DEFAULT_SORT_FIELD, initDir or DEFAULT_SORT_DIR))
    updateSortHeaders()

    -- ------------------------------------------------------------------
    -- Refresh
    -- ------------------------------------------------------------------

    -- Build the recipe row items for the viewed profession, identity only.
    local function buildRecipeItems()
        local profID = viewed()
        if not profID then return {} end
        local items = {}
        for _, recipeID in ipairs(ledger:getKnownRecipes(profID)) do
            items[#items + 1] = { id = recipeID }
        end
        return items
    end

    -- Push the current recipe id set into the list. Used ONLY for genuine
    -- wholesale change (the profession's known set is established/replaced):
    -- open and profession switch. Per-row changes (learn, pin, cooldown,
    -- skill-up) are surgical and do NOT come through here.
    function instance:repopulate()
        recipeList:replaceAll(buildRecipeItems())

        -- Keep a selection so the detail panel reflects the list. Keep the
        -- current selection if it survived the rebuild; otherwise select the
        -- first visible row. An active filter can match zero records (a
        -- legitimate state), so there may be no visible row - firstVisible() is
        -- then nil, selection becomes nil, and the selection event's consumers
        -- handle nil by clearing.
        --
        -- A conversion target survives a rebuild untouched: it has no row to
        -- lose, and a rescan of the profession it is being milled for is not
        -- a reason to abandon it.
        if selectedKind == "convert" then
            instance:select(selectedID, "convert")
            return
        end
        if not (selectedID and recipeList:get(selectedID)) then
            local first = recipeList:firstVisible()
            selectedID = first and first.id or nil
        end
        instance:select(selectedID)
    end

    -- Insert one just-learned recipe: the model gains the row like any other -
    -- visible iff it passes the active filter - and a full pass sorts it into
    -- place now, so an arrival ghost flies to its real home.
    function instance:addRecipe(recipeID)
        recipeList:upsert({ id = recipeID })
        recipeList:refreshAll()
    end

    -- Re-sync the whole filter bar to the registry's current state (after a
    -- restore for a new profession), then re-project the list. Each control is
    -- set silently - this is a view-follows-state sync, not a user action, so
    -- it must not re-fire the controls' onChange (which would re-persist or
    -- loop).
    function instance:syncToRegistry()
        for id, lt in pairs(toggleControls) do
            lt:SetValue(registry:getState(id) == true, true)
        end
        if searchId then
            searchInput:set(registry:getState(searchId) or "", true)
        end
        updateSortHeaders()
        recipeList:setFilter(registry:activeFilter())
        local f, d = registry:savedSort()
        recipeList:setSort(registry:sortComparator(
            f or DEFAULT_SORT_FIELD, d or DEFAULT_SORT_DIR))
    end

    function instance:redrawVisible()      recipeList:redrawVisible() end
    function instance:frameFor(recipeID)   return recipeList:frameFor(recipeID) end
    function instance:recipeRowKind()      return recipeRowKind end
    function instance:listFrame()          return recipeList:getFrame() end

    return instance
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("recipePanel",
        {"reactiveList", "filterTextbox", "filterRegistry", "contextMenu",
         "ledger", "recipeCatalog", "recipeView", "difficulty", "cooldownData",
         "theme", "tooltip", "events"})
end

Addon.recipePanel = recipePanel
return recipePanel
