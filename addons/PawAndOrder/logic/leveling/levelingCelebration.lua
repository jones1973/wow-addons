--[[
  logic/leveling/levelingCelebration.lua
  Leveling Celebration Integration
  
  Provides integration between the leveling queue system and
  the level 25 celebration popup.
  
  Called by notifications.lua to:
    - Get next pet to level for display
    - Handle "Slot in Team" action
  
  Dependencies: levelingLogic, petCache, events
  Exports: Addon.levelingCelebration
]]

local ADDON_NAME, Addon = ...

local levelingCelebration = {}

-- Module references
local levelingLogic, petCache, events

-- ============================================================================
-- NEXT PET INFO
-- ============================================================================

--[[
  Get next pet info for celebration popup.
  Returns formatted data ready for display.
  
  @return table|nil - { petID, name, icon, level, familyName, queueName, isRare }
]]
function levelingCelebration:getNextPetInfo()
    if not levelingLogic then return nil end
    
    local pet, queueId, queueName = levelingLogic:getNextPet()
    if not pet then return nil end
    
    return {
        petID = pet.petID,
        name = pet.name or "Unknown",
        icon = pet.icon,
        level = pet.level or 1,
        familyName = pet.familyName or "Unknown",
        queueName = queueName or "Queue",
        isRare = pet.rarity == 4,
        isPinned = queueId == "pinned",
    }
end

--[[
  Check if leveling queue system is active.
  @return boolean
]]
function levelingCelebration:isEnabled()
    if not levelingLogic then return false end
    
    -- Check if any queues are enabled
    local queues = levelingLogic:getQueues()
    for _, q in ipairs(queues) do
        if q.enabled then return true end
    end
    
    return false
end

--[[
  Get count of remaining levelable pets.
  @return number
]]
function levelingCelebration:getRemainingCount()
    if not levelingLogic then return 0 end
    return levelingLogic:getTotalCount()
end

-- ============================================================================
-- TEAM SLOTTING
-- ============================================================================

--[[
  Attempt to slot a pet into the active team.
  Replaces the first pet that is level 25.
  
  @param petID string - Pet to slot
  @return boolean, string - Success, message
]]
function levelingCelebration:slotPetInTeam(petID)
    if not petID then
        return false, "No pet specified"
    end
    
    -- Find a level 25 pet in team to replace
    local slotToReplace = nil
    
    for slot = 1, 3 do
        local slotPetID = C_PetJournal.GetPetLoadOutInfo(slot)
        if slotPetID then
            local _, _, level = C_PetJournal.GetPetInfoByPetID(slotPetID)
            if level == 25 then
                slotToReplace = slot
                break
            end
        else
            -- Empty slot
            slotToReplace = slot
            break
        end
    end
    
    if not slotToReplace then
        return false, "No slot available (no level 25 pets in team)"
    end
    
    -- Slot the pet
    C_PetJournal.SetPetLoadOutInfo(slotToReplace, petID)
    
    -- Get pet name for message
    local name = "Pet"
    if petCache then
        local pet = petCache:getPet(petID)
        if pet then name = pet.name end
    end
    
    return true, string.format("%s slotted in position %d", name, slotToReplace)
end

--[[
  Slot the next queued pet into team.
  @return boolean, string - Success, message
]]
function levelingCelebration:slotNextPet()
    if not levelingLogic then
        return false, "Leveling system not available"
    end
    
    local pet = levelingLogic:getNextPet()
    if not pet then
        return false, "No pets in queue"
    end
    
    return self:slotPetInTeam(pet.petID)
end

-- ============================================================================
-- EVENT INTEGRATION
-- ============================================================================

--[[
  Called when a pet levels up.
  Checks if pet graduated from queue (hit 25).
  
  @param petID string
  @param oldLevel number
  @param newLevel number
]]
function levelingCelebration:onPetLeveled(petID, oldLevel, newLevel)
    if newLevel ~= 25 then return end
    
    -- Pet graduated - the queue will naturally exclude it now
    -- Just emit event for any listeners
    if events then
        local name, speciesID
        if petCache then
            local pet = petCache:getPet(petID)
            if pet then
                name = pet.name
                speciesID = pet.speciesID
            end
        end
        events:emit("LEVELING:PET_GRADUATED", {
            petID = petID,
            oldLevel = oldLevel,
            speciesID = speciesID,
            name = name,
        })
    end
    
    -- Clear pin if this was the pinned pet
    if levelingLogic and levelingLogic:isPinned(petID) then
        levelingLogic:clearPinnedPet()
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function levelingCelebration:initialize()
    events = Addon.events
    petCache = Addon.petCache
    levelingLogic = Addon.levelingLogic
    
    -- Subscribe to pet level events
    if events then
        events:subscribe("CACHE:PETS_LEVELED", function(eventName, payload)
            if not payload or not payload.pets then return end
            for _, petInfo in ipairs(payload.pets) do
                self:onPetLeveled(petInfo.petID, petInfo.oldLevel, petInfo.newLevel)
            end
        end)
    end
    
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("levelingCelebration", {
        "events", "petCache", "levelingLogic"
    }, function()
        return levelingCelebration:initialize()
    end)
end

Addon.levelingCelebration = levelingCelebration
return levelingCelebration
