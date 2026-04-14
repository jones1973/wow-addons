--[[
  logic/petAcquisitions.lua
  Pet Acquisition Tracking
  
  Tracks when pets were acquired for "recent" filtering and visual indicators.
  Only tracks pets acquired after this feature is installed - existing pets
  have no entry and are considered "pre-feature".
  
  SavedVariable: pao_petAcquired = { [petID] = timestamp, ... }
  
  Events Subscribed:
    - NEW_PET_ADDED - Records acquisition timestamp
    - PETS:REMOVED - Cleans up removed pets
  
  Events Emitted:
    - PETS:NEW_ACQUISITION (petID, speciesID, timestamp)
  
  Dependencies: events, utils, options
  Exports: Addon.petAcquisitions
]]

local ADDON_NAME, Addon = ...

local petAcquisitions = {}

-- Module references (set during init)
local events, utils, options

-- State
local initialized = false

-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

--[[
  Get current timestamp.
  @return number - Unix timestamp
]]
local function now()
  return time()
end

--[[
  Get the appropriate storage table for a pet based on canBattle status.
  @param canBattle boolean - Whether the pet can battle
  @return table - The storage table to use
]]
local function getStorage(canBattle)
  if canBattle == false then
    pao_character = pao_character or {}
    pao_character.petAcquired = pao_character.petAcquired or {}
    return pao_character.petAcquired
  else
    pao_petAcquired = pao_petAcquired or {}
    return pao_petAcquired
  end
end

--[[
  Handle NEW_PET_ADDED event.
  @param petID string - The new pet's ID
]]
local function onNewPetAdded(petID)
  if not petID then return end
  
  -- Get pet info to determine storage location
  local speciesID, customName, level, xp, maxXp, displayID, favorite, name,
        icon, petType, creatureID, sourceText, description, isWild, canBattle = 
    C_PetJournal.GetPetInfoByPetID(petID)
  
  local storage = getStorage(canBattle)
  
  -- Skip if already tracked
  if storage[petID] then return end
  
  -- Record acquisition
  local timestamp = now()
  storage[petID] = timestamp
  
  -- Emit event for UI updates
  if events then
    events:emit("PETS:NEW_ACQUISITION", {
      petID = petID,
      speciesID = speciesID,
      timestamp = timestamp,
      name = name,
    })
  end
end

--[[
  Handle PETS:REMOVED event.
  @param payload table - {petID, speciesID, reason}
]]
local function onPetRemoved(payload)
  if not payload or not payload.petID then return end
  
  local petID = payload.petID
  
  -- Remove from account-wide storage
  if pao_petAcquired and pao_petAcquired[petID] then
    pao_petAcquired[petID] = nil
  end
  
  -- Remove from character-specific storage
  if pao_character and pao_character.petAcquired and pao_character.petAcquired[petID] then
    pao_character.petAcquired[petID] = nil
  end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Check if a pet is considered "recent".
  
  @param petID string - Pet GUID
  @param days number|nil - Days threshold (uses setting if nil)
  @return boolean - True if pet was acquired within threshold
]]
function petAcquisitions:isRecent(petID, days)
  if not petID then return false end
  
  -- Check both storages
  local acquiredAt = nil
  if pao_petAcquired and pao_petAcquired[petID] then
    acquiredAt = pao_petAcquired[petID]
  elseif pao_character and pao_character.petAcquired and pao_character.petAcquired[petID] then
    acquiredAt = pao_character.petAcquired[petID]
  end
  
  if not acquiredAt then return false end
  
  -- Get threshold
  days = days or (options and options:Get("recentPetDays")) or 14
  local cutoff = now() - (days * 24 * 60 * 60)
  
  return acquiredAt >= cutoff
end

--[[
  Get acquisition timestamp for a pet.
  
  @param petID string - Pet GUID
  @return number|nil - Unix timestamp or nil if not tracked
]]
function petAcquisitions:getAcquiredDate(petID)
  if not petID then return nil end
  
  -- Check account-wide storage first
  if pao_petAcquired and pao_petAcquired[petID] then
    return pao_petAcquired[petID]
  end
  
  -- Check character-specific storage
  if pao_character and pao_character.petAcquired and pao_character.petAcquired[petID] then
    return pao_character.petAcquired[petID]
  end
  
  return nil
end

--[[
  Get formatted acquisition date string.
  
  @param petID string - Pet GUID
  @return string|nil - Formatted date or nil if not tracked
]]
function petAcquisitions:getAcquiredDateFormatted(petID)
  local timestamp = self:getAcquiredDate(petID)
  if not timestamp then return nil end
  return date("%b %d, %Y", timestamp)
end

--[[
  Get count of recent pets.
  
  @param days number|nil - Days threshold (uses setting if nil)
  @return number
]]
function petAcquisitions:getRecentCount(days)
  days = days or (options and options:Get("recentPetDays")) or 14
  local cutoff = now() - (days * 24 * 60 * 60)
  local count = 0
  
  -- Count from account-wide storage
  if pao_petAcquired then
    for petID, acquiredAt in pairs(pao_petAcquired) do
      if acquiredAt >= cutoff then
        count = count + 1
      end
    end
  end
  
  -- Count from character-specific storage
  if pao_character and pao_character.petAcquired then
    for petID, acquiredAt in pairs(pao_character.petAcquired) do
      if acquiredAt >= cutoff then
        count = count + 1
      end
    end
  end
  
  return count
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function petAcquisitions:initialize()
  if initialized then return true end
  
  events = Addon.events
  utils = Addon.utils
  options = Addon.options
  
  -- pao_petAcquired created by svRegistry before module init.
  
  -- Subscribe to new pet events
  if events then
    events:subscribe("NEW_PET_ADDED", function(eventName, petID)
      onNewPetAdded(petID)
    end)
    
    events:subscribe("PETS:REMOVED", function(eventName, payload)
      onPetRemoved(payload)
    end)
  end
  
  initialized = true
  return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
  Addon.registerModule("petAcquisitions", {"events", "utils", "options"}, function()
    return petAcquisitions:initialize()
  end)
end

Addon.petAcquisitions = petAcquisitions
return petAcquisitions