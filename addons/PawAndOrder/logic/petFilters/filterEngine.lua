--[[
  logic/petFilters/filterEngine.lua
  Filter Engine
  
  Applies compiled filters to arrays of pets.
  Handles batch filtering operations efficiently.
  
  Dependencies: FilterRegistry, CompiledFilter
  Exports: Addon.filterEngine
]]

local ADDON_NAME, Addon = ...

-- Wait for dependencies
if not Addon.filterRegistry or not Addon.filterCompiled then
    error("filterEngine: Dependencies not loaded")
end

local filterRegistry = Addon.filterRegistry
local filterType = Addon.filterType

local filterEngine = {}

-- Lazy-load options
local function getOptions()
    return Addon.options and Addon.options.GetAll and Addon.options:GetAll()
end

-- ============================================================================
-- BATCH FILTERING
-- ============================================================================

--[[
  Apply compiled filter to array of pets
  
  @param pets table - Array of pet data
  @param compiled CompiledFilter - Compiled filter to apply
  @param opts table - Optional options:
    - contexts: boolean - Generate match contexts (default: true)
    - showNonCombat: boolean - Show non-combat pets (default: true)
  @return table - Filtered pets array
  @return table - Match contexts indexed by petID
]]
function filterEngine:apply(pets, compiled, opts)
    opts = opts or {}
    local generateContexts = opts.contexts ~= false
    local showNonCombat = opts.showNonCombat
    
    -- Get showNonCombat from options if not specified
    if showNonCombat == nil then
        local options = getOptions()
        showNonCombat = not options or options.showNonCombatPets ~= false
    end
    
    local results = {}
    local contexts = {}
    
    -- Get all filter types for matching
    local filterTypes = filterRegistry:getAllFilters()
    
    -- Get familyUtils for context generation
    local familyUtils = generateContexts and filterType.getFamilyUtils() or nil
    
    -- Filter options for matches
    local matchOpts = {
        showNonCombat = showNonCombat,
    }
    
    -- Apply filter to each pet
    for _, pet in ipairs(pets) do
        if compiled:matches(pet, filterTypes, matchOpts) then
            table.insert(results, pet)
            
            -- Generate match context if requested
            -- Caged pets (petID=nil) have no context key; they pass filters but aren't highlighted
            if generateContexts and pet.petID then
                local context = compiled:getMatchContext(pet, filterTypes, familyUtils)
                contexts[pet.petID] = context
            end
        end
    end
    
    return results, contexts
end

--[[
  Apply filter text to array of pets (convenience method)
  Parses filter text then applies it.
  
  @param pets table - Array of pet data
  @param filterText string - Filter text to parse and apply
  @param opts table - Optional options (same as apply)
  @return table - Filtered pets array
  @return table - Match contexts
]]
function filterEngine:filter(pets, filterText, opts)
    if not Addon.filterParser then
        error("filterEngine: FilterParser not loaded")
    end
    
    local compiled = Addon.filterParser:parse(filterText)
    return self:apply(pets, compiled, opts)
end

--[[
  Get match context for a single pet
  Helper for detail panel highlighting without filtering.
  
  @param pet table - Pet data
  @param filterText string - Filter text
  @return table|nil - Match context or nil
]]
function filterEngine:getMatchContext(pet, filterText)
    if not pet or not filterText or filterText == "" then
        return nil
    end
    
    if not Addon.filterParser then
        error("filterEngine: filterParser not loaded")
    end
    
    local compiled = Addon.filterParser:parse(filterText)
    local filterTypes = filterRegistry:getAllFilters()
    local familyUtils = filterType.getFamilyUtils()
    
    return compiled:getMatchContext(pet, filterTypes, familyUtils)
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

Addon.filterEngine = filterEngine

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterEngine", {"filterRegistry", "filterCompiled"}, function()
        return true
    end)
end

return filterEngine