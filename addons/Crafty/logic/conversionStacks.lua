--[[
  logic/conversionStacks.lua
  Conversion Stack Locator

  Milling and prospecting consume a stack of exactly CAST_SIZE from one bag
  slot, and the secure button that casts them needs that slot as attributes
  (spell + target-bag + target-slot) before the click, not after. This module
  answers "where is a castable stack of item X" - read live from the bags at
  every ask, because slot positions churn with every loot, move, and split;
  a cached slot is a wrong slot.

  Usage:
    local bag, slot = conversionStacks:find(itemID)   -- nil when none is castable
    conversionStacks:casts(itemID)                    -- how many casts the bags hold

  Dependencies: none (reads the container API)
  Exports: Addon.conversionStacks
]]

local ADDON_NAME, Addon = ...

local conversionStacks = {}

-- Both verbs consume five at a time.
local CAST_SIZE = 5

-- The first bag slot holding a castable stack of the item: bag, slot. A
-- partial stack cannot be cast on its own, so slots below CAST_SIZE are not
-- candidates even though they hold the item.
function conversionStacks:find(itemID)
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID == itemID and (info.stackCount or 0) >= CAST_SIZE then
                return bag, slot
            end
        end
    end
    return nil
end

-- How many casts the bags hold for this item. Stacks convert individually, so
-- the total is the sum of what each stack can give, not the item total split
-- five ways: four slots of four are four wasted stacks, not three casts.
function conversionStacks:casts(itemID)
    local total = 0
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.itemID == itemID then
                total = total + math.floor((info.stackCount or 0) / CAST_SIZE)
            end
        end
    end
    return total
end

function conversionStacks:castSize() return CAST_SIZE end

function conversionStacks:initialize()
    return true
end

Addon.conversionStacks = conversionStacks

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("conversionStacks", {}, function()
        return conversionStacks:initialize()
    end)
end

return conversionStacks
