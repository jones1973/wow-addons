--[[
    Zone Data for Pet Battle Features

    Data Sources:
    - Pet battle levels: https://www.warcraftpets.com/wow-pets/zone/ (filter by continent, "Wild Pets" checked)
    - Player levels + faction: https://www.wowhead.com/mop-classic/zones
    - UiMapIDs: https://wowpedia.fandom.com/wiki/UiMapID (UiMap.db2)

    Last updated: 2026-02-19

    Structure:
    - Key: UiMapID (integer, from C_Map.GetBestMapForUnit / C_Map.GetMapInfo)
    - name: English zone name (matches C_Map.GetMapInfo(mapID).name)
    - continent: Continent UiMapID (see CONTINENT constants)
    - faction: "Alliance" | "Horde" | "Contested" | "Sanctuary"
    - levelRange: {min, max} player levels, nil if not applicable
    - petLevelRange: {min, max} wild pet levels, nil if no wild pets
    - partOf: UiMapID of parent zone (cities only, for pet battle grouping)
]]

local _, Addon = ...

Addon.data = Addon.data or {}

-- Continent UiMapIDs (from C_Map hierarchy)
local CONTINENT = {
    EASTERN_KINGDOMS = 13,
    KALIMDOR         = 12,
    OUTLAND          = 1467,
    NORTHREND        = 113,
    THE_MAELSTROM    = 948,
    PANDARIA         = 424,
}

Addon.data.CONTINENT = CONTINENT

-- Continent display order and names for UI
Addon.data.continentOrder = {
    CONTINENT.EASTERN_KINGDOMS,
    CONTINENT.KALIMDOR,
    CONTINENT.OUTLAND,
    CONTINENT.NORTHREND,
    CONTINENT.THE_MAELSTROM,
    CONTINENT.PANDARIA,
}

Addon.data.continentNames = {
    [CONTINENT.EASTERN_KINGDOMS] = "Eastern Kingdoms",
    [CONTINENT.KALIMDOR]         = "Kalimdor",
    [CONTINENT.OUTLAND]          = "Outland",
    [CONTINENT.NORTHREND]        = "Northrend",
    [CONTINENT.THE_MAELSTROM]    = "The Maelstrom",
    [CONTINENT.PANDARIA]         = "Pandaria",
}

local EK  = CONTINENT.EASTERN_KINGDOMS
local KAL = CONTINENT.KALIMDOR
local OUT = CONTINENT.OUTLAND
local NR  = CONTINENT.NORTHREND
local MAE = CONTINENT.THE_MAELSTROM
local PAN = CONTINENT.PANDARIA

Addon.data.zones = {
    ---------------------------------------------------------------------------
    -- EASTERN KINGDOMS
    ---------------------------------------------------------------------------

    -- Capitals
    [84] = {
        name = "Stormwind City", continent = EK,
        faction = "Alliance",
        levelRange = {1, 90}, petLevelRange = {1, 1},
        partOf = 37,
    },
    [87] = {
        name = "Ironforge", continent = EK,
        faction = "Alliance",
        levelRange = {1, 90}, petLevelRange = {1, 3},
        partOf = 27,
    },
    [90] = {
        name = "Undercity", continent = EK,
        faction = "Horde",
        levelRange = {1, 90}, petLevelRange = {1, 2},
        partOf = 18,
    },
    [110] = {
        name = "Silvermoon City", continent = EK,
        faction = "Horde",
        levelRange = {1, 90}, petLevelRange = {1, 3},
        partOf = 94,
    },
    [202] = {
        name = "Gilneas City", continent = EK,
        faction = "Alliance",
        levelRange = nil, petLevelRange = {1, 2},
        partOf = 217,
    },

    -- Starting Zones
    [37] = {
        name = "Elwynn Forest", continent = EK,
        faction = "Alliance",
        levelRange = {1, 10}, petLevelRange = {1, 2},
    },
    [27] = {
        name = "Dun Morogh", continent = EK,
        faction = "Alliance",
        levelRange = {1, 10}, petLevelRange = {1, 2},
    },
    [18] = {
        name = "Tirisfal Glades", continent = EK,
        faction = "Horde",
        levelRange = {1, 10}, petLevelRange = {1, 2},
    },
    [94] = {
        name = "Eversong Woods", continent = EK,
        faction = "Horde",
        levelRange = {1, 10}, petLevelRange = {1, 2},
    },
    [217] = {
        name = "Ruins of Gilneas", continent = EK,
        faction = "Contested",
        levelRange = {1, 20}, petLevelRange = {1, 1},
    },

    -- Level 10-20 Zones
    [52] = {
        name = "Westfall", continent = EK,
        faction = "Alliance",
        levelRange = {10, 15}, petLevelRange = {3, 4},
    },
    [48] = {
        name = "Loch Modan", continent = EK,
        faction = "Alliance",
        levelRange = {10, 20}, petLevelRange = {3, 6},
    },
    [21] = {
        name = "Silverpine Forest", continent = EK,
        faction = "Horde",
        levelRange = {10, 20}, petLevelRange = {3, 6},
    },
    [95] = {
        name = "Ghostlands", continent = EK,
        faction = "Horde",
        levelRange = {10, 20}, petLevelRange = {3, 6},
    },
    [49] = {
        name = "Redridge Mountains", continent = EK,
        faction = "Contested",
        levelRange = {15, 20}, petLevelRange = {4, 6},
    },

    -- Level 20-30 Zones
    [47] = {
        name = "Duskwood", continent = EK,
        faction = "Contested",
        levelRange = {20, 25}, petLevelRange = {5, 7},
    },
    [56] = {
        name = "Wetlands", continent = EK,
        faction = "Contested",
        levelRange = {20, 25}, petLevelRange = {6, 7},
    },
    [25] = {
        name = "Hillsbrad Foothills", continent = EK,
        faction = "Contested",
        levelRange = {20, 25}, petLevelRange = {6, 7},
    },
    [14] = {
        name = "Arathi Highlands", continent = EK,
        faction = "Contested",
        levelRange = {25, 30}, petLevelRange = {7, 8},
    },
    [50] = {
        name = "Northern Stranglethorn", continent = EK,
        faction = "Contested",
        levelRange = {25, 30}, petLevelRange = {7, 9},
    },

    -- Level 30-40 Zones
    [210] = {
        name = "The Cape of Stranglethorn", continent = EK,
        faction = "Contested",
        levelRange = {30, 35}, petLevelRange = {9, 10},
    },
    [26] = {
        name = "The Hinterlands", continent = EK,
        faction = "Contested",
        levelRange = {30, 35}, petLevelRange = {11, 12},
    },
    [22] = {
        name = "Western Plaguelands", continent = EK,
        faction = "Contested",
        levelRange = {35, 40}, petLevelRange = {10, 11},
    },
    [23] = {
        name = "Eastern Plaguelands", continent = EK,
        faction = "Contested",
        levelRange = {40, 45}, petLevelRange = {12, 13},
    },

    -- Level 40-55 Zones
    [15] = {
        name = "Badlands", continent = EK,
        faction = "Contested",
        levelRange = {45, 48}, petLevelRange = {13, 14},
    },
    [32] = {
        name = "Searing Gorge", continent = EK,
        faction = "Contested",
        levelRange = {47, 51}, petLevelRange = {13, 14},
    },
    [36] = {
        name = "Burning Steppes", continent = EK,
        faction = "Contested",
        levelRange = {50, 52}, petLevelRange = {15, 16},
    },
    [51] = {
        name = "Swamp of Sorrows", continent = EK,
        faction = "Contested",
        levelRange = {52, 54}, petLevelRange = {14, 15},
    },

    -- Level 55-60 Zones
    [17] = {
        name = "Blasted Lands", continent = EK,
        faction = "Contested",
        levelRange = {55, 60}, petLevelRange = {16, 17},
    },
    [42] = {
        name = "Deadwind Pass", continent = EK,
        faction = "Contested",
        levelRange = {55, 56}, petLevelRange = {17, 18},
    },

    -- TBC Zone
    [122] = {
        name = "Isle of Quel'Danas", continent = EK,
        faction = "Contested",
        levelRange = {70, 70}, petLevelRange = {20, 20},
    },

    -- Cataclysm Zone
    [241] = {
        name = "Twilight Highlands", continent = EK,
        faction = "Contested",
        levelRange = {84, 85}, petLevelRange = {23, 24},
    },

    ---------------------------------------------------------------------------
    -- KALIMDOR
    ---------------------------------------------------------------------------

    -- Capitals
    [85] = {
        name = "Orgrimmar", continent = KAL,
        faction = "Horde",
        levelRange = {1, 90}, petLevelRange = {1, 1},
        partOf = 1,
    },
    [88] = {
        name = "Thunder Bluff", continent = KAL,
        faction = "Horde",
        levelRange = {1, 90}, petLevelRange = {1, 3},
        partOf = 7,
    },
    [89] = {
        name = "Darnassus", continent = KAL,
        faction = "Alliance",
        levelRange = {1, 90}, petLevelRange = {1, 3},
        partOf = 57,
    },
    [103] = {
        name = "The Exodar", continent = KAL,
        faction = "Alliance",
        levelRange = {1, 90}, petLevelRange = {1, 3},
        partOf = 97,
    },

    -- Starting Zones
    [1] = {
        name = "Durotar", continent = KAL,
        faction = "Horde",
        levelRange = {1, 10}, petLevelRange = {1, 2},
    },
    [7] = {
        name = "Mulgore", continent = KAL,
        faction = "Horde",
        levelRange = {1, 10}, petLevelRange = {1, 2},
    },
    [57] = {
        name = "Teldrassil", continent = KAL,
        faction = "Alliance",
        levelRange = {1, 10}, petLevelRange = {1, 2},
    },
    [97] = {
        name = "Azuremyst Isle", continent = KAL,
        faction = "Alliance",
        levelRange = {1, 10}, petLevelRange = {1, 2},
    },

    -- Level 10-20 Zones
    [62] = {
        name = "Darkshore", continent = KAL,
        faction = "Alliance",
        levelRange = {10, 20}, petLevelRange = {3, 6},
    },
    [106] = {
        name = "Bloodmyst Isle", continent = KAL,
        faction = "Alliance",
        levelRange = {10, 20}, petLevelRange = {3, 6},
    },
    [10] = {
        name = "Northern Barrens", continent = KAL,
        faction = "Horde",
        levelRange = {10, 20}, petLevelRange = {3, 4},
    },
    [76] = {
        name = "Azshara", continent = KAL,
        faction = "Horde",
        levelRange = {10, 20}, petLevelRange = {3, 6},
    },

    -- Level 20-35 Zones
    [63] = {
        name = "Ashenvale", continent = KAL,
        faction = "Contested",
        levelRange = {20, 25}, petLevelRange = {4, 6},
    },
    [65] = {
        name = "Stonetalon Mountains", continent = KAL,
        faction = "Contested",
        levelRange = {25, 30}, petLevelRange = {5, 7},
    },
    [199] = {
        name = "Southern Barrens", continent = KAL,
        faction = "Contested",
        levelRange = {30, 35}, petLevelRange = {9, 10},
    },
    [66] = {
        name = "Desolace", continent = KAL,
        faction = "Contested",
        levelRange = {30, 35}, petLevelRange = {7, 9},
    },

    -- Level 35-45 Zones
    [69] = {
        name = "Feralas", continent = KAL,
        faction = "Contested",
        levelRange = {35, 40}, petLevelRange = {11, 12},
    },
    [70] = {
        name = "Dustwallow Marsh", continent = KAL,
        faction = "Contested",
        levelRange = {35, 40}, petLevelRange = {12, 13},
    },
    [64] = {
        name = "Thousand Needles", continent = KAL,
        faction = "Contested",
        levelRange = {40, 45}, petLevelRange = {13, 14},
    },

    -- Level 45-60 Zones
    [77] = {
        name = "Felwood", continent = KAL,
        faction = "Contested",
        levelRange = {45, 50}, petLevelRange = {14, 15},
    },
    [71] = {
        name = "Tanaris", continent = KAL,
        faction = "Contested",
        levelRange = {45, 50}, petLevelRange = {13, 14},
    },
    [78] = {
        name = "Un'Goro Crater", continent = KAL,
        faction = "Contested",
        levelRange = {50, 55}, petLevelRange = {15, 16},
    },
    [83] = {
        name = "Winterspring", continent = KAL,
        faction = "Contested",
        levelRange = {50, 55}, petLevelRange = {17, 18},
    },
    [81] = {
        name = "Silithus", continent = KAL,
        faction = "Contested",
        levelRange = {55, 60}, petLevelRange = {16, 17},
    },

    -- Special Zones
    [80] = {
        name = "Moonglade", continent = KAL,
        faction = "Contested",
        levelRange = {15, 15}, petLevelRange = {15, 16},
    },
    [327] = {
        name = "Ahn'Qiraj: The Fallen Kingdom", continent = KAL,
        faction = "Contested",
        levelRange = nil, petLevelRange = {16, 17},
    },

    -- Cataclysm Zones
    [198] = {
        name = "Mount Hyjal", continent = KAL,
        faction = "Contested",
        levelRange = {80, 82}, petLevelRange = {22, 24},
    },
    [249] = {
        name = "Uldum", continent = KAL,
        faction = "Contested",
        levelRange = {83, 84}, petLevelRange = {23, 24},
    },
    [338] = {
        name = "Molten Front", continent = KAL,
        faction = "Contested",
        levelRange = {85, 85}, petLevelRange = {24, 24},
    },

    ---------------------------------------------------------------------------
    -- OUTLAND
    ---------------------------------------------------------------------------

    [111] = {
        name = "Shattrath City", continent = OUT,
        faction = "Sanctuary",
        levelRange = {1, 90}, petLevelRange = {18, 19},
        partOf = 108,
    },
    [100] = {
        name = "Hellfire Peninsula", continent = OUT,
        faction = "Contested",
        levelRange = {58, 63}, petLevelRange = {17, 18},
    },
    [102] = {
        name = "Zangarmarsh", continent = OUT,
        faction = "Contested",
        levelRange = {60, 64}, petLevelRange = {18, 19},
    },
    [108] = {
        name = "Terokkar Forest", continent = OUT,
        faction = "Contested",
        levelRange = {62, 65}, petLevelRange = {18, 19},
    },
    [107] = {
        name = "Nagrand", continent = OUT,
        faction = "Contested",
        levelRange = {64, 67}, petLevelRange = {18, 19},
    },
    [105] = {
        name = "Blade's Edge Mountains", continent = OUT,
        faction = "Contested",
        levelRange = {65, 68}, petLevelRange = {18, 20},
    },
    [109] = {
        name = "Netherstorm", continent = OUT,
        faction = "Contested",
        levelRange = {67, 70}, petLevelRange = {20, 21},
    },
    [104] = {
        name = "Shadowmoon Valley", continent = OUT,
        faction = "Contested",
        levelRange = {67, 70}, petLevelRange = {20, 21},
    },

    ---------------------------------------------------------------------------
    -- NORTHREND
    ---------------------------------------------------------------------------

    [125] = {
        name = "Dalaran", continent = NR,
        faction = "Sanctuary",
        levelRange = {1, 90}, petLevelRange = {21, 21},
    },
    [114] = {
        name = "Borean Tundra", continent = NR,
        faction = "Contested",
        levelRange = {68, 72}, petLevelRange = {20, 22},
    },
    [117] = {
        name = "Howling Fjord", continent = NR,
        faction = "Contested",
        levelRange = {68, 72}, petLevelRange = {20, 22},
    },
    [115] = {
        name = "Dragonblight", continent = NR,
        faction = "Contested",
        levelRange = {71, 75}, petLevelRange = {22, 23},
    },
    [116] = {
        name = "Grizzly Hills", continent = NR,
        faction = "Contested",
        levelRange = {73, 75}, petLevelRange = {21, 22},
    },
    [121] = {
        name = "Zul'Drak", continent = NR,
        faction = "Contested",
        levelRange = {74, 76}, petLevelRange = {22, 23},
    },
    [119] = {
        name = "Sholazar Basin", continent = NR,
        faction = "Contested",
        levelRange = {76, 78}, petLevelRange = {21, 22},
    },
    [120] = {
        name = "The Storm Peaks", continent = NR,
        faction = "Contested",
        levelRange = {77, 80}, petLevelRange = {22, 23},
    },
    [118] = {
        name = "Icecrown", continent = NR,
        faction = "Contested",
        levelRange = {77, 80}, petLevelRange = {22, 23},
    },
    [127] = {
        name = "Crystalsong Forest", continent = NR,
        faction = "Contested",
        levelRange = {77, 80}, petLevelRange = {22, 23},
    },

    ---------------------------------------------------------------------------
    -- THE MAELSTROM
    ---------------------------------------------------------------------------

    [407] = {
        name = "Darkmoon Island", continent = MAE,
        faction = "Contested",
        levelRange = nil, petLevelRange = {1, 10},
    },
    [207] = {
        name = "Deepholm", continent = MAE,
        faction = "Contested",
        levelRange = {82, 83}, petLevelRange = {22, 23},
    },
    [245] = {
        name = "Tol Barad Peninsula", continent = MAE,
        faction = "Contested",
        levelRange = {85, 85}, petLevelRange = {23, 24},
    },
    [244] = {
        name = "Tol Barad", continent = MAE,
        faction = "Contested",
        levelRange = {84, 85}, petLevelRange = {23, 24},
    },

    ---------------------------------------------------------------------------
    -- PANDARIA
    ---------------------------------------------------------------------------

    [371] = {
        name = "The Jade Forest", continent = PAN,
        faction = "Contested",
        levelRange = {85, 86}, petLevelRange = {23, 25},
    },
    [376] = {
        name = "Valley of the Four Winds", continent = PAN,
        faction = "Contested",
        levelRange = {86, 87}, petLevelRange = {23, 25},
    },
    [418] = {
        name = "Krasarang Wilds", continent = PAN,
        faction = "Contested",
        levelRange = {86, 87}, petLevelRange = {23, 25},
    },
    [379] = {
        name = "Kun-Lai Summit", continent = PAN,
        faction = "Contested",
        levelRange = {87, 88}, petLevelRange = {23, 25},
    },
    [433] = {
        name = "The Veiled Stair", continent = PAN,
        faction = "Contested",
        levelRange = {87, 87}, petLevelRange = {23, 24},
    },
    [388] = {
        name = "Townlong Steppes", continent = PAN,
        faction = "Contested",
        levelRange = {88, 89}, petLevelRange = {24, 25},
    },
    [422] = {
        name = "Dread Wastes", continent = PAN,
        faction = "Contested",
        levelRange = {89, 90}, petLevelRange = {24, 25},
    },
    [390] = {
        name = "Vale of Eternal Blossoms", continent = PAN,
        faction = "Contested",
        levelRange = {90, 90}, petLevelRange = {24, 25},
    },
    [504] = {
        name = "Isle of Thunder", continent = PAN,
        faction = "Contested",
        levelRange = {85, 90}, petLevelRange = {25, 25},
    },
    [507] = {
        name = "Isle of Giants", continent = PAN,
        faction = "Contested",
        levelRange = {85, 90}, petLevelRange = {25, 25},
    },
    [554] = {
        name = "Timeless Isle", continent = PAN,
        faction = "Contested",
        levelRange = {85, 90}, petLevelRange = {25, 25},
    },
}

-- Reverse index: zone name → mapID (built once at load)
local nameIndex = {}
for mapID, zone in pairs(Addon.data.zones) do
    nameIndex[zone.name] = mapID
end
Addon.data.zoneNameIndex = nameIndex

-- Utility: Get zone data by mapID
function Addon.data:getZone(mapID)
    return self.zones[mapID]
end

-- Utility: Get zone data by name (backward compat)
function Addon.data:getZoneByName(zoneName)
    local mapID = self.zoneNameIndex[zoneName]
    return mapID and self.zones[mapID] or nil
end

-- Utility: Get mapID from zone name
function Addon.data:getMapIDByName(zoneName)
    return self.zoneNameIndex[zoneName]
end

-- Utility: Get continent ID for a mapID
function Addon.data:getContinentID(mapID)
    local zone = self.zones[mapID]
    return zone and zone.continent
end

-- Utility: Get continent display name
function Addon.data:getContinentName(continentID)
    return self.continentNames[continentID]
end

-- Utility: Get pet level range for a zone
function Addon.data:getPetLevelRange(mapID)
    local zone = self.zones[mapID]
    return zone and zone.petLevelRange
end

-- Utility: Get all zones for a continent
function Addon.data:getZonesByContinent(continentID)
    local result = {}
    for mapID, zone in pairs(self.zones) do
        if zone.continent == continentID then
            result[mapID] = zone
        end
    end
    return result
end

-- Utility: Get all zones with wild pets in a level range
function Addon.data:getZonesByPetLevel(minLevel, maxLevel)
    local result = {}
    for mapID, zone in pairs(self.zones) do
        if zone.petLevelRange then
            local zoneMin, zoneMax = zone.petLevelRange[1], zone.petLevelRange[2]
            if zoneMin <= maxLevel and zoneMax >= minLevel then
                result[mapID] = zone
            end
        end
    end
    return result
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("data.zones", {}, function()
        return true  -- Data is ready immediately
    end)
end