--[[
  core/itemDropIndex.lua
  Questie-backed item-drop index

  Owns three lazily-built caches:

    npcToItems   {[npcId]  = {itemId, ...}}
        Forward index. Given an NPC ID, which items does it drop?

    itemToNpcs   {[itemId] = {npcId, ...}}
        Inverse index. Given an item ID, which NPCs drop it?

    itemNames    {[itemId] = "name string"}
        Item ID to display name. Cached at index build time so
        hot-path searches don't need to call QueryItemSingle.

  A single walk of qdb.ItemPointers populates all three; subsequent
  calls short-circuit. Cost on cold cache: ~25k QueryItemSingle
  calls (one name + one npcDrops field per droppable item).

  This module is shared by reasonTypeahead (which uses the forward
  index for NPC-context-aware reason suggestions) and itemAddPanel
  (which uses the inverse index for item-first batch entry creation).
  Both want the same data; centralizing the cache avoids walking
  Questie twice and avoids one module reaching into another's locals.

  Public API:
    itemDropIndex:ensure()                  → boolean (cache available)
    itemDropIndex:itemsForNpc(npcName)      → {itemId, ...} | nil
    itemDropIndex:itemName(itemId)          → string | nil

  Dependencies: Questie (soft — module returns nil/false when absent)
  Exports: Addon.itemDropIndex
]]

local _, Addon = ...

local itemDropIndex = {}

-- ============================================================================
-- INTERNAL STATE
-- ============================================================================

local npcToItems   -- nil until ensure() succeeds
local itemToNpcs   -- nil until ensure() succeeds
local itemNames    -- nil until ensure() succeeds

local function resolveQuestie()
    local loader = _G.QuestieLoader
    if not loader or not loader.ImportModule then
        return nil
    end
    local ok, qdb = pcall(loader.ImportModule, loader, "QuestieDB")
    local _,  qs  = pcall(loader.ImportModule, loader, "QuestieSearch")
    if not ok or not qdb or not qs then return nil end
    if not qdb.ItemPointers then return nil end
    return qdb, qs
end

local function stripDifficultyMarker(name)
    return (name:gsub("%s*%([NH]%)%s*$", ""))
end

-- ============================================================================
-- CACHE BUILD
-- ============================================================================

--[[
  Build all three caches by walking every item's npcDrops field and
  reading its name in one pass. Idempotent; subsequent calls short-
  circuit. Returns true on success, false if Questie is unavailable.
]]
function itemDropIndex:ensure()
    if npcToItems then return true end

    local qdb = resolveQuestie()
    if not qdb then return false end

    npcToItems = {}
    itemToNpcs = {}
    itemNames  = {}
    for itemId, _ in pairs(qdb.ItemPointers) do
        local drops = qdb.QueryItemSingle(itemId, "npcDrops")
        if drops then
            -- Cache the name once. Items with no NPC drops aren't
            -- useful to any current consumer, so we skip their names
            -- to keep the table smaller.
            local name = qdb.QueryItemSingle(itemId, "name")
            if name then
                itemNames[itemId] = name

                local invBucket = {}
                itemToNpcs[itemId] = invBucket

                for _, npcId in pairs(drops) do
                    local fwdBucket = npcToItems[npcId]
                    if not fwdBucket then
                        fwdBucket = {}
                        npcToItems[npcId] = fwdBucket
                    end
                    fwdBucket[#fwdBucket + 1] = itemId
                    invBucket[#invBucket + 1] = npcId
                end
            end
        end
    end

    return true
end

-- ============================================================================
-- LOOKUPS
-- ============================================================================

--[[
  Resolve an NPC name to the list of itemIds dropped by any matching
  NPC. Both normal and heroic variants count — they typically share
  drops, and aggregating both matches "drops from this mob."

  Caller is expected to handle nil (no Questie, no name, no matches)
  as "empty result."

  @param npcName string|nil
  @return {itemId, ...} | nil
]]
function itemDropIndex:itemsForNpc(npcName)
    if not npcName or npcName == "" then return nil end
    if not self:ensure() then return nil end

    local _, qs = resolveQuestie()
    if not qs then return nil end

    local stripped = stripDifficultyMarker(npcName)
    local ok, ids = pcall(qs.Search, qs, stripped, "npc", "chars")
    if not ok or not ids then return nil end

    -- Aggregate drops across all matching NPC IDs. Dedupe items: an
    -- item dropped by N+H variants of the same mob would appear
    -- twice without the seen-set.
    local itemSet = {}
    for npcId in pairs(ids) do
        local bucket = npcToItems[npcId]
        if bucket then
            for _, itemId in ipairs(bucket) do
                itemSet[itemId] = true
            end
        end
    end

    local out = {}
    for itemId in pairs(itemSet) do
        out[#out + 1] = itemId
    end
    return out
end

--[[
  Item ID to display name.
  @param itemId integer
  @return string | nil
]]
function itemDropIndex:itemName(itemId)
    if not itemNames then return nil end
    return itemNames[itemId]
end

--[[
  Substring-search across cached item names. Returns up to `max`
  item IDs whose name contains `text` (case-insensitive). Used by
  itemAddPanel's search field — operates on the cached name table,
  no Questie calls in the hot path.

  @param text string
  @param max integer
  @return {itemId, ...}  (empty table if cache unavailable)
]]
function itemDropIndex:searchItems(text, max)
    if not self:ensure() then return {} end
    if not text or text == "" then return {} end

    local lower = text:lower()
    local out = {}
    for itemId, name in pairs(itemNames) do
        if name:lower():find(lower, 1, true) then
            out[#out + 1] = itemId
            if max and #out >= max then break end
        end
    end

    -- Stable alphabetical order so the dropdown isn't pair-iteration
    -- chaos. Sort after the cap because cap-before-sort would give
    -- a random alphabetical slice.
    table.sort(out, function(a, b)
        return itemNames[a] < itemNames[b]
    end)
    return out
end

--[[
  Inverse-index lookup: NPC IDs that drop the given item.
  @param itemId integer
  @return {npcId, ...} | nil
]]
function itemDropIndex:npcsForItem(itemId)
    if not itemToNpcs then return nil end
    return itemToNpcs[itemId]
end

--[[
  Given a list of picked item IDs, produce the staged NPC entries
  the user is about to add to the watch list. Handles:

    - Heroic dedup: NPCs whose names differ only by Questie's "(1)"
      heroic suffix are collapsed by base name. If both N and H
      variants drop a picked item, the entry uses the bare name
      (no marker). If only one variant does, the entry uses
      "(N)" or "(H)" as appropriate.

    - Reason concatenation: an NPC dropping multiple picked items
      gets a single entry with reason = "Item A, Item B".

    - Zone resolution: prefers the normal variant's first spawn
      zone; falls back to the heroic variant's; nil if neither
      has zone data (the user gets a zoneless entry).

    - Conflict detection: each entry is flagged isConflict=true if
      a row already exists in existingEntries with the same
      (name, zone) pair. Caller decides what to do with conflicts.

  @param itemIds {itemId, ...}
  @param existingEntries {{name=string, zone=string|nil, reason=string}, ...}
  @return {{name=string, zone=string|nil, reason=string, isConflict=boolean}, ...}
]]
function itemDropIndex:resolveStaging(itemIds, existingEntries)
    if not self:ensure() then return {} end

    local qdb = resolveQuestie()
    if not qdb then return {} end

    -- Walk each picked item, collect the NPC IDs that drop it, and
    -- group them by bare name. Each group tracks which variants
    -- (N/H) saw which items, so we can build the reason later.
    --
    -- groups[baseName] = {
    --     hasNormal     = bool,
    --     hasHeroic     = bool,
    --     normalId      = npcId | nil  (representative for zone lookup)
    --     heroicId      = npcId | nil
    --     itemsByVariant = {
    --         normal = {[itemId] = true, ...}
    --         heroic = {[itemId] = true, ...}
    --     }
    -- }
    local groups = {}

    for _, itemId in ipairs(itemIds) do
        local npcIds = itemToNpcs[itemId]
        if npcIds then
            for _, npcId in ipairs(npcIds) do
                local rawName = qdb.QueryNPCSingle(npcId, "name")
                if rawName and not Addon.npcNameFilter:isJunk(rawName) then
                    local baseName, isHeroic = Addon.questieHelpers:stripNumericSuffix(rawName)
                    local g = groups[baseName]
                    if not g then
                        g = {
                            hasNormal = false, hasHeroic = false,
                            normalId  = nil,   heroicId  = nil,
                            itemsByVariant = { normal = {}, heroic = {} },
                        }
                        groups[baseName] = g
                    end
                    if isHeroic then
                        g.hasHeroic = true
                        g.heroicId  = g.heroicId or npcId
                        g.itemsByVariant.heroic[itemId] = true
                    else
                        g.hasNormal = true
                        g.normalId  = g.normalId or npcId
                        g.itemsByVariant.normal[itemId] = true
                    end
                end
            end
        end
    end

    -- Validate heroic claims: a "(1)"-suffixed NPC only counts as a
    -- real heroic if its health is proportional to the normal
    -- variant's. Data-artifact "(1)" entries (BG NPCs, dev placeholders)
    -- use placeholder health values and are downgraded back to
    -- normal-only.
    for _, g in pairs(groups) do
        if g.hasHeroic then
            local normalHealth = g.normalId and qdb.QueryNPCSingle(g.normalId, "maxLevelHealth")
            local heroicHealth = g.heroicId and qdb.QueryNPCSingle(g.heroicId, "maxLevelHealth")
            if not Addon.questieHelpers:isHeroicVariant(normalHealth, heroicHealth) then
                -- Fold the heroic-side items into the normal side;
                -- it's really the same NPC.
                for itemId in pairs(g.itemsByVariant.heroic) do
                    g.itemsByVariant.normal[itemId] = true
                end
                g.itemsByVariant.heroic = {}
                g.hasHeroic = false
                -- If only the suffixed artifact existed, promote it
                -- as the normal representative so the group still has
                -- an ID for zone lookup downstream.
                if not g.hasNormal then
                    g.hasNormal = true
                    g.normalId  = g.heroicId
                end
                g.heroicId  = nil
            end
        end
    end

    -- Build a (name, zone) → true map of the existing entries so
    -- conflict checks are O(1) per staged entry.
    local existingKey = {}
    if existingEntries then
        for _, e in ipairs(existingEntries) do
            existingKey[(e.name or "") .. "|" .. (e.zone or "")] = true
        end
    end

    -- Emit staged entries. For each group, resolve display name,
    -- zone (preferring the normal variant), and concatenated reason
    -- across all items contributing to that group.
    local out = {}
    for baseName, g in pairs(groups) do
        -- Display-name rules:
        --   Normal only       → bare name (most NPCs; outdoor mobs
        --                       have no heroic variant, so the suffix
        --                       would be meaningless noise).
        --   Heroic only       → "(H)" suffix (unusual data; flag it
        --                       so the user knows the drop comes from
        --                       a heroic-only mob).
        --   Normal + heroic   → bare name (the user picked an item;
        --                       both variants drop it; without per-
        --                       variant drop-rate data there's no
        --                       reason to disambiguate).
        local displayName
        if g.hasHeroic and not g.hasNormal then
            displayName = baseName .. " (H)"
        else
            displayName = baseName
        end

        local repId = g.normalId or g.heroicId
        local zone
        if repId then
            local spawns = qdb.QueryNPCSingle(repId, "spawns")
            if spawns then
                -- spawns is { [zoneId] = {coordlist} }; grab the
                -- first available zone ID's display name.
                for zoneId in pairs(spawns) do
                    zone = Addon.questieHelpers:zoneDisplayName(zoneId)
                    if zone then break end
                end
            end
        end

        -- Concatenate reason from items that contributed to this
        -- group, across both variants. Dedupe by itemId.
        local contributingItems = {}
        for itemId in pairs(g.itemsByVariant.normal) do
            contributingItems[itemId] = true
        end
        for itemId in pairs(g.itemsByVariant.heroic) do
            contributingItems[itemId] = true
        end
        local itemNameList = {}
        for itemId in pairs(contributingItems) do
            local n = itemNames[itemId]
            if n then itemNameList[#itemNameList + 1] = n end
        end
        table.sort(itemNameList)
        local reason = table.concat(itemNameList, ", ")

        local key = displayName .. "|" .. (zone or "")
        out[#out + 1] = {
            name       = displayName,
            zone       = zone,
            reason     = reason,
            isConflict = existingKey[key] == true,
        }
    end

    -- Stable display order: by name, then zone.
    table.sort(out, function(a, b)
        if a.name == b.name then return (a.zone or "") < (b.zone or "") end
        return a.name < b.name
    end)
    return out
end

function itemDropIndex:initialize()
    return true
end

Addon.itemDropIndex = itemDropIndex
return itemDropIndex
