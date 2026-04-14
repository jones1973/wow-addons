-- tools/harvestPets.lua - Pet Data Harvesting System
local ADDON_NAME, Addon = ...
local utils = Addon.utils
local time, date = time, date

-- Module reference
local harvestPets = {}

-- Harvest state
local harvestState = {
    isHarvesting = false,
    startTime = 0,
    processedPets = 0,
    enhancedPets = 0,
    totalPets = 0,
    harvestedData = {},
    savedState = {}
}

-- Store original Pet Journal state
local function storePetJournalState()
    harvestState.savedState = {
        searchText = C_PetJournal.GetSearchFilter(),
        sourceFilter = C_PetJournal.GetPetSourceFilter(),
        typeFilters = {}
    }
    
    for i = 1, C_PetJournal.GetNumPetTypes() do
        harvestState.savedState.typeFilters[i] = C_PetJournal.IsPetTypeFilterChecked(i)
    end
    
    utils:debug("Stored Pet Journal state")
end

-- Restore Pet Journal state
local function restorePetJournalState()
    if next(harvestState.savedState) then
        C_PetJournal.SetSearchFilter(harvestState.savedState.searchText or "")
        C_PetJournal.SetAllPetSourcesFilter(false)
        C_PetJournal.SetPetSourceFilter(harvestState.savedState.sourceFilter)
        
        for petType, isChecked in pairs(harvestState.savedState.typeFilters) do
            C_PetJournal.SetPetTypeFilter(petType, isChecked)
        end
        
        harvestState.savedState = {}
        utils:debug("Restored Pet Journal state")
    end
end

-- Clear all Pet Journal filters
local function clearAllPetJournalFilters()
    C_PetJournal.SetSearchFilter("")
    C_PetJournal.SetAllPetSourcesFilter(true)
    C_PetJournal.SetAllPetTypesChecked(true)
    C_PetJournal.ClearSearchFilter()
    
    utils:debug("Cleared all Pet Journal filters")
    return true
end

-- Get species acquisition data from static database
local function getSpeciesAcquisitionData(speciesID)
    if not Addon.data or not Addon.data.pets or not Addon.data.pets[speciesID] then
        return {
            acquisitionBroad = "UNKNOWN",
            acquisitionDetailed = "Unknown",
            zone = "Unknown",
            patch = "Unknown"
        }
    end
    
    local petData = Addon.data.pets[speciesID]
    
    return {
        acquisitionBroad = petData.acquisition or "UNKNOWN",
        acquisitionDetailed = petData.acquisitionDetails or "Unknown",
        zone = petData.zone or "Unknown",
        patch = petData.patch or "Unknown"
    }
end

-- Harvest single pet data
local function harvestSinglePet(petIndex, includeUnowned)
    local petID, speciesID, isOwned = C_PetJournal.GetPetInfoByIndex(petIndex)
    
    if not speciesID or (not isOwned and not includeUnowned) then
        return nil
    end
    
    -- Get core pet data from API
    local name, icon, petType, _, description = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    local tradeable, unique = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    
    -- Get acquisition data from static database
    local acquisitionData = getSpeciesAcquisitionData(speciesID)
    
    -- Build pet data structure
    local petData = {
        speciesId = speciesID,
        name = name or "Unknown Pet",
        icon = icon,
        petType = petType,
        description = description or "",
        tradeable = tradeable,
        unique = unique,
        canBattle = C_PetJournal.GetPetAbilityInfo(1, 1, petID) ~= nil,
        
        -- Static database fields
        acquisitionBroad = acquisitionData.acquisitionBroad,
        acquisitionDetailed = acquisitionData.acquisitionDetailed,
        zone = acquisitionData.zone,
        patch = acquisitionData.patch
    }
    
    -- Debug logging to show data source prioritization
    local gameDataCount = 0
    local staticDataCount = 0
    
    -- Count game API data points
    if petData.name ~= "Unknown Pet" then gameDataCount = gameDataCount + 1 end
    if petData.description and petData.description ~= "" then gameDataCount = gameDataCount + 1 end
    if petData.tradeable ~= nil then gameDataCount = gameDataCount + 1 end
    if petData.canBattle ~= nil then gameDataCount = gameDataCount + 1 end
    
    -- Count static data points
    if petData.acquisitionBroad ~= "UNKNOWN" then staticDataCount = staticDataCount + 1 end
    if petData.patch ~= "Unknown" then staticDataCount = staticDataCount + 1 end
    
    utils:debug(string.format("Pet %d (%s): %d game data points, %d static data points", 
        speciesID, petData.name, gameDataCount, staticDataCount))
    
    return petData
end

-- Harvest pets in batches
local function harvestBatch(startIndex, endIndex)
    local batchData = {}
    local processed = 0
    local enhanced = 0
    
    for petIndex = startIndex, endIndex do
        local petData = harvestSinglePet(petIndex, true) -- Include unowned pets
        
        if petData then
            table.insert(batchData, petData)
            harvestState.harvestedData[petData.speciesId] = petData
            
            processed = processed + 1
            if petData.acquisitionBroad ~= "UNKNOWN" then
                enhanced = enhanced + 1
            end
        end
        
        harvestState.processedPets = harvestState.processedPets + 1
    end
    
    harvestState.enhancedPets = harvestState.enhancedPets + enhanced
    
    utils:debug(string.format("Batch %d-%d: %d pets processed, %d enhanced", 
        startIndex, endIndex, processed, enhanced))
    
    return batchData
end

-- Main harvesting function
local function startPetHarvest()
    if harvestState.isHarvesting then
        utils:error("Pet harvest already in progress")
        return
    end
    
    -- Initialize harvest
    harvestState.isHarvesting = true
    harvestState.startTime = time()
    harvestState.processedPets = 0
    harvestState.enhancedPets = 0
    harvestState.harvestedData = {}
    
    -- Store and clear Pet Journal state
    storePetJournalState()
    if not clearAllPetJournalFilters() then
        harvestState.isHarvesting = false
        return
    end
    
    -- Get total pet count
    local numPets, numOwned = C_PetJournal.GetNumPets()
    harvestState.totalPets = numPets
    
    utils:notify(string.format("🐾 Starting pet harvest (%d total pets)...", numPets))
    
    -- Harvest in batches of 50
    local batchSize = 50
    for startIndex = 1, numPets, batchSize do
        local endIndex = math.min(startIndex + batchSize - 1, numPets)
        harvestBatch(startIndex, endIndex)
        
        -- Progress update every batch
        local progress = math.floor((harvestState.processedPets / numPets) * 100)
        print(string.format("Progress: %d/%d pets (%d%%)", harvestState.processedPets, numPets, progress))
    end
    
    -- Complete harvest
    completePetHarvest()
end

-- Complete the harvest
local function completePetHarvest()
    local harvestDuration = time() - harvestState.startTime
    
    restorePetJournalState()
    
    utils:notify("🎉 Pet harvest complete!")
    utils:notify(string.format("📊 Final Stats:"))
    utils:notify(string.format("  Total pets processed: %d", harvestState.processedPets))
    utils:notify(string.format("  Pets with acquisition data: %d", harvestState.enhancedPets))
    utils:notify(string.format("  Enhancement rate: %d%%", 
        math.floor((harvestState.enhancedPets / harvestState.processedPets) * 100)))
    utils:notify(string.format("  Harvest duration: %d seconds", harvestDuration))
    utils:notify("📋 Data Sources:")
    utils:notify("  ✅ Pet names, stats, abilities: Pet Journal API")
    utils:notify("  ✅ Acquisition methods, zones: Static database")
    utils:notify("  ✅ Game data prioritized over static data")
    
    -- Store harvested data
    if pao_pet then
        pao_pet.version = "2.2.0"
        pao_pet.harvestDate = date("%Y-%m-%d %H:%M:%S")
        pao_pet.totalPets = harvestState.processedPets
        pao_pet.enhancedPets = harvestState.enhancedPets
        pao_pet.pets = harvestState.harvestedData
        
        utils:notify("💾 Pet data saved to pao_pet SavedVariable")
    end
    
    harvestState.isHarvesting = false
end

-- Sample diverse pets for formula derivation
local function samplePetsForFormula()
    local numPets, numOwned = C_PetJournal.GetNumPets()
    
    utils:debug(string.format("Total pets: %d, Owned: %d", numPets, numOwned))
    
    if numOwned == 0 then
        utils:error("You don't own any pets to sample")
        return
    end
    
    -- Check if Battle Pet BreedID is available
    local breedDetector = GetBreedID_Journal
    if not breedDetector then
        utils:debug("GetBreedID_Journal not found")
    else
        utils:debug("Using GetBreedID_Journal for breed detection")
    end
    
    -- Collection tracking for diversity - separate buckets
    local levelBuckets = {
        [1] = {},   -- Level 1 pets
        [5] = {},   -- Level 2-9 pets
        [10] = {},  -- Level 10-14 pets
        [15] = {},  -- Level 15-19 pets
        [20] = {},  -- Level 20-24 pets
        [25] = {}   -- Level 25 pets
    }
    local qualityBuckets = {
        [1] = {},  -- Poor
        [2] = {},  -- Common
        [3] = {},  -- Uncommon
        [4] = {}   -- Rare
    }
    
    -- Iterate through all pets and sort into buckets
    for petIndex = 1, numPets do
        -- Get basic pet info (MoP API returns only 3 values)
        local petID, speciesID, isOwned = C_PetJournal.GetPetInfoByIndex(petIndex)
        
        if isOwned and petID and speciesID then
            -- Get pet stats
            local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
            
            if health and power and speed and rarity then
                -- Get species info for name
                local speciesName = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
                
                -- Get custom name and level
                local customName, _, level = C_PetJournal.GetPetInfoByPetID(petID)
                
                if level then
                    -- Try to get breed from Battle Pet BreedID addon
                    local breedName = "???"
                    if breedDetector then
                        local result = breedDetector(petID)
                        if result and type(result) == "string" then
                            breedName = result
                        end
                    end
                    
                    -- Determine level bucket
                    local levelBucket = level == 1 and 1 or
                                       level < 10 and 5 or
                                       level < 15 and 10 or
                                       level < 20 and 15 or
                                       level < 25 and 20 or 25
                    
                    local petData = {
                        index = petIndex,
                        speciesID = speciesID,
                        name = customName or speciesName,
                        level = level,
                        quality = rarity,
                        health = health,
                        power = power,
                        speed = speed,
                        breedName = breedName
                    }
                    
                    -- Add to appropriate buckets
                    table.insert(levelBuckets[levelBucket], petData)
                    table.insert(qualityBuckets[rarity], petData)
                    
                    utils:debug(string.format("Pet %d: %s L%d Q%d H%d P%d S%d %s", 
                        petIndex, speciesName or "Unknown", level, rarity, 
                        health, power, speed, breedName))
                end
            end
        end
    end
    
    -- Sample from buckets to ensure diversity
    local samples = {}
    
    -- Priority 1: Get pets from each level bucket (10 per bucket max)
    for level, pets in pairs(levelBuckets) do
        utils:debug(string.format("Level bucket %d has %d pets", level, #pets))
        local count = 0
        for _, pet in ipairs(pets) do
            if count >= 10 then break end
            table.insert(samples, pet)
            count = count + 1
        end
    end
    
    utils:debug(string.format("After level sampling: %d pets", #samples))
    
    -- Priority 2: If we have < 60, add more from quality buckets we're missing
    if #samples < 60 then
        for quality, pets in pairs(qualityBuckets) do
            if #samples >= 60 then break end
            -- Check if this quality is underrepresented
            local qualityCount = 0
            for _, sample in ipairs(samples) do
                if sample.quality == quality then
                    qualityCount = qualityCount + 1
                end
            end
            
            if qualityCount < 15 then
                for _, pet in ipairs(pets) do
                    if #samples >= 60 then break end
                    -- Don't add duplicates
                    local alreadyAdded = false
                    for _, sample in ipairs(samples) do
                        if sample.index == pet.index then
                            alreadyAdded = true
                            break
                        end
                    end
                    if not alreadyAdded then
                        table.insert(samples, pet)
                    end
                end
            end
        end
    end
    
    utils:debug(string.format("After quality sampling: %d pets", #samples))
    
    -- Trim to 60 if needed
    while #samples > 60 do
        table.remove(samples)
    end
    
    -- Output results
    utils:notify(string.format("📊 Sampled %d pets for formula derivation:", #samples))
    if not breedDetector then
        utils:notify("⚠️ Battle Pet BreedID not detected - breed data unavailable")
    end
    utils:notify("Format: [Idx] Sp:### Lv:## Q:# H:### P:### S:### Breed Base:H/P/S")
    utils:notify("Quality: 1=Poor, 2=Common, 3=Uncommon, 4=Rare")
    utils:notify("─────────────────────────────────────────────────")
    
    -- Sort by level, then quality for readability
    table.sort(samples, function(a, b)
        if a.level ~= b.level then
            return a.level < b.level
        end
        return a.quality < b.quality
    end)
    
    for _, pet in ipairs(samples) do
        local output = string.format("[%d] Sp:%d Lv:%d Q:%d H:%d P:%d S:%d %s",
            pet.index, pet.speciesID, pet.level, pet.quality,
            pet.health, pet.power, pet.speed, pet.breedName)
        
        -- Add BPBID base stats if available
        if BPBID_Arrays and BPBID_Arrays.BasePetStats and BPBID_Arrays.BasePetStats[pet.speciesID] then
            local base = BPBID_Arrays.BasePetStats[pet.speciesID]
            output = output .. string.format(" Base:%.1f/%.1f/%.1f", base[1], base[2], base[3])
        end
        
        print(output)
    end
    
    utils:notify("─────────────────────────────────────────────────")
    utils:notify("Copy the output above and provide to Claude for analysis")
end

-- Show harvest status
function harvestPets:showStatus()
    if harvestState.isHarvesting then
        local progress = math.floor((harvestState.processedPets / harvestState.totalPets) * 100)
        local elapsed = time() - harvestState.startTime
        
        utils:notify("🐾 Pet Harvest Status:")
        utils:notify(string.format("  Progress: %d/%d pets (%d%%)", 
            harvestState.processedPets, harvestState.totalPets, progress))
        utils:notify(string.format("  Enhanced: %d pets", harvestState.enhancedPets))
        utils:notify(string.format("  Elapsed time: %d seconds", elapsed))
    else
        utils:notify("🐾 No pet harvest currently in progress")
        
        if pao_pet and pao_pet.harvestDate then
            utils:notify(string.format("📊 Last harvest: %s", pao_pet.harvestDate))
            utils:notify(string.format("  Total pets: %d", pao_pet.totalPets or 0))
            utils:notify(string.format("  Enhanced pets: %d", pao_pet.enhancedPets or 0))
        end
    end
end

-- Start harvest
function harvestPets:startHarvest()
    startPetHarvest()
end

-- Stop harvest
function harvestPets:stopHarvest()
    if harvestState.isHarvesting then
        harvestState.isHarvesting = false
        restorePetJournalState()
        utils:notify("🛑 Pet harvest stopped")
    else
        utils:notify("No pet harvest in progress to stop")
    end
end

-- Sample pets for formula
function harvestPets:sampleForFormula()
    samplePetsForFormula()
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("harvestPets", {"utils", "commands"}, function()
        -- Initialize pao_pet SavedVariable
        pao_pet = pao_pet or {
            version = "2.2.0",
            harvestDate = nil,
            totalPets = 0,
            enhancedPets = 0,
            pets = {}
        }
        
        -- Register harvest command after dependencies are loaded
        if Addon.commands then
            Addon.commands:register({
                command = "harvest",
                handler = function(args)
                    local harvestType = args.type or (args and args[1]) or ""
                    
                    if harvestType == "pets" or harvestType == "pet" then
                        harvestPets:startHarvest()
                    elseif harvestType == "abilities" or harvestType == "ability" then
                        if Addon.abilityHarvester and Addon.abilityHarvester.startHarvest then
                            Addon.abilityHarvester:startHarvest()
                        else
                            utils:error("Ability harvester not available")
                        end
                    elseif harvestType == "breeds" or harvestType == "breed" then
                        if Addon.harvestBreeds and Addon.harvestBreeds.run then
                            Addon.harvestBreeds:run()
                        else
                            utils:error("Breed harvester not available")
                        end
                    elseif harvestType == "sample" then
                        harvestPets:sampleForFormula()
                    elseif harvestType == "status" then
                        harvestPets:showStatus()
                        if Addon.abilityHarvester and Addon.abilityHarvester.showStatus then
                            Addon.abilityHarvester:showStatus()
                        end
                        if Addon.harvestBreeds and Addon.harvestBreeds.showStatus then
                            Addon.harvestBreeds:showStatus()
                        end
                    else
                        utils:notify("🌾 PAO Harvest System:")
                        utils:notify("  /pao harvest pets     - Harvest pet data from Pet Journal")
                        utils:notify("  /pao harvest abilities - Harvest ability data from game")
                        utils:notify("  /pao harvest breeds   - Harvest breed data from BPBID")
                        utils:notify("  /pao harvest sample   - Sample 60 diverse pets for formula derivation")
                        utils:notify("  /pao harvest status   - Show harvest status")
                    end
                end,
                help = "Harvest game data (pets, abilities, etc.)",
                usage = "harvest <pets|abilities|breeds|sample|status>",
                args = {
                    {name = "type", required = false, description = "Type of data to harvest"}
                },
                detailedHelp = [[
🌾 Harvest live game data for PAO database

Types:
  pets       Harvest all pets from Pet Journal with acquisition data
  abilities  Harvest ability data from game API
  breeds     Harvest available breeds from BPBID (requires Battle Pet BreedID)
  sample     Sample 60 diverse pets for breed formula derivation
             Includes BPBID base stats if available
  status     Show current harvest progress

The sample command selects pets across different levels, qualities,
and breeds to help derive stat calculation formulas.
]],
                category = "Development"
            })
        end
        
        return true
    end)
end

Addon.harvestPets = harvestPets
return harvestPets