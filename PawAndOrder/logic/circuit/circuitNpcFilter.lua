--[[
  logic/circuit/circuitNpcFilter.lua
  Circuit-Specific NPC Filtering and Categorization
  
  Provides circuit-specific operations on top of the generic npcUtils module.
  Handles continent filtering, category organization for UI tree building, and
  circuit-aware validation. Special handling for faction-dependent NPCs like
  Jeremy Feasel (Darkmoon Faire) who appears in faction-appropriate continents.
  Tags portal-required NPCs for UI display.
  
  Dependencies: utils, npcUtils, circuitConstants
  Exports: Addon.circuitNpcFilter
]]

local addonName, Addon = ...

Addon.circuitNpcFilter = {}
local filter = Addon.circuitNpcFilter

-- Portal-required NPCs (require portal travel rather than direct flight)
local PORTAL_REQUIRED_NPCS = {
  [67370] = true,  -- Jeremy Feasel (Darkmoon Faire)
  [66815] = true,  -- Bordin Steadyfist (Deepholm)
}

-- Spirit Tamer NPC ID to pet data mapping (name and species ID)
local SPIRIT_TAMER_PETS = {
  [68463] = {name = "Pandaren Fire Spirit", speciesID = 1124, hasLeash = true},   -- Burning Pandaren Spirit
  [68462] = {name = "Pandaren Water Spirit", speciesID = 868,  hasLeash = true},  -- Flowing Pandaren Spirit
  [68464] = {name = "Pandaren Air Spirit",   speciesID = 1125, hasLeash = false}, -- Whispering Pandaren Spirit
  [68465] = {name = "Pandaren Earth Spirit", speciesID = 1126, hasLeash = false}, -- Thundering Pandaren Spirit
}

-- Bag-rewarding NPCs with complete contents data
-- iconID uses texture file IDs for consistency
local BAG_REWARD_NPCS = {
  -- Grand Masters (Sack of Pet Supplies)
  [66522] = {  -- Lydia Accoste (EK Grand Master)
    bagType = "sack",
    bagName = "Sack of Pet Supplies",
    iconID = 133642,  -- Green bag
    contents = {
      {type = "item", name = "Flawless Battle-Stone"},
      {type = "pet", name = "Porcupette", speciesID = 634},
    }
  },
  [66466] = {  -- Stonecold Trixie (Kalimdor Grand Master)
    bagType = "sack",
    bagName = "Sack of Pet Supplies",
    iconID = 133642,
    contents = {
      {type = "item", name = "Flawless Battle-Stone"},
      {type = "pet", name = "Porcupette", speciesID = 634},
    }
  },
  [66557] = {  -- Bloodknight Antari (Outland Grand Master)
    bagType = "sack",
    bagName = "Sack of Pet Supplies",
    iconID = 133642,
    contents = {
      {type = "item", name = "Flawless Battle-Stone"},
      {type = "pet", name = "Porcupette", speciesID = 634},
    }
  },
  [66675] = {  -- Major Payne (Northrend Grand Master)
    bagType = "sack",
    bagName = "Sack of Pet Supplies",
    iconID = 133642,
    contents = {
      {type = "item", name = "Flawless Battle-Stone"},
      {type = "pet", name = "Porcupette", speciesID = 634},
    }
  },
  [66824] = {  -- Obalis (Cataclysm Grand Master)
    bagType = "sack",
    bagName = "Sack of Pet Supplies",
    iconID = 133642,
    contents = {
      {type = "item", name = "Flawless Battle-Stone"},
      {type = "pet", name = "Porcupette", speciesID = 634},
    }
  },
  
  -- Darkmoon Faire
  [67370] = {  -- Jeremy Feasel
    bagType = "darkmoon",
    bagName = "Darkmoon Pet Supplies",
    iconID = 133667,  -- Darkmoon ticket
    contents = {
      {type = "item", name = "5x Darkmoon Prize Ticket"},
      {type = "pet", name = "Darkmoon Eye", speciesID = 1046},
      {type = "toy", name = "Chain Pet Leash"},
      {type = "toy", name = "Red Ribbon Pet Leash"},
    }
  },
}

--[[
  Get NPCs available for circuit planning with portal tags
  Wraps npcUtils:filterAvailableNpcs() and adds portal-required flags.
  
  @return table - Categorized NPCs with portalRequired flag added
]]
function filter:getAvailableForCircuit()
  local npcs = Addon.npcUtils:filterAvailableNpcs()
  local constants = Addon.circuitConstants
  
  -- Tag portal-required NPCs and check portal availability
  for _, category in pairs(npcs) do
    for _, npcInfo in ipairs(category) do
      -- Tag portal-required NPCs
      if PORTAL_REQUIRED_NPCS[npcInfo.id] then
        npcInfo.portalRequired = true
        npcInfo.portalIcon = constants.UI.PORTAL_ICON
        
        -- Check if portal is available (only if not already disabled)
        if not npcInfo.disabled and Addon.portalManager then
          local requiresPortal, destMapID = Addon.portalManager:doesNpcRequirePortal(npcInfo.id)
          if requiresPortal and destMapID then
            -- Get player's current map
            local playerMapID = 0
            if Addon.location and Addon.location.getCurrentPlayerLocation then
              local loc = Addon.location:getCurrentPlayerLocation()
              playerMapID = loc.mapID or 0
            end
            
            -- Only check portal if player is NOT already at destination
            if playerMapID ~= destMapID then
              local portal, reason = Addon.portalManager:findPortalTo(playerMapID, destMapID)
              if not portal then
                npcInfo.disabled = true
                npcInfo.disabledReason = reason or "Portal not available"
              end
            end
          end
        end
      end
      
      -- Tag bag-rewarding NPCs with full contents data
      local givesBag = false
      local bagData = nil
      
      if BAG_REWARD_NPCS[npcInfo.id] then
        -- Explicitly marked NPCs (Grand Masters, Jeremy Feasel)
        givesBag = true
        bagData = BAG_REWARD_NPCS[npcInfo.id]
      elseif npcInfo.npc.types and bit.band(npcInfo.npc.types, Addon.NPC_TYPE.SPIRIT) > 0 then
        -- Spirit Tamers give Pandaren Spirit Pet Supplies with tamer-specific pet
        local spiritPetData = SPIRIT_TAMER_PETS[npcInfo.id]
        if spiritPetData then
          givesBag = true
          local contents = {
            {type = "item", name = "Flawless Battle-Stone"},
            {type = "pet", name = spiritPetData.name, speciesID = spiritPetData.speciesID},
          }
          
          -- Only Fire and Water spirits have Chain Pet Leash
          if spiritPetData.hasLeash then
            table.insert(contents, {type = "toy", name = "Chain Pet Leash"})
          end
          
          bagData = {
            bagType = "spirit",
            bagName = "Pandaren Spirit Pet Supplies",
            iconID = 133663,  -- Pet carrier (not green bag)
            contents = contents
          }
        end
      elseif npcInfo.npc.types and bit.band(npcInfo.npc.types, Addon.NPC_TYPE.FABLED) > 0 then
        -- Fabled Beasts give Fabled Pandaren Pet Supplies (Red Panda is quest reward only)
        givesBag = true
        bagData = {
          bagType = "fabled",
          bagName = "Fabled Pandaren Pet Supplies",
          iconID = 133663,  -- Pet carrier box
          contents = {
            {type = "pet", name = "Snowy Panda", speciesID = 1197},
            {type = "pet", name = "Mountain Panda", speciesID = 1198},
            {type = "pet", name = "Sunfur Panda", speciesID = 1196},
            {type = "item", name = "Flawless Battle-Stone"},
            {type = "toy", name = "Chain Pet Leash"},
            {type = "toy", name = "Red Ribbon Pet Leash"},
            {type = "item", name = "Lesser Pet Treat"},
          }
        }
      elseif npcInfo.continent == 424 and npcInfo.npc.types and bit.band(npcInfo.npc.types, Addon.NPC_TYPE.TAMER) > 0 then
        -- Pandaria Master Tamers give Sack of Pet Supplies
        givesBag = true
        bagData = {
          bagType = "sack",
          bagName = "Sack of Pet Supplies",
          iconID = 133642,
          contents = {
            {type = "item", name = "Flawless Battle-Stone"},
            {type = "pet", name = "Porcupette", speciesID = 634},
          }
        }
      end
      
      if givesBag and bagData then
        npcInfo.givesBag = true
        npcInfo.bagType = bagData.bagType
        npcInfo.bagName = bagData.bagName
        npcInfo.bagIcon = bagData.iconID
        npcInfo.bagContents = bagData.contents
      end
    end
  end
  
  return npcs
end

--[[
  Get faction-appropriate continent for special NPCs
  Handles NPCs like Jeremy Feasel and Bordin Steadyfist who appear in different 
  continents based on faction (portal from faction home continent).
  
  @param npcId number - NPC ID to check
  @param actualContinent number - NPC's actual continent from data
  @return number - Continent ID to use for UI display (may differ from actual)
]]
local function getFactionContinent(npcId, actualContinent)
  -- Jeremy Feasel special case: appears in faction home continent despite being on Darkmoon
  if npcId == 67370 then  -- Jeremy Feasel
    local faction = UnitFactionGroup("player")
    if faction == "Alliance" then
      return 13  -- Eastern Kingdoms
    else
      return 12  -- Kalimdor
    end
  end
  
  -- Bordin Steadyfist special case: appears in both faction home continents
  if npcId == 66815 then  -- Bordin Steadyfist (Deepholm)
    local faction = UnitFactionGroup("player")
    if faction == "Alliance" then
      return 13  -- Eastern Kingdoms
    else
      return 12  -- Kalimdor
    end
  end
  
  return actualContinent
end

--[[
  Filter NPCs by continent with faction-aware continent mapping
  Takes categorized NPC data and filters to only include NPCs on specified continent.
  Handles special cases like Jeremy Feasel appearing in faction-appropriate continents.
  
  @param npcs table - NPC data organized by category
  @param continent number|string - Continent ID to filter by
  @return table - Filtered NPC data with same structure
]]
function filter:filterByContinent(npcs, continent)
  local filtered = {
    fabledBeasts = {},
    spiritTamers = {},
    dailyTamers = {},
    specialBattles = {},
    theMaelstrom = {},
    cataclysmTamers = {},
  }
  
  for _, npcInfo in ipairs(npcs.fabledBeasts) do
    local displayContinent = getFactionContinent(npcInfo.id, npcInfo.continent)
    if displayContinent == continent then
      table.insert(filtered.fabledBeasts, npcInfo)
    end
  end
  
  for _, npcInfo in ipairs(npcs.spiritTamers) do
    local displayContinent = getFactionContinent(npcInfo.id, npcInfo.continent)
    if displayContinent == continent then
      table.insert(filtered.spiritTamers, npcInfo)
    end
  end
  
  -- Separate portal tamers and Cata tamers: Jeremy to specialBattles, Bordin to theMaelstrom, Cata tamers to cataclysmTamers
  local regularTamers = {}
  local jeremyTamer = nil
  local bordinTamer = nil
  local cataTamers = {}
  
  for _, npcInfo in ipairs(npcs.dailyTamers) do
    local displayContinent = getFactionContinent(npcInfo.id, npcInfo.continent)
    if displayContinent == continent then
      if npcInfo.id == 67370 then  -- Jeremy Feasel
        jeremyTamer = npcInfo
        jeremyTamer.needsSeparator = true  -- Flag for UI spacing
      elseif npcInfo.id == 66815 then  -- Bordin Steadyfist
        bordinTamer = npcInfo
      elseif npcInfo.continent == 948 then  -- Cataclysm tamers (use actual continent, not display)
        table.insert(cataTamers, npcInfo)
      else
        table.insert(regularTamers, npcInfo)
      end
    end
  end
  
  -- Add regular tamers to dailyTamers
  for _, npcInfo in ipairs(regularTamers) do
    table.insert(filtered.dailyTamers, npcInfo)
  end
  
  -- Add Cata tamers to cataclysmTamers
  for _, npcInfo in ipairs(cataTamers) do
    table.insert(filtered.cataclysmTamers, npcInfo)
  end
  
  -- Add Jeremy to specialBattles if present
  if jeremyTamer then
    table.insert(filtered.specialBattles, jeremyTamer)
  end
  
  -- Add Bordin to theMaelstrom if present
  if bordinTamer then
    table.insert(filtered.theMaelstrom, bordinTamer)
  end
  
  for _, npcInfo in ipairs(npcs.specialBattles) do
    local displayContinent = getFactionContinent(npcInfo.id, npcInfo.continent)
    if displayContinent == continent then
      table.insert(filtered.specialBattles, npcInfo)
    end
  end
  
  return filtered
end

--[[
  Get unique continents from NPC data with faction-aware mapping
  Scans all NPCs and returns list of unique continent IDs, applying faction
  mapping where appropriate (e.g., Jeremy shows in EK for Alliance, Kal for Horde).
  
  @param npcs table - Categorized NPC data
  @return table - Array of unique continent IDs
]]
function filter:getUniqueContinents(npcs)
  local continents = {}
  local seen = {}
  
  for _, category in pairs(npcs) do
    for _, npcInfo in ipairs(category) do
      local displayContinent = getFactionContinent(npcInfo.id, npcInfo.continent)
      if displayContinent and not seen[displayContinent] then
        seen[displayContinent] = true
        table.insert(continents, displayContinent)
      end
    end
  end
  
  -- Sort continents by expansion (newest first), player's faction continent before opposite faction
  table.sort(continents, function(a, b)
    -- Handle special "darkmoon" string key (should not appear with faction mapping)
    if type(a) == "string" then return false end
    if type(b) == "string" then return true end
    
    -- Get player faction
    local playerFaction = UnitFactionGroup("player")  -- "Alliance" or "Horde"
    
    -- Define sort order: MoP → WotLK → TBC → Cataclysm → Player's faction → Opposite faction
    -- Actual MoP continent IDs: 13=EK, 12=Kalimdor, 1467=Outland, 113=Northrend, 424=Pandaria, 948=Maelstrom
    local sortOrder = {
      [424] = 1,   -- Pandaria (MoP, neutral)
      [113] = 2,   -- Northrend (WotLK, neutral)
      [1467] = 3,  -- Outland (TBC, neutral)
      [948] = 4,   -- The Maelstrom (Cataclysm, neutral)
      [13] = playerFaction == "Alliance" and 5 or 6,  -- Eastern Kingdoms (Alliance home)
      [12] = playerFaction == "Horde" and 5 or 6,     -- Kalimdor (Horde home)
    }
    
    local orderA = sortOrder[a] or 999
    local orderB = sortOrder[b] or 999
    
    return orderA < orderB
  end)
  
  return continents
end

--[[
  Count total NPCs across all categories
  Helper for determining if any NPCs are available.
  
  @param npcs table - Categorized NPC data
  @return number - Total NPC count
]]
function filter:countTotalNpcs(npcs)
  return #npcs.fabledBeasts + #npcs.spiritTamers + 
         #npcs.dailyTamers + #npcs.specialBattles + 
         (npcs.theMaelstrom and #npcs.theMaelstrom or 0) +
         (npcs.cataclysmTamers and #npcs.cataclysmTamers or 0)
end

--[[
  Get category display order
  Returns the canonical order for displaying NPC categories in UI.
  
  @return table - Array of category info {key, displayName, priorityOrder}
]]
function filter:getCategoryDisplayOrder()
  return {
    {key = "dailyTamers", displayName = "Daily Tamers", order = 1},
    {key = "spiritTamers", displayName = "Spirit Tamers", order = 2},
    {key = "fabledBeasts", displayName = "Fabled Beasts", order = 3},
    {key = "cataclysmTamers", displayName = "Cataclysm Tamers", order = 4},
    {key = "specialBattles", displayName = "Special Encounters", order = 5},
    {key = "theMaelstrom", displayName = "The Maelstrom", order = 6},
  }
end

--[[
  Validate NPCs for circuit start
  Wraps npcUtils:validateNpcs() for circuit-specific context.
  
  @param npcIds table - Array of NPC IDs to validate
  @return table - Filtered array of valid NPC IDs
]]
function filter:validateForCircuit(npcIds)
  return Addon.npcUtils:validateNpcs(npcIds)
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("circuitNpcFilter", {"utils", "npcUtils", "circuitConstants", "portalManager"}, function()
    return true
  end)
end

return filter