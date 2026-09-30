--[[
  logic/recipeScanner.lua

  The single "read the open trade-skill window into recipe records" operation.
  Given a trade-skill window that is already open (the harvester opened it and
  knows which profession it is), scan every recipe row and write the results
  through the ledger's set interface. This module reads the game; the ledger only
  stores.

  Profession identity (profID, name, rank, category) is PASSED IN by the
  caller - it opened the window and is the authority on which profession this is
  (on MoP GetTradeSkillLine does not reliably return the skill-line id).

  Reagents, output, and made-quantity come only from the legacy index API
  (GetNumTradeSkills / GetTradeSkillInfo / GetTradeSkill*). The legacy list
  interleaves category headers with recipes, so headers are skipped. Each
  recipe's id is parsed from its recipe link; everything is keyed on that id.

  Dependencies: events, ledger, constants
  Exports: Addon.recipeScanner
]]

local ADDON_NAME, Addon = ...

local events, ledger, constants

-- Parse a recipeID out of a trade-skill recipe link.
-- MoP recipe links are |cff...|Henchant:RECIPEID|h[name]|h|r.
local function recipeIDFromLink(link)
    return tonumber(link:match("enchant:(%d+)"))
end

-- Parse an itemID out of an item link (reagent or output). A nil link is a
-- legitimate state: enchanting recipes produce an enchantment, not an item, so
-- GetTradeSkillItemLink returns nil for them - return nil, stored as "no item".

local recipeScanner = {}

--[[
  Scan the open profession window. Resets the profession's stored state, then
  records every recipe. Emits RECIPES_SCANNED with the count.

  @param profID number, name string, rank number, category string
  @return boolean - true if the scan captured every recipe GetAllRecipeIDs lists
]]
function recipeScanner:scanOpen(profID, name, rank, category)
    -- Never scan a linked window: it is another player's tradeskill shown via a
    -- chat link, and its recipes are not ours to record. Fires the same
    -- TRADE_SKILL_SHOW as a real open, so guard at the write point.
    if C_TradeSkillUI.IsTradeSkillLinked() then return false end

    -- Reset Blizzard's own trade-skill filters before reading. Any active filter
    -- makes GetNumTradeSkills/GetTradeSkillInfo return only the matching subset,
    -- producing a partial scan (recipes appear "missing" until a later rescan with
    -- filters clear). Each gates the visible list independently.
    SetTradeSkillSubClassFilter(0, 1, 1)   -- all subclasses (category filter)
    SetTradeSkillInvSlotFilter(0, 1, 1)    -- all inventory slots
    SetTradeSkillItemNameFilter("")        -- the search box
    SetTradeSkillItemLevelFilter(0, 0)     -- item level range
    TradeSkillOnlyShowSkillUps(false)      -- "only show skill-ups" toggle
    TradeSkillOnlyShowMakeable(false)      -- "only show what I can make" toggle

    -- Gather every recipe into a local buffer WITHOUT touching the ledger yet.
    -- The ledger is committed only once the scan is verified complete, so a
    -- partial read (index list still populating) never wipes good stored data.
    local numSkills = GetNumTradeSkills()
    local scanned = {}          -- ordered list of { recipeID, facts, cooldownExpiry }
    local recordedIDs = {}

    for i = 1, numSkills do
        local skillType = select(2, GetTradeSkillInfo(i))

        -- Only recipe rows matter: category headers/subheaders have no link, and
        -- a nil link marks a non-recipe (empty/placeholder) row. Both are skipped
        -- by processing only rows that are neither a header nor linkless.
        local isHeader = skillType == "header" or skillType == "subheader"
        local link = not isHeader and GetTradeSkillRecipeLink(i) or nil
        if link then
            local recipeID = recipeIDFromLink(link)
            recordedIDs[recipeID] = true

            -- The scan records only what is TRUE OF THIS CHARACTER: that it knows
            -- this recipe, and the recipe's live cooldown. Everything else about a
            -- recipe (reagents, output, icon, description, difficulty) is either a
            -- game constant shipped in the catalog's static tables or derivable live from
            -- the recipeID, so none of it is harvested or stored here.
            local cd = GetTradeSkillCooldown(i)
            scanned[#scanned + 1] = {
                recipeID       = recipeID,
                cooldownExpiry = cd and (cd + time()) or nil,
                -- The colour the CLIENT is showing, and the row it is on. Both
                -- are already in hand here - the loop reads skillType for the
                -- header test and the link for the id - and both were being
                -- discarded. Keeping them lets the band check compare without a
                -- second walk, and lets a later check read one row directly
                -- instead of rebuilding links to find it.
                skillType      = skillType,
                index          = i,
            }
        end
    end

    -- Completeness: GetAllRecipeIDs() is the authoritative recipe-ID set for the
    -- open profession (independent of the index list's load state). If any id it
    -- lists was not seen, the index list was still populating - an incomplete
    -- read. Do NOT commit it: leave existing stored data intact and report
    -- incomplete, so a later TRADE_SKILL_UPDATE can drive a full rescan.
    local authoritative = C_TradeSkillUI.GetAllRecipeIDs() or {}

    for _, id in ipairs(authoritative) do
        if not recordedIDs[id] then
            events:emit(constants.EVENT.RECIPES_SCANNED,
                { count = 0, prof = profID, complete = false })
            return false
        end
    end

    -- Complete: commit the buffer atomically (reset, then record all).
    ledger:beginProfessionScan(profID, name, rank, category)
    for _, rec in ipairs(scanned) do
        ledger:recordKnownRecipe(profID, rec.recipeID, rec.cooldownExpiry)
    end

    -- The scanned rows travel with the event: they carry the client's colour
    -- and the row each recipe sits on, both read during the walk above. A
    -- consumer that wants either gets it without walking the list again.
    events:emit(constants.EVENT.RECIPES_SCANNED,
        { count = #scanned, prof = profID, complete = true, rows = scanned })
    return true
end

Addon.recipeScanner = recipeScanner

if Addon.registerModule then
    Addon.registerModule("recipeScanner", {"events", "ledger"}, function()
        events = Addon.events
        ledger = Addon.ledger
        constants = Addon.constants
    end)
end
