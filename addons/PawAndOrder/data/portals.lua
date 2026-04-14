--[[
  data/portals.lua
  Portal Location Database for Cross-Zone Travel
  
  Stores individual portal records for zones requiring portal access (DMF, Cataclysm).
  Each portal is a standalone record - bidirectional portals are stored as two separate
  entries for maximum flexibility in routing logic.
  
  Portal availability depends on:
  - Player faction (Alliance/Horde/both)
  - Event activity (Darkmoon Faire)
  - Quest completion (Cataclysm zone unlocks)
  
  Used by routing system to insert portal waypoints when NPCs require portal travel.
  
  Dependencies: None (pure data)
  Exports: Addon.portalDatabase
]]

local addonName, Addon = ...

Addon.portalDatabase = {}
local portalDB = Addon.portalDatabase

--[[
  Portal database
  Each portal record contains:
  - id: Unique portal identifier
  - portalType: Semantic grouping (darkmoon, earthshrine, etc)
  - location: Where the portal is located
    - mapID: Map ID where portal is found
    - x, y: Coordinates (0-100 scale)
    - zone: Zone name
    - continent: Continent ID
    - subzone: Optional subzone name
  - destination: Where the portal leads
    - mapID: Destination map ID
    - zone: Destination zone name
    - continent: Destination continent ID
  - faction: "Alliance", "Horde", or "both"
  - bidirectional: Boolean - can portal be used in reverse direction?
  - requirements: Optional conditions for portal availability
    - event: Event that must be active (e.g., "DARKMOON_FAIRE")
    - quest: Quest ID that must be completed
]]
portalDB.PORTALS = {
  
  -- ========== DARKMOON FAIRE PORTALS ==========
  
  -- Alliance: Elwynn Forest to Darkmoon Island
  {
    id = "elwynn_to_dmf",
    portalType = "darkmoon",
    location = {
      mapID = 37,
      x = 42.0,
      y = 70.0,
      zone = "Elwynn Forest",
      continent = 13,  -- Eastern Kingdoms
    },
    destination = {
      mapID = 407,
      zone = "Darkmoon Island",
      continent = 407,  -- Special DMF continent
    },
    faction = "Alliance",
    bidirectional = true,
    requirements = {
      event = "DARKMOON_FAIRE",
    },
  },
  
  -- Horde: Mulgore to Darkmoon Island
  {
    id = "mulgore_to_dmf",
    portalType = "darkmoon",
    location = {
      mapID = 7,
      x = 37.0,
      y = 38.0,
      zone = "Mulgore",
      continent = 12,  -- Kalimdor
    },
    destination = {
      mapID = 407,
      zone = "Darkmoon Island",
      continent = 407,
    },
    faction = "Horde",
    bidirectional = true,
    requirements = {
      event = "DARKMOON_FAIRE",
    },
  },
  
  -- ========== CATACLYSM EARTHSHRINE PORTALS ==========
  
  -- Alliance: Stormwind to Mount Hyjal
  {
    id = "sw_to_hyjal",
    portalType = "earthshrine",
    location = {
      mapID = 84,
      x = 76.1,
      y = 18.7,
      zone = "Stormwind City",
      subzone = "Eastern Earthshrine",
      continent = 13,  -- Eastern Kingdoms
    },
    destination = {
      mapID = 606,
      zone = "Mount Hyjal",
      continent = 12,  -- Kalimdor (Hyjal is part of Kalimdor)
    },
    faction = "Alliance",
    bidirectional = true,
    requirements = {
      quest = 25316,  -- "As Hyjal Burns"
    },
  },
  
  -- Horde: Orgrimmar to Mount Hyjal
  {
    id = "org_to_hyjal",
    portalType = "earthshrine",
    location = {
      mapID = 85,
      x = 50.9,
      y = 38.2,
      zone = "Orgrimmar",
      subzone = "Western Earthshrine",
      continent = 12,  -- Kalimdor
    },
    destination = {
      mapID = 606,
      zone = "Mount Hyjal",
      continent = 12,
    },
    faction = "Horde",
    bidirectional = true,
    requirements = {
      quest = 25316,  -- "As Hyjal Burns"
    },
  },
  
  -- Alliance: Stormwind to Deepholm
  {
    id = "sw_to_deepholm",
    portalType = "earthshrine",
    location = {
      mapID = 84,
      x = 73.2,
      y = 19.7,
      zone = "Stormwind City",
      subzone = "Eastern Earthshrine",
      continent = 13,
    },
    destination = {
      mapID = 640,
      zone = "Deepholm",
      continent = 948,  -- The Maelstrom
    },
    faction = "Alliance",
    bidirectional = true,
    requirements = {
      quest = 27203,  -- "The Maelstrom"
    },
  },
  
  -- Horde: Orgrimmar to Deepholm
  {
    id = "org_to_deepholm",
    portalType = "earthshrine",
    location = {
      mapID = 85,
      x = 50.8,
      y = 36.5,
      zone = "Orgrimmar",
      subzone = "Western Earthshrine",
      continent = 12,
    },
    destination = {
      mapID = 640,
      zone = "Deepholm",
      continent = 948,
    },
    faction = "Horde",
    bidirectional = true,
    requirements = {
      quest = 27203,  -- "The Maelstrom"
    },
  },
  
  -- Alliance: Stormwind to Twilight Highlands
  {
    id = "sw_to_twilight",
    portalType = "earthshrine",
    location = {
      mapID = 84,
      x = 75.3,
      y = 16.6,
      zone = "Stormwind City",
      subzone = "Eastern Earthshrine",
      continent = 13,
    },
    destination = {
      mapID = 700,
      zone = "Twilight Highlands",
      continent = 13,  -- Eastern Kingdoms
    },
    faction = "Alliance",
    bidirectional = true,
    requirements = {
      quest = 27545,  -- "The Way is Open"
    },
  },
  
  -- Horde: Orgrimmar to Twilight Highlands
  {
    id = "org_to_twilight",
    portalType = "earthshrine",
    location = {
      mapID = 85,
      x = 50.8,
      y = 38.5,  -- Approximate - needs verification
      zone = "Orgrimmar",
      subzone = "Western Earthshrine",
      continent = 12,
    },
    destination = {
      mapID = 700,
      zone = "Twilight Highlands",
      continent = 13,
    },
    faction = "Horde",
    bidirectional = true,
    requirements = {
      quest = 26840,  -- "Return to the Highlands"
    },
  },
  
  -- Alliance: Stormwind to Uldum (ONE-WAY)
  {
    id = "sw_to_uldum",
    portalType = "earthshrine",
    location = {
      mapID = 84,
      x = 75.2,
      y = 20.3,
      zone = "Stormwind City",
      subzone = "Eastern Earthshrine",
      continent = 13,
    },
    destination = {
      mapID = 720,
      zone = "Uldum",
      continent = 12,  -- Kalimdor
    },
    faction = "Alliance",
    bidirectional = false,  -- One-way portal only
    requirements = {
      quest = 28112,  -- "Escape From the Lost City"
    },
  },
  
  -- Horde: Orgrimmar to Uldum (ONE-WAY)
  {
    id = "org_to_uldum",
    portalType = "earthshrine",
    location = {
      mapID = 85,
      x = 50.9,
      y = 40.0,  -- Approximate - needs verification
      zone = "Orgrimmar",
      subzone = "Western Earthshrine",
      continent = 12,
    },
    destination = {
      mapID = 720,
      zone = "Uldum",
      continent = 12,
    },
    faction = "Horde",
    bidirectional = false,  -- One-way portal only
    requirements = {
      quest = 28112,  -- "Escape From the Lost City"
    },
  },
}

-- ========== INDEXING SYSTEM ==========
-- Build lookup indices for efficient queries

portalDB.indices = {
  bySourceMap = {},
  byDestinationMap = {},
  byFaction = {},
  byType = {},
}

--[[
  Build lookup indices for fast queries
  Called once at addon initialization
]]
function portalDB:buildIndices()
  -- Clear existing indices
  self.indices.bySourceMap = {}
  self.indices.byDestinationMap = {}
  self.indices.byFaction = {}
  self.indices.byType = {}
  
  for _, portal in ipairs(self.PORTALS) do
    -- Index by source map
    local sourceMap = portal.location.mapID
    if not self.indices.bySourceMap[sourceMap] then
      self.indices.bySourceMap[sourceMap] = {}
    end
    table.insert(self.indices.bySourceMap[sourceMap], portal)
    
    -- Index by destination map
    local destMap = portal.destination.mapID
    if not self.indices.byDestinationMap[destMap] then
      self.indices.byDestinationMap[destMap] = {}
    end
    table.insert(self.indices.byDestinationMap[destMap], portal)
    
    -- Index by faction
    local faction = portal.faction or "both"
    if not self.indices.byFaction[faction] then
      self.indices.byFaction[faction] = {}
    end
    table.insert(self.indices.byFaction[faction], portal)
    
    -- Index by portal type
    local portalType = portal.portalType
    if portalType then
      if not self.indices.byType[portalType] then
        self.indices.byType[portalType] = {}
      end
      table.insert(self.indices.byType[portalType], portal)
    end
  end
end

-- Initialize indices on load
portalDB:buildIndices()

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("portals", {}, function()
    return true
  end)
end

return portalDB