local addonName, ns = ...

--- Repeatable turn-in data. Keyed by faction ID.
--- Each entry: itemID, nameDisplay, quantityRequired, repPerTurnIn,
--- standingMin (lowest standing it works at), standingMax (highest standing it works at),
--- isTradeable (can be bought on AH).

ns.dataTurnIns = {
    [ns.FACTION_SCRYERS] = {
        {
            itemID = 29425,
            nameDisplay = "Firewing Signet",
            quantityRequired = 10,
            repPerTurnIn = 250,
            standingMin = ns.STANDING_FRIENDLY,
            standingMax = ns.STANDING_HONORED,
            isTradeable = true,
            notes = "Drops from lower-level Blood Elves (Firewing Point, etc.)",
        },
        {
            itemID = 29426,
            nameDisplay = "Sunfury Signet",
            quantityRequired = 10,
            repPerTurnIn = 250,
            standingMin = ns.STANDING_HONORED,
            standingMax = ns.STANDING_EXALTED,
            isTradeable = true,
            notes = "Drops from higher-level Blood Elves (Netherstorm, SMV, Tempest Keep)",
        },
        {
            itemID = 28452,
            nameDisplay = "Arcane Tome",
            quantityRequired = 1,
            repPerTurnIn = 350,
            standingMin = ns.STANDING_FRIENDLY,
            standingMax = ns.STANDING_EXALTED,
            isTradeable = true,
            notes = "Rare drop from Blood Elves. Also grants 1 Arcane Rune (for inscriptions)",
        },
    },

    [ns.FACTION_CENARION_EXPEDITION] = {
        {
            itemID = 24401,
            nameDisplay = "Unidentified Plant Parts",
            quantityRequired = 10,
            repPerTurnIn = 250,
            standingMin = ns.STANDING_NEUTRAL,
            standingMax = ns.STANDING_HONORED,
            isTradeable = true,
            notes = "Zangarmarsh mobs and herb nodes. Turn in to Lauranna Thar'well",
        },
        {
            itemID = 24245,
            nameDisplay = "Uncatalogued Species",
            quantityRequired = 1,
            repPerTurnIn = 500,
            standingMin = ns.STANDING_NEUTRAL,
            standingMax = ns.STANDING_EXALTED,
            isTradeable = false,
            notes = "Chance from Plant Parts turn-in reward bag. SAVE these past Honored",
        },
        {
            itemID = 24368,
            nameDisplay = "Coilfang Armaments",
            quantityRequired = 1,
            repPerTurnIn = 75,
            standingMin = ns.STANDING_FRIENDLY,
            standingMax = ns.STANDING_EXALTED,
            isTradeable = true,
            notes = "Drops from Steamvault trash. First turn-in is 250 rep (Orders from Lady Vashj). Turn in to Ysiel Windsinger",
        },
    },

    [ns.FACTION_CONSORTIUM] = {
        {
            itemID = 25433,
            nameDisplay = "Obsidian Warbeads",
            quantityRequired = 10,
            repPerTurnIn = 250,
            standingMin = ns.STANDING_FRIENDLY,
            standingMax = ns.STANDING_EXALTED,
            isTradeable = true,
            notes = "Drop from Nagrand ogres. Turn in at Aeris Landing",
        },
        {
            itemID = 29209,
            nameDisplay = "Zaxxis Insignia",
            quantityRequired = 10,
            repPerTurnIn = 250,
            standingMin = ns.STANDING_FRIENDLY,
            standingMax = ns.STANDING_EXALTED,
            isTradeable = false,
            notes = "Drop from Zaxxis Ethereals south of Area 52. Requires Consortium Crystal Collection first",
        },
        {
            itemID = 25416,
            nameDisplay = "Oshu'gun Crystal Fragment",
            quantityRequired = 10,
            repPerTurnIn = 250,
            standingMin = ns.STANDING_NEUTRAL,
            standingMax = ns.STANDING_FRIENDLY,
            isTradeable = false,
            notes = "Found near Oshu'gun in Nagrand. Only works to Friendly",
        },
        {
            itemID = 25463,
            nameDisplay = "Pair of Ivory Tusks",
            quantityRequired = 3,
            repPerTurnIn = 250,
            standingMin = ns.STANDING_NEUTRAL,
            standingMax = ns.STANDING_FRIENDLY,
            isTradeable = false,
            notes = "Drop from Nagrand elekk. Only works to Friendly",
        },
    },

    -- Sha'tar has no direct repeatable turn-ins.
    -- Rep comes from Scryer/Aldor spillover (to Friendly 5999) and Tempest Keep dungeon runs.
}

--- Calculates how many turn-ins of a specific item are needed to close a rep gap.
--- @param turnInData table -- single entry from dataTurnIns
--- @param repNeeded number
--- @return number turnInsRequired, number itemsRequired
function ns.turnInsCalculate(turnInData, repNeeded)
    if repNeeded <= 0 then return 0, 0 end
    local turnInsRequired = math.ceil(repNeeded / turnInData.repPerTurnIn)
    local itemsRequired = turnInsRequired * turnInData.quantityRequired
    return turnInsRequired, itemsRequired
end
