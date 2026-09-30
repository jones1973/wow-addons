--[[
  data/processingActivities_mop.lua
  Processing activities per profession (MoP)

  A processing activity applies an action to an input item to yield materials
  with probabilistic outcomes: milling herbs into pigments, prospecting ore
  into gems, disenchanting gear into enchanting materials. Each is unlocked by
  possessing a specific primary profession, but is NOT a recipe-list craft and
  does not appear among a profession's scanned recipes - so the fact "having
  this profession grants this processing activity" lives nowhere the client
  reports it, and is declared here.

  Keyed by the granting profession's skill-line id. Each entry names the
  processing verb (Crafty's internal key, matching the conversion engine's
  convertVerb and the data table in data/<verb>_mop.lua) and a stable id used
  for the activity's identity and persisted hidden/order state.

  Smelting is deliberately absent: it is a real trade-skill window with a
  recipe list (Mining's craftable side, opened via the Mining->Smelting spell
  override in professionHarvester), so it is a windowed profession activity,
  not a processing activity. Disenchanting, milling, and prospecting have no
  window - they cast at a bag slot.

  [grantingProfID] = { verb = <internal key>, id = <activity id>, order = <n> }

  Exports: Addon.data.processingActivities
]]

local ADDON_NAME, Addon = ...

Addon.data = Addon.data or {}
Addon.data.processingActivities = {
    [333] = { verb = "disenchanting", id = "proc:disenchanting", order = 1 },  -- Enchanting
    [773] = { verb = "milling",       id = "proc:milling",       order = 2 },  -- Inscription
    [755] = { verb = "prospecting",   id = "proc:prospecting",   order = 3 },  -- Jewelcrafting
}

return Addon.data.processingActivities
