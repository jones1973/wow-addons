--[[
  ui/shared/widgets/reactiveList.lua   [SHARED: pending sync to monorepo shared/]
  reactiveList - a surgical, model-backed scrolling list.

  Successor to listView. The difference is architectural, not cosmetic:

    listView is PULL + REBUILD. The caller mutates its own data and calls
    refresh(); the widget re-pulls everything and re-renders every row.

    reactiveList is MODEL + SURGICAL OPS. The widget OWNS the item model (keyed
    by identity). Per-row changes are named directly and touch ONE row:
      upsert(item)      - add or update one row. A new row appends at the bottom
                          (a list always has an end); it sorts into place on the
                          next full render. Updating an existing row re-renders
                          it in place.
      removeRow(id)     - drop one row, re-flow the rows below it up
    A full sort/filter/group pass over the whole model happens on the trigger
    cases where wholesale change is the real event: construction, setFilter,
    setSort, setGroup, replaceAll (the whole dataset is replaced), refreshAll (a
    derived value changed across many rows), and expand/collapse.

    The split is deliberate: adding one item and replacing the whole dataset are
    genuinely different events, so they are different operations. A per-row
    change updates that row immediately, not on a later refresh tick, so a held
    row cannot show stale state waiting for a rebuild.

  --------------------------------------------------------------------------
  THE PIPELINE (pure): model -> filter -> sort -> group -> visible stream

  The visible stream is derived from the model through three pure transforms.
  Setting any of them (setFilter/setSort/setGroup) recomputes the projection and
  does a full render.

  The filter is SOLELY the consumer's predicate; the widget adds no bypass of
  its own. Behaviour like "pinned items always show" or "a just-added item shows
  even though it does not match the active filter" is expressed by the consumer
  inside its own predicate (deriving the fact live from the id, or from a small
  set the consumer keeps and ages out). The widget knows nothing of pinned,
  recent, or sticky - it just runs the predicate. This is why those behaviours
  need no widget mechanism: they are ordinary filter/sort logic the consumer
  already owns.

  --------------------------------------------------------------------------
  Construction (declarative):

    local rl = Addon.reactiveList:create({
        parent     = someFrame,
        width      = 300,
        height     = 400,
        scrollFrameName = "MyListScroll",       -- optional; debug aid

        filter = function(item) return item.visible end,  -- optional
        sort   = function(a, b) return a.id < b.id end,    -- optional
        group  = { key = fn, sort = fn, accordion = false },-- optional

        kinds = {                                -- per-kind {height, factory, render}
            row    = { height = 36, factory = fn, render = fn, chrome = {...} },
            -- A group header is just a kind. Same shape as any row; its render
            -- receives (frame, key, items, expanded). Clicking it toggles the
            -- group (the widget wires that), so the consumer supplies only the
            -- appearance.
            header = { height = 22, factory = fn, render = fn },
        },

        onClick = fn, onDoubleClick = fn, onContextMenu = fn,
        onSelectionChanged = fn,
    })

  Every item MUST carry a stable `id` field; that is its identity (the spine).
  There is no identityFn - identity is a stored key, not a computed value.

  Model mutations (the caller names the real-world change):
    rl:upsert(item)         -- add or update one row
    rl:removeRow(identity)  -- drop one row, re-flow below
    rl:replaceAll(items)    -- replace the whole dataset
    rl:refreshAll()         -- full re-evaluation of every row
    rl:get(identity)        -- read one item from the model
    rl:items()              -- shallow copy of the model's items (unordered)

  Pipeline:
    rl:setFilter(fn)   -- full render
    rl:setSort(fn)     -- full render
    rl:setGroup(spec)  -- full render

  Selection / expand / escape hatches:
    rl:getSelected(); rl:setSelected(id); rl:clearSelection()
    rl:getExpandedKeys(); rl:setExpandedKeys(set)
    rl:isExpanded(key); rl:setExpanded(key, bool)
    rl:getScrollFrame(); rl:getFrame()

  The render context passed to a kind's render(frame, item, ctx):
    ctx = { isSelected = bool, identity = id }

  Dependencies: rowStack, pool, theme (chrome tokens via rowStack)
  Exports: Addon.reactiveList
]]

local _, Addon = ...

local reactiveList = {}

-- A group header is just a row whose kind is "header" - no special vocabulary.
-- Its identity is derived from the group key so it is stable across renders.
local HEADER_KIND = "header"

local function headerIdentity(key) return "header:" .. tostring(key) end

function reactiveList:create(config)
    assert(type(config) == "table", "reactiveList:create requires a config table")
    assert(type(config.kinds) == "table", "reactiveList:create requires kinds")

    -- Identity is item.id - a stable stored key on every item, not a computed
    -- function. Header rows carry .id too (headerIdentity(key)), so identity is
    -- one uniform field read everywhere.
    local kinds = config.kinds

    -- ====================================================================
    -- MODEL: identity -> item. The single source of truth. The screen is a
    -- projection of this; it is never a parallel copy.
    -- ====================================================================
    local model      = {}   -- identity -> item
    local modelOrder = {}   -- insertion order of identities (stable tiebreak)

    -- Pipeline state.
    local filterPred = config.filter
    local sortFn     = config.sort
    local groupSpec  = config.group
    local expandedKeys = {}

    -- ====================================================================
    -- The underlying rowStack renders pooled rows by kind and tracks them by
    -- identity. Every stream row carries its own `kind` and `id`, so rowStack
    -- handles item rows and header rows uniformly - there is no translation
    -- layer, no synthetic-identity wrapper, and no kind-based click routing.
    -- A header is simply a row whose kind is "header"; the consumer supplies a
    -- `kinds.header` spec in the same {height, factory, render} shape as any
    -- other kind, and its render receives the header row (key + items + expanded).
    -- ====================================================================

    -- Expand state: one core sets a group's expanded flag; toggle and the
    -- public setExpanded both go through it. Defined here so the header kind's
    -- click can reach it.
    local fullRender  -- forward decl (defined below)
    local function setExpandedTo(key, desired)
        desired = desired and true or false
        if (expandedKeys[key] == true) == desired then return end
        if desired and groupSpec and groupSpec.accordion then
            expandedKeys = {}
        end
        expandedKeys[key] = desired or nil
        fullRender()
    end
    local function toggleGroup(key)
        setExpandedTo(key, expandedKeys[key] ~= true)
    end

    -- The header kind: rendered from the consumer's header spec, clicking it
    -- toggles its group. Clicks belong to the kind, not to a central router.
    local headerSpec = kinds[HEADER_KIND]
    local stackKinds = {}
    for kind, spec in pairs(kinds) do
        stackKinds[kind] = spec
    end
    if headerSpec then
        stackKinds[HEADER_KIND] = {
            height  = headerSpec.height,
            factory = headerSpec.factory,
            render  = function(frameRef, row)
                headerSpec.render(frameRef, row.key, row.items, row.expanded)
            end,
            chrome  = headerSpec.chrome or { hover = false, selection = false },
            onClick = function(row) toggleGroup(row.key) end,
        }
    end

    local stack = Addon.rowStack:create({
        scroll       = {
            parent          = config.parent,
            width           = config.width,
            height          = config.height,
            scrollFrameName = config.scrollFrameName,
        },
        kinds        = stackKinds,
        onClick      = config.onClick,
        onDoubleClick = config.onDoubleClick,
        onContextMenu = config.onContextMenu,
        onSelectionChanged = config.onSelectionChanged,
    })

    local box = stack:getScrollBox()

    local instance = {}

    -- ====================================================================
    -- PIPELINE (pure): model -> filter -> sort -> group -> stream. The filter is
    -- solely the consumer's predicate; the widget adds no bypass of its own.
    -- ====================================================================
    local function passesFilter(item)
        if not filterPred then return true end
        return filterPred(item)
    end

    -- MEMBERSHIP. isMember is purely the filter's output: which model rows pass
    -- the active predicate. Recomputed only when membership can change (filter
    -- change or model mutation). Order comes from modelOrder; no second list.
    -- Sort and group are arrangement over this set and never re-run the filter.
    local isMember = {}        -- identity -> true if it passes the filter

    local function recomputeMembers()
        isMember = {}
        for i = 1, #modelOrder do
            local id = modelOrder[i]
            local item = model[id]
            if item and passesFilter(item) then isMember[id] = true end
        end
    end

    local function buildOrderedList()
        local kept = {}
        for i = 1, #modelOrder do
            local id = modelOrder[i]
            if isMember[id] then kept[#kept + 1] = model[id] end
        end
        if sortFn then
            table.sort(kept, sortFn)
        end
        return kept
    end

    local function bucketByGroup(orderedList)
        local keyFn   = groupSpec.key
        local buckets = {}
        local order   = {}
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

    -- Build the normal projection's stream (filtered/sorted/grouped). Transient
    -- rows are NOT here - they are composed in by assembleStream.
    local function buildNormalStream()
        local items  = buildOrderedList()
        local stream = {}

        if not groupSpec or #items == 0 then
            for i = 1, #items do stream[#stream + 1] = items[i] end
            return stream
        end

        local groups = bucketByGroup(items)

        -- Singleton suppression: a single group needs no header - emit its items
        -- flat.
        if #groups == 1 then
            local g = groups[1]
            for i = 1, #g.items do stream[#stream + 1] = g.items[i] end
            return stream
        end

        for i = 1, #groups do
            local g = groups[i]
            stream[#stream + 1] = {
                id       = headerIdentity(g.key),
                kind     = HEADER_KIND,
                key      = g.key,
                items    = g.items,
                expanded = expandedKeys[g.key] == true,
            }
            for j = 1, #g.items do stream[#stream + 1] = g.items[j] end
        end
        return stream
    end

    -- Assemble the flat stream: the filtered/sorted/grouped projection.
    local function assembleStream()
        return buildNormalStream()
    end

    -- ====================================================================
    -- RENDER: a full sort/filter/group pass over the model, projecting it to the
    -- screen. The single internal full-render.
    -- ====================================================================
    function fullRender()
        stack:render(assembleStream())
    end

    -- ====================================================================
    -- MODEL MUTATIONS - the caller names the real-world change.
    -- ====================================================================

    -- Add or update one row (update if its identity is already in the model,
    -- insert otherwise). A new row appends at the BOTTOM (a list always has an
    -- end); it sorts into place on the next full render. Whether a row shows is
    -- decided solely by the consumer's filter predicate - there is no widget-side
    -- bypass. A consumer that wants an item visible past the active filter
    -- (e.g. just-added) expresses that in its own predicate.
    function instance:upsert(item)
        local id = item.id

        if model[id] ~= nil then
            model[id] = item
            if stack:isRendered(id) then
                stack:updateRow(item)        -- already shown: re-render in place
            elseif passesFilter(item) then
                isMember[id] = true
                stack:appendRow(item)        -- was hidden, now passes: show it
            end
            return
        end

        model[id] = item
        modelOrder[#modelOrder + 1] = id
        if passesFilter(item) then
            isMember[id] = true
            stack:appendRow(item)            -- passes filter: show it
        end
    end

    -- Remove one row.
    function instance:removeRow(identity)
        if model[identity] == nil then return end
        model[identity] = nil
        for i = 1, #modelOrder do
            if modelOrder[i] == identity then
                table.remove(modelOrder, i)
                break
            end
        end
        isMember[identity] = nil
        stack:removeRow(identity)
    end

    -- Wholesale replacement: a new dataset entirely.
    function instance:replaceAll(items)
        model      = {}
        modelOrder = {}
        for i = 1, #items do
            local id = items[i].id
            if model[id] == nil then modelOrder[#modelOrder + 1] = id end
            model[id] = items[i]
        end
        recomputeMembers()
        fullRender()
    end

    -- Full re-evaluation of every row against the current model (e.g. a derived
    -- value changed across many rows, so colors/filter membership are recomputed).
    function instance:refreshAll()
        fullRender()
    end

    -- Redraw the content of currently-visible rows WITHOUT re-projecting (no
    -- filter/sort/group pass). Use when a derived value changed the way rows DRAW
    -- (e.g. skill-up recolors difficulty bands) but the set of rows is unchanged.
    function instance:redrawVisible()
        local byId = {}
        local stream = assembleStream()
        for i = 1, #stream do byId[stream[i].id] = stream[i] end
        stack:redrawVisible(function(id) return byId[id] end)
    end

    function instance:get(identity) return model[identity] end

    function instance:items()
        local out = {}
        for i = 1, #modelOrder do out[#out + 1] = model[modelOrder[i]] end
        return out
    end

    -- The first row in DISPLAYED order (after filter/sort/group), skipping any
    -- group header. Returns the item, or nil if nothing is visible. This is the
    -- "top of the list as the user sees it" - distinct from items()[1], which is
    -- raw model order.
    function instance:firstVisible()
        local stream = assembleStream()
        for i = 1, #stream do
            if stream[i].kind ~= HEADER_KIND then return stream[i] end
        end
        return nil
    end

    -- ====================================================================
    -- PIPELINE setters - set state, re-project.
    -- ====================================================================
    function instance:setFilter(fn)
        filterPred = fn
        recomputeMembers()   -- filter changed -> membership changes
        fullRender()
    end

    function instance:setSort(fn)
        sortFn = fn
        fullRender()         -- arrangement only; membership unchanged
    end

    function instance:setGroup(spec)
        groupSpec = spec
        fullRender()         -- arrangement only; membership unchanged
    end

    -- First paint.
    recomputeMembers()
    fullRender()

    -- ====================================================================
    -- SELECTION / EXPAND / ESCAPE HATCHES - delegate to rowStack / local state.
    -- ====================================================================
    function instance:getSelected()    return stack:getSelected() end
    function instance:setSelected(id)  stack:setSelected(id) end

    -- The rendered frame for an identity (e.g. to decorate it), or nil.
    function instance:frameFor(identity) return stack:frameFor(identity) end
    function instance:clearSelection() stack:clearSelection() end

    function instance:getExpandedKeys()
        local out = {}
        for k, v in pairs(expandedKeys) do if v then out[k] = true end end
        return out
    end

    function instance:setExpandedKeys(set)
        expandedKeys = {}
        if type(set) == "table" then
            for k, v in pairs(set) do if v then expandedKeys[k] = true end end
        end
        fullRender()
    end

    function instance:isExpanded(key) return expandedKeys[key] == true end

    function instance:setExpanded(key, value)
        setExpandedTo(key, value)
    end

    function instance:getScrollFrame() return box:getScrollFrame() end
    function instance:getFrame()       return box:getFrame() end

    return instance
end

if Addon.registerModule then
    Addon.registerModule("reactiveList", {"rowStack"})
end

Addon.reactiveList = reactiveList
return reactiveList
