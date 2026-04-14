--[[
  core/familyUtils.lua
  Pet Family Strength/Weakness Utility
  
  Central source of truth for pet battle family interactions. All lookups
  use numeric family IDs (1-10) as the standard representation.
  
  Damage System:
  - Strong attack: +50% damage (1.5x multiplier)
  - Weak attack: -33% damage (0.66x multiplier)
  - Strong defense: -33% damage received
  - Weak defense: +50% damage received
  
  Dependencies: None
  Exports: Addon.familyUtils
]]

local ADDON_NAME, Addon = ...

local familyUtils = {}

-- Family IDs (matches WoW API)
local FAMILY_IDS = {
    HUMANOID = 1,
    DRAGONKIN = 2,
    FLYING = 3,
    UNDEAD = 4,
    CRITTER = 5,
    MAGIC = 6,
    ELEMENTAL = 7,
    BEAST = 8,
    AQUATIC = 9,
    MECHANICAL = 10,
}

--[[
  Family Type ID to Name mapping
  Used for display and converting IDs to names
]]
local FAMILY_TYPE_TO_NAME = {
    [1] = "humanoid",
    [2] = "dragonkin",
    [3] = "flying",
    [4] = "undead",
    [5] = "critter",
    [6] = "magic",
    [7] = "elemental",
    [8] = "beast",
    [9] = "aquatic",
    [10] = "mechanical"
}

--[[
  Family Name to Type ID mapping
  Used for converting user input to IDs
]]
local FAMILY_NAME_TO_TYPE = {
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

--[[
  Offensive Strength Chart (numeric keys)
  Maps ability family ID -> target family ID that takes +50% damage
  
  Example: Beast (8) abilities deal +50% damage to Critter (5) pets
]]
local STRONG_VS = {
    [1] = 2,   -- Humanoid -> Dragonkin
    [2] = 6,   -- Dragonkin -> Magic
    [3] = 9,   -- Flying -> Aquatic
    [4] = 1,   -- Undead -> Humanoid
    [5] = 4,   -- Critter -> Undead
    [6] = 3,   -- Magic -> Flying
    [7] = 10,  -- Elemental -> Mechanical
    [8] = 5,   -- Beast -> Critter
    [9] = 7,   -- Aquatic -> Elemental
    [10] = 8,  -- Mechanical -> Beast
}

--[[
  Defensive Weakness Chart (numeric keys)
  Maps pet family ID -> ability family ID that deals +50% damage to it
  
  Example: Beast (8) pets take +50% damage from Mechanical (10) abilities
]]
local WEAK_AGAINST = {
    [1] = 4,   -- Humanoid weak to Undead
    [2] = 1,   -- Dragonkin weak to Humanoid
    [3] = 6,   -- Flying weak to Magic
    [4] = 5,   -- Undead weak to Critter
    [5] = 8,   -- Critter weak to Beast
    [6] = 2,   -- Magic weak to Dragonkin
    [7] = 9,   -- Elemental weak to Aquatic
    [8] = 10,  -- Beast weak to Mechanical
    [9] = 3,   -- Aquatic weak to Flying
    [10] = 7,  -- Mechanical weak to Elemental
}

--[[
  Defensive Resistance Chart (numeric keys)
  Maps pet family ID -> ability family ID that deals -33% damage to it
  
  Example: Beast (8) pets take -33% damage from Humanoid (1) abilities
]]
local RESISTANT_TO = {
    [1] = 5,   -- Humanoid resists Critter
    [2] = 3,   -- Dragonkin resists Flying
    [3] = 8,   -- Flying resists Beast
    [4] = 2,   -- Undead resists Dragonkin
    [5] = 1,   -- Critter resists Humanoid
    [6] = 9,   -- Magic resists Aquatic
    [7] = 10,  -- Elemental resists Mechanical
    [8] = 1,   -- Beast resists Humanoid
    [9] = 4,   -- Aquatic resists Undead
    [10] = 6,  -- Mechanical resists Magic
}

--[[
  Offensive Weakness Chart (numeric keys)
  Maps ability family ID -> target family ID that takes -33% damage
  
  Example: Beast (8) abilities deal -33% damage to Flying (3) pets
]]
local WEAK_OFFENSE = {
    [1] = 8,   -- Humanoid weak offense vs Beast
    [2] = 4,   -- Dragonkin weak offense vs Undead
    [3] = 2,   -- Flying weak offense vs Dragonkin
    [4] = 9,   -- Undead weak offense vs Aquatic
    [5] = 3,   -- Critter weak offense vs Flying
    [6] = 10,  -- Magic weak offense vs Mechanical
    [7] = 5,   -- Elemental weak offense vs Critter
    [8] = 3,   -- Beast weak offense vs Flying
    [9] = 6,   -- Aquatic weak offense vs Magic
    [10] = 7,  -- Mechanical weak offense vs Elemental
}

--[[
  Family Passive Abilities
  Each family has a unique passive that affects battle mechanics.
]]
local FAMILY_PASSIVES = {
    [1] = "Humanoids recover 4% of their maximum health if they dealt damage this round.",
    [2] = "Dragons deal 50% additional damage on the next round after bringing a target's health below 50%.",
    [3] = "Flying creatures gain 50% extra speed while above 50% health.",
    [4] = "Undead pets return to life for one round after dying, immune to damage.",
    [5] = "Critters break out of crowd control effects more quickly.",
    [6] = "Magic pets cannot be dealt more than 35% of their maximum health in one attack.",
    [7] = "Elementals ignore all negative weather effects.",
    [8] = "Beasts deal 25% extra damage below half health.",
    [9] = "Aquatic pets suffer 50% less damage from damage over time effects.",
    [10] = "Mechanicals come back to life once per battle, returning to 20% health.",
}

-- ============================================================================
-- ID/NAME CONVERSION
-- ============================================================================

--[[
  Get family name from family type ID
  
  @param familyType number - Family type ID (1-10)
  @return string|nil - Family name in lowercase, or nil if invalid
]]
function familyUtils:getFamilyNameFromType(familyType)
    if not familyType then return nil end
    return FAMILY_TYPE_TO_NAME[familyType]
end

--[[
  Get family type ID from family name
  
  @param familyName string - Family name (any case)
  @return number|nil - Family type ID (1-10), or nil if invalid
]]
function familyUtils:getFamilyTypeFromName(familyName)
    if not familyName then return nil end
    return FAMILY_NAME_TO_TYPE[familyName:lower()]
end

--[[
  Resolve partial family name to family type ID
  Matches a partial family name to a family ID for flexible filtering.
  Only returns a match if exactly one family starts with the partial name.
  
  @param partialName string - Partial family name (e.g., "bea", "drag")
  @return number|nil - Family type ID if unique match found, nil otherwise
]]
function familyUtils:resolveFamily(partialName)
    if not partialName or partialName == "" then return nil end
    
    local partial = partialName:lower()
    
    -- Exact match first
    if FAMILY_NAME_TO_TYPE[partial] then
        return FAMILY_NAME_TO_TYPE[partial]
    end
    
    -- Partial match (starts with) - only return if exactly one match
    local matches = {}
    for name, id in pairs(FAMILY_NAME_TO_TYPE) do
        if name:sub(1, #partial) == partial then
            table.insert(matches, id)
        end
    end
    
    -- Only return if exactly one match found
    if #matches == 1 then
        return matches[1]
    end
    
    return nil
end

-- ============================================================================
-- STRENGTH/WEAKNESS CHECKS (all numeric)
-- ============================================================================

--[[
  Check if an ability family is strong against a target pet family
  
  @param abilityFamilyId number - Family type ID of the ability (1-10)
  @param targetFamilyId number - Family type ID of the target pet (1-10)
  @return boolean - true if ability deals +50% damage to target
]]
function familyUtils:isStrongVs(abilityFamilyId, targetFamilyId)
    if not abilityFamilyId or not targetFamilyId then return false end
    return STRONG_VS[abilityFamilyId] == targetFamilyId
end

-- Alias for isStrongVs
function familyUtils:isStrongAgainst(abilityFamilyId, targetFamilyId)
    return self:isStrongVs(abilityFamilyId, targetFamilyId)
end

--[[
  Check if a pet family is weak against an ability family
  
  @param petFamilyId number - Family type ID of the pet (1-10)
  @param abilityFamilyId number - Family type ID of the attacking ability (1-10)
  @return boolean - true if pet takes +50% damage from ability family
]]
function familyUtils:isWeakAgainst(petFamilyId, abilityFamilyId)
    if not petFamilyId or not abilityFamilyId then return false end
    return WEAK_AGAINST[petFamilyId] == abilityFamilyId
end

--[[
  Get the family ID that a given family is strong against (offensive)
  
  @param abilityFamilyId number - Family type ID of the ability
  @return number|nil - Target family ID, or nil if none
]]
function familyUtils:getStrongVsTarget(abilityFamilyId)
    if not abilityFamilyId then return nil end
    return STRONG_VS[abilityFamilyId]
end

--[[
  Get the family ID that a given family is weak against (defensive)
  
  @param petFamilyId number - Family type ID of the pet
  @return number|nil - Attacking family ID, or nil if none
]]
function familyUtils:getWeakAgainstFamily(petFamilyId)
    if not petFamilyId then return nil end
    return WEAK_AGAINST[petFamilyId]
end

--[[
  Get the family ID that a given family resists (defensive)
  
  @param petFamilyId number - Family type ID of the pet
  @return number|nil - Attacking family ID that deals -33%, or nil if none
]]
function familyUtils:getResistantToFamily(petFamilyId)
    if not petFamilyId then return nil end
    return RESISTANT_TO[petFamilyId]
end

--[[
  Get the family ID that a given family deals reduced damage to (offensive weakness)
  
  @param abilityFamilyId number - Family type ID of the ability
  @return number|nil - Target family ID that takes -33%, or nil if none
]]
function familyUtils:getWeakOffenseTarget(abilityFamilyId)
    if not abilityFamilyId then return nil end
    return WEAK_OFFENSE[abilityFamilyId]
end

--[[
  Get the passive ability description for a family
  
  @param familyId number - Family type ID (1-10)
  @return string|nil - Passive description, or nil if invalid
]]
function familyUtils:getPassive(familyId)
    if not familyId then return nil end
    return FAMILY_PASSIVES[familyId]
end

-- ============================================================================
-- DISPLAY HELPERS
-- ============================================================================

--[[
  Capitalize first letter of family name
  
  @param familyName string - Family name (any case)
  @return string - Family name with first letter capitalized
]]
function familyUtils:capitalize(familyName)
    if not familyName or familyName == "" then return "" end
    return familyName:sub(1,1):upper() .. familyName:sub(2):lower()
end

-- Export constants for direct access if needed
familyUtils.FAMILY_IDS = FAMILY_IDS

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("familyUtils", {}, function()
        return true
    end)
end

Addon.familyUtils = familyUtils
return familyUtils