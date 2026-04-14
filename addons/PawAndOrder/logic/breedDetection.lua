-- logic/breedDetection.lua - Pet Breed Detection System
--
-- Detects pet breeds by comparing observed stats against expected stats.
-- Uses dataStore for species data access (handles static/SV merge automatically).
-- When species is unknown, derives base stats from observed values and saves
-- via dataStore for future lookups.
--
-- Dependencies: dataStore (for species/ability data access)

local ADDON_NAME, Addon = ...

local breedDetection = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

-- Breed stat modifiers (added to base stats before level/quality scaling)
-- These are the canonical values used by WoW's pet battle system
local BREED_MODIFIERS = {
    [3]  = {health = 0.5, power = 0.5, speed = 0.5},  -- B/B (Balanced)
    [4]  = {health = 0,   power = 2,   speed = 0},    -- P/P (Power)
    [5]  = {health = 0,   power = 0,   speed = 2},    -- S/S (Speed)
    [6]  = {health = 2,   power = 0,   speed = 0},    -- H/H (Health)
    [7]  = {health = 0.9, power = 0.9, speed = 0},    -- H/P (Health/Power)
    [8]  = {health = 0,   power = 0.9, speed = 0.9},  -- P/S (Power/Speed)
    [9]  = {health = 0.9, power = 0,   speed = 0.9},  -- H/S (Health/Speed)
    [10] = {health = 0.4, power = 0.9, speed = 0.4},  -- P/B (Power/Balanced)
    [11] = {health = 0.4, power = 0.4, speed = 0.9},  -- S/B (Speed/Balanced)
    [12] = {health = 0.9, power = 0.4, speed = 0.4}   -- H/B (Health/Balanced)
}

local BREED_NAMES = {
    [3]  = "B/B",
    [4]  = "P/P",
    [5]  = "S/S",
    [6]  = "H/H",
    [7]  = "H/P",
    [8]  = "P/S",
    [9]  = "H/S",
    [10] = "P/B",
    [11] = "S/B",
    [12] = "H/B"
}

local QUALITY_MULTIPLIERS = {
    [1] = 1.0,   -- Poor
    [2] = 1.1,   -- Common
    [3] = 1.2,   -- Uncommon
    [4] = 1.3,   -- Rare
    [5] = 1.4,   -- Epic
    [6] = 1.5    -- Legendary
}

local ALL_BREEDS = {3, 4, 5, 6, 7, 8, 9, 10, 11, 12}

local BASE_HEALTH = 100
local HEALTH_PER_STAMINA = 5

-- Minimum level for reliable reverse-engineering (lower = more rounding error)
local MIN_LEVEL_FOR_DERIVATION = 20

-- ============================================================================
-- STAT CALCULATION
-- ============================================================================

--[[
  Calculate expected stats for a given breed.
  This is the canonical WoW pet stat formula.
  
  @param baseHealth number - Species base health stat
  @param basePower number - Species base power stat
  @param baseSpeed number - Species base speed stat
  @param breedID number - Breed ID (3-12)
  @param level number - Pet level (1-25)
  @param quality number - Quality/rarity (1-6)
  @return health, power, speed numbers
]]
local function calculateStats(baseHealth, basePower, baseSpeed, breedID, level, quality)
    local breed = BREED_MODIFIERS[breedID]
    if not breed then return 0, 0, 0 end
    
    local qualityMult = QUALITY_MULTIPLIERS[quality] or 1.0
    
    local health = math.floor((baseHealth + breed.health) * qualityMult * level * HEALTH_PER_STAMINA + 0.5) + BASE_HEALTH
    local power = math.floor((basePower + breed.power) * qualityMult * level + 0.5)
    local speed = math.floor((baseSpeed + breed.speed) * qualityMult * level + 0.5)
    
    return health, power, speed
end

--[[
  Calculate weighted difference between observed and expected stats.
  Health difference is weighted less (divided by 5) since health scales 5x.
]]
local function calculateDifference(obsHealth, obsPower, obsSpeed, expHealth, expPower, expSpeed)
    local healthDiff = math.abs(obsHealth - expHealth) / 5
    local powerDiff = math.abs(obsPower - expPower)
    local speedDiff = math.abs(obsSpeed - expSpeed)
    
    return healthDiff + powerDiff + speedDiff
end

-- ============================================================================
-- REVERSE ENGINEERING (FALLBACK FOR UNKNOWN SPECIES)
-- ============================================================================

--[[
  Reverse-engineer breed and base stats from observed stats.
  
  For pets not in static data (e.g., new promotional pets), we can derive the breed
  by trying each breed's modifiers and reverse-calculating what base stats would
  be required, then verifying via forward calculation.
  
  This works reliably at level 20+ where stats are large enough that rounding
  errors don't cause ambiguity. At lower levels, multiple breeds may produce
  identical observed stats due to floor() rounding.
  
  IMPORTANT: We verify with raw (unrounded) derived values because species base
  stats don't always conform to clean 0.5 intervals. Rounding is only done for
  storage/display after verification succeeds.
  
  @param level number - Pet level (20+ for reliable results)
  @param quality number - Quality (1-6)
  @param observedHealth number - Current health stat
  @param observedPower number - Current power stat  
  @param observedSpeed number - Current speed stat
  @return breedID, baseStats, confidence (or nil, nil, 0)
]]
local function deriveBreedFromStats(level, quality, observedHealth, observedPower, observedSpeed)
    -- Require minimum level for reliable derivation
    if level < MIN_LEVEL_FOR_DERIVATION then
        return nil, nil, 0
    end
    
    local qualityMult = QUALITY_MULTIPLIERS[quality]
    if not qualityMult then
        return nil, nil, 0
    end
    
    local divisor = qualityMult * level
    
    -- Try each breed and see if we get an exact round-trip match
    for _, breedID in ipairs(ALL_BREEDS) do
        local breed = BREED_MODIFIERS[breedID]
        
        -- Reverse calculate potential base stats from observed stats (raw, no rounding)
        -- Formula: observed = floor((base + mod) * mult * level [* 5 for health] + 0.5) [+ 100 for health]
        -- Solving: base = observed / (mult * level [* 5]) - mod [after removing +100 for health]
        local rawBaseHealth = (observedHealth - BASE_HEALTH) / (divisor * HEALTH_PER_STAMINA) - breed.health
        local rawBasePower = observedPower / divisor - breed.power
        local rawBaseSpeed = observedSpeed / divisor - breed.speed
        
        -- Validate: base stats should be positive and reasonable (typically 4-12 range)
        if rawBaseHealth >= 3 and rawBaseHealth <= 15 and
           rawBasePower >= 3 and rawBasePower <= 15 and
           rawBaseSpeed >= 3 and rawBaseSpeed <= 15 then
            
            -- Forward calculate using RAW values to verify exact round-trip
            local expHealth, expPower, expSpeed = calculateStats(
                rawBaseHealth, rawBasePower, rawBaseSpeed,
                breedID, level, quality
            )
            
            -- Exact match means this is THE correct breed and base stats
            if expHealth == observedHealth and expPower == observedPower and expSpeed == observedSpeed then
                -- Round to 2 decimal places for clean storage/display
                local baseStats = {
                    health = math.floor(rawBaseHealth * 100 + 0.5) / 100,
                    power = math.floor(rawBasePower * 100 + 0.5) / 100,
                    speed = math.floor(rawBaseSpeed * 100 + 0.5) / 100
                }
                return breedID, baseStats, 100
            end
        end
    end
    
    -- No exact match found (shouldn't happen for valid pets at level 20+)
    return nil, nil, 0
end

--[[
  Save derived species data via dataStore.
  Also captures any unknown abilities.
  Format matches static data for easy export/promotion.
  
  @param speciesID number
  @param breedID number
  @param baseStats table {health, power, speed}
]]
local function saveDerivedSpecies(speciesID, breedID, baseStats)
    if not Addon.dataStore then
        return
    end
    
    -- Check if already exists (static or SV)
    if Addon.dataStore:getEntity("species", speciesID) then
        return
    end
    
    -- Get full species info from API
    local speciesName, speciesIcon, petType, creatureID, sourceText, description, 
          isWild, canBattle, tradeable, unique, obtainable, displayID = 
          C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    
    -- Get abilities
    local abilityList = C_PetJournal.GetPetAbilityList(speciesID)
    local abilities = {
        [0] = {}, -- Slot 1
        [1] = {}, -- Slot 2
        [2] = {}  -- Slot 3
    }
    
    if abilityList then
        for i, abilityID in ipairs(abilityList) do
            local slot = math.floor((i - 1) / 2)  -- 0, 0, 1, 1, 2, 2
            local tier = ((i - 1) % 2) + 1        -- 1, 2, 1, 2, 1, 2
            local levelReq = Addon.abilityUtils and Addon.abilityUtils:getLevelRequirement(i) or 
                            ({1, 10, 2, 15, 4, 20})[i] or 1
            
            abilities[slot][tier] = {
                id = abilityID,
                level = levelReq
            }
            
            -- Capture ability if not already known
            if not Addon.dataStore:getEntity("ability", abilityID) then
                local abilityName, abilityIcon, abilityPetType = C_PetJournal.GetPetAbilityInfo(abilityID)
                local _, abilityMaxCooldown, abilityDuration = C_PetBattles.GetAbilityInfoByID(abilityID)
                
                Addon.dataStore:addEntity("ability", abilityID, {
                    name = abilityName or "Unknown",
                    icon = abilityIcon or 134400,
                    familyType = abilityPetType or 0,
                    cooldown = abilityMaxCooldown or 0,
                    duration = abilityDuration or 1,
                    description = "",
                    harvestedAt = time()
                })
            end
        end
    end
    
    -- Map source type text to enum
    local sourceTypeEnum = 0
    if sourceText then
        if sourceText:match("^Pet Battle") then
            sourceTypeEnum = 4  -- Wild
        elseif sourceText:match("^Vendor") then
            sourceTypeEnum = 2  -- Vendor
        elseif sourceText:match("^Profession") or sourceText:match("^Crafted") then
            sourceTypeEnum = 3  -- Profession
        elseif sourceText:match("^Drop") or sourceText:match("^Loot") then
            sourceTypeEnum = 1  -- Drop
        elseif sourceText:match("^Quest") then
            sourceTypeEnum = 5  -- Quest
        elseif sourceText:match("^Achievement") then
            sourceTypeEnum = 6  -- Achievement
        elseif sourceText:match("^Promotion") or sourceText:match("^Trading Card") then
            sourceTypeEnum = 7  -- Promotion
        end
    end
    
    -- Build available breeds list (we only know the one we derived)
    local availableBreeds = { BREED_NAMES[breedID] }
    
    -- Save via dataStore
    Addon.dataStore:addEntity("species", speciesID, {
        abilities = abilities,
        availableBreeds = availableBreeds,
        baseStats = {
            health = baseStats.health,
            power = baseStats.power,
            speed = baseStats.speed
        },
        canBattle = (canBattle ~= false),
        creatureId = creatureID or 0,
        description = description or "",
        familyType = petType or 0,
        name = speciesName or "Unknown",
        source = sourceText or "",
        sourceTypeEnum = sourceTypeEnum,
        tradeable = tradeable or false,
        unique = unique or false,
        -- Metadata for verification
        _derivedBreed = breedID,
        _derivedAt = date("%Y-%m-%d %H:%M:%S"),
        _note = "Auto-derived. Verify availableBreeds before adding to static data."
    })
    
    -- Debug notification
    if Addon.utils then
        Addon.utils:debug(string.format(
            "Derived species %d (%s): base H=%.2f P=%.2f S=%.2f, breed=%s. Saved via dataStore.",
            speciesID, speciesName or "Unknown",
            baseStats.health, baseStats.power, baseStats.speed,
            BREED_NAMES[breedID] or "?"
        ))
    end
end

--[[
  Convert breed name strings to breed IDs.
  @param availableBreeds table - Array of breed names like {"S/B", "P/P"}
  @return table - Array of breed IDs like {11, 4}
]]
local function breedNamesToIDs(availableBreeds)
    if not availableBreeds then return nil end
    
    local ids = {}
    for _, breedName in ipairs(availableBreeds) do
        for id, name in pairs(BREED_NAMES) do
            if name == breedName then
                table.insert(ids, id)
                break
            end
        end
    end
    
    return #ids > 0 and ids or nil
end

--[[
  Get species data from dataStore (handles static/SV merge).
  Converts availableBreeds strings to breed IDs for detection.
  
  @param speciesID number
  @return table|nil - {baseStats, breeds, ...} or nil if not found
]]
local function getSpeciesData(speciesID)
    if not Addon.dataStore then
        return nil
    end
    
    local species = Addon.dataStore:getEntity("species", speciesID)
    if not species or not species.baseStats then
        return nil
    end
    
    -- Convert breed names to IDs if present
    local breedIDs = nil
    if species.availableBreeds then
        breedIDs = breedNamesToIDs(species.availableBreeds)
    elseif species._derivedBreed then
        -- Fallback for derived species with only one known breed
        breedIDs = { species._derivedBreed }
    end
    
    return {
        baseStats = species.baseStats,
        breeds = breedIDs,
        name = species.name
    }
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Detect breed from observed stats using known base stats.
  
  @param speciesID number - Species ID (for reference)
  @param level number - Pet level
  @param quality number - Quality (1-6)
  @param observedHealth number - Current health
  @param observedPower number - Current power
  @param observedSpeed number - Current speed
  @param baseStats table - {health, power, speed} base stats from species data
  @param availableBreeds table|nil - Array of valid breed IDs, or nil for all
  @return breedID, confidence (0-100), breedName
]]
function breedDetection:detectBreed(speciesID, level, quality, observedHealth, observedPower, observedSpeed, baseStats, availableBreeds)
    -- Validate inputs
    if not speciesID or not level or not quality or not observedHealth or not observedPower or not observedSpeed then
        return nil, 0, nil
    end
    
    if not baseStats or not baseStats.health or not baseStats.power or not baseStats.speed then
        return nil, 0, nil
    end
    
    -- Determine which breeds to test
    local breedsToTest = availableBreeds or ALL_BREEDS
    
    -- Find best matching breed
    local bestBreed = nil
    local bestDiff = math.huge
    local secondBestDiff = math.huge
    
    for _, breedID in ipairs(breedsToTest) do
        local expHealth, expPower, expSpeed = calculateStats(
            baseStats.health, baseStats.power, baseStats.speed,
            breedID, level, quality
        )
        
        local diff = calculateDifference(
            observedHealth, observedPower, observedSpeed,
            expHealth, expPower, expSpeed
        )
        
        if diff < bestDiff then
            secondBestDiff = bestDiff
            bestDiff = diff
            bestBreed = breedID
        elseif diff < secondBestDiff then
            secondBestDiff = diff
        end
    end
    
    -- Calculate confidence percentage
    local confidence = 0
    if bestBreed then
        if bestDiff == 0 then
            confidence = 100
        elseif secondBestDiff > 0 then
            local ratio = secondBestDiff / math.max(bestDiff, 0.1)
            confidence = math.min(100, math.floor(ratio * 20))
        end
    end
    
    return bestBreed, confidence, BREED_NAMES[bestBreed]
end

--[[
  Detect breed from Pet Journal pet ID.
  
  Uses dataStore for species lookup (handles static/SV merge).
  Falls back to reverse-engineering for unknown species (level 20+).
  
  @param petID string - Pet GUID
  @return breedID, confidence (0-100), breedName
]]
function breedDetection:detectBreedByPetID(petID)
    if not petID then
        return nil, 0, nil
    end
    
    -- Get pet info from game API
    local speciesID, customName, level = C_PetJournal.GetPetInfoByPetID(petID)
    if not speciesID or not level then
        return nil, 0, nil
    end
    
    -- Get pet stats from game API
    local health, maxHealth, power, speed, quality = C_PetJournal.GetPetStats(petID)
    if not health or not power or not speed or not quality then
        return nil, 0, nil
    end
    
    -- Try species data (dataStore handles static/SV merge)
    local speciesData = getSpeciesData(speciesID)
    if speciesData and speciesData.baseStats then
        local baseStats = speciesData.baseStats
        if baseStats.health and baseStats.power and baseStats.speed then
            local availableBreeds = speciesData.breeds or ALL_BREEDS
            return self:detectBreed(speciesID, level, quality, health, power, speed, baseStats, availableBreeds)
        end
    end
    
    -- FALLBACK: Reverse-engineer breed from observed stats
    -- Only works reliably at level 20+
    local breedID, derivedBaseStats, confidence = deriveBreedFromStats(level, quality, health, power, speed)
    
    if breedID and derivedBaseStats then
        -- Save via dataStore for reuse next session
        saveDerivedSpecies(speciesID, breedID, derivedBaseStats)
        
        return breedID, confidence, BREED_NAMES[breedID]
    end
    
    -- Could not detect breed
    return nil, 0, nil
end

--[[
  Get breed name by ID.
  @param breedID number
  @return string|nil
]]
function breedDetection:getBreedName(breedID)
    return BREED_NAMES[breedID]
end

--[[
  Get all breed names.
  @return table - {[breedID] = "name", ...}
]]
function breedDetection:getAllBreedNames()
    return BREED_NAMES
end

--[[
  Get breed modifiers.
  @param breedID number
  @return table|nil - {health, power, speed}
]]
function breedDetection:getBreedModifiers(breedID)
    return BREED_MODIFIERS[breedID]
end

--[[
  Calculate predicted stats at level 25 for display.
  @param baseStats table - {health, power, speed}
  @param breedID number
  @param quality number - defaults to 4 (Rare)
  @return health, power, speed
]]
function breedDetection:predictStatsAtLevel25(baseStats, breedID, quality)
    if not baseStats or not breedID then
        return nil, nil, nil
    end
    
    quality = quality or 4
    
    return calculateStats(
        baseStats.health, baseStats.power, baseStats.speed,
        breedID, 25, quality
    )
end

--[[
  Get species data from dataStore (public API).
  Handles static/SV merge automatically.
  
  @param speciesID number
  @return table|nil - {baseStats, breeds, name} or nil
]]
function breedDetection:getSpeciesData(speciesID)
    return getSpeciesData(speciesID)
end

--[[
  Get all derived species from SavedVariables.
  Returns only SV data (not merged with static) for export purposes.
  @return table|nil
]]
function breedDetection:getDerivedSpecies()
    return pao_species
end

-- ============================================================================
-- BATTLE DETECTION (C_PetBattles API)
-- ============================================================================

--[[
  Detect breed for a pet in battle using C_PetBattles API.
  
  Handles wild pet stat reductions automatically:
  - Wild pets have 20% less HP (multiply by 1.2 to restore)
  - Wild pets have reduced power: 40% less at level <6, 25% less at level 6+
  - Flying pets above 50% HP have 50% speed boost (divide by 1.5)
  - C_PetBattles.GetBreedQuality returns value 1 lower than other APIs
  
  @param petOwner number - Enum.BattlePetOwner.Ally or .Enemy
  @param petIndex number - Pet slot (1-3)
  @return breedID, confidence, breedName, speciesID, level, rarity
]]
function breedDetection:detectBreedInBattle(petOwner, petIndex)
    if not C_PetBattles or not C_PetBattles.IsInBattle() then
        return nil, 0, nil
    end
    
    local speciesID = C_PetBattles.GetPetSpeciesID(petOwner, petIndex)
    if not speciesID then
        return nil, 0, nil
    end
    
    local level = C_PetBattles.GetLevel(petOwner, petIndex)
    -- C_PetBattles.GetBreedQuality returns value 1 lower than other APIs (Blizzard bug since 11.0.0)
    local rarity = C_PetBattles.GetBreedQuality(petOwner, petIndex) + 1
    local maxHealth = C_PetBattles.GetMaxHealth(petOwner, petIndex)
    local power = C_PetBattles.GetPower(petOwner, petIndex)
    local speed = C_PetBattles.GetSpeed(petOwner, petIndex)
    local petType = C_PetBattles.GetPetType(petOwner, petIndex)
    local currentHealth = C_PetBattles.GetHealth(petOwner, petIndex)
    
    if not level or not rarity or not maxHealth or not power or not speed then
        return nil, 0, nil
    end
    
    -- Check if this is a wild enemy pet (needs stat adjustments)
    local isWild = C_PetBattles.IsWildBattle() and petOwner == Enum.BattlePetOwner.Enemy
    
    local adjustedHealth = maxHealth
    local adjustedPower = power
    local adjustedSpeed = speed
    
    if isWild then
        -- Wild pets have 20% less HP
        adjustedHealth = math.floor(maxHealth * 1.2 + 0.5)
        -- Wild pets have reduced power: 40% less at level <6, 25% less at level 6+
        if level < 6 then
            adjustedPower = math.floor(power * 1.4 + 0.5)
        else
            adjustedPower = math.floor(power * 1.25 + 0.5)
        end
    end
    
    -- Flying pets above 50% health have 50% speed boost from passive
    local isFlying = (petType == 3)
    local hasSpeedBoost = isFlying and currentHealth and maxHealth and maxHealth > 0 and (currentHealth / maxHealth > 0.5)
    if hasSpeedBoost then
        adjustedSpeed = math.floor(speed / 1.5 + 0.5)
    end
    
    -- Get species data and detect breed
    local speciesData = getSpeciesData(speciesID)
    if not speciesData or not speciesData.baseStats then
        return nil, 0, nil, speciesID, level, rarity
    end
    
    local breedID, confidence, breedName = self:detectBreed(
        speciesID, level, rarity,
        adjustedHealth, adjustedPower, adjustedSpeed,
        speciesData.baseStats, speciesData.breeds
    )
    
    return breedID, confidence, breedName, speciesID, level, rarity
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("breedDetection", {"dataStore", "speciesData", "abilities", "utils"}, function()
        return true
    end)
end

Addon.breedDetection = breedDetection
return breedDetection