--[[
  data/instances.lua
  Instance Data (Dungeons & Raids)
  
  Maps instance zone names to continent and level range, mirroring the
  structure of data/zones.lua for outdoor zones. Keys match the Zone:
  field from C_PetJournal sourceText (e.g., "Throne of Thunder").
  
  Structure: { continent = continentID, levelRange = {min, max}, instanceType = "dungeon"|"raid", players = "5"|"10"|"20"|"25"|"40"|"10/25" }
  
  Dependencies: none (pure data)
  Exports: Addon.data.instances
]]

local ADDON_NAME, Addon = ...

if not Addon.data then Addon.data = {} end

Addon.data.instances = {

  -- ========================================================================
  -- CLASSIC DUNGEONS
  -- ========================================================================

  ["Ragefire Chasm"]         = { continent = 12,          levelRange = {13, 18},  instanceType = "dungeon", players = "5" },
  ["Wailing Caverns"]        = { continent = 12,          levelRange = {15, 25},  instanceType = "dungeon", players = "5" },
  ["The Deadmines"]          = { continent = 13,  levelRange = {15, 21},  instanceType = "dungeon", players = "5" },
  ["Deadmines"]              = { continent = 13,  levelRange = {15, 21},  instanceType = "dungeon", players = "5" },
  ["Shadowfang Keep"]        = { continent = 13,  levelRange = {22, 30},  instanceType = "dungeon", players = "5" },
  ["The Stockade"]           = { continent = 13,  levelRange = {22, 30},  instanceType = "dungeon", players = "5" },
  ["Stormwind Stockade"]     = { continent = 13,  levelRange = {22, 30},  instanceType = "dungeon", players = "5" },
  ["Blackfathom Deeps"]      = { continent = 12,          levelRange = {24, 32},  instanceType = "dungeon", players = "5" },
  ["Gnomeregan"]             = { continent = 13,  levelRange = {29, 38},  instanceType = "dungeon", players = "5" },
  ["Razorfen Kraul"]         = { continent = 12,          levelRange = {30, 40},  instanceType = "dungeon", players = "5" },
  ["Scarlet Monastery"]      = { continent = 13,  levelRange = {28, 42},  instanceType = "dungeon", players = "5" },
  ["Scarlet Halls"]          = { continent = 13,  levelRange = {28, 42},  instanceType = "dungeon", players = "5" },
  ["Razorfen Downs"]         = { continent = 12,          levelRange = {40, 50},  instanceType = "dungeon", players = "5" },
  ["Uldaman"]                = { continent = 13,  levelRange = {42, 52},  instanceType = "dungeon", players = "5" },
  ["Zul'Farrak"]             = { continent = 12,          levelRange = {44, 54},  instanceType = "dungeon", players = "5" },
  ["Maraudon"]               = { continent = 12,          levelRange = {46, 55},  instanceType = "dungeon", players = "5" },
  ["Temple of Atal'Hakkar"]  = { continent = 13,  levelRange = {50, 60},  instanceType = "dungeon", players = "5" },
  ["Sunken Temple"]          = { continent = 13,  levelRange = {50, 60},  instanceType = "dungeon", players = "5" },
  ["Blackrock Depths"]       = { continent = 13,  levelRange = {52, 60},  instanceType = "dungeon", players = "5" },
  ["Lower Blackrock Spire"]  = { continent = 13,  levelRange = {55, 60},  instanceType = "dungeon", players = "5" },
  ["Upper Blackrock Spire"]  = { continent = 13,  levelRange = {55, 60},  instanceType = "dungeon", players = "5" },
  ["Dire Maul"]              = { continent = 12,          levelRange = {55, 60},  instanceType = "dungeon", players = "5" },
  ["Stratholme"]             = { continent = 13,  levelRange = {58, 60},  instanceType = "dungeon", players = "5" },
  ["Scholomance"]            = { continent = 13,  levelRange = {58, 60},  instanceType = "dungeon", players = "5" },

  -- ========================================================================
  -- CLASSIC RAIDS
  -- ========================================================================

  ["Molten Core"]                = { continent = 13,  levelRange = {60, 60},  instanceType = "raid", players = "40" },
  ["Blackwing Lair"]             = { continent = 13,  levelRange = {60, 60},  instanceType = "raid", players = "40" },
  ["Ruins of Ahn'Qiraj"]        = { continent = 12,          levelRange = {60, 60},  instanceType = "raid", players = "20" },
  ["Temple of Ahn'Qiraj"]       = { continent = 12,          levelRange = {60, 60},  instanceType = "raid", players = "40" },
  ["Ahn'Qiraj"]                 = { continent = 12,          levelRange = {60, 60},  instanceType = "raid", players = "40" },
  ["Onyxia's Lair"]             = { continent = 12,          levelRange = {60, 60},  instanceType = "raid", players = "40" },

  -- ========================================================================
  -- TBC DUNGEONS
  -- ========================================================================

  ["Hellfire Ramparts"]      = { continent = 1467,  levelRange = {60, 62},  instanceType = "dungeon", players = "5" },
  ["The Blood Furnace"]      = { continent = 1467,  levelRange = {61, 63},  instanceType = "dungeon", players = "5" },
  ["Blood Furnace"]          = { continent = 1467,  levelRange = {61, 63},  instanceType = "dungeon", players = "5" },
  ["The Slave Pens"]         = { continent = 1467,  levelRange = {62, 64},  instanceType = "dungeon", players = "5" },
  ["Slave Pens"]             = { continent = 1467,  levelRange = {62, 64},  instanceType = "dungeon", players = "5" },
  ["The Underbog"]           = { continent = 1467,  levelRange = {63, 65},  instanceType = "dungeon", players = "5" },
  ["Underbog"]               = { continent = 1467,  levelRange = {63, 65},  instanceType = "dungeon", players = "5" },
  ["Mana-Tombs"]             = { continent = 1467,  levelRange = {64, 66},  instanceType = "dungeon", players = "5" },
  ["Auchenai Crypts"]        = { continent = 1467,  levelRange = {65, 67},  instanceType = "dungeon", players = "5" },
  ["Sethekk Halls"]          = { continent = 1467,  levelRange = {67, 69},  instanceType = "dungeon", players = "5" },
  ["Shadow Labyrinth"]       = { continent = 1467,  levelRange = {70, 70},  instanceType = "dungeon", players = "5" },
  ["The Mechanar"]           = { continent = 1467,  levelRange = {69, 70},  instanceType = "dungeon", players = "5" },
  ["Mechanar"]               = { continent = 1467,  levelRange = {69, 70},  instanceType = "dungeon", players = "5" },
  ["The Botanica"]           = { continent = 1467,  levelRange = {70, 70},  instanceType = "dungeon", players = "5" },
  ["Botanica"]               = { continent = 1467,  levelRange = {70, 70},  instanceType = "dungeon", players = "5" },
  ["The Arcatraz"]           = { continent = 1467,  levelRange = {70, 70},  instanceType = "dungeon", players = "5" },
  ["Arcatraz"]               = { continent = 1467,  levelRange = {70, 70},  instanceType = "dungeon", players = "5" },
  ["Old Hillsbrad Foothills"] = { continent = 1467, levelRange = {66, 68},  instanceType = "dungeon", players = "5" },
  ["The Black Morass"]       = { continent = 1467,  levelRange = {70, 70},  instanceType = "dungeon", players = "5" },
  ["Black Morass"]           = { continent = 1467,  levelRange = {70, 70},  instanceType = "dungeon", players = "5" },
  ["The Shattered Halls"]    = { continent = 1467,  levelRange = {70, 70},  instanceType = "dungeon", players = "5" },
  ["Shattered Halls"]        = { continent = 1467,  levelRange = {70, 70},  instanceType = "dungeon", players = "5" },
  ["The Steamvault"]         = { continent = 1467,  levelRange = {70, 70},  instanceType = "dungeon", players = "5" },
  ["Steamvault"]             = { continent = 1467,  levelRange = {70, 70},  instanceType = "dungeon", players = "5" },
  ["Magisters' Terrace"]     = { continent = 13,  levelRange = {70, 70},  instanceType = "dungeon", players = "5" },

  -- ========================================================================
  -- TBC RAIDS
  -- ========================================================================

  ["Karazhan"]               = { continent = 13,  levelRange = {70, 70},  instanceType = "raid", players = "10" },
  ["Gruul's Lair"]           = { continent = 1467,           levelRange = {70, 70},  instanceType = "raid", players = "25" },
  ["Magtheridon's Lair"]     = { continent = 1467,           levelRange = {70, 70},  instanceType = "raid", players = "25" },
  ["Serpentshrine Cavern"]   = { continent = 1467,           levelRange = {70, 70},  instanceType = "raid", players = "25" },
  ["Tempest Keep"]           = { continent = 1467,           levelRange = {70, 70},  instanceType = "raid", players = "25" },
  ["The Eye"]                = { continent = 1467,           levelRange = {70, 70},  instanceType = "raid", players = "25" },
  ["Hyjal Summit"]           = { continent = 12,          levelRange = {70, 70},  instanceType = "raid", players = "25" },
  ["Black Temple"]           = { continent = 1467,           levelRange = {70, 70},  instanceType = "raid", players = "25" },
  ["Sunwell Plateau"]        = { continent = 13,  levelRange = {70, 70},  instanceType = "raid", players = "25" },
  ["Zul'Aman"]               = { continent = 13,  levelRange = {70, 70},  instanceType = "raid", players = "10" },

  -- ========================================================================
  -- WOTLK DUNGEONS
  -- ========================================================================

  ["Utgarde Keep"]                  = { continent = 113,  levelRange = {70, 72},  instanceType = "dungeon", players = "5" },
  ["The Nexus"]                     = { continent = 113,  levelRange = {71, 73},  instanceType = "dungeon", players = "5" },
  ["Nexus"]                         = { continent = 113,  levelRange = {71, 73},  instanceType = "dungeon", players = "5" },
  ["Azjol-Nerub"]                   = { continent = 113,  levelRange = {72, 74},  instanceType = "dungeon", players = "5" },
  ["Ahn'kahet: The Old Kingdom"]    = { continent = 113,  levelRange = {73, 75},  instanceType = "dungeon", players = "5" },
  ["Old Kingdom"]                   = { continent = 113,  levelRange = {73, 75},  instanceType = "dungeon", players = "5" },
  ["Drak'Tharon Keep"]              = { continent = 113,  levelRange = {74, 76},  instanceType = "dungeon", players = "5" },
  ["The Violet Hold"]               = { continent = 113,  levelRange = {75, 77},  instanceType = "dungeon", players = "5" },
  ["Violet Hold"]                   = { continent = 113,  levelRange = {75, 77},  instanceType = "dungeon", players = "5" },
  ["Gundrak"]                       = { continent = 113,  levelRange = {76, 78},  instanceType = "dungeon", players = "5" },
  ["Halls of Stone"]                = { continent = 113,  levelRange = {77, 79},  instanceType = "dungeon", players = "5" },
  ["Halls of Lightning"]            = { continent = 113,  levelRange = {80, 80},  instanceType = "dungeon", players = "5" },
  ["The Oculus"]                    = { continent = 113,  levelRange = {80, 80},  instanceType = "dungeon", players = "5" },
  ["Oculus"]                        = { continent = 113,  levelRange = {80, 80},  instanceType = "dungeon", players = "5" },
  ["Utgarde Pinnacle"]              = { continent = 113,  levelRange = {80, 80},  instanceType = "dungeon", players = "5" },
  ["The Culling of Stratholme"]     = { continent = 113,  levelRange = {80, 80},  instanceType = "dungeon", players = "5" },
  ["Culling of Stratholme"]         = { continent = 113,  levelRange = {80, 80},  instanceType = "dungeon", players = "5" },
  ["Trial of the Champion"]         = { continent = 113,  levelRange = {80, 80},  instanceType = "dungeon", players = "5" },
  ["The Forge of Souls"]            = { continent = 113,  levelRange = {80, 80},  instanceType = "dungeon", players = "5" },
  ["Forge of Souls"]                = { continent = 113,  levelRange = {80, 80},  instanceType = "dungeon", players = "5" },
  ["Pit of Saron"]                  = { continent = 113,  levelRange = {80, 80},  instanceType = "dungeon", players = "5" },
  ["Halls of Reflection"]           = { continent = 113,  levelRange = {80, 80},  instanceType = "dungeon", players = "5" },

  -- ========================================================================
  -- WOTLK RAIDS
  -- ========================================================================

  ["Naxxramas"]              = { continent = 113,  levelRange = {80, 80},  instanceType = "raid", players = "10/25" },
  ["The Obsidian Sanctum"]   = { continent = 113,  levelRange = {80, 80},  instanceType = "raid", players = "10/25" },
  ["Obsidian Sanctum"]       = { continent = 113,  levelRange = {80, 80},  instanceType = "raid", players = "10/25" },
  ["The Eye of Eternity"]    = { continent = 113,  levelRange = {80, 80},  instanceType = "raid", players = "10/25" },
  ["Eye of Eternity"]        = { continent = 113,  levelRange = {80, 80},  instanceType = "raid", players = "10/25" },
  ["Ulduar"]                 = { continent = 113,  levelRange = {80, 80},  instanceType = "raid", players = "10/25" },
  ["Trial of the Crusader"]  = { continent = 113,  levelRange = {80, 80},  instanceType = "raid", players = "10/25" },
  ["Icecrown Citadel"]       = { continent = 113,  levelRange = {80, 80},  instanceType = "raid", players = "10/25" },
  ["Ruby Sanctum"]           = { continent = 113,  levelRange = {80, 80},  instanceType = "raid", players = "10/25" },
  ["Vault of Archavon"]      = { continent = 113,  levelRange = {80, 80},  instanceType = "raid", players = "10/25" },

  -- ========================================================================
  -- CATACLYSM DUNGEONS
  -- ========================================================================

  ["Blackrock Caverns"]      = { continent = 13,  levelRange = {80, 81},  instanceType = "dungeon", players = "5" },
  ["Throne of the Tides"]    = { continent = 13,  levelRange = {80, 81},  instanceType = "dungeon", players = "5" },
  ["The Stonecore"]          = { continent = 13,  levelRange = {82, 84},  instanceType = "dungeon", players = "5" },
  ["Stonecore"]              = { continent = 13,  levelRange = {82, 84},  instanceType = "dungeon", players = "5" },
  ["The Vortex Pinnacle"]    = { continent = 12,          levelRange = {82, 84},  instanceType = "dungeon", players = "5" },
  ["Vortex Pinnacle"]        = { continent = 12,          levelRange = {82, 84},  instanceType = "dungeon", players = "5" },
  ["Lost City of the Tol'vir"] = { continent = 12,       levelRange = {85, 85},  instanceType = "dungeon", players = "5" },
  ["Halls of Origination"]   = { continent = 12,          levelRange = {85, 85},  instanceType = "dungeon", players = "5" },
  ["Grim Batol"]             = { continent = 13,  levelRange = {85, 85},  instanceType = "dungeon", players = "5" },
  ["Zul'Gurub"]              = { continent = 13,  levelRange = {85, 85},  instanceType = "dungeon", players = "5" },
  ["End Time"]               = { continent = 12,          levelRange = {85, 85},  instanceType = "dungeon", players = "5" },
  ["Well of Eternity"]       = { continent = 12,          levelRange = {85, 85},  instanceType = "dungeon", players = "5" },
  ["Hour of Twilight"]       = { continent = 13,  levelRange = {85, 85},  instanceType = "dungeon", players = "5" },

  -- ========================================================================
  -- CATACLYSM RAIDS
  -- ========================================================================

  ["Baradin Hold"]               = { continent = 13,  levelRange = {85, 85},  instanceType = "raid", players = "10/25" },
  ["Blackwing Descent"]          = { continent = 13,  levelRange = {85, 85},  instanceType = "raid", players = "10/25" },
  ["The Bastion of Twilight"]    = { continent = 13,  levelRange = {85, 85},  instanceType = "raid", players = "10/25" },
  ["Bastion of Twilight"]        = { continent = 13,  levelRange = {85, 85},  instanceType = "raid", players = "10/25" },
  ["Throne of the Four Winds"]   = { continent = 12,          levelRange = {85, 85},  instanceType = "raid", players = "10/25" },
  ["Firelands"]                  = { continent = 12,          levelRange = {85, 85},  instanceType = "raid", players = "10/25" },
  ["Dragon Soul"]                = { continent = 12,          levelRange = {85, 85},  instanceType = "raid", players = "10/25" },

  -- ========================================================================
  -- MOP DUNGEONS
  -- ========================================================================

  ["Temple of the Jade Serpent"]  = { continent = 424,          levelRange = {85, 87},  instanceType = "dungeon", players = "5" },
  ["Stormstout Brewery"]          = { continent = 424,          levelRange = {86, 88},  instanceType = "dungeon", players = "5" },
  ["Shado-Pan Monastery"]         = { continent = 424,          levelRange = {87, 89},  instanceType = "dungeon", players = "5" },
  ["Mogu'shan Palace"]            = { continent = 424,          levelRange = {87, 89},  instanceType = "dungeon", players = "5" },
  ["Gate of the Setting Sun"]     = { continent = 424,          levelRange = {88, 90},  instanceType = "dungeon", players = "5" },
  ["Siege of Niuzao Temple"]      = { continent = 424,          levelRange = {88, 90},  instanceType = "dungeon", players = "5" },

  -- ========================================================================
  -- MOP RAIDS
  -- ========================================================================

  ["Mogu'shan Vaults"]        = { continent = 424,  levelRange = {90, 90},  instanceType = "raid", players = "10/25" },
  ["Heart of Fear"]            = { continent = 424,  levelRange = {90, 90},  instanceType = "raid", players = "10/25" },
  ["Terrace of Endless Spring"] = { continent = 424, levelRange = {90, 90},  instanceType = "raid", players = "10/25" },
  ["Throne of Thunder"]        = { continent = 424,  levelRange = {90, 90},  instanceType = "raid", players = "10/25" },
  ["Siege of Orgrimmar"]       = { continent = 424,  levelRange = {90, 90},  instanceType = "raid", players = "10/25" },
}