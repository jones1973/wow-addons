--[[
  data/achievements/achievementData.lua
  Achievement Constants and Category Data
  
  Static data for the achievements system including category IDs,
  subcategory mappings, and display constants.
  
  The pet battle achievement category is 15117 (confirmed from Blizzard_PetCollection.lua).
  Guild category is 15076 with subcategories including 15088 (General).
  
  Dependencies: none
  Exports: Addon.achievementData
]]

local ADDON_NAME, Addon = ...

local achievementData = {}

-- ============================================================================
-- CATEGORY CONSTANTS
-- ============================================================================

-- Main pet battle achievement category (from Blizzard source)
achievementData.PET_BATTLE_CATEGORY_ID = 15117

-- Guild achievement parent category
achievementData.GUILD_CATEGORY_ID = 15076

-- Guild subcategories (discovered via GetCategoryInfo)
achievementData.GUILD_SUBCATEGORIES = {
    15077,  -- Guild: Quests
    15078,  -- Guild: Player vs. Player
    15079,  -- Guild: Dungeons & Raids
    15080,  -- Guild: Professions
    15088,  -- Guild: General (contains Critter Kill Squad)
    15089,  -- Guild: Reputation
    15093,  -- Guild: Feats of Strength
}

-- Known subcategory names (for display grouping)
achievementData.SUBCATEGORY_ORDER = {
    "Collect",
    "Battle",
    "Level",
    "Guild",
}

-- Display name overrides
achievementData.SUBCATEGORY_DISPLAY_NAMES = {}

-- ============================================================================
-- DISPLAY CONSTANTS
-- ============================================================================

-- Row heights
achievementData.HEADER_HEIGHT = 28
achievementData.ROW_HEIGHT = 48           -- Collapsed row
achievementData.ROW_SPACING = 2

-- Progress bar dimensions
achievementData.PROGRESS_BAR_WIDTH = 100
achievementData.PROGRESS_BAR_HEIGHT = 8

-- Icon sizes
achievementData.ICON_SIZE = 40
achievementData.PET_REWARD_ICON_SIZE = 28  -- Bigger pet reward icon

-- Points shield
achievementData.POINTS_SHIELD_SIZE = 32

-- Animation
achievementData.ANIMATION_DURATION = 0.15

-- Recent achievements
achievementData.RECENT_DAYS = 7

-- Colors
achievementData.COLORS = {
    -- Progress states
    COMPLETED = {0.2, 0.8, 0.2},
    IN_PROGRESS = {0.8, 0.8, 0.2},
    NOT_STARTED = {0.5, 0.5, 0.5},
    
    -- Section headers
    HEADER_BG = {0.15, 0.15, 0.15, 0.9},
    HEADER_TEXT = {1, 0.82, 0},
    
    -- Row backgrounds
    ROW_BG_NORMAL = {0.1, 0.1, 0.1, 0.7},
    ROW_BG_HOVER = {0.2, 0.2, 0.2, 0.8},
    ROW_BG_SELECTED = {0.25, 0.25, 0.35, 0.9},
    ROW_BG_EXPANDED = {0.12, 0.12, 0.15, 0.9},
    
    -- Expansion area
    EXPANSION_BG = {0.08, 0.08, 0.1, 0.95},
    
    -- Progress bar
    PROGRESS_BG = {0.2, 0.2, 0.2, 1},
    PROGRESS_FILL = {0.3, 0.6, 0.3, 1},
    PROGRESS_FILL_COMPLETE = {0.2, 0.8, 0.2, 1},
    
    -- Pet reward indicator
    PET_REWARD = {0.4, 0.7, 1.0},
    
    -- Pet name
    PET_NAME_OWNED = {0.4, 0.8, 0.4},
    PET_NAME_MISSING = {0.8, 0.4, 0.4},
    
    -- Reward text colors
    REWARD_QUEST_UNLOCK = {0.4, 0.7, 1.0},      -- Daily quest blue
    REWARD_BATTLE_STONE = {0.0, 0.44, 0.87},    -- Rare blue (darker)
    REWARD_LOCKED = {0.8, 0.4, 0.4},            -- Uncollected red
    REWARD_DEFAULT = {0.82, 0.71, 0.55},        -- Tan/brown for items
    
    -- Criteria
    CRITERIA_COMPLETE = {0.4, 0.8, 0.4},
    CRITERIA_INCOMPLETE = {0.6, 0.6, 0.6},
    CRITERIA_SEPARATOR = {0.3, 0.3, 0.3},
}

-- ============================================================================
-- TRACKING CONSTANTS
-- ============================================================================

achievementData.MAX_TRACKED = 10

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

function achievementData:getSubcategoryDisplayName(apiName)
    return self.SUBCATEGORY_DISPLAY_NAMES[apiName] or apiName
end

function achievementData:getStateColor(completed, hasProgress)
    if completed then
        return unpack(self.COLORS.COMPLETED)
    elseif hasProgress then
        return unpack(self.COLORS.IN_PROGRESS)
    else
        return unpack(self.COLORS.NOT_STARTED)
    end
end

--[[
  Parse pet name from reward text.
  @param rewardText string - e.g., "Reward: Mr. Bigglesworth"
  @return string|nil
]]
function achievementData:parsePetNameFromReward(rewardText)
    if not rewardText or rewardText == "" then
        return nil
    end
    return rewardText:match("^Reward:%s*(.+)$")
end

-- Known item rewards with their item IDs (use reward text, not item name)
local KNOWN_ITEM_REWARDS = {
    ["Safari Hat"] = 92738,
    ["Sack of Pet Supplies"] = 89125,
    ["Pet Supplies"] = 89125,
    ["Heavy Sack of Gold"] = 92744,
    ["Marked Flawless Battle Stone"] = 98715,
    ["Flawless Battle Stone"] = 92741,
}

-- Known quest unlock rewards (these unlock access to quests/vendors)
local QUEST_UNLOCK_PATTERNS = {
    "Unlocks",
    "access to",
    "eligible",
    "allows you to",
    "Quests?$",  -- Ends with "Quest" or "Quests"
}

--[[
  Strip "Reward:", "Quest Reward:" etc from display text.
  @param rewardText string
  @return string - Clean reward name without prefix
]]
function achievementData:cleanRewardText(rewardText)
    if not rewardText then return "" end
    
    -- Strip common prefixes
    local cleaned = rewardText
    cleaned = cleaned:gsub("^Quest Reward:%s*", "")
    cleaned = cleaned:gsub("^Reward:%s*", "")
    cleaned = cleaned:gsub("^Title Reward:%s*", "")
    cleaned = cleaned:gsub("^Title:%s*", "")
    
    return cleaned:gsub("^%s+", ""):gsub("%s+$", "")
end

--[[
  Check if reward is an item and get its item ID.
  @param rewardText string
  @return number|nil - Item ID if known
]]
function achievementData:getRewardItemID(rewardText)
    if not rewardText then return nil end
    
    local cleaned = self:cleanRewardText(rewardText)
    
    -- Check known items (use plain string find, not pattern)
    for itemName, itemID in pairs(KNOWN_ITEM_REWARDS) do
        if cleaned:find(itemName, 1, true) then
            return itemID
        end
    end
    
    return nil
end

--[[
  Check if reward unlocks something (quest, vendor access, etc).
  @param rewardText string
  @return boolean
]]
function achievementData:isUnlockReward(rewardText)
    if not rewardText then return false end
    
    for _, pattern in ipairs(QUEST_UNLOCK_PATTERNS) do
        if rewardText:lower():find(pattern:lower()) then
            return true
        end
    end
    
    return false
end

--[[
  Get icon for a reward.
  Returns item icon if known item, quest icon for unlocks, or default gift icon.
  @param rewardText string
  @return number|string - Icon texture
]]
function achievementData:getRewardIcon(rewardText)
    if not rewardText then return "Interface\\ICONS\\INV_Misc_Gift_02" end
    
    -- Check for known item (table lookup)
    local itemID = self:getRewardItemID(rewardText)
    if itemID then
        local icon = GetItemIcon(itemID)
        if icon then return icon end
    end
    
    -- Check for unlock reward (quest chain) - pattern based
    if self:isUnlockReward(rewardText) then
        return 132049  -- Yellow quest available icon (AvailableQuestIcon)
    end
    
    -- Default gift icon
    return "Interface\\ICONS\\INV_Misc_Gift_02"
end

--[[
  Get color for a reward based on type and completion status.
  @param rewardText string
  @param completed boolean - Whether the achievement is completed
  @return table - RGB color values
]]
function achievementData:getRewardColor(rewardText, completed)
    if not rewardText then return self.COLORS.REWARD_DEFAULT end
    
    -- Quest unlock rewards - daily blue (pattern based)
    if self:isUnlockReward(rewardText) then
        if completed then
            return self.COLORS.REWARD_QUEST_UNLOCK
        else
            return self.COLORS.REWARD_LOCKED
        end
    end
    
    -- Check if it's a known item
    local itemID = self:getRewardItemID(rewardText)
    
    -- Battle-Stone rewards - rare blue (by itemID)
    if itemID == 98715 or itemID == 92741 then
        if completed then
            return self.COLORS.REWARD_BATTLE_STONE
        else
            return self.COLORS.REWARD_LOCKED
        end
    end
    
    -- Default item color - tan/brown if completed, red if not
    if completed then
        return self.COLORS.REWARD_DEFAULT
    else
        return self.COLORS.REWARD_LOCKED
    end
end

--[[
  Check if reward text indicates a title reward.
  @param rewardText string
  @return boolean
]]
function achievementData:isTitleReward(rewardText)
    if not rewardText then return false end
    -- Check for various title formats: "Title: X", "Reward: Title", etc.
    return rewardText:match("[Tt]itle") ~= nil
end

--[[
  Parse title name from reward text.
  Handles gendered titles like "the Insane" vs character-specific forms.
  @param rewardText string
  @return string|nil - The title name
]]
function achievementData:parseTitleFromReward(rewardText)
    if not rewardText then return nil end
    
    -- Try "Title Reward: <n>" format (common in MoP)
    local title = rewardText:match("Title Reward:%s*(.+)")
    if title then
        return title:gsub("^%s+", ""):gsub("%s+$", "")
    end
    
    -- Try "Title: <n>" format
    title = rewardText:match("Title:%s*(.+)")
    if title then
        return title:gsub("^%s+", ""):gsub("%s+$", "")
    end
    
    -- Try "Reward: <title>" format
    title = rewardText:match("Reward:%s*(.+)")
    if title then
        return title:gsub("^%s+", ""):gsub("%s+$", "")
    end
    
    return nil
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("achievementData", {}, function()
        return true
    end)
end

Addon.achievementData = achievementData
return achievementData