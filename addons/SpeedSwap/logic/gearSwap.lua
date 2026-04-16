--[[
  logic/gearSwap.lua
  Mount Speed Gear Swap Logic

  Handles the actual item swaps: equipping speed trinkets on mount, restoring
  saved gear on dismount, swapping the swim belt on/off. Centralizes the
  "can we safely swap right now?" check because EquipItemByName misbehaves
  under specific conditions.

  Why not just call EquipItemByName directly from the caller?
  - In combat it's protected (throws ADDON_ACTION_BLOCKED on this client)
  - With vendor/bank/mail/trade/auction windows open, it can sell the item
    or put it on the cursor instead of equipping
  - The retry loop needs a single gated entry point so it can re-attempt
    without each caller duplicating the checks

  Exports: Addon.gearSwap
]]

local ADDON_NAME, Addon = ...

local gearSwap = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local TRINKET_SLOT = 13    -- Top trinket slot
local BOOTS_SLOT   = 8
local GLOVES_SLOT  = 10
local WAIST_SLOT   = 6

-- Mount speed trinkets. Value is the mount speed bonus percentage.
-- None of these stack with each other; the Crop/Whip 10% bonus also caps
-- out enchants (Mithril Spurs, Riding Skill), so those are only worth
-- equipping alongside Carrot.
local SPEED_TRINKETS = {
    [25653] = 10,  -- Riding Crop
    [32863] = 10,  -- Skybreaker Whip
    [11122] = 3,   -- Carrot on a Stick
}

local SWIM_BELT_ID = 7052  -- Azure Silk Belt (+15% swim speed)

-- Enchant IDs as they appear in item links (item:id:ENCHANT:...)
local ENCHANT_MITHRIL_SPURS = "464"  -- Boots, +4% mount speed
local ENCHANT_RIDING_SKILL  = "930"  -- Gloves, +2% mount speed

-- ============================================================================
-- BAG / GEAR LOOKUPS
-- ============================================================================

--[[
  Extract the enchant ID from an item link.

  @param link string|nil - Item link string (e.g., "|cff...|Hitem:1234:567:...")
  @return string|nil - Enchant ID as a string, or nil if no link or no enchant
]]
local function getEnchantFromLink(link)
    if not link then return nil end
    return link:match("item:%d+:(%d+)")
end

--[[
  Scan the player's bags for the highest-value speed trinket.

  @return number|nil, number - Item ID and bonus percentage, or nil if none found
]]
local function findBestSpeedTrinketInBags()
    local bestID, bestBonus = nil, 0
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID and SPEED_TRINKETS[itemID] and SPEED_TRINKETS[itemID] > bestBonus then
                bestID = itemID
                bestBonus = SPEED_TRINKETS[itemID]
            end
        end
    end
    return bestID, bestBonus
end

--[[
  Check whether a specific item ID exists anywhere in the player's bags.

  @param searchID number - Item ID to look for
  @return boolean
]]
local function hasItemInBags(searchID)
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            if C_Container.GetContainerItemID(bag, slot) == searchID then
                return true
            end
        end
    end
    return false
end

-- ============================================================================
-- SAFETY GATE
-- ============================================================================

--[[
  Determine whether EquipItemByName can be called safely right now.

  Blocks on two conditions:
  - InCombatLockdown: EquipItemByName is protected during combat on the
    TBC Anniversary client (modern client behavior, unlike original TBC)
  - Interaction frames: vendor/bank/mail/trade/auction windows cause the
    function to misbehave (sell item, place on cursor) rather than fail cleanly

  @return boolean
]]
function gearSwap:canSwapNow()
    if InCombatLockdown() then return false end
    if MerchantFrame and MerchantFrame:IsShown() then return false end
    if BankFrame    and BankFrame:IsShown()    then return false end
    if MailFrame    and MailFrame:IsShown()    then return false end
    if TradeFrame   and TradeFrame:IsShown()   then return false end
    if AuctionFrame and AuctionFrame:IsShown() then return false end
    return true
end

-- ============================================================================
-- DISPLAY HELPERS
-- ============================================================================

--[[
  Get the display name of an item by ID.

  @param itemID number|nil
  @return string - Item name from GetItemInfo, or "empty" if nil, or the ID as a string if uncached
]]
function gearSwap:getItemNameByID(itemID)
    if not itemID then return "empty" end
    local name = GetItemInfo(itemID)
    return name or tostring(itemID)
end

--[[
  Summarize the current trinket slot and saved restore ID.
  Used for diagnostic output on summons and status commands.

  @return string - Formatted "slot=NAME saved=NAME" string
]]
function gearSwap:trinketStateString()
    local equippedID = GetInventoryItemID("player", TRINKET_SLOT)
    local savedID = speedswap_character.savedTrinketID
    return string.format("slot=%s saved=%s",
        self:getItemNameByID(equippedID),
        self:getItemNameByID(savedID))
end

-- ============================================================================
-- ENCHANTED GEAR CACHE
-- ============================================================================

-- Cached links to bag items carrying speed enchants. Populated on BAG_UPDATE
-- and at login. Links are used (not IDs) because the enchant ID is part of
-- the link, and we need to equip the exact enchanted instance.
local spursBootsLink = nil
local ridingGlovesLink = nil

--[[
  Rescan bags for boots with Mithril Spurs and gloves with Riding Skill.
  Called from BAG_UPDATE in gearState and once at login.
]]
function gearSwap:scanBagsForEnchantedGear()
    spursBootsLink = nil
    ridingGlovesLink = nil
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local link = C_Container.GetContainerItemLink(bag, slot)
            if link then
                local enchantID = getEnchantFromLink(link)
                if enchantID == ENCHANT_MITHRIL_SPURS then
                    spursBootsLink = link
                elseif enchantID == ENCHANT_RIDING_SKILL then
                    ridingGlovesLink = link
                end
            end
        end
    end
end

function gearSwap:hasSpursBoots()
    return spursBootsLink ~= nil
end

function gearSwap:hasRidingGloves()
    return ridingGlovesLink ~= nil
end

-- ============================================================================
-- TRINKET STATE TESTS
-- ============================================================================

function gearSwap:isSpeedTrinket(itemID)
    return itemID and SPEED_TRINKETS[itemID] ~= nil
end

-- ============================================================================
-- MOUNT EQUIP / RESTORE
-- ============================================================================

--[[
  Attempt to equip a speed trinket (and legacy gear if using Carrot).
  Saves the currently-equipped trinket ID for later restoration.

  Safe to call repeatedly - checks slot state first, does nothing if already
  holding a speed trinket. Respects canSwapNow gating.

  @return boolean - true if the slot now holds (or already held) a speed trinket
]]
function gearSwap:tryMountEquip()
    if not self:canSwapNow() then return false end

    local equippedTrinketID = GetInventoryItemID("player", TRINKET_SLOT)
    if self:isSpeedTrinket(equippedTrinketID) then
        return true
    end

    local bestID, bestBonus = findBestSpeedTrinketInBags()
    if not bestID then return false end

    -- Save the trinket we're displacing so we can restore it later
    if equippedTrinketID then
        speedswap_character.savedTrinketID = equippedTrinketID
    end
    EquipItemByName(bestID, TRINKET_SLOT)

    -- With Carrot (sub-10%), also equip enchanted legacy gear. Crop/Whip
    -- cap at 10% so the enchants add nothing alongside them.
    local useLegacyGear = bestBonus < 10
    if useLegacyGear then
        if spursBootsLink then
            local currentEnchant = getEnchantFromLink(GetInventoryItemLink("player", BOOTS_SLOT))
            if currentEnchant ~= ENCHANT_MITHRIL_SPURS then
                local currentBootsID = GetInventoryItemID("player", BOOTS_SLOT)
                if currentBootsID then
                    speedswap_character.savedBootsID = currentBootsID
                end
                EquipItemByName(spursBootsLink, BOOTS_SLOT)
            end
        end
        if ridingGlovesLink then
            local currentEnchant = getEnchantFromLink(GetInventoryItemLink("player", GLOVES_SLOT))
            if currentEnchant ~= ENCHANT_RIDING_SKILL then
                local currentGlovesID = GetInventoryItemID("player", GLOVES_SLOT)
                if currentGlovesID then
                    speedswap_character.savedGlovesID = currentGlovesID
                end
                EquipItemByName(ridingGlovesLink, GLOVES_SLOT)
            end
        end
    end

    return false  -- Swap initiated; caller should verify on next tick
end

--[[
  Attempt to restore saved gear (trinket, boots, gloves).
  Each slot is independently checked - a saved ID is cleared once the
  corresponding speed gear is no longer equipped there.

  @return boolean - true if all saved slots are fully restored
]]
function gearSwap:tryMountRestore()
    if not self:canSwapNow() then return false end

    local allDone = true

    -- Trinket
    local equippedTrinketID = GetInventoryItemID("player", TRINKET_SLOT)
    if self:isSpeedTrinket(equippedTrinketID) and speedswap_character.savedTrinketID then
        EquipItemByName(speedswap_character.savedTrinketID, TRINKET_SLOT)
        allDone = false
    elseif not self:isSpeedTrinket(equippedTrinketID) and speedswap_character.savedTrinketID then
        speedswap_character.savedTrinketID = nil
    end

    -- Boots
    if speedswap_character.savedBootsID then
        local currentEnchant = getEnchantFromLink(GetInventoryItemLink("player", BOOTS_SLOT))
        if currentEnchant == ENCHANT_MITHRIL_SPURS then
            EquipItemByName(speedswap_character.savedBootsID, BOOTS_SLOT)
            allDone = false
        else
            speedswap_character.savedBootsID = nil
        end
    end

    -- Gloves
    if speedswap_character.savedGlovesID then
        local currentEnchant = getEnchantFromLink(GetInventoryItemLink("player", GLOVES_SLOT))
        if currentEnchant == ENCHANT_RIDING_SKILL then
            EquipItemByName(speedswap_character.savedGlovesID, GLOVES_SLOT)
            allDone = false
        else
            speedswap_character.savedGlovesID = nil
        end
    end

    return allDone
end

-- ============================================================================
-- SWIM BELT SWAP / RESTORE
-- ============================================================================

--[[
  Attempt to equip the Azure Silk Belt for swim speed.

  @return boolean - true if the belt is now equipped (or no swap was needed)
]]
function gearSwap:trySwimEquip()
    if not self:canSwapNow() then return false end

    local equippedID = GetInventoryItemID("player", WAIST_SLOT)
    if equippedID == SWIM_BELT_ID then return true end
    if not hasItemInBags(SWIM_BELT_ID) then return true end  -- Nothing to equip; stop trying

    if equippedID then
        speedswap_character.savedWaistID = equippedID
    end
    EquipItemByName(SWIM_BELT_ID, WAIST_SLOT)
    return false
end

--[[
  Attempt to restore the previously-equipped waist item.

  @return boolean - true if restored (or no restore needed)
]]
function gearSwap:trySwimRestore()
    if not self:canSwapNow() then return false end

    local equippedID = GetInventoryItemID("player", WAIST_SLOT)
    if equippedID ~= SWIM_BELT_ID then
        speedswap_character.savedWaistID = nil
        return true
    end
    if not speedswap_character.savedWaistID then return true end

    EquipItemByName(speedswap_character.savedWaistID, WAIST_SLOT)
    return false
end

-- ============================================================================
-- EXPORT
-- ============================================================================

Addon.gearSwap = gearSwap
