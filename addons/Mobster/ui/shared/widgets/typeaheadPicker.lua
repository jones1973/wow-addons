--[[
  ui/shared/widgets/typeaheadPicker.lua
  Typeahead Picker Factory

  Generic chrome for popup pickers attached to an EditBox: scrollable
  result list, frame pool, debounced query, click-to-pick. The picker
  is the dropdown surface; the consumer is responsible for what items
  look like and where they come from.

  Row construction is declarative. The consumer describes each item
  kind's shape (frame type, height, background, texts, accent stripe,
  mixins) as a data spec; the picker builds the frames. The consumer's
  render function bridges from item data to the spec-created widgets.

  Usage:
    local picker = Addon.typeaheadPicker:create({
        runQuery = function(text) return { item, item, ... } end,

        rows = {
            -- Keyed by item.kind. Each item returned from runQuery
            -- must carry a `kind` field whose value is a key here.
            row = {
                pickable = true,    -- required. Pickable rows are
                                    -- Button frames and get chrome
                                    -- hover/click behavior. Non-pickable
                                    -- kinds (headers, banners) are Frame
                                    -- frames and ignore mouse input.

                height   = 24,      -- required

                render   = function(frame, item)
                    -- required; runs every time a frame is reused
                    -- for a new item. Widgets defined by the spec
                    -- are reachable as frame[key] for each entry in
                    -- `texts`, plus frame.accent (if accentStripe set).
                end,

                -- Optional. Omitted entries are skipped — no extra
                -- frame children are created for them.

                background = {
                    color = Addon.theme.tokens.SURFACE.PANEL_BASE,
                    alpha = 1.0,    -- optional; overrides color.a
                },

                accentStripe = {
                    width = 3,
                    color = Addon.theme.tokens.TEXT.EMPHASIS,
                    alpha = 0.9,
                    -- Hidden by default; render decides per-row
                    -- visibility via frame.accent:SetShown(bool).
                },

                texts = {
                    {
                        key      = "nameFS",     -- frame[key] = FontString
                        font     = "GameFontHighlight",
                        points   = {              -- list of SetPoint args
                            { "TOPLEFT",   10, -5 },
                            { "TOPRIGHT", -10, -5 },
                        },
                        justifyH = "LEFT",        -- optional, default "LEFT"
                    },
                },

                -- Applies overflowTooltipMixin so render can call
                -- frame:SetOverflowText(fs, fullText). Requires
                -- pickable=true (mixin hooks OnEnter/OnLeave).
                overflowTooltip = true,
            },
        },

        onPick = function(item) end,

        -- Tunables (optional)
        debounce        = 0.2,
        minQueryLen     = 1,
        maxResults      = 100,
        visibleMaxRows  = 7,    -- viewport caps at this many "row" heights
        scrollFrameName = "MyAddonPickerScroll",
        hideOnPick      = true,

        -- Chevron — combobox-style affordance on the editBox's right edge.
        --
        --   showChevron        boolean.        Attach the chevron at all.
        --   chevronVisibleWhen "always" |      Stock combobox: chevron is
        --                      "hasQuery" |    always there (default).
        --                      function(text)  "hasQuery": chevron shows
        --                                      only when text length >=
        --                                      minQueryLen — parallels
        --                                      searchBox's clear-icon
        --                                      visibility pattern. Or a
        --                                      custom predicate.
        --   chevronAction      "showAll" |     "showAll": click bypasses
        --                      "toggle"        minQueryLen and shows
        --                                      everything (default; the
        --                                      classic combobox click).
        --                                      "toggle": click honors
        --                                      minQueryLen — a no-op
        --                                      when query is too short.
        --
        -- Natural pairings:
        --   visibleWhen=always   + action=showAll   (combobox)
        --   visibleWhen=hasQuery + action=toggle    (search field — the
        --                                            chevron is visible
        --                                            iff click is useful)
        showChevron        = false,
        chevronVisibleWhen = "always",
        chevronAction      = "showAll",
    })

    picker:attach(editBox, parent, width, opts)  -- opts = { growDownward }
    picker:onQuery(text)
    picker:hide()
    picker:isShown()
    picker:moveHighlight(dir)        -- dir: 1 down, -1 up
    picker:commitHighlight()         -- pick the keyboard-highlighted row

  Each :create() returns an independent picker — no shared state
  between instances. State (debounce token, dropdown frame, pools)
  is closed over per-instance.

  Dependencies: panel, pool, theme, overflowTooltipMixin
  Exports: Addon.typeaheadPicker
]]

local _, Addon = ...

local typeaheadPicker = {}

-- ============================================================================
-- DEFAULTS
-- ============================================================================

local DEFAULTS = {
    debounce       = 0.2,
    minQueryLen    = 1,
    maxResults     = 100,
    visibleMaxRows = 7,
    hideOnPick     = true,
    showChevron    = false,
    chevronVisibleWhen = "always",   -- "always" | "hasQuery" | function(text)
    chevronAction      = "showAll",  -- "showAll" | "toggle"

    -- Layout constants. The chrome owns these so all consumers look
    -- the same. If a consumer needs a different look, that's a strong
    -- signal it's a different widget, not a different config of this one.
    pad         = 8,
    scrollbarW  = 20,
    chevronSize = 16,
    chevronGap  = 4,   -- horizontal gap between chevron and clearButton, if both present
}

-- ============================================================================
-- INTERNAL: spec → factory
-- ============================================================================

--[[
  Given a row spec, return a factory function (parent) -> frame that
  builds a frame matching the spec. Pure construction; chrome wrapping
  (hover tint, click handlers) is applied separately so this stays
  spec-agnostic.
]]
local function buildSpecFactory(spec)
    return function(parent)
        local frameType = spec.pickable and "Button" or "Frame"
        local frame = CreateFrame(frameType, nil, parent)
        frame:SetHeight(spec.height)

        if spec.background then
            local bg = frame:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            local c = spec.background.color
            local a = spec.background.alpha or c.a or 1.0
            bg:SetColorTexture(c.r, c.g, c.b, a)
        end

        if spec.accentStripe then
            local accent = frame:CreateTexture(nil, "ARTWORK")
            accent:SetPoint("TOPLEFT", 0, 0)
            accent:SetPoint("BOTTOMLEFT", 0, 0)
            accent:SetWidth(spec.accentStripe.width)
            local c = spec.accentStripe.color
            local a = spec.accentStripe.alpha or c.a or 1.0
            accent:SetColorTexture(c.r, c.g, c.b, a)
            accent:Hide()  -- render decides per-row visibility
            frame.accent = accent
        end

        if spec.texts then
            for i = 1, #spec.texts do
                local t = spec.texts[i]
                local fs = frame:CreateFontString(nil, "OVERLAY", t.font)
                if t.points then
                    for j = 1, #t.points do
                        fs:SetPoint(unpack(t.points[j]))
                    end
                end
                fs:SetJustifyH(t.justifyH or "LEFT")
                fs:SetJustifyV("TOP")
                -- Fixed-width single-line truncation idiom. WordWrap+
                -- MaxLines tells WoW to wrap the text internally then
                -- display only the first line with ellipsis. SetHeight
                -- pins the FontString to its font's nominal line height
                -- — without this, the internal multi-line layout makes
                -- the FontString report a height larger than the visible
                -- content, which pokes past the row's bottom into the
                -- scrollFrame's measured-content area and produces a
                -- phantom scroll range. Querying GetFont keeps this
                -- correct for any font addon the user has installed.
                fs:SetWordWrap(true)
                fs:SetMaxLines(1)
                local _, fontSize = fs:GetFont()
                fs:SetHeight(fontSize)
                frame[t.key] = fs
            end
        end

        if spec.overflowTooltip then
            Mixin(frame, Addon.overflowTooltipMixin)
            frame:InitOverflowTooltip()
        end

        return frame
    end
end

--[[
  Validate a row spec. Throws on bad spec. Catches mistakes at
  create-time so they don't surface as nil-index errors during render.
]]
local function validateSpec(kind, spec)
    if type(spec) ~= "table" then
        error("typeaheadPicker: rows." .. kind .. " must be a table")
    end
    if type(spec.pickable) ~= "boolean" then
        error("typeaheadPicker: rows." .. kind .. ".pickable must be boolean")
    end
    if type(spec.height) ~= "number" then
        error("typeaheadPicker: rows." .. kind .. ".height must be a number")
    end
    if type(spec.render) ~= "function" then
        error("typeaheadPicker: rows." .. kind .. ".render must be a function")
    end
    if spec.overflowTooltip and not spec.pickable then
        error("typeaheadPicker: rows." .. kind ..
              ".overflowTooltip requires pickable=true (mixin hooks mouse events)")
    end
end

-- ============================================================================
-- FACTORY
-- ============================================================================

--[[
  Create a typeahead picker instance.

  @param config table - See header for full schema.
  @return table       - Picker instance with attach/onQuery/hide/etc.
]]
function typeaheadPicker:create(config)
    if not config then
        error("typeaheadPicker:create requires config")
    end
    if not config.runQuery then
        error("typeaheadPicker:create requires config.runQuery")
    end
    if type(config.rows) ~= "table" or next(config.rows) == nil then
        error("typeaheadPicker:create requires config.rows with at least one kind")
    end

    for kind, spec in pairs(config.rows) do
        validateSpec(kind, spec)
    end

    -- Resolve config with defaults.
    local debounce       = config.debounce       or DEFAULTS.debounce
    local minQueryLen    = config.minQueryLen    or DEFAULTS.minQueryLen
    local maxResults     = config.maxResults     or DEFAULTS.maxResults
    local visibleMaxRows = config.visibleMaxRows or DEFAULTS.visibleMaxRows
    local pad            = DEFAULTS.pad
    local scrollbarW     = DEFAULTS.scrollbarW

    -- hideOnPick: explicit false stays as false; nil → default true.
    local hideOnPick = config.hideOnPick
    if hideOnPick == nil then hideOnPick = DEFAULTS.hideOnPick end

    -- showChevron: opt-in affordance. When true, attach installs a
    -- caret button on the edit's right edge. Visibility and click
    -- behavior are governed by chevronVisibleWhen and chevronAction
    -- respectively — see the docblock at the top of the file.
    local showChevron = config.showChevron
    if showChevron == nil then showChevron = DEFAULTS.showChevron end

    local chevronVisibleWhen = config.chevronVisibleWhen or DEFAULTS.chevronVisibleWhen
    local chevronAction      = config.chevronAction      or DEFAULTS.chevronAction

    local instance = {}

    -- Per-instance UI state (populated in :attach)
    local dropdown
    local scrollFrame
    local scrollContent
    local attachedEdit
    local dropdownWidth   -- captured from attach(width); used by showResults
                          -- to widen/narrow scrollContent as the bar toggles
    local onPickFn = config.onPick

    -- Per-kind frame pools, lazily populated on first use. A consumer
    -- whose query only emits "row" items never builds the header pool.
    local pools = {}

    -- Ordered list of currently-rendered pickable frames, in display
    -- order. Used by keyboard nav to walk through results and by
    -- commitHighlight to look up which frame's item to pick. Rebuilt
    -- on every showResults; empty when dropdown is hidden.
    local pickableFrames = {}

    -- Index into pickableFrames of the currently-highlighted row, or
    -- nil when nothing is highlighted (initial state of each query).
    local highlightIndex

    -- Debounce token. Bumped on every onQuery; the C_Timer callback
    -- captures the current token and bails if it's been superseded.
    local queryToken = 0

    -- Chrome's own theme tokens — independent of how consumers style
    -- the rest of the row. Dropdown bg matches OVERLAY (the documented
    -- popover/dropdown surface); hover tint uses SURFACE.ROW_HOVER
    -- (the documented mouseover row wash, same token watchList uses).
    -- BRAND.SELECTION_TINT_* is intentionally NOT used here — those
    -- denote persistent selection/active state, not transient hover.
    local hlToken = Addon.theme.tokens.SURFACE.ROW_HOVER
    local bgToken = Addon.theme.tokens.SURFACE.OVERLAY

    -- ========================================================================
    -- INTERNAL: chrome wiring (hover tint + click) for pickable kinds
    -- ========================================================================

    local function applyChrome(frame, pickable)
        -- Hover tint sits at BACKGROUND, drawn after any consumer
        -- background so the tint is visible on top of it.
        local hl = frame:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints()
        hl:SetColorTexture(hlToken.r, hlToken.g, hlToken.b, hlToken.a)
        hl:Hide()
        frame._chrome_hl = hl

        if not pickable then return end

        -- OnEnter/OnLeave use HookScript so consumer-installed handlers
        -- (e.g., overflowTooltipMixin) coexist with the chrome's
        -- highlight. OnClick is SetScript: it's the chrome's primary
        -- contract; chaining click handlers would be surprising.
        frame:HookScript("OnEnter", function(self) self._chrome_hl:Show() end)
        frame:HookScript("OnLeave", function(self) self._chrome_hl:Hide() end)
        frame:SetScript("OnClick", function(self)
            if onPickFn and self._chrome_item then
                onPickFn(self._chrome_item)
            end
            if hideOnPick then instance:hide() end
        end)
    end

    --[[
      Get or create the pool for a kind. Spec-driven construction +
      chrome wrapping.
    ]]
    local function getPool(kind)
        local existing = pools[kind]
        if existing then return existing end

        local spec = config.rows[kind]
        if not spec then
            error("typeaheadPicker: item kind '" .. tostring(kind) ..
                  "' has no entry in config.rows")
        end

        local specFactory = buildSpecFactory(spec)

        local pool = Addon.pool:new(function()
            local frame = specFactory(scrollContent)
            applyChrome(frame, spec.pickable)
            return frame
        end)

        pools[kind] = pool
        return pool
    end

    -- ========================================================================
    -- INTERNAL: layout
    -- ========================================================================

    local function showResults(items)
        if not dropdown then return end

        -- Release every pool's active frames. Items might come back
        -- with a different kind mix than last time; releaseAll on each
        -- pool is the safe path.
        for _, p in pairs(pools) do
            p:releaseAll()
        end

        -- Reset keyboard-nav state. Each fresh query starts with no
        -- row highlighted; the user pressing Down once selects the
        -- first pickable row.
        pickableFrames = {}
        highlightIndex = nil

        if not items or #items == 0 then
            dropdown:Hide()
            return
        end

        -- Place items top-to-bottom, tracking cumulative height. Cache
        -- the first pickable-row's height for viewport sizing below.
        local totalH = 0
        local rowH

        for i = 1, #items do
            local item = items[i]
            local kind = item.kind
            if not kind then
                error("typeaheadPicker: item missing 'kind' field at index " .. i)
            end

            local spec = config.rows[kind]
            if not spec then
                error("typeaheadPicker: no spec for kind '" .. kind .. "'")
            end

            local frame = getPool(kind):acquire()

            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT",  0, -totalH)
            frame:SetPoint("TOPRIGHT", 0, -totalH)

            spec.render(frame, item)
            frame._chrome_item = item

            frame:Show()

            -- Recycled frames may have hover state stuck on; reset.
            if frame._chrome_hl then frame._chrome_hl:Hide() end

            -- Pickable frames go into the keyboard-nav list in display
            -- order. Non-pickable kinds (headers) are skipped: arrow
            -- keys walk only the pickable rows.
            if spec.pickable then
                pickableFrames[#pickableFrames + 1] = frame
                rowH = rowH or spec.height
            end

            totalH = totalH + spec.height
        end

        scrollContent:SetHeight(totalH)

        -- Viewport caps at visibleMaxRows * (first pickable row's
        -- height) — long header sections shouldn't shrink the list of
        -- pickable rows below the user's expectation. If there are no
        -- pickable rows (degenerate case), cap at total height.
        local cap = (rowH or totalH) * visibleMaxRows
        local viewportH = math.min(totalH, cap)
        dropdown:SetHeight(viewportH + pad * 2)

        scrollFrame:SetVerticalScroll(0)

        -- Force the engine to recompute scroll range now. Without this,
        -- the internal range carries residue from prior larger-content
        -- layouts (e.g., a typeahead narrowing as the user types):
        -- content shrinks but GetVerticalScrollRange keeps returning
        -- the larger residual value. The scrollbar visibility check
        -- below depends on an accurate read.
        scrollFrame:UpdateScrollChildRect()

        dropdown:Show()

        -- Scrollbar visibility, and reclaim the gutter when hidden.
        -- The scrollFrame's right inset reserves scrollbarW pixels for
        -- the bar; when the bar isn't needed, those pixels are dead
        -- space. Re-anchor both the scrollFrame and the scrollContent
        -- to whichever right inset matches the current bar state.
        -- Widening doesn't affect scroll range (content height is
        -- driven by row count, not width), and the explicit FontString
        -- heights set in the row factory keep truncation behavior
        -- correct at any width.
        local sb = scrollFrame.ScrollBar
        local hasScroll = scrollFrame:GetVerticalScrollRange() > 0
        local rightInset = pad + (hasScroll and scrollbarW or 0)
        scrollFrame:ClearAllPoints()
        scrollFrame:SetPoint("TOPLEFT",     pad,         -pad)
        scrollFrame:SetPoint("BOTTOMRIGHT", -rightInset,  pad)
        scrollContent:SetWidth(dropdownWidth - pad * 2 - (hasScroll and scrollbarW or 0))
        if sb then
            if hasScroll then sb:Show() else sb:Hide() end
        end
    end

    -- ========================================================================
    -- INTERNAL: keyboard-nav highlight
    -- ========================================================================

    --[[
      Update the visual highlight on every pickable frame to match
      highlightIndex. Reuses _chrome_hl (the same texture the mouse
      uses) so keyboard and mouse highlights look identical.
    ]]
    local function refreshHighlight()
        for i = 1, #pickableFrames do
            local frame = pickableFrames[i]
            if frame._chrome_hl then
                if i == highlightIndex then
                    frame._chrome_hl:Show()
                else
                    frame._chrome_hl:Hide()
                end
            end
        end
    end

    --[[
      Scroll the highlighted row into view if it's outside the
      viewport. Uses the frame's anchor offset (negative Y in WoW
      coords) as a stand-in for its top within scrollContent.
    ]]
    local function scrollHighlightIntoView()
        if not highlightIndex then return end
        local frame = pickableFrames[highlightIndex]
        if not frame then return end

        local scroll = scrollFrame:GetVerticalScroll()
        local viewportH = scrollFrame:GetHeight()
        local _, _, _, _, offsetY = frame:GetPoint(1)
        local frameTop = -(offsetY or 0)
        local frameBottom = frameTop + frame:GetHeight()

        if frameTop < scroll then
            scrollFrame:SetVerticalScroll(frameTop)
        elseif frameBottom > scroll + viewportH then
            scrollFrame:SetVerticalScroll(frameBottom - viewportH)
        end
    end

    -- ========================================================================
    -- PUBLIC METHODS
    -- ========================================================================

    function instance:onQuery(text)
        queryToken = queryToken + 1
        local myToken = queryToken

        if (not text) or #text < minQueryLen then
            if dropdown then dropdown:Hide() end
            return
        end

        C_Timer.After(debounce, function()
            -- Superseded by a later query; bail.
            if myToken ~= queryToken then return end
            if not attachedEdit then return end
            if not attachedEdit:IsVisible() then return end

            local results = config.runQuery(text)
            -- Honor maxResults regardless of what runQuery returns;
            -- consumers might over-produce.
            if results and #results > maxResults then
                local trimmed = {}
                for i = 1, maxResults do trimmed[i] = results[i] end
                results = trimmed
            end
            showResults(results)
        end)
    end

    --[[
      Open the dropdown with results for the current edit text.
      Bypasses minQueryLen (the gate is for typing latency, not for
      deliberate user actions like clicking the chevron) and skips
      the debounce (the chevron is a single deliberate action; no
      keystrokes to coalesce). Invalidates any in-flight debounced
      query so a delayed keystroke result can't overwrite the
      chevron-triggered display.

      Reads the current edit text rather than always querying ""
      because the user's mental model of the chevron is "show me
      suggestions for what's in there now" — empty box → all
      results; partial input → filtered. Matches standard combobox
      behavior.
    ]]
    function instance:showSuggestions()
        queryToken = queryToken + 1   -- invalidate in-flight debounce
        if not attachedEdit then return end
        if not attachedEdit:IsVisible() then return end

        local text = attachedEdit:GetText() or ""
        local results = config.runQuery(text)
        if results and #results > maxResults then
            local trimmed = {}
            for i = 1, maxResults do trimmed[i] = results[i] end
            results = trimmed
        end
        showResults(results)
    end

    function instance:hide()
        queryToken = queryToken + 1   -- invalidate any in-flight debounce
        if dropdown then dropdown:Hide() end
        pickableFrames = {}
        highlightIndex = nil
    end

    function instance:isShown()
        return dropdown ~= nil and dropdown:IsShown()
    end

    --[[
      Move the keyboard highlight up or down through pickable rows.
      Wraps at both ends. No-op when no rows are visible. Caller
      passes 1 for down, -1 for up.
    ]]
    function instance:moveHighlight(dir)
        local n = #pickableFrames
        if n == 0 then return end

        if highlightIndex == nil then
            highlightIndex = (dir > 0) and 1 or n
        else
            highlightIndex = highlightIndex + dir
            if     highlightIndex < 1 then highlightIndex = n
            elseif highlightIndex > n then highlightIndex = 1 end
        end

        refreshHighlight()
        scrollHighlightIntoView()
    end

    --[[
      Pick the currently-highlighted row, if any. Returns true if a
      pick was committed; false if no row was highlighted.
    ]]
    function instance:commitHighlight()
        if not highlightIndex then return false end
        local frame = pickableFrames[highlightIndex]
        if not frame or not frame._chrome_item then return false end
        if onPickFn then onPickFn(frame._chrome_item) end
        if hideOnPick then instance:hide() end
        return true
    end

    --[[
      Wire the picker to an edit box. Must be called once before
      onQuery is invoked. Does NOT install scripts on the edit box —
      the caller drives onQuery / hide directly.

      Frame layering owned by the picker (consumer doesn't pass strata):
        FULLSCREEN_DIALOG — the dropdown itself. Sits above anything
                            at DIALOG (panels, sub-panels) so dropdown
                            rows always win mouse focus over panel
                            content underneath.
        FULLSCREEN        — invisible click catcher, full screen, shown
                            only while the dropdown is shown. Anything
                            in this band sits between dropdown and
                            panels. Catches clicks outside the dropdown
                            and dismisses; propagates the click through
                            so the underlying frame still receives it
                            (so e.g. clicking another button outside
                            the dropdown both closes the dropdown AND
                            fires the other button).

      @param editBox Frame
      @param parent  Frame   - Parent for the dropdown. Pass UIParent
                               (or a higher ancestor) to escape any
                               clipsChildren on intermediate frames.
      @param width   number  - Dropdown pixel width.
      @param opts    table|nil { growDownward = bool }
    ]]
    function instance:attach(editBox, parent, width, opts)
        opts = opts or {}
        attachedEdit = editBox
        dropdownWidth = width

        dropdown = Addon.panel:opaque(parent, {
            strata = "FULLSCREEN_DIALOG",
            r = bgToken.r, g = bgToken.g, b = bgToken.b, a = bgToken.a,
        })
        dropdown:SetWidth(width)

        scrollFrame = CreateFrame("ScrollFrame", config.scrollFrameName, dropdown,
                                  "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT",     pad,                -pad)
        scrollFrame:SetPoint("BOTTOMRIGHT", -pad - scrollbarW,   pad)

        scrollContent = CreateFrame("Frame", nil, scrollFrame)
        scrollContent:SetSize(width - pad * 2 - scrollbarW, 1)
        scrollFrame:SetScrollChild(scrollContent)

        -- Anchor relative to the edit box. -8 horizontal compensates
        -- for InputBoxTemplate's decorative end caps; all current
        -- consumers use textBox/searchBox which have similar caps.
        if opts.growDownward then
            dropdown:SetPoint("TOPLEFT",    editBox, "BOTTOMLEFT", -8, -10)
        else
            dropdown:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT",    -8,  10)
        end
        dropdown:Hide()

        -- Click catcher: full-screen invisible button that sits between
        -- the dropdown (FULLSCREEN_DIALOG) and the panels (DIALOG).
        -- Shown only while the dropdown is shown; dismisses dropdown
        -- on any click outside its bounds. Clicks do NOT propagate to
        -- the underlying frame — first click closes the dropdown,
        -- second click is needed to operate other UI. Standard
        -- dropdown semantics (matches browser <select>, OS context
        -- menus). Avoids the side-effect of an outside click acting
        -- on the frame it landed on (e.g., toggling a staging row's
        -- checkbox when the user just meant "dismiss the dropdown").
        local clickCatcher = CreateFrame("Button", nil, UIParent)
        clickCatcher:SetAllPoints(UIParent)
        clickCatcher:SetFrameStrata("FULLSCREEN")
        clickCatcher:RegisterForClicks("AnyDown")
        clickCatcher:SetScript("OnClick", function()
            instance:hide()
        end)
        clickCatcher:Hide()

        dropdown:HookScript("OnShow", function() clickCatcher:Show() end)
        dropdown:HookScript("OnHide", function() clickCatcher:Hide() end)

        -- Industry-standard combobox layout: chevron at the outermost
        -- right edge (the permanent affordance "this is a combobox"),
        -- and the clear button — when present, contextual to having
        -- content — sits to the chevron's left. searchBox creates the
        -- clearButton anchored to its own right edge; we re-anchor it
        -- here so the chevron can claim the right slot.
        if showChevron then
            local chevron = CreateFrame("Button", nil, editBox)
            chevron:SetSize(DEFAULTS.chevronSize, DEFAULTS.chevronSize)
            chevron:SetPoint("RIGHT", editBox, "RIGHT", -4, 0)

            if editBox.clearButton then
                editBox.clearButton:ClearAllPoints()
                editBox.clearButton:SetPoint("RIGHT", chevron, "LEFT",
                                             -DEFAULTS.chevronGap, 0)
            end

            -- Stock dropdown chevron artwork. The texcoord crop matches
            -- the family's dropdown.lua / dropdownLegacy.lua convention:
            -- the raw texture has transparent margin that makes the
            -- arrow look small and off-center; cropping to the inner
            -- 50% renders at the expected size.
            local tex = chevron:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            tex:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
            tex:SetTexCoord(0.25, 0.75, 0.25, 0.75)

            chevron:SetScript("OnClick", function()
                if instance:isShown() then
                    instance:hide()
                    return
                end
                editBox:SetFocus()
                if chevronAction == "showAll" then
                    -- Bypass minQueryLen; show whatever runQuery("") returns.
                    instance:showSuggestions()
                else
                    -- "toggle": only open the dropdown if the current
                    -- query meets minQueryLen. No-op below threshold
                    -- (and in practice the chevron is hidden in that
                    -- state when chevronVisibleWhen == "hasQuery").
                    local text = editBox:GetText() or ""
                    if #text >= minQueryLen then
                        instance:showSuggestions()
                    end
                end
            end)

            -- Visibility policy. "always" leaves the chevron permanently
            -- shown; other modes drive it from editBox text changes,
            -- paralleling searchBox's clear-icon visibility pattern.
            if chevronVisibleWhen ~= "always" then
                local predicate
                if chevronVisibleWhen == "hasQuery" then
                    predicate = function(t) return t and #t >= minQueryLen end
                elseif type(chevronVisibleWhen) == "function" then
                    predicate = chevronVisibleWhen
                else
                    -- Unknown string; fall back to "always" behavior so
                    -- a typo doesn't render the chevron permanently
                    -- invisible.
                    predicate = function() return true end
                end

                local function updateChevronVisibility()
                    local text = editBox:GetText() or ""
                    if predicate(text) then
                        chevron:Show()
                    else
                        chevron:Hide()
                    end
                end

                -- HookScript so we coexist with any other consumer of
                -- OnTextChanged (e.g. searchBox's clear-button toggle).
                editBox:HookScript("OnTextChanged", updateChevronVisibility)
                updateChevronVisibility()  -- initial state
            end
        end
    end

    return instance
end

Addon.typeaheadPicker = typeaheadPicker
return typeaheadPicker
