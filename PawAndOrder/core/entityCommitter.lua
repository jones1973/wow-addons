-- core/entityCommitter.lua
-- Entity-agnostic commit handler with smart change detection

local _, Addon = ...
local utils = Addon.utils
local location = Addon.location
local dataStore = Addon.dataStore

local entityCommitter = {}

-- Fields tracked for changes at root level
local TRACKED_FIELDS = {
    "name",
    "faction",
    "race",
    "gender"
}

-- Compare two pet arrays to see if they're different
-- Returns false if same, or a string describing the difference
local function petsAreDifferent(oldPets, newPets)
    if not oldPets and not newPets then return false end
    if not oldPets then return "old pets nil" end
    if not newPets then return "new pets nil" end
    if #oldPets ~= #newPets then return string.format("count %d->%d", #oldPets, #newPets) end
    
    for i = 1, #newPets do
        local oldPet = oldPets[i]
        local newPet = newPets[i]
        local petName = (newPet and newPet.name) or (oldPet and oldPet.name) or "?"
        
        if not oldPet then return string.format("[%d-%s] old nil", i, petName) end
        if not newPet then return string.format("[%d-%s] new nil", i, petName) end
        if oldPet.speciesID ~= newPet.speciesID then 
            return string.format("[%d-%s] speciesID %d->%d", i, petName, oldPet.speciesID or 0, newPet.speciesID or 0)
        end
        if oldPet.level ~= newPet.level then 
            return string.format("[%d-%s] level %d->%d", i, petName, oldPet.level or 0, newPet.level or 0)
        end
        
        -- Check abilities (only if at least one side has them)
        local oldAbilities = oldPet.abilities
        local newAbilities = newPet.abilities
        if oldAbilities or newAbilities then
            if not oldAbilities then 
                return string.format("[%d-%s] old abilities nil", i, petName)
            elseif not newAbilities then 
                return string.format("[%d-%s] new abilities nil", i, petName)
            elseif #oldAbilities ~= #newAbilities then 
                return string.format("[%d-%s] abilities count %d->%d", i, petName, #oldAbilities, #newAbilities)
            else
                for j = 1, #newAbilities do
                    if oldAbilities[j] ~= newAbilities[j] then 
                        return string.format("[%d-%s] ability[%d] %d->%d", i, petName, j, oldAbilities[j] or 0, newAbilities[j] or 0)
                    end
                end
            end
        end
    end
    
    return false
end

-- Compare two locations for meaningful differences
-- Uses a tolerance for coordinates since player position varies slightly per observation
local COORD_TOLERANCE = 1.0  -- 1% of map scale

local function locationChanged(oldLoc, newLoc)
    if not oldLoc and not newLoc then return false end
    if not oldLoc or not newLoc then return true end
    if oldLoc.mapID ~= newLoc.mapID then return true end
    -- Both have coords: compare with tolerance
    if oldLoc.x and oldLoc.y and newLoc.x and newLoc.y then
        local dx = oldLoc.x - newLoc.x
        local dy = oldLoc.y - newLoc.y
        return math.sqrt(dx * dx + dy * dy) > COORD_TOLERANCE
    end
    -- One has coords and the other doesn't: that's a change
    if (oldLoc.x and not newLoc.x) or (newLoc.x and not oldLoc.x) then return true end
    return false
end

-- Compute differences between old and new entity data
local function computeDifferences(oldEntity, newInfo)
    local changes = {}

    for _, field in ipairs(TRACKED_FIELDS) do
        local oldValue = oldEntity[field]
        local newValue = newInfo[field]

        if oldValue ~= newValue then
            changes[field] = {old = oldValue, new = newValue}
        end
    end

    -- Location comparison: resolve existing entity's best location and compare
    -- against the single observation in newInfo.locations[1]
    local existingLoc = location:getNpcLocation(oldEntity)
    local newLoc = newInfo.locations and newInfo.locations[1]
    if locationChanged(existingLoc, newLoc) then
        changes.location = {old = existingLoc, new = newLoc}
    end

    -- Special handling for pets array
    local petsDiff = petsAreDifferent(oldEntity.pets, newInfo.pets)
    if petsDiff then
        changes.pets = {old = oldEntity.pets, new = newInfo.pets, reason = petsDiff}
    end

    return changes
end

-- Format change log for debug output
local function formatChangeLog(npcId, entityType, changes)
    local lines = {
        string.format("Entity %i updated:", npcId)
    }
    
    for field, change in pairs(changes) do
        if field == "pets" then
            table.insert(lines, string.format("  - pets: %s", change.reason or "[array changed]"))
        elseif field == "location" then
            local old = change.old
            local new = change.new
            local oldStr = old and string.format("mapID=%d (%.1f, %.1f)", old.mapID or 0, old.x or 0, old.y or 0) or "none"
            local newStr = new and string.format("mapID=%d (%.1f, %.1f)", new.mapID or 0, new.x or 0, new.y or 0) or "none"
            table.insert(lines, string.format("  - location: %s -> %s", oldStr, newStr))
        elseif field == "types" then
            table.insert(lines, string.format("  - types: 0x%02X -> 0x%02X", change.old or 0, change.new or 0))
        else
            table.insert(lines, string.format("  - %s: %s -> %s", field, tostring(change.old), tostring(change.new)))
        end
    end
    
    return table.concat(lines, "\n")
end

-- Main commit function
function entityCommitter:commit(info)
    if not info or not info.npcID or not info.entityType then
        utils:error("entityCommitter:commit - invalid parameters")
        return false
    end

    -- Add notes field if missing
    if not info.notes then
        info.notes = ""
    end

    -- Prepare filtered record for storage (remove npcID and entityType from stored data)
    local persist = {}
    for k, v in pairs(info) do
        if k ~= "npcID" and k ~= "entityType" then
            persist[k] = v
        end
    end

    local key = info.npcID
    local entityType = info.entityType
    
    -- Get merged entity (static + SV)
    local existing = dataStore:getEntity(entityType, key)

    if not existing then
        -- Brand new entity (not in static or SV)
        local newKey = dataStore:addEntity(entityType, key, persist)
        if newKey then
            utils:notify(string.format("New %s discovered: %s (%i)", 
                entityType, persist.name, newKey))
        else
            utils:error(string.format("entityCommitter: Failed to add %s '%s'", 
                entityType, persist.name))
        end
        return true
    else
        -- Existing entity - check for changes

        -- Merge NPC type flags (bit.bor preserves existing types, adds new ones)
        if info.types and existing.types then
            local mergedTypes = bit.bor(existing.types, info.types)
            persist.types = mergedTypes
            info.types = mergedTypes
        end

        local changes = computeDifferences(existing, info)

        -- Type flags use bit.bor merge, not tracked by computeDifferences
        if persist.types and persist.types ~= (existing.types or 0) then
            changes.types = {old = existing.types or 0, new = persist.types}
        end
        
        if next(changes) then
            -- Has changes - update SV with new data
            local updateData = {}
            for field, change in pairs(changes) do
                if field == "location" then
                    updateData.locations = info.locations
                elseif field == "pets" then
                    updateData.pets = info.pets
                    updateData.petOrder = info.petOrder
                else
                    updateData[field] = change.new
                end
            end

            -- Update timestamp
            updateData.lastUpdated = date("%Y-%m-%d %H:%M:%S")

            if dataStore:updateEntity(entityType, key, updateData) then
                utils:debug(string.format("Entity updated: %s (%s) - %s", 
                    persist.name, entityType, formatChangeLog(key, entityType, changes)))
            else
                utils:error(string.format("entityCommitter: Failed to update %s '%s'", 
                    entityType, persist.name))
            end
            return true
        else
            -- No changes - don't update anything (not even timestamp)
            return true
        end
    end
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("entityCommitter", {"utils", "location", "dataStore"}, function()
        return true
    end)
end

Addon.entityCommitter = entityCommitter
return entityCommitter