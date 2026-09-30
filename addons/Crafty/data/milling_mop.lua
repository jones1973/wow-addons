--[[
  data/milling_mop.lua
  Milling conversion table (design/merge_recipe_data.py, 2026-08-31)

  What only sampling knows: which results a source can yield, and how
  often. Eligibility and required skill are NOT here - the client
  declares both at runtime.

  [sourceItemID] = { { id, chance (0-1, INDEPENDENT per-cast presence -
  not a distribution), tier = "primary"|"proc", qty = {min,max} per proc
  when known }, ... } sorted best-first
]]

local ADDON_NAME, Addon = ...

Addon.data = Addon.data or {}
Addon.data.milling = {
    [765] = { { id = 39151, chance = 0.9982, tier = "primary", qty = { 2, 4 } } }, -- Silverleaf
    [785] = { { id = 39334, chance = 0.9954, tier = "primary", qty = { 2, 3 } }, { id = 43103, chance = 0.2145, tier = "proc", qty = { 1, 3 } } }, -- Mageroyal
    [2447] = { { id = 39151, chance = 1.0, tier = "primary", qty = { 2, 3 } } }, -- Peacebloom
    [2449] = { { id = 39151, chance = 1.0, tier = "primary", qty = { 2, 4 } } }, -- Earthroot
    [2450] = { { id = 39334, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 43103, chance = 0.28, tier = "proc", qty = { 1, 3 } } }, -- Briarthorn
    [2452] = { { id = 39334, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 43103, chance = 0.2808, tier = "proc", qty = { 1, 2 } } }, -- Swiftthistle
    [2453] = { { id = 39334, chance = 0.9997, tier = "primary", qty = { 2, 4 } }, { id = 43103, chance = 0.4748, tier = "proc", qty = { 1, 3 } } }, -- Bruiseweed
    [3355] = { { id = 39338, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 43104, chance = 0.2624, tier = "proc", qty = { 1, 3 } } }, -- Wild Steelbloom
    [3356] = { { id = 39338, chance = 0.9965, tier = "primary", qty = { 2, 4 } }, { id = 43104, chance = 0.5514, tier = "proc", qty = { 1, 3 } } }, -- Kingsblood
    [3357] = { { id = 39338, chance = 0.9864, tier = "primary", qty = { 2, 4 } }, { id = 43104, chance = 0.4534, tier = "proc", qty = { 1, 3 } } }, -- Liferoot
    [3358] = { { id = 39339, chance = 0.9959, tier = "primary", qty = { 3, 4 } }, { id = 43105, chance = 0.4215, tier = "proc", qty = { 1, 3 } } }, -- Khadgar's Whisker
    [3369] = { { id = 39338, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 43104, chance = 0.3265, tier = "proc", qty = { 1, 3 } } }, -- Grave Moss
    [3818] = { { id = 39339, chance = 0.9928, tier = "primary", qty = { 2, 3 } }, { id = 43105, chance = 0.2341, tier = "proc", qty = { 1, 3 } } }, -- Fadeleaf
    [3819] = { { id = 39339, chance = 0.9584, tier = "primary", qty = { 3, 4 } }, { id = 43105, chance = 0.4324, tier = "proc", qty = { 1, 2 } } }, -- Dragon's Teeth
    [3820] = { { id = 39334, chance = 0.986, tier = "primary", qty = { 2, 4 } }, { id = 43103, chance = 0.3988, tier = "proc", qty = { 1, 2 } } }, -- Stranglekelp
    [3821] = { { id = 39339, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 43105, chance = 0.2963, tier = "proc", qty = { 1, 1 } } }, -- Goldthorn
    [4625] = { { id = 39340, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 43106, chance = 0.2383, tier = "proc", qty = { 1, 1 } } }, -- Firebloom
    [8831] = { { id = 39340, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 43106, chance = 0.3856, tier = "proc", qty = { 1, 1 } } }, -- Purple Lotus
    [8836] = { { id = 39340, chance = 1.0, tier = "primary", qty = { 3, 3 } } }, -- Arthas' Tears
    [8838] = { { id = 39340, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 43106, chance = 0.2209, tier = "proc", qty = { 1, 2 } } }, -- Sungrass
    [8839] = { { id = 39340, chance = 0.939, tier = "primary", qty = { 2, 4 } }, { id = 43106, chance = 0.5426, tier = "proc", qty = { 1, 1 } } }, -- Blindweed
    [8845] = { { id = 39340, chance = 1.0, tier = "primary", qty = { 2, 4 } }, { id = 43106, chance = 0.7113, tier = "proc", qty = { 1, 1 } } }, -- Ghost Mushroom
    [8846] = { { id = 39340, chance = 0.9815, tier = "primary", qty = { 2, 4 } }, { id = 43106, chance = 0.641, tier = "proc", qty = { 1, 3 } } }, -- Gromsblood
    [13463] = { { id = 39341, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 43107, chance = 0.2189, tier = "proc", qty = { 1, 3 } } }, -- Dreamfoil
    [13464] = { { id = 39341, chance = 0.9832, tier = "primary", qty = { 2, 3 } }, { id = 43107, chance = 0.2862, tier = "proc", qty = { 1, 3 } } }, -- Golden Sansam
    [13465] = { { id = 39341, chance = 0.9752, tier = "primary", qty = { 2, 4 } }, { id = 43107, chance = 0.5508, tier = "proc", qty = { 1, 3 } } }, -- Mountain Silversage
    [13466] = { { id = 39341, chance = 0.9803, tier = "primary", qty = { 2, 4 } }, { id = 43107, chance = 0.5622, tier = "proc", qty = { 1, 3 } } }, -- Sorrowmoss
    [13467] = { { id = 39341, chance = 1.0, tier = "primary", qty = { 2, 4 } }, { id = 43107, chance = 0.4761, tier = "proc", qty = { 1, 3 } } }, -- Icecap
    [22785] = { { id = 39342, chance = 0.9826, tier = "primary", qty = { 2, 3 } }, { id = 43108, chance = 0.1889, tier = "proc", qty = { 1, 3 } } }, -- Felweed
    [22786] = { { id = 39342, chance = 0.9912, tier = "primary", qty = { 2, 3 } }, { id = 43108, chance = 0.3134, tier = "proc", qty = { 1, 3 } } }, -- Dreaming Glory
    [22787] = { { id = 39342, chance = 0.9774, tier = "primary", qty = { 2, 3 } }, { id = 43108, chance = 0.3733, tier = "proc", qty = { 1, 1 } } }, -- Ragveil
    [22789] = { { id = 39342, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 43108, chance = 0.2041, tier = "proc", qty = { 1, 3 } } }, -- Terocone
    [22790] = { { id = 39342, chance = 0.9555, tier = "primary", qty = { 2, 4 } }, { id = 43108, chance = 0.5023, tier = "proc", qty = { 1, 1 } }, { id = 39343, chance = 0.0211, tier = "proc", qty = { 2, 2 } } }, -- Ancient Lichen
    [22791] = { { id = 39342, chance = 1.0, tier = "primary", qty = { 2, 4 } }, { id = 43108, chance = 0.4767, tier = "proc", qty = { 1, 1 } } }, -- Netherbloom
    [22792] = { { id = 39342, chance = 1.0, tier = "primary", qty = { 2, 4 } }, { id = 43108, chance = 0.4844, tier = "proc", qty = { 1, 3 } } }, -- Nightmare Vine
    [22793] = { { id = 39342, chance = 1.0, tier = "primary", qty = { 2, 4 } }, { id = 43108, chance = 0.4494, tier = "proc", qty = { 1, 1 } } }, -- Mana Thistle
    [36901] = { { id = 39343, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 43109, chance = 0.1897, tier = "proc", qty = { 1, 3 } } }, -- Goldclover
    [36903] = { { id = 39343, chance = 1.0, tier = "primary", qty = { 2, 4 } }, { id = 43109, chance = 0.3969, tier = "proc", qty = { 1, 3 } } }, -- Adder's Tongue
    [36904] = { { id = 39343, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 43109, chance = 0.2247, tier = "proc", qty = { 1, 2 } } }, -- Tiger Lily
    [36905] = { { id = 39343, chance = 1.0, tier = "primary", qty = { 2, 4 } }, { id = 43109, chance = 0.4822, tier = "proc", qty = { 1, 3 } } }, -- Lichbloom
    [36906] = { { id = 39343, chance = 1.0, tier = "primary", qty = { 2, 4 } }, { id = 43109, chance = 0.5905, tier = "proc", qty = { 1, 3 } } }, -- Icethorn
    [36907] = { { id = 39343, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 43109, chance = 0.2471, tier = "proc", qty = { 1, 3 } } }, -- Talandra's Rose
    [37921] = { { id = 39343, chance = 0.9904, tier = "primary", qty = { 2, 3 } }, { id = 43109, chance = 0.2885, tier = "proc", qty = { 1, 3 } } }, -- Deadnettle
    [39970] = { { id = 39343, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 43109, chance = 0.2438, tier = "proc", qty = { 1, 3 } } }, -- Fire Leaf
    [52983] = { { id = 61979, chance = 0.9886, tier = "primary", qty = { 2, 3 } }, { id = 61980, chance = 0.2187, tier = "proc", qty = { 1, 3 } } }, -- Cinderbloom
    [52984] = { { id = 61979, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 61980, chance = 0.119, tier = "proc", qty = { 1, 1 } } }, -- Stormvine
    [52985] = { { id = 61979, chance = 1.0, tier = "primary", qty = { 2, 3 } }, { id = 61980, chance = 0.321, tier = "proc", qty = { 1, 3 } } }, -- Azshara's Veil
    [52986] = { { id = 61979, chance = 0.9831, tier = "primary", qty = { 2, 3 } }, { id = 61980, chance = 0.2144, tier = "proc", qty = { 1, 1 } } }, -- Heartblossom
    [52987] = { { id = 61979, chance = 1.0, tier = "primary", qty = { 2, 4 } }, { id = 61980, chance = 0.4517, tier = "proc", qty = { 1, 2 } } }, -- Twilight Jasmine
    [52988] = { { id = 61979, chance = 0.9813, tier = "primary", qty = { 2, 4 } }, { id = 61980, chance = 0.3325, tier = "proc", qty = { 1, 1 } } }, -- Whiptail
    [72234] = { { id = 79251, chance = 0.9876, tier = "primary", qty = { 2, 3 } }, { id = 79253, chance = 0.2138, tier = "proc", qty = { 1, 3 } } }, -- Green Tea Leaf
    [72235] = { { id = 79251, chance = 0.9897, tier = "primary", qty = { 2, 4 } }, { id = 79253, chance = 0.2245, tier = "proc", qty = { 1, 3 } } }, -- Silkweed
    [72237] = { { id = 79251, chance = 0.9954, tier = "primary", qty = { 2, 3 } }, { id = 79253, chance = 0.2237, tier = "proc", qty = { 1, 3 } } }, -- Rain Poppy
    [79010] = { { id = 79251, chance = 0.9956, tier = "primary", qty = { 2, 3 } }, { id = 79253, chance = 0.221, tier = "proc", qty = { 1, 3 } } }, -- Snow Lily
    [79011] = { { id = 79251, chance = 0.9891, tier = "primary", qty = { 2, 4 } }, { id = 79253, chance = 0.4241, tier = "proc", qty = { 1, 3 } } }, -- Fool's Cap
    [87821] = { { id = 87828, chance = 1.0, tier = "primary", qty = { 2, 3 } } }, -- Coagulated Tiger's Blood
    [89639] = { { id = 79251, chance = 0.9906, tier = "primary", qty = { 2, 3 } }, { id = 79253, chance = 0.2653, tier = "proc", qty = { 1, 3 } } }, -- Desecrated Herb
}

return Addon.data.milling
