-- logic/npcUtils.lua
-- NPC data utilities and availability filtering
--
-- Dependencies: dataStore, location, utils, quests

local addonName, Addon = ...

Addon.npcUtils = {}
local npcUtils = Addon.npcUtils

-- Special battle NPC IDs
local SPECIAL_NPCS = {
  JEREMY_FEASEL = 67370,
  DOOPY = 71438
  -- Christoph VonFeasel added in WoD patch 6.0.2, not in MoP
}

--[[
  Get primary mapID for an NPC
  @param npc table - NPC data
  @return number|nil - mapID or nil
]]
local function getNpcMapID(npc)
  local loc = Addon.location:getNpcLocation(npc)
  return loc and loc.mapID
end

--[[
  Get primary continent for an NPC
  @param npc table - NPC data
  @return number|nil - continent ID or nil
]]
local function getNpcContinent(npc)
  local loc = Addon.location:getNpcLocation(npc)
  if not loc then return nil end
  if loc.continent then return loc.continent end
  if loc.mapID then return Addon.location:getContinentByMapID(loc.mapID) end
  return nil
end

--[[
  Get NPC data from unified entity system
  @param npcId string|number - NPC ID
  @return table|nil - NPC data if found
]]
function npcUtils:getNpcData(npcId)
  if not npcId then return nil end
  return Addon.dataStore:getEntity("npc", npcId)
end

--[[
  Extract creature ID from a unit GUID.
  @param guid string - Unit GUID (format: ....-<creatureID>-<hex>)
  @return number|nil - Creature ID or nil if parse fails
]]
function npcUtils:getCreatureId(guid)
  if not guid then return nil end
  -- GUID format: ....-<creatureID>-<hex>
  return tonumber(guid:match("-(%d+)-%x+$"))
end

--[[
  Get all NPCs (merged static + SV)
  @return table - {[npcId] = npcData}
]]
function npcUtils:getAllNpcs()
  return Addon.dataStore:listEntities("npc")
end

--[[
  Validate that NPCs exist and are accessible
  @param npcIds table - array of NPC IDs
  @return table - filtered array of valid NPC IDs
]]
function npcUtils:validateNpcs(npcIds)
  local valid = {}
  
  for _, npcId in ipairs(npcIds) do
    local npc = self:getNpcData(npcId)
    if npc then
      table.insert(valid, npcId)
    end
  end
  
  return valid
end

--[[
  Check if NPC has a specific type flag
  @param npc table - NPC data
  @param flag number - NPC_TYPE bit flag
  @return boolean
]]
function npcUtils:hasType(npc, flag)
  if not npc or not npc.types then return false end
  return bit.band(npc.types, flag) > 0
end

--[[
  Check if NPC is a Spirit Tamer
  @param npc table - NPC data
  @return boolean
]]
function npcUtils:isSpiritTamer(npc)
  return self:hasType(npc, Addon.NPC_TYPE.SPIRIT)
end

--[[
  Get the primary category for an NPC based on type flags
  Used for UI categorization - returns the most specific type.
  Priority: FABLED > SPIRIT > TAMER > TRAINER > VENDOR
  @param npc table - NPC data
  @return string - category key for filterAvailableNpcs
]]
local function getPrimaryCategory(npc)
  local NPC_TYPE = Addon.NPC_TYPE
  local types = npc.types or 0
  
  if bit.band(types, NPC_TYPE.FABLED) > 0 then return "fabledBeasts" end
  if bit.band(types, NPC_TYPE.SPIRIT) > 0 then return "spiritTamers" end
  if bit.band(types, NPC_TYPE.TAMER) > 0 then return "dailyTamers" end
  -- TRAINER excluded: they teach pet battles, not opponents to fight
  
  return nil
end

--[[
  Filter and categorize available NPCs with faction filtering
  @return table - categorized NPCs {dailyTamers, spiritTamers, fabledBeasts, specialBattles}
]]
function npcUtils:filterAvailableNpcs()
  local NPC_TYPE = Addon.NPC_TYPE
  local available = {
    dailyTamers = {},
    spiritTamers = {},
    fabledBeasts = {},
    specialBattles = {},
  }
  
  local allNpcs = self:getAllNpcs()
  
  -- Get player's faction for filtering (convert API string to integer)
  local playerFactionStr = UnitFactionGroup("player")
  local playerFactionId = playerFactionStr and Addon.FACTION[playerFactionStr:upper()] or nil
  
  -- Counters for summary
  local totalCount = 0
  local includedCount = 0
  local factionSkipped = 0
  local noMapSkipped = 0
  
  for npcId, npc in pairs(allNpcs) do
    totalCount = totalCount + 1
    local shouldInclude = true
    
    -- Faction filtering: skip NPCs that don't match player faction
    -- npc.faction is nil for neutral, integer for faction-specific
    if npc.faction then
      if npc.faction ~= playerFactionId then
        factionSkipped = factionSkipped + 1
        shouldInclude = false
      end
    end
    
    -- Only process NPC if it passed faction check
    if shouldInclude then
      -- Get continent from first location, with runtime fallback
      local continent = getNpcContinent(npc)
      if not continent then
        local mapID = getNpcMapID(npc)
        continent = Addon.location:getContinentByMapID(mapID)
      end
      if continent then
        local isCompleted = self:isNpcCompletedToday(npcId)
        local isDisabled = false
        local disabledReason = nil
        
        -- Disable completed daily quests but NOT fabled beasts
        -- Fabled beasts are repeatable battles even though quest is daily
        if isCompleted and not self:hasType(npc, NPC_TYPE.FABLED) then
          isDisabled = true
          disabledReason = "Completed today - available after daily reset"
        end
        
        -- Determine category from type flags
        local category = getPrimaryCategory(npc)
        
        if category then
          local npcInfo = {
            id = npcId,
            npc = npc,
            completed = isCompleted,
            disabled = isDisabled,
            disabledReason = disabledReason,
            continent = continent
          }
          
          -- Special encounters handled separately by getSpecialBattles()
          local isSpecialEncounter = category == "dailyTamers" and 
            (npcId == SPECIAL_NPCS.DOOPY or npcId == SPECIAL_NPCS.JEREMY_FEASEL)
          
          if not isSpecialEncounter then
            table.insert(available[category], npcInfo)
            includedCount = includedCount + 1
          end
        end
      else
        noMapSkipped = noMapSkipped + 1
      end
    end
  end
  
  -- Add special battles separately
  for _, specialInfo in ipairs(self:getSpecialBattles()) do
    table.insert(available.specialBattles, specialInfo)
  end
  
  Addon.utils:debug(string.format("filterAvailableNpcs: %d included, %d faction-filtered, %d no-mapID (of %d total)\n%s",
    includedCount, factionSkipped, noMapSkipped, totalCount, debugstack(2, 6, 0)))
  
  return available
end

--[[
  Get special battles (Jeremy Feasel, Doopy, etc)
  These are tamers that should appear in their own category in the UI.
  @return table - array of special battle info
]]
function npcUtils:getSpecialBattles()
  local specials = {}
  
  -- Jeremy Feasel (Darkmoon Faire only)
  local jeremy = self:getNpcData(SPECIAL_NPCS.JEREMY_FEASEL)
  if jeremy then
    local continent = getNpcContinent(jeremy)
    if not continent then
      local mapID = getNpcMapID(jeremy)
      continent = Addon.location:getContinentByMapID(mapID)
    end
    if continent then
      local dmfActive = self:isDarkmoonFaireActive()
      local isCompleted = self:isNpcCompletedToday(SPECIAL_NPCS.JEREMY_FEASEL)
      local isDisabled = false
      local disabledReason = nil
      
      -- Disable if DMF is not active OR if completed today
      if not dmfActive then
        isDisabled = true
        disabledReason = "Only available during Darkmoon Faire"
      elseif isCompleted then
        isDisabled = true
        disabledReason = "Completed today - available after daily reset"
      end
      
      table.insert(specials, {
        id = SPECIAL_NPCS.JEREMY_FEASEL,
        npc = jeremy,
        completed = isCompleted,
        disabled = isDisabled,
        disabledReason = disabledReason,
        continent = continent
      })
    else
      Addon.utils:error("Jeremy Feasel has no resolvable continent")
    end
  end
  
  -- Doopy (always available)
  local doopy = self:getNpcData(SPECIAL_NPCS.DOOPY)
  if doopy then
    local continent = getNpcContinent(doopy)
    if not continent then
      local mapID = getNpcMapID(doopy)
      continent = Addon.location:getContinentByMapID(mapID)
    end
    if continent then
      local isCompleted = self:isNpcCompletedToday(SPECIAL_NPCS.DOOPY)
      local isDisabled = false
      local disabledReason = nil
      
      -- Disable if completed today
      if isCompleted then
        isDisabled = true
        disabledReason = "Completed today - available after daily reset"
      end
      
      table.insert(specials, {
        id = SPECIAL_NPCS.DOOPY,
        npc = doopy,
        completed = isCompleted,
        disabled = isDisabled,
        disabledReason = disabledReason,
        continent = continent
      })
    else
      Addon.utils:error("Doopy has no resolvable continent")
    end
  end
  
  return specials
end

--[[
  Check if Darkmoon Faire is currently active
  Uses Calendar API to check for active DMF event
  @return boolean
]]
function npcUtils:isDarkmoonFaireActive()
  local today = C_DateAndTime.GetCurrentCalendarTime()
  
  -- Set calendar to current month
  C_Calendar.SetAbsMonth(today.month, today.year)
  
  -- Check today's events for Darkmoon Faire
  local numEvents = C_Calendar.GetNumDayEvents(0, today.monthDay)
  for i = 1, numEvents do
    local event = C_Calendar.GetDayEvent(0, today.monthDay, i)
    if event and event.title and event.title:find("Darkmoon") then
      Addon.utils:debug("Darkmoon Faire is active")
      return true
    end
  end
  
  return false
end

--[[
  Check if NPC quest completed today
  Handles account-wide quests (Beasts of Fable) and daily quests (tamers, spirits).
  
  @param npcId string|number - NPC ID to check
  @return boolean - true if quest is completed today
]]
function npcUtils:isNpcCompletedToday(npcId)
  if not npcId then
    Addon.utils:debug("isNpcCompletedToday: npcId is nil")
    return false
  end
  
  -- Need quest database
  if not Addon.questDatabase then
    Addon.utils:debug("isNpcCompletedToday: questDatabase not available")
    return false
  end
  
  if not Addon.questDatabase.indices then
    Addon.utils:debug("isNpcCompletedToday: questDatabase.indices not built")
    return false
  end
  
  local npcIdNum = tonumber(npcId)
  if not npcIdNum then
    Addon.utils:debug(string.format("isNpcCompletedToday: could not convert npcId '%s' to number", tostring(npcId)))
    return false
  end
  
  -- Look up quest IDs for this NPC using the quest database indices
  local questIds = Addon.questDatabase.indices.byNpcId[npcIdNum]
  
  if not questIds or #questIds == 0 then
    -- No quest associated with this NPC - not necessarily an error, some NPCs don't have dailies
    return false
  end
  
  -- Get NPC data to check type and name
  local npc = self:getNpcData(npcId)
  local isFabled = npc and self:hasType(npc, Addon.NPC_TYPE.FABLED)
  local npcName = npc and npc.name
  
  -- Check each quest associated with this NPC
  for _, questId in ipairs(questIds) do
    local quest = Addon.questDatabase.QUESTS[questId]
    
    if quest then
      if isFabled and npcName then
        -- Fabled beasts: quest covers multiple beasts (e.g., Book II has Greyhoof, Lucky Yi, Skitterer)
        -- When all beasts defeated, quest auto-completes and objectives reset.
        -- So check quest completion first, then fall back to objective status.
        local questCompleted = C_QuestLog.IsQuestFlaggedCompleted(questId)
        if questCompleted then
          Addon.utils:debug(string.format("isNpcCompletedToday: NPC %d (%s), quest %d completed (all beasts done)", 
            npcIdNum, npcName, questId))
          return true
        end
        
        -- Quest not complete yet - check if this specific beast's objective is done
        local objectives = C_QuestLog.GetQuestObjectives(questId)
        if objectives then
          for _, obj in ipairs(objectives) do
            -- Match "Defeat Greyhoof" to NPC name "Greyhoof"
            -- Use plain text matching (4th arg = true) to avoid pattern interpretation
            -- e.g., "Dos-Ryga" has a hyphen which is a pattern character
            if obj.text and obj.text:find(npcName, 1, true) then
              if obj.finished then
                Addon.utils:debug(string.format("isNpcCompletedToday: NPC %d (%s), objective '%s' = true", 
                  npcIdNum, npcName, obj.text))
                return true
              end
            end
          end
        end
      else
        -- Tamers/spirits: check quest completion flag
        local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(questId)
        if isCompleted then
          Addon.utils:debug(string.format("isNpcCompletedToday: NPC %d, quest %d (%s) = true", 
            npcIdNum, questId, quest.name or "unknown"))
          return true
        end
      end
    end
  end
  
  return false
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("npcUtils", {"utils", "dataStore", "location", "quests", "data.zones", "npcs"}, function()
    return true
  end)
end

return npcUtils