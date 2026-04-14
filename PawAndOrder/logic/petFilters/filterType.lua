--[[
  logic/petFilters/filterType.lua
  FilterType Base Class
  
  Defines the structure and behavior of a filter type.
  Each filter type specifies how to match, parse, and test pets.
  
  Dependencies: None (base class)
  Exports: Addon.filterType
]]

local ADDON_NAME, Addon = ...

local filterType = {}
filterType.__index = filterType

--[[
  Create a new filter type definition
  
  @param config table - Filter type configuration
    - id: string - Unique identifier
    - category: string - Category name for filter values
    - patterns: table - Array of regex patterns to match
    - parser: function(term, value, captures, wasQuoted) - Parse captured value
    - matcher: function(pet, value) - Test if pet matches value
    - resolver: function(value) - Optional value resolver (e.g., family names)
    - logicType: string - "OR" or "AND" (default: "OR")
    - supportsNegation: boolean - Can be negated with ! (default: true)
    - priority: number - Check order, lower = first (default: 100)
  @return FilterType instance
]]
function filterType:new(config)
    if not config.id then
        error("FilterType: id is required")
    end
    
    if not config.category then
        error("FilterType: category is required for " .. config.id)
    end
    
    if not config.patterns or #config.patterns == 0 then
        error("FilterType: patterns required for " .. config.id)
    end
    
    if not config.matcher then
        error("FilterType: matcher required for " .. config.id)
    end
    
    local instance = {
        id = config.id,
        category = config.category,
        patterns = config.patterns,
        parser = config.parser,
        matcher = config.matcher,
        resolver = config.resolver,
        logicType = config.logicType or "OR",
        supportsNegation = config.supportsNegation ~= false,
        priority = config.priority or 100,
    }
    
    return setmetatable(instance, filterType)
end

--[[
  Check if this filter type matches a term
  
  @param term string - Filter term to check
  @return boolean - True if any pattern matches
]]
function filterType:matchesTerm(term)
    for _, pattern in ipairs(self.patterns) do
        if term:match(pattern) then
            return true
        end
    end
    return false
end

--[[
  Parse a term to extract filter value
  
  @param term string - Filter term
  @return any - Parsed value, or nil if parsing failed
]]
function filterType:parseTerm(term)
    for _, pattern in ipairs(self.patterns) do
        local captures = {term:match(pattern)}
        if #captures > 0 then
            local value = captures[1]
            local wasQuoted = false
            
            -- Strip quotes if present (centralized quote handling)
            local unquoted = value:match('^"(.-)"$') or value:match("^'(.-)'$")
            if unquoted then
                value = unquoted
                wasQuoted = true
            end
            
            -- Apply resolver if present (e.g., resolve "dra" to "Dragonkin")
            if self.resolver then
                value = self.resolver(value)
                if not value then
                    return nil  -- Resolution failed
                end
            end
            
            -- Apply parser if present (e.g., convert to number, build structure)
            -- Parser signature: parser(term, value, captures, wasQuoted)
            if self.parser then
                value = self.parser(term, value, captures, wasQuoted)
                if value == nil then
                    return nil  -- Parsing failed
                end
            end
            
            return value
        end
    end
    return nil
end

-- ============================================================================
-- SHARED UTILITIES
-- ============================================================================

--[[
  Get familyUtils module (lazy-loaded)
  Centralizes the lazy-load pattern used by family-based filters.
  
  @return table|nil - familyUtils module or nil if not loaded
]]
function filterType.getFamilyUtils()
    return Addon.familyUtils
end

--[[
  Create a standard family resolver function
  Returns a resolver that converts family names/partials to numeric IDs.
  Used by vs, damage, counter, and family filters.
  
  @return function - Resolver function for filterType config
]]
function filterType.createFamilyResolver()
    return function(value)
        local familyUtils = filterType.getFamilyUtils()
        if familyUtils and familyUtils.resolveFamily then
            return familyUtils:resolveFamily(value)
        end
        return nil
    end
end

--[[
  Check if filter text contains ownership tokens
  Detects owned/unowned/!owned/!unowned in filter text.
  Used by UI to override collection dropdown behavior.
  
  @param filterText string - Raw filter text
  @return boolean - True if ownership tokens present
]]
function filterType.hasOwnershipToken(filterText)
    if not filterText or filterText == "" then
        return false
    end
    local padded = " " .. filterText:lower() .. " "
    return padded:find("%s!?owned%s") ~= nil or padded:find("%s!?unowned%s") ~= nil
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

Addon.filterType = filterType

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterType", {}, function()
        return true
    end)
end

return filterType