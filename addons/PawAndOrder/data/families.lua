-- data/families.lua
-- Pet family passive abilities and effect immunities

local FAMILY_DATA = {
    [1] = { -- Humanoid
        name = "Humanoid",
        passive = "Humanoids recover 4% of their maximum health if they dealt damage this round.",
        immunities = {},
        resistances = {},
        weaknesses = {"Beast"},
        strongAgainst = {"Dragonkin"},
        icon = "Interface\\Icons\\INV_Misc_Head_Human_01"
    },
    
    [2] = { -- Dragonkin  
        name = "Dragonkin",
        passive = "Dragonkins deal 50% additional damage on the next round after bringing a target's health below 50%.",
        immunities = {},
        resistances = {},
        weaknesses = {"Humanoid"},
        strongAgainst = {"Magic"},
        icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01"
    },
    
    [3] = { -- Flying
        name = "Flying", 
        passive = "Flying creatures gain 50% extra speed while above 50% health.",
        immunities = {},
        resistances = {"Flying"},
        weaknesses = {"Magic"},
        strongAgainst = {"Aquatic"},
        icon = "Interface\\Icons\\Spell_Nature_WispSplode"
    },
    
    [4] = { -- Undead
        name = "Undead",
        passive = "Undead pets return to life immortal for 1 round when killed, but deal 25% less damage.",
        immunities = {},
        resistances = {"Undead"},
        weaknesses = {"Critter"},
        strongAgainst = {"Humanoid"},
        icon = "Interface\\Icons\\INV_Misc_Bone_ElfSkull_01"
    },
    
    [5] = { -- Critter
        name = "Critter",
        passive = "Critters are immune to stun, root, and sleep effects.",
        immunities = {"stun", "root", "sleep"},
        resistances = {"Critter"},
        weaknesses = {"Beast"},
        strongAgainst = {"Undead"},
        icon = "Interface\\Icons\\INV_Box_PetCarrier_01"
    },
    
    [6] = { -- Magic
        name = "Magic",
        passive = "Magic pets cannot take more than 35% of their maximum health in one attack.",
        immunities = {},
        resistances = {"Magic"},
        weaknesses = {"Dragonkin"},
        strongAgainst = {"Flying"},
        maxDamagePercent = 35,
        icon = "Interface\\Icons\\INV_Wand_07"
    },
    
    [7] = { -- Elemental
        name = "Elemental",
        passive = "Elementals ignore all negative weather effects. Their attacks can't be dodged.",
        immunities = {"weather"},
        cannotBeDodged = true,
        resistances = {"Elemental"},
        weaknesses = {"Aquatic"},
        strongAgainst = {"Mechanical"},
        icon = "Interface\\Icons\\Spell_Frost_SummonWaterElemental_2"
    },
    
    [8] = { -- Beast
        name = "Beast",
        passive = "Beasts deal 25% extra damage below half health.",
        damageBonus = { condition = "below_50_health", multiplier = 1.25 },
        resistances = {"Beast"},
        weaknesses = {"Mechanical"}, 
        strongAgainst = {"Critter"},
        icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01"
    },
    
    [9] = { -- Aquatic
        name = "Aquatic", 
        passive = "Aquatic pets have a 25% chance to heal when damaged by DOT effects.",
        dotHealChance = 0.25,
        resistances = {"Aquatic"},
        weaknesses = {"Flying"},
        strongAgainst = {"Elemental"},
        icon = "Interface\\Icons\\INV_Misc_Fish_02"
    },
    
    [10] = { -- Mechanical
        name = "Mechanical",
        passive = "Mechanical pets come back to life once per battle, returning to 20% health.",
        reviveOnce = true,
        reviveHealthPercent = 20,
        resistances = {"Mechanical"},
        weaknesses = {"Elemental"}, 
        strongAgainst = {"Beast"},
        icon = "Interface\\Icons\\INV_Gizmo_07"
    }
}

-- Utility functions for family lookups
local FAMILY_UTILS = {
    getById = function(familyId)
        return FAMILY_DATA[familyId]
    end,
    
    getByName = function(familyName) 
        for id, data in pairs(FAMILY_DATA) do
            if data.name:lower() == familyName:lower() then
                return data, id
            end
        end
        return nil
    end,
    
    isImmuneToEffect = function(familyId, effectId)
        local family = FAMILY_DATA[familyId]
        if not family or not family.immunities then return false end
        
        for _, immunity in ipairs(family.immunities) do
            if immunity == effectId then return true end
        end
        return false
    end,
    
    getEffectivenessMultiplier = function(attackerFamily, defenderFamily)
        local attacker = FAMILY_DATA[attackerFamily]
        if not attacker then return 1.0 end
        
        local defenderData = FAMILY_DATA[defenderFamily]
        if not defenderData then return 1.0 end
        
        -- Check if strong against
        if attacker.strongAgainst then
            for _, strongType in ipairs(attacker.strongAgainst) do
                if strongType == defenderData.name then
                    return 1.5 -- 50% bonus damage
                end
            end
        end
        
        -- Check if weak against  
        if attacker.weaknesses then
            for _, weakType in ipairs(attacker.weaknesses) do
                if weakType == defenderData.name then
                    return 0.67 -- 33% damage reduction
                end
            end
        end
        
        return 1.0 -- Normal damage
    end
}

local _, Addon = ...

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("familyData", {}, function()
        return true
    end)
end

Addon.familyData = {
    families = FAMILY_DATA,
    utils = FAMILY_UTILS
}
return {
    families = FAMILY_DATA,
    utils = FAMILY_UTILS
}