--[[
  logic/petFilters/compiledFilter.lua
  Compiled Filter Object
  
  Represents a parsed and compiled filter that can be applied to pets.
  Provides unified matching logic for both positive and negative filters.
  
  Key features:
  - Immutable after compilation
  - Efficient matching (no re-parsing)
  - Unified positive/negative filter handling
  - Optional match context generation for highlighting
  
  Dependencies: None (standalone)
  Exports: CompiledFilter class
]]

local ADDON_NAME, Addon = ...

local compiledFilter = {}
compiledFilter.__index = compiledFilter

-- ============================================================================
-- CONSTRUCTION
-- ============================================================================

--[[
  Create a new CompiledFilter instance
  
  @return compiledFilter
]]
function compiledFilter:new()
    local instance = {
        positive = {},  -- [category] = {values...}
        negative = {},  -- [category] = {values...}
        isEmpty = true,
    }
    return setmetatable(instance, compiledFilter)
end

--[[
  Add a filter value to the compiled filter
  
  @param filterType FilterType - The filter type definition
  @param value any - Parsed filter value
  @param negated boolean - True if this is a negated filter
]]
function compiledFilter:add(filterType, value, negated)
    if not filterType or value == nil then return end
    
    self.isEmpty = false
    
    -- Use filter type's category
    local category = filterType.category
    if not category then
        return  -- Skip filters without category (shouldn't happen)
    end
    
    local container = negated and self.negative or self.positive
    
    if not container[category] then
        container[category] = {}
    end
    
    table.insert(container[category], value)
end

-- ============================================================================
-- QUERYING
-- ============================================================================

--[[
  Check if this filter is empty (no filters applied)
  
  @return boolean
]]
function compiledFilter:isFilterEmpty()
    return self.isEmpty
end

--[[
  Check if pet passes all positive filters
  
  @param pet table - Pet data
  @param filterType FilterType - Filter type to check
  @return boolean
]]
local function matchesPositiveFilter(self, pet, filterType)
    local values = self.positive[filterType.category]
    if not values or #values == 0 then
        return true  -- No filter of this type, pass
    end
    
    if filterType.logicType == "OR" then
        -- OR logic: pet must match ANY value
        for _, value in ipairs(values) do
            if filterType.matcher(pet, value) then
                return true
            end
        end
        return false
    else
        -- AND logic: pet must match ALL values
        for _, value in ipairs(values) do
            if not filterType.matcher(pet, value) then
                return false
            end
        end
        return true
    end
end

--[[
  Check if pet is excluded by negative filters
  
  @param pet table - Pet data
  @param filterType FilterType - Filter type to check
  @return boolean - True if pet should be excluded
]]
local function matchesNegativeFilter(self, pet, filterType)
    local values = self.negative[filterType.category]
    if not values or #values == 0 then
        return false  -- No negation of this type, don't exclude
    end
    
    -- Negative filters: exclude if pet matches ANY negated value
    for _, value in ipairs(values) do
        if filterType.matcher(pet, value) then
            return true  -- Match found, exclude this pet
        end
    end
    
    return false  -- No matches, don't exclude
end

--[[
  Check if pet matches this compiled filter
  
  Main matching logic that applies all positive and negative filters.
  
  @param pet table - Pet data to test
  @param filterTypes table - All filter type definitions
  @param opts table - Optional options
    - showNonCombat: boolean (default true) - Show non-combat pets
  @return boolean - True if pet matches all criteria
]]
function compiledFilter:matches(pet, filterTypes, opts)
    opts = opts or {}
    local showNonCombat = opts.showNonCombat ~= false
    
    -- Filter out non-combat pets if option is disabled
    if not showNonCombat and pet.canBattle == false then
        return false
    end
    
    -- If no filters applied, all pets match (except non-combat if filtered)
    if self.isEmpty then
        return true
    end
    
    -- Apply positive filters (AND logic across filter types)
    for _, filterType in ipairs(filterTypes) do
        if not matchesPositiveFilter(self, pet, filterType) then
            return false
        end
    end
    
    -- Apply negative filters (exclude if ANY match)
    for _, filterType in ipairs(filterTypes) do
        if matchesNegativeFilter(self, pet, filterType) then
            return false  -- Excluded by negative filter
        end
    end
    
    return true
end

-- ============================================================================
-- MATCH CONTEXT GENERATION
-- ============================================================================

--[[
  Generate match context for a pet (for highlighting)
  
  Returns information about which filters matched, useful for
  highlighting matched abilities, sources, etc. in the UI.
  
  Design: First verifies pet matches the filter (detail panel can show
  non-matching pets). Then uses simple category presence checks for most
  filters, with fine-grained checking only for text and ability filters.
  
  @param pet table - Pet data
  @param filterTypes table - Filter type definitions (for matches() check)
  @param familyUtils table - familyUtils module for family comparisons
  @return table|nil - Match context with structure:
    {
      abilities = {[abilityID] = matchType},  -- "vs", "damage", "counter", "text"
      family = boolean,
      source = boolean,
      name = boolean,
      level = boolean,
      breed = boolean,
      tradable = boolean,
      unique = boolean,
      upgradeable = boolean,
    }
]]

function compiledFilter:getMatchContext(pet, filterTypes, familyUtils)
    if self.isEmpty or not pet then
        return nil
    end
    
    -- Only generate context for pets that actually match the filter
    -- (detail panel can show non-matching pets when selection persists)
    if not self:matches(pet, filterTypes) then
        return nil
    end
    
    local context = {
        abilities = {},
        family = false,
        source = false,
        name = false,
        level = false,
        breed = false,
        tradable = false,
        unique = false,
        upgradeable = false,
    }
    
    local hasMatches = false
    
    -- ========================================================================
    -- SIMPLE CATEGORY MAPPINGS
    -- If pet passed filter and category has values, the corresponding field matched.
    -- Check both positive and negative - negated filters still indicate relevance.
    -- ========================================================================
    
    -- Helper to check if category has values (positive or negative)
    local function hasCategory(cat)
        return (self.positive[cat] and #self.positive[cat] > 0) or
               (self.negative[cat] and #self.negative[cat] > 0)
    end
    
    -- Species filter highlights name
    if hasCategory("species") then
        context.name = true
        hasMatches = true
    end
    
    -- Family filter highlights family
    if hasCategory("family") then
        context.family = true
        hasMatches = true
    end
    
    -- Source filter highlights source (also conditional filter checks sourceText)
    if hasCategory("source") or hasCategory("conditional") then
        context.source = true
        hasMatches = true
    end
    
    -- Level filters highlight level
    if hasCategory("level") or hasCategory("levelRange") or hasCategory("levelOps") then
        context.level = true
        hasMatches = true
    end
    
    -- Tradable filter highlights cageable element
    if hasCategory("tradable") then
        context.tradable = true
        hasMatches = true
    end
    
    -- Unique filter highlights unique element
    if hasCategory("unique") then
        context.unique = true
        hasMatches = true
    end
    
    -- Upgradeable filter highlights upgradeable element
    if hasCategory("upgradeable") then
        context.upgradeable = true
        hasMatches = true
    end
    
    -- ========================================================================
    -- ABILITY FILTERS (need fine-grained checking to identify WHICH abilities)
    -- ========================================================================
    
    -- Get ability database for ability family lookups
    local abilityDB = Addon.data and Addon.data.abilities
    
    -- VS (strong against) - identify abilities that are strong vs target family
    local vsValues = self.positive.vs
    if vsValues and #vsValues > 0 and pet.abilities and familyUtils and abilityDB then
        for _, targetFamilyId in ipairs(vsValues) do
            for _, ability in ipairs(pet.abilities) do
                if ability.abilityID then
                    local abilityData = abilityDB[ability.abilityID]
                    if abilityData and abilityData.familyType then
                        if familyUtils:isStrongAgainst(abilityData.familyType, targetFamilyId) then
                            context.abilities[ability.abilityID] = "vs"
                            hasMatches = true
                        end
                    end
                end
            end
        end
    end
    
    -- Damage type - identify abilities matching damage family
    local damageValues = self.positive.damage
    if damageValues and #damageValues > 0 and pet.abilities and abilityDB then
        for _, damageFamilyId in ipairs(damageValues) do
            for _, ability in ipairs(pet.abilities) do
                if ability.abilityID then
                    local abilityData = abilityDB[ability.abilityID]
                    if abilityData and abilityData.familyType == damageFamilyId then
                        -- Don't overwrite "vs" with "damage"
                        if not context.abilities[ability.abilityID] then
                            context.abilities[ability.abilityID] = "damage"
                            hasMatches = true
                        end
                    end
                end
            end
        end
    end
    
    -- Counter (double-counter) - pet weak vs target, ability strong vs target
    local counterValues = self.positive.counter
    if counterValues and #counterValues > 0 and pet.abilities and familyUtils and pet.petType and abilityDB then
        for _, targetFamilyId in ipairs(counterValues) do
            if familyUtils:isWeakAgainst(pet.petType, targetFamilyId) then
                for _, ability in ipairs(pet.abilities) do
                    if ability.abilityID then
                        local abilityData = abilityDB[ability.abilityID]
                        if abilityData and abilityData.familyType then
                            if familyUtils:isStrongAgainst(abilityData.familyType, targetFamilyId) then
                                context.abilities[ability.abilityID] = "counter"
                                hasMatches = true
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- ========================================================================
    -- TEXT FILTER (searches multiple fields - need to check which matched)
    -- ========================================================================
    
    local textValues = self.positive.text
    if textValues and #textValues > 0 then
        for _, searchText in ipairs(textValues) do
            local search = searchText:lower()
            
            -- Check pet name
            if pet.name and pet.name:lower():find(search, 1, true) then
                context.name = true
                hasMatches = true
            end
            
            -- Check species name
            if pet.speciesName and pet.speciesName:lower():find(search, 1, true) then
                context.name = true
                hasMatches = true
            end
            
            -- Check pet family name
            if pet.familyName and pet.familyName:lower():find(search, 1, true) then
                context.family = true
                hasMatches = true
            end
            
            -- Check breed
            if pet.breedText and pet.breedText:lower():find(search, 1, true) then
                context.breed = true
                hasMatches = true
            end
            
            -- Check source
            if pet.sourceText then
                local cleanSource = Addon.utils and Addon.utils:cleanSourceText(pet.sourceText) or pet.sourceText
                if cleanSource:lower():find(search, 1, true) then
                    context.source = true
                    hasMatches = true
                end
            end
            
            -- Check ability names and descriptions
            if pet.abilities then
                for _, ability in ipairs(pet.abilities) do
                    if ability.abilityID then
                        local matched = false
                        if ability.name and ability.name:lower():find(search, 1, true) then
                            matched = true
                        end
                        if not matched and ability.description then
                            local cleanDesc = ability.description:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h", ""):gsub("|h", "")
                            if cleanDesc:lower():find(search, 1, true) then
                                matched = true
                            end
                        end
                        if matched and not context.abilities[ability.abilityID] then
                            context.abilities[ability.abilityID] = "text"
                            hasMatches = true
                        end
                    end
                end
            end
        end
    end
    
    return hasMatches and context or nil
end

-- ============================================================================
-- DEBUGGING
-- ============================================================================

--[[
  Get a string representation of this filter for debugging
  
  @return string
]]
function compiledFilter:toString()
    if self.isEmpty then
        return "CompiledFilter(empty)"
    end
    
    local parts = {}
    
    -- Positive filters
    for category, values in pairs(self.positive) do
        table.insert(parts, string.format("%s: %d values", category, #values))
    end
    
    -- Negative filters
    for category, values in pairs(self.negative) do
        table.insert(parts, string.format("!%s: %d values", category, #values))
    end
    
    return "CompiledFilter(" .. table.concat(parts, ", ") .. ")"
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

Addon.filterCompiled = compiledFilter

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterCompiled", {}, function()
        return true
    end)
end

return compiledFilter