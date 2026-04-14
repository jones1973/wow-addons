---------------------------------------------------------------------------
-- GrimoireTracker  -  Data.lua
-- Static reference data: icons, spell ordering, baseline abilities,
-- and grimoire rank/level requirements.
--
-- GRIMOIRE_RANKS sourced from in-game vendor dump 2026-02-07.
---------------------------------------------------------------------------

GrimoireTracker = GrimoireTracker or {}

---------------------------------------------------------------------------
-- Pet icons
---------------------------------------------------------------------------
GrimoireTracker.PET_ICONS = {
    ["Imp"]         = "Interface\\Icons\\Spell_Shadow_SummonImp",
    ["Voidwalker"]  = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker",
    ["Succubus"]    = "Interface\\Icons\\Spell_Shadow_SummonSuccubus",
    ["Felhunter"]   = "Interface\\Icons\\Spell_Shadow_SummonFelHunter",
    ["Felguard"]    = "Interface\\Icons\\Spell_Shadow_SummonFelGuard",
}

---------------------------------------------------------------------------
-- Per-pet accent colors (color code strings, no leading |c)
---------------------------------------------------------------------------
GrimoireTracker.PET_COLORS = {
    ["Imp"]        = "ffff8c42",  -- fiery orange
    ["Voidwalker"] = "ff6e8efb",  -- shadow blue
    ["Succubus"]   = "ffee82ee",  -- magenta-pink
    ["Felhunter"]  = "ff4fd1c5",  -- teal
    ["Felguard"]   = "ffcc4444",  -- dark red
}

---------------------------------------------------------------------------
-- Spell icons
---------------------------------------------------------------------------
GrimoireTracker.SPELL_ICONS = {
    -- Imp
    ["Firebolt"]            = "Interface\\Icons\\Spell_Fire_FireBolt",
    ["Blood Pact"]          = "Interface\\Icons\\Spell_Shadow_BloodBoil",
    ["Fire Shield"]         = "Interface\\Icons\\Spell_Fire_FireArmor",
    ["Phase Shift"]         = 136164,
    -- Voidwalker
    ["Torment"]             = "Interface\\Icons\\Spell_Shadow_GatherShadows",
    ["Consume Shadows"]     = "Interface\\Icons\\Spell_Shadow_AntiShadow",
    ["Sacrifice"]           = "Interface\\Icons\\Spell_Shadow_SacrificialShield",
    ["Suffering"]           = "Interface\\Icons\\Spell_Shadow_BlackPlague",
    -- Succubus
    ["Lash of Pain"]        = "Interface\\Icons\\Spell_Shadow_Curse",
    ["Soothing Kiss"]       = "Interface\\Icons\\Spell_Shadow_SoothingKiss",
    ["Seduction"]           = "Interface\\Icons\\Spell_Shadow_MindSteal",
    ["Lesser Invisibility"] = "Interface\\Icons\\Spell_Magic_LesserInvisibilty",
    -- Felhunter
    ["Devour Magic"]        = "Interface\\Icons\\Spell_Nature_WispHeal",
    ["Spell Lock"]          = "Interface\\Icons\\Spell_Shadow_MindRot",
    ["Tainted Blood"]       = "Interface\\Icons\\Spell_Shadow_LifeDrain02",
    ["Paranoia"]            = "Interface\\Icons\\Spell_Shadow_AuraOfDarkness",
    -- Felguard
    ["Cleave"]              = "Interface\\Icons\\Ability_Warrior_Cleave",
    ["Intercept"]           = "Interface\\Icons\\Ability_Rogue_Sprint",
    ["Anguish"]             = "Interface\\Icons\\Spell_Shadow_UnholyFrenzy",
    ["Demonic Frenzy"]      = "Interface\\Icons\\Spell_Shadow_DemonBreath",
    ["Avoidance"]           = "Interface\\Icons\\Ability_Rogue_Feint",
}

---------------------------------------------------------------------------
-- Canonical ordering
---------------------------------------------------------------------------
GrimoireTracker.PET_ORDER = { "Imp", "Voidwalker", "Succubus", "Felhunter", "Felguard" }

GrimoireTracker.SPELL_ORDER = {
    ["Imp"]        = { "Firebolt", "Blood Pact", "Fire Shield", "Phase Shift" },
    ["Voidwalker"] = { "Torment", "Consume Shadows", "Sacrifice", "Suffering" },
    ["Succubus"]   = { "Lash of Pain", "Soothing Kiss", "Seduction", "Lesser Invisibility" },
    ["Felhunter"]  = { "Devour Magic", "Spell Lock", "Tainted Blood", "Paranoia" },
    ["Felguard"]   = { "Cleave", "Intercept", "Anguish", "Avoidance", "Demonic Frenzy" },
}

---------------------------------------------------------------------------
-- Baseline abilities - auto-learned with the pet, no grimoire needed.
-- Only spells whose Rank 1 is NOT sold by the grimoire vendor.
-- BASELINE[pet][spell] = true  (always rank 1)
---------------------------------------------------------------------------
GrimoireTracker.BASELINE = {
    ["Imp"] = {
        ["Firebolt"] = true,        -- vendor starts at Rank 2
    },
    ["Voidwalker"] = {
        ["Torment"] = true,         -- vendor starts at Rank 2
    },
    ["Succubus"] = {
        ["Lash of Pain"] = true,    -- vendor starts at Rank 2
    },
    ["Felhunter"] = {
        ["Devour Magic"] = true,    -- vendor starts at Rank 2
    },
    ["Felguard"] = {
        -- All Felguard grimoires are sold starting at Rank 1.
    },
}

---------------------------------------------------------------------------
-- All grimoire ranks sold by the demon trainer and their required
-- warlock levels.  Sourced from in-game vendor dump.
--
-- GRIMOIRE_RANKS[pet][spell] = { {rank, reqLevel}, ... }
-- Sorted by rank ascending.  Only ranks the vendor sells are listed;
-- baseline Rank 1 spells (Firebolt, Torment, Lash of Pain, Devour Magic)
-- are omitted because the pet learns them automatically.
---------------------------------------------------------------------------
GrimoireTracker.GRIMOIRE_RANKS = {
    ["Imp"] = {
        ["Firebolt"]    = {{2,8},{3,18},{4,28},{5,38},{6,48},{7,58},{8,68}},
        ["Blood Pact"]  = {{1,4},{2,14},{3,26},{4,38},{5,50},{6,62}},
        ["Fire Shield"] = {{1,14},{2,24},{3,34},{4,44},{5,54},{6,64}},
        ["Phase Shift"] = {{1,12}},
    },
    ["Voidwalker"] = {
        ["Torment"]         = {{2,20},{3,30},{4,40},{5,50},{6,60},{7,70}},
        ["Consume Shadows"] = {{1,18},{2,26},{3,34},{4,42},{5,50},{6,58},{7,66}},
        ["Sacrifice"]       = {{1,16},{2,24},{3,32},{4,40},{5,48},{6,56},{7,64}},
        ["Suffering"]       = {{1,24},{2,36},{3,48},{4,60},{5,63},{6,69}},
    },
    ["Succubus"] = {
        ["Lash of Pain"]        = {{2,28},{3,36},{4,44},{5,52},{6,60},{7,68}},
        ["Soothing Kiss"]       = {{1,22},{2,34},{3,46},{4,58},{5,70}},
        ["Seduction"]           = {{1,26}},
        ["Lesser Invisibility"] = {{1,32}},
    },
    ["Felhunter"] = {
        ["Devour Magic"]  = {{2,38},{3,46},{4,54},{5,62},{6,70}},
        ["Spell Lock"]    = {{1,36},{2,52}},
        ["Tainted Blood"] = {{1,32},{2,40},{3,48},{4,56},{5,64}},
        ["Paranoia"]      = {{1,42}},
    },
    ["Felguard"] = {
        ["Cleave"]         = {{1,50},{2,60},{3,68}},
        ["Intercept"]      = {{1,52},{2,61},{3,69}},
        ["Anguish"]        = {{1,50},{2,60},{3,70}},
        ["Avoidance"]      = {{1,60}},
        ["Demonic Frenzy"] = {{1,56}},
    },
}