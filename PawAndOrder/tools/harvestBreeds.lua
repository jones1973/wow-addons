-- tools/harvestBreeds.lua
-- Harvests available breed data from Battle Pet BreedID addon.
-- Iterates BPBID_Arrays.BreedsPerSpecies, filters to MoP Classic species
-- via GetPetInfoBySpeciesID existence check. No Pet Journal filter manipulation.
-- Also captures BPBID's BasePetStats for cross-validation against wago.db.
--
-- Usage: /pao harvest breeds
-- Requires: Battle Pet BreedID addon loaded
--
-- Output: pao_tools.breedHarvest SavedVariable
-- Dependencies: utils

-- luacheck: globals pao_tools
-- luacheck: read_globals BPBID_Arrays date

local _, Addon = ...

local harvestBreeds = {}

--[[
  Harvest breed data from BPBID for all MoP Classic species.
  Iterates BPBID tables directly, uses GetPetInfoBySpeciesID to filter
  to species that exist in this client. No Pet Journal filter manipulation.
  Synchronous -- just reading Lua tables, no API throttling needed.
]]
local function runHarvest()
    local utils = Addon.utils

    -- Validate BPBID is loaded
    if not BPBID_Arrays then
        utils:error("Battle Pet BreedID not detected. Install and enable it, then /reload.")
        return
    end

    if not BPBID_Arrays.BreedsPerSpecies then
        utils:error("BPBID_Arrays.BreedsPerSpecies not found. Is BPBID fully loaded?")
        return
    end

    local hasBaseStats = (BPBID_Arrays.BasePetStats ~= nil)

    utils:notify("Harvesting breed data from BPBID...")

    local speciesData = {}
    local counts = {
        total = 0,
        withBaseStats = 0,
        missingBreeds = 0,
        missingBaseStats = 0,
    }

    -- Iterate every species BPBID knows about
    for speciesID, bpbidBreeds in pairs(BPBID_Arrays.BreedsPerSpecies) do
        -- Filter to species that exist in this client
        local speciesName = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
        if speciesName and type(speciesName) == "string" then
            counts.total = counts.total + 1

            -- BPBID uses false (not nil) for species with no data
            if bpbidBreeds and bpbidBreeds ~= false and #bpbidBreeds > 0 then
                local entry = {
                    breeds = {},
                }
                for j = 1, #bpbidBreeds do
                    entry.breeds[j] = bpbidBreeds[j]
                end

                -- Base stats (for cross-validation against wago.db)
                if hasBaseStats then
                    local bpbidStats = BPBID_Arrays.BasePetStats[speciesID]
                    if bpbidStats and bpbidStats ~= false and bpbidStats[1] then
                        entry.baseStats = {
                            bpbidStats[1],
                            bpbidStats[2],
                            bpbidStats[3],
                        }
                        counts.withBaseStats = counts.withBaseStats + 1
                    else
                        counts.missingBaseStats = counts.missingBaseStats + 1
                        utils:debug(string.format("harvestBreeds: speciesID %d (%s) has no base stats",
                            speciesID, speciesName))
                    end
                end

                -- String key prevents WoW's SV serializer from nil-padding sparse numeric keys
                speciesData[tostring(speciesID)] = entry
            else
                counts.missingBreeds = counts.missingBreeds + 1
                utils:debug(string.format("harvestBreeds: speciesID %d (%s) has no breed data",
                    speciesID, speciesName))
            end
        end
    end

    -- Store to SavedVariable
    pao_tools = pao_tools or {}
    pao_tools.breedHarvest = {
        meta = {
            harvestDate = date("%Y-%m-%d %H:%M:%S"),
            bpbidVersion = BPBID_Arrays.CurrentVersion or "unknown",
            speciesCount = counts.total,
            withBaseStats = counts.withBaseStats,
            skippedNoBreeds = counts.missingBreeds,
            missingBaseStats = counts.missingBaseStats,
        },
        species = speciesData,
    }

    -- Report
    local stored = counts.total - counts.missingBreeds
    utils:notify("Breed harvest complete:")
    utils:notify(string.format("  MoP species: %d, stored: %d, missing breeds: %d",
        counts.total, stored, counts.missingBreeds))
    if hasBaseStats then
        utils:notify(string.format("  With base stats: %d, missing: %d", counts.withBaseStats, counts.missingBaseStats))
    end
    utils:notify("Saved to pao_tools.breedHarvest.")
end

--[[
  Show status of last breed harvest.
]]
function harvestBreeds:showStatus()
    local utils = Addon.utils

    pao_tools = pao_tools or {}
    local harvest = pao_tools.breedHarvest

    if not harvest or not harvest.meta then
        utils:notify("No breed harvest data found. Run: /pao harvest breeds")
        return
    end

    local meta = harvest.meta
    utils:notify("Breed Harvest Status:")
    utils:notify(string.format("  Date: %s", meta.harvestDate or "unknown"))
    utils:notify(string.format("  BPBID version: %s", meta.bpbidVersion or "unknown"))
    utils:notify(string.format("  MoP species: %d, stored: %d, missing breeds: %d",
        meta.speciesCount or 0,
        (meta.speciesCount or 0) - (meta.skippedNoBreeds or 0),
        meta.skippedNoBreeds or 0))
    if meta.withBaseStats then
        utils:notify(string.format("  Base stats: %d with data, %d missing",
            meta.withBaseStats, meta.missingBaseStats or 0))
    end
end

--[[
  Start the breed harvest.
]]
function harvestBreeds:run()
    runHarvest()
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("harvestBreeds", {"utils"}, function()
        return true
    end)
end

Addon.harvestBreeds = harvestBreeds
return harvestBreeds