--[[
  logic/cooldownSweep.lua
  Crafty login cooldown sweep

  At login, reads the character's professions and records which cooldown recipes
  are currently active - WITHOUT needing a harvest or the user ever opening
  Crafty. Cooldown state is keyed to professions, and the set of cooldown recipes
  is a small static list (recipeCatalog:cooldownRecipeIDs), so we only need:
      professions (GetProfessions/GetProfessionInfo)  x  the CD recipes for them
  and a C_Spell.GetSpellCooldown read per recipe.

  This is what makes cross-character cooldowns work: log into any alt and its
  daily cooldowns are captured into the shared store, so another character can
  see them, with no harvest and no window ever opened on that alt.

  Cooldowns only change mid-session when the player crafts one, which goes
  through Crafty (the crafter records its own crafts), so a single sweep per
  login is sufficient - no per-profession re-sweep, no event sentry.

  Profession data is not ready immediately after login, so the sweep runs on
  SKILL_LINES_CHANGED (the same readiness signal the harvester uses) and guards
  against running before professions resolve.

  Dependencies: events, ledger, cooldownData
  Exports: Addon.cooldownSweep
]]

local ADDON_NAME, Addon = ...

local cooldownSweep = {}

local events, ledger, cooldownData

-- Whether this session has already completed a successful sweep.
local sweptThisSession = false

-- Read C_Spell.GetSpellCooldown for a recipe and return its absolute expiry
-- (time() value) if active, else nil. C_Spell.GetSpellCooldown is the modern
-- API and returns a table: { startTime, duration, isEnabled, isActive, ... }.
-- start/duration are GetTime()-based; convert to an absolute time() expiry so it
-- survives across sessions.
local function activeExpiry(recipeID)
    local info = C_Spell.GetSpellCooldown(recipeID)
    if not info then return nil end
    local remaining = info.duration - (GetTime() - info.startTime)
    if remaining <= 0 then return nil end

    -- A daily-reset recipe's cooldown ends at the next daily reset, not N hours
    -- from the craft - so its expiry is the reset boundary, not the rolling
    -- remaining the client reports. (The cooldown read above only tells us THAT
    -- it is on cooldown; our data says it is a daily reset, and the boundary is
    -- the truth.)
    if cooldownData:isDailyReset(recipeID) then
        return time() + C_DateAndTime.GetSecondsUntilDailyReset()
    end

    return time() + remaining
end

--[[
  Sweep the current character's professions for active cooldown recipes and
  record them. Returns true if professions were available (a real sweep ran),
  false if profession data was not ready yet.
]]
function cooldownSweep:run()
    -- Windowed only: a cooldown belongs to a recipe, and a gathering skill has
    -- none. The harvester reports every profession the character has; which of
    -- them can be opened is a field on the record, not an absence from the list.
    local profs = {}
    for _, prof in ipairs(Addon.professionHarvester:enumerate()) do
        if prof.windowed then profs[#profs + 1] = prof end
    end
    local sawAny = false

    for _, prof in ipairs(profs) do
        sawAny = true
        local recipes = cooldownData:recipesForProfession(prof.profID)
        for _, recipeID in ipairs(recipes) do
            local expiry = activeExpiry(recipeID)
            -- Store active expiries; clear stale ones that have lapsed.
            ledger:setCooldown(prof.profID, recipeID, expiry)
        end
    end

    if sawAny then
        sweptThisSession = true
        events:emit("COOLDOWNS:SWEPT", {})
    end
    return sawAny
end

function cooldownSweep:initialize()
    events = Addon.events
    ledger = Addon.ledger
    cooldownData = Addon.cooldownData

    if not events or not ledger or not cooldownData then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444cooldownSweep: Missing dependencies|r")
        return false
    end

    -- Profession data loads slightly after login; SKILL_LINES_CHANGED fires when
    -- it is ready (and on later skill changes). Sweep once per session, on the
    -- first fire that yields usable professions.
    events:subscribe("SKILL_LINES_CHANGED", function()
        if not sweptThisSession then
            self:run()
        end
    end)

    -- After a craft, the just-crafted recipe's cooldown is NOT yet readable -
    -- the client reports stale data until the trade-skill window settles, which
    -- it signals with TRADE_SKILL_UPDATE. So on CRAFT:COMPLETE, arm a one-shot
    -- watch: when TRADE_SKILL_UPDATE lands, sweep (now the new cooldown, and any
    -- shared-category siblings locked with it, read correctly) and tear the watch
    -- down. No timer, no polling - the settle event drives it.
    events:subscribe("CRAFT:COMPLETE", function()
        local watchID
        watchID = events:subscribe("TRADE_SKILL_UPDATE", function()
            events:unsubscribe(watchID)
            self:run()
        end)
    end)

    return true
end

Addon.cooldownSweep = cooldownSweep

if Addon.registerModule then
    Addon.registerModule("cooldownSweep", { "events", "ledger", "cooldownData", "professionHarvester" }, function()
        return cooldownSweep:initialize()
    end)
end

return cooldownSweep
