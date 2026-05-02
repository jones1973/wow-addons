--[[
  data/slotOrder.lua
  Slot Grouping and Display Order

  Maps equipLoc strings (from GetItemInfoInstant) to display position and
  group name. The position is used as primary sort so the grid groups items
  top-to-bottom in natural gear order: Head, Neck, Shoulder, Back, etc.

  INVTYPE_FINGER and INVTYPE_TRINKET are NOT in slotOrder. They're multi-
  instance slots (two of them equipped at once) and get handled separately
  via multiInstanceSlots below, which produces per-equipped-slot rows
  ("Ring 1" vs "Ring 2") with slot-specific upgrade percentages.

  Pair rows (synthesized MH+OH combinations) use PAIR_SLOT_RANK = 18, which
  places them between the individual MH/OH groups (rank 16-17) and Ranged
  (rank 19).

  Dependencies: none (pure data)
  Exports: Addon.data.slotOrder
           Addon.data.slotDefault
           Addon.data.pairSlotRank
           Addon.data.pairSlotName
           Addon.data.multiInstanceSlots
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
    -- Ranks 11-14 reserved for multi-instance ring/trinket rows; see
    -- multiInstanceSlots below.
    INVTYPE_2HWEAPON       = { 15, "Two-Hand" },
    INVTYPE_WEAPON         = { 16, "Main Hand" },
    INVTYPE_WEAPONMAINHAND = { 16, "Main Hand" },
    INVTYPE_WEAPONOFFHAND  = { 17, "Off Hand" },
    INVTYPE_HOLDABLE       = { 17, "Off Hand" },
    INVTYPE_SHIELD         = { 17, "Off Hand" },
    -- Rank 18 reserved for synthesized pair rows.
    INVTYPE_RANGED         = { 19, "Ranged" },
    INVTYPE_RANGEDRIGHT    = { 19, "Ranged" },
    INVTYPE_THROWN         = { 19, "Ranged" },
    INVTYPE_RELIC          = { 19, "Relic" },
}

Addon.data.slotDefault  = { 99, "Other" }
Addon.data.pairSlotRank = 18
Addon.data.pairSlotName = "Pair"  -- UI will rename to "Two-Piece" at display

-- ============================================================================
-- MULTI-INSTANCE SLOTS (rings, trinkets, and dual-wielded 1H weapons)
-- ============================================================================

--[[
  Slots where the character equips two items of the same equipLoc. An
  auction item for these slots produces ONE ROW PER EQUIPPED SLOT it
  actually upgrades -- "Ring 1" and "Ring 2" are separate filter tabs
  with slot-specific comparisons.

  Each entry's slotID is the Blizzard INVSLOT_* constant used with
  GetInventoryItemLink to fetch the currently-equipped item for comparison:
    INVSLOT_FINGER1 = 11, INVSLOT_FINGER2  = 12
    INVSLOT_TRINKET1 = 13, INVSLOT_TRINKET2 = 14

  The display ranks (11-14) fit between Feet (10) and Two-Hand (15),
  preserving natural gear order in the tab strip.

  INVTYPE_WEAPON (1H ambidextrous) is multi-instance only for dual-wield
  classes -- for those, the item can beat MH or OH independently. Eval
  filters this in based on canDualWield[playerClass] at eval-start time;
  the weaponsDualWield table below is the template applied only when DW
  is true. Non-DW classes fall through to single-instance MH-only via
  equipLocToInvSlot. Because weapon multi-instance slots produce rows
  stamped with slotName="Main Hand"/"Off Hand", the rows land in the
  existing MH/OH tabs rather than producing new tab labels the way
  rings produce "Ring 1"/"Ring 2".
]]
Addon.data.multiInstanceSlots = {
    INVTYPE_FINGER = {
        { slotID = 11, rank = 11, name = "Ring 1" },
        { slotID = 12, rank = 12, name = "Ring 2" },
    },
    INVTYPE_TRINKET = {
        { slotID = 13, rank = 13, name = "Trinket 1" },
        { slotID = 14, rank = 14, name = "Trinket 2" },
    },
}

--[[
  Template for weapon multi-instance entries. eval:start merges this
  into a per-eval copy of multiInstanceSlots ONLY for dual-wield-capable
  classes, keyed on INVTYPE_WEAPON. Ranks 16/17 match the existing MH/OH
  ranks in slotOrder so rows flow into the existing tabs in natural order.
]]
Addon.data.weaponsDualWield = {
    INVTYPE_WEAPON = {
        { slotID = 16, rank = 16, name = "Main Hand" },
        { slotID = 17, rank = 17, name = "Off Hand"  },
    },
}

-- ============================================================================
-- EQUIPLOC -> INVENTORY SLOT (for equipped-item lookups)
-- ============================================================================

--[[
  Maps a single-instance equipLoc to the Blizzard INVSLOT_* constant used
  with GetInventoryItemLink. Eval consults this when stamping equippedLink
  on a promoted row so the panel can show "<equipped item>" in the slot
  tab tooltip.

  Multi-instance slots (FINGER, TRINKET, and WEAPON-for-DW-classes) are
  resolved through multiInstanceSlots instead -- this map handles the
  single-instance fallback case.

  Notes on weapons:
    INVTYPE_WEAPONMAINHAND -> 16 (always MH-only by spec)
    INVTYPE_WEAPONOFFHAND  -> 17 (class proficiency gate already
                                   excluded non-DW classes from these)
    INVTYPE_WEAPON         -> 16 (for non-DW classes; DW classes route
                                   through multiInstanceSlots instead)
    INVTYPE_2HWEAPON       -> 16 (two-hand displaces whatever's in OH)
    INVTYPE_HOLDABLE,
    INVTYPE_SHIELD         -> 17

  INVSLOT constants:
    HEAD=1 NECK=2 SHOULDER=3 BACK=15 CHEST=5 WRIST=9 HAND=10
    WAIST=6 LEGS=7 FEET=8 MAINHAND=16 OFFHAND=17 RANGED=18
]]
Addon.data.equipLocToInvSlot = {
    INVTYPE_HEAD           =  1,
    INVTYPE_NECK           =  2,
    INVTYPE_SHOULDER       =  3,
    INVTYPE_CLOAK          = 15,
    INVTYPE_BACK           = 15,
    INVTYPE_CHEST          =  5,
    INVTYPE_ROBE           =  5,
    INVTYPE_WRIST          =  9,
    INVTYPE_HAND           = 10,
    INVTYPE_WAIST          =  6,
    INVTYPE_LEGS           =  7,
    INVTYPE_FEET           =  8,
    INVTYPE_WEAPON         = 16,
    INVTYPE_WEAPONMAINHAND = 16,
    INVTYPE_2HWEAPON       = 16,
    INVTYPE_WEAPONOFFHAND  = 17,
    INVTYPE_HOLDABLE       = 17,
    INVTYPE_SHIELD         = 17,
    INVTYPE_RANGED         = 18,
    INVTYPE_RANGEDRIGHT    = 18,
    INVTYPE_THROWN         = 18,
    INVTYPE_RELIC          = 18,
}

return Addon.data
