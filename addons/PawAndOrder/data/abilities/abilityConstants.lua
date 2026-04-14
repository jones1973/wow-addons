--[[
  data/abilities/abilityConstants.lua
  Pet Battle Ability Constants and Utilities
  
  Centralized constants and utility functions used by the tooltip parser.
  Provides color codes, proc type enums, mathematical helpers, and formatting
  constants needed for ability description parsing and display.
  
  These constants mirror Blizzard's PET_BATTLE_EVENT_* and color systems
  to ensure tooltip parsing matches the default Pet Journal behavior exactly.
  
  Dependencies: none
  Exports: Addon.abilityConstants
]]

local addonName, Addon = ...

Addon.abilityConstants = {}
local constants = Addon.abilityConstants

--[[
  Color Constants
  WoW color codes for formatting damage, healing, and text in tooltips
]]
constants.COLORS = {
  GREEN = GREEN_FONT_COLOR_CODE or "|cff20ff20",
  RED = RED_FONT_COLOR_CODE or "|cffff2020",
  HIGHLIGHT = HIGHLIGHT_FONT_COLOR_CODE or "|cffffffff",
  CLOSE = FONT_COLOR_CODE_CLOSE or "|r",
}

--[[
  Proc Type Constants
  Pet battle event types used for ability effect timing (when effects trigger)
  Maps to C_PetBattles event constants
]]
constants.PROC_TYPES = {
  ON_APPLY = PET_BATTLE_EVENT_ON_APPLY,
  ON_DAMAGE_TAKEN = PET_BATTLE_EVENT_ON_DAMAGE_TAKEN,
  ON_DAMAGE_DEALT = PET_BATTLE_EVENT_ON_DAMAGE_DEALT,
  ON_HEAL_TAKEN = PET_BATTLE_EVENT_ON_HEAL_TAKEN,
  ON_HEAL_DEALT = PET_BATTLE_EVENT_ON_HEAL_DEALT,
  ON_AURA_REMOVED = PET_BATTLE_EVENT_ON_AURA_REMOVED,
  ON_ROUND_START = PET_BATTLE_EVENT_ON_ROUND_START,
  ON_ROUND_END = PET_BATTLE_EVENT_ON_ROUND_END,
  ON_TURN = PET_BATTLE_EVENT_ON_TURN,
  ON_ABILITY = PET_BATTLE_EVENT_ON_ABILITY,
  ON_SWAP_IN = PET_BATTLE_EVENT_ON_SWAP_IN,
  ON_SWAP_OUT = PET_BATTLE_EVENT_ON_SWAP_OUT,
}

--[[
  Target Constants
  Target identifiers used in ability descriptions for who is affected
]]
constants.TARGETS = {
  SELF = "self",
  ENEMY = "enemy",
  AURAWEARER = "aurawearer",
  AURACASTER = "auracaster",
  AFFECTED = "affected",
}

--[[
  Utility Math Functions
  Common mathematical operations exposed to the parser environment
  These are safe functions that don't allow environment manipulation
]]
constants.MATH_UTILS = {
  ceil = math.ceil,
  floor = math.floor,
  abs = math.abs,
  min = math.min,
  max = math.max,
  
  -- Conditional: returns onTrue if conditional is true, else onFalse
  cond = function(conditional, onTrue, onFalse)
    if conditional then
      return onTrue
    else
      return onFalse
    end
  end,
  
  -- Clamp: restricts value to be between minClamp and maxClamp
  clamp = function(value, minClamp, maxClamp)
    return math.min(math.max(value, minClamp), maxClamp)
  end,
}

--[[
  Strong/Weak Badge Icons
  Texture paths for colorblind mode indicators on damage/healing
]]
constants.BADGES = {
  STRONG = "|Tinterface\\petbattles\\battlebar-abilitybadge-strong-small:0|t",
  WEAK = "|Tinterface\\petbattles\\battlebar-abilitybadge-weak-small:0|t",
}

--[[
  Pet Family Names
  Returns localized pet type name from Blizzard globals
  
  @param petType number - Pet type ID (1-10)
  @return string - Localized pet type name
]]
function constants:getPetTypeName(petType)
  return _G["BATTLE_PET_DAMAGE_NAME_"..petType] or "Unknown"
end

--[[
  Attack Modifier
  Gets damage multiplier for attacker type vs defender type
  Uses Blizzard's C_PetBattles.GetAttackModifier for accurate calculations
  
  @param attackType number - Attacking pet's type
  @param defenderType number - Defending pet's type
  @return number - Damage multiplier (0.5 = weak, 1.0 = neutral, 1.5 = strong)
]]
function constants:getAttackModifier(attackType, defenderType)
  return C_PetBattles.GetAttackModifier(attackType, defenderType)
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("abilityConstants", {}, function()
    -- No initialization needed - just constants
    return true
  end)
end

return constants