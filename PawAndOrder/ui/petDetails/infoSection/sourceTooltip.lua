--[[
  ui/petDetails/infoSection/sourceTooltip.lua
  Source Tooltip Rendering
  
  Handles rendering of pet source tooltips, including:
    - Pet Battle sources with enhanced zone/level display
    - Drop sources with mob/zone info
    - Vendor sources with cost/faction info
    - Trading Card Game sources with expansion name and optional vendor
    - Achievement sources with achievement name and category
    - Quest sources with giver/ender, completion status, daily/random indicators
    - In-Game Shop / Pet Store sources
    - Standard source tooltips with Blizzard text cleanup
  
  Quest tooltips use static curated data from sourceOverrides.lua (questData),
  with optional Questie enrichment for NPC zone/coords when Questie is loaded.
  
  Dependencies: tooltip, uiUtils, location, data.zones, data.instances
  Exports: Addon.sourceTooltip
]]

local ADDON_NAME, Addon = ...

local sourceTooltip = {}

-- Colors for Pet Battle zone tooltip
local ZONE_COLORS = {
  OTHER = {0.9, 0.9, 0.9},              -- White - zone names
  LEVEL_ACCESSIBLE = {0.2, 1, 0.2},     -- Green - player outlevels the zone
  LEVEL_NEAR = {1, 1, 0.2},             -- Yellow - player is within range
  LEVEL_DANGEROUS = {1, 0.4, 0.4},      -- Red - player is below the zone
  HEADER = {1, 0.82, 0},                -- Gold - continent headers
  COLUMN_HEADER = {0.6, 0.6, 0.6},      -- Dim gray - column labels
  CONDITION = {0.75, 0.55, 1.0},        -- Strong lavender - spawn condition values
}

local MOB_COLORS = {
  BOSS = {1, 0.7, 0.3},            -- Warm amber - instance bosses
  OUTDOOR = {0.7, 0.8, 0.9},       -- Silver-blue - outdoor named mobs
}
local MAX_ZONES_DISPLAY = 12

-- Header icon for Pet Battle sources
local BATTLE_ICON = 643856

-- Caution icon for spawn conditions
local CAUTION_ICON = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew"
local NOTE_ICON = "Interface\\AddOns\\PawAndOrder\\textures\\info-icon.png"

-- Vendor tooltip constants
local VENDOR_ICON = "Interface\\Icons\\INV_Misc_Coin_01"  -- Placeholder gold coin
local COIN_ICONS = {
  gold = "Interface\\MoneyFrame\\UI-GoldIcon",
  silver = "Interface\\MoneyFrame\\UI-SilverIcon",
  copper = "Interface\\MoneyFrame\\UI-CopperIcon",
}
local GOBLIN_QUOTES = {
  "I got what you need.",
  "Got the best deals anywhere!",
  "Do I have a deal for you!",
  "Ah, potential customer...",
  "Can I show ya my wares?",
  "Cha-ching!",
  "I ain't got it, you don't want it.",
  "I know a buyer when I see one.",
  "This stuff sells itself.",
  "You break it, you buy it.",
  "Can I lighten that coinpurse for ya?",
}
local VENDOR_COLORS = {
  NAME = {0.7, 0.8, 0.9},  -- Silver-blue, like outdoor mobs
}

-- Black Market Auction House note color
local BMAH_COLOR = {0.82, 0.56, 0.28}  -- Tarnished copper/bronze

-- Quest tooltip constants
local QUEST_ICON = "Interface\\Icons\\INV_Misc_Book_09"
local QUEST_COLORS = {
  NAME = {0.75, 0.55, 1.0},     -- Lavender - pet quest name
  CURRENT = {1, 0.85, 0.5},     -- Warm amber - current step
  COMPLETE = {0.2, 1, 0.2},     -- Green
  INCOMPLETE = {0.6, 0.6, 0.6}, -- Gray
  TAG = {1, 0.82, 0},           -- Gold for [Daily], [Random], etc.
  BAG = {0.9, 0.7, 0.3},        -- Warm amber for bag names
}
local QUEST_FLAVOR = {
  "Every adventure begins with a single step... toward a quest giver.",
  "The reward was never gold. It was the friends we made. Well, and the pet.",
  "Some quests reward experience. The best ones reward companionship.",
  "Not all who wander are lost. Some are on a quest for a pet.",
  "A hero's journey, measured in fetch quests and escort missions.",
}

-- Tooltip icon layout constants
local ICON_SIZE = 48

-- Hoisted lookup tables (avoid rebuilding per call)
local ZONE_NAME_CORRECTIONS = {
  ["Jade Forest"] = "The Jade Forest",
  ["Valley of Four Winds"] = "Valley of the Four Winds",
  ["Stormwind"] = "Stormwind City",
}

local VENDOR_ZONE_CORRECTIONS = {
  ["Stormwind City"] = "Stormwind",
}

local CONDITION_EXPANSIONS = {
  ["Snow"] = "Snowy Weather",
  ["Rain"] = "Rainy Weather",
  ["Sandstorm"] = "Sandstorm Weather",
  ["Night"] = "Nighttime",
  ["Winter"] = "Winter Season",
  ["Summer"] = "Summer Season",
}

local CAPITALS_AND_SANCTUARIES = {
  ["Stormwind"] = true, ["Stormwind City"] = true,
  ["Ironforge"] = true, ["Darnassus"] = true, ["The Exodar"] = true,
  ["Orgrimmar"] = true, ["Thunder Bluff"] = true,
  ["Undercity"] = true, ["Silvermoon City"] = true,
  ["Dalaran"] = true, ["Shattrath City"] = true, ["Shattrath"] = true,
}

-- Strip color codes from sourceText, delegating to uiUtils when available
local function stripColorCodes(text)
  local uiUtils = Addon.uiUtils
  return uiUtils and uiUtils:stripColorCodes(text) or text
end

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

--[[
  Format level range as string.
  
  @param range table - {min, max} or nil
  @return string - "min-max", single number, or "N/A"
]]
local function formatLevelRange(range)
  if not range then return "N/A" end
  if range[1] == range[2] then
    return tostring(range[1])
  end
  return range[1] .. "-" .. range[2]
end

--[[
  Get color for level range based on player level vs zone range.
  
  Green: player outlevels the zone entirely (level >= zone max)
  Yellow: player is within the zone's range (level >= zone min)
  Red: player is below the zone (level < zone min)
  
  @param levelRange table - {min, max} level range
  @param playerLevel number - Player's current level
  @return table - RGB color array
]]
local function getLevelColor(levelRange, playerLevel)
  if not levelRange or not playerLevel then
    return ZONE_COLORS.OTHER
  end
  
  if playerLevel >= levelRange[2] then
    return ZONE_COLORS.LEVEL_ACCESSIBLE
  elseif playerLevel >= levelRange[1] then
    return ZONE_COLORS.LEVEL_NEAR
  end
  return ZONE_COLORS.LEVEL_DANGEROUS
end

--[[
  Convert RGB color array to WoW inline color code.
  
  @param color table - {r, g, b} values 0-1
  @return string - "|cffRRGGBB"
]]
local function colorCode(color)
  return string.format("|cff%02x%02x%02x", color[1] * 255, color[2] * 255, color[3] * 255)
end

--[[
  Get player location context for tooltip rendering.
  Gathers current zone, continent display name, and player level.
  
  @return string - Current zone name
  @return string - Current continent display name
  @return number - Player level
]]
local function getPlayerLocationContext()
  local currentZone = GetZoneText() or ""
  local currentContinent = ""
  
  if Addon.location then
    local continentID = Addon.location:getCurrentContinent()
    currentContinent = Addon.location:getContinentName(continentID) or ""
  end
  
  local playerLevel = UnitLevel("player") or 90
  return currentZone, currentContinent, playerLevel
end

--[[
  Format continent name with star suffix if player is on that continent.
  
  @param continent string - Continent display name
  @param currentContinent string - Player's current continent
  @return string - Continent name, with "*" appended if current
]]
local function formatContinentText(continent, currentContinent)
  if continent == currentContinent then
    return continent .. "*"
  end
  return continent
end

--[[
  Normalize zone name to match zones.lua entries.
  Handles known API variations.
  
  @param zoneName string - Zone name from sourceText
  @param zones table - Reference to Addon.data.zones
  @return string - Normalized zone name (or original if no match found)
]]
local function normalizeZoneName(zoneName)
  if not zoneName then return zoneName end
  local nameIndex = Addon.data and Addon.data.zoneNameIndex
  if not nameIndex then return zoneName end
  
  -- Direct match
  if nameIndex[zoneName] then return zoneName end
  
  -- Known API variations
  if ZONE_NAME_CORRECTIONS[zoneName] and nameIndex[ZONE_NAME_CORRECTIONS[zoneName]] then
    return ZONE_NAME_CORRECTIONS[zoneName]
  end
  
  -- Return original if no normalization found
  return zoneName
end

--[[
  Check if player is currently in the specified zone.
  Handles capitals by checking if player's current zone has a parentZone matching the target.
  
  @param zoneName string - Zone to check against
  @param currentZone string - Player's current zone from GetZoneText()
  @return boolean
]]
local function isPlayerInZone(zoneName, currentZone)
  if zoneName == currentZone then return true end
  
  -- Check if current zone is a capital whose partOf matches the target
  local nameIndex = Addon.data and Addon.data.zoneNameIndex
  if nameIndex then
    local currentMapID = nameIndex[currentZone]
    if currentMapID then
      local currentZoneData = Addon.data.zones[currentMapID]
      if currentZoneData and currentZoneData.partOf then
        local parentData = Addon.data.zones[currentZoneData.partOf]
        if parentData and parentData.name == zoneName then
          return true
        end
      end
    end
  end
  
  return false
end

-- ============================================================================
-- PET BATTLE SOURCE PARSING
-- ============================================================================

--[[
  Parse Pet Battle source text to extract zone names.
  Format: "Pet Battle: Zone1, Zone2, Zone3" (may appear after description text)
  
  @param sourceText string - The source text from C_PetJournal
  @return table|nil - Array of zone names, or nil if not a Pet Battle source
]]
local function parsePetBattleZones(sourceText)
  if not sourceText then return nil end
  
  -- Strip WoW color codes before matching (API returns colored text)
  local cleaned = stripColorCodes(sourceText)
  
  -- Find "Pet Battle:" anywhere in the string (not just at start)
  local zonesStr = cleaned:match("Pet Battle:%s*([^\n|]+)")
  if not zonesStr then return nil end
  
  -- Split by comma and trim each zone name
  local zones = {}
  for zone in zonesStr:gmatch("[^,]+") do
    zone = zone:match("^%s*(.-)%s*$")  -- trim whitespace
    if zone and zone ~= "" then
      table.insert(zones, zone)
    end
  end
  
  return #zones > 0 and zones or nil
end

--[[
  Parse Pet Battle source text to extract spawn conditions.
  Conditions appear on separate lines after "Pet Battle: zones"
  Format examples:
    "Pet Battle: The Storm Peaks\n\nWeather: Snow"
    "Pet Battle: Duskwood\n\nTime: Night"
    "Pet Battle: The Jade Forest\n\nFaction: Order of the Cloud Serpent (Exalted)"
  
  @param sourceText string - The source text from C_PetJournal
  @return string|nil - Condition value (e.g., "Snow", "Night")
]]
local function parsePetBattleCondition(sourceText)
  if not sourceText then return nil end
  
  local cleaned = stripColorCodes(sourceText)
  cleaned = cleaned:gsub("|n", "\n")
  
  -- Look for condition patterns (Weather, Time, Season, Faction, Event)
  local condition = cleaned:match("Weather:%s*([^\n]+)")
                 or cleaned:match("Time:%s*([^\n]+)")
                 or cleaned:match("Season:%s*([^\n]+)")
                 or cleaned:match("Faction:%s*([^\n]+)")
                 or cleaned:match("Event:%s*([^\n]+)")
  
  if condition then
    return condition:match("^%s*(.-)%s*$")  -- trim whitespace
  end
  
  return nil
end

--[[
  Group zones by continent using zone data.
  
  @param zoneNames table - Array of zone name strings
  @return table - { [continent] = { {name, data}, ... }, ... }
  @return table - Array of continent names in display order
]]
local function groupZonesByContinent(zoneNames)
  local nameIndex = Addon.data and Addon.data.zoneNameIndex
  if not nameIndex then return {}, {} end
  
  local grouped = {}  -- keyed by continent display name
  local continentOrder = Addon.data.continentOrder or {}
  
  for _, zoneName in ipairs(zoneNames) do
    local normalizedName = normalizeZoneName(zoneName)
    local mapID = nameIndex[normalizedName]
    if mapID then
      local data = Addon.data.zones[mapID]
      local continent = data.continent and Addon.data:getContinentName(data.continent) or "Unknown"
      if not grouped[continent] then
        grouped[continent] = {}
      end
      table.insert(grouped[continent], {name = normalizedName, data = data})
    end
  end
  
  -- Build ordered list using continentOrder (integer IDs → display names)
  local orderedContinents = {}
  for _, continentID in ipairs(continentOrder) do
    local name = Addon.data:getContinentName(continentID)
    if name and grouped[name] then
      table.insert(orderedContinents, name)
    end
  end
  
  -- Add any unknown continents at the end
  for continent in pairs(grouped) do
    local found = false
    for _, c in ipairs(orderedContinents) do
      if c == continent then found = true; break end
    end
    if not found then
      table.insert(orderedContinents, continent)
    end
  end
  
  return grouped, orderedContinents
end

-- ============================================================================
-- PET BATTLE TOOLTIP RENDERING
-- ============================================================================

local ZEBRA_COLOR = {0.15, 0.15, 0.15, 0.6}

--[[
  Render the enhanced Pet Battle zone tooltip.
  
  @param tip table - The tooltip module
  @param zoneNames table - Array of zone name strings
  @param condition string|nil - Spawn condition (e.g., "Snow", "Night")
]]
local function renderPetBattleTooltip(tip, zoneNames, condition)
  tip:space(16)
  
  -- Render condition block if present (two-line format with centered icon)
  if condition then
    -- Expand terse conditions to descriptive text
    local expandedCondition = CONDITION_EXPANSIONS[condition] or condition
    
    tip:iconBlock({
      {text = "Requirement:", color = ZONE_COLORS.HEADER},
      {text = expandedCondition, color = ZONE_COLORS.CONDITION},
    }, {
      icon = CAUTION_ICON,
      iconSize = 16,
      iconSpacing = 6,
      textureName = "cautionIcon",
      lineSpacing = 2,
    })
    
    tip:space(16)  -- Same spacing as flavor to content
  end
  
  -- Get player location info
  local currentZone, currentContinent, playerLevel = getPlayerLocationContext()
  
  -- Group zones by continent
  local grouped, orderedContinents = groupZonesByContinent(zoneNames)
  
  -- Count total zones for truncation
  local totalZones = #zoneNames
  local displayedZones = 0
  local truncated = false
  local isFirstContinent = true
  
  -- Render each continent group
  for _, continent in ipairs(orderedContinents) do
    local zones = grouped[continent]
    if zones and #zones > 0 then
      if displayedZones >= MAX_ZONES_DISPLAY then
        truncated = true
        break
      end
      
      -- Vertical space between continent groups
      if not isFirstContinent then
        tip:space(12)
      end
      isFirstContinent = false
      
      -- Continent header: star suffix if player is here
      tip:text(formatContinentText(continent, currentContinent), {color = ZONE_COLORS.HEADER})
      tip:space(6)
      
      -- Render zones in this continent
      local zoneIndex = 0
      for _, zoneEntry in ipairs(zones) do
        if displayedZones >= MAX_ZONES_DISPLAY then
          truncated = true
          break
        end
        
        -- 3px gap between zone rows
        if zoneIndex > 0 then
          tip:space(3)
        end
        
        local zoneName = zoneEntry.name
        local data = zoneEntry.data
        
        -- Zone level coloring (green/yellow/red based on player level)
        local levelColor = getLevelColor(data.levelRange, playerLevel)
        
        -- Build zone text: "  Zone Name (zone-level)" — star suffix after level if current zone
        local zoneText = "  " .. zoneName
        local isCurrentZone = isPlayerInZone(zoneName, currentZone)
        if data.levelRange then
          zoneText = zoneText .. " " .. colorCode(levelColor) .. "(" .. formatLevelRange(data.levelRange) .. ")|r"
        end
        if isCurrentZone then
          zoneText = zoneText .. "*"
        end
        
        local petStr = formatLevelRange(data.petLevelRange)
        
        -- Zebra stripe on alternating rows
        local bgColor = (zoneIndex % 2 == 1) and ZEBRA_COLOR or nil
        
        tip:row(
          {text = zoneText, color = ZONE_COLORS.OTHER, background = bgColor},
          {text = petStr, color = ZONE_COLORS.OTHER, rightAlign = true}
        )
        
        zoneIndex = zoneIndex + 1
        displayedZones = displayedZones + 1
      end
    end
  end
  
  -- Show truncation message if needed
  if truncated then
    tip:space(4)
    local remaining = totalZones - displayedZones
    tip:text("... and " .. remaining .. " more zone" .. (remaining > 1 and "s" or ""), 
      {color = {0.6, 0.6, 0.6}})
  end
  
  -- Handle zones not found in our data
  local unknownZones = {}
  local nameIndex = Addon.data and Addon.data.zoneNameIndex
  if nameIndex then
    for _, zoneName in ipairs(zoneNames) do
      local normalizedName = normalizeZoneName(zoneName)
      if not nameIndex[normalizedName] then
        table.insert(unknownZones, zoneName)
      end
    end
  end
  
  if #unknownZones > 0 and not truncated then
    tip:space(8)
    tip:text("Other:", {color = ZONE_COLORS.HEADER})
    tip:space(3)
    for _, zoneName in ipairs(unknownZones) do
      tip:text("  " .. zoneName, {color = ZONE_COLORS.OTHER})
    end
  end
end

-- ============================================================================
-- STANDARD SOURCE TOOLTIP RENDERING
-- ============================================================================

--[[
  Render standard source tooltip (non-Pet Battle sources).
  Cleans up Blizzard's sourceText formatting.
  
  @param tip table - The tooltip module
  @param sourceText string - Raw source text from C_PetJournal
]]
local function renderStandardTooltip(tip, sourceText)
  tip:space(4)
  
  -- Parse |n separated lines
  local lines = {}
  local current = 1
  while current <= #sourceText do
    local nextNewline = sourceText:find("|n", current, true)
    if not nextNewline then
      table.insert(lines, sourceText:sub(current))
      break
    end
    table.insert(lines, sourceText:sub(current, nextNewline - 1))
    current = nextNewline + 2
  end
  
  for _, line in ipairs(lines) do
    line = line:match("^%s*(.-)%s*$") or line  -- trim
    if line ~= "" then
      -- Strip existing color codes
      line = line:gsub("|c%x%x%x%x%x%x%x%x", "")
      line = line:gsub("|r", "")
      
      -- Fix broken texture strings for money icons
      if line:find("|T") then
        line = line:gsub("|T[^|]*|t", function(originalTexture)
          if originalTexture:find("SILVERICON") or originalTexture:find("SilverIcon") then
            return "|TInterface\\MoneyFrame\\UI-SilverIcon:0|t"
          elseif originalTexture:find("COPPERICON") or originalTexture:find("CopperIcon") then
            return "|TInterface\\MoneyFrame\\UI-CopperIcon:0|t"
          else
            return "|TInterface\\MoneyFrame\\UI-GoldIcon:0|t"
          end
        end)
      end
      
      -- Format "Label:" portions with gold color
      local label, rest = line:match("^([^:]+):%s*(.*)")
      if label and rest and rest ~= "" then
        tip:text("|cffffd100" .. label .. ":|r " .. rest, {wrap = true})
      else
        tip:text(line, {wrap = true, color = {0.9, 0.9, 0.9}})
      end
    end
  end
end

-- ============================================================================
-- DROP SOURCE PARSING & RENDERING
-- ============================================================================

--[[
  Parse drop source text to extract mob name and zone.
  Format: "Drop: MobName\nZone: ZoneName" (newlines may be |n)
  
  @param sourceText string - The source text from C_PetJournal
  @return table|nil - {mob = string, zone = string} or nil
]]
local function parseDropSource(sourceText)
  if not sourceText then return nil end
  
  local cleaned = stripColorCodes(sourceText)
  
  -- Normalize newlines (API uses |n)
  cleaned = cleaned:gsub("|n", "\n")
  
  local mob = cleaned:match("^Drop:%s*([^\n]+)")
  if not mob then return nil end
  mob = mob:match("^%s*(.-)%s*$")
  
  local zone = cleaned:match("Zone:%s*([^\n]+)")
  if zone then
    zone = zone:match("^%s*(.-)%s*$")
  end
  
  -- "World Drop" has no specific mob — the mob field IS "World Drop"
  local isWorldDrop = mob:lower():find("world") ~= nil
  
  return {mob = mob, zone = zone, isWorldDrop = isWorldDrop}
end

--[[
  Parse vendor source text to extract vendor, zone, cost, and faction info.
  Handles multiple formats:
    - Simple: "Vendor: Name\nZone: X\nCost: Y"
    - World Event: "World Event: Name\nVendor: X\nZone: Y\nCost: Z"
    - Multi-vendor: Multiple vendor blocks separated by blank lines
  
  @param sourceText string - The source text from C_PetJournal
  @return table|nil - {vendorEntries = table, worldEvent = string, faction = string, standing = string, isBreanni = boolean} or nil
]]
local function parseVendorSource(sourceText)
  if not sourceText then return nil end
  
  local cleaned = stripColorCodes(sourceText)
  
  -- Normalize newlines
  cleaned = cleaned:gsub("|n", "\n")
  
  -- Check for World Event prefix
  local worldEvent = cleaned:match("^World Event:%s*([^\n]+)")
  
  -- Must have at least one Vendor: line
  if not cleaned:find("Vendor:") then return nil end
  
  -- Parse faction (could be "Faction:" or "Reputation:") - applies to all vendors
  local factionStr = cleaned:match("Faction:%s*([^\n]+)") or cleaned:match("Reputation:%s*([^\n]+)")
  local faction, standing
  if factionStr then
    factionStr = factionStr:match("^%s*(.-)%s*$")
    faction, standing = factionStr:match("(.-)%s*%-%s*(.+)")
    if not faction then
      faction = factionStr
    end
  end
  
  -- Split into vendor blocks (separated by double newlines or "Vendor:" markers)
  local vendorEntries = {}
  local isBreanni = false
  
  -- Find all vendor blocks
  local pos = 1
  while true do
    -- Find next Vendor: line
    local vendorStart, vendorEnd, vendorName = cleaned:find("Vendor:%s*([^\n]+)", pos)
    if not vendorStart then break end
    
    vendorName = vendorName:match("^%s*(.-)%s*$")
    
    -- Find the end of this vendor block (next Vendor: or end of string)
    local nextVendor = cleaned:find("\nVendor:", vendorEnd)
    local blockEnd = nextVendor and (nextVendor - 1) or #cleaned
    local block = cleaned:sub(vendorEnd + 1, blockEnd)
    
    -- Parse zone and cost from this block
    local zoneStr = block:match("Zone:%s*([^\n]+)")
    local blockZones = {}
    if zoneStr then
      -- Split comma-separated zones
      for zone in zoneStr:gmatch("[^,]+") do
        zone = zone:match("^%s*(.-)%s*$")
        if zone and zone ~= "" then
          table.insert(blockZones, zone)
        end
      end
    end
    
    local cost = block:match("Cost:%s*([^\n]+)")
    if cost then
      cost = cost:match("^%s*(.-)%s*$")
    end
    
    -- Handle comma-separated vendor names (e.g., "Halpa, Naleen")
    -- Create entry for each vendor+zone combination
    for name in vendorName:gmatch("[^,]+") do
      name = name:match("^%s*(.-)%s*$")
      if name and name ~= "" then
        if #blockZones > 0 then
          for _, zone in ipairs(blockZones) do
            table.insert(vendorEntries, {
              name = name,
              zone = zone,
              cost = cost,
            })
          end
        else
          table.insert(vendorEntries, {
            name = name,
            zone = nil,
            cost = cost,
          })
        end
        
        if name:lower():find("breanni") then
          isBreanni = true
        end
      end
    end
    
    pos = vendorEnd + 1
  end
  
  if #vendorEntries == 0 then return nil end
  
  return {
    vendorEntries = vendorEntries,
    faction = faction,
    standing = standing,
    worldEvent = worldEvent,
    isBreanni = isBreanni,
  }
end

--[[
  Render enhanced drop source tooltip with mob, zone, and continent info.
  
  @param tip table - The tooltip module
  @param dropInfo table - {mob = string, zone = string}
]]
local function renderDropTooltip(tip, dropInfo)
  local currentZone, currentContinent, playerLevel = getPlayerLocationContext()
  
  -- Look up zone data from outdoor zones then instances
  local zoneData, instanceData
  local zoneMapID
  if dropInfo.zone then
    local nameIndex = Addon.data and Addon.data.zoneNameIndex
    zoneMapID = nameIndex and nameIndex[dropInfo.zone]
    zoneData = zoneMapID and Addon.data.zones[zoneMapID]
    if not zoneData and Addon.data and Addon.data.instances then
      instanceData = Addon.data.instances[dropInfo.zone]
      zoneData = instanceData
    end
  end
  
  -- Mob name with boss skull for instance mobs
  tip:space(16)
  if not dropInfo.isWorldDrop then
    if instanceData then
      -- Boss skull icon + mob name
      tip:iconText("Interface\\TargetingFrame\\UI-RaidTargetingIcon_8", dropInfo.mob, {
        iconWidth = 13, iconHeight = 18, iconOffsetY = 4, textOffsetY = -2, color = MOB_COLORS.BOSS,
      })
    else
      -- Rare star icon + mob name
      tip:iconText("Interface\\AddOns\\PawAndOrder\\textures\\rare-star.png", dropInfo.mob, {
        iconSize = 14, textOffsetY = -1, color = MOB_COLORS.OUTDOOR,
      })
    end
  end
  
  -- Zone info: left-aligned, color and spacing provide hierarchy
  if dropInfo.zone and zoneData then
    tip:space(8)
    
    -- Continent: both zones and instances store continent as integer ID
    local continent = Addon.data:getContinentName(zoneData.continent) or "Unknown"
    tip:text(formatContinentText(continent, currentContinent), {color = ZONE_COLORS.HEADER})
    tip:space(4)
    
    -- Zone with level range and instance type: star suffix at end if current zone
    local levelColor = getLevelColor(zoneData.levelRange, playerLevel)
    local zoneText = "  " .. dropInfo.zone
    local isCurrentZone = isPlayerInZone(dropInfo.zone, currentZone)
    if zoneData.levelRange then
      zoneText = zoneText .. " " .. colorCode(levelColor) .. "(" .. formatLevelRange(zoneData.levelRange) .. ")|r"
    end
    if instanceData and instanceData.instanceType then
      local typeLabel
      if instanceData.players then
        typeLabel = instanceData.players .. "-Player "
      else
        typeLabel = ""
      end
      typeLabel = typeLabel .. (instanceData.instanceType == "raid" and "Raid" or "Dungeon")
      zoneText = zoneText .. "  |cff808080" .. typeLabel .. "|r"
    end
    if isCurrentZone then
      zoneText = zoneText .. "*"
    end
    
    tip:text(zoneText, {color = ZONE_COLORS.OTHER})
  elseif dropInfo.zone then
    tip:space(8)
    tip:text(dropInfo.zone, {color = ZONE_COLORS.OTHER})
  end
end

--[[
  Format cost string with coin icons for gold/silver/copper.
  Non-standard currencies get an icon from the registry plus the currency name.
  
  @param cost string - Cost string like "50 gold" or "15 Platinum Coin"
  @return string - Formatted cost with icons
]]
local CURRENCY_ICONS = {
  ["Platinum Coin"]    = 901746,
  ["Burning Blossom"]  = 134020,
  ["Love Token"]       = 135453,
}

local function formatCost(cost)
  if not cost then return nil end
  
  local display = cost
  -- Use :0:0:0:-3 for icon sizing and vertical offset (3px down)
  display = display:gsub("(%d+)%s*gold", "%1 |T" .. COIN_ICONS.gold .. ":0:0:0:-3|t")
  display = display:gsub("(%d+)%s*silver", "%1 |T" .. COIN_ICONS.silver .. ":0:0:0:-3|t")
  display = display:gsub("(%d+)%s*copper", "%1 |T" .. COIN_ICONS.copper .. ":0:0:0:-3|t")
  
  -- If no gold/silver/copper matched, check the currency icon registry
  if display == cost then
    for currencyName, iconID in pairs(CURRENCY_ICONS) do
      local pattern = "(%d+)%s*" .. currencyName
      if cost:find(pattern) then
        display = cost:gsub(pattern, "%1 |T" .. iconID .. ":0:0:0:-3|t " .. currencyName)
        break
      end
    end
  end
  
  return display
end

--[[
  Normalize vendor zone name for display.
  "Stormwind City" → "Stormwind" for cleaner vendor display.
  
  @param zoneName string
  @return string
]]
local function normalizeVendorZone(zoneName)
  if not zoneName then return nil end
  return VENDOR_ZONE_CORRECTIONS[zoneName] or zoneName
end

--[[
  Get Darkmoon Island portal zone based on player faction.
  Darkmoon Faire is accessed via portals in faction-specific zones.
  
  @param zoneName string - Zone to check
  @return table|nil - {portalZone = string} or nil if not Darkmoon Island
]]
local function getDarkmoonPortalInfo(zoneName)
  if zoneName ~= "Darkmoon Island" then return nil end
  
  local faction = UnitFactionGroup("player")
  if faction == "Alliance" then
    return { portalZone = "Elwynn Forest" }
  else
    return { portalZone = "Mulgore" }
  end
end

--[[
  Check if a zone is a capital city or sanctuary (no level range shown).
  
  @param zoneName string
  @return boolean
]]
local function isCapitalOrSanctuary(zoneName)
  return CAPITALS_AND_SANCTUARIES[zoneName] or false
end

--[[
  Check if vendor should be filtered by faction.
  Returns the faction-appropriate zone for Guild Vendor, or nil if no filtering needed.
  
  @param vendorName string
  @param zone string
  @return string|nil - Filtered zone or nil
]]
local function getGuildVendorZone(vendorName, zone)
  if vendorName ~= "Guild Vendor" then return nil end
  
  local faction = UnitFactionGroup("player")
  if faction == "Alliance" then
    return "Stormwind"
  else
    return "Orgrimmar"
  end
end

--[[
  Render vendor source tooltip with vendor names, zones, cost, and requirements.
  New format: Vendor name(s), Zone (level), Continent - US mail style
  
  @param tip table - The tooltip module
  @param vendorInfo table - {vendorEntries, worldEvent, faction, standing, isBreanni, ...}
]]
local function renderVendorTooltip(tip, vendorInfo)
  local currentZone, currentContinent, playerLevel = getPlayerLocationContext()
  tip:space(16)
  
  -- Requirement blocks (achievement gate, guild reputation, world event, faction)
  local requirements = {}
  if vendorInfo.achievementGate then
    table.insert(requirements, {text = vendorInfo.achievementGate, label = "Achievement:", textureName = "vendorAchIcon"})
  end
  if vendorInfo.guildReputation then
    table.insert(requirements, {text = "Guild - " .. vendorInfo.guildReputation, label = "Reputation:", textureName = "vendorGuildRepIcon"})
  end
  if vendorInfo.worldEvent then
    table.insert(requirements, {text = vendorInfo.worldEvent, textureName = "vendorEventIcon"})
  end
  if vendorInfo.faction then
    local factionText = vendorInfo.faction
    if vendorInfo.standing then
      factionText = factionText .. " (" .. vendorInfo.standing .. ")"
    end
    table.insert(requirements, {text = factionText, textureName = "vendorFactionIcon"})
  end
  
  for i, req in ipairs(requirements) do
    if i > 1 then
      tip:space(8)
    end
    tip:iconBlock({
      {text = req.label or "Requirement:", color = ZONE_COLORS.HEADER},
      {text = req.text, color = ZONE_COLORS.CONDITION},
    }, {
      icon = CAUTION_ICON,
      iconSize = 16,
      iconSpacing = 6,
      textureName = req.textureName,
      lineSpacing = 2,
    })
  end
  
  local vendorEntries = vendorInfo.vendorEntries or {}
  
  -- Expand __faction_capitals__ entries into per-capital entries
  local expandedEntries = {}
  local playerFaction = UnitFactionGroup("player")
  local factionCapitals = {
    Alliance = {"Stormwind", "Ironforge", "Darnassus", "The Exodar"},
    Horde = {"Orgrimmar", "Thunder Bluff", "Undercity", "Silvermoon City"},
  }
  for _, entry in ipairs(vendorEntries) do
    if entry.zone == "__faction_capitals__" then
      local capitals = factionCapitals[playerFaction] or factionCapitals["Alliance"]
      for _, capital in ipairs(capitals) do
        table.insert(expandedEntries, {
          name = entry.name,
          zone = capital,
          cost = entry.cost,
        })
      end
    else
      table.insert(expandedEntries, entry)
    end
  end
  
  -- Build filtered and grouped vendor list
  -- Group vendors by zone, filter by faction where needed
  local vendorsByZone = {}
  local zoneOrder = {}
  
  for _, entry in ipairs(expandedEntries) do
    local zone = entry.zone
    local vendorName = entry.name
    
    -- Per-entry faction filter: skip entries not matching player faction
    if not entry.faction or entry.faction == playerFaction then
      -- Check for Guild Vendor faction filtering
      local guildZone = getGuildVendorZone(vendorName, zone)
      if guildZone then
        zone = guildZone
      elseif vendorName == "Guild Vendor" then
        -- Skip if no zone match
        zone = nil
      end
      
      if zone then
        if not vendorsByZone[zone] then
          vendorsByZone[zone] = {}
          table.insert(zoneOrder, zone)
        end
        
        -- Avoid duplicate vendor names in same zone
        local found = false
        for _, v in ipairs(vendorsByZone[zone]) do
          if v == vendorName then found = true break end
        end
        if not found then
          table.insert(vendorsByZone[zone], vendorName)
        end
      end
    end
  end
  
  -- Render each zone group
  local isFirst = true
  local hasRequirements = #requirements > 0
  for _, zone in ipairs(zoneOrder) do
    local vendors = vendorsByZone[zone]
    
    if not isFirst or hasRequirements then
      tip:space(16)
    end
    isFirst = false
    
    -- Render vendor names (comma-separated on one line)
    tip:text(table.concat(vendors, ", "), {color = VENDOR_COLORS.NAME})
    
    -- Then render zone/continent
    if zone then
      tip:space(6)
      
      -- Check for Darkmoon Island
      local darkmoonInfo = getDarkmoonPortalInfo(zone)
      local displayZoneName = zone
      if darkmoonInfo then
        tip:text("Darkmoon Island", {color = ZONE_COLORS.OTHER})
        tip:space(3)
        displayZoneName = darkmoonInfo.portalZone
      end
      
      -- Normalize zone name
      local displayZone = normalizeVendorZone(displayZoneName)
      local normalizedZone = normalizeZoneName(displayZone)
      local nameIndex = Addon.data and Addon.data.zoneNameIndex
      local zoneMapID = nameIndex and nameIndex[normalizedZone]
      local data = zoneMapID and Addon.data.zones[zoneMapID]
      
      -- Zone line with optional level range
      local isCurrentZone = isPlayerInZone(normalizedZone, currentZone)
      local zoneText = displayZone
      
      if data and data.levelRange and not isCapitalOrSanctuary(displayZone) then
        local levelColor = getLevelColor(data.levelRange, playerLevel)
        zoneText = zoneText .. " " .. colorCode(levelColor) .. "(" .. formatLevelRange(data.levelRange) .. ")|r"
      end
      
      if isCurrentZone then
        zoneText = zoneText .. "*"
      end
      
      tip:text(zoneText, {color = ZONE_COLORS.OTHER})
      
      -- Continent line
      if data and data.continent then
        tip:space(3)
        local continent = Addon.data:getContinentName(data.continent) or "Unknown"
        tip:text(formatContinentText(continent, currentContinent), {color = ZONE_COLORS.HEADER})
      end
    end
  end
  
  -- Cost
  local sharedCost = vendorEntries[1] and vendorEntries[1].cost
  if sharedCost then
    tip:space(16)
    tip:text("Cost: " .. formatCost(sharedCost), {color = {1, 1, 1}})
  end
  
  -- Debug: warn if vendor entries have no matching NPC data (once per vendor)
  if pao_settings and pao_settings.debugMode then
    local npcs = Addon.data and Addon.data.npcs
    if npcs then
      sourceTooltip._warnedVendors = sourceTooltip._warnedVendors or {}
      for _, entry in ipairs(vendorEntries) do
        local vendorName = entry.name
        if not sourceTooltip._warnedVendors[vendorName] then
          local found = false
          for _, npcData in pairs(npcs) do
            if npcData.name == vendorName then
              found = true
              break
            end
          end
          if not found and Addon.utils then
            Addon.utils:debug("Missing NPC data for vendor: " .. vendorName)
            sourceTooltip._warnedVendors[vendorName] = true
          end
        end
      end
    end
  end
end

-- ============================================================================
-- TRADING CARD GAME SOURCE PARSING & RENDERING
-- ============================================================================

--[[
  Parse Trading Card Game source text to extract the expansion name.
  Format: "Trading Card Game: Expansion: Sub-expansion"
  
  @param sourceText string - The source text from C_PetJournal
  @return string|nil - Expansion name (everything after "Trading Card Game: "), or nil
]]
local function parseTCGSource(sourceText)
  if not sourceText then return nil end
  
  local cleaned = stripColorCodes(sourceText)
  cleaned = cleaned:gsub("|n", "\n")
  
  local expansion = cleaned:match("^Trading Card Game:%s*(.+)")
  if not expansion then return nil end
  
  -- Trim and take only the first line
  expansion = expansion:match("^([^\n]+)")
  if expansion then
    expansion = expansion:match("^%s*(.-)%s*$")
  end
  
  return expansion
end

--[[
  Apply text corrections from sourceOverrides to a display string.
  
  @param text string - Text to correct
  @param corrections table - {["wrong"] = "right", ...}
  @return string - Corrected text
]]
local function applyTextCorrections(text, corrections)
  if not text or not corrections then return text end
  for wrong, right in pairs(corrections) do
    text = text:gsub(wrong, right)
  end
  return text
end

--[[
  Render Trading Card Game source tooltip with expansion name
  and optional vendor subsection from override data.
  
  @param tip table - The tooltip module
  @param expansion string - TCG expansion name
  @param vendorInfo table|nil - Vendor info from override, or nil
]]
local function renderTCGTooltip(tip, expansion, vendorInfo)
  -- Expansion name
  tip:space(16)
  tip:text(expansion, {color = ZONE_COLORS.CONDITION})
  
  -- Optional vendor subsection
  if vendorInfo then
    tip:space(16)
    tip:separator()
    tip:space(4)
    tip:text("Also Available From:", {color = ZONE_COLORS.HEADER})
    renderVendorTooltip(tip, vendorInfo)
  end
end

-- ============================================================================
-- ACHIEVEMENT SOURCE PARSING & RENDERING
-- ============================================================================

--[[
  Parse Achievement source text to extract achievement name and category.
  Format: "Achievement: Name\nCategory: Category"
  Variant: "Achievement: Name Part1\nName Part2\nAchievement: Category"
  Last line is always the category (prefix stripped). All preceding lines
  form the achievement name (first line's "Achievement:" prefix stripped).
  
  @param sourceText string - The source text from C_PetJournal
  @return table|nil - {name = string, category = string} or nil
]]
local function parseAchievementSource(sourceText)
  if not sourceText then return nil end
  
  local cleaned = stripColorCodes(sourceText)
  cleaned = cleaned:gsub("|n", "\n")
  
  -- Must start with "Achievement:"
  if not cleaned:match("^Achievement:") then return nil end
  
  -- Split into lines
  local lines = {}
  for line in cleaned:gmatch("[^\n]+") do
    local trimmed = line:match("^%s*(.-)%s*$")
    if trimmed and trimmed ~= "" then
      table.insert(lines, trimmed)
    end
  end
  
  if #lines == 0 then return nil end
  
  -- First line: strip "Achievement:" prefix to start the name
  local name = lines[1]:match("^Achievement:%s*(.+)") or lines[1]
  
  -- Middle lines (if any): name continuations
  for i = 2, #lines - 1 do
    -- Strip any prefix from continuation lines too
    local linePart = lines[i]:match("^[^:]+:%s*(.+)")
    name = name .. " " .. (linePart or lines[i])
  end
  
  -- Last line: category (strip "Category:" or "Achievement:" prefix)
  local category
  if #lines >= 2 then
    local lastLine = lines[#lines]
    category = lastLine:match("^Category:%s*(.+)")
             or lastLine:match("^Achievement:%s*(.+)")
             or lastLine
  end
  
  return {name = name, category = category}
end

-- Achievement breadcrumb cache: achievementID -> breadcrumb string
local achievementBreadcrumbCache = {}

-- Known category name corrections (Blizzard inconsistencies)
local CATEGORY_CORRECTIONS = {
  ["Pet Battle"] = "Pet Battles",
}

--[[
  Build a full category breadcrumb for an achievement using static data
  and the WoW achievement API.
  
  Looks up the achievementID from Addon.data.achievementBySpecies, then
  uses GetAchievementCategory to get the category and walks up the parent
  chain to build "Parent > Child > Grandchild" breadcrumb.
  
  Results are cached per achievementID.
  
  @param speciesID number - Species ID to look up achievement for
  @return string|nil - Breadcrumb like "Pet Battles > Collect", or nil
]]
local function buildAchievementBreadcrumb(speciesID)
  if not speciesID then return nil end
  
  local achievementData = Addon.data and Addon.data.achievementBySpecies
  if not achievementData then return nil end
  
  local achievementID = achievementData[speciesID]
  if not achievementID then return nil end
  
  -- Check cache
  if achievementBreadcrumbCache[achievementID] ~= nil then
    local cached = achievementBreadcrumbCache[achievementID]
    return cached ~= false and cached or nil
  end
  
  -- Get category directly from achievementID — works for hidden chain members too
  local categoryID = GetAchievementCategory(achievementID)
  if not categoryID then
    achievementBreadcrumbCache[achievementID] = false
    return nil
  end
  
  -- Walk up the parent chain to build breadcrumb
  local parts = {}
  local currentID = categoryID
  local safety = 10
  while currentID and safety > 0 do
    local catName, parentID = GetCategoryInfo(currentID)
    if catName then
      table.insert(parts, 1, catName)
    end
    if not parentID or parentID == -1 or parentID == 0 then
      break
    end
    currentID = parentID
    safety = safety - 1
  end
  
  if #parts == 0 then
    achievementBreadcrumbCache[achievementID] = false
    return nil
  end
  
  local breadcrumb = table.concat(parts, " > ")
  achievementBreadcrumbCache[achievementID] = breadcrumb
  return breadcrumb
end

--[[
  Render Achievement source tooltip with achievement name and category.
  
  @param tip table - The tooltip module
  @param achievementInfo table - {name = string, category = string}
  @param speciesID number - Species ID for achievement lookup
]]
local function renderAchievementTooltip(tip, achievementInfo, speciesID)
  -- Achievement name
  tip:space(16)
  tip:text(achievementInfo.name, {color = ZONE_COLORS.CONDITION})
  
  -- Category with breadcrumb from static data + API
  if achievementInfo.category then
    tip:space(6)
    
    -- Try static data breadcrumb first
    local breadcrumb = buildAchievementBreadcrumb(speciesID)
    if breadcrumb then
      tip:text(breadcrumb)
    else
      -- Fallback to TT category with corrections
      local category = achievementInfo.category:gsub(" and ", " & ")
      category = CATEGORY_CORRECTIONS[category] or category
      local debugMarker = (pao_settings and pao_settings.debugMode) and "  |cffff4444[TT]|r" or ""
      tip:text(category .. debugMarker)
    end
  end
end

-- ============================================================================
-- QUEST SOURCE PARSING & RENDERING
-- ============================================================================

--[[
  Parse Quest source text to detect quest-sourced pets.
  Format: "Quest: Quest Name" or "Quest: Quest Name\nZone: ZoneName"
  Also matches bare "Quest" with no details.
  
  @param sourceText string - The source text from C_PetJournal
  @return table|nil - {name = string|nil, zone = string|nil} or nil
]]
local function parseQuestSource(sourceText)
  if not sourceText then return nil end
  
  local cleaned = stripColorCodes(sourceText)
  cleaned = cleaned:gsub("|n", "\n")
  
  if not cleaned:match("^Quest") then return nil end
  
  local name = cleaned:match("^Quest:%s*([^\n]+)")
  if name then
    name = name:match("^%s*(.-)%s*$")
  end
  
  local zone = cleaned:match("Zone:%s*([^\n]+)")
  if zone then
    zone = zone:match("^%s*(.-)%s*$")
  end
  
  return {name = name, zone = zone}
end

-- Resolve Questie's QuestieDB module, or nil if not loaded
-- luacheck: globals QuestieLoader QuestieDB
local function getQuestieDB()
  if QuestieLoader and QuestieLoader.ImportModule then
    local ok, db = pcall(QuestieLoader.ImportModule, QuestieLoader, "QuestieDB")
    if ok and db then return db end
  end
  if QuestieDB then return QuestieDB end
  return nil
end

--[[
  Get NPC name, zone, and coords from Questie.
  
  @param npcId number
  @return table|nil - {name, zone, x, y}
]]
local function getQuestieNpcInfo(npcId)
  if not npcId then return nil end
  local qdb = getQuestieDB()
  if not qdb or not qdb.GetNPC then return nil end
  
  local npc = qdb:GetNPC(npcId)
  if not npc then return nil end
  
  local info = {name = npc.name}
  
  if npc.spawns then
    for zoneId, coords in pairs(npc.spawns) do
      if type(coords) == "table" then
        for _, point in ipairs(coords) do
          if type(point) == "table" and point[1] and point[2]
            and point[1] >= 0 and point[2] >= 0 then
            -- Zone name: area ID -> map ID -> C_Map name
            if QuestieLoader and QuestieLoader.ImportModule then
              local ok, zoneDB = pcall(QuestieLoader.ImportModule, QuestieLoader, "ZoneDB")
              if ok and zoneDB and zoneDB.GetUiMapIdByAreaId then
                local mapID = zoneDB:GetUiMapIdByAreaId(zoneId)
                if mapID and C_Map and C_Map.GetMapInfo then
                  local mapInfo = C_Map.GetMapInfo(mapID)
                  if mapInfo then
                    info.zone = mapInfo.name
                    info.mapID = mapID
                  end
                end
              end
            end
            info.x = math.floor(point[1] * 10 + 0.5) / 10
            info.y = math.floor(point[2] * 10 + 0.5) / 10
            return info
          end
        end
      end
    end
  end
  
  return info
end

--[[
  Get quest data from Questie: name, starter NPC IDs, ender NPC IDs.
  
  @param questId number
  @return table|nil - {name, starters = {npcId, ...}, enders = {npcId, ...},
                       preQuestSingle, preQuestGroup, nextQuestInChain}
]]
local function getQuestieQuestData(questId)
  if not questId then return nil end
  local qdb = getQuestieDB()
  if not qdb then return nil end
  
  local name, preQuestSingle, preQuestGroup, nextQuest, startedBy, finishedBy
  
  if qdb.QueryQuestSingle then
    name = qdb.QueryQuestSingle(questId, "name")
    preQuestSingle = qdb.QueryQuestSingle(questId, "preQuestSingle")
    preQuestGroup = qdb.QueryQuestSingle(questId, "preQuestGroup")
    nextQuest = qdb.QueryQuestSingle(questId, "nextQuestInChain")
    startedBy = qdb.QueryQuestSingle(questId, "startedBy")
    finishedBy = qdb.QueryQuestSingle(questId, "finishedBy")
  end

  -- Fall back to GetQuest if QueryQuestSingle is absent or returned no name
  if not name and qdb.GetQuest then
    local quest = qdb.GetQuest(questId)
    if quest then
      name = quest.name
      preQuestSingle = preQuestSingle or quest.preQuestSingle
      preQuestGroup = preQuestGroup or quest.preQuestGroup
      nextQuest = nextQuest or quest.nextQuestInChain
      startedBy = startedBy or quest.startedBy
      finishedBy = finishedBy or quest.finishedBy
    end
  end
  
  if not name then return nil end
  
  -- startedBy/finishedBy are nested: {npcIds, objectIds, itemIds}
  -- Extract NPC IDs from index [1]
  local starterNpcs = startedBy and type(startedBy) == "table" and startedBy[1] or {}
  local enderNpcs = finishedBy and type(finishedBy) == "table" and finishedBy[1] or {}
  
  return {
    name = name,
    starters = starterNpcs,
    enders = enderNpcs,
    preQuestSingle = preQuestSingle,
    preQuestGroup = preQuestGroup,
    nextQuestInChain = (nextQuest and nextQuest > 0) and nextQuest or nil,
  }
end

--[[
  Build quest chain by walking backward (preQuestSingle) and forward
  (nextQuestInChain) from a given quest ID. Marks each step with completion
  status, identifies the first incomplete step as current position, and
  marks the pet-giving quest for lavender highlighting.
  
  Max 5 steps displayed at once, windowed around current step.
  Truncated portions show count instead of ellipsis.
  
  @param questId number - The pet-reward quest
  @return table|nil - {{questId, name, isCurrent, isPetQuest, complete}, ...}
]]
local MAX_CHAIN_DISPLAY = 5

-- luacheck: ignore buildQuestChain (reserved for future quest chain popup)
local function buildQuestChain(questId)
  local qdb = getQuestieDB()
  if not qdb then return nil end
  
  local canCheck = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
  
  -- Walk backward
  local backward = {}
  local currentId = questId
  local safety = 20
  while safety > 0 do
    safety = safety - 1
    local data = getQuestieQuestData(currentId)
    if not data then break end
    
    local prevId
    if data.preQuestSingle and type(data.preQuestSingle) == "table" and #data.preQuestSingle > 0 then
      prevId = data.preQuestSingle[1]
    end
    
    if not prevId or prevId <= 0 then break end
    table.insert(backward, 1, {questId = prevId})
    currentId = prevId
  end
  
  -- Fill names and completion for backward steps
  for _, step in ipairs(backward) do
    local data = getQuestieQuestData(step.questId)
    step.name = data and data.name or ("Quest #" .. step.questId)
    step.complete = canCheck and C_QuestLog.IsQuestFlaggedCompleted(step.questId) or false
  end
  
  -- Target quest
  local targetData = getQuestieQuestData(questId)
  local chain = {}
  for _, step in ipairs(backward) do
    table.insert(chain, step)
  end
  table.insert(chain, {
    questId = questId,
    name = targetData and targetData.name or ("Quest #" .. questId),
    complete = canCheck and C_QuestLog.IsQuestFlaggedCompleted(questId) or false,
    isPetQuest = true,
  })
  
  -- Walk forward
  currentId = questId
  safety = 20
  while safety > 0 do
    safety = safety - 1
    local data = getQuestieQuestData(currentId)
    if not data or not data.nextQuestInChain then break end
    
    local nextId = data.nextQuestInChain
    local nextData = getQuestieQuestData(nextId)
    table.insert(chain, {
      questId = nextId,
      name = nextData and nextData.name or ("Quest #" .. nextId),
      complete = canCheck and C_QuestLog.IsQuestFlaggedCompleted(nextId) or false,
    })
    currentId = nextId
  end
  
  -- Single quest = no chain to display
  if #chain <= 1 then return nil end
  
  -- Mark first incomplete step as current position
  local currentIdx = nil
  for i, step in ipairs(chain) do
    if not step.complete then
      step.isCurrent = true
      currentIdx = i
      break
    end
  end
  
  -- If chain fits within limit, return all
  if #chain <= MAX_CHAIN_DISPLAY then return chain end
  
  -- Window centered on current step (or end of chain if all complete)
  local centerIdx = currentIdx or #chain
  local halfWindow = math.floor(MAX_CHAIN_DISPLAY / 2)
  local startIdx = math.max(1, centerIdx - halfWindow)
  local endIdx = startIdx + MAX_CHAIN_DISPLAY - 1
  if endIdx > #chain then
    endIdx = #chain
    startIdx = math.max(1, endIdx - MAX_CHAIN_DISPLAY + 1)
  end
  
  local windowed = {}
  if startIdx > 1 then
    local hiddenBefore = startIdx - 1
    table.insert(windowed, {
      name = "(" .. hiddenBefore .. " earlier " .. (hiddenBefore == 1 and "quest" or "quests") .. ")",
      isTruncation = true,
    })
  end
  for i = startIdx, endIdx do
    table.insert(windowed, chain[i])
  end
  if endIdx < #chain then
    local hiddenAfter = #chain - endIdx
    table.insert(windowed, {
      name = "(" .. hiddenAfter .. " more " .. (hiddenAfter == 1 and "quest" or "quests") .. ")",
      isTruncation = true,
    })
  end
  
  return windowed
end

--[[
  Walk a sub-chain backward from branchRootId (a preQuestGroup entry) to its
  start, then locate the first incomplete step and count how many steps remain
  after it within this branch.

  @param branchRootId number - Last quest in this sub-chain (must be complete
                               before the pet quest unlocks)
  @return table|nil - {complete=true} if all done, or
                      {name, questId, questData, remaining, complete=false}
]]
local function buildBranchInfo(branchRootId)
  local canCheck = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted

  -- Walk backward through preQuestSingle to build the full sub-chain
  local chainIds = {}
  local walkId = branchRootId
  local safety = 30
  while safety > 0 do
    safety = safety - 1
    table.insert(chainIds, 1, walkId)
    local data = getQuestieQuestData(walkId)
    if not data then break end
    local prevId
    if data.preQuestSingle and type(data.preQuestSingle) == "table" and #data.preQuestSingle > 0 then
      prevId = data.preQuestSingle[1]
    end
    if not prevId or prevId <= 0 then break end
    walkId = prevId
  end

  if #chainIds == 0 then return nil end

  -- Locate first incomplete step
  local firstIncompleteIdx = nil
  for i, qid in ipairs(chainIds) do
    if not (canCheck and C_QuestLog.IsQuestFlaggedCompleted(qid)) then
      firstIncompleteIdx = i
      break
    end
  end

  if not firstIncompleteIdx then
    return { complete = true }
  end

  local currentId = chainIds[firstIncompleteIdx]
  local currentData = getQuestieQuestData(currentId)

  return {
    complete = false,
    name = currentData and currentData.name or ("Quest #" .. currentId),
    questId = currentId,
    questData = currentData,
    remaining = #chainIds - firstIncompleteIdx,  -- steps after current in this branch
  }
end

--[[
  Build branch info for a pet quest with preQuestGroup entries. Each entry
  is a separate prerequisite sub-chain that must be fully completed before
  the pet quest unlocks.

  @param petQuestId number
  @return table|nil - {branches, allComplete} or nil if no preQuestGroup
]]
local function buildQuestBranches(petQuestId)
  if not getQuestieDB() then return nil end

  -- Walk preQuestSingle spine from pet quest upward, looking for a quest
  -- with a preQuestGroup (the convergence node where multiple chains merge).
  -- The convergence node may not be the pet quest itself.
  local convergenceId = nil
  local walkId = petQuestId
  local safety = 30
  while safety > 0 do
    safety = safety - 1
    local data = getQuestieQuestData(walkId)
    if not data then break end
    local preGroup = data.preQuestGroup
    if preGroup and type(preGroup) == "table" and #preGroup > 0 then
      convergenceId = walkId
      break
    end
    local prevId
    if data.preQuestSingle and type(data.preQuestSingle) == "table" and #data.preQuestSingle > 0 then
      prevId = data.preQuestSingle[1]
    end
    if not prevId or prevId <= 0 then break end
    walkId = prevId
  end

  if not convergenceId then return nil end

  local convergenceData = getQuestieQuestData(convergenceId)
  local preGroup = convergenceData.preQuestGroup

  local branches = {}
  local allComplete = true

  for _, branchId in ipairs(preGroup) do
    local info = buildBranchInfo(branchId)
    if info then
      if not info.complete then allComplete = false end
      table.insert(branches, info)
    end
  end

  if #branches == 0 then return nil end
  return { branches = branches, allComplete = allComplete, convergenceId = convergenceId }
end

--[[
  Resolve a questId field (number or table of numbers) to the first
  quest ID that the player has completed, or the first ID if none complete.
  
  @param questIdField number|table
  @return number - single quest ID
]]
local function resolveQuestId(questIdField)
  if type(questIdField) == "number" then return questIdField end
  if type(questIdField) ~= "table" then return nil end
  
  -- Return first completed, or first available
  if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
    for _, qid in ipairs(questIdField) do
      if C_QuestLog.IsQuestFlaggedCompleted(qid) then
        return qid
      end
    end
  end
  return questIdField[1]
end

--[[
  Check if any quest in a questId field (number or table) is complete.
  
  @param questIdField number|table
  @return boolean
]]
local function isAnyQuestComplete(questIdField)
  if not C_QuestLog or not C_QuestLog.IsQuestFlaggedCompleted then return false end
  if type(questIdField) == "number" then
    return C_QuestLog.IsQuestFlaggedCompleted(questIdField)
  end
  if type(questIdField) == "table" then
    for _, qid in ipairs(questIdField) do
      if C_QuestLog.IsQuestFlaggedCompleted(qid) then return true end
    end
  end
  return false
end

-- Quest giver/ender icon textures
local QUEST_GIVER_ICON = "|TInterface\\GossipFrame\\AvailableQuestIcon:12:12:0:-2|t"
local QUEST_ENDER_ICON = "|TInterface\\GossipFrame\\ActiveQuestIcon:12:12:0:-2|t"
-- Blue daily ender icon (texture ID 368577)
local QUEST_DAILY_ENDER_ICON = "|T368577:12:12:0:-2|t"
-- Combined: -2 x-offset on ender to close the 2px gap
local QUEST_BOTH_ICON = "|TInterface\\GossipFrame\\AvailableQuestIcon:12:12:0:-2|t|TInterface\\GossipFrame\\ActiveQuestIcon:12:12:-2:-2|t"
-- Inline checkmark for completed quests
local QUEST_DONE_MARK = "|TInterface\\RaidFrame\\ReadyCheck-Ready:12:12:0:-2|t "

--[[
  Render zone + continent lines for a quest NPC block.
  Shared helper used by both the standard and deduplicated layouts.

  @param tip table
  @param npcInfo table - From getQuestieNpcInfo
]]
local function renderQuestZoneBlock(tip, npcInfo)
  if not npcInfo.zone then return end

  local currentZone, currentContinent, playerLevel = getPlayerLocationContext()

  local normalizedZone = normalizeZoneName(npcInfo.zone)
  local nameIndex = Addon.data and Addon.data.zoneNameIndex
  local zoneMapID = nameIndex and nameIndex[normalizedZone]
  local data = zoneMapID and Addon.data.zones[zoneMapID]

  local isCurrentZone = isPlayerInZone(normalizedZone, currentZone)
  local zoneText = npcInfo.zone

  if data and data.levelRange and not isCapitalOrSanctuary(npcInfo.zone) then
    local levelColor = getLevelColor(data.levelRange, playerLevel)
    zoneText = zoneText .. " " .. colorCode(levelColor) .. "(" .. formatLevelRange(data.levelRange) .. ")|r"
  end

  if isCurrentZone then zoneText = zoneText .. "*" end
  tip:text(zoneText, {color = ZONE_COLORS.OTHER})

  if data and data.continent then
    tip:space(3)
    local continent = Addon.data:getContinentName(data.continent) or "Unknown"
    tip:text(formatContinentText(continent, currentContinent), {color = ZONE_COLORS.HEADER})
  end
end

--[[
  Unified NPC block renderer. Renders name + coords + zone + continent for any
  NPC regardless of context (quest giver, ender, vendor, faction requirement).
  Always sets sourceTooltip._waypointNpcId so Ctrl-click waypoint works for
  any rendered NPC block.

  @param tip table
  @param npcId number - Questie NPC ID
  @param icon string - Inline texture string prepended to name
  @param opts table - Optional:
    suppressZone boolean - skip zone/continent block
    npcInfo table - pre-fetched npcInfo (skips getQuestieNpcInfo call)
]]
local function renderNpcBlock(tip, npcId, icon, opts)
  opts = opts or {}
  local npcInfo = opts.npcInfo or getQuestieNpcInfo(npcId)
  if not npcInfo then return end

  local nameText = icon .. npcInfo.name
  if npcInfo.x and npcInfo.y then
    nameText = nameText .. string.format(" (%.1f, %.1f)", npcInfo.x, npcInfo.y)
  end
  tip:text(nameText, {color = VENDOR_COLORS.NAME})

  if not opts.suppressZone then
    tip:space(3)
    renderQuestZoneBlock(tip, npcInfo)
  end

  -- Last rendered NPC is the waypoint target
  sourceTooltip._waypointNpcId = npcId
end

--[[
  Render giver/ender NPC blocks for a quest.

  Same NPC: single !? block with full zone info.
  Different NPCs, same zone: giver name, ender name, shared zone block.
  Different NPCs, different zones: each gets its own full block.

  @param tip table
  @param questData table - From getQuestieQuestData
]]
local function renderNpcLines(tip, questData)
  if not questData then return end

  local giverNpc = questData.starters and questData.starters[1]
  local enderNpc = questData.enders and questData.enders[1]

  -- Same NPC: single !? block
  if giverNpc and enderNpc and giverNpc == enderNpc then
    local npcInfo = getQuestieNpcInfo(giverNpc)
    if npcInfo then
      tip:space(8)
      renderNpcBlock(tip, giverNpc, QUEST_BOTH_ICON, {npcInfo = npcInfo})
    end
    return
  end

  local giverInfo = giverNpc and getQuestieNpcInfo(giverNpc)
  local enderInfo = enderNpc and getQuestieNpcInfo(enderNpc)

  -- Same zone: stack names, shared zone block below
  local sameZone = giverInfo and enderInfo
    and giverInfo.zone and giverInfo.zone == enderInfo.zone

  if sameZone then
    tip:space(8)
    renderNpcBlock(tip, giverNpc, QUEST_GIVER_ICON, {npcInfo = giverInfo, suppressZone = true})
    tip:space(3)
    renderNpcBlock(tip, enderNpc, QUEST_ENDER_ICON, {npcInfo = enderInfo, suppressZone = true})
    tip:space(6)
    renderQuestZoneBlock(tip, giverInfo)
    -- Waypoint targets the ender (more actionable when both present)
    sourceTooltip._waypointNpcId = enderNpc
  else
    if giverInfo then
      tip:space(8)
      renderNpcBlock(tip, giverNpc, QUEST_GIVER_ICON, {npcInfo = giverInfo})
    end
    if enderInfo then
      tip:space(8)
      renderNpcBlock(tip, enderNpc, QUEST_ENDER_ICON, {npcInfo = enderInfo})
    end
  end
end

--[[
  Render Quest source tooltip. Questie-driven for giver, ender, zone, chain.
  Static override provides only questId, randomDrop, bagName, dailyQuestId.
  
  @param tip table - The tooltip module
  @param questInfo table - Parsed from sourceText {name, zone}
  @param speciesID number - Species ID for override lookup
]]
--[[
  Find the first incomplete step in a flat preQuestSingle chain and count
  remaining steps between it and the pet quest.

  @param petQuestId number
  @return table|nil - {questId, name, questData, remaining, isPetQuest} or nil if single quest
]]
local function findCurrentStep(petQuestId)
  local canCheck = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted

  -- Walk backward to build the linear chain (excludes preQuestGroup nodes)
  local chainIds = {}
  local walkId = petQuestId
  local safety = 30
  while safety > 0 do
    safety = safety - 1
    local data = getQuestieQuestData(walkId)
    if not data then break end
    local prevId
    if data.preQuestSingle and type(data.preQuestSingle) == "table" and #data.preQuestSingle > 0 then
      prevId = data.preQuestSingle[1]
    end
    if not prevId or prevId <= 0 then break end
    table.insert(chainIds, 1, prevId)
    walkId = prevId
  end
  table.insert(chainIds, petQuestId)

  if #chainIds <= 1 then return nil end  -- single quest, no spine

  for i, qid in ipairs(chainIds) do
    if not (canCheck and C_QuestLog.IsQuestFlaggedCompleted(qid)) then
      local data = getQuestieQuestData(qid)
      -- Steps remaining = entries between current and pet quest (exclusive of both)
      local remaining = math.max(0, #chainIds - i - 1)
      return {
        questId = qid,
        name = data and data.name or ("Quest #" .. qid),
        questData = data,
        remaining = remaining,
        isPetQuest = (qid == petQuestId),
      }
    end
  end
  return nil
end

--[[
  Render Quest source tooltip. Questie-driven for giver, ender, zone, chain.
  Static override provides only questId, randomDrop, bagName, dailyQuestId.

  Layout (all incomplete cases):
    Quest Name                    [lavender]
    ─────────────────────────────
    Current Step Name             [white, omitted if same as pet quest]
    ! Giver (x, y)
      Zone (level)
      Continent
    (N more quests)               [gray, omitted if 0]

    [additional blocks if multiple deduplicated branches]

  @param tip table - The tooltip module
  @param questInfo table - Parsed from sourceText {name, zone}
  @param speciesID number - Species ID for override lookup
]]
local function renderQuestTooltip(tip, questInfo, speciesID)
  local overrides = Addon.data and Addon.data.sourceOverrides
  local speciesOverride = overrides and speciesID and overrides[speciesID]
  local qd = speciesOverride and speciesOverride.questData

  local questId = qd and resolveQuestId(qd.questId)
  -- One-time quest complete check — permanent flag
  local onceComplete = qd and isAnyQuestComplete(qd.questId)
  -- If a daily variant exists, use its completion for the "is it done today?" check
  local dailyId = qd and qd.dailyQuestId
  local dailyComplete = dailyId and isAnyQuestComplete(dailyId)
  -- isComplete: the one that matters for display
  -- One-time done + no daily → fully complete (Case 1)
  -- One-time done + daily not done → show daily context
  local isComplete = onceComplete and (not dailyId or dailyComplete)
  -- Active quest to drive display/waypoint: daily if applicable, else one-time
  local activeQuestId = (dailyId and not dailyComplete and onceComplete) and dailyId or questId

  local questieData = activeQuestId and getQuestieQuestData(activeQuestId)
  local questName = (questieData and questieData.name) or (questInfo and questInfo.name)
  if questName and speciesOverride and speciesOverride.textCorrections then
    questName = applyTextCorrections(questName, speciesOverride.textCorrections)
  end

  -- When showAllQuestNames is set and questId is an array, collect all names
  local questNames = nil
  if qd and qd.showAllQuestNames and type(qd.questId) == "table" then
    questNames = {}
    for _, qid in ipairs(qd.questId) do
      local d = getQuestieQuestData(qid)
      table.insert(questNames, d and d.name or ("Quest #" .. qid))
    end
  end

  -- Branch structure (hoisted; nil if complete or no questId)
  local branchResult = activeQuestId and not isComplete and buildQuestBranches(activeQuestId)

  -- Debug: recursively dump full prereq tree (once per quest per session)
  if pao_settings and pao_settings.debugMode and activeQuestId then
    sourceTooltip._debuggedChains = sourceTooltip._debuggedChains or {}
    if not sourceTooltip._debuggedChains[activeQuestId] then
      sourceTooltip._debuggedChains[activeQuestId] = true
      local utils = Addon.utils
      local canCheck = C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
      if utils then
        utils:debug("Quest prereq tree for speciesID " .. (speciesID or "?") .. " questId=" .. activeQuestId)

        local currentIds = {}
        if branchResult then
          for _, branch in ipairs(branchResult.branches) do
            if not branch.complete and branch.questId then
              currentIds[branch.questId] = true
            end
          end
        end

        local seen = {}
        local function dumpNode(id, indent)
          local prefix = string.rep("  ", indent)
          if seen[id] then return end
          seen[id] = true
          local d = getQuestieQuestData(id)
          local pqgCount = d and d.preQuestGroup and #d.preQuestGroup or 0
          local pqsCount = d and d.preQuestSingle and #d.preQuestSingle or 0

          if d then
            if d.preQuestGroup and #d.preQuestGroup > 0 then
              for _, pid in ipairs(d.preQuestGroup) do dumpNode(pid, indent + 1) end
            elseif d.preQuestSingle and #d.preQuestSingle > 0 then
              dumpNode(d.preQuestSingle[1], indent + 1)
            end
          end

          local name = d and d.name or "?"
          local done = canCheck and C_QuestLog.IsQuestFlaggedCompleted(id) and " [DONE]" or ""
          local current = currentIds[id] and " [CURRENT]" or ""
          local tag = id == activeQuestId and " [PET]" or ""
          utils:debug(prefix .. "[" .. id .. "] " .. name .. tag .. done .. current
            .. "  (pqg=" .. pqgCount .. " pqs=" .. pqsCount .. ")")
        end

        dumpNode(questId, 0)
      end
    end
  end

  -- -----------------------------------------------------------------------
  -- Case 1: Complete
  -- -----------------------------------------------------------------------
  if isComplete then
    if questName then
      tip:space(16)
      tip:text(QUEST_DONE_MARK .. questName, {color = QUEST_COLORS.NAME})
      if qd and qd.randomDrop and qd.bagName then
        tip:space(4)
        tip:text("[Random from " .. qd.bagName .. "]", {color = QUEST_COLORS.TAG, font = "small"})
      end
    end
    return
  end

  -- -----------------------------------------------------------------------
  -- Cases 2-4: Build unified current-step list
  -- -----------------------------------------------------------------------
  local currentSteps = {}

  if branchResult and not branchResult.allComplete then
    -- Incomplete branches: show each unique blocking step
    local seen = {}
    for _, branch in ipairs(branchResult.branches) do
      if not branch.complete and not (branch.questId and seen[branch.questId]) then
        if branch.questId then seen[branch.questId] = true end
        table.insert(currentSteps, {
          questId  = branch.questId,
          name     = branch.name,
          questData = branch.questData,
          remaining = branch.remaining,
          isPetQuest = false,
        })
      end
    end

  elseif branchResult and branchResult.allComplete then
    -- All prereqs done — pet quest is the current step
    table.insert(currentSteps, {
      questId   = activeQuestId,
      questData = questieData,
      remaining = 0,
      isPetQuest = true,
    })

  else
    -- Linear spine or single quest
    local step = findCurrentStep(activeQuestId)
    if step then
      table.insert(currentSteps, step)
    else
      -- Truly single quest (no chain)
      table.insert(currentSteps, {
        questId   = activeQuestId,
        questData = questieData,
        remaining = 0,
        isPetQuest = true,
      })
    end
  end

  -- -----------------------------------------------------------------------
  local allPetQuest = true
  for _, step in ipairs(currentSteps) do
    if not step.isPetQuest then allPetQuest = false break end
  end

  if questNames then
    tip:space(16)
    for _, name in ipairs(questNames) do
      tip:text(name, {color = QUEST_COLORS.NAME})
      tip:space(2)
    end
  elseif questName then
    tip:space(16)
    tip:text(questName, {color = QUEST_COLORS.NAME})
  end

  -- Separator only when prereq steps exist above the NPC block
  if not allPetQuest then
    tip:space(12)
    tip:separator()
  end

  -- Faction requirement (e.g. Red Cricket: Best Friend with Sho)
  if qd and qd.factionRequirement then
    local fr = qd.factionRequirement
    local reqText = fr.standing .. " with " .. fr.faction
    tip:space(12)
    tip:iconBlock({
      {text = "Requirement:", color = ZONE_COLORS.HEADER},
      {text = reqText, color = ZONE_COLORS.CONDITION},
    }, {
      icon = CAUTION_ICON,
      iconSize = 16,
      iconSpacing = 6,
      textureName = "questFactionReqIcon",
      lineSpacing = 2,
    })
    if fr.npc then
      tip:space(8)
      renderNpcBlock(tip, fr.npc, QUEST_DAILY_ENDER_ICON)
    end
  else
    for i, step in ipairs(currentSteps) do
      if i > 1 then tip:space(12) end

      -- Current step name in amber, unless it IS the pet quest (already shown above)
      if not step.isPetQuest then
        tip:space(8)
        tip:text(step.name, {color = QUEST_COLORS.CURRENT})
      end

    renderNpcLines(tip, step.questData)

    if step.isPetQuest and allPetQuest and qd and qd.randomDrop and qd.bagName then
      tip:space(8)
      tip:text("[Random from " .. qd.bagName .. "]", {color = QUEST_COLORS.TAG, font = "small"})
    end

    if step.remaining and step.remaining > 0 then
      local noun = step.remaining == 1 and "quest" or "quests"
      tip:space(4)
      tip:text("(" .. step.remaining .. " more " .. noun .. ")", {
        color = QUEST_COLORS.INCOMPLETE,
        font = "small",
      })
    end
  end
  end -- factionRequirement else

  -- vendorNpcs: faction-aware NPC blocks for quests with no formal giver/ender
  -- (e.g. Westfall Chicken — navigate to the feed vendor and spam chickens nearby)
  if qd and qd.vendorNpcs then
    local playerFaction = UnitFactionGroup("player")
    for _, entry in ipairs(qd.vendorNpcs) do
      if not entry.faction or entry.faction == playerFaction then
        tip:space(8)
        renderNpcBlock(tip, entry.npcId, "")
      end
    end
  end

  -- -----------------------------------------------------------------------
  -- Hints (returned to show() for unified rendering)
  -- -----------------------------------------------------------------------
  local questHints = {}
  -- Only offer waypoint hint if an NPC block was actually rendered
  -- luacheck: globals TomTom
  if TomTom and not isComplete and sourceTooltip._waypointNpcId then
    table.insert(questHints, "Ctrl-click to set waypoint")
  end
  table.insert(questHints, "Alt-click for quest series")

  -- Daily alternate — only when the one-time quest is what's being shown
  if qd and qd.dailyQuestId and activeQuestId == questId then
    local dailyData = getQuestieQuestData(qd.dailyQuestId)
    local dailyName = dailyData and dailyData.name or ("Daily Quest #" .. qd.dailyQuestId)

    tip:space(16)
    tip:separator()
    tip:space(4)
    tip:text("Also from daily:", {color = ZONE_COLORS.HEADER, font = "small"})
    tip:space(4)
    tip:text(dailyName .. " [Daily]", {color = QUEST_COLORS.NAME, font = "small"})
    if qd.bagName then
      tip:space(2)
      tip:text("Random from " .. qd.bagName, {color = QUEST_COLORS.BAG, font = "small"})
    end
  end

  return questHints
end

--[[
  Show source tooltip for a pet.
  Automatically detects Pet Battle sources and uses enhanced rendering.
  
  @param owner frame - Frame to anchor tooltip to
  @param sourceText string - Source text from C_PetJournal
  @param opts table - Optional: {hints = table, speciesID = number, petIcon = string}
]]
function sourceTooltip:show(owner, sourceText, opts)
  if not sourceText or sourceText == "" then return end
  
  -- Debug: alt-hover shows raw source text in GameTooltip
  if IsAltKeyDown() and pao_settings and pao_settings.debugMode then
    GameTooltip:SetOwner(owner, "ANCHOR_BOTTOMLEFT", 0, -2)
    GameTooltip:AddLine("Source (raw)", 1, 0.82, 0)
    GameTooltip:AddLine(sourceText, 1, 1, 1, true)
    GameTooltip:Show()
    return
  end
  
  local tip = Addon.tooltip
  if not tip then return end
  
  opts = opts or {}
  local speciesID = opts.speciesID
  local questHints = nil  -- set by renderQuestTooltip if quest source
  sourceTooltip._waypointNpcId = nil  -- cleared here, set by renderQuestTooltip
  
  -- Check for species-specific overrides
  local overrides = Addon.data and Addon.data.sourceOverrides
  local speciesOverride = overrides and speciesID and overrides[speciesID]
  
  tip:show(owner)
  tip:minWidth(280)
  
  -- Check if this is a Pet Battle source with zone data available
  local petBattleZones = parsePetBattleZones(sourceText)
  
  -- Check for Trading Card Game source
  local tcgExpansion = not petBattleZones and parseTCGSource(sourceText) or nil
  
  -- Check for Achievement source
  local achievementInfo = not petBattleZones and not tcgExpansion and parseAchievementSource(sourceText) or nil
  
  -- Check for Quest source
  local questInfo = not petBattleZones and not tcgExpansion and not achievementInfo and parseQuestSource(sourceText) or nil
  
  local dropInfo = not petBattleZones and not tcgExpansion and not achievementInfo and not questInfo and parseDropSource(sourceText) or nil
  
  -- Check for In-Game Shop / Pet Store source
  local cleanedSource = stripColorCodes(sourceText):match("^%s*(.-)%s*$")
  local isStoreSource = not petBattleZones and not tcgExpansion and not achievementInfo and not questInfo and not dropInfo
    and (cleanedSource == "Pet Store" or cleanedSource == "In-Game Shop") or false
  
  -- Build vendor info from override or sourceText parsing
  -- TCG sources use override vendorEntries as a subsection, not as primary routing
  local vendorInfo
  local tcgVendorInfo
  if tcgExpansion and speciesOverride and speciesOverride.vendorEntries then
    -- TCG with vendor override: vendor data goes to TCG subsection
    tcgVendorInfo = {
      vendorEntries = speciesOverride.vendorEntries,
    }
  elseif not tcgExpansion and not achievementInfo and not questInfo and speciesOverride and speciesOverride.vendorEntries then
    -- Non-TCG vendor override
    vendorInfo = {
      vendorEntries = speciesOverride.vendorEntries,
      isBreanni = false,
    }
    for _, entry in ipairs(speciesOverride.vendorEntries) do
      if entry.name:lower():find("breanni") then
        vendorInfo.isBreanni = true
      end
    end
  elseif not petBattleZones and not tcgExpansion and not achievementInfo and not questInfo and not dropInfo and not isStoreSource then
    vendorInfo = parseVendorSource(sourceText)
  end
  
  -- Inject achievement gate and guild reputation from override into vendorInfo
  if vendorInfo and speciesOverride then
    if speciesOverride.achievementGate then
      vendorInfo.achievementGate = speciesOverride.achievementGate
    end
    if speciesOverride.guildReputation then
      vendorInfo.guildReputation = speciesOverride.guildReputation
    end
  end
  
  if petBattleZones and Addon.data and Addon.data.zones then
    tip:header("Pet Battle", {
      color = {1, 0.82, 0},
    })
    tip:cornerIcon(BATTLE_ICON, {size = ICON_SIZE})
    tip:text("Trappers have spotted this pet roaming the wilds of Azeroth.", {
      color = {1, 1, 1},
      wrap = true,
      font = "small",
    })
    
    -- Parse and pass condition to renderer
    local condition = parsePetBattleCondition(sourceText)
    renderPetBattleTooltip(tip, petBattleZones, condition)
  elseif tcgExpansion then
    tip:header("Trading Card Game", {color = {1, 0.82, 0}})
    if opts.petIcon then
      tip:cornerIcon(opts.petIcon, {size = ICON_SIZE})
    end
    tip:text("Once sealed in a foil pack, now loose in the wild.", {
      color = {1, 1, 1},
      wrap = true,
      font = "small",
    })
    
    -- Apply text corrections from override
    if speciesOverride and speciesOverride.textCorrections then
      tcgExpansion = applyTextCorrections(tcgExpansion, speciesOverride.textCorrections)
    end
    
    renderTCGTooltip(tip, tcgExpansion, tcgVendorInfo)
  elseif achievementInfo then
    tip:header("Achievement", {color = {1, 0.82, 0}})
    if opts.petIcon then
      tip:cornerIcon(opts.petIcon, {size = ICON_SIZE})
    end
    tip:text("Not every companion is found in the wild. Some must be earned.", {
      color = {1, 1, 1},
      wrap = true,
      font = "small",
    })
    
    renderAchievementTooltip(tip, achievementInfo, speciesID)
  elseif questInfo then
    tip:header("Quest", {color = {1, 0.82, 0}})
    tip:cornerIcon(QUEST_ICON, {size = ICON_SIZE})
    tip:text(QUEST_FLAVOR[math.random(#QUEST_FLAVOR)], {
      color = {1, 1, 1},
      wrap = true,
      font = "small",
    })
    
    questHints = renderQuestTooltip(tip, questInfo, speciesID)
  elseif dropInfo then
    if dropInfo.isWorldDrop then
      tip:header("World Drop", {color = {1, 0.82, 0}})
      if opts.petIcon then
        tip:cornerIcon(opts.petIcon, {size = ICON_SIZE})
      end
      tip:text("World drops are exceptionally rare. Many sane collectors, flush with cash, find the Auction House a more reliable path.", {
        color = {1, 1, 1},
        wrap = true,
        font = "small",
      })
    else
      tip:header("Drop", {color = {1, 0.82, 0}})
      if opts.petIcon then
        tip:cornerIcon(opts.petIcon, {size = ICON_SIZE})
      end
      tip:text("There have been sporadic, yet consistent, reports of this pet dropping.", {
        color = {1, 1, 1},
        wrap = true,
        font = "small",
      })
    end
    renderDropTooltip(tip, dropInfo)
  elseif isStoreSource then
    tip:header("In-Game Shop", {color = {1, 0.82, 0}})
    if opts.petIcon then
      tip:cornerIcon(opts.petIcon, {size = ICON_SIZE})
    end
    tip:text("Some companions skip the wilds entirely and arrive gift-wrapped from the Blizzard shop.", {
      color = {1, 1, 1},
      wrap = true,
      font = "small",
    })
  elseif vendorInfo then
    tip:header("Vendor", {color = {1, 0.82, 0}})
    tip:cornerIcon(VENDOR_ICON, {size = ICON_SIZE})
    
    -- Flavor text - special for Breanni, random goblin quote otherwise
    local flavorText
    if vendorInfo.isBreanni then
      flavorText = "Breanni, the virtual host of WarcraftPets.com, has this in stock."
    else
      flavorText = GOBLIN_QUOTES[math.random(#GOBLIN_QUOTES)]
    end
    tip:text(flavorText, {
      color = {1, 1, 1},
      wrap = true,
      font = "small",
    })
    
    renderVendorTooltip(tip, vendorInfo)
  else
    tip:header("Source", {color = {1, 0.82, 0}})
    renderStandardTooltip(tip, sourceText)
  end
  
  -- Override notes — rendered after type-specific content with highlight band
  if speciesOverride and speciesOverride.notes then
    local notePad = 6
    tip:space(20)  -- net visual gap above band = 14 - notePad = 8px

    -- Capture start height for background band
    local noteStart = tip:getCursor("totalHeight")

    -- Render note lines using normal tip methods
    local noteLines = type(speciesOverride.notes) == "table"
      and speciesOverride.notes
      or {speciesOverride.notes}

    for i, s in ipairs(noteLines) do
      if i > 1 then tip:space(8) end
      tip:text(s, {color = {0.9, 0.9, 0.9}, wrap = true, indent = 6})
    end

    -- Queue background band for done()
    local noteEnd = tip:getCursor("totalHeight")
    tip:queueBackground({
      startHeight = noteStart,
      endHeight   = noteEnd,
      bgPad       = notePad,
      color       = {1, 0.85, 0.4},
    })

    tip:space(2)  -- net visual gap below band = 2 + notePad = 8px
  end
  
  -- Build hint list with spacers between groups:
  -- Group 1: filter hints (Click, Shift-Click)
  -- Group 2: waypoint (Ctrl-click) — quest-specific
  -- Group 3: quest series (Alt-click) — quest-specific
  local allHints = {}
  local HINT_GROUP_SPACE = {space = 6}

  if opts.hints then
    for _, h in ipairs(opts.hints) do table.insert(allHints, h) end
  end

  if questHints then
    for _, h in ipairs(questHints) do
      if #allHints > 0 then
        table.insert(allHints, HINT_GROUP_SPACE)
      end
      table.insert(allHints, h)
    end
  end

  if #allHints > 0 then
    tip:hints(allHints, {separator = true})
  end

  tip:done()
end

--[[
  Set a TomTom waypoint to the NPC computed during the last quest tooltip render.
  Giver NPC if quest not yet in log; ender NPC if quest accepted but not complete.
  No-op if TomTom unavailable, no quest source was shown, or no valid coords found.
]]
function sourceTooltip:setWaypoint()
  local npcId = self._waypointNpcId
  if not npcId then return end
  if not Addon.waypoint or not Addon.waypoint:isAvailable() then return end
  local npcInfo = getQuestieNpcInfo(npcId)
  if not npcInfo or not npcInfo.mapID or not npcInfo.x or not npcInfo.y then return end
  Addon.waypoint:set(npcInfo.mapID, npcInfo.x, npcInfo.y, npcInfo.name, npcInfo.zone)
  if Addon.utils then
    Addon.utils:notify("Waypoint set: " .. (npcInfo.name or "Unknown"))
  end
end

--[[
  Hide the source tooltip.
]]
function sourceTooltip:hide()
  if Addon.tooltip then
    Addon.tooltip:hide()
  end
  GameTooltip:Hide()
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("sourceTooltip", {"tooltip", "uiUtils"}, function()
    return true
  end)
end

Addon.sourceTooltip = sourceTooltip
return sourceTooltip