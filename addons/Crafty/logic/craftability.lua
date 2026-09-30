--[[
  logic/craftability.lua
  Crafty Craftability Calculations

  Composes the catalog's and ledger's read APIs into "how many can I make"
  answers. The catalog and ledger hold facts; this module computes. No frames, no rendering - pure logic that
  the crafting window consumes.

  Build 1 computes craftable-from-bags only (current character's live bags).
  Account-wide pooled mode is a later build; the math here is written so adding
  it is a different source filter, not a different algorithm.

  Dependencies: ledger, recipeCatalog
  Exports: Addon.craftability
]]

local ADDON_NAME, Addon = ...

local craftability = {}

local ledger, recipeCatalog

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  How many times a recipe can be crafted from the current character's bags.

  Gated by reagents: for each required reagent, how many crafts its on-hand
  count supports (floor of have/need); the answer is the minimum across all
  reagents. A recipe with no reagents recorded returns 0 (we cannot confirm
  craftability without knowing its inputs).

  This is the count of CRAFTS, not output items. Output quantity (which may be
  a range) is a separate question answered by recipeCatalog:output.

  @param recipeID number
  @return number - how many times the recipe can be crafted from bags
]]
-- A reagent a vendor sells at unlimited stock for gold is not a constraint on
-- whether a recipe can be made - it is an errand. Holding no Refreshing Spring
-- Water should not read as "cannot craft" when the answer is to walk to a
-- A plain fact about the reagent, not a decision about it: whether a vendor
-- sells it at unlimited stock for gold. The callers differ on what to DO with
-- that - one lists a recipe anyway, one marks a row - so each states its own
-- question rather than sharing a name for the answer.
local function vendorSold(reagent)
    return (Addon.data.vendorReagents or {})[reagent.item] ~= nil
end

--[[
  Whether this recipe is workable once the vendor errands are run.

  Vendor reagents are excluded because buying thread is an errand, not a
  constraint: a recipe you lack only thread for is one you can make today, and
  a planning question - "what could I be working on" - should say so.

  Contrast fromBags, which counts what the bags hold. These are not two counts -
  they are a filter and a count, and the filter is the only thing that ever
  wants a vendor errand overlooked.

  A BOOLEAN because the caller is a filter: it decides whether a recipe is
  listed, and nothing downstream wants a number from it. fromBags is where the
  count lives, and it counts every reagent - including the vendor ones, which
  are in the bags or they are not like anything else.

  @param recipeID number
  @return boolean
]]
function craftability:reachable(recipeID)
    local reagents = recipeCatalog:reagents(recipeID)
    if not reagents or #reagents == 0 then return false end

    for _, reagent in ipairs(reagents) do
        -- A vendor reagent never blocks listing: buying thread is an errand,
        -- and a recipe waiting only on an errand is one to work on today.
        if not vendorSold(reagent) then
            local have = ledger:getItemCount(reagent.item)
            if (have.bags or 0) < (reagent.count or 1) then return false end
        end
    end
    return true
end

function craftability:fromBags(recipeID)
    local reagents = recipeCatalog:reagents(recipeID)
    if not reagents or #reagents == 0 then
        return 0
    end

    -- EVERY reagent, vendor-sold included. The question is what the bags hold,
    -- and thread you have not bought is thread you do not have - a recipe whose
    -- reagents are all vendor-sold has 581 counterparts in the catalog, and
    -- every one of them answered with a ceiling nobody could back up rather
    -- than with what was in the bags.
    local minCrafts
    for _, reagent in ipairs(reagents) do
        local have = ledger:getItemCount(reagent.item)   -- current char, optional charKey omitted
        local onHand = have.bags or 0
        local need = reagent.count or 1
        local possible = math.floor(onHand / need)
        if minCrafts == nil or possible < minCrafts then
            minCrafts = possible
        end
    end

    return minCrafts or 0
end

--[[
  Per-reagent breakdown for display: what each reagent needs vs what is on hand
  in bags. Lets the window show which reagent is the limiting factor.

  @param recipeID number
  @return table - array of { item, need, haveBags }
]]
function craftability:reagentBreakdown(recipeID)
    local reagents = recipeCatalog:reagents(recipeID)
    local out = {}
    for _, reagent in ipairs(reagents) do
        local have = ledger:getItemCount(reagent.item)
        out[#out + 1] = {
            id       = reagent.item,   -- itemID; serves as the row identity
            -- PER CRAFT. What the recipe takes is a property of the recipe, and
            -- multiplying it by the order size changes what the row means -
            -- "Thorium Setting 36/10" then claims the recipe needs ten when it
            -- needs one. How far the bags stretch is a different question, and
            -- "Can make from bags" is where it is answered.
            need     = reagent.count or 1,
            haveBags = have.bags or 0,
            -- The row still shows what you hold; the flag is how it says the
            -- shortfall does not matter. Omitting the reagent instead would
            -- make the panel disagree with the recipe it is describing.
            vendor   = vendorSold(reagent) or nil,
        }
    end
    return out
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function craftability:initialize()
    ledger = Addon.ledger
    recipeCatalog = Addon.recipeCatalog

    if not ledger or not recipeCatalog then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444craftability: Missing dependencies|r")
        return false
    end

    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("craftability", {"ledger", "recipeCatalog"}, function()
        return craftability:initialize()
    end)
end

Addon.craftability = craftability
return craftability
