--[[
  data/sourceOverrides.lua
  Corrections to pet source data from Blizzard API
  
  All overrides keyed by speciesID. Applied before rendering source tooltips.
  
  Override fields:
    zoneCorrections = {["BadName"] = "GoodName"} - zone name fixes
    textCorrections = {["BadText"] = "GoodText"} - sourceText typo fixes
    sourceType = "vendor" | "drop" | "petBattle" - force source type
    vendorEntries = {{name, zone, cost, faction}, ...} - override vendor data
      faction field is optional: "Alliance" or "Horde" to show only for that faction
    worldEvent = "Event Name" - add event requirement
    notes = "string" - supplementary note rendered after source content (e.g., BMAH)
    achievementGate = "Achievement Name" - achievement required before vendor purchase
    guildReputation = "Revered" | "Honored" | ... - guild rep required for vendor purchase
    
  Dependencies: none (pure data)
  Exports: Addon.data.sourceOverrides
]]

local ADDON_NAME, Addon = ...

Addon.data = Addon.data or {}

-- Shared note strings
local BMAH_NOTE = "Occasionally appears on the Black Market Auction House."

Addon.data.sourceOverrides = {
  -- ============================================================================
  -- ZONE NAME CORRECTIONS
  -- ============================================================================
  
  -- Garden Moth: API returns "Jade Forest" without "The"
  [753] = {
    zoneCorrections = {
      ["Jade Forest"] = "The Jade Forest",
    },
  },
  
  -- Calico Cat (and other Breanni pets): API returns "Crystalsong Forest" 
  -- but Breanni is in Dalaran (which floats above Crystalsong)
  [224] = {
    zoneCorrections = {
      ["Crystalsong Forest"] = "Dalaran",
    },
  },
  
  -- TODO: Find speciesID for pet with "Valley of Four Winds"
  -- [???] = {
  --   zoneCorrections = {
  --     ["Valley of Four Winds"] = "Valley of the Four Winds",
  --   },
  -- },
  
  -- ============================================================================
  -- VENDOR DATA CORRECTIONS
  -- ============================================================================
  
  -- Orange Tabby Cat: API erroneously lists Steven Lisbane (pet tamer, not vendor)
  [43] = {
    vendorEntries = {
      {name = "Donni Anthania", zone = "Elwynn Forest", cost = "40 silver"},
    },
  },
  
  -- ============================================================================
  -- EVENT VENDOR ZONE CORRECTIONS
  -- Event vendors appear in all faction capitals but API provides no zone.
  -- Use special zone marker; renderer expands to current faction's capitals.
  -- ============================================================================
  
  -- Spirit of Summer: Midsummer Merchant in faction capitals
  [128] = {
    vendorEntries = {
      {name = "Midsummer Merchant", zone = "__faction_capitals__", cost = "350 Burning Blossom"},
    },
    worldEvent = "Midsummer Fire Festival",
  },
  
  -- Spring Rabbit: Noblegarden Merchant in faction capitals
  [200] = {
    vendorEntries = {
      {name = "Noblegarden Merchant", zone = "__faction_capitals__", cost = "100 Noblegarden Chocolate"},
    },
    worldEvent = "Noblegarden",
  },
  
  -- Peddlefeet: Lovely Merchant in faction capitals
  [122] = {
    vendorEntries = {
      {name = "Lovely Merchant", zone = "__faction_capitals__", cost = "40 Love Token"},
    },
    worldEvent = "Love is in the Air",
  },
  
  -- ============================================================================
  -- FULL DATA OVERRIDES
  -- ============================================================================
  
  -- Blue Clockwork Rocket Bot: API says "World Vendors" with no actual names
  [254] = {
    vendorEntries = {
      {name = "Craggle Wobbletop", zone = "Stormwind", cost = "50 gold"},
      {name = "Blax Bottlerocket", zone = "Orgrimmar", cost = "50 gold"},
      {name = "Jepetto Joybuzz", zone = "Dalaran", cost = "50 gold"},
      {name = "Clockwork Assistant", zone = "Dalaran", cost = "50 gold"},
    },
  },
  
  -- ============================================================================
  -- ACHIEVEMENT-GATED VENDOR PETS
  -- Guild vendor pets that require a guild achievement (and sometimes guild rep)
  -- before they appear for purchase. Blizzard's sourceText omits these gates.
  -- ============================================================================
  
  -- Dark Phoenix Hatchling: United Nations guild achievement + Revered
  [270] = {
    achievementGate = "United Nations",
    guildReputation = "Revered",
  },
  
  -- Armadillo Pup: Critter Kill Squad guild achievement + Revered
  [272] = {
    achievementGate = "Critter Kill Squad",
    guildReputation = "Revered",
  },
  
  -- Guild Page (Alliance): Horde Slayer guild achievement + Honored
  [280] = {
    achievementGate = "Horde Slayer",
    guildReputation = "Honored",
  },
  
  -- Guild Page (Horde): Alliance Slayer guild achievement + Honored
  [281] = {
    achievementGate = "Alliance Slayer",
    guildReputation = "Honored",
  },
  
  -- Guild Herald (Alliance): Profit Sharing guild achievement + Revered
  [282] = {
    achievementGate = "Profit Sharing",
    guildReputation = "Revered",
  },
  
  -- Guild Herald (Horde): Profit Sharing guild achievement + Revered
  [283] = {
    achievementGate = "Profit Sharing",
    guildReputation = "Revered",
  },
  
  -- Lil' Tarecgosa: Dragonwrath guild edition achievement
  [320] = {
    achievementGate = "Dragonwrath, Tarecgosa's Rest - Guild Edition",
  },
  
  -- Thundering Serpent Hatchling: Challenge Conquerors Gold guild edition
  [802] = {
    achievementGate = "Challenge Conquerors: Gold - Guild Edition",
  },
  
  -- ============================================================================
  -- TRADING CARD GAME OVERRIDES
  -- ============================================================================
  
  -- Eye of the Legion: Blizzard misspells "Ancients" as "Anicents"
  -- Also available from Platinum Coin vendors (Challenge Mode Season 2)
  [348] = {
    textCorrections = {
      ["Anicents"] = "Ancients",
    },
    vendorEntries = {
      {name = "Jaelof Ironhart", zone = "Shrine of Seven Stars", cost = "15 Platinum Coin", faction = "Alliance"},
      {name = "Viktor Felhallow", zone = "Shrine of Two Moons", cost = "15 Platinum Coin", faction = "Horde"},
    },
  },
  
  -- Bananas: TCG pet also available on BMAH
  [156] = {
    notes = BMAH_NOTE,
  },
  
  -- Rocket Chicken: TCG pet also available on BMAH
  [168] = {
    notes = BMAH_NOTE,
  },
  
  -- ============================================================================
  -- BLACK MARKET AUCTION HOUSE AVAILABILITY
  -- Pets whose primary source is NOT TCG but appear on the BMAH.
  -- ============================================================================
  
  -- Bombay Cat
  [40] = {
    notes = BMAH_NOTE,
  },
  
  -- Green Wing Macaw
  [50] = {
    notes = BMAH_NOTE,
  },
  
  -- Dark Whelpling
  [56] = {
    notes = BMAH_NOTE,
  },
  
  -- Azure Whelpling
  [57] = {
    notes = BMAH_NOTE,
  },
  
  -- Emerald Whelpling
  [59] = {
    notes = BMAH_NOTE,
  },
  
  -- Disgusting Oozeling
  [114] = {
    notes = BMAH_NOTE,
  },
  
  -- Firefly
  [146] = {
    notes = BMAH_NOTE,
  },
  
  -- Phoenix Hatchling
  [175] = {
    notes = BMAH_NOTE,
  },
  
  -- Giant Sewer Rat
  [193] = {
    notes = BMAH_NOTE,
  },
  
  -- Proto-Drake Whelp
  [196] = {
    notes = BMAH_NOTE,
  },
  
  -- Tirisfal Batling
  [206] = {
    notes = BMAH_NOTE,
  },
  
  -- Elwynn Lamb
  [209] = {
    notes = BMAH_NOTE,
  },
  
  -- Mechanopeep
  [215] = {
    notes = BMAH_NOTE,
  },
  
  -- Sen'jin Fetish
  [218] = {
    notes = BMAH_NOTE,
  },
  
  -- Shimmering Wyrmling
  [229] = {
    notes = BMAH_NOTE,
  },
  
  -- Gundrak Hatchling
  [234] = {
    notes = BMAH_NOTE,
  },
  
  -- Obsidian Hatchling
  [236] = {
    notes = BMAH_NOTE,
  },
  
  -- ============================================================================
  -- QUEST SOURCE DATA
  -- Curated from alexkulya/pandaria_5.4.8 world database.
  -- Only data that cannot be obtained at runtime from Questie or the WoW API.
  --   questId        - quest ID (or {id, id} for faction variants)
  --   dailyQuestId   - daily quest that also awards this pet via bag
  --   randomDrop     - true if pet is a chance drop from a reward bag
  --   bagName        - name of the reward bag (when randomDrop)
  -- ============================================================================
  
  -- Mechanical Chicken
  [83] = { questData = { questId = 3721 } },
  -- Sprite Darter Egg
  [87] = { questData = { questId = 4298 } },
  -- Worg Carrier
  [89] = { questData = { questId = 4729 } },
  -- Smolderweb Carrier
  [90] = { questData = { questId = 4862 } },
  -- Miniwing
  [149] = { questData = { questId = 10898 } },
  -- Argent Squire (Alliance) / Argent Gruntling (Horde)
  [214] = { questData = { questId = {13702, 13732, 13733, 13734, 13735} } },
  [216] = { questData = { questId = {13736, 13737, 13738, 13739, 13740} } },
  -- Withers
  [220] = { questData = { questId = 13570 } },
  -- Blue Mini Jouster
  [259] = { questData = { questId = 25560 } },
  -- Gold Mini Jouster
  [260] = { questData = { questId = 25560 } },
  -- Tiny Flamefly (faction variants)
  [287] = { questData = { questId = {28415, 28491} } },
  -- Singing Sunflower
  [291] = { questData = { questId = 28748 } },
  -- Panther Cub (faction variants)
  [301] = { questData = { questId = {29267, 29268} } },
  -- Lashtail Hatchling
  [307] = { questData = { questId = 29208 } },
  -- Alliance Balloon
  [331] = { questData = { questId = 29412 } },
  -- Horde Balloon
  [332] = { questData = { questId = 29401 } },
  -- Fishy (faction variants)
  [847] = { questData = { questId = {29905, 29938, 31239} } },
  -- Pandaren Fire Spirit (Burning Pandaren Spirit, daily 32434)
  [1124] = { questData = {
    questId = 32428,
    dailyQuestId = 32434,
    randomDrop = true,
    bagName = "Pandaren Spirit Pet Supplies",
  }},
  -- Pandaren Water Spirit (Flowing Pandaren Spirit, daily 32439)
  [868] = { questData = {
    questId = 32428,
    dailyQuestId = 32439,
    randomDrop = true,
    bagName = "Pandaren Spirit Pet Supplies",
  }},
  -- Pandaren Air Spirit (Whispering Pandaren Spirit, daily 32440)
  [1125] = { questData = {
    questId = 32428,
    dailyQuestId = 32440,
    randomDrop = true,
    bagName = "Pandaren Spirit Pet Supplies",
  }},
  -- Pandaren Earth Spirit (Thundering Pandaren Spirit, daily 32441)
  [1126] = { questData = {
    questId = 32428,
    dailyQuestId = 32441,
    randomDrop = true,
    bagName = "Pandaren Spirit Pet Supplies",
  }},
  -- Red Panda
  [1176] = { questData = { questId = 32603 } },
  -- Spectral Porcupette
  [1185] = { questData = { questId = 32616 } },
  -- Rotten Little Helper (random from Stolen Present, faction variant dailies)
  [1349] = { questData = {
    questId = {7043, 6983},
    randomDrop = true,
    bagName = "Stolen Present",
  }},
  
  -- Sunfur Panda (random from Fabled Pandaren Pet Supplies, Beasts of Fable dailies)
  [1196] = { questData = {
    questId = {32604, 32868, 32869},
    showAllQuestNames = true,
    randomDrop = true,
    bagName = "Fabled Pandaren Pet Supplies",
  }},
  -- Snowy Panda (random from Fabled Pandaren Pet Supplies, Beasts of Fable dailies)
  [1197] = { questData = {
    questId = {32604, 32868, 32869},
    showAllQuestNames = true,
    randomDrop = true,
    bagName = "Fabled Pandaren Pet Supplies",
  }},
  -- Mountain Panda (random from Fabled Pandaren Pet Supplies, Beasts of Fable dailies)
  [1198] = { questData = {
    questId = {32604, 32868, 32869},
    showAllQuestNames = true,
    randomDrop = true,
    bagName = "Fabled Pandaren Pet Supplies",
  }},
  -- TODO: Red Cricket — Tillers Best Friend with Sho, not a quest reward
  -- Red Cricket: reach Best Friend with Sho (NPC 58708) in Valley of the Four Winds
  [1042] = {
    textCorrections = {
      ["Sho, Requires Exalted Friendship Faction"] = "Sho",
    },
    questData = {
      factionRequirement = {
        npc = 58708,           -- Sho
        standing = "Best Friend",
        faction = "Sho (Tillers)",
      },
    },
  },
  -- Westfall Chicken: spam /chicken at any chicken critter until it offers the quest.
  -- Navigate to the feed vendor — chickens are plentiful nearby.
  [84] = {
    notes = {
      "Spam /chicken at nearby critter chickens until one says 'Chicken looks up at you quizzically.'",
      "Note: battle pet chickens will not offer the quest.",
      "Accept the quest, buy Special Chicken Feed from this vendor if you haven't already, then turn in. Interact with the egg on the ground to receive [Chicken Egg], then use it to summon the pet.",
    },
    questData = {
      vendorNpcs = {
        {npcId = 233,   faction = "Alliance"},  -- Farmer Saldean, Westfall
        {npcId = 33996, faction = "Horde"},     -- William Saldean, Tirisfal Glades
      },
    },
  },
}

return Addon.data.sourceOverrides