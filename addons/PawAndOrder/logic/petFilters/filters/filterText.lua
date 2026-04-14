--[[
  logic/petFilters/filters/textFilter.lua
  Text Search Filter (Fallback)
  
  Matches pets by text search in name, species, breed, abilities, and source.
  This is the fallback filter - any term that doesn't match other patterns
  becomes a text search term.
  
  Multiple text terms use AND logic (must match ALL terms).
  
  Examples:
    spider        - Pets with "spider" in name/abilities/source
    bite          - Pets with "bite" in ability name/description
    p/p           - Pets with P/P breed
    rare spider   - Pets that are rare AND have "spider"
  
  Dependencies: FilterType, FilterRegistry
]]

local ADDON_NAME, Addon = ...

-- Wait for dependencies
if not Addon.filterType or not Addon.filterRegistry then
    error("textFilter: Dependencies not loaded")
end

local filterType = Addon.filterType

-- Helper to strip ability markup
local function stripAbilityMarkup(text)
    if not text then return "" end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")  -- Color start
    text = text:gsub("|r", "")                   -- Color end
    text = text:gsub("|H.-|h", "")               -- Link start
    text = text:gsub("|h", "")                   -- Link end
    return text
end

local textFilter = filterType:new({
    id = "text",
    category = "text",
    patterns = {"^(.+)$"},  -- Matches anything (lowest priority)
    priority = 100,
    logicType = "AND",  -- All text terms must match
    supportsNegation = false,
    
    parser = function(term, value, captures)
        return value:lower()
    end,
    
    matcher = function(pet, searchTerm)
        -- Search in: name, species name, breed, family, abilities (name + description), source
        
        -- Pet name
        if pet.name and pet.name:lower():find(searchTerm, 1, true) then
            return true
        end
        
        -- Species name
        if pet.speciesName and pet.speciesName:lower():find(searchTerm, 1, true) then
            return true
        end
        
        -- Family name (beast, critter, etc.)
        if pet.familyName and pet.familyName:lower():find(searchTerm, 1, true) then
            return true
        end
        
        -- Breed
        if pet.breedText and pet.breedText:lower():find(searchTerm, 1, true) then
            return true
        end
        
        -- Abilities
        if pet.abilities then
            for _, ability in ipairs(pet.abilities) do
                -- Ability name
                if ability.name then
                    local cleanName = stripAbilityMarkup(ability.name):lower()
                    if cleanName:find(searchTerm, 1, true) then
                        return true
                    end
                end
                
                -- Ability description
                if ability.description then
                    local cleanDesc = stripAbilityMarkup(ability.description):lower()
                    if cleanDesc:find(searchTerm, 1, true) then
                        return true
                    end
                end
            end
        end
        
        -- Source (location) - strip texture escape sequences to avoid matching icon paths
        if pet.sourceText then
            local cleanSource = Addon.utils and Addon.utils:cleanSourceText(pet.sourceText) or pet.sourceText
            if cleanSource:lower():find(searchTerm, 1, true) then
                return true
            end
        end
        
        return false
    end,
})

-- Self-register
Addon.filterRegistry:register(textFilter)

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterText", {"filterType", "filterRegistry"}, function()
        return true
    end)
end

return textFilter