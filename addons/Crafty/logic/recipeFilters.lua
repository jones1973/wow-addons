--[[
  logic/recipeFilters.lua
  Crafty's built-in recipe filters

  Registers the filters that ship with Crafty into the filterRegistry. Each is a
  self-contained registration; adding or removing one here does not touch the
  window. Effect/stat search and profit/cost sorts will register here too once
  their data lands.

  Current filters:
    search     - multi-term text match over the recipe name (order-independent;
                 "potion int" requires both "potion" and "int" to appear). Built
                 to extend to reagent and effect text later.
    difficulty - keep only recipes that can still give a skill-up (better than
                 grey), the common leveling filter.
    cooldown   - show only recipes that have a cooldown by nature.

  Dependencies: filterRegistry, difficulty, cooldownData, recipeView, craftability, recipeCatalog
  Exports: (none; registers side-effects on initialize)
]]

local ADDON_NAME, Addon = ...

local recipeFilters = {}

-- Lowercase, split on whitespace into terms.
local function terms(query)
    local t = {}
    for word in string.gmatch(string.lower(query), "%S+") do
        t[#t + 1] = word
    end
    return t
end

function recipeFilters:initialize()
    local registry      = Addon.filterRegistry
    local difficulty    = Addon.difficulty
    local cooldownData  = Addon.cooldownData
    local recipeCatalog = Addon.recipeCatalog

    if not registry or not difficulty or not cooldownData or not recipeCatalog then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444recipeFilters: Missing dependencies|r")
        return false
    end

    -- Multi-term name search. All terms must be present (AND), order-independent.
    -- The searchable text is the recipe name for now; reagent and effect text
    -- get appended here when those land.
    registry:register({
        id    = "search",
        label = "Search",
        kind  = "search",
        order = 10,
        predicate = function(item, query)
            local haystack = string.lower(Addon.recipeView:name(item.id) or "")
            for _, term in ipairs(terms(query)) do
                if not string.find(haystack, term, 1, true) then
                    return false
                end
            end
            return true
        end,
    })

    -- Difficulty: keep recipes that can still skill up (anything not grey).
    registry:register({
        id    = "skillup",
        label = "Skill-ups",
        kind  = "toggle",
        order = 20,
        predicate = function(item)
            local band = Addon.recipeView:band(item.id)
            return band ~= "grey" and band ~= "unavailable"
        end,
    })

    -- Cooldown: only recipes that have a cooldown by nature.
    registry:register({
        id    = "cooldown",
        label = "Cooldowns",
        kind  = "toggle",
        order = 30,
        predicate = function(item)
            return cooldownData:hasCooldown(item.id) == true
        end,
    })

    -- Materials: only recipes the character can make from bags right now. Widens
    -- to bank/mail/alts/guild later by broadening the craftability source.
    registry:register({
        id    = "hasmats",
        label = "Craftable",
        kind  = "toggle",
        order = 40,
        predicate = function(item)
            -- REACHABLE, not fromBags: a recipe you lack only vendor thread
            -- for is one you can make today, and this filter answers what to
            -- work on rather than what a click would do right now.
            return Addon.craftability:reachable(item.id)
        end,
    })

    -- Sorts. Name and difficulty now; cost/profit register here once Auctionator
    -- data is wired, with no change to the window.
    registry:registerSort({
        id    = "name",
        label = "Name",
        order = 10,
        defaultDir = "asc",
        comparator = function(dir)
            if dir == "desc" then
                return function(a, b) return Addon.recipeView:name(a.id) > Addon.recipeView:name(b.id) end
            end
            return function(a, b) return Addon.recipeView:name(a.id) < Addon.recipeView:name(b.id) end
        end,
    })
    registry:registerSort({
        id    = "difficulty",
        label = "Difficulty",
        order = 20,
        defaultDir = "desc",
        comparator = function(dir)
            -- Sort by the recipe's skill level (learn rank from the catalog),
            -- then by each band boundary in turn: yellow, green, grey.
            --
            -- Two recipes learned at the same rank are not equally useful. The
            -- one whose yellow comes later keeps paying skill-ups longer, and
            -- breaking that tie on NAME sorted them alphabetically - which is
            -- to say arbitrarily, on the one axis the list exists to answer.
            --
            -- Later boundaries sort first in "desc", the levelling direction,
            -- so the recipe that stays orange longest leads its group. Name
            -- remains the final tie-break, for recipes identical in all four.
            local function keys(id)
                local c = recipeCatalog:colors(id)
                return recipeCatalog:learn(id) or math.huge,
                       c and c[2] or 0, c and c[3] or 0, c and c[4] or 0
            end
            return function(a, b)
                local la, ya, ga, ka = keys(a.id)
                local lb, yb, gb, kb = keys(b.id)
                if la ~= lb then
                    if dir == "desc" then return la > lb end
                    return la < lb
                end
                if ya ~= yb then
                    if dir == "desc" then return ya > yb end
                    return ya < yb
                end
                if ga ~= gb then
                    if dir == "desc" then return ga > gb end
                    return ga < gb
                end
                if ka ~= kb then
                    if dir == "desc" then return ka > kb end
                    return ka < kb
                end
                return Addon.recipeView:name(a.id) < Addon.recipeView:name(b.id)
            end
        end,
    })

    return true
end

if Addon.registerModule then
    Addon.registerModule("recipeFilters",
        { "filterRegistry", "difficulty", "cooldownData", "recipeView", "craftability", "recipeCatalog" }, function()
            return recipeFilters:initialize()
        end)
end

return recipeFilters
