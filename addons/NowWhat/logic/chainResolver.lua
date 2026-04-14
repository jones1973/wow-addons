local addonName, ns = ...

-- luacheck: globals QuestieLoader QuestieDB

local questieDB = nil

local function questieInit()
    if questieDB then return true end

    if QuestieLoader and QuestieLoader.ImportModule then
        local ok, db = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieDB")
        if ok and db then
            questieDB = db
            return true
        end
    end

    if QuestieDB then
        questieDB = QuestieDB
        return true
    end

    return false
end

-- Quests removed from the game but still in Questie's database
ns.QUEST_BLACKLIST = {
    [10169] = true, -- Losing Gracefully (removed in Patch 2.4)
}

--- Builds a quest node with all metadata.
--- @param questID number
--- @param factionID number
--- @return table|nil node
local function buildQuestNode(questID, factionID)
    local queryFn = questieDB.QueryQuestSingle
    if not queryFn then return nil end

    local name = queryFn(questID, "name")
    if not name then return nil end

    local isComplete = C_QuestLog.IsQuestFlaggedCompleted(questID)
    local questLevel = queryFn(questID, "questLevel")
    local requiredLevel = queryFn(questID, "requiredLevel")
    local questFlags = queryFn(questID, "questFlags")
    local specialFlags = queryFn(questID, "specialFlags")
    local zoneOrSort = queryFn(questID, "zoneOrSort")

    local repAmount = 0
    local repReward = queryFn(questID, "reputationReward")
    if repReward and type(repReward) == "table" then
        for _, reward in ipairs(repReward) do
            if reward[1] == factionID then
                repAmount = reward[2] or 0
                break
            end
        end
    end

    local isGroupQuest = false
    local isDaily = false
    if questFlags and type(questFlags) == "number" then
        isGroupQuest = bit.band(questFlags, 1) > 0
        isDaily = bit.band(questFlags, 4096) > 0
    end

    local isRepeatable = false
    if specialFlags and type(specialFlags) == "number" then
        isRepeatable = bit.band(specialFlags, 1) > 0
    end

    -- Prereq check for availability
    local preQuestGroup = queryFn(questID, "preQuestGroup")
    local preQuestSingle = queryFn(questID, "preQuestSingle")
    local preReqsMet = true

    if preQuestGroup and #preQuestGroup > 0 then
        for _, preID in ipairs(preQuestGroup) do
            if not C_QuestLog.IsQuestFlaggedCompleted(preID) then
                preReqsMet = false
                break
            end
        end
    end

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
        end
    end

    local isAvailable = preReqsMet and not isComplete
    local inQuestLog = ns.questInLog(questID)
    local turnInReady = ns.questLogTurnInReady(questID)

    return {
        questID = questID,
        nameDisplay = name,
        repAmount = repAmount,
        questLevel = questLevel,
        requiredLevel = requiredLevel,
        zoneOrSort = zoneOrSort,
        isComplete = isComplete,
        isAvailable = isAvailable,
        inQuestLog = inQuestLog,
        turnInReady = turnInReady,
        isGroupQuest = isGroupQuest,
        isRepeatable = isRepeatable,
        isDaily = isDaily,
        children = {},
    }
end

--- Recursively collects all prereq quest IDs into a set.
local function collectAllPrereqs(questID, allQuests, visited)
    if visited[questID] then return end
    if ns.QUEST_BLACKLIST[questID] then return end
    visited[questID] = true

    local queryFn = questieDB.QueryQuestSingle
    if not queryFn then return end

    local name = queryFn(questID, "name")
    if not name then return end

    if ns.questRewardsHostileFaction(questID, queryFn) then return end
    if not ns.questRepRequirementsMet(questID, queryFn) then return end

    allQuests[questID] = true

    local preQuestGroup = queryFn(questID, "preQuestGroup")
    if preQuestGroup then
        for _, preID in ipairs(preQuestGroup) do
            collectAllPrereqs(preID, allQuests, visited)
        end
    end

    local preQuestSingle = queryFn(questID, "preQuestSingle")
    if preQuestSingle then
        for _, preID in ipairs(preQuestSingle) do
            collectAllPrereqs(preID, allQuests, visited)
        end
    end
end

--- Builds forward trees for a faction.
--- Instead of building backward from each rep quest, builds a forward graph
--- from common ancestors, correctly handling sibling quests.
--- @param factionID number
--- @return table chains -- array of root nodes with .children
function ns.chainsForFaction(factionID)
    if not questieInit() then return {} end
    if not questieDB.QuestPointers then return {} end

    local queryFn = questieDB.QueryQuestSingle
    if not queryFn then return {} end

    -- Step 1: find all uncompleted, one-time rep quests for this faction
    local repQuestIDs = {}
    for questID in pairs(questieDB.QuestPointers) do
        local repReward = queryFn(questID, "reputationReward")
        if repReward and type(repReward) == "table" then
            for _, reward in ipairs(repReward) do
                if reward[1] == factionID and reward[2] and reward[2] > 0 then
                    if not C_QuestLog.IsQuestFlaggedCompleted(questID) and not ns.QUEST_BLACKLIST[questID] then
                        local specialFlags = queryFn(questID, "specialFlags")
                        local questFlags = queryFn(questID, "questFlags")
                        local isRepeatable = specialFlags and type(specialFlags) == "number" and bit.band(specialFlags, 1) > 0
                        local isDaily = questFlags and type(questFlags) == "number" and bit.band(questFlags, 4096) > 0

                        if not isRepeatable and not isDaily then
                            if not ns.questRewardsHostileFaction(questID, queryFn) and ns.questRepRequirementsMet(questID, queryFn) then
                                table.insert(repQuestIDs, questID)
                            end
                        end
                    end
                    break
                end
            end
        end
    end

    -- Step 2: collect all quest IDs in the graph (rep quests + all their prereqs)
    local allQuests = {}
    local collectVisited = {}
    for _, questID in ipairs(repQuestIDs) do
        collectAllPrereqs(questID, allQuests, collectVisited)
    end

    -- Step 3: build forward links (parent -> children)
    local forwardLinks = {}  -- questID -> { childQuestID, ... }
    local hasParent = {}

    for questID in pairs(allQuests) do
        local preQuestGroup = queryFn(questID, "preQuestGroup")
        local preQuestSingle = queryFn(questID, "preQuestSingle")

        -- preQuestGroup: ALL required, all are real parents
        if preQuestGroup then
            for _, preID in ipairs(preQuestGroup) do
                if allQuests[preID] then
                    forwardLinks[preID] = forwardLinks[preID] or {}
                    table.insert(forwardLinks[preID], questID)
                    hasParent[questID] = true
                end
            end
        end

        -- preQuestSingle: ANY ONE required. Pick the completed one, or first available.
        if preQuestSingle then
            local chosenPreID = nil
            for _, preID in ipairs(preQuestSingle) do
                if allQuests[preID] and C_QuestLog.IsQuestFlaggedCompleted(preID) then
                    chosenPreID = preID
                    break
                end
            end
            if not chosenPreID then
                for _, preID in ipairs(preQuestSingle) do
                    if allQuests[preID] then
                        chosenPreID = preID
                        break
                    end
                end
            end
            if chosenPreID then
                forwardLinks[chosenPreID] = forwardLinks[chosenPreID] or {}
                table.insert(forwardLinks[chosenPreID], questID)
                hasParent[questID] = true
            end
        end
    end

    -- Step 4: find roots (quests with no parent in the graph)
    local rootIDs = {}
    for questID in pairs(allQuests) do
        if not hasParent[questID] then
            table.insert(rootIDs, questID)
        end
    end

    -- Step 5: build forward trees from roots
    local treeVisited = {}

    local function buildTree(questID)
        if treeVisited[questID] then return nil end
        treeVisited[questID] = true

        local node = buildQuestNode(questID, factionID)
        if not node then return nil end

        local childIDs = forwardLinks[questID]
        if childIDs then
            for _, childID in ipairs(childIDs) do
                local childNode = buildTree(childID)
                if childNode then
                    table.insert(node.children, childNode)
                end
            end
        end

        return node
    end

    local chains = {}
    for _, rootID in ipairs(rootIDs) do
        local chain = buildTree(rootID)
        if chain then
            table.insert(chains, chain)
        end
    end

    table.sort(chains, function(a, b)
        if a.isAvailable ~= b.isAvailable then
            return a.isAvailable
        end
        if a.isComplete ~= b.isComplete then
            return not a.isComplete
        end
        return (a.repAmount or 0) > (b.repAmount or 0)
    end)

    return chains
end

--- Flattens a forward chain tree into a displayable row list.
--- @param node table
--- @param depth number
--- @param rows table
local function flattenChain(node, depth, rows)
    table.insert(rows, {
        questID = node.questID,
        nameDisplay = node.nameDisplay,
        repAmount = node.repAmount,
        questLevel = node.questLevel,
        zoneOrSort = node.zoneOrSort,
        isComplete = node.isComplete,
        isAvailable = node.isAvailable,
        inQuestLog = node.inQuestLog,
        turnInReady = node.turnInReady,
        isGroupQuest = node.isGroupQuest,
        isRepeatable = node.isRepeatable,
        isDaily = node.isDaily,
        depth = depth,
    })

    for _, child in ipairs(node.children) do
        flattenChain(child, depth + 1, rows)
    end
end

--- Flattens all chains for a faction into a displayable row list, grouped by zone.
--- Zone is determined by the rep-granting quest (root of each chain).
--- @param factionID number
--- @return table rows
function ns.chainRowsForFaction(factionID)
    local chains = ns.chainsForFaction(factionID)

    -- Group chains by zone
    local zoneGroups = {}  -- zoneID -> { chains }
    local zoneOrder = {}   -- ordered list of zoneIDs
    local zoneSeen = {}

    for _, chain in ipairs(chains) do
        local zoneID = chain.zoneOrSort or 0
        if not zoneSeen[zoneID] then
            zoneSeen[zoneID] = true
            table.insert(zoneOrder, zoneID)
        end
        zoneGroups[zoneID] = zoneGroups[zoneID] or {}
        table.insert(zoneGroups[zoneID], chain)
    end

    -- Build rows with zone headers
    local rows = {}
    for _, zoneID in ipairs(zoneOrder) do
        local zoneName
        if zoneID > 0 then
            zoneName = C_Map.GetAreaInfo(zoneID)
        end
        table.insert(rows, { isZoneHeader = true, zoneName = zoneName or "Unknown Zone" })

        local chainsInZone = zoneGroups[zoneID]
        for j, chain in ipairs(chainsInZone) do
            if j > 1 then
                table.insert(rows, { isSeparator = true })
            end
            flattenChain(chain, 0, rows)
        end
    end

    return rows
end

--- Returns daily quests that grant rep for a faction.
--- @param factionID number
--- @return table dailies
function ns.dailiesForFaction(factionID)
    if not questieInit() then return {} end
    if not questieDB.QuestPointers then return {} end

    local queryFn = questieDB.QueryQuestSingle
    if not queryFn then return {} end

    local results = {}
    for questID in pairs(questieDB.QuestPointers) do
        if not ns.QUEST_BLACKLIST[questID] then
        local repReward = queryFn(questID, "reputationReward")
        if repReward and type(repReward) == "table" then
            for _, reward in ipairs(repReward) do
                if reward[1] == factionID and reward[2] and reward[2] > 0 then
                    if ns.questRewardsHostileFaction(questID, queryFn) then break end
                    if not ns.questRepRequirementsMet(questID, queryFn) then break end

                    local questFlags = queryFn(questID, "questFlags")
                    local isDaily = questFlags and type(questFlags) == "number" and bit.band(questFlags, 4096) > 0
                    if isDaily then
                        local name = queryFn(questID, "name")
                        local inLog = ns.questInLog(questID)
                        local turnIn = ns.questLogTurnInReady(questID)
                        table.insert(results, {
                            questID = questID,
                            nameDisplay = name or ("Quest " .. questID),
                            repAmount = reward[2],
                            isDaily = true,
                            inQuestLog = inLog,
                            turnInReady = turnIn,
                            isAvailable = true,
                        })
                    end
                    break
                end
            end
        end
        end -- blacklist
    end

    table.sort(results, function(a, b) return a.repAmount > b.repAmount end)
    return results
end

--- Returns repeatable (non-daily) quests that grant rep for a faction.
--- @param factionID number
--- @return table repeatables
function ns.repeatablesForFaction(factionID)
    if not questieInit() then return {} end
    if not questieDB.QuestPointers then return {} end

    local queryFn = questieDB.QueryQuestSingle
    if not queryFn then return {} end

    local results = {}
    for questID in pairs(questieDB.QuestPointers) do
        if not ns.QUEST_BLACKLIST[questID] then
        local repReward = queryFn(questID, "reputationReward")
        if repReward and type(repReward) == "table" then
            for _, reward in ipairs(repReward) do
                if reward[1] == factionID and reward[2] and reward[2] > 0 then
                    if ns.questRewardsHostileFaction(questID, queryFn) then break end
                    if not ns.questRepRequirementsMet(questID, queryFn) then break end

                    local specialFlags = queryFn(questID, "specialFlags")
                    local questFlags = queryFn(questID, "questFlags")
                    local isRepeatable = specialFlags and type(specialFlags) == "number" and bit.band(specialFlags, 1) > 0
                    local isDaily = questFlags and type(questFlags) == "number" and bit.band(questFlags, 4096) > 0

                    if isRepeatable and not isDaily then
                        local name = queryFn(questID, "name")
                        local inLog = ns.questInLog(questID)
                        local turnIn = ns.questLogTurnInReady(questID)
                        table.insert(results, {
                            questID = questID,
                            nameDisplay = name or ("Quest " .. questID),
                            repAmount = reward[2],
                            isRepeatable = true,
                            inQuestLog = inLog,
                            turnInReady = turnIn,
                            isAvailable = true,
                        })
                    end
                    break
                end
            end
        end
        end -- blacklist
    end

    table.sort(results, function(a, b) return a.repAmount > b.repAmount end)
    return results
end

--- Returns tooltip information for a quest.
--- @param questID number
--- @return table|nil info
function ns.questTooltipInfo(questID)
    if not questieInit() then return nil end

    local queryFn = questieDB.QueryQuestSingle
    if not queryFn then return nil end

    local info = {
        nameDisplay = queryFn(questID, "name") or ("Quest " .. questID),
    }

    -- Quest giver NPC
    local startedBy = queryFn(questID, "startedBy")
    if startedBy and startedBy[1] and type(startedBy[1]) == "table" then
        for _, npcID in ipairs(startedBy[1]) do
            if questieDB.QueryNPCSingle then
                local npcName = questieDB.QueryNPCSingle(npcID, "name")
                if npcName then
                    info.questGiver = npcName
                    info.questGiverID = npcID
                    break
                end
            end
        end
    end

    -- Turn-in NPC
    local finishedBy = queryFn(questID, "finishedBy")
    if finishedBy and finishedBy[1] and type(finishedBy[1]) == "table" then
        for _, npcID in ipairs(finishedBy[1]) do
            if questieDB.QueryNPCSingle then
                local npcName = questieDB.QueryNPCSingle(npcID, "name")
                if npcName then
                    info.turnInNPC = npcName
                    info.turnInID = npcID
                    break
                end
            end
        end
    end

    -- Zone
    local zoneOrSort = queryFn(questID, "zoneOrSort")
    if zoneOrSort and zoneOrSort > 0 then
        local zoneName = C_Map.GetAreaInfo(zoneOrSort)
        if zoneName then
            info.zone = zoneName
        end
    end

    -- Quest type from quest log (if in log) or flags
    local logIndex = GetQuestLogIndexByID(questID)
    if logIndex and logIndex > 0 then
        local _, _, questTag, suggestedGroup = GetQuestLogTitle(logIndex)
        info.questTag = questTag
        info.suggestedGroup = suggestedGroup
    else
        -- Derive from questFlags if not in log
        local questFlags = queryFn(questID, "questFlags")
        if questFlags and type(questFlags) == "number" then
            if bit.band(questFlags, 2) > 0 then
                info.questTag = "Dungeon"
            elseif bit.band(questFlags, 1) > 0 then
                info.questTag = "Group"
            end
        end
    end

    return info
end
