-- Crafty profession tier unlocks (Wowhead-sourced, tbc)
-- [skillLine] = { {rank=learnRank, spell=spellID}, ... } ascending
local _, Addon = ...
Addon.data = Addon.data or {}
Addon.data.professionTiers = {
  [129] = {  -- First Aid
    {rank=1, spell=3273},
    {rank=50, spell=3274},
    {rank=125, spell=7924},
    {rank=200, spell=10846},
    {rank=275, spell=27028},
  },
  [164] = {  -- Blacksmithing
    {rank=1, spell=2018},
    {rank=50, spell=3100},
    {rank=125, spell=3538},
    {rank=200, spell=9785},
    {rank=275, spell=29844},
  },
  [165] = {  -- Leatherworking
    {rank=1, spell=2108},
    {rank=50, spell=3104},
    {rank=125, spell=3811},
    {rank=200, spell=10662},
    {rank=275, spell=32549},
  },
  [171] = {  -- Alchemy
    {rank=1, spell=2259},
    {rank=50, spell=3101},
    {rank=125, spell=3464},
    {rank=200, spell=11611},
    {rank=275, spell=28596},
  },
  [185] = {  -- Cooking
    {rank=1, spell=2550},
    {rank=50, spell=3102},
    {rank=125, spell=3413},
    {rank=200, spell=18260},
    {rank=275, spell=33359},
  },
  [186] = {  -- Mining
    {rank=1, spell=2575},
    {rank=50, spell=2576},
    {rank=125, spell=3564},
    {rank=200, spell=10248},
    {rank=275, spell=29354},
  },
  [197] = {  -- Tailoring
    {rank=1, spell=3908},
    {rank=50, spell=3909},
    {rank=125, spell=3910},
    {rank=200, spell=12180},
    {rank=275, spell=26790},
  },
  [202] = {  -- Engineering
    {rank=1, spell=4036},
    {rank=50, spell=4037},
    {rank=125, spell=4038},
    {rank=200, spell=12656},
    {rank=275, spell=30350},
  },
  [333] = {  -- Enchanting
    {rank=1, spell=7411},
    {rank=50, spell=7412},
    {rank=125, spell=7413},
    {rank=200, spell=13920},
    {rank=275, spell=28029},
  },
  [755] = {  -- Jewelcrafting
    {rank=1, spell=25229},
    {rank=50, spell=25230},
    {rank=125, spell=28894},
    {rank=200, spell=28895},
    {rank=275, spell=28897},
  },
}
