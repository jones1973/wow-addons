--[[
  logic/petUtils.lua
  Pet Data Utilities
  
  Utility functions for pet data processing. Badge formatting, battle stone
  handling, and Pet Journal state isolation. Cache operations have been moved
  to petCache.lua.
  
  Key Responsibilities:
    - Badge formatting for UI display (breed, duplicate count)
    - Battle stone scanning and pet rarity upgrades
    - Pet Journal state management (store/clear/restore filters)
  
  Dependencies: utils, constants, petCache
  Exports: Addon.petUtils
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in petUtils.lua.|r")
    return {}
end

local utils = Addon.utils

local petUtils = {}

-- Module-level references (initialized in initialize())
local constants, petCache

-- Caged pet scan cache — invalidated by BAG_UPDATE so keystrokes don't re-scan bags
local cagedPetsCache = nil

-- Transient Pet Journal state (used only during atomic fetch operation)
local savedPetJournalState = nil

-- Caged pet item ID (Pet Cage)
local CAGED_PET_ITEM_ID = 82800

--[[
  Initialize petUtils module
  Resolves dependencies and validates required modules are available.
  
  @return boolean - true if initialization successful
]]
function petUtils:initialize()
    -- Resolve dependencies
    constants = Addon.constants
    petCache = Addon.petCache
    
    if not constants then
        utils:error("PetUtils: Addon.constants not available")
        return false
    end

    -- Invalidate caged pet scan cache when bags change
    if Addon.events then
        Addon.events:subscribe("BAG_UPDATE", function()
            cagedPetsCache = nil
        end, petUtils)
    end

    return true
end

-- ============================================================================
-- PET JOURNAL STATE MANAGEMENT
-- Used for isolating Pet Journal filters during data operations
-- ============================================================================

--[[
  Store current Pet Journal filter state
  Captures search text, type filters, and source filters for restoration.
  Note: Collected filter state cannot be read from API, so it's not restored.
]]
function petUtils:storePetJournalState()
    if not C_PetJournal then return end
    
    savedPetJournalState = {
        searchText = C_PetJournal.GetSearchFilter(),
        typeFilters = {},
        sourceFilters = {}
    }
    
    local numTypes = C_PetJournal.GetNumPetTypes()
    for i = 1, numTypes do
        savedPetJournalState.typeFilters[i] = C_PetJournal.IsPetTypeChecked(i)
    end
    
    local numSources = C_PetJournal.GetNumPetSources()
    for i = 1, numSources do
        savedPetJournalState.sourceFilters[i] = C_PetJournal.IsPetSourceChecked(i)
    end
    
    utils:debug("petUtils: Stored Pet Journal state")
end

--[[
  Clear all Pet Journal filters
  Resets Pet Journal to default state (all pets visible).
]]
function petUtils:clearPetJournalFilters()
    if not C_PetJournal then return end
    
    C_PetJournal.SetDefaultFilters()
    
    utils:debug("petUtils: Cleared Pet Journal filters")
end

--[[
  Restore previously saved Pet Journal state
  Reapplies search text, type filters, and source filters.
  Note: Collected filter cannot be restored (API limitation).
]]
function petUtils:restorePetJournalState()
    if not C_PetJournal or not savedPetJournalState then 
        utils:debug("petUtils: No Pet Journal state to restore")
        return 
    end
    
    C_PetJournal.SetSearchFilter(savedPetJournalState.searchText or "")
    
    if savedPetJournalState.typeFilters then
        for petType, isChecked in pairs(savedPetJournalState.typeFilters) do
            C_PetJournal.SetPetTypeFilter(petType, isChecked)
        end
    end
    
    if savedPetJournalState.sourceFilters then
        for source, isChecked in pairs(savedPetJournalState.sourceFilters) do
            C_PetJournal.SetPetSourceChecked(source, isChecked)
        end
    end
    
    savedPetJournalState = nil
    utils:debug("petUtils: Restored Pet Journal state")
end

-- ============================================================================
-- DELEGATION TO PET CACHE
-- These methods delegate to petCache for backward compatibility
-- ============================================================================

--[[
  Get all pet data
  Delegates to petCache. Returns array of pet data plus stats.
  
  @return table - Array of pet data structures
  @return table - Duplicate count map
  @return table - Rarity statistics
]]
function petUtils:getAllPetData()
    if not petCache then
        petCache = Addon.petCache
    end
    
    if not petCache then
        utils:error("petUtils:getAllPetData FAILED - petCache module not available")
        return {}, {}, {}
    end
    
    if not petCache:isInitialized() then
        utils:debug("petUtils:getAllPetData - petCache not initialized yet, returning empty data")
        return {}, {}, {}
    end
    
    local pets = petCache:getAllPets()
    local dupCounts = petCache:getDuplicateCounts()
    local rarityStats = petCache:getRarityStats()
    
    -- Failure debugging - only print when we get empty data unexpectedly
    if not pets or #pets == 0 then
        utils:error("petUtils:getAllPetData FAILED - petCache:getAllPets() returned empty")
        utils:error("  petCache:isInitialized() = " .. tostring(petCache:isInitialized()))
        utils:error("  C_PetJournal exists = " .. tostring(C_PetJournal ~= nil))
        if C_PetJournal then
            local numPets, numOwned = C_PetJournal.GetNumPets()
            utils:error("  C_PetJournal.GetNumPets() = " .. tostring(numPets) .. " total, " .. tostring(numOwned) .. " owned")
        end
    end
    
    return pets, dupCounts, rarityStats
end

--[[
  Count species+breed duplicates
  Utility function for counting duplicates in a pet array.
  
  @param pets table - Array of pet data structures
  @return table - Map of "speciesID-breedText" to count
]]
function petUtils:countSpeciesBreedDuplicates(pets)
    local counts = {}
    for _, p in ipairs(pets) do
        if p.owned then
            local key = (p.speciesID or 0) .. "-" .. (p.breedText or "unknown")
            counts[key] = (counts[key] or 0) + 1
        end
    end
    return counts
end

--[[
  Calculate rarity statistics
  Counts how many owned pets exist at each rarity level (0-3).
  
  @param pets table - Array of pet data structures
  @return table - Map of rarity index to count (1-4)
]]
function petUtils:getRarityStats(pets)
    local stats = {[1]=0, [2]=0, [3]=0, [4]=0}
    for _, p in ipairs(pets) do
        local r = p.rarity or 2
        if r >= 1 and r <= 4 then
            stats[r] = stats[r] + 1
        end
    end
    return stats
end

-- ============================================================================
-- RARITY HELPERS
-- Pet-specific rarity functions with business rules
-- ============================================================================

--[[
  Get rarity color for player pets
  API and cache use 1-based rarity (1=Poor, 2=Common, 3=Uncommon, 4=Rare).
  Player pets cap at Rare (4).
  
  @param rarity number - Rarity value (1-based)
  @return table - Color table {r, g, b}
]]
function petUtils:getRarityColor(rarity)
    -- Cap at Rare (4) for player pets, default to Common (2) if invalid
    rarity = math.min(math.max(tonumber(rarity) or 2, 1), 4)
    return constants:GetRarityColor(rarity)
end

-- ============================================================================
-- BADGE FORMATTING
-- UI helper functions for pet display badges
-- ============================================================================

--[[
  Format breed badge for display
  Creates a formatted string showing breed and optional confidence.
  
  @param breedText string|nil - Breed text from pet data
  @return string - Formatted badge text or empty string
]]
function petUtils:formatBreedBadge(breedText)
    if not breedText or breedText == "" then
        return ""
    end
    return breedText
end

--[[
  Format duplicate badge for display
  Creates a formatted string for duplicate count indicator.
  
  @param count number - Number of duplicates
  @return string - Formatted badge (e.g., "x3") or empty string
]]
function petUtils:formatDuplicateBadge(count)
    if not count or count <= 1 then
        return ""
    end
    return string.format("x%d", count)
end

--[[
  Format pet name with breed for display
  Produces a WoW color-coded string: "Name (Breed)" with breed dimmed to 75%
  of the pet's rarity color. Strips confidence percentages from breed text.
  
  @param petData table - Pet data with name, rarity, breedText, owned fields
  @param maxLen number|nil - Max display length (default 50)
  @return string - Formatted display name with color codes
]]
function petUtils:formatPetDisplayName(petData, maxLen)
    maxLen = maxLen or 50
    local displayName = petData.name or "Unknown Pet"
    
    if petData.owned then
        local rarity = petData.rarity or 2
        local color = self:getRarityColor(rarity)
        local dimR = math.floor(color.r * 0.75 * 255)
        local dimG = math.floor(color.g * 0.75 * 255)
        local dimB = math.floor(color.b * 0.75 * 255)
        local breedColor = string.format("|cff%02x%02x%02x", dimR, dimG, dimB)
        
        if petData.breedText and petData.breedText ~= "" then
            local cleanBreed = string.gsub(petData.breedText, " %(%d+%%%)", "")
            cleanBreed = cleanBreed:gsub("%s+$", "")
            displayName = displayName .. " " .. breedColor .. "(" .. cleanBreed .. ")|r"
        else
            displayName = displayName .. " " .. breedColor .. "(??)|r"
        end
    end
    
    if utils then
        return utils:truncate(displayName, maxLen)
    end
    return displayName
end

-- ============================================================================
-- BAG SCANNING
-- Generic bag iteration utility used by battle stone and caged pet scanning
-- ============================================================================

--[[
  Find all bag slots containing a specific item ID
  Scans backpack (0) and 4 equipped bags. Inventory only, no bank.
  
  @param itemID number - Item ID to search for
  @return table - Array of {bag, slot} pairs
]]
function petUtils:findBagItemsByID(itemID)
    if not itemID then return {} end
    local results = {}
    for bag = 0, 4 do
        local slots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, slots do
            if C_Container.GetContainerItemID(bag, slot) == itemID then
                table.insert(results, {bag = bag, slot = slot})
            end
        end
    end
    return results
end

-- ============================================================================
-- BATTLE STONE HANDLING
-- Functions for upgrading pet rarity with battle stones
-- Uses constants.FAMILY_FLAWLESS_STONES and constants.UNIVERSAL_STONE_IDS
-- ============================================================================

--[[
  Get battle stone for a pet type
  Returns the appropriate battle stone item ID for upgrading a pet.
  
  @param petType number - Pet family type ID
  @return number|nil - Item ID of battle stone, or nil if unavailable
]]
function petUtils:getBattleStoneForType(petType)
    return constants.FAMILY_FLAWLESS_STONES[petType]
end

--[[
  Check if player has battle stone for pet type
  Scans bags for the appropriate battle stone.
  
  @param petType number - Pet family type ID
  @return boolean - true if player has the stone
  @return number|nil - Bag index if found
  @return number|nil - Slot index if found
]]
function petUtils:hasBattleStone(petType)
    local stoneID = constants.FAMILY_FLAWLESS_STONES[petType]
    if not stoneID then return false end
    
    local allStones = self:findAllBattleStones()
    local universalFallback = nil
    
    for _, stone in ipairs(allStones) do
        -- Family-specific stone: return immediately (preferred)
        if stone.itemID == stoneID then
            return true, stone.bag, stone.slot
        end
        -- Track first universal stone as fallback
        if stone.petType == 0 and not universalFallback then
            universalFallback = stone
        end
    end
    
    if universalFallback then
        return true, universalFallback.bag, universalFallback.slot
    end
    return false
end

--[[
  Find all battle stones in bags
  Returns a list of all available battle stones with bag/slot info.
  
  @return table - Array of {itemID, bag, slot, petType}
]]
function petUtils:findAllBattleStones()
    local stones = {}
    
    for bag = 0, 4 do
        local slots = C_Container.GetContainerNumSlots(bag)
        for slot = 1, slots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
                -- Check family-specific stones
                for petType, stoneID in pairs(constants.FAMILY_FLAWLESS_STONES) do
                    if itemID == stoneID then
                        table.insert(stones, {
                            itemID = itemID,
                            bag = bag,
                            slot = slot,
                            petType = petType
                        })
                        break
                    end
                end
                -- Check universal stones
                if constants.UNIVERSAL_STONE_IDS[itemID] then
                    table.insert(stones, {
                        itemID = itemID,
                        bag = bag,
                        slot = slot,
                        petType = 0  -- 0 = any type
                    })
                end
            end
        end
    end
    
    return stones
end

--[[
  Scan for battle stones that can upgrade a pet
  Finds all stones in bags that could upgrade a pet of the given type and rarity.
  
  @param petType number - Pet family type ID
  @param currentRarity number - Current pet rarity (1-4)
  @return table - Array of {itemID, bag, slot, petType, isFlawless}
]]
function petUtils:scanBattleStones(petType, currentRarity)
    local results = {}
    
    -- Can't upgrade Rare pets (rarity 4)
    if currentRarity and currentRarity >= 4 then
        return results
    end
    
    local allStones = self:findAllBattleStones()
    
    for _, stone in ipairs(allStones) do
        -- Stone matches if it's for this pet type or is flawless (petType 0)
        if stone.petType == 0 or stone.petType == petType then
            table.insert(results, {
                itemID = stone.itemID,
                bag = stone.bag,
                slot = stone.slot,
                petType = stone.petType,
                isFlawless = (stone.petType == 0)
            })
        end
    end
    
    return results
end

-- ============================================================================
-- CAGED PET SCANNING
-- Scans bags for caged battle pets (itemID 82800) and parses their data
-- from the battlepet hyperlink embedded in the item.
-- ============================================================================

--[[
  Parse a battlepet hyperlink into structured data
  Format: |cff...|Hbattlepet:speciesID:level:rarity:maxHealth:power:speed:0:creatureID|h[Name]|h|r
  
  @param link string - Item link from C_Container.GetContainerItemLink
  @return table|nil - Parsed data or nil if not a battlepet link
]]
local function parseBattlePetLink(link)
    if not link then return nil end
    
    local speciesID, level, rarity, maxHealth, power, speed, _, creatureID =
        link:match("|Hbattlepet:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)|h")
    if not speciesID then return nil end
    
    local name = link:match("|h%[(.-)%]|h")
    
    return {
        speciesID = tonumber(speciesID),
        level = tonumber(level),
        rarity = tonumber(rarity),
        maxHealth = tonumber(maxHealth),
        power = tonumber(power),
        speed = tonumber(speed),
        creatureID = tonumber(creatureID),
        name = name,
    }
end

--[[
  Scan bags for caged battle pets and build filter-pipeline-compatible entries
  
  Each returned entry has the same shape as petCache entries so it can be
  merged into the filter pipeline before grouping. Fields that don't apply
  to caged pets (petID, customName, etc.) are nil/false.
  
  Breed is detected from the hyperlink stats when species data is available.
  
  @return table - Array of caged pet entries
]]
function petUtils:scanCagedPets()
    if cagedPetsCache then return cagedPetsCache end

    local caged = {}
    local slots = self:findBagItemsByID(CAGED_PET_ITEM_ID)
    
    if #slots == 0 then
        cagedPetsCache = caged
        return caged
    end
    
    -- Resolve lazily — these are always available by the time PAO shows
    local breedDetection = Addon.breedDetection
    local speciesDB = Addon.data and Addon.data.species
    
    for _, loc in ipairs(slots) do
        local link = C_Container.GetContainerItemLink(loc.bag, loc.slot)
        local parsed = parseBattlePetLink(link)
        
        if parsed and parsed.speciesID then
            local speciesData = speciesDB and speciesDB[parsed.speciesID]
            
            -- API is authoritative for petType (familyType). Static data has 66 species with familyType=0
            -- which is invalid (valid range 1-10). API returns correct values for these.
            local _, speciesIcon, apiPetType, _, sourceText, description, _, _, tradable =
                C_PetJournal.GetPetInfoBySpeciesID(parsed.speciesID)
            local familyType = apiPetType or (speciesData and speciesData.familyType)
            if not familyType or familyType < 1 or familyType > 10 then
                utils:debug(string.format("scanCagedPets - bad familyType %s for speciesID %d", tostring(familyType), parsed.speciesID))
            end
            local familyName = (familyType and familyType >= 1 and familyType <= 10) and constants:GetPetFamilyName(familyType) or "Unknown"
            local canBattle = not speciesData or speciesData.canBattle ~= false
            local sourceTypeEnum = -1
            if Addon.data and Addon.data.speciesSourceType then
                sourceTypeEnum = Addon.data.speciesSourceType[parsed.speciesID] or -1
            end
            
            -- Detect breed from hyperlink stats
            -- breedDetection:getSpeciesData handles breed name→ID conversion
            local breedID, breedName
            if breedDetection then
                local breedSpeciesData = breedDetection:getSpeciesData(parsed.speciesID)
                if breedSpeciesData and breedSpeciesData.baseStats then
                    breedID, _, breedName = breedDetection:detectBreed(
                        parsed.speciesID, parsed.level, parsed.rarity + 1,
                        parsed.maxHealth, parsed.power, parsed.speed,
                        breedSpeciesData.baseStats, breedSpeciesData.breeds
                    )
                end
            end
            
            table.insert(caged, {
                -- Identity
                -- Synthetic petID encodes bag+slot so selection/detail display works.
                -- These IDs are session-local and not stored in SavedVariables.
                petID = string.format("caged:%d:%d", loc.bag, loc.slot),
                speciesID = parsed.speciesID,
                speciesName = parsed.name or (speciesData and speciesData.name) or "Unknown",
                name = parsed.name or (speciesData and speciesData.name) or "Unknown",
                icon = speciesIcon,
                
                -- Stats
                level = parsed.level,
                -- Battlepet hyperlink uses 0-indexed quality (0=Poor→3=Rare), same as
                -- C_PetBattles.GetBreedQuality. PAO uses 1-indexed (1=Poor→4=Rare). Add 1.
                rarity = parsed.rarity + 1,
                maxHealth = parsed.maxHealth,
                power = parsed.power,
                speed = parsed.speed,
                petType = familyType,
                familyName = familyName,
                canBattle = canBattle,
                
                -- Breed
                breedID = breedID,
                breedText = breedName or "",
                
                -- Flags — these define the caged entry shape
                owned = true,
                isCaged = true,
                customName = nil,
                isFavorite = false,
                duplicateCount = nil,
                tradable = tradable or false,
                unique = false,
                
                -- Source/flavor — from GetPetInfoBySpeciesID
                description = description or "",
                sourceText = sourceText or "",
                sourceTypeEnum = sourceTypeEnum,
            })
        end
    end
    
    cagedPetsCache = caged

    -- Count how many caged pets share the same speciesID (duplicate detection)
    local cagedSpeciesCounts = {}
    for _, entry in ipairs(caged) do
        local sid = entry.speciesID
        cagedSpeciesCounts[sid] = (cagedSpeciesCounts[sid] or 0) + 1
    end
    for _, entry in ipairs(caged) do
        entry.duplicateCount = cagedSpeciesCounts[entry.speciesID] or 1
    end

    return caged
end

-- ============================================================================
-- STAT RETRIEVAL
-- Unified stat access for both journal-owned and caged pets.
-- infoSection calls this rather than reaching into C_PetJournal directly,
-- so it stays ignorant of synthetic vs real petIDs.
-- ============================================================================

--[[
  Get live combat stats for a pet.

  For journal-owned pets, calls C_PetJournal.GetPetStats with the real GUID.
  For caged pets, returns stats parsed from the battlepet hyperlink (stored on entry).
  Callers receive the same return shape regardless of source.

  @param petData table - Pet data entry
  @return number|nil maxHealth
  @return number|nil power
  @return number|nil speed
]]
function petUtils:getPetStats(petData)
    if not petData then return nil, nil, nil end

    if petData.isCaged then
        -- Stats were parsed from the battlepet hyperlink in scanCagedPets
        return petData.maxHealth, petData.power, petData.speed
    end

    -- petData.owned guards against synthetic "species:N" petIDs which are truthy
    -- but not valid journal GUIDs — GetPetStats rejects them with a usage error
    if petData.owned and petData.petID and C_PetJournal.GetPetStats then
        local health, maxHealth, power, speed = C_PetJournal.GetPetStats(petData.petID)
        -- API returns current health and max health separately; callers want max
        return maxHealth or health, power, speed
    end

    return nil, nil, nil
end

-- ============================================================================
-- PET XP BUFF DETECTION
-- Functions for checking active pet XP buffs (Safari Hat, treats, DMF hat)
-- Uses constants.XP_BUFF for spell/item IDs
-- ============================================================================

--[[
  Check if player has a specific XP buff active
  
  @param buffKey string - Key from constants.XP_BUFF.SPELL_IDS (e.g., "SAFARI_HAT")
  @return boolean - true if buff is active
]]
function petUtils:hasXpBuff(buffKey)
  local spellId = constants.XP_BUFF.SPELL_IDS[buffKey]
  if not spellId then
    utils:debug("petUtils:hasXpBuff - Unknown buff key: " .. tostring(buffKey))
    return false
  end
  
  for i = 1, 40 do
    local _, _, _, _, _, _, _, _, _, auraSpellId = UnitBuff("player", i)
    if not auraSpellId then break end
    if auraSpellId == spellId then return true end
  end
  
  return false
end

--[[
  Get all currently active XP buffs
  
  @return table - Array of active buff keys (e.g., {"SAFARI_HAT", "PET_TREAT"})
]]
function petUtils:getActiveXpBuffs()
  local active = {}
  
  for buffKey, spellId in pairs(constants.XP_BUFF.SPELL_IDS) do
    if self:hasXpBuff(buffKey) then
      table.insert(active, buffKey)
    end
  end
  
  return active
end

--[[
  Calculate total XP bonus from all active buffs
  Buffs stack additively (10% + 25% + 50% + 10% = 95% max)
  
  @return number - Total bonus percentage (e.g., 60 for +60%)
]]
function petUtils:getTotalXpBonus()
  local total = 0
  
  for buffKey, spellId in pairs(constants.XP_BUFF.SPELL_IDS) do
    if self:hasXpBuff(buffKey) then
      total = total + (constants.XP_BUFF.PERCENTAGES[buffKey] or 0)
    end
  end
  
  return total
end

--[[
  Check if player owns an XP buff item (not whether buff is active)
  For toys, checks PlayerHasToy. For consumables, checks bags.
  
  @param buffKey string - Key from constants.XP_BUFF.ITEM_IDS
  @return boolean - true if player owns the item
  @return number|nil - Item count (for consumables) or 1 (for toys)
]]
function petUtils:hasXpBuffItem(buffKey)
  local itemId = constants.XP_BUFF.ITEM_IDS[buffKey]
  local itemType = constants.XP_BUFF.ITEM_TYPES[buffKey]
  
  if not itemId then
    return false
  end
  
  if itemType == "toy" then
    local hasToy = PlayerHasToy(itemId)
    return hasToy, hasToy and 1 or 0
  else
    -- Consumable - check bags
    local count = GetItemCount(itemId)
    return count > 0, count
  end
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("petUtils", {"utils", "constants"}, function()
        if petUtils.initialize then
            return petUtils:initialize()
        end
        return false
    end)
end

Addon.petUtils = petUtils
return petUtils