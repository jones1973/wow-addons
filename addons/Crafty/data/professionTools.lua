--[[
  data/professionTools.lua
  Crafty profession tool actions.

  A "tool action" is a portable station the player triggers from the crafting
  window (place an anvil, build a campfire). Two normalized tables:

    toolActions[id] = kind   -- the tool's kind ("spell" | "item"), keyed by the
                                id we always start from. kind selects the
                                availability check and trigger mechanism; the
                                user never sees it.
    professionTools[skillLine] = { id, ... }  -- which tool(s) a profession uses,
                                by reference. A tool shared by two professions
                                (the anvil) is defined once and referenced twice.

  No per-flavor split and no stored names: the availability check self-filters by
  client (an id absent on a client is simply never available - e.g. the MoP-only
  Thermal Anvil reads as "no item in bags" on TBC), and names/icons are derived
  from the id at display time so they cannot drift and are correctly localized.

  Thermal Anvil (item 87216) places an anvil and forge - Blacksmithing and
  Engineering. Basic Campfire (spell 818) - Cooking.

  Exports: Addon.toolActions, Addon.professionTools
]]

local ADDON_NAME, Addon = ...

Addon.data = Addon.data or {}
Addon.data.toolActions = {
    [87216] = "item",    -- Thermal Anvil (places anvil + forge)
    [818]   = "spell",   -- Basic Campfire
    [38682] = "target",  -- Enchanting Vellum: not an action but a spell
                         -- TARGET - it only does anything while a cast is
                         -- awaiting one
}

Addon.data.professionTools = {
    [164] = { 87216 },   -- Blacksmithing
    [202] = { 87216 },   -- Engineering
    [185] = { 818 },     -- Cooking
    [333] = { 38682 },   -- Enchanting
}
