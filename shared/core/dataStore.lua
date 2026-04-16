-- core/dataStore.lua
-- Generic CRUD module for all entity types with static/SV merging

local _, Addon = ...
local utils = Addon.utils

local dataStore = {}

-- Registry of entity type configurations
local entityRegistry = {}

-- Register an entity type configuration
function dataStore:registerEntityType(config)
    if not config.typeName or not config.svName then
        utils:error("dataStore: Invalid entity type registration - missing typeName or svName")
        return false
    end
    
    entityRegistry[config.typeName] = {
        svName = config.svName,
        staticKey = config.staticKey,
        needsPets = config.needsPets or false
    }
    
    -- SV must already exist (created by svRegistry during ADDON_LOADED).
    -- If it doesn't, the SV is missing from svRegistry — that's a bug.
    if not _G[config.svName] then
        utils:error(string.format("dataStore: SV '%s' not initialized. Register it in svRegistry.", config.svName))
    end
        
    return true
end

-- Get the SavedVariable for a given entity type
local function getSV(entityType)
    local config = entityRegistry[entityType]
    if not config then
      --  utils:error("dataStore: Unknown entity type '" .. tostring(entityType) .. "'")
        return nil
    end
    return _G[config.svName]
end

-- Get static data for a given entity type
local function getStatic(entityType)
    local config = entityRegistry[entityType]
    if not config or not config.staticKey then
        return nil
    end
    
    if Addon.data and Addon.data[config.staticKey] then
        return Addon.data[config.staticKey]
    end
    
    return nil
end

-- Merge static and SV data (SV wins on conflicts)
local function mergeData(staticData, svData)
    if not staticData and not svData then
        return nil
    end
    
    if not staticData then
        return svData
    end
    
    if not svData then
        return staticData
    end
    
    -- Create merged result (SV overrides static)
    local merged = {}
    
    -- Start with static data
    for k, v in pairs(staticData) do
        merged[k] = v
    end
    
    -- Override with SV data
    for k, v in pairs(svData) do
        merged[k] = v
    end
    
    return merged
end

-- Get single entity by type and key (merged static + SV)
function dataStore:getEntity(entityType, key)
    if not key then return nil end
    
    local sv = getSV(entityType)
    local static = getStatic(entityType)
    
    local svData = sv and sv[key]
    local staticData = static and static[key]
    
    return mergeData(staticData, svData)
end

-- Check if entity exists in static data
function dataStore:existsInStatic(entityType, key)
    if not key then return false end
    local static = getStatic(entityType)
    return static and static[key] ~= nil
end

-- Add new entity (to SV only)
function dataStore:addEntity(entityType, key, info)
    if not key or not info then
        utils:error("dataStore: Cannot add entity - invalid key or info")
        return nil
    end
    
    local sv = getSV(entityType)
    if not sv then return nil end
    
    -- Check for collision
    if sv[key] then
        utils:debug(string.format("dataStore: Entity %s/%i already exists in SV", entityType, key))
        return nil
    end
    
    info.lastUpdated = info.lastUpdated or time()
    sv[key] = info
    
    return key
end

-- Update existing entity (in SV only - stores delta, not full copy)
function dataStore:updateEntity(entityType, key, changes)
    if not key then return false end
    
    local sv = getSV(entityType)
    if not sv then return false end
    
    -- Verify entity exists somewhere (static or SV)
    local static = getStatic(entityType)
    local existsInStatic = static and static[key] ~= nil
    local existsInSV = sv[key] ~= nil
    
    if not existsInStatic and not existsInSV then
        -- Entity doesn't exist anywhere, can't update
        return false
    end
    
    -- Get or create SV entry (delta only, NOT a copy of static)
    local entity = sv[key]
    if not entity then
        entity = {}
        sv[key] = entity
    end
    
    -- Apply changes (only the delta gets stored in SV)
    for field, newValue in pairs(changes) do
        entity[field] = newValue
    end
    
    -- Update timestamp
    entity.lastUpdated = time()
    
    return true
end

-- Get all entities of a type (merged static + SV)
function dataStore:listEntities(entityType)
    local sv = getSV(entityType)
    local static = getStatic(entityType)
    
    local result = {}
    
    -- Start with all static entries
    if static then
        for key, staticData in pairs(static) do
            local svData = sv and sv[key]
            result[key] = mergeData(staticData, svData)
        end
    end
    
    -- Add SV-only entries (new discoveries not in static)
    if sv then
        for key, svData in pairs(sv) do
            if not result[key] then
                result[key] = svData
            end
        end
    end
    
    return result
end

-- Count entities of a type (merged)
function dataStore:countEntities(entityType)
    local entities = self:listEntities(entityType)
    local count = 0
    for _ in pairs(entities) do
        count = count + 1
    end
    return count
end

-- Check if entity type needs pets
function dataStore:entityNeedsPets(entityType)
    local config = entityRegistry[entityType]
    return config and config.needsPets or false
end

-- Get static data key for entity type
function dataStore:getStaticKey(entityType)
    local config = entityRegistry[entityType]
    return config and config.staticKey
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("dataStore", {"utils"}, function()
        return true
    end)
end

Addon.dataStore = dataStore
return dataStore