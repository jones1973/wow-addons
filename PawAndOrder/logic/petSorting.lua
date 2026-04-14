-- logic/petSorting.lua
-- Comprehensive sorting logic for Paw and Order
local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in petSorting.lua.|r")
    return {}
end

local utils = Addon.utils

local petSorting = {}

-- Module-level references (initialized in initialize())
local constants

function petSorting:initialize()
    -- Resolve dependencies
    constants = Addon.constants
    
    if not constants then
        utils:error("PetSorting: Addon.constants not available")
        return false
    end

    return true
end

-- Options for dropdowns (values must match primary keys)
function petSorting:getSortOptions()
    return {
        {text = "Name", value = "name"},
        {text = "Level", value = "level"},
        {text = "Rarity", value = "rarity"},
        {text = "Family", value = "family"},
        {text = "Breed", value = "breed"},
    }
end

-- Single entry-point sorter with direction and stable tie-breaks
-- opts.primary: name|level|rarity|family|breed
-- opts.dir: asc|desc
function petSorting:sortPets(pets, opts)
    local primary = opts and opts.primary or "name"
    local dir = opts and opts.dir or "asc"
    local inv = (dir == "desc")
    
    local function less(a, b)
        local av, bv
        
        if primary == "name" then
            av, bv = a.name or "", b.name or ""
            if av ~= bv then
                if inv then return av > bv else return av < bv end
            end
        elseif primary == "level" then
            av, bv = a.level or 0, b.level or 0
            if av ~= bv then
                if inv then return av > bv else return av < bv end
            end
        elseif primary == "rarity" then
            av, bv = a.rarity or 0, b.rarity or 0
            if av ~= bv then
                if inv then return av > bv else return av < bv end
            end
        elseif primary == "family" then
            av, bv = a.familyName or "", b.familyName or ""
            if av ~= bv then
                if inv then return av > bv else return av < bv end
            end
        elseif primary == "breed" then
            av, bv = a.breedText or "", b.breedText or ""
            if av ~= bv then
                if inv then return av > bv else return av < bv end
            end
        end
        
        -- Secondary: Name asc
        local an, bn = a.name or "", b.name or ""
        if an ~= bn then
            return an < bn
        end
        
        -- Tertiary: Level desc
        local al, bl = a.level or 0, b.level or 0
        if al ~= bl then
            return al > bl
        end
        
        -- Final tiebreak: speciesID asc to keep sort stable
        return (a.speciesID or 0) < (b.speciesID or 0)
    end
    
    table.sort(pets, less)
    return pets
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("petSorting", {"utils", "constants"}, function()
        if petSorting.initialize then
            return petSorting:initialize()
        end
        return true
    end)
end

Addon.petSorting = petSorting
return petSorting