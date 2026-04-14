local addonName, ns = ...

--- Dungeon reputation data. Keyed by a dungeon identifier.
--- factionID, nameDisplay, zone, repPerRunNormal (approximate),
--- repPerRunHeroic (approximate), standingCapNormal, standingCapHeroic.
--- A nil standingCap means Exalted.

ns.dataDungeons = {
    -- Coilfang Reservoir (Cenarion Expedition)
    slavePens = {
        factionID = ns.FACTION_CENARION_EXPEDITION,
        nameDisplay = "The Slave Pens",
        zone = "Zangarmarsh",
        repPerRunNormal = 900,
        repPerRunHeroic = 1750,
        standingCapNormal = ns.STANDING_HONORED,
        standingCapHeroic = nil,
    },
    underbog = {
        factionID = ns.FACTION_CENARION_EXPEDITION,
        nameDisplay = "The Underbog",
        zone = "Zangarmarsh",
        repPerRunNormal = 1000,
        repPerRunHeroic = 1750,
        standingCapNormal = ns.STANDING_HONORED,
        standingCapHeroic = nil,
        notes = "Hungarfen and giants give rep past Honored on normal",
    },
    steamvault = {
        factionID = ns.FACTION_CENARION_EXPEDITION,
        nameDisplay = "The Steamvault",
        zone = "Zangarmarsh",
        repPerRunNormal = 1662,
        repPerRunHeroic = 2750,
        standingCapNormal = nil,
        standingCapHeroic = nil,
        notes = "Best normal dungeon for CE rep. Also drops Coilfang Armaments",
    },

    -- Tempest Keep (Sha'tar)
    mechanar = {
        factionID = ns.FACTION_SHATAR,
        nameDisplay = "The Mechanar",
        zone = "Netherstorm",
        repPerRunNormal = 1200,
        repPerRunHeroic = 2000,
        standingCapNormal = nil,
        standingCapHeroic = nil,
        notes = "Blood Elf mobs also drop Sunfury Signets and Arcane Tomes (Scryers)",
    },
    botanica = {
        factionID = ns.FACTION_SHATAR,
        nameDisplay = "The Botanica",
        zone = "Netherstorm",
        repPerRunNormal = 1300,
        repPerRunHeroic = 2100,
        standingCapNormal = nil,
        standingCapHeroic = nil,
        notes = "Blood Elf mobs also drop Sunfury Signets and Arcane Tomes (Scryers)",
    },
    arcatraz = {
        factionID = ns.FACTION_SHATAR,
        nameDisplay = "The Arcatraz",
        zone = "Netherstorm",
        repPerRunNormal = 1300,
        repPerRunHeroic = 2100,
        standingCapNormal = nil,
        standingCapHeroic = nil,
        notes = "Requires Key to the Arcatraz or party member with key",
    },

    -- Auchindoun (Consortium via Mana-Tombs)
    manaTombs = {
        factionID = ns.FACTION_CONSORTIUM,
        nameDisplay = "Mana-Tombs",
        zone = "Terokkar Forest",
        repPerRunNormal = 1200,
        repPerRunHeroic = 1800,
        standingCapNormal = ns.STANDING_HONORED,
        standingCapHeroic = nil,
    },
}

--- Returns all dungeons that grant rep for a given faction.
--- @param factionID number
--- @return table dungeonsMatched
function ns.dungeonsForFaction(factionID)
    local dungeonsMatched = {}
    for key, data in pairs(ns.dataDungeons) do
        if data.factionID == factionID then
            data.key = key
            table.insert(dungeonsMatched, data)
        end
    end
    return dungeonsMatched
end

--- Estimates dungeon runs needed to close a rep gap.
--- Picks the best available dungeon (highest rep per run that isn't capped).
--- @param factionID number
--- @param repNeeded number
--- @param standingCurrent number
--- @param useHeroic boolean
--- @return string dungeonName, number runsRequired, number repPerRun
function ns.dungeonRunsEstimate(factionID, repNeeded, standingCurrent, useHeroic)
    if repNeeded <= 0 then return "none", 0, 0 end

    local dungeons = ns.dungeonsForFaction(factionID)
    local dungeonBest = nil
    local repBest = 0

    for _, dungeon in ipairs(dungeons) do
        local repPerRun = useHeroic and dungeon.repPerRunHeroic or dungeon.repPerRunNormal
        local cap = useHeroic and dungeon.standingCapHeroic or dungeon.standingCapNormal

        -- Skip if current standing is at or above this dungeon's cap
        if cap and standingCurrent >= cap then
            repPerRun = 0
        end

        if repPerRun > repBest then
            repBest = repPerRun
            dungeonBest = dungeon
        end
    end

    if not dungeonBest or repBest == 0 then
        return "none available", 0, 0
    end

    local runsRequired = math.ceil(repNeeded / repBest)
    return dungeonBest.nameDisplay, runsRequired, repBest
end
