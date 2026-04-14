--[[
  logic/petCache.lua
  Reactive Pet Cache - Single Source of Truth for Pet Data
  
  Central cache for all pet data with event-driven surgical updates.
  Replaces the sledgehammer clear/rebuild approach with targeted refreshes.
  
  Design Principles:
  - Static data loaded once from Addon.speciesDB
  - Dynamic data (health, level, XP) refreshed on specific events
  - Indexes maintained for O(1) lookups
  - Events fire after updates so UI can react
  
  Events Consumed (Blizzard):
  - NEW_PET_ADDED              → addPet(battlePetGUID)
  - PET_JOURNAL_LIST_UPDATE    → initialize() if not initialized
  - PET_JOURNAL_PET_DELETED    → removePet(petID)
  - UNIT_SPELLCAST_SUCCEEDED   → refreshAllHealth() [spells 125439, 133994]
  - PET_BATTLE_LEVEL_CHANGED   → stores petID for post-battle update
  - PET_BATTLE_OVER            → refreshPetStats(leveled pets) + refreshLoadoutHealth()
  - UPDATE_SUMMONPETS_ACTION   → updatePet(summonedGUID)
  
  Events Consumed (Internal - from dialogs.lua):
  - COLLECTION:PET_RENAMED     → updatePet(petID)
  - COLLECTION:PET_RELEASED    → removePet(petID)
  - COLLECTION:PET_CAGED       → removePet(petID) (pet leaves journal, becomes bag item)
  
  Events Fired (Internal):
  - CACHE:INITIALIZED          → full cache ready
  - CACHE:PET_UPDATED          → single pet changed
  - CACHE:PETS_UPDATED         → multiple pets changed
  - CACHE:PETS_LEVELED         → pets that leveled after battle
                                 payload: { pets = {{petID, oldLevel, newLevel}, ...} }
  - CACHE:LOADOUT_CHANGED      → team composition changed
  - CACHE:HEALTH_CHANGED       → health values changed
  - CACHE:COLLECTION_CHANGED   → pet added/removed
  - CACHE:STATS_CHANGED        → rarity stats changed
  
  Dependencies: utils, constants, breedDetection (optional)
  Exports: Addon.petCache
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
  print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in petCache.lua.|r")
  return {}
end

local utils = Addon.utils

local petCache = {}

-- ============================================================================
-- SAVED VARIABLES
-- ============================================================================

--[[
  pao_edgeCasePets - Persistence for edge case pets
  
  Some pets have obtainable=false (like Snowy Owl during winter) which causes
  GetPetInfoByIndex() to skip them. We detect these via NEW_PET_ADDED and
  persist their petIDs so we can restore them on reload.
  
  Structure: { [petID] = true, ... }
  Managed by svRegistry, but initialized here at file scope because
  PET_JOURNAL_LIST_UPDATE fires before ADDON_LOADED.
]]
pao_edgeCasePets = pao_edgeCasePets or {}

-- ============================================================================
-- CACHE STATE
-- ============================================================================

-- Primary pet storage: petID -> pet data
local pets = {}

-- Indexes for fast lookups
local bySpecies = {}           -- speciesID -> { petID, ... }
local loadout = { nil, nil, nil }  -- Current team petIDs
local deadPets = {}            -- petID -> true
local injuredPets = {}         -- petID -> true (health < maxHealth)
local duplicateCounts = {}     -- "speciesID-breedText" -> count
local speciesCounts = {}       -- speciesID -> count (total owned of species)
local rarityStats = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 }

-- Module references (resolved at init)
local constants, breedDetection

-- State flags
local initialized = false

-- Pets that leveled during current battle (petID -> newLevel)
-- Populated by PET_BATTLE_LEVEL_CHANGED, consumed by PET_BATTLE_OVER
local petsLeveledInBattle = {}


-- Temporary subscription ID for PET_JOURNAL_LIST_UPDATE (unsubscribed after init)
local petJournalListUpdateSubId = nil

-- Filter state saved by ensureReady, restored after init
local savedFiltersForInit = nil  -- { search, types, sources }
-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

--[[
  Get family name from pet type ID
  Uses constants helper if available.
]]
local function getFamilyName(petType)
  if not petType then
    return "Companion"  -- Non-combat pets have no family type
  end
  if constants and constants.GetPetFamilyName then
    return constants:GetPetFamilyName(petType)
  end
  return "Unknown"
end

--[[
  Build pet data from C_PetJournal API
  Fetches all pet info and enriches with breed detection and static DB.
  
  @param petID string - Pet GUID
  @param speciesID number - Species ID (optional, fetched if nil)
  @return table|nil - Pet data structure
]]
local function buildPetFromAPI(petID, speciesID)
  if not petID then return nil end
  
  -- Get base info from API (pcall: API throws for stale/invalid GUIDs
  -- instead of returning nil, but our contract is to return nil on failure)
  local ok, sID, customName, level, xp, maxXp, displayID, favorite, petName, icon, petType,
        creatureID, sourceText, description, isWild, canBattle, tradable, unique =
        pcall(C_PetJournal.GetPetInfoByPetID, petID)
  
  if not ok or not sID then return nil end
  speciesID = speciesID or sID
  
  -- Get dynamic stats
  local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
  
  -- Cap rarity at Rare (4) for player pets - API may return higher but it's not achievable
  local cappedRarity = math.min(rarity or 2, 4)
  
  -- Display name logic
  local displayName = (customName and customName ~= "" and customName) or petName or "Unknown Pet"
  local speciesName = petName or "Unknown"
  
  -- Family name
  local familyName = getFamilyName(petType)
  
  -- Breed detection
  local breedID, breedConfidence, breedText
  if breedDetection then
    breedID, breedConfidence, breedText = breedDetection:detectBreedByPetID(petID)
    if breedText and breedConfidence and breedConfidence < 100 then
      breedText = breedText .. string.format(" (%d%%)", breedConfidence)
    end
  end
  
  -- Source type enum from dedicated data file
  local sourceTypeEnum = -1
  if Addon.data and Addon.data.speciesSourceType then
    sourceTypeEnum = Addon.data.speciesSourceType[speciesID] or -1
  end
  
  -- Source text from API (no static override)
  local speciesSource = sourceText or "Unknown"
  
  -- Abilities from API
  -- GetPetAbilityList returns both ability IDs and their unlock levels
  local abilities = {}
  if C_PetJournal.GetPetAbilityList then
    local apiAbilities, apiLevels = C_PetJournal.GetPetAbilityList(speciesID)
    if apiAbilities and #apiAbilities > 0 then
      for i, abilityID in ipairs(apiAbilities) do
        local abName, abIcon = C_PetJournal.GetPetAbilityInfo(abilityID)
        table.insert(abilities, {
          abilityID = abilityID,
          name = abName or "Unknown",
          icon = abIcon,
          level = (apiLevels and apiLevels[i]) or 1,
          slot = math.floor((i - 1) / 2),
          tier = ((i - 1) % 2) + 1
        })
      end
    end
  end
  
  return {
    -- Identity
    petID = petID,
    speciesID = speciesID,
    speciesName = speciesName,
    
    -- Display
    name = displayName,
    customName = customName,
    icon = icon,
    
    -- Classification
    petType = petType,
    familyName = familyName,
    breedID = breedID,
    breedText = breedText,
    
    -- Status flags
    owned = true,
    favorite = favorite,
    tradable = tradable,
    unique = unique,
    canBattle = canBattle,
    isWild = isWild,
    
    -- Dynamic stats (refreshed on events)
    health = health or 0,
    maxHealth = maxHealth or 1,
    power = power or 0,
    speed = speed or 0,
    level = level or 1,
    xp = xp or 0,
    maxXp = maxXp or 1,
    rarity = cappedRarity,
    
    -- Source/acquisition
    sourceText = speciesSource,
    sourceTypeEnum = sourceTypeEnum,
    description = description or "",
    
    -- Abilities
    abilities = abilities,
    
    -- Duplicate tracking (set after full load)
    duplicateCount = 1,
    speciesCount = 1
  }
end

--[[
  Build pet data for UNOWNED pet from speciesID
  Uses C_PetJournal.GetPetInfoBySpeciesID and species DB.
  These pets have no petID, so we use "species:{speciesID}" as key.
  
  @param speciesID number - Species ID
  @param index number - Journal index (for reference)
  @return table|nil - Pet data structure
]]
local function buildUnownedPetFromSpecies(speciesID, index)
  if not speciesID then return nil end
  
  -- Get base info from API
  local petName, icon, petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable =
        C_PetJournal.GetPetInfoBySpeciesID(speciesID)
  
  if not petName then return nil end
  
  -- Family name
  local familyName = getFamilyName(petType)
  
  -- Synthetic petID for unowned pets
  local syntheticPetID = "species:" .. speciesID
  
  -- Source type enum from dedicated data file
  local sourceTypeEnum = -1
  if Addon.data and Addon.data.speciesSourceType then
    sourceTypeEnum = Addon.data.speciesSourceType[speciesID] or -1
  end
  
  -- Source text from API (no static override)
  local speciesSource = sourceText or "Unknown"
  
  -- Abilities from API
  -- GetPetAbilityList returns both ability IDs and their unlock levels
  local abilities = {}
  if C_PetJournal.GetPetAbilityList then
    local apiAbilities, apiLevels = C_PetJournal.GetPetAbilityList(speciesID)
    if apiAbilities and #apiAbilities > 0 then
      for i, abilityID in ipairs(apiAbilities) do
        local abName, abIcon = C_PetJournal.GetPetAbilityInfo(abilityID)
        table.insert(abilities, {
          abilityID = abilityID,
          name = abName or "Unknown",
          icon = abIcon,
          level = (apiLevels and apiLevels[i]) or 1,
          slot = math.floor((i - 1) / 2),
          tier = ((i - 1) % 2) + 1
        })
      end
    end
  end
  
  return {
    -- Identity (synthetic petID for unowned)
    petID = syntheticPetID,
    speciesID = speciesID,
    speciesName = petName,
    
    -- Display
    name = petName,
    customName = nil,
    icon = icon,
    
    -- Classification
    petType = petType,
    familyName = familyName,
    breedID = nil,
    breedText = nil,
    
    -- Status flags
    owned = false,
    favorite = false,
    tradable = tradable,
    unique = unique,
    canBattle = canBattle,
    isWild = isWild,
    obtainable = obtainable,
    
    -- No dynamic stats for unowned
    health = 0,
    maxHealth = 0,
    power = 0,
    speed = 0,
    level = 1,
    xp = 0,
    maxXp = 1,
    rarity = 2,  -- Default to Common for unowned
    
    -- Source/acquisition
    sourceText = speciesSource,
    sourceTypeEnum = sourceTypeEnum,
    description = description or "",
    
    -- Abilities
    abilities = abilities,
    
    -- No duplicates for unowned
    duplicateCount = 0,
    speciesCount = 0,
    
    -- Index for reference
    index = index
  }
end

--[[
  Refresh dynamic stats for a single pet
  Only updates health, maxHealth, power, speed, level, xp, rarity, favorite.
  
  @param petID string - Pet GUID
  @return boolean - true if pet exists and was updated
]]
local function refreshPetStats(petID)
  local pet = pets[petID]
  if not pet then return false end
  
  -- Fetch current stats
  local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
  if not health then return false end
  
  -- Fetch current info (for level, xp, favorite)
  local _, customName, level, xp, maxXp, _, favorite = C_PetJournal.GetPetInfoByPetID(petID)
  
  -- Update dynamic fields
  pet.health = health
  pet.maxHealth = maxHealth
  pet.power = power
  pet.speed = speed
  pet.level = level or pet.level
  pet.xp = xp or pet.xp
  pet.maxXp = maxXp or pet.maxXp
  pet.favorite = favorite
  pet.customName = customName
  pet.name = (customName and customName ~= "" and customName) or pet.speciesName
  
  -- Cap rarity at Rare (4) for player pets
  if rarity then
    pet.rarity = math.min(rarity, 4)
  end
  
  return true
end

-- ============================================================================
-- INDEX MAINTENANCE
-- ============================================================================

--[[
  Rebuild dead/injured indexes from current pet data
]]
local function rebuildHealthIndexes()
  deadPets = {}
  injuredPets = {}
  
  for petID, pet in pairs(pets) do
    if pet.owned then
      if pet.health <= 0 then
        deadPets[petID] = true
      elseif pet.health < pet.maxHealth then
        injuredPets[petID] = true
      end
    end
  end
end

--[[
  Rebuild species index from current pet data
]]
local function rebuildSpeciesIndex()
  bySpecies = {}
  
  for petID, pet in pairs(pets) do
    local sid = pet.speciesID
    if not bySpecies[sid] then
      bySpecies[sid] = {}
    end
    table.insert(bySpecies[sid], petID)
  end
end

--[[
  Rebuild duplicate counts and species counts from current pet data
  - duplicateCounts: same species + same breed
  - speciesCounts: same species (any breed)
]]
local function rebuildDuplicates()
  duplicateCounts = {}
  speciesCounts = {}
  
  -- First pass: count duplicates and species totals
  -- Use breedID (not breedText) because breedText includes confidence percentage
  for petID, pet in pairs(pets) do
    local breedKey = (pet.speciesID or 0) .. "-" .. (pet.breedID or "unknown")
    duplicateCounts[breedKey] = (duplicateCounts[breedKey] or 0) + 1
    
    local speciesID = pet.speciesID or 0
    speciesCounts[speciesID] = (speciesCounts[speciesID] or 0) + 1
  end
  
  -- Second pass: update each pet's counts
  for petID, pet in pairs(pets) do
    local breedKey = (pet.speciesID or 0) .. "-" .. (pet.breedID or "unknown")
    pet.duplicateCount = duplicateCounts[breedKey] or 1
    pet.speciesCount = speciesCounts[pet.speciesID or 0] or 1
  end
end

--[[
  Rebuild rarity statistics from current pet data
]]
local function rebuildRarityStats()
  rarityStats = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 }
  
  for petID, pet in pairs(pets) do
    local r = pet.rarity or 2
    if r >= 1 and r <= 4 then
      rarityStats[r] = rarityStats[r] + 1
    end
  end
end

--[[
  Rebuild all indexes
]]
local function rebuildAllIndexes()
  rebuildSpeciesIndex()
  rebuildHealthIndexes()
  rebuildDuplicates()
  rebuildRarityStats()
end

-- ============================================================================
-- LOADOUT MANAGEMENT
-- ============================================================================

--[[
  Update loadout array from C_PetJournal
]]
local function updateLoadoutFromAPI()
  for slot = 1, 3 do
    local petID = C_PetJournal.GetPetLoadOutInfo(slot)
    loadout[slot] = petID
  end
end

-- ============================================================================
-- PUBLIC API - INITIALIZATION
-- ============================================================================

--[[
  Initialize the pet cache
  Called by ensureReady's event handler. Filters already cleared.
  Iterates pets, compares count to expected total.
  
  @return boolean - true if initialized successfully
]]
--[[
  Initialize the pet cache
  Performs full load from C_PetJournal, builds all indexes.
  Call once at addon load after PET_JOURNAL data is ready.
  
  @return boolean - true if initialized successfully
]]
function petCache:initialize()
  if initialized then return true end
  
  -- Resolve dependencies
  constants = Addon.constants
  breedDetection = Addon.breedDetection
  
  if not constants then
    utils:error("petCache: constants not available")
    return false
  end
  
  if not C_PetJournal then
    utils:error("petCache: C_PetJournal not available")
    return false
  end
  
  -- Get expected total (filters already cleared by ensureReady)
  local expectedTotal = C_PetJournal.GetNumPets()
  pets = {}
  
  local ownedCount = 0
  local unownedCount = 0
  
  for i = 1, expectedTotal do
    local petID, speciesID, owned = C_PetJournal.GetPetInfoByIndex(i)
    
    -- petID is the source of truth for ownership - it only exists for owned pets
    if petID then
      local pet = buildPetFromAPI(petID, speciesID)
      if pet then
        pet.index = i
        pets[petID] = pet
        ownedCount = ownedCount + 1
      end
    elseif speciesID then
      local pet = buildUnownedPetFromSpecies(speciesID, i)
      if pet then
        pets[pet.petID] = pet
        unownedCount = unownedCount + 1
      end
    end
  end
  
  -- Count what we got
  local petCount = 0
  for _ in pairs(pets) do petCount = petCount + 1 end
  
  -- Compare to expected
  if petCount ~= expectedTotal then
    -- Data incomplete, wait for next event
    pets = {}  -- Clear partial data
    return false
  end
  
  -- Helper to restore filters
  local function restoreFilters()
    if not savedFiltersForInit then return end
    
    C_PetJournal.SetSearchFilter(savedFiltersForInit.search or "")
    for petType, checked in pairs(savedFiltersForInit.types) do
      C_PetJournal.SetPetTypeFilter(petType, checked)
    end
    for source, checked in pairs(savedFiltersForInit.sources) do
      C_PetJournal.SetPetSourceChecked(source, checked)
    end
    savedFiltersForInit = nil
  end
  
  -- Restore filters
  restoreFilters()
  
  -- Build all indexes
  rebuildAllIndexes()
  
  -- Restore edge case pets (obtainable=false pets skipped by GetPetInfoByIndex)
  local restoredCount = 0
  for petID in pairs(pao_edgeCasePets) do
    if not pets[petID] then
      local pet = buildPetFromAPI(petID)
      if pet then
        pets[petID] = pet
        restoredCount = restoredCount + 1
      else
        -- Pet no longer exists, clean up
        pao_edgeCasePets[petID] = nil
      end
    end
  end
  
  if restoredCount > 0 then
    rebuildAllIndexes()
  end
  
  -- Load current loadout
  updateLoadoutFromAPI()
  
  initialized = true
  
  -- Unsubscribe from PET_JOURNAL_LIST_UPDATE - no longer needed for init
  if petJournalListUpdateSubId and Addon.events then
    Addon.events:unsubscribe(petJournalListUpdateSubId)
    petJournalListUpdateSubId = nil
  end
  
  -- Fire initialized event
  if Addon.events then
    Addon.events:emit("CACHE:INITIALIZED", {
      petCount = petCount,
      ownedCount = ownedCount,
      unownedCount = unownedCount,
    })
  end
  
  return true
end

--[[
  Check if cache is initialized
  @return boolean
]]
function petCache:isInitialized()
  return initialized
end

--[[
  Ensure pet data is ready.
  Call when PAO opens and needs pet data.
  Subscribes to event, saves filters, clears filters to trigger load.
  
  @return boolean - true if ready now, false if waiting
]]
function petCache:ensureReady()
  if initialized then return true end
  
  -- Already have a pending subscription?
  if petJournalListUpdateSubId then return false end
  
  -- Save current filters before we clear them
  local numTypes = C_PetJournal.GetNumPetTypes()
  local numSources = C_PetJournal.GetNumPetSources()
  
  savedFiltersForInit = {
    search = C_PetJournal.GetSearchFilter(),
    types = {},
    sources = {}
  }
  
  for i = 1, numTypes do
    savedFiltersForInit.types[i] = C_PetJournal.IsPetTypeChecked(i)
  end
  
  for i = 1, numSources do
    savedFiltersForInit.sources[i] = C_PetJournal.IsPetSourceChecked(i)
  end
  
  -- Subscribe to event
  if Addon.events then
    petJournalListUpdateSubId = Addon.events:subscribe("PET_JOURNAL_LIST_UPDATE", function(eventName)
      if not initialized then
        petCache:initialize()
      end
    end)
  end
  
  -- Clear filters to trigger event
  -- SetDefaultFilters() resets type/source filters AND sets both Collected and
  -- Not Collected to true, ensuring we get ALL pets (owned + unowned species)
  C_PetJournal.SetDefaultFilters()
  C_PetJournal.SetSearchFilter("")
  
  return false
end

-- ============================================================================
-- PUBLIC API - READ ACCESS
-- ============================================================================

--[[
  Get a single pet by petID
  @param petID string - Pet GUID
  @return table|nil - Pet data or nil if not found
]]
function petCache:getPet(petID)
  return pets[petID]
end

--[[
  Get all pets as array
  Builds array from pets dict on each call.
  @return table - Array of pet data
]]
function petCache:getAllPets()
  local result = {}
  for _, pet in pairs(pets) do
    table.insert(result, pet)
  end
  return result
end

--[[
  Get count of owned pets
  @return number
]]
function petCache:getOwnedCount()
  local count = 0
  for _, pet in pairs(pets) do
    if pet.owned then
      count = count + 1
    end
  end
  return count
end

--[[
  Get total pet count (owned + unowned species)
  @return number
]]
function petCache:getTotalCount()
  local count = 0
  for _ in pairs(pets) do
    count = count + 1
  end
  return count
end

--[[
  Get count of injured pets
  @return number
]]
function petCache:getInjuredCount()
  local count = 0
  for _ in pairs(injuredPets) do
    count = count + 1
  end
  for _ in pairs(deadPets) do
    count = count + 1
  end
  return count
end

--[[
  Get current loadout pets
  @return table - Array of 3 pet data (may contain nils for empty slots)
]]
function petCache:getLoadoutPets()
  local result = {}
  for slot = 1, 3 do
    local petID = loadout[slot]
    result[slot] = petID and pets[petID] or nil
  end
  return result
end

--[[
  Get loadout pet IDs
  @return table - Array of 3 petIDs (may contain nils)
]]
function petCache:getLoadoutPetIDs()
  return { loadout[1], loadout[2], loadout[3] }
end

--[[
  Get all dead pets
  @return table - Array of pet data where health == 0
]]
function petCache:getDeadPets()
  local result = {}
  for petID in pairs(deadPets) do
    table.insert(result, pets[petID])
  end
  return result
end

--[[
  Check if a pet is dead
  @param petID string - Pet GUID
  @return boolean
]]
function petCache:isPetDead(petID)
  return deadPets[petID] == true
end

--[[
  Get all injured pets (health < maxHealth but > 0) and dead pets (health == 0)
  @return table - Array of pet data
]]
function petCache:getInjuredPets()
  local result = {}
  for petID in pairs(injuredPets) do
    table.insert(result, pets[petID])
  end
  for petID in pairs(deadPets) do
    table.insert(result, pets[petID])
  end
  return result
end

--[[
  Get rarity statistics
  @return table - { [1]=count, [2]=count, [3]=count, [4]=count }
]]
function petCache:getRarityStats()
  return rarityStats
end

--[[
  Get duplicate counts map
  @return table - "speciesID-breedText" -> count
]]
function petCache:getDuplicateCounts()
  return duplicateCounts
end

--[[
  Get all pets of a specific species
  @param speciesID number
  @return table - Array of pet data
]]
function petCache:getPetsBySpecies(speciesID)
  local result = {}
  local petIDs = bySpecies[speciesID]
  if petIDs then
    for _, petID in ipairs(petIDs) do
      table.insert(result, pets[petID])
    end
  end
  return result
end

-- ============================================================================
-- PUBLIC API - SURGICAL UPDATES
-- ============================================================================

--[[
  Update a single pet from API
  Use after rename, favorite toggle, rarity upgrade, etc.
  
  @param petID string - Pet GUID
  @return boolean - true if updated
]]
function petCache:updatePet(petID)
  if not petID then return false end
  
  local existed = pets[petID] ~= nil
  
  if existed then
    -- Refresh existing pet
    if not refreshPetStats(petID) then
      return false
    end
  else
    -- New pet - full build
    local pet = buildPetFromAPI(petID)
    if not pet then return false end
    pets[petID] = pet
  end
  
  -- Update relevant indexes
  rebuildHealthIndexes()
  rebuildRarityStats()  -- Always rebuild - rarity may have changed
  
  if not existed then
    rebuildSpeciesIndex()
    rebuildDuplicates()
  end
  
  -- Fire event
  if Addon.events then
    Addon.events:emit("CACHE:PET_UPDATED", { petID = petID, pet = pets[petID] })
  end
  
  return true
end

--[[
  Update multiple pets from API
  More efficient than calling updatePet repeatedly.
  
  @param petIDs table - Array of pet GUIDs
]]
function petCache:updatePets(petIDs)
  if not petIDs or #petIDs == 0 then return end
  
  local updated = {}
  for _, petID in ipairs(petIDs) do
    if refreshPetStats(petID) then
      table.insert(updated, petID)
    end
  end
  
  rebuildHealthIndexes()
  rebuildRarityStats()
  
  if Addon.events and #updated > 0 then
    local updatedPets = {}
    for _, petID in ipairs(updated) do
      updatedPets[petID] = pets[petID]
    end
    Addon.events:emit("CACHE:PETS_UPDATED", { petIDs = updated, pets = updatedPets })
  end
end

--[[
  Build payload for CACHE:HEALTH_CHANGED event.
  Includes pet objects so subscribers don't need to re-query the cache.
  @param changedIDs table - Array of changed petIDs
  @param extra table|nil - Additional fields to merge (e.g., {healed = true})
  @return table - Event payload
]]
local function healthPayload(changedIDs, extra)
  local result = { petIDs = changedIDs, pets = {} }
  for _, petID in ipairs(changedIDs) do
    result.pets[petID] = pets[petID]
  end
  if extra then
    for k, v in pairs(extra) do result[k] = v end
  end
  return result
end

--[[
  Update loadout and refresh loadout pet stats
  Call after team composition or pet health changes.
]]
function petCache:updateLoadout()
  local oldLoadout = { loadout[1], loadout[2], loadout[3] }
  updateLoadoutFromAPI()
  
  -- Refresh stats for all loadout pets
  local changed = {}
  for slot = 1, 3 do
    local petID = loadout[slot]
    if petID and refreshPetStats(petID) then
      table.insert(changed, petID)
    end
  end
  
  rebuildHealthIndexes()
  
  -- Check if composition changed
  local compositionChanged = false
  for slot = 1, 3 do
    if oldLoadout[slot] ~= loadout[slot] then
      compositionChanged = true
      break
    end
  end
  
  if Addon.events then
    if compositionChanged then
      Addon.events:emit("CACHE:LOADOUT_CHANGED", { loadout = loadout })
    end
    if #changed > 0 then
      Addon.events:emit("CACHE:HEALTH_CHANGED", healthPayload(changed))
    end
  end
end

--[[
  Update loadout pets specifically (after battle)
  Refreshes stats for pets in loadout.
]]
function petCache:updateLoadoutPets()
  local changed = {}
  for slot = 1, 3 do
    local petID = loadout[slot]
    if petID and refreshPetStats(petID) then
      table.insert(changed, petID)
    end
  end
  
  rebuildHealthIndexes()
  rebuildRarityStats() -- Level changes affect nothing, but rarity might
  
  if Addon.events and #changed > 0 then
    Addon.events:emit("CACHE:HEALTH_CHANGED", healthPayload(changed))
  end
end

--[[
  Refresh health only for loadout pets
  Lighter weight than updateLoadoutPets - only updates health values.
  Call after battle to update damage taken.
]]
function petCache:refreshLoadoutHealth()
  local changed = {}
  
  for slot = 1, 3 do
    -- Get fresh loadout from API (cached loadout may be stale)
    local petID = C_PetJournal.GetPetLoadOutInfo(slot)
    loadout[slot] = petID  -- Update cache while we're at it
    
    if petID then
      local pet = pets[petID]
      if pet then
        local oldHealth = pet.health
        local health, maxHealth = C_PetJournal.GetPetStats(petID)
        if health then
          pet.health = health
          pet.maxHealth = maxHealth
          if health ~= oldHealth then
            table.insert(changed, petID)
          end
        end
      end
    end
  end
  
  rebuildHealthIndexes()
  
  if Addon.events and #changed > 0 then
    Addon.events:emit("CACHE:HEALTH_CHANGED", healthPayload(changed))
  end
end

--[[
  Refresh health for all pets
  Call after PET_JOURNAL_PETS_HEALED.
]]
function petCache:refreshAllHealth()
  local changed = {}
  
  for petID, pet in pairs(pets) do
    -- Skip synthetic unowned pets (species:123 keys) - they have no health
    if type(petID) ~= "string" or not petID:find("^species:") then
      local oldHealth = pet.health
      local health, maxHealth = C_PetJournal.GetPetStats(petID)
      if health then
        pet.health = health
        pet.maxHealth = maxHealth
        if health ~= oldHealth then
          table.insert(changed, petID)
        end
      end
    end
  end
  
  rebuildHealthIndexes()
  
  if Addon.events and #changed > 0 then
    Addon.events:emit("CACHE:HEALTH_CHANGED", healthPayload(changed, { healed = true }))
  end
end

--[[
  Add a new pet to the cache
  Call when a new pet is acquired.
  
  @param petID string - Pet GUID
  @return boolean - true if added
]]
function petCache:addPet(petID)
  if not petID or pets[petID] then return false end
  
  local pet = buildPetFromAPI(petID)
  if not pet then return false end
  
  pets[petID] = pet
  
  -- Check if this is an edge case pet (obtainable=false)
  -- These pets are skipped by GetPetInfoByIndex() on reload, so we persist them
  local _, _, _, _, _, _, isWild, canBattle, tradable, unique, obtainable = 
        C_PetJournal.GetPetInfoByPetID(petID)
  
  if obtainable == false then
    pao_edgeCasePets[petID] = true
  end
  
  -- Rebuild affected indexes
  rebuildSpeciesIndex()
  rebuildDuplicates()
  rebuildRarityStats()
  rebuildHealthIndexes()
  
  if Addon.events then
    Addon.events:emit("CACHE:COLLECTION_CHANGED", { 
      action = "added", 
      petID = petID, 
      pet = pet 
    })
  end
  
  return true
end

--[[
  Remove a pet from the cache
  Call when a pet is caged or released.
  
  @param petID string - Pet GUID
  @return boolean - true if removed
]]
function petCache:removePet(petID)
  local pet = pets[petID]
  if not pet then return false end
  
  local petName = pet.name
  local speciesID = pet.speciesID
  
  -- Remove from primary storage
  pets[petID] = nil
  
  -- Remove from indexes
  deadPets[petID] = nil
  injuredPets[petID] = nil
  
  -- Clean up from edge case persistence
  if pao_edgeCasePets[petID] then
    pao_edgeCasePets[petID] = nil
  end
  
  -- Rebuild affected indexes
  rebuildSpeciesIndex()
  rebuildDuplicates()
  rebuildRarityStats()
  
  if Addon.events then
    Addon.events:emit("CACHE:COLLECTION_CHANGED", { 
      action = "removed", 
      petID = petID, 
      speciesID = speciesID 
    })
  end
  
  return true
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

--[[
  Register Blizzard event handlers
  Called during initialization to wire up reactive updates.
  Note: PET_JOURNAL_LIST_UPDATE subscription happens in ensureReady() when PAO opens.
]]
function petCache:registerEvents()
  if not Addon.events then
    utils:error("petCache: Addon.events not available for event registration")
    return
  end
  
  -- New pet added (captured, learned from cage, etc.)
  -- This is a Blizzard event that fires with battlePetGUID
  Addon.events:subscribe("NEW_PET_ADDED", function(eventName, battlePetGUID)
    if initialized and battlePetGUID then
      petCache:addPet(battlePetGUID)
    end
  end)
  
  -- Pet deleted from journal (caged or released, via Blizzard UI or PAO).
  -- For PAO-initiated caging, COLLECTION:PET_CAGED also fires removePet();
  -- double-removal is harmless (second call returns false).
  Addon.events:subscribe("PET_JOURNAL_PET_DELETED", function(eventName, petID)
    if initialized and petID then
      petCache:removePet(petID)
    end
  end)
  
  -- Heal spell cast - Revive Battle Pets (125439) or Battle Pet Bandage (133994)
  -- PET_JOURNAL_PETS_HEALED doesn't fire in MoP Classic, use spell completion instead
  Addon.events:subscribe("UNIT_SPELLCAST_SUCCEEDED", function(eventName, unit, castGUID, spellID)
    if not initialized then return end
    if unit ~= "player" then return end
    
    -- 125439 = Revive Battle Pets spell
    -- 133994 = Battle Pet Bandage item spell
    if spellID == 125439 or spellID == 133994 then
      petCache:refreshAllHealth()
    end
  end)
  
  -- Internal heal event (from secure buttons using bandages/heal spell)
  -- UNIT_SPELLCAST_SUCCEEDED may not fire for item use via secure macro
  Addon.events:subscribe("TEAM:PETS_HEALED", function()
    if not initialized then return end
    petCache:refreshAllHealth()
  end)

  -- Battle ended - update loadout pets
  -- C_PetJournal.GetPetStats() returns stale data until PET_JOURNAL_LIST_UPDATE fires
  local waitingForPostBattleUpdate = false
  
  Addon.events:subscribe("PET_BATTLE_OVER", function(eventName)
    if not initialized then return end
    
    -- Flag that we're waiting for the journal update
    waitingForPostBattleUpdate = true
    
    -- Process leveled pets immediately (level data is accurate)
    local leveledPets = {}
    for petID, newLevel in pairs(petsLeveledInBattle) do
      refreshPetStats(petID)
      local pet = pets[petID]
      
      if pet then
        pet.level = newLevel
        table.insert(leveledPets, {
          petID = petID,
          oldLevel = newLevel - 1,
          newLevel = newLevel
        })
      end
    end
    
    petsLeveledInBattle = {}
    
    if #leveledPets > 0 and Addon.events then
      Addon.events:emit("CACHE:PETS_LEVELED", { pets = leveledPets })
    end
    
    -- Fallback: if PET_JOURNAL_LIST_UPDATE doesn't fire within 2s, force refresh
    C_Timer.After(2, function()
      if waitingForPostBattleUpdate then
        waitingForPostBattleUpdate = false
        petCache:refreshLoadoutHealth()
      end
    end)
  end)
  
  -- PET_JOURNAL_LIST_UPDATE fires after battle with accurate health data
  Addon.events:subscribe("PET_JOURNAL_LIST_UPDATE", function(eventName)
    if not initialized then return end
    
    if waitingForPostBattleUpdate then
      waitingForPostBattleUpdate = false
      petCache:refreshLoadoutHealth()
    end
  end)
  
  -- Level changed during battle - store newLevel from event payload
  -- Event provides authoritative newLevel; C_PetJournal API lags behind
  Addon.events:subscribe("PET_BATTLE_LEVEL_CHANGED", function(eventName, owner, petIndex, newLevel)
    if not initialized then return end
    
    -- Only track ally pets
    if owner ~= Enum.BattlePetOwner.Ally then return end
    
    -- Get petID from loadout slot
    local petID = C_PetJournal.GetPetLoadOutInfo(petIndex)
    
    if petID and newLevel then
      petsLeveledInBattle[petID] = newLevel
    end
  end)
  
  -- Summoned pet changed (includes rarity upgrades)
  Addon.events:subscribe("UPDATE_SUMMONPETS_ACTION", function(eventName)
    if not initialized then return end
    local summonedGUID = C_PetJournal.GetSummonedPetGUID()
    if summonedGUID then
      petCache:updatePet(summonedGUID)
    end
  end)
  
  -- Internal events from dialogs.lua - pet operations via PAO UI
  -- Rename has no Blizzard event, so we must handle it here
  Addon.events:subscribe("COLLECTION:PET_RENAMED", function(eventName, payload)
    if initialized and payload and payload.petData and payload.petData.petID then
      petCache:updatePet(payload.petData.petID)
    end
  end)
  
  -- Release and cage both remove the pet from the journal.
  -- PET_JOURNAL_PET_DELETED also fires for both; double-removal is harmless.
  Addon.events:subscribe("COLLECTION:PET_RELEASED", function(eventName, payload)
    if initialized and payload and payload.petData and payload.petData.petID then
      petCache:removePet(payload.petData.petID)
    end
  end)
  
  Addon.events:subscribe("COLLECTION:PET_CAGED", function(eventName, payload)
    if initialized and payload and payload.petData and payload.petData.petID then
      petCache:removePet(payload.petData.petID)
    end
  end)
  
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
  Addon.registerModule("petCache", {"constants", "utils", "breedDetection"}, function()
    petCache:registerEvents()
    -- Note: Full initialization happens later when pet data is ready
    return true
  end)
end

Addon.petCache = petCache
return petCache