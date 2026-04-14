--[[
  logic/abilities/abilityUtils.lua
  Ability Data Utilities
  
  Centralized utilities for pet ability data operations. Handles the complexity
  of WoW's ability array structure where GetPetAbilityList returns abilities as:
    [slot1tier1, slot2tier1, slot3tier1, slot1tier2, slot2tier2, slot3tier2]
  
  This module provides clean abstractions over this structure for consumers
  like teamSection and infoSection.
  
  Dependencies: None (pure utility module)
  Used by: teamSection, infoSection, abilityTooltips
]]

local ADDON_NAME, Addon = ...

local abilityUtils = {}

-- Level requirements by ability index (1-6)
-- Indices 1-3 are tier 1 abilities, indices 4-6 are tier 2 abilities
local ABILITY_LEVEL_REQUIREMENTS = {
  [1] = 1,   -- Slot 1, Tier 1
  [2] = 2,   -- Slot 2, Tier 1
  [3] = 4,   -- Slot 3, Tier 1
  [4] = 10,  -- Slot 1, Tier 2
  [5] = 15,  -- Slot 2, Tier 2
  [6] = 20,  -- Slot 3, Tier 2
}

--[[
  Get All Abilities for Species
  Returns all 6 abilities for a species with metadata.
  
  @param speciesID number - The pet species ID
  @return table|nil - Array of ability data, or nil if unavailable
    Each entry: {abilityID, name, icon, petType, slot (1-3), tier (1-2), levelReq}
]]
function abilityUtils:getAllAbilities(speciesID)
  if not speciesID then return nil end
  
  local abilityIDs = C_PetJournal.GetPetAbilityList(speciesID)
  if not abilityIDs or #abilityIDs < 6 then return nil end
  
  local abilities = {}
  for i, abilityID in ipairs(abilityIDs) do
    local name, icon, petType = C_PetJournal.GetPetAbilityInfo(abilityID)
    
    -- Calculate slot (1-3) and tier (1-2) from index
    -- Indices 1-3 are tier 1, indices 4-6 are tier 2
    local slot = ((i - 1) % 3) + 1
    local tier = (i <= 3) and 1 or 2
    
    abilities[i] = {
      abilityID = abilityID,
      name = name or "Unknown",
      icon = icon,
      petType = petType,
      slot = slot,
      tier = tier,
      levelReq = ABILITY_LEVEL_REQUIREMENTS[i] or 1,
    }
  end
  
  return abilities
end

--[[
  Get Ability Pair for Slot
  Returns both tier 1 and tier 2 abilities for a specific ability slot.
  
  @param speciesID number - The pet species ID
  @param abilitySlot number - The ability slot (1-3)
  @return number|nil, number|nil - tier1AbilityID, tier2AbilityID
]]
function abilityUtils:getAbilityPairForSlot(speciesID, abilitySlot)
  if not speciesID or not abilitySlot then return nil, nil end
  if abilitySlot < 1 or abilitySlot > 3 then return nil, nil end
  
  local abilityIDs = C_PetJournal.GetPetAbilityList(speciesID)
  if not abilityIDs or #abilityIDs < 6 then return nil, nil end
  
  -- Array structure: [slot1t1, slot2t1, slot3t1, slot1t2, slot2t2, slot3t2]
  local tier1Index = abilitySlot
  local tier2Index = abilitySlot + 3
  
  return abilityIDs[tier1Index], abilityIDs[tier2Index]
end

--[[
  Get Ability Pair Info for Slot
  Returns full info for both abilities in a slot.
  
  @param speciesID number - The pet species ID
  @param abilitySlot number - The ability slot (1-3)
  @return table|nil, table|nil - tier1Info, tier2Info
    Each: {abilityID, name, icon, petType, levelReq}
]]
function abilityUtils:getAbilityPairInfoForSlot(speciesID, abilitySlot)
  local tier1ID, tier2ID = self:getAbilityPairForSlot(speciesID, abilitySlot)
  if not tier1ID then return nil, nil end
  
  local name1, icon1, petType1 = C_PetJournal.GetPetAbilityInfo(tier1ID)
  local name2, icon2, petType2 = C_PetJournal.GetPetAbilityInfo(tier2ID)
  
  local tier1Info = {
    abilityID = tier1ID,
    name = name1 or "Unknown",
    icon = icon1,
    petType = petType1,
    levelReq = ABILITY_LEVEL_REQUIREMENTS[abilitySlot] or 1,
  }
  
  local tier2Info = {
    abilityID = tier2ID,
    name = name2 or "Unknown",
    icon = icon2,
    petType = petType2,
    levelReq = ABILITY_LEVEL_REQUIREMENTS[abilitySlot + 3] or 1,
  }
  
  return tier1Info, tier2Info
end

--[[
  Get Active Abilities for Team Slot
  Returns the 3 currently active ability IDs for a team slot.
  
  @param teamSlot number - The team slot (1-3)
  @return table|nil - {[1]=abilityID, [2]=abilityID, [3]=abilityID} or nil
]]
function abilityUtils:getActiveAbilitiesForTeamSlot(teamSlot)
  if not teamSlot or teamSlot < 1 or teamSlot > 3 then return nil end
  
  local petID, ability1, ability2, ability3 = C_PetJournal.GetPetLoadOutInfo(teamSlot)
  if not petID then return nil end
  
  return {ability1, ability2, ability3}
end

--[[
  Get Alternate Ability
  Given a species and the current active ability for a slot, returns the other option.
  
  @param speciesID number - The pet species ID
  @param abilitySlot number - The ability slot (1-3)
  @param currentAbilityID number - The currently active ability ID
  @return number|nil - The alternate ability ID, or nil if not found
]]
function abilityUtils:getAlternateAbility(speciesID, abilitySlot, currentAbilityID)
  local tier1ID, tier2ID = self:getAbilityPairForSlot(speciesID, abilitySlot)
  if not tier1ID or not tier2ID then return nil end
  
  if currentAbilityID == tier1ID then
    return tier2ID
  else
    return tier1ID
  end
end

--[[
  Get Alternate Ability Info
  Returns full info for the alternate ability.
  
  @param speciesID number - The pet species ID
  @param abilitySlot number - The ability slot (1-3)
  @param currentAbilityID number - The currently active ability ID
  @return table|nil - {abilityID, name, icon, petType, levelReq}
]]
function abilityUtils:getAlternateAbilityInfo(speciesID, abilitySlot, currentAbilityID)
  local alternateID = self:getAlternateAbility(speciesID, abilitySlot, currentAbilityID)
  if not alternateID then return nil end
  
  local name, icon, petType = C_PetJournal.GetPetAbilityInfo(alternateID)
  local tier = (currentAbilityID == self:getAbilityPairForSlot(speciesID, abilitySlot)) and 2 or 1
  local levelReqIndex = (tier == 1) and abilitySlot or (abilitySlot + 3)
  
  return {
    abilityID = alternateID,
    name = name or "Unknown",
    icon = icon,
    petType = petType,
    levelReq = ABILITY_LEVEL_REQUIREMENTS[levelReqIndex] or 1,
  }
end

--[[
  Get Level Requirement for Ability Index
  Returns the level required to use an ability at a given index.
  
  @param abilityIndex number - The ability index (1-6)
  @return number - The required level
]]
function abilityUtils:getLevelRequirement(abilityIndex)
  return ABILITY_LEVEL_REQUIREMENTS[abilityIndex] or 1
end

--[[
  Get Which Tier is Active
  Determines if tier 1 or tier 2 is currently active for a slot.
  
  @param speciesID number - The pet species ID
  @param abilitySlot number - The ability slot (1-3)
  @param activeAbilityID number - The currently active ability ID
  @return number - 1 or 2 indicating which tier is active
]]
function abilityUtils:getActiveTier(speciesID, abilitySlot, activeAbilityID)
  local tier1ID, tier2ID = self:getAbilityPairForSlot(speciesID, abilitySlot)
  if activeAbilityID == tier2ID then
    return 2
  end
  return 1
end

-- Export constants for consumers that need them
abilityUtils.LEVEL_REQUIREMENTS = ABILITY_LEVEL_REQUIREMENTS

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("abilityUtils", {}, function()
    return true
  end)
end

Addon.abilityUtils = abilityUtils

return abilityUtils
