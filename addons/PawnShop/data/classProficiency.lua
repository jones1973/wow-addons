--[[
  data/classProficiency.lua
  Class Armor/Weapon Proficiencies

  Maps each playable class to the armor classes and weapon subclasses it can
  equip. Used to filter AH items before Pawn evaluation so we don't waste
  Pawn calls on items the character can't wear.

  Also includes canDualWield: which classes can pair two 1H weapons. Classes
  that can't still pair 1H + holdable or 1H + shield.

  Based on TBC Classic proficiencies. Tanks/heals trained at 40 are
  included; we err on the inclusive side to avoid false rejection.

  Subclass IDs:
    Armor:  0=Misc (rings/necks/cloaks/trinkets, always allowed, not listed),
            1=Cloth, 2=Leather, 3=Mail, 4=Plate, 6=Shield, 7=Libram,
            8=Idol, 9=Totem
    Weapon: 0=Axe1H 1=Axe2H 2=Bow 3=Gun 4=Mace1H 5=Mace2H 6=Polearm
            7=Sword1H 8=Sword2H 10=Staff 13=Fist 15=Dagger 16=Thrown
            18=Crossbow 19=Wand

  Dependencies: none (pure data)
  Exports: Addon.data.armorProficiency
           Addon.data.weaponProficiency
           Addon.data.canDualWield
]]

local ADDON_NAME, Addon = ...

Addon.data = Addon.data or {}

-- ============================================================================
-- ARMOR PROFICIENCY
-- ============================================================================

-- Subclass 0 (Misc: rings, necks, cloaks, trinkets, off-hand held) is
-- always allowed and not listed here.
Addon.data.armorProficiency = {
    WARRIOR = { [1]=true, [2]=true, [3]=true, [4]=true, [6]=true },
    PALADIN = { [1]=true, [2]=true, [3]=true, [4]=true, [6]=true, [7]=true },
    HUNTER  = { [1]=true, [2]=true, [3]=true },
    ROGUE   = { [1]=true, [2]=true },
    PRIEST  = { [1]=true },
    SHAMAN  = { [1]=true, [2]=true, [3]=true, [6]=true, [9]=true },
    MAGE    = { [1]=true },
    WARLOCK = { [1]=true },
    DRUID   = { [1]=true, [2]=true, [8]=true },
}

-- ============================================================================
-- WEAPON PROFICIENCY
-- ============================================================================

-- Inclusive; if a specific weapon slipped through that the character hasn't
-- trained, Pawn downstream returns nil and we drop it as not_upgrade anyway.
Addon.data.weaponProficiency = {
    WARRIOR = { [0]=true, [1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [10]=true, [13]=true, [15]=true, [16]=true, [18]=true },
    PALADIN = { [0]=true, [1]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [10]=true },
    HUNTER  = { [0]=true, [1]=true, [2]=true, [3]=true, [4]=true, [6]=true, [7]=true, [8]=true, [10]=true, [13]=true, [15]=true, [18]=true },
    ROGUE   = { [0]=true, [3]=true, [4]=true, [7]=true, [13]=true, [15]=true, [16]=true, [18]=true },
    PRIEST  = { [4]=true, [10]=true, [15]=true, [19]=true },
    SHAMAN  = { [0]=true, [1]=true, [4]=true, [5]=true, [10]=true, [13]=true, [15]=true },
    MAGE    = { [4]=true, [7]=true, [10]=true, [15]=true, [19]=true },
    WARLOCK = { [4]=true, [7]=true, [10]=true, [15]=true, [19]=true },
    DRUID   = { [1]=true, [4]=true, [5]=true, [6]=true, [10]=true, [13]=true, [15]=true },
}

-- ============================================================================
-- DUAL WIELD
-- ============================================================================

-- Per TBC proficiencies: Rogue, Warrior (Fury at 20), Hunter, Shaman (Enh
-- at 40) can. Druid/Paladin/Priest/Mage/Warlock cannot. We assume yes if
-- the talent/spec-gate applies, since it's safer to show a pair that the
-- player just won't buy than to hide one that's actually valid.
Addon.data.canDualWield = {
    WARRIOR     = true,
    ROGUE       = true,
    HUNTER      = true,
    SHAMAN      = true,
    DEATHKNIGHT = true,  -- not relevant in TBC but future-proof for MoP
}

return Addon.data
