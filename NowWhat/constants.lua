local addonName, ns = ...

ns.STANDING_HATED      = 1
ns.STANDING_HOSTILE    = 2
ns.STANDING_UNFRIENDLY = 3
ns.STANDING_NEUTRAL    = 4
ns.STANDING_FRIENDLY   = 5
ns.STANDING_HONORED    = 6
ns.STANDING_REVERED    = 7
ns.STANDING_EXALTED    = 8

ns.STANDING_NAME = {
    [1] = "Hated",
    [2] = "Hostile",
    [3] = "Unfriendly",
    [4] = "Neutral",
    [5] = "Friendly",
    [6] = "Honored",
    [7] = "Revered",
    [8] = "Exalted",
}

-- Rep required to fill each standing tier
ns.STANDING_MAX = {
    [1] = 36000, -- Hated
    [2] = 3000,  -- Hostile
    [3] = 3000,  -- Unfriendly
    [4] = 3000,  -- Neutral
    [5] = 6000,  -- Friendly
    [6] = 12000, -- Honored
    [7] = 21000, -- Revered
    [8] = 999,   -- Exalted (no ceiling that matters)
}

-- TBC faction IDs (GetFactionInfoByID)
ns.FACTION_SCRYERS             = 934
ns.FACTION_ALDOR               = 932
ns.FACTION_CENARION_EXPEDITION = 942
ns.FACTION_SHATAR              = 935
ns.FACTION_CONSORTIUM          = 933
ns.FACTION_LOWER_CITY          = 1011
ns.FACTION_HONOR_HOLD          = 946
ns.FACTION_THRALLMAR           = 947
ns.FACTION_KEEPERS_OF_TIME     = 989
ns.FACTION_SPOREGGAR           = 970
ns.FACTION_KURENAI             = 978
ns.FACTION_MAGHAR              = 941
ns.FACTION_NETHERWING          = 1015
ns.FACTION_SHATTERED_SUN       = 1077
ns.FACTION_OGRI_LA             = 1038
ns.FACTION_SKYGUARD            = 1031
ns.FACTION_VIOLET_EYE          = 967
ns.FACTION_SCALE_OF_SANDS      = 990
ns.FACTION_ASHTONGUE           = 1012

-- All TBC faction IDs for lookup (GetFactionInfoByID works on all, even undiscovered)
ns.FACTION_IDS = {
    ns.FACTION_SCRYERS, ns.FACTION_ALDOR, ns.FACTION_CENARION_EXPEDITION,
    ns.FACTION_SHATAR, ns.FACTION_CONSORTIUM, ns.FACTION_LOWER_CITY,
    ns.FACTION_HONOR_HOLD, ns.FACTION_THRALLMAR, ns.FACTION_KEEPERS_OF_TIME,
    ns.FACTION_SPOREGGAR, ns.FACTION_KURENAI, ns.FACTION_MAGHAR,
    ns.FACTION_NETHERWING, ns.FACTION_SHATTERED_SUN, ns.FACTION_OGRI_LA,
    ns.FACTION_SKYGUARD, ns.FACTION_VIOLET_EYE, ns.FACTION_SCALE_OF_SANDS,
    ns.FACTION_ASHTONGUE,
}

-- Profession IDs (TBC Classic uses GetSkillLineInfo)
ns.PROFESSION_ALCHEMY        = 171
ns.PROFESSION_BLACKSMITHING  = 164
ns.PROFESSION_ENCHANTING     = 333
ns.PROFESSION_ENGINEERING    = 202
ns.PROFESSION_JEWELCRAFTING  = 755
ns.PROFESSION_LEATHERWORKING = 165
ns.PROFESSION_TAILORING      = 197

-- Item source types for the catalog
ns.SOURCE_VENDOR  = "vendor"
ns.SOURCE_QUEST   = "quest"
ns.SOURCE_CRAFTED = "crafted"
ns.SOURCE_DROP    = "drop"
ns.SOURCE_TURN_IN = "turnIn"
