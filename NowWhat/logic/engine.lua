local addonName, ns = ...

-- Questie access via QuestieLoader (same pattern as PAO's questieExtract)
-- luacheck: globals QuestieDB Questie QuestieLoader

local questieDB = nil
local questieAvailable = false

local function questieInit()
    if questieDB then return true end

    if QuestieLoader and QuestieLoader.ImportModule then
        local ok, db = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieDB")
        if ok and db then
            questieDB = db
            questieAvailable = true
            return true
        end
    end

    if QuestieDB then
        questieDB = QuestieDB
        questieAvailable = true
        return true
    end

    return false
end

--- Queries Questie for uncompleted quests that grant rep for a given faction.
--- @param factionID number
--- @return table questsAvailable
local function questieQuestsForFaction(factionID)
    if not questieInit() then return {} end
    if not questieDB.QuestPointers then return {} end

    local questsAvailable = {}
    local queryFn = questieDB.QueryQuestSingle

    if not queryFn then return {} end

    for questID in pairs(questieDB.QuestPointers) do
        if not C_QuestLog.IsQuestFlaggedCompleted(questID) and not ns.QUEST_BLACKLIST[questID] then
            -- Skip quests that reward rep to a faction the player is hostile to
            -- or that have rep requirements the player doesn't meet
            if not ns.questRewardsHostileFaction(questID, queryFn) and ns.questRepRequirementsMet(questID, queryFn) then
            local repReward = queryFn(questID, "reputationReward")

            if repReward and type(repReward) == "table" then
                for _, reward in ipairs(repReward) do
                    if reward[1] == factionID and reward[2] and reward[2] > 0 then
                        local name = queryFn(questID, "name")
                        local questLevel = queryFn(questID, "questLevel")
                        local requiredLevel = queryFn(questID, "requiredLevel")
                        local zoneOrSort = queryFn(questID, "zoneOrSort")
                        local preQuestGroup = queryFn(questID, "preQuestGroup")
                        local preQuestSingle = queryFn(questID, "preQuestSingle")
                        local questFlags = queryFn(questID, "questFlags")
                        local specialFlags = queryFn(questID, "specialFlags")
                        local exclusiveTo = queryFn(questID, "exclusiveTo")

                        -- Determine if prereqs are met
                        local preReqsMet = true
                        local preReqsBlocking = nil

                        -- preQuestGroup: ALL must be complete
                        if preQuestGroup and #preQuestGroup > 0 then
                            for _, preID in ipairs(preQuestGroup) do
                                if not C_QuestLog.IsQuestFlaggedCompleted(preID) then
                                    preReqsMet = false
                                    preReqsBlocking = preReqsBlocking or {}
                                    table.insert(preReqsBlocking, preID)
                                end
                            end
                        end

                        -- preQuestSingle: ANY ONE must be complete
                        if preQuestSingle and #preQuestSingle > 0 then
                            local anyComplete = false
                            for _, preID in ipairs(preQuestSingle) do
                                if C_QuestLog.IsQuestFlaggedCompleted(preID) then
                                    anyComplete = true
                                    break
                                end
                            end
                            if not anyComplete then
                                preReqsMet = false
                                preReqsBlocking = preQuestSingle
                            end
                        end

                        -- Check if an exclusive quest was already completed
                        local excludedByComplete = false
                        if exclusiveTo and type(exclusiveTo) == "table" then
                            for _, exID in ipairs(exclusiveTo) do
                                if C_QuestLog.IsQuestFlaggedCompleted(exID) then
                                    excludedByComplete = true
                                    break
                                end
                            end
                        end

                        -- Detect group quest from questFlags bitmask
                        local isGroupQuest = false
                        local isDaily = false
                        if questFlags and type(questFlags) == "number" then
                            isGroupQuest = bit.band(questFlags, 1) > 0
                            isDaily = bit.band(questFlags, 4096) > 0
                        end

                        -- Detect repeatable from specialFlags (bit 1 = repeatable)
                        local isRepeatable = false
                        if specialFlags and type(specialFlags) == "number" then
                            isRepeatable = bit.band(specialFlags, 1) > 0
                        end

                        if not excludedByComplete then
                            table.insert(questsAvailable, {
                                questID = questID,
                                nameDisplay = name or ("Quest " .. questID),
                                repAmount = reward[2],
                                questLevel = questLevel,
                                requiredLevel = requiredLevel,
                                zoneOrSort = zoneOrSort,
                                isGroupQuest = isGroupQuest,
                                isRepeatable = isRepeatable,
                                isDaily = isDaily,
                                preReqsMet = preReqsMet,
                                preReqsBlocking = preReqsBlocking,
                            })
                        end

                        break
                    end
                end
            end
            end -- hostile faction filter
        end
    end

    table.sort(questsAvailable, function(a, b)
        if a.preReqsMet ~= b.preReqsMet then
            return a.preReqsMet
        end
        return a.repAmount > b.repAmount
    end)

    return questsAvailable
end

ns.questieQuestsForFaction = questieQuestsForFaction

-- Plan building

--- Builds a plan for a single faction goal.
--- @param factionID number
--- @param standingTarget number
--- @return table plan
function ns.planBuild(factionID, standingTarget)
    local repData = ns.reputationGet(factionID)
    local factionMeta = ns.dataReputations[factionID]

    local plan = {
        factionID = factionID,
        nameDisplay = factionMeta and factionMeta.nameDisplay or ("Faction " .. factionID),
        standingCurrent = repData and repData.standing or 0,
        valueCurrent = repData and repData.valueCurrent or 0,
        valueMax = repData and repData.valueMax or 0,
        standingTarget = standingTarget,
        repNeeded = 0,
        repFromQuests = 0,
        repFromQuestsReady = 0,
        repFromQuestsBlocked = 0,
        questsAvailable = {},
        repRemaining = 0,
        turnInOptions = {},
        dungeonEstimate = {},
    }

    plan.repNeeded = ns.repGapCalculate(factionID, standingTarget)

    if plan.repNeeded <= 0 then
        return plan
    end

    -- Phase 1: Available quests from Questie
    plan.questsAvailable = questieQuestsForFaction(factionID)
    for _, quest in ipairs(plan.questsAvailable) do
        if not quest.isRepeatable and not quest.isDaily then
            plan.repFromQuests = plan.repFromQuests + quest.repAmount
            if quest.preReqsMet then
                plan.repFromQuestsReady = plan.repFromQuestsReady + quest.repAmount
            else
                plan.repFromQuestsBlocked = plan.repFromQuestsBlocked + quest.repAmount
            end
        end
    end

    -- Phase 2: Remaining gap after quests
    plan.repRemaining = math.max(0, plan.repNeeded - plan.repFromQuests)

    -- Phase 3: Turn-in options for the remaining gap
    local turnIns = ns.dataTurnIns[factionID]
    if turnIns and plan.repRemaining > 0 then
        for _, turnIn in ipairs(turnIns) do
            if plan.standingCurrent < turnIn.standingMax then
                local turnInsNeeded, itemsNeeded = ns.turnInsCalculate(turnIn, plan.repRemaining)
                table.insert(plan.turnInOptions, {
                    nameDisplay = turnIn.nameDisplay,
                    itemID = turnIn.itemID,
                    turnInsNeeded = turnInsNeeded,
                    itemsNeeded = itemsNeeded,
                    isTradeable = turnIn.isTradeable,
                    repPerTurnIn = turnIn.repPerTurnIn,
                    notes = turnIn.notes,
                })
            end
        end
    end

    -- Phase 4: Dungeon run estimate for remaining gap
    if plan.repRemaining > 0 then
        local dungeonName, runsNormal, repNormal = ns.dungeonRunsEstimate(
            factionID, plan.repRemaining, plan.standingCurrent, false)
        local dungeonNameH, runsHeroic, repHeroic = ns.dungeonRunsEstimate(
            factionID, plan.repRemaining, plan.standingCurrent, true)

        plan.dungeonEstimate = {
            normal = { dungeonName = dungeonName, runsRequired = runsNormal, repPerRun = repNormal },
            heroic = { dungeonName = dungeonNameH, runsRequired = runsHeroic, repPerRun = repHeroic },
        }
    end

    return plan
end

--- Builds plans for all active goals.
--- @return table plans
function ns.plansAll()
    local goals = ns.charDb and ns.charDb.goalsActive or {}
    local plans = {}

    for factionID, standingTarget in pairs(goals) do
        local plan = ns.planBuild(factionID, standingTarget)
        table.insert(plans, plan)
    end

    table.sort(plans, function(a, b) return a.repNeeded > b.repNeeded end)

    return plans
end

-- Slash commands

ns.commandRegister("plan", function(args)
    ns.reputationsRead()

    local goals = ns.charDb.goalsActive
    if not next(goals) then
        print("|cff33ff99NowWhat|r No goals set. Use /nw goal <faction> <standing> to add one.")
        print("  Example: /nw goal scryers exalted")
        return
    end

    local plans = ns.plansAll()
    for _, plan in ipairs(plans) do
        local standingName = ns.STANDING_NAME[plan.standingCurrent] or "?"
        local targetName = ns.STANDING_NAME[plan.standingTarget] or "?"

        print(string.format("|cff33ff99%s|r: %s (%d/%d) -> %s | |cffffff00%d rep needed|r",
            plan.nameDisplay, standingName, plan.valueCurrent, plan.valueMax, targetName, plan.repNeeded))

        if plan.repNeeded <= 0 then
            print("  Already at or above target!")
        else
            if not questieAvailable then
                print("  |cffff6600Questie not detected|r - quest data unavailable")
            elseif #plan.questsAvailable > 0 then
                local countReady = 0
                local countBlocked = 0
                for _, q in ipairs(plan.questsAvailable) do
                    if not q.isRepeatable then
                        if q.preReqsMet then countReady = countReady + 1
                        else countBlocked = countBlocked + 1 end
                    end
                end

                print(string.format("  Quests: %d available (~%d rep) | %d ready (~%d rep), %d blocked (~%d rep)",
                    countReady + countBlocked, plan.repFromQuests,
                    countReady, plan.repFromQuestsReady,
                    countBlocked, plan.repFromQuestsBlocked))
            else
                print("  No uncompleted quests found for this faction")
            end

            if plan.repRemaining > 0 then
                print(string.format("  Remaining after quests: |cffffff00%d rep|r", plan.repRemaining))

                if #plan.turnInOptions > 0 then
                    print("  Turn-in options:")
                    for _, opt in ipairs(plan.turnInOptions) do
                        local tradeTag = opt.isTradeable and " |cff00ff00(AH)|r" or ""
                        print(string.format("    %s x%d (%d turn-ins, %d rep each)%s",
                            opt.nameDisplay, opt.itemsNeeded, opt.turnInsNeeded, opt.repPerTurnIn, tradeTag))
                    end
                end

                local est = plan.dungeonEstimate
                if est and est.normal and est.normal.runsRequired > 0 then
                    print(string.format("  Dungeon option: %s x%d runs normal (~%d rep/run)",
                        est.normal.dungeonName, est.normal.runsRequired, est.normal.repPerRun))
                end
                if est and est.heroic and est.heroic.runsRequired > 0 then
                    print(string.format("  Dungeon option: %s x%d runs heroic (~%d rep/run)",
                        est.heroic.dungeonName, est.heroic.runsRequired, est.heroic.repPerRun))
                end
            end
        end
    end
end, "Show rep plan for all active goals")

-- Quest detail for a single faction

ns.commandRegister("quests", function(args)
    ns.reputationsRead()
    local factionAlias = args:match("^(%S+)")

    if not factionAlias then
        print("|cff33ff99NowWhat|r Usage: /nw quests <faction>")
        return
    end

    local factionID = factionResolve(factionAlias)
    if not factionID then return end

    if not questieInit() then
        print("|cff33ff99NowWhat|r Questie not detected.")
        return
    end

    local factionMeta = ns.dataReputations[factionID]
    local factionName = factionMeta and factionMeta.nameDisplay or ("Faction " .. factionID)
    local quests = questieQuestsForFaction(factionID)

    if #quests == 0 then
        print(string.format("|cff33ff99%s|r: No uncompleted rep quests found.", factionName))
        return
    end

    print(string.format("|cff33ff99%s|r: %d uncompleted rep quests:", factionName, #quests))
    for _, q in ipairs(quests) do
        local statusTag
        if q.isRepeatable then
            statusTag = "|cff8888ff[R]|r"
        elseif q.preReqsMet then
            statusTag = "|cff00ff00[Ready]|r"
        else
            statusTag = "|cffff6600[Blocked]|r"
        end

        local groupTag = q.isGroupQuest and " |cffff0000(Group)|r" or ""

        print(string.format("  %s %s (+%d rep) [%d]%s",
            statusTag, q.nameDisplay, q.repAmount, q.questID, groupTag))

        if not q.preReqsMet and q.preReqsBlocking then
            for _, preID in ipairs(q.preReqsBlocking) do
                local preName = questieDB.QueryQuestSingle and questieDB.QueryQuestSingle(preID, "name") or preID
                print(string.format("    Requires: %s [%d]", preName or "?", preID))
            end
        end
    end
end, "List available rep quests for a faction: /nw quests <faction>")

-- Goal management

--- Resolves a faction name from user input via fuzzy matching.
--- @param input string
--- @return number|nil factionID
--- @return string|nil factionName
local function factionResolve(input)
    local factionID, factionName = ns.factionLookup(input)
    if not factionID then
        print("|cff33ff99NowWhat|r Unknown faction: " .. input)
    end
    return factionID, factionName
end

local STANDING_ALIAS = {
    friendly = ns.STANDING_FRIENDLY,
    honored  = ns.STANDING_HONORED,
    revered  = ns.STANDING_REVERED,
    exalted  = ns.STANDING_EXALTED,
}

ns.commandRegister("goal", function(args)
    local factionAlias, standingAlias = args:match("^(%S+)%s+(%S+)")

    if not factionAlias or not standingAlias then
        print("|cff33ff99NowWhat|r Usage: /nw goal <faction> <standing>")
        print("  Faction: any part of the faction name (e.g. scryer, shatar, ashtongue)")
        print("  Standings: friendly, honored, revered, exalted")
        return
    end

    local factionID, factionName = factionResolve(factionAlias)
    local standingTarget = STANDING_ALIAS[standingAlias:lower()]

    if not factionID then return end
    if not standingTarget then
        print("|cff33ff99NowWhat|r Unknown standing: " .. standingAlias)
        return
    end

    ns.charDb.goalsActive[factionID] = standingTarget

    factionName = factionName or ("Faction " .. factionID)
    print(string.format("|cff33ff99NowWhat|r Goal set: %s -> %s", factionName, ns.STANDING_NAME[standingTarget]))
end, "Set a rep goal: /nw goal <faction> <standing>")

ns.commandRegister("goals", function()
    local goals = ns.charDb.goalsActive
    if not next(goals) then
        print("|cff33ff99NowWhat|r No goals set.")
        return
    end
    print("|cff33ff99NowWhat|r Active goals:")
    for factionID, standingTarget in pairs(goals) do
        local factionMeta = ns.dataReputations[factionID]
        local factionName = factionMeta and factionMeta.nameDisplay or ("Faction " .. factionID)
        local repData = ns.reputationGet(factionID)
        local standingCurrent = repData and ns.STANDING_NAME[repData.standing] or "?"
        print(string.format("  %s: %s -> %s", factionName, standingCurrent, ns.STANDING_NAME[standingTarget]))
    end
end, "List active goals")

ns.commandRegister("clear", function(args)
    local factionAlias = args:match("^(%S+)")
    if not factionAlias then
        print("|cff33ff99NowWhat|r Usage: /nw clear <faction> or /nw clear all")
        return
    end

    if factionAlias:lower() == "all" then
        ns.charDb.goalsActive = {}
        print("|cff33ff99NowWhat|r All goals cleared.")
        return
    end

    local factionID, factionName = factionResolve(factionAlias)
    if not factionID then return end

    ns.charDb.goalsActive[factionID] = nil
    factionName = factionName or ("Faction " .. factionID)
    print(string.format("|cff33ff99NowWhat|r Goal cleared: %s", factionName))
end, "Clear a goal: /nw clear <faction> or /nw clear all")

-- Rep check for a single faction

ns.commandRegister("rep", function(args)
    ns.reputationsRead()
    local factionAlias = args:match("^(%S+)")

    if not factionAlias then
        print("|cff33ff99NowWhat|r Usage: /nw rep <faction>")
        return
    end

    local factionID, factionName = factionResolve(factionAlias)
    if not factionID then return end

    local repData = ns.reputationGet(factionID)
    factionName = factionName or ("Faction " .. factionID)

    if not repData then
        print(string.format("|cff33ff99%s|r: No reputation data found.", factionName))
        return
    end

    print(string.format("|cff33ff99%s|r: %s %d/%d",
        factionName, ns.STANDING_NAME[repData.standing], repData.valueCurrent, repData.valueMax))

    local itemsRelevant = ns.vendorItemsGet(factionID, true)
    if #itemsRelevant > 0 then
        print("  Items relevant to you:")
        for _, item in ipairs(itemsRelevant) do
            local standingName = ns.STANDING_NAME[item.standingRequired] or "?"
            local available = repData.standing >= item.standingRequired
            local tag = available and "|cff00ff00AVAILABLE|r" or ("|cffff6600" .. standingName .. "|r")
            local profTag = item.professionRequired and " [" .. (item.category or "") .. "]" or ""
            print(string.format("    %s - %s%s %s", item.nameDisplay, item.notes or "", profTag, tag))
        end
    end
end, "Show rep status and relevant items for a faction")