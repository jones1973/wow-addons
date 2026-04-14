-- Core/abilityHarvester.lua

-- Systematically harvests all ability data from MoP Classic with persistent state

local _, Addon = ...

local utils = Addon.utils
local commands = Addon.commands

local abilityHarvester = {}

-- Configuration constants for harvest throttling
local HARVEST_BATCH_SIZE = 10        -- Process X abilities at a time
local HARVEST_DELAY_SECONDS = 2.0    -- Seconds between batches
local HARVEST_CHUNK_SIZE = 50        -- Process X abilities before requiring reload
local HARVEST_TOTAL_MAX_ID = 2000    -- Total ability IDs to eventually check

-- Initialize persistent harvest state
local function initializeHarvestState()
    if not pao_settings.harvestState then
        pao_settings.harvestState = {
            currentStartId = 1,
            totalProcessed = 0,
            totalStored = 0,
            chunkNumber = 1,
            isComplete = false,
            lastChunkStats = {}
        }
    end
end

-- Check for corrupted data from previous runs and clean it up
local function validateAndCleanExistingData()
    if not pao_ability then
        utils:debug("No existing ability data found")
        return true
    end
    
    local corruptedEntries = {}
    local nilEntries = 0
    local keylessEntries = 0
    local validEntries = 0
    
    -- Scan existing data for corruption
    for key, value in pairs(pao_ability) do
        if key == nil then
            keylessEntries = keylessEntries + 1
            table.insert(corruptedEntries, {type = "nil_key", key = key, value = value})
        elseif value == nil then
            nilEntries = nilEntries + 1
            table.insert(corruptedEntries, {type = "nil_value", key = key, value = value})
        elseif type(value) ~= "table" then
            table.insert(corruptedEntries, {type = "non_table", key = key, value = value})
        elseif not value.name or value.name == "" then
            table.insert(corruptedEntries, {type = "no_name", key = key, value = value})
        else
            validEntries = validEntries + 1
        end
    end
    
    -- Report findings
    if #corruptedEntries > 0 then
        utils:notify(string.format("🚨 Data Corruption Detected! Found %d corrupted entries:", #corruptedEntries))
        utils:notify(string.format("   - Nil values: %d", nilEntries))
        utils:notify(string.format("   - Keyless entries: %d", keylessEntries))
        utils:notify(string.format("   - Other corruption: %d", #corruptedEntries - nilEntries - keylessEntries))
        utils:notify(string.format("   - Valid entries: %d", validEntries))
        
        -- Identify the affected range to re-harvest
        local minCorruptedId = math.huge
        local maxCorruptedId = -1
        
        for _, entry in ipairs(corruptedEntries) do
            if entry.key and type(entry.key) == "number" then
                minCorruptedId = math.min(minCorruptedId, entry.key)
                maxCorruptedId = math.max(maxCorruptedId, entry.key)
            end
        end
        
        -- Clean up all corrupted data
        utils:notify("🧹 Cleaning up corrupted data...")
        for _, entry in ipairs(corruptedEntries) do
            pao_ability[entry.key] = nil
        end
        
        -- Reset harvest state to re-do the affected range
        if minCorruptedId ~= math.huge and maxCorruptedId ~= -1 then
            -- Reset to start of the corrupted chunk
            local chunkStart = math.floor((minCorruptedId - 1) / HARVEST_CHUNK_SIZE) * HARVEST_CHUNK_SIZE + 1
            utils:notify(string.format("🔄 Resetting harvest to re-do IDs %d+ due to corruption", chunkStart))
            
            if pao_settings.harvestState then
                pao_settings.harvestState.currentStartId = chunkStart
                pao_settings.harvestState.chunkNumber = math.floor((chunkStart - 1) / HARVEST_CHUNK_SIZE) + 1
                pao_settings.harvestState.totalProcessed = chunkStart - 1
                
                -- Recalculate total stored count
                local actualStored = 0
                for k, v in pairs(pao_ability) do
                    if type(k) == "number" and type(v) == "table" and v.name then
                        actualStored = actualStored + 1
                    end
                end
                pao_settings.harvestState.totalStored = actualStored
            end
        end
        
        utils:notify(string.format("✅ Cleanup complete! Removed %d corrupted entries, %d valid entries remain", 
            #corruptedEntries, validEntries))
        return false -- Indicate data was corrupted and cleaned
    else
        utils:debug(string.format("✅ Data integrity check passed: %d valid entries", validEntries))
        return true -- Data is clean
    end
end

-- Get current harvest progress info
local function getHarvestProgress()
    initializeHarvestState()
    local state = pao_settings.harvestState
    local remaining = math.max(0, HARVEST_TOTAL_MAX_ID - state.totalProcessed)
    local progress = math.floor((state.totalProcessed / HARVEST_TOTAL_MAX_ID) * 100)
    
    return {
        currentChunk = state.chunkNumber,
        startId = state.currentStartId,
        processed = state.totalProcessed,
        stored = state.totalStored,
        remaining = remaining,
        progress = progress,
        isComplete = state.isComplete
    }
end

-- Harvest current chunk with persistent state
local function harvestCurrentChunk()
    initializeHarvestState()
    local state = pao_settings.harvestState
    
    -- Check if completely done
    if state.isComplete or state.currentStartId > HARVEST_TOTAL_MAX_ID then
        utils:notify("🎉 HARVEST FULLY COMPLETE! All ability IDs have been processed.")
        return false
    end
    
    local chunkStartId = state.currentStartId
    local chunkEndId = math.min(chunkStartId + HARVEST_CHUNK_SIZE - 1, HARVEST_TOTAL_MAX_ID)
    local chunkStartTime = time()
    local currentBatch = 0
    
    -- Stats for this chunk
    local chunkStats = {
        newAbilities = 0,
        nils = 0,
        GMs = 0,
        noDescs = 0,
        skippedTests = 0
    }
    
    utils:notify(string.format("🔄 Starting Chunk %d: IDs %d-%d", 
        state.chunkNumber, chunkStartId, chunkEndId))
    utils:notify(string.format("📊 Progress: %d/%d processed (%d%% complete)", 
        state.totalProcessed, HARVEST_TOTAL_MAX_ID, 
        math.floor((state.totalProcessed / HARVEST_TOTAL_MAX_ID) * 100)))
    
    -- Helper function for whole word matching
    local function hasWholeWord(text, word)
        if not text then return false end
        local lowerText = text:lower()
        local lowerWord = word:lower()
        return lowerText:match("%f[%a]" .. lowerWord .. "%f[%A]") ~= nil
    end
    
    -- Harvest function for current batch
    local function harvestBatch(batchStartId, batchEndId)
        utils:debug(string.format("Processing batch %d: IDs %d-%d", 
            currentBatch, batchStartId, batchEndId))
        
        for abilityId = batchStartId, batchEndId do
            -- Direct API call without pcall for speed
            local id, name, icon, maxCooldown, unparsedDescription, numTurns, petType, noStrongWeakHints = 
                C_PetBattles.GetAbilityInfoByID(abilityId)
                
            if name and name ~= "" then
                -- Check for abilities with no description (skip entirely)
                if not unparsedDescription or unparsedDescription == "" then
                    chunkStats.noDescs = chunkStats.noDescs + 1
                -- Check for GM abilities (GameMaster test abilities) - whole word only
                elseif hasWholeWord(name, "gm") or hasWholeWord(unparsedDescription, "gm") then
                    chunkStats.GMs = chunkStats.GMs + 1
                -- Check for test/testing abilities - whole word only
                elseif hasWholeWord(name, "test") or hasWholeWord(unparsedDescription, "test") or 
                       hasWholeWord(name, "testing") or hasWholeWord(unparsedDescription, "testing") then
                    chunkStats.skippedTests = chunkStats.skippedTests + 1
                else
                    -- Valid ability - store it
                    pao_ability[abilityId] = {
                        name = name,
                        icon = icon,
                        cooldown = maxCooldown or 0,
                        duration = numTurns or 0,
                        familyType = petType,
                        description = unparsedDescription,
                        harvestedAt = date("%Y-%m-%d %H:%M:%S"),
                        harvestedFrom = "bulk"
                    }
                    
                    chunkStats.newAbilities = chunkStats.newAbilities + 1
                end
            else
                -- No name returned - count as nil
                chunkStats.nils = chunkStats.nils + 1
            end
        end
        
        currentBatch = currentBatch + 1
        
        -- Progress report every few batches
        if currentBatch % 3 == 0 then
            utils:notify(string.format("⏳ Chunk %d Progress: %d abilities stored", 
                state.chunkNumber, chunkStats.newAbilities))
        end
    end
    
    -- Schedule batch processing for this chunk
    local currentId = chunkStartId
    
    local function scheduleNextBatch()
        if currentId <= chunkEndId then
            local batchEnd = math.min(currentId + HARVEST_BATCH_SIZE - 1, chunkEndId)
            
            harvestBatch(currentId, batchEnd)
            
            currentId = batchEnd + 1
            
            -- Schedule next batch after delay
            if currentId <= chunkEndId then
                C_Timer.After(HARVEST_DELAY_SECONDS, scheduleNextBatch)
            else
                -- Chunk complete - update persistent state
                local chunkDuration = time() - chunkStartTime
                
                -- Update global state
                state.totalProcessed = chunkEndId
                state.totalStored = state.totalStored + chunkStats.newAbilities
                state.currentStartId = chunkEndId + 1
                state.lastChunkStats = chunkStats
                
                -- Check if completely finished
                if state.currentStartId > HARVEST_TOTAL_MAX_ID then
                    state.isComplete = true
                    utils:notify("🎉 HARVEST FULLY COMPLETE! All ability IDs processed.")
                    utils:notify(string.format("📊 Final Totals: %d abilities stored from %d total processed", 
                        state.totalStored, state.totalProcessed))
                else
                    state.chunkNumber = state.chunkNumber + 1
                    utils:notify(string.format("✅ Chunk %d Complete! %d stored, %d no-desc, %d tests, %d GMs, %d nils (%d sec)", 
                        state.chunkNumber - 1, chunkStats.newAbilities, chunkStats.noDescs, 
                        chunkStats.skippedTests, chunkStats.GMs, chunkStats.nils, chunkDuration))
                    utils:notify(string.format("🔄 Ready for next chunk (%d-%d). /reload then /pao harvestabilities", 
                        state.currentStartId, math.min(state.currentStartId + HARVEST_CHUNK_SIZE - 1, HARVEST_TOTAL_MAX_ID)))
                end
            end
        end
    end
    
    -- Start the batch processing
    scheduleNextBatch()
    
    return true
end

-- Start harvesting with persistent state
function abilityHarvester:startHarvest(forceReset)
    initializeHarvestState()
    local state = pao_settings.harvestState
    
    -- Handle force reset
    if forceReset then
        utils:notify("🔄 Resetting harvest state...")
        pao_ability = {}
        pao_settings.harvestState = nil
        pao_settings.abilityHarvestComplete = false
        initializeHarvestState()
        state = pao_settings.harvestState
    else
        -- Check data integrity before continuing
        utils:notify("🔍 Checking data integrity...")
        local dataIsClean = validateAndCleanExistingData()
        
        if not dataIsClean then
            utils:notify("⚠️ Data corruption was detected and cleaned. Continuing with corrected harvest state...")
        end
	end
    
    -- Show current progress
    local progress = getHarvestProgress()
    if progress.isComplete then
        utils:notify(string.format("🎉 Harvest already complete! %d abilities stored from %d processed.", 
            progress.stored, progress.processed))
        return
    end
    
    utils:notify(string.format("📍 Resuming harvest: Chunk %d, starting from ID %d", 
        progress.currentChunk, progress.startId))
    
    -- Start current chunk
    harvestCurrentChunk()
end

-- Show harvest status
function abilityHarvester:showStatus()
    local progress = getHarvestProgress()
    
    utils:notify("📊 Harvest Status:")
    utils:notify(string.format("   Current Chunk: %d", progress.currentChunk))
    utils:notify(string.format("   Next Start ID: %d", progress.startId))
    utils:notify(string.format("   Total Processed: %d / %d (%d%%)", 
        progress.processed, HARVEST_TOTAL_MAX_ID, progress.progress))
    utils:notify(string.format("   Abilities Stored: %d", progress.stored))
    utils:notify(string.format("   Status: %s", progress.isComplete and "Complete" or "In Progress"))
    
    if not progress.isComplete then
        utils:notify(string.format("   Next: /pao harvestabilities (will process IDs %d-%d)", 
            progress.startId, math.min(progress.startId + HARVEST_CHUNK_SIZE - 1, HARVEST_TOTAL_MAX_ID)))
    end
end

-- Register commands
commands:register({
    command = "harvestabilities",
    aliases = {"abilityharvest"},
    handler = function(args)
        if Addon.abilityHarvester then
            local forceReset = (args and type(args) == "string" and args:lower() == "reset")
            Addon.abilityHarvester:startHarvest(forceReset)
        else
            utils:error("abilityHarvester function not available")
        end
    end,
    help = "Continue harvest from where it left off (add 'reset' to start over)",
    usage = "harvestAbilities [reset]",
    category = "tools"
})

commands:register({
    command = "harveststatus",
    aliases = {"abilityharvestatus"},
    handler = function()
        if Addon.abilityHarvester then
            Addon.abilityHarvester:showStatus()
        else
            utils:error("abilityHarvester function not available")
        end
    end,
    help = "Show current harvest progress and status",
    usage = "harvestStatus",
    category = "tools"
})

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("abilityHarvester", {"utils", "commands"}, function()
        return true
    end)
end

Addon.abilityHarvester = abilityHarvester
return abilityHarvester