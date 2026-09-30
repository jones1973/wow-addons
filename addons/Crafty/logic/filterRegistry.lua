--[[
  logic/filterRegistry.lua
  Crafty recipe-filter registry

  Filters register themselves here instead of being hard-coded into the window.
  Each filter has an id, a label, a kind (how the UI renders its control), and a
  predicate that decides whether a recipe item passes. The window asks the
  registry for the active composite predicate (an array listView ANDs together)
  and for the list of registered filters to render controls for.

  Adding a filter later (effect/stat search, profit margin, "craftable now") is
  one registerFilter call - no edits to the window's filter bar.

  Filter kinds:
    "toggle" - on/off; predicate applies only while toggled on.
    "search" - a text box; predicate receives the current query string. The
               registry stores the query; an empty query means the filter is
               inactive (passes everything).
    "choice" - a set of mutually exclusive or multi options (e.g. difficulty
               bands); the filter owns its option state.

  A predicate returns true to KEEP an item. Inactive filters are simply not
  included in the composite, so they cost nothing.

  Dependencies: events
  Exports: Addon.filterRegistry
]]

local ADDON_NAME, Addon = ...

local filterRegistry = {}

local events

-- Ordered list of registered filter specs and a lookup by id.
local filters = {}
local byId = {}

-- Registered sort specs: { id, label, order, comparator(dir) -> function(a,b) }.
local sorts = {}
local sortById = {}

--[[
  Register a filter.

  spec = {
    id        = "search",            -- unique key
    label     = "Search",            -- UI label
    kind      = "toggle"|"search"|"choice",
    order     = 10,                  -- sort order in the bar (optional)
    options   = { ... },             -- for "choice": { {value=, label=}, ... }
    -- predicate(item, state) -> boolean. state is the filter's current control
    -- state: bool for toggle, string for search, the chosen value(s) for choice.
    predicate = function(item, state) return true end,
    -- isActive(state) -> bool: whether this filter currently constrains the list.
    -- Defaults: toggle active when true; search active when non-empty; choice
    -- active when a value is set.
    isActive  = nil,
  }
]]
function filterRegistry:register(spec)
    if type(spec) ~= "table" or not spec.id then
        error("filterRegistry:register requires a spec with an id")
    end
    if byId[spec.id] then
        error("filterRegistry: duplicate filter id '" .. spec.id .. "'")
    end
    if type(spec.predicate) ~= "function" then
        error("filterRegistry: filter '" .. spec.id .. "' needs a predicate")
    end

    spec.kind  = spec.kind or "toggle"
    spec.order = spec.order or (#filters + 1) * 10
    spec.state = spec.defaultState
    if spec.state == nil then
        if spec.kind == "toggle" then spec.state = false
        elseif spec.kind == "search" then spec.state = "" end
    end

    byId[spec.id] = spec
    filters[#filters + 1] = spec
    table.sort(filters, function(a, b) return a.order < b.order end)
end

-- Default activeness test per kind, unless the spec overrides it.
local function specActive(spec)
    if spec.isActive then return spec.isActive(spec.state) end
    if spec.kind == "toggle" then return spec.state == true end
    if spec.kind == "search" then return spec.state ~= nil and spec.state ~= "" end
    return spec.state ~= nil
end

-- Set a filter's control state (UI calls this on user input) and notify.
function filterRegistry:setState(id, state)
    local spec = byId[id]
    if not spec then return end
    spec.state = state
    self:persist()
    if events then events:emit("FILTERS:CHANGED", { id = id }) end
end

-- The default state for a spec (explicit defaultState, else kind-based).
local function defaultStateFor(spec)
    if spec.defaultState ~= nil then return spec.defaultState end
    if spec.kind == "toggle" then return false end
    if spec.kind == "search" then return "" end
    return nil
end

-- The state key for the current profession. Filter and sort state live in the
-- per-character crafty_config SV (WoW-scoped to this character - no charKey
-- needed, and other toons never see it), keyed by profID: each profession is its
-- own workspace, and "can skill up" / cooldown filters mean different things in
-- different professions.
local function scopeKey()
    return tostring(Addon.ledger:getViewedProfID())
end

-- The per-character config store's profession table, created on demand.
local function profStore()
    local cfg = crafty_config
    if type(cfg) ~= "table" then return nil end
    cfg.professions = cfg.professions or {}
    return cfg.professions
end

-- Resolve a sort's direction: the remembered per-sort direction if the user has
-- set one, else the sort spec's own default (name asc, difficulty desc).
function filterRegistry:sortDirFor(field)
    if self._sortDirs and self._sortDirs[field] then
        return self._sortDirs[field]
    end
    local spec = sortById[field]
    return (spec and spec.defaultDir) or "asc"
end

-- Persist filter + sort state for the current profession (including search text,
-- per design - the list reopens shaped as it was left). Per-sort directions are
-- remembered individually so each sort keeps its own last-used direction.
function filterRegistry:persist()
    local store = profStore()
    if not store then return end
    local snap = { filters = {}, sortField = self._sortField, sortDirs = self._sortDirs or {} }
    for _, spec in ipairs(filters) do
        snap.filters[spec.id] = spec.state
    end
    store[scopeKey()] = snap
end

-- Restore filter + sort state for the current profession. Called after the
-- viewed profession is established, on open and on profession switch.
function filterRegistry:restore()
    local store = profStore()
    local snap = store and store[scopeKey()] or nil
    -- No saved state for this profession: clear to defaults so one profession's
    -- filters never leak into another's view.
    if type(snap) ~= "table" then
        for _, spec in ipairs(filters) do spec.state = defaultStateFor(spec) end
        self._sortField = nil
        self._sortDirs = {}
        return
    end
    for _, spec in ipairs(filters) do
        local saved = snap.filters and snap.filters[spec.id]
        spec.state = (saved ~= nil) and saved or defaultStateFor(spec)
    end
    self._sortField = snap.sortField
    self._sortDirs = snap.sortDirs or {}
end

-- Remember the active sort field and its direction (per-sort). Persisted.
function filterRegistry:setSort(field, dir)
    self._sortField = field
    self._sortDirs = self._sortDirs or {}
    self._sortDirs[field] = dir
    self:persist()
end

-- The active sort field and its resolved direction.
function filterRegistry:savedSort()
    local field = self._sortField
    if not field then return nil, nil end
    return field, self:sortDirFor(field)
end

function filterRegistry:getState(id)
    local spec = byId[id]
    return spec and spec.state or nil
end

-- The registered filters, in display order (for the UI to render controls).
function filterRegistry:list()
    return filters
end

--[[
  Register a sort option. Sorts are registration-driven like filters, so adding
  a new sort (cost, profit margin, difficulty) is one call, no window edit.

  spec = {
    id         = "name",
    label      = "Name",
    order      = 10,
    -- comparator(dir) returns a function(a, b) for listView's sort, where dir is
    -- "asc" or "desc".
    comparator = function(dir) return function(a, b) ... end end,
  }
]]
function filterRegistry:registerSort(spec)
    if type(spec) ~= "table" or not spec.id then
        error("filterRegistry:registerSort requires a spec with an id")
    end
    if sortById[spec.id] then
        error("filterRegistry: duplicate sort id '" .. spec.id .. "'")
    end
    if type(spec.comparator) ~= "function" then
        error("filterRegistry: sort '" .. spec.id .. "' needs a comparator")
    end
    spec.order = spec.order or (#sorts + 1) * 10
    sortById[spec.id] = spec
    sorts[#sorts + 1] = spec
    table.sort(sorts, function(a, b) return a.order < b.order end)
end

-- Sort options in {value, text} form for the sortControl dropdown.
function filterRegistry:sortOptions()
    local out = {}
    for _, spec in ipairs(sorts) do
        out[#out + 1] = { value = spec.id, text = spec.label }
    end
    return out
end

-- The comparator function for a sort id + direction, for listView:setSort.
function filterRegistry:sortComparator(field, dir)
    local spec = sortById[field]
    if not spec then return nil end
    return spec.comparator(dir)
end

-- The composite predicate array for listView: one closure per ACTIVE filter,
-- each binding its current state. listView ANDs them. Inactive filters are
-- omitted entirely.
function filterRegistry:activePredicates()
    local out = {}
    for _, spec in ipairs(filters) do
        if specActive(spec) then
            local s = spec.state
            local p = spec.predicate
            out[#out + 1] = function(item) return p(item, s) end
        end
    end
    return out
end

-- A single composite filter that exempts pinned items: a pinned recipe always
-- passes regardless of active filters (pins are never hidden by filtering).
-- Returned as a one-element array for listView. When no filters are active this
-- still returns a predicate, but it passes everything, so it is harmless.
function filterRegistry:activeFilter()
    local preds = self:activePredicates()
    if #preds == 0 then return nil end
    -- A single predicate: pinned items bypass active filters (derived live, not
    -- read from a stored item field); otherwise all active predicates must pass.
    return function(item)
        if Addon.ledger:isPinned(item.id) then return true end
        for _, p in ipairs(preds) do
            if not p(item) then return false end
        end
        return true
    end
end

-- Clear all filters back to inactive defaults.
function filterRegistry:clearAll()
    for _, spec in ipairs(filters) do
        if spec.kind == "toggle" then spec.state = false
        elseif spec.kind == "search" then spec.state = ""
        else spec.state = spec.defaultState end
    end
    if events then events:emit("FILTERS:CHANGED", { id = nil }) end
end

function filterRegistry:initialize()
    events = Addon.events
    return true
end

Addon.filterRegistry = filterRegistry

if Addon.registerModule then
    Addon.registerModule("filterRegistry", { "events", "ledger" }, function()
        return filterRegistry:initialize()
    end)
end

return filterRegistry
