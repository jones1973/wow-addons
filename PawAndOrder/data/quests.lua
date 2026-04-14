--[[
  data/quests.lua
  Quest Database for Completion Tracking and Feature Unlocking
  
  Stores quest metadata for features that depend on quest completion:
  - Portal unlocks (Cataclysm zones)
  - Pet battle daily/weekly tracking
  - Event-dependent quests
  
  Uses bit fields for type and category to allow quests with multiple classifications
  (e.g., Beasts of Fable = DAILY + ACCOUNT, Darkmoon = DAILY + SPECIAL_EVENT).
  
  Quest IDs sourced from Wowhead and verified against WoW MoP Classic.
  Uses C_QuestLog.IsQuestFlaggedCompleted() for completion checks.
  
  Dependencies: None (pure data)
  Exports: Addon.questDatabase
]]

local addonName, Addon = ...

Addon.questDatabase = {}
local questDB = Addon.questDatabase

-- ========== QUEST TYPE BIT FLAGS ==========
-- Quests can have multiple types (combine with bit.bor)
questDB.TYPE = {
  DAILY       = 0x01,  -- 1   - Resets daily
  ONE_TIME    = 0x02,  -- 2   - Completed once per character
  WEEKLY      = 0x04,  -- 4   - Resets weekly
  ACCOUNT     = 0x08,  -- 8   - Account-wide completion (not per-character)
}

-- ========== QUEST CATEGORY BIT FLAGS ==========
-- Quests can belong to multiple categories (combine with bit.bor)
questDB.CATEGORY = {
  PORTAL_UNLOCK      = 0x01,  -- 1   - Unlocks a portal
  PET_BATTLE         = 0x02,  -- 2   - Pet battle related
  SPECIAL_EVENT      = 0x04,  -- 4   - Tied to calendar events (DMF, etc)
  ACHIEVEMENT        = 0x08,  -- 8   - Achievement prerequisite
}

--[[
  Helper: Check if quest has a specific type flag
  
  @param quest table - Quest data record
  @param typeFlag number - Type bit flag to check
  @return boolean - True if quest has this type
]]
function questDB:hasType(quest, typeFlag)
  return bit.band(quest.type, typeFlag) ~= 0
end

--[[
  Helper: Check if quest has a specific category flag
  
  @param quest table - Quest data record
  @param categoryFlag number - Category bit flag to check
  @return boolean - True if quest has this category
]]
function questDB:hasCategory(quest, categoryFlag)
  return bit.band(quest.category, categoryFlag) ~= 0
end

-- ========== QUEST DATABASE ==========
--[[
  Master quest database
  Each entry contains:
  - id: Quest ID (key)
  - name: Quest name for debugging/reference
  - type: Quest type flags (daily, onetime, weekly, account)
  - category: Category flags (portal_unlock, pet_battle, etc)
  - zone: Associated zone/map name
  - mapID: Optional map ID
  - description: What completing this quest unlocks/enables
  - faction: "Alliance", "Horde", or "both"
  - npcId: Optional associated NPC ID
]]
questDB.QUESTS = {
  
  -- ========== CATACLYSM PORTAL UNLOCKS ==========
  
  [25316] = {
    name = "As Hyjal Burns",
    type = questDB.TYPE.ONE_TIME,
    category = questDB.CATEGORY.PORTAL_UNLOCK,
    zone = "Mount Hyjal",
    mapID = 606,
    description = "Unlocks Stormwind/Orgrimmar portal to Mount Hyjal",
    faction = "both",
  },
  
  [27203] = {
    name = "The Maelstrom",
    type = questDB.TYPE.ONE_TIME,
    category = questDB.CATEGORY.PORTAL_UNLOCK,
    zone = "Deepholm",
    mapID = 640,
    description = "Unlocks Stormwind/Orgrimmar portal to Deepholm",
    faction = "both",
  },
  
  [28112] = {
    name = "Escape From the Lost City",
    type = questDB.TYPE.ONE_TIME,
    category = questDB.CATEGORY.PORTAL_UNLOCK,
    zone = "Uldum",
    mapID = 720,
    description = "Unlocks Stormwind/Orgrimmar portal to Uldum (one-way only)",
    faction = "both",
  },
  
  [27545] = {
    name = "The Way is Open",
    type = questDB.TYPE.ONE_TIME,
    category = questDB.CATEGORY.PORTAL_UNLOCK,
    zone = "Twilight Highlands",
    mapID = 700,
    description = "Unlocks Stormwind portal to Twilight Highlands",
    faction = "Alliance",
  },
  
  [26840] = {
    name = "Return to the Highlands",
    type = questDB.TYPE.ONE_TIME,
    category = questDB.CATEGORY.PORTAL_UNLOCK,
    zone = "Twilight Highlands",
    mapID = 700,
    description = "Unlocks Orgrimmar portal to Twilight Highlands",
    faction = "Horde",
  },
  
  -- ========== BEASTS OF FABLE (DAILY + ACCOUNT-WIDE) ==========
  
  [32604] = {
    name = "Beasts of Fable Book I",
    type = bit.bor(questDB.TYPE.DAILY, questDB.TYPE.ACCOUNT),
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Pandaria",
    description = "Defeat 4 Beasts of Fable: Kawi, Kafi, Dos-Ryga, Nitun",
    faction = "both",
    npcIds = {68555, 68563, 68564, 68565},  -- Kawi, Kafi, Dos-Ryga, Nitun
  },
  
  [32868] = {
    name = "Beasts of Fable Book II",
    type = bit.bor(questDB.TYPE.DAILY, questDB.TYPE.ACCOUNT),
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Pandaria",
    description = "Defeat 3 Beasts of Fable: Greyhoof, Lucky Yi, Skitterer Xi'a",
    faction = "both",
    npcIds = {68560, 68561, 68566},  -- Greyhoof, Lucky Yi, Skitterer Xi'a
  },
  
  [32869] = {
    name = "Beasts of Fable Book III",
    type = bit.bor(questDB.TYPE.DAILY, questDB.TYPE.ACCOUNT),
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Pandaria",
    description = "Defeat 3 Beasts of Fable: Gorespine, No-No, Ti'un",
    faction = "both",
    npcIds = {68558, 68559, 68562},  -- Gorespine, No-No, Ti'un
  },
  
  -- ========== SPIRIT TAMERS (DAILY) ==========
  
  [32434] = {
    name = "Burning Pandaren Spirit",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Townlong Steppes",
    description = "Daily battle with Burning Pandaren Spirit",
    faction = "both",
    npcId = 68463,
  },
  
  [32439] = {
    name = "Flowing Pandaren Spirit",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Dread Wastes",
    description = "Daily battle with Flowing Pandaren Spirit",
    faction = "both",
    npcId = 68462,
  },
  
  [32440] = {
    name = "Whispering Pandaren Spirit",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Jade Forest",
    description = "Daily battle with Whispering Pandaren Spirit",
    faction = "both",
    npcId = 68464,
  },
  
  [32441] = {
    name = "Thundering Pandaren Spirit",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Kun-Lai Summit",
    description = "Daily battle with Thundering Pandaren Spirit",
    faction = "both",
    npcId = 68465,
  },
  
  -- ========== DARKMOON FAIRE (DAILY + SPECIAL EVENT) ==========
  
  [32175] = {
    name = "Darkmoon Pet Battle!",
    type = questDB.TYPE.DAILY,
    category = bit.bor(questDB.CATEGORY.PET_BATTLE, questDB.CATEGORY.SPECIAL_EVENT),
    zone = "Darkmoon Island",
    mapID = 407,
    description = "Daily pet battle with Jeremy Feasel during Darkmoon Faire",
    faction = "both",
    npcId = 67370,
  },
  
  -- ========== GRAND MASTER PET TAMERS (DAILY) ==========
  
  [31916] = {
    name = "Grand Master Lydia Accoste",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Deadwind Pass",
    description = "Daily battle with Grand Master Lydia Accoste (EK)",
    faction = "both",
    npcId = 66522,
  },
  
  [31909] = {
    name = "Grand Master Trixxy",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Winterspring",
    description = "Daily battle with Stonecold Trixxy (Kalimdor)",
    faction = "both",
    npcId = 66466,
  },
  
  [31926] = {
    name = "Grand Master Antari",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Shadowmoon Valley",
    description = "Daily battle with Bloodknight Antari (Outland)",
    faction = "both",
    npcId = 66557,
  },
  
  [31935] = {
    name = "Grand Master Payne",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Icecrown",
    description = "Daily battle with Major Payne (Northrend)",
    faction = "both",
    npcId = 66675,
  },
  
  [31971] = {
    name = "Grand Master Obalis",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Uldum",
    description = "Daily battle with Obalis (Cataclysm)",
    faction = "both",
    npcId = 66824,
  },
  
  [31910] = {
    name = "David Kosse",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "The Hinterlands",
    description = "Daily battle with David Kosse (EK)",
    faction = "both",
    npcId = 66478,
  },
  
  [31911] = {
    name = "Deiza Plaguehorn",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Eastern Plaguelands",
    description = "Daily battle with Deiza Plaguehorn (EK)",
    faction = "both",
    npcId = 66512,
  },
  
  [31912] = {
    name = "Kortas Darkhammer",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Searing Gorge",
    description = "Daily battle with Kortas Darkhammer (EK)",
    faction = "both",
    npcId = 66515,
  },
  
  [31913] = {
    name = "Everessa",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Swamp of Sorrows",
    description = "Daily battle with Everessa (EK)",
    faction = "both",
    npcId = 66518,
  },
  
  [31914] = {
    name = "Durin Darkhammer",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Burning Steppes",
    description = "Daily battle with Durin Darkhammer (EK)",
    faction = "both",
    npcId = 66520,
  },
  
  [31953] = {
    name = "Grand Master Hyuna",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "The Jade Forest",
    description = "Daily battle with Hyuna of the Shrines (Pandaria)",
    faction = "both",
    npcId = 66730,
  },
  
  [31955] = {
    name = "Grand Master Nishi",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Valley of the Four Winds",
    description = "Daily battle with Farmer Nishi (Pandaria)",
    faction = "both",
    npcId = 66734,
  },
  
  [31954] = {
    name = "Grand Master Mo'ruk",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Krasarang Wilds",
    description = "Daily battle with Mo'ruk (Pandaria)",
    faction = "both",
    npcId = 66733,
  },
  
  [31956] = {
    name = "Grand Master Yon",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Kun-Lai Summit",
    description = "Daily battle with Courageous Yon (Pandaria)",
    faction = "both",
    npcId = 66738,
  },
  
  [31991] = {
    name = "Grand Master Zusshi",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Townlong Steppes",
    description = "Daily battle with Seeker Zusshi (Pandaria)",
    faction = "both",
    npcId = 66918,
  },
  
  [31957] = {
    name = "Grand Master Shu",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Dread Wastes",
    description = "Daily battle with Wastewalker Shu (Pandaria)",
    faction = "both",
    npcId = 66739,
  },
  
  [31958] = {
    name = "Grand Master Aki",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Vale of Eternal Blossoms",
    description = "Daily battle with Aki the Chosen (Pandaria)",
    faction = "both",
    npcId = 66741,
  },
  
  [31922] = {
    name = "Nicki Tinytech",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Hellfire Peninsula",
    description = "Daily battle with Nicki Tinytech (Outland)",
    faction = "both",
    npcId = 66550,
  },
  
  [31923] = {
    name = "Ras'an",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Zangarmarsh",
    description = "Daily battle with Ras'an (Outland)",
    faction = "both",
    npcId = 66551,
  },
  
  [31924] = {
    name = "Narrok",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Nagrand",
    description = "Daily battle with Narrok (Outland)",
    faction = "both",
    npcId = 66552,
  },
  
  [31925] = {
    name = "Morulu the Elder",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Shattrath City",
    description = "Daily battle with Morulu the Elder (Outland)",
    faction = "both",
    npcId = 66553,
  },
  
  [31854] = {
    name = "Analynn",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Ashenvale",
    description = "Daily battle with Analynn (Kalimdor)",
    faction = "Horde",
    npcId = 66136,
  },
  
  [31905] = {
    name = "Grazzle the Great",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Dustwallow Marsh",
    description = "Daily battle with Grazzle the Great (Kalimdor)",
    faction = "both",
    npcId = 66436,
  },
  
  [31906] = {
    name = "Kela Grimtotem",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Thousand Needles",
    description = "Daily battle with Kela Grimtotem (Kalimdor)",
    faction = "both",
    npcId = 66452,
  },
  
  [31907] = {
    name = "Zoltan",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Felwood",
    description = "Daily battle with Zoltan (Kalimdor)",
    faction = "both",
    npcId = 66442,
  },
  
  [31908] = {
    name = "Elena Flutterfly",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Moonglade",
    description = "Daily battle with Elena Flutterfly (Kalimdor)",
    faction = "both",
    npcId = 66412,
  },
  
  [31871] = {
    name = "Traitor Gluk",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Feralas",
    description = "Daily battle with Traitor Gluk (Kalimdor)",
    faction = "both",
    npcId = 66352,
  },
  
  [31862] = {
    name = "Zonya the Sadist",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Stonetalon Mountains",
    description = "Daily battle with Zonya the Sadist (Kalimdor)",
    faction = "Horde",
    npcId = 66137,
  },
  
  [31904] = {
    name = "Cassandra Kaboom",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Southern Barrens",
    description = "Daily battle with Cassandra Kaboom (Kalimdor)",
    faction = "Horde",
    npcId = 66422,
  },
  
  [31931] = {
    name = "Beegle Blastfuse",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Howling Fjord",
    description = "Daily battle with Beegle Blastfuse (Northrend)",
    faction = "both",
    npcId = 66635,
  },
  
  [31932] = {
    name = "Nearly Headless Jacob",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Crystalsong Forest",
    description = "Daily battle with Nearly Headless Jacob (Northrend)",
    faction = "both",
    npcId = 66636,
  },
  
  [31933] = {
    name = "Okrut Dragonwaste",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Dragonblight",
    description = "Daily battle with Okrut Dragonwaste (Northrend)",
    faction = "both",
    npcId = 66638,
  },
  
  [31934] = {
    name = "Gutretch",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Zul'Drak",
    description = "Daily battle with Gutretch (Northrend)",
    faction = "both",
    npcId = 66639,
  },
  
  [31818] = {
    name = "Zunta",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Durotar",
    description = "Daily battle with Zunta (Kalimdor)",
    faction = "Horde",
    npcId = 66126,
  },
  
  [31819] = {
    name = "Dagra the Fierce",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Northern Barrens",
    description = "Daily battle with Dagra the Fierce (Kalimdor)",
    faction = "Horde",
    npcId = 66135,
  },
  
  [31916] = {
    name = "Merda Stronghoof",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Desolace",
    description = "Daily battle with Merda Stronghoof (Kalimdor)",
    faction = "Horde",
    npcId = 66372,
  },
  
  [31693] = {
    name = "Julia Stevens",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Elwynn Forest",
    description = "Daily battle with Julia Stevens (EK)",
    faction = "Alliance",
    npcId = 64330,
  },
  
  [31721] = {
    name = "Lindsay",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Redridge Mountains",
    description = "Daily battle with Lindsay (EK)",
    faction = "Alliance",
    npcId = 65651,
  },
  
  [31727] = {
    name = "Steven Lisbane",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Northern Stranglethorn",
    description = "Daily battle with Steven Lisbane (EK)",
    faction = "Alliance",
    npcId = 63194,
  },
  
  [31851] = {
    name = "Bill Buckler",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Cape of Stranglethorn",
    description = "Daily battle with Bill Buckler (EK)",
    faction = "Alliance",
    npcId = 65656,
  },
  
  [31780] = {
    name = "Old MacDonald",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Westfall",
    description = "Daily battle with Old MacDonald (EK)",
    faction = "Alliance",
    npcId = 65648,
  },
  
  [31850] = {
    name = "Eric Davidson",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Duskwood",
    description = "Daily battle with Eric Davidson (EK)",
    faction = "Alliance",
    npcId = 65655,
  },
  
  [31972] = {
    name = "Brok",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Mount Hyjal",
    description = "Daily battle with Brok (Cataclysm)",
    faction = "both",
    npcId = 66819,
  },
  
  [31973] = {
    name = "Bordin Steadyfist",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Deepholm",
    description = "Daily battle with Bordin Steadyfist (Cataclysm)",
    faction = "both",
    npcId = 66815,
  },
  
  [31974] = {
    name = "Goz Banefury",
    type = questDB.TYPE.DAILY,
    category = questDB.CATEGORY.PET_BATTLE,
    zone = "Twilight Highlands",
    description = "Daily battle with Goz Banefury (Cataclysm)",
    faction = "both",
    npcId = 66822,
  },
}

-- ========== INDEXING SYSTEM ==========
-- Build lookup indices for efficient queries

questDB.indices = {
  byCategory = {},
  byType = {},
  byZone = {},
  byFaction = {},
  byNpcId = {},
}

--[[
  Build lookup indices for fast queries
  Called once at addon initialization
]]
function questDB:buildIndices()
  -- Clear existing indices
  self.indices.byCategory = {}
  self.indices.byType = {}
  self.indices.byZone = {}
  self.indices.byFaction = {}
  self.indices.byNpcId = {}
  
  for questId, quest in pairs(self.QUESTS) do
    -- Index by each category flag
    for flagName, flagValue in pairs(self.CATEGORY) do
      if self:hasCategory(quest, flagValue) then
        if not self.indices.byCategory[flagValue] then
          self.indices.byCategory[flagValue] = {}
        end
        table.insert(self.indices.byCategory[flagValue], questId)
      end
    end
    
    -- Index by each type flag
    for flagName, flagValue in pairs(self.TYPE) do
      if self:hasType(quest, flagValue) then
        if not self.indices.byType[flagValue] then
          self.indices.byType[flagValue] = {}
        end
        table.insert(self.indices.byType[flagValue], questId)
      end
    end
    
    -- Index by zone
    if quest.zone then
      if not self.indices.byZone[quest.zone] then
        self.indices.byZone[quest.zone] = {}
      end
      table.insert(self.indices.byZone[quest.zone], questId)
    end
    
    -- Index by faction
    local faction = quest.faction or "both"
    if not self.indices.byFaction[faction] then
      self.indices.byFaction[faction] = {}
    end
    table.insert(self.indices.byFaction[faction], questId)
    
    -- Index by NPC ID (for single npcId)
    if quest.npcId then
      if not self.indices.byNpcId[quest.npcId] then
        self.indices.byNpcId[quest.npcId] = {}
      end
      table.insert(self.indices.byNpcId[quest.npcId], questId)
    end
    
    -- Index by NPC IDs (for multiple npcIds like Beasts of Fable)
    if quest.npcIds then
      for _, npcId in ipairs(quest.npcIds) do
        if not self.indices.byNpcId[npcId] then
          self.indices.byNpcId[npcId] = {}
        end
        table.insert(self.indices.byNpcId[npcId], questId)
      end
    end
  end
end

-- Initialize indices on load
questDB:buildIndices()

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("quests", {}, function()
    return true
  end)
end

return questDB