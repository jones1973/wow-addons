-- data/species.lua
-- Species database with base stats, abilities, and breed information

local _, Addon = ...

Addon.data = Addon.data or {}
Addon.data.species = {
    [39] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 384,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 389,
                    level = 2
                },
                [2] =                 {
                    id = 392,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 459,
                    level = 4
                },
                [2] =                 {
                    id = 278,
                    level = 20
                }            }
        },
        availableBreeds = {"S/B"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 2671,
        description = "A mechanical squirrel's logic center tells it to collect and store both nuts and bolts for the winter.",
        familyType = 8,
        name = "Mechanical Squirrel",
        source = "Profession: Engineering",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [40] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 7385,
        description = "Donni Anthania plans to have a bombay buried with her when she dies. A wise adventurer can put its talents to much better use.",
        familyType = 1,
        name = "Bombay Cat",
        source = "Vendor: Donni Anthania|nZone: Elwynn Forest|nCost: 40|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [41] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 7384,
        description = "Donni Anthania invites these cats to her tea parties. But she doesn't serve their favorite drink: the tears of their enemies.",
        familyType = 1,
        name = "Cornish Rex Cat",
        source = "Vendor: Donni Anthania|nZone: Elwynn Forest|nCost: 40|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [42] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 6.5,
            power = 9,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 7383,
        description = "Old Alterac saying: 'A cat has nine lives, but needs only one.'",
        familyType = 1,
        name = "Black Tabby Cat",
        source = "Drop: World Drop|nZone: Hillsbrad Foothills",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [43] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 7,
            power = 9,
            speed = 8
        },
        canBattle = true,
        creatureId = 7382,
        description = "The last person who tried to housebreak this cat quickly learned that a soiled rug is better than a shredded everything-else.",
        familyType = 1,
        name = "Orange Tabby Cat",
        source = "Vendor: Donni Anthania, Steven Lisbane|nZone: Elwynn Forest|nCost: 40|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [44] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 7380,
        description = "Known for its blue eyes. Also considered a delicacy by giant murlocs.",
        familyType = 1,
        name = "Siamese Cat",
        source = "Vendor: Dealer Rashaad|nZone: Netherstorm|nCost: 60|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [45] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 7381,
        description = "Sleeping is this cat's second favorite activity. The first is yawning.",
        familyType = 1,
        name = "Silver Tabby Cat",
        source = "Vendor: Donni Anthania|nZone: Elwynn Forest|nCost: 40|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [46] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 7.5,
            power = 7.5,
            speed = 9
        },
        canBattle = true,
        creatureId = 7386,
        description = "'The queen had three kittens. The first gave her a juicy rat. The second, a tasty hare. And the white, her favorite, presented the head of her rival.'",
        familyType = 1,
        name = "White Kitten",
        source = "Vendor: Lil Timmy|nZone: Stormwind City|nCost: 60|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [47] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 521,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 7390,
        description = "Some say this clever bird can be taught to speak--but it's smart enough to keep its beak shut.",
        familyType = 5,
        name = "Cockatiel",
        source = "Vendor: Harry No-Hooks, Narkk|nZone: The Cape of Stranglethorn|nCost: 40|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [49] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 521,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 9,
            power = 7,
            speed = 8
        },
        canBattle = true,
        creatureId = 7391,
        description = "The jungle trolls train these birds to mimic calls for help in order to lure unsuspecting travelers into traps.",
        familyType = 5,
        name = "Hyacinth Macaw",
        source = "Drop: World Drop|nZone: Northern Stranglethorn, The Cape of Stranglethorn",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [50] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 521,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {"S/B"},
        baseStats =         {
            health = 9,
            power = 8,
            speed = 7
        },
        canBattle = true,
        creatureId = 7387,
        description = "Favored pet of the Defias pirates, this colorful bird is handy for remembering passwords, grocery lists, and cracker recipes.",
        familyType = 5,
        name = "Green Wing Macaw",
        source = "Drop: Defias Pirate|nZone: The Deadmines",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [51] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 521,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 7389,
        description = "Favored pet of the goblins of Booty Bay, this colorful bird is renowned for its ability to count coins, tally budgets, and lie about contracts.",
        familyType = 5,
        name = "Senegal",
        source = "Vendor: Narkk, Harry No-Hooks|nZone: The Cape of Stranglethorn|nCost: 40|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t|n|nVendor: Dealer Rashaad|nZone: Netherstorm|nCost: 40|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [52] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 524,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 642,
                    level = 4
                },
                [2] =                 {
                    id = 581,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 7394,
        description = "It thinks you taste like chicken too.",
        familyType = 5,
        name = "Ancona Chicken",
        source = "Vendor: Plucky\" Johnson|nZone: Thousand Needles|nCost: 1|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t\"",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [55] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 8.5,
            power = 7,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 7395,
        description = "The cockroach is usually an impulse buy. Its owners have a hard time parting with it even after numerous attempts.",
        familyType = 2,
        name = "Undercity Cockroach",
        source = "Vendor: Dealer Rashaad|nZone: Netherstorm|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t|n|nVendor: Jeremiah Payson|nZone: Tirisfal Glades|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [56] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 393,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 347,
                    level = 2
                },
                [2] =                 {
                    id = 256,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 169,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8.5,
            power = 9,
            speed = 6.5
        },
        canBattle = true,
        creatureId = 7543,
        description = "Hopes that someday it can grow up to destroy villages, just like mommy.",
        familyType = 3,
        name = "Dark Whelpling",
        source = "Drop: Whelplings|nZone: Wetlands, Dustwallow Marsh, Badlands, Burning Steppes",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [57] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 115,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 589,
                    level = 2
                },
                [2] =                 {
                    id = 592,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 593,
                    level = 4
                },
                [2] =                 {
                    id = 624,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 7547,
        description = "Like other members of the blue dragonflight, these whimsical little critters display an affinity to arcane magic.",
        familyType = 3,
        name = "Azure Whelpling",
        source = "Drop: World Drop|nZone: Winterspring",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [58] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 168,
                    level = 2
                },
                [2] =                 {
                    id = 172,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 169,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 7,
            power = 9,
            speed = 8
        },
        canBattle = true,
        creatureId = 7544,
        description = "Hailing from the Wetlands, this young dragon is just learning how to hunt, breathe fire, and go on cute destructive rampages.",
        familyType = 3,
        name = "Crimson Whelpling",
        source = "Drop: World Drop|nZone: Wetlands",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [59] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 525,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 595,
                    level = 2
                },
                [2] =                 {
                    id = 597,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 254,
                    level = 4
                },
                [2] =                 {
                    id = 598,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 7545,
        description = "Once bred and raised by the green dragon Itharius, this unique breed of dragon has settled in the jungles of Feralas.",
        familyType = 3,
        name = "Emerald Whelpling",
        source = "Drop: Noxious Whelp|nZone: Feralas",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [64] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 7550,
        description = "Vendors at the Darkmoon Faire offer strange and exotic wonders. They also sell wood frogs.",
        familyType = 0,
        name = "Wood Frog",
        source = "Vendor: Flik|nZone: Darkmoon Island|nCost: 1|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [65] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 7549,
        description = "Known for their powerful legs and keen eyesight.",
        familyType = 0,
        name = "Tree Frog",
        source = "Vendor: Flik|nZone: Darkmoon Island|nCost: 1|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [67] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 184,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 784,
                    level = 2
                },
                [2] =                 {
                    id = 190,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 517,
                    level = 4
                },
                [2] =                 {
                    id = 518,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 7555,
        description = "This dark-feathered bird of prey is often seen as a harbinger of doom amongst the druids of Teldrassil.",
        familyType = 5,
        name = "Hawk Owl",
        source = "Vendor: Shylenai|nZone: Teldrassil|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [68] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 184,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 784,
                    level = 2
                },
                [2] =                 {
                    id = 190,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 517,
                    level = 4
                },
                [2] =                 {
                    id = 518,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 7553,
        description = "Night elf children are given an owl feather on their first birthday as a token of good luck.",
        familyType = 5,
        name = "Great Horned Owl",
        source = "Vendor: Shylenai|nZone: Teldrassil|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [70] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 367,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 165,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 159,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 14421,
        description = "A complex system of burrows protects the prairie dog from its neighbors' massive hooves.",
        familyType = 2,
        name = "Brown Prairie Dog",
        source = "Vendor: Halpa, Naleen|nZone: Mulgore|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [72] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 7,
            speed = 9
        },
        canBattle = true,
        creatureId = 7560,
        description = "If you go chasing snowshoe rabbits, you know you're going to fall.",
        familyType = 2,
        name = "Snowshoe Rabbit",
        source = "Vendor: Yarlyn Amberstill|nZone: Dun Morogh|nCost: 20|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [74] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {"S/B"},
        baseStats =         {
            health = 7.5,
            power = 7.5,
            speed = 9
        },
        canBattle = true,
        creatureId = 7561,
        description = "A favored companion of Kirin Tor magi, this reptile makes one wonder whether it's truly a snake or something else altogether.",
        familyType = 1,
        name = "Albino Snake",
        source = "Vendor: Breanni|nZone: Dalaran|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [75] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 7565,
        description = "Xan'tish fearlessly tracks, captures, and trains these noble snakes so they will aid their comrades in battle.",
        familyType = 1,
        name = "Black Kingsnake",
        source = "Vendor: Xan'tish|nZone: Orgrimmar|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [77] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 7562,
        description = "The brown snake is native to Horde-controlled territories. It seems unremarkable until its victims are within range.",
        familyType = 1,
        name = "Brown Snake",
        source = "Vendor: Xan'tish|nZone: Orgrimmar|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [78] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 7567,
        description = "The crimson snake is favored among the Darkspear trolls for not only its vicious nature, but also its steadfast loyalty.",
        familyType = 1,
        name = "Crimson Snake",
        source = "Vendor: Dealer Rashaad|nZone: Netherstorm|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t|n|nVendor: Xan'tish|nZone: Orgrimmar|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [83] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 455,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 389,
                    level = 2
                },
                [2] =                 {
                    id = 533,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 208,
                    level = 4
                },
                [2] =                 {
                    id = 459,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 8376,
        description = "Not to worry; the combat mechanisms and homing logic have been disabled on this unit, I think. --Oglethorpe Obnoticus",
        familyType = 8,
        name = "Mechanical Chicken",
        source = "Quest: An OOX of Your Own|nZone: Booty Bay|n",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [84] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 524,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 642,
                    level = 4
                },
                [2] =                 {
                    id = 581,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 30379,
        description = "Don't call this bird chicken unless you want egg on your face.",
        familyType = 5,
        name = "Westfall Chicken",
        source = "Quest: CLUCK!|nZone: Westfall",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [85] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 116,
                    level = 1
                },
                [2] =                 {
                    id = 455,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 634,
                    level = 2
                },
                [2] =                 {
                    id = 640,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 754,
                    level = 4
                },
                [2] =                 {
                    id = 282,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 9656,
        description = "Possibly explosive, definitely adorable. Keep away from open flame.",
        familyType = 8,
        name = "Pet Bombling",
        source = "Profession: Engineering",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [86] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 777,
                    level = 1
                },
                [2] =                 {
                    id = 455,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 640,
                    level = 2
                },
                [2] =                 {
                    id = 634,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 636,
                    level = 4
                },
                [2] =                 {
                    id = 293,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 9657,
        description = "This tiny peacekeeper security bot is often outfitted with the latest arcane nullifiers and crowd pummelers. Not for the environmentally minded.",
        familyType = 8,
        name = "Lil' Smoky",
        source = "Profession: Engineering",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [87] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 421,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 440,
                    level = 2
                },
                [2] =                 {
                    id = 277,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 595,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 9662,
        description = "These adorable critters love snuggling with their owners after a long day of brutal, bloody battle.",
        familyType = 3,
        name = "Sprite Darter Hatchling",
        source = "Drop: World Drop|nZone: Feralas",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [89] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 362,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 366,
                    level = 20
                }            }
        },
        availableBreeds = {"H/H"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 10259,
        description = "Worgs are the favored companions of orcs and are fiercely loyal on the battlefield.",
        familyType = 1,
        name = "Worg Pup",
        source = "Drop: Quartermaster Zigris|nZone: Lower Blackrock Spire",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [90] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 378,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 382,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 250,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 10598,
        description = "Although born in the warm heights of Blackrock Spire, the smolderweb hatchling can survive most environments.",
        familyType = 1,
        name = "Smolderweb Hatchling",
        source = "Drop: Mother Smolderweb|nZone: Lower Blackrock Spire",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [92] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 347,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 247,
                    level = 2
                },
                [2] =                 {
                    id = 348,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 345,
                    level = 4
                },
                [2] =                 {
                    id = 124,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 11325,
        description = "This pint-sized panda cub is highly sought after by adventurers around Azeroth - despite its narcoleptic nature.",
        familyType = 1,
        name = "Panda Cub",
        source = "Promotion: World of Warcraft Collector's Edition",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [93] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 472,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 256,
                    level = 2
                },
                [2] =                 {
                    id = 468,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 471,
                    level = 4
                },
                [2] =                 {
                    id = 650,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 6.5,
            power = 9,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 11326,
        description = "AND THE HEAVENS SHALL TREMBLE, AND MAN SHALL WEEP, AND THE END OF DAYS SHALL--wait, why are you so tall?",
        familyType = 7,
        name = "Mini Diablo",
        source = "Promotion: World of Warcraft Collectors Edition",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [94] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 194,
                    level = 2
                },
                [2] =                 {
                    id = 197,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 160,
                    level = 4
                },
                [2] =                 {
                    id = 198,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 7,
            power = 7,
            speed = 10
        },
        canBattle = true,
        creatureId = 11327,
        description = "A small, fierce member of the Zerg swarm, the zergling is not to be trifled with. Very dangerous in high numbers.",
        familyType = 7,
        name = "Zergling",
        source = "Promotion: World of Warcraft Collectors Edition",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [95] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 278,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 12419,
        description = "Talented engineers have crafted an exact replica of a wood frog, at only ten times the cost of buying the real thing.",
        familyType = 8,
        name = "Lifelike Toad",
        source = "Profession: Engineering",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [106] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 14878,
        description = "The legendary ale frog was believed to be extinct until the strange brews at the Darkmoon Faire brought them out of hiding.",
        familyType = 0,
        name = "Jubling",
        source = "World Event: Darkmoon Faire",
        sourceTypeEnum = 6,
        tradeable = false,
        unique = false
    },
    [111] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 111,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 756,
                    level = 2
                },
                [2] =                 {
                    id = 757,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 350,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 15358,
        description = "Lurky's charming disposition and lively antics are guaranteed to soothe frustration and lighten even the darkest moods.",
        familyType = 6,
        name = "Lurky",
        source = "Promotion: Burning Crusade Collector's Edition (EU only)|n",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [114] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 445,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 447,
                    level = 2
                },
                [2] =                 {
                    id = 448,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 450,
                    level = 4
                },
                [2] =                 {
                    id = 369,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 15429,
        description = "Warning: Wear gloves and goggles while handling disgusting oozeling. DO NOT WASH. Will stain most armor.",
        familyType = 7,
        name = "Disgusting Oozeling",
        source = "Drop: World Drop|nCreature: Oozes, Slimes and Worms",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [116] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 384,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 204,
                    level = 2
                },
                [2] =                 {
                    id = 206,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 208,
                    level = 4
                },
                [2] =                 {
                    id = 209,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 15699,
        description = "This clever toy is equipped with a secret switch to disable its 'tranquil' mode. Luckily, even the engineers who built it don't know how to find it.",
        familyType = 8,
        name = "Tranquil Mechanical Yeti",
        source = "Profession: Engineering",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [117] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 477,
                    level = 1
                },
                [2] =                 {
                    id = 478,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 206,
                    level = 2
                },
                [2] =                 {
                    id = 414,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 120,
                    level = 4
                },
                [2] =                 {
                    id = 481,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 15710,
        description = "He loves to dance and wave and play with you! He melts after Winter Veil, but don't worry; he'll be back again someday!",
        familyType = 4,
        name = "Tiny Snowman",
        source = "World Event: Feast of Winter Veil|n",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [118] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 493,
                    level = 1
                },
                [2] =                 {
                    id = 163,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 254,
                    level = 2
                },
                [2] =                 {
                    id = 574,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 539,
                    level = 4
                },
                [2] =                 {
                    id = 376,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 15706,
        description = "Would rather not spend any more time inside a wrapped holiday gift box.",
        familyType = 2,
        name = "Winter Reindeer",
        source = "World Event: Feast of Winter Veil",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [119] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 477,
                    level = 1
                },
                [2] =                 {
                    id = 413,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 206,
                    level = 2
                },
                [2] =                 {
                    id = 835,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 624,
                    level = 4
                },
                [2] =                 {
                    id = 586,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 15698,
        description = "These off-season allies work tirelessly to prepare for the Feast of Winter Veil, and would appreciate not being disturbed the rest of the year.",
        familyType = 6,
        name = "Father Winter's Helper",
        source = "World Event: Feast of Winter Veil",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [120] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 477,
                    level = 1
                },
                [2] =                 {
                    id = 413,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 206,
                    level = 2
                },
                [2] =                 {
                    id = 835,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 624,
                    level = 4
                },
                [2] =                 {
                    id = 586,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 15705,
        description = "During the majestic Winter Veil celebration, these faithful companions spread joy throughout the land. The rest of the year, they are busy.",
        familyType = 6,
        name = "Winter's Little Helper",
        source = "World Event: Feast of Winter Veil",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [121] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 111,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 756,
                    level = 2
                },
                [2] =                 {
                    id = 757,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 350,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 16069,
        description = "Gurky is a born performer, though she remains elusive, making public appearances only on the rarest of occasions.",
        familyType = 6,
        name = "Gurky",
        source = "Promotion: EU Fansite Promotion|n",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [122] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 771,
                    level = 1
                },
                [2] =                 {
                    id = 774,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 772,
                    level = 2
                },
                [2] =                 {
                    id = 775,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 773,
                    level = 4
                },
                [2] =                 {
                    id = 776,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 16085,
        description = "The power of love can be a dangerous thing, especially when wielded by an airborne, ill-tempered goblin.",
        familyType = 6,
        name = "Peddlefeet",
        source = "World Event: Love is in the Air|nVendor: Lovely Merchant|nCost: 40|TINTERFACE\\\\ICONS\\\\INV_ValentinesCard01:0|t|n",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [124] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 347,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 348,
                    level = 2
                },
                [2] =                 {
                    id = 247,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 345,
                    level = 4
                },
                [2] =                 {
                    id = 206,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 16456,
        description = "This cub shares many traits with its relatives, but it's in a league of its own with its singing ability.",
        familyType = 1,
        name = "Poley",
        source = "Promotion: iCoke",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [125] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 249,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 310,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 376,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 16547,
        description = "Slow and steady wins the race.",
        familyType = 0,
        name = "Speedy",
        source = "World Event: Children's Week",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [126] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 493,
                    level = 1
                },
                [2] =                 {
                    id = 499,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 578,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 252,
                    level = 4
                },
                [2] =                 {
                    id = 376,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 16548,
        description = "Many assume 'Wiggles' refers to the motion of this pig's posterior. They discover the true meaning when they see their own entrails.",
        familyType = 2,
        name = "Mr. Wiggles",
        source = "World Event: Children's Week",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [127] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 359,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 253,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 16549,
        description = "A clever tactician, Whiskers will feign death to fool predators and bill collectors.",
        familyType = 2,
        name = "Whiskers the Rat",
        source = "World Event: Children's Week",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [128] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 501,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 178,
                    level = 2
                },
                [2] =                 {
                    id = 172,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 179,
                    level = 4
                },
                [2] =                 {
                    id = 409,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 16701,
        description = "This little piece of summer smells of warm evenings and lightning storms. If you look closely, you might be able to make out a face.",
        familyType = 4,
        name = "Spirit of Summer",
        source = "World Event: Midsummer Fire Festival|nVendor: Midsummer Merchant|nCost: 350|TINTERFACE\\\\ICONS\\\\INV_SummerFest_FireFlower:0|t",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [131] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 608,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 764,
                    level = 2
                },
                [2] =                 {
                    id = 188,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 609,
                    level = 4
                },
                [2] =                 {
                    id = 752,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 18381,
        description = "Offspring of the nether drakes of Outland, this young dragon is still growing into its role as hunter, protector, and adorable terror of the skies.",
        familyType = 3,
        name = "Netherwhelp",
        source = "Promotion: Burning Crusade Collector's Edition",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [132] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 356,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 511,
                    level = 2
                },
                [2] =                 {
                    id = 310,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 513,
                    level = 4
                },
                [2] =                 {
                    id = 273,
                    level = 20
                }            }
        },
        availableBreeds = {"H/H"},
        baseStats =         {
            health = 9,
            power = 8,
            speed = 7
        },
        canBattle = true,
        creatureId = 18839,
        description = "Only magical wishes make magical crawdads. If you wish for a fish, fish for a wish.",
        familyType = 0,
        name = "Magical Crawdad",
        source = "Fishing: Fishing (430)|nZone: Terokkar Forest (Fishing Nodes)",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [136] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 484,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 486,
                    level = 2
                },
                [2] =                 {
                    id = 488,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 489,
                    level = 4
                },
                [2] =                 {
                    id = 490,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/P",
            "P/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 20408,
        description = "The ethereal Rashaad began breeding these enigmatic creatures after learning of their ability to feed on arcane energies.",
        familyType = 7,
        name = "Mana Wyrmling",
        source = "Vendor: Dealer Rashaad|nZone: Netherstorm|nCost: 40|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [137] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 7,
            speed = 9
        },
        canBattle = true,
        creatureId = 20472,
        description = "This bunny is the cutest thing its opponent will ever see. It'll also be the last.",
        familyType = 2,
        name = "Brown Rabbit",
        source = "Vendor: Dealer Rashaad|nZone: Netherstorm|nCost: 10|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [138] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 21010,
        description = "Delicate denizen of Azuremyst Isle, this magical insect has been rumored to possess healing abilities.",
        familyType = 5,
        name = "Blue Moth",
        source = "Vendor: Sixx|nZone: The Exodar|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [139] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S",
            "H/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 21009,
        description = "A product of exposure to wild magical energies, this insect is the unexpectedly colorful result of Azerothian moth species being released into the eco-domes of the Netherstorm.",
        familyType = 5,
        name = "Red Moth",
        source = "Vendor: Dealer Rashaad|nZone: Netherstorm|nCost: 10|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [140] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 21008,
        description = "Prefers flying during thunderstorms, which are common in Azuremyst Isle.",
        familyType = 5,
        name = "Yellow Moth",
        source = "Vendor: Sixx|nZone: The Exodar|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [141] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/B"
        },
        baseStats =         {
            health = 7.5,
            power = 7.5,
            speed = 9
        },
        canBattle = true,
        creatureId = 21018,
        description = "Prefers flying during foggy nights, which are common in Azuremyst Isle.",
        familyType = 5,
        name = "White Moth",
        source = "Vendor: Sixx|nZone: The Exodar|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [142] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 184,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 179,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 501,
                    level = 4
                },
                [2] =                 {
                    id = 503,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 21055,
        description = "Once prized by dragonhawk breeders in Silvermoon. Stands out at night to predators, making it necessary to gain awareness at an early age.",
        familyType = 3,
        name = "Golden Dragonhawk Hatchling",
        source = "Vendor: Jilanne|nZone: Eversong Woods|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [143] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 184,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 179,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 501,
                    level = 4
                },
                [2] =                 {
                    id = 503,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 21064,
        description = "Mortal enemies with silver dragonhawks; on pretty good terms with golden dragonhawks.",
        familyType = 3,
        name = "Red Dragonhawk Hatchling",
        source = "Vendor: Jilanne|nZone: Eversong Woods|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [144] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 184,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 179,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 501,
                    level = 4
                },
                [2] =                 {
                    id = 503,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 7.5,
            power = 7.5,
            speed = 9
        },
        canBattle = true,
        creatureId = 21063,
        description = "Ferocious species of dragonhawk, often seen diving down on prey from high in the sky.",
        familyType = 3,
        name = "Silver Dragonhawk Hatchling",
        source = "Vendor: Jilanne|nZone: Eversong Woods|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [145] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 184,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 179,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 501,
                    level = 4
                },
                [2] =                 {
                    id = 503,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/H",
            "P/S"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 21056,
        description = "Raised by the few dealers still willing to trade in Netherstorm.",
        familyType = 3,
        name = "Blue Dragonhawk Hatchling",
        source = "Vendor: Dealer Rashaad|nZone: Netherstorm|nCost: 10|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [146] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 632,
                    level = 2
                },
                [2] =                 {
                    id = 506,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 270,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 21076,
        description = "Commonly used by sporelings as a light source as they navigate the waterways of Zangarmarsh, this luminescent insect helps them avoid the dangerous bogflare needlers.",
        familyType = 5,
        name = "Firefly",
        source = "Drop: Bogflare Needler|nZone: Zangarmarsh",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [149] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 184,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 784,
                    level = 2
                },
                [2] =                 {
                    id = 190,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 517,
                    level = 4
                },
                [2] =                 {
                    id = 518,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 7.5,
            power = 7,
            speed = 9.5
        },
        canBattle = true,
        creatureId = 22445,
        description = "The magical energies released during Skywing's transformation back into his true arakkoa form liberated this poor creature, a fledgling bird imprisoned by Luanga in order to power his fowl curse.",
        familyType = 5,
        name = "Miniwing",
        source = "Quest: Skywing|nZone: Terokkar Forest|n|n",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [153] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 571,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 515,
                    level = 2
                },
                [2] =                 {
                    id = 594,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 376,
                    level = 4
                },
                [2] =                 {
                    id = 124,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 22943,
        description = "Many a drunken Brewfest goer has told the tale of this mysterious creature, but few remember that tale in the morning.",
        familyType = 2,
        name = "Wolpertinger",
        source = "World Event: Brewfest",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [155] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 493,
                    level = 1
                },
                [2] =                 {
                    id = 499,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 578,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 252,
                    level = 4
                },
                [2] =                 {
                    id = 376,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 23198,
        description = "Lucky squeals when he's angry or when he's eating. Either way, you don't want to bother him.",
        familyType = 2,
        name = "Lucky",
        source = "Promotion: World Wide Invitational 2007|n",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [157] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 228,
                    level = 1
                },
                [2] =                 {
                    id = 473,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 474,
                    level = 2
                },
                [2] =                 {
                    id = 475,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 468,
                    level = 4
                },
                [2] =                 {
                    id = 476,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 23231,
        description = "He's slightly evil but extremely narcoleptic. Keep him away from critters!",
        familyType = 7,
        name = "Willy",
        source = "World Event: Children's Week",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [158] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 112,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 310,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 377,
                    level = 4
                },
                [2] =                 {
                    id = 568,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 23258,
        description = "The sin'dorei use hawkstriders as mounts, but this little one was deemed unfit after being diagnosed with numerous anxiety disorders.",
        familyType = 2,
        name = "Egbert",
        source = "World Event: Children's Week",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [159] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 349,
                    level = 1
                },
                [2] =                 {
                    id = 377,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 375,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 376,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {"H/H"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 23266,
        description = "Domesticated elekks are trained as mounts by the draenei people. In the wild they are hunted for their ivory tusks.",
        familyType = 2,
        name = "Peanut",
        source = "World Event: Children's Week",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [160] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 576,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 527,
                    level = 4
                },
                [2] =                 {
                    id = 539,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 23274,
        description = "Stinker uses his aroma to repel predators and attract cats. He's much more successful with the former than the latter.",
        familyType = 2,
        name = "Stinker",
        source = "Achievement: Shop Smart, Shop Pet...Smart|nCategory: Pet Battles",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [162] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 398,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 318,
                    level = 2
                },
                [2] =                 {
                    id = 402,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 303,
                    level = 4
                },
                [2] =                 {
                    id = 745,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 23909,
        description = "This mischievous gourd likes to pop out of the ground and scare you right out of your pants. Hail to the pumpkin song!",
        familyType = 4,
        name = "Sinister Squashling",
        source = "World Event: Hallow's End",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [163] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 803,
                    level = 1
                },
                [2] =                 {
                    id = 160,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 509,
                    level = 2
                },
                [2] =                 {
                    id = 118,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 423,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 24388,
        description = "The crocolisk's hide and meat are prized by hunters, but the beast is ferocious and seldom taken by surprise.",
        familyType = 0,
        name = "Toothy",
        source = "Profession: Fishing|nZone: Shattrath",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [164] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 803,
                    level = 1
                },
                [2] =                 {
                    id = 160,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 509,
                    level = 2
                },
                [2] =                 {
                    id = 118,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 423,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 24389,
        description = "Muckbreath is just like other crocolisks, except he has an excellent sense of humor.",
        familyType = 0,
        name = "Muckbreath",
        source = "Profession: Fishing|nZone: Shattrath",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [165] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 24480,
        description = "Amani witch doctors have turned many victims into frogs. Some never recover.",
        familyType = 0,
        name = "Mojo",
        source = "Drop: Forest Frog|nZone: Zul'Aman",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [166] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 349,
                    level = 1
                },
                [2] =                 {
                    id = 377,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 375,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 376,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 24753,
        description = "A shy creature, the pink elekk will only make its presence known to those that have befriended it, or to anyone too intoxicated to harm it.",
        familyType = 2,
        name = "Pint-Sized Pink Pachyderm",
        source = "World Event: Brewfest|nVendor: Belbi Quikswitch|nZone: Dun Morogh|nCost: 100|TINTERFACE\\\\ICONS\\\\INV_Misc_Coin_01:0|t|n|nVendor: Bliz Fixwidget|nZone: Durotar|nCost: 100|TINTERFACE\\\\ICONS\\\\INV_Misc_Coin_01:0|t",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [167] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 210,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 743,
                    level = 2
                },
                [2] =                 {
                    id = 745,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 746,
                    level = 4
                },
                [2] =                 {
                    id = 632,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 9,
            power = 7.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 25062,
        description = "Wild sporebats are vicious creatures, but if tamed at a young age, they can be loyal companions.",
        familyType = 5,
        name = "Tiny Sporebat",
        source = "Vendor: Mycah|nZone: Zangarmarsh|nFaction: Sporeggar - Exalted|nCost: 30|TINTERFACE\\\\ICONS\\\\INV_Mushroom_02:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [172] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 501,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 178,
                    level = 2
                },
                [2] =                 {
                    id = 172,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 179,
                    level = 4
                },
                [2] =                 {
                    id = 409,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 25706,
        description = "Elder shaman have warned that wisps of Ragnaros, loyal servants of the Firelord, have taken to the Molten Front.  Vigilance is advised.",
        familyType = 4,
        name = "Searing Scorchling",
        source = "Vendor: Zen'Vorka|nZone: Molten Front|nCost: 30|TINTERFACE\\\\ICONS\\\\INV_MISC_MARKOFTHEWORLDTREE.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [173] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 803,
                    level = 1
                },
                [2] =                 {
                    id = 160,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 509,
                    level = 2
                },
                [2] =                 {
                    id = 118,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 423,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 26050,
        description = "Crocolisks are six-legged amphibian predators found in coastal waters. Archaeologists believe they may be descended from the diemetradons of Un'Goro Crater.",
        familyType = 0,
        name = "Snarly",
        source = "Profession: Fishing|nZone: Shattrath",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [174] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 803,
                    level = 1
                },
                [2] =                 {
                    id = 160,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 509,
                    level = 2
                },
                [2] =                 {
                    id = 118,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 423,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 26056,
        description = "After studying the crocolisk species for several years, the famed angler Nat Pagle determined that baby crocolisks are mostly harmless.",
        familyType = 0,
        name = "Chuck",
        source = "Profession: Fishing|nZone: Shattrath",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [175] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 112,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 173,
                    level = 2
                },
                [2] =                 {
                    id = 178,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 409,
                    level = 4
                },
                [2] =                 {
                    id = 179,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 26119,
        description = "A child of phoenix god Al'ar, the hatchling takes flight immediately after birth.",
        familyType = 4,
        name = "Phoenix Hatchling",
        source = "Drop: Kael'thas Sunstrider|nZone: Magisters' Terrace",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [179] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 611,
                    level = 2
                },
                [2] =                 {
                    id = 614,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 860,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 27217,
        description = "These stunning creatures, awarded to heroes for victory in battle, represent bravery and strength.",
        familyType = 3,
        name = "Spirit of Competition",
        source = "Promotion: Battleground Event",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = false
    },
    [180] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 611,
                    level = 2
                },
                [2] =                 {
                    id = 614,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 860,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 27346,
        description = "Only heroes who have proven their valor through great acts are gifted one of these mystical serpentine creatures.",
        familyType = 3,
        name = "Essence of Competition",
        source = "Promotion: China PVP Event",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = false
    },
    [186] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 421,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 122,
                    level = 2
                },
                [2] =                 {
                    id = 420,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 422,
                    level = 4
                },
                [2] =                 {
                    id = 394,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 28470,
        description = "Native to the Terokkar Forest, nether rays spawn during the rainy season. Out of the hundreds of offspring resulting from one hatching, very few survive to adulthood.",
        familyType = 5,
        name = "Nether Ray Fry",
        source = "Vendor: Grella|nZone: Terokkar Forest|nFaction: Sha'tari Skyguard - Exalted|nCost: 40|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [187] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 357,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 383,
                    level = 2
                },
                [2] =                 {
                    id = 521,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 186,
                    level = 4
                },
                [2] =                 {
                    id = 517,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 28513,
        description = "Vampire bats have been trained as scouts and mounts by the Forsaken of the Undercity and the Amani trolls of Zul'Aman.",
        familyType = 9,
        name = "Vampiric Batling",
        source = "Drop: Prince Tenris Mirkblood|nZone: Karazhan",
        sourceTypeEnum = 0,
        tradeable = false,
        unique = false
    },
    [188] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 499,
                    level = 1
                },
                [2] =                 {
                    id = 782,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 206,
                    level = 2
                },
                [2] =                 {
                    id = 784,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 624,
                    level = 4
                },
                [2] =                 {
                    id = 786,
                    level = 20
                }            }
        },
        availableBreeds = {"H/H"},
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 28883,
        description = "Accidentally created when the Lich King's deathly powers raised Rimefang from undeath.",
        familyType = 9,
        name = "Frosty",
        source = "Promotion: Wrath of the Lich King Collector's Edition",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [189] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 765,
                    level = 1
                },
                [2] =                 {
                    id = 768,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 766,
                    level = 2
                },
                [2] =                 {
                    id = 769,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 767,
                    level = 4
                },
                [2] =                 {
                    id = 770,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 29089,
        description = "'I am Justice itself!'",
        familyType = 6,
        name = "Mini Tyrael",
        source = "Promotion: World Wide Invitational 2008",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [190] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 210,
                    level = 1
                },
                [2] =                 {
                    id = 121,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 654,
                    level = 2
                },
                [2] =                 {
                    id = 442,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 212,
                    level = 4
                },
                [2] =                 {
                    id = 321,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/P",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 29147,
        description = "When it senses the impending death of a nearby creature, the skull will emit an ear-piercing cackle.",
        familyType = 9,
        name = "Ghostly Skull",
        source = "Vendor: Darahir|nZone: Crystalsong Forest|nCost: 40|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [191] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 777,
                    level = 1
                },
                [2] =                 {
                    id = 455,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 640,
                    level = 2
                },
                [2] =                 {
                    id = 634,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 636,
                    level = 4
                },
                [2] =                 {
                    id = 293,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 24968,
        description = "This mechanical warrior is a favorite gift during Winter Veil. Batteries not included, but rockets definitely are!",
        familyType = 8,
        name = "Clockwork Rocket Bot",
        source = "World Event: Feast of Winter Veil",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [192] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 528,
                    level = 2
                },
                [2] =                 {
                    id = 575,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 413,
                    level = 4
                },
                [2] =                 {
                    id = 529,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 29726,
        description = "Mr. Chilly's appearance evokes a more civilized era, when duelists battled in tuxedos.",
        familyType = 0,
        name = "Mr. Chilly",
        source = "Promotion: Wow/Battle.net Account Merger",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [193] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 31575,
        description = "You wouldn't want to meet this rat in a dark alley. Or anywhere else, for that matter.",
        familyType = 2,
        name = "Giant Sewer Rat",
        source = "Profession: Fishing|nZone: Dalaran",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [194] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 190,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 521,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S",
            "H/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 32589,
        description = "Unlike most of Geen the gorloc's 'mysterious eggs,' this one actually contained a living thing.",
        familyType = 5,
        name = "Tickbird Hatchling",
        source = "Drop: Mysterious Egg",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [195] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 190,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 521,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "P/S",
            "H/S",
            "S/B"
        },
        baseStats =         {
            health = 7.5,
            power = 7.5,
            speed = 9
        },
        canBattle = true,
        creatureId = 32590,
        description = "The rare albino tickbird is revered amongst the Oracles. It is seen as a sign of heavy rainstorms, good grub harvests, and hibernating wolvar.",
        familyType = 5,
        name = "White Tickbird Hatchling",
        source = "Drop: Mysterious Egg",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [196] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 110,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 503,
                    level = 2
                },
                [2] =                 {
                    id = 611,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 612,
                    level = 4
                },
                [2] =                 {
                    id = 347,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 32592,
        description = "These voracious whelps grow at an incredible rate and can devour nearly twice their weight in raw meat per day.",
        familyType = 3,
        name = "Proto-Drake Whelp",
        source = "Drop: Mysterious Egg",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [197] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 32591,
        description = "The cobras of Azeroth are renowned for their fast-acting venom and swift strikes.",
        familyType = 1,
        name = "Cobra Hatchling",
        source = "Drop: Mysterious Egg",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [198] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 528,
                    level = 2
                },
                [2] =                 {
                    id = 575,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 413,
                    level = 4
                },
                [2] =                 {
                    id = 529,
                    level = 20
                }            }
        },
        availableBreeds = {"S/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 32595,
        description = "Notable for its wide eyes and sassy slide.",
        familyType = 0,
        name = "Pengu",
        source = "Vendor: Sairuk|nZone: Dragonblight|nFaction: The Kalu'ak - Exalted|nCost: 12|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t|n|nVendor: Tanaika|nZone: Howling Fjord|nFaction: The Kalu'ak - Exalted|nCost: 12|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [199] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 114,
                    level = 1
                },
                [2] =                 {
                    id = 421,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 323,
                    level = 2
                },
                [2] =                 {
                    id = 589,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 299,
                    level = 4
                },
                [2] =                 {
                    id = 476,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 32643,
        description = "To prevent apprentices from secretly using the familiar to complete their chores, the archmagi placed the ritual required to summon the creature across the pages of several spellbooks hidden throughout Dalaran.",
        familyType = 4,
        name = "Kirin Tor Familiar",
        source = "Achievement: Higher Learning|nCategory: General",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [200] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 8,
            power = 7,
            speed = 9
        },
        canBattle = true,
        creatureId = 32791,
        description = "Spring rabbits symbolize fertility, and they love to demonstrate why.",
        familyType = 2,
        name = "Spring Rabbit",
        source = "World Event: Noblegarden|nVendor: Noblegarden Merchant|nCost: 100|TINTERFACE\\\\ICONS\\\\Achievement_Noblegarden_Chocolate_Egg:0|t",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [201] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 524,
                    level = 2
                },
                [2] =                 {
                    id = 579,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 580,
                    level = 4
                },
                [2] =                 {
                    id = 581,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 32818,
        description = "He's humble, clairvoyant, and delicious with cranberry sauce.",
        familyType = 5,
        name = "Plump Turkey",
        source = "World Event: Pilgrim's Bounty",
        sourceTypeEnum = 6,
        tradeable = false,
        unique = true
    },
    [202] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 347,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 348,
                    level = 2
                },
                [2] =                 {
                    id = 247,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 345,
                    level = 4
                },
                [2] =                 {
                    id = 206,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 32841,
        description = "This rare bear is bred for its small size and perpetually youthful appearance.",
        familyType = 1,
        name = "Baby Blizzard Bear",
        source = "Achievement: WoW's 4th Anniversary|nCategory: Feats of Strength",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [203] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 493,
                    level = 1
                },
                [2] =                 {
                    id = 163,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 254,
                    level = 2
                },
                [2] =                 {
                    id = 574,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 539,
                    level = 4
                },
                [2] =                 {
                    id = 376,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 8,
            power = 7,
            speed = 9
        },
        canBattle = true,
        creatureId = 32939,
        description = "She likes the company of friends. Seventy-five of them, to be precise.",
        familyType = 2,
        name = "Little Fawn",
        source = "Achievement: Lil' Game Hunter|nCategory: Pet Battles",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [204] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 962,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 318,
                    level = 2
                },
                [2] =                 {
                    id = 630,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 268,
                    level = 4
                },
                [2] =                 {
                    id = 400,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 33188,
        description = "It always wakes up dancing. What a happy little tree!",
        familyType = 4,
        name = "Teldrassil Sproutling",
        source = "Vendor: Rook Hawkfist|nZone: Icecrown|nCost: 40|TINTERFACE\\\\ICONS\\\\Ability_Paladin_ArtofWar.blp:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [205] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 347,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 247,
                    level = 2
                },
                [2] =                 {
                    id = 348,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 345,
                    level = 4
                },
                [2] =                 {
                    id = 124,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 33194,
        description = "The bears of Dun Morogh are prized for their hardiness, loyalty, and combat prowess. Their time among the dwarves does little to curb their ferocity.",
        familyType = 1,
        name = "Dun Morogh Cub",
        source = "Vendor: Derrick Brindlebeard|nZone: Icecrown|nCost: 40|TINTERFACE\\\\ICONS\\\\Ability_Paladin_ArtofWar.blp:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [206] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 383,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 521,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 186,
                    level = 4
                },
                [2] =                 {
                    id = 517,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "S/B"
        },
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 33197,
        description = "Can sense an opponent's heartbeat through echolocation.",
        familyType = 5,
        name = "Tirisfal Batling",
        source = "Vendor: Eliza Killian|nZone: Icecrown|nCost: 40|TINTERFACE\\\\ICONS\\\\Ability_Paladin_ArtofWar.blp:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [207] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 356,
                    level = 1
                },
                [2] =                 {
                    id = 355,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 359,
                    level = 4
                },
                [2] =                 {
                    id = 124,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 33198,
        description = "The volatile Durotar scorpion is a fierce desert predator. It's known for only occasionally stinging its owner.",
        familyType = 1,
        name = "Durotar Scorpion",
        source = "Vendor: Freka Bloodaxe|nZone: Icecrown|nCost: 40|TINTERFACE\\\\ICONS\\\\Ability_Paladin_ArtofWar.blp:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [209] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 493,
                    level = 1
                },
                [2] =                 {
                    id = 541,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 253,
                    level = 2
                },
                [2] =                 {
                    id = 497,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 539,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 33200,
        description = "Unlike the polymorphed variety, trueborn sheep can be quite scary.",
        familyType = 2,
        name = "Elwynn Lamb",
        source = "Vendor: Corporal Arthur Flew|nZone: Icecrown|nCost: 40|TINTERFACE\\\\ICONS\\\\Ability_Paladin_ArtofWar.blp:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [210] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 112,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 310,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 377,
                    level = 4
                },
                [2] =                 {
                    id = 568,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 33219,
        description = "A tallstrider's speed on open ground is unrivaled, so predators rely on stealth and pack tactics when hunting them.",
        familyType = 2,
        name = "Mulgore Hatchling",
        source = "Vendor: Doru Thunderhorn|nZone: Icecrown|nCost: 40|TINTERFACE\\\\ICONS\\\\Ability_Paladin_ArtofWar.blp:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [211] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 356,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 511,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 310,
                    level = 4
                },
                [2] =                 {
                    id = 513,
                    level = 20
                }            }
        },
        availableBreeds = {"H/H"},
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 33226,
        description = "The strand crawler has adapted to the northern cold by hibernating under the island beaches.",
        familyType = 0,
        name = "Strand Crawler",
        source = "Profession: Fishing|nZone: Northrend, Stormwind, Orgrimmar",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [212] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 394,
                    level = 1
                },
                [2] =                 {
                    id = 398,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 396,
                    level = 2
                },
                [2] =                 {
                    id = 303,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 402,
                    level = 4
                },
                [2] =                 {
                    id = 400,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 33205,
        description = "The long-term effects of the contamination caused by the Exodar are still under observation.",
        familyType = 4,
        name = "Ammen Vale Lashling",
        source = "Vendor: Irisee|nZone: Icecrown|nCost: 40|TINTERFACE\\\\ICONS\\\\Ability_Paladin_ArtofWar.blp:0|t |n",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [213] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 452,
                    level = 1
                },
                [2] =                 {
                    id = 455,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 453,
                    level = 2
                },
                [2] =                 {
                    id = 457,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 456,
                    level = 4
                },
                [2] =                 {
                    id = 459,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 33227,
        description = "Created by a blood elf apprentice, this broom would be extremely useful if anyone could figure out how to make it stop.",
        familyType = 7,
        name = "Enchanted Broom",
        source = "Vendor: Trellis Morningsun|nZone: Icecrown|nCost: 40|TINTERFACE\\\\ICONS\\\\Ability_Paladin_ArtofWar.blp:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [214] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 111,
                    level = 1
                }            }
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = false,
        creatureId = 33238,
        description = "Many of Stormwind's youth joined the Argent Crusade as squires, hoping to one day serve the Holy Light in battle.",
        familyType = 6,
        name = "Argent Squire",
        source = "Quest: A Champion Rises|nZone: Icecrown",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [215] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 533,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 455,
                    level = 2
                },
                [2] =                 {
                    id = 389,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 459,
                    level = 4
                },
                [2] =                 {
                    id = 278,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 33274,
        description = "Used as a training mount for young gnomes, the Mechanopeep has none of the speed but all of the charm of its bigger brothers.",
        familyType = 8,
        name = "Mechanopeep",
        source = "Vendor: Rillie Spindlenut|nZone: Icecrown",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [216] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 111,
                    level = 1
                }            }
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = false,
        creatureId = 33239,
        description = "These young orcs strive to embody the Argent Crusade's virtues: valor, strength, and integrity.",
        familyType = 6,
        name = "Argent Gruntling",
        source = "Quest: A Champion Rises|nZone: Icecrown",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [217] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 111,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 760,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 761,
                    level = 4
                },
                [2] =                 {
                    id = 762,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 33578,
        description = "Murkimus is the most fearsome of all murloc arena warriors. And for a time, the only one.",
        familyType = 6,
        name = "Murkimus the Gladiator",
        source = "Promotion: Arena Tournament",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [218] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 210,
                    level = 1
                },
                [2] =                 {
                    id = 501,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 178,
                    level = 2
                },
                [2] =                 {
                    id = 592,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 763,
                    level = 4
                },
                [2] =                 {
                    id = 476,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 33810,
        description = "This is actually three pets in one. You won't know what you'll get until you summon it!",
        familyType = 9,
        name = "Sen'jin Fetish",
        source = "Vendor: Samamba|nZone: Icecrown|nCost: 40|TINTERFACE\\\\ICONS\\\\Ability_Paladin_ArtofWar.blp:0|t|n",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [220] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 962,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 318,
                    level = 2
                },
                [2] =                 {
                    id = 630,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 268,
                    level = 4
                },
                [2] =                 {
                    id = 400,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 34278,
        description = "A solemn reminder of what was lost when the Worldbreaker changed the face of Azeroth.",
        familyType = 4,
        name = "Withers",
        source = "Quest: Remembrance of Auberdine|nZone: Darkshore",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [224] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 34364,
        description = "Many have mocked this cat before battle. Their last words are usually, 'Here, kitty, kitty.'",
        familyType = 1,
        name = "Calico Cat",
        source = "Vendor: Breanni|nZone: Crystalsong Forest|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [225] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 111,
                    level = 1
                },
                [2] =                 {
                    id = 118,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 631,
                    level = 2
                },
                [2] =                 {
                    id = 667,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 669,
                    level = 4
                },
                [2] =                 {
                    id = 668,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 33530,
        description = "The bouncy gurloc is a distant cousin of the murloc.",
        familyType = 6,
        name = "Curious Oracle Hatchling",
        source = "World Event: Children's Week",
        sourceTypeEnum = 6,
        tradeable = false,
        unique = false
    },
    [226] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 111,
                    level = 1
                },
                [2] =                 {
                    id = 110,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 670,
                    level = 2
                },
                [2] =                 {
                    id = 740,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 741,
                    level = 4
                },
                [2] =                 {
                    id = 345,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 33529,
        description = "Despite their smaller stature, the wolvar are some of the most aggressive creatures in Northrend. This often makes their curious nature intimidating.",
        familyType = 6,
        name = "Curious Wolvar Pup",
        source = "World Event: Children's Week",
        sourceTypeEnum = 6,
        tradeable = false,
        unique = false
    },
    [227] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 777,
                    level = 1
                },
                [2] =                 {
                    id = 455,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 640,
                    level = 2
                },
                [2] =                 {
                    id = 634,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 392,
                    level = 4
                },
                [2] =                 {
                    id = 293,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 34587,
        description = "A fighting robot fueled by delicious red or blue electrolytes.",
        familyType = 8,
        name = "Warbot",
        source = "Promotion: Mountain Dew Promotion",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [229] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 484,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 486,
                    level = 2
                },
                [2] =                 {
                    id = 488,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 489,
                    level = 4
                },
                [2] =                 {
                    id = 490,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 34724,
        description = "This extremely rare species of mana wyrm is prized for its unique coloration and even temperament.",
        familyType = 7,
        name = "Shimmering Wyrmling",
        source = "Vendor: Hiren Loresong|nZone: Icecrown|nFaction: The Silver Covenant - Exalted|nCost: 40|TINTERFACE\\\\ICONS\\\\Ability_Paladin_ArtofWar.blp:0|t|n",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [232] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 305,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 35396,
        description = "Rarely leaves nest until maturity. Enjoys conducting pranks on the nearby Razormaw nest.",
        familyType = 1,
        name = "Darting Hatchling",
        source = "Drop: Dart's Nest|nZone: Dustwallow Marsh",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [233] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 305,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 35395,
        description = "The demand for this purple-skinned breed has drastically reduced the raptor population near the Wailing Caverns.",
        familyType = 1,
        name = "Deviate Hatchling",
        source = "Drop: Deviate Guardian, Deviate Ravager|nZone: Wailing Caverns",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [234] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 305,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 35400,
        description = "This crafty raptor was born in the icy wastes of Northrend. Its harsh upbringing gives it strength when many others would perish.",
        familyType = 1,
        name = "Gundrak Hatchling",
        source = "Drop: Gundrak Raptor|nZone: Zul'Drak",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [235] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 305,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 35387,
        description = "This offspring of Takk the Leaper is incredibly agile and can maneuver through difficult environments with ease.",
        familyType = 1,
        name = "Leaping Hatchling",
        source = "Drop: Takk's Nest|nZone: The Barrens",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [236] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 305,
                    level = 20
                }            }
        },
        availableBreeds = {"H/H"},
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 35399,
        description = "This hatchling is coveted for its unique coloration. Despite Breanni's loving care, the raptor's feral nature cannot be restrained.",
        familyType = 1,
        name = "Obsidian Hatchling",
        source = "Vendor: Breanni|nZone: Crystalsong Forest|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [237] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 305,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 35397,
        description = "Larger than other raptor infants, these hatchlings grow into towering reptilian beasts capable of massive devastation.",
        familyType = 1,
        name = "Ravasaur Hatchling",
        source = "Drop: Ravasaur Matriarch's Nest|nZone: Un'goro Crater",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [238] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 305,
                    level = 20
                }            }
        },
        availableBreeds = {"S/B"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 35398,
        description = "Razormaw eggs are protected fiercely by their mothers. Their cuteness belies their inherited ferocity.",
        familyType = 1,
        name = "Razormaw Hatchling",
        source = "Drop: Razormaw Matriarch's Nest|nZone: Wetlands",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [239] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 305,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 35394,
        description = "Razzashi raptors are among the cleverest predators in the jungle, making them favored by the Gurubashi trolls.",
        familyType = 1,
        name = "Razzashi Hatchling",
        source = "Drop: World Drop|nZone: Northern Stranglethorn, The Cape of Stranglethorn",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [240] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 437,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 436,
                    level = 2
                },
                [2] =                 {
                    id = 347,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 621,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 35468,
        description = "The onyx panther is invisible at night, like a stalking shadow, and disappears with the dawn.",
        familyType = 7,
        name = "Onyx Panther",
        source = "Promotion: Korea World Event",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [243] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 168,
                    level = 2
                },
                [2] =                 {
                    id = 172,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 169,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 9,
            power = 9,
            speed = 6
        },
        canBattle = true,
        creatureId = 36607,
        description = "Spawn of Onyxia, this young dragon has decided that it doesn't want to follow in its grandfathers' cataclysmic footsteps.",
        familyType = 3,
        name = "Onyxian Whelpling",
        source = "Achievement: WoW's 5th Anniversary|nCategory: Feats of Strength",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [245] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 524,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 581,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 36908,
        description = "A gift from the Wildhammer dwarves to the heroes of the Alliance, these hatchlings are descendants of the same gryphons ridden by Falstad and his entourage into Grim Batol.",
        familyType = 5,
        name = "Gryphon Hatchling",
        source = "Pet Store",
        sourceTypeEnum = 9,
        tradeable = false,
        unique = true
    },
    [246] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 524,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 420,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 581,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 36909,
        description = "Thorg No-Legs never paid heed to the old orc saying, 'Don't pull a wyvern's tail.'",
        familyType = 1,
        name = "Wind Rider Cub",
        source = "Pet Store",
        sourceTypeEnum = 9,
        tradeable = false,
        unique = true
    },
    [249] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 210,
                    level = 1
                },
                [2] =                 {
                    id = 120,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 212,
                    level = 2
                },
                [2] =                 {
                    id = 214,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 414,
                    level = 4
                },
                [2] =                 {
                    id = 218,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 36979,
        description = "In life, Kel'Thuzad betrayed the Kirin Tor and created the Cult of the Damned. In death, he serves the Scourge as the Archlich Lord of Naxxramas.",
        familyType = 9,
        name = "Lil' K.T.",
        source = "Pet Store",
        sourceTypeEnum = 9,
        tradeable = false,
        unique = true
    },
    [250] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 576,
                    level = 2
                },
                [2] =                 {
                    id = 578,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 377,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 7.5,
            power = 9,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 37865,
        description = "Although small, pugs are very dangerous when provoked.",
        familyType = 2,
        name = "Perky Pug",
        source = "Achievement: Looking For Multitudes|nCategory: Dungeons & Raids",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [251] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 445,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 447,
                    level = 2
                },
                [2] =                 {
                    id = 448,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 450,
                    level = 4
                },
                [2] =                 {
                    id = 369,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 38374,
        description = "This, um, 'adorable' little guy likes to play with critters. Just don't let them get too close.",
        familyType = 7,
        name = "Toxic Wasteling",
        source = "World Event: Love is in the Air",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [253] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 413,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 414,
                    level = 2
                },
                [2] =                 {
                    id = 575,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 624,
                    level = 4
                },
                [2] =                 {
                    id = 120,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 40198,
        description = "While not nearly as destructive as its original master, the Ice Lord Ahune, the frostling has been known to lob chilly snowballs at unsuspecting adventurers.",
        familyType = 4,
        name = "Frigid Frostling",
        source = "World Event: Midsummer Fire Festival",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [254] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 777,
                    level = 1
                },
                [2] =                 {
                    id = 455,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 640,
                    level = 2
                },
                [2] =                 {
                    id = 634,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 636,
                    level = 4
                },
                [2] =                 {
                    id = 293,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 40295,
        description = "Jepetto's top-selling toy this season, the bot's new blue chassis has children across Azeroth scrambling for this feisty battle bot.",
        familyType = 8,
        name = "Blue Clockwork Rocket Bot",
        source = "Vendor: World Vendors|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [255] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 860,
                    level = 1
                },
                [2] =                 {
                    id = 347,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 611,
                    level = 2
                },
                [2] =                 {
                    id = 589,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 595,
                    level = 4
                },
                [2] =                 {
                    id = 258,
                    level = 20
                }            }
        },
        availableBreeds = {"H/H"},
        baseStats =         {
            health = 7.5,
            power = 9,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 40624,
        description = "Breanni in Dalaran, one of the world's foremost collectors of exotic pets, will only award the mystical Celestial Dragon to fellow collectors whose obsession rivals her own.",
        familyType = 3,
        name = "Celestial Dragon",
        source = "Achievement: Littlest Pet Shop|nCategory: Pet Battles",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [256] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 116,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 278,
                    level = 2
                },
                [2] =                 {
                    id = 279,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 386,
                    level = 4
                },
                [2] =                 {
                    id = 387,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 9,
            speed = 7
        },
        canBattle = true,
        creatureId = 40703,
        description = "Modeled after the huge titan prototype in Ulduar, this volatile little construct plays hard with its toys.",
        familyType = 8,
        name = "Lil' XT",
        source = "Pet Store",
        sourceTypeEnum = 9,
        tradeable = false,
        unique = true
    },
    [259] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 521,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 42177,
        description = "Unlike its gold counterpart, the blue mini jouster takes a leisurely pace when jabbing its opponent's eyeballs.",
        familyType = 5,
        name = "Blue Mini Jouster",
        source = "Quest: Egg Wave|nZone: Mount Hyjal|n|n",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [260] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 521,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 42183,
        description = "This critter is infamous for its ability to unleash a fast and furious eyeball jabbing.",
        familyType = 5,
        name = "Gold Mini Jouster",
        source = "Quest: Egg Wave|nZone: Mount Hyjal|n|n",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [261] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 384,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 278,
                    level = 2
                },
                [2] =                 {
                    id = 208,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 754,
                    level = 4
                },
                [2] =                 {
                    id = 644,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 43800,
        description = "Goblin engineering at its finest. Blueprints based on the massive fel reaver in Hellfire Peninsula.",
        familyType = 8,
        name = "Personal World Destroyer",
        source = "Profession: Engineering",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [262] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 384,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 389,
                    level = 2
                },
                [2] =                 {
                    id = 392,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 390,
                    level = 4
                },
                [2] =                 {
                    id = 278,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 43916,
        description = "The gold standard for sturdy gnomish design, this mechanical critter is the perfect companion for the lonely engineer on the go.",
        familyType = 8,
        name = "De-Weaponized Mechanical Companion",
        source = "Profession: Engineering",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [264] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 210,
                    level = 1
                },
                [2] =                 {
                    id = 468,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 611,
                    level = 2
                },
                [2] =                 {
                    id = 780,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 218,
                    level = 4
                },
                [2] =                 {
                    id = 476,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 45128,
        description = "This appears to be nothing more than the paw of a small primate. A closer inspection shows that the hand has been dried by centuries of exposure to the sands of Uldum.",
        familyType = 9,
        name = "Crawling Claw",
        source = "Profession: Archaeology",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [265] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 801,
                    level = 1
                },
                [2] =                 {
                    id = 621,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 453,
                    level = 2
                },
                [2] =                 {
                    id = 814,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 628,
                    level = 4
                },
                [2] =                 {
                    id = 644,
                    level = 20
                }            }
        },
        availableBreeds = {"H/H"},
        baseStats =         {
            health = 9.5,
            power = 8,
            speed = 6.5
        },
        canBattle = true,
        creatureId = 45247,
        description = "An adventurous little elemental, Pebble escaped hungry gyreworms in the Crumbling Depths, braved the emptiness of the Twisting Nether, and ultimately found himself rescued from a mailbox.",
        familyType = 4,
        name = "Pebble",
        source = "Achievement: Rock Lover|nCategory: Quests",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [266] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 648,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 611,
                    level = 2
                },
                [2] =                 {
                    id = 214,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 650,
                    level = 4
                },
                [2] =                 {
                    id = 649,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 45340,
        description = "You stare at her, and she just stares right back. So clever; sometimes it seems as if she's figuring out how to open doors.",
        familyType = 9,
        name = "Fossilized Hatchling",
        source = "Profession: Archaeology",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [267] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 114,
                    level = 1
                },
                [2] =                 {
                    id = 113,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 460,
                    level = 2
                },
                [2] =                 {
                    id = 463,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 751,
                    level = 4
                },
                [2] =                 {
                    id = 461,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 46898,
        description = "Reduces the likelihood of being eaten by monsters when you enter pitch-black places.",
        familyType = 7,
        name = "Enchanted Lantern",
        source = "Profession: Enchanting (525)|nFormula: Enchanted Lantern",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [268] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 393,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 256,
                    level = 2
                },
                [2] =                 {
                    id = 809,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 606,
                    level = 4
                },
                [2] =                 {
                    id = 607,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8.5,
            power = 9,
            speed = 6.5
        },
        canBattle = true,
        creatureId = 46896,
        description = "Nations tremble under his shadow - the Destroyer, the one-time Aspect of Earth, and the monster responsible for breaking Azeroth asunder.  Now in a convenient travel-size!",
        familyType = 3,
        name = "Lil' Deathwing",
        source = "Promotion: Cataclysm Collector's Edition",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [270] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 482,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 792,
                    level = 2
                },
                [2] =                 {
                    id = 178,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 179,
                    level = 4
                },
                [2] =                 {
                    id = 794,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 47944,
        description = "Fire hatchlings are born from the ashes of a phoenix. Dark hatchlings emerge from their shadows.",
        familyType = 4,
        name = "Dark Phoenix Hatchling",
        source = "Vendor: Guild Vendor|nZone: Stormwind, Orgrimmar|nCost: 300|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t|n",
        sourceTypeEnum = 2,
        tradeable = false,
        unique = true
    },
    [271] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 190,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 521,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 48107,
        description = "This bird is a salty veteran of the endless naval battles surrounding Tol Barad--a veteran whose grown plump from picking through the leftovers, that is.",
        familyType = 5,
        name = "Rustberg Gull",
        source = "Vendor: Quartermaster Brazie|nZone: Tol Barad Peninsula|nFaction: Baradin's Wardens - Honored|nCost: 50|TINTERFACE\\\\ICONS\\\\Achievement_Zone_TolBarad.blp:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [272] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 310,
                    level = 2
                },
                [2] =                 {
                    id = 347,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 117,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 9,
            power = 7.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 48242,
        description = "Rolls into a protective ball when it feels threatened. Or when its mother calls.",
        familyType = 2,
        name = "Armadillo Pup",
        source = "Vendor: Guild Vendor|nZone: Stormwind, Orgrimmar|nCost: 300|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t|n",
        sourceTypeEnum = 2,
        tradeable = false,
        unique = true
    },
    [277] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 384,
                    level = 1
                },
                [2] =                 {
                    id = 712,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 278,
                    level = 2
                },
                [2] =                 {
                    id = 713,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 710,
                    level = 4
                },
                [2] =                 {
                    id = 293,
                    level = 20
                }            }
        },
        availableBreeds = {"S/B"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 48609,
        description = "Thought to be an original construct of the titans, the clockwork gnome has some gears smaller than the eye can see.",
        familyType = 8,
        name = "Clockwork Gnome",
        source = "Profession: Archaeology",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [278] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 362,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 366,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 48641,
        description = "The fighting in Tol Barad has made it difficult to find these kits, and numerous would-be owners have decimated the fox population there as a result.",
        familyType = 1,
        name = "Fox Kit",
        source = "Drop: Baradin Fox|nZone: Tol Barad Peninsula",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [279] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 383,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 380,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 621,
                    level = 4
                },
                [2] =                 {
                    id = 436,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 48982,
        description = "The elemental shale spider is no true arachnid, but it has durability and ferocity that make it feared even in Deepholm.",
        familyType = 4,
        name = "Tiny Shale Spider",
        source = "Drop: Jadefang|nZone: Deepholm",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [280] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 111,
                    level = 1
                }            }
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = false,
        creatureId = 49586,
        description = "Guild pages must be fearless since they are called upon to announce their guild's victories over the Horde in battle.",
        familyType = 6,
        name = "Guild Page",
        source = "Vendor: Guild Vendor|nZone: Stormwind, Orgrimmar|nCost: 300|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t|nCooldown: 8 hrs",
        sourceTypeEnum = 2,
        tradeable = false,
        unique = false
    },
    [281] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 111,
                    level = 1
                }            }
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = false,
        creatureId = 49588,
        description = "When a guild earns enough glory by defeating Alliance champions, some orcs will come to share the glory by serving the guild.",
        familyType = 6,
        name = "Guild Page",
        source = "Vendor: Guild Vendor|nZone: Stormwind, Orgrimmar|nCost: 300|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t|nCooldown: 8 hrs",
        sourceTypeEnum = 2,
        tradeable = false,
        unique = false
    },
    [282] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 111,
                    level = 1
                }            }
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = false,
        creatureId = 49587,
        description = "When guilds have accumulated enough wealth, brave soldiers are often called to bear their standards.",
        familyType = 6,
        name = "Guild Herald",
        source = "Vendor: Guild Vendor|nZone: Stormwind, Orgrimmar|nCost: 500|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t|nCooldown: 4 hrs",
        sourceTypeEnum = 2,
        tradeable = false,
        unique = false
    },
    [283] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 111,
                    level = 1
                }            }
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = false,
        creatureId = 49590,
        description = "Wealthy guilds draw the attention of soldiers willing to carry their standards into battle.",
        familyType = 6,
        name = "Guild Herald",
        source = "Vendor: Guild Vendor|nZone: Stormwind, Orgrimmar|nCost: 500|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t|nCooldown: 4 hrs",
        sourceTypeEnum = 2,
        tradeable = false,
        unique = false
    },
    [286] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 367,
                    level = 1
                },
                [2] =                 {
                    id = 160,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 369,
                    level = 2
                },
                [2] =                 {
                    id = 371,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 159,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 9,
            power = 8,
            speed = 7
        },
        canBattle = true,
        creatureId = 50586,
        description = "The grubs of the Plaguelands are a side effect of necromantic corruption and the massive number of corpses there. Mr. Grubbs is from a particularly acrobatic breed.",
        familyType = 1,
        name = "Mr. Grubbs",
        source = "World Drop: Eastern Plaguelands (requires Fiona's Lucky Charm)",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [287] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 178,
                    level = 2
                },
                [2] =                 {
                    id = 155,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 162,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 51632,
        description = "After swarming around open lava pits during the day, these strange insects emit a fiery glow at night.",
        familyType = 5,
        name = "Tiny Flamefly",
        source = "Quest: SEVEN! YUP!, Not Fireflies, Flameflies|nZone: Burning Steppes|n",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [289] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 445,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 369,
                    level = 2
                },
                [2] =                 {
                    id = 310,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 564,
                    level = 4
                },
                [2] =                 {
                    id = 376,
                    level = 20
                }            }
        },
        availableBreeds = {"H/H"},
        baseStats =         {
            health = 9.5,
            power = 8.5,
            speed = 6
        },
        canBattle = true,
        creatureId = 51635,
        description = "You'll find him in his shell, exactly where a snail has to be!",
        familyType = 2,
        name = "Scooter the Snail",
        source = "World Event: Children's Week",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [291] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 394,
                    level = 1
                },
                [2] =                 {
                    id = 753,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 268,
                    level = 2
                },
                [2] =                 {
                    id = 298,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 405,
                    level = 4
                },
                [2] =                 {
                    id = 404,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 9,
            power = 7.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 51090,
        description = "This sweet flower will brighten your day with its warm smile and cheerful song! Also strong against undead.",
        familyType = 4,
        name = "Singing Sunflower",
        source = "Quest: Lawn of the Dead|nZone: Hillsbrad Foothills|n",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [292] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 114,
                    level = 1
                },
                [2] =                 {
                    id = 421,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 763,
                    level = 2
                },
                [2] =                 {
                    id = 323,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 751,
                    level = 4
                },
                [2] =                 {
                    id = 273,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 50545,
        description = "Higitus figi- hockity pocki- abracadab- prestidig--oh, pinfeathers!",
        familyType = 7,
        name = "Magic Lamp",
        source = "Profession: Enchanting",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [293] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 484,
                    level = 1
                },
                [2] =                 {
                    id = 617,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 263,
                    level = 2
                },
                [2] =                 {
                    id = 488,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 621,
                    level = 4
                },
                [2] =                 {
                    id = 606,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 50722,
        description = "Often confused by miners as a rare gem, the geode initially makes its presence known by emitting melodic reverberations.",
        familyType = 4,
        name = "Elementium Geode",
        source = "Drop: Elementium Vein, Rich Elementium Vein|nZone: Deepholm, Twilight Highlands, Uldum",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [301] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {"S/B"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 52226,
        description = "It looked up at you with those huge black eyes and seemed to ask, 'Are you my mommy?'",
        familyType = 1,
        name = "Panther Cub",
        source = "Quest: Some Good Will Come|nZone: Northern Stranglethorn|n|n",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [306] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {"S/B"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 52831,
        description = "Winterspring cubs are happiest when frolicking in freshly fallen snow.",
        familyType = 1,
        name = "Winterspring Cub",
        source = "Vendor: Michelle De Rum|nZone: Winterspring|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [307] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 305,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 52894,
        description = "Born in the jungles of Stranglethorn, unlucky raptor hatchlings are often captured by the Gurubashi and taken to the troll city of Zul'Gurub.",
        familyType = 1,
        name = "Lashtail Hatchling",
        source = "Quest: An Old Friend|nZone: Zul'gurub",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [308] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 482,
                    level = 1
                },
                [2] =                 {
                    id = 297,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 593,
                    level = 2
                },
                [2] =                 {
                    id = 323,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 473,
                    level = 4
                },
                [2] =                 {
                    id = 513,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 53048,
        description = "Wild marsh walkers are dangerously aggressive, but they're loyal and affectionate if you manage to tame them.",
        familyType = 7,
        name = "Legs",
        source = "World Event: Children's Week",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [309] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 515,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 611,
                    level = 2
                },
                [2] =                 {
                    id = 519,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 568,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 6.5,
            power = 9,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 53225,
        description = "Pterrordax eggs are incubated underneath the fossils of their forebears, allowing the hatchlings to absorb their ancestors' ferocity and intelligence.",
        familyType = 5,
        name = "Pterrordax Hatchling",
        source = "Profession: Archaeology",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [310] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 210,
                    level = 1
                },
                [2] =                 {
                    id = 501,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 178,
                    level = 2
                },
                [2] =                 {
                    id = 592,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 763,
                    level = 4
                },
                [2] =                 {
                    id = 476,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 53232,
        description = "Voodoo figurines were often empowered by flasks of mojo, troll sweat, and the flesh of tribal enemies.",
        familyType = 9,
        name = "Voodoo Figurine",
        source = "Profession: Archaeology",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [317] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 347,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 247,
                    level = 2
                },
                [2] =                 {
                    id = 348,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 345,
                    level = 4
                },
                [2] =                 {
                    id = 124,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 53658,
        description = "The cubs of Hyjal suffered much during the Cataclysm. On the bright side, the devastation also led to their newfound love of heights and daredevil stunts.",
        familyType = 1,
        name = "Hyjal Bear Cub",
        source = "Vendor: Varlan Highbough|nZone: Molten Front|nCost: 1500|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [318] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 394,
                    level = 1
                },
                [2] =                 {
                    id = 398,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 396,
                    level = 2
                },
                [2] =                 {
                    id = 303,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 402,
                    level = 4
                },
                [2] =                 {
                    id = 400,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 53661,
        description = "Native to the ashen soils of the Firelands, the lasher was transplanted to Azeroth with the help of the Guardians of Hyjal.",
        familyType = 4,
        name = "Crimson Lasher",
        source = "Vendor: Ayla Shadowstorm|nZone: Molten Front|nCost: 1500|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [319] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 437,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 436,
                    level = 2
                },
                [2] =                 {
                    id = 256,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 6.5,
            power = 9,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 53884,
        description = "Ride with the moon (and this furry, whiskered witch) in the dead of night!",
        familyType = 1,
        name = "Feline Familiar",
        source = "World Event: Hallow's End|nVendor: Chub|nZone: Tirisfal Glades|nCost: 150|TINTERFACE\\\\ICONS\\\\achievement_halloween_candy_01:0|t|n|nVendor: Dorothy|nZone: Stormwind City|nCost: 150|TINTERFACE\\\\ICONS\\\\achievement_halloween_candy_01:0|t",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [320] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 421,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 593,
                    level = 2
                },
                [2] =                 {
                    id = 592,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 589,
                    level = 4
                },
                [2] =                 {
                    id = 299,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 54027,
        description = "A legendary member of the blue dragonflight.",
        familyType = 3,
        name = "Lil' Tarecgosa",
        source = "Vendor: Guild Vendor|nZone: Stormwind, Orgrimmar|nCost: 1500|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t|n",
        sourceTypeEnum = 2,
        tradeable = false,
        unique = true
    },
    [321] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 655,
                    level = 1
                },
                [2] =                 {
                    id = 468,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 780,
                    level = 2
                },
                [2] =                 {
                    id = 218,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 649,
                    level = 20
                }            }
        },
        availableBreeds = {"H/H"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 54128,
        description = "Previous owners of the crate have reported the disappearance of other pets from their collection.",
        familyType = 9,
        name = "Creepy Crate",
        source = "World Event: Hallow's End",
        sourceTypeEnum = 6,
        tradeable = false,
        unique = false
    },
    [323] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 411,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 165,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 167,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 54227,
        description = "Most squirrels hoard acorns for sustenance. Nuts, on the other hand, hoards acorns to stock its supply of ammunition.",
        familyType = 2,
        name = "Nuts",
        source = "Achievement: Petting Zoo|nCategory: Pet Battles",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [325] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 184,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 784,
                    level = 2
                },
                [2] =                 {
                    id = 190,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 517,
                    level = 4
                },
                [2] =                 {
                    id = 518,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 7.5,
            power = 9,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 54374,
        description = "One of the rarest creatures, this kaliri is set apart from others by its brilliant plumage and the lengths hunters will go to capture them.",
        familyType = 5,
        name = "Brilliant Kaliri",
        source = "Achievement: Menagerie|nCategory: Pet Battles",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [330] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 349,
                    level = 1
                },
                [2] =                 {
                    id = 492,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 347,
                    level = 2
                },
                [2] =                 {
                    id = 350,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 352,
                    level = 4
                },
                [2] =                 {
                    id = 354,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 54491,
        description = "The monkeys of Azeroth are infamous tricksters, and these beloved companions of the Darkmoon Faire have taken that innate cunning to a whole new level.",
        familyType = 1,
        name = "Darkmoon Monkey",
        source = "Vendor: Lhara|nZone: Darkmoon Island|nCost: 90|TINTERFACE\\\\ICONS\\\\inv_misc_ticket_darkmoon_01:0|t |n",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [331] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                }            }
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = false,
        creatureId = 54539,
        description = "Created to entertain children at the Darkmoon Faire, these magical balloons never lose their floatiness.",
        familyType = 5,
        name = "Alliance Balloon",
        source = "Quest: Blown Away|nZone: Stormwind",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [332] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                }            }
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = false,
        creatureId = 54541,
        description = "A magical wonder, these balloons will never deflate and are traditionally created in batches of ninety-nine.",
        familyType = 5,
        name = "Horde Balloon",
        source = "Quest: Blown Away|nZone: Orgrimmar|n",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [335] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 249,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 310,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 376,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 9,
            power = 7.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 54487,
        description = "This shelled reptile bravely protects the home on its back with an unwaveringly happy disposition.",
        familyType = 0,
        name = "Darkmoon Turtle",
        source = "Vendor: Lhara|nZone: Darkmoon Island|nCost: 90|TINTERFACE\\\\ICONS\\\\inv_misc_ticket_darkmoon_01:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [336] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                }            }
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = false,
        creatureId = 55187,
        description = "It just floats along...",
        familyType = 5,
        name = "Darkmoon Balloon",
        source = "Vendor: Lhara|nZone: Darkmoon Island|nCost: 90|TINTERFACE\\\\ICONS\\\\inv_misc_ticket_darkmoon_01:0|t |n",
        sourceTypeEnum = 2,
        tradeable = false,
        unique = false
    },
    [337] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 801,
                    level = 1
                },
                [2] =                 {
                    id = 621,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 453,
                    level = 2
                },
                [2] =                 {
                    id = 814,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 628,
                    level = 4
                },
                [2] =                 {
                    id = 644,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 55215,
        description = "A stowaway from Greatfather Winter's workshop, this tiny elemental found himself trapped in a present that was stolen by the Abominable Greench.",
        familyType = 4,
        name = "Lumpy",
        source = "World Event: Feast of Winter Veil",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [338] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 777,
                    level = 1
                },
                [2] =                 {
                    id = 778,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 646,
                    level = 2
                },
                [2] =                 {
                    id = 634,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 301,
                    level = 4
                },
                [2] =                 {
                    id = 209,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 55356,
        description = "A favorite of children across Azeroth, this tough little toy can withstand even the most aggressive imagination.",
        familyType = 8,
        name = "Darkmoon Tonk",
        source = "Vendor: Lhara|nZone: Darkmoon Island|nCost: 90|TINTERFACE\\\\ICONS\\\\inv_misc_ticket_darkmoon_01:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [339] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 777,
                    level = 1
                },
                [2] =                 {
                    id = 515,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 647,
                    level = 2
                },
                [2] =                 {
                    id = 282,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 779,
                    level = 4
                },
                [2] =                 {
                    id = 334,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 55367,
        description = "Lacking the mines and rockets of its predecessor, this kid-friendly faire prize is a new favorite among Azeroth's children.",
        familyType = 8,
        name = "Darkmoon Zeppelin",
        source = "Vendor: Lhara|nZone: Darkmoon Island|nCost: 90|TINTERFACE\\\\ICONS\\\\inv_misc_ticket_darkmoon_01:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [340] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 419,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 509,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 513,
                    level = 4
                },
                [2] =                 {
                    id = 297,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 55386,
        description = "Despite its diminutive size, it is impossible to miss a sea pony cutting through the water.",
        familyType = 0,
        name = "Sea Pony",
        source = "Profession: Fishing|nZone: Darkmoon Island",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [341] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 114,
                    level = 1
                },
                [2] =                 {
                    id = 113,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 460,
                    level = 2
                },
                [2] =                 {
                    id = 463,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 751,
                    level = 4
                },
                [2] =                 {
                    id = 461,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 55571,
        description = "These magical lanterns are acquired at the Lunar Festival, which celebrates the defeat of the Burning Legion by the free races of Azeroth.",
        familyType = 7,
        name = "Lunar Lantern",
        source = "World Event: Lunar Festival|nVendor: Valadar Starsong|nZone: Moonglade|nCost: 50|TINTERFACE\\\\ICONS\\\\INV_Misc_ElvenCoins:0|t",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [342] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 114,
                    level = 1
                },
                [2] =                 {
                    id = 113,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 460,
                    level = 2
                },
                [2] =                 {
                    id = 463,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 751,
                    level = 4
                },
                [2] =                 {
                    id = 461,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 55574,
        description = "The light from each lantern honors the soul of an ancestor spirit. During the Lunar Festival, these ghostly elders pass along their wisdom to the current generation.",
        familyType = 7,
        name = "Festival Lantern",
        source = "World Event: Lunar Festival|nVendor: Valadar Starsong|nZone: Moonglade|nCost: 50|TINTERFACE\\\\ICONS\\\\INV_Misc_ElvenCoins:0|t",
        sourceTypeEnum = 6,
        tradeable = true,
        unique = false
    },
    [343] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 56031,
        description = "This snuggly kitten loves to frolic, but sometimes it seems to be chasing things that aren't really there.",
        familyType = 1,
        name = "Darkmoon Cub",
        source = "Vendor: Lhara|nZone: Darkmoon Island|nCost: 90|TINTERFACE\\\\ICONS\\\\inv_misc_ticket_darkmoon_01:0|t |n",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [374] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 493,
                    level = 1
                },
                [2] =                 {
                    id = 541,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 253,
                    level = 2
                },
                [2] =                 {
                    id = 497,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 539,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/P",
            "P/S",
            "H/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 60649,
        description = "Offspring of the black sheep, the black lamb is only found in the forests of Elwynn.",
        familyType = 2,
        name = "Black Lamb",
        source = "Pet Battle: Elwynn Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [378] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7,
            speed = 9
        },
        canBattle = true,
        creatureId = 61080,
        description = "When you have two rabbits, you'll often soon have three.",
        familyType = 2,
        name = "Rabbit",
        source = "Pet Battle: Azshara, Blade's Edge Mountains, Crystalsong Forest, Darkshore, Dun Morogh, Duskwood, Elwynn Forest, Eversong Woods, Feralas, Hillsbrad Foothills, Howling Fjord, Moonglade, Mount Hyjal, Mulgore, Nagrand, Redridge Mountains, Silvermoon City, Silverpine Forest, Stonetalon Mountains, Stormwind City, Tirisfal Glades, Western Plaguelands, Westfall, Wetlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [379] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 411,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 165,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 167,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61081,
        description = "Most people do not know the difference between a squirrel and a chipmunk. Most don't care.",
        familyType = 2,
        name = "Squirrel",
        source = "Pet Battle: Ammen Vale, Ashenvale, Azshara, Blade's Edge Mountains, Crystalsong Forest, Darkshore, Duskwood, Dustwallow Marsh, Elwynn Forest, Feralas, Hillsbrad Foothills, Howling Fjord, Loch Modan, Moonglade, Mount Hyjal, Nagrand, Sholazar Basin, Silverpine Forest, Stormwind City, Terokkar Forest, Tol Barad Peninsula, Western Plaguelands, Westfall, Wetlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [380] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 424,
                    level = 1
                },
                [2] =                 {
                    id = 412,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 411,
                    level = 4
                },
                [2] =                 {
                    id = 541,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62992,
        description = "It's hard to know what's more dangerous: the teeth or the tail.",
        familyType = 1,
        name = "Bucktooth Flapper",
        source = "Pet Battle: The Jade Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [381] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 315,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 283,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61086,
        description = "Despite the name you should absolutely never, ever pet it.",
        familyType = 2,
        name = "Porcupette",
        source = "Drop: Sack of Pet Supplies|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [382] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 283,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 152,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61087,
        description = "Aptly named 'ring bandits' by the pandaren, raccoons have dexterous paws and insatiable appetites for shiny objects, especially jewelry.",
        familyType = 2,
        name = "Raccoon Kit",
        sourceTypeEnum = -1,
        tradeable = true,
        unique = false
    },
    [383] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 497,
                    level = 4
                },
                [2] =                 {
                    id = 297,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61088,
        description = "It seems like a trick to the eyes, but the eternal strider can walk across water, its small feet never breaking the surface.",
        familyType = 0,
        name = "Eternal Strider",
        source = "Pet Battle: Vale of Eternal Blossoms",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [384] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 412,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 509,
                    level = 4
                },
                [2] =                 {
                    id = 564,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61089,
        description = "The thick pelt of the otter makes it adaptable to any climate, but it particularly prefers frigid waters where abalone is plentiful.",
        familyType = 0,
        name = "Otter Pup",
        sourceTypeEnum = -1,
        tradeable = true,
        unique = false
    },
    [385] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61143,
        description = "It seems that mice are completely incapable of resisting cheese even in the face of imprisonment, injury, or death.",
        familyType = 2,
        name = "Mouse",
        source = "Pet Battle: Duskwood, Dustwallow Marsh, Grizzly Hills, Mulgore, Netherstorm, Westfall, Wetlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [386] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 367,
                    level = 1
                },
                [2] =                 {
                    id = 162,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 165,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 253,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61141,
        description = "Distinct from their tree dwelling cousins, these ground squirrels make their homes on the plains of Azeroth and beyond.",
        familyType = 2,
        name = "Prairie Dog",
        source = "Pet Battle: Arathi Highlands, Mulgore, Nagrand, Northern Barrens, Southern Barrens, Thunder Bluff, Westfall",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [387] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61142,
        description = "Due to recent accidents, the goblin cartels have prohibited anyone from bringing snakes on a zeppelin.",
        familyType = 1,
        name = "Snake",
        source = "Pet Battle: Dustwallow Marsh, Eversong Woods, Feralas, Ghostlands, Howling Fjord, Loch Modan, Nagrand, Northern Stranglethorn, Sholazar Basin, Silverpine Forest, Terokkar Forest, Westfall, Zangarmarsh, Zul'Drak",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [388] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 356,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 511,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 310,
                    level = 4
                },
                [2] =                 {
                    id = 513,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 61158,
        description = "These arthropods line many Azerothian shores and seek to fulfill their one true desire: to pinch.",
        familyType = 0,
        name = "Shore Crab",
        source = "Pet Battle: Azshara, Borean Tundra, Howling Fjord, Krasarang Wilds, Twilight Highlands, Westfall",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [389] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 384,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 389,
                    level = 2
                },
                [2] =                 {
                    id = 392,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 390,
                    level = 4
                },
                [2] =                 {
                    id = 278,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "S/S",
            "H/H",
            "H/P",
            "P/S",
            "H/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 61160,
        description = "The tiny harvester collects weeds and small grains that the larger reapers may have missed.",
        familyType = 8,
        name = "Tiny Harvester",
        source = "Pet Battle: Westfall",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [391] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 7,
            speed = 9
        },
        canBattle = true,
        creatureId = 61167,
        description = "Mountain cottontails can leap up a steep incline with speed you would not believe.",
        familyType = 2,
        name = "Mountain Cottontail",
        source = "Pet Battle: Redridge Mountains",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [392] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61168,
        description = "The rats in Redridge grow fat from feasting on the bounty of the village larders.",
        familyType = 2,
        name = "Redridge Rat",
        source = "Pet Battle: Redridge Mountains",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [393] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "H/H",
            "H/P",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61384,
        description = "They were here long before us and will be here long after we are gone.",
        familyType = 2,
        name = "Cockroach",
        source = "Pet Battle: Burning Steppes, Eastern Plaguelands, Icecrown, The Hinterlands, Twilight Highlands, Un'Goro Crater",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [394] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 493,
                    level = 1
                },
                [2] =                 {
                    id = 541,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 253,
                    level = 2
                },
                [2] =                 {
                    id = 497,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 539,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61170,
        description = "Little Bo Peep has lost her sheep, and doesn't know where to find them. Leave them alone, and they'll come OH MY GOD THEY'RE INSIDE THE HOUSE!",
        familyType = 2,
        name = "Sheep",
        source = "Pet Battle: Redridge Mountains",
        sourceTypeEnum = -1,
        tradeable = false,
        unique = false
    },
    [395] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 521,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 61171,
        description = "Always wear a helm in the Redridge Mountains. Buzzards view humanoid hair as excellent nesting material.",
        familyType = 5,
        name = "Fledgling Buzzard",
        source = "Pet Battle: Redridge Mountains",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [396] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 378,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 382,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 250,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/S",
            "S/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61253,
        description = "Native to Duskwood, these eight-legged critters are often used as ingredients in alchemy potions.",
        familyType = 1,
        name = "Dusk Spiderling",
        source = "Pet Battle: Duskwood",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [397] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 576,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 527,
                    level = 4
                },
                [2] =                 {
                    id = 539,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61255,
        description = "Skunks are known as solitary creatures for reasons which are hopefully obvious.",
        familyType = 2,
        name = "Skunk",
        source = "Pet Battle: Ammen Vale, Azshara, Bloodmyst Isle, Duskwood, Howling Fjord, Terokkar Forest|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [398] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61257,
        description = "While many people believe black cats to be bad luck, black rats are held in higher esteem.",
        familyType = 2,
        name = "Black Rat",
        source = "Pet Battle: Badlands, Duskwood, Dustwallow Marsh, Eastern Plaguelands, Thousand Needles, Twilight Highlands, Western Plaguelands, Wetlands|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [399] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61258,
        description = "Years ago, humans introduced these reptiles into Duskwood to cull the local rat population.",
        familyType = 1,
        name = "Rat Snake",
        source = "Pet Battle: Duskwood",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [400] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 378,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 382,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 250,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "H/S",
            "S/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61259,
        description = "Widow spiderlings have plenty of time to explore Duskwood once they take care of their pesky family commitments.",
        familyType = 1,
        name = "Widow Spiderling",
        source = "Pet Battle: Duskwood|nTime: Night",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [401] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 356,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 511,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 310,
                    level = 4
                },
                [2] =                 {
                    id = 513,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 61312,
        description = "The low tide reveals the colonies of strand crabs and the sound of their clicking dance as they feed upon small creatures hidden in the sand.",
        familyType = 0,
        name = "Strand Crab",
        source = "Pet Battle: Darkshore, Dragonblight, Northern Stranglethorn, Swamp of Sorrows, The Cape of Stranglethorn|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [402] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 61370,
        description = "Prefers to dwell in wet, muddy areas and feed on Sorrowmoss nectar.",
        familyType = 5,
        name = "Swamp Moth",
        source = "Pet Battle: Swamp of Sorrows",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [403] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 521,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61313,
        description = "Parrots can mimic speech, but have difficulty with meaningful conversation.",
        familyType = 5,
        name = "Parrot",
        source = "Pet Battle: Northern Stranglethorn, Swamp of Sorrows, The Cape of Stranglethorn, Un'Goro Crater",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [404] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61317,
        description = "Thought by many to be nothing more than the subject of children's nursery rhymes, the long-tailed mole is very much real.",
        familyType = 2,
        name = "Long-tailed Mole",
        source = "Pet Battle: Dun Morogh, Northern Stranglethorn, The Cape of Stranglethorn, Un'Goro Crater",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [405] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "H/P"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61318,
        description = "Stranglethorn's Gurubashi trolls often capture these powerful beasts to keep as pets... or to cook as meals.",
        familyType = 1,
        name = "Tree Python",
        source = "Pet Battle: Northern Stranglethorn, The Cape of Stranglethorn, Un'Goro Crater",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [406] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 61319,
        description = "A hardy insect that can dwell in just about any climate, the beetle is known to thrive on battlefields after the fighting has ended.",
        familyType = 2,
        name = "Beetle",
        source = "Pet Battle: Badlands, Eastern Plaguelands, Felwood, Northern Stranglethorn, Silithus, The Cape of Stranglethorn, Un'Goro Crater",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [407] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 378,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 382,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 250,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S",
            "S/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61320,
        description = "This vicious species weaves elaborate webs throughout the dense jungles of Stranglethorn Vale.",
        familyType = 1,
        name = "Forest Spiderling",
        source = "Pet Battle: Northern Stranglethorn, The Cape of Stranglethorn",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [408] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 563,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 355,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 253,
                    level = 4
                },
                [2] =                 {
                    id = 802,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61321,
        description = "If a female lizard does not lay her clutch in a well camouflaged area, her eggs will likely be devoured by Lashtail Raptors.",
        familyType = 1,
        name = "Lizard Hatchling",
        source = "Pet Battle: Northern Stranglethorn, The Cape of Stranglethorn",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [409] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 521,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 7,
            power = 8,
            speed = 9
        },
        canBattle = true,
        creatureId = 61322,
        description = "Parrots can't get enough of the fresh fish the Bloodscalp trolls eat. They're less interested in dry flatbreads.",
        familyType = 5,
        name = "Polly",
        source = "Pet Battle: Northern Stranglethorn",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [410] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61323,
        description = "Just like the rough and tumble sailors who live dockside, the wharf rats are feral, violent creatures.",
        familyType = 2,
        name = "Wharf Rat",
        source = "Pet Battle: The Cape of Stranglethorn, Tol Barad Peninsula",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [411] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 349,
                    level = 1
                },
                [2] =                 {
                    id = 492,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 347,
                    level = 2
                },
                [2] =                 {
                    id = 350,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 352,
                    level = 4
                },
                [2] =                 {
                    id = 354,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61324,
        description = "Young apes quickly learn to hang from branches with their feet, leaving both hands free to fling objects at interlopers.",
        familyType = 1,
        name = "Baby Ape",
        source = "Pet Battle: The Cape of Stranglethorn|nWeather: Rain",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [412] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 378,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 382,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 250,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61327,
        description = "The most common of the arachnid family, these critters spin their webs in nearly every corner of Azeroth.",
        familyType = 1,
        name = "Spider",
        source = "Pet Battle: Azshara, Blasted Lands, Dustwallow Marsh, Eastern Plaguelands, Ghostlands, Hillsbrad Foothills, Howling Fjord, Stonetalon Mountains, Swamp of Sorrows, The Hinterlands, The Storm Peaks, Tirisfal Glades, Winterspring, Zul'Drak",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [414] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 356,
                    level = 1
                },
                [2] =                 {
                    id = 355,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 359,
                    level = 4
                },
                [2] =                 {
                    id = 124,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61326,
        description = "Venom capable of killing creatures up to 100 times its own body weight.",
        familyType = 1,
        name = "Scorpid",
        source = "Pet Battle: Blade's Edge Mountains, Blasted Lands, Burning Steppes, Eastern Plaguelands, Hellfire Peninsula, Orgrimmar, Shadowmoon Valley, Silithus, Thousand Needles, Twilight Highlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [415] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 173,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 172,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 61328,
        description = "Drawn to heat and the smell of smoke, the fire beetle's diet consists of ash.",
        familyType = 2,
        name = "Fire Beetle",
        source = "Pet Battle: Blasted Lands, Burning Steppes, Mount Hyjal, Searing Gorge, Un'Goro Crater",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [416] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 356,
                    level = 1
                },
                [2] =                 {
                    id = 355,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 359,
                    level = 4
                },
                [2] =                 {
                    id = 124,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61329,
        description = "Despite its snapping claws and venom-dripping tail, it is the bite of the diminutive scorpling that is the greatest threat.",
        familyType = 1,
        name = "Scorpling",
        source = "Pet Battle: Blasted Lands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [417] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61366,
        description = "The intrepid archaeologist Harrison Jones has a well documented fear of rats.",
        familyType = 2,
        name = "Rat",
        source = "Pet Battle: Arathi Highlands, Ashenvale, Azshara, Bloodmyst Isle, Crystalsong Forest, Darkshore, Desolace, Ghostlands, Hillsbrad Foothills, Howling Fjord, Loch Modan, Nagrand, Ruins of Gilneas, Silverpine Forest, Stonetalon Mountains, Swamp of Sorrows, Terokkar Forest, The Cape of Stranglethorn, The Hinterlands, Tirisfal Glades",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [418] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61367,
        description = "Brought to Orgrimmar aboard merchant ships, these short-lived reptiles are considered pests by the city's residents.",
        familyType = 1,
        name = "Water Snake",
        source = "Pet Battle: Durotar, Northern Stranglethorn, Orgrimmar, Swamp of Sorrows, Twilight Highlands, Wetlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [419] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 61071,
        description = "This is a small frog.",
        familyType = 0,
        name = "Small Frog",
        source = "Pet Battle: Arathi Highlands, Darnassus, Desolace, Elwynn Forest, Eversong Woods, Ghostlands, Loch Modan, Northern Barrens, Southern Barrens, Swamp of Sorrows, Teldrassil, Zangarmarsh",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [420] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/P",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 61369,
        description = "The song of late summer nights is the song of toads.",
        familyType = 0,
        name = "Toad",
        source = "Pet Battle: Ashenvale, Durotar, Dustwallow Marsh, Eversong Woods, Felwood, Ghostlands, Hillsbrad Foothills, Howling Fjord, Nagrand, Orgrimmar, Silverpine Forest, Swamp of Sorrows, Teldrassil, Twilight Highlands, Wetlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [421] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 61314,
        description = "Prefers to dwell in humid, tropical areas and feed on Kingsblood nectar.",
        familyType = 5,
        name = "Crimson Moth",
        source = "Pet Battle: Northern Stranglethorn, The Cape of Stranglethorn",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [422] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 61372,
        description = "When hunting or evading predators, this snake can travel on the surface of water for short distances.",
        familyType = 1,
        name = "Moccasin",
        source = "Pet Battle: Swamp of Sorrows",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [423] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 283,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 310,
                    level = 2
                },
                [2] =                 {
                    id = 173,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 179,
                    level = 4
                },
                [2] =                 {
                    id = 319,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 61383,
        description = "The thick exoskeleton of this adaptable arthropod allows it to thrive in harsh environments.",
        familyType = 4,
        name = "Lava Crab",
        source = "Pet Battle: Burning Steppes, Searing Gorge",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [424] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "H/H",
            "H/P",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61169,
        description = "A nuisance to most, roaches' incredible survivability sets them apart from other species.",
        familyType = 2,
        name = "Roach",
        source = "Pet Battle: Ashenvale, Azshara, Desolace, Duskwood, Howling Fjord, Loch Modan, Northern Stranglethorn, Redridge Mountains, Stonetalon Mountains, The Cape of Stranglethorn, Thousand Needles, Tirisfal Glades|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [425] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61385,
        description = "This ill-tempered snake species makes its home around the fiery molten pits of the Burning Steppes.",
        familyType = 1,
        name = "Ash Viper",
        source = "Pet Battle: Burning Steppes, Shadowmoon Valley",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [427] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 378,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 382,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 250,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61420,
        description = "The rock-hard carapaces of these spiders allow them to survive in the Searing Gorge's blistering heat.",
        familyType = 1,
        name = "Ash Spiderling",
        source = "Pet Battle: Searing Gorge",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [428] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 383,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 173,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 319,
                    level = 4
                },
                [2] =                 {
                    id = 382,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S",
            "S/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61425,
        description = "These blisteringly hot spiders camouflage themselves by blending in with oozing magma.",
        familyType = 1,
        name = "Molten Hatchling",
        source = "Pet Battle: Searing Gorge",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [429] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 173,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 172,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 61386,
        description = "Beetles in the Burning Steppes roll magma into tiny balls and eat them once they cool off.",
        familyType = 2,
        name = "Lava Beetle",
        source = "Pet Battle: Burning Steppes",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [430] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 61438,
        description = "Tiny, autonomous machines created by the Titans to clean and maintain their mighty edifices.",
        familyType = 2,
        name = "Gold Beetle",
        source = "Pet Battle: Badlands, Tanaris",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [431] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/S",
            "H/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61439,
        description = "Wildhammer dwarves train young gryphons by sending them out to hunt rattlesnakes in the Twilight Highlands.",
        familyType = 1,
        name = "Rattlesnake",
        source = "Pet Battle: Badlands, Tanaris, Twilight Highlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [432] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 356,
                    level = 1
                },
                [2] =                 {
                    id = 355,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 359,
                    level = 4
                },
                [2] =                 {
                    id = 124,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61440,
        description = "Less venomous but more aggressive than other breeds of scorpion.",
        familyType = 1,
        name = "Stripe-Tailed Scorpid",
        source = "Pet Battle: Badlands, Tanaris, Terokkar Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [433] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 563,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 355,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 253,
                    level = 4
                },
                [2] =                 {
                    id = 802,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61441,
        description = "The coloration of the spiky lizard allows it to blend in seamlessly with the desert sands of Silithus.",
        familyType = 1,
        name = "Spiky Lizard",
        source = "Pet Battle: Badlands, Silithus",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [437] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 493,
                    level = 1
                },
                [2] =                 {
                    id = 541,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 253,
                    level = 2
                },
                [2] =                 {
                    id = 497,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 376,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61459,
        description = "These rams hone their fighting skills by head-butting twigs and saplings near Loch Modan.",
        familyType = 1,
        name = "Little Black Ram",
        source = "Pet Battle: Loch Modan",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [438] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61443,
        description = "This snake is often seen sunning on the exposed rocks high in the Badlands.",
        familyType = 1,
        name = "King Snake",
        source = "Pet Battle: Badlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [439] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 422,
                    level = 1
                },
                [2] =                 {
                    id = 421,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 657,
                    level = 2
                },
                [2] =                 {
                    id = 214,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 121,
                    level = 4
                },
                [2] =                 {
                    id = 764,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 61375,
        description = "These creatures are silent, save for the occasional sigh of otherworldly despair.",
        familyType = 9,
        name = "Restless Shadeling",
        source = "Pet Battle: Deadwind Pass|nTime: Early Morning",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [440] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "P/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61689,
        description = "The thick snow near Dun Morogh acts as camouflage for snow cubs learning to hunt.",
        familyType = 1,
        name = "Snow Cub",
        source = "Pet Battle: Dun Morogh",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [441] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 7,
            speed = 9
        },
        canBattle = true,
        creatureId = 61690,
        description = "The alpine hare can burrow into the permafrost and hibernate for weeks or even months.",
        familyType = 2,
        name = "Alpine Hare",
        source = "Pet Battle: Dun Morogh, Winterspring",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [442] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/P",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 9,
            power = 6.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61691,
        description = "Most creatures cannot withstand a fraction of the harsh conditions that roaches can thrive in.",
        familyType = 2,
        name = "Irradiated Roach",
        source = "Pet Battle: Dun Morogh",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [443] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61704,
        description = "Despite their idyllic surroundings, grasslands cottontails hop at surprising speed when evading their pursuers.",
        familyType = 2,
        name = "Grasslands Cottontail",
        source = "Pet Battle: Arathi Highlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [445] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 514,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 515,
                    level = 2
                },
                [2] =                 {
                    id = 348,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 190,
                    level = 4
                },
                [2] =                 {
                    id = 204,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/P",
            "H/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61703,
        description = "Twisters delight in sneaking up on unsuspecting creatures and surprising them with gusts up their nostrils.",
        familyType = 4,
        name = "Tiny Twister",
        source = "Pet Battle: Arathi Highlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [446] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 445,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 447,
                    level = 2
                },
                [2] =                 {
                    id = 448,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 450,
                    level = 4
                },
                [2] =                 {
                    id = 369,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 61718,
        description = "Jade Oozelings glow in the dark, making them a welcome sight to workers in pitch-black mineshafts.",
        familyType = 7,
        name = "Jade Oozeling",
        source = "Pet Battle: The Hinterlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [447] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 493,
                    level = 1
                },
                [2] =                 {
                    id = 163,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 254,
                    level = 2
                },
                [2] =                 {
                    id = 574,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 539,
                    level = 4
                },
                [2] =                 {
                    id = 376,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61165,
        description = "Pay attention to deer crossings. Even a fawn will total a goblin trike.",
        familyType = 2,
        name = "Fawn",
        source = "Pet Battle: Elwynn Forest, Teldrassil",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [448] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7,
            speed = 9
        },
        canBattle = true,
        creatureId = 61751,
        description = "A carrot, a box, a stick, and some string. Wait a few hours and you'll have a hare.",
        familyType = 2,
        name = "Hare",
        source = "Pet Battle: Arathi Highlands, Durotar, The Hinterlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [449] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 367,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 159,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61752,
        description = "Distinct from their Azerothian relatives, these critters of Outland make their home in Blade's Edge Mountains.",
        familyType = 2,
        name = "Brown Marmot",
        source = "Pet Battle: Blade's Edge Mountains, The Hinterlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [450] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 367,
                    level = 1
                },
                [2] =                 {
                    id = 160,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 369,
                    level = 2
                },
                [2] =                 {
                    id = 371,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 159,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H"
        },
        baseStats =         {
            health = 9,
            power = 8,
            speed = 7
        },
        canBattle = true,
        creatureId = 61753,
        description = "The preferred habitat of this creature is woodland areas where it can safely complete its metamorphosis.",
        familyType = 1,
        name = "Maggot",
        source = "Pet Battle: Ashenvale, Ghostlands, Hillsbrad Foothills, Howling Fjord, The Hinterlands, Tirisfal Glades",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [452] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 411,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 165,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 167,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61757,
        description = "According to the tales of the night elves, the first red-tailed chipmunk was colored so after the theft and consumption of a sacred apple.",
        familyType = 2,
        name = "Red-Tailed Chipmunk",
        source = "Pet Battle: Darnassus, Desolace, Hillsbrad Foothills, Teldrassil",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [453] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 499,
                    level = 1
                },
                [2] =                 {
                    id = 347,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 348,
                    level = 2
                },
                [2] =                 {
                    id = 247,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 345,
                    level = 4
                },
                [2] =                 {
                    id = 663,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/P"
        },
        baseStats =         {
            health = 9,
            power = 8,
            speed = 7
        },
        canBattle = true,
        creatureId = 61758,
        description = "Infested cubs still listen for the telltale buzzing of bees even though they can no longer taste honey.",
        familyType = 9,
        name = "Infested Bear Cub",
        source = "Pet Battle: Hillsbrad Foothills",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [454] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61889,
        description = "Even the rats of Lordaeron fell to the apothecaries' plague, chewing upon the tainted flesh of the dead.",
        familyType = 2,
        name = "Undercity Rat",
        source = "Pet Battle: Tirisfal Glades",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [455] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 411,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 165,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 666,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/P",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61890,
        description = "Undead squirrels have acquired a taste for the strange berries and mushrooms that now grow in Silverpine Forest.",
        familyType = 9,
        name = "Blighted Squirrel",
        source = "Pet Battle: Silverpine Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [456] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 117,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 665,
                    level = 2
                },
                [2] =                 {
                    id = 654,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P",
            "P/S"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 61826,
        description = "Curiously, this hawk uses its razor-sharp talons to peel the bark off trees as it searches for bugs, even though it has no need for sustenance.",
        familyType = 9,
        name = "Blighthawk",
        source = "Pet Battle: Western Plaguelands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [457] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 367,
                    level = 1
                },
                [2] =                 {
                    id = 160,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 369,
                    level = 2
                },
                [2] =                 {
                    id = 371,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 159,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 9,
            power = 8,
            speed = 7
        },
        canBattle = true,
        creatureId = 61830,
        description = "It can swallow three times its own body weight in blood.",
        familyType = 1,
        name = "Festering Maggot",
        source = "Pet Battle: Eastern Plaguelands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [458] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 210,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 212,
                    level = 2
                },
                [2] =                 {
                    id = 299,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 650,
                    level = 4
                },
                [2] =                 {
                    id = 218,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H"
        },
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 61905,
        description = "These small spirits find their undead neighbors to be poor company, so they typically wander Tirisfal Glades alone.",
        familyType = 9,
        name = "Lost of Lordaeron",
        source = "Pet Battle: Tirisfal Glades",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [459] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S",
            "S/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62019,
        description = "After centuries of domestication, these furry critters inhabit nearly every human nation in the Eastern Kingdoms.",
        familyType = 1,
        name = "Cat",
        source = "Pet Battle: Arathi Highlands, Elwynn Forest, Eversong Woods, Netherstorm, Silvermoon City",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [460] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 962,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 318,
                    level = 2
                },
                [2] =                 {
                    id = 630,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 268,
                    level = 4
                },
                [2] =                 {
                    id = 400,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62020,
        description = "Small elemental saplings grow into treants, fierce defenders of forests and groves.",
        familyType = 4,
        name = "Ruby Sapling",
        source = "Pet Battle: Eversong Woods",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [461] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 367,
                    level = 1
                },
                [2] =                 {
                    id = 160,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 369,
                    level = 2
                },
                [2] =                 {
                    id = 371,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 159,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 9,
            power = 8,
            speed = 7
        },
        canBattle = true,
        creatureId = 62022,
        description = "This new arrival to Azeroth was spawned a short time ago. It seeks to thrive while awaiting its next phase of evolution.",
        familyType = 1,
        name = "Larva",
        source = "Pet Battle: Ghostlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [463] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 356,
                    level = 1
                },
                [2] =                 {
                    id = 488,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 509,
                    level = 2
                },
                [2] =                 {
                    id = 513,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 310,
                    level = 4
                },
                [2] =                 {
                    id = 476,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 9,
            power = 9,
            speed = 6
        },
        canBattle = true,
        creatureId = 62034,
        description = "The souls of slain crabs seek vengeance against the murlocs who ate them.",
        familyType = 9,
        name = "Spirit Crab",
        source = "Pet Battle: Ghostlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [464] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62050,
        description = "You can easily locate moths if you wear expensive garments near Ammen Vale. They can't resist the delicious taste of high fashion.",
        familyType = 5,
        name = "Grey Moth",
        source = "Pet Battle: Azuremyst Isle",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [465] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 441,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 359,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 124,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "P/S"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62051,
        description = "These voracious carnivores first arrived on Azeroth aboard the draenei's dimensional fortress, the Exodar.",
        familyType = 1,
        name = "Ravager Hatchling",
        source = "Pet Battle: Bloodmyst Isle",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [466] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 563,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 355,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 253,
                    level = 4
                },
                [2] =                 {
                    id = 802,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62114,
        description = "The children of Orgrimmar frequently capture these lizards as pets.  The adults of Orgrimmar frequently step on them.",
        familyType = 1,
        name = "Spiny Lizard",
        source = "Pet Battle: Durotar, Orgrimmar",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [467] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62115,
        description = "A desert dwelling forager attracted to areas rich with dung.",
        familyType = 2,
        name = "Dung Beetle",
        source = "Pet Battle: Durotar, Orgrimmar, Uldum",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [468] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62116,
        description = "These beetles often make their homes in quarries abandoned by the Horde war machine in Durotar.",
        familyType = 2,
        name = "Creepy Crawly",
        source = "Pet Battle: Durotar",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [469] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62118,
        description = "An enigmatic species, said to feed off the chaotic energies of the Old Gods.",
        familyType = 2,
        name = "Twilight Beetle",
        source = "Pet Battle: Azshara, Deepholm, Mount Hyjal",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [470] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 378,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 382,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 250,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "H/P",
            "S/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62117,
        description = "Twisted by the Twilight Hammer's dark magic, these sinister critters are known to feed on their own young.",
        familyType = 1,
        name = "Twilight Spider",
        source = "Pet Battle: Azshara, Deepholm, Twilight Highlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [471] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 455,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 389,
                    level = 2
                },
                [2] =                 {
                    id = 533,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 208,
                    level = 4
                },
                [2] =                 {
                    id = 459,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/H",
            "P/S",
            "H/S",
            "P/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62119,
        description = "Originally built by an irate goblin to annoy neighbors with an early morning wake-up call.",
        familyType = 8,
        name = "Robo-Chick",
        source = "Pet Battle: Azshara, Orgrimmar, Winterspring|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [472] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 384,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 389,
                    level = 2
                },
                [2] =                 {
                    id = 392,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 666,
                    level = 4
                },
                [2] =                 {
                    id = 278,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "S/S",
            "H/H",
            "H/P",
            "P/S",
            "P/B",
            "S/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62120,
        description = "Considered by most to be a significant improvement to the 4000 series, there were nonetheless serious concerns about the amount of heat they produced.",
        familyType = 8,
        name = "Rabid Nut Varmint 5000",
        source = "Pet Battle: Azshara, Stonetalon Mountains, Winterspring|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [473] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 249,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 310,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 376,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S"
        },
        baseStats =         {
            health = 9,
            power = 7.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 62121,
        description = "Turtles are feared by the naga, who consider them bad luck and give them a wide berth on the shores of Azshara.",
        familyType = 0,
        name = "Turquoise Turtle",
        source = "Pet Battle: Azshara",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [474] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 6,
            power = 8,
            speed = 10
        },
        canBattle = true,
        creatureId = 62129,
        description = "These playful feline cubs practice their hunting skills by stalking each other through the Barrens.",
        familyType = 1,
        name = "Cheetah Cub",
        source = "Pet Battle: Northern Barrens",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [475] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 493,
                    level = 1
                },
                [2] =                 {
                    id = 163,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 254,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 376,
                    level = 4
                },
                [2] =                 {
                    id = 539,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62130,
        description = "The barbaric centaur over-hunted giraffes for decades, but it was the tauren who saved this species from extinction.",
        familyType = 1,
        name = "Giraffe Calf",
        source = "Pet Battle: Southern Barrens",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [477] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 493,
                    level = 1
                },
                [2] =                 {
                    id = 163,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 254,
                    level = 2
                },
                [2] =                 {
                    id = 574,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 539,
                    level = 4
                },
                [2] =                 {
                    id = 376,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/B"
        },
        baseStats =         {
            health = 7.5,
            power = 7.5,
            speed = 9
        },
        canBattle = true,
        creatureId = 62176,
        description = "Young gazelles quickly learn to flee when they hear the war cries of tauren hunters in Mulgore.  They don't hear the good hunters, unfortunately.",
        familyType = 2,
        name = "Gazelle Fawn",
        source = "Pet Battle: Mulgore",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [478] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 62177,
        description = "Prefers to dwell in cool, forested areas and feed on Mageroyal nectar.",
        familyType = 5,
        name = "Forest Moth",
        source = "Pet Battle: Ashenvale, Darnassus, Desolace, Moonglade, Mount Hyjal, Teldrassil",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [479] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 6.5,
            speed = 9.5
        },
        canBattle = true,
        creatureId = 62178,
        description = "Their proximity to the magic of the elves has caused some of them unnatural long life. And in some elfin rabbits...stranger things.",
        familyType = 2,
        name = "Elfin Rabbit",
        source = "Pet Battle: Darnassus, Desolace, Mount Hyjal, Teldrassil",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [480] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 383,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 380,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 621,
                    level = 4
                },
                [2] =                 {
                    id = 436,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 62181,
        description = "Prized by gem crafters, the undamaged carapace of a topaz hatchling can be used to create stunning inlays for rings and bracelets.",
        familyType = 4,
        name = "Topaz Shale Hatchling",
        source = "Pet Battle: Deepholm, Desolace|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [482] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62184,
        description = "Long ago, Mount Hyjal's druids tempered this species to live in peace alongside the region's other creatures.",
        familyType = 1,
        name = "Rock Viper",
        source = "Pet Battle: Blade's Edge Mountains, Desolace, Mount Hyjal, Silithus",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [483] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62185,
        description = "There are many scholars who question whether it is a toad or not.",
        familyType = 0,
        name = "Horny Toad",
        source = "Pet Battle: Desolace",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [484] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 378,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 382,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 250,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S",
            "S/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62186,
        description = "This cunning species tunnels beneath Uldum and erupts from the ground to ensnare its prey.",
        familyType = 1,
        name = "Desert Spider",
        source = "Pet Battle: Desolace, Silithus, Tanaris, Uldum",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [485] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 310,
                    level = 2
                },
                [2] =                 {
                    id = 347,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 117,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 9,
            power = 7.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 62187,
        description = "When these sleepy critters aren't snoozing, they use their massive claws to dig for tasty insect snacks.",
        familyType = 2,
        name = "Stone Armadillo",
        source = "Pet Battle: Desolace|nTime: Night|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [487] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 411,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 165,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 167,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62189,
        description = "Many an explorer has been entranced by the adorable nature of the alpine chipmunk, failing to notice its small teeth on frostbitten digits.",
        familyType = 2,
        name = "Alpine Chipmunk",
        source = "Pet Battle: Mount Hyjal, Stonetalon Mountains, Winterspring",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [488] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62190,
        description = "Brave assassins sometimes capture these critters to use their highly toxic venom to poison weapons.",
        familyType = 1,
        name = "Coral Snake",
        source = "Pet Battle: Stonetalon Mountains",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [489] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 168,
                    level = 2
                },
                [2] =                 {
                    id = 172,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 169,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 62201,
        description = "These vicious fire-breathing whelps escaped Onyxia's lair and fled into the surrounding region. Handle with extreme caution.",
        familyType = 3,
        name = "Spawn of Onyxia",
        source = "Pet Battle: Dustwallow Marsh",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [491] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 7,
            power = 9,
            speed = 8
        },
        canBattle = true,
        creatureId = 62257,
        description = "Originally bred by the Sandfury trolls as pets, these feral and savage felines prowl the deserts of Tanaris.",
        familyType = 1,
        name = "Sand Kitten",
        source = "Pet Battle: Tanaris",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [492] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 62256,
        description = "A desert-dwelling insect which defends its eggs by spraying a foul, ogrelike scent.",
        familyType = 2,
        name = "Stinkbug",
        source = "Pet Battle: Tanaris",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [493] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 445,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 369,
                    level = 2
                },
                [2] =                 {
                    id = 310,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 564,
                    level = 4
                },
                [2] =                 {
                    id = 376,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P"
        },
        baseStats =         {
            health = 9.5,
            power = 8.5,
            speed = 6
        },
        canBattle = true,
        creatureId = 62246,
        description = "Hunts for food just below water's surface on coast of Darkshore.",
        familyType = 2,
        name = "Shimmershell Snail",
        source = "Pet Battle: Darkshore",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [494] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 538,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 453,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62258,
        description = "These hatchlings entertain themselves by clacking their mandibles together in increasingly complex rhythms.",
        familyType = 1,
        name = "Silithid Hatchling",
        source = "Pet Battle: Tanaris|nWeather: Sandstorm",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [495] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62312,
        description = "For every frog, a prince and princess in waiting.",
        familyType = 0,
        name = "Frog",
        source = "Pet Battle: Ashenvale",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [496] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 445,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 369,
                    level = 2
                },
                [2] =                 {
                    id = 310,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 564,
                    level = 4
                },
                [2] =                 {
                    id = 376,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 9.5,
            power = 8.5,
            speed = 6
        },
        canBattle = true,
        creatureId = 62313,
        description = "Don't let their lack of a face fool you--these slimy critters are angry and just itching for a fight.",
        familyType = 2,
        name = "Rusty Snail",
        source = "Pet Battle: Ashenvale",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [497] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/P",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62314,
        description = "Even cockroaches were not strong enough to withstand the foul seepage of demonic corruption.",
        familyType = 2,
        name = "Tainted Cockroach",
        source = "Pet Battle: Felwood, Shadowmoon Valley",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [498] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S",
            "H/S"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 62315,
        description = "Prefers to dwell in corrupted woodlands and feed on Purple Lotus nectar.",
        familyType = 5,
        name = "Tainted Moth",
        source = "Pet Battle: Felwood",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [499] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62316,
        description = "There are some things too dirty even for rats.",
        familyType = 2,
        name = "Tainted Rat",
        source = "Pet Battle: Felwood",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [500] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 406,
                    level = 1
                },
                [2] =                 {
                    id = 178,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 409,
                    level = 2
                },
                [2] =                 {
                    id = 392,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 407,
                    level = 4
                },
                [2] =                 {
                    id = 282,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "H/H",
            "H/P",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62317,
        description = "These ill-tempered constructs of flame and rage sometimes rise from the remains of larger infernals who fall in battle.",
        familyType = 7,
        name = "Minfernal",
        source = "Pet Battle: Felwood",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [502] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62370,
        description = "The dwarven explorer who first discovered the spotted bell frog could not decide between naming it after the unique spot pattern or the sound of the frog's mating ritual. She chose both.",
        familyType = 0,
        name = "Spotted Bell Frog",
        source = "Pet Battle: Un'Goro Crater",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [503] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 7.5,
            power = 7.5,
            speed = 9
        },
        canBattle = true,
        creatureId = 62373,
        description = "Prefers to dwell in the shadow of Nordrassil and feed on Stormvine nectar.",
        familyType = 5,
        name = "Silky Moth",
        source = "Pet Battle: Moonglade, Mount Hyjal, Un'Goro Crater",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [504] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 563,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 355,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 253,
                    level = 4
                },
                [2] =                 {
                    id = 802,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 62375,
        description = "Diemetradons abandon their hatchlings in Un'Goro Crater to fend for themselves. Only the strongest survive.",
        familyType = 1,
        name = "Diemetradon Hatchling",
        source = "Pet Battle: Un'Goro Crater",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [505] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 563,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 355,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 253,
                    level = 4
                },
                [2] =                 {
                    id = 802,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P",
            "S/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62255,
        description = "Although most reptiles enjoy basking in sunlight, these scaly beasts love bathing in the glow of Azeroth's twin moons.",
        familyType = 1,
        name = "Twilight Iguana",
        source = "Pet Battle: Thousand Needles",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [506] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 378,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 382,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 250,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/S",
            "S/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62191,
        description = "These eight-legged critters have lurked in the shadowy cliffs of the Stonetalon Mountains for millennia.",
        familyType = 1,
        name = "Venomspitter Hatchling",
        source = "Pet Battle: Stonetalon Mountains",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [507] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 184,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 784,
                    level = 2
                },
                [2] =                 {
                    id = 190,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 517,
                    level = 4
                },
                [2] =                 {
                    id = 518,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62242,
        description = "Many owls nest high in the stone structures of Darnassus, hunting any pests that enter the night elves' city.",
        familyType = 5,
        name = "Crested Owl",
        source = "Pet Battle: Teldrassil",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [508] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 347,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 247,
                    level = 2
                },
                [2] =                 {
                    id = 348,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 345,
                    level = 4
                },
                [2] =                 {
                    id = 124,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "H/P"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62250,
        description = "The fur of the darkshore bears owes to the almost perpetual gloom they live in, and their vision in the darkness is uncanny.",
        familyType = 1,
        name = "Darkshore Cub",
        source = "Pet Battle: Darkshore",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [509] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 406,
                    level = 1
                },
                [2] =                 {
                    id = 350,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 394,
                    level = 2
                },
                [2] =                 {
                    id = 364,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 398,
                    level = 4
                },
                [2] =                 {
                    id = 124,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61686,
        description = "These small elementals cling to the backs of larger mire beasts, picking off tasty bugs and mites.",
        familyType = 4,
        name = "Tiny Bog Beast",
        source = "Pet Battle: Wetlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [511] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62523,
        description = "Native to Azeroth's desert regions, these resilient reptiles can survive for weeks without water.",
        familyType = 1,
        name = "Sidewinder",
        source = "Pet Battle: Silithus, Uldum",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [512] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "H/H",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62524,
        description = "Spawn of the nefarious Shrieker Scarabs of Ahn'Qiraj, the hatchlings are much more docile (and quiet) than their parents.",
        familyType = 2,
        name = "Scarab Hatchling",
        source = "Pet Battle: Silithus",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [513] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 406,
                    level = 1
                },
                [2] =                 {
                    id = 741,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 521,
                    level = 2
                },
                [2] =                 {
                    id = 453,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 186,
                    level = 4
                },
                [2] =                 {
                    id = 227,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "S/S",
            "H/H",
            "H/P",
            "P/S",
            "H/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62526,
        description = "The squeaks used by these tiny insectoids may sound cute, but they're actually screaming for your death.",
        familyType = 6,
        name = "Qiraji Guardling",
        source = "Pet Battle: Silithus|nSeason: Summer",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [514] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 713,
                    level = 1
                },
                [2] =                 {
                    id = 355,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 426,
                    level = 2
                },
                [2] =                 {
                    id = 490,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 307,
                    level = 4
                },
                [2] =                 {
                    id = 124,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "S/S",
            "H/H",
            "H/P",
            "P/S",
            "H/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62555,
        description = "A brash fel orc once tried to enslave these critters as his personal soldiers. Pieces of him are still scattered across Outland.",
        familyType = 6,
        name = "Flayer Youngling",
        source = "Pet Battle: Hellfire Peninsula",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [515] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 219,
                    level = 1
                },
                [2] =                 {
                    id = 778,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 743,
                    level = 2
                },
                [2] =                 {
                    id = 745,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 746,
                    level = 4
                },
                [2] =                 {
                    id = 165,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "S/S",
            "H/H",
            "H/P",
            "P/S",
            "H/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62564,
        description = "These pudgy little beings often get themselves into trouble while hunting down their favorite snack: glow caps.",
        familyType = 6,
        name = "Sporeling Sprout",
        source = "Pet Battle: Zangarmarsh",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [517] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 616,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 355,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 802,
                    level = 4
                },
                [2] =                 {
                    id = 253,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62583,
        description = "After hatching, these twisted reptiles devour the weaker members of their clutches as an act of dominance.",
        familyType = 1,
        name = "Warpstalker Hatchling",
        source = "Pet Battle: Terokkar Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [518] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 349,
                    level = 1
                },
                [2] =                 {
                    id = 377,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 283,
                    level = 2
                },
                [2] =                 {
                    id = 375,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 571,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H"
        },
        baseStats =         {
            health = 9,
            power = 8.5,
            speed = 6.5
        },
        canBattle = true,
        creatureId = 62620,
        description = "For ogres, comparing a female's hair to a clefthoof's shaggy coat is a term of great endearment.",
        familyType = 1,
        name = "Clefthoof Runt",
        source = "Pet Battle: Nagrand",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [519] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 501,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 178,
                    level = 2
                },
                [2] =                 {
                    id = 172,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 179,
                    level = 4
                },
                [2] =                 {
                    id = 409,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 62621,
        description = "Born from demonic magic, these petulant little entities corrupt everything they touch with foul energies.",
        familyType = 4,
        name = "Fel Flame",
        source = "Pet Battle: Shadowmoon Valley",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [521] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 421,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 122,
                    level = 2
                },
                [2] =                 {
                    id = 420,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 422,
                    level = 4
                },
                [2] =                 {
                    id = 394,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 7,
            power = 9,
            speed = 8
        },
        canBattle = true,
        creatureId = 62627,
        description = "Adult nether rays are relatively docile, but their younglings are short-tempered and highly energetic beasts.",
        familyType = 5,
        name = "Fledgling Nether Ray",
        source = "Pet Battle: Netherstorm",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [523] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 367,
                    level = 1
                },
                [2] =                 {
                    id = 160,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 369,
                    level = 2
                },
                [2] =                 {
                    id = 371,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 159,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 9,
            power = 8,
            speed = 7
        },
        canBattle = true,
        creatureId = 62640,
        description = "Howling Fjord teems with the ever shifting cycle of life. When a creature dies, its body is quickly consumed by maggots, which in turn pass those nutrients on to a number of other creatures.",
        familyType = 1,
        name = "Devouring Maggot",
        source = "Pet Battle: Howling Fjord",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [525] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 524,
                    level = 2
                },
                [2] =                 {
                    id = 579,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 580,
                    level = 4
                },
                [2] =                 {
                    id = 581,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62648,
        description = "A key food source during the Feast of Winter Veil.",
        familyType = 5,
        name = "Turkey",
        source = "Pet Battle: Howling Fjord",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [528] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 569,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 347,
                    level = 2
                },
                [2] =                 {
                    id = 568,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 202,
                    level = 4
                },
                [2] =                 {
                    id = 357,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62628,
        description = "This grumpy species of basilisk roams the Blade's Edge Mountains, avoiding contact with other critters whenever possible.",
        familyType = 1,
        name = "Scalded Basilisk Hatchling",
        source = "Pet Battle: Blade's Edge Mountains",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [529] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 362,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 366,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "H/P"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62669,
        description = "There's an old vrykul saying that goes, 'Let sleeping worgs lie, unless you don't want your face anymore.'",
        familyType = 1,
        name = "Fjord Worg Pup",
        source = "Pet Battle: Howling Fjord",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [530] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 445,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 447,
                    level = 2
                },
                [2] =                 {
                    id = 448,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 450,
                    level = 4
                },
                [2] =                 {
                    id = 369,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62697,
        description = "These living blobs of ooze lack even the most rudimentary form of intelligence, but that doesn't mean they can't be your friend.",
        familyType = 7,
        name = "Oily Slimeling",
        source = "Pet Battle: Borean Tundra",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [532] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 349,
                    level = 1
                },
                [2] =                 {
                    id = 283,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 377,
                    level = 2
                },
                [2] =                 {
                    id = 571,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 375,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "H/H"
        },
        baseStats =         {
            health = 8.5,
            power = 9,
            speed = 6.5
        },
        canBattle = true,
        creatureId = 62816,
        description = "The fierce wolvar hunt these ill-tempered brutes for their horns, which are then carved into talismans and other trinkets.",
        familyType = 1,
        name = "Stunted Shardhorn",
        source = "Pet Battle: Sholazar Basin",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [534] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 190,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 521,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "S/S",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62819,
        description = "The taunka collect the feathers of these noble birds of prey to use in crude fortunetelling ceremonies.",
        familyType = 5,
        name = "Imperial Eagle Chick",
        source = "Pet Battle: Grizzly Hills",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [535] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 413,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 414,
                    level = 2
                },
                [2] =                 {
                    id = 416,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 418,
                    level = 4
                },
                [2] =                 {
                    id = 419,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62820,
        description = "The trolls of Zul'Drak inadvertently created these little beings while summoning water elementals to fight the Scourge.",
        familyType = 4,
        name = "Water Waveling",
        source = "Pet Battle: Zul'Drak",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [536] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 528,
                    level = 2
                },
                [2] =                 {
                    id = 575,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 413,
                    level = 4
                },
                [2] =                 {
                    id = 529,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 62835,
        description = "Tundra penguins often gather in large groups on the ice for protection against aquatic threats. Unfortunately this makes them easy prey for humanoid hunters seeking meat, skins and other achievements.",
        familyType = 0,
        name = "Tundra Penguin",
        source = "Pet Battle: Borean Tundra, Dragonblight",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [537] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 521,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "H/H",
            "H/P"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 62852,
        description = "These skulking little creatures hatch in nests built around the ancient dragon bones of central Northrend.",
        familyType = 5,
        name = "Dragonbone Hatchling",
        source = "Pet Battle: Dragonblight",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [538] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 393,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 256,
                    level = 2
                },
                [2] =                 {
                    id = 214,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 657,
                    level = 4
                },
                [2] =                 {
                    id = 668,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "P/S"
        },
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 62854,
        description = "Kel'Thuzad once nursed a plague-infected whelp to adulthood, feeding it only the finest liquefied remains.",
        familyType = 9,
        name = "Scourged Whelpling",
        source = "Pet Battle: Icecrown",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [539] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 359,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 253,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62884,
        description = "Grotto voles are often confused with mice. Never twice.",
        familyType = 2,
        name = "Grotto Vole",
        source = "Pet Battle: Mount Hyjal",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [540] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62885,
        description = "Where there is carrion, there will always be rats.",
        familyType = 2,
        name = "Carrion Rat",
        source = "Pet Battle: Mount Hyjal",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [541] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 8.5,
            power = 7,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62886,
        description = "The outer member of the roaches' eggs protect the larva from incineration. It is here in incubation that they gain the ability to resist the fire and heat of the volcanic climate.",
        familyType = 2,
        name = "Fire-Proof Roach",
        source = "Pet Battle: Mount Hyjal",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [542] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62892,
        description = "Flamboyantly colored and more exuberant than most frogs.",
        familyType = 0,
        name = "Mac Frog",
        source = "Pet Battle: Uldum",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [543] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62893,
        description = "When the locusts swarm, you can hear nothing but the sound of their wings.",
        familyType = 2,
        name = "Locust",
        source = "Pet Battle: Uldum",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [544] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 62895,
        description = "Prefers to dwell along desert streams, wells or watering holes and feed on Whiptail nectar.",
        familyType = 5,
        name = "Oasis Moth",
        source = "Pet Battle: Uldum",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [545] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 356,
                    level = 1
                },
                [2] =                 {
                    id = 355,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 359,
                    level = 4
                },
                [2] =                 {
                    id = 124,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62896,
        description = "Loves to rest inside footwear of unsuspecting travelers during the night.",
        familyType = 1,
        name = "Leopard Scorpid",
        source = "Pet Battle: Uldum",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [546] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62899,
        description = "Carrion feeders often found in large numbers within ancient unearthed tombs; they can survive long periods of time without feeding.",
        familyType = 2,
        name = "Tol'vir Scarab",
        source = "Pet Battle: Uldum",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [547] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 114,
                    level = 1
                },
                [2] =                 {
                    id = 461,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 463,
                    level = 2
                },
                [2] =                 {
                    id = 421,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 751,
                    level = 4
                },
                [2] =                 {
                    id = 299,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P",
            "H/S",
            "P/B",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 7,
            speed = 9
        },
        canBattle = true,
        creatureId = 62888,
        description = "During the Third War, thousands of these mystical beings annihilated the demon lord Archimonde.",
        familyType = 7,
        name = "Nordrassil Wisp",
        source = "Pet Battle: Mount Hyjal",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [548] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 524,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 420,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 581,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "S/S",
            "H/H",
            "H/P",
            "P/S",
            "H/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62900,
        description = "Too afraid to attempt flying until thrown from a great height.",
        familyType = 5,
        name = "Wildhammer Gryphon Hatchling",
        source = "Pet Battle: Twilight Highlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [549] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 367,
                    level = 1
                },
                [2] =                 {
                    id = 162,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 165,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 253,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62904,
        description = "Distinct from their plain dwelling relatives, these critters make their homes amidst the war-torn Twilight Highlands.",
        familyType = 2,
        name = "Yellow-Bellied Marmot",
        source = "Pet Battle: Twilight Highlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [550] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62905,
        description = "The mice of the highlands, perhaps twisted by the Twilight's Hammer, are aggressive and fight for dominance between each other.",
        familyType = 2,
        name = "Highlands Mouse",
        source = "Pet Battle: Twilight Highlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [552] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 655,
                    level = 1
                },
                [2] =                 {
                    id = 492,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 448,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 197,
                    level = 4
                },
                [2] =                 {
                    id = 212,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "H/H",
            "H/P",
            "S/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62914,
        description = "Demonstrating that a little evil goes a long way, this fiendling uses its razor-sharp teeth and gaping maw to devour anything in its path.",
        familyType = 7,
        name = "Twilight Fiendling",
        source = "Pet Battle: Twilight Highlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [553] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62921,
        description = "In the lean times when adrift at sea, the sight of a rat was a welcome one.",
        familyType = 2,
        name = "Stowaway Rat",
        source = "Pet Battle: Deepholm",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [554] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 383,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 380,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 621,
                    level = 4
                },
                [2] =                 {
                    id = 436,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62922,
        description = "Through experimentation, the mages of Dalaran have discovered that the powered remains of a crimson shale spider will greatly increase the conflagration of their fire spells.",
        familyType = 4,
        name = "Crimson Shale Hatchling",
        source = "Pet Battle: Deepholm",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [555] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 8.5,
            power = 7,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62924,
        description = "The cockroaches of Deepholm can burrow into stone itself to make their nests.",
        familyType = 2,
        name = "Deepholm Cockroach",
        source = "Pet Battle: Deepholm",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [556] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62925,
        description = "A cousin to the Twilight Beetle, this insect has learned to feed on crystals which resonate with ancient energies.",
        familyType = 2,
        name = "Crystal Beetle",
        source = "Pet Battle: Deepholm",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [557] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 421,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 440,
                    level = 2
                },
                [2] =                 {
                    id = 277,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 595,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "S/S",
            "H/P",
            "P/B",
            "S/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62395,
        description = "Much like other faerie dragons, these playful and mystical flyers are born with a natural defense against magic.",
        familyType = 3,
        name = "Nether Faerie Dragon",
        source = "Pet Battle: Feralas",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [558] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 362,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 366,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62864,
        description = "During frigid nights in the Storm Peaks, these critters use their fluffy tails as a blanket to stay warm.",
        familyType = 1,
        name = "Arctic Fox Kit",
        source = "Pet Battle: The Storm Peaks|nWeather: Snow",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [559] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 484,
                    level = 1
                },
                [2] =                 {
                    id = 617,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 263,
                    level = 2
                },
                [2] =                 {
                    id = 488,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 621,
                    level = 4
                },
                [2] =                 {
                    id = 606,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 7.5,
            power = 9,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 62927,
        description = "Therazane wore these spunky crimson elementals as jewelry before the azure craze swept through Deepholm.",
        familyType = 4,
        name = "Crimson Geode",
        source = "Pet Battle: Deepholm",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [560] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 190,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 521,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62953,
        description = "The seagull is a coastal scavenger often found near the docks.",
        familyType = 5,
        name = "Sea Gull",
        source = "Pet Battle: Krasarang Wilds, Tanaris",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [562] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62991,
        description = "The coral adder's venom is so deadly that one bite has been known to kill a full grown kodo beast.",
        familyType = 1,
        name = "Coral Adder",
        source = "Pet Battle: The Jade Forest|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [564] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 525,
                    level = 1
                },
                [2] =                 {
                    id = 249,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 310,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 376,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/B"
        },
        baseStats =         {
            health = 9.5,
            power = 7.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 62994,
        description = "It is difficult to believe that Shen-zin Su, on whose shell rests all of the Wandering Isle, began life as a tiny emerald turtle.",
        familyType = 0,
        name = "Emerald Turtle",
        source = "Pet Battle: The Jade Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [565] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 62997,
        description = "In the jungle, every leaf could conceal a frog. Stop to check and it could be long gone.",
        familyType = 0,
        name = "Jungle Darter",
        source = "Pet Battle: The Jade Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [566] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 497,
                    level = 4
                },
                [2] =                 {
                    id = 297,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 7.5,
            power = 7.5,
            speed = 9
        },
        canBattle = true,
        creatureId = 62998,
        description = "When preparing to travel to distant locations, Pandaren will traditionally capture a mirror strider and safely relocate it to another body of water.",
        familyType = 0,
        name = "Mirror Strider",
        source = "Pet Battle: The Jade Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [567] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "P/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62999,
        description = "The Jade Forest's pandaren consider these reptiles distant relatives of the revered Jade Serpent, Yu'lon.",
        familyType = 1,
        name = "Temple Snake",
        source = "Pet Battle: The Jade Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [568] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 445,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 369,
                    level = 2
                },
                [2] =                 {
                    id = 310,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 564,
                    level = 4
                },
                [2] =                 {
                    id = 376,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S"
        },
        baseStats =         {
            health = 9.5,
            power = 8.5,
            speed = 6
        },
        canBattle = true,
        creatureId = 63001,
        description = "Hides in shell to escape claws of nearby crabs.",
        familyType = 2,
        name = "Silkbead Snail",
        source = "Pet Battle: The Jade Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [569] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 63002,
        description = "One of the stranger nuisances to horticulturalists, garden frogs can cause untold damage to gardens.",
        familyType = 0,
        name = "Garden Frog",
        source = "Pet Battle: The Jade Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [570] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 283,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 152,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63003,
        description = "There's a raging debate over whether tanukis are raccoons or dogs, but the distinction seems trivial when they're gnawing on your femur.",
        familyType = 2,
        name = "Masked Tanuki",
        source = "Pet Battle: The Jade Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [571] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 63004,
        description = "The Jade Forest's mountain hozen fear these venomous reptiles and often hunt them out of pure spite.",
        familyType = 1,
        name = "Grove Viper",
        source = "Pet Battle: The Jade Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [572] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 356,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 511,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 310,
                    level = 4
                },
                [2] =                 {
                    id = 513,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "H/H"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 63005,
        description = "These tiny arthropods are Pandaria natives that call the area of the Windless Isle their home.",
        familyType = 0,
        name = "Spirebound Crab",
        source = "Pet Battle: The Jade Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [573] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 190,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 521,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/B",
            "S/B"
        },
        baseStats =         {
            health = 9,
            power = 7,
            speed = 8
        },
        canBattle = true,
        creatureId = 63006,
        description = "The sandy petrel flies high above the Windless Isle, safe from landbound predators.",
        familyType = 5,
        name = "Sandy Petrel",
        source = "Pet Battle: The Jade Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [626] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 383,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 521,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 186,
                    level = 4
                },
                [2] =                 {
                    id = 517,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "S/S",
            "H/P",
            "P/S",
            "P/B",
            "S/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61829,
        description = "This foreboding creature stalks the night skies of the Eastern Plaguelands, feeding on carrion.",
        familyType = 5,
        name = "Bat",
        source = "Pet Battle: Eastern Plaguelands, Mount Hyjal, Tirisfal Glades",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [627] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 499,
                    level = 1
                },
                [2] =                 {
                    id = 163,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 666,
                    level = 2
                },
                [2] =                 {
                    id = 743,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 160,
                    level = 4
                },
                [2] =                 {
                    id = 663,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/P",
            "P/B"
        },
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 61828,
        description = "More horrifying than its appearance is that the infected squirrels of the Plaguelands no longer hoard nuts, instead collecting rotten, decaying flesh.",
        familyType = 9,
        name = "Infected Squirrel",
        source = "Pet Battle: Bloodmyst Isle, Eastern Plaguelands, Silverpine Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [628] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 499,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 665,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 212,
                    level = 4
                },
                [2] =                 {
                    id = 214,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/B"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 61827,
        description = "Only the dimwitted or insane would mount an infected deer head on their wall. The good news is they'll fit right in with their new undead friends.",
        familyType = 9,
        name = "Infected Fawn",
        source = "Pet Battle: Bloodmyst Isle, Eastern Plaguelands, Silverpine Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [629] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 356,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 511,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 310,
                    level = 4
                },
                [2] =                 {
                    id = 513,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "H/P"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 63097,
        description = "Only found on the shores of Kezan, this lovely sea creature can be a bit snarky.",
        familyType = 0,
        name = "Shore Crawler",
        source = "Vendor: Matty|nZone: Orgrimmar",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [630] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 792,
                    level = 2
                },
                [2] =                 {
                    id = 256,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 517,
                    level = 4
                },
                [2] =                 {
                    id = 522,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63098,
        description = "Quoth the raven: the last word you said. It gets old.",
        familyType = 5,
        name = "Gilnean Raven",
        source = "Vendor: Will Larsons|nZone: Darkshore",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [631] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62127,
        description = "Hunted for its beautifully patterned skin, this majestic species thrives alongside Azeroth's lush rivers.",
        familyType = 1,
        name = "Emerald Boa",
        source = "Pet Battle: Northern Barrens, Southern Barrens, Uldum, Un'Goro Crater",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [632] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 563,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 355,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 253,
                    level = 4
                },
                [2] =                 {
                    id = 802,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62364,
        description = "The ash lizard gets its name from the way its shed skin looks, with an appearance like burnt cinders.",
        familyType = 1,
        name = "Ash Lizard",
        source = "Pet Battle: Mount Hyjal, Un'Goro Crater",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [633] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 576,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 527,
                    level = 4
                },
                [2] =                 {
                    id = 539,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/P",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61677,
        description = "The mountain skunk is most famous for its adventurous nature. No really, that is what it is famous for.",
        familyType = 2,
        name = "Mountain Skunk",
        source = "Pet Battle: Grizzly Hills, Stonetalon Mountains, The Storm Peaks, Wetlands, Winterspring",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [634] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 378,
                    level = 1
                },
                [2] =                 {
                    id = 569,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 382,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 250,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62435,
        description = "These strange critters glimmer like ice, allowing them to hide among Winterspring's snowy expanses.",
        familyType = 1,
        name = "Crystal Spider",
        source = "Pet Battle: Winterspring",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [635] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 61325,
        description = "Unlike other snakes that actively hunt, these crafty reptiles hide in thick foliage and ambush their prey.",
        familyType = 1,
        name = "Adder",
        source = "Pet Battle: Blasted Lands, Durotar, Hellfire Peninsula, Nagrand, Northern Barrens, Northern Stranglethorn, Southern Barrens|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [637] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 378,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 382,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 250,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62638,
        description = "These arachnids use their razor-sharp legs to carve tunnels in the solid rock of the Blade's Edge Mountains.",
        familyType = 1,
        name = "Skittering Cavern Crawler",
        source = "Pet Battle: Blade's Edge Mountains",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [638] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 193,
                    level = 1
                },
                [2] =                 {
                    id = 608,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 8.5,
            power = 7,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62625,
        description = "The nether roach has adapted to the cold vacuum of space and requires no air to survive. Inside it bears almost no resemblance to a common roach.",
        familyType = 2,
        name = "Nether Roach",
        source = "Pet Battle: Netherstorm",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [639] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 367,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 159,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62695,
        description = "Distinct from their cousins found in warmer climes, these hardy critters make their homes in the icy wastes of Northrend.",
        familyType = 2,
        name = "Borean Marmot",
        source = "Pet Battle: Borean Tundra",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [640] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7,
            speed = 9
        },
        canBattle = true,
        creatureId = 61755,
        description = "With the extra large surface area of their legs, snowshoe hares are able to effortlessly hop along the snow while their pursuers get bogged down in the drifts.",
        familyType = 2,
        name = "Snowshoe Hare",
        source = "Pet Battle: Hillsbrad Foothills",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [641] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7,
            speed = 9
        },
        canBattle = true,
        creatureId = 62693,
        description = "The heart of an arctic hare beats twice as fast as a common hare.",
        familyType = 2,
        name = "Arctic Hare",
        source = "Pet Battle: Borean Tundra, Dragonblight, The Storm Peaks, Zul'Drak",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [644] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62641,
        description = "If not for being extremely accident prone, the fjord rat might take over the world.",
        familyType = 2,
        name = "Fjord Rat",
        source = "Pet Battle: Howling Fjord",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [645] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 524,
                    level = 2
                },
                [2] =                 {
                    id = 579,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 580,
                    level = 4
                },
                [2] =                 {
                    id = 581,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62906,
        description = "Capable of flying, unlike domesticated types.",
        familyType = 5,
        name = "Highlands Turkey",
        source = "Pet Battle: Twilight Highlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [646] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 524,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 642,
                    level = 4
                },
                [2] =                 {
                    id = 581,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62664,
        description = "Tends to avoid crossing roads, regardless of motivations.",
        familyType = 5,
        name = "Chicken",
        source = "Pet Battle: Duskwood, Dustwallow Marsh, Elwynn Forest, Hillsbrad Foothills, Howling Fjord, Redridge Mountains, Terokkar Forest, Tirisfal Glades, Westfall, Wetlands|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [647] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 411,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 165,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 167,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S",
            "P/B",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62818,
        description = "In the deep forest, even the small creatures must have the ferocity to fend for themselves.",
        familyType = 2,
        name = "Grizzly Squirrel",
        source = "Pet Battle: Grizzly Hills, Twilight Highlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [648] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P",
            "H/B"
        },
        baseStats =         {
            health = 9,
            power = 7.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 61368,
        description = "This is a huge toad.",
        familyType = 0,
        name = "Huge Toad",
        source = "Pet Battle: Hillsbrad Foothills, Swamp of Sorrows, Twilight Highlands, Zul'Drak",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [649] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/P",
            "P/S"
        },
        baseStats =         {
            health = 9,
            power = 7.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 62815,
        description = "The rumors of the medicinal uses of the biletoad were believed to have been started by a particularly mischievous apothecary.",
        familyType = 0,
        name = "Biletoad",
        source = "Pet Battle: Sholazar Basin|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [650] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 826,
                    level = 1
                },
                [2] =                 {
                    id = 419,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 745,
                    level = 2
                },
                [2] =                 {
                    id = 298,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 404,
                    level = 4
                },
                [2] =                 {
                    id = 828,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 63365,
        description = "And you thought turnips at the dinner table were bad.",
        familyType = 4,
        name = "Terrible Turnip",
        source = "Drop: World Drop|nZone: Valley of the Four Winds",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [652] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 230,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 513,
                    level = 4
                },
                [2] =                 {
                    id = 297,
                    level = 20
                }            }
        },
        availableBreeds = {"S/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63559,
        description = "This bubble is way worse than a tank.",
        familyType = 0,
        name = "Tiny Goldfish",
        source = "Vendor: Nat Pagle|nZone: Krasarang Wilds|nFaction: The Anglers - Honored|nCost: 250|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [671] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 576,
                    level = 2
                },
                [2] =                 {
                    id = 578,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 377,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63832,
        description = "Offspring of the Imperial Quilen.",
        familyType = 2,
        name = "Lucky Quilen Cub",
        source = "Promotion: Mists of Pandaria Collector's Edition Pet",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [675] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62954,
        description = "Unnoticed but to cats and ratcatchers, when Deathwing descended upon Stormwind all the rats beat a hasty retreat from the city. Only of late have they returned.",
        familyType = 2,
        name = "Stormwind Rat",
        source = "Pet Battle: Elwynn Forest, Stormwind City|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [677] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 283,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 152,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 64246,
        description = "A goblin alchemist once claimed that the bite of this raccoon gave him the gift of prophecy. Turns out, it was just rabies.",
        familyType = 2,
        name = "Shy Bandicoon",
        source = "Pet Battle: Valley of the Four Winds",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [678] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 367,
                    level = 1
                },
                [2] =                 {
                    id = 160,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 369,
                    level = 2
                },
                [2] =                 {
                    id = 371,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 159,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63304,
        description = "These little green grubs are native to wilds of Pandaria. Its verdant coloration camouflages it from would-be predators.",
        familyType = 1,
        name = "Jungle Grub",
        source = "Pet Battle: Krasarang Wilds",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [679] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 493,
                    level = 1
                },
                [2] =                 {
                    id = 541,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 253,
                    level = 2
                },
                [2] =                 {
                    id = 497,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 376,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 64248,
        description = "You'll often find them perched high atop impossibly high and remote stone outcroppings. There are few creatures as sure of foot.",
        familyType = 1,
        name = "Summit Kid",
        source = "Pet Battle: Kun-Lai Summit|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [680] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 412,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 509,
                    level = 4
                },
                [2] =                 {
                    id = 564,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63953,
        description = "The mongoose is prized for its ability to drive off poisonous snakes.  Rikk-tikk-tikki-tikki-tchk!",
        familyType = 0,
        name = "Kuitan Mongoose",
        source = "Pet Battle: Townlong Steppes|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [699] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 378,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 382,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 250,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 63715,
        description = "This terrifying and highly venomous species leaps onto its prey from the Jade Forest's dense canopy.",
        familyType = 1,
        name = "Jumping Spider",
        source = "Pet Battle: The Jade Forest|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [702] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 63919,
        description = "The leopard tree frog was named for the way it pounces from branch to branch.",
        familyType = 0,
        name = "Leopard Tree Frog",
        source = "Pet Battle: The Jade Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [703] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 283,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 152,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63716,
        description = "Many young raccoons rail against their strict curfews, complaining that dawn is way too early to go to bed.",
        familyType = 2,
        name = "Masked Tanuki Pup",
        source = "Pet Battle: The Jade Forest",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [706] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 283,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 152,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63062,
        description = "The taciturn bandicoon's diet consists mostly of apples.",
        familyType = 2,
        name = "Bandicoon",
        source = "Pet Battle: Valley of the Four Winds",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [707] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 283,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 152,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63064,
        description = "Some druids say pandaren and raccoons are distant cousins, but never when a pandaren can hear them.",
        familyType = 2,
        name = "Bandicoon Kit",
        source = "Pet Battle: Valley of the Four Winds",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [708] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 315,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 283,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 63094,
        description = "Many believe that the quillrat is able to shoot its spines at aggressors.",
        familyType = 2,
        name = "Malayan Quillrat",
        source = "Pet Battle: Valley of the Four Winds, Krasarang Wilds",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [709] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 315,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 283,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 63095,
        description = "Although the wounds caused by the young quillrat are seldom fatal, most predators seek easier prey.",
        familyType = 2,
        name = "Malayan Quillrat Pup",
        source = "Pet Battle: Valley of the Four Winds",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [710] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 626,
                    level = 1
                },
                [2] =                 {
                    id = 357,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 706,
                    level = 2
                },
                [2] =                 {
                    id = 506,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 573,
                    level = 4
                },
                [2] =                 {
                    id = 298,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63096,
        description = "Known to feast on the tasty plants in Valley of the Four Winds.",
        familyType = 2,
        name = "Marsh Fiddler",
        source = "Pet Battle: Valley of the Four Winds",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [711] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 412,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 509,
                    level = 4
                },
                [2] =                 {
                    id = 564,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63057,
        description = "The sifang otter lives near rivers and is normally friendly and playful.",
        familyType = 0,
        name = "Sifang Otter",
        source = "Pet Battle: Valley of the Four Winds",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [712] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 412,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 509,
                    level = 4
                },
                [2] =                 {
                    id = 564,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63358,
        description = "Otters swim by propelling themselves with their powerful tails and flexing their long bodies. Very fast in the water.",
        familyType = 0,
        name = "Sifang Otter Pup",
        source = "Pet Battle: Valley of the Four Winds",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [713] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 249,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 310,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 376,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S"
        },
        baseStats =         {
            health = 9,
            power = 7.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 63060,
        description = "Softshell turtle meat is considered a delicacy and is the key ingredient in soothing turtle bisque.",
        familyType = 0,
        name = "Softshell Snapling",
        source = "Pet Battle: Valley of the Four Winds",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [714] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 378,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 382,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 250,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "P/B",
            "S/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 65054,
        description = "The common folk remedy to a feverbite hatchling's bite is to dance wildly and try to sweat out the toxins before they can take hold.",
        familyType = 1,
        name = "Feverbite Hatchling",
        source = "Pet Battle: Krasarang Wilds|n|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [716] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 378,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 382,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 250,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 63288,
        description = "A rarity among arachnids, these non-venomous critters feed solely on plants and fruit.",
        familyType = 1,
        name = "Amethyst Spiderling",
        source = "Pet Battle: Krasarang Wilds|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [717] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "H/H",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 63291,
        description = "The most delicious of the beetle family.",
        familyType = 2,
        name = "Savory Beetle",
        source = "Pet Battle: Krasarang Wilds|n|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [718] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 65124,
        description = "A daring, narcissist insect willing to brave any threat in its pursuit of the spotlight.",
        familyType = 5,
        name = "Luyu Moth",
        source = "Pet Battle: Krasarang Wilds|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [722] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 632,
                    level = 2
                },
                [2] =                 {
                    id = 506,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 270,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "P/B",
            "H/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 65185,
        description = "Feeds on small leaves and grass when full grown.",
        familyType = 5,
        name = "Mei Li Sparkler",
        source = "Pet Battle: Krasarang Wilds|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [723] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 249,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 310,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 376,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 9,
            power = 7.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 63293,
        description = "Angering a spiny terrapin will cause it to withdraw into its shell and begin to spin wildly towards an attacker.",
        familyType = 0,
        name = "Spiny Terrapin",
        source = "Pet Battle: Krasarang Wilds",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [724] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 362,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 366,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63550,
        description = "Burrows deep into snowbanks to hide from predators.",
        familyType = 1,
        name = "Alpine Foxling",
        source = "Pet Battle: Kun-Lai Summit|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [725] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 362,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 366,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63551,
        description = "Occasionally sneaks bites of food from kills made by much larger animals.",
        familyType = 1,
        name = "Alpine Foxling Kit",
        source = "Pet Battle: Kun-Lai Summit|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [726] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 563,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 355,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 253,
                    level = 4
                },
                [2] =                 {
                    id = 802,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 63547,
        description = "While stationary, the plains monitor will continuously flick its tail back and forth. From a distance this mimics the appearance of swaying tallgrass, camouflaging the lizard from aerial predators.",
        familyType = 1,
        name = "Plains Monitor",
        source = "Pet Battle: Kun-Lai Summit|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [727] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 253,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 59702,
        description = "On the prairie there are numerous rodents and other small creatures, but none more common than the mouse.",
        familyType = 2,
        name = "Prairie Mouse",
        source = "Pet Battle: Kun-Lai Summit|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [728] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 524,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 642,
                    level = 4
                },
                [2] =                 {
                    id = 581,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63585,
        description = "Will only lay eggs in bright light.",
        familyType = 5,
        name = "Szechuan Chicken",
        source = "Pet Battle: Kun-Lai Summit",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [729] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7,
            speed = 9
        },
        canBattle = true,
        creatureId = 63557,
        description = "In the ancient fables, the first Tolai hare strode across the gulf between the stars before it upset them and they tumbled from the heavens to the world below.",
        familyType = 2,
        name = "Tolai Hare",
        source = "Pet Battle: Kun-Lai Summit|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [730] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7,
            speed = 9
        },
        canBattle = true,
        creatureId = 63558,
        description = "Tolai hare pups are sent from their dens at a young age to find their own way.",
        familyType = 2,
        name = "Tolai Hare Pup",
        source = "Pet Battle: Kun-Lai Summit|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [731] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 156,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 63555,
        description = "These reptiles possess hooked scales, allowing them to slither up Kun-Lai Summit's rocky slopes and steep cliffs.",
        familyType = 1,
        name = "Zooey Snake",
        source = "Pet Battle: Kun-Lai Summit|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [732] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/S",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 65187,
        description = "Known to flourish in the rainy season, this insect is drawn to lightning storms.",
        familyType = 5,
        name = "Amber Moth",
        source = "Pet Battle: Dread Wastes|nPet Battle: Townlong Steppes",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [733] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 626,
                    level = 1
                },
                [2] =                 {
                    id = 357,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 706,
                    level = 2
                },
                [2] =                 {
                    id = 506,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 573,
                    level = 4
                },
                [2] =                 {
                    id = 298,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63549,
        description = "At night, the grassland hoppers fill the night with their maddening song. Those unaccustomed to it have spent many a sleepless night serenaded by their mating calls.",
        familyType = 2,
        name = "Grassland Hopper",
        source = "Pet Battle: Townlong Steppes",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [737] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 412,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 509,
                    level = 4
                },
                [2] =                 {
                    id = 564,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 6.5,
            power = 8,
            speed = 9.5
        },
        canBattle = true,
        creatureId = 65190,
        description = "Contrary to its benign appearance, mongoose are dangerous carnivores, well known for their ability to hunt venomous snakes that could kill much larger creatures.",
        familyType = 0,
        name = "Mongoose",
        source = "Pet Battle: Townlong Steppes|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [739] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 412,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 509,
                    level = 4
                },
                [2] =                 {
                    id = 564,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 7,
            power = 8,
            speed = 9
        },
        canBattle = true,
        creatureId = 63954,
        description = "Mongoose pups prefer long grass where only their mothers can find them.",
        familyType = 0,
        name = "Mongoose Pup",
        source = "Pet Battle: Townlong Steppes|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [740] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 253,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 360,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 163,
                    level = 4
                },
                [2] =                 {
                    id = 283,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 63957,
        description = "The bond between yak and rat is a strange one, and what the rat gains out of the symbiotic relationship is a mystery.",
        familyType = 2,
        name = "Yakrat",
        source = "Pet Battle: Townlong Steppes, Dread Wastes|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [741] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 315,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 283,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 64804,
        description = "These hedgehogs may be silent, but often are heard the cries of those that foolishly step upon their quills.",
        familyType = 1,
        name = "Silent Hedgehog",
        source = "Pet Battle: Dread Wastes|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [742] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 283,
                    level = 2
                },
                [2] =                 {
                    id = 315,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 158,
                    level = 4
                },
                [2] =                 {
                    id = 566,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 64242,
        description = "Hedgehogs are not at all fond of croquet nor flamingos.",
        familyType = 1,
        name = "Clouded Hedgehog",
        source = "Pet Battle: Dread Wastes|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [743] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 445,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 369,
                    level = 2
                },
                [2] =                 {
                    id = 310,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 564,
                    level = 4
                },
                [2] =                 {
                    id = 376,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/B"
        },
        baseStats =         {
            health = 9.5,
            power = 8.5,
            speed = 6
        },
        canBattle = true,
        creatureId = 64352,
        description = "Has been spotted fighting other whelks for prime food sources.",
        familyType = 2,
        name = "Rapana Whelk",
        source = "Pet Battle: Dread Wastes|n|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [744] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "H/H",
            "H/P",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 64238,
        description = "The roaches of the Dread Wastes dwell in the shadows. Some people swear the shadows travel with them.",
        familyType = 2,
        name = "Resilient Roach",
        source = "Pet Battle: Dread Wastes|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [745] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 356,
                    level = 1
                },
                [2] =                 {
                    id = 355,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 359,
                    level = 4
                },
                [2] =                 {
                    id = 124,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63548,
        description = "Unique carapace is prized by trinket makers for its texture and strength.",
        familyType = 1,
        name = "Crunchy Scorpion",
        source = "Pet Battle: Dread Wastes|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [746] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 356,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 511,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 310,
                    level = 4
                },
                [2] =                 {
                    id = 513,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "H/H"
        },
        baseStats =         {
            health = 8.5,
            power = 9,
            speed = 6.5
        },
        canBattle = true,
        creatureId = 65203,
        description = "The emperor crab was named for its regal appearance: the ridges of its shell and its raised claws eerily resembling a crown. One that would pinch your eyes out if you tried to wear it.",
        familyType = 0,
        name = "Emperor Crab",
        source = "Pet Battle: Dread Wastes|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [747] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 632,
                    level = 2
                },
                [2] =                 {
                    id = 506,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 270,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "P/B",
            "H/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 63850,
        description = "Luminescent body used to attract mates.",
        familyType = 5,
        name = "Effervescent Glowfly",
        source = "Pet Battle: Vale of Eternal Blossoms|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [748] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P",
            "P/S",
            "H/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 63838,
        description = "This delicate insect's wings are often sewn into clothing and armor.",
        familyType = 5,
        name = "Gilded Moth",
        source = "Pet Battle: Vale of Eternal Blossoms|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [749] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 412,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 509,
                    level = 4
                },
                [2] =                 {
                    id = 564,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63841,
        description = "Civets are landbound cousins of the otter and are prized for their heady musks.",
        familyType = 0,
        name = "Golden Civet",
        source = "Pet Battle: Vale of Eternal Blossoms",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [750] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 412,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 509,
                    level = 4
                },
                [2] =                 {
                    id = 564,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63842,
        description = "The civets are known to guard their young ferociously.",
        familyType = 0,
        name = "Golden Civet Kitten",
        source = "Pet Battle: Vale of Eternal Blossoms",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [751] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 497,
                    level = 4
                },
                [2] =                 {
                    id = 297,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 63847,
        description = "Named for their apparent dancelike behavior when skimming aquatic surfaces, the species uses erratic movements to avoid being devoured by fish and other underwater predators.",
        familyType = 0,
        name = "Dancing Water Skimmer",
        source = "Pet Battle: Vale of Eternal Blossoms|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [752] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 232,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "H/B"
        },
        baseStats =         {
            health = 9,
            power = 7.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 63849,
        description = "Despite its menacing appearance, the yellow-bellied bullfrog was aptly named.",
        familyType = 0,
        name = "Yellow-Bellied Bullfrog",
        source = "Pet Battle: Vale of Eternal Blossoms|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [753] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 65215,
        description = "Known to flourish in the rainy season, this insect is drawn to lightning storms.",
        familyType = 5,
        name = "Garden Moth",
        source = "Pet Battle: Jade Forest|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [754] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 632,
                    level = 2
                },
                [2] =                 {
                    id = 506,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 270,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P",
            "P/S",
            "H/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 65216,
        description = "This species of insect is drawn to the latent energy in shrines, their luminescent appearance adding to the mystique of the places of power.",
        familyType = 5,
        name = "Shrine Fly",
        source = "Pet Battle: The Jade Forest|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [755] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 155,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 519,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 9,
            power = 6.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62887,
        description = "The markings on the carapace of this cockroach closely resemble that of the Death's Head.",
        familyType = 2,
        name = "Death's Head Cockroach",
        source = "Pet Battle: Mount Hyjal|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [756] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 162,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/S"
        },
        baseStats =         {
            health = 8.5,
            power = 7,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62916,
        description = "Prefers to dwell in dark caves and feed on Heartblossom nectar.",
        familyType = 5,
        name = "Fungal Moth",
        source = "Pet Battle: Deepholm|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [757] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 204,
                    level = 2
                },
                [2] =                 {
                    id = 347,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 190,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 14755,
        description = "Legends say that these vibrant emerald beings bring good fortune and safe travels to their owners.",
        familyType = 3,
        name = "Tiny Green Dragon",
        source = "Promotion: iCoke China",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [758] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 204,
                    level = 2
                },
                [2] =                 {
                    id = 347,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 190,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 14756,
        description = "Said to bring good fortune when spotted in autumn.  Known to hide from unfamiliar creatures.",
        familyType = 3,
        name = "Tiny Red Dragon",
        source = "Promotion: iCoke China",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [792] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 521,
                    level = 2
                },
                [2] =                 {
                    id = 431,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 190,
                    level = 4
                },
                [2] =                 {
                    id = 581,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 65314,
        description = "A graceful creature from the isle of Pandaria.",
        familyType = 5,
        name = "Jade Crane Chick",
        source = "Vendor: Audrey Burnhep, Varzok|nZone: Stormwind, Orgrimmar|nCost: 50|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [802] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 204,
                    level = 2
                },
                [2] =                 {
                    id = 347,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 190,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 65313,
        description = "A baby version of the mighty Thundering Cloud Serpent that hails from the far lands of Pandaria.",
        familyType = 3,
        name = "Thundering Serpent Hatchling",
        source = "Vendor: Guild Vendor|nZone: Stormwind, Orgrimmar|nCost: 300|TINTERFACE\\\\MONEYFRAME\\\\UI-GOLDICON.BLP:0|t|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [817] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 204,
                    level = 2
                },
                [2] =                 {
                    id = 347,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 190,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 65323,
        description = "So cute, yet so epic.",
        familyType = 3,
        name = "Wild Jade Hatchling",
        source = "Pet Battle: The Jade Forest|nFaction: Order of the Cloud Serpent (Exalted)|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [818] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 204,
                    level = 2
                },
                [2] =                 {
                    id = 347,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 190,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 65324,
        description = "So cute, yet so epic.",
        familyType = 3,
        name = "Wild Golden Hatchling",
        source = "Pet Battle: The Jade Forest|nFaction: Order of the Cloud Serpent (Exalted)",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [819] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 168,
                    level = 2
                },
                [2] =                 {
                    id = 172,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 169,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 65321,
        description = "So cute, yet so epic.",
        familyType = 3,
        name = "Wild Crimson Hatchling",
        source = "Pet Battle: The Jade Forest|nFaction: Order of the Cloud Serpent (Exalted)|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [820] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 626,
                    level = 1
                },
                [2] =                 {
                    id = 357,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 706,
                    level = 2
                },
                [2] =                 {
                    id = 506,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 573,
                    level = 4
                },
                [2] =                 {
                    id = 298,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 64232,
        description = "Known to feast on the tasty plants in Krasarang Wilds.",
        familyType = 2,
        name = "Singing Cricket",
        source = "Achievement: Pro Pet Mob|nCategory: Pet Battle",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = true
    },
    [821] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 406,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 371,
                    level = 2
                },
                [2] =                 {
                    id = 398,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 669,
                    level = 4
                },
                [2] =                 {
                    id = 668,
                    level = 20
                }            }
        },
        availableBreeds = {"S/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 63621,
        description = "It keeps looking at me. I think it wants to bite me.",
        familyType = 6,
        name = "Feral Vermling",
        source = "Achievement: Going to Need More Leashes|nCategory: Collect",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [823] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 576,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 527,
                    level = 4
                },
                [2] =                 {
                    id = 539,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62907,
        description = "This ferocious skunk can spray an attacker from thirty yards away, temporarily blinding them.  Handle with caution!",
        familyType = 2,
        name = "Highlands Skunk",
        source = "Pet Battle: Twilight Highlands",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [834] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 801,
                    level = 1
                },
                [2] =                 {
                    id = 621,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 453,
                    level = 2
                },
                [2] =                 {
                    id = 814,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 628,
                    level = 4
                },
                [2] =                 {
                    id = 644,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 64634,
        description = "Mogu sorcerers, keepers of the secret to bringing stone to life, prefer these stolid companions over more beastly familiars.",
        familyType = 4,
        name = "Grinder",
        source = "Drop: Karr the Darkener|nZone: Dread Wastes|n|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [835] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 406,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 371,
                    level = 2
                },
                [2] =                 {
                    id = 398,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 669,
                    level = 4
                },
                [2] =                 {
                    id = 668,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 64632,
        description = "The great big world can be a dangerous place for such a tiny, adorable creature.",
        familyType = 6,
        name = "Hopling",
        source = "Achievement: Ling-Ting's Herbal Journey|nCategory: Dungeons and Raids",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = true
    },
    [836] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 230,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 497,
                    level = 4
                },
                [2] =                 {
                    id = 297,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 7.5,
            power = 7,
            speed = 9.5
        },
        canBattle = true,
        creatureId = 64633,
        description = "Water striders serve an important role in Jinyu culture, acting as a mount, means of sending communications, and even a family pet.",
        familyType = 0,
        name = "Aqua Strider",
        source = "Drop: Nalash Verdantis|nZone: Dread Wastes|n|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [837] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 383,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 380,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 621,
                    level = 4
                },
                [2] =                 {
                    id = 436,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "S/S",
            "H/H",
            "H/P",
            "P/S",
            "H/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 62915,
        description = "Adventurers have reported rare sightings of a monstrous sized emerald shale spider, which the denizens of Deepholm have come to call the Jadefang.",
        familyType = 4,
        name = "Emerald Shale Hatchling",
        source = "Pet Battle: Deepholm",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [838] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 383,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 380,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 621,
                    level = 4
                },
                [2] =                 {
                    id = 436,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "S/S",
            "H/H",
            "H/P",
            "P/S",
            "H/S",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62182,
        description = "Adult amethyst shale spiders prefer to create their nests against the outer walls of Deepholm.",
        familyType = 4,
        name = "Amethyst Shale Hatchling",
        source = "Pet Battle: Deepholm, Desolace",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [844] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 515,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 647,
                    level = 2
                },
                [2] =                 {
                    id = 779,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 282,
                    level = 4
                },
                [2] =                 {
                    id = 334,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 64899,
        description = "Constructed from a seemingly impossible mass of gears, springs, wires, and a little something special, this dragonling embodies the spirit of Pandaria as seen through an engineer's goggles.",
        familyType = 8,
        name = "Mechanical Pandaren Dragonling",
        source = "Profession: Engineering",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [845] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 162,
                    level = 2
                },
                [2] =                 {
                    id = 521,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 61877,
        description = "Jade is naturally rich with life and color, making it the perfect raw material for this gentle companion.  It is said the wind created by their wings can soothe the troubled mind.",
        familyType = 7,
        name = "Jade Owl",
        source = "Profession: Jewelcrafting|n",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [846] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 394,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 621,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 6,
            power = 8,
            speed = 10
        },
        canBattle = true,
        creatureId = 61883,
        description = "While each cub is crafted in the same fashion, tiny imperfections in the gemstones create a unique personality when imbued with life.  They are, however, always playful and friendly.",
        familyType = 4,
        name = "Sapphire Cub",
        source = "Profession: Jewelcrafting|n",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [847] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 230,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 513,
                    level = 4
                },
                [2] =                 {
                    id = 297,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 62829,
        description = "Many believe (incorrectly) that goldfish have no memories. Trainers who have worked with them know this is clearly not the case and have the bruises to prove it.",
        familyType = 0,
        name = "Fishy",
        source = "Quest: Let Them Burn|nZone: The Jade Forest",
        sourceTypeEnum = 1,
        tradeable = true,
        unique = false
    },
    [848] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 849,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 851,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 7,
            speed = 9
        },
        canBattle = true,
        creatureId = 59358,
        description = "This rabbit is much stronger than it looks.",
        familyType = 2,
        name = "Darkmoon Rabbit",
        source = "Drop: Darkmoon Rabbit|nZone: Darkmoon Island",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [849] =     {
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = false,
        creatureId = 66104,
        description = "A beautiful kite brought to life by the scribes of Pandaria.",
        familyType = 5,
        name = "Chi-Ji Kite",
        source = "Profession: Inscription",
        sourceTypeEnum = 3,
        tradeable = false,
        unique = false
    },
    [850] =     {
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = false,
        creatureId = 66105,
        description = "Who knew scribes could make kites?",
        familyType = 5,
        name = "Yu'lon Kite",
        source = "Profession: Inscription",
        sourceTypeEnum = 3,
        tradeable = false,
        unique = false
    },
    [851] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 563,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 355,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 253,
                    level = 4
                },
                [2] =                 {
                    id = 802,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "H/P"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 62894,
        description = "Not only is it quick, it's loud too!",
        familyType = 1,
        name = "Horned Lizard",
        source = "Pet Battle: Uldum",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [855] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 394,
                    level = 1
                },
                [2] =                 {
                    id = 398,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 404,
                    level = 2
                },
                [2] =                 {
                    id = 303,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 402,
                    level = 4
                },
                [2] =                 {
                    id = 745,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 66491,
        description = "Seems odd that he doesn't like flies... right?",
        familyType = 4,
        name = "Venus",
        source = "Achievement: That's a Lot of Pet Food|nCategory: Collect",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [856] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 630,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 310,
                    level = 2
                },
                [2] =                 {
                    id = 268,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 400,
                    level = 4
                },
                [2] =                 {
                    id = 318,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 66450,
        description = "Careful now, she can get a bit frisky sometimes!",
        familyType = 4,
        name = "Jade Tentacle",
        source = "Achievement: Time To Open a Pet Store|nCategory: Pet Battles",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [868] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 419,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 123,
                    level = 2
                },
                [2] =                 {
                    id = 513,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 564,
                    level = 4
                },
                [2] =                 {
                    id = 418,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 66950,
        description = "These spirits represent the heart of Pandaria's elemental powers.",
        familyType = 4,
        name = "Pandaren Water Spirit",
        source = "Quest: Pandaren Spirit Tamer|nZone: Vale of Eternal Blossoms",
        sourceTypeEnum = 1,
        tradeable = true,
        unique = false
    },
    [1013] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 249,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 310,
                    level = 2
                },
                [2] =                 {
                    id = 576,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 297,
                    level = 4
                },
                [2] =                 {
                    id = 230,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 9,
            power = 7.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 67022,
        description = "Legend has it that a seadragon turtle just like this one grew up to become Shen-zin Su, the Wandering Isle. Perhaps your little turtle will grow into something amazing?",
        familyType = 0,
        name = "Wanderer's Festival Hatchling",
        source = "Pet Battle: Krasarang Wilds|nEvent: Wanderer's Festival",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1039] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 514,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 507,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 508,
                    level = 4
                },
                [2] =                 {
                    id = 190,
                    level = 20
                }            }
        },
        availableBreeds = {"H/H"},
        baseStats =         {
            health = 7.5,
            power = 7.5,
            speed = 9
        },
        canBattle = true,
        creatureId = 67230,
        description = "The larval form of this moth is world-renowned for creating the finest silk in Azeroth.",
        familyType = 5,
        name = "Imperial Moth",
        source = "Profession: Tailoring (Imperial Silk)",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [1040] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 367,
                    level = 1
                },
                [2] =                 {
                    id = 160,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 371,
                    level = 2
                },
                [2] =                 {
                    id = 507,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {"H/H"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 67233,
        description = "This plump red caterpillar is world-renowned for creating the finest silk in Azeroth.",
        familyType = 2,
        name = "Imperial Silkworm",
        source = "Profession: Tailoring (Imperial Silk)|n",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [1042] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 626,
                    level = 1
                },
                [2] =                 {
                    id = 357,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 706,
                    level = 2
                },
                [2] =                 {
                    id = 506,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 573,
                    level = 4
                },
                [2] =                 {
                    id = 298,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 6.75,
            power = 10.5,
            speed = 6.75
        },
        canBattle = true,
        creatureId = 63370,
        description = "Be careful, he might eat all your crops!",
        familyType = 2,
        name = "Red Cricket",
        source = "Quest: Sho, Requires Exalted Friendship Faction|nZone: Valley of the Four Winds",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = false
    },
    [1061] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 377,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 521,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 581,
                    level = 4
                },
                [2] =                 {
                    id = 518,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 67319,
        description = "Most of Violet's numerous forest strider hatchlings are turned into Faire fare by Stamp Thunderhorn, though a few are raised as mounts or purchased by adventurers looking for a petite purple pet.",
        familyType = 2,
        name = "Darkmoon Hatchling",
        source = "Vendor: Lhara|nZone: Darkmoon Island|nCost: 90|TINTERFACE\\\\ICONS\\\\inv_misc_ticket_darkmoon_01:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [1062] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 270,
                    level = 2
                },
                [2] =                 {
                    id = 359,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 632,
                    level = 4
                },
                [2] =                 {
                    id = 366,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/S",
            "P/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 67329,
        description = "Their eerie green light, reminiscent of fel flames, is occasionally seen flitting through the twisted trees of Darkmoon Island.",
        familyType = 5,
        name = "Darkmoon Glowfly",
        source = "Pet Battle: Darkmoon Island|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1063] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 482,
                    level = 1
                },
                [2] =                 {
                    id = 473,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 475,
                    level = 2
                },
                [2] =                 {
                    id = 216,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 869,
                    level = 4
                },
                [2] =                 {
                    id = 474,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 67332,
        description = "Don't even think about cheating now.",
        familyType = 7,
        name = "Darkmoon Eye",
        source = "Drop: Darkmoon Pet Supplies|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1068] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 524,
                    level = 2
                },
                [2] =                 {
                    id = 256,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 870,
                    level = 4
                },
                [2] =                 {
                    id = 517,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 67443,
        description = "While smaller than the infamous ravens of Gilneas, crows are no less clever or cunning.",
        familyType = 5,
        name = "Crow",
        source = "Pet Battle: Occasionally appears alongside other creatures during battles on Darkmoon Island.",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1124] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 319,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 178,
                    level = 2
                },
                [2] =                 {
                    id = 503,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 173,
                    level = 4
                },
                [2] =                 {
                    id = 179,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68466,
        description = "These spirits represent the heart of Pandaria's elemental powers.",
        familyType = 4,
        name = "Pandaren Fire Spirit",
        source = "Quest: Pandaren Spirit Tamer|nZone: Vale of Eternal Blossoms|n",
        sourceTypeEnum = 1,
        tradeable = true,
        unique = false
    },
    [1125] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 514,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 741,
                    level = 2
                },
                [2] =                 {
                    id = 396,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 190,
                    level = 4
                },
                [2] =                 {
                    id = 589,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68467,
        description = "These spirits represent the heart of Pandaria's elemental powers.",
        familyType = 4,
        name = "Pandaren Air Spirit",
        source = "Quest: Pandaren Spirit Tamer|nZone: Vale of Eternal Blossoms|n",
        sourceTypeEnum = 1,
        tradeable = true,
        unique = false
    },
    [1126] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 801,
                    level = 1
                },
                [2] =                 {
                    id = 621,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 814,
                    level = 2
                },
                [2] =                 {
                    id = 628,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 569,
                    level = 4
                },
                [2] =                 {
                    id = 572,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68468,
        description = "These spirits represent the heart of Pandaria's elemental powers.",
        familyType = 4,
        name = "Pandaren Earth Spirit",
        source = "Quest: Pandaren Spirit Tamer|nZone: Vale of Eternal Blossoms|n",
        sourceTypeEnum = 1,
        tradeable = true,
        unique = false
    },
    [1128] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 412,
                    level = 1
                },
                [2] =                 {
                    id = 424,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 572,
                    level = 2
                },
                [2] =                 {
                    id = 152,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 283,
                    level = 4
                },
                [2] =                 {
                    id = 527,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68506,
        description = "A rodent of usual size.",
        familyType = 1,
        name = "Sumprush Rodent",
        source = "Pet Battle: Krasarang Wilds",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1142] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 219,
                    level = 1
                },
                [2] =                 {
                    id = 762,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 389,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 307,
                    level = 4
                },
                [2] =                 {
                    id = 312,
                    level = 20
                }            }
        },
        availableBreeds = {"S/B"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 68601,
        description = "Created for one purpose and one purpose alone: to punch little critters, as hard as it possibly can.",
        familyType = 8,
        name = "Clock'em",
        source = "Vendor: Paul North|nZone: Brawl'gar Arena|nCost: 30|TINTERFACE\\\\MONEYFRAME\\\\UI-SILVERICON.BLP:0|t",
        sourceTypeEnum = 2,
        tradeable = false,
        unique = false
    },
    [1143] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 648,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 339,
                    level = 2
                },
                [2] =                 {
                    id = 212,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 383,
                    level = 4
                },
                [2] =                 {
                    id = 780,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68656,
        description = "Found in a dusty egg clutch at the back of Maexxna's lair, these creatures are already undead when they hatch.",
        familyType = 9,
        name = "Giant Bone Spider",
        source = "Drop: Maexxna|nZone: Naxxramas",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1144] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 449,
                    level = 1
                },
                [2] =                 {
                    id = 160,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 743,
                    level = 2
                },
                [2] =                 {
                    id = 745,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 746,
                    level = 4
                },
                [2] =                 {
                    id = 402,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68657,
        description = "Loatheb's body is covered in small pods capable of spreading blighted fungal spores up to 1000 yards given proper wind conditions.",
        familyType = 9,
        name = "Fungal Abomination",
        source = "Drop: Loatheb|nZone: Naxxramas",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1145] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 479,
                    level = 2
                },
                [2] =                 {
                    id = 414,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 624,
                    level = 4
                },
                [2] =                 {
                    id = 120,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68655,
        description = "Upon exiting the freezing necropolis of Naxxramas, Mr. Bigglesworth promptly found a warm spot in the sun to take a long nap in.",
        familyType = 9,
        name = "Mr. Bigglesworth",
        source = "Achievement: Raiding with Leashes|nCategory: Collect",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [1146] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 499,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 666,
                    level = 2
                },
                [2] =                 {
                    id = 362,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 665,
                    level = 4
                },
                [2] =                 {
                    id = 657,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68654,
        description = "When Gluth died to a band of brave adventurers, these lil' guys were found in the corpse, gnawing on giant, undead bones.",
        familyType = 9,
        name = "Stitched Pup",
        source = "Drop: Gluth|nZone: Naxxramas",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1147] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 219,
                    level = 1
                },
                [2] =                 {
                    id = 113,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 319,
                    level = 2
                },
                [2] =                 {
                    id = 178,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 800,
                    level = 4
                },
                [2] =                 {
                    id = 179,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68665,
        description = "Few of these fiery harbingers remain following Ragnaros' defeat in the Firelands.",
        familyType = 6,
        name = "Harbinger of Flame",
        source = "Drop: Sulfuron Harbinger|nZone: Molten Core",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1149] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 567,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 409,
                    level = 2
                },
                [2] =                 {
                    id = 503,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 173,
                    level = 4
                },
                [2] =                 {
                    id = 592,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68664,
        description = "These tiny flame imps roam the Molten Core in large swarms and can replenish their numbers rapidly.",
        familyType = 6,
        name = "Corefire Imp",
        source = "Drop: Magmadar|nZone: Molten Core",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1150] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 484,
                    level = 1
                },
                [2] =                 {
                    id = 113,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 263,
                    level = 2
                },
                [2] =                 {
                    id = 436,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 569,
                    level = 4
                },
                [2] =                 {
                    id = 609,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68666,
        description = "The cooled core of Golemagg, it appears to retain some semi-sentient properties.",
        familyType = 4,
        name = "Ashstone Core",
        source = "Drop: Golemagg the Incinerator|nZone: Molten Core|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1151] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 347,
                    level = 2
                },
                [2] =                 {
                    id = 315,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 609,
                    level = 4
                },
                [2] =                 {
                    id = 168,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68661,
        description = "One of Razorgore's eggs that miraculously survived in Blackwing Lair.",
        familyType = 3,
        name = "Untamed Hatchling",
        source = "Drop: Razorgore the Untamed|nZone: Blackwing Lair",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1152] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 299,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 362,
                    level = 2
                },
                [2] =                 {
                    id = 611,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 802,
                    level = 4
                },
                [2] =                 {
                    id = 593,
                    level = 20
                }            }
        },
        availableBreeds = {"H/H"},
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 68662,
        description = "Opponents that face this fierce chromatic monstrosity just hope it doesn't have Time Stop!",
        familyType = 3,
        name = "Chrominius",
        source = "Drop: Chromaggus|nZone: Blackwing Lair",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1153] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 713,
                    level = 1
                },
                [2] =                 {
                    id = 393,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 741,
                    level = 2
                },
                [2] =                 {
                    id = 315,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 792,
                    level = 4
                },
                [2] =                 {
                    id = 350,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68663,
        description = "A runt of the Black Talon, left to guard the whelps.",
        familyType = 3,
        name = "Death Talon Whelpguard",
        source = "Drop: Broodlord Lashlayer|nZone: Blackwing Lair",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1154] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 445,
                    level = 1
                },
                [2] =                 {
                    id = 756,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 471,
                    level = 2
                },
                [2] =                 {
                    id = 380,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 450,
                    level = 4
                },
                [2] =                 {
                    id = 448,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68660,
        description = "This small globule didn't make it back to Viscidus in time to re-form.",
        familyType = 7,
        name = "Viscidus Globule",
        source = "Drop: Viscidus|nZone: Ahn'Qiraj",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1155] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 406,
                    level = 1
                },
                [2] =                 {
                    id = 390,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 453,
                    level = 2
                },
                [2] =                 {
                    id = 436,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 490,
                    level = 4
                },
                [2] =                 {
                    id = 814,
                    level = 20
                }            }
        },
        availableBreeds = {"H/H"},
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 68659,
        description = "An anubisath idol from the Temple of Ahn'qiraj, infused with ancient qiraji magic.",
        familyType = 6,
        name = "Anubisath Idol",
        source = "Drop: Emperor Vek'lor|nZone: Ahn'Qiraj",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1156] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 475,
                    level = 1
                },
                [2] =                 {
                    id = 489,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 488,
                    level = 2
                },
                [2] =                 {
                    id = 216,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 474,
                    level = 4
                },
                [2] =                 {
                    id = 277,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68658,
        description = "The bane of many an adventurer, to look into its eyes is to truly know madness.",
        familyType = 7,
        name = "Mini Mindslayer",
        source = "Drop: The Prophet Skeram|nZone: Ahn'Qiraj",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1157] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 184,
                    level = 1
                },
                [2] =                 {
                    id = 420,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 515,
                    level = 2
                },
                [2] =                 {
                    id = 158,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 524,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68804,
        description = "They only get more beautiful as they age.",
        familyType = 6,
        name = "Harpy Youngling",
        source = "Pet Battle: Northern Barrens",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1158] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 202,
                    level = 1
                },
                [2] =                 {
                    id = 111,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 314,
                    level = 2
                },
                [2] =                 {
                    id = 762,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 124,
                    level = 4
                },
                [2] =                 {
                    id = 348,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 68805,
        description = "Hunted by locals for years, this is an extremely rare specimen.",
        familyType = 6,
        name = "Stunted Yeti",
        source = "Pet Battle: Feralas",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1159] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 421,
                    level = 1
                },
                [2] =                 {
                    id = 422,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 299,
                    level = 2
                },
                [2] =                 {
                    id = 488,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 216,
                    level = 4
                },
                [2] =                 {
                    id = 218,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 68806,
        description = "Most people have never read this book.",
        familyType = 7,
        name = "Lofty Libram",
        source = "Pet Battle: Hillsbrad Foothills|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1160] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 473,
                    level = 1
                },
                [2] =                 {
                    id = 483,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 475,
                    level = 2
                },
                [2] =                 {
                    id = 486,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 474,
                    level = 4
                },
                [2] =                 {
                    id = 489,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 68819,
        description = "Never take your eye off of it.",
        familyType = 7,
        name = "Arcane Eye",
        source = "Pet Battle: Deadwind Pass|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1161] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 122,
                    level = 1
                },
                [2] =                 {
                    id = 594,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 168,
                    level = 2
                },
                [2] =                 {
                    id = 471,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 405,
                    level = 4
                },
                [2] =                 {
                    id = 792,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 68820,
        description = "You better believe he knows what time it is.",
        familyType = 3,
        name = "Infinite Whelpling",
        source = "Pet Battle: Caverns of Time|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1162] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 923,
                    level = 2
                },
                [2] =                 {
                    id = 389,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 536,
                    level = 4
                },
                [2] =                 {
                    id = 208,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 7,
            power = 9,
            speed = 8
        },
        canBattle = true,
        creatureId = 68838,
        description = "Originally created by the engineers in the bowels of Gnomeregan, the Fluxfire Feline is a marvel of modern engineering.",
        familyType = 8,
        name = "Fluxfire Feline",
        source = "Pet Battle: Gnomeregan|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1163] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 390,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 278,
                    level = 2
                },
                [2] =                 {
                    id = 533,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 345,
                    level = 4
                },
                [2] =                 {
                    id = 208,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/P"
        },
        baseStats =         {
            health = 9,
            power = 8,
            speed = 7
        },
        canBattle = true,
        creatureId = 68839,
        description = "The engineering wizards in Everlook created this unique cub as a test model.  Unfortunately a few went rogue and were never recovered.",
        familyType = 8,
        name = "Anodized Robo Cub",
        source = "Pet Battle: Winterspring|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1164] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 455,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 389,
                    level = 2
                },
                [2] =                 {
                    id = 357,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 305,
                    level = 4
                },
                [2] =                 {
                    id = 278,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "S/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 68841,
        description = "This model of raptors is produced in the Blade's Edge Mountains.  Their robotic roars are a common sound near Toshley Station.",
        familyType = 8,
        name = "Cogblade Raptor",
        source = "Pet Battle: Blade's Edge Mountains|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1165] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 122,
                    level = 1
                },
                [2] =                 {
                    id = 782,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 763,
                    level = 2
                },
                [2] =                 {
                    id = 489,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 592,
                    level = 4
                },
                [2] =                 {
                    id = 589,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 68845,
        description = "The runts of Malygos brood, these whelplings are prized for their boundless arcane magics.",
        familyType = 3,
        name = "Nexus Whelpling",
        source = "Pet Battle: Coldarra|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1166] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 202,
                    level = 1
                },
                [2] =                 {
                    id = 221,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 314,
                    level = 2
                },
                [2] =                 {
                    id = 416,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 124,
                    level = 4
                },
                [2] =                 {
                    id = 481,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 68846,
        description = "Indigenous to the peaks of Kun-Lai Summit, this rare yeti is much more dangerous than it looks.",
        familyType = 6,
        name = "Kun-Lai Runt",
        source = "Pet Battle: Kun-Lai Summit|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1167] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 525,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 611,
                    level = 2
                },
                [2] =                 {
                    id = 597,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 612,
                    level = 4
                },
                [2] =                 {
                    id = 598,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 68850,
        description = "These beautiful drakes can be found across the shores of Northrend.",
        familyType = 3,
        name = "Emerald Proto-Whelp",
        source = "Pet Battle: Sholazar Basin|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1168] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 111,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 756,
                    level = 2
                },
                [2] =                 {
                    id = 757,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 350,
                    level = 4
                },
                [2] =                 {
                    id = 163,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 15361,
        description = "Murki is one of the world's rarest species of murloc.",
        familyType = 6,
        name = "Murki",
        source = "Promotion: Korean Promotional Event",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [1175] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 424,
                    level = 1
                },
                [2] =                 {
                    id = 908,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 578,
                    level = 2
                },
                [2] =                 {
                    id = 906,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 779,
                    level = 4
                },
                [2] =                 {
                    id = 325,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 69648,
        description = "Touched by lightning, these dangerous rodents should be kept at a safe distance.",
        familyType = 4,
        name = "Thundertail Flapper",
        source = "Pet Battle: Isle of Thunder",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1176] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 119,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 905,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 576,
                    level = 4
                },
                [2] =                 {
                    id = 247,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 69649,
        description = "Can you believe how cute I am?  Me neither.",
        familyType = 1,
        name = "Red Panda",
        source = "Quest: Beasts of Fable|n",
        sourceTypeEnum = 1,
        tradeable = false,
        unique = true
    },
    [1177] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 111,
                    level = 1
                },
                [2] =                 {
                    id = 910,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 436,
                    level = 2
                },
                [2] =                 {
                    id = 453,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 621,
                    level = 4
                },
                [2] =                 {
                    id = 912,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/P",
            "H/S",
            "P/B"
        },
        baseStats =         {
            health = 9,
            power = 8,
            speed = 7
        },
        canBattle = true,
        creatureId = 69748,
        description = "Born of sand, these dangerous creatures can form and disperse in the blink of an eye.",
        familyType = 4,
        name = "Living Sandling",
        source = "Drop: Throne of Thunder|n|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1178] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 482,
                    level = 1
                },
                [2] =                 {
                    id = 901,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 392,
                    level = 2
                },
                [2] =                 {
                    id = 916,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 204,
                    level = 4
                },
                [2] =                 {
                    id = 208,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 69778,
        description = "Loyal to the Sunreavers from creation, these pint-sized constructs can still pack a punch.",
        familyType = 8,
        name = "Sunreaver Micro-Sentry",
        source = "Drop: Haywire Sunreaver Construct|nZone: Isle of Thunder",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1179] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 803,
                    level = 1
                },
                [2] =                 {
                    id = 908,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 909,
                    level = 2
                },
                [2] =                 {
                    id = 423,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 906,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 69794,
        description = "Lightning can be seen flowing across its body, teeth to tail.",
        familyType = 4,
        name = "Electrified Razortooth",
        source = "Pet Battle: Isle of Thunder",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1180] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 921,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 357,
                    level = 2
                },
                [2] =                 {
                    id = 919,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 364,
                    level = 4
                },
                [2] =                 {
                    id = 917,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "S/S",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 69796,
        description = "This unique raptor was born on the island of Zandalar and transported here along with the rest of the Zandalari army.",
        familyType = 1,
        name = "Zandalari Kneebiter",
        source = "Drop: Zandalari Dinomancer|nZone: Isle Of Giants",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1181] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 152,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 359,
                    level = 2
                },
                [2] =                 {
                    id = 930,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 929,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 69818,
        description = "These snakes have been known to swallow gnomes in one gulp.",
        familyType = 1,
        name = "Elder Python",
        source = "Pet Battle: Isle of Thunder",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1182] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 228,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 932,
                    level = 2
                },
                [2] =                 {
                    id = 232,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 233,
                    level = 4
                },
                [2] =                 {
                    id = 934,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 69819,
        description = "Probably best not to touch it.",
        familyType = 0,
        name = "Swamp Croaker",
        source = "Pet Battle: Isle of Thunder",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1183] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 384,
                    level = 1
                },
                [2] =                 {
                    id = 455,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 937,
                    level = 2
                },
                [2] =                 {
                    id = 940,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 392,
                    level = 4
                },
                [2] =                 {
                    id = 938,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 69820,
        description = "Forged in the Throne of Thunder, these tiny creations are servants of the great Dark Animus.",
        familyType = 8,
        name = "Son of Animus",
        source = "Drop: Animus|nZone: Throne of Thunder",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1184] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 958,
                    level = 1
                },
                [2] =                 {
                    id = 377,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 571,
                    level = 2
                },
                [2] =                 {
                    id = 163,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 920,
                    level = 4
                },
                [2] =                 {
                    id = 960,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8.25,
            power = 8,
            speed = 7.75
        },
        canBattle = true,
        creatureId = 69849,
        description = "Even at this tiny size, Direhorns are known to wreak havoc on unsuspecting victims.",
        familyType = 1,
        name = "Stunted Direhorn",
        source = "Achievement: Brutal Pet Brawler|nCategory: Battle",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [1185] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 566,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 442,
                    level = 2
                },
                [2] =                 {
                    id = 914,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 465,
                    level = 4
                },
                [2] =                 {
                    id = 913,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 69848,
        description = "Something about this creature looks familiar...",
        familyType = 7,
        name = "Spectral Porcupette",
        source = "Quest: A Large Pile of Giant Dinosaur Bones|nZone: Isle Of Giants",
        sourceTypeEnum = 1,
        tradeable = true,
        unique = false
    },
    [1196] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 119,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 247,
                    level = 2
                },
                [2] =                 {
                    id = 905,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 404,
                    level = 4
                },
                [2] =                 {
                    id = 165,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 69891,
        description = "These cuddly rascals enjoy basking in the sun, sleeping in the sun, and napping in the sun.",
        familyType = 1,
        name = "Sunfur Panda",
        source = "Quest: Beasts of Fable|n",
        sourceTypeEnum = 1,
        tradeable = true,
        unique = false
    },
    [1197] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 477,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 905,
                    level = 2
                },
                [2] =                 {
                    id = 206,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 165,
                    level = 4
                },
                [2] =                 {
                    id = 479,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 69893,
        description = "The white fur of the Snowy Panda allows it to hide in the snowbanks of Kun-Lai Summit.",
        familyType = 1,
        name = "Snowy Panda",
        source = "Quest: Beasts of Fable|n",
        sourceTypeEnum = 1,
        tradeable = true,
        unique = false
    },
    [1198] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 119,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 905,
                    level = 2
                },
                [2] =                 {
                    id = 628,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 572,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 69892,
        description = "Cousin to the Snowy Panda, Mountain Pandas reside in the lower regions of Kun-Lai Summit.",
        familyType = 1,
        name = "Mountain Panda",
        source = "Quest: Beasts of Fable|n",
        sourceTypeEnum = 1,
        tradeable = true,
        unique = false
    },
    [1200] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 958,
                    level = 1
                },
                [2] =                 {
                    id = 377,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 571,
                    level = 2
                },
                [2] =                 {
                    id = 163,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 920,
                    level = 4
                },
                [2] =                 {
                    id = 960,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8.25,
            power = 8,
            speed = 7.75
        },
        canBattle = true,
        creatureId = 70083,
        description = "Don't pet the pointy end. Note: all of the ends are pointy.",
        familyType = 1,
        name = "Pygmy Direhorn",
        source = "Drop: Horridon|nZone: Throne of Thunder",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1201] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 276,
                    level = 1
                },
                [2] =                 {
                    id = 908,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 564,
                    level = 2
                },
                [2] =                 {
                    id = 906,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 779,
                    level = 4
                },
                [2] =                 {
                    id = 909,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 70098,
        description = "Some Pandaren believe G'nathus to be an ancient Zandalari Loa left behind to guard the waters south of Lei Shen's island citadel.",
        familyType = 0,
        name = "Spawn of G'nathus",
        source = "Drop: G'nathus|nZone: Townlong Steppes",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1202] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 112,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 514,
                    level = 2
                },
                [2] =                 {
                    id = 369,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 581,
                    level = 4
                },
                [2] =                 {
                    id = 936,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 7.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 70144,
        description = "Deadly offspring of the Ancient Mother, Ji-Kun Hatchlings are considered sacred treasures in many cultures.",
        familyType = 5,
        name = "Ji-Kun Hatchling",
        source = "Drop: Ji-Kun|nZone: Throne of Thunder",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1204] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 943,
                    level = 1
                },
                [2] =                 {
                    id = 942,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 527,
                    level = 2
                },
                [2] =                 {
                    id = 945,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 941,
                    level = 4
                },
                [2] =                 {
                    id = 580,
                    level = 20
                }            }
        },
        availableBreeds = {"S/B"},
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 70082,
        description = "Every cook's dream wrapped up in a perfect bundle of metal and bolts. Too bad what he cooks up isn't suitable for humanoid consumption. According to Jard's notes, he intends to make this little guy for his friend, Emily Cole.",
        familyType = 8,
        name = "Pierre",
        source = "Profession: Engineering|n",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [1205] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 958,
                    level = 1
                },
                [2] =                 {
                    id = 377,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 571,
                    level = 2
                },
                [2] =                 {
                    id = 163,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 920,
                    level = 4
                },
                [2] =                 {
                    id = 960,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P",
            "H/S",
            "P/B"
        },
        baseStats =         {
            health = 8.25,
            power = 8,
            speed = 7.75
        },
        canBattle = true,
        creatureId = 70154,
        description = "The Zandalari breed specific Direhorn species for their small size for use as mounts.",
        familyType = 1,
        name = "Direhorn Runt",
        source = "Drop: Direhorns|nZone: Isle of Giants|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1206] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 230,
                    level = 2
                },
                [2] =                 {
                    id = 922,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 513,
                    level = 4
                },
                [2] =                 {
                    id = 315,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 70257,
        description = "The red scales on these fish are believed to be a warning to predators of the Townlong Steppes and the Dread Wastes that their flesh is toxic. Dedicated fishermen can sometimes befriend one.",
        familyType = 0,
        name = "Tiny Red Carp",
        source = "Profession: Fishing",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [1207] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 509,
                    level = 1
                },
                [2] =                 {
                    id = 483,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 922,
                    level = 2
                },
                [2] =                 {
                    id = 592,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 297,
                    level = 4
                },
                [2] =                 {
                    id = 489,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 70258,
        description = "These little guys can be found in the waters of the Timeless Isle, or swimming alongside Jewel Danio or Redbelly Mandarin. Dedicated fishermen can sometimes befriend one.",
        familyType = 0,
        name = "Tiny Blue Carp",
        source = "Profession: Fishing",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [1208] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 230,
                    level = 2
                },
                [2] =                 {
                    id = 922,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 513,
                    level = 4
                },
                [2] =                 {
                    id = 259,
                    level = 20
                }            }
        },
        availableBreeds = {"S/B"},
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 70259,
        description = "It is believed that the green coloration and stripes on the tiny green carp serve as camouflage in the waters of the Jade Forest, Valley of the Four Winds and the Krasarang Wilds. Dedicated fishermen can sometimes befriend one.",
        familyType = 0,
        name = "Tiny Green Carp",
        source = "Profession: Fishing",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [1209] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 230,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 564,
                    level = 4
                },
                [2] =                 {
                    id = 922,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 70260,
        description = "These hardy fish can survive in a wide range of climates, from the snow capped mountains of Kun-Lai Summit to the temperate, salty waters of the oceans around Pandaria. Dedicated fishermen can sometimes befriend one.",
        familyType = 0,
        name = "Tiny White Carp",
        source = "Profession: Fishing|n",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [1211] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 921,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 920,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 538,
                    level = 4
                },
                [2] =                 {
                    id = 919,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "S/S",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 70451,
        description = "These tiny minions of Zandalar are adept at stowing away within the cargo holds of the enormous Zandalari warships.",
        familyType = 1,
        name = "Zandalari Anklerender",
        source = "Drop: Zandalari Dinomancer|nZone: Isle Of Giants",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1212] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 921,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 920,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 917,
                    level = 4
                },
                [2] =                 {
                    id = 305,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "S/S",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 70452,
        description = "Even at this size, these raptors can eviscerate an entire cow in less than 10 seconds.",
        familyType = 1,
        name = "Zandalari Footslasher",
        source = "Drop: Zandalari Dinomancer|nZone: Isle Of Giants",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1213] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 193,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 364,
                    level = 2
                },
                [2] =                 {
                    id = 920,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 917,
                    level = 4
                },
                [2] =                 {
                    id = 919,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "S/S",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 70453,
        description = "These adorable beasts are both cuddly and huggable, provided you do not enjoy having a face.",
        familyType = 1,
        name = "Zandalari Toenibbler",
        source = "Drop: Zandalari Dinomancer|nZone: Isle Of Giants",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1226] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 158,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 314,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 362,
                    level = 4
                },
                [2] =                 {
                    id = 535,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "S/S",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 71014,
        description = "The oft-forgotten offspring of the Big Bad Wolf, found gorged and asleep in a basket of sweets.",
        familyType = 6,
        name = "Lil' Bad Wolf",
        source = "Drop: The Big Bad Wolf|nZone: Karazhan",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1227] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 116,
                    level = 1
                },
                [2] =                 {
                    id = 389,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 646,
                    level = 2
                },
                [2] =                 {
                    id = 390,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 301,
                    level = 4
                },
                [2] =                 {
                    id = 209,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 71015,
        description = "Primary responsibilities include dusting Medivh's many magical artifacts, an activity which has claimed the life, sanity, or physical composition of the many caretakers preceding Moroes.",
        familyType = 8,
        name = "Menagerie Custodian",
        source = "Drop: The Curator|nZone: Karazhan",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1228] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 406,
                    level = 1
                },
                [2] =                 {
                    id = 178,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 409,
                    level = 2
                },
                [2] =                 {
                    id = 282,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 407,
                    level = 4
                },
                [2] =                 {
                    id = 466,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "H/H",
            "P/S"
        },
        baseStats =         {
            health = 8,
            power = 8.25,
            speed = 7.75
        },
        canBattle = true,
        creatureId = 71016,
        description = "Upon leaving Netherspace, Malchezaar's Abyssals become strangely distorted by Karazhan's magical protections, rendering them tiny, and much less likely to spontaneously erupt in flames.",
        familyType = 7,
        name = "Netherspace Abyssal",
        source = "Drop: Prince Malchezaar|nZone: Karazhan",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1229] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 763,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 409,
                    level = 2
                },
                [2] =                 {
                    id = 503,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 567,
                    level = 4
                },
                [2] =                 {
                    id = 466,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 7.75,
            power = 8,
            speed = 8.25
        },
        canBattle = true,
        creatureId = 71033,
        description = "A minion of Terestian Illhoof, this tricky imp was left in Karazhan when the portal to the Twisting Nether closed behind it.",
        familyType = 6,
        name = "Fiendish Imp",
        source = "Drop: Terestian Illhoof|nZone: Karazhan",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1230] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 406,
                    level = 1
                },
                [2] =                 {
                    id = 249,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 419,
                    level = 2
                },
                [2] =                 {
                    id = 532,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 350,
                    level = 4
                },
                [2] =                 {
                    id = 418,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 8.25,
            power = 8.25,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 71017,
        description = "An astounding find for the scientific community of Azeroth, who have long pondered, often in taverns, what a baby Sea Giant might look like.",
        familyType = 0,
        name = "Tideskipper",
        source = "Drop: Morogrim Tidewalker|nZone: Serpentshrine Cavern",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1231] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 445,
                    level = 1
                },
                [2] =                 {
                    id = 380,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 369,
                    level = 2
                },
                [2] =                 {
                    id = 447,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 123,
                    level = 4
                },
                [2] =                 {
                    id = 448,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/B",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 71018,
        description = "The spawn of Hydross, considered by the elemental community to be the Earl of Puddles.\"\"",
        familyType = 4,
        name = "Tainted Waveling",
        source = "Drop: Hydross the Unstable|nZone: Serpentshrine Cavern",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1232] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 482,
                    level = 1
                },
                [2] =                 {
                    id = 473,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 323,
                    level = 2
                },
                [2] =                 {
                    id = 465,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 593,
                    level = 4
                },
                [2] =                 {
                    id = 488,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/B",
            "H/B"
        },
        baseStats =         {
            health = 7.75,
            power = 8.25,
            speed = 8
        },
        canBattle = true,
        creatureId = 71019,
        description = "It is unknown how Lady Vashj empowers these Fen Striders with their mind-bending powers; even at an early age this creature shows significant psychic ability.",
        familyType = 7,
        name = "Coilfang Stalker",
        source = "Drop: Lady Vashj|nZone: Serpentshrine Cavern",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1233] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 384,
                    level = 1
                },
                [2] =                 {
                    id = 202,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 278,
                    level = 2
                },
                [2] =                 {
                    id = 644,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 901,
                    level = 4
                },
                [2] =                 {
                    id = 208,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "H/H",
            "H/P",
            "P/S"
        },
        baseStats =         {
            health = 8.25,
            power = 8.5,
            speed = 7.25
        },
        canBattle = true,
        creatureId = 71020,
        description = "Sent through the Twisting Nether by the great Archimonde the Defiler to terrorize tiny civilizations with their medium-sized stomping noises.",
        familyType = 8,
        name = "Pocket Reaver",
        source = "Drop: Void Reaver|nZone: Tempest Keep|n|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1234] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 422,
                    level = 1
                },
                [2] =                 {
                    id = 608,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 212,
                    level = 2
                },
                [2] =                 {
                    id = 444,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 218,
                    level = 4
                },
                [2] =                 {
                    id = 486,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 8.25,
            power = 8,
            speed = 7.75
        },
        canBattle = true,
        creatureId = 71021,
        description = "The lanterns carried by Voidcallers bridge the realms of the living and the dead, and often attract wayward ghosts and spirits.",
        familyType = 7,
        name = "Lesser Voidcaller",
        source = "Drop: High Astromancer Solarian|nZone: Tempest Keep|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1235] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 429,
                    level = 1
                },
                [2] =                 {
                    id = 184,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 492,
                    level = 2
                },
                [2] =                 {
                    id = 515,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 501,
                    level = 4
                },
                [2] =                 {
                    id = 170,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "S/B",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 71022,
        description = "These brightly-colored dragonhawks carry Kael'thas' forces swiftly and unerringly through the nether storm surrounding the Eye.",
        familyType = 3,
        name = "Phoenix Hawk Hatchling",
        source = "Drop: Al'ar|nZone: Tempest Keep|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1236] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 355,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 800,
                    level = 2
                },
                [2] =                 {
                    id = 362,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 190,
                    level = 4
                },
                [2] =                 {
                    id = 578,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 7.5,
            power = 8.25,
            speed = 8.25
        },
        canBattle = true,
        creatureId = 71023,
        description = "Though generally an expert at taking stage direction, the show had to be stopped on more than one occasion when Tito and Roar would lock eyes, resulting in an extended chase around the Karazhan Opera House.",
        familyType = 1,
        name = "Tito",
        source = "Achievement: Raiding with Leashes II: Attunement Edition|nCategory: Collect",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [1237] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 424,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 538,
                    level = 2
                },
                [2] =                 {
                    id = 276,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 513,
                    level = 4
                },
                [2] =                 {
                    id = 418,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8.25,
            speed = 7.75
        },
        canBattle = true,
        creatureId = 71159,
        description = "The trolls have a long and storied history of summoning hydras. While he might not be the biggest or strongest hydra, Gahz'rooki will bite your fingers quite hard if you get too close.",
        familyType = 0,
        name = "Gahz'rooki",
        source = "Vendor: Ravika|nZone: Durotar|nCost: 1|TINTERFACE\\\\ICONS\\\\inv_drink_31_embalmingfluid:0|t|n|nVendor: Tenuki|nZone: Durotar|nCost: 1|TINTERFACE\\\\ICONS\\\\inv_drink_31_embalmingfluid:0|t",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [1238] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 210,
                    level = 1
                },
                [2] =                 {
                    id = 422,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 212,
                    level = 2
                },
                [2] =                 {
                    id = 218,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 652,
                    level = 4
                },
                [2] =                 {
                    id = 321,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H"
        },
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 71163,
        description = "Val'kyr are considered unborn\" until they vanquish a creature of high nobility.\"",
        familyType = 9,
        name = "Unborn Val'kyr",
        source = "Pet Battle: Northrend",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1243] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 445,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 447,
                    level = 2
                },
                [2] =                 {
                    id = 369,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 450,
                    level = 4
                },
                [2] =                 {
                    id = 957,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 71199,
        description = "The dark pools in Primordius' chamber laid stagnant after the fall of the mogu, and murky thoughts began to coalesce.",
        familyType = 7,
        name = "Living Fluid",
        source = "Drop: Primordius|nZone: Throne of Thunder|nDifficulty: Looking For Raid|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1244] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 445,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 447,
                    level = 2
                },
                [2] =                 {
                    id = 657,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 450,
                    level = 4
                },
                [2] =                 {
                    id = 957,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 71200,
        description = "These malicious oozes are highly sensitive to Primordius' pheromone signature.",
        familyType = 7,
        name = "Viscous Horror",
        source = "Drop: Primordius|nZone: Throne of Thunder|nDifficulty: Normal or Heroic|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1245] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 668,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 527,
                    level = 2
                },
                [2] =                 {
                    id = 450,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 447,
                    level = 4
                },
                [2] =                 {
                    id = 448,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 71201,
        description = "Battle pet trainers are strongly encouraged to wash their hands for at least 30 minutes after playing with the filthling.",
        familyType = 7,
        name = "Filthling",
        source = "Drop: Quivering Filth",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1256] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 1021,
                    level = 1
                },
                [2] =                 {
                    id = 1022,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 1020,
                    level = 2
                },
                [2] =                 {
                    id = 1026,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 1025,
                    level = 4
                },
                [2] =                 {
                    id = 1024,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/B",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 71693,
        description = "This little guy seems to like to hang out at the fringes of cataclysmic events. There is no evidence to suggest he has anything to do with the cause of these events, though - he's probably just an observer. Or maybe he just gets lost on his trek to other places.",
        familyType = 8,
        name = "Rascal-Bot",
        source = "Profession: Engineering|n",
        sourceTypeEnum = 3,
        tradeable = true,
        unique = false
    },
    [1266] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 974,
                    level = 1
                },
                [2] =                 {
                    id = 110,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 1016,
                    level = 2
                },
                [2] =                 {
                    id = 595,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 997,
                    level = 4
                },
                [2] =                 {
                    id = 536,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 8,
            power = 8.25,
            speed = 7.75
        },
        canBattle = true,
        creatureId = 71942,
        description = "Fierce and loyal, Xu-Fu loves to hunt by moonlight.  Once during a full moon, he killed and ate an entire Ironfur Great Bull, prompting a two day nap.",
        familyType = 1,
        name = "Xu-Fu, Cub of Xuen",
        source = "Vendor: Tournament of Celestials",
        sourceTypeEnum = 2,
        tradeable = false,
        unique = true
    },
    [1276] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 978,
                    level = 1
                },
                [2] =                 {
                    id = 110,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 362,
                    level = 2
                },
                [2] =                 {
                    id = 165,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 979,
                    level = 4
                },
                [2] =                 {
                    id = 980,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 72160,
        description = "Moonfang's cubs grow into massive, slavering, black-furred killing machines...except for Moon Moon.",
        familyType = 1,
        name = "Moon Moon",
        source = "Drop: Moonfang|nZone: Darkmoon Island",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1303] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 1027,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 254,
                    level = 2
                },
                [2] =                 {
                    id = 592,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 998,
                    level = 4
                },
                [2] =                 {
                    id = 568,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8.25,
            power = 8.25,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 72462,
        description = "Chi-Chi tries to inspires hope with her loud squawk and by chasing, and eventually eating, butterflies.",
        familyType = 5,
        name = "Chi-Chi, Hatchling of Chi-Ji",
        source = "Vendor: Master Li|nZone: Timeless Isle|nCost: 3|TINTERFACE\\\\ICONS\\\\INV_MISC_TRINKETPANDA_07:0|t",
        sourceTypeEnum = 2,
        tradeable = false,
        unique = true
    },
    [1304] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 115,
                    level = 1
                },
                [2] =                 {
                    id = 1031,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 597,
                    level = 2
                },
                [2] =                 {
                    id = 1032,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 170,
                    level = 4
                },
                [2] =                 {
                    id = 277,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 7,
            power = 8.5,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 72463,
        description = "A master sculptor devoted her life to creating an incomparably beatufiul statue, inspired by her love and reverence for Yu'lon.  When the sculptor passed away, Yu'lon breathed a fraction of her essence into the statue, bringing Yu'la into the world.",
        familyType = 3,
        name = "Yu'la, Broodling of Yu'lon",
        source = "Vendor: Master Li|nZone: Timeless Isle|nCost: 3|TINTERFACE\\\\ICONS\\\\INV_MISC_TRINKETPANDA_07:0|t",
        sourceTypeEnum = 2,
        tradeable = false,
        unique = true
    },
    [1305] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 377,
                    level = 1
                },
                [2] =                 {
                    id = 1095,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 376,
                    level = 2
                },
                [2] =                 {
                    id = 273,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 1019,
                    level = 4
                },
                [2] =                 {
                    id = 1029,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8.5,
            power = 8,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 72464,
        description = "Always on the lookout for a fight or some tasty grass, Zao keeps his head down and eyes forward.",
        familyType = 1,
        name = "Zao, Calfling of Niuzao",
        source = "Vendor: Tournament of Celestials",
        sourceTypeEnum = 2,
        tradeable = false,
        unique = true
    },
    [1320] =     {
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 73011,
        description = "This handsome little robot is the spitting image of his Dad\"",
        familyType = 8,
        name = "Lil' Bling",
        source = "Drop: Blingtron Gift Package|n",
        tradeable = true,
        unique = false
    },
    [1321] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 184,
                    level = 1
                },
                [2] =                 {
                    id = 581,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 230,
                    level = 2
                },
                [2] =                 {
                    id = 922,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 186,
                    level = 4
                },
                [2] =                 {
                    id = 509,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "S/S",
            "H/P",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8.5,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 73534,
        description = "Crane chicks of the Timeless Isle sometimes sing a curious song that calms the nerves and soothes the soul.",
        familyType = 5,
        name = "Azure Crane Chick",
        source = "Drop: Crane Nest|nZone: Timeless Isle",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1322] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 116,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 647,
                    level = 2
                },
                [2] =                 {
                    id = 1041,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 282,
                    level = 4
                },
                [2] =                 {
                    id = 1025,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "H/H",
            "H/P"
        },
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 73352,
        description = "The first bombling created in the Underhold, Siegecrafter Blackfuse couldn't bear to see it destroyed, and kept it as a friendly, if explosive, pet.",
        familyType = 8,
        name = "Blackfuse Bombling",
        source = "Drop: Siegecrafter Blackfuse|nRaid: Siege of Orgrimmar",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1323] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 630,
                    level = 1
                },
                [2] =                 {
                    id = 111,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 753,
                    level = 2
                },
                [2] =                 {
                    id = 592,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 400,
                    level = 4
                },
                [2] =                 {
                    id = 318,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "S/S",
            "P/B",
            "S/B"
        },
        baseStats =         {
            health = 7.5,
            power = 8.25,
            speed = 8.25
        },
        canBattle = true,
        creatureId = 73533,
        description = "The Ashleaf Sprites of the Timeless Isle tirelessly protect the vegetation of the island from the burning fury of Ordos and his minions.",
        familyType = 6,
        name = "Ashleaf Spriteling",
        source = "Drop: Leafmender|nZone: Timeless Isle|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1324] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 504,
                    level = 1
                },
                [2] =                 {
                    id = 514,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 1040,
                    level = 2
                },
                [2] =                 {
                    id = 506,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 507,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S",
            "H/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 73542,
        description = "Jinyu assassins employ this moth as both a portable decoy and a light source to reveal weak spots in their enemy's armor.",
        familyType = 5,
        name = "Ashwing Moth",
        source = "Pet Battle: Timeless Isle|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1325] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 504,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 168,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 1040,
                    level = 4
                },
                [2] =                 {
                    id = 508,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 73543,
        description = "Cats and other curious critters often have short-lived play sessions with this moth that end with a face full of singed hair.",
        familyType = 5,
        name = "Flamering Moth",
        source = "Pet Battle: Timeless Isle|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1326] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 420,
                    level = 1
                },
                [2] =                 {
                    id = 186,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 506,
                    level = 2
                },
                [2] =                 {
                    id = 308,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 508,
                    level = 4
                },
                [2] =                 {
                    id = 204,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/S",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 73368,
        description = "This curious moth is sometimes found interrupting the spells of a wandering mage or warlock.",
        familyType = 5,
        name = "Skywisp Moth",
        source = "Pet Battle: Timeless Isle|n",
        sourceTypeEnum = 4,
        tradeable = false,
        unique = false
    },
    [1328] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 756,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 564,
                    level = 2
                },
                [2] =                 {
                    id = 934,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 657,
                    level = 4
                },
                [2] =                 {
                    id = 1043,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 73356,
        description = "The waters of Ruby Lake are colored a strange reddish hue, possibly due to the ruby crystals found deep within the mountains of the Timeless Isle.",
        familyType = 4,
        name = "Ruby Droplet",
        source = "Drop: Garnia|nZone: Timeless Isle",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1329] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 110,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 1047,
                    level = 2
                },
                [2] =                 {
                    id = 1045,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 307,
                    level = 4
                },
                [2] =                 {
                    id = 366,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "P/S",
            "H/S",
            "S/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 73532,
        description = "While fascinated by flowers, the frolicker has also been known to dance with blades of grass and the occasional weed.",
        familyType = 6,
        name = "Dandelion Frolicker",
        source = "Drop: Scary Sprite|nZone: Timeless Isle|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1330] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 152,
                    level = 1
                },
                [2] =                 {
                    id = 156,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 1050,
                    level = 2
                },
                [2] =                 {
                    id = 165,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 159,
                    level = 4
                },
                [2] =                 {
                    id = 1049,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "P/P",
            "S/S",
            "H/H",
            "P/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 73364,
        description = "Late in life, if the environmental conditions are correct, a Death Adder may shed its skin and undergo a transformation into an Imperial Python.",
        familyType = 1,
        name = "Death Adder Hatchling",
        source = "Drop: Imperial Python|nZone: Timeless Isle",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1331] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 447,
                    level = 1
                },
                [2] =                 {
                    id = 276,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 1051,
                    level = 2
                },
                [2] =                 {
                    id = 450,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 668,
                    level = 4
                },
                [2] =                 {
                    id = 218,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "P/S",
            "P/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 73350,
        description = "A small remnant of the power of Y'shaarj that spawned the Sha, a single Drop of Y'shaarj can magnify emotional states for thousands of yards, causing entire towns to shut down in fear or doubt.",
        familyType = 4,
        name = "Droplet of Y'Shaarj",
        source = "Drop: Sha of Pride|nRaid: Siege of Orgrimmar|nDifficulty: Flexible, Normal or Heroic",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1332] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 1056,
                    level = 1
                },
                [2] =                 {
                    id = 448,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 256,
                    level = 2
                },
                [2] =                 {
                    id = 1055,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 468,
                    level = 4
                },
                [2] =                 {
                    id = 214,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "S/S",
            "H/H"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 73351,
        description = "Sha-lings reflect the emotional state of their handler, becoming agitated, depressed, fearful, or doubtful depending on the magnitude of negative thoughts around them.",
        familyType = 4,
        name = "Gooey Sha-ling",
        source = "Drop: Sha of Pride|nRaid: Siege of Orgrimmar|nDifficulty: LFR and Flexible",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1333] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 1060,
                    level = 1
                },
                [2] =                 {
                    id = 432,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 431,
                    level = 2
                },
                [2] =                 {
                    id = 1062,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 1051,
                    level = 4
                },
                [2] =                 {
                    id = 418,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "S/S",
            "P/S",
            "H/S"
        },
        baseStats =         {
            health = 7.75,
            power = 8.5,
            speed = 7.75
        },
        canBattle = true,
        creatureId = 73355,
        description = "The Jademist Dancers of the Timeless Isle have a curious attraction to the steam vents of the northwestern shore.",
        familyType = 4,
        name = "Jademist Dancer",
        source = "Drop: Jademist Dancer|nZone: Timeless Isle",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1334] =     {
        availableBreeds = {
            "H/H",
            "H/P",
            "H/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 73354,
        description = "The tiny terror of the Dread Wastes, Kovok prefers a steady diet of brain food:\" mushan brains",
        familyType = 1,
        name = "Kovok",
        source = "Drop: Paragons of the Klaxxi|nRaid: Siege of Orgrimmar|n",
        tradeable = true,
        unique = false
    },
    [1335] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 1066,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 1040,
                    level = 2
                },
                [2] =                 {
                    id = 172,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 179,
                    level = 4
                },
                [2] =                 {
                    id = 1068,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 73357,
        description = "The odd blue flames found within the Cavern of Lost Spirits have led many unwary adventurers to their doom.",
        familyType = 4,
        name = "Ominous Flame",
        source = "Drop: Foreboding Flame|nZone: Timeless Isle|n|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1336] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 1008,
                    level = 1
                },
                [2] =                 {
                    id = 354,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 572,
                    level = 2
                },
                [2] =                 {
                    id = 1070,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 1010,
                    level = 4
                },
                [2] =                 {
                    id = 1072,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/H",
            "H/P",
            "H/S",
            "H/B"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 73367,
        description = "When the village of Pi'jiu was attacked by the Ordon Yaungol generations ago, the villagers bravely erected a keg in the center of the village. The following morning, after the celebration had died down, the still-drunken Yaungol blearily agreed to a peace treaty.",
        familyType = 4,
        name = "Skunky Alemental",
        source = "Drop: Zhu-Gon the Sour|nZone: Timeless Isle|n|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1337] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 803,
                    level = 1
                },
                [2] =                 {
                    id = 355,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 1073,
                    level = 2
                },
                [2] =                 {
                    id = 123,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 513,
                    level = 4
                },
                [2] =                 {
                    id = 423,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "H/H"
        },
        baseStats =         {
            health = 7.5,
            power = 9,
            speed = 7.5
        },
        canBattle = true,
        creatureId = 73366,
        description = "Spineclaw crabs of Pandaria have existed for thousands of years and remain one of the continent's oldest creatures.",
        familyType = 0,
        name = "Spineclaw Crab",
        source = "Drop: Monstrous Spineclaw|nZone: Timeless Isle|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1338] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 233,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 572,
                    level = 2
                },
                [2] =                 {
                    id = 1087,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 706,
                    level = 4
                },
                [2] =                 {
                    id = 663,
                    level = 20
                }            }
        },
        availableBreeds = {
            "B/B",
            "H/P",
            "H/B"
        },
        baseStats =         {
            health = 8.5,
            power = 7.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 73359,
        description = "Gulp frogs of the Timeless Isle can feast upon prey several times larger than themselves by slowly digesting the victim externally with a toxic slime.",
        familyType = 0,
        name = "Gulp Froglet",
        source = "Drop: Bufo|nPet Battle: Timeless Isle",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1343] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 219,
                    level = 1
                },
                [2] =                 {
                    id = 110,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 1054,
                    level = 2
                },
                [2] =                 {
                    id = 312,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 762,
                    level = 4
                },
                [2] =                 {
                    id = 1052,
                    level = 20
                }            }
        },
        availableBreeds = {
            "P/P",
            "S/S",
            "H/P",
            "P/S",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 73668,
        description = "Some young and rambunctious hozen are trained from an early age to use boxing gloves so they don't accidentally kill their tribe members, and more importantly, to keep them from picking their noses.",
        familyType = 6,
        name = "Bonkers",
        source = "Drop: Kukuru Chest|nZone: Timeless Isle",
        sourceTypeEnum = 0,
        tradeable = false,
        unique = false
    },
    [1344] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 110,
                    level = 1
                },
                [2] =                 {
                    id = 566,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 914,
                    level = 2
                },
                [2] =                 {
                    id = 283,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 193,
                    level = 4
                },
                [2] =                 {
                    id = 997,
                    level = 20
                }            }
        },
        availableBreeds = {"H/P"},
        baseStats =         {
            health = 8.25,
            power = 8,
            speed = 7.75
        },
        canBattle = true,
        creatureId = 73688,
        description = "One of the beasts left on the Timeless Isle when it shifted through time, most likely sacrificed by the Ordon to their demigod, Ordos.",
        familyType = 1,
        name = "Vengeful Porcupette",
        source = "Vendor: Speaker Gulan|nZone: Timeless Isle",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [1345] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 367,
                    level = 1
                },
                [2] =                 {
                    id = 706,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 369,
                    level = 2
                },
                [2] =                 {
                    id = 541,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 160,
                    level = 4
                },
                [2] =                 {
                    id = 159,
                    level = 20
                }            }
        },
        availableBreeds = {
            "H/H",
            "H/S"
        },
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 73730,
        description = "Swarmlings of Gu'chi spin an ancient, and very powerful, form of silk that has not been seen in Pandaria in ages.",
        familyType = 2,
        name = "Gu'chi Swarmling",
        source = "Drop: Gu'chi the Swarmbringer|nZone: Timeless Isle",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1346] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 429,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 1032,
                    level = 2
                },
                [2] =                 {
                    id = 595,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 247,
                    level = 4
                },
                [2] =                 {
                    id = 254,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 73732,
        description = "Prolonged exposure to Shaohao's tranquil mists has calmed these spirits, which act as peaceful companions to the Mistweavers.",
        familyType = 7,
        name = "Harmonious Porcupette",
        source = "Vendor: Mistweaver Ku|nZone: Timeless Isle|nFaction: Shaohao - Pathwalker",
        sourceTypeEnum = 2,
        tradeable = true,
        unique = false
    },
    [1348] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 1082,
                    level = 1
                },
                [2] =                 {
                    id = 432,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 597,
                    level = 2
                },
                [2] =                 {
                    id = 178,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 168,
                    level = 4
                },
                [2] =                 {
                    id = 1084,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 73738,
        description = "The Jadefire Spirit is thought to be a living embodiment of Yu'lon's own jade breath.",
        familyType = 4,
        name = "Jadefire Spirit",
        source = "Drop: Spirit of Jadefire|nZone: Timeless Isle|n|n",
        sourceTypeEnum = 0,
        tradeable = true,
        unique = false
    },
    [1349] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 1079,
                    level = 1
                },
                [2] =                 {
                    id = 413,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 1080,
                    level = 2
                },
                [2] =                 {
                    id = 624,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 1076,
                    level = 4
                },
                [2] =                 {
                    id = 206,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 7.75,
            power = 8.25,
            speed = 8
        },
        canBattle = true,
        creatureId = 73741,
        description = "Fed up with long hours, low pay, and entitled adventurers whining about sub-standard Winter Veil gifts, these nasty little creatures fled their magical workshops to join up with the Abominable Greench.",
        familyType = 6,
        name = "Rotten Little Helper",
        source = "World Event: Feast of Winter Veil|n",
        sourceTypeEnum = 1,
        tradeable = true,
        unique = false
    },
    [1350] =     {
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = false,
        creatureId = 73809,
        description = "A candle inside of the kite heats the air, causing it to rise into the air without the need for wind.",
        familyType = 5,
        name = "Sky Lantern",
        source = "Vendor: Ku-Mo|nZone: Timeless Isle",
        sourceTypeEnum = 2,
        tradeable = false,
        unique = false
    },
    [4211] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 493,
                    level = 1
                },
                [2] =                 {
                    id = 499,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 578,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 252,
                    level = 4
                },
                [2] =                 {
                    id = 376,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 23114,
        description = "Lucky squeals when he's angry or when he's eating. Either way, you don't want to bother him.",
        familyType = 2,
        name = "Lucky",
        source = "Promotion |nWorld Wide Invitational 2007",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [4233] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 424,
                    level = 1
                },
                [2] =                 {
                    id = 118,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 298,
                    level = 2
                },
                [2] =                 {
                    id = 934,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 273,
                    level = 4
                },
                [2] =                 {
                    id = 404,
                    level = 20
                }            }
        },
        availableBreeds = {"H/B"},
        baseStats =         {
            health = 8,
            power = 8,
            speed = 8
        },
        canBattle = true,
        creatureId = 181485,
        description = "Flurky carries a sunflower close to her heart, spreading peace and unity wherever she waddles.",
        familyType = 6,
        name = "Flurky",
        source = "Promotion |nPet Pack for Ukraine",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [4234] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 118,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 436,
                    level = 2
                },
                [2] =                 {
                    id = 564,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 628,
                    level = 4
                },
                [2] =                 {
                    id = 624,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8.625,
            power = 7.625,
            speed = 7.75
        },
        canBattle = true,
        creatureId = 194870,
        description = "A peculiar penguin with a penchant for pebbles.",
        familyType = 0,
        name = "Pebble",
        source = "Promotion |nNorthrend Heroic/Epic Upgrade",
        sourceTypeEnum = 7,
        tradeable = true,
        unique = true
    },
    [4235] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 421,
                    level = 1
                },
                [2] =                 {
                    id = 360,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 979,
                    level = 2
                },
                [2] =                 {
                    id = 980,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 273,
                    level = 4
                },
                [2] =                 {
                    id = 589,
                    level = 20
                }            }
        },
        availableBreeds = {"S/S"},
        baseStats =         {
            health = 7.5,
            power = 7.5,
            speed = 9
        },
        canBattle = true,
        creatureId = 196534,
        description = "Because it's her favorite holiday, Hoplet wears her Lunar Festival outfit year-round.",
        familyType = 7,
        name = "Hoplet",
        source = "Promotion |n6-Month WoW Subscription (2023)",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [4236] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 118,
                    level = 1
                },
                [2] =                 {
                    id = 509,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 230,
                    level = 2
                },
                [2] =                 {
                    id = 511,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 297,
                    level = 4
                },
                [2] =                 {
                    id = 273,
                    level = 20
                }            }
        },
        availableBreeds = {"H/S"},
        baseStats =         {
            health = 8.25,
            power = 7.5,
            speed = 8.25
        },
        canBattle = true,
        creatureId = 200900,
        description = "A bubbly goldfish who's always ready to make a splash!",
        familyType = 0,
        name = "Glub",
        source = "Promotion |n6-Month WoW Subscription (2023)",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [4273] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 2538,
                    level = 1
                },
                [2] =                 {
                    id = 122,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 268,
                    level = 2
                },
                [2] =                 {
                    id = 347,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 190,
                    level = 4
                },
                [2] =                 {
                    id = 404,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8.5,
            power = 7.75,
            speed = 7.75
        },
        canBattle = true,
        creatureId = 211012,
        description = "Cypress soars with the wisdom of forests and the fire of celebration.",
        familyType = 3,
        name = "Cypress",
        source = "Promotion |n6-Month WoW Subscription (2024)",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [4274] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 122,
                    level = 1
                },
                [2] =                 {
                    id = 501,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 440,
                    level = 2
                },
                [2] =                 {
                    id = 256,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 169,
                    level = 4
                },
                [2] =                 {
                    id = 640,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 7.25,
            power = 9.5,
            speed = 7.25
        },
        canBattle = true,
        creatureId = 211025,
        description = "Don't let the tiny wings fool you. He is already scheming, sulking, and setting things on fire.",
        familyType = 3,
        name = "Lil' Wrathion",
        source = "Promotion |nCataclysm Classic Blazing Heroic Pack",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [4329] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 648,
                    level = 1
                },
                [2] =                 {
                    id = 2532,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 2530,
                    level = 2
                },
                [2] =                 {
                    id = 624,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 2531,
                    level = 4
                },
                [2] =                 {
                    id = 2533,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 7.5,
            power = 8.5,
            speed = 8
        },
        canBattle = true,
        creatureId = 213605,
        description = "There must always be a Lick King.",
        familyType = 9,
        name = "Arfus",
        source = "Achievement: Defense Protocol Gamma: Terminated|nAchievement: Dungeons & Raids|n",
        sourceTypeEnum = 5,
        tradeable = false,
        unique = true
    },
    [4532] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 2534,
                    level = 1
                },
                [2] =                 {
                    id = 2535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 1121,
                    level = 2
                },
                [2] =                 {
                    id = 2536,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 934,
                    level = 4
                },
                [2] =                 {
                    id = 310,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 8.75,
            power = 8,
            speed = 7.25
        },
        canBattle = true,
        creatureId = 222858,
        description = "Everything you own will eventually belong to Pinchy. What, are you really going to argue with those claws?",
        familyType = 0,
        name = "Pinchy the Plunderer",
        source = "Special Event: Plunderstorm",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [4585] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 112,
                    level = 1
                },
                [2] =                 {
                    id = 184,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 206,
                    level = 2
                },
                [2] =                 {
                    id = 170,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 517,
                    level = 4
                },
                [2] =                 {
                    id = 413,
                    level = 20
                }            }
        },
        availableBreeds = {"P/B"},
        baseStats =         {
            health = 7.5,
            power = 7.5,
            speed = 9
        },
        canBattle = true,
        creatureId = 224065,
        description = "This wise watcher of the winter woods is a hoot to adventure with!",
        familyType = 5,
        name = "Swoopy",
        source = "Promotion |n6-Month WoW Subscription (2024)",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [4683] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 119,
                    level = 1
                },
                [2] =                 {
                    id = 535,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 165,
                    level = 2
                },
                [2] =                 {
                    id = 252,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 568,
                    level = 4
                },
                [2] =                 {
                    id = 2537,
                    level = 20
                }            }
        },
        availableBreeds = {"P/S"},
        baseStats =         {
            health = 7.5,
            power = 8,
            speed = 8.5
        },
        canBattle = true,
        creatureId = 232527,
        description = "The game's afoot. Except when it is time to nap. Afterwards though, it's game on!",
        familyType = 1,
        name = "Reven",
        source = "Promotion |nCureDuchenne Special Promotion",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    },
    [4685] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 113,
                    level = 1
                },
                [2] =                 {
                    id = 424,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 173,
                    level = 2
                },
                [2] =                 {
                    id = 170,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 204,
                    level = 4
                },
                [2] =                 {
                    id = 1045,
                    level = 20
                }            }
        },
        availableBreeds = {
            "S/S",
            "P/S"
        },
        baseStats =         {
            health = 7.5,
            power = 8.325,
            speed = 8.175
        },
        canBattle = true,
        creatureId = 232536,
        description = "Crafted from sacred timber and blessed by festive winds.",
        familyType = 5,
        name = "Timbered Air Snakelet",
        source = "Promotion |n6-Month WoW Subscription (2025)",
        sourceTypeEnum = 7,
        tradeable = true,
        unique = true
    },
    [4734] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 421,
                    level = 1
                },
                [2] =                 {
                    id = 449,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 298,
                    level = 2
                },
                [2] =                 {
                    id = 1047,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 589,
                    level = 4
                },
                [2] =                 {
                    id = 752,
                    level = 20
                }            }
        },
        availableBreeds = {"P/P"},
        baseStats =         {
            health = 7.875,
            power = 9,
            speed = 7.125
        },
        canBattle = true,
        creatureId = 237248,
        description = "A rare Sha born of hope, radiating happiness instead of despair.",
        familyType = 4,
        name = "Joyous",
        source = "Promotion |nMists of Pandaria Classic Heroic Pack",
        sourceTypeEnum = 7,
        tradeable = true,
        unique = true
    },
    [4850] =     {
        abilities =         {
            [0] = {
                [1] =                 {
                    id = 803,
                    level = 1
                },
                [2] =                 {
                    id = 110,
                    level = 10
                }            },
            [1] = {
                [1] =                 {
                    id = 509,
                    level = 2
                },
                [2] =                 {
                    id = 463,
                    level = 15
                }            },
            [2] = {
                [1] =                 {
                    id = 920,
                    level = 4
                },
                [2] =                 {
                    id = 423,
                    level = 20
                }            }
        },
        availableBreeds = {"B/B"},
        baseStats =         {
            health = 8.5,
            power = 8.5,
            speed = 7
        },
        canBattle = true,
        creatureId = 245603,
        description = "According to Tol'vir beliefs, a crocolisk nest that hatches during the Festival of the Sun is said to be blessed by the river guardian, Sa'bak.",
        familyType = 0,
        name = "Sa'bak's Favored",
        source = "Promotion |nv6-Month WoW Subscription (2025)",
        sourceTypeEnum = 7,
        tradeable = false,
        unique = true
    }
}

-- Register with dataStore for static/SV merging
if Addon.registerModule then
    Addon.registerModule("speciesData", {"dataStore"}, function()
        Addon.dataStore:registerEntityType({
            typeName = "species",
            svName = "pao_species",
            staticKey = "species",
            needsPets = false
        })
        return true
    end)
end

-- Register SavedVariable for export
if Addon.registerModule then
    Addon.registerModule("species_export", {"exports"}, function()
        if Addon.exports then
            Addon.exports:register("species", function()
                return pao_species
            end)
        end
        return true
    end)
end