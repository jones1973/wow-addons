--[[
  logic/petFilters/filters/sourceFilter.lua
  Source Filter
  
  Matches pets by source keywords with abbreviation support.
  Multiple sources use OR logic (match ANY).
  
  Supported keywords:
    wild, vendor, drop, achievement (achi), quest, promotion (promo),
    event (world), profession (prof), pet battle, in-game shop (store, shop)
  
  Examples:
    wild            -> Wild-caught pets
    vendor          -> Vendor pets
    source:vendor   -> Same (explicit prefix)
    source:"pet battle" -> Pet Battle pets
    achi            -> Achievement pets (abbreviation)
    !wild           -> NOT wild pets
  
  Dependencies: FilterType, FilterRegistry
]]

local ADDON_NAME, Addon = ...

-- Wait for dependencies
if not Addon.filterType or not Addon.filterRegistry then
    error("sourceFilter: Dependencies not loaded")
end

local filterType = Addon.filterType

-- Source keyword map with abbreviations
local sourceKeywordMap = {
    wild = "wild",
    vendor = "vendor",
    drop = "drop",
    achievement = "achievement",
    quest = "quest",
    promotion = "promotion",
    event = "event",
    profession = "profession",
    -- Multi-word sources
    ["pet battle"] = "pet battle",
    ["in-game shop"] = "in-game shop",
    -- Abbreviations
    promo = "promotion",
    achi = "achievement",
    prof = "profession",
    world = "event",
    battle = "pet battle",
    store = "in-game shop",
    shop = "in-game shop",
}

-- Helper to resolve source keyword (exact or partial match)
local function resolveSourceKeyword(value)
    local valueLower = value:lower()
    
    -- Exact match first
    if sourceKeywordMap[valueLower] then
        return sourceKeywordMap[valueLower]
    end
    
    -- Partial match for single words only
    if not valueLower:find(" ") then
        for keyword, canonical in pairs(sourceKeywordMap) do
            if keyword:find(valueLower, 1, true) then
                return canonical
            end
        end
    end
    
    return nil
end

local sourceFilter = filterType:new({
    id = "source",
    category = "source",
    patterns = {
        "^source[:=]\"(.+)\"$",   -- source:"pet battle" (quoted)
        "^source[:=]'(.+)'$",     -- source:'pet battle' (single quoted)
        "^source[:=](.+)$",       -- source:vendor (explicit prefix)
        "^(.+)$",                 -- vendor (bare keyword, parser validates)
    },
    priority = 70,
    logicType = "OR",
    supportsNegation = true,
    
    parser = function(term, value, captures)
        -- value is already the captured group
        local resolved = resolveSourceKeyword(value)
        if resolved then
            return resolved
        end
        
        -- For explicit source: prefix with unrecognized value, do raw text match
        if term:lower():match("^source[:=]") then
            return value:lower()
        end
        
        return nil  -- Not a source keyword (bare word that doesn't match)
    end,
    
    matcher = function(pet, sourceKeyword)
        if not pet.sourceText then return false end
        
        -- Strip texture escape sequences to avoid matching icon paths
        local utils = Addon.utils
        local source = (utils and utils:cleanSourceText(pet.sourceText) or pet.sourceText):lower()
        
        -- Direct substring match
        if source:find(sourceKeyword, 1, true) then
            return true
        end
        
        -- Special cases
        if sourceKeyword == "wild" then
            return source:find("wild", 1, true) or source:find("capture", 1, true)
        elseif sourceKeyword == "promotion" then
            return source:find("promotion", 1, true) or source:find("promotional", 1, true)
        elseif sourceKeyword == "in-game shop" then
            return source:find("in-game shop", 1, true) or source:find("pet store", 1, true)
        elseif sourceKeyword == "achievement" then
            -- Also match achievement-gated vendor pets via static data
            local bySpecies = Addon.data and Addon.data.achievementBySpecies
            if bySpecies and pet.speciesID and bySpecies[pet.speciesID] then
                return true
            end
        end
        
        return false
    end,
})

-- Self-register
Addon.filterRegistry:register(sourceFilter)

-- Module registration
if Addon.registerModule then
    Addon.registerModule("filterSource", {"filterType", "filterRegistry"}, function()
        return true
    end)
end

return sourceFilter