--[[
  data/circuit/circuitConstants.lua
  Circuit System Constants and Configuration Values
  
  Centralized repository for all circuit-related magic numbers, timing values,
  dimensions, and other configuration constants. Extracting these values here
  improves maintainability and makes it easy to tune the circuit system without
  hunting through code.
  
  Dependencies: none
  Exports: Addon.circuitConstants
]]

local addonName, Addon = ...

Addon.circuitConstants = {}
local constants = Addon.circuitConstants

--[[
  Notable Mechanics
  Fabled pets with mechanics worth warning about.
  Key = NPC ID, value = table of mechanic type to ability ID.
  Ability ID is used to display the ability's icon on the tracker.
]]
constants.NOTABLE_MECHANICS = {
  [68558] = {armor = 315},              -- Gorespine: Spiked Skin
  [68562] = {armor = 310, aoe = 419},   -- Ti'un: Shell Shield, Tidal Wave
  [72291] = {armor = 597},              -- Yu'la: Emerald Presence
}

--[[
  UI Layout Constants
  Frame dimensions, spacing, and positioning values for circuit UI components.
  Values based on 8pt grid system - see uiConstants.lua for scale reference.
]]
constants.UI = {
  -- Popup window dimensions
  POPUP_WIDTH = 500,
  POPUP_HEIGHT = 584,
  
  -- Tracker bar dimensions (compact notification style)
  TRACKER_WIDTH = 300,
  TRACKER_HEIGHT = 128,
  TRACKER_DEFAULT_X = -20,
  TRACKER_DEFAULT_Y = -200,
  
  -- Tracker layout
  TRACKER_PADDING = 16,           -- Standard padding per UI reference
  TRACKER_ROW_HEIGHT = 16,        -- Compact rows
  TRACKER_ROW_GAP = 1,            -- Minimal gap - related content stays tight
  
  -- Icon sizes
  BUFF_ICON_SIZE = 32,            -- Larger for visibility
  MECHANIC_ICON_SIZE = 18,        -- Inline with NPC name
  FAMILY_ICON_SIZE = 40,          -- Left side, spans both rows (fabled only)
  
  -- Control buttons
  CONTROL_BUTTON_WIDTH = 60,
  CONTROL_BUTTON_HEIGHT = 20,
  
  -- NPC tree layout
  CHECKBOX_HEIGHT = 20,
  CHECKBOX_SIZE = 18,
  CATEGORY_HEIGHT = 25,
  INDENT = 20,
  
  -- Waypoint display limits
  MAX_WAYPOINTS_SHOWN = 5,
  
  -- Button dimensions
  START_BUTTON_WIDTH = 200,
  START_BUTTON_HEIGHT = 30,
  
  -- Icons
  PORTAL_ICON = "Interface\\Icons\\Spell_Arcane_PortalDarnassus",
}

--[[
  Timing Constants
  Intervals for polling, updates, and warning notifications
]]
constants.TIMING = {
  -- Progress monitoring (seconds)
  PROGRESS_CHECK_INTERVAL = 2,
  
  -- Daily reset monitoring (seconds)
  RESET_CHECK_INTERVAL = 300,  -- 5 minutes
  
  -- Reset warning thresholds
  DEFAULT_RESET_WARNING_TIME = 3600,      -- 1 hour before reset
  DEFAULT_RESET_WARNING_INTERVAL = 600,   -- 10 minutes between warnings
}

--[[
  Quest Giver Locations
  Static coordinates for faction-specific quest givers in Vale of Eternal Blossoms
]]
constants.QUEST_GIVERS = {
  Alliance = {
    name = "Sara Finkleswitch",
    continent = 424,  -- Pandaria
    zone = "Vale of Eternal Blossoms",
    mapID = 390,
    x = 86.6,
    y = 60.2,
  },
  
  Horde = {
    name = "Gentle San",
    continent = 424,  -- Pandaria
    zone = "Vale of Eternal Blossoms",
    mapID = 390,
    x = 75.8,
    y = 32.6,
  },
}

--[[
  Return Location Types
  Valid return location type identifiers
]]
constants.RETURN_TYPES = {
  NONE = "none",
  CURRENT = "current",
  QUEST_GIVER = "questgiver",
}

--[[
  Return location display names for UI
  @return table - Map of return type to display name
]]
function constants:getReturnTypeNames()
  return {
    [self.RETURN_TYPES.NONE] = "None",
    [self.RETURN_TYPES.CURRENT] = "Current Location",
    [self.RETURN_TYPES.QUEST_GIVER] = "Quest Giver",
  }
end

--[[
  Get quest giver location for player's faction
  @return table - Quest giver location data with name, continent, zone, mapID, x, y
]]
function constants:getQuestGiverForFaction()
  local faction = UnitFactionGroup("player")
  
  if faction == "Alliance" then
    return self.QUEST_GIVERS.Alliance
  else
    return self.QUEST_GIVERS.Horde
  end
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("circuitConstants", {}, function()
    -- No initialization needed - just constants
    return true
  end)
end

return constants