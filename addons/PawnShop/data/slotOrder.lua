--[[
  data/slotOrder.lua
  Slot Grouping and Display Order

  Maps equipLoc strings (from GetItemInfoInstant) to display position and
  group name. The position is used as primary sort so the grid groups items
  top-to-bottom in natural gear order: Head, Neck, Shoulder, Back, etc.

  Pair rows (synthesized MH+OH combinations) use PAIR_SLOT_RANK = 16, which
  places them between the individual MH/OH groups (rank 14-15) and Ranged
  (rank 17).

  Dependencies: none (pure data)
  Exports: Addon.data.slotOrder
           Addon.data.slotDefault
           Addon.data.pairSlotRank
           Addon.data.pairSlotName
]]

local ADDON_NAME, Addon = ...

Addon.data = Addon.data or {}

Addon.data.slotOrder = {
    INVTYPE_HEAD           = {  1, "Head" },
    INVTYPE_NECK           = {  2, "Neck" },
    INVTYPE_SHOULDER       = {  3, "Shoulder" },
    INVTYPE_CLOAK          = {  4, "Back" },
    INVTYPE_BACK           = {  4, "Back" },
    INVTYPE_CHEST          = {  5, "Chest" },
    INVTYPE_ROBE           = {  5, "Chest" },
    INVTYPE_WRIST          = {  6, "Wrist" },
    INVTYPE_HAND           = {  7, "Hands" },
    INVTYPE_WAIST          = {  8, "Waist" },
    INVTYPE_LEGS           = {  9, "Legs" },
    INVTYPE_FEET           = { 10, "Feet" },
    INVTYPE_FINGER         = { 11, "Finger" },
    INVTYPE_TRINKET        = { 12, "Trinket" },
    INVTYPE_2HWEAPON       = { 13, "Two-Hand" },
    INVTYPE_WEAPON         = { 14, "Main Hand" },
    INVTYPE_WEAPONMAINHAND = { 14, "Main Hand" },
    INVTYPE_WEAPONOFFHAND  = { 15, "Off Hand" },
    INVTYPE_HOLDABLE       = { 15, "Off Hand" },
    INVTYPE_SHIELD         = { 15, "Off Hand" },
    -- Rank 16 reserved for synthesized pair rows.
    INVTYPE_RANGED         = { 17, "Ranged" },
    INVTYPE_RANGEDRIGHT    = { 17, "Ranged" },
    INVTYPE_THROWN         = { 17, "Ranged" },
    INVTYPE_RELIC          = { 17, "Relic" },
}

Addon.data.slotDefault  = { 99, "Other" }
Addon.data.pairSlotRank = 16
Addon.data.pairSlotName = "Pair"  -- UI will rename to "Two-Piece" at display

return Addon.data
