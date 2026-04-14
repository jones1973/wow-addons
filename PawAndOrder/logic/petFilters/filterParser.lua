--[[
  logic/petFilters/filterParser.lua
  Filter Parser with LRU Cache
  
  Parses filter text into CompiledFilter objects.
  Implements LRU caching to avoid re-parsing identical filters.
  
  Dependencies: FilterType, FilterRegistry, CompiledFilter, utils
  Exports: Addon.filterParser
]]

local ADDON_NAME, Addon = ...

-- Wait for dependencies
if not Addon.filterType or not Addon.filterRegistry or not Addon.filterCompiled then
    error("filterParser: Dependencies not loaded")
end

local compiledFilter = Addon.filterCompiled
local filterRegistry = Addon.filterRegistry
local utils = Addon.utils

local filterParser = {}

-- ============================================================================
-- LRU CACHE
-- ============================================================================

local parseCache = {
    maxSize = 10,
    entries = {},  -- [filterText] = {compiled, timestamp}
    hits = 0,
    misses = 0,
}

-- Count entries in a table (Lua has no built-in for this)
local function tableCount(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

--[[
  Get cached compiled filter
  
  @param filterText string - Filter text
  @return CompiledFilter|nil
]]
local function getCached(filterText)
    local entry = parseCache.entries[filterText]
    if entry then
        entry.timestamp = GetTime()
        parseCache.hits = parseCache.hits + 1
        return entry.compiled
    end
    
    parseCache.misses = parseCache.misses + 1
    return nil
end

--[[
  Store compiled filter in cache
  Implements LRU eviction if cache is full.
  
  @param filterText string - Filter text
  @param compiled CompiledFilter - Compiled filter object
]]
local function setCached(filterText, compiled)
    if tableCount(parseCache.entries) >= parseCache.maxSize then
        -- Find least recently used entry
        local oldestKey = nil
        local oldestTime = math.huge
        
        for key, entry in pairs(parseCache.entries) do
            if entry.timestamp < oldestTime then
                oldestTime = entry.timestamp
                oldestKey = key
            end
        end
        
        -- Evict oldest
        if oldestKey then
            parseCache.entries[oldestKey] = nil
        end
    end
    
    -- Add new entry
    parseCache.entries[filterText] = {
        compiled = compiled,
        timestamp = GetTime(),
    }
end

--[[
  Clear parse cache
]]
function filterParser:clearCache()
    parseCache.entries = {}
    parseCache.hits = 0
    parseCache.misses = 0
end

--[[
  Get cache statistics
  
  @return table - {hits, misses, hitRate, size}
]]
function filterParser:getCacheStats()
    local size = tableCount(parseCache.entries)
    local total = parseCache.hits + parseCache.misses
    local hitRate = total > 0 and (parseCache.hits / total) or 0
    
    return {
        hits = parseCache.hits,
        misses = parseCache.misses,
        hitRate = hitRate,
        size = size,
        maxSize = parseCache.maxSize,
    }
end

-- ============================================================================
-- PARSING
-- ============================================================================

--[[
  Strip negation prefix from term
  
  @param term string - Filter term
  @return string, boolean - Term without prefix, was negated
]]
local function stripNegation(term)
    if term:sub(1, 1) == "!" then
        local stripped = term:sub(2)
        -- Reject empty or double-negated terms
        if stripped == "" or stripped:sub(1, 1) == "!" then
            return nil, false
        end
        return stripped, true
    end
    return term, false
end

--[[
  Parse filter text into CompiledFilter
  
  @param filterText string - Filter text to parse
  @return CompiledFilter - Compiled filter object
]]
function filterParser:parse(filterText)
    if not filterText or filterText == "" then
        return compiledFilter:new()  -- Empty filter
    end
    
    -- Check cache first
    local cached = getCached(filterText)
    if cached then
        return cached
    end
    
    -- Parse new filter
    local compiled = compiledFilter:new()
    local filterTypes = filterRegistry:getAllFilters()
    
    -- Process each term (utils:tokenize handles quoted strings)
    local terms = utils:tokenize(utils:trim(filterText):lower())
    for _, term in ipairs(terms) do
        local strippedTerm, negated = stripNegation(term)
        if strippedTerm then
            -- Try each filter type in priority order
            for _, filterType in ipairs(filterTypes) do
                if filterType:matchesTerm(strippedTerm) then
                    local value = filterType:parseTerm(strippedTerm)
                    
                    if value ~= nil then
                        -- Skip negated filters that don't support negation
                        if not negated or filterType.supportsNegation then
                            compiled:add(filterType, value, negated)
                        end
                        break
                    end
                end
            end
        end
    end
    
    -- Cache the result
    setCached(filterText, compiled)
    
    return compiled
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

Addon.filterParser = filterParser

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterParser", {"filterType", "filterRegistry", "filterCompiled", "utils"}, function()
        return true
    end)
end

return filterParser