-- Crafty augment verbs (mop (design/merge_recipe_data.py))
--
-- [skillLine] = "verb" - what this profession calls modifying an item,
-- from SkillLine.AlternateVerb_lang, so it arrives in the player's
-- language. Used for recipes whose effect augments rather than creates;
-- see emit_craft_verbs.
local _, Addon = ...
Addon.data = Addon.data or {}
Addon.data.augmentVerbs = {
  [164] = "Modify",   -- Blacksmithing
  [165] = "Emboss",   -- Leatherworking
  [171] = "Refill",   -- Alchemy
  [197] = "Embroider",   -- Tailoring
  [202] = "Tinker",   -- Engineering
  [333] = "Enchant",   -- Enchanting
  [755] = "Modify",   -- Jewelcrafting
  [773] = "Inscribe",   -- Inscription
}
