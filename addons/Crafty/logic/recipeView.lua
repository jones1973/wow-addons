--[[
  logic/recipeView.lua
  Live derivation of a recipe's display facts from its id.

  The recipe list holds items that carry ONLY identity (recipeID). Every display
  fact - name, difficulty band, cooldown state - is DERIVED from that id at the
  moment it is needed (render, sort, filter), never stored on the item. This is
  the single place those derivations live, so the row renderer, the sort
  comparators, and the filter predicates all agree by construction (one source
  of truth) and none of them can read a stale snapshot.

  Why derive instead of store: difficulty is a function of (current rank, static
  thresholds); cooldown remaining is a function of (now, stored expiry). Baking
  them onto the item freezes them - a skill-up or a cooldown tick would leave the
  item lying until a full re-pull. Deriving live means the held model never goes
  stale and per-row updates stay correct.

  Dependencies: ledger, difficulty, cooldownData, recipeCatalog
  Exports: Addon.recipeView
]]

local ADDON_NAME, Addon = ...

local recipeView = {}

local ledger, difficulty, cooldownData, recipeCatalog

-- The recipe's display name, derived live (not stored - a stored localized name
-- is wrong on other-locale clients). The recipeID is the recipe's spellID, so
-- the spell name is the authoritative source; for item-producing recipes the
-- output item's name is an equivalent fallback. Both can momentarily be nil
-- before the client caches them (e.g. an alt's never-seen recipe); a stable
-- id-keyed string covers that until a later derivation resolves.
function recipeView:name(recipeID)
    return C_Spell.GetSpellName(recipeID)
end

--[[
  The name as the UI shows it: the recipe, its yield, and the skill it grants.

  "Bolt of Woolen Cloth (2) +3"

  One function because the list and the detail panel show the same string, and
  two copies would drift. NOT :name() - that is the recipe's actual name, and
  the sort comparators and the catalog's identity checks want it unadorned.

  The yield goes first because Blizzard writes it into 14 spell names itself
  ("Large Copper Bomb (2-4)"); a name that already carries one is left alone
  rather than doubled. The skill-up trails both, since it is a fact about
  crafting rather than about the item, and it carries the game's own multiskill
  icon so the bare number is never left to explain itself.

  @param recipeID number
  @return string
]]
-- The full texture escape: path, height, width, x, y, file dims, texel
-- bounds, then r:g:b VERTEX COLOUR. A |c code does NOT tint a texture - it
-- only colours text - so the short form left the icon in its own orange while
-- the number took the tint. Blizzard's own chat icons use this same form.
local UPS_ICON_FMT = "|TInterface\\TradeSkillFrame\\UI-TradeSkill-Multiskill:14:14:0:-1:16:16:0:16:0:16:%d:%d:%d|t"

--[[
  The skill-up count and its icon, as one coloured unit. Nil below two.

  One function so the list and the detail panel cannot drift in colour, spacing
  or icon. The number and icon are a single token - "3" beside a bare texture
  reads as two facts - so they are coloured together and set tight, with no
  space between.

  @param recipeID number
  @return string|nil
]]
function recipeView:skillUpTag(recipeID)
    local ups = recipeCatalog:skillUps(recipeID)
    if not ups or ups <= 1 then return nil end
    local c = Addon.theme.tokens.STATE.INFO_SOFT
    return Addon.theme.derive.inline(c, ups)
           .. UPS_ICON_FMT:format(c.r * 255, c.g * 255, c.b * 255)
end

function recipeView:displayName(recipeID)
    local name = self:name(recipeID) or tostring(recipeID)

    local _, low, high = recipeCatalog:output(recipeID)
    if high and high > 1 and not name:find("%(%d+%-?%d*%)$") then
        name = name .. " (" .. (high > low and (low .. "-" .. high) or high) .. ")"
    end

    local tag = self:skillUpTag(recipeID)
    return tag and (name .. " " .. tag) or name
end

-- What the difficulty functions need for a recipe, in the scale the player
-- reads: its thresholds shifted by the character's skill bonus, and the
-- character's reported rank. Both nil when the character lacks the recipe's
-- profession, or when the recipe has no stored thresholds.
local function playerScale(recipeID)
    local rank, bonus = ledger:skillIn(recipeCatalog:professionOf(recipeID))
    if not rank then return nil end
    return difficulty:thresholds(recipeCatalog:colors(recipeID),
                                 recipeCatalog:learn(recipeID), bonus), rank
end

-- The recipe's difficulty band for the CURRENT character, derived live from the
-- character's rank against the recipe's thresholds. The profession is the
-- recipe's own (a stored recipe fact), so no UI context is needed. Returns a
-- band string or nil if unknown.
function recipeView:band(recipeID)
    local thresholds, rank = playerScale(recipeID)
    return difficulty:bandForSkill(rank, thresholds)
end

-- The full difficulty progression for a recipe: current band, the next
-- transition, distance to it, and progress through the current band. Returns nil
-- if unknown.
function recipeView:transition(recipeID)
    local thresholds, rank = playerScale(recipeID)
    return difficulty:transition(rank, thresholds)
end

-- The bar's inputs: the recipe's thresholds and the character's rank, both in
-- the scale the player reads, so every number the bar prints agrees with the
-- profession band and the game. Returns thresholds, rank (either may be nil).
function recipeView:skillProgress(recipeID)
    return playerScale(recipeID)
end

--[[
  Crafts until this recipe's next band boundary, for this character.

  Built on playerScale, so the character's profession bonus is applied by
  construction rather than by remembering to pass it - the bar and this count
  then read the same thresholds, which is the whole reason they belong to one
  owner.

  @param recipeID number
  @return number|nil - nil at grey, where there is no next boundary
]]
function recipeView:craftsToNextBand(recipeID)
    local thresholds, rank = playerScale(recipeID)
    local t = difficulty:transition(rank, thresholds)
    if not t or not t.toNext then return nil end
    return math.max(1, math.ceil(t.toNext / (recipeCatalog:skillUps(recipeID) or 1)))
end

-- The recipe's display icon: the created item's icon (what the player
-- expects to see); enchants produce no item, so they fall back to the
-- recipe's spell texture. Both are live lookups by ID.
function recipeView:icon(recipeID)
    local itemID = recipeCatalog:output(recipeID)
    local tex
    if itemID and itemID ~= 0 then
        tex = C_Item.GetItemIconByID(itemID)
    end
    return tex or C_Spell.GetSpellTexture(recipeID)
end

-- An item's name, from the client's own cache. Items reached through crafting
-- data are in cache by construction (they were named in a reagent line or a
-- conversion table the moment they were shown); a cold cache returns nil and
-- the caller shows the id's absence, not a placeholder.
function recipeView:itemName(itemID)
    return C_Item.GetItemNameByID(itemID)
end

-- A recipe THIS character knows that produces the item, with its profession:
-- the reagent-detour affordance. First known producer wins (multiple sources
-- for one item are rare and any known one serves).
function recipeView:knownProducerOf(itemID)
    local producers = recipeCatalog:producersOf(itemID)
    if not producers then return nil end
    for _, recipeID in ipairs(producers) do
        local profID = recipeCatalog:professionOf(recipeID)
        if profID and ledger:knowsRecipe(profID, recipeID) then
            return recipeID, profID
        end
    end
    return nil
end

-- The conversion route to an item, for a character who has the verb's
-- profession: pigments and gems are not crafted, they are milled and
-- prospected out of something. Returns the verb and its profession; the
-- SKILL to do it is the client's judgment at cast time, never ours.
function recipeView:conversionRouteTo(itemID)
    local sources = recipeCatalog:conversionSources(itemID)
    if not sources then return nil end
    local verb = sources[1].verb
    local info = recipeCatalog:conversionVerbInfo(verb)
    if not info then return nil end
    -- The live profession list is the truth for "do I have this at all";
    -- whether the skill is high enough for a given source is the client's
    -- judgment at cast time.
    -- Windowed only: the verb casts into a craftable window.
    for _, p in ipairs(Addon.professionHarvester:enumerate()) do
        if p.profID == info.profID and p.windowed then return verb, info.profID end
    end
    return nil
end

-- Format a remaining-seconds cooldown as a short duration, e.g. "2h 14m",
-- "1d 3h", "45s".
function recipeView:formatDuration(remaining)
    local d = math.floor(remaining / 86400)
    local h = math.floor((remaining % 86400) / 3600)
    local m = math.floor((remaining % 3600) / 60)
    local s = remaining % 60
    if d > 0 then
        return string.format("%dd %dh", d, h)
    elseif h > 0 then
        return string.format("%dh %dm", h, m)
    elseif m > 0 then
        return string.format("%dm", m)
    else
        return string.format("%ds", s)
    end
end

-- The wall-clock local time a cooldown becomes ready, from its absolute expiry,
-- phrased relative to today: just the time if it is ready today ("11:00 AM"),
-- "tomorrow" plus the time if the next day, or "in N days" plus the time when
-- further out. Day difference is by calendar day, not elapsed hours. The expiry
-- is rounded to the nearest minute first: a daily reset computed as
-- now+secondsUntilReset lands a few seconds shy of the whole minute, and we want
-- the real reset time (11:00 AM), not a truncated 10:59.
function recipeView:formatReadyClock(expiry)
    expiry = math.floor(expiry / 60 + 0.5) * 60
    local clock = date("%I:%M %p", expiry):gsub("^0", "")
    local today    = date("*t", time())
    local readyDay = date("*t", expiry)
    local startToday = time({ year = today.year,   month = today.month,   day = today.day,   hour = 0 })
    local startReady = time({ year = readyDay.year, month = readyDay.month, day = readyDay.day, hour = 0 })
    local days = math.floor((startReady - startToday) / 86400 + 0.5)

    if days <= 0 then
        return clock
    elseif days == 1 then
        return "Tomorrow at " .. clock
    end
    return ("in %d days at %s"):format(days, clock)
end

function recipeView:initialize()
    ledger        = Addon.ledger
    difficulty    = Addon.difficulty
    cooldownData  = Addon.cooldownData
    recipeCatalog = Addon.recipeCatalog
    if not ledger or not difficulty or not cooldownData or not recipeCatalog then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444recipeView: Missing dependencies|r")
        return false
    end
    return true
end

Addon.recipeView = recipeView

if Addon.registerModule then
    Addon.registerModule("recipeView", {"ledger", "difficulty", "cooldownData", "recipeCatalog", "professionHarvester"}, function()
        return recipeView:initialize()
    end)
end

return recipeView
