-- logic/abilities/abilityData.lua
-- Wrapper for accessing normalized ability, effect, and family data

local _, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r |cffff4444Error|r - Addon.utils not available in abilityData.lua. This is a critical initialization error.")
    return
end

local utils = Addon.utils

-- Import data files
local effectDefinitions = {} 
local abilityDatabase = {}
local familyData = {}
local familyUtils = {}

local abilityData = {}

-- Initialize and load data files
function abilityData:initialize()
    -- Load effect definitions using direct require-style loading
    local effectModule = Addon.effectDefinitions or {}
    if next(effectModule) then
        effectDefinitions = effectModule
        local count = 0
        for _ in pairs(effectDefinitions) do count = count + 1 end
    else
	    -- not currently trafficking in effects
        -- utils:error("abilityData: No effect definitions found")
    end
    
    -- Load ability database
    local abilityModule = Addon.abilityDatabase or {}
    if next(abilityModule) then
        abilityDatabase = abilityModule
        local count = 0
        for _ in pairs(abilityDatabase) do count = count + 1 end
    else
	    -- fairly sure we're not loading ability data this way
        -- utils:error("abilityData: No ability database found")
    end
    
    -- Load family data  
    local familyModule = Addon.familyData or {}
    if next(familyModule) then
        familyData = familyModule.families or {}
        familyUtils = familyModule.utils or {}
        local count = 0
        for _ in pairs(familyData) do count = count + 1 end
    else
        utils:error("abilityData: No family data found")
    end
    
    return true
end

-- Effect Definition Accessors
function abilityData:getEffectDefinition(effectId)
    return effectDefinitions[effectId]
end

function abilityData:getAllEffectDefinitions()
    return effectDefinitions
end

function abilityData:getEffectsByType(effectType)
    local results = {}
    for id, effect in pairs(effectDefinitions) do
        if effect[effectType] then
            results[id] = effect
        end
    end
    return results
end

-- Ability Database Accessors
function abilityData:getAbilityData(abilityId)
    return abilityDatabase[abilityId]
end

function abilityData:getAllAbilities()
    return abilityDatabase
end

function abilityData:getAbilitiesWithEffect(effectId)
    local results = {}
    for id, ability in pairs(abilityDatabase) do
        if ability.effects then
            for _, effect in ipairs(ability.effects) do
                if effect.effectId == effectId then
                    table.insert(results, id)
                    break
                end
            end
        end
    end
    return results
end

function abilityData:getAbilitiesByCooldown(cooldown)
    local results = {}
    for id, ability in pairs(abilityDatabase) do
        if ability.cooldown == cooldown then
            results[id] = ability
        end
    end
    return results
end

function abilityData:getAbilitiesWithSelfEffects()
    local results = {}
    for id, ability in pairs(abilityDatabase) do
        if ability.effects then
            for _, effect in ipairs(ability.effects) do
                if effect.target == "self" then
                    table.insert(results, id)
                    break
                end
            end
        end
    end
    return results
end

-- Family Data Accessors
function abilityData:getFamilyData(familyId)
    if familyUtils.getById then
        return familyUtils:getById(familyId)
    end
    return familyData[familyId]
end

function abilityData:getFamilyByName(familyName)
    if familyUtils.getByName then
        return familyUtils:getByName(familyName)
    end
    
    -- Fallback manual search
    for id, data in pairs(familyData) do
        if data.name and data.name:lower() == familyName:lower() then
            return data, id
        end
    end
    return nil
end

function abilityData:getAllFamilies()
    return familyData
end

function abilityData:isImmuneToEffect(familyId, effectId)
    if familyUtils.isImmuneToEffect then
        return familyUtils:isImmuneToEffect(familyId, effectId)
    end
    
    -- Fallback implementation
    local family = familyData[familyId]
    if not family or not family.immunities then return false end
    
    for _, immunity in ipairs(family.immunities) do
        if immunity == effectId then return true end
    end
    return false
end

function abilityData:getEffectivenessMultiplier(attackerFamily, defenderFamily)
    if familyUtils.getEffectivenessMultiplier then
        return familyUtils:getEffectivenessMultiplier(attackerFamily, defenderFamily)
    end
    return 1.0 -- Fallback to normal damage
end

-- Combo queries combining multiple data sources
function abilityData:getAbilityWithEffectInfo(abilityId)
    local ability = self:getAbilityData(abilityId)
    if not ability then return nil end
    
    local result = {
        ability = ability,
        effects = {}
    }
    
    if ability.effects then
        for _, effect in ipairs(ability.effects) do
            local effectDef = self:getEffectDefinition(effect.effectId)
            table.insert(result.effects, {
                definition = effectDef,
                parameters = effect
            })
        end
    end
    
    return result
end

function abilityData:getCounterAbilities(familyId)
    -- Find abilities that are strong against this family
    local family = self:getFamilyData(familyId)
    if not family or not family.weaknesses then return {} end
    
    local counters = {}
    for _, weakness in ipairs(family.weaknesses) do
        local weaknessFamily, weaknessFamilyId = self:getFamilyByName(weakness)
        if weaknessFamilyId then
            -- Find abilities of this type
            for abilityId, ability in pairs(abilityDatabase) do
                -- This would need additional metadata to determine ability family
                -- For now, placeholder logic
                table.insert(counters, abilityId)
            end
        end
    end
    
    return counters
end

-- Enhanced NPC fields support
function abilityData:enhanceNpcData(npcData)
    if not npcData or not npcData.pets then return npcData end
    
    local enhanced = {}
    for k, v in pairs(npcData) do
        enhanced[k] = v
    end
    
    -- Add notes field if missing
    if not enhanced.notes then
        enhanced.notes = ""
    end
    
    -- Enhance pet ability data
    if enhanced.pets then
        for _, pet in ipairs(enhanced.pets) do
            if pet.abilities then
                pet.enhancedAbilities = {}
                for _, abilityId in ipairs(pet.abilities) do
                    local abilityInfo = self:getAbilityWithEffectInfo(abilityId)
                    if abilityInfo then
                        table.insert(pet.enhancedAbilities, abilityInfo)
                    end
                end
            end
        end
    end
    
    return enhanced
end

-- Update the entity committer tracked fields to include notes
function abilityData:updateEntityCommitterTrackedFields()
    -- This would be called during initialization to ensure notes are tracked
    if Addon.entityCommitter and Addon.entityCommitter.addTrackedField then
        Addon.entityCommitter:addTrackedField("notes")
    end
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("abilityData", {"utils"}, function()
        if abilityData.initialize then
            local success = abilityData:initialize()
            if success then
                return true
            end
        end
        return false
    end)
end

Addon.abilityData = abilityData
return abilityData