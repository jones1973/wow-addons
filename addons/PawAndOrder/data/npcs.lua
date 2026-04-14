-- data/npcs.lua
-- Unified NPC database with bit-flag type system
-- All battle-related NPC types (trainers, tamers, spirits, fabled, vendors, stable masters) in one table
-- SV: pao_npc | Static: Addon.data.npcs
--
-- Schema:
--   locations = { { mapID, continent, x, y, subzone }, ... }
--     - mapID: Zone map ID (required)
--     - continent: Continent map ID (required for routing)
--     - x, y: Coordinates 0-100 scale (omit for roaming NPCs)
--     - subzone: Subzone text for flavor (optional)
--   types: NPC_TYPE bit flags (required)
--   faction: Root-level, only if NPC serves single faction (nil = neutral)
--   name: NPC name (required)
--
-- Generated from Questie data via /pao questie harvest
-- Manual additions: Speaker Gulan (73307) - not in Questie item DB
-- Pet team data preserved from SV captures

local _, Addon = ...

-- NPC type bit flags (combinable with +)
local NPC_TYPE = {
    TRAINER       = 0x01,  -- Battle pet trainer (teaches pet battles)
    TAMER         = 0x02,  -- Master pet tamer (daily battle, has team)
    SPIRIT        = 0x04,  -- Pandaren spirit tamer (daily battle, special team)
    FABLED        = 0x08,  -- Fabled beast (single-pet daily battle)
    VENDOR        = 0x10,  -- Pet vendor (sells battle pets or supplies)
    STABLE_MASTER = 0x20,  -- Stable master (pet healing/recovery)
}

-- NPC faction constants (nil = neutral/any faction)
local FACTION = {
    ALLIANCE = 1,
    HORDE    = 2,
}

-- Export to addon namespace for cross-module access
Addon.NPC_TYPE = NPC_TYPE
Addon.FACTION = FACTION

-- Static NPC database - baseline data, supplemented by SV discoveries
local NPC_DB = {

    [543] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 77, continent = 12, x = 61.61, y = 25.43 },
        },
        name = "Nalesette Wildbringer",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [1263] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 27, continent = 13, x = 70.66, y = 49.27 },
        },
        name = "Yarlyn Amberstill",
        types = NPC_TYPE.VENDOR,
    },
    [2663] = {
        locations = {
            { mapID = 210, continent = 13, x = 42.62, y = 69.1 },
        },
        name = "Narkk",
        types = NPC_TYPE.VENDOR,
    },
    [6367] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 37, continent = 13, x = 44.21, y = 53.42 },
        },
        name = "Donni Anthania",
        types = NPC_TYPE.VENDOR,
    },
    [6749] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 37, continent = 13, x = 42.84, y = 65.94 },
        },
        name = "Erma",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [8401] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 88, continent = 12, x = 61.96, y = 58.36 },
        },
        name = "Halpa",
        types = NPC_TYPE.VENDOR,
    },
    [8403] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 998, continent = 424, x = 67.58, y = 44.16 },
        },
        name = "Jeremiah Payson",
        questEnds = { 5049 },
        types = NPC_TYPE.VENDOR,
    },
    [8404] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 85, continent = 12, x = 33.55, y = 67.82 },
        },
        name = "Xan'tish",
        types = NPC_TYPE.VENDOR,
    },
    [8665] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 89, continent = 12, x = 64.03, y = 53.57 },
        },
        name = "Shylenai",
        types = NPC_TYPE.VENDOR,
    },
    [8666] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 84, continent = 13, x = 61.22, y = 44.77 },
        },
        name = "Lil Timmy",
        types = NPC_TYPE.VENDOR,
    },
    [9976] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 14, continent = 13, x = 69.05, y = 33.91 },
        },
        name = "Tharlidun",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [9979] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 21, continent = 13, x = 46.04, y = 42.54 },
        },
        name = "Sarah Goode",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [9980] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 27, continent = 13, x = 54.11, y = 50.98 },
        },
        name = "Shelby Stoneflint",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [9981] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 10, continent = 12, x = 49.12, y = 57.46 },
        },
        name = "Sikwa",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [9982] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 49, continent = 13, x = 26.21, y = 42.89 },
        },
        name = "Penny",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [9984] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 87, continent = 13, x = 69.29, y = 83.57 },
        },
        name = "Ulbrek Firehand",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [9985] = {
        locations = {
            { mapID = 71, continent = 12, x = 52.69, y = 27.31 },
        },
        name = "Laziphus",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [9986] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 69, continent = 12, x = 74.47, y = 43.25 },
        },
        name = "Shyrka Wolfrunner",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [9987] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 1, continent = 12, x = 51.98, y = 41.83 },
        },
        name = "Shoja'my",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [9988] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 85, continent = 12, x = 32.4, y = 64.74 },
        },
        name = "Xon'cha",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [9989] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 48, continent = 13, x = 34.62, y = 48.07 },
        },
        name = "Lina Hearthstove",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10045] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 52, continent = 13, x = 52.93, y = 53.06 },
        },
        name = "Kirk Maxwell",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10046] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 56, continent = 13, x = 10.44, y = 59.63 },
        },
        name = "Bethaine Flinthammer",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10047] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 70, continent = 12, x = 65.99, y = 45.48 },
        },
        name = "Michael",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10048] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 65, continent = 12, x = 50.78, y = 63.2 },
        },
        name = "Gereck",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10049] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 51, continent = 13, x = 47.29, y = 55.5 },
        },
        name = "Hekkru",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10050] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 7, continent = 12, x = 46.94, y = 59.76 },
        },
        name = "Seikwa",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10051] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 57, continent = 12, x = 56.23, y = 52.08 },
        },
        name = "Seriadne",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10052] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 63, continent = 12, x = 36.5, y = 50.34 },
        },
        name = "Maluressian",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10053] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 998, continent = 424, x = 67.41, y = 37.58 },
        },
        name = "Anya Maulray",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10054] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 88, continent = 12, x = 45.09, y = 60.22 },
        },
        name = "Bulrug",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10055] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 18, continent = 13, x = 61.81, y = 52.18 },
        },
        name = "Morganus",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10056] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 89, continent = 12, x = 43.15, y = 28.92 },
        },
        name = "Alassin",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10057] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 25, continent = 13, x = 56.87, y = 46.99 },
        },
        name = "Theodore Mont Claire",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10058] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 15, continent = 13, x = 18.34, y = 42.44 },
        },
        name = "Greth",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10059] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 69, continent = 12, x = 46.8, y = 45.5 },
        },
        name = "Antarius",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10060] = {
        locations = {
            { mapID = 210, continent = 13, x = 41.27, y = 73.62 },
        },
        name = "Grimestack",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10061] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 26, continent = 13, x = 14.4, y = 45.21 },
        },
        name = "Killium Bouldertoe",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10062] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 47, continent = 13, x = 74.01, y = 46.09 },
        },
        name = "Steven Black",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10063] = {
        locations = {
            { mapID = 10, continent = 12, x = 67.53, y = 74.28 },
        },
        name = "Reggifuz",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [10085] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 62, continent = 12, x = 50.42, y = 19.14 },
        },
        name = "Jaelysia",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [11069] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 84, continent = 13, x = 67.26, y = 37.65 },
        },
        name = "Jenova Stoneshield",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [11104] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 66, continent = 12, x = 65.6, y = 7.82 },
        },
        name = "Shelgrayn",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [11105] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 66, continent = 12, x = 24.89, y = 68.66 },
        },
        name = "Aboda",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [11119] = {
        locations = {
            { mapID = 83, continent = 12, x = 58.73, y = 50.12 },
        },
        name = "Azzleby",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [14741] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 26, continent = 13, x = 79.14, y = 79.51 },
        },
        name = "Huntsman Markhor",
        questEnds = { 7828, 7829, 7830, 7849, 26223, 26224 },
        questStarts = { 26223, 26224, 26987 },
        types = NPC_TYPE.STABLE_MASTER,
    },
    [14828] = {
        locations = {
            { mapID = 407, continent = 12, x = 47.75, y = 64.77 },
        },
        name = "Gelvas Grimegate",
        questEnds = { 7904, 7905, 7926, 7930, 7931, 7932, 7933, 7934, 7935, 7936, 7940, 7981, 9249 },
        questStarts = { 7940 },
        types = NPC_TYPE.VENDOR,
    },
    [14846] = {
        locations = {
            { mapID = 407, continent = 12, x = 48.07, y = 69.54 },
        },
        name = "Lhara",
        types = NPC_TYPE.VENDOR,
    },
    [14860] = {
        locations = {
            { mapID = 407, continent = 12, x = 56.33, y = 63.37 },
        },
        name = "Flik",
        types = NPC_TYPE.VENDOR,
    },
    [15131] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 63, continent = 12, x = 73.25, y = 60.66 },
        },
        name = "Qeeju",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [15722] = {
        locations = {
            { mapID = 81, continent = 12, x = 53.28, y = 34.43 },
        },
        name = "Squire Leoren Mal'derath",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [15864] = {
        locations = {
            { mapID = 80, continent = 12, x = 53.64, y = 35.26 },
        },
        name = "Valadar Starsong",
        questEnds = { 8862, 8863, 8864, 8865, 8868, 8883 },
        questStarts = { 8868, 8883 },
        types = NPC_TYPE.VENDOR,
    },
    [16094] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 50, continent = 13, x = 37.95, y = 51.47 },
        },
        name = "Durik",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [16185] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 94, continent = 13, x = 47.58, y = 47.31 },
        },
        name = "Anathos",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [16586] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 100, continent = 1467, x = 54.35, y = 41 },
        },
        name = "Huntsman Torf Angerhoof",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [16656] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 110, continent = 1467, x = 82.71, y = 30.76 },
        },
        name = "Shalenn",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [16665] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 95, continent = 13, x = 48.48, y = 31.34 },
        },
        name = "Paniar",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [16764] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 103, continent = 12, x = 60.2, y = 25.16 },
        },
        name = "Arthaid",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [16824] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 100, continent = 1467, x = 54.45, y = 62.67 },
        },
        name = "Master Sergeant Lorin Thalmerok",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [16860] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 94, continent = 13, x = 44.79, y = 71.81 },
        },
        name = "Jilanne",
        types = NPC_TYPE.VENDOR,
    },
    [17485] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 97, continent = 12, x = 48.95, y = 49.83 },
        },
        name = "Esbina",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [17666] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 106, continent = 12, x = 55.01, y = 60 },
        },
        name = "Astur",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [17896] = {
        locations = {
            { mapID = 102, continent = 1467, x = 78.73, y = 64.33 },
        },
        name = "Kameel Longstride",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [18244] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 102, continent = 1467, x = 31.74, y = 49.78 },
        },
        name = "Khalan",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [18250] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 102, continent = 1467, x = 67.6, y = 49.68 },
        },
        name = "Joraal",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [18382] = {
        locations = {
            { mapID = 102, continent = 1467, x = 17.85, y = 51.12 },
        },
        name = "Mycah",
        types = NPC_TYPE.VENDOR,
    },
    [18984] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 108, continent = 1467, x = 49.29, y = 44.69 },
        },
        name = "Trag",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [19018] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 107, continent = 1467, x = 56.72, y = 40.81 },
        },
        name = "Wilda Bearmane",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [19019] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 107, continent = 1467, x = 55.79, y = 74.5 },
        },
        name = "Luftasia",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [19368] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 104, continent = 1467, x = 37.51, y = 56.04 },
        },
        name = "Crinn Pathfinder",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [19476] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 105, continent = 1467, x = 53.52, y = 53.2 },
        },
        name = "Lor",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [20980] = {
        locations = {
            { mapID = 109, continent = 1467, x = 43.5, y = 35.26 },
        },
        name = "Dealer Rashaad",
        types = NPC_TYPE.VENDOR,
    },
    [21019] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 103, continent = 12, x = 30.1, y = 33.79 },
        },
        name = "Sixx",
        types = NPC_TYPE.VENDOR,
    },
    [21336] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 104, continent = 1467, x = 29.22, y = 29.32 },
        },
        name = "Gedrah",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [21517] = {
        locations = {
            { mapID = 111, continent = 1467, x = 55.97, y = 80 },
        },
        name = "Ilthuril",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [21518] = {
        locations = {
            { mapID = 111, continent = 1467, x = 28.58, y = 47.75 },
        },
        name = "Oruhe",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [22468] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 105, continent = 1467, x = 75.5, y = 60.27 },
        },
        name = "Ogrin",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [22469] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 105, continent = 1467, x = 36.06, y = 64.5 },
        },
        name = "Fiskal Shadowsong",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [23367] = {
        locations = {
            { mapID = 108, continent = 1467, x = 64.28, y = 66.23 },
        },
        name = "Grella",
        types = NPC_TYPE.VENDOR,
    },
    [23392] = {
        locations = {
            { mapID = 105, continent = 1467, x = 27.58, y = 52.49 },
        },
        name = "Skyguard Stable Master",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [23710] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 27, continent = 13, x = 56.38, y = 37.82 },
        },
        name = "Belbi Quikswitch",
        questEnds = { 11321, 12193, 13932, 29397 },
        types = NPC_TYPE.VENDOR,
    },
    [23733] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 117, continent = 113, x = 58.7, y = 63.06 },
        },
        name = "Horatio the Stable Boy",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [24066] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 117, continent = 113, x = 60.64, y = 16.04 },
        },
        name = "Artie Grizzlehand",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [24067] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 117, continent = 113, x = 49.44, y = 11.05 },
        },
        name = "Mahana Frosthoof",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [24154] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 117, continent = 113, x = 52.03, y = 66.45 },
        },
        name = "Mary Darrow",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [24350] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 117, continent = 113, x = 79.05, y = 30.78 },
        },
        name = "Robert Clarke",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [24495] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 1, continent = 12, x = 40.32, y = 17.87 },
        },
        name = "Blix Fixwidget",
        questEnds = { 11413, 12194, 13931, 29396 },
        types = NPC_TYPE.VENDOR,
    },
    [24905] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 108, continent = 1467, x = 56.28, y = 53.84 },
        },
        name = "Leassian",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [24974] = {
        locations = {
            { mapID = 109, continent = 1467, x = 32, y = 64.79 },
        },
        name = "Liza Cutlerflix",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [25037] = {
        locations = {
            { mapID = 122, continent = 113, x = 50.29, y = 35.45 },
        },
        name = "Seraphina Bloodheart",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },

    [26044] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 114, continent = 113, x = 40.27, y = 54.99 },
        },
        name = "Durkot Wolfbrother",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [26123] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 89, continent = 12, x = 61.88, y = 48.29 },
            { mapID = 87, continent = 13, x = 64.82, y = 26.26 },
            { mapID = 103, continent = 12, x = 42.49, y = 25.97 },
            { mapID = 84, continent = 13, x = 49, y = 71.93 },
        },
        name = "Midsummer Supplier",
        types = NPC_TYPE.VENDOR,
    },
    [26124] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 110, continent = 1467, x = 70.37, y = 44.28 },
            { mapID = 88, continent = 12, x = 20.86, y = 24.16 },
            { mapID = 85, continent = 12, x = 47.36, y = 39.22 },
            { mapID = 998, continent = 424, x = 68.07, y = 11.2 },
        },
        name = "Midsummer Merchant",
        types = NPC_TYPE.VENDOR,
    },
    [26377] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 116, continent = 113, x = 59.07, y = 26.6 },
        },
        name = "Squire Percy",
        questEnds = { 12414 },
        questStarts = { 12414 },
        types = NPC_TYPE.STABLE_MASTER,
    },
    [26504] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 115, continent = 113, x = 37.07, y = 48.53 },
        },
        name = "Soar Hawkfury",
        questEnds = { 12100, 12104, 12111 },
        questStarts = { 12100, 12101, 12111 },
        types = NPC_TYPE.STABLE_MASTER,
    },
    [26597] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 114, continent = 113, x = 57.14, y = 19.05 },
        },
        name = "Toby \"Mother Goose\" Ironbolt",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [26721] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 114, continent = 113, x = 77.02, y = 37.21 },
        },
        name = "Halona Stormwhisper",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [26944] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 116, continent = 113, x = 64.99, y = 47.87 },
        },
        name = "Soulok Stormfury",
        questEnds = { 12415 },
        questStarts = { 12415 },
        types = NPC_TYPE.STABLE_MASTER,
    },
    [27010] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 114, continent = 113, x = 58.39, y = 68.51 },
        },
        name = "Celidh Aletracker",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [27040] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 115, continent = 113, x = 77.36, y = 50.95 },
        },
        name = "Zybarus of Darnassus",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [27056] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 115, continent = 113, x = 28.85, y = 55.97 },
        },
        name = "Sentinel Sweetspring",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [27065] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 114, continent = 113, x = 49.78, y = 10.44 },
        },
        name = "Breka Wolfsister",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [27068] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 116, continent = 113, x = 32.52, y = 59.49 },
        },
        name = "Matthew Ackerman",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [27150] = {
        locations = {
            { mapID = 117, continent = 113, x = 25.4, y = 59.05 },
        },
        name = "Trapper Shesh",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [27183] = {
        locations = {
            { mapID = 115, continent = 113, x = 48.39, y = 74.69 },
        },
        name = "Trapper Tikaani",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [27194] = {
        locations = {
            { mapID = 114, continent = 113, x = 78.14, y = 49.05 },
        },
        name = "Trapper Saghani",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [27385] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 114, continent = 113, x = 56.6, y = 73.06 },
        },
        name = "Ronald Anderson",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [27478] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 87, continent = 13, x = 19.29, y = 52.64 },
            { mapID = 87, continent = 13, x = 18.78, y = 53.08 },
        },
        name = "Larkin Thunderbrew",
        questEnds = { 12278, 12420 },
        types = NPC_TYPE.VENDOR,
    },
    [27489] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 1, continent = 12, x = 42.44, y = 9.49 },
            { mapID = 85, continent = 12, x = 50.34, y = 73.47 },
        },
        name = "Ray'ma",
        questEnds = { 12306, 12421 },
        types = NPC_TYPE.VENDOR,
    },
    [27948] = {
        locations = {
            { mapID = 115, continent = 113, x = 61.47, y = 53.35 },
        },
        name = "Risera",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [28047] = {
        locations = {
            { mapID = 119, continent = 113, x = 27.36, y = 59.39 },
        },
        name = "Hadrius Harlowe",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [28057] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 115, continent = 113, x = 76.8, y = 62.74 },
        },
        name = "Garmin Herzog",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [28690] = {
        locations = {
            { mapID = 125, continent = 113, x = 59.61, y = 37.41 },
        },
        name = "Tassia Whisperglen",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [28790] = {
        locations = {
            { mapID = 121, continent = 113, x = 40.27, y = 65.28 },
        },
        name = "Fala Softhoof",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [28951] = {
        locations = {
            { mapID = 125, continent = 113, x = 58.83, y = 38.95 },
        },
        name = "Breanni",
        types = NPC_TYPE.VENDOR,
    },
    [29250] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 116, continent = 113, x = 13.81, y = 84.69 },
        },
        name = "Tim Street",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [29251] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 116, continent = 113, x = 13.84, y = 84.72 },
        },
        name = "Kor",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [29478] = {
        locations = {
            { mapID = 125, continent = 113, x = 44.79, y = 45.6 },
        },
        name = "Jepetto Joybuzz",
        types = NPC_TYPE.VENDOR,
    },
    [29537] = {
        locations = {
            { mapID = 125, continent = 113, x = 60, y = 27.78 },
        },
        name = "Darahir",
        types = NPC_TYPE.VENDOR,
    },
    [29658] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 117, continent = 113, x = 31.59, y = 41.34 },
        },
        name = "Chelsea Reese",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [29716] = {
        locations = {
            { mapID = 125, continent = 113, x = 45.26, y = 46.38 },
        },
        name = "Clockwork Assistant",
        types = NPC_TYPE.VENDOR,
    },
    [29740] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 116, continent = 113, x = 21.64, y = 64.06 },
        },
        name = "Craga Ironsting",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [29906] = {
        locations = {
            { mapID = 120, continent = 113, x = 40.95, y = 86.06 },
        },
        name = "Heksi",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [29948] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 120, continent = 113, x = 28.66, y = 74.38 },
        },
        name = "Boarmaster Bragh",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [29959] = {
        locations = {
            { mapID = 120, continent = 113, x = 30.61, y = 36.85 },
        },
        name = "Andurg Slatechest",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [29967] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 120, continent = 113, x = 67.51, y = 50.27 },
        },
        name = "Udoho Icerunner",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [30008] = {
        locations = {
            { mapID = 120, continent = 113, x = 49.8, y = 65.97 },
        },
        name = "Kari the Beastmaster",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [30039] = {
        locations = {
            { mapID = 121, continent = 113, x = 59, y = 57.73 },
        },
        name = "Asgari",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [30304] = {
        locations = {
            { mapID = 118, continent = 113, x = 44.23, y = 22.35 },
        },
        name = "Imhadria",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [31916] = {
        locations = {
            { mapID = 117, continent = 113, x = 25.5, y = 58.7 },
        },
        name = "Tanaika",
        types = NPC_TYPE.VENDOR,
    },
    [32763] = {
        locations = {
            { mapID = 115, continent = 113, x = 48.46, y = 75.65 },
        },
        name = "Sairuk",
        types = NPC_TYPE.VENDOR,
    },
    [32836] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 27, continent = 13, x = 54.11, y = 50.81 },
            { mapID = 57, continent = 12, x = 55.7, y = 51.3 },
            { mapID = 37, continent = 13, x = 43.03, y = 65.31 },
            { mapID = 97, continent = 12, x = 49, y = 51.17 },
        },
        name = "Noblegarden Vendor",
        questEnds = { 13502 },
        questStarts = { 13502 },
        types = NPC_TYPE.VENDOR,
    },
    [32837] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 1, continent = 12, x = 51.88, y = 41.86 },
            { mapID = 7, continent = 12, x = 47.09, y = 59.88 },
            { mapID = 18, continent = 13, x = 61.34, y = 52.96 },
            { mapID = 94, continent = 13, x = 47.63, y = 47.31 },
        },
        name = "Noblegarden Merchant",
        questEnds = { 13503 },
        questStarts = { 13503 },
        types = NPC_TYPE.VENDOR,
    },
    [33307] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 118, continent = 113, x = 76.43, y = 19.17 },
        },
        name = "Corporal Arthur Flew",
        types = NPC_TYPE.VENDOR,
    },
    [33310] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 118, continent = 113, x = 76.53, y = 19.39 },
        },
        name = "Derrick Brindlebeard",
        types = NPC_TYPE.VENDOR,
    },
    [33553] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 118, continent = 113, x = 76.41, y = 24.35 },
        },
        name = "Freka Bloodaxe",
        types = NPC_TYPE.VENDOR,
    },
    [33554] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 118, continent = 113, x = 76.09, y = 24.45 },
        },
        name = "Samamba",
        types = NPC_TYPE.VENDOR,
    },
    [33555] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 118, continent = 113, x = 76.43, y = 24.11 },
        },
        name = "Eliza Killian",
        types = NPC_TYPE.VENDOR,
    },
    [33556] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 118, continent = 113, x = 76.23, y = 24.52 },
        },
        name = "Doru Thunderhorn",
        types = NPC_TYPE.VENDOR,
    },
    [33557] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 118, continent = 113, x = 76.33, y = 23.89 },
        },
        name = "Trellis Morningsun",
        types = NPC_TYPE.VENDOR,
    },
    [33650] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 118, continent = 113, x = 76.5, y = 19.63 },
        },
        name = "Rillie Spindlenut",
        types = NPC_TYPE.VENDOR,
    },
    [33653] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 118, continent = 113, x = 76.26, y = 19.12 },
        },
        name = "Rook Hawkfist",
        types = NPC_TYPE.VENDOR,
    },
    [33657] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 118, continent = 113, x = 76.14, y = 19.29 },
        },
        name = "Irisee",
        types = NPC_TYPE.VENDOR,
    },
    [33854] = {
        locations = {
            { mapID = 118, continent = 113, x = 71.81, y = 22.47 },
        },
        name = "Thomas Partridge",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [33980] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 62, continent = 12, x = 57.26, y = 33.77 },
        },
        name = "Apothecary Furrows",
        types = NPC_TYPE.VENDOR,
    },
    [34772] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 118, continent = 113, x = 76.14, y = 23.89 },
        },
        name = "Vasarin Redmorn",
        types = NPC_TYPE.VENDOR,
    },
    [34881] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 118, continent = 113, x = 76.14, y = 19.56 },
        },
        name = "Hiren Loresong",
        types = NPC_TYPE.VENDOR,
    },
    [35290] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 118, continent = 113, x = 75.7, y = 23.62 },
        },
        name = "Steen Horngrass",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [35291] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 118, continent = 113, x = 75.92, y = 20.2 },
        },
        name = "Moonbell",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [35344] = {
        locations = {
            { mapID = 118, continent = 113, x = 69.68, y = 22.08 },
        },
        name = "Bognar Ironfoot",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [37674] = {
        locations = {
            { mapID = 85, continent = 12, x = 53.03, y = 77.02 },
            { mapID = 89, continent = 12, x = 45.13, y = 57.8 },
            { mapID = 110, continent = 1467, x = 64.5, y = 67.07 },
            { mapID = 998, continent = 424, x = 66.11, y = 38.73 },
            { mapID = 84, continent = 13, x = 62.49, y = 75.23 },
            { mapID = 88, continent = 12, x = 43.4, y = 53.01 },
            { mapID = 87, continent = 13, x = 33.94, y = 66.11 },
            { mapID = 103, continent = 12, x = 73.67, y = 56.33 },
        },
        name = "Lovely Merchant",
        types = NPC_TYPE.VENDOR,
    },
    [41135] = {
        locations = {
            { mapID = 64, continent = 12, x = 85.7, y = 91.61 },
        },
        name = "\"Plucky\" Johnson",
        types = NPC_TYPE.VENDOR,
    },
    [41893] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 65, continent = 12, x = 66.36, y = 63.96 },
        },
        name = "Gelbin",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [41903] = {
        locations = {
            { mapID = 205, continent = 948, x = 49.46, y = 41.91 },
        },
        name = "Tender Aru",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [42875] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 205, continent = 948, x = 49, y = 57.56 },
        },
        name = "Miriam Brassbomb",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [42911] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 205, continent = 948, x = 51.47, y = 62.79 },
        },
        name = "Larok",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [42966] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 204, continent = 948, x = 56.14, y = 73.15 },
        },
        name = "Chase Whithers",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43017] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 65, continent = 12, x = 39.83, y = 32.25 },
        },
        name = "Fahlestad",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43019] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 65, continent = 12, x = 31.69, y = 61.42 },
        },
        name = "Teldorae",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43021] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 65, continent = 12, x = 58.61, y = 56.77 },
        },
        name = "Adrius",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43151] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 204, continent = 948, x = 52.98, y = 59.19 },
        },
        name = "Shurrak",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43379] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 198, continent = 12, x = 19.39, y = 36.21 },
        },
        name = "Limiah Whitebranch",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43408] = {
        locations = {
            { mapID = 198, continent = 12, x = 63.23, y = 23.13 },
        },
        name = "Aili Greenwillow",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43494] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 198, continent = 12, x = 41.76, y = 45.21 },
        },
        name = "Oltarin Graycloud",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43617] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 63, continent = 12, x = 12.76, y = 33.86 },
        },
        name = "Lursa",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43630] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 63, continent = 12, x = 38.7, y = 42.3 },
        },
        name = "Drek",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43634] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 63, continent = 12, x = 50.32, y = 65.99 },
        },
        name = "Vorcha",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43766] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 26, continent = 13, x = 31.88, y = 57.38 },
        },
        name = "Roslyn Paxton",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43770] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 26, continent = 13, x = 66.41, y = 45.18 },
        },
        name = "Tathan Thunderstone",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43773] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 76, continent = 12, x = 56.8, y = 50.05 },
        },
        name = "Stella Boomboom",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43877] = {
        locations = {
            { mapID = 66, continent = 12, x = 56.94, y = 49.61 },
        },
        name = "Fina Stillgrove",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43979] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 48, continent = 13, x = 83.94, y = 62.96 },
        },
        name = "Gravin Steelbeard",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43982] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 10, continent = 12, x = 62.35, y = 16.85 },
        },
        name = "Vernon Soursprye",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43988] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 10, continent = 12, x = 56.48, y = 39.9 },
        },
        name = "Carthok",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [43994] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 56, continent = 13, x = 57.73, y = 40.29 },
        },
        name = "Salustred",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44007] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 56, continent = 13, x = 26.09, y = 26.01 },
        },
        name = "Shep Goldtend",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44123] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 14, continent = 13, x = 40, y = 49.14 },
        },
        name = "Emily Jackson",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44179] = {
        locations = {
            { mapID = 210, continent = 13, x = 46.65, y = 93.33 },
        },
        name = "Harry No-Hooks",
        types = NPC_TYPE.VENDOR,
    },
    [44191] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 210, continent = 13, x = 34.87, y = 27.36 },
        },
        name = "Finzy Watchwoozle",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44252] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 84, continent = 13, x = 77.8, y = 67.38 },
        },
        name = "Karin",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44310] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 17, continent = 13, x = 41.56, y = 12.74 },
        },
        name = "Kroff",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44330] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 17, continent = 13, x = 60.32, y = 15.82 },
        },
        name = "Gina Gellar",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44335] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 17, continent = 13, x = 46.01, y = 85.33 },
        },
        name = "Willard C. Bennington",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44346] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 199, continent = 12, x = 39.05, y = 11.3 },
        },
        name = "Brandon Merriweather",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44347] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 199, continent = 12, x = 48.92, y = 68.29 },
        },
        name = "Werner Eastbrook",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44348] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 199, continent = 12, x = 65.92, y = 46.82 },
        },
        name = "Carey Willis",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [44349] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 199, continent = 12, x = 39.29, y = 19.83 },
        },
        name = "Munada",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44354] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 199, continent = 12, x = 40.78, y = 69.61 },
        },
        name = "Grantor",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44378] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 69, continent = 12, x = 51.69, y = 47.95 },
        },
        name = "Ajaye",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44382] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 69, continent = 12, x = 51.03, y = 18.07 },
        },
        name = "Veir",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44384] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 69, continent = 12, x = 41.47, y = 15.65 },
        },
        name = "Sora",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [44788] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 85, continent = 12, x = 39.32, y = 49.24 },
        },
        name = "Lonto",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [45297] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 207, continent = 948, x = 51.3, y = 50.2 },
        },
        name = "Beast-Handler Rustclamp",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [45298] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 207, continent = 948, x = 47.36, y = 51.59 },
        },
        name = "Mule Driver Ironshod",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [45498] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 21, continent = 13, x = 44.55, y = 20.76 },
        },
        name = "\"Salty\" Rocka",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [45789] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 85, continent = 12, x = 40.88, y = 80.71 },
        },
        name = "Bezzil",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [46572] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 85, continent = 12, x = 48.46, y = 75.57 },
        },
        name = "Goram",
        types = NPC_TYPE.VENDOR,
    },
    [46602] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 84, continent = 13, x = 64.13, y = 77.02 },
        },
        name = "Shay Pressler",
        types = NPC_TYPE.VENDOR,
    },
    [47328] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 245, continent = 13, x = 72.32, y = 63.18 },
        },
        name = "Quartermaster Brazie",
        types = NPC_TYPE.VENDOR,
    },
    [47337] = {
        locations = {
            { mapID = 51, continent = 13, x = 72.03, y = 14.72 },
        },
        name = "Shecky Shrimpshoot",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [47368] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 51, continent = 13, x = 28.56, y = 33.13 },
        },
        name = "Joran",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [47761] = {
        locations = {
            { mapID = 22, continent = 13, x = 47.24, y = 31.86 },
        },
        name = "Hank Ford",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [47764] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 85, continent = 12, x = 62.13, y = 35.26 },
        },
        name = "Murog",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [47866] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 22, continent = 13, x = 47.9, y = 64.08 },
        },
        name = "Lois Henderson",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [47934] = {
        locations = {
            { mapID = 32, continent = 13, x = 40.71, y = 68.95 },
        },
        name = "Karn Cragcare",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [48055] = {
        locations = {
            { mapID = 15, continent = 13, x = 65.62, y = 36.28 },
        },
        name = "Deedee Dropbolt",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [48095] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 15, continent = 13, x = 20.93, y = 56.45 },
        },
        name = "Katrina Lyons",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [48216] = {
        locations = {
            { mapID = 77, continent = 12, x = 44.45, y = 28.53 },
        },
        name = "Hurah",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [48531] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 245, continent = 13, x = 54.47, y = 81.32 },
        },
        name = "Pogg",
        types = NPC_TYPE.VENDOR,
    },
    [48887] = {
        locations = {
            { mapID = 249, continent = 12, x = 54.72, y = 33.67 },
        },
        name = "Darwishi",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [49395] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 25, continent = 13, x = 36.16, y = 61.54 },
        },
        name = "Shannon Lamb",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [49408] = {
        locations = {
            { mapID = 249, continent = 12, x = 26.94, y = 7.43 },
        },
        name = "Farah Tamina",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [49431] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 25, continent = 13, x = 59.68, y = 64.74 },
        },
        name = "Ansel Tunsleworth",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [49554] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 241, continent = 13, x = 75.62, y = 52.64 },
        },
        name = "Kanath",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [49577] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 241, continent = 13, x = 55.53, y = 14.79 },
        },
        name = "Baird Darkfeather",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [49593] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 241, continent = 13, x = 48.63, y = 29.36 },
        },
        name = "Tarm Deepgale",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [49600] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 241, continent = 13, x = 43.69, y = 57.26 },
        },
        name = "Matthew Churchill",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [49689] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 241, continent = 13, x = 80.59, y = 77.46 },
        },
        name = "Bonnie Hennigan",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [49755] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 241, continent = 13, x = 45.11, y = 76.41 },
        },
        name = "Zay'hana",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [49767] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 241, continent = 13, x = 53.84, y = 42.98 },
        },
        name = "Rukh Zumtarg",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [49790] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 241, continent = 13, x = 75.48, y = 16.82 },
        },
        name = "Kazz Fetchum",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [49803] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 241, continent = 13, x = 60.22, y = 58.12 },
        },
        name = "Kennen",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [50069] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 198, continent = 12, x = 41.76, y = 45.21 },
        },
        name = "Oltarin Graycloud",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [51495] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 87, continent = 13, x = 36.31, y = 85.79 },
        },
        name = "Steeg Haskell",
        types = NPC_TYPE.VENDOR,
    },
    [51496] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 998, continent = 424, x = 69.85, y = 43.72 },
        },
        name = "Kim Horn",
        types = NPC_TYPE.VENDOR,
    },
    [51501] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 103, continent = 12, x = 53.62, y = 69.66 },
        },
        name = "Nuri",
        types = NPC_TYPE.VENDOR,
    },
    [51502] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 110, continent = 1467, x = 78.34, y = 85.23 },
        },
        name = "Larissia",
        types = NPC_TYPE.VENDOR,
    },
    [51503] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 88, continent = 12, x = 37.07, y = 63.28 },
        },
        name = "Randah Songhorn",
        types = NPC_TYPE.VENDOR,
    },
    [51504] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 89, continent = 12, x = 64.79, y = 37.63 },
        },
        name = "Velia Moonbow",
        types = NPC_TYPE.VENDOR,
    },
    [51512] = {
        locations = {
            { mapID = 125, continent = 113, x = 52.54, y = 54.96 },
        },
        name = "Mirla Silverblaze",
        types = NPC_TYPE.VENDOR,
    },
    [52268] = {
        locations = {
            { mapID = 111, continent = 1467, x = 58.73, y = 46.38 },
        },
        name = "Riha",
        types = NPC_TYPE.VENDOR,
    },
    [52358] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 84, continent = 13, x = 57.87, y = 65.04 },
        },
        name = "Craggle Wobbletop",
        types = NPC_TYPE.VENDOR,
    },
    [52809] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 85, continent = 12, x = 58.95, y = 58.78 },
        },
        name = "Blax Bottlerocket",
        types = NPC_TYPE.VENDOR,
    },
    [52830] = {
        locations = {
            { mapID = 83, continent = 12, x = 59.9, y = 51.59 },
        },
        name = "Michelle De Rum",
        types = NPC_TYPE.VENDOR,
    },
    [53728] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 37, continent = 13, x = 32.05, y = 50.71 },
        },
        name = "Dorothy",
        types = NPC_TYPE.VENDOR,
    },
    [53757] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 18, continent = 13, x = 62.22, y = 66.43 },
        },
        name = "Chub",
        types = NPC_TYPE.VENDOR,
    },
    [53780] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 198, continent = 12, x = 19.39, y = 36.21 },
        },
        name = "Limiah Whitebranch",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [53881] = {
        locations = {
            { mapID = 338, continent = 12, x = 44.06, y = 86.31 },
        },
        name = "Ayla Shadowstorm",
        questEnds = { 29280 },
        questStarts = { 29279 },
        types = NPC_TYPE.VENDOR,
    },
    [53882] = {
        locations = {
            { mapID = 338, continent = 12, x = 44.43, y = 88.78 },
        },
        name = "Varlan Highbough",
        questStarts = { 29283 },
        types = NPC_TYPE.VENDOR,
    },
    [55305] = {
        locations = {
            { mapID = 407, continent = 12, x = 49.39, y = 77.41 },
        },
        name = "Carl Goodup",
        types = NPC_TYPE.VENDOR,
    },
    [59310] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 418, continent = 424, x = 59.1, y = 24.3 },
        },
        name = "Teve Dawnchaser",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [59413] = {
        locations = {
            { mapID = 379, continent = 424, x = 42.25, y = 69.32 },
        },
        name = "Cousin Mountainmusk",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [59509] = {
        locations = {
            { mapID = 379, continent = 424, x = 65.33, y = 61.52 },
        },
        name = "Herder Muskfree",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [62935] = {
        locations = {
            { mapID = 433, continent = 424, x = 55.7, y = 75.82 },
        },
        name = "Kama the Beast Tamer",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [63014] = {
        locations = {
            { mapID = 37, continent = 13, x = 40.32, y = 66.01 },
        },
        name = "Marcus Jensen",
        questEnds = { 31308, 31309, 31550, 31785 },
        questStarts = { 31308, 31309, 31550, 31785 },
        types = NPC_TYPE.TRAINER,
    },
    [63061] = {
        locations = {
            { mapID = 1, continent = 12, x = 52.69, y = 41.27 },
        },
        name = "Narzak",
        questEnds = { 31570, 31571, 31572, 31830 },
        questStarts = { 31570, 31571, 31830 },
        types = NPC_TYPE.TRAINER,
    },
    [63067] = {
        locations = {
            { mapID = 7, continent = 12, x = 49.19, y = 56.06 },
        },
        name = "Naleen",
        questEnds = { 31573, 31574, 31575, 31831 },
        types = NPC_TYPE.TRAINER,
    },
    [63070] = {
        locations = {
            { mapID = 57, continent = 12, x = 55.21, y = 51.32 },
        },
        name = "Valeena",
        questEnds = { 31552, 31553, 31555, 31826 },
        questStarts = { 31555 },
        types = NPC_TYPE.TRAINER,
    },
    [63073] = {
        locations = {
            { mapID = 18, continent = 13, x = 60.93, y = 54.3 },
        },
        name = "Ansel Fincap",
        questEnds = { 31576, 31577, 31578, 31823 },
        questStarts = { 31823 },
        types = NPC_TYPE.TRAINER,
    },
    [63075] = {
        locations = {
            { mapID = 27, continent = 13, x = 53.81, y = 50.07 },
        },
        name = "Grady Bannson",
        questEnds = { 31548, 31549, 31551, 31822 },
        questStarts = { 31822 },
        types = NPC_TYPE.TRAINER,
    },
    [63077] = {
        locations = {
            { mapID = 97, continent = 12, x = 49.29, y = 52.15 },
        },
        name = "Lehna",
        questEnds = { 31556, 31568, 31569, 31825 },
        questStarts = { 31825 },
        types = NPC_TYPE.TRAINER,
    },
    [63080] = {
        locations = {
            { mapID = 94, continent = 13, x = 47.33, y = 47.33 },
        },
        name = "Jarson Everlong",
        questEnds = { 31579, 31580, 31581, 31824 },
        questStarts = { 31579 },
        types = NPC_TYPE.TRAINER,
    },
    [63083] = {
        locations = {
            { mapID = 62, continent = 12, x = 50.12, y = 20.15 },
        },
        name = "Will Larsons",
        questEnds = { 31582, 31583, 31584, 31832 },
        questStarts = { 31584, 31832 },
        types = NPC_TYPE.TRAINER,
    },
    [63086] = {
        locations = {
            { mapID = 85, continent = 12, x = 36.77, y = 77.14 },
        },
        name = "Matty",
        questEnds = { 31585, 31586, 31587, 31828 },
        questStarts = { 31585, 31828 },
        types = NPC_TYPE.TRAINER,
    },
    [63194] = {
        locations = {
            { mapID = 50, continent = 13, x = 45.99, y = 40.44 },
        },
        name = "Steven Lisbane",
        questEnds = { 31729, 31852 },
        questStarts = { 31728, 31852 },
        types = NPC_TYPE.TAMER,
        petOrder = { 885, 884, 883 },
        pets = {
            { speciesID = 885, name = "Nanners", level = 9, maxHealth = 496, power = 88, speed = 88, familyType = 8, abilities = { 349, 124, 354 } },
            { speciesID = 884, name = "Moonstalker", level = 9, maxHealth = 496, power = 88, speed = 88, familyType = 8, abilities = { 429, 535, 536 } },
            { speciesID = 883, name = "Emeralda", level = 9, maxHealth = 595, power = 79, speed = 79, familyType = 6, abilities = { 432, 538, 431 } },
        },
    },
    [63596] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 84, continent = 13, x = 69.49, y = 25.16 },
        },
        name = "Audrey Burnhep",
        questEnds = {
            31591,
            31592,
            31593,
            31821,
            31917,
            31975,
            31976,
            31981,
            31984,
            31985,
            32008,
            32863,
        },
        questStarts = {
            31316,
            31591,
            31592,
            31593,
            31821,
            31889,
            31902,
            31919,
            31927,
            31930,
            31966,
            32008,
            32863,
        },
        types = NPC_TYPE.TRAINER,
    },
    [63626] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 85, continent = 12, x = 52.54, y = 59.27 },
        },
        name = "Varzok",
        questEnds = {
            31588,
            31589,
            31590,
            31827,
            31918,
            31977,
            31980,
            31982,
            31983,
            31986,
            32009,
            32863,
        },
        questStarts = {
            31588,
            31589,
            31590,
            31812,
            31827,
            31891,
            31903,
            31921,
            31929,
            31952,
            31967,
            32009,
            32863,
        },
        types = NPC_TYPE.TRAINER,
    },
    [63721] = {
        locations = {
            { mapID = 418, continent = 424, x = 68.41, y = 43.5 },
        },
        name = "Nat Pagle",
        questEnds = { 31443, 31444, 31446, 36608 },
        questStarts = { 36609, 36882 },
        types = NPC_TYPE.VENDOR,
    },
    [63986] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 390, continent = 424, x = 60.27, y = 22.76 },
        },
        name = "Tracker Lang",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [63988] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 390, continent = 424, x = 84.6, y = 63.45 },
        },
        name = "Jaul Hsu",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [64330] = {
        locations = {
            { mapID = 37, continent = 13, x = 41.64, y = 83.64 },
        },
        name = "Julia Stevens",
        questEnds = { 31316, 31693 },
        questStarts = { 31693, 31724 },
        types = NPC_TYPE.TAMER,
        petOrder = { 873, 872 },
        pets = {
            { speciesID = 873, name = "Fangs", level = 2, maxHealth = 194, power = 19, speed = 19, familyType = 8, abilities = { 110, 152, 158 } },
            { speciesID = 872, name = "Slither", level = 2, maxHealth = 194, power = 19, speed = 19, familyType = 8, abilities = { 110, 155, 156 } },
        },
    },
    [64572] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 390, continent = 424, x = 86.58, y = 59.98 },
        },
        name = "Sara Finkleswitch",
        questEnds = { 32428, 32603, 32604, 32863, 32868, 32869 },
        questStarts = { 32428, 32603, 32604, 32863, 32868, 32869 },
        types = NPC_TYPE.TRAINER,
    },
    [64582] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 390, continent = 424, x = 60.78, y = 23.69 },
        },
        name = "Gentle San",
        questEnds = { 32428, 32603, 32604, 32863, 32868, 32869 },
        questStarts = { 32428, 32603, 32604, 32863, 32868, 32869 },
        types = NPC_TYPE.TRAINER,
    },
    [65648] = {
        locations = {
            { mapID = 52, continent = 13, x = 60.83, y = 18.48 },
        },
        name = "Old MacDonald",
        questEnds = { 31724, 31780 },
        questStarts = { 31725, 31780 },
        types = NPC_TYPE.TAMER,
        petOrder = { 876, 875, 874 },
        pets = {
            { speciesID = 876, name = "Foe Reaper 800", level = 3, maxHealth = 247, power = 29, speed = 26, familyType = 10, abilities = { 384, 389, 390 } },
            { speciesID = 875, name = "Clucks", level = 3, maxHealth = 232, power = 29, speed = 44, familyType = 3, abilities = { 112, 524, 581 } },
            { speciesID = 874, name = "Teensy", level = 3, maxHealth = 240, power = 28, speed = 28, familyType = 5, abilities = { 119, 360, 283 } },
        },
    },
    [65651] = {
        locations = {
            { mapID = 49, continent = 13, x = 33.28, y = 52.57 },
        },
        name = "Lindsay",
        questEnds = { 31725, 31781 },
        questStarts = { 31726, 31781 },
        types = NPC_TYPE.TAMER,
        petOrder = { 879, 878, 877 },
        pets = {
            { speciesID = 879, name = "Flufftail", level = 5, maxHealth = 345, power = 49, speed = 44, familyType = 5, abilities = { 119, 159, 360 } },
            { speciesID = 878, name = "Dipsy", level = 5, maxHealth = 334, power = 47, speed = 47, familyType = 5, abilities = { 119, 162, 360 } },
            { speciesID = 877, name = "Flipsy", level = 5, maxHealth = 345, power = 44, speed = 49, familyType = 5, abilities = { 119, 312, 163 } },
        },
    },
    [65655] = {
        locations = {
            { mapID = 47, continent = 13, x = 19.88, y = 44.6 },
        },
        name = "Eric Davidson",
        questEnds = { 31726, 31850 },
        questStarts = { 31729, 31850 },
        types = NPC_TYPE.TAMER,
        petOrder = { 882, 881, 880 },
        pets = {
            { speciesID = 882, name = "Webwinder", level = 7, maxHealth = 443, power = 62, speed = 69, familyType = 8, abilities = { 378, 339, 380 } },
            { speciesID = 881, name = "Blackfang", level = 7, maxHealth = 408, power = 69, speed = 69, familyType = 8, abilities = { 378, 339, 383 } },
            { speciesID = 880, name = "Darkwidow", level = 7, maxHealth = 443, power = 69, speed = 62, familyType = 8, abilities = { 380, 382, 250 } },
        },
    },
    [65656] = {
        locations = {
            { mapID = 210, continent = 13, x = 51.47, y = 73.37 },
        },
        name = "Bill Buckler",
        questEnds = { 31728, 31851 },
        questStarts = { 31851, 31917 },
        types = NPC_TYPE.TAMER,
        petOrder = { 888, 887, 886 },
        pets = {
            { speciesID = 888, name = "Burgle", level = 11, maxHealth = 661, power = 112, speed = 112, familyType = 1, abilities = { 111, 757, 230 } },
            { speciesID = 887, name = "Eyegouger", level = 11, maxHealth = 628, power = 117, speed = 176, familyType = 3, abilities = { 420, 521, 190 } },
            { speciesID = 886, name = "Young Beaky", level = 11, maxHealth = 687, power = 106, speed = 176, familyType = 3, abilities = { 170, 202, 162 } },
        },
    },
    [66126] = {
        locations = {
            { mapID = 1, continent = 12, x = 43.79, y = 28.78 },
        },
        name = "Zunta",
        questEnds = { 31812, 31818 },
        questStarts = { 31813, 31818 },
        types = NPC_TYPE.TAMER,
        petOrder = { 890, 889 },
        pets = {
            { speciesID = 890, name = "Spike", level = 2, maxHealth = 194, power = 19, speed = 19, familyType = 8, abilities = { 429, 357, 355 } },
            { speciesID = 889, name = "Mumtar", level = 2, maxHealth = 194, power = 19, speed = 19, familyType = 5, abilities = { 119, 155, 706 } },
        },
    },
    [66135] = {
        locations = {
            { mapID = 10, continent = 12, x = 58.58, y = 52.98 },
        },
        name = "Dagra the Fierce",
        questEnds = { 31813, 31819 },
        questStarts = { 31814, 31819 },
        types = NPC_TYPE.TAMER,
        petOrder = { 893, 892, 891 },
        pets = {
            { speciesID = 893, name = "Longneck", level = 3, maxHealth = 240, power = 28, speed = 28, familyType = 8, abilities = { 493, 254, 163 } },
            { speciesID = 892, name = "Springtail", level = 3, maxHealth = 232, power = 29, speed = 29, familyType = 5, abilities = { 493, 574, 376 } },
            { speciesID = 891, name = "Ripper", level = 3, maxHealth = 232, power = 26, speed = 33, familyType = 8, abilities = { 429, 492, 536 } },
        },
    },
    [66136] = {
        locations = {
            { mapID = 63, continent = 12, x = 20.2, y = 29.39 },
            { mapID = 63, continent = 12, x = 20.2, y = 29.58 },
        },
        name = "Analynn",
        questEnds = { 31814, 31854 },
        questStarts = { 31815, 31854 },
        types = NPC_TYPE.TAMER,
        petOrder = { 896, 895, 894 },
        pets = {
            { speciesID = 896, name = "Mister Pinch", level = 5, maxHealth = 375, power = 44, speed = 44, familyType = 9, abilities = { 356, 511, 310 } },
            { speciesID = 895, name = "Oozer", level = 5, maxHealth = 320, power = 49, speed = 49, familyType = 5, abilities = { 445, 369, 449 } },
            { speciesID = 894, name = "Flutterby", level = 5, maxHealth = 320, power = 44, speed = 83, familyType = 3, abilities = { 506, 507, 508 } },
        },
    },
    [66137] = {
        locations = {
            { mapID = 65, continent = 12, x = 59.58, y = 71.39 },
            { mapID = 65, continent = 12, x = 59.58, y = 71.59 },
        },
        name = "Zonya the Sadist",
        questEnds = { 31815, 31862 },
        questStarts = { 31817, 31862 },
        types = NPC_TYPE.TAMER,
        petOrder = { 899, 898, 897 },
        pets = {
            { speciesID = 899, name = "Constrictor", level = 7, maxHealth = 408, power = 69, speed = 69, familyType = 8, abilities = { 110, 155, 156 } },
            { speciesID = 898, name = "Odoron", level = 7, maxHealth = 427, power = 65, speed = 65, familyType = 5, abilities = { 119, 576, 527 } },
            { speciesID = 897, name = "Acidous", level = 7, maxHealth = 443, power = 62, speed = 69, familyType = 8, abilities = { 378, 380, 250 } },
        },
    },
    [66230] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 371, continent = 424, x = 28.7, y = 13.08 },
        },
        name = "Su Mi",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [66241] = {
        locations = {
            { mapID = 371, continent = 424, x = 46.53, y = 43.77 },
        },
        name = "Hong the Kindly",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [66243] = {
        locations = {
            { mapID = 371, continent = 424, x = 54.84, y = 62.96 },
        },
        name = "Pan the Kind Hand",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [66244] = {
        locations = {
            { mapID = 376, continent = 424, x = 55.26, y = 49.66 },
        },
        name = "Su the Tamer",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [66245] = {
        locations = {
            { mapID = 390, continent = 424, x = 35.99, y = 75.43 },
        },
        name = "Mount-haver Nik Nik",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [66246] = {
        locations = {
            { mapID = 388, continent = 424, x = 71.37, y = 57.58 },
        },
        name = "Tigermaster Gai-Lin",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [66247] = {
        locations = {
            { mapID = 388, continent = 424, x = 74.82, y = 81.32 },
        },
        name = "Tigermaster Liu-Do",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [66248] = {
        locations = {
            { mapID = 388, continent = 424, x = 50.15, y = 71.47 },
        },
        name = "Tigermistress Min-To",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [66249] = {
        locations = {
            { mapID = 422, continent = 424, x = 55.87, y = 69.56 },
        },
        name = "Rough-rider Kim",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [66250] = {
        locations = {
            { mapID = 422, continent = 424, x = 53.67, y = 32.37 },
        },
        name = "Handler Kla'vik",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [66251] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 418, continent = 424, x = 67.24, y = 32.25 },
        },
        name = "Huntress Vael'yrie",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [66266] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 371, continent = 424, x = 44.6, y = 84.79 },
        },
        name = "Cheung",
        types = NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR,
    },
    [66352] = {
        locations = {
            { mapID = 69, continent = 12, x = 59.73, y = 49.63 },
        },
        name = "Traitor Gluk",
        questEnds = { 31871 },
        questStarts = { 31871 },
        types = NPC_TYPE.TAMER,
        petOrder = { 906, 905, 904 },
        pets = {
            { speciesID = 906, name = "Glimmer", level = 13, maxHealth = 724, power = 125, speed = 156, familyType = 2, abilities = { 440, 277, 595 } },
            { speciesID = 905, name = "Rasp", level = 13, maxHealth = 724, power = 139, speed = 139, familyType = 8, abilities = { 110, 158, 156 } },
            { speciesID = 904, name = "Prancer", level = 13, maxHealth = 794, power = 125, speed = 139, familyType = 5, abilities = { 493, 254, 539 } },
        },
    },
    [66372] = {
        locations = {
            { mapID = 66, continent = 12, x = 57.09, y = 45.67 },
        },
        name = "Merda Stronghoof",
        questEnds = { 31817, 31872 },
        questStarts = { 31870, 31872 },
        types = NPC_TYPE.TAMER,
        petOrder = { 902, 901, 900 },
        pets = {
            { speciesID = 902, name = "Bounder", level = 9, maxHealth = 541, power = 79, speed = 88, familyType = 9, abilities = { 118, 230, 232 } },
            { speciesID = 901, name = "Ambershell", level = 9, maxHealth = 595, power = 79, speed = 79, familyType = 7, abilities = { 621, 383, 436 } },
            { speciesID = 900, name = "Rockhide", level = 9, maxHealth = 595, power = 79, speed = 79, familyType = 5, abilities = { 117, 310, 566 } },
        },
    },
    [66412] = {
        locations = {
            { mapID = 80, continent = 12, x = 46.11, y = 60.27 },
        },
        name = "Elena Flutterfly",
        questEnds = { 31908 },
        questStarts = { 31908 },
        types = NPC_TYPE.TAMER,
        petOrder = { 926, 925, 924 },
        pets = {
            { speciesID = 926, name = "Willow", level = 17, maxHealth = 916, power = 182, speed = 182, familyType = 2, abilities = { 115, 122, 347 } },
            { speciesID = 925, name = "Beacon", level = 17, maxHealth = 1008, power = 182, speed = 163, familyType = 6, abilities = { 114, 460, 463 } },
            { speciesID = 924, name = "Lacewing", level = 17, maxHealth = 1008, power = 163, speed = 272, familyType = 3, abilities = { 420, 506, 162 } },
        },
    },
    [66422] = {
        locations = {
            { mapID = 199, continent = 12, x = 39.58, y = 79.19 },
        },
        name = "Cassandra Kaboom",
        questEnds = { 31870, 31904 },
        questStarts = { 31904, 31918 },
        types = NPC_TYPE.TAMER,
        petOrder = { 909, 908, 907 },
        pets = {
            { speciesID = 909, name = "Gizmo", level = 11, maxHealth = 628, power = 106, speed = 132, familyType = 10, abilities = { 392, 390 } },
            { speciesID = 908, name = "Cluckatron", level = 11, maxHealth = 628, power = 117, speed = 117, familyType = 10, abilities = { 777, 640, 645 } },
            { speciesID = 907, name = "Whirls", level = 11, maxHealth = 687, power = 106, speed = 117, familyType = 10, abilities = { 455, 208, 278 } },
        },
    },
    [66436] = {
        locations = {
            { mapID = 70, continent = 12, x = 53.84, y = 74.87 },
        },
        name = "Grazzle the Great",
        questEnds = { 31905 },
        questStarts = { 31905 },
        types = NPC_TYPE.TAMER,
        petOrder = { 913, 912, 911 },
        pets = {
            { speciesID = 913, name = "Blaze", level = 14, maxHealth = 772, power = 158, speed = 141, familyType = 2, abilities = { 115, 172, 169 } },
            { speciesID = 912, name = "Flameclaw", level = 14, maxHealth = 772, power = 176, speed = 126, familyType = 2, abilities = { 115, 122, 169 } },
            { speciesID = 911, name = "Firetooth", level = 14, maxHealth = 848, power = 158, speed = 126, familyType = 2, abilities = { 115, 168, 169 } },
        },
    },
    [66442] = {
        locations = {
            { mapID = 77, continent = 12, x = 39.93, y = 56.55 },
        },
        name = "Zoltan",
        questEnds = { 31907 },
        questStarts = { 31907 },
        types = NPC_TYPE.TAMER,
        petOrder = { 923, 922, 921 },
        pets = {
            { speciesID = 923, name = "Hatewalker", level = 16, maxHealth = 1108, power = 144, speed = 154, familyType = 10, abilities = { 202, 208, 644 } },
            { speciesID = 922, name = "Beamer", level = 16, maxHealth = 868, power = 192, speed = 154, familyType = 6, abilities = { 473, 474, 475 } },
            { speciesID = 921, name = "Ultramus", level = 16, maxHealth = 954, power = 171, speed = 154, familyType = 6, abilities = { 406, 409, 407 } },
        },
    },
    [66452] = {
        locations = {
            { mapID = 64, continent = 12, x = 31.86, y = 32.93 },
        },
        name = "Kela Grimtotem",
        questEnds = { 31906 },
        questStarts = { 31906 },
        types = NPC_TYPE.TAMER,
        petOrder = { 917, 916, 915 },
        pets = {
            { speciesID = 917, name = "Indigon", level = 15, maxHealth = 1000, power = 144, speed = 144, familyType = 5, abilities = { 119, 155, 706 } },
            { speciesID = 916, name = "Plague", level = 15, maxHealth = 820, power = 160, speed = 160, familyType = 5, abilities = { 253, 360, 283 } },
            { speciesID = 915, name = "Cho'guana", level = 15, maxHealth = 901, power = 160, speed = 144, familyType = 8, abilities = { 563, 357, 802 } },
        },
    },
    [66466] = {
        locations = {
            { mapID = 83, continent = 12, x = 65.62, y = 64.5 },
        },
        name = "Stone Cold Trixxy",
        questEnds = { 31897, 31909 },
        questStarts = { 31897, 31909, 31977 },
        types = NPC_TYPE.TAMER,
        petOrder = { 929, 928, 927 },
        pets = {
            { speciesID = 929, name = "Tinygos", level = 19, maxHealth = 1115, power = 182, speed = 203, familyType = 2, abilities = { 589, 592, 593 } },
            { speciesID = 928, name = "Frostmaw", level = 19, maxHealth = 1012, power = 203, speed = 203, familyType = 8, abilities = { 429, 492, 536 } },
            { speciesID = 927, name = "Blizzy", level = 19, maxHealth = 1012, power = 182, speed = 342, familyType = 3, abilities = { 184, 518, 517 } },
        },
    },
    [66478] = {
        locations = {
            { mapID = 26, continent = 13, x = 62.98, y = 54.57 },
        },
        name = "David Kosse",
        questEnds = { 31910 },
        questStarts = { 31910 },
        types = NPC_TYPE.TAMER,
        petOrder = { 933, 932, 931 },
        pets = {
            { speciesID = 933, name = "Subject 142", level = 13, maxHealth = 724, power = 125, speed = 156, familyType = 5, abilities = { 119, 312, 159 } },
            { speciesID = 932, name = "Corpsefeeder", level = 13, maxHealth = 880, power = 125, speed = 125, familyType = 8, abilities = { 369, 160, 371 } },
            { speciesID = 931, name = "Plop", level = 13, maxHealth = 794, power = 125, speed = 139, familyType = 6, abilities = { 445, 447, 448 } },
        },
    },
    [66512] = {
        locations = {
            { mapID = 23, continent = 13, x = 66.94, y = 52.4 },
        },
        name = "Deiza Plaguehorn",
        questEnds = { 31911 },
        questStarts = { 31911 },
        types = NPC_TYPE.TAMER,
        petOrder = { 936, 935, 934 },
        pets = {
            { speciesID = 936, name = "Carrion", level = 14, maxHealth = 814, power = 143, speed = 143, familyType = 8, abilities = { 367, 369, 364 } },
            { speciesID = 935, name = "Bleakspinner", level = 14, maxHealth = 772, power = 150, speed = 150, familyType = 8, abilities = { 378, 339, 382 } },
            { speciesID = 934, name = "Plaguebringer", level = 14, maxHealth = 940, power = 134, speed = 134, familyType = 4, abilities = { 499, 212, 214 } },
        },
    },
    [66515] = {
        locations = {
            { mapID = 32, continent = 13, x = 35.28, y = 27.75 },
        },
        name = "Kortas Darkhammer",
        questEnds = { 31912 },
        questStarts = { 31912 },
        types = NPC_TYPE.TAMER,
        petOrder = { 939, 938, 937 },
        pets = {
            { speciesID = 939, name = "Garnestrasz", level = 15, maxHealth = 901, power = 160, speed = 144, familyType = 2, abilities = { 115, 168, 122 } },
            { speciesID = 938, name = "Veridia", level = 15, maxHealth = 901, power = 144, speed = 160, familyType = 2, abilities = { 525, 597, 598 } },
            { speciesID = 937, name = "Obsidion", level = 15, maxHealth = 820, power = 160, speed = 160, familyType = 2, abilities = { 393, 256, 792 } },
        },
    },
    [66518] = {
        locations = {
            { mapID = 51, continent = 13, x = 76.8, y = 41.49 },
        },
        name = "Everessa",
        questEnds = { 31913 },
        questStarts = { 31913 },
        types = NPC_TYPE.TAMER,
        petOrder = { 943, 942, 941 },
        pets = {
            { speciesID = 943, name = "Dampwing", level = 16, maxHealth = 954, power = 154, speed = 256, familyType = 3, abilities = { 504, 162, 507 } },
            { speciesID = 942, name = "Croaker", level = 16, maxHealth = 1060, power = 154, speed = 154, familyType = 9, abilities = { 233, 228, 232 } },
            { speciesID = 941, name = "Anklor", level = 16, maxHealth = 868, power = 171, speed = 171, familyType = 8, abilities = { 110, 156, 152 } },
        },
    },
    [66520] = {
        locations = {
            { mapID = 36, continent = 13, x = 25.53, y = 47.48 },
        },
        name = "Durin Darkhammer",
        questEnds = { 31914 },
        questStarts = { 31914 },
        types = NPC_TYPE.TAMER,
        petOrder = { 946, 945, 944 },
        pets = {
            { speciesID = 946, name = "Comet", level = 17, maxHealth = 916, power = 163, speed = 306, familyType = 3, abilities = { 504, 506, 706 } },
            { speciesID = 945, name = "Ignious", level = 17, maxHealth = 1008, power = 182, speed = 163, familyType = 5, abilities = { 113, 173, 172 } },
            { speciesID = 944, name = "Moltar", level = 17, maxHealth = 1120, power = 163, speed = 163, familyType = 7, abilities = { 113, 179, 319 } },
        },
    },
    [66522] = {
        locations = {
            { mapID = 42, continent = 13, x = 40.05, y = 76.45 },
        },
        name = "Lydia Accoste",
        questEnds = { 31915, 31916 },
        questStarts = { 31915, 31916, 31976, 31980 },
        types = NPC_TYPE.TAMER,
        petOrder = { 949, 948, 947 },
        pets = {
            { speciesID = 949, name = "Jack", level = 19, maxHealth = 1012, power = 203, speed = 203, familyType = 7, abilities = { 398, 318, 303 } },
            { speciesID = 948, name = "Bishibosh", level = 19, maxHealth = 1012, power = 182, speed = 228, familyType = 4, abilities = { 210, 592, 476 } },
            { speciesID = 947, name = "Nightstalker", level = 19, maxHealth = 1115, power = 182, speed = 203, familyType = 4, abilities = { 422, 657, 121 } },
        },
    },
    [66550] = {
        locations = {
            { mapID = 100, continent = 1467, x = 64.3, y = 49.29 },
        },
        name = "Nicki Tinytech",
        questEnds = { 31922 },
        questStarts = { 31922 },
        types = NPC_TYPE.TAMER,
        petOrder = { 952, 951, 950 },
        pets = {
            { speciesID = 952, name = "ED-005", level = 20, maxHealth = 1168, power = 214, speed = 192, familyType = 10, abilities = { 455, 640, 636 } },
            { speciesID = 951, name = "Goliath", level = 20, maxHealth = 1168, power = 214, speed = 192, familyType = 10, abilities = { 777, 634, 645 } },
            { speciesID = 950, name = "Sploder", level = 20, maxHealth = 1300, power = 192, speed = 192, familyType = 10, abilities = { 754, 640, 282 } },
        },
    },
    [66551] = {
        locations = {
            { mapID = 102, continent = 1467, x = 17.24, y = 50.51 },
        },
        name = "Ras'an",
        questEnds = { 31923 },
        questStarts = { 31923 },
        types = NPC_TYPE.TAMER,
        petOrder = { 955, 954, 953 },
        pets = {
            { speciesID = 955, name = "Glitterfly", level = 21, maxHealth = 1108, power = 202, speed = 378, familyType = 3, abilities = { 706, 506, 270 } },
            { speciesID = 954, name = "Tripod", level = 21, maxHealth = 1171, power = 214, speed = 214, familyType = 6, abilities = { 483, 593, 589 } },
            { speciesID = 953, name = "Fungor", level = 21, maxHealth = 1360, power = 202, speed = 202, familyType = 1, abilities = { 221, 743, 746 } },
        },
    },
    [66552] = {
        locations = {
            { mapID = 107, continent = 1467, x = 60.95, y = 49.41 },
        },
        name = "Narrok",
        questEnds = { 31924 },
        questStarts = { 31924 },
        types = NPC_TYPE.TAMER,
        petOrder = { 958, 957, 956 },
        pets = {
            { speciesID = 958, name = "Prince Wart", level = 22, maxHealth = 1222, power = 224, speed = 224, familyType = 9, abilities = { 228, 233, 232 } },
            { speciesID = 957, name = "Dramaticus", level = 22, maxHealth = 1156, power = 235, speed = 235, familyType = 5, abilities = { 367, 165, 253 } },
            { speciesID = 956, name = "Stompy", level = 22, maxHealth = 1420, power = 211, speed = 211, familyType = 8, abilities = { 377, 375, 571 } },
        },
    },
    [66553] = {
        locations = {
            { mapID = 111, continent = 1467, x = 58.75, y = 70.05 },
        },
        name = "Morulu The Elder",
        questEnds = { 31925 },
        questStarts = { 31925 },
        types = NPC_TYPE.TAMER,
        petOrder = { 961, 960, 959 },
        pets = {
            { speciesID = 961, name = "Chomps", level = 23, maxHealth = 1204, power = 276, speed = 221, familyType = 9, abilities = { 803, 509, 538 } },
            { speciesID = 960, name = "Gnasher", level = 23, maxHealth = 1204, power = 276, speed = 221, familyType = 9, abilities = { 803, 538, 423 } },
            { speciesID = 959, name = "Cragmaw", level = 23, maxHealth = 1204, power = 246, speed = 246, familyType = 9, abilities = { 160, 118, 423 } },
        },
    },
    [66557] = {
        locations = {
            { mapID = 104, continent = 1467, x = 30.49, y = 41.74 },
        },
        name = "Bloodknight Antari",
        questEnds = { 31920, 31926 },
        questStarts = { 31920, 31926, 31981, 31982 },
        types = NPC_TYPE.TAMER,
        petOrder = { 964, 963, 962 },
        pets = {
            { speciesID = 964, name = "Arcanus", level = 24, maxHealth = 1426, power = 265, speed = 265, familyType = 6, abilities = { 484, 486, 488 } },
            { speciesID = 963, name = "Jadefire", level = 24, maxHealth = 1488, power = 278, speed = 250, familyType = 7, abilities = { 113, 178, 179 } },
            { speciesID = 962, name = "Netherbite", level = 24, maxHealth = 1348, power = 278, speed = 278, familyType = 2, abilities = { 764, 608, 751 } },
        },
    },
    [66635] = {
        locations = {
            { mapID = 117, continent = 113, x = 28.61, y = 33.86 },
        },
        name = "Beegle Blastfuse",
        questEnds = { 31931 },
        questStarts = { 31931 },
        types = NPC_TYPE.TAMER,
        petOrder = { 967, 966, 965 },
        pets = {
            { speciesID = 967, name = "Dinner", level = 25, maxHealth = 1400, power = 289, speed = 434, familyType = 3, abilities = { 524, 170, 581 } },
            { speciesID = 966, name = "Gobbles", level = 25, maxHealth = 1546, power = 260, speed = 434, familyType = 3, abilities = { 580, 420, 579 } },
            { speciesID = 965, name = "Warble", level = 25, maxHealth = 1481, power = 276, speed = 276, familyType = 9, abilities = { 112, 624, 575 } },
        },
    },
    [66636] = {
        locations = {
            { mapID = 127, continent = 113, x = 50.1, y = 58.95 },
        },
        name = "Nearly Headless Jacob",
        questEnds = { 31932 },
        questStarts = { 31932 },
        types = NPC_TYPE.TAMER,
        petOrder = { 970, 969, 968 },
        pets = {
            { speciesID = 970, name = "Spooky Strangler", level = 25, maxHealth = 1400, power = 289, speed = 289, familyType = 4, abilities = { 218, 468, 780 } },
            { speciesID = 969, name = "Stitch", level = 25, maxHealth = 1546, power = 260, speed = 289, familyType = 4, abilities = { 471, 256, 650 } },
            { speciesID = 968, name = "Mort", level = 25, maxHealth = 1546, power = 289, speed = 260, familyType = 4, abilities = { 654, 442, 212 } },
        },
    },
    [66638] = {
        locations = {
            { mapID = 115, continent = 113, x = 59, y = 77.04 },
        },
        name = "Okrut Dragonwaste",
        questEnds = { 31933 },
        questStarts = { 31933 },
        types = NPC_TYPE.TAMER,
        petOrder = { 973, 972, 971 },
        pets = {
            { speciesID = 973, name = "Drogar", level = 25, maxHealth = 1400, power = 289, speed = 289, familyType = 2, abilities = { 503, 612, 611 } },
            { speciesID = 972, name = "Sleet", level = 25, maxHealth = 1546, power = 260, speed = 289, familyType = 4, abilities = { 782, 206, 624 } },
            { speciesID = 971, name = "Rot", level = 25, maxHealth = 1546, power = 289, speed = 260, familyType = 4, abilities = { 393, 214, 657 } },
        },
    },
    [66639] = {
        locations = {
            { mapID = 121, continent = 113, x = 13.23, y = 66.77 },
        },
        name = "Gutretch",
        questEnds = { 31934 },
        questStarts = { 31934 },
        types = NPC_TYPE.TAMER,
        petOrder = { 976, 975, 974 },
        pets = {
            { speciesID = 976, name = "Cadavus", level = 25, maxHealth = 1546, power = 289, speed = 260, familyType = 8, abilities = { 369, 364, 159 } },
            { speciesID = 975, name = "Fleshrender", level = 25, maxHealth = 1725, power = 260, speed = 260, familyType = 8, abilities = { 160, 369, 364 } },
            { speciesID = 974, name = "Blight", level = 25, maxHealth = 1400, power = 289, speed = 289, familyType = 5, abilities = { 360, 253, 359 } },
        },
    },
    [66675] = {
        locations = {
            { mapID = 118, continent = 113, x = 77.38, y = 19.58 },
        },
        name = "Major Payne",
        questEnds = { 31928, 31935 },
        questStarts = { 31928, 31935, 31983, 31984 },
        types = NPC_TYPE.TAMER,
        petOrder = { 979, 978, 977 },
        pets = {
            { speciesID = 979, name = "Grizzle", level = 25, maxHealth = 1850, power = 280, speed = 280, familyType = 8, abilities = { 247, 348, 124 } },
            { speciesID = 978, name = "Beakmaster X-225", level = 25, maxHealth = 1500, power = 311, speed = 311, familyType = 10, abilities = { 455, 459, 646 } },
            { speciesID = 977, name = "Bloom", level = 25, maxHealth = 1657, power = 280, speed = 311, familyType = 7, abilities = { 394, 396, 400 } },
        },
    },
    [66717] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 371, continent = 424, x = 27.73, y = 46.72 },
        },
        name = "Beast-Haver Chi Chi",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [66730] = {
        locations = {
            { mapID = 371, continent = 424, x = 47.95, y = 54.16 },
        },
        name = "Hyuna of the Shrines",
        questEnds = { 31953 },
        questStarts = { 31953 },
        types = NPC_TYPE.TAMER,
        petOrder = { 994, 993, 992 },
        pets = {
            { speciesID = 994, name = "Skyshaper", level = 25, maxHealth = 1500, power = 311, speed = 467, familyType = 3, abilities = { 632, 420, 270 } },
            { speciesID = 993, name = "Fangor", level = 25, maxHealth = 1500, power = 280, speed = 350, familyType = 8, abilities = { 155, 156, 159 } },
            { speciesID = 992, name = "Dor the Wall", level = 25, maxHealth = 1850, power = 280, speed = 280, familyType = 9, abilities = { 310, 376, 123 } },
        },
    },
    [66733] = {
        locations = {
            { mapID = 418, continent = 424, x = 62.22, y = 45.89 },
        },
        name = "Mo'ruk",
        questEnds = { 31954 },
        questStarts = { 31954 },
        types = NPC_TYPE.TAMER,
        petOrder = { 998, 1000, 999 },
        pets = {
            { speciesID = 998, name = "Woodcarver", level = 25, maxHealth = 1657, power = 280, speed = 311, familyType = 8, abilities = { 160, 369, 159 } },
            { speciesID = 1000, name = "Lightstalker", level = 25, maxHealth = 1500, power = 311, speed = 467, familyType = 3, abilities = { 504, 507, 508 } },
            { speciesID = 999, name = "Needleback", level = 25, maxHealth = 1850, power = 280, speed = 280, familyType = 9, abilities = { 376, 249, 566 } },
        },
    },
    [66734] = {
        locations = {
            { mapID = 376, continent = 424, x = 46.06, y = 43.67 },
        },
        name = "Farmer Nishi",
        questEnds = { 31955 },
        questStarts = { 31955 },
        types = NPC_TYPE.TAMER,
        petOrder = { 997, 996, 995 },
        pets = {
            { speciesID = 997, name = "Siren", level = 25, maxHealth = 1657, power = 311, speed = 280, familyType = 7, abilities = { 268, 404, 753 } },
            { speciesID = 996, name = "Toothbreaker", level = 25, maxHealth = 1850, power = 280, speed = 280, familyType = 7, abilities = { 745, 298, 828 } },
            { speciesID = 995, name = "Brood of Mothallus", level = 25, maxHealth = 1657, power = 280, speed = 311, familyType = 8, abilities = { 160, 369, 159 } },
        },
    },
    [66738] = {
        locations = {
            { mapID = 379, continent = 424, x = 35.84, y = 73.62 },
        },
        name = "Courageous Yon",
        questEnds = { 31956 },
        questStarts = { 31956 },
        types = NPC_TYPE.TAMER,
        petOrder = { 1003, 1002, 1001 },
        pets = {
            { speciesID = 1003, name = "Piqua", level = 25, maxHealth = 1657, power = 280, speed = 467, familyType = 3, abilities = { 524, 170, 581 } },
            { speciesID = 1002, name = "Lapin", level = 25, maxHealth = 1657, power = 280, speed = 311, familyType = 5, abilities = { 360, 162, 159 } },
            { speciesID = 1001, name = "Bleat", level = 25, maxHealth = 1500, power = 311, speed = 311, familyType = 8, abilities = { 541, 539, 163 } },
        },
    },
    [66739] = {
        locations = {
            { mapID = 422, continent = 424, x = 55.09, y = 37.56 },
        },
        name = "Wastewalker Shu",
        questEnds = { 31957 },
        questStarts = { 31957 },
        types = NPC_TYPE.TAMER,
        petOrder = { 1009, 1008, 1007 },
        pets = {
            { speciesID = 1009, name = "Crusher", level = 25, maxHealth = 1657, power = 311, speed = 280, familyType = 9, abilities = { 509, 511, 513 } },
            { speciesID = 1008, name = "Pounder", level = 25, maxHealth = 1850, power = 280, speed = 280, familyType = 7, abilities = { 453, 814, 644 } },
            { speciesID = 1007, name = "Mutilator", level = 25, maxHealth = 1500, power = 350, speed = 280, familyType = 8, abilities = { 315, 158, 566 } },
        },
    },
    [66741] = {
        locations = {
            { mapID = 390, continent = 424, x = 67.56, y = 40.64 },
        },
        name = "Aki the Chosen",
        questEnds = { 31951, 31958 },
        questStarts = { 31958 },
        types = NPC_TYPE.TAMER,
        petOrder = { 1012, 1011, 1010 },
        pets = {
            { speciesID = 1012, name = "Chirrup", level = 25, maxHealth = 1600, power = 300, speed = 375, familyType = 5, abilities = { 706, 573, 298 } },
            { speciesID = 1011, name = "Stormlash", level = 25, maxHealth = 1769, power = 334, speed = 300, familyType = 2, abilities = { 204, 122, 347 } },
            { speciesID = 1010, name = "Whiskers", level = 25, maxHealth = 1600, power = 334, speed = 334, familyType = 9, abilities = { 509, 283, 564 } },
        },
    },
    [66815] = {
        locations = {
            { mapID = 207, continent = 948, x = 49.85, y = 57.04 },
        },
        name = "Bordin Steadyfist",
        questEnds = { 31973 },
        questStarts = { 31973 },
        types = NPC_TYPE.TAMER,
        petOrder = { 985, 984, 983 },
        pets = {
            { speciesID = 985, name = "Ruby", level = 25, maxHealth = 1657, power = 311, speed = 280, familyType = 7, abilities = { 617, 263, 621 } },
            { speciesID = 984, name = "Crystallus", level = 25, maxHealth = 1657, power = 280, speed = 311, familyType = 5, abilities = { 193, 155, 519 } },
            { speciesID = 983, name = "Fracture", level = 25, maxHealth = 1850, power = 280, speed = 280, familyType = 7, abilities = { 484, 488, 606 } },
        },
    },
    [66819] = {
        locations = {
            { mapID = 198, continent = 12, x = 61.34, y = 32.69 },
        },
        name = "Brok",
        questEnds = { 31972 },
        questStarts = { 31972 },
        types = NPC_TYPE.TAMER,
        petOrder = { 982, 981, 980 },
        pets = {
            { speciesID = 982, name = "Kali", level = 25, maxHealth = 1500, power = 280, speed = 350, familyType = 6, abilities = { 461, 463, 299 } },
            { speciesID = 981, name = "Ashtail", level = 25, maxHealth = 1500, power = 311, speed = 311, familyType = 8, abilities = { 563, 355, 253 } },
            { speciesID = 980, name = "Incinderous", level = 25, maxHealth = 1850, power = 280, speed = 280, familyType = 5, abilities = { 119, 706, 283 } },
        },
    },
    [66822] = {
        locations = {
            { mapID = 241, continent = 13, x = 56.58, y = 56.77 },
        },
        name = "Goz Banefury",
        questEnds = { 31974 },
        questStarts = { 31974 },
        types = NPC_TYPE.TAMER,
        petOrder = { 988, 987, 986 },
        pets = {
            { speciesID = 988, name = "Twilight", level = 25, maxHealth = 1500, power = 311, speed = 311, familyType = 7, abilities = { 792, 482, 794 } },
            { speciesID = 987, name = "Amythel", level = 25, maxHealth = 1657, power = 280, speed = 311, familyType = 6, abilities = { 655, 197, 448 } },
            { speciesID = 986, name = "Helios", level = 25, maxHealth = 1500, power = 350, speed = 280, familyType = 8, abilities = { 383, 382, 250 } },
        },
    },
    [66824] = {
        locations = {
            { mapID = 249, continent = 12, x = 56.55, y = 41.98 },
        },
        name = "Obalis",
        questEnds = { 31970, 31971 },
        questStarts = { 31970, 31971, 31985, 31986 },
        types = NPC_TYPE.TAMER,
        petOrder = { 991, 990, 989 },
        pets = {
            { speciesID = 991, name = "Pyth", level = 25, maxHealth = 1500, power = 311, speed = 311, familyType = 8, abilities = { 152, 158, 156 } },
            { speciesID = 990, name = "Spring", level = 25, maxHealth = 1500, power = 280, speed = 525, familyType = 3, abilities = { 420, 506, 508 } },
            { speciesID = 989, name = "Clatter", level = 25, maxHealth = 1657, power = 280, speed = 311, familyType = 5, abilities = { 193, 155, 519 } },
        },
    },
    [66918] = {
        locations = {
            { mapID = 388, continent = 424, x = 36.31, y = 52.18 },
        },
        name = "Seeker Zusshi",
        questEnds = { 31991 },
        questStarts = { 31991 },
        types = NPC_TYPE.TAMER,
        petOrder = { 1006, 1005, 1004 },
        pets = {
            { speciesID = 1006, name = "Diamond", level = 25, maxHealth = 1850, power = 280, speed = 280, familyType = 7, abilities = { 416, 414, 120 } },
            { speciesID = 1005, name = "Mollus", level = 25, maxHealth = 1657, power = 280, speed = 311, familyType = 5, abilities = { 449, 369, 564 } },
            { speciesID = 1004, name = "Skimmer", level = 25, maxHealth = 1657, power = 280, speed = 311, familyType = 9, abilities = { 497, 230, 297 } },
        },
    },
    [67370] = {
        locations = {
            { mapID = 407, continent = 12, x = 47.7, y = 62.64 },
        },
        name = "Jeremy Feasel",
        questEnds = { 32175 },
        questStarts = { 32175 },
        types = NPC_TYPE.TAMER,
        petOrder = { 1065, 1067, 1066 },
        pets = {
            { speciesID = 1065, name = "Judgement", level = 25, maxHealth = 1587, power = 329, speed = 276, familyType = 6, abilities = { 473, 475, 869 } },
            { speciesID = 1067, name = "Honky-Tonk", level = 25, maxHealth = 1745, power = 294, speed = 280, familyType = 10, abilities = { 777, 646, 301 } },
            { speciesID = 1066, name = "Fezwick", level = 25, maxHealth = 1570, power = 311, speed = 294, familyType = 8, abilities = { 349, 350, 352 } },
        },
    },
    [68462] = {
        locations = {
            { mapID = 422, continent = 424, x = 61.12, y = 87.48 },
        },
        name = "Flowing Pandaren Spirit",
        questEnds = { 32439 },
        questStarts = { 32439 },
        types = NPC_TYPE.SPIRIT,
        petOrder = { 1132, 1133, 1138 },
        pets = {
            { speciesID = 1132, name = "Marley", level = 25, maxHealth = 1600, power = 300, speed = 375, familyType = 9, abilities = { 297, 564, 513 } },
            { speciesID = 1133, name = "Tiptoe", level = 25, maxHealth = 1675, power = 334, speed = 315, familyType = 9, abilities = { 118, 123, 419 } },
            { speciesID = 1138, name = "Pandaren Water Spirit", level = 25, maxHealth = 1769, power = 300, speed = 334, familyType = 7, abilities = { 513, 418, 419 } },
        },
    },
    [68463] = {
        locations = {
            { mapID = 388, continent = 424, x = 57.14, y = 42.08 },
        },
        name = "Burning Pandaren Spirit",
        questEnds = { 32434 },
        questStarts = { 32434 },
        types = NPC_TYPE.SPIRIT,
        petOrder = { 1130, 1139, 1131 },
        pets = {
            { speciesID = 1130, name = "Crimson", level = 25, maxHealth = 1600, power = 334, speed = 334, familyType = 2, abilities = { 115, 190, 170 } },
            { speciesID = 1139, name = "Pandaren Fire Spirit", level = 25, maxHealth = 1600, power = 334, speed = 334, familyType = 7, abilities = { 179, 178, 173 } },
            { speciesID = 1131, name = "Glowy", level = 25, maxHealth = 1675, power = 315, speed = 501, familyType = 3, abilities = { 706, 632, 270 } },
        },
    },
    [68464] = {
        locations = {
            { mapID = 371, continent = 424, x = 28.88, y = 36.01 },
        },
        name = "Whispering Pandaren Spirit",
        questEnds = { 32440 },
        questStarts = { 32440 },
        types = NPC_TYPE.SPIRIT,
        petOrder = { 1135, 1136, 1140 },
        pets = {
            { speciesID = 1135, name = "Dusty", level = 25, maxHealth = 1769, power = 315, speed = 473, familyType = 3, abilities = { 507, 508, 506 } },
            { speciesID = 1136, name = "Whispertail", level = 25, maxHealth = 1694, power = 319, speed = 319, familyType = 2, abilities = { 515, 420, 514 } },
            { speciesID = 1140, name = "Pandaren Air Spirit", level = 25, maxHealth = 1694, power = 319, speed = 319, familyType = 7, abilities = { 420, 514, 396 } },
        },
    },
    [68465] = {
        locations = {
            { mapID = 379, continent = 424, x = 64.94, y = 93.77 },
        },
        name = "Thundering Pandaren Spirit",
        questEnds = { 32441 },
        questStarts = { 32441 },
        types = NPC_TYPE.SPIRIT,
        petOrder = { 1141, 1134, 1137 },
        pets = {
            { speciesID = 1141, name = "Pandaren Earth Spirit", level = 25, maxHealth = 1769, power = 334, speed = 300, familyType = 7, abilities = { 814, 569, 801 } },
            { speciesID = 1134, name = "Sludgy", level = 25, maxHealth = 1769, power = 300, speed = 334, familyType = 6, abilities = { 445, 448, 450 } },
            { speciesID = 1137, name = "Darnak the Tunneler", level = 25, maxHealth = 1975, power = 300, speed = 300, familyType = 8, abilities = { 159, 436, 621 } },
        },
    },
    [68555] = {
        locations = {
            { mapID = 371, continent = 424, x = 48.39, y = 70.98 },
        },
        name = "Ka'wi the Gorger",
        types = NPC_TYPE.FABLED,
        petOrder = { 1129 },
        pets = {
            { speciesID = 1129, name = "Ka'wi the Gorger", level = 25, maxHealth = 2020, power = 492, speed = 281, familyType = 5, abilities = { 507, 631, 541 } },
        },
    },
    [68558] = {
        locations = {
            { mapID = 422, continent = 424, x = 26.16, y = 50.29 },
        },
        name = "Gorespine",
        types = NPC_TYPE.FABLED,
        petOrder = { 1187 },
        pets = {
            { speciesID = 1187, name = "Gorespine", level = 24, maxHealth = 1826, power = 500, speed = 275, familyType = 8, abilities = { 315, 119, 803 } },
        },
    },
    [68559] = {
        locations = {
            { mapID = 390, continent = 424, x = 10.98, y = 70.39 },
            { mapID = 390, continent = 424, x = 10.98, y = 70.59 },
        },
        name = "No-No",
        types = NPC_TYPE.FABLED,
        petOrder = { 1188 },
        pets = {
            { speciesID = 1188, name = "No-No", level = 25, maxHealth = 1938, power = 469, speed = 309, familyType = 9, abilities = { 424, 564, 325 } },
        },
    },
    [68560] = {
        locations = {
            { mapID = 376, continent = 424, x = 25.18, y = 78.39 },
            { mapID = 376, continent = 424, x = 25.18, y = 78.58 },
        },
        name = "Greyhoof",
        types = NPC_TYPE.FABLED,
        petOrder = { 1189 },
        pets = {
            { speciesID = 1189, name = "Greyhoof", level = 24, maxHealth = 1919, power = 442, speed = 281, familyType = 8, abilities = { 377, 493, 347 } },
        },
    },
    [68561] = {
        locations = {
            { mapID = 376, continent = 424, x = 40.51, y = 43.64 },
        },
        name = "Lucky Yi",
        types = NPC_TYPE.FABLED,
        petOrder = { 1190 },
        pets = {
            { speciesID = 1190, name = "Lucky Yi", level = 25, maxHealth = 1883, power = 440, speed = 329, familyType = 5, abilities = { 563, 576, 252 } },
        },
    },
    [68562] = {
        locations = {
            { mapID = 388, continent = 424, x = 72.18, y = 79.78 },
        },
        name = "Ti'un the Wanderer",
        types = NPC_TYPE.FABLED,
        petOrder = { 1191 },
        pets = {
            { speciesID = 1191, name = "Ti'un the Wanderer", level = 24, maxHealth = 2182, power = 454, speed = 252, familyType = 9, abilities = { 419, 297, 310 } },
        },
    },
    [68563] = {
        locations = {
            { mapID = 379, continent = 424, x = 35.18, y = 55.99 },
        },
        name = "Kafi",
        types = NPC_TYPE.FABLED,
        petOrder = { 1192 },
        pets = {
            { speciesID = 1192, name = "Kafi", level = 25, maxHealth = 1961, power = 477, speed = 292, familyType = 8, abilities = { 412, 376, 364 } },
        },
    },
    [68564] = {
        locations = {
            { mapID = 379, continent = 424, x = 67.85, y = 84.67 },
        },
        name = "Dos-Ryga",
        types = NPC_TYPE.FABLED,
        petOrder = { 1193 },
        pets = {
            { speciesID = 1193, name = "Dos-Ryga", level = 24, maxHealth = 1868, power = 429, speed = 284, familyType = 9, abilities = { 782, 513, 123 } },
        },
    },
    [68565] = {
        locations = {
            { mapID = 371, continent = 424, x = 57.02, y = 29.12 },
        },
        name = "Nitun",
        types = NPC_TYPE.FABLED,
        petOrder = { 1194 },
        pets = {
            { speciesID = 1194, name = "Nitun", level = 25, maxHealth = 1840, power = 485, speed = 329, familyType = 5, abilities = { 492, 536, 802 } },
        },
    },
    [68566] = {
        locations = {
            { mapID = 418, continent = 424, x = 36.19, y = 37.19 },
        },
        name = "Skitterer Xi'a",
        types = NPC_TYPE.FABLED,
        petOrder = { 1195 },
        pets = {
            { speciesID = 1195, name = "Skitterer Xi'a", level = 25, maxHealth = 1801, power = 450, speed = 375, familyType = 9, abilities = { 626, 118, 360 } },
        },
    },
    [69252] = {
        faction = FACTION.HORDE,
        locations = {
            { mapID = 504, continent = 424, x = 32.84, y = 32.47 },
        },
        name = "Ranger Shalan",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [70184] = {
        faction = FACTION.ALLIANCE,
        locations = {
            { mapID = 504, continent = 424, x = 63.25, y = 73.96 },
        },
        name = "Tassia Whisperglen",
        types = NPC_TYPE.STABLE_MASTER,
    },
    [73082] = {
        locations = {
            { mapID = 554, continent = 424, x = 34.79, y = 59.39 },
            { mapID = 554, continent = 424, x = 34.79, y = 59.58 },
        },
        name = "Master Li",
        questEnds = { 33136, 33137 },
        questStarts = { 33136, 33137 },
        types = NPC_TYPE.VENDOR,
    },
    [73819] = {
        locations = {
            { mapID = 554, continent = 424, x = 41.2, y = 63.4 },
            { mapID = 554, continent = 424, x = 41.2, y = 63.59 },
        },
        name = "Ku-Mo",
        types = NPC_TYPE.VENDOR,
    },
    [73307] = {
        -- Sells Vengeful Porcupette for 100 Bloody Coins
        -- Not in Questie item DB - manual entry required
        locations = {
            { mapID = 554, continent = 424 },
        },
        name = "Speaker Gulan",
        types = NPC_TYPE.VENDOR,
    },
}

Addon.data = Addon.data or {}
Addon.data.npcs = NPC_DB

-- Classification rules for entityDetector (priority-ordered, highest first)
-- Used only for detection - title patterns determine NPC type, then discarded
local CLASSIFICATION_RULES = {
    {
        flag = NPC_TYPE.SPIRIT,
        priority = 10,
        needsPets = true,
        rules = {
            keywords = {"pandaren spirit"},
            titles = {}
        }
    },
    {
        flag = NPC_TYPE.TAMER,
        priority = 5,
        needsPets = true,
        rules = {
            keywords = {},
            titles = {
                "grand master pet tamer",
                "master pet tamer",
                "pet tamer",
                "aspiring pet tamer",
            }
        }
    },
    {
        flag = NPC_TYPE.TRAINER,
        priority = 3,
        needsPets = false,
        rules = {
            keywords = {},
            titles = {
                "battle pet trainer",
            }
        }
    },
    -- Fabled beasts have no pre-classification rules; detected by pet count during battle
}

-- Register module
if Addon.registerModule then
    Addon.registerModule("npcs", {"entityDetector", "dataStore"}, function()
        -- Register unified NPC entity type with dataStore
        if Addon.dataStore then
            Addon.dataStore:registerEntityType({
                typeName = "npc",
                svName = "pao_npc",
                staticKey = "npcs"
            })
        else
            Addon.utils:error("npcs: dataStore not available")
            return false
        end

        -- Register classification rules with entityDetector
        if Addon.entityDetector then
            for _, rule in ipairs(CLASSIFICATION_RULES) do
                Addon.entityDetector:registerClassification(rule)
            end
        else
            Addon.utils:error("npcs: entityDetector not available")
            return false
        end

        return true
    end)
end

-- Register SavedVariable for export
if Addon.registerModule then
    Addon.registerModule("npcs_export", {"exports"}, function()
        if Addon.exports then
            Addon.exports:register("npcs", function()
                return pao_npc
            end)
        end
        return true
    end)
end

return NPC_DB