--[[
  logic/leveling/levelingLogic.lua
  Leveling Queue Logic
  
  Core logic for pet leveling queue system:
    - Queue CRUD operations
    - Pet evaluation against queue filters
    - Priority-based queue ordering
    - Pin/override management
    - Family count calculations for special sorts
  
  Events Emitted:
    - LEVELING:QUEUE_CHANGED     - Queue added/updated/deleted/reordered
    - LEVELING:PIN_CHANGED       - Pin set or cleared
    - LEVELING:NEXT_PET_CHANGED  - Next pet to level changed
  
  SavedVariable: pao_leveling
  
  Dependencies: utils, events, petCache, petFilters, levelingDefaults
  Exports: Addon.levelingLogic
]]

local ADDON_NAME, Addon = ...

local levelingLogic = {}

-- Module references (resolved at init)
local utils, events, petCache, petFilters, levelingDefaults

-- State
local queues = {}           -- Array of queue definitions (sorted by priority)
local pinnedPetID = nil     -- Currently pinned pet (override)
local settings = {}         -- User settings
local familyCounts = nil    -- Cached { familyId = {total=N, rare=N} }
local initialized = false

-- ============================================================================
-- SAVEDVARIABLE MANAGEMENT
-- ============================================================================

--[[
  Load queues from SavedVariable or defaults.
]]
local function loadFromSaved()
    pao_leveling = pao_leveling or {}
    
    -- Load queues
    if pao_leveling.queues and #pao_leveling.queues > 0 then
        queues = pao_leveling.queues
    else
        -- Deep copy defaults
        queues = {}
        for _, q in ipairs(levelingDefaults.DEFAULT_QUEUES) do
            table.insert(queues, levelingDefaults:createQueue(q))
        end
    end
    
    -- Load pin
    pinnedPetID = pao_leveling.pinnedPetID
    
    -- Load settings
    settings = pao_leveling.settings or {}
    for k, v in pairs(levelingDefaults.DEFAULT_SETTINGS) do
        if settings[k] == nil then
            settings[k] = v
        end
    end
    
    -- Sort queues by priority
    levelingLogic:sortQueues()
end

--[[
  Save current state to SavedVariable.
]]
local function saveToSaved()
    pao_leveling = pao_leveling or {}
    pao_leveling.queues = queues
    pao_leveling.pinnedPetID = pinnedPetID
    pao_leveling.settings = settings
end

-- ============================================================================
-- QUEUE MANAGEMENT
-- ============================================================================

--[[
  Sort queues by priority (ascending).
]]
function levelingLogic:sortQueues()
    table.sort(queues, function(a, b)
        return (a.priority or 99) < (b.priority or 99)
    end)
end

--[[
  Get all queues (sorted by priority).
  @return table - Array of queue definitions
]]
function levelingLogic:getQueues()
    return queues
end

--[[
  Get queue by ID.
  @param queueId string
  @return table|nil
]]
function levelingLogic:getQueue(queueId)
    for _, q in ipairs(queues) do
        if q.id == queueId then
            return q
        end
    end
    return nil
end

--[[
  Add new queue.
  @param queue table - Queue definition
  @return boolean, string - Success, error message
]]
function levelingLogic:addQueue(queue)
    local valid, err = levelingDefaults:validateQueue(queue)
    if not valid then
        return false, err
    end
    
    table.insert(queues, queue)
    self:sortQueues()
    saveToSaved()
    
    if events then
        events:emit("LEVELING:QUEUE_CHANGED", { action = "add", queueId = queue.id })
    end
    
    return true, nil
end

--[[
  Update existing queue.
  @param queueId string
  @param updates table - Fields to update
  @return boolean, string - Success, error message
]]
function levelingLogic:updateQueue(queueId, updates)
    local queue = self:getQueue(queueId)
    if not queue then
        return false, "Queue not found"
    end
    
    -- Apply updates
    for k, v in pairs(updates) do
        if k ~= "id" then  -- Don't allow ID change
            queue[k] = v
        end
    end
    
    -- Validate after update
    local valid, err = levelingDefaults:validateQueue(queue)
    if not valid then
        return false, err
    end
    
    self:sortQueues()
    saveToSaved()
    
    if events then
        events:emit("LEVELING:QUEUE_CHANGED", { action = "update", queueId = queueId })
    end
    
    return true, nil
end

--[[
  Delete queue.
  @param queueId string
  @return boolean, string - Success, error message
]]
function levelingLogic:deleteQueue(queueId)
    -- Don't allow deleting last queue
    if #queues <= 1 then
        return false, "Cannot delete last queue"
    end
    
    for i, q in ipairs(queues) do
        if q.id == queueId then
            table.remove(queues, i)
            saveToSaved()
            
            if events then
                events:emit("LEVELING:QUEUE_CHANGED", { action = "delete", queueId = queueId })
            end
            return true, nil
        end
    end
    
    return false, "Queue not found"
end

--[[
  Duplicate queue.
  @param queueId string
  @return table|nil, string - New queue, error message
]]
function levelingLogic:duplicateQueue(queueId)
    local queue = self:getQueue(queueId)
    if not queue then
        return nil, "Queue not found"
    end
    
    local newQueue = levelingDefaults:copyQueue(queue)
    local ok, err = self:addQueue(newQueue)
    if not ok then
        return nil, err
    end
    
    return newQueue, nil
end

--[[
  Reorder queues by setting priorities.
  @param orderedIds table - Array of queue IDs in desired order
]]
function levelingLogic:reorderQueues(orderedIds)
    for i, queueId in ipairs(orderedIds) do
        local queue = self:getQueue(queueId)
        if queue then
            queue.priority = i
        end
    end
    
    self:sortQueues()
    saveToSaved()
    
    if events then
        events:emit("LEVELING:QUEUE_CHANGED", { action = "reorder" })
    end
end

--[[
  Toggle queue enabled state.
  @param queueId string
  @param enabled boolean
]]
function levelingLogic:setQueueEnabled(queueId, enabled)
    local queue = self:getQueue(queueId)
    if queue then
        queue.enabled = enabled
        saveToSaved()
        
        if events then
            events:emit("LEVELING:QUEUE_CHANGED", { action = "toggle", queueId = queueId })
        end
    end
end

-- ============================================================================
-- PIN/OVERRIDE MANAGEMENT
-- ============================================================================

--[[
  Pin a specific pet as next to level.
  @param petID string
]]
function levelingLogic:setPinnedPet(petID)
    pinnedPetID = petID
    saveToSaved()
    
    if events then
        events:emit("LEVELING:PIN_CHANGED", { petID = petID })
        events:emit("LEVELING:NEXT_PET_CHANGED")
    end
end

--[[
  Clear pinned pet.
]]
function levelingLogic:clearPinnedPet()
    pinnedPetID = nil
    saveToSaved()
    
    if events then
        events:emit("LEVELING:PIN_CHANGED", { petID = nil })
        events:emit("LEVELING:NEXT_PET_CHANGED")
    end
end

--[[
  Get pinned pet ID.
  @return string|nil
]]
function levelingLogic:getPinnedPetID()
    return pinnedPetID
end

--[[
  Check if a pet is pinned.
  @param petID string
  @return boolean
]]
function levelingLogic:isPinned(petID)
    return pinnedPetID == petID
end

-- ============================================================================
-- FAMILY COUNT CALCULATIONS
-- ============================================================================

--[[
  Rebuild family counts from pet cache.
  Called when cache updates or when needed.
]]
function levelingLogic:rebuildFamilyCounts()
    familyCounts = {}
    
    if not petCache then return end
    
    local allPets = petCache:getAllPets()
    if not allPets then return end
    
    for _, pet in ipairs(allPets) do
        if pet.owned and not pet.isCaged and pet.level < 25 and pet.petType then
            local familyId = pet.petType
            if not familyCounts[familyId] then
                familyCounts[familyId] = { total = 0, rare = 0 }
            end
            familyCounts[familyId].total = familyCounts[familyId].total + 1
            if pet.rarity == 4 then  -- Rare
                familyCounts[familyId].rare = familyCounts[familyId].rare + 1
            end
        end
    end
end

--[[
  Get family count for a pet type.
  @param petType number - Family type ID
  @return number, number - Total count, rare count
]]
function levelingLogic:getFamilyCount(petType)
    if not familyCounts then
        self:rebuildFamilyCounts()
    end
    
    local data = familyCounts[petType]
    if data then
        return data.total, data.rare
    end
    return 0, 0
end

--[[
  Get ranked family list (for family-bottom:N filter).
  @param byRare boolean - Rank by rare count (true) or total (false)
  @return table - Array of {familyId, count} sorted ascending
]]
function levelingLogic:getRankedFamilies(byRare)
    if not familyCounts then
        self:rebuildFamilyCounts()
    end
    
    local ranked = {}
    for familyId, data in pairs(familyCounts) do
        table.insert(ranked, {
            familyId = familyId,
            count = byRare and data.rare or data.total,
        })
    end
    
    table.sort(ranked, function(a, b)
        return a.count < b.count
    end)
    
    return ranked
end

-- ============================================================================
-- PET EVALUATION
-- ============================================================================

--[[
  Evaluate a single queue and return matching pets.
  @param queue table - Queue definition
  @return table - Array of matching pets (sorted)
]]
function levelingLogic:evaluateQueue(queue)
    if not petCache or not petFilters then
        return {}
    end
    
    local allPets = petCache:getAllPets()
    if not allPets then return {} end
    
    -- Base filter: owned, level < 25, can battle
    local basePets = {}
    for _, pet in ipairs(allPets) do
        if pet.owned and not pet.isCaged and pet.level < 25 and pet.canBattle ~= false then
            table.insert(basePets, pet)
        end
    end
    
    -- Apply queue filter
    local filtered = basePets
    if queue.filter and queue.filter ~= "" then
        filtered = petFilters:filter(basePets, queue.filter)
    end
    
    -- Sort results
    local sorted = self:sortPets(filtered, queue.sortField, queue.sortDir)
    
    return sorted
end

--[[
  Sort pets by leveling sort criteria.
  @param pets table - Array of pets
  @param sortField string - Field to sort by (level, name, familyCount, random)
  @param sortDir string - Direction: "asc" or "desc"
  @return table - Sorted array
]]
function levelingLogic:sortPets(pets, sortField, sortDir)
    local field = sortField or levelingDefaults.DEFAULT_SORT_FIELD
    local desc = (sortDir == "desc")
    
    -- Validate field
    if not levelingDefaults.SORT_BY_ID[field] then
        field = levelingDefaults.DEFAULT_SORT_FIELD
    end
    
    -- Handle random sort
    if field == "random" then
        -- Fisher-Yates shuffle
        local shuffled = {}
        for i, pet in ipairs(pets) do shuffled[i] = pet end
        for i = #shuffled, 2, -1 do
            local j = math.random(i)
            shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
        end
        return shuffled
    end
    
    -- Handle special family count sorts
    if field == "familyCount" or field == "familyRareCount" then
        local byRare = field == "familyRareCount"
        table.sort(pets, function(a, b)
            local aTotal, aRare = self:getFamilyCount(a.petType)
            local bTotal, bRare = self:getFamilyCount(b.petType)
            local aVal = byRare and aRare or aTotal
            local bVal = byRare and bRare or bTotal
            
            if aVal ~= bVal then
                return aVal < bVal  -- Always ascending for "bottom" families
            end
            -- Tiebreaker 1: level ascending
            local aLevel = a.level or 0
            local bLevel = b.level or 0
            if aLevel ~= bLevel then
                return aLevel < bLevel
            end
            -- Tiebreaker 2: pseudo-random based on petID
            local aID = a.petID or ""
            local bID = b.petID or ""
            local aHash, bHash = 0, 0
            for i = 1, #aID do aHash = aHash + aID:byte(i) * (i % 7 + 1) end
            for i = 1, #bID do bHash = bHash + bID:byte(i) * (i % 7 + 1) end
            return aHash < bHash
        end)
        return pets
    end
    
    -- Standard field sorts
    table.sort(pets, function(a, b)
        local aVal = a[field]
        local bVal = b[field]
        
        -- Handle nil
        if aVal == nil and bVal == nil then return false end
        if aVal == nil then return not desc end
        if bVal == nil then return desc end
        
        -- Compare
        if aVal ~= bVal then
            if desc then
                return aVal > bVal
            else
                return aVal < bVal
            end
        end
        
        -- Tiebreaker: pseudo-random based on petID (stable across refreshes)
        -- XOR petID chars to get a consistent hash
        local aID = a.petID or ""
        local bID = b.petID or ""
        local aHash, bHash = 0, 0
        for i = 1, #aID do aHash = aHash + aID:byte(i) * (i % 7 + 1) end
        for i = 1, #bID do bHash = bHash + bID:byte(i) * (i % 7 + 1) end
        return aHash < bHash
    end)
    
    return pets
end

-- ============================================================================
-- QUEUE PREVIEW
-- ============================================================================

--[[
  Get preview of combined queue (all enabled queues in priority order).
  Returns pets with their source queue info.
  @param count number - Max pets to return (default from settings)
  @return table - Array of {pet, queueId, queueName}
]]
function levelingLogic:getQueuePreview(count)
    count = count or settings.previewCount or 10
    
    local preview = {}
    local seenPetIDs = {}
    
    -- If pinned, add first
    if pinnedPetID then
        local pinnedPet = petCache and petCache:getPet(pinnedPetID)
        if pinnedPet and pinnedPet.owned and not pinnedPet.isCaged and pinnedPet.level < 25 then
            table.insert(preview, {
                pet = pinnedPet,
                queueId = "pinned",
                queueName = "Pinned",
            })
            seenPetIDs[pinnedPetID] = true
        end
    end
    
    -- Evaluate each enabled queue in priority order
    for _, queue in ipairs(queues) do
        if queue.enabled and #preview < count then
            local queuePets = self:evaluateQueue(queue)
            
            for _, pet in ipairs(queuePets) do
                if not seenPetIDs[pet.petID] then
                    table.insert(preview, {
                        pet = pet,
                        queueId = queue.id,
                        queueName = queue.name,
                    })
                    seenPetIDs[pet.petID] = true
                    
                    if #preview >= count then
                        break
                    end
                end
            end
        end
    end
    
    return preview
end

--[[
  Get next pet to level.
  @return table|nil - Pet data
  @return string|nil - Queue ID (or "pinned")
  @return string|nil - Queue name
]]
function levelingLogic:getNextPet()
    -- Check pinned first
    if pinnedPetID then
        local pinnedPet = petCache and petCache:getPet(pinnedPetID)
        if pinnedPet and pinnedPet.owned and not pinnedPet.isCaged and pinnedPet.level < 25 then
            return pinnedPet, "pinned", "Pinned"
        else
            -- Pinned pet no longer valid, clear it
            self:clearPinnedPet()
        end
    end
    
    -- Find first pet from enabled queues
    for _, queue in ipairs(queues) do
        if queue.enabled then
            local queuePets = self:evaluateQueue(queue)
            if #queuePets > 0 then
                return queuePets[1], queue.id, queue.name
            end
        end
    end
    
    return nil, nil, nil
end

--[[
  Get count of pets in a specific queue.
  @param queueId string
  @return number
]]
function levelingLogic:getQueueCount(queueId)
    local queue = self:getQueue(queueId)
    if not queue then return 0 end
    
    local pets = self:evaluateQueue(queue)
    return #pets
end

--[[
  Get total count of levelable pets across all enabled queues.
  @return number
]]
function levelingLogic:getTotalCount()
    local seenPetIDs = {}
    local total = 0
    
    for _, queue in ipairs(queues) do
        if queue.enabled then
            local queuePets = self:evaluateQueue(queue)
            for _, pet in ipairs(queuePets) do
                if not seenPetIDs[pet.petID] then
                    seenPetIDs[pet.petID] = true
                    total = total + 1
                end
            end
        end
    end
    
    return total
end

-- ============================================================================
-- SETTINGS
-- ============================================================================

--[[
  Get setting value.
  @param key string
  @return any
]]
function levelingLogic:getSetting(key)
    return settings[key]
end

--[[
  Set setting value.
  @param key string
  @param value any
]]
function levelingLogic:setSetting(key, value)
    settings[key] = value
    saveToSaved()
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

--[[
  Initialize leveling logic.
  @return boolean
]]
function levelingLogic:initialize()
    utils = Addon.utils
    events = Addon.events
    petCache = Addon.petCache
    petFilters = Addon.petFilters
    levelingDefaults = Addon.levelingDefaults
    
    if not utils or not events or not levelingDefaults then
        print("|cff33ff99PAO|r: |cffff4444levelingLogic: Missing dependencies|r")
        return false
    end
    
    -- Load saved data
    loadFromSaved()
    
    -- Subscribe to cache rebuild to update family counts
    events:subscribe("CACHE:PETS_LOADED", function()
        familyCounts = nil  -- Invalidate
    end)
    
    events:subscribe("CACHE:PET_UPDATED", function()
        familyCounts = nil  -- Invalidate
    end)
    
    initialized = true
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("levelingLogic", {
        "utils", "events", "petCache", "petFilters", "levelingDefaults"
    }, function()
        return levelingLogic:initialize()
    end)
end

Addon.levelingLogic = levelingLogic
return levelingLogic