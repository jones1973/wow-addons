--[[
  data/dbRecipeCooldown_mop.lua
  Crafty recipe cooldowns - GENERATED, do not hand-edit.

  Source: SkillLineAbility + SpellCooldowns + SpellCategories + SpellCategory
  DB2 (wago.tools). Regenerate after a patch per design/patch-day.md.

  Each entry: [recipeID] = { hours=, flags=, sharedCat= }  -- Meow
    hours     - rolling cooldown length in hours; 0 for a daily regional reset
                (a daily reset is a wall-clock boundary, not an N-hour countdown;
                the flag carries that and the client computes time to next reset).
    flags     - bitmask:
                  0x1 (CD_DAILY_RESET) - resets at the regional daily boundary
                  0x2 (CD_SHARED)      - shares one timer with its category
    sharedCat - the shared cooldown-category id; 0 when not shared. Recipes with
                the same non-zero sharedCat share ONE timer: crafting any one
                puts the others on cooldown (e.g. the 42 transmutes share 310).
  A recipe's absence from this table means it has no cooldown by nature.

  Dependencies: none (plain data table)
  Exports: Addon.dbRecipeCooldown
]]

local ADDON_NAME, Addon = ...

Addon.data = Addon.data or {}
Addon.data.dbRecipeCooldown = {
  [11479] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Iron to Gold
  [11480] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Mithril to Truesilver
  [17559] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Air to Fire
  [17560] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Fire to Earth
  [17561] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Earth to Water
  [17562] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Water to Air
  [17563] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Undeath to Water
  [17564] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Water to Undeath
  [17565] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Life to Earth
  [17566] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Earth to Life
  [28027] = {hours=48.0, flags=2, sharedCat=1174},  -- Prismatic Sphere
  [28028] = {hours=48.0, flags=2, sharedCat=1174},  -- Void Sphere
  [28566] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Primal Air to Fire
  [28567] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Primal Earth to Water
  [28568] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Primal Fire to Earth
  [28569] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Primal Water to Air
  [28580] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Primal Shadow to Water
  [28581] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Primal Water to Shadow
  [28582] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Primal Mana to Fire
  [28583] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Primal Fire to Mana
  [28584] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Primal Life to Earth
  [28585] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Primal Earth to Life
  [47280] = {hours=20.0, flags=0, sharedCat=0},  -- Brilliant Glass
  [53771] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Eternal Life to Shadow
  [53773] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Eternal Life to Fire
  [53774] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Eternal Fire to Water
  [53775] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Eternal Fire to Life
  [53776] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Eternal Air to Water
  [53777] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Eternal Air to Earth
  [53779] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Eternal Shadow to Earth
  [53780] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Eternal Shadow to Life
  [53781] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Eternal Earth to Air
  [53782] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Eternal Earth to Shadow
  [53783] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Eternal Water to Air
  [53784] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Eternal Water to Fire
  [54020] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Eternal Might
  [56005] = {hours=0, flags=3, sharedCat=1285},  -- Glacial Bag
  [60893] = {hours=0, flags=3, sharedCat=1274},  -- Northrend Alchemy Research
  [61177] = {hours=0, flags=3, sharedCat=1276},  -- Northrend Inscription Research
  [61288] = {hours=0, flags=3, sharedCat=1275},  -- Minor Inscription Research
  [66658] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Ametrine
  [66659] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Cardinal Ruby
  [66660] = {hours=0, flags=3, sharedCat=310},  -- Transmute: King's Amber
  [66662] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Dreadstone
  [66663] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Majestic Zircon
  [66664] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Eye of Zul
  [73478] = {hours=0, flags=3, sharedCat=1291},  -- Fire Prism
  [75141] = {hours=0, flags=3, sharedCat=1278},  -- Dream of Skywall
  [75142] = {hours=0, flags=3, sharedCat=1281},  -- Dream of Deepholm
  [75144] = {hours=0, flags=3, sharedCat=1282},  -- Dream of Hyjal
  [75145] = {hours=0, flags=3, sharedCat=1280},  -- Dream of Ragnaros
  [75146] = {hours=0, flags=3, sharedCat=1279},  -- Dream of Azshara
  [78866] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Living Elements
  [80244] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Pyrium Bar
  [86654] = {hours=0, flags=3, sharedCat=1267},  -- Forged Documents
  [89244] = {hours=0, flags=3, sharedCat=1267},  -- Forged Documents
  [112996] = {hours=0, flags=3, sharedCat=1339},  -- Scroll of Wisdom
  [114780] = {hours=0, flags=3, sharedCat=310},  -- Transmute: Living Steel
  [116499] = {hours=0, flags=3, sharedCat=1357},  -- Sha Crystal
  [125557] = {hours=0, flags=3, sharedCat=1402},  -- Imperial Silk
  [131593] = {hours=0, flags=3, sharedCat=1409},  -- River's Heart
  [131686] = {hours=0, flags=3, sharedCat=1409},  -- Primordial Ruby
  [131688] = {hours=0, flags=3, sharedCat=1409},  -- Wild Jade
  [131690] = {hours=0, flags=3, sharedCat=1409},  -- Vermilion Onyx
  [131691] = {hours=0, flags=3, sharedCat=1409},  -- Imperial Amethyst
  [131695] = {hours=0, flags=3, sharedCat=1409},  -- Sun's Radiance
  [138646] = {hours=0, flags=3, sharedCat=1433},  -- Lightning Steel Ingot
  [139176] = {hours=0, flags=3, sharedCat=1438},  -- Jard's Peculiar Energy Source
  [140040] = {hours=0, flags=3, sharedCat=1434},  -- Magnificence of Leather
  [140041] = {hours=0, flags=3, sharedCat=1434},  -- Magnificence of Scales
  [140050] = {hours=0, flags=3, sharedCat=1436},  -- Serpent's Heart
  [142976] = {hours=0, flags=3, sharedCat=1441},  -- Hardened Magnificent Hide
  [143011] = {hours=0, flags=3, sharedCat=1442},  -- Celestial Cloth
  [143255] = {hours=0, flags=3, sharedCat=1443},  -- Balanced Trillium Ingot
}
