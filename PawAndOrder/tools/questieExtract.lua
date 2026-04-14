-- tools/questieExtract.lua
-- Extracts NPC and quest data from Questie's internal database for our NPCs.
-- Questie is not a dependency; this is a dev-only data mining tool.
--
-- Usage: /pao questie extract
-- Requires: debug mode enabled, Questie addon loaded
--
-- Dependencies: utils, commands, dataStore

-- luacheck: globals QuestieDB Questie DevTools_Dump ChatFontNormal DEFAULT_CHAT_FRAME

local _, Addon = ...

local questieExtract = {}

-- Questie's faction codes mapped to readable strings
local FACTION_MAP = {
    ["A"] = "Alliance",
    ["H"] = "Horde",
    ["AH"] = "Both",
}

-- Resolve the QuestieDB module via QuestieLoader
-- luacheck: globals QuestieLoader
local function getQuestieDB()
    if QuestieLoader and QuestieLoader.ImportModule then
        local ok, db = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieDB")
        if ok and db then return db end
    end
    -- Fallback for older Questie versions
    if QuestieDB then return QuestieDB end
    return nil
end

-- Resolve the ZoneDB module for coordinate translation
local function getZoneDB()
    if QuestieLoader and QuestieLoader.ImportModule then
        local ok, db = pcall(QuestieLoader.ImportModule, QuestieLoader, "ZoneDB")
        if ok and db then return db end
    end
    return nil
end

-- Flatten a Questie spawns table { [zoneId] = { {x,y}, ... } } into readable form
local function flattenSpawns(spawns)
    if not spawns or type(spawns) ~= "table" then return nil end

    local result = {}
    for zoneId, coords in pairs(spawns) do
        if type(coords) == "table" then
            for _, point in ipairs(coords) do
                if type(point) == "table" and point[1] then
                    table.insert(result, {
                        zoneId = zoneId,
                        x = point[1],
                        y = point[2],
                    })
                end
            end
        end
    end
    return #result > 0 and result or nil
end

-- Extract quest prereqs one level deep
local function extractQuestInfo(questId)
    if not questId then return nil end
    local qdb = getQuestieDB()
    if not qdb then return nil end

    -- Try QueryQuestSingle first (lighter), fall back to GetQuest
    local name, preQuestGroup, preQuestSingle, requiredLevel, questLevel, nextQuest

    if qdb.QueryQuestSingle then
        name = qdb.QueryQuestSingle(questId, "name")
        preQuestGroup = qdb.QueryQuestSingle(questId, "preQuestGroup")
        preQuestSingle = qdb.QueryQuestSingle(questId, "preQuestSingle")
        requiredLevel = qdb.QueryQuestSingle(questId, "requiredLevel")
        questLevel = qdb.QueryQuestSingle(questId, "questLevel")
        nextQuest = qdb.QueryQuestSingle(questId, "nextQuestInChain")
    elseif qdb.GetQuest then
        local quest = qdb.GetQuest(questId)
        if quest then
            name = quest.name
            preQuestGroup = quest.preQuestGroup
            preQuestSingle = quest.preQuestSingle
            requiredLevel = quest.requiredLevel
            questLevel = quest.questLevel
            nextQuest = quest.nextQuestInChain
        end
    end

    if not name then return nil end

    local info = {
        name = name,
        level = questLevel,
        requiredLevel = requiredLevel,
    }

    -- Only include prereqs if they exist
    if preQuestGroup and #preQuestGroup > 0 then
        info.preQuestGroup = preQuestGroup
    end
    if preQuestSingle and #preQuestSingle > 0 then
        info.preQuestSingle = preQuestSingle
    end
    if nextQuest and nextQuest > 0 then
        info.nextQuestInChain = nextQuest
    end

    return info
end

-- Build quest details for an array of quest IDs
local function buildQuestDetails(questIds)
    if not questIds or type(questIds) ~= "table" or #questIds == 0 then
        return nil
    end

    local details = {}
    for _, questId in ipairs(questIds) do
        local info = extractQuestInfo(questId)
        if info then
            details[questId] = info
        end
    end
    return next(details) and details or nil
end

-- Extract all available data for a single NPC from Questie
local function extractNpcData(npcId)
    local qdb = getQuestieDB()
    if not qdb then return nil end

    local npc
    if qdb.GetNPC then
        npc = qdb.GetNPC(npcId)
    end
    if not npc then return nil end

    local result = {}

    -- Name and basic info
    result.questieName = npc.name
    result.friendlyToFaction = npc.friendlyToFaction
    if result.friendlyToFaction then
        result.factionReadable = FACTION_MAP[result.friendlyToFaction] or result.friendlyToFaction
    end

    -- Zone and location
    result.zoneID = npc.zoneID
    result.spawns = flattenSpawns(npc.spawns)

    -- NPC metadata
    if npc.minLevel then result.minLevel = npc.minLevel end
    if npc.maxLevel then result.maxLevel = npc.maxLevel end
    if npc.rank then result.rank = npc.rank end
    if npc.npcFlags then result.npcFlags = npc.npcFlags end
    if npc.subName then result.subName = npc.subName end

    -- Quest associations — the primary reason for this tool
    local questStarts = npc.questStarts
    local questEnds = npc.questEnds

    if questStarts and #questStarts > 0 then
        result.questStarts = questStarts
        result.questStartDetails = buildQuestDetails(questStarts)
    end

    if questEnds and #questEnds > 0 then
        result.questEnds = questEnds
        result.questEndDetails = buildQuestDetails(questEnds)
    end

    -- Dump any other non-function keys we haven't explicitly handled
    local handled = {
        name = true, friendlyToFaction = true, zoneID = true, spawns = true,
        minLevel = true, maxLevel = true, rank = true, npcFlags = true,
        subName = true, questStarts = true, questEnds = true,
        -- Internal Questie fields we skip
        Id = true, type = true,
    }

    for key, value in pairs(npc) do
        if not handled[key] and type(value) ~= "function" then
            result["_" .. key] = value
        end
    end

    return result
end

-- Main extraction routine
function questieExtract:run()
    local utils = Addon.utils

    if not utils:isDebugEnabled() then
        utils:error("Questie extract requires debug mode. Use /pao debug first.")
        return
    end

    -- Check for Questie
    local qdb = getQuestieDB()
    if not Questie and not qdb then
        utils:error("Questie not detected. Install and enable Questie, then reload.")
        return
    end

    if not qdb then
        utils:error("Questie DB not initialized yet. Try /pao questie dump to explore what's available.")
        return
    end

    if not qdb.GetNPC and not qdb.QueryNPCSingle then
        utils:error("Questie database API not found. Try /pao questie dump to inspect structure.")
        return
    end

    -- Gather our NPC IDs from all sources
    local npcIds = {}
    local dataStore = Addon.dataStore

    if dataStore then
        local allNpcs = dataStore:listEntities("npc")
        if allNpcs then
            for id in pairs(allNpcs) do
                npcIds[id] = true
            end
        end
    end

    -- Fallback: direct table access
    if not next(npcIds) and Addon.data and Addon.data.npcs then
        for id in pairs(Addon.data.npcs) do
            npcIds[id] = true
        end
    end

    local count = 0
    for _ in pairs(npcIds) do count = count + 1 end

    if count == 0 then
        utils:error("No NPCs found in our database to look up.")
        return
    end

    utils:notify(string.format("Extracting Questie data for %d NPCs...", count))

    -- Extract data
    local results = {}
    local found = 0
    local withQuests = 0

    for npcId in pairs(npcIds) do
        local data = extractNpcData(npcId)
        if data then
            -- Add our own name for cross-reference
            local ourNpc = dataStore and dataStore:getEntity("npc", npcId)
            if ourNpc then
                data.paoName = ourNpc.name
            end
            results[npcId] = data
            found = found + 1
            if data.questStarts or data.questEnds then
                withQuests = withQuests + 1
            end
        end
    end

    utils:notify(string.format(
        "Extraction complete: %d/%d NPCs found in Questie, %d with quest data.",
        found, count, withQuests
    ))

    -- Display in export window
    if Addon.ui and Addon.ui.showExportWindow then
        Addon.ui.showExportWindow(results)
    else
        utils:error("Export window not available. Results dumped to chat.")
        for npcId, data in pairs(results) do
            utils:debug(string.format("[%d] %s - quests: %s",
                npcId,
                data.questieName or "?",
                data.questStarts and table.concat(data.questStarts, ",") or "none"
            ))
        end
    end
end

-- ScrollingMessageFrame for viewing dump output
local dumpFrame = nil

local function getDumpFrame()
    if dumpFrame then return dumpFrame end

    local f = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    f:SetSize(700, 500)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    f:SetBackdropColor(0, 0, 0, 0.9)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")
    f:SetResizable(true)
    f:SetMinResize(400, 300)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)

    local smf = CreateFrame("ScrollingMessageFrame", nil, f)
    smf:SetPoint("TOPLEFT", 12, -12)
    smf:SetPoint("BOTTOMRIGHT", -32, 12)
    smf:SetFontObject(ChatFontNormal)
    smf:SetJustifyH("LEFT")
    smf:SetFading(false)
    smf:SetMaxLines(20000)
    smf:EnableMouseWheel(true)
    smf:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then
            self:ScrollUp()
        else
            self:ScrollDown()
        end
    end)

    -- Resize handle
    local resize = CreateFrame("Button", nil, f)
    resize:SetSize(16, 16)
    resize:SetPoint("BOTTOMRIGHT", -2, 2)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resize:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
    resize:SetScript("OnMouseUp", function() f:StopMovingOrSizing() end)

    f.smf = smf
    dumpFrame = f
    return f
end

function questieExtract:dump()
    local utils = Addon.utils

    if not Questie or not Questie.db then
        utils:error("Questie.db not available.")
        return
    end

    local frame = getDumpFrame()
    frame.smf:Clear()
    frame:Show()

    -- Feed lines directly into the ScrollingMessageFrame as captured
    local lineCount = 0
    local chatFrame = DEFAULT_CHAT_FRAME
    local orig = chatFrame.AddMessage
    chatFrame.AddMessage = function(self, msg, ...)
        lineCount = lineCount + 1
        frame.smf:AddMessage(tostring(msg))
    end

    DevTools_Dump(Questie.db)

    chatFrame.AddMessage = orig

    utils:notify(string.format("Questie dump: %d lines displayed.", lineCount))
end

-- Save Questie.db dump to SavedVariable for file access
-- luacheck: globals pao_tools
function questieExtract:sv()
    local utils = Addon.utils

    if not Questie or not Questie.db then
        utils:error("Questie.db not available.")
        return
    end

    local captured = {}
    local chatFrame = DEFAULT_CHAT_FRAME
    local orig = chatFrame.AddMessage
    chatFrame.AddMessage = function(self, msg, ...)
        table.insert(captured, tostring(msg))
    end

    DevTools_Dump(Questie.db)

    chatFrame.AddMessage = orig

    pao_tools = pao_tools or {}
    pao_tools.questie_dump = table.concat(captured, "\n")

    utils:notify(string.format(
        "Questie dump saved to pao_tools.questie_dump (%d lines, %d chars).",
        #captured, #pao_tools.questie_dump
    ))
end

-- Fabled beast quest IDs
local FABLED_QUEST_IDS = { 32604, 32868, 32869 }

-- ============================================================================
-- POST-HARVEST CORRECTIONS
-- Fixes for known Questie data issues that require manual curation
-- ============================================================================

local NPC_CORRECTIONS = {
    -- Hyjal phased stable masters: Questie reports "AH" (neutral) but each
    -- faction sees a different NPC ID. We store both with correct faction.
    [43494] = { faction = "FACTION.HORDE" },   -- Oltarin Graycloud (Horde)
    [50069] = { faction = "FACTION.ALLIANCE" }, -- Oltarin Graycloud (Alliance)
    [43379] = { faction = "FACTION.HORDE" },   -- Limiah Whitebranch (Horde)
    [53780] = { faction = "FACTION.ALLIANCE" }, -- Limiah Whitebranch (Alliance)
}

-- Apply corrections to harvested results
local function applyCorrections(results)
    local correctionCount = 0
    for npcId, corrections in pairs(NPC_CORRECTIONS) do
        if results[npcId] then
            for field, value in pairs(corrections) do
                results[npcId][field] = value
            end
            correctionCount = correctionCount + 1
        end
    end
    return correctionCount
end

-- NPC flag for vendor detection (MoP/non-Classic value)
local NPC_FLAG_VENDOR = 128

-- Item class/subClass for companion pets
local ITEM_CLASS_MISC = 15
local ITEM_SUBCLASS_COMPANION = 2

-- Garbage NPC name patterns (developer/test NPCs)
local GARBAGE_NAME_PATTERNS = {
    "^%[Deprecated",      -- [Deprecated for X.x]
    "UNUSED",             -- UNUSED suffix
    "Programmer",         -- Developer NPCs
    "GM can see",         -- GM-only waypoints
    "Tweedle",            -- Test NPCs (Tweedle Dee/Dum)
}

-- Garbage title patterns
local GARBAGE_TITLE_PATTERNS = {
    "^Visual$",           -- Visual markers
    "^NPC$",              -- Generic test title
    "^Testing$",          -- Test NPCs
    "^Questgiver$",       -- Generic questgiver markers
}

-- Check if NPC name matches any garbage pattern
local function isGarbageName(name)
    if not name then return true end
    for _, pattern in ipairs(GARBAGE_NAME_PATTERNS) do
        if name:find(pattern) then return true end
    end
    return false
end

-- Check if NPC title matches any garbage pattern
local function isGarbageTitle(title)
    if not title then return false end
    for _, pattern in ipairs(GARBAGE_TITLE_PATTERNS) do
        if title:find(pattern) then return true end
    end
    return false
end

-- Check if NPC has valid locations (not empty, not all -1,-1)
local function hasValidLocations(spawns)
    if not spawns or type(spawns) ~= "table" then return false end
    
    for _, coords in pairs(spawns) do
        if type(coords) == "table" then
            for _, point in ipairs(coords) do
                if type(point) == "table" and point[1] and point[2] then
                    -- Valid if not -1, -1
                    if point[1] >= 0 and point[2] >= 0 then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- Check if NPC has a valid trainer title (Battle Pet Trainer)
local function hasTrainerTitle(npc)
    if not npc.subName then return false end
    local title = npc.subName:lower()
    return title:find("trainer") ~= nil
end

-- Validate NPC for inclusion in harvest output
-- Returns true if NPC should be included, false if garbage
local function isValidNpc(npc, expectedTitle)
    if not npc or not npc.name then return false end
    
    -- Check garbage patterns
    if isGarbageName(npc.name) then return false end
    if isGarbageTitle(npc.subName) then return false end
    
    -- If we expect a specific title (like "Stable Master"), require it
    -- This filters out mobs incorrectly flagged as stable masters
    if expectedTitle and npc.subName ~= expectedTitle then
        return false
    end
    
    -- Must have at least one valid spawn location
    if not hasValidLocations(npc.spawns) then return false end
    
    return true
end

-- Pet item name patterns (case-insensitive matching)
local PET_ITEM_PATTERNS = {
    "battle%-stone",
    "battle%-training stone",
    "pet bandage",
    "pet treat",
    "leash",
    "sack of pet supplies",
    "pandaren spirit pet supplies",
    "fabled pandaren pet supplies",
    "darkmoon pet supplies",
}

-- Check if item name matches any pet item pattern
local function isPetItemByName(itemName)
    if not itemName then return false end
    local lowerName = itemName:lower()
    for _, pattern in ipairs(PET_ITEM_PATTERNS) do
        if lowerName:find(pattern) then
            return true
        end
    end
    return false
end

-- Build map of NPC IDs to item arrays for pet-related vendors
-- Finds: companion pets (class 15/subclass 2) + items matching pet item patterns
local function buildPetVendorSet(qdb)
    local petVendors = {}  -- {npcId = {itemId, itemId, ...}}
    local itemCount = 0
    local vendorCount = 0
    
    if not qdb.ItemPointers then
        return petVendors, 0, 0
    end
    
    for itemId in pairs(qdb.ItemPointers) do
        local isPetItem = false
        
        -- Check class/subclass for companion pets
        local class = qdb.QueryItemSingle(itemId, "class")
        local subClass = qdb.QueryItemSingle(itemId, "subClass")
        if class == ITEM_CLASS_MISC and subClass == ITEM_SUBCLASS_COMPANION then
            isPetItem = true
        end
        
        -- Check name patterns for other pet items
        if not isPetItem then
            local itemName = qdb.QueryItemSingle(itemId, "name")
            if isPetItemByName(itemName) then
                isPetItem = true
            end
        end
        
        if isPetItem then
            itemCount = itemCount + 1
            local vendors = qdb.QueryItemSingle(itemId, "vendors")
            if vendors and type(vendors) == "table" then
                for _, npcId in ipairs(vendors) do
                    if not petVendors[npcId] then
                        petVendors[npcId] = {}
                        vendorCount = vendorCount + 1
                    end
                    table.insert(petVendors[npcId], itemId)
                end
            end
        end
    end
    
    return petVendors, itemCount, vendorCount
end

-- Check if NPC has vendor flag in npcFlags bitmask
local function hasVendorFlag(npc)
    if not npc.npcFlags then return false end
    return bit.band(npc.npcFlags, NPC_FLAG_VENDOR) > 0
end

-- Resolve mapID to continent ID using C_Map hierarchy
local function getContinentFromMapID(mapID)
    if not mapID or mapID == 0 then return nil end
    if not C_Map or not C_Map.GetMapInfo then return nil end
    
    local mapInfo = C_Map.GetMapInfo(mapID)
    if not mapInfo then return nil end
    
    -- Walk up hierarchy to find continent
    local maxIterations = 10
    local iterations = 0
    while mapInfo and mapInfo.parentMapID and iterations < maxIterations do
        iterations = iterations + 1
        local parentInfo = C_Map.GetMapInfo(mapInfo.parentMapID)
        if not parentInfo then break end
        
        -- Cosmic (946) or Azeroth (947) = parent of continents
        if parentInfo.mapID == 946 or parentInfo.mapID == 947 then
            return mapInfo.mapID
        end
        
        mapInfo = parentInfo
    end
    
    return mapInfo and mapInfo.mapID or nil
end

-- Convert Questie spawns to our locations format
-- Skips invalid -1,-1 coordinates (legacy/placeholder data)
local function convertSpawns(spawns, zoneDB)
    if not spawns or type(spawns) ~= "table" then return nil end
    
    local locations = {}
    for areaId, coords in pairs(spawns) do
        local mapID = zoneDB and zoneDB.GetUiMapIdByAreaId and zoneDB:GetUiMapIdByAreaId(areaId)
        if mapID and type(coords) == "table" then
            local continent = getContinentFromMapID(mapID)
            for _, point in ipairs(coords) do
                if type(point) == "table" and point[1] and point[2] then
                    -- Skip -1,-1 placeholder coordinates
                    if point[1] >= 0 and point[2] >= 0 then
                        table.insert(locations, {
                            mapID = mapID,
                            continent = continent,
                            x = math.floor(point[1] * 100 + 0.5) / 100,
                            y = math.floor(point[2] * 100 + 0.5) / 100,
                        })
                    end
                end
            end
        end
    end
    return #locations > 0 and locations or nil
end

-- Convert friendlyToFaction to our faction format
local function convertFaction(friendlyToFaction)
    if friendlyToFaction == "A" then
        return "FACTION.ALLIANCE"
    elseif friendlyToFaction == "H" then
        return "FACTION.HORDE"
    end
    return nil -- neutral, omit field
end

-- Build NPC entry in our npcs.lua format
-- npcTypes can be a string or table of type strings to combine with bit.bor
-- sellsItems is optional array of item IDs for vendors
local function buildNpcEntry(npc, npcTypes, zoneDB, sellsItems)
    local entry = {
        name = npc.name,
    }
    
    -- Title intentionally not stored - used only transiently for classification
    
    -- Handle single type string or table of types
    if type(npcTypes) == "table" then
        entry.types = table.concat(npcTypes, " + ")
    else
        entry.types = npcTypes
    end
    
    local faction = convertFaction(npc.friendlyToFaction)
    if faction then
        entry.faction = faction
    end
    
    local locations = convertSpawns(npc.spawns, zoneDB)
    if locations then
        entry.locations = locations
    end
    
    if npc.questStarts and #npc.questStarts > 0 then
        entry.questStarts = npc.questStarts
    end
    
    if npc.questEnds and #npc.questEnds > 0 then
        entry.questEnds = npc.questEnds
    end
    
    if sellsItems and #sellsItems > 0 then
        entry.sellsItems = sellsItems
    end
    
    return entry
end

-- Main harvest function
function questieExtract:harvest()
    local utils = Addon.utils
    
    local qdb = getQuestieDB()
    if not qdb then
        utils:error("QuestieDB not available. Is Questie installed and loaded?")
        return
    end
    
    local zoneDB = getZoneDB()
    if not zoneDB then
        utils:error("ZoneDB not available.")
        return
    end
    
    -- Build pet vendor set first
    utils:notify("Building pet vendor set from item database...")
    local petVendors, petItemCount, petVendorCount = buildPetVendorSet(qdb)
    utils:notify(string.format("  Found %d pet-related items sold by %d unique vendors", 
        petItemCount, petVendorCount))
    
    local results = {}
    local counts = { trainers = 0, stables = 0, tamers = 0, spirits = 0, fabled = 0, vendors = 0, filtered = 0 }
    
    -- 1. Battle Pet Trainers from townsfolk (require trainer-like title)
    if Questie and Questie.db and Questie.db.global and Questie.db.global.townsfolk then
        local trainers = Questie.db.global.townsfolk["Battle Pet Trainer"]
        if trainers then
            for _, npcId in ipairs(trainers) do
                local npc = qdb:GetNPC(npcId)
                if npc and isValidNpc(npc, nil) and hasTrainerTitle(npc) then
                    -- Check if trainer is also a vendor
                    local types = { "NPC_TYPE.TRAINER" }
                    local sellsItems = nil
                    if hasVendorFlag(npc) or petVendors[npcId] then
                        table.insert(types, "NPC_TYPE.VENDOR")
                        sellsItems = petVendors[npcId]
                        counts.vendors = counts.vendors + 1
                    end
                    results[npcId] = buildNpcEntry(npc, types, zoneDB, sellsItems)
                    counts.trainers = counts.trainers + 1
                elseif npc then
                    counts.filtered = counts.filtered + 1
                end
            end
        end
        
        -- 2. Stable Masters from townsfolk (require "Stable Master" title)
        local stables = Questie.db.global.townsfolk["Stable Master"]
        if stables then
            for _, npcId in ipairs(stables) do
                local npc = qdb:GetNPC(npcId)
                if npc and isValidNpc(npc, "Stable Master") then
                    -- Check if stable master is also a vendor
                    local types = { "NPC_TYPE.STABLE_MASTER" }
                    local sellsItems = nil
                    if hasVendorFlag(npc) or petVendors[npcId] then
                        table.insert(types, "NPC_TYPE.VENDOR")
                        sellsItems = petVendors[npcId]
                        counts.vendors = counts.vendors + 1
                    end
                    results[npcId] = buildNpcEntry(npc, types, zoneDB, sellsItems)
                    counts.stables = counts.stables + 1
                elseif npc then
                    counts.filtered = counts.filtered + 1
                end
            end
        end
    end
    
    -- 3. Tamers, 4. Spirits via NPCPointers iteration
    if qdb.NPCPointers then
        for npcId in pairs(qdb.NPCPointers) do
            if not results[npcId] then
                local npc = qdb:GetNPC(npcId)
                if npc and isValidNpc(npc, nil) then
                    -- Check for Spirit first (more specific)
                    if npc.name and npc.name:find("Pandaren Spirit") and npc.questStarts then
                        results[npcId] = buildNpcEntry(npc, "NPC_TYPE.SPIRIT", zoneDB)
                        counts.spirits = counts.spirits + 1
                    -- Then check for Tamer
                    elseif npc.subName and npc.subName:lower():find("pet tamer") then
                        results[npcId] = buildNpcEntry(npc, "NPC_TYPE.TAMER", zoneDB)
                        counts.tamers = counts.tamers + 1
                    end
                end
            end
        end
    end
    
    -- 5. Fabled beasts from quest objectives
    for _, questId in ipairs(FABLED_QUEST_IDS) do
        local quest = qdb.GetQuest and qdb.GetQuest(questId)
        if quest and quest.ObjectiveData then
            for _, obj in ipairs(quest.ObjectiveData) do
                if obj.Type == "monster" and obj.Id then
                    local npcId = obj.Id
                    if not results[npcId] then
                        local npc = qdb:GetNPC(npcId)
                        if npc and isValidNpc(npc, nil) then
                            results[npcId] = buildNpcEntry(npc, "NPC_TYPE.FABLED", zoneDB)
                            counts.fabled = counts.fabled + 1
                        elseif npc then
                            counts.filtered = counts.filtered + 1
                        end
                    end
                end
            end
        end
    end
    
    -- 6. Add standalone pet vendors (not already captured as trainers/stable masters)
    -- Check if vendor is actually a Stable Master and add both types if so
    for npcId, itemIds in pairs(petVendors) do
        if not results[npcId] then
            local npc = qdb:GetNPC(npcId)
            if npc and isValidNpc(npc, nil) then
                if npc.subName == "Stable Master" then
                    results[npcId] = buildNpcEntry(npc, {"NPC_TYPE.STABLE_MASTER", "NPC_TYPE.VENDOR"}, zoneDB, itemIds)
                    counts.stables = counts.stables + 1
                    counts.vendors = counts.vendors + 1
                else
                    results[npcId] = buildNpcEntry(npc, "NPC_TYPE.VENDOR", zoneDB, itemIds)
                    counts.vendors = counts.vendors + 1
                end
            elseif npc then
                counts.filtered = counts.filtered + 1
            end
        end
    end
    
    -- 7. Apply post-harvest corrections for known Questie data issues
    local correctionCount = applyCorrections(results)
    
    -- Print summary to chat
    local total = counts.trainers + counts.stables + counts.tamers + counts.spirits + counts.fabled + counts.vendors
    utils:notify(string.format("Harvest complete: %d NPCs total (%d filtered, %d corrected)", 
        total, counts.filtered, correctionCount))
    utils:notify(string.format("  Trainers: %d, Stable Masters: %d, Tamers: %d", 
        counts.trainers, counts.stables, counts.tamers))
    utils:notify(string.format("  Spirits: %d, Fabled: %d, Vendors: %d", counts.spirits, counts.fabled, counts.vendors))
    
    -- Display in export window
    if Addon.ui and Addon.ui.showExportWindow then
        Addon.ui.showExportWindow(results)
    else
        utils:error("Export window not available.")
    end
end

-- Register command
if Addon.registerModule then
    Addon.registerModule("questieExtract", {"utils", "commands", "dataStore"}, function()
        local commands = Addon.commands

        commands:register({
            command = "questie",
            handler = function(args)
                local action = args.action and args.action:lower() or ""
                if action == "extract" then
                    questieExtract:run()
                elseif action == "dump" then
                    questieExtract:dump()
                elseif action == "sv" then
                    questieExtract:sv()
                elseif action == "harvest" then
                    questieExtract:harvest()
                else
                    Addon.utils:notify("Questie Tools:")
                    Addon.utils:notify("  /pao questie extract - Extract NPC/quest data from Questie DB")
                    Addon.utils:notify("  /pao questie dump    - View Questie.db in scrollable frame")
                    Addon.utils:notify("  /pao questie sv      - Save Questie.db dump to SavedVariable")
                    Addon.utils:notify("  /pao questie harvest - Harvest all pet battle NPCs to npcs.lua format")
                end
            end,
            help = "Questie data extraction tools",
            usage = "questie |cFFFFCC9A<action>|r",
            args = {
                { name = "action", required = false, description = "Action: extract, dump, sv, harvest" },
            },
            category = "Tools"
        })

        return true
    end)
end

Addon.questieExtract = questieExtract
return questieExtract