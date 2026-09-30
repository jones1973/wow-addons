--[[ DEPENDENCY HEADER (mirror of registerModule; loader is source of truth)
  Layer:     component  (shared/ui/components/optionsPanel/)
  UI deps:   none at normalize stage (renderer consumes labeledToggle, slider,
             dropdown, infoTip; the normalizer itself touches no widgets)
  Core deps: options (binding target), utils (optional, for error/debug)
]]
--[[
  ui/shared/components/optionsPanel/normalize.lua

  Schema normalizer for the shared options panel.

  Turns the terse, human-authored descriptor tree into a fully-resolved tree
  the renderer can walk WITHOUT making interpretation decisions. Pure logic:
  schema in, resolved schema out. Touches no frames, instantiates no widgets,
  so it is unit-testable in isolation before the renderer exists.

  What it does (see design doc section 8a):
    1. Fill defaults  - every unstated field gets its default (applies="live",
                        the store default value, etc.) so the renderer never
                        writes `descriptor.x or fallback`.
    2. Resolve binding - turn `key` into get/set closures against the options
                        store, OR use author-supplied get/set overrides. After
                        this, every leaf has a uniform { get, set } and the
                        renderer never learns whether it came from a key or an
                        override.
    3. Validate       - catch authoring mistakes here, once, with a clear
                        message, rather than as a confusing frame error mid-render.
    4. Index          - build lowercased search text per leaf so search is a
                        cheap lookup later, not a re-walk per keystroke.

  Input descriptor (what the author writes; most fields optional):
    {
      kind  = "checkbox"|"slider"|"dropdown"|"text"|"group"|"action"|"custom",
      key   = "storeKey",            -- omitted for group/action/custom-without-binding
      label = "Label",
      tooltip = "hover string",      -- cheap built-in widget hover
      info  = { title=, brief=, description=, sections= },  -- rich infoTip
      get   = function() ... end,    -- override; else derived from key
      set   = function(v) ... end,   -- override; else derived from key
      visible  = function() ... end, -- predicate; default always-visible
      disabled = function() ... end, -- predicate; default never-disabled
      applies  = "live"|"reload",    -- default "live"
      confirm  = { title=, body=, destructive= },  -- action kind
      -- kind-specific: min/max/step/decimals (slider), choices (dropdown),
      --                children (group), run (action), build (custom)
    }

  Output: a resolved tree where every leaf is fully specified - guaranteed
  get/set, guaranteed applies, guaranteed visible/disabled predicates,
  a _resolved marker, a _setter descriptor (which widget method + suppress flag
  the refresh phase uses), and an _index string.

  This module does NOT register with the dependency system on its own; it is
  required by the optionsPanel module's entry point, which registers.

  Dependencies: options (passed in, not hard-required), utils (optional)
  Exports: Addon.optionsPanelNormalize
]]

local ADDON_NAME, Addon = ...

local N = {}

-- ============================================================================
-- KIND TABLE
-- ============================================================================
-- Each kind declares: whether it binds to a value, whether it groups children,
-- and (for value kinds) which widget method the refresh phase calls to push a
-- value in without firing the user callback. The setter names differ per
-- widget (historical), but the contract is uniform: method(value, suppressFlag).

local KINDS = {
    checkbox = {
        binds    = true,
        setter   = "setChecked",   -- labeledToggle/toggle
        suppress = "silent",       -- 2nd arg name, documentation only
    },
    slider = {
        binds    = true,
        setter   = "SetValue",     -- slider
        suppress = "suppressCallback",
    },
    dropdown = {
        binds    = true,
        setter   = "SetValue",     -- dropdown
        suppress = "silent",
    },
    dropdownLegacy = {
        binds    = true,
        setter   = "SetValue",     -- dropdownLegacy
        suppress = "silent",
    },
    text = {
        binds    = true,
        setter   = "SetBoxText",   -- textBox; no native suppress, renderer guards
        suppress = nil,
    },
    search = {
        binds    = true,
        setter   = "SetValue",     -- searchBox contract surface
        suppress = nil,
    },
    segmented = {
        binds    = true,
        setter   = "SetValue",     -- segmentedControl (filterTabStrip)
        suppress = nil,
    },
    radio = {
        binds    = true,
        setter   = "SetValue",     -- radioControl (toggle group)
        suppress = nil,
    },
    group  = { binds = false, groups = true },
    action = { binds = false, isAction = true },
    custom = { binds = false, isCustom = true },
}

N.KINDS = KINDS

-- ============================================================================
-- ERROR HELPERS
-- ============================================================================
-- Validation failures are authoring bugs: fail loudly and specifically. We
-- accumulate all problems and raise once with the full list, so an author
-- fixing a schema sees every mistake at once rather than one-per-run.

local function pathString(path)
    if #path == 0 then return "<root>" end
    return table.concat(path, " > ")
end

local function addError(errors, path, msg)
    errors[#errors + 1] = string.format("  [%s] %s", pathString(path), msg)
end

-- ============================================================================
-- BINDING RESOLUTION
-- ============================================================================
-- The common case: a descriptor has `key`, so get/set are derived against the
-- options store. The override case: the descriptor supplies its own get/set
-- (e.g. binding to tab enabled-state instead of a stored key), used verbatim.
-- After this runs, every value-leaf has BOTH get and set as callables, and the
-- renderer never has to know which path produced them.

-- ctx is the caller-supplied binding context: { sv = <SavedVariable table>,
-- defaults = <table of key->default> }. The module owns get/set mechanics; the
-- CALLER owns what the SV table and the defaults are. We never go through a
-- separate store object - this module IS the options store.
local function resolveBinding(desc, ctx, path, errors)
    local hasKey      = desc.key ~= nil
    local hasOverride = type(desc.get) == "function" or type(desc.set) == "function"

    if hasOverride then
        -- Override path: both halves must be present if either is. A get
        -- without a set (or vice versa) is almost always an authoring slip.
        if type(desc.get) ~= "function" then
            addError(errors, path, "has set override but no get override")
        end
        if type(desc.set) ~= "function" then
            addError(errors, path, "has get override but no set override")
        end
        -- Overrides win; a stray key alongside them is ignored but flagged so
        -- the author knows the key is dead.
        if hasKey then
            addError(errors, path,
                "has both key='" .. tostring(desc.key) ..
                "' and get/set overrides; key is ignored, remove it")
        end
        return desc.get, desc.set
    end

    if not hasKey then
        addError(errors, path,
            "value descriptor (kind='" .. tostring(desc.kind) ..
            "') needs either a key or get/set overrides")
        return nil, nil
    end

    -- Key path: derive closures that read/write the caller's SavedVariable
    -- table directly. Get returns the SV value if present, else the caller-
    -- supplied default. Set writes straight into the SV table (which is what
    -- the WoW client serializes on logout/reload - that is the persistence).
    -- ctx may be nil at normalize-test time; closures tolerate that so the
    -- normalizer stays testable without a live SV.
    local key = desc.key
    local get = function()
        local sv = ctx and ctx.sv
        if sv ~= nil and sv[key] ~= nil then
            return sv[key]
        end
        local defaults = ctx and ctx.defaults
        return defaults and defaults[key]
    end
    local set = function(value)
        local sv = ctx and ctx.sv
        if sv then sv[key] = value end
    end
    return get, set
end

-- ============================================================================
-- SEARCH INDEX
-- ============================================================================
-- One lowercased string per leaf: label + info text + key. Built once so the
-- search filter is a substring test, not a tree re-walk per keystroke.

local function buildIndex(desc)
    local parts = {}
    if desc.label then parts[#parts + 1] = desc.label end
    if desc.key   then parts[#parts + 1] = tostring(desc.key) end
    if type(desc.info) == "table" then
        if desc.info.title       then parts[#parts + 1] = desc.info.title end
        if desc.info.brief       then parts[#parts + 1] = desc.info.brief end
        if desc.info.description then parts[#parts + 1] = desc.info.description end
    end
    return string.lower(table.concat(parts, " "))
end

-- ============================================================================
-- PREDICATE NORMALIZATION
-- ============================================================================
-- visible/disabled may be a function, a literal boolean, or absent. Normalize
-- all three to a function so the renderer always calls a predicate. Absent
-- visible -> always shown; absent disabled -> never disabled.

local function normalizePredicate(value, default)
    if type(value) == "function" then return value end
    if type(value) == "boolean" then return function() return value end end
    return function() return default end
end

-- ============================================================================
-- LEAF / NODE NORMALIZATION
-- ============================================================================

local VALID_APPLIES = { live = true, reload = true }

local function normalizeNode(desc, ctx, path, errors, seenDefault)
    if type(desc) ~= "table" then
        addError(errors, path, "descriptor is not a table")
        return nil
    end

    local kindSpec = KINDS[desc.kind]
    if not kindSpec then
        addError(errors, path,
            "unknown kind '" .. tostring(desc.kind) .. "' (valid: " ..
            "checkbox, slider, dropdown, dropdownLegacy, text, search, group, action, custom)")
        -- Continue with a stub so sibling errors still surface.
        return { kind = desc.kind, label = desc.label, _resolved = true, _invalid = true }
    end

    -- Shallow copy so the author's table is never mutated.
    local out = {}
    for k, v in pairs(desc) do out[k] = v end
    out._resolved = true

    -- applies: default live, validate value
    if out.applies == nil then
        out.applies = "live"
    elseif not VALID_APPLIES[out.applies] then
        addError(errors, path,
            "applies must be 'live' or 'reload', got '" .. tostring(out.applies) .. "'")
        out.applies = "live"
    end

    -- predicates always become callables
    out.visible  = normalizePredicate(desc.visible, true)
    out.disabled = normalizePredicate(desc.disabled, false)

    -- search index
    out._index = buildIndex(out)

    if kindSpec.groups then
        -- group: recurse children; a group does not bind. A group with no
        -- children is almost certainly a mistake.
        local kids = desc.children
        if type(kids) ~= "table" or #kids == 0 then
            addError(errors, path, "group has no children")
            out.children = {}
        else
            out.children = {}
            for i, child in ipairs(kids) do
                local childPath = {}
                for _, p in ipairs(path) do childPath[#childPath + 1] = p end
                childPath[#childPath + 1] = child.label or child.key or ("#" .. i)
                out.children[i] = normalizeNode(child, ctx, childPath, errors, seenDefault)
            end
        end
        return out

    elseif kindSpec.isAction then
        -- action: needs a run() and, if destructive, a confirm table.
        if type(desc.run) ~= "function" then
            addError(errors, path, "action needs a run function")
        end
        if desc.confirm ~= nil and type(desc.confirm) ~= "table" then
            addError(errors, path, "confirm must be a table { title, body, destructive }")
        end
        return out

    elseif kindSpec.isCustom then
        -- custom: needs a build(parent, ctx). Binding is optional - a custom
        -- widget may bind via get/set or be purely presentational.
        if type(desc.build) ~= "function" then
            addError(errors, path, "custom needs a build(parent, ctx) function")
        end
        if type(desc.get) == "function" or type(desc.set) == "function" then
            out.get, out.set = resolveBinding(desc, ctx, path, errors)
        end
        return out

    elseif kindSpec.binds then
        -- value leaf: resolve binding, record setter contract, validate
        -- kind-specifics, guard duplicate keys.
        out.get, out.set = resolveBinding(desc, ctx, path, errors)
        out._setter   = kindSpec.setter
        out._suppress = kindSpec.suppress

        if out.key ~= nil then
            if seenDefault[out.key] then
                addError(errors, path, "duplicate key '" .. tostring(out.key) ..
                    "' (also at [" .. seenDefault[out.key] .. "])")
            else
                seenDefault[out.key] = pathString(path)
            end
        end

        if desc.kind == "slider" then
            if type(desc.min) ~= "number" or type(desc.max) ~= "number"
               or type(desc.step) ~= "number" then
                addError(errors, path, "slider needs numeric min, max, step")
            elseif desc.min >= desc.max then
                addError(errors, path, "slider min must be < max")
            end
        elseif desc.kind == "dropdown" or desc.kind == "dropdownLegacy"
               or desc.kind == "segmented" or desc.kind == "radio" then
            if type(desc.choices) ~= "table" or #desc.choices == 0 then
                addError(errors, path, "dropdown needs a non-empty choices list")
            end
        end

        if not out.label then
            addError(errors, path, "value descriptor needs a label")
        end

        return out
    end

    addError(errors, path, "kind '" .. tostring(desc.kind) .. "' fell through normalization")
    return out
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Normalize a schema.

  @param schema  table  - array of top-level descriptors (the author's tree)
  @param options table  - the options store (for key-based binding). May be
                          nil at test time; key closures resolve Addon.options
                          lazily so normalization still succeeds.
  @return table         - { ok = bool, tree = <resolved array>, errors = {strings} }
                          On failure ok=false and tree is the best-effort partial
                          (every node that could be resolved is), so a caller can
                          choose to surface errors and still inspect structure.
]]
function N.normalize(schema, ctx)
    local errors = {}
    local tree = {}

    if type(schema) ~= "table" then
        return { ok = false, tree = {}, errors = { "  [<root>] schema must be a table (array of descriptors)" } }
    end

    -- seenDefault doubles as the duplicate-key guard across the whole tree.
    local seenKeys = {}

    for i, desc in ipairs(schema) do
        local path = { desc.label or desc.key or ("#" .. i) }
        tree[i] = normalizeNode(desc, ctx, path, errors, seenKeys)
    end

    return {
        ok     = (#errors == 0),
        tree   = tree,
        errors = errors,
    }
end

--[[
  Convenience: normalize and raise on failure. For call sites that want
  fail-fast rather than inspecting the result table.
]]
function N.normalizeOrError(schema, ctx)
    local result = N.normalize(schema, ctx)
    if not result.ok then
        error("optionsPanel schema invalid:\n" .. table.concat(result.errors, "\n"), 2)
    end
    return result.tree
end

Addon.optionsPanelNormalize = N
return N
