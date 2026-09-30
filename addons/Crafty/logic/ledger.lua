--[[
  logic/ledger.lua
  Crafty Account-Wide Ledger

  Holds facts, normalized, single source of truth. Knows nothing about the
  crafting UI - keyed entirely on universal ids (recipeID, itemID, profession
  skill-line id) and character identity (Name-Realm). Designed so it could be
  lifted into its own addon by moving its SavedVariable declarations; nothing
  here references a crafting-specific concept.

  One store:
    crafty_character - per-character facts (known sets, cooldowns, ranks,
                        inventory). Keyed by "Name-Realm".

  Universal recipe facts (reagents, output, difficulty) are NOT stored: they are
  game constants shipped in the static data tables and read through
  recipeCatalog, keyed by recipeID, identical for every character. The ledger
  reads them live rather than caching a copy into the save.

  Dependencies: utils, events, constants, recipeCatalog
  Exports: Addon.ledger
]]

local ADDON_NAME, Addon = ...

local ledger = {}

-- Module references (resolved at init, not at file load)
local utils, events, constants, recipeCatalog

-- The live SV tables, resolved at init.
local characterStore     -- crafty_character

-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

--[[
  Build the "Name-Realm" key for a character. Realm is normalized (spaces
  stripped) to match how WoW returns it across APIs.

  @param name string|nil  - character name; defaults to current player
  @param realm string|nil - realm name; defaults to current realm
  @return string - "Name-Realm"
]]
local function characterKey(name, realm)
    name = name or UnitName("player")
    realm = realm or GetRealmName()
    realm = (realm or ""):gsub("%s+", "")
    return name .. "-" .. realm
end

--[[
  Resolve a charKey argument that is optional and defaults to current player.

  @param charKey string|nil
  @return string
]]
local function resolveChar(charKey)
    return charKey or characterKey()
end

--[[
  Get (creating if absent) the per-character record.

  @param charKey string
  @return table
]]
local function getCharRecord(charKey)
    local rec = characterStore.chars[charKey]
    if not rec then
        rec = { professions = {}, inventory = {}, inventoryScan = {}, pinned = {} }
        characterStore.chars[charKey] = rec
    end
    -- Backfill pinned for records created before pins existed.
    rec.pinned = rec.pinned or {}
    return rec
end


--[[
  Get (creating if absent) a character's per-profession record.

  @param charKey string
  @param profID number
  @return table
]]
local function getProfRecord(charKey, profID)
    local rec = getCharRecord(charKey)
    local prof = rec.professions[profID]
    if not prof then
        prof = { known = {}, cooldowns = {}, rank = 0 }
        rec.professions[profID] = prof
    end
    return prof
end

-- ============================================================================
-- SCAN (write path) - modern C_TradeSkillUI by default
-- ============================================================================

-- ============================================================================
-- SET: profession scan write interface
-- ============================================================================
-- The scanner (logic, lives elsewhere) reads the open trade-skill window and
-- writes results through these setters. The ledger never reads the game; it only
-- stores what it is given. beginProfessionScan resets a profession's stored state
-- for a fresh scan; recordKnownRecipe records one recipe.

--[[
  Start a fresh scan of a profession: set its metadata and clear its known set
  and cooldowns so the scan that follows fully rewrites them.

  @param profID number, name string, rank number, category string
]]
function ledger:beginProfessionScan(profID, name, rank, category)
    local prof = getProfRecord(characterKey(), profID)
    prof.rank = rank
    -- Stored so the character's difficulty thresholds stay derivable when they
    -- are not logged in; the live path reads the harvester and never uses this.
    local _, bonus = self:skillIn(profID)
    prof.bonus = bonus
    wipe(prof.known)
    wipe(prof.cooldowns)
end

--[[
  Record one known recipe for a profession: mark it known for this character and
  set its running cooldown if any. Universal recipe facts (reagents, output,
  icon, difficulty) are NOT stored - they are game constants read live from the
  catalog's static tables, or derived from the recipeID at display.

  @param profID number
  @param recipeID number
  @param cooldownExpiry number|nil - absolute expiry time, or nil for no cooldown
]]
function ledger:recordKnownRecipe(profID, recipeID, cooldownExpiry)
    local prof = getProfRecord(characterKey(), profID)
    -- known maps recipeID -> learnedAt timestamp. Presence is the "known" fact;
    -- the value is when THIS character first learned it. Set the timestamp only
    -- on the unknown->known transition - scans re-record known recipes every
    -- time, so a known recipe keeps its original learned time.
    if not prof.known[recipeID] then
        prof.known[recipeID] = time()
    end
    if cooldownExpiry then
        prof.cooldowns[recipeID] = cooldownExpiry
    end
end

--[[
  Record a recipe learned outside a scan (the NEW_RECIPE_LEARNED event gives only
  a spellID, and a recipe can be learned with no profession window open - from a
  trainer, a bag item, a discovery, or a level-up). Everything needed is in the
  static recipe data keyed by that spellID: its profession (via recipeCatalog),
  output, and reagents. No live window, no current-profession assumption.

  Returns the profID it was filed under, or nil if the recipe is not in the
  static data (nothing to file it against).

  @param recipeID number
  @return number|nil
]]
function ledger:recordLearnedRecipe(recipeID)
    local profID = recipeCatalog:professionOf(recipeID)
    if not profID then return nil end

    self:recordKnownRecipe(profID, recipeID)
    return profID
end

-- ============================================================================
-- SCAN (write path) - live bag counts
-- ============================================================================

--[[
  Rewrite this character's bag counts. Full rewrite is correct by construction
  and cheap. Bank/mail are deferred to a later build.
]]
function ledger:scanBags()
    local charKey = characterKey()
    local rec = getCharRecord(charKey)

    -- Reset bag counts; preserve bank/mail sections (not scanned here).
    for itemID, byContainer in pairs(rec.inventory) do
        byContainer.bags = nil
        if next(byContainer) == nil then
            rec.inventory[itemID] = nil
        end
    end

    local counts = {}
    for bag = 0, NUM_BAG_SLOTS do
        local slots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID then
                counts[info.itemID] = (counts[info.itemID] or 0) + (info.stackCount or 1)
            end
        end
    end

    for itemID, n in pairs(counts) do
        local entry = rec.inventory[itemID]
        if not entry then
            entry = {}
            rec.inventory[itemID] = entry
        end
        entry.bags = n
    end

    rec.inventoryScan.bags = time()
    events:emit(constants.EVENT.BAGS_SCANNED, {})
end

-- ============================================================================
-- READ API - charKey is always OPTIONAL and LAST (omitted == current char)
-- ============================================================================

--[[
  @param profID number
  @param charKey string|nil
  @return table - array of recipeIDs this character knows in this profession
]]
--[[
  Remove a profession's entire record for a character: an unlearn. The recipes,
  ranks, and cooldowns under it are facts about a skill the character no longer
  has. Viewed-profession state pointing at it is cleared with it.

  @param profID number
  @param charKey string|nil - defaults to the current character
]]
function ledger:forgetProfession(profID, charKey)
    local rec = getCharRecord(resolveChar(charKey))
    rec.professions[profID] = nil
    if rec.viewedProfID == profID then
        rec.viewedProfID = nil
    end
end

function ledger:getKnownRecipes(profID, charKey)
    local rec = characterStore.chars[resolveChar(charKey)]
    if not rec then return {} end
    local prof = rec.professions[profID]
    if not prof then return {} end
    local out = {}
    for recipeID in pairs(prof.known) do
        out[#out + 1] = recipeID
    end
    return out
end

--[[
  Pins are a per-character set of recipeIDs that float to the top of the recipe
  list. Used for things like research-cooldown recipes you always want visible.
]]

-- Whether a recipe is pinned for the given (or current) character.
function ledger:isPinned(recipeID, charKey)
    local rec = characterStore.chars[resolveChar(charKey)]
    return rec ~= nil and rec.pinned ~= nil and rec.pinned[recipeID] == true
end

-- Set or clear a pin. Returns the new pinned state.
function ledger:setPinned(recipeID, pinned, charKey)
    local rec = getCharRecord(resolveChar(charKey))
    rec.pinned[recipeID] = pinned and true or nil
    return rec.pinned[recipeID] == true
end

-- Toggle a pin. Returns the new pinned state.
function ledger:togglePin(recipeID, charKey)
    return self:setPinned(recipeID, not self:isPinned(recipeID, charKey), charKey)
end

-- The last-viewed profession for a character (per-character UI state), or nil
-- if none has been recorded yet.
-- The current character's identity key ("Name-Realm"). Used to scope
-- per-character-profession state.
function ledger:currentCharKey()
    return characterKey()
end

function ledger:getViewedProfID(charKey)
    local rec = characterStore.chars[resolveChar(charKey)]
    return rec and rec.viewedProfID or nil
end

-- Record the last-viewed profession for a character.
function ledger:setViewedProfID(profID, charKey)
    local rec = getCharRecord(resolveChar(charKey))
    rec.viewedProfID = profID
end

-- The set of pinned recipeIDs for the given (or current) character.
function ledger:getPinned(charKey)
    local rec = characterStore.chars[resolveChar(charKey)]
    if not rec or not rec.pinned then return {} end
    return rec.pinned
end

-- Merge another character's pins into the current character's. Additive: the
-- source's pins are added, existing pins are kept. Returns how many were added.
function ledger:copyPinsFrom(sourceCharKey, destCharKey)
    local source = characterStore.chars[sourceCharKey]
    if not source or not source.pinned then return 0 end
    local dest = getCharRecord(resolveChar(destCharKey))
    local added = 0
    for recipeID in pairs(source.pinned) do
        if not dest.pinned[recipeID] then
            dest.pinned[recipeID] = true
            added = added + 1
        end
    end
    return added
end

--[[
  @param profID number
  @param recipeID number
  @param charKey string|nil
  @return boolean
]]
function ledger:knowsRecipe(profID, recipeID, charKey)
    local rec = characterStore.chars[resolveChar(charKey)]
    if not rec then return false end
    local prof = rec.professions[profID]
    return prof and prof.known[recipeID] ~= nil or false
end

--[[
  When a character first learned a recipe (absolute time()), or nil if unknown.
  The known set maps recipeID -> learnedAt timestamp, so this is just that value.

  @param profID number
  @param recipeID number
  @param charKey string|nil - defaults to current character
  @return number|nil
]]
function ledger:learnedAt(profID, recipeID, charKey)
    local rec = characterStore.chars[resolveChar(charKey)]
    if not rec then return nil end
    local prof = rec.professions[profID]
    return prof and prof.known[recipeID] or nil
end

--[[
  Which of this account's characters know a given recipe.

  @param recipeID number
  @return table - array of charKeys
]]
function ledger:whoKnows(recipeID)
    local out = {}
    for charKey, rec in pairs(characterStore.chars) do
        for _, prof in pairs(rec.professions) do
            if prof.known[recipeID] then
                out[#out + 1] = charKey
                break
            end
        end
    end
    return out
end

--[[
  @param profID number
  @return string|nil - localized profession name, derived live (not stored)
]]
function ledger:getProfessionName(profID)
    for _, p in ipairs(Addon.professionHarvester:enumerate()) do
        if p.profID == profID then return p.name end
    end
    return nil
end

--[[
  Record an absolute cooldown expiry for a recipe under a profession on the
  current (or given) character. Used by the login cooldown sweep. Pass expiry as
  an absolute time() value; nil clears it.

  @param profID number
  @param recipeID number
  @param expiry number|nil - absolute time() when the cooldown ends
  @param charKey string|nil
]]
function ledger:setCooldown(profID, recipeID, expiry, charKey)
    local prof = getProfRecord(resolveChar(charKey), profID)
    prof.cooldowns[recipeID] = expiry
end

--[[
  A character's reported rank and skill bonus in a profession. The rank is what
  the game displays and what recipe learn levels gate on; the bonus is the gap
  between it and the trained skill that static thresholds are written in. Live
  for the current character, so difficulty is right the instant skill changes;
  from the store for anyone else, who is not logged in.

  @param profID number - skill-line id
  @param charKey string|nil
  The third return is an ITEM bonus, which is a different thing again: it does
  not move recipe difficulty but it does extend gathering reach. Live only - a
  character who is not logged in is not wearing anything we can ask about.

  @param profID number - skill-line id
  @param charKey string|nil
  @return number|nil, number|nil, number - rank, bonus, itemBonus
]]
function ledger:skillIn(profID, charKey)
    if not charKey or resolveChar(charKey) == characterKey() then
        for _, prof in ipairs(Addon.professionHarvester:enumerate()) do
            if prof.profID == profID then
                return prof.rank, prof.bonus, prof.itemBonus
            end
        end
        -- not currently one of the live professions; fall through to stored
    end
    local rec = characterStore.chars[resolveChar(charKey)]
    local prof = rec and rec.professions[profID]
    if not prof then return nil end
    return prof.rank, prof.bonus, 0
end


--[[
  Seconds remaining on a recipe's cooldown for a character, or nil.

  @param recipeID number
  @param charKey string|nil
  @return number|nil
]]
function ledger:getCooldown(recipeID, charKey)
    local rec = characterStore.chars[resolveChar(charKey)]
    if not rec then return nil end
    for _, prof in pairs(rec.professions) do
        local expiry = prof.cooldowns[recipeID]
        if expiry then
            return expiry > time() and expiry or nil
        end
    end
    return nil
end

--[[
  Per-container counts of an item for a character. Mail is summed across
  non-expired stacks. Bank/mail are nil until those scans exist.

  @param itemID number
  @param charKey string|nil
  @return table - { bags, bank, mail }
]]
function ledger:getItemCount(itemID, charKey)
    local rec = characterStore.chars[resolveChar(charKey)]
    if not rec then return { bags = 0, bank = 0, mail = 0 } end
    local entry = rec.inventory[itemID]
    if not entry then return { bags = 0, bank = 0, mail = 0 } end

    local mailTotal = 0
    if entry.mail then
        local now = time()
        for _, stack in ipairs(entry.mail) do
            if not stack.expires or stack.expires > now then
                mailTotal = mailTotal + (stack.count or 0)
            end
        end
    end

    return {
        bags = entry.bags or 0,
        bank = entry.bank or 0,
        mail = mailTotal,
    }
end

--[[
  Account-wide total of an item across all characters, plus per-character.

  @param itemID number
  @return table - { perChar = {charKey -> total}, account = N }
]]
function ledger:getItemTotal(itemID)
    local perChar = {}
    local account = 0
    for charKey in pairs(characterStore.chars) do
        local c = self:getItemCount(itemID, charKey)
        local total = (c.bags or 0) + (c.bank or 0) + (c.mail or 0)
        perChar[charKey] = total
        account = account + total
    end
    return { perChar = perChar, account = account }
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ledger:initialize()
    utils = Addon.utils
    events = Addon.events
    constants = Addon.constants
    recipeCatalog = Addon.recipeCatalog

    if not utils or not events or not constants or not recipeCatalog then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444ledger: Missing dependencies|r")
        return false
    end

    -- The SV tables are created/migrated by svRegistry before module init.
    characterStore = crafty_character


    -- Trade-skill scanning is driven by the professionHarvester, which opens
    -- each profession and calls recipeScanner:scanOpen. The scanner writes
    -- results back through this ledger's set interface (beginProfessionScan /
    -- recordKnownRecipe). The ledger does not read the game or subscribe to raw
    -- trade-skill events itself.

    -- Bag changes.
    events:subscribe("BAG_UPDATE_DELAYED", function()
        ledger:scanBags()
    end)

    -- One bag scan at login so we have counts before the first bag event.
    ledger:scanBags()

    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("ledger", {"utils", "events", "recipeCatalog"}, function()
        return ledger:initialize()
    end)
end

Addon.ledger = ledger
return ledger
