--[[
  ui/shared/widgets/listView.lua   [SHARED: pending sync to monorepo shared/]
  ListView — generic scrollable, pooled, vertical list with sort/filter/group

  A reusable container for any "scrolling list of items" UI in the
  addon family: watch lists, search staging, leaderboards, anywhere a
  scrollable column of pooled rows is needed. Vertical-only by design;
  flow layouts (chip strips, etc.) belong in a separate widget.

  Construction is declarative. The consumer describes:
    - Where the data comes from (dataFn) and how to identify each item
      (identityFn).
    - An optional pipeline: filter → sort → group, all as plain
      functions.
    - Per-kind render specs (height, factory, render) keyed by the
      item's `kind` field. Group headers are themselves a kind named
      "group"; they may carry an optional expandable body.
    - Optional event hooks (click, double-click, context menu,
      selection-changed).

  ListView owns:
    - The ScrollFrame + content frame.
    - Pools per kind (lazy, one per kind).
    - The selected identity (nullable; single selection only).
    - Group-expand state (which group keys are open).
    - Click/double-click dispatch (with manual double-click timing for
      TBC Classic which has no OnDoubleClick).

  ListView does NOT own:
    - Any row visuals. Backgrounds, hover tints, accent stripes,
      selection paint — all consumer-rendered inside `factory` and
      `render`. Hover handlers go on the frame in `factory`.
    - Per-row state beyond identity. Toggle states, expansion of
      non-group rows, etc., live in the consumer.
    - Persistence. `getExpandedKeys` / `setExpandedKeys` are the hooks
      for the consumer to mirror state into its SavedVariable.

  Usage:
    local lv = Addon.listView:create({
        parent     = scrollChildFrame,
        width      = 300,
        height     = 400,
        scrollFrameName = "MyListScroll",   -- optional; debug aid only

        dataFn     = function() return svData.items end,
        identityFn = function(item) return item._id end,

        filter = function(item) return item.visible end,
        sort   = function(a, b) return a.name < b.name end,
        group  = {
            key       = function(item) return item.zone or "(none)" end,
            sort      = function(a, b) return a < b end,
            accordion = false,
        },

        kinds = {
            -- Item-row kinds keyed by `item.kind`. Each item returned
            -- from dataFn must carry a `kind` field. Single-kind lists
            -- can omit the field and have `kinds.row = { ... }` —
            -- listView defaults item.kind to "row" if absent.
            row = {
                height  = 36,
                factory = function(parent) ... return frame end,
                render  = function(frame, item, ctx)
                    -- ctx = { isSelected, identity }
                end,
            },

            -- Group header kind. Required only if `group` is set.
            -- Optional `body` slot enables expand/collapse: when the
            -- header is clicked, the body region renders below it.
            group = {
                headerHeight = 22,
                factory      = function(parent) ... return frame end,
                render       = function(frame, key, items, expanded) ... end,
                body = {
                    renderHeight = function(key, items) return 100 end,
                    factory      = function(parent) ... return frame end,
                    render       = function(frame, key, items) ... end,
                },
            },
        },

        onClick            = function(item, kind, identity) ... end,
        onDoubleClick      = function(item, kind, identity) ... end,
        onContextMenu      = function(item, kind, identity, frame) ... end,
        onSelectionChanged = function(identity) ... end,
    })

    lv:refresh()
    lv:getSelected();      lv:setSelected(id);   lv:clearSelection()
    lv:setSort(fn);        lv:setFilter(fnOrArr); lv:setGroup(spec)
    lv:getExpandedKeys();  lv:setExpandedKeys(set)
    lv:isExpanded(key);    lv:setExpanded(key, bool)
    lv:getScrollFrame()    -- escape hatch

  Click semantics:
    - Right-click fires onContextMenu (always); never fires onClick.
    - Left-click: first click fires onClick. Second left-click on the
      same frame within DOUBLE_CLICK_INTERVAL fires onDoubleClick
      INSTEAD of a second onClick. After that, the pair-state resets.
    - If onDoubleClick is absent, every left-click fires onClick.
    - Group-header clicks toggle expand state when `body` is set, and
      additionally fire the consumer's onClick if provided.

  Group rendering rules:
    - Groups with zero post-filter items are skipped entirely (header
      not drawn).
    - "Singleton" suppression: when every visible item maps to one
      group AND the group has no `body` (ornamental header only), the
      header is omitted. Groups with a `body` always show their
      header because the header IS the interactive expand target.

  Dependencies: pool, theme (for chrome tokens — currently unused; the
                widget paints no chrome itself, but is in the family
                that imports theme universally)
  Exports: Addon.listView
]]

local _, Addon = ...

local listView = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

-- Manual double-click timing window (TBC Classic Button has no
-- OnDoubleClick). Matches watchList's previous local constant.
local DOUBLE_CLICK_INTERVAL = 0.4

-- Default kind name when an item has no `kind` field. Lets single-
-- kind lists skip the `kind = "row"` boilerplate per item.
local DEFAULT_KIND = "row"

-- Group-header kind name. Group specs go in `kinds.group`.
local GROUP_KIND = "group"

-- ============================================================================
-- SPEC VALIDATION
-- ============================================================================

local function validateKindSpec(kind, spec)
    if type(spec) ~= "table" then
        error("listView: kinds." .. kind .. " must be a table")
    end
    if kind == GROUP_KIND then
        if type(spec.headerHeight) ~= "number" then
            error("listView: kinds.group.headerHeight must be a number")
        end
        if type(spec.factory) ~= "function" then
            error("listView: kinds.group.factory must be a function")
        end
        if type(spec.render) ~= "function" then
            error("listView: kinds.group.render must be a function")
        end
        if spec.body then
            if type(spec.body) ~= "table" then
                error("listView: kinds.group.body must be a table")
            end
            if type(spec.body.renderHeight) ~= "function" then
                error("listView: kinds.group.body.renderHeight must be a function")
            end
            if type(spec.body.factory) ~= "function" then
                error("listView: kinds.group.body.factory must be a function")
            end
            if type(spec.body.render) ~= "function" then
                error("listView: kinds.group.body.render must be a function")
            end
        end
    else
        if type(spec.height) ~= "number" then
            error("listView: kinds." .. kind .. ".height must be a number")
        end
        if type(spec.factory) ~= "function" then
            error("listView: kinds." .. kind .. ".factory must be a function")
        end
        if type(spec.render) ~= "function" then
            error("listView: kinds." .. kind .. ".render must be a function")
        end
    end
end

local function validateGroupSpec(group)
    if type(group) ~= "table" then
        error("listView: group must be a table")
    end
    if type(group.key) ~= "function" then
        error("listView: group.key must be a function")
    end
    if group.sort ~= nil and type(group.sort) ~= "function" then
        error("listView: group.sort must be a function or nil")
    end
end

-- ============================================================================
-- FILTER PIPELINE
-- ============================================================================

--[[
  Normalize a filter input into a single predicate. Accepts a single
  function (used directly) or an array of functions (AND'd in order).
  nil → nil (no filter).
]]
local function buildFilterPredicate(filter)
    if filter == nil then return nil end
    if type(filter) == "function" then return filter end
    if type(filter) == "table" then
        local fns = filter
        return function(item)
            for i = 1, #fns do
                if not fns[i](item) then return false end
            end
            return true
        end
    end
    error("listView: filter must be a function, an array of functions, or nil")
end

-- ============================================================================
-- FACTORY
-- ============================================================================

--[[
  Create a listView instance.

  @param config table - See header for full schema.
  @return table       - listView instance.
]]
function listView:create(config)
    if not config then
        error("listView:create requires config")
    end
    if not config.parent then
        error("listView:create requires config.parent")
    end
    if type(config.width) ~= "number" or type(config.height) ~= "number" then
        error("listView:create requires numeric config.width and config.height")
    end
    if type(config.dataFn) ~= "function" then
        error("listView:create requires config.dataFn (function)")
    end
    if type(config.identityFn) ~= "function" then
        error("listView:create requires config.identityFn (function)")
    end
    if type(config.kinds) ~= "table" or next(config.kinds) == nil then
        error("listView:create requires config.kinds with at least one kind")
    end

    for kind, spec in pairs(config.kinds) do
        validateKindSpec(kind, spec)
    end

    if config.group then
        validateGroupSpec(config.group)
        if not config.kinds[GROUP_KIND] then
            error("listView:create: group configured but kinds.group missing")
        end
    end

    -- Per-instance state ---------------------------------------------------

    local dataFn        = config.dataFn
    local identityFn    = config.identityFn
    local filterPred    = buildFilterPredicate(config.filter)
    local sortFn        = config.sort
    local groupSpec     = config.group
    local kinds         = config.kinds

    local onClick            = config.onClick
    local onDoubleClick      = config.onDoubleClick
    local onContextMenu      = config.onContextMenu
    local onSelectionChanged = config.onSelectionChanged

    -- Selected identity (nullable). nil = nothing selected.
    local selectedIdentity = nil

    -- Set of group keys currently in the expanded state. Keys present
    -- with value true are expanded; absent/false keys are collapsed.
    local expandedKeys = {}

    -- Pools, one per kind, lazily created on first use. Plus separate
    -- pools for group bodies (keyed by "__body_" + kind to avoid
    -- collision with item kinds). Single-kind lists never pay for
    -- pools they don't use.
    local pools = {}

    -- Identity → frame for currently-rendered item rows. Lets
    -- setSelected re-render only the affected rows. Rebuilt each
    -- refresh; entries removed when rows are released.
    local identityToFrame = {}

    -- Frame → identity, the inverse map. Used by click handlers to
    -- look up the identity for the clicked row. Lives on the frame as
    -- _lvIdentity rather than in this map (cheaper, no extra table
    -- lookup) — keep just for diff visibility during dev. Removed.

    -- Double-click pair state (TBC Classic has no OnDoubleClick).
    local lastClickTime  = 0
    local lastClickFrame = nil

    -- ScrollFrame chrome ---------------------------------------------------

    local frame = CreateFrame("Frame", nil, config.parent)
    frame:SetSize(config.width, config.height)

    local scrollFrame = CreateFrame("ScrollFrame", config.scrollFrameName,
        frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    -- 20px reserve on the right for the scrollbar (UIPanelScrollFrameTemplate
    -- standard). Consumers wanting a different scrollbar style swap the
    -- template; this widget assumes the family-standard chrome.
    scrollFrame:SetPoint("BOTTOMRIGHT", -20, 0)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(config.width - 20, 1)
    scrollFrame:SetScrollChild(content)

    -- Instance object -----------------------------------------------------

    local instance = {}

    -- ====================================================================
    -- INTERNAL: click wiring
    -- ====================================================================

    local function fireClick(self, button)
        local item     = self._lvItem
        local kind     = self._lvKind
        local identity = self._lvIdentity

        if button == "RightButton" then
            if onContextMenu then
                onContextMenu(item, kind, identity, self)
            end
            return
        end

        local now      = GetTime()
        local isDouble = (self == lastClickFrame)
            and ((now - lastClickTime) < DOUBLE_CLICK_INTERVAL)

        if isDouble and onDoubleClick then
            lastClickTime  = 0
            lastClickFrame = nil
            onDoubleClick(item, kind, identity)
        else
            lastClickTime  = now
            lastClickFrame = self
            if onClick then
                onClick(item, kind, identity)
            end
        end
    end

    --[[
      Wire click handlers onto a row frame. Called once per
      factory-produced frame (chrome is permanent across recycles).
      Frames must be a Button (or template inheriting Button) to host
      OnClick / RegisterForClicks.
    ]]
    local function wireRowClicks(rowFrame)
        if not rowFrame.RegisterForClicks then return end  -- not a Button
        if onContextMenu then
            rowFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        else
            rowFrame:RegisterForClicks("LeftButtonUp")
        end
        rowFrame:SetScript("OnClick", fireClick)
    end

    --[[
      Wire group-header clicks. Distinct from rows: a header click
      toggles expand state if the group has a body, then fires the
      consumer's onClick if provided. Right-click still routes through
      onContextMenu.
    ]]
    local groupHasBody = groupSpec and kinds[GROUP_KIND]
        and kinds[GROUP_KIND].body ~= nil

    local function fireGroupHeaderClick(self, button)
        if button == "RightButton" then
            if onContextMenu then
                onContextMenu(self._lvItems, GROUP_KIND, self._lvKey, self)
            end
            return
        end
        if groupHasBody then
            instance:setExpanded(self._lvKey, not expandedKeys[self._lvKey])
        end
        if onClick then
            onClick(self._lvItems, GROUP_KIND, self._lvKey)
        end
    end

    local function wireGroupHeaderClicks(headerFrame)
        if not headerFrame.RegisterForClicks then return end
        if onContextMenu then
            headerFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        else
            headerFrame:RegisterForClicks("LeftButtonUp")
        end
        headerFrame:SetScript("OnClick", fireGroupHeaderClick)
    end

    -- ====================================================================
    -- INTERNAL: pools
    -- ====================================================================

    local function getRowPool(kind)
        local existing = pools[kind]
        if existing then return existing end

        local spec = kinds[kind]
        if not spec then
            error("listView: no kind spec for '" .. tostring(kind) .. "'")
        end

        local pool = Addon.pool:new(function()
            local f = spec.factory(content)
            if kind == GROUP_KIND then
                wireGroupHeaderClicks(f)
            else
                wireRowClicks(f)
            end
            return f
        end)
        pools[kind] = pool
        return pool
    end

    local function getBodyPool()
        local key = "__body__"
        local existing = pools[key]
        if existing then return existing end

        local bodySpec = kinds[GROUP_KIND].body
        local pool = Addon.pool:new(function()
            return bodySpec.factory(content)
        end)
        pools[key] = pool
        return pool
    end

    -- ====================================================================
    -- INTERNAL: pipeline (filter → sort → group)
    -- ====================================================================

    --[[
      Run dataFn, apply filter and sort, return ordered array. No
      grouping yet — caller decides whether to bucket.
    ]]
    local function buildOrderedList()
        local raw  = dataFn() or {}
        local kept = {}

        if filterPred then
            for i = 1, #raw do
                if filterPred(raw[i]) then
                    kept[#kept + 1] = raw[i]
                end
            end
        else
            -- shallow copy so sort doesn't mutate caller's array
            for i = 1, #raw do kept[i] = raw[i] end
        end

        if sortFn then
            table.sort(kept, sortFn)
        end

        return kept
    end

    --[[
      Bucket an ordered list by group.key. Returns:
        groups       — array of { key = key, items = {...} }, ordered
                       by group.sort (or insertion order if no sort fn)
        keysSeen     — set of group keys present
      The items inside each bucket preserve the sort order from
      buildOrderedList.
    ]]
    local function bucketByGroup(orderedList)
        local keyFn = groupSpec.key
        local buckets = {}      -- key → items array
        local order   = {}      -- keys in first-seen order

        for i = 1, #orderedList do
            local item = orderedList[i]
            local key  = keyFn(item)
            if buckets[key] == nil then
                buckets[key] = {}
                order[#order + 1] = key
            end
            buckets[key][#buckets[key] + 1] = item
        end

        if groupSpec.sort then
            table.sort(order, groupSpec.sort)
        end

        local groups = {}
        for i = 1, #order do
            groups[i] = { key = order[i], items = buckets[order[i]] }
        end
        return groups
    end

    -- ====================================================================
    -- INTERNAL: layout
    -- ====================================================================

    local function releaseAllPools()
        for _, pool in pairs(pools) do
            pool:releaseAll()
        end
    end

    local function placeRow(rowFrame, y)
        rowFrame:ClearAllPoints()
        rowFrame:SetPoint("TOPLEFT",  0, -y)
        rowFrame:SetPoint("TOPRIGHT", 0, -y)
        rowFrame:Show()
    end

    --[[
      Render a single item row at the given y offset. Returns the y
      offset just below the row.
    ]]
    local function renderItem(item, y)
        local kind = item.kind or DEFAULT_KIND
        local spec = kinds[kind]
        if not spec then
            error("listView: item has unknown kind '" .. tostring(kind) .. "'")
        end

        local rowFrame = getRowPool(kind):acquire()
        local identity = identityFn(item)

        rowFrame:SetHeight(spec.height)
        rowFrame._lvItem     = item
        rowFrame._lvKind     = kind
        rowFrame._lvIdentity = identity

        identityToFrame[identity] = rowFrame

        placeRow(rowFrame, y)
        spec.render(rowFrame, item, {
            isSelected = (identity == selectedIdentity),
            identity   = identity,
        })

        return y + spec.height
    end

    --[[
      Render a single group's header + (if expanded and bodied) body.
      Returns the y offset just below the group's full extent.
    ]]
    local function renderGroup(group, y)
        local spec     = kinds[GROUP_KIND]
        local key      = group.key
        local items    = group.items
        local expanded = expandedKeys[key] == true

        local header = getRowPool(GROUP_KIND):acquire()
        header._lvKey   = key
        header._lvItems = items

        header:SetHeight(spec.headerHeight)
        placeRow(header, y)
        spec.render(header, key, items, expanded)
        y = y + spec.headerHeight

        if expanded and spec.body then
            local bodyH    = spec.body.renderHeight(key, items)
            local bodyFrame = getBodyPool():acquire()
            bodyFrame:SetHeight(bodyH)
            placeRow(bodyFrame, y)
            spec.body.render(bodyFrame, key, items)
            y = y + bodyH
        elseif not spec.body then
            -- Header-only grouping: render each item below.
            for i = 1, #items do
                y = renderItem(items[i], y)
            end
        end

        return y
    end

    -- Scrollbar visibility, with reclaim of the bar's reserved gutter
    -- when hidden. Called at the end of every refresh() path.
    -- UpdateScrollChildRect forces the engine to recompute scroll
    -- range from the current geometry — without it,
    -- GetVerticalScrollRange returns a stale residual value after
    -- content shrinks. The reclaim widens scrollFrame and content
    -- when no bar is needed so rows can use that ~20px of space.
    local SCROLLBAR_W = 20
    local function updateScrollChrome()
        scrollFrame:UpdateScrollChildRect()
        local sb = scrollFrame.ScrollBar
        local hasScroll = scrollFrame:GetVerticalScrollRange() > 0
        local rightInset = hasScroll and SCROLLBAR_W or 0
        scrollFrame:ClearAllPoints()
        scrollFrame:SetPoint("TOPLEFT", 0, 0)
        scrollFrame:SetPoint("BOTTOMRIGHT", -rightInset, 0)
        content:SetWidth(config.width - rightInset)
        if sb then
            if hasScroll then sb:Show() else sb:Hide() end
        end
    end

    --[[
      Full refresh: rebuild the data pipeline and lay out every visible
      frame.
    ]]
    function instance:refresh()
        releaseAllPools()
        identityToFrame = {}

        local items = buildOrderedList()

        if #items == 0 then
            content:SetHeight(1)
            updateScrollChrome()
            return
        end

        local y = 0

        if not groupSpec then
            for i = 1, #items do
                y = renderItem(items[i], y)
            end
        else
            local groups = bucketByGroup(items)

            -- Singleton-header suppression: ornamental groups (no
            -- body) collapse to a flat list when only one group
            -- exists. Groups with bodies always show their header
            -- because the header IS the interactive expand target.
            local groupSpecKind = kinds[GROUP_KIND]
            local hasBody = groupSpecKind.body ~= nil

            if #groups == 1 and not hasBody then
                for i = 1, #groups[1].items do
                    y = renderItem(groups[1].items[i], y)
                end
            else
                for i = 1, #groups do
                    y = renderGroup(groups[i], y)
                end
            end
        end

        content:SetHeight(math.max(1, y))
        updateScrollChrome()
    end

    -- ====================================================================
    -- INTERNAL: re-render single rows on selection change
    -- ====================================================================

    local function rerenderForIdentity(identity)
        if not identity then return end
        local rowFrame = identityToFrame[identity]
        if not rowFrame then return end
        local kind = rowFrame._lvKind
        local spec = kinds[kind]
        spec.render(rowFrame, rowFrame._lvItem, {
            isSelected = (identity == selectedIdentity),
            identity   = identity,
        })
    end

    -- ====================================================================
    -- PUBLIC API
    -- ====================================================================

    function instance:getSelected()
        return selectedIdentity
    end

    function instance:setSelected(identity)
        if identity == selectedIdentity then return end
        local previous = selectedIdentity
        selectedIdentity = identity
        rerenderForIdentity(previous)
        rerenderForIdentity(identity)
        if onSelectionChanged then
            onSelectionChanged(identity)
        end
    end

    function instance:clearSelection()
        self:setSelected(nil)
    end

    function instance:setSort(fn)
        sortFn = fn
        self:refresh()
    end

    function instance:setFilter(filter)
        filterPred = buildFilterPredicate(filter)
        self:refresh()
    end

    function instance:setGroup(spec)
        if spec ~= nil then
            validateGroupSpec(spec)
            if not kinds[GROUP_KIND] then
                error("listView:setGroup: kinds.group missing; cannot enable grouping")
            end
        end
        groupSpec = spec
        groupHasBody = groupSpec and kinds[GROUP_KIND]
            and kinds[GROUP_KIND].body ~= nil
        self:refresh()
    end

    function instance:getExpandedKeys()
        local copy = {}
        for k, v in pairs(expandedKeys) do
            if v then copy[k] = true end
        end
        return copy
    end

    function instance:setExpandedKeys(set)
        expandedKeys = {}
        if type(set) == "table" then
            for k, v in pairs(set) do
                if v then expandedKeys[k] = true end
            end
        end
        self:refresh()
    end

    function instance:isExpanded(key)
        return expandedKeys[key] == true
    end

    function instance:setExpanded(key, value)
        local desired = value and true or false
        if (expandedKeys[key] == true) == desired then return end

        if desired and groupSpec and groupSpec.accordion then
            -- Accordion: expanding one collapses every other.
            expandedKeys = {}
        end
        expandedKeys[key] = desired or nil
        self:refresh()
    end

    function instance:getScrollFrame()
        return scrollFrame
    end

    function instance:getFrame()
        return frame
    end

    return instance
end

Addon.listView = listView
return listView
