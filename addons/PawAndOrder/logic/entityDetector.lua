-- core/entityDetector.lua
-- Battle-based entity detection with plugin registration

local _, Addon = ...

local utils = Addon.utils
local events = nil -- Will be initialized when module loads

local entityDetector = {
    classifications = {}, -- Registered NPC type classification rules
    pendingEntity = nil   -- Stores NPC info captured pre-battle
}

-- Strip WoW color codes from text (e.g., "|cff00c200<Grand Master Pet Tamer>|r" -> "Grand Master Pet Tamer")
local function stripColorCodes(text)
    if not text then return nil end
    -- Remove |cXXXXXXXX color start codes
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")
    -- Remove |r color end codes
    text = text:gsub("|r", "")
    -- Remove angle brackets that sometimes wrap titles
    text = text:gsub("^<", ""):gsub(">$", "")
    -- Trim whitespace
    text = text:match("^%s*(.-)%s*$")
    return text ~= "" and text or nil
end

-- Capture ability data during battles
local function captureAbility(abilityId)
    -- Check if ability already exists (static or SV)
    if Addon.dataStore and Addon.dataStore:getEntity("ability", abilityId) then
        return
    end
    
    local id, name, icon, maxCooldown, unparsedDescription, numTurns, petType, noStrongWeakHints = 
        C_PetBattles.GetAbilityInfoByID(abilityId)
    
    local abilityData = {
        name = name or ("Unknown " .. abilityId),
        description = unparsedDescription,
        icon = icon,
        cooldown = maxCooldown,
        duration = numTurns,
        familyType = petType,
        harvestedAt = date("%Y-%m-%d %H:%M:%S"),
        harvestedFrom = "battle"
    }
    
    if Addon.dataStore then
        Addon.dataStore:addEntity("ability", abilityId, abilityData)
    else
        -- Fallback if dataStore not ready yet
        if not pao_ability then
            pao_ability = {}
        end
        pao_ability[abilityId] = abilityData
    end
end

-- Extract title from GameTooltip (returns clean title without color codes)
local function extractTitleFromTooltip(unit)
    if not unit or not UnitExists(unit) then return nil end
    
    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    GameTooltip:SetUnit(unit)
    local titleLine = _G["GameTooltipTextLeft2"]
    local title = nil
    
    if titleLine and titleLine:IsShown() then
        local text = titleLine:GetText()
        if text and text ~= "" and not text:find("Level") and not text:find("Wild Pet") then
            local npcName = UnitName(unit) or ""
            -- Strip color codes before comparison and storage
            local cleanText = stripColorCodes(text)
            if cleanText and cleanText ~= npcName then
                title = cleanText
            end
        end
    end
    
    GameTooltip:Hide()
    return title
end

-- Extract pet battle opponent data
local function extractBattlePets()
    if not C_PetBattles or not C_PetBattles.IsInBattle() then
        return nil, nil
    end

    local pets = {}
    local petOrder = {}
    local numPets = C_PetBattles.GetNumPets(2) -- enemy team

    for i = 1, numPets do
        local speciesID = C_PetBattles.GetPetSpeciesID(2, i)
        local level = C_PetBattles.GetLevel(2, i)
        local maxHealth = C_PetBattles.GetMaxHealth(2, i)
        local power = C_PetBattles.GetPower(2, i)
        local speed = C_PetBattles.GetSpeed(2, i)
        local quality = C_PetBattles.GetBreedQuality(2, i)
        local petName = C_PetBattles.GetName(2, i)

        -- Get additional pet info from species database
        local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, 
              isWildOnly, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID = 
              C_PetJournal.GetPetInfoBySpeciesID(speciesID)

        -- Capture abilities for this pet
        local abilities = {}
        for slot = 1, 3 do
            local abilityID = C_PetBattles.GetAbilityInfo(2, i, slot)
            if abilityID then
                table.insert(abilities, abilityID)
                captureAbility(abilityID)
            end
        end

        local petData = {
            speciesID = speciesID,
            name = petName,
            level = level,
            quality = quality,
            maxHealth = maxHealth,
            power = power,
            speed = speed,
            familyType = petType,
            icon = speciesIcon,
            displayID = creatureDisplayID,
            abilities = abilities
        }

        table.insert(pets, petData)
        table.insert(petOrder, speciesID)
    end

    return pets, petOrder
end

-- Extract NPC information from current target
local function extractEntityInfo()
    if not UnitExists("target") then
        utils:debug("extractEntityInfo: No target exists")
        return nil
    end

    local guid = UnitGUID("target")
    if not guid then
        utils:debug("extractEntityInfo: UnitGUID returned nil")
        return nil
    end

    -- npcUtils accessed at runtime, not declared as dependency to avoid circular:
    -- entityDetector -> npcUtils -> npcs -> entityDetector
    -- Safe because extractEntityInfo only runs during battle events, long after init.
    local creatureID = Addon.npcUtils:getCreatureId(guid)
    if not creatureID then
        utils:debug("extractEntityInfo: Could not parse creature ID from GUID: " .. tostring(guid))
        return nil
    end
    
    -- Skip wild pets - they're not trackable entities
    -- DISABLED: Fabled beasts return "Wild Pet" but are trackable. The filter
    -- now happens in onBattleStart where we can distinguish by pet count.
    -- local creatureType = UnitCreatureType("target")
    -- if creatureType == "Wild Pet" or creatureType == "Not specified" then
    --     return nil
    -- end

    local name = UnitName("target") or "Unknown"
    local title = extractTitleFromTooltip("target") or ""
    local factionStr = UnitFactionGroup("target")
    local faction = factionStr and Addon.FACTION[factionStr:upper()] or nil
    
    -- Get race and gender
    local race = UnitRace("target")
    local sexCode = UnitSex("target")
    local gender = nil
    if sexCode == 2 then
        gender = "male"
    elseif sexCode == 3 then
        gender = "female"
    end

    -- Get location
    local currentLoc
    if Addon.location and Addon.location.getCurrentPlayerLocation then
        currentLoc = Addon.location:getCurrentPlayerLocation()
    else
        utils:debug("extractEntityInfo: location module not available")
        return nil
    end
    
    if not currentLoc then
        utils:debug("extractEntityInfo: getCurrentPlayerLocation returned nil")
        return nil
    end
    
    if not currentLoc.mapID then
        utils:debug("extractEntityInfo: currentLoc.mapID is nil")
        return nil
    end

    -- All location data goes inside the location entry (including subzone)
    return {
        npcID = creatureID,
        name = name,
        title = title,
        displayID = 0, -- Placeholder for NPC model display ID (to be added manually from creature db2)
        faction = faction,
        race = race,
        gender = gender,
        locations = {
            {
                mapID = currentLoc.mapID or 0,
                continent = currentLoc.continent,
                x = currentLoc.x,
                y = currentLoc.y,
                subzone = currentLoc.subzone
            }
        },
        lastUpdated = date("%Y-%m-%d %H:%M:%S"),
        autoDetected = true,
    }
end

-- Classify entity against registered rules, returns bit flag and needsPets
local function classifyEntity(info)
    local name = info.name:lower()
    local title = info.title:lower()

    -- Sort classifications by priority (highest first)
    local sorted = {}
    for _, classification in ipairs(entityDetector.classifications) do
        table.insert(sorted, classification)
    end
    table.sort(sorted, function(a, b)
        return (a.priority or 0) > (b.priority or 0)
    end)

    -- First match wins (highest priority)
    for _, classification in ipairs(sorted) do
        local rules = classification.rules

        if rules.keywords then
            for _, keyword in ipairs(rules.keywords) do
                if name:find(keyword, 1, true) then
                    return classification.flag, classification.needsPets
                end
            end
        end

        if rules.titles then
            for _, pattern in ipairs(rules.titles) do
                if title:find(pattern, 1, true) then
                    return classification.flag, classification.needsPets
                end
            end
        end
    end

    return nil, false
end

-- Check gossip options for a specific type (available after GOSSIP_SHOW fires)
local function hasGossipType(targetType)
    if not C_GossipInfo or not C_GossipInfo.GetOptions then return false end
    local options = C_GossipInfo.GetOptions()
    for _, option in ipairs(options) do
        if option.type == targetType then
            return true
        end
    end
    return false
end

-- Register a classification rule for NPC type detection
function entityDetector:registerClassification(config)
    if not config.flag then
        utils:error("entityDetector: Cannot register classification - missing flag")
        return false
    end

    table.insert(self.classifications, config)
    return true
end

-- Pre-battle: Capture NPC info when target is available
function entityDetector:onPreBattle(eventName)
    -- Clear any stale pending entity from previous battle
    self.pendingEntity = nil
    
    local info = extractEntityInfo()
    if not info then
        utils:debug("entityDetector: Could not extract entity info from target")
        return
    end
    
    local typeFlag, needsPets = classifyEntity(info)
    
    -- Check gossip options for vendor capability
    local isVendor = hasGossipType("vendor")
    
    -- Always capture entity info - we'll determine if it's trackable during battle
    self.pendingEntity = {
        info = info,
        typeFlag = typeFlag,     -- might be nil (fabled beasts, wild pets)
        needsPets = needsPets,
        isVendor = isVendor
    }
end

-- Battle start: Capture pets and commit everything
function entityDetector:onBattleStart()
    C_Timer.After(0.1, function()
        if not self.pendingEntity then
            return
        end
        
        local NPC_TYPE = Addon.NPC_TYPE
        local info = self.pendingEntity.info
        local typeFlag = self.pendingEntity.typeFlag
        local needsPets = self.pendingEntity.needsPets
        local isVendor = self.pendingEntity.isVendor
        
        -- Check if this is a single-pet battle (fabled beast)
        local numPets = C_PetBattles.GetNumPets(2)
        local isFabledBeast = (numPets == 1)
        
        if isFabledBeast then
            -- Override classification - all single-pet battles are fabled beasts
            typeFlag = NPC_TYPE.FABLED
            needsPets = true
            -- Keep title for fabled beasts - it's their identity (e.g., "No-No", "Dos-Ryga")
        else
            -- Non-fabled: title was only used for classification, don't store it
            info.title = nil
            
            if not typeFlag then
                -- Multi-pet battle with no classification = wild pet battle
                return
            end
        end
        
        -- OR in vendor flag if gossip indicated vendor capability
        if isVendor then
            typeFlag = bit.bor(typeFlag, NPC_TYPE.VENDOR)
        end
        
        -- Set unified entity type and type flags
        info.entityType = "npc"
        info.types = typeFlag
        
        -- Update timestamp at commit time
        info.lastUpdated = date("%Y-%m-%d %H:%M:%S")
        
        -- Capture pets if classification needs them
        if needsPets then
            local pets, petOrder = extractBattlePets()
            if pets then
                info.pets = pets
                info.petOrder = petOrder
                info.staticOrder = true
                
                -- For fabled beasts, copy the pet's displayID to the owner level
                if isFabledBeast and #pets == 1 and pets[1].displayID then
                    info.displayID = pets[1].displayID
                end
            else
                utils:debug("entityDetector: Failed to capture pets for " .. info.name)
            end
        end
        
        -- Commit to storage
        if Addon.entityCommitter and Addon.entityCommitter.commit then
            Addon.entityCommitter:commit(info)
        else
            utils:error("entityDetector: entityCommitter not available")
        end
    end)
end

-- Initialize event listeners
function entityDetector:initialize()
    events = Addon.events
    
    if not events then
        utils:error("entityDetector: Events system not available")
        return false
    end
    
    -- Register pre-battle events
    events:subscribe("GOSSIP_CONFIRM", function(event)
        entityDetector:onPreBattle(event)
    end)
    
    events:subscribe("PLAYER_CONTROL_LOST", function(event)
        entityDetector:onPreBattle(event)
    end)
    
    -- Register battle start event
    events:subscribe("PET_BATTLE_OPENING_START", function(event)
        entityDetector:onBattleStart()
    end)
    
    return true
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("entityDetector", {"utils", "location", "dataStore", "abilities", "entityCommitter", "events"}, function()
        if entityDetector:initialize() then
            return true
        end
        return false
    end)
end

Addon.entityDetector = entityDetector
return entityDetector