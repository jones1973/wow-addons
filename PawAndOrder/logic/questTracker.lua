--[[
  logic/questTracker.lua
  Quest Completion Tracking and Query System
  
  Provides quest completion checking using C_QuestLog.IsQuestFlaggedCompleted().
  No caching - checks are infrequent enough that direct API calls are sufficient.
  
  Handles faction-specific filtering and category/type-based queries using the
  indexed quest database for efficient lookups.
  
  Dependencies: utils, questDatabase
  Exports: Addon.questTracker
]]

local addonName, Addon = ...

Addon.questTracker = {}
local tracker = Addon.questTracker

--[[
  Check if a quest is completed
  Direct WoW API call, no caching
  
  @param questId number - Quest ID to check
  @return boolean - True if quest is flagged as completed
]]
function tracker:isQuestCompleted(questId)
  if not questId then return false end
  return C_QuestLog.IsQuestFlaggedCompleted(questId)
end

--[[
  Check if all quests in a list are completed
  Useful for checking prerequisites or quest chains
  
  @param questIds table - Array of quest IDs
  @return boolean - True if all quests are completed
]]
function tracker:areAllQuestsCompleted(questIds)
  if not questIds or #questIds == 0 then return true end
  
  for _, questId in ipairs(questIds) do
    if not self:isQuestCompleted(questId) then
      return false
    end
  end
  
  return true
end

--[[
  Check if any quest in a list is completed
  Useful for "OR" logic where multiple quests can unlock a feature
  
  @param questIds table - Array of quest IDs
  @return boolean - True if at least one quest is completed
]]
function tracker:isAnyQuestCompleted(questIds)
  if not questIds or #questIds == 0 then return false end
  
  for _, questId in ipairs(questIds) do
    if self:isQuestCompleted(questId) then
      return true
    end
  end
  
  return false
end

--[[
  Get all quests with a specific category flag
  
  @param categoryFlag number - Category bit flag from questDatabase.CATEGORY
  @return table - Array of quest IDs with that category
]]
function tracker:getQuestsByCategory(categoryFlag)
  local db = Addon.questDatabase
  return db.indices.byCategory[categoryFlag] or {}
end

--[[
  Get all quests with a specific type flag
  
  @param typeFlag number - Type bit flag from questDatabase.TYPE
  @return table - Array of quest IDs with that type
]]
function tracker:getQuestsByType(typeFlag)
  local db = Addon.questDatabase
  return db.indices.byType[typeFlag] or {}
end

--[[
  Get all quests for a specific zone
  
  @param zone string - Zone name
  @return table - Array of quest IDs for that zone
]]
function tracker:getQuestsByZone(zone)
  local db = Addon.questDatabase
  return db.indices.byZone[zone] or {}
end

--[[
  Get quests associated with a specific NPC
  Useful for checking if an NPC's daily quest is completed
  
  @param npcId number - NPC ID
  @return table - Array of quest IDs associated with this NPC
]]
function tracker:getQuestsByNpcId(npcId)
  local db = Addon.questDatabase
  return db.indices.byNpcId[npcId] or {}
end

--[[
  Get quests filtered by player's faction
  
  @param questIds table - Array of quest IDs to filter
  @return table - Array of quest IDs appropriate for player faction
]]
function tracker:filterByFaction(questIds)
  local playerFaction = UnitFactionGroup("player")
  local db = Addon.questDatabase
  local filtered = {}
  
  for _, questId in ipairs(questIds) do
    local quest = db.QUESTS[questId]
    if quest then
      local questFaction = quest.faction or "both"
      if questFaction == "both" or questFaction == playerFaction then
        table.insert(filtered, questId)
      end
    end
  end
  
  return filtered
end

--[[
  Check if a specific feature is unlocked
  Main entry point for checking portal unlocks, etc.
  Uses OR logic - if ANY quest in the category is completed, feature is unlocked
  
  @param categoryFlag number - Feature category flag
  @param zone string - Optional zone filter
  @return boolean - True if feature is unlocked
  @return number|nil - Quest ID that unlocked it (if unlocked)
]]
function tracker:isFeatureUnlocked(categoryFlag, zone)
  local questIds = self:getQuestsByCategory(categoryFlag)
  
  -- Filter by faction
  questIds = self:filterByFaction(questIds)
  
  -- Filter by zone if specified
  if zone then
    local db = Addon.questDatabase
    local zoneFiltered = {}
    for _, questId in ipairs(questIds) do
      local quest = db.QUESTS[questId]
      if quest and quest.zone == zone then
        table.insert(zoneFiltered, questId)
      end
    end
    questIds = zoneFiltered
  end
  
  -- Check if any of the quests are completed (OR logic for multiple unlock paths)
  for _, questId in ipairs(questIds) do
    if self:isQuestCompleted(questId) then
      return true, questId
    end
  end
  
  return false, nil
end

--[[
  Check if an NPC's associated quest is completed today
  Used to determine if an NPC should be disabled in circuit UI
  
  @param npcId number - NPC ID
  @return boolean - True if NPC's quest is completed
  @return number|nil - Quest ID if found
]]
function tracker:isNpcQuestCompleted(npcId)
  local questIds = self:getQuestsByNpcId(npcId)
  
  -- Filter by faction
  questIds = self:filterByFaction(questIds)
  
  -- Check if any quest is completed
  for _, questId in ipairs(questIds) do
    if self:isQuestCompleted(questId) then
      return true, questId
    end
  end
  
  return false, nil
end

--[[
  Get quest data by ID
  Convenience wrapper for database lookup
  
  @param questId number - Quest ID
  @return table|nil - Quest data or nil if not found
]]
function tracker:getQuestData(questId)
  return Addon.questDatabase.QUESTS[questId]
end

--[[
  Get human-readable description of why a quest is unavailable
  Used for tooltip generation in UI
  
  @param questId number - Quest ID
  @return string - Reason text
]]
function tracker:getUnavailableReason(questId)
  local quest = self:getQuestData(questId)
  if not quest then
    return "Unknown quest"
  end
  
  local db = Addon.questDatabase
  
  -- Check if it's a daily/weekly quest
  if db:hasType(quest, db.TYPE.DAILY) then
    return "Completed today"
  elseif db:hasType(quest, db.TYPE.WEEKLY) then
    return "Completed this week"
  elseif db:hasType(quest, db.TYPE.ONE_TIME) then
    return "Already completed"
  end
  
  return "Unavailable"
end

if Addon.registerModule then
  Addon.registerModule("questTracker", {"utils", "quests"}, function()
    return true
  end)
end

return tracker