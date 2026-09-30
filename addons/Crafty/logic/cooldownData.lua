--[[
  logic/cooldownData.lua
  Crafty static recipe cooldowns

  Knows which recipes have a cooldown BY NATURE, from DB2 data (via
  recipeCatalog), independent of whether a cooldown is currently active.

  This exists because the live trade-skill API has a blind spot: it reports the
  remaining time of an ACTIVE cooldown, but reports nothing for a cooldown that
  is ready. So a ready daily-cooldown recipe looks identical to a recipe with no
  cooldown at all. The static data closes that gap - Crafty can show a recipe is
  a cooldown recipe before it has ever been crafted, and while it is ready.

  Each entry is { hours, flags, sharedCat }:
    hours     - rolling cooldown length in hours; 0 for a daily regional reset
    flags     - bitmask: CD_DAILY_RESET (0x1), CD_SHARED (0x2)
    sharedCat - shared cooldown-category id; 0 when not shared. Recipes with the
                same non-zero sharedCat share ONE timer (crafting one puts the
                others on cooldown).
  A recipe absent from the table has no cooldown by nature.

  Dependencies: recipeCatalog
  Exports: Addon.cooldownData
]]

local ADDON_NAME, Addon = ...

local cooldownData = {}

local recipeCatalog

-- Flag bits in the data's `flags` field.
local CD_DAILY_RESET = 0x1
local CD_SHARED      = 0x2

-- Bitwise AND for flag tests. MoP/TBC Lua 5.1 has no bitwise operators and the
-- flags are small, so a simple modulo-based test suffices for single bits.
local function hasBit(value, bit)
    return value % (bit + bit) >= bit
end

-- Whether a recipe has a cooldown by nature (present in the static data).
function cooldownData:hasCooldown(recipeID)
    return recipeCatalog:cooldown(recipeID) ~= nil
end

-- The recipe's rolling cooldown length in SECONDS, or nil if it has none (either
-- no cooldown at all, or a daily reset which has no fixed duration). Seconds to
-- match the live cooldown values Crafty works in.
function cooldownData:durationSeconds(recipeID)
    local entry = recipeCatalog:cooldown(recipeID)
    if not entry then return nil end
    local hours = entry.hours
    if not hours or hours <= 0 then return nil end
    return hours * 3600
end

-- Whether the recipe's cooldown is a daily regional reset (vs a rolling timer).
function cooldownData:isDailyReset(recipeID)
    local entry = recipeCatalog:cooldown(recipeID)
    return entry ~= nil and hasBit(entry.flags, CD_DAILY_RESET)
end

-- Whether the recipe shares one cooldown timer with others in its category.
function cooldownData:isShared(recipeID)
    local entry = recipeCatalog:cooldown(recipeID)
    return entry ~= nil and hasBit(entry.flags, CD_SHARED)
end

-- The shared cooldown-category id (nil if the recipe does not share a timer).
function cooldownData:sharedCategory(recipeID)
    local entry = recipeCatalog:cooldown(recipeID)
    if not entry then return nil end
    local cat = entry.sharedCat
    if not cat or cat == 0 then return nil end
    return cat
end

-- All cooldown recipe ids belonging to a profession (skillLine). The cooldown
-- data is not keyed by profession, so we resolve each recipe's profession via
-- the catalog - the recipe->profession fact lives in the recipe data, not
-- duplicated here. Returns an array of recipeIDs.
function cooldownData:recipesForProfession(skillLine)
    local out = {}
    for _, recipeID in ipairs(recipeCatalog:cooldownRecipeIDs()) do
        if recipeCatalog:professionOf(recipeID) == skillLine then
            out[#out + 1] = recipeID
        end
    end
    return out
end

function cooldownData:initialize()
    recipeCatalog = Addon.recipeCatalog
    if not recipeCatalog then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444cooldownData: Missing dependencies|r")
        return false
    end
    return true
end

Addon.cooldownData = cooldownData

if Addon.registerModule then
    Addon.registerModule("cooldownData", {"recipeCatalog"}, function()
        return cooldownData:initialize()
    end)
end

return cooldownData
