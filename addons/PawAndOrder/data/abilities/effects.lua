-- data/abilities/effects.lua
-- Effect definitions for pet battle abilities

local _, Addon = ...

local EFFECT_DB = {
    ["damage"] = {
        id = "damage",
        name = "Damage",
        description = "Deals damage to target",
        stackable = false,
        icon = "Interface\\Icons\\Spell_Fire_SoulBurn"
    },
    
    ["sleep"] = {
        id = "sleep",
        name = "Sleep",
        description = "Cannot act for {duration} rounds or until damaged",
        preventsActions = true,
        breaksOnDamage = true,
        immuneTypes = {"critter"},
        stackable = false,
        icon = "Interface\\Icons\\Spell_Nature_Sleep"
    },
    
    ["stun"] = {
        id = "stun",
        name = "Stunned", 
        description = "Cannot act for {duration} rounds",
        preventsActions = true,
        breaksOnDamage = false,
        immuneTypes = {"critter"},
        stackable = false,
        icon = "Interface\\Icons\\Ability_Stun"
    },
    
    ["poison"] = {
        id = "poison",
        name = "Poisoned",
        description = "Takes damage each round for {duration} rounds",
        damagePerRound = true,
        stackable = true,
        icon = "Interface\\Icons\\Ability_Creature_Poison_02"
    },
    
    ["burn"] = {
        id = "burn", 
        name = "Burning",
        description = "Takes elemental damage each round for {duration} rounds",
        damagePerRound = true,
        stackable = true,
        icon = "Interface\\Icons\\Spell_Fire_Immolation"
    },
    
    ["heal"] = {
        id = "heal",
        name = "Heal",
        description = "Restores health to target",
        stackable = false,
        icon = "Interface\\Icons\\Spell_Holy_Heal"
    },
    
    ["shield"] = {
        id = "shield",
        name = "Shield",
        description = "Reduces incoming damage for {duration} rounds",
        stackable = false,
        icon = "Interface\\Icons\\Spell_Holy_PowerWordShield"
    },
    
    ["blind"] = {
        id = "blind",
        name = "Blinded",
        description = "Cannot hit target for {duration} rounds",
        hitChanceReduction = 1.0,
        stackable = false,
        icon = "Interface\\Icons\\Spell_Shadow_MindSteal"
    },
    
    ["root"] = {
        id = "root",
        name = "Rooted",
        description = "Cannot swap out for {duration} rounds",
        preventsSwap = true,
        immuneTypes = {"critter"},
        stackable = false,
        icon = "Interface\\Icons\\Spell_Nature_StrangleVines"
    },
    
    ["polymorph"] = {
        id = "polymorph", 
        name = "Polymorphed",
        description = "Transformed and cannot act for {duration} rounds or until damaged",
        preventsActions = true,
        breaksOnDamage = true,
        stackable = false,
        icon = "Interface\\Icons\\Spell_Nature_Polymorph"
    },
    
    ["dodge"] = {
        id = "dodge",
        name = "Dodge",
        description = "Next attack will miss",
        dodgesNext = true,
        stackable = false,
        icon = "Interface\\Icons\\Ability_Rogue_Evasion"
    },
    
    ["speed_buff"] = {
        id = "speed_buff",
        name = "Speed Increase",
        description = "Increased speed for {duration} rounds",
        speedModifier = 1.25,
        stackable = false,
        icon = "Interface\\Icons\\Ability_Rogue_Sprint"
    },
    
    ["power_buff"] = {
        id = "power_buff",
        name = "Power Increase", 
        description = "Increased damage for {duration} rounds",
        powerModifier = 1.25,
        stackable = false,
        icon = "Interface\\Icons\\Spell_Nature_Bloodlust"
    }
}

local _, Addon = ...

-- Assign static data to addon namespace
Addon.data = Addon.data or {}
Addon.data.effects = EFFECT_DB

-- Register SavedVariable for export
if Addon.registerModule then
    Addon.registerModule("effects_export", {"exports"}, function()
        if Addon.exports then
            Addon.exports:register("effects", function()
                return pao_effects  -- SV data, not static DB
            end)
        end
        return true
    end)
end

return EFFECTS_DB