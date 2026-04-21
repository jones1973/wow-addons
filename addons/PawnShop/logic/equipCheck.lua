--[[
  logic/equipCheck.lua
  Class/Item Equip Eligibility

  Answers "can this class equip this item?" using the static proficiency
  tables in Addon.data. Pure predicate; no side effects, no Pawn, no state.

  Used as a pre-filter before evaluation so we don't waste Pawn calls on
  items the character fundamentally can't wear.

  Dependencies: constants
  Exports: Addon.equipCheck
]]

local ADDON_NAME, Addon = ...

local equipCheck = {}

-- Module references
local constants

-- ============================================================================
-- CAN EQUIP
-- ============================================================================

--[[
  Returns true if this class can equip items of the given (classID, subclassID).

  classID must be ITEM_CLASS_ARMOR or ITEM_CLASS_WEAPON by this point --
  callers should filter non-gear out beforehand.

  For armor: subclassID 0 (Misc: rings, necks, cloaks, trinkets, off-hand
  held) is always allowed regardless of class.

  @param playerClass string - uppercase class token from UnitClass("player")
  @param classID number - Blizzard item classID
  @param subclassID number - Blizzard item subclassID
  @return boolean
]]
function equipCheck:canEquipType(playerClass, classID, subclassID)
    if classID == constants.ITEM_CLASS_ARMOR then
        if subclassID == 0 then return true end
        local prof = Addon.data.armorProficiency[playerClass]
        return (prof and prof[subclassID]) and true or false
    elseif classID == constants.ITEM_CLASS_WEAPON then
        local prof = Addon.data.weaponProficiency[playerClass]
        return (prof and prof[subclassID]) and true or false
    end
    return false
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function equipCheck:initialize()
    constants = Addon.constants

    if not constants then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444equipCheck: Missing constants|r")
        return false
    end

    if not Addon.data or not Addon.data.armorProficiency or not Addon.data.weaponProficiency then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444equipCheck: Missing proficiency data|r")
        return false
    end

    return true
end

if Addon.registerModule then
    Addon.registerModule("equipCheck", {"constants"}, function()
        return equipCheck:initialize()
    end)
end

Addon.equipCheck = equipCheck
return equipCheck
