--[[
  ui/shared/widgets/typeaheadPicker.lua
  Typeahead Picker Factory

  Generic chrome for popup pickers attached to an EditBox: scrollable
  result list, frame pool, debounced query, click-to-pick. The picker
  is the dropdown surface; the consumer is responsible for what items
  look like and where they come from.

  This widget exists because two different consumers (NPC name search,
  zone search) had nearly identical scaffolding around totally
  different search backends. The chrome — debounce, scroll, pool,
  anchor logic, hover tint, click-to-pick — is the shared primitive.

  Usage:
    local picker = typeaheadPicker:create({
        runQuery     = function(text) return {item, item, ...} end,

        -- Per-kind rendering. Items must carry a `kind` field whose
        -- value is a key in `factories` and `renderers`.
        factories    = {
            row = function(parent) return frame end,
            header = function(parent) return frame end,  -- optional
        },
        renderers    = {
            row = function(frame, item) end,
            header = function(frame, item) end,
        },
        heights      = { row = 36, header = 24 },

        -- The shape of items the consumer hands back to onPick.
        -- Default behavior: invoke onPick on click of any item whose
        -- kind is in `pickableKinds`. Default pickableKinds = {row=true}.
        -- pickableKinds = { row = true },

        onPick       = function(item) end,

        -- Tunables (all optional, sensible defaults provided)
        debounce        = 0.2,
        minQueryLen     = 1,
        maxResults      = 100,
        visibleMaxRows  = 7,    -- viewport caps at this many "row" heights
        scrollFrameName = "MyAddonPickerScroll",
    })

    picker:attach(editBox, parent, width, opts)  -- opts = { growDownward = bool }
    picker:onQuery(text)
    picker:hide()

  Each :create() returns an independent picker — no shared global state
  between instances. State (debounce token, current dropdown frame,
  pools) is closed over per-instance.

  Dependencies: panel, pool
  Exports: Addon.typeaheadPicker
]]

local ADDON_NAME, Addon = ...

local typeaheadPicker = {}

-- ============================================================================
-- DEFAULTS
-- ============================================================================

local DEFAULTS = {
    debounce        = 0.2,
    minQueryLen     = 1,
    maxResults      = 100,
    visibleMaxRows  = 7,
    pickableKinds   = { row = true },

    -- Whether the dropdown auto-hides after a pick. Single-pick
    -- consumers (Name field → fills the field → done) want true.
    -- Multi-pick consumers (item-add panel → user adds several
    -- items in a row) want false: the dropdown stays open so the
    -- user can keep clicking matches without re-querying.
    hideOnPick      = true,

    -- Visual constants. The chrome owns these so all consumers look
    -- the same. If a consumer needs a different look, that's a strong
    -- signal it's a different widget, not a different config of this
    -- one.
    pad             = 8,
    scrollbarW      = 20,
    bgR             = 0.10,
    bgG             = 0.10,
    bgB             = 0.12,
    bgA             = 1.0,
    hlR             = 0.35,
    hlG             = 0.65,
    hlB             = 1.00,
    hlA             = 0.35,
}

-- ============================================================================
-- FACTORY
-- ============================================================================

--[[
  Create a typeahead picker instance.

  @param config table - See header for full schema.
  @return table - Picker instance with attach/onQuery/hide methods.
]]
function typeaheadPicker:create(config)
    if not config then
        error("typeaheadPicker:create requires config")
        return nil
    end
    if not config.runQuery then
        error("typeaheadPicker:create requires config.runQuery")
        return nil
    end
    if not config.factories or not config.renderers or not config.heights then
        error("typeaheadPicker:create requires factories, renderers, heights")
        return nil
    end
    if not config.scrollFrameName then
        error("typeaheadPicker:create requires scrollFrameName for scrollbar lookup")
        return nil
    end

    -- Resolve config with defaults.
    local debounce       = config.debounce       or DEFAULTS.debounce
    local minQueryLen    = config.minQueryLen    or DEFAULTS.minQueryLen
    local maxResults     = config.maxResults     or DEFAULTS.maxResults
    local visibleMaxRows = config.visibleMaxRows or DEFAULTS.visibleMaxRows
    local pickableKinds  = config.pickableKinds  or DEFAULTS.pickableKinds
    local pad            = DEFAULTS.pad
    local scrollbarW     = DEFAULTS.scrollbarW

    -- hideOnPick: explicit false stays as false; nil → default true.
    local hideOnPick = config.hideOnPick
    if hideOnPick == nil then hideOnPick = DEFAULTS.hideOnPick end

    -- The picker itself. Methods bind to upvalues below.
    local instance = {}

    -- Per-instance UI state (set up in :attach)
    local dropdown
    local scrollFrame
    local scrollContent
    local attachedEdit
    local onPickFn = config.onPick

    -- Per-kind frame pools, lazily populated on first use of each kind.
    -- A consumer that only emits "row" items never builds the header
    -- pool, etc.
    local pools = {}

    -- Ordered list of currently-rendered pickable frames, in display
    -- order. Used by keyboard nav to walk through results, and by
    -- commitHighlight to look up which frame's item to pick. Rebuilt
    -- on every showResults; empty when dropdown is hidden.
    local pickableFrames = {}

    -- Index into pickableFrames of the currently-highlighted row, or
    -- nil when nothing is highlighted (initial state on each query).
    local highlightIndex

    -- Debounce token. Bumped on every onQuery; the C_Timer callback
    -- captures the current token and bails if it's been superseded.
    local queryToken = 0

    -- ========================================================================
    -- INTERNAL: row creation + click wiring
    -- ========================================================================

    --[[
      Get or create the pool for a kind. Wraps the consumer's factory
      with chrome behavior (hover tint, click handling).
    ]]
    local function getPool(kind)
        local existing = pools[kind]
        if existing then return existing end

        local userFactory = config.factories[kind]
        if not userFactory then
            error("typeaheadPicker: no factory for kind '" .. tostring(kind) .. "'")
        end

        local pool = Addon.pool:new(function()
            local frame = userFactory(scrollContent)

            -- Chrome adds a hover tint texture behind whatever the
            -- consumer rendered. The consumer's renderer can use any
            -- layer; tint sits at BACKGROUND so it's underneath.
            local hl = frame:CreateTexture(nil, "BACKGROUND")
            hl:SetAllPoints()
            hl:SetColorTexture(DEFAULTS.hlR, DEFAULTS.hlG, DEFAULTS.hlB, DEFAULTS.hlA)
            hl:Hide()
            frame._chrome_hl = hl

            -- Chrome handles enter/leave for hover, and click for
            -- pick. The consumer's factory is responsible for making
            -- the frame mouse-enabled (e.g., creating it as a Button)
            -- IF this kind is pickable. Non-pickable kinds (headers)
            -- can be plain Frames with no mouse interaction.
            --
            -- OnEnter/OnLeave use HookScript so external code (e.g.,
            -- an overflowTooltipMixin) can add additional hover
            -- behavior without wiping the chrome's highlight. OnClick
            -- stays as SetScript: it's the chrome's primary contract,
            -- and chaining multiple click handlers via Hook would be
            -- surprising for consumers.
            if pickableKinds[kind] then
                frame:HookScript("OnEnter", function(self) self._chrome_hl:Show() end)
                frame:HookScript("OnLeave", function(self) self._chrome_hl:Hide() end)
                frame:SetScript("OnClick", function(self)
                    if onPickFn and self._chrome_item then
                        onPickFn(self._chrome_item)
                    end
                    if hideOnPick then instance:hide() end
                end)
            end

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
        -- as a different mix of kinds than last time; releaseAll on
        -- each pool is the safe path.
        for _, p in pairs(pools) do
            p:releaseAll()
        end

        -- Reset keyboard-nav state. A fresh query starts with no
        -- row highlighted; the user pressing Down once selects the
        -- first pickable row.
        pickableFrames = {}
        highlightIndex = nil

        if not items or #items == 0 then
            dropdown:Hide()
            return
        end

        -- Place items top-to-bottom, tracking cumulative height, and
        -- count "row"-kind heights for viewport sizing.
        local totalH = 0
        local rowKindHeights = 0
        local rowKindCount = 0

        for i = 1, #items do
            local item = items[i]
            local kind = item.kind
            if not kind then
                error("typeaheadPicker: item missing 'kind' field at index " .. i)
            end

            local h = config.heights[kind]
            if not h then
                error("typeaheadPicker: no height for kind '" .. kind .. "'")
            end

            local frame = getPool(kind):acquire()

            frame:ClearAllPoints()
            frame:SetPoint("TOPLEFT", 0, -totalH)
            frame:SetPoint("TOPRIGHT", 0, -totalH)

            config.renderers[kind](frame, item)
            frame._chrome_item = item

            frame:Show()

            -- Reset hover state — recycled frames may have it stuck on.
            if frame._chrome_hl then frame._chrome_hl:Hide() end

            -- Pickable frames go into the keyboard-nav list in display
            -- order. Headers and other non-pickable kinds are skipped:
            -- arrow keys walk only the pickable rows.
            if pickableKinds[kind] then
                pickableFrames[#pickableFrames + 1] = frame
            end

            totalH = totalH + h
            -- Use "row" height as the viewport unit. Headers count
            -- against total but not against the visible-rows cap.
            if kind == "row" then
                rowKindHeights = rowKindHeights + h
                rowKindCount = rowKindCount + 1
                if rowKindCount == 1 then
                    -- Cache row height for viewport math (assumes all
                    -- "row" items are the same height — typical case).
                    -- If consumers ever need variable row heights,
                    -- this caps incorrectly; revisit then.
                    instance._rowH = h
                end
            end
        end

        scrollContent:SetHeight(totalH)

        -- Viewport caps at visibleMaxRows * rowHeight, not measured
        -- against headers — long header sections shouldn't shrink the
        -- list of pickable rows below the user's expectation.
        local rowH = instance._rowH or 36
        local cap = visibleMaxRows * rowH
        local viewportH = math.min(totalH, cap)
        dropdown:SetHeight(viewportH + pad * 2)

        scrollFrame:SetVerticalScroll(0)

        local scrollBar = _G[config.scrollFrameName .. "ScrollBar"]
        if scrollBar then
            if totalH > viewportH then scrollBar:Show() else scrollBar:Hide() end
        end

        dropdown:Show()
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
            -- Honor maxResults cap regardless of what runQuery returns;
            -- consumer might over-produce.
            if results and #results > maxResults then
                local trimmed = {}
                for i = 1, maxResults do trimmed[i] = results[i] end
                results = trimmed
            end
            showResults(results)
        end)
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
      Update the visual highlight on every pickable frame to match
      highlightIndex. Reuses _chrome_hl (the same texture used for
      mouse hover) so keyboard and mouse highlights look identical.
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
            if highlightIndex < 1 then highlightIndex = n
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
      onQuery is invoked. Doesn't install scripts on the edit box —
      the caller drives onQuery / hide directly.

      @param editBox Frame
      @param parent  Frame   - Frame to parent the dropdown to. The
                               dropdown is positioned relative to
                               editBox regardless, but parented here
                               for strata/visibility/clipping purposes.
                               If editBox sits inside a frame with
                               SetClipsChildren(true), the dropdown
                               would be clipped if parented under
                               that frame; pass UIParent (or a higher
                               ancestor) to escape the clip.
      @param width   number  - Dropdown pixel width.
      @param opts    table|nil {
          growDownward = bool,
          strata       = string|nil — explicit frame strata for the
                                      dropdown. Defaults to inheriting
                                      from parent. Pass "DIALOG" or
                                      higher when parent is UIParent
                                      and the dropdown should appear
                                      above other UI.
      }
    ]]
    function instance:attach(editBox, parent, width, opts)
        opts = opts or {}
        attachedEdit = editBox

        dropdown = Addon.panel:opaque(parent, {
            -- If caller specified strata explicitly, use that.
            -- Otherwise inherit from parent (the prior behavior).
            strata       = opts.strata,
            parentStrata = (not opts.strata) and true or nil,
            r = DEFAULTS.bgR, g = DEFAULTS.bgG, b = DEFAULTS.bgB, a = DEFAULTS.bgA,
        })
        dropdown:SetWidth(width)

        scrollFrame = CreateFrame("ScrollFrame", config.scrollFrameName, dropdown,
                                  "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", pad, -pad)
        scrollFrame:SetPoint("BOTTOMRIGHT", -pad - scrollbarW, pad)

        scrollContent = CreateFrame("Frame", nil, scrollFrame)
        scrollContent:SetSize(width - pad * 2 - scrollbarW, 1)
        scrollFrame:SetScrollChild(scrollContent)

        -- Anchor relative to the edit box. -8 horizontal compensates
        -- for InputBoxTemplate's decorative end caps; consumers using
        -- non-InputBoxTemplate inputs may want a different offset, but
        -- in practice all current consumers use textBox/searchBox
        -- which have similar caps.
        if opts.growDownward then
            dropdown:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", -8, -10)
        else
            dropdown:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT", -8, 10)
        end
        dropdown:Hide()
    end

    return instance
end

Addon.typeaheadPicker = typeaheadPicker
return typeaheadPicker
