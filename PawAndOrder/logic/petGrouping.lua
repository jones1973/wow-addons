--[[
  logic/petGrouping.lua
  Species View Grouping Logic

  Pure function that transforms a flat list of pets into a species-grouped
  display list. No UI, no frames -- just data transformation.

  Pipeline:
    1. Separate owned from unowned pets
    2. Group owned pets by speciesID
    3. Sort within each group and extract species-level aggregates
    4. Inject unowned species into same array (with zero aggregates)
    5. Sort all species groups together by caller's sort criteria
    6. Build flat display list with typed entries

  Entry types returned in display list:
    {type="species"}   -- species header row (40px)
    {type="chipTray"}  -- expanded chip container (variable height)
    {type="unowned"}   -- unowned species row (40px)

  Dependencies: utils
  Exports: Addon.petGrouping
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in petGrouping.lua.|r")
    return {}
end

local utils = Addon.utils

local petGrouping = {}

function petGrouping:initialize()
    return true
end

-- ============================================================================
-- INTERNAL SORTING
-- ============================================================================

--[[
  Sort pets within a species group: rarity desc, then level desc.
  This determines pip order and chip order (best pet first).
]]
local function sortPetsWithinGroup(pets)
    table.sort(pets, function(a, b)
        -- Caged pets always sort after non-caged so pets[1] is always the best battleable pet
        local ac, bc = a.isCaged or false, b.isCaged or false
        if ac ~= bc then return not ac end
        local ar, br = a.rarity or 0, b.rarity or 0
        if ar ~= br then return ar > br end
        local al, bl = a.level or 0, b.level or 0
        if al ~= bl then return al > bl end
        local aid = a.petID or ""
        local bid = b.petID or ""
        return aid < bid
    end)
end

--[[
  Sort species groups by the caller's sort field and direction.
  Tiebreaker chain: species name asc, then speciesID for stability.

  Sort operates on species-level aggregates, not individual pets.
  Breed is excluded per spec -- no meaningful species-level aggregation.
]]
local function sortSpeciesGroups(groups, sortField, sortDir)
    local inv = (sortDir == "desc")

    table.sort(groups, function(a, b)
        local av, bv

        if sortField == "name" then
            av = (a.speciesName or ""):lower()
            bv = (b.speciesName or ""):lower()
            if av ~= bv then
                if inv then return av > bv else return av < bv end
            end
        elseif sortField == "level" then
            av, bv = a.bestLevel or 0, b.bestLevel or 0
            if av ~= bv then
                if inv then return av > bv else return av < bv end
            end
        elseif sortField == "rarity" then
            av, bv = a.bestRarity or 0, b.bestRarity or 0
            if av ~= bv then
                if inv then return av > bv else return av < bv end
            end
        elseif sortField == "family" then
            av = (a.familyName or ""):lower()
            bv = (b.familyName or ""):lower()
            if av ~= bv then
                if inv then return av > bv else return av < bv end
            end
        end

        -- Tiebreaker: species name asc
        local an = (a.speciesName or ""):lower()
        local bn = (b.speciesName or ""):lower()
        if an ~= bn then return an < bn end

        -- Final: speciesID for deterministic ordering
        return (a.speciesID or 0) < (b.speciesID or 0)
    end)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Transform a filtered pet list into a species-grouped display list.

  @param pets table - Array of pet entries (already filtered by base + text filters).
                      Mix of owned, caged, and unowned entries from petCache.
  @param sortField string - "name", "level", "rarity", or "family"
  @param sortDir string - "asc" or "desc"
  @param expandedSpecies table - {[speciesID] = true} for expanded species
  @param baseCollectionFilter string - "all", "owned", or "unowned"
  @param showNonCombat boolean - false to exclude canBattle==false species

  @return table - Flat array of typed display entries:
    {type="species", speciesID, speciesName, familyType, familyName,
     bestRarity, bestLevel, petCount, pips, isExpanded}
    {type="chipTray", speciesID, chips}
    {type="unowned", speciesID, speciesName, familyType, familyName}
]]
function petGrouping:group(pets, sortField, sortDir, expandedSpecies, baseCollectionFilter, showNonCombat)
    if not pets then return {} end

    sortField = sortField or "name"
    sortDir = sortDir or "asc"
    expandedSpecies = expandedSpecies or {}

    -- ========================================================================
    -- STEP 1: Separate owned from unowned
    -- ========================================================================
    local ownedPets = {}
    local unownedBySpecies = {}  -- speciesID -> first unowned pet entry (for name/family data)

    for _, pet in pairs(pets) do
        if type(pet) == "table" then
            if pet.owned == true then
                table.insert(ownedPets, pet)
            elseif pet.owned == false then
                if pet.speciesID and not unownedBySpecies[pet.speciesID] then
                    unownedBySpecies[pet.speciesID] = pet
                end
            end
        end
    end

    -- ========================================================================
    -- STEP 2: Group owned pets by speciesID
    -- ========================================================================
    local speciesGroups = {}   -- speciesID -> group table
    local speciesIDsSeen = {}  -- ordered array of speciesIDs (insertion order)

    for _, pet in ipairs(ownedPets) do
        local sid = pet.speciesID
        if sid then
            if not speciesGroups[sid] then
                speciesGroups[sid] = { pets = {} }
                table.insert(speciesIDsSeen, sid)
            end
            table.insert(speciesGroups[sid].pets, pet)
        end
    end

    -- ========================================================================
    -- STEP 3: Sort within groups and extract aggregates
    -- ========================================================================
    local sortableSpecies = {}

    for _, sid in ipairs(speciesIDsSeen) do
        local group = speciesGroups[sid]
        sortPetsWithinGroup(group.pets)

        -- Best pet is first after sort (highest rarity, then highest level, non-caged first).
        -- Use first non-caged pet for species-level aggregates; fall back to pets[1] if all caged.
        local best = group.pets[1]
        for _, pet in ipairs(group.pets) do
            if not pet.isCaged then
                best = pet
                break
            end
        end

        -- Build pips array (one per pet, same order as chips)
        local pips = {}
        for _, pet in ipairs(group.pets) do
            table.insert(pips, {
                rarity = pet.rarity or 0,
                level = pet.level or 0,
                isCaged = pet.isCaged or false,
            })
        end

        table.insert(sortableSpecies, {
            speciesID = sid,
            speciesName = best.speciesName or best.name or "Unknown",
            familyType = best.petType or 0,
            familyName = best.familyName or "Unknown",
            bestRarity = best.rarity or 0,
            bestLevel = best.level or 0,
            petCount = #group.pets,
            pips = pips,
            pets = group.pets,
        })
    end

    -- ========================================================================
    -- STEP 4: Inject unowned species (if collection filter allows)
    -- Unowned participate in the same sort as owned, interleaving naturally.
    -- ========================================================================
    if baseCollectionFilter ~= "owned" then
        local ownedSpeciesSet = {}
        for _, sid in ipairs(speciesIDsSeen) do
            ownedSpeciesSet[sid] = true
        end

        for sid, pet in pairs(unownedBySpecies) do
            if not ownedSpeciesSet[sid] then
                local canBattle = pet.canBattle
                if showNonCombat ~= false or canBattle ~= false then
                    table.insert(sortableSpecies, {
                        speciesID = sid,
                        speciesName = pet.speciesName or pet.name or "Unknown",
                        familyType = pet.petType or 0,
                        familyName = pet.familyName or "Unknown",
                        bestRarity = 0,
                        bestLevel = 0,
                        petCount = 0,
                        pips = nil,
                        pets = nil,
                        isUnowned = true,
                    })
                end
            end
        end
    end

    -- ========================================================================
    -- STEP 5: Sort all species groups (owned and unowned together)
    -- ========================================================================
    sortSpeciesGroups(sortableSpecies, sortField, sortDir)

    -- ========================================================================
    -- STEP 6: Build flat display list
    -- ========================================================================
    local displayList = {}

    for _, group in ipairs(sortableSpecies) do
        if group.isUnowned then
            table.insert(displayList, {
                type = "unowned",
                speciesID = group.speciesID,
                speciesName = group.speciesName,
                familyType = group.familyType,
                familyName = group.familyName,
            })
        else
            local isExpanded = expandedSpecies[group.speciesID] == true

            table.insert(displayList, {
                type = "species",
                speciesID = group.speciesID,
                speciesName = group.speciesName,
                familyType = group.familyType,
                familyName = group.familyName,
                bestRarity = group.bestRarity,
                bestLevel = group.bestLevel,
                petCount = group.petCount,
                pips = group.pips,
                pets = group.pets,
                isExpanded = isExpanded,
            })

            if isExpanded then
                table.insert(displayList, {
                    type = "chipTray",
                    speciesID = group.speciesID,
                    chips = group.pets,
                })
            end
        end
    end

    return displayList
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("petGrouping", {"utils"}, function()
        return petGrouping:initialize()
    end)
end

Addon.petGrouping = petGrouping
return petGrouping