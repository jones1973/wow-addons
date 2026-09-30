--[[
  logic/recipeCatalog.lua
  Crafty Static Recipe Catalog

  The single consumer-facing object over the shipped static recipe data. The
  data layer is split by provenance (wh* = Wowhead scrape, db* = DB2 export,
  patch* = hand-curated corrections) so each file maps to the pipeline that
  regenerates it - but no consumer should have to know which source holds
  which fact. This module consolidates all of them; consumers ask the catalog
  and never touch the source tables.

  Owns: Addon.data.dbRecipeReagents, Addon.data.recipeProgression,
  Addon.data.dbRecipeCooldown, Addon.data.recipeGate,
  Addon.data.professionTiers. Accessors exist for the facts consumers actually
  read; when a new consumer needs a gate/tier/source fact, the accessor is
  added here rather than the consumer reaching into the table.

  Corrections are applied upstream by the merge, not at lookup time,
  so both source tables stay exactly what their pipelines produced.

  Dependencies: none (reads plain data tables, resolved at init)
  Exports: Addon.recipeCatalog
]]

local ADDON_NAME, Addon = ...

local recipeCatalog = {}

-- Source tables (resolved at init, not at file load)
local reagentsTbl, progressionTbl, cooldownTbl, npcTbl, gateTbl

-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

-- The progression row for a recipe. One table: corrections are applied by the
-- merge (design/user_verdicts_*.json), so what ships is already correct.
local function prog(recipeID)
    return progressionTbl[recipeID]
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  The profession (skillLine) a recipe belongs to.

  @param recipeID number
  @return number|nil - skillLine, or nil if the recipe is unknown
]]
function recipeCatalog:professionOf(recipeID)
    local rd = reagentsTbl[recipeID]
    return rd and rd.skill
end

--[[
  Reagent composition for a recipe. The shipped rows are positional pairs
  {itemID, count}; this maps them to the keyed {item, count} shape the rest of
  the addon consumes, so the storage format stays an implementation detail of
  the data files.

  @param recipeID number
  @return table - array of { item, count } (empty if unknown)
]]
function recipeCatalog:reagents(recipeID)
    local rd = reagentsTbl[recipeID]
    if not rd then return {} end
    local out = {}
    for i = 1, #rd.reagents do
        local pair = rd.reagents[i]
        out[i] = { item = pair[1], count = pair[2] }
    end
    return out
end

--[[
  What a recipe creates. Multiple returns (not a table) so hot paths - sort
  comparators, row renders - read it without allocating.

  @param recipeID number
  @return number|nil, number|nil, number|nil - output itemID, yield low, yield high
]]
function recipeCatalog:output(recipeID)
    local ri = prog(recipeID)
    if not ri then return nil end
    return ri.item, ri.min, ri.max
end

-- ============================================================================
-- CONVERSIONS (milling / prospecting)
-- ============================================================================
-- The same facade duty over the shipped conversion tables (data/milling_*,
-- data/prospecting_*). Those tables carry only what sampling knows: which
-- results a source yields, how often (INDEPENDENT per-cast presence, not a
-- distribution), and per-proc quantity where known. Eligibility and required
-- skill are the CLIENT's to declare at runtime, so they are not shipped and
-- not consulted here.

-- The verbs and their identities. A client without a verb's data table (TBC
-- has no Milling) simply contributes no sources.
local CONVERT_VERBS = {
    milling     = { spellID = 51005, profID = 773 },
    prospecting = { spellID = 31252, profID = 755 },
}

-- [sourceItemID] = { verb, results } and [resultItemID] -> sources reverse;
-- built lazily once, like the producers index below.
local convertSources, convertByResult

local function ensureConversions()
    if convertSources then return end
    convertSources, convertByResult = {}, {}
    local tables = {
        milling     = Addon.data.milling,
        prospecting = Addon.data.prospecting,
    }
    for verb, tbl in pairs(tables) do
        if tbl then
            for sourceID, results in pairs(tbl) do
                convertSources[sourceID] = { verb = verb, results = results }
                for _, r in ipairs(results) do
                    local list = convertByResult[r.id]
                    if not list then
                        list = {}
                        convertByResult[r.id] = list
                    end
                    list[#list + 1] = {
                        sourceID = sourceID, verb = verb,
                        chance = r.chance, tier = r.tier, qty = r.qty,
                    }
                end
            end
        end
    end
    -- The grid leads with the best source.
    for _, list in pairs(convertByResult) do
        table.sort(list, function(a, b)
            if a.chance ~= b.chance then return a.chance > b.chance end
            return a.sourceID < b.sourceID
        end)
    end
end

-- The verb's identity facts (spellID for casting, profID for band/journey
-- routing).
function recipeCatalog:conversionVerbInfo(verb)
    return CONVERT_VERBS[verb]
end

-- The verb that consumes this item, or nil.
function recipeCatalog:convertibleVerb(itemID)
    ensureConversions()
    local entry = convertSources[itemID]
    return entry and entry.verb or nil
end

-- One source's outcomes: { verb, results }, best-first.
function recipeCatalog:conversionResults(sourceItemID)
    ensureConversions()
    return convertSources[sourceItemID]
end

-- Every source that can produce this item, best chance first - the grid
-- behind "this reagent is milled/prospected, not crafted".
function recipeCatalog:conversionSources(resultItemID)
    ensureConversions()
    return convertByResult[resultItemID]
end


-- Reverse index: which recipes produce an item. Built lazily once (static
-- data), keyed by output itemID.
local producersIndex
function recipeCatalog:producersOf(itemID)
    if not producersIndex then
        producersIndex = {}
        for recipeID in pairs(reagentsTbl) do
            local item = recipeCatalog:output(recipeID)
            if item and item ~= 0 then
                local list = producersIndex[item]
                if not list then
                    list = {}
                    producersIndex[item] = list
                end
                list[#list + 1] = recipeID
            end
        end
    end
    return producersIndex[itemID]
end

--[[
  @param recipeID number
  @return number|nil - skill rank the recipe is learnable at
]]
function recipeCatalog:learn(recipeID)
    -- The minimum skill to acquire this recipe by any of its paths, derived
    -- from the per-path data (the flat learn value is gone - it conflated
    -- acquisition skill with difficulty and could not hold more than one path).
    -- Trainer requirement, each item path's own req, and each discovery path's
    -- skill are the candidates; the lowest is the earliest you can get it.
    local ri = prog(recipeID)
    if not ri then return nil end
    local best
    if ri.trainerReq then best = ri.trainerReq end
    for _, path in ipairs(ri.paths or {}) do
        if path.req and (not best or path.req < best) then best = path.req end
    end
    for _, d in ipairs(self:discoveredFrom(recipeID) or {}) do
        -- skill 0 is the SKILL-case sentinel (any discovery-capable craft of the
        -- profession), not a real skill gate - it does not lower the minimum.
        if d.skill and d.skill > 0 and (not best or d.skill < best) then
            best = d.skill
        end
    end
    return best
end

--[[
  @param recipeID number
  @return number|nil - skill points granted per craft
]]
function recipeCatalog:skillUps(recipeID)
    local ri = prog(recipeID)
    return ri and ri.skillupCnt
end

--[[
  The recipe's static difficulty thresholds. Returns the stored row (do not
  mutate).

  @param recipeID number
  @return table|nil - {orange, yellow, green, grey} band starts
]]
function recipeCatalog:colors(recipeID)
    local ri = prog(recipeID)
    return ri and ri.colors
end

--[[
  The recipe's static cooldown row, or nil if it has no cooldown by nature.
  Raw storage shape ({hours, flags, sharedCat}) - cooldownData is the domain
  API over it; other consumers should go there.

  @param recipeID number
  @return table|nil
]]
--[[
  The Wowhead source codes for a recipe ({6}=trainer, {7}=discovery, ...),
  or nil. Shipped on progression rows by the merge pipeline.

  @param recipeID number
  @return table|nil
]]
--[[
  The recipe this one supersedes (rank chains: Lightweave Embroidery II
  replaces I), or nil for the vast majority that stand alone.

  @param recipeID number
  @return number|nil
]]
--[[
  The character level a recipe is gated behind, or nil. Only trainers state
  this, so it is present only where field observation recorded one.

  @param recipeID number
  @return number|nil
]]
--[[
  The recipe's acquisition paths, or nil where the source pass has not
  captured it. Each path names its kind and whatever detail that kind
  carries; trainer and vendor/drop paths reference an NPC by id (see
  recipeCatalog:npc).

  A recipe with several paths can be obtained several ways, each with its own
  requirement - the ramp is a property of the recipe, the requirement is a
  property of the path.

  @param recipeID number
  @return table|nil - array of {kind, npc?, item?, quest?, req?, ...}
]]
--[[
  Who a recipe is restricted to, or nil where it is open to everyone.
  Faction is 0 both / 1 Alliance / 2 Horde; class is a class mask; spec is a
  specialization spell. Two same-named recipes creating different items are
  usually the faction pair (Forged Documents), so a recipe absent from YOUR
  trainer may simply be the other side's.

  @param recipeID number
  @return table|nil - {class, faction, spec}
]]
function recipeCatalog:gate(recipeID)
    return gateTbl and gateTbl[recipeID]
end

--[[
  Whether this character can learn the recipe at all, per its gate.

  @param recipeID number
  @return boolean
]]
function recipeCatalog:isEligible(recipeID)
    local g = self:gate(recipeID)
    if not g then return true end
    if g.faction and g.faction ~= 0 then
        local mine = UnitFactionGroup("player") == "Alliance" and 1 or 2
        if g.faction ~= mine then return false end
    end
    return true
end

--[[
  The recipe's non-trainer acquisition paths, or nil.

  Trainers are NOT here - see :trainers(). An item or quest path is a RECORD
  whose fields vary per path (which item, its own skill requirement, where the
  item itself comes from), so each needs its own table. A trainer is one id.

  @param recipeID number
  @return table|nil - array of path tables
]]
function recipeCatalog:paths(recipeID)
    local p = prog(recipeID)
    return p and p.paths
end

--[[
  The recipe's trainer NPC ids, as the packed string they are stored in, or nil.

  Stored packed because it is a SET of ids: the kind never varies, only the id
  does. Held as one table per element it cost 111x the memory and put 57,543
  copies of a constant word in the data file.

  @param recipeID number
  @return string|nil - comma-separated npc ids
]]
function recipeCatalog:trainers(recipeID)
    local p = prog(recipeID)
    return p and p.trainers
end

-- The recipe->trainer relation is stored recipe-side, but "what does THIS
-- trainer teach" is the question asked at a trainer window. Answering it from
-- the recipe side means scanning every recipe; inverting it once at first use
-- turns that into a lookup. Built lazily because most sessions never open a
-- trainer - and lazily is what makes the packed form free, since the split
-- happens here rather than at load.
local trainerIndex

local function buildTrainerIndex()
    trainerIndex = {}
    for recipeID, p in pairs(progressionTbl) do
        for npc in string.gmatch(p.trainers or "", "%d+") do
            npc = tonumber(npc)
            local bucket = trainerIndex[npc]
            if not bucket then
                bucket = {}
                trainerIndex[npc] = bucket
            end
            bucket[#bucket + 1] = recipeID
        end
    end
end

-- Which recipe a teaching ITEM teaches. Item paths name the item, so the map
-- runs the wrong way for a merchant window, where all you have is what is on
-- the shelf. Inverted once at first use, lazily - most sessions never open a
-- vendor, and the walk is over the 3,052 item paths rather than every recipe.
local itemIndex

local function buildItemIndex()
    itemIndex = {}
    for recipeID, p in pairs(progressionTbl) do
        for _, path in ipairs(p.paths or {}) do
            if path.kind == "item" and path.item then
                itemIndex[path.item] = recipeID
            end
        end
    end
end

-- Which discoverers can produce a recipe. The data is stored discoverer-side
-- because 61 discoverers cover 812 recipes and 236 of those have more than one
-- discoverer - recipe-side would repeat the relation on both ends. Inverted
-- once at first use, like the trainer index.
local discoveryIndex

local function buildDiscoveryIndex()
    discoveryIndex = {}
    for discoverer, groups in pairs(Addon.data.discovery or {}) do
        for _, g in ipairs(groups) do
            for id in string.gmatch(g.recipes, "%d+") do
                local recipeID = tonumber(id)
                local list = discoveryIndex[recipeID]
                if not list then
                    list = {}
                    discoveryIndex[recipeID] = list
                end
                list[#list + 1] = { from = discoverer, skill = g.skill,
                                    chance = g.chance }
            end
        end
    end
end

--[[
  How a recipe is discovered, or nil if it is not a discovery recipe.

  `from` is the discovering spell, or 0 for the SKILL case - any
  discovery-capable craft of that profession, which is not the same as any
  craft: the spell being cast must itself be a discovery spell.

  @param recipeID number
  @return table|nil - array of { from, skill, chance }
]]
function recipeCatalog:discoveredFrom(recipeID)
    if not discoveryIndex then buildDiscoveryIndex() end
    return discoveryIndex[recipeID]
end

--[[
  Every recipe a discoverer can produce.

  @param discovererID number - spellID, or 0 for the skill case
  @return table - array of recipeIDs, empty when it discovers nothing
]]
function recipeCatalog:discovers(discovererID)
    local out = {}
    for _, g in ipairs((Addon.data.discovery or {})[discovererID] or {}) do
        for id in string.gmatch(g.recipes, "%d+") do
            out[#out + 1] = tonumber(id)
        end
    end
    return out
end

-- Recipes by profession. professionOf answers the reverse, so the forward map
-- means walking the whole catalog; inverted once at first use, lazily.
local profIndex

local function buildProfIndex()
    profIndex = {}
    for recipeID in pairs(progressionTbl) do
        local p = recipeCatalog:professionOf(recipeID)
        if p then
            local bucket = profIndex[p]
            if not bucket then
                bucket = {}
                profIndex[p] = bucket
            end
            bucket[#bucket + 1] = recipeID
        end
    end
end

--[[
  Every recipe in a profession.

  @param profID number - skill-line id
  @return table - array of recipeIDs, empty when the profession has none
]]
function recipeCatalog:recipesIn(profID)
    if not profIndex then buildProfIndex() end
    return profIndex[profID] or {}
end

--[[
  The recipe a teaching item teaches, or nil if this item teaches nothing we
  carry.

  @param itemID number
  @return number|nil - recipeID
]]
function recipeCatalog:taughtByItem(itemID)
    if not itemIndex then buildItemIndex() end
    return itemIndex[itemID]
end

--[[
  Every recipe this trainer NPC teaches, per the captured paths.

  @param npcID number
  @return table - array of recipeIDs, empty when this NPC teaches none
]]
function recipeCatalog:recipesTaughtBy(npcID)
    if not trainerIndex then buildTrainerIndex() end
    return trainerIndex[npcID] or {}
end

--[[
  An NPC named by an acquisition path: name, tag, and the zones they stand in.

  @param npcID number
  @return table|nil - {name, tag, zones}
]]
function recipeCatalog:npc(npcID)
    return npcTbl and npcTbl[npcID]
end

function recipeCatalog:levelReq(recipeID)
    local p = prog(recipeID)
    return p and p.levelReq
end

--[[
  The skill requirement of the ITEM that teaches this recipe, where a live
  teaching item exists. A recipe with both an item and a trainer has two
  acquisition paths with two requirements; this is the item's.

  @param recipeID number
  @return number|nil
]]
function recipeCatalog:itemReq(recipeID)
    local p = prog(recipeID)
    return p and p.itemReq
end

--[[
  What this recipe's button should say: the profession's own word when the
  recipe AUGMENTS an item, nil when it creates one.

  Enchanting says "Enchant", Inscription "Inscribe", Leatherworking "Emboss" -
  Blizzard's own strings, in the player's language, from
  SkillLine.AlternateVerb_lang.

  Per RECIPE, not per profession: a Blacksmithing sword is created and a
  Blacksmithing socket is a modification, so the flag lives on the recipe and
  the word on the profession.

  @param recipeID number
  @return string|nil
]]
function recipeCatalog:augmentVerb(recipeID)
    local ri = prog(recipeID)
    if not (ri and ri.augments) then return nil end
    return (Addon.data.augmentVerbs or {})[self:professionOf(recipeID)]
end

function recipeCatalog:supercedes(recipeID)
    local p = prog(recipeID)
    return p and p.supercedes
end

-- Source-code constants, matching the merge's WH_SOURCE numbering. Callers
-- compare against these; the codes are now DERIVED from the per-path data
-- rather than read from a stored flat array (which drifted from the paths).
local SRC_DROP, SRC_QUEST, SRC_VENDOR, SRC_WORLD = 1, 2, 4, 5
local SRC_TRAINER, SRC_DISCOVERY, SRC_GRANT = 6, 7, 100
local KIND_CODE = { drop = SRC_DROP, quest = SRC_QUEST, vendor = SRC_VENDOR,
                    world = SRC_WORLD, grant = SRC_GRANT, achievement = 12,
                    instance = 22 }

function recipeCatalog:sources(recipeID)
    -- The set of source codes for a recipe, derived from every path that can
    -- reach it: its trainers (SRC_TRAINER), each acquisition path's kind, and
    -- membership in the discovery table (SRC_DISCOVERY). One place answers each
    -- - no stored summary to fall out of sync with the paths it summarizes.
    local ri = prog(recipeID)
    if not ri then return nil end
    local seen, codes = {}, {}
    local function add(code)
        if code and not seen[code] then seen[code] = true; codes[#codes + 1] = code end
    end
    if ri.trainers then add(SRC_TRAINER) end
    for _, path in ipairs(ri.paths or {}) do
        -- An item path is a vendor or a drop when it says so, else just an item
        -- (no source code - the item itself is the source, named in the path).
        if path.kind == "item" then
            -- The item path names where the teaching item comes from: a vendor,
            -- or a drop (Wowhead's "commondrop" is a drop too). A bare item path
            -- with no `from` has no world source - the item itself is it.
            if path.from == "vendor" then add(SRC_VENDOR)
            elseif path.from == "drop" or path.from == "commondrop" then add(SRC_DROP)
            end
        else
            add(KIND_CODE[path.kind])
        end
    end
    if self:discoveredFrom(recipeID) then add(SRC_DISCOVERY) end
    return codes
end

--[[
  Iterate every recipeID in the shipped progression.
  Order is undefined.

  @return iterator over recipeID
]]
function recipeCatalog:eachRecipeID()
    return pairs(progressionTbl)
end

function recipeCatalog:cooldown(recipeID)
    return cooldownTbl[recipeID]
end

--[[
  Every recipe that has a cooldown by nature.

  @return table - array of recipeIDs (order unspecified)
]]
function recipeCatalog:cooldownRecipeIDs()
    local out = {}
    for recipeID in pairs(cooldownTbl) do
        out[#out + 1] = recipeID
    end
    return out
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function recipeCatalog:initialize()
    -- Source tables are plain data (loaded from data/ per client flavor via
    -- the TOC's AllowLoadGameType lines), not registered modules.
    reagentsTbl    = Addon.data.dbRecipeReagents
    progressionTbl = Addon.data.recipeProgression
    npcTbl         = Addon.data.sourceNPCs
    gateTbl        = Addon.data.recipeGate
    cooldownTbl    = Addon.data.dbRecipeCooldown

    if not reagentsTbl or not progressionTbl or not cooldownTbl then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444recipeCatalog: Missing data tables|r")
        return false
    end

    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("recipeCatalog", {}, function()
        return recipeCatalog:initialize()
    end)
end

Addon.recipeCatalog = recipeCatalog
return recipeCatalog
