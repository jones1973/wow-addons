--[[
  logic/professionProgress.lua
  Where a character stands in a PROFESSION, and what is worth walking toward.

  The recipe bar answers "how much longer is this one worth crafting". This
  answers "where am I going, and what do I get next" - a different scope, which
  is why it belongs in a footer spanning the frame rather than beside the recipe.

  SCALE. Reported rank throughout, 1 to the profession's CEILING - not to
  GetProfessionInfo's maxRank, which is only the current tier's cap. That cap is
  still reported, as `cap`: it is a hard stop skill will not pass until the next
  tier is trained, which is a fact worth drawing rather than a scale. A level-1
  character reads 75 there, and a bar drawn to it would show a road that ends at
  the first milestone. The ceiling is the ladder: every tier is 75 skill, so it
  is 75 x however many tiers the flavor has, plus the character's skill bonus
  because their whole scale is shifted by it.

  Recipe learn requirements gate on the reported rank too (trainer-confirmed),
  so nothing here needs the trained-skill conversion the difficulty thresholds
  do.

  MILESTONES. All tier unlocks - they give the bar its structure and are
  uniform across professions - plus the next recipe you could learn. Nine marks
  at most.

  ACTIONABLE. A recipe only counts if reaching that rank actually gets you
  something: a trainer teaches it, you already hold the teaching item, or a
  vendor sells it. A drop or a discovery is not reached by crafting to a number.

  BEHIND THE MARKER. A recipe whose requirement you passed and never picked up
  is the answer to "why am I not getting skill-ups", so those are counted too.

  Dependencies: recipeCatalog, ledger, professionHarvester
  Exports: Addon.professionProgress
]]

local ADDON_NAME, Addon = ...

local catalog, ledger, harvester

local professionProgress = {}

-- Whether reaching a rank actually gets you this recipe. A trainer is always
-- there; an item only counts when you hold it, which is a live question the
-- bags answer; a vendor is an errand rather than a wish, so it counts but is
-- worth showing as its own thing.
-- Every tier is 75 skill, so the ceiling is the length of the ladder. Derived
-- rather than written down: TBC's ladder is shorter than MoP's, and a constant
-- would be one more thing to remember on a flavor change.
local TIER_SPAN = 75

local function actionable(recipeID)
    if catalog:trainers(recipeID) then return "trainer" end
    for _, path in ipairs(catalog:paths(recipeID) or {}) do
        if path.kind == "item" and path.item then
            if GetItemCount(path.item, true) > 0 then return "held" end
            if path.from == "vendor" then return "vendor" end
        end
    end
    return nil
end

--[[
  The footer's whole model for one profession.

  @param profID number - skill-line id
  @return table|nil - {
      profName,                            -- for the tier requirement line
      rank, cap, ceiling,                  -- reported. cap is the CURRENT
                                           -- tier's ceiling and a real wall;
                                           -- ceiling is the ladder's end.
      tiers   = { {rank, level, spell}, ... },  -- every tier, ascending
      next    = { rank, names = {...} },   -- soonest actionable unlock, or nil
      missed  = { { recipeID, rank, how, name }, ... },  -- passed, unlearned
  }
]]
function professionProgress:forProfession(profID)
    local rank, cap, bonus
    for _, prof in ipairs(harvester:enumerate()) do
        if prof.profID == profID then
            rank, cap, bonus = prof.rank, prof.maxRank, prof.bonus
        end
    end
    if not rank then return nil end

    -- Whole records, not just ranks: a tier tick names itself and states both
    -- of its gates, and the spell is what carries the name ("Artisan First Aid"
    -- comes from GetSpellInfo, so no tier-name table is needed here).
    local tiers = {}
    for _, t in ipairs((Addon.data.professionTiers or {})[profID] or {}) do
        tiers[#tiers + 1] = { rank = t.rank, level = t.level, spell = t.spell }
    end
    local ceiling = #tiers * TIER_SPAN + bonus

    local nextAt, nextNames, missed = nil, nil, {}
    for _, recipeID in ipairs(catalog:recipesIn(profID)) do
        local learn = catalog:learn(recipeID)
        if learn and learn > 0 and catalog:isEligible(recipeID) then
            local how = actionable(recipeID)
            if how then
                if learn > rank then
                    -- Soonest first, and a rank can carry more than one recipe.
                    if not nextAt or learn < nextAt then
                        nextAt, nextNames = learn, {}
                    end
                    if learn == nextAt then
                        nextNames[#nextNames + 1] = GetSpellInfo(recipeID) or recipeID
                    end
                elseif not ledger:knowsRecipe(profID, recipeID) then
                    missed[#missed + 1] = { recipeID = recipeID, rank = learn,
                                            how = how,
                                            name = GetSpellInfo(recipeID) or recipeID }
                end
            end
        end
    end

    return {
        rank = rank, cap = cap, ceiling = ceiling, tiers = tiers,
        profName = ledger:getProfessionName(profID),
        next = nextAt and { rank = nextAt, names = nextNames } or nil,
        missed = missed,
    }
end

function professionProgress:initialize()
    catalog   = Addon.recipeCatalog
    ledger    = Addon.ledger
    harvester = Addon.professionHarvester
    return true
end

if Addon.registerModule then
    Addon.registerModule("professionProgress",
        {"recipeCatalog", "ledger", "professionHarvester"},
        function()
            return professionProgress:initialize()
        end)
end

Addon.professionProgress = professionProgress
return professionProgress
