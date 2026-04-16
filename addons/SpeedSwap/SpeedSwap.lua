----------------------------------------------------------------------
-- SpeedSwap
-- Auto-equips mount speed gear on mount, restores on dismount.
-- Auto-equips Azure Silk Belt while swimming.
-- Supports Riding Crop, Skybreaker Whip, Carrot on a Stick,
-- Mithril Spurs (boots), and Riding Skill (gloves).
----------------------------------------------------------------------

local ADDON_NAME = "SpeedSwap"
local TRINKET_SLOT = 13
local BOOTS_SLOT = 8
local GLOVES_SLOT = 10
local WAIST_SLOT = 6
local RETRY_INTERVAL = 2

-- Mount speed trinkets (don't stack with each other or with enchants)
local SPEED_TRINKETS = {
    [25653] = 10, -- Riding Crop (+10%)
    [32863] = 10, -- Skybreaker Whip (+10%)
    [11122] = 3,  -- Carrot on a Stick (+3%)
}

local SWIM_BELT_ID = 7052 -- Azure Silk Belt (+15% swim speed)

-- Enchant IDs found in item links
local ENCHANT_MITHRIL_SPURS = "464" -- +4% mount speed on boots
local ENCHANT_RIDING_SKILL = "930"  -- +2% mount speed on gloves

SpeedSwapCharDB = SpeedSwapCharDB or {}

----------------------------------------------------------------------
-- Debug output
----------------------------------------------------------------------

local function Debug(...)
    if not SpeedSwapCharDB.debug then return end
    print("|cffff9900SpeedSwap debug:|r", ...)
end

-- Only prints if the message is different from the last one for this key
local lastDebugState = {}
local function DebugOnce(key, ...)
    if not SpeedSwapCharDB.debug then return end
    local msg = string.join(" ", tostringall(...))
    if lastDebugState[key] == msg then return end
    lastDebugState[key] = msg
    print("|cffff9900SpeedSwap debug:|r", ...)
end

local function Msg(...)
    print("|cff00ccffSpeedSwap:|r", ...)
end

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

local function IsSpeedTrinket(itemID)
    return itemID and SPEED_TRINKETS[itemID] ~= nil
end

local function GetEnchantFromLink(link)
    if not link then return nil end
    local enchantID = link:match("item:%d+:(%d+)")
    return enchantID
end

-- Cached enchanted gear links (found during bag scans)
local spursBootsLink = nil
local ridingGlovesLink = nil

local function ScanBagsForEnchantedGear()
    spursBootsLink = nil
    ridingGlovesLink = nil
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local link = C_Container.GetContainerItemLink(bag, slot)
            if link then
                local enchantID = GetEnchantFromLink(link)
                if enchantID == ENCHANT_MITHRIL_SPURS then
                    spursBootsLink = link
                elseif enchantID == ENCHANT_RIDING_SKILL then
                    ridingGlovesLink = link
                end
            end
        end
    end
end

local function FindBestSpeedTrinketInBags()
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

local function HasItemInBags(searchID)
    for bag = 0, 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            if C_Container.GetContainerItemID(bag, slot) == searchID then
                return true
            end
        end
    end
    return false
end

local function ShouldHaveSpeedGear()
    return IsMounted() and not UnitOnTaxi("player") and not IsInInstance()
end

-- EquipItemByName is protected during combat on TBC Anniversary's client,
-- and misbehaves with vendor/bank/mail/trade/auction windows open.
local function CanSwapNow()
    if InCombatLockdown() then return false end
    if MerchantFrame and MerchantFrame:IsShown() then return false end
    if BankFrame and BankFrame:IsShown() then return false end
    if MailFrame and MailFrame:IsShown() then return false end
    if TradeFrame and TradeFrame:IsShown() then return false end
    if AuctionFrame and AuctionFrame:IsShown() then return false end
    return true
end

local function GetItemNameByID(itemID)
    if not itemID then return "empty" end
    local name = GetItemInfo(itemID)
    return name or tostring(itemID)
end

local function TrinketStateString()
    local equippedID = GetInventoryItemID("player", TRINKET_SLOT)
    local savedID = SpeedSwapCharDB.savedTrinketID
    return string.format("slot=%s saved=%s",
        GetItemNameByID(equippedID),
        GetItemNameByID(savedID))
end

----------------------------------------------------------------------
-- Retry timer
----------------------------------------------------------------------

local pendingMountAction = nil  -- "equip" or "restore"
local pendingSwimAction = nil   -- "equip" or "restore"
local retryCount = 0

local retryFrame = CreateFrame("Frame")
retryFrame:Hide()
local retryElapsed = 0

local function StopRetry()
    retryFrame:Hide()
end

local function StartRetry()
    retryElapsed = 0
    retryCount = 0
    retryFrame:Show()
end

----------------------------------------------------------------------
-- Mount gear swap
----------------------------------------------------------------------

local function TryMountEquip()
    if not CanSwapNow() then return end

    local equippedTrinketID = GetInventoryItemID("player", TRINKET_SLOT)

    -- Already have a speed trinket, done
    if IsSpeedTrinket(equippedTrinketID) then
        if retryCount > 1 then
            Debug("Equipped after", retryCount, "retries")
        end
        pendingMountAction = nil
        return
    end

    local bestID, bestBonus = FindBestSpeedTrinketInBags()

    -- Determine strategy: Crop/Whip = just trinket. Carrot = trinket + enchanted gear.
    local useLegacyGear = bestID and bestBonus < 10

    if bestID then
        if equippedTrinketID then
            SpeedSwapCharDB.savedTrinketID = equippedTrinketID
        end
        EquipItemByName(bestID, TRINKET_SLOT)
        DebugOnce("equip_trinket", "Mounted: equipping", GetItemNameByID(bestID), "- was", GetItemNameByID(equippedTrinketID))
    else
        pendingMountAction = nil
        return
    end

    -- With Carrot (sub-10%), also equip spurs and riding skill gloves if available
    if useLegacyGear then
        if spursBootsLink then
            local currentBootsID = GetInventoryItemID("player", BOOTS_SLOT)
            local currentEnchant = GetEnchantFromLink(GetInventoryItemLink("player", BOOTS_SLOT))
            if currentEnchant ~= ENCHANT_MITHRIL_SPURS then
                if currentBootsID then
                    SpeedSwapCharDB.savedBootsID = currentBootsID
                end
                EquipItemByName(spursBootsLink, BOOTS_SLOT)
            end
        end
        if ridingGlovesLink then
            local currentGlovesID = GetInventoryItemID("player", GLOVES_SLOT)
            local currentEnchant = GetEnchantFromLink(GetInventoryItemLink("player", GLOVES_SLOT))
            if currentEnchant ~= ENCHANT_RIDING_SKILL then
                if currentGlovesID then
                    SpeedSwapCharDB.savedGlovesID = currentGlovesID
                end
                EquipItemByName(ridingGlovesLink, GLOVES_SLOT)
            end
        end
    end
end

local function TryMountRestore()
    if not CanSwapNow() then return end

    local allDone = true

    -- Trinket
    local equippedTrinketID = GetInventoryItemID("player", TRINKET_SLOT)
    if IsSpeedTrinket(equippedTrinketID) and SpeedSwapCharDB.savedTrinketID then
        EquipItemByName(SpeedSwapCharDB.savedTrinketID, TRINKET_SLOT)
        DebugOnce("restore_trinket", "Dismounted: restoring", GetItemNameByID(SpeedSwapCharDB.savedTrinketID))
        allDone = false
    elseif not IsSpeedTrinket(equippedTrinketID) and SpeedSwapCharDB.savedTrinketID then
        SpeedSwapCharDB.savedTrinketID = nil
    end

    -- Boots
    if SpeedSwapCharDB.savedBootsID then
        local currentEnchant = GetEnchantFromLink(GetInventoryItemLink("player", BOOTS_SLOT))
        if currentEnchant == ENCHANT_MITHRIL_SPURS then
            EquipItemByName(SpeedSwapCharDB.savedBootsID, BOOTS_SLOT)
            allDone = false
        else
            SpeedSwapCharDB.savedBootsID = nil
        end
    end

    -- Gloves
    if SpeedSwapCharDB.savedGlovesID then
        local currentEnchant = GetEnchantFromLink(GetInventoryItemLink("player", GLOVES_SLOT))
        if currentEnchant == ENCHANT_RIDING_SKILL then
            EquipItemByName(SpeedSwapCharDB.savedGlovesID, GLOVES_SLOT)
            allDone = false
        else
            SpeedSwapCharDB.savedGlovesID = nil
        end
    end

    if allDone then
        if retryCount > 1 then
            Debug("Restored after", retryCount, "retries")
        end
        pendingMountAction = nil
    end
end

local function TryMountAction()
    if pendingMountAction == "equip" then
        if not ShouldHaveSpeedGear() then
            pendingMountAction = nil
            return
        end
        TryMountEquip()
    elseif pendingMountAction == "restore" then
        TryMountRestore()
    end
end

----------------------------------------------------------------------
-- Swim belt swap
----------------------------------------------------------------------

local function TrySwimAction()
    if not CanSwapNow() then
        return
    end

    if pendingSwimAction == "equip" then
        if not IsSwimming() then
            pendingSwimAction = nil
            return
        end
        local equippedID = GetInventoryItemID("player", WAIST_SLOT)
        if equippedID == SWIM_BELT_ID then
            pendingSwimAction = nil
            return
        end
        if HasItemInBags(SWIM_BELT_ID) then
            if equippedID then
                SpeedSwapCharDB.savedWaistID = equippedID
            end
            EquipItemByName(SWIM_BELT_ID, WAIST_SLOT)
        else
            pendingSwimAction = nil
        end

    elseif pendingSwimAction == "restore" then
        local equippedID = GetInventoryItemID("player", WAIST_SLOT)
        if equippedID ~= SWIM_BELT_ID then
            SpeedSwapCharDB.savedWaistID = nil
            pendingSwimAction = nil
            return
        end
        if SpeedSwapCharDB.savedWaistID then
            EquipItemByName(SpeedSwapCharDB.savedWaistID, WAIST_SLOT)
        else
            pendingSwimAction = nil
        end
    end
end

----------------------------------------------------------------------
-- Retry loop
----------------------------------------------------------------------

local function ProcessRetry()
    retryCount = retryCount + 1
    if pendingMountAction then TryMountAction() end
    if pendingSwimAction then TrySwimAction() end
    if not pendingMountAction and not pendingSwimAction then
        StopRetry()
    end
end

retryFrame:SetScript("OnUpdate", function(self, elapsed)
    retryElapsed = retryElapsed + elapsed
    if retryElapsed < RETRY_INTERVAL then return end
    retryElapsed = 0
    ProcessRetry()
end)

----------------------------------------------------------------------
-- Speed LDB integration (optional, only if Speed addon is loaded)
----------------------------------------------------------------------

local function FlashSpeedDelta(beforeSpeed)
    local speedLDB = LibStub and LibStub("LibDataBroker-1.1", true)
    if not speedLDB then return end
    local speedObj = speedLDB:GetDataObjectByName("Speed")
    if not speedObj then return end

    local afterSpeed = GetUnitSpeed("player")
    local beforePct = beforeSpeed / 7 * 100
    local afterPct = afterSpeed / 7 * 100
    local delta = afterPct - beforePct

    if math.abs(delta) < 0.1 then return end

    local savedText = speedObj.text
    local sign = delta > 0 and "+" or ""
    speedObj.text = string.format("Speed: %d%% %s%d%%", afterPct, sign, delta)

    C_Timer.After(3, function()
        -- Only reset if nothing else has changed it
        local currentText = speedObj.text
        if currentText:find("%+") or currentText:find("%-") then
            speedObj.text = savedText
        end
    end)
end

----------------------------------------------------------------------
-- State change detection
----------------------------------------------------------------------

local wasMounted = false
local wasSwimming = false
local summonPending = false

-- Track which events fire around mount state changes
local mountChangeTime = 0
local mountChangeGotAura = false
local mountChangeGotPMDC = false

local function CheckMountState(event)
    if not SpeedSwapCharDB.autoEquip then return end

    local isMounted = ShouldHaveSpeedGear()

    -- Track event sources around mount changes
    if isMounted ~= wasMounted then
        -- This event triggered the state change
        mountChangeTime = GetTime()
        mountChangeGotAura = (event == "UNIT_AURA")
        mountChangeGotPMDC = (event == "PLAYER_MOUNT_DISPLAY_CHANGED")

        C_Timer.After(1, function()
            if mountChangeTime > 0 then
                if not mountChangeGotAura then
                    Debug("Mount change: UNIT_AURA did not fire")
                    PlaySound(888, "Master")
                elseif not mountChangeGotPMDC then
                    Debug("Mount change: PLAYER_MOUNT_DISPLAY_CHANGED did not fire")
                    PlaySound(888, "Master")
                end
                mountChangeTime = 0
            end
        end)

        if isMounted and not wasMounted then
            local beforeSpeed = GetUnitSpeed("player")
            pendingMountAction = "equip"
            lastDebugState["equip_trinket"] = nil
            TryMountAction()
            if pendingMountAction then
                StartRetry()
            else
                C_Timer.After(0.5, function() FlashSpeedDelta(beforeSpeed) end)
            end
        elseif not isMounted and wasMounted then
            pendingMountAction = "restore"
            lastDebugState["restore_trinket"] = nil
            TryMountAction()
            if pendingMountAction then StartRetry() end
        end

        wasMounted = isMounted
    else
        -- No state change, but confirm the other event fired
        if GetTime() - mountChangeTime < 1.5 then
            if event == "UNIT_AURA" then mountChangeGotAura = true end
            if event == "PLAYER_MOUNT_DISPLAY_CHANGED" then mountChangeGotPMDC = true end
        end
    end
end

local stateWatcher = CreateFrame("Frame")
stateWatcher:RegisterEvent("UNIT_AURA")
stateWatcher:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
stateWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
stateWatcher:RegisterEvent("CONFIRM_SUMMON")
stateWatcher:RegisterEvent("BAG_UPDATE")
stateWatcher:SetScript("OnEvent", function(self, event, unit)

    -- Bag scan on inventory changes
    if event == "BAG_UPDATE" then
        ScanBagsForEnchantedGear()
        return
    end

    -- Summon notification: when the dialog appears
    if event == "CONFIRM_SUMMON" then
        local summoner = C_SummonInfo.GetSummonConfirmSummoner()
        local area = C_SummonInfo.GetSummonConfirmAreaName()
        Msg(string.format("Summon from %s to %s. %s | mounted=%s instance=%s",
            summoner or "unknown", area or "unknown", TrinketStateString(),
            tostring(IsMounted()), tostring(IsInInstance())))
        summonPending = true
        return
    end

    -- Zone-in handler
    if event == "PLAYER_ENTERING_WORLD" then
        -- Summon notification: on arrival
        if summonPending then
            summonPending = false
            Msg(string.format("Arrived. %s | mounted=%s instance=%s taxi=%s",
                TrinketStateString(), tostring(IsMounted()),
                tostring(IsInInstance()), tostring(UnitOnTaxi("player"))))
        end

        -- If we're in an instance with speed gear, restore
        if IsInInstance() then
            local equippedID = GetInventoryItemID("player", TRINKET_SLOT)
            if IsSpeedTrinket(equippedID) and SpeedSwapCharDB.savedTrinketID then
                Debug("Zone-in: in instance with speed trinket, restoring")
                pendingMountAction = "restore"
                TryMountAction()
                if pendingMountAction then StartRetry() end
            end
        end

        -- Update tracked states
        wasMounted = ShouldHaveSpeedGear()
        wasSwimming = IsSwimming()
        return
    end

    -- UNIT_AURA: only care about player
    if event == "UNIT_AURA" and unit ~= "player" then return end

    -- Mount state change (from UNIT_AURA or PLAYER_MOUNT_DISPLAY_CHANGED)
    if event == "UNIT_AURA" or event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        CheckMountState(event)
    end

    -- Swim state change
    if SpeedSwapCharDB.swimBelt then
        local isSwimming = IsSwimming()

        if isSwimming and not wasSwimming then
            pendingSwimAction = "equip"
            TrySwimAction()
            if pendingSwimAction then StartRetry() end
        elseif not isSwimming and wasSwimming then
            pendingSwimAction = "restore"
            TrySwimAction()
            if pendingSwimAction then StartRetry() end
        end

        wasSwimming = isSwimming
    end
end)

----------------------------------------------------------------------
-- Login restoration
----------------------------------------------------------------------

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self, event)
    SpeedSwapCharDB = SpeedSwapCharDB or {}
    if SpeedSwapCharDB.autoEquip == nil then SpeedSwapCharDB.autoEquip = true end
    if SpeedSwapCharDB.swimBelt == nil then SpeedSwapCharDB.swimBelt = false end
    if SpeedSwapCharDB.debug == nil then SpeedSwapCharDB.debug = false end

    ScanBagsForEnchantedGear()

    -- If we have saved gear and we're not mounted, restore
    if not IsMounted() then
        local needsRestore = false

        if SpeedSwapCharDB.savedTrinketID then
            local equippedID = GetInventoryItemID("player", TRINKET_SLOT)
            if IsSpeedTrinket(equippedID) then
                needsRestore = true
                Debug("Login: speed trinket still equipped, queuing restore")
            else
                SpeedSwapCharDB.savedTrinketID = nil
            end
        end

        if SpeedSwapCharDB.savedBootsID then
            local currentEnchant = GetEnchantFromLink(GetInventoryItemLink("player", BOOTS_SLOT))
            if currentEnchant == ENCHANT_MITHRIL_SPURS then
                needsRestore = true
            else
                SpeedSwapCharDB.savedBootsID = nil
            end
        end

        if SpeedSwapCharDB.savedGlovesID then
            local currentEnchant = GetEnchantFromLink(GetInventoryItemLink("player", GLOVES_SLOT))
            if currentEnchant == ENCHANT_RIDING_SKILL then
                needsRestore = true
            else
                SpeedSwapCharDB.savedGlovesID = nil
            end
        end

        if needsRestore then
            pendingMountAction = "restore"
            TryMountAction()
            if pendingMountAction then StartRetry() end
        end
    end

    -- Same for swim belt
    if SpeedSwapCharDB.savedWaistID and not IsSwimming() then
        local equippedID = GetInventoryItemID("player", WAIST_SLOT)
        if equippedID == SWIM_BELT_ID then
            pendingSwimAction = "restore"
            TrySwimAction()
            if pendingSwimAction then StartRetry() end
        else
            SpeedSwapCharDB.savedWaistID = nil
        end
    end

    wasMounted = ShouldHaveSpeedGear()
    wasSwimming = IsSwimming()

    self:UnregisterEvent("PLAYER_LOGIN")
end)

----------------------------------------------------------------------
-- Slash commands
----------------------------------------------------------------------
SLASH_SPEEDSWAP1 = "/speedswap"
SLASH_SPEEDSWAP2 = "/ss"
SlashCmdList["SPEEDSWAP"] = function(msg)
    msg = strtrim(msg or ""):lower()
    if msg == "equip" then
        SpeedSwapCharDB.autoEquip = not SpeedSwapCharDB.autoEquip
        if SpeedSwapCharDB.autoEquip then
            Msg("Auto-equip speed gear |cff00ff00ON|r.")
        else
            Msg("Auto-equip speed gear |cffff0000OFF|r.")
        end
    elseif msg == "swim" then
        SpeedSwapCharDB.swimBelt = not SpeedSwapCharDB.swimBelt
        if SpeedSwapCharDB.swimBelt then
            Msg("Swim belt auto-equip |cff00ff00ON|r.")
        else
            Msg("Swim belt auto-equip |cffff0000OFF|r.")
        end
    elseif msg == "debug" then
        SpeedSwapCharDB.debug = not SpeedSwapCharDB.debug
        if SpeedSwapCharDB.debug then
            Msg("Debug mode |cff00ff00ON|r.")
        else
            Msg("Debug mode |cffff0000OFF|r.")
        end
    elseif msg == "status" then
        Msg("Trinket: " .. TrinketStateString())
        Msg("Pending mount: " .. tostring(pendingMountAction))
        Msg("Pending swim: " .. tostring(pendingSwimAction))
        Msg("Mounted: " .. tostring(IsMounted()) .. " Taxi: " .. tostring(UnitOnTaxi("player")) .. " Instance: " .. tostring(IsInInstance()))
        Msg("Spurs boots: " .. (spursBootsLink and "found" or "none"))
        Msg("Riding gloves: " .. (ridingGlovesLink and "found" or "none"))
        Msg("Swim belt saved: " .. GetItemNameByID(SpeedSwapCharDB.savedWaistID))
    elseif msg == "" then
        Msg("commands:")
        print("  /ss equip - Toggle auto-equip speed gear on mount")
        print("  /ss swim - Toggle auto-equip Azure Silk Belt while swimming")
        print("  /ss status - Show current swap state and gear info")
        print("  /ss debug - Toggle debug output")
    else
        Msg("Unknown command. Type /ss for help.")
    end
end
