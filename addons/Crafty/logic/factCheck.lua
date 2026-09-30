--[[
  logic/factCheck.lua
  Reality check: the game is the third witness.

  Passively compares what the client shows against what the static data
  claims, in both directions - observed-but-unexpected AND expected-but-
  missing. Inconsistencies chat once and accumulate in crafty_factcheck;
  the SV export feeds the merge pipeline (design/merge_recipe_data.py) as
  ground truth, so the static data self-corrects through play.

  Observation points:
    - trainer windows: every service with its state (available / known /
      gated) vs our learn level and source. Absence is judged only against
      the tiers THIS window displayed - the list grows with skill and
      expansion gates, so one visit is never the whole picture.
    - source gaps: a recipe the shipped data gives no source for, learned or
      offered from an OBSERVED origin, is a mismatch worth announcing - the
      observation is the missing fact. Only an unattributable learn is left
      unrecorded, having taught nothing.
    - rank chains: their own invariants - ascending learn levels, and a
      superseded rank must not be offered once a later one is known
    - skill-ups: every point recolours the whole list. A band that moves at a
      rank our ramp did not predict names that boundary exactly - the only
      channel that observes the RAMP rather than the orange.
    - level gates and item paths: a trainer states a character-level
      requirement, and a teaching item states its own skill requirement.
      Both are independently checkable facts about the same recipe.
    - band crossings: every observed tier transition is logged with the rank
      it happened at, the ground truth for where the client draws each boundary
    - recipe learns: HOW (trainer / item [which] / discovery / unknown) and
      at what skill and level, vs the predicted class and learn
    - trainer quests: a quest offered while a trainer is engaged (the
      Training Project gate is this shape)

  Every observation stores character level and skill: when a trainer list
  grows, the stored context explains why.

  SV shape (design/reality-check.md): enumerated kinds; expected/observed
  share field names; flat context; repeats bump count, never append.

  Dependencies: events, ledger, recipeCatalog, crafter,
                professionHarvester, utils, constants
  Exports: Addon.factCheck
]]

local ADDON_NAME, Addon = ...

local factCheck = {}

local events, ledger, catalog, crafter, harvester, utils, constants, difficulty, theme

local store              -- crafty_factcheck (svRegistry-created)
-- The services of the trainer you are STANDING AT - true until you walk away,
-- which is why only TRAINER_CLOSED clears it. It outlives the evaluation that
-- first needed it: captureOrigin asks it whether this trainer offers a recipe
-- you just learned, and a learn happens long after the settle timer has run.
local trainerSnapshot
local trainerTimer       -- settles the snapshot while the window is still up
local rankChainOf        -- forward: used by evaluateTrainer
local evaluateTrainer    -- forward: the settle timer in captureTrainer calls it
local lastTeachCast      -- { spellID, guid } - a live item-use teach-cast,
                         -- recorded at START, consumed by the learn it produces

local TRAINER_SOURCE   = 6
local DISCOVERY_SOURCE = 7
-- Crafty-assigned, outside Wowhead's numbering: granted with the profession.
local GRANT_SOURCE     = 100
-- Item-delivered sources: Wowhead codes that all mean "taught by an item you
-- obtain" (design/merge_recipe_data.py WH_SOURCE - drop, quest, vendor, world,
-- questreward, instance). A learn from any of them surfaces at runtime as
-- how=item, so all map to the single observed class "item". Kept as a set,
-- because a recipe's source is a set: a design that drops AND is sold AND is
-- trained is one recipe with three codes, and a learn matching any is expected.
local ITEM_SOURCES = { [1]=true, [2]=true, [4]=true, [5]=true, [16]=true,
                       [21]=true, [22]=true }
-- Game state during a transition is mid-write: a burst of learns, a trainer
-- list mid-update. Evaluation waits this long after the last event so it
-- compares against settled state.
local SETTLE_SEC       = 1.0

-- ============================================================================
-- STORE
-- ============================================================================

-- Record an observation, deduplicated by identity. First sighting chats.
-- Kinds whose subject is an ITEM rather than a recipe spell: a conversion
-- yield is a fact about the herb or ore that was consumed.
local ITEM_SUBJECT = {
    ["conversion-yield-outside-range"] = true,
}

-- The expected-source set as a stable, readable string: sorted keys joined,
-- e.g. {trainer,item} -> "item/trainer". Used in both the confirmation line and
-- the mismatch findings so a pasted line names every source the data allows.
local function expectedKeys(set)
    local keys = {}
    for k in pairs(set or {}) do keys[#keys + 1] = k end
    table.sort(keys)
    return table.concat(keys, "/")
end

-- A positive confirmation: the game did exactly what the data said it could.
-- Distinct from observe in two ways - it is not a finding, so it never enters
-- the observations store, and it does not interrupt (chat, not notify). It
-- exists because item-path attribution was invisible until the teach-cast was
-- captured before the learn; a matching item-learn is now worth SEEING, to
-- confirm the recorded paths are real, without treating it as a defect.
local function confirm(kind, recipeID, expected, observed)
    local name = recipeID and (GetSpellInfo(recipeID) or ("spell " .. recipeID)) or "?"
    local prof = recipeID and catalog:professionOf(recipeID) or nil
    local where = (prof and ledger:getProfessionName(prof)) or ""
    local parts = {}
    for _, side in ipairs({ { "expected", expected }, { "observed", observed } }) do
        local bits = {}
        for k, v in pairs(side[2] or {}) do
            bits[#bits + 1] = k .. "=" .. tostring(v)
        end
        table.sort(bits)
        if #bits > 0 then
            parts[#parts + 1] = side[1] .. " " .. table.concat(bits, " ")
        end
    end
    utils:chat(theme.derive.inline(theme.tokens.STATE.SUCCESS,
               "fact check [" .. kind .. "] " .. name
             .. (recipeID and (" (" .. recipeID .. ")") or "")
             .. (where ~= "" and (" [" .. where .. "]") or "")
             .. (#parts > 0 and (": " .. table.concat(parts, ", ")) or "")))
end

local function observe(kind, recipeID, expected, observed, source)
    -- The key is built from the expected fields as sorted name=value pairs.
    -- Encoding the NAMES, not just the values, is what makes it stable: two
    -- findings are the same key iff they carry the same fields with the same
    -- values. Appending bare values (name-sorted) instead silently changed the
    -- key whenever a field was renamed - {class=trainer,learn=135} and
    -- {source=trainer,learn=135} serialised to "trainer:135" vs "135:trainer",
    -- storing one logical finding under two rows across versions.
    local key = kind .. ":" .. tostring(recipeID or 0)
    local names = {}
    for k in pairs(expected or {}) do names[#names + 1] = k end
    table.sort(names)
    for _, k in ipairs(names) do
        key = key .. ":" .. k .. "=" .. tostring(expected[k])
    end
    local obs = store.observations[key]
    if obs then
        obs.count = obs.count + 1
        obs.lastSeen = time()
        return
    end
    local isItem = ITEM_SUBJECT[kind] or false
    local prof = (not isItem) and recipeID and catalog:professionOf(recipeID) or nil
    store.observations[key] = {
        kind = kind, spell = (not isItem) and recipeID or nil,
        item = isItem and recipeID or nil, prof = prof,
        expected = expected, observed = observed, source = source,
        char = ledger:currentCharKey(),
        level = UnitLevel("player"),
        skill = ledger:skillIn(prof),
        count = 1, firstSeen = time(), lastSeen = time(),
    }
    -- The chat line carries the values, not just the name: a pasted line
    -- should be enough to act on without looking anything up.
    local name = recipeID and (isItem and (GetItemInfo(recipeID) or ("item " .. recipeID))
                               or GetSpellInfo(recipeID)) or "?"
    local parts = {}
    for _, side in ipairs({ { "expected", expected }, { "observed", observed } }) do
        local bits = {}
        for k, v in pairs(side[2] or {}) do
            bits[#bits + 1] = k .. "=" .. tostring(v)
        end
        table.sort(bits)
        if #bits > 0 then
            parts[#parts + 1] = side[1] .. " " .. table.concat(bits, " ")
        end
    end
    -- Where it was seen belongs in the line: the profession whose data is
    -- being questioned and the NPC that said otherwise. Without them a
    -- pasted finding invites guessing at which profession it came from.
    local where = (prof and ledger:getProfessionName(prof)) or ""
    -- The NAME here, not the id: a pasted line is read by a person. The id is
    -- what the store and the catalog lookups use, so both travel on `source`.
    local who = source and (source.npcName or source.npc)
    if who then
        where = where .. (where ~= "" and " @ " or "@ ") .. who
    end
    -- notify rather than chat: findings are worth interrupting for, and a
    -- long crafting session scrolls them past unnoticed otherwise.
    utils:notify(theme.derive.inline(theme.tokens.STATE.DANGER,
                 "fact check [" .. kind .. "] " .. name
               .. (recipeID and (" (" .. recipeID .. ")") or "")
               .. (where ~= "" and (" [" .. where .. "]") or "")
               .. (#parts > 0 and (": " .. table.concat(parts, ", ")) or "")))
end

-- ============================================================================
-- NAME INDEX (player's professions only; built lazily, rebuilt on learn/unlearn)
-- ============================================================================

-- The spell ID behind a trainer service. The service list is index-based and
-- GetTrainerServiceInfo returns only text, but the service tooltip knows the
-- spell: GetSpell returns (name, spellID) on this client. An identity, not an
-- inference.
local scanTip
local function serviceSpellID(index)
    if not scanTip then
        scanTip = CreateFrame("GameTooltip", "CraftyFactCheckTip",
                              nil, "GameTooltipTemplate")
        scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    end
    scanTip:ClearLines()
    scanTip:SetTrainerService(index)
    return select(2, scanTip:GetSpell())   -- (name, spellID)
end

-- The recipe a trainer service refers to: its spell ID, from the service
-- tooltip. An identity, not an inference.
local function resolveService(svc)
    return svc.spellID
end

local function hasSource(recipeID, code)
    local s = catalog:sources(recipeID)
    if not s then return false end
    for _, v in ipairs(s) do if v == code then return true end end
    return false
end

-- ============================================================================
-- TRAINER WINDOWS
-- ============================================================================

-- ============================================================================
-- RANK CHAINS
-- ============================================================================

-- The recipe this one replaces, or nil. Rank chains (Lightweave Embroidery I
-- -> II -> III, the Spellthreads, the Leg Reinforcements) are shipped as a
-- supercedes edge on the progression row.
rankChainOf = function(recipeID)
    return catalog:supercedes(recipeID)
end

-- Rank chains have their own invariants, and a trainer window is where they
-- are visible: the trainer offers exactly the rank you are eligible for.
--   - a superseded rank offered while a LATER rank is already known is wrong
--   - the chain's learn levels must ascend
local function checkRankChains(snapshot)
    local knownLater = {}
    for recipeID in catalog:eachRecipeID() do
        local prev = rankChainOf(recipeID)
        if prev then
            local prof = catalog:professionOf(recipeID)
            if prof and ledger:knowsRecipe(prof, recipeID) then
                knownLater[prev] = recipeID
            end
            -- Perk recipes (Socket Bracer, the Spellthreads) carry a
            -- placeholder learn of 1 - their real gate is MinSkillLineRank,
            -- a different number in a different field. Comparing that against
            -- a predecessor's real learn compares two unlike things.
            local a, b = catalog:learn(prev), catalog:learn(recipeID)
            if a and b and a > 1 and b > 1 and b <= a then
                observe("rank-chain-order", recipeID,
                    { learn = b, after = a }, { ascending = false },
                    { how = "data" })
            end
        end
    end
    for _, svc in ipairs(snapshot.services) do
        -- "used" means the trainer is DISPLAYING it as already known; only
        -- "available" is an offer. A known earlier rank shown greyed out is
        -- the trainer being informative, not a contradiction.
        local recipeID = svc.state == "available" and resolveService(svc)
        if recipeID and knownLater[recipeID] then
            observe("rank-chain-superseded-offered", recipeID,
                { offered = false, because = "later rank known" },
                { offered = true, state = svc.state },
                { how = "trainer", npc = snapshot.npc,
                  npcName = snapshot.npcName })
        end
    end
end

-- ============================================================================
-- TRAINER WINDOWS
-- ============================================================================

-- Capture the open trainer's service list. Every service carries its
-- availability state - the trainer shows what you can buy now, what you
-- already know, and what is still gated - and each state is evidence about a
-- different claim, so all three are captured.
--
-- One window is never the whole picture: the list grows as skill and
-- expansion gates open, so a single visit's absence proves nothing. Absence
-- is only judged against what THIS window could have shown (see
-- evaluateTrainer).
-- Headers this visit collapsed, so the window can be handed back as it was
-- found. Cleared on TRAINER_CLOSED with the snapshot.
local collapsedByUs
local filteredByUs   -- service-type filters we turned on, to put back
local capturedThisOpen   -- per-open: the authoritative snapshot for this trainer
                         -- open has been built and its evaluation scheduled.
                         -- One open yields one complete snapshot; later updates
                         -- in the same open (notably the filter-restore echo) do
                         -- not rebuild it. Reset on TRAINER_SHOW (a new open) so
                         -- a missed TRAINER_CLOSED cannot carry it across visits.

local function captureTrainer()
    if not GetNumTrainerServices then return end
    local n = GetNumTrainerServices()
    if not n or n == 0 then return end

    -- A trainer's list carries only what is EXPANDED. Jack "All-Trades"
    -- Derrington teaches nine professions and shows one at a time, so a capture
    -- of the list as displayed sees a fraction of what he offers - which read as
    -- 94 recipes missing rather than 94 recipes not asked about.
    --
    -- Expand everything, note what we opened, and put it back after the
    -- evaluation: unfolding nine professions is a visible change to the
    -- player's window, and it is ours to undo. ExpandTrainerSkillLine fires
    -- TRAINER_UPDATE, which re-enters here - collapsedByUs already being set is
    -- what stops that recursing, and the settle timer restarting on each update
    -- is what makes the LAST pass the one that evaluates.
    -- The list is FILTERED before it is walked. The trainer window hides
    -- "used" and "unavailable" services by whatever the player last chose, so a
    -- walk of it sees what they can learn RIGHT NOW rather than what the
    -- trainer teaches - and a recipe already known then reads as one the
    -- trainer does not offer.
    --
    -- All three shown, noted, and put back after the evaluation, exactly as the
    -- collapsed headers are: this is the player's window and the change is ours
    -- to undo.
    if not filteredByUs and SetTrainerServiceTypeFilter then
        filteredByUs = {}
        for _, kind in ipairs({ "available", "unavailable", "used" }) do
            local on = GetTrainerServiceTypeFilter and GetTrainerServiceTypeFilter(kind)
            if not on then
                -- BOOLEAN, not 1. The docs describe a 0/1 flag and note the
                -- getter now returns a boolean; this client rejects the number
                -- outright with "Missing on/off parameter".
                --
                -- Recorded AFTER the call, so a filter we failed to turn on is
                -- not one we later turn off - that would hide a category the
                -- player had chosen to see.
                SetTrainerServiceTypeFilter(kind, true)
                filteredByUs[kind] = true
                filteredByUs.n = (filteredByUs.n or 0) + 1
            end
        end
        if filteredByUs.n then
            return   -- the resulting TRAINER_UPDATE captures the full list
        end
    end

    if not collapsedByUs and ExpandTrainerSkillLine then
        collapsedByUs = {}
        for i = 1, n do
            local name, _, category, isExpanded = GetTrainerServiceInfo(i)
            if category == "header" and not isExpanded then
                -- By NAME: indices shift as the list expands, so an index
                -- recorded now names a different row afterwards.
                collapsedByUs[name] = true
                collapsedByUs.n = (collapsedByUs.n or 0) + 1
            end
        end
        if collapsedByUs.n then
            ExpandTrainerSkillLine(0)   -- 0 = every header
            return                       -- the resulting TRAINER_UPDATE captures
        end
    end

    -- Setup (filters cleared, headers expanded) is complete when execution
    -- reaches here. The authoritative snapshot for this open is built exactly
    -- once: a later update in the same open - in particular the TRAINER_UPDATE
    -- the filter-restore fires - must not rebuild it from the now-restored
    -- (filtered) window, which would drop already-known services and drive a
    -- second evaluation against an incomplete list. One open, one snapshot.
    if capturedThisOpen then return end

    n = GetNumTrainerServices()
    -- The NPC's ID, not its name: the catalog keys trainers by id, and two
    -- trainers in different cities share a name often enough that a name is
    -- not an identity. GUID form is "Creature-0-<server>-<instance>-<zone>-<id>-<spawn>".
    local guid = UnitGUID("npc") or UnitGUID("target")

    local npcID = guid and tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)"))
    trainerSnapshot = { services = {}, npc = npcID,
                        npcName = UnitName("npc") or UnitName("target") }
    for i = 1, n do
        local name, _, category = GetTrainerServiceInfo(i)
        if name and category ~= "header" then
            local svc = { name = name, state = category,   -- available|used|unavailable
                          spellID = serviceSpellID(i) }
            if GetTrainerServiceSkillReq then
                local _, req = GetTrainerServiceSkillReq(i)
                svc.skillReq = req
            end
            if GetTrainerServiceLevelReq then
                svc.levelReq = GetTrainerServiceLevelReq(i)
            end
            trainerSnapshot.services[#trainerSnapshot.services + 1] = svc
        end
    end

    -- Evaluate while the window is STILL OPEN, once its updates stop. A
    -- trainer list settles by finishing its updates, not by closing - and
    -- findings are only useful while you can still look at what produced
    -- them. (TRAINER_CLOSED is also not guaranteed on every dismissal path,
    -- which would strand the snapshot unevaluated.)
    if trainerTimer then trainerTimer:Cancel() end
    trainerTimer = C_Timer.NewTimer(SETTLE_SEC, function()
        trainerTimer = nil
        evaluateTrainer()
    end)
    -- Marked at SCHEDULE time, not evaluate time: a capture arriving between the
    -- schedule and the timer firing must also find this open already captured.
    capturedThisOpen = true
end

-- Clear everything scoped to one trainer visit. Called at the start of a new
-- open (TRAINER_SHOW) and when a visit ends (TRAINER_CLOSED). One owner for
-- "what a trainer cycle holds", so the two call sites cannot drift apart.
local function resetTrainerCycle()
    if trainerTimer then
        trainerTimer:Cancel()
        trainerTimer = nil
    end
    trainerSnapshot = nil
    collapsedByUs = nil
    filteredByUs = nil
    capturedThisOpen = nil
end

-- What a vendor actually has on the shelf, right now.
--
-- The only source for this. DB2 links a teaching item forever whether or not
-- anyone still sells it, and no column tells the two apart (PATTERNS.md, worked
-- negative); the scrape names the vendor but carries no stock, because stock
-- lives on the ITEM's page and the crawl fetches recipe pages. The merchant
-- window is the game answering directly.
--
-- numAvailable is -1 for unlimited stock and a count for limited. That
-- distinction exists nowhere else we hold, so it is recorded whether or not
-- anything disagrees.
local function captureMerchant()
    if not GetMerchantNumItems then return end
    local n = GetMerchantNumItems()
    if not n or n == 0 then return end

    local guid = UnitGUID("npc") or UnitGUID("target")
    local npcID = guid and tonumber(guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)"))
    if not npcID then return end

    store.vendors = store.vendors or {}
    local rec = store.vendors[npcID]
    if not rec then
        rec = { sells = {} }
        store.vendors[npcID] = rec
    end
    rec.name = UnitName("npc") or UnitName("target")
    rec.seen = time()

    for i = 1, n do
        local link = GetMerchantItemLink(i)
        local itemID = link and tonumber(link:match("item:(%d+)"))
        local recipeID = itemID and catalog:taughtByItem(itemID)
        if recipeID then
            local _, _, price, _, numAvailable, _, _, extendedCost, currencyID =
                GetMerchantItemInfo(i)

            -- extendedCost is only a FLAG that the price is not just gold. The
            -- cost itself - which token, which currency, how many - comes from
            -- GetMerchantItemCostItem, and that is the interesting case: an
            -- alt-currency vendor is a gated one, which is the same question
            -- the stock count exists to answer. Blizzard's own frame reads it
            -- exactly this way to draw the icons.
            local costs
            if extendedCost and GetMerchantItemCostInfo then
                for c = 1, GetMerchantItemCostInfo(i) do
                    local _, value, costLink, currencyName = GetMerchantItemCostItem(i, c)
                    if value then
                        costs = costs or {}
                        costs[#costs + 1] = {
                            item = costLink and tonumber(costLink:match("item:(%d+)")) or nil,
                            currency = currencyName,
                            qty = value,
                        }
                    end
                end
            end

            rec.sells[itemID] = { recipe = recipeID, price = price,
                                  stock = numAvailable, currency = currencyID,
                                  costs = costs }

            -- Two different findings, and only one is a disagreement.
            --
            -- A path that names NO vendor is a gap: 226 of the 1,018 vendor
            -- item paths carry no fromID, so "we do not know who sells this"
            -- is common and this window is the answer to it. Recorded in the
            -- store above, silent - new information, not a contradiction.
            --
            -- A path naming a DIFFERENT vendor is a contradiction, and that
            -- one is worth saying out loud.
            --
            -- Absence is not the mirror of either: stock rotates and gates
            -- exist, so a recipe we attribute here and do not see on the shelf
            -- is a question, and is left alone.
            local named
            for _, path in ipairs(catalog:paths(recipeID) or {}) do
                if path.kind == "item" and path.item == itemID and path.fromID then
                    named = path.fromID
                end
            end
            if named and named ~= npcID then
                observe("vendor-mismatch", recipeID,
                    { fromID = named },
                    { sells = itemID },
                    { how = "vendor", npc = npcID, npcName = rec.name })
            end
        end
    end
end

-- Evaluate the settled snapshot when the trainer closes. Only MISMATCHES are
-- recorded: a listed recipe whose learn level or class agrees with the shipped
-- data is the expected case and says nothing worth keeping.
evaluateTrainer = function()
    if not trainerSnapshot then return end
    local listed = {}
    -- The professions this trainer window is actually SHOWING, gathered from the
    -- services it listed. A trainer window displays one profession's services at
    -- a time; a recipe the catalog attributes to this NPC but from a profession
    -- the window is not showing is not "missing" - it is simply not on screen.
    -- Without this, a corrupt cross-profession attribution (Wowhead has copied
    -- whole catalogues onto the wrong NPC) makes every off-screen recipe read as
    -- missing - 120 Alchemy false positives at an Engineering trainer.
    local shownProfessions = {}

    for _, svc in ipairs(trainerSnapshot.services) do
        -- A trainer sells more than recipes: profession ranks, class
        -- abilities, riding skill. Only spells the catalog carries are
        -- claims this module has anything to say about.
        local recipeID = resolveService(svc)
        local prof = recipeID and catalog:professionOf(recipeID)
        if prof then
            listed[recipeID] = svc
            shownProfessions[prof] = true
            local learn = catalog:learn(recipeID)
            local src = { how = "trainer", npc = trainerSnapshot.npc,
                          npcName = trainerSnapshot.npcName }

            -- The trainer states ITS learn level. For a recipe with two
            -- acquisition paths - a teaching item AND a trainer - the item's
            -- requirement and the trainer's are both real and differ by
            -- design (the item gates a whole tier, the trainer gates each
            -- recipe). Our orange is the earliest path, so a trainer stating
            -- something HIGHER is the expected shape, not a mismatch. Only a
            -- trainer teaching EARLIER than our orange contradicts us.
            if svc.skillReq and learn and learn > 0 and svc.skillReq < learn then
                observe("trainer-learn-mismatch", recipeID,
                    { learn = learn },
                    { skillReq = svc.skillReq, levelReq = svc.levelReq }, src)
            end

            -- A trainer stating LATER than our learn is only expected when some
            -- other path is the earlier one. With no path but this trainer,
            -- there is nothing to be earlier and the two numbers describe the
            -- same fact, so any difference is a real disagreement.
            local trainerOnly = catalog:trainers(recipeID) ~= nil
                                and catalog:paths(recipeID) == nil
            if svc.skillReq and learn and learn > 0 and trainerOnly
                    and svc.skillReq ~= learn then
                observe("trainer-only-disagrees", recipeID,
                    { learn = learn }, { skillReq = svc.skillReq }, src)
            end

            -- A recipe can have no orange band at all: it becomes available at
            -- a skill past where orange would have ended (Smelt Tin, bands
            -- 40/57/75, trained at 50), so its orange threshold is legitimately
            -- absent and the comparison above has nothing to test. The trainer
            -- still gates it, and that gate is the only statement anywhere of
            -- the skill it takes to acquire - DB2's MinSkillLineRank is unset
            -- for these, and the scrape captures a trainer as an npc id alone.
            -- One value per recipe: a recipe's requirement is the same at every
            -- trainer that teaches it.
            if svc.skillReq and (not learn or learn == 0) then
                observe("trainer-skill-req", recipeID,
                    { source = "trainer" }, { skillReq = svc.skillReq }, src)
            end

            -- The trainer is the only source that states a character-level
            -- gate. Ours must agree, and a gate we do not carry at all is
            -- the finding that puts it in the data.
            local lreq = catalog:levelReq(recipeID)
            if (svc.levelReq or 0) ~= (lreq or 0) then
                observe("level-req-mismatch", recipeID,
                    { levelReq = lreq or 0 },
                    { levelReq = svc.levelReq or 0 }, src)
            end
            -- A trainer offering it is proof of the trainer source, and both
            -- ways the shipped data can be wrong are findings: naming no
            -- source at all, or naming one that excludes trainers.
            local srcs = catalog:sources(recipeID)
            if not srcs or #srcs == 0 then
                -- A trainer is selling it and our data names no source: the
                -- window just answered the open question.
                observe("source-unknown-observed", recipeID,
                    { source = "none" }, { source = "trainer" }, src)
            elseif not hasSource(recipeID, TRAINER_SOURCE) then
                observe("trainer-source-mismatch", recipeID,
                    { source = "not-trainer" }, { source = "trainer" }, src)
            end
        end
    end

    -- Expected-but-missing, gated on THIS trainer actually teaching the recipe
    -- AND on the window currently showing that recipe's profession.
    --
    -- A recipe names the trainers that teach it (captured paths); if this NPC is
    -- among them but the recipe is not on the trainer's live list, that is a
    -- real anomaly. A recipe taught only by OTHER trainers is expected to be
    -- absent here - that was the old false positive (Oakpaw flagged for recipes
    -- taught by the Pandaria smelt trainers). A recipe whose paths were never
    -- captured is in no trainer's set, so it stays silent rather than being
    -- guessed at.
    --
    -- A trainer shows what it teaches regardless of what you know - a character
    -- who has never learned Cooking sees Fielding Chesterhill's full ladder,
    -- Apprentice through Zen Master, every recipe red. So an absence here is a
    -- real absence, checkable without holding the profession, PROVIDED the list
    -- was expanded first - which captureTrainer does before snapshotting - and
    -- PROVIDED the window is showing that profession. An empty shown-set (a
    -- trainer that listed no recipe services at all) is no basis to call
    -- anything missing, so nothing is flagged.
    for _, recipeID in ipairs(catalog:recipesTaughtBy(trainerSnapshot.npc)) do
        if not listed[recipeID]
                and shownProfessions[catalog:professionOf(recipeID)]
                and catalog:isEligible(recipeID)
                and not rankChainOf(recipeID)
                and not ledger:knowsRecipe(catalog:professionOf(recipeID), recipeID) then
            observe("trainer-missing", recipeID,
                { source = "trainer", learn = catalog:learn(recipeID) },
                { listed = false }, { how = "trainer",
                                      npc = trainerSnapshot.npc,
                                      npcName = trainerSnapshot.npcName })
        end
    end

    checkRankChains(trainerSnapshot)

    -- Hand the window back as it was found. Collapsing a header removes its
    -- children from the list, so every index after it shifts - walking BACKWARDS
    -- means the indices still ahead of the cursor are the ones that have not
    -- moved yet.
    if collapsedByUs and collapsedByUs.n and CollapseTrainerSkillLine then
        for i = GetNumTrainerServices(), 1, -1 do
            local name, _, category, isExpanded = GetTrainerServiceInfo(i)
            -- Only the ones WE opened. A header the player had expanded before
            -- we arrived stays expanded.
            if category == "header" and isExpanded and collapsedByUs[name] then
                CollapseTrainerSkillLine(i)
            end
        end
        collapsedByUs = {}   -- restored; not nil, or the next update re-expands
    end

    -- And the filters we turned on, for the same reason.
    if filteredByUs and filteredByUs.n and SetTrainerServiceTypeFilter then
        for _, kind in ipairs({ "available", "unavailable", "used" }) do
            if filteredByUs[kind] then SetTrainerServiceTypeFilter(kind, false) end
        end
        filteredByUs = {}   -- restored; not nil, or the next update re-clears
    end
end

-- ============================================================================
-- TIER MISMATCH (piggybacks the scanner's completed, filter-neutral list)
-- ============================================================================

-- Every skill point is a measurement on every known recipe at once: the game
-- recolours the list, and a recipe that changes band when our ramp says it
-- should not - or fails to when it should - pins that boundary exactly. This
-- is the only channel that observes the RAMP; trainers only ever state the
-- orange.
--
-- A crossing is reported with the rank it happened at, which IS the boundary
-- value: orange -> yellow at rank N means yellow is N.
-- Every band transition is logged verbatim - recipeID, the rank it happened
-- at, and the from/into bands. Nothing derivable from the recipeID is emitted
-- (colors, boundaries, DB2 fields are all joined offline); the log carries
-- only the live-client facts that cannot be reconstructed after the fact. The
-- crossing rank IS the boundary the client actually used, which is the one
-- thing DB2 cannot state.
-- ============================================================================
-- DIFFICULTY BANDS
-- ============================================================================

--[[
  Our band against the colour the client is showing.

  THREE PARTS, EACH PAYING ITS OWN WAY.

  1. AT SCAN. The scanner already walks every row, reading skillType for the
     header test and the link for the recipe id. Both were discarded; it now
     carries them on RECIPES_SCANNED, so comparing all of them here costs one
     table pass and no client calls at all.

  2. DURING A CRAFT. Nothing. A crossing is arithmetic - our stored thresholds
     against a rank that changed - so it never touches the trade-skill window.
     Its predecessor walked the live list on every TRADE_SKILL_UPDATE, which
     fires per craft, and raced Blizzard's repeat into stopping early.

  3. AFTER THE ORDER. Only the recipes whose band actually moved, read directly
     by the row the scan recorded. One GetTradeSkillInfo each, no link building,
     no walk.

  The row map is invalidated by a learn: a new recipe shifts every index after
  it, and reading a stale row would compare the wrong recipe's colour.
]]

-- The client's own word for a recipe's difficulty: GetTradeSkillInfo's second
-- return, and the skillType the scanner already reads.
local CLIENT_BAND = { optimal = "orange", medium = "yellow",
                      easy = "green", trivial = "grey" }

local rowOf         -- recipeID -> live list index, from the last scan
local bandAt        -- recipeID -> our band when last examined
local lastRank = {} -- profID -> rank at the last measurement
local movedDuringOrder

local function ourBand(recipeID)
    return Addon.recipeView:band(recipeID)
end

local function compare(recipeID, shown, rank)
    local ours = ourBand(recipeID)
    if ours and shown and ours ~= shown then
        -- The thresholds travel with the finding. Two colour names say only
        -- that something disagrees; the numbers say WHERE the boundary sits in
        -- our data and what rank it was judged at, which is the whole content
        -- of the disagreement.
        local c = catalog:colors(recipeID)
        observe("band-mismatch", recipeID,
            { band = ours,
              bands = c and string.format("%d/%d/%d/%d", c[1], c[2], c[3], c[4]) },
            { band = shown, rank = rank },
            { how = "tradeskill" })
    end
end

-- 1. Everything, from rows the scan already read.
local function checkScannedBands(profID, rows)
    -- profID indexes lastRank below, and a nil index is a hard error rather
    -- than a miss. The scan always carries one, but this reads it from an event
    -- payload and a table write is not the place to find out otherwise.
    if not rows or not profID then return end
    local rank = ledger:skillIn(profID)
    -- Seed the skill-up baseline here: without it the first craft after a scan
    -- has nothing to measure a delta against and would be skipped.
    lastRank[profID] = rank
    rowOf, bandAt = {}, {}
    for _, r in ipairs(rows) do
        rowOf[r.recipeID] = r.index
        bandAt[r.recipeID] = ourBand(r.recipeID)
        if rank and rank > 0 then
            compare(r.recipeID, CLIENT_BAND[r.skillType], rank)
        end
    end
end

--[[
  What a craft actually granted, against skillupCnt.

  The gain is the rank delta across SKILL_LINES_CHANGED, and the recipe is
  whatever the open order is crafting. No client call: both are already held.

  EVERY BAND, and the band is recorded. A gain of ZERO is not a finding and
  never reaches here anyway: SKILL_LINES_CHANGED only fires when the number
  moves, so a craft that granted nothing produces no event at all. Zero is bad
  luck, which orange will not see and yellow mostly will not.

  A gain of 1 where 2, 5 or 10 was due is the finding - that is the open
  question, whether a recipe worth more in orange still pays it at yellow, and
  if not, where it stops and whether it stops consistently.

  TrinityCore applies NumSkillUps unscaled - the band decides IF, never HOW MUCH
  - so any band granting less than skillupCnt contradicts the server code we
  have, and any band granting the full amount confirms it. Both are worth
  recording, so the observation carries the band rather than being filtered by
  it.
]]
local function checkSkillUpAmount(profID)
    local rank = ledger:skillIn(profID)
    local was = lastRank[profID]
    lastRank[profID] = rank
    if not rank or not was or rank <= was then return end

    local recipeID = Addon.crafter:currentRecipe()
    if not recipeID then return end

    local expect = catalog:skillUps(recipeID) or 1
    local gained = rank - was
    local band = ourBand(recipeID)

    -- A gain LARGER than one craft grants means the client coalesced two crafts
    -- into one update. Neither craft is in question, so it is not a finding.
    if gained > expect then return end

    -- Keyed by band as well as recipe, so the same recipe reports once per band
    -- rather than once ever - which is what makes the decay visible.
    if gained < expect then
        observe("skillup-amount", recipeID,
            { granted = expect, band = band },
            { granted = gained, rank = rank },
            { how = "tradeskill" })
    end
end

-- 2. Free: which of OUR bands moved while crafting. No client calls.
local function noteBandMovement(profID)
    if not bandAt then return end
    movedDuringOrder = movedDuringOrder or {}
    for recipeID, was in pairs(bandAt) do
        local now = ourBand(recipeID)
        if now ~= was then
            movedDuringOrder[recipeID] = true
            bandAt[recipeID] = now
        end
    end
end

-- 3. Only what moved, read by its recorded row.
local function checkMovedBands(profID)
    if not movedDuringOrder or not rowOf then return end
    local rank = ledger:skillIn(profID)
    if not rank or rank <= 0 or not GetTradeSkillInfo then
        movedDuringOrder = nil
        return
    end
    for recipeID in pairs(movedDuringOrder) do
        -- Absent from the map when the recipe was learned after the last scan:
        -- the learn drops the map, and a band can move before the next scan
        -- rebuilds it.
        local idx = rowOf[recipeID]
        if idx then
            -- CONFIRM the row is still this recipe before believing its colour.
            -- The index was cached at scan time and the list reshapes under it -
            -- a collapsed header, a filter, anything that changes what sits
            -- where - and a stale index reports another recipe's colour under
            -- this recipe's name. One link read per MOVED recipe, and few move.
            local link = GetTradeSkillRecipeLink(idx)
            if link and tonumber(link:match("enchant:(%d+)")) == recipeID then
                local _, skillType = GetTradeSkillInfo(idx)
                compare(recipeID, CLIENT_BAND[skillType], rank)
            end
        end
    end
    movedDuringOrder = nil
end

-- ============================================================================
-- LEARNS: HOW, AND AT WHAT SKILL
-- ============================================================================

-- Deferred evaluation. Learns arrive in bursts (a profession grant hands over
-- its whole starter set at once) and DURING a burst the game state is
-- mid-write: the profession itself may not be registered yet, so rank reads
-- as unknown and every comparison against it is against a torn state. The
-- queue drains SETTLE_SEC after the last arrival, when the state is whole -
-- and the burst's shape is itself evidence, since a profession appearing
-- alongside the recipes identifies them as its grant.
local pending = {}          -- recipeID -> attribution captured at arrival
local pendingTimer
local professionSet         -- profID set, refreshed on SKILL_LINES_CHANGED

local function snapshotProfessions()
    local set = {}
    for _, prof in ipairs(harvester:enumerate()) do set[prof.profID] = true end
    return set
end

-- What the game showed us about where this recipe came from. Captured at
-- ARRIVAL because the evidence is perishable - a trainer window closes, a
-- craft ages out - while the comparison it feeds happens later.
-- Ordered by strength of evidence, not by convenience.
--
-- A teach-cast is DIRECT: UNIT_SPELLCAST_SUCCEEDED fired with the teaching
-- item's own spell id, which is the game naming the thing that taught you. An
-- open trainer window is CIRCUMSTANTIAL - a window being up says nothing about
-- what taught you - so a recipe used from the bags while a trainer happens to
-- be open must not be filed as trainer-taught.
--
-- And the trainer branch tests the trainer's own service list rather than the
-- frame's visibility: "this trainer offers this recipe" is evidence, "a trainer
-- window is open" is a coincidence. The list is already captured.
local function trainerOffers(recipeID)
    -- The frame check is load-bearing, not belt-and-braces: TRAINER_CLOSED is
    -- not guaranteed on every dismissal path, so the snapshot can outlive the
    -- visit. With the window shut, whatever it still holds describes a trainer
    -- you walked away from and must not answer for a later learn.
    if not (ClassTrainerFrame and ClassTrainerFrame:IsShown()) then return false end
    if not trainerSnapshot then return false end
    for _, svc in ipairs(trainerSnapshot.services) do
        if svc.spellID == recipeID then return true end
    end
    return false
end

local function captureOrigin(recipeID)
    -- Ordered by strength of evidence, and to be robust to same-frame event
    -- races. A trainer that OFFERS this recipe with its window open is a
    -- positive statement about this recipe - checked first, so a lingering
    -- teach-cast can never mislabel a trainer learn as an item one. A live
    -- teach-cast (an item-use spell started, recorded at START before the
    -- learn) NAMES the item; presence is the signal, not recency, so there is
    -- no window to expire - the ~2.8s item-use cast that outran the old window
    -- is now read correctly. It is consumed on read, so one cast answers one
    -- learn. A craft in progress is the weakest - only a coincidence in time -
    -- so it comes last.
    if trainerOffers(recipeID) then
        return { how = "trainer" }
    elseif lastTeachCast then
        local item = lastTeachCast.spellID
        lastTeachCast = nil
        return { how = "item", item = item }
    elseif crafter:recentlyCrafted() then
        -- A craft in progress is the weakest evidence here: it says only that
        -- something was being made when this arrived, not that the craft taught
        -- it. The discovery relation is the thing that actually knows - a
        -- recipe listed there IS discoverable, and one that is not was taught by
        -- something else that happened to coincide with a craft.
        --
        -- Reported either way by the pool check below, which is where the
        -- relation is consulted - the relation is incomplete (it covers
        -- Alchemy, Inscription and Engineering, and nothing for Blacksmithing),
        -- so a learn with no recorded pool is a finding rather than a
        -- contradiction.
        return { how = "discovery" }
    end
    return { how = "unknown" }
end

local function evaluateLearn(recipeID, source, grantedProf)
    local prof = catalog:professionOf(recipeID)
    -- The reported rank: learning gates on it, so a skill bonus lets a character
    -- learn a recipe that many points before their trained skill reaches its
    -- stated requirement. The requirement itself does not move.
    local rank = ledger:skillIn(prof)
    local learn = catalog:learn(recipeID)
    local how = source.how

    -- A profession appearing in the same burst is certain, not inferred: the
    -- recipes it brought are its grant. This outranks the timing-correlation
    -- guesses above.
    if grantedProf and prof == grantedProf then
        how = "profession-grant"
    end

    -- A recipe cannot be learnable above the rank that just learned it.
    if rank and rank > 0 and learn and learn > rank then
        observe("learn-above-rank", recipeID,
            { learn = learn }, { rank = rank }, source)
    end

    -- Learned from an item: the item path has its own requirement, and the
    -- rank that just used it cannot be below it.
    local ireq = catalog:itemReq(recipeID)
    if how == "item" and ireq and rank and rank > 0 and ireq > rank then
        observe("item-req-above-rank", recipeID,
            { itemReq = ireq }, { rank = rank }, source)
    end

    -- A level gate we know about must have been met.
    local lreq = catalog:levelReq(recipeID)
    if lreq and UnitLevel("player") < lreq then
        observe("level-gate-passed-below-req", recipeID,
            { levelReq = lreq }, { level = UnitLevel("player") }, source)
    end

    -- A discovery outside the recorded pool. The discovery relation comes from
    -- Blizzard's server data, but the emulator dumps record each discoverer's
    -- OWN tier only - Scroll of Wisdom lists 37 glyphs and overlaps the
    -- Northrend and Minor pools by zero - while players report that the pools
    -- nest and a Scroll can produce any unlearned Inscription glyph. One of
    -- those is wrong, and a discovery landing outside the recipe's recorded
    -- discoverers is the observation that says which.
    if how == "discovery" then
        local pools = catalog:discoveredFrom(recipeID)
        local cast  = Addon.crafter:currentRecipe()
        if not pools then
            observe("discovery-outside-pool", recipeID,
                { pool = "none recorded" }, { cast = cast, rank = rank },
                { how = how })
        elseif cast then
            -- The skill case (from == 0) is any discovery-capable craft of the
            -- profession, so it matches whatever was cast. A named discoverer
            -- has to BE the thing cast.
            local matched
            for _, p in ipairs(pools) do
                if p.from == 0 or p.from == cast then matched = true end
            end
            if not matched then
                observe("discovery-outside-pool", recipeID,
                    { pool = pools[1].from },
                    { cast = cast, rank = rank },
                    { how = how })
            end
        end
    end

    -- The expected source is a SET, not a single class: a recipe carries every
    -- code that can teach it, and a learn is only a contradiction when the way
    -- it happened is outside that set. Collapsing to one class (trainer winning
    -- by priority) mis-flags the legitimate ways - a design that both drops and
    -- is trained, learned from the drop, read as "expected trainer, got item".
    local expected = {}   -- set of expected `how` values
    local codes = catalog:sources(recipeID)
    if codes then
        for _, code in ipairs(codes) do
            if code == TRAINER_SOURCE then expected.trainer = true
            elseif code == DISCOVERY_SOURCE then expected.discovery = true
            elseif code == GRANT_SOURCE then expected["profession-grant"] = true
            elseif ITEM_SOURCES[code] then expected.item = true end
        end
    end
    -- A profession grant is certain from the burst even when the data carries no
    -- grant code, so an observed grant is always expected.
    expected["profession-grant"] = expected["profession-grant"]
        or (how == "profession-grant") or nil

    local haveExpectation = next(expected) ~= nil

    if not haveExpectation then
        -- Our data names no source and the game just demonstrated one. Only an
        -- unattributable learn teaches nothing.
        if how ~= "unknown" then
            observe("source-unknown-observed", recipeID,
                { source = "none" }, { source = how, rank = rank },
                { how = how, item = source.item })
        end
    elseif how == "unknown" then
        -- We expected a specific source (or set) and the game gave us nothing to
        -- match it against - the attribution failed, distinct from a mismatch.
        observe("source-expected-observed-unknown", recipeID,
            { class = expectedKeys(expected), learn = learn },
            { how = how, rank = rank }, { how = how, item = source.item })
    elseif not expected[how] then
        observe("learned", recipeID,
            { class = expectedKeys(expected), learn = learn },
            { how = how, rank = rank }, { how = how, item = source.item })
    else
        -- Observed source is within the recipe's recorded set: the learn
        -- happened exactly as the data says it could. A positive confirmation -
        -- the item-path attribution that was invisible until the START capture,
        -- now visible and matching.
        confirm("learned-as-recorded", recipeID,
            { class = expectedKeys(expected) },
            { how = how, item = source.item, rank = rank })
    end
end

local function drainPending()
    pendingTimer = nil
    local before = professionSet
    professionSet = snapshotProfessions()
    local granted
    for profID in pairs(professionSet) do
        if before and not before[profID] then granted = profID end
    end
    local discovered = false
    for recipeID, source in pairs(pending) do
        if source.how == "discovery" then discovered = true end
        evaluateLearn(recipeID, source, granted)
    end
    -- A discovery is an event, not a per-recipe fact: one cue marks it however
    -- many recipes the craft yielded. The tradeskill UI plays nothing on
    -- discovery, so this is the only feedback. 888 is LEVELUP, verified present
    -- in the 5.5.4 SoundKit table (the retail recipe-learned kit 73919 does not
    -- exist on this client - PlaySound returned nil for it).
    if discovered then PlaySound(888) end
    pending = {}
end

local function queueLearn(recipeID)
    pending[recipeID] = captureOrigin(recipeID)
    if pendingTimer then pendingTimer:Cancel() end
    pendingTimer = C_Timer.NewTimer(SETTLE_SEC, drainPending)
end

-- ============================================================================
-- CONVERSION YIELDS (milling, prospecting)
-- ============================================================================

-- The next rank at which any known recipe changes band, and what changes there.
--
-- Mining only, and only when you opened it yourself. That is the whole scope
-- rather than a volume compromise. A
-- crafting profession only gains skill at the window, so every crossing is
-- observed as it happens and announcing the next one tells you nothing you will
-- not be handed. Mining rises while gathering, with nothing watching, so it is
-- the only profession where being told where to stop changes what gets seen:
-- sit at boundary-1 with Crafty open, take a single point, read the line.
--
-- Thresholds are in the player's scale, so the rank announced is the rank the
-- game will report.
local BOUNDARY_BAND = { "yellow", "green", "grey" }
local WATCHED_PROF  = 186   -- Mining

local function announceNextBoundary(profID)
    if profID ~= WATCHED_PROF then return end
    -- A sweep opens and scans every profession in turn. This line addresses the
    -- player about the profession in front of them, so it must not fire for one
    -- the harvester merely walked past on its way through.
    if harvester:isSweeping() then return end
    local rank, bonus = ledger:skillIn(profID)
    if not rank then return end

    local at, what = nil, nil
    for _, recipeID in ipairs(ledger:getKnownRecipes(profID)) do
        local thresholds = difficulty:thresholds(catalog:colors(recipeID),
                                                 catalog:learn(recipeID), bonus)
        for i = 1, #BOUNDARY_BAND do
            local v = thresholds and thresholds[i + 1]
            if v and v > rank then
                if not at or v < at then at, what = v, {} end
                if v == at then
                    what[#what + 1] = (GetSpellInfo(recipeID) or recipeID)
                                      .. " -> " .. BOUNDARY_BAND[i]
                end
            end
        end
    end
    if not at then return end
    utils:chat("NEXT " .. at .. " (stop at " .. (at - 1) .. "): " .. table.concat(what, ", "))
end

-- The shipped per-proc quantities come from Wowhead's sampling, and MoP
-- Classic does not necessarily match it: the 2014 server data, Wowhead, and
-- the live game have each been seen to disagree. Only the game is
-- authoritative, so every mill and prospect is checked against the range we
-- ship and anything outside it is reported with the value observed.
local lastConversion   -- { source = itemID, verb = "Milling", at = GetTime() }
local reportConversionYield   -- forward: noteConversion closes the open tally

-- Called by the detail panel as a conversion is cast: the source item is
-- known there and nowhere else afterwards.
function factCheck:noteConversion(sourceItemID)
    -- A new cast closes the previous one's tally. The settle timer would
    -- otherwise keep being pushed back by the next cast's loot and merge two
    -- casts into one total - which reads as a yield far above the range
    -- instead of a normal pair of casts.
    if reportConversionYield then reportConversionYield() end

    local entry = catalog:conversionResults(sourceItemID)
    lastConversion = { source = sourceItemID, at = GetTime(),
                       verb = entry and entry.verb or "conversion" }
end

--[[
  Loot arriving just after a conversion cast is that cast's yield.

  ACCUMULATED, then judged. One cast's yield of a single result arrives as
  SEVERAL loot messages - a mill of Silkweed reads "x2", "x2", "1" - and each
  message alone falls outside the shipped range while their sum sits inside it.
  Judging per message reports a cast that was entirely normal.

  The CAST is what separates one yield from the next, not a timer: each click
  notes a conversion, and the loot that follows belongs to it until the next
  one does. A settle timer alone cannot tell a slow second message from a fast
  second cast.
]]
local yieldTally         -- itemID -> count, for the cast being tallied
local yieldTimer

function reportConversionYield()
    yieldTimer = nil
    local src = lastConversion and lastConversion.source
    local entry = src and catalog:conversionResults(src)
    local tally = yieldTally
    yieldTally = nil
    if not entry or not tally then return end

    for _, res in ipairs(entry.results or {}) do
        local count = tally[res.id]
        local q = res.qty
        if count and q and (count < q[1] or count > q[2]) then
            -- Name the result rather than its id: the finding is about two
            -- items and neither should need looking up.
            local rname = GetItemInfo(res.id) or ("item " .. res.id)
            observe("conversion-yield-outside-range", src,
                { min = q[1], max = q[2], result = rname },
                { count = count, result = rname },
                { how = lastConversion.verb })
        end
    end
end

local function checkConversionYield(itemID, count)
    if not lastConversion or (GetTime() - lastConversion.at) > 3.0 then return end
    if not catalog:conversionResults(lastConversion.source) then return end

    yieldTally = yieldTally or {}
    yieldTally[itemID] = (yieldTally[itemID] or 0) + count

    -- The timer only closes a LAST cast, whose successor never comes. A cast
    -- that is followed closes at that cast instead.
    if yieldTimer then yieldTimer:Cancel() end
    yieldTimer = C_Timer.NewTimer(2.0, reportConversionYield)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function factCheck:initialize()
    events     = Addon.events
    ledger     = Addon.ledger
    catalog    = Addon.recipeCatalog
    crafter    = Addon.crafter
    harvester  = Addon.professionHarvester
    utils      = Addon.utils
    constants  = Addon.constants
    difficulty = Addon.difficulty
    theme      = Addon.theme

    store = _G.crafty_factcheck
    if not store then return false end
    store.observations = store.observations or {}
    professionSet = snapshotProfessions()

    -- After the ORDER, not after a craft: CRAFT:COMPLETE now fires when the
    -- last cast lands or the client halts the repeat, so this walk cannot land
    -- between casts.
    -- After the ORDER: CRAFT:COMPLETE now fires when the last cast lands or the
    -- client halts the repeat, so this cannot land between casts.
    events:subscribe("CRAFT:COMPLETE", function()
        checkMovedBands(Addon.professionWindow:liveOpenProfID())
    end)

    -- Every skill change moves bands. Recording which is arithmetic on data
    -- already in memory - no client call - so it is safe mid-repeat.
    --
    -- SKILL_LINES_CHANGED fires for ANY skill, including ones with no trade
    -- window open - a weapon skill, a language, a gathering point picked up in
    -- the world - and liveOpenProfID is nil in all of those. Both checks are
    -- about the profession being crafted, so with none open there is nothing
    -- to check.
    events:subscribe("SKILL_LINES_CHANGED", function()
        local prof = Addon.professionWindow:liveOpenProfID()
        if not prof then return end
        checkSkillUpAmount(prof)
        noteBandMovement(prof)
    end)

    events:subscribe("MERCHANT_SHOW", captureMerchant)
    events:subscribe("MERCHANT_UPDATE", captureMerchant)
    -- A trainer OPEN begins a fresh cycle: reset the per-open state before
    -- capturing, so a new visit never inherits the prior one's - a missed
    -- TRAINER_CLOSED (not guaranteed on every dismissal) would otherwise leave
    -- filters marked-cleared and the snapshot marked-captured, and the new open
    -- would skip filter-clearing and skip building its own snapshot. An UPDATE
    -- is a change WITHIN the current open and must not reset.
    events:subscribe("TRAINER_SHOW", function()
        resetTrainerCycle()
        captureTrainer()
    end)
    events:subscribe("TRAINER_UPDATE", captureTrainer)
    events:subscribe("TRAINER_CLOSED", resetTrainerCycle)

    events:subscribe(constants.EVENT.RECIPES_SCANNED, function(_, payload)
        if payload and payload.complete then
            checkScannedBands(payload.prof, payload.rows)
            announceNextBoundary(payload.prof)
        end
    end)

    events:subscribe("NEW_RECIPE_LEARNED", function(_, spellID)
        -- A learned recipe is inserted into the list, shifting every row after
        -- it. Reading a stale row would compare another recipe's colour, so the
        -- map is dropped and rebuilt by the next scan.
        rowOf, bandAt, movedDuringOrder = nil, nil, nil
        if spellID then queueLearn(spellID) end
    end)
    events:subscribe("SKILL_LINES_CHANGED", function()
        -- A profession change with no learns attached still moves the
        -- baseline the next burst is diffed against.
        if not pendingTimer then professionSet = snapshotProfessions() end
    end)

    -- A teaching item, when used, casts a wrapper spell (no reagents); a craft
    -- casts a recipe (reagents). This START sees both. It records the item-use
    -- as the live teach-cast, and a craft clears any lingering one - the player
    -- has moved on from item-use, so a discovery the craft procs must not read a
    -- stale teach-cast as its source. Emptiness, not truthiness: reagents()
    -- returns {} for a non-recipe spell, which is truthy, so `not reagents()`
    -- was always false and the teach-cast was never recorded at all - the real
    -- reason every item learn read unknown.
    events:subscribe("UNIT_SPELLCAST_START", function(_, unit, castGUID, spellID)
        if unit ~= "player" or not spellID then return end
        if next(catalog:reagents(spellID)) == nil then
            lastTeachCast = { spellID = spellID, guid = castGUID }
        else
            lastTeachCast = nil
        end
    end)

    -- Loot lines name the item and how many arrived; a conversion cast in the
    -- last few seconds says which source produced them.
    events:subscribe("CHAT_MSG_LOOT", function(_, msg)
        if not msg then return end
        local link, num = msg:match("(|c%x+|Hitem:.-|h.-|h|r)%s*x?(%d*)")
        local itemID = link and tonumber(link:match("item:(%d+)"))
        if itemID then
            checkConversionYield(itemID, tonumber(num) or 1)
        end
    end)

    -- A quest offered while a trainer is engaged: the level-gated
    -- trainer-quest shape (Training Projects). General quests are out of scope.
    events:subscribe("QUEST_DETAIL", function()
        if ClassTrainerFrame and ClassTrainerFrame:IsShown() then
            observe("quest-offered", nil,
                {}, { questID = GetQuestID and GetQuestID() or nil },
                { how = "trainer", npc = UnitName("questnpc") or UnitName("npc") })
        end
    end)

    return true
end

if Addon.registerModule then
    Addon.registerModule("factCheck",
        {"events", "ledger", "recipeCatalog", "crafter",
         "professionHarvester", "utils", "difficulty", "theme"},
        function()
            return factCheck:initialize()
        end)
end

Addon.factCheck = factCheck
return factCheck
