--[[
  data/dbRecipeCooldown_tbc.lua
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
  [11479] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Iron to Gold
  [11480] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Mithril to Truesilver
  [17559] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Air to Fire
  [17560] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Fire to Earth
  [17561] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Earth to Water
  [17562] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Water to Air
  [17563] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Undeath to Water
  [17564] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Water to Undeath
  [17565] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Life to Earth
  [17566] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Earth to Life
  [26751] = {hours=92.0, flags=0, sharedCat=0},  -- Primal Mooncloth
  [28027] = {hours=48.0, flags=2, sharedCat=1174},  -- Prismatic Sphere
  [28028] = {hours=48.0, flags=2, sharedCat=1174},  -- Void Sphere
  [28566] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Primal Air to Fire
  [28567] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Primal Earth to Water
  [28568] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Primal Fire to Earth
  [28569] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Primal Water to Air
  [28580] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Primal Shadow to Water
  [28581] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Primal Water to Shadow
  [28582] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Primal Mana to Fire
  [28583] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Primal Fire to Mana
  [28584] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Primal Life to Earth
  [28585] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Primal Earth to Life
  [29688] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Primal Might
  [31373] = {hours=92.0, flags=0, sharedCat=0},  -- Spellcloth
  [32765] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Earthstorm Diamond
  [32766] = {hours=20.0, flags=2, sharedCat=310},  -- Transmute: Skyfire Diamond
  [36686] = {hours=92.0, flags=0, sharedCat=0},  -- Shadowcloth
  [47280] = {hours=20.0, flags=0, sharedCat=0},  -- Brilliant Glass
}
