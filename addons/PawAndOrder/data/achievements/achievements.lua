--[[
  data/achievements/achievements.lua
  Curated Achievement Data
  
  Static achievement data that the WoW API cannot reliably provide at runtime.
  Completed chain achievements are hidden from category enumeration, and
  guild achievements don't surface their pet unlock relationships.
  
  Fields:
    speciesID  - Pet species rewarded by completing this achievement (optional)
    isGuild    - true if this is a guild achievement (optional)
    gatesSpecies - table of speciesIDs unlocked at guild vendor by this achievement (optional)
  
  Dependencies: none (loaded before logic layer)
  Exports: Addon.data.achievements, Addon.data.achievementBySpecies (built at load)
]]

local ADDON_NAME, Addon = ...

Addon.data = Addon.data or {}

-- ============================================================================
-- ACHIEVEMENT DATA
-- ============================================================================

Addon.data.achievements = {
  -- ========================================================================
  -- PET-REWARDING ACHIEVEMENTS (pet mailed or added to journal on completion)
  -- ========================================================================
  
  -- Collection chain (Can I Keep Him? → ... → That's a Lot of Pet Food)
  [1250] = { speciesID = 160 },   -- Shop Smart, Shop Pet...Smart → Stinker
  [2516] = { speciesID = 203 },   -- Lil' Game Hunter → Little Fawn
  [5876] = { speciesID = 323 },   -- Petting Zoo → Nuts
  [5877] = { speciesID = 325 },   -- Menagerie → Brilliant Kaliri
  [5875] = { speciesID = 255 },   -- Littlest Pet Shop → Celestial Dragon
  [7500] = { speciesID = 821 },   -- Going to Need More Leashes → Feral Vermling
  [7501] = { speciesID = 855 },   -- That's a Lot of Pet Food → Venus
  
  -- Pet Battles > Collect
  [7934] = { speciesID = 1145 },  -- Raiding with Leashes → Mr. Bigglesworth
  [8293] = { speciesID = 1236 },  -- Raiding with Leashes II: Attunement Edition → Tito
  [7521] = { speciesID = 856 },   -- Time to Open a Pet Store → Jade Tentacle
  
  -- Pet Battles > Battle
  [8300] = { speciesID = 1184 },  -- Brutal Pet Brawler → Stunted Direhorn
  
  -- Pet Battles > Level
  [6582] = { speciesID = 820 },   -- Pro Pet Mob → Singing Cricket
  
  -- Dungeons & Raids
  [4478] = { speciesID = 250 },   -- Looking For Multitudes → Perky Pug
  [6402] = { speciesID = 835 },   -- Ling-Ting's Herbal Journey → Hopling
  [19439] = { speciesID = 4329 }, -- Defense Protocol Gamma: Terminated → Arfus
  
  -- Quests
  [5449] = { speciesID = 265 },   -- Rock Lover → Pebble
  
  -- General
  [1956] = { speciesID = 199 },   -- Higher Learning → Kirin Tor Familiar
  
  -- Feats of Strength
  [2398] = { speciesID = 202 },   -- WoW's 4th Anniversary → Baby Blizzard Bear
  [4400] = { speciesID = 244 },   -- WoW's 5th Anniversary → Onyxian Whelpling
  
  -- ========================================================================
  -- GUILD ACHIEVEMENTS (unlock pet purchase at guild vendor)
  -- ========================================================================
  
  -- Guild: General
  [5144] = { isGuild = true, gatesSpecies = {272} },       -- Critter Kill Squad → Armadillo Pup
  [5201] = { isGuild = true, gatesSpecies = {282, 283} },  -- Profit Sharing → Guild Herald (A/H)
  
  -- Guild: Reputation
  [5892] = { isGuild = true, gatesSpecies = {270} },       -- United Nations → Dark Phoenix Hatchling
  
  -- Guild: Player vs. Player
  [5031] = { isGuild = true, gatesSpecies = {280} },       -- Horde Slayer → Guild Page (Alliance)
  [5179] = { isGuild = true, gatesSpecies = {281} },       -- Alliance Slayer → Guild Page (Horde)
  
  -- Guild: Dungeons & Raids
  [5840] = { isGuild = true, gatesSpecies = {320} },       -- Dragonwrath, Tarecgosa's Rest - Guild Edition → Lil' Tarecgosa
  
  -- Guild: Feats of Strength
  [6634] = { isGuild = true, gatesSpecies = {802} },       -- Challenge Conquerors: Gold - Guild Edition → Thundering Serpent Hatchling
}

-- ============================================================================
-- REVERSE INDEX: speciesID → achievementID
-- Built at load time from entries with speciesID or gatesSpecies.
-- ============================================================================

Addon.data.achievementBySpecies = {}

local function buildReverseIndex()
  local bySpecies = Addon.data.achievementBySpecies
  for achievementID, data in pairs(Addon.data.achievements) do
    if data.speciesID then
      bySpecies[data.speciesID] = achievementID
    end
    if data.gatesSpecies then
      for _, sid in ipairs(data.gatesSpecies) do
        bySpecies[sid] = achievementID
      end
    end
  end
end

buildReverseIndex()