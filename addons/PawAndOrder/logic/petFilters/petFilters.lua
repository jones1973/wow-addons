--[[
  logic/petFilters/petFilters.lua
  Pet Filters - Public API
  
  Comprehensive filtering system for pet battle collections.
  Provides text-based filtering with category-based OR/AND logic.
  
  Main API:
  - filter(pets, filterText, opts) - Filter pets by text
  - parse(filterText) - Parse filter text to CompiledFilter
  - applyCompiled(pets, compiled, opts) - Apply pre-parsed filter
  - getMatchContext(pet, filterText) - Get match context for single pet
  - clearCache() - Clear parse cache
  
  Dependencies: FilterParser, FilterEngine
  Exports: Addon.petFilters
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in petFilters.lua.|r")
    return {}
end

local utils = Addon.utils

-- Module references (lazy-loaded)
local filterParser
local filterEngine

local petFilters = {}

-- ============================================================================
-- LAZY INITIALIZATION
-- ============================================================================

local function ensureModules()
    if not filterParser then
        filterParser = Addon.filterParser
        if not filterParser then
            utils:error("petFilters: filterParser not available")
            return false
        end
    end
    
    if not filterEngine then
        filterEngine = Addon.filterEngine
        if not filterEngine then
            utils:error("petFilters: filterEngine not available")
            return false
        end
    end
    
    return true
end

-- ============================================================================
-- PRIMARY API
-- ============================================================================

--[[
  Filter pets by text filter
  Primary filtering API - parses text and applies to pets.
  
  @param pets table - Array of pet data to filter
  @param filterText string - Filter text (e.g., "rare beast >20")
  @param opts table - Optional options:
    - contexts: boolean - Generate match contexts (default: true)
    - showNonCombat: boolean - Show non-combat pets (default: from settings)
  @return table - Filtered pets array
  @return table - Match contexts indexed by result position
  
  Example:
    local filtered, contexts = petFilters:filter(allPets, "rare beast")
]]
function petFilters:filter(pets, filterText, opts)
    if not ensureModules() then
        return pets, {}
    end
    
    return filterEngine:filter(pets, filterText, opts)
end

--[[
  Parse filter text to CompiledFilter
  Useful for validation, caching, or passing compiled filters via events.
  
  @param filterText string - Filter text to parse
  @return CompiledFilter - Compiled filter object
  
  Example:
    local compiled = petFilters:parse("rare beast")
    -- Pass compiled to event or use later
]]
function petFilters:parse(filterText)
    if not ensureModules() then
        return Addon.CompiledFilter and Addon.CompiledFilter:new() or {}
    end
    
    return filterParser:parse(filterText)
end

--[[
  Apply pre-compiled filter to pets
  More efficient when filter is already parsed (e.g., from event).
  
  @param pets table - Array of pet data
  @param compiled CompiledFilter - Pre-parsed compiled filter
  @param opts table - Optional options (same as filter())
  @return table - Filtered pets array
  @return table - Match contexts
  
  Example:
    local compiled = petFilters:parse("rare beast")
    local filtered, contexts = petFilters:applyCompiled(allPets, compiled)
]]
function petFilters:applyCompiled(pets, compiled, opts)
    if not ensureModules() then
        return pets, {}
    end
    
    -- Instrumentation: Track usage
    if utils and utils.debug then
        utils:debug("petFilters:applyCompiled called with " .. #pets .. " pets")
    end
    
    return filterEngine:apply(pets, compiled, opts)
end

--[[
  Get match context for a single pet
  Helper for detail panel highlighting without filtering entire list.
  
  @param pet table - Pet data
  @param filterText string - Filter text
  @return table|nil - Match context {abilities, family, source} or nil
  
  Example:
    local context = petFilters:getMatchContext(currentPet, "rare beast")
    if context and context.family then
      -- Highlight family
    end
]]
function petFilters:getMatchContext(pet, filterText)
    if not ensureModules() then
        return nil
    end
    
    return filterEngine:getMatchContext(pet, filterText)
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("petFilters", {"filterParser", "filterEngine"}, function()
        return true
    end)
end

Addon.petFilters = petFilters
return petFilters