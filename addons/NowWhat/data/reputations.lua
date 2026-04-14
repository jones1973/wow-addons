local addonName, ns = ...

--- Faction metadata: zones, quest hubs, key NPCs.
--- Populated for Scryers, CE, Sha'tar, Consortium for now.
ns.dataReputations = {
    [ns.FACTION_SCRYERS] = {
        nameDisplay = "The Scryers",
        zonesQuest = {
            "Netherstorm",
            "Shadowmoon Valley",
            "Shattrath City",
        },
        hubsQuest = {
            {
                zone = "Shattrath City",
                npcName = "Magistrix Fyalenn",
                notes = "Signet and tome turn-ins",
            },
            {
                zone = "Netherstorm",
                subZone = "Area 52",
                npcName = "Spymaster Thalodien",
                notes = "Manaforge chain (~1920 rep)",
            },
            {
                zone = "Netherstorm",
                subZone = "Area 52",
                npcName = "Magistrix Larynna",
                notes = "Sunfury chain through Turning Point (~2075 rep)",
            },
            {
                zone = "Shadowmoon Valley",
                subZone = "Sanctum of the Stars",
                npcName = "Larissa Sunstrike",
                notes = "Karabor Training Grounds chain",
            },
            {
                zone = "Shadowmoon Valley",
                subZone = "Sanctum of the Stars",
                npcName = "Arcanist Thelis",
                notes = "Tablets of Baa'ri chain",
            },
            {
                zone = "Shadowmoon Valley",
                subZone = "Sanctum of the Stars",
                npcName = "Varen the Reclaimer",
                notes = "Ashtongue Broken chain",
            },
        },
        -- 50% of Scryer rep gains also grant Sha'tar rep, up to Friendly 5999
        repSpillover = {
            [ns.FACTION_SHATAR] = { ratio = 0.5, capStanding = ns.STANDING_FRIENDLY, capValue = 5999 },
        },
    },

    [ns.FACTION_CENARION_EXPEDITION] = {
        nameDisplay = "Cenarion Expedition",
        zonesQuest = {
            "Hellfire Peninsula",
            "Zangarmarsh",
            "Terokkar Forest",
            "Blade's Edge Mountains",
            "Netherstorm",
        },
        hubsQuest = {
            {
                zone = "Hellfire Peninsula",
                subZone = "Cenarion Post",
                npcName = "Thiah Redmane",
                notes = "Demonic Contamination chain",
            },
            {
                zone = "Zangarmarsh",
                subZone = "Cenarion Refuge",
                npcName = "Ysiel Windsinger",
                notes = "Main hub, Coilfang Armaments turn-in",
            },
            {
                zone = "Zangarmarsh",
                subZone = "Cenarion Refuge",
                npcName = "Lauranna Thar'well",
                notes = "Plant Parts turn-in (to Honored only)",
            },
            {
                zone = "Terokkar Forest",
                subZone = "Cenarion Thicket",
                npcName = "Earthbinder Tavgren",
                notes = "Tuurem chain (~1875 rep)",
            },
            {
                zone = "Blade's Edge Mountains",
                subZone = "Evergrove",
                npcName = "Tree Warden Chawn",
                notes = "Wyrmcult chain",
            },
            {
                zone = "Blade's Edge Mountains",
                subZone = "Evergrove",
                npcName = "Wildlord Antelarion",
                notes = "Felsworn/Death's Door chain (~1950 rep)",
            },
            {
                zone = "Netherstorm",
                npcName = "Aurine Moonblade",
                notes = "Eco-dome quests (~750 rep), near Stormspire elevator",
            },
        },
    },

    [ns.FACTION_SHATAR] = {
        nameDisplay = "The Sha'tar",
        zonesQuest = {
            "Shattrath City",
            "Shadowmoon Valley",
        },
        hubsQuest = {
            {
                zone = "Shattrath City",
                npcName = "Almaador",
                notes = "Quartermaster, Terrace of Light",
            },
        },
        notes = "Primary rep from Tempest Keep dungeons (Mechanar, Botanica, Arcatraz). "
              .. "Also gains 50% of Scryer/Aldor rep up to Friendly 5999.",
    },

    [ns.FACTION_CONSORTIUM] = {
        nameDisplay = "The Consortium",
        zonesQuest = {
            "Nagrand",
            "Netherstorm",
        },
        hubsQuest = {
            {
                zone = "Nagrand",
                subZone = "Aeris Landing",
                npcName = "Gezhe",
                notes = "Warbead turn-ins, monthly gem salary",
            },
            {
                zone = "Netherstorm",
                subZone = "Area 52",
                npcName = "Nether-Stalker Khay'ji",
                notes = "Crystal Collection -> Zaxxis chain, Arcatraz attunement start",
            },
            {
                zone = "Netherstorm",
                subZone = "Stormspire",
                npcName = "Quartermaster Karaaz",
                notes = "Quartermaster, recipes and gear",
            },
            {
                zone = "Netherstorm",
                subZone = "Protectorate Watch Post",
                npcName = "Commander Ameer",
                notes = "Ethereum Prison key chain (requires Honored)",
            },
        },
    },
}
