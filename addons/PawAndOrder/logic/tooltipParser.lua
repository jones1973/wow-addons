--[[
  logic/tooltipParser.lua
  Pet Battle Ability Tooltip Parser

  Parses ability descriptions with embedded expressions (e.g., [StandardDamage(1,1)])
  and replaces them with calculated values based on pet stats. Provides damage/healing
  formatting with strong/weak colors matching Blizzard's Pet Journal tooltips.

  The parser creates a safe sandbox environment where expressions are evaluated using
  pet stats, ability data, and game constants. This matches Blizzard's tooltip system
  to ensure our tooltips look identical to the default Pet Journal.

  Usage:
    local abilityInfo = tooltipParser:createAbilityInfo(abilityID, petID, speciesID)
    local parsed = tooltipParser:parseText(abilityInfo, "[StandardDamage(1,1)] damage")
    -- Result: "127 damage" (with appropriate color codes)

  Dependencies: abilityConstants, utils
  Exports: Addon.tooltipParser
]]

local addonName, Addon = ...

-- Deferred module references
local constants, utils

local tooltipParser = {}

--[[
  Create Ability Info Object
  Factory that builds an abilityInfo context object with pet stats and methods.
  This object provides the data needed by the parser environment to evaluate
  expressions in ability descriptions.

  @param abilityID number - The ability being parsed
  @param petID string|nil - Pet GUID (nil for species-only context)
  @param speciesID number - Pet species ID
  @return table - abilityInfo object with stat accessors
]]
function tooltipParser:createAbilityInfo(abilityID, petID, speciesID)
  -- Validate required parameters
  if not abilityID or type(abilityID) ~= "number" then
    if utils then
      utils:error("tooltipParser:createAbilityInfo - Invalid abilityID: " .. tostring(abilityID))
    end
    return nil
  end

  local info = {
    abilityID = abilityID,
    petID = petID,
    speciesID = speciesID,
  }

  -- Fetch pet stats if we have a real petID (not synthetic "species:XXX")
  local isRealPetID = petID and petID:sub(1, 10) == "BattlePet-"
  
  if isRealPetID then
    local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
    info.health = health or 100
    info.maxHealth = maxHealth or 100
    info.power = power or 0
    info.speed = speed or 0
    info.rarity = rarity or 1
  else
    -- Default stats for unowned/species-only context
    info.health = 100
    info.maxHealth = 100
    info.power = 0
    info.speed = 0
    info.rarity = 1
  end

  -- Fetch pet type from species
  if speciesID then
    local _, _, petType = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
    info.petType = petType or 1
  else
    info.petType = 1
  end

  -- Stat accessor methods (match Blizzard's PET_JOURNAL_ABILITY_INFO interface)
  function info:GetAbilityID()
    return self.abilityID
  end

  function info:GetHealth(target)
    return self.health
  end

  function info:GetMaxHealth(target)
    return self.maxHealth
  end

  function info:GetAttackStat(target)
    return self.power
  end

  function info:GetSpeedStat(target)
    return self.speed
  end

  function info:GetPetType(target)
    return self.petType
  end

  function info:IsInBattle()
    return false -- Journal tooltips are never in battle
  end

  return info
end

--[[
  Create Parser Environment
  Builds the safe sandbox environment with all functions and constants available
  to parsed expressions. The environment is bound to a specific abilityInfo context.

  This is a large function that sets up ~60+ functions for the parser. It's organized
  into logical sections: constants, math utils, data fetching, effect parameters,
  state functions, and calculation aliases.

  @param abilityInfo table - The ability context object
  @return table - Parser environment table
]]
local function createParserEnvironment(abilityInfo)
  local env = {}

  -- Target constants
  env.SELF = constants.TARGETS.SELF
  env.ENEMY = constants.TARGETS.ENEMY
  env.AURAWEARER = constants.TARGETS.AURAWEARER
  env.AURACASTER = constants.TARGETS.AURACASTER
  env.AFFECTED = constants.TARGETS.AFFECTED

  -- Proc type constants
  env.PROC_ON_APPLY = constants.PROC_TYPES.ON_APPLY
  env.PROC_ON_DAMAGE_TAKEN = constants.PROC_TYPES.ON_DAMAGE_TAKEN
  env.PROC_ON_DAMAGE_DEALT = constants.PROC_TYPES.ON_DAMAGE_DEALT
  env.PROC_ON_HEAL_TAKEN = constants.PROC_TYPES.ON_HEAL_TAKEN
  env.PROC_ON_HEAL_DEALT = constants.PROC_TYPES.ON_HEAL_DEALT
  env.PROC_ON_AURA_REMOVED = constants.PROC_TYPES.ON_AURA_REMOVED
  env.PROC_ON_ROUND_START = constants.PROC_TYPES.ON_ROUND_START
  env.PROC_ON_ROUND_END = constants.PROC_TYPES.ON_ROUND_END
  env.PROC_ON_TURN = constants.PROC_TYPES.ON_TURN
  env.PROC_ON_ABILITY = constants.PROC_TYPES.ON_ABILITY
  env.PROC_ON_SWAP_IN = constants.PROC_TYPES.ON_SWAP_IN
  env.PROC_ON_SWAP_OUT = constants.PROC_TYPES.ON_SWAP_OUT

  -- Math utilities
  env.ceil = constants.MATH_UTILS.ceil
  env.floor = constants.MATH_UTILS.floor
  env.abs = constants.MATH_UTILS.abs
  env.min = constants.MATH_UTILS.min
  env.max = constants.MATH_UTILS.max
  env.cond = constants.MATH_UTILS.cond
  env.clamp = constants.MATH_UTILS.clamp

  -- Data fetching functions (bound to abilityInfo)
  env.unitPower = function(target)
    return abilityInfo:GetAttackStat(target or "default")
  end

  env.unitSpeed = function(target)
    return abilityInfo:GetSpeedStat(target or "default")
  end

  env.unitMaxHealth = function(target)
    return abilityInfo:GetMaxHealth(target or "default")
  end

  env.unitHealth = function(target)
    return abilityInfo:GetHealth(target or "default")
  end

  env.unitPetType = function(target)
    return abilityInfo:GetPetType(target or "default")
  end

  env.isInBattle = function()
    return abilityInfo:IsInBattle()
  end

  env.numTurns = function(queryAbilityID)
    local id = queryAbilityID or abilityInfo:GetAbilityID()
    local _, name, icon, maxCooldown, description, numTurns = C_PetBattles.GetAbilityInfoByID(id)
    return numTurns
  end

  env.maxCooldown = function(queryAbilityID)
    local id = queryAbilityID or abilityInfo:GetAbilityID()
    local _, name, icon, maxCooldown, description, numTurns = C_PetBattles.GetAbilityInfoByID(id)
    return maxCooldown
  end

  env.abilityPetType = function(queryAbilityID)
    local id = queryAbilityID or abilityInfo:GetAbilityID()
    local _, name, icon, maxCooldown, description, numTurns, petType = C_PetBattles.GetAbilityInfoByID(id)
    return petType
  end

  env.petTypeName = function(petType)
    return constants:getPetTypeName(petType)
  end

  env.abilityName = function(queryAbilityID)
    local id = queryAbilityID or abilityInfo:GetAbilityID()
    local _, name, icon, maxCooldown, description, numTurns, petType = C_PetBattles.GetAbilityInfoByID(id)
    return name
  end

  env.abilityHasHints = function(queryAbilityID)
    local id = queryAbilityID or abilityInfo:GetAbilityID()
    local _, name, icon, maxCooldown, unparsedDescription, numTurns, petType, noStrongWeakHints = C_PetBattles.GetAbilityInfoByID(id)
    return petType and not noStrongWeakHints
  end

  -- State functions (return defaults for journal tooltips - not in battle)
  env.unitState = function(stateID, target)
    return 0 -- No state modifiers in journal
  end

  env.padState = function(stateID, target)
    return 0 -- No pad effects in journal
  end

  env.weatherState = function(stateID)
    return 0 -- No weather in journal
  end

  env.abilityStateMod = function(stateID, queryAbilityID)
    local id = queryAbilityID or abilityInfo:GetAbilityID()
    return C_PetBattles.GetAbilityStateModification(id, stateID) or 0
  end

  env.unitIsAlly = function(target)
    return true -- In journal, viewing own pet (always ally)
  end

  env.unitHasAura = function(auraID, target)
    return false -- No auras in journal
  end

  env.currentCooldown = function()
    return 0 -- No cooldowns in journal
  end

  env.remainingDuration = function()
    return 0 -- No active effects in journal
  end

  env.getProcIndex = function(procType, queryAbilityID)
    local id = queryAbilityID or abilityInfo:GetAbilityID()
    local turnIndex = C_PetBattles.GetAbilityProcTurnIndex(id, procType)
    if not turnIndex then
      error("No such proc type: " .. tostring(procType))
    end
    return turnIndex
  end

  -- Populate effect parameters dynamically
  local effectParamStrings = {C_PetBattles.GetAllEffectNames()}
  for i = 1, #effectParamStrings do
    local paramName = effectParamStrings[i]
    env[paramName] = function(turnIndex, effectIndex, queryAbilityID)
      local id = queryAbilityID or abilityInfo:GetAbilityID()
      local value = C_PetBattles.GetAbilityEffectInfo(id, turnIndex, effectIndex, paramName)
      if not value then
        error("No such attribute: " .. paramName)
      end
      return value
    end
  end

  -- Populate state constants (STATE_* format)
  C_PetBattles.GetAllStates(env)

  -- Alias functions for common operations
  env.OnlyInBattle = function(text)
    if env.isInBattle() then
      return text
    else
      return ""
    end
  end

  env.School = function(queryAbilityID)
    return env.petTypeName(env.abilityPetType(queryAbilityID))
  end

  env.SumStates = function(stateID, target)
    -- In journal: no weather, no pad, just return unit state (which is 0)
    -- Elementals (type 7) aren't affected by weather even in battles
    if env.unitPetType(target) == 7 then
      return env.unitState(stateID, target) + env.padState(stateID, target)
    else
      return env.unitState(stateID, target) + env.padState(stateID, target) + env.weatherState(stateID)
    end
  end

  -- Accuracy calculation aliases
  env.AccuracyBonus = function(...)
    return env.SumStates(env.STATE_Stat_Accuracy)
  end

  env.SimpleAccuracy = function(...)
    return env.accuracy(...) + env.AccuracyBonus()
  end

  env.StandardAccuracy = function(...)
    local accuracyBonus = env.AccuracyBonus(...)
    local output = string.format("%d%%", math.floor(env.SimpleAccuracy(...)))

    if accuracyBonus > 0 then
      if ENABLE_COLORBLIND_MODE == "1" then
        output = output .. "(+)"
      end
      output = constants.COLORS.GREEN .. output .. constants.COLORS.CLOSE
    elseif accuracyBonus < 0 then
      if ENABLE_COLORBLIND_MODE == "1" then
        output = output .. "(-)"
      end
      output = constants.COLORS.RED .. output .. constants.COLORS.CLOSE
    else
      output = constants.COLORS.HIGHLIGHT .. output .. constants.COLORS.CLOSE
    end

    return output
  end

  -- Attack calculation aliases
  env.AttackBonus = function()
    return 1 + 0.05 * env.unitPower()
  end

  env.SimpleDamage = function(...)
    return env.points(...) * env.AttackBonus()
  end

  env.StandardDamage = function(...)
    local turnIndex, effectIndex, queryAbilityID = ...
    return env.FormatDamage(env.SimpleDamage(...), queryAbilityID)
  end

  env.FormatDamage = function(baseDamage, queryAbilityID)
    if env.isInBattle() and env.abilityHasHints(queryAbilityID) then
      return constants:formatDamage(baseDamage, env.abilityPetType(queryAbilityID), env.unitPetType(env.AFFECTED))
    else
      return env.floor(baseDamage)
    end
  end

  -- Healing calculation aliases
  env.HealingBonus = function()
    return 1 + 0.05 * env.unitPower()
  end

  env.SimpleHealing = function(...)
    return env.points(...) * env.HealingBonus()
  end

  env.StandardHealing = function(...)
    return env.FormatHealing(env.SimpleHealing(...))
  end

  env.FormatHealing = function(baseHealing)
    if env.isInBattle() then
      -- States 65 and 66 are healing done/taken modifiers
      return constants:formatHealing(baseHealing, env.SumStates(65), env.SumStates(66))
    else
      return env.floor(baseHealing)
    end
  end

  return env
end

--[[
  Parse Expression
  Evaluates a single expression in a safe sandbox environment.
  Called by parseText for each [expression] found in the description.

  @param abilityInfo table - The ability context object
  @param expression string - Expression including brackets: "[StandardDamage(1,1)]"
  @return string|number - Evaluated result or error message
]]
local function parseExpression(abilityInfo, expression)
  -- Build parser environment for this parse
  local parserEnv = createParserEnvironment(abilityInfo)

  -- Create safe environment that prevents modification
  local safeEnv = {}
  setmetatable(safeEnv, {
    __index = parserEnv,
    __newindex = function() end -- Prevent environment pollution
  })

  -- Strip brackets and evaluate expression
  local exprCode = string.sub(expression, 2, -2)
  local exprFunc = loadstring("return (" .. exprCode .. ")")

  if not exprFunc then
    return "PARSING ERROR"
  end

  -- Set safe environment
  setfenv(exprFunc, safeEnv)

  -- Evaluate with error handling
  local success, result = pcall(exprFunc)

  if success then
    if type(result) == "number" then
      return math.floor(result) -- No decimals in tooltips
    else
      return result or ""
    end
  else
    -- Handle errors gracefully
    if IsGMClient and IsGMClient() then
      local err = string.match(result, ":%d+: (.*)")
      return "[DATA ERROR: " .. (err or "unknown") .. "]"
    else
      return "DATA ERROR"
    end
  end
end

--[[
  Parse Text
  Main entry point for tooltip parsing. Replaces all [expression] tokens
  in the unparsed text with their evaluated results.

  @param abilityInfo table - The ability context object (from createAbilityInfo)
  @param unparsedText string - Raw ability description with [expressions]
  @return string - Parsed text with expressions replaced by values
]]
function tooltipParser:parseText(abilityInfo, unparsedText)
  -- Validate inputs
  if not abilityInfo then
    if utils then
      utils:error("tooltipParser:parseText - abilityInfo is nil")
    end
    return unparsedText or ""
  end

  if not unparsedText or unparsedText == "" then
    return ""
  end

  -- Replace all [expression] patterns with evaluated results
  local parsed = string.gsub(unparsedText, "%b[]", function(expr)
    return parseExpression(abilityInfo, expr)
  end)

  return parsed
end

--[[
  Initialize Module
  Load dependencies and register with dependency system
]]
function tooltipParser:initialize()
  constants = Addon.abilityConstants
  utils = Addon.utils

  if not constants then
    print("PAO Error: tooltipParser could not load abilityConstants")
    return false
  end

  return true
end

-- Export module
Addon.tooltipParser = tooltipParser

-- Register with dependency system
if Addon.registerModule then
  Addon.registerModule("tooltipParser", {"abilityConstants", "utils"}, function()
    return tooltipParser:initialize()
  end)
end

return tooltipParser