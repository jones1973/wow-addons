--[[
  logic/activityModel.lua
  Activity Model

  The single source the activity rail renders from. An activity is a
  destination in Crafty's navigation: a profession (windowed - a recipe list),
  a processing verb (milling / prospecting / disenchanting - a bag-slot cast),
  or a gathering skill (windowless - an informational page). The model turns
  live game state plus the static processing map into an ordered, grouped list,
  then applies the character's own hidden/reorder choices on top.

  Groups, in canonical order:
    professions   primary windowed crafting professions (Enchanting, Mining's
                  Smelting side, ...)
    processing    the milling/prospecting/disenchanting verbs a primary grants
    secondary     Cooking, First Aid
    gathering     windowless primaries (Herbalism, Skinning, ...) - the skill
                  is real even though nothing opens

  Identity: every activity carries a stable string id. Profession and gathering
  activities key on the skill-line id ("prof:333"); processing activities carry
  the id from the static map ("proc:milling"). The id is what persisted
  hidden/order state is keyed by, so it must not change between sessions.

  Ordering and visibility are the character's to set (Customize Activities).
  This module reads and writes that state in the per-character crafty_config SV
  under `activities`; the editor UI (a later phase) mutates the same store
  through setHidden / setOrder / resetGroup. Absent state means "defaults":
  canonical order, nothing hidden.

  This is logic only: it computes the activity list and owns its persistence.
  It creates no frames and reads no theme. The rail consumes enumerate().

  Dependencies: professionHarvester, ledger
  Exports: Addon.activityModel
]]

local ADDON_NAME, Addon = ...

local activityModel = {}

local professionHarvester, ledger

-- Group identity and the canonical order groups themselves appear in. A
-- character's reorder of the groups (Customize Activities) overlays this.
local GROUP = {
    PROFESSIONS = "professions",
    PROCESSING  = "processing",
    SECONDARY   = "secondary",
    GATHERING   = "gathering",
}
local GROUP_ORDER = {
    GROUP.PROFESSIONS,
    GROUP.PROCESSING,
    GROUP.SECONDARY,
    GROUP.GATHERING,
}

activityModel.GROUP = GROUP

-- ============================================================================
-- PERSISTENCE (per-character crafty_config.activities)
-- ============================================================================

-- The activities store, created on demand. WoW scopes crafty_config to this
-- character, so no charKey is needed and other toons never see these choices -
-- the same access filterRegistry uses for per-profession filter state.
--
--   activities = {
--     hidden = { [activityId] = true, ... },   -- activities the user hid
--     order  = { [activityId] = n, ... },       -- within-group sort override
--     groups = { [groupKey]   = n, ... },       -- group sort override
--   }
local function store()
    local cfg = crafty_config
    if type(cfg) ~= "table" then return nil end
    cfg.activities = cfg.activities or {}
    local a = cfg.activities
    a.hidden = a.hidden or {}
    a.order  = a.order or {}
    a.groups = a.groups or {}
    return a
end

-- ============================================================================
-- INTERNAL: derive the raw activity list from live state
-- ============================================================================

-- The processing activity a windowed primary grants, or nil. The granting
-- fact is static (data/processingActivities): having Inscription grants
-- Milling, and nothing the client reports says so.
local function processingFor(profID)
    local map = Addon.data.processingActivities
    return map and map[profID]
end

--[[
  Build every activity the character has, ungrouped-but-tagged and in canonical
  within-group order, before hidden/reorder overlays. Read live every call so a
  learned or unlearned profession is reflected at once.

  A profession record from the harvester already carries windowed and category;
  that plus the processing map is the whole derivation:
    - windowed primary  -> a professions-group activity, and (if it grants one)
                           a processing-group activity
    - windowless primary-> a gathering-group activity
    - secondary         -> a secondary-group activity

  @return array of activity records:
    { id, kind, group, profID?, verb?, name, rank?, maxRank?, order }
]]
local function deriveRaw()
    local out = {}

    for _, prof in ipairs(professionHarvester:enumerate()) do
        if prof.category == "secondary" then
            out[#out + 1] = {
                id      = "prof:" .. prof.profID,
                kind    = "profession",
                group   = GROUP.SECONDARY,
                profID  = prof.profID,
                name    = prof.name,
                rank    = prof.rank,
                maxRank = prof.maxRank,
                order   = #out + 1,
            }
        elseif prof.windowed then
            out[#out + 1] = {
                id      = "prof:" .. prof.profID,
                kind    = "profession",
                group   = GROUP.PROFESSIONS,
                profID  = prof.profID,
                name    = prof.name,
                rank    = prof.rank,
                maxRank = prof.maxRank,
                order   = #out + 1,
            }
            local proc = processingFor(prof.profID)
            if proc then
                out[#out + 1] = {
                    id     = proc.id,
                    kind   = "processing",
                    group  = GROUP.PROCESSING,
                    profID = prof.profID,  -- the granting profession
                    verb   = proc.verb,
                    name   = proc.verb,    -- display name resolved by the rail
                    order  = proc.order,
                }
            end
        else
            out[#out + 1] = {
                id      = "prof:" .. prof.profID,
                kind    = "gathering",
                group   = GROUP.GATHERING,
                profID  = prof.profID,
                name    = prof.name,
                rank    = prof.rank,
                maxRank = prof.maxRank,
                order   = #out + 1,
            }
        end
    end

    return out
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  The character's activities, grouped and ordered, with the character's own
  hidden/reorder choices applied.

  Groups appear in the character's chosen order (or canonical), and within each
  group activities appear in the character's chosen order (or canonical, which
  for professions/gathering is enumerate() order and for processing is the map
  order). Hidden activities are excluded when includeHidden is false (the rail);
  the editor passes true to show them for un-hiding.

  @param includeHidden boolean - keep hidden activities in the result
  @return array of groups: { key = <groupKey>, activities = { <activity>, ... } }
]]
function activityModel:enumerate(includeHidden)
    local st = store()
    local hidden = (st and st.hidden) or {}
    local orderOverride = (st and st.order) or {}
    local groupOverride = (st and st.groups) or {}

    -- Bucket the raw activities by group.
    local buckets = {}
    for _, key in ipairs(GROUP_ORDER) do buckets[key] = {} end
    for _, act in ipairs(deriveRaw()) do
        if includeHidden or not hidden[act.id] then
            act.hidden = hidden[act.id] or false
            buckets[act.group][#buckets[act.group] + 1] = act
        end
    end

    -- Within-group order: the character's override wins, else the activity's
    -- canonical order field. A stable comparator - equal keys keep insertion
    -- order via the index tiebreak.
    for _, key in ipairs(GROUP_ORDER) do
        local list = buckets[key]
        local index = {}
        for i, act in ipairs(list) do index[act] = i end
        table.sort(list, function(a, b)
            local ao = orderOverride[a.id] or a.order
            local bo = orderOverride[b.id] or b.order
            if ao ~= bo then return ao < bo end
            return index[a] < index[b]
        end)
    end

    -- Group order: the character's override wins, else canonical position.
    local groups = {}
    for i, key in ipairs(GROUP_ORDER) do
        groups[#groups + 1] = {
            key        = key,
            activities = buckets[key],
            order      = groupOverride[key] or i,
            index      = i,
        }
    end
    table.sort(groups, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        return a.index < b.index
    end)

    -- Empty groups carry no heading and nothing to render - drop them from the
    -- result. The editor, wanting to show every group a character could
    -- populate, is a later concern; the rail only ever wants populated groups.
    local out = {}
    for _, g in ipairs(groups) do
        if #g.activities > 0 then
            out[#out + 1] = { key = g.key, activities = g.activities }
        end
    end
    return out
end

--[[
  Hide or show an activity by id. Persisted immediately.

  @param activityId string
  @param hidden boolean
]]
function activityModel:setHidden(activityId, hidden)
    local st = store()
    if not st then return end
    st.hidden[activityId] = hidden or nil
end

-- Whether an activity is hidden.
function activityModel:isHidden(activityId)
    local st = store()
    return (st and st.hidden[activityId]) or false
end

--[[
  Record a within-group ordering. `orderedIds` is the activity ids of one group
  in the order the user arranged them; each id's position becomes its override.

  @param orderedIds array of activity id strings
]]
function activityModel:setOrder(orderedIds)
    local st = store()
    if not st then return end
    for i, id in ipairs(orderedIds) do
        st.order[id] = i
    end
end

--[[
  Record the group ordering. `orderedKeys` is group keys in the user's order.

  @param orderedKeys array of group key strings
]]
function activityModel:setGroupOrder(orderedKeys)
    local st = store()
    if not st then return end
    for i, key in ipairs(orderedKeys) do
        st.groups[key] = i
    end
end

-- Clear all hidden/reorder choices - Customize Activities' reset. The next
-- enumerate returns canonical order with nothing hidden.
function activityModel:resetAll()
    local st = store()
    if not st then return end
    wipe(st.hidden)
    wipe(st.order)
    wipe(st.groups)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function activityModel:initialize()
    professionHarvester = Addon.professionHarvester
    ledger = Addon.ledger

    if not professionHarvester or not ledger then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444activityModel: Missing dependencies|r")
        return false
    end

    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("activityModel", {"professionHarvester", "ledger"},
        function()
            return activityModel:initialize()
        end)
end

Addon.activityModel = activityModel
return activityModel
