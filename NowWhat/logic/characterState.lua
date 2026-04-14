local addonName, ns = ...

local stateCharacter = {}
ns.stateCharacter = stateCharacter

function ns.characterStateInit()
    local _, classFile = UnitClass("player")
    local _, raceFile = UnitRace("player")
    local factionPlayer = UnitFactionGroup("player")
    local levelPlayer = UnitLevel("player")

    stateCharacter.classFile = classFile
    stateCharacter.raceFile = raceFile
    stateCharacter.factionPlayer = factionPlayer
    stateCharacter.levelPlayer = levelPlayer

    ns.professionsRead()
    ns.reputationsRead()
end

-- Professions (TBC Classic uses GetSkillLineInfo, not GetProfessions)

local PROFESSION_NAMES = {
    ["Alchemy"] = ns.PROFESSION_ALCHEMY,
    ["Blacksmithing"] = ns.PROFESSION_BLACKSMITHING,
    ["Enchanting"] = ns.PROFESSION_ENCHANTING,
    ["Engineering"] = ns.PROFESSION_ENGINEERING,
    ["Jewelcrafting"] = ns.PROFESSION_JEWELCRAFTING,
    ["Leatherworking"] = ns.PROFESSION_LEATHERWORKING,
    ["Tailoring"] = ns.PROFESSION_TAILORING,
}

function ns.professionsRead()
    stateCharacter.professions = {}

    local inProfessions = false
    for i = 1, GetNumSkillLines() do
        local name, isHeader, _, skillLevel, _, _, _, _, _, _, _, _, _ = GetSkillLineInfo(i)
        if isHeader then
            inProfessions = (name == "Professions")
        elseif inProfessions then
            local profID = PROFESSION_NAMES[name]
            if profID then
                stateCharacter.professions[profID] = {
                    nameDisplay = name,
                    skillLevel = skillLevel,
                    skillMax = 375,
                }
            end
        end
    end
end

function ns.professionHas(professionID)
    return stateCharacter.professions[professionID] ~= nil
end

-- Reputations

function ns.reputationsRead()
    stateCharacter.reputations = {}

    ExpandFactionHeader(0) -- expand all headers so we can iterate

    local countFaction = GetNumFactions()
    for i = 1, countFaction do
        local name, _, standing, barMin, barMax, barValue, _, _, isHeader, _, hasRep, _, _, factionID = GetFactionInfo(i)
        if factionID and (not isHeader or hasRep) then
            local valueCurrent = barMax - barValue
            local valueMax = barMax - barMin

            stateCharacter.reputations[factionID] = {
                nameDisplay = name,
                standing = standing,
                valueCurrent = valueCurrent,
                valueMax = valueMax,
            }
        end
    end
end

function ns.reputationGet(factionID)
    return stateCharacter.reputations[factionID]
end

--- Returns true if the player is hostile to a given faction.
function ns.isHostileTo(factionID)
    local repData = stateCharacter.reputations[factionID]
    if repData then
        return repData.standing <= ns.STANDING_HOSTILE
    end
    -- Fallback: query API directly (faction may not be in cached list)
    local _, _, standing = GetFactionInfoByID(factionID)
    if standing then
        return standing <= ns.STANDING_HOSTILE
    end
    return false
end

--- Checks if a quest rewards rep to any faction the player is hostile to.
--- @param questID number
--- @param queryFn function -- QuestieDB.QueryQuestSingle
--- @return boolean
function ns.questRewardsHostileFaction(questID, queryFn)
    local repReward = queryFn(questID, "reputationReward")
    if not repReward or type(repReward) ~= "table" then return false end
    for _, reward in ipairs(repReward) do
        if reward[1] and ns.isHostileTo(reward[1]) then
            return true
        end
    end
    return false
end

--- Calculates total rep needed from current standing to a target standing.
--- @param factionID number
--- @param standingTarget number (ns.STANDING_* constant)
--- @return number repNeeded, or 0 if already at or above target
function ns.repGapCalculate(factionID, standingTarget)
    local repData = stateCharacter.reputations[factionID]
    if not repData then return 0 end

    local standingCurrent = repData.standing
    local valueCurrent = repData.valueCurrent

    if standingCurrent >= standingTarget then return 0 end

    -- Rep remaining in current tier (valueCurrent is already remaining)
    local repNeeded = valueCurrent

    -- Full tiers between current and target
    for tier = standingCurrent + 1, standingTarget - 1 do
        repNeeded = repNeeded + (ns.STANDING_MAX[tier] or 0)
    end

    return repNeeded
end

-- Quest status checks

function ns.questIsComplete(questID)
    return C_QuestLog.IsQuestFlaggedCompleted(questID)
end

--- Returns true if quest is currently in the player's quest log.
function ns.questInLog(questID)
    local logIndex = GetQuestLogIndexByID(questID)
    return logIndex and logIndex > 0
end

--- Returns true if quest is in the log and ready to turn in.
function ns.questLogTurnInReady(questID)
    local logIndex = GetQuestLogIndexByID(questID)
    if not logIndex or logIndex == 0 then return false end
    local _, _, _, _, _, _, isComplete = GetQuestLogTitle(logIndex)
    return isComplete and true or false
end

--- Checks if the player meets a quest's rep requirements.
--- @param questID number
--- @param queryFn function -- QuestieDB.QueryQuestSingle
--- @return boolean
function ns.questRepRequirementsMet(questID, queryFn)
    local requiredMinRep = queryFn(questID, "requiredMinRep")
    local requiredMaxRep = queryFn(questID, "requiredMaxRep")
    if requiredMinRep and type(requiredMinRep) == "table" and requiredMinRep[1] then
        local _, _, _, _, _, barValue = GetFactionInfoByID(requiredMinRep[1])
        if barValue and barValue < requiredMinRep[2] then return false end
    end
    if requiredMaxRep and type(requiredMaxRep) == "table" and requiredMaxRep[1] then
        local _, _, _, _, _, barValue = GetFactionInfoByID(requiredMaxRep[1])
        if barValue and barValue >= requiredMaxRep[2] then return false end
    end
    return true
end

-- Faction lookup (fuzzy matching via GetFactionInfoByID)

local factionNameMap = nil  -- lowercase name -> factionID

--- Builds the faction name lookup table from constants.
--- Uses GetFactionInfoByID which works for all factions, even undiscovered.
local function factionLookupBuild()
    if factionNameMap then return end
    factionNameMap = {}

    for _, factionID in ipairs(ns.FACTION_IDS) do
        local name = GetFactionInfoByID(factionID)
        if name then
            factionNameMap[name:lower()] = factionID
        end
    end
end

--- Fuzzy-matches user input against known faction names.
--- Matches if input is a substring of any faction name (case-insensitive).
--- @param input string
--- @return number|nil factionID
--- @return string|nil factionName
function ns.factionLookup(input)
    factionLookupBuild()

    local search = input:lower()
    local bestID, bestName

    -- Exact match first
    if factionNameMap[search] then
        local name = GetFactionInfoByID(factionNameMap[search])
        return factionNameMap[search], name
    end

    -- Substring match
    for name, id in pairs(factionNameMap) do
        if name:find(search, 1, true) then
            if bestName then
                -- Ambiguous: multiple matches
                return nil, nil
            end
            bestID = id
            bestName = name
        end
    end

    if bestID then
        local displayName = GetFactionInfoByID(bestID)
        return bestID, displayName
    end

    return nil, nil
end

-- Slash command: status

ns.commandRegister("status", function()
    ns.reputationsRead()
    ns.professionsRead()

    local state = stateCharacter
    print("|cff33ff99NowWhat|r Character Status:")
    print(string.format("  %s %s %s (Level %d)",
        state.factionPlayer, state.raceFile, state.classFile, state.levelPlayer))

    print("  Professions:")
    if next(state.professions) then
        for _, data in pairs(state.professions) do
            print(string.format("    %s (%d)", data.nameDisplay, data.skillLevel))
        end
    else
        print("    None detected")
    end
end, "Show character info")