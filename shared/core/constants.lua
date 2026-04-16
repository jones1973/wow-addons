-- Core_constants.lua - Centralized constants for Paw and Order addon
local ADDON_NAME, Addon = ...

Addon.constants = Addon.constants or {}
local constants = Addon.constants

-- ===========================================================================
-- WINDOW & LAYOUT CONSTANTS
-- ===========================================================================

-- Main window dimensions
constants.WINDOW_WIDTH = 1150
constants.WINDOW_HEIGHT = 662  -- Includes tab bar height
constants.WINDOW_MIN_WIDTH = 1050
constants.WINDOW_MIN_HEIGHT = 662
constants.WINDOW_MAX_WIDTH = 1450
constants.WINDOW_MAX_HEIGHT = 1062

-- List panel dimensions  
constants.LIST_WIDTH = 350
constants.LIST_ENTRY_HEIGHT = 40

-- UI element sizing
constants.BADGE_COLUMN_WIDTH = 25
constants.RARITY_BAR_HEIGHT = 12
constants.RARITY_BAR_SPACING = 8

-- Default row height for generic lists
constants.DEFAULT_ROW_HEIGHT = 28

-- ===========================================================================
-- CENTRALIZED LAYOUT SYSTEM
-- Bounds flow down from mainFrame to children. All spacing derives from here.
-- ===========================================================================

constants.LAYOUT = {
  -- Universal padding
  EDGE_PADDING = 16,           -- Content to window edge (left/right/bottom)
  SECTION_GAP = 8,             -- Between major sections (list/details, filter/list)
  INNER_PADDING = 8,           -- Inside section backgrounds
  
  -- Vertical reference points (from frame top, after title bar)
  CONTENT_TOP = 28,            -- Below title bar chrome
  HEADER_HEIGHT = 44,          -- Height of header bar (40px buttons + 4px padding)
  
  -- Filter box
  FILTER_HEIGHT = 28,
  
  -- Persistent bar (footer/sidebar)
  PERSISTENT_BAR_FOOTER_HEIGHT = 28,     -- Footer mode: single status bar row
  PERSISTENT_BAR_SIDEBAR_COLLAPSED = 52, -- Sidebar collapsed width
  PERSISTENT_BAR_SIDEBAR_EXPANDED = 180, -- Sidebar expanded width
  
  -- Colors for section backgrounds (lighter to match Pet Journal)
  SECTION_BG_COLOR = {0.12, 0.12, 0.12, 0.85},   -- Lighter dark
  DETAIL_BG_COLOR = {0.12, 0.12, 0.12, 0.85},    -- Lighter dark
  
  -- Section background texture (optional pattern overlay)
  SECTION_BG_TEXTURE = "Interface\\FrameGeneral\\UI-Background-Marble",
}

-- ===========================================================================
-- POPUP & DIALOG CONSTANTS  
-- ===========================================================================

-- Standard popup dimensions
constants.POPUP_WIDTH = 470
constants.POPUP_HEIGHT = 325

-- Circuit/Tree popup specific
constants.TREE_WIDTH = 350
constants.TREE_SCROLL_HEIGHT = 220
constants.TREE_GROUP_HEADER_HEIGHT = 24
constants.TREE_ITEM_HEIGHT = 20
constants.TREE_INDENT_SIZE = 20

-- ===========================================================================
-- PET FAMILY ICON CONSTANTS
-- ===========================================================================

-- Pet family icon texture paths
constants.FAMILY_ICON_PATHS = {
    [1] = "Interface\\PetBattles\\PetIcon-Humanoid",
    [2] = "Interface\\PetBattles\\PetIcon-Dragon",
    [3] = "Interface\\PetBattles\\PetIcon-Flying",
    [4] = "Interface\\PetBattles\\PetIcon-Undead",
    [5] = "Interface\\PetBattles\\PetIcon-Critter",
    [6] = "Interface\\PetBattles\\PetIcon-Magical",
    [7] = "Interface\\PetBattles\\PetIcon-Elemental",
    [8] = "Interface\\PetBattles\\PetIcon-Beast",
    [9] = "Interface\\PetBattles\\PetIcon-Water",
    [10] = "Interface\\PetBattles\\PetIcon-Mechanical",
}

constants.PET_FAMILY_ICONS = {
	[1]  = "Interface\\Icons\\PetType_Humanoid",
	[2]  = "Interface\\Icons\\PetType_Dragon",
	[3]  = "Interface\\Icons\\PetType_Flying",
	[4]  = "Interface\\Icons\\PetType_Undead",
	[5]  = "Interface\\Icons\\PetType_Critter",
	[6]  = "Interface\\Icons\\PetType_Magic",
	[7]  = "Interface\\Icons\\PetType_Elemental",
	[8]  = "Interface\\Icons\\PetType_Beast",
	[9]  = "Interface\\Icons\\PetType_Aquatic",
	[10] = "Interface\\Icons\\PetType_Mechanical",
}

-- Pet family icon numeric file data IDs (for SetTexture by ID)
constants.PET_FAMILY_ICON_IDS = {
    [1]  = 590342,  -- Humanoid
    [2]  = 590339,  -- Dragonkin
    [3]  = 590341,  -- Flying
    [4]  = 590345,  -- Undead
    [5]  = 590338,  -- Critter
    [6]  = 590343,  -- Magic
    [7]  = 590340,  -- Elemental
    [8]  = 590337,  -- Beast
    [9]  = 590346,  -- Aquatic
    [10] = 590344,  -- Mechanical
}

-- ===========================================================================
-- GAMEPLAY CONSTANTS
-- ===========================================================================

-- Pet Battle Training spell ID
constants.PET_BATTLE_SPELL_ID = 125439

-- Circuit waypoint thresholds
constants.PROXIMITY_THRESHOLD = 30
constants.DEVIATE_THRESHOLD = 200
constants.UPDATE_INTERVAL = 1

-- ===========================================================================
-- PET XP BUFF CONSTANTS
-- ===========================================================================

-- Pet XP bonus buffs (Safari Hat, treats, Darkmoon Top Hat)
-- Used by circuit tracker, safari hat reminder, and any XP bonus display
constants.XP_BUFF = {
  -- Buff spell IDs (for aura detection)
  SPELL_IDS = {
    SAFARI_HAT = 158486,
    LESSER_PET_TREAT = 142204,
    PET_TREAT = 142205,
    DARKMOON_TOP_HAT = 136583,
  },
  
  -- Item IDs (for ownership/bag checks)
  ITEM_IDS = {
    SAFARI_HAT = 92738,
    LESSER_PET_TREAT = 98112,
    PET_TREAT = 98114,
    DARKMOON_TOP_HAT = 93730,
  },
  
  -- XP bonus percentages
  PERCENTAGES = {
    SAFARI_HAT = 10,
    LESSER_PET_TREAT = 25,
    PET_TREAT = 50,
    DARKMOON_TOP_HAT = 10,
  },
  
  -- Item types ("toy" = PlayerHasToy, "consumable" = bag check)
  ITEM_TYPES = {
    SAFARI_HAT = "toy",
    LESSER_PET_TREAT = "consumable",
    PET_TREAT = "consumable",
    DARKMOON_TOP_HAT = "consumable",
  },
}

-- ===========================================================================
-- BATTLE STONE CONSTANTS
-- ===========================================================================

-- Universal battle stones (apply to any pet family)
constants.UNIVERSAL_STONE_IDS = {
    [92742] = true,  -- Polished Battle-Stone (universal)
    [92741] = true,  -- Flawless Battle-Stone (universal)
    [98715] = true,  -- Marked Flawless Battle-Stone (universal)
}

-- Family-specific battle stone ID ranges
constants.FAMILY_STONE_RANGES = {
    polished = { min = 92684, max = 92693 },  -- Upgrade to uncommon
    flawless = { min = 92665, max = 92683 },  -- Upgrade to rare
}

-- Family-specific flawless battle stone IDs (indexed by pet type)
constants.FAMILY_FLAWLESS_STONES = {
    [1]  = 92682,  -- Humanoid
    [2]  = 92683,  -- Dragonkin  
    [3]  = 92677,  -- Flying
    [4]  = 92681,  -- Undead
    [5]  = 92676,  -- Critter
    [6]  = 92678,  -- Magic
    [7]  = 92665,  -- Elemental
    [8]  = 92675,  -- Beast
    [9]  = 92679,  -- Aquatic
    [10] = 92680,  -- Mechanical
}

-- ===========================================================================
-- SEMANTIC TEXT COLORS
-- ===========================================================================

-- Text colors - use these instead of hardcoded RGB values
-- Rule: Grey is ONLY for disabled/unavailable. Warnings get warm colors.
constants.TEXT = {
  -- Standard readable text on dark backgrounds
  PRIMARY = {1.00, 1.00, 1.00},           -- White - default body text
  SECONDARY = {0.85, 0.85, 0.85},         -- Light grey - supplementary info
  MUTED = {0.50, 0.50, 0.50},             -- Grey - ONLY for disabled/unavailable
  EMPHASIS = {1.00, 0.82, 0.00},          -- WoW Gold - important, headers
}

-- Semantic colors - convey meaning
constants.SEMANTIC = {
  -- Positive states
  SUCCESS = {0.30, 1.00, 0.30},           -- Bright green - active, complete
  SUCCESS_SOFT = {0.60, 0.90, 0.60},      -- Soft green - positive notes
  
  -- Caution - attention needed
  WARNING = {1.00, 0.80, 0.20},           -- Yellow-gold - caution
  WARNING_SOFT = {0.90, 0.80, 0.50},      -- Muted gold - notes, tips
  
  -- Critical - negative outcomes
  DANGER = {1.00, 0.40, 0.30},            -- Red-orange - errors, lost on death
  DANGER_SOFT = {1.00, 0.60, 0.40},       -- Soft orange - important warnings
  
  -- Neutral information
  INFO = {0.70, 0.85, 1.00},              -- Light blue - explanations
}

-- ===========================================================================
-- COLOR TABLES
-- ===========================================================================

-- Pet rarity colors (matches API: 1=Poor, 2=Common, 3=Uncommon, 4=Rare, 5=Epic, 6=Legendary)
-- Player pets cap at Rare (4). NPC pets can be Legendary (6).
constants.RARITY_COLORS = {
    [1] = { r = 0.62, g = 0.62, b = 0.62 }, -- Poor (gray)
    [2] = { r = 1.00, g = 1.00, b = 1.00 }, -- Common (white)
    [3] = { r = 0.12, g = 1.00, b = 0.00 }, -- Uncommon (green)
    [4] = { r = 0.20, g = 0.55, b = 0.87 }, -- Rare (blue) -- brightened so near-zero red doesn't desaturate at 75% dim
    [5] = { r = 0.63, g = 0.21, b = 0.93 }, -- Epic (purple)
    [6] = { r = 1.00, g = 0.50, b = 0.00 }, -- Legendary (orange)
}

-- Selection and highlight colors
constants.SELECTION_COLORS = {
    primary = { r = 0.67, g = 0.51, b = 0.93 },    -- Lavender (main selection)
    light = { r = 0.77, g = 0.61, b = 0.93 },      -- Light lavender (hover)
    dark = { r = 0.57, g = 0.41, b = 0.83 },       -- Dark lavender (pressed)
    border = { r = 0.67, g = 0.51, b = 0.93, a = 0.8 }  -- Border lavender
}

-- Battle stone upgrade indicator colors  
constants.UPGRADE_COLORS = {
    background = { r = 0.00, g = 0.30, b = 0.60, a = 0.18 },  -- Subtle blue tint
    arrow = { r = 0.00, g = 0.44, b = 0.87 },                 -- Blue arrow
    text = { r = 0.00, g = 0.44, b = 0.87 }                   -- Blue text
}

-- Pet rarity names for display
-- Pet rarity names for display (matches API indexing)
constants.RARITY_NAMES = {
    [1] = "Poor",
    [2] = "Common", 
    [3] = "Uncommon",
    [4] = "Rare",
    [5] = "Epic",
    [6] = "Legendary"
}

-- Natural language rarity keywords (lowercase) for filter parsing
constants.RARITY_KEYWORDS = {
    poor = 1,
    common = 2,
    uncommon = 3,
    rare = 4,
    epic = 5
}

-- Pet type/family colors (1-10 for pet families)
constants.PET_TYPE_COLORS = {
    [1]  = { r = 1.00, g = 0.96, b = 0.41 }, -- Humanoid (yellow)
    [2]  = { r = 0.78, g = 0.61, b = 0.43 }, -- Dragonkin (brown)
    [3]  = { r = 0.54, g = 0.81, b = 0.94 }, -- Flying (light blue)
    [4]  = { r = 0.60, g = 0.60, b = 0.60 }, -- Undead (gray)
    [5]  = { r = 0.95, g = 0.76, b = 0.32 }, -- Critter (orange)
    [6]  = { r = 0.71, g = 0.45, b = 0.82 }, -- Magic (purple)
    [7]  = { r = 0.13, g = 0.59, b = 0.95 }, -- Elemental (blue)
    [8]  = { r = 0.76, g = 0.27, b = 0.08 }, -- Beast (red)
    [9]  = { r = 0.00, g = 0.52, b = 0.75 }, -- Aquatic (dark blue)
    [10] = { r = 0.75, g = 0.75, b = 0.75 }  -- Mechanical (light gray)
}

-- Pet family names (indexed by pet type ID)
constants.PET_FAMILY_NAMES = {
    [1]  = "Humanoid",
    [2]  = "Dragonkin", 
    [3]  = "Flying",
    [4]  = "Undead",
    [5]  = "Critter",
    [6]  = "Magic",
    [7]  = "Elemental",
    [8]  = "Beast",
    [9]  = "Aquatic",
    [10] = "Mechanical"
}

-- Reverse lookup: family name (lowercase) -> type ID
constants.FAMILY_NAME_TO_TYPE = {
    humanoid = 1,
    dragonkin = 2,
    flying = 3,
    undead = 4,
    critter = 5,
    magic = 6,
    elemental = 7,
    beast = 8,
    aquatic = 9,
    mechanical = 10
}

-- ===========================================================================
-- PET SOURCE TYPES
-- ===========================================================================

-- Pet source type enum mapping (from species DB sourceTypeEnum field)
constants.PET_SOURCE_TYPES = {
    [-1] = "Unknown",
    [0]  = "Drop",
    [1]  = "Quest",
    [2]  = "Vendor",
    [3]  = "Profession",
    [4]  = "Wild Pet",
    [5]  = "Achievement",
    [6]  = "World Event",
    [7]  = "Promotion",
    [8]  = "Trading Card Game",
    [9]  = "Store",
    [10] = "Discovery"
}

-- ===========================================================================
-- ABILITY LEVEL REQUIREMENTS (MoP Classic fallback)
-- ===========================================================================

-- Common ability level requirements for pet abilities (slots 1-6)
constants.ABILITY_LEVEL_REQUIREMENTS = { 1, 2, 4, 10, 15, 20 }

-- ===========================================================================
-- HELPER FUNCTIONS
-- ===========================================================================

-- Get rarity color by rarity level (with fallback)
function constants:GetRarityColor(rarity)
    rarity = tonumber(rarity) or 2
    return self.RARITY_COLORS[rarity] or self.RARITY_COLORS[2]
end

-- Get pet type color by pet type ID (with fallback)  
function constants:GetPetTypeColor(petType)
    petType = tonumber(petType) or 1
    return self.PET_TYPE_COLORS[petType] or { r = 1, g = 1, b = 1 }
end

-- Get pet family name by pet type ID (with fallback)
function constants:GetPetFamilyName(petType)
    petType = tonumber(petType) or 1
    return self.PET_FAMILY_NAMES[petType] or "Unknown"
end

-- Get rarity name by rarity level (with fallback)
function constants:GetRarityName(rarity)
    rarity = tonumber(rarity) or 2  
    return self.RARITY_NAMES[rarity] or "Unknown"
end

-- Check if a stone ID is a family-specific stone (not universal)
function constants:IsFamilySpecificStone(itemID)
    if self.UNIVERSAL_STONE_IDS[itemID] then
        return false
    end
    local ranges = self.FAMILY_STONE_RANGES
    if itemID >= ranges.polished.min and itemID <= ranges.polished.max then
        return true
    end
    if itemID >= ranges.flawless.min and itemID <= ranges.flawless.max then
        return true
    end
    return false
end

-- Self-register with dependency system (no dependencies - foundational module)
if Addon.registerModule then
    Addon.registerModule("constants", {}, function()
        return true -- No initialization needed, module is ready
    end)
end

return constants