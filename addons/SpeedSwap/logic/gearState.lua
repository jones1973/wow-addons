--[[
  logic/gearState.lua
  Mount/Swim State Detection and Retry Loop

  Watches for mount and swim state changes and schedules gear swaps via
  Addon.gearSwap. A swap request is fired immediately on state change;
  if it can't complete (combat, vendor window, etc.), a 2-second retry
  timer keeps attempting until the swap succeeds or the state changes again.

  Why PLAYER_MOUNT_DISPLAY_CHANGED, not UNIT_AURA?
  - PLAYER_MOUNT_DISPLAY_CHANGED fires specifically and reliably on mount
    state transitions. UNIT_AURA fires for every buff change and was the
    event that occasionally failed to fire for dismounts in testing.

  Dependencies: Addon.gearSwap
  Exports: Addon.gearState
]]

local ADDON_NAME, Addon = ...

local gearState = {}

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local RETRY_INTERVAL = 2  -- Seconds between retry attempts

local TRINKET_SLOT = 13

-- ============================================================================
-- STATE
-- ============================================================================

local pendingMountAction = nil  -- "equip" | "restore" | nil
local pendingSwimAction  = nil  -- "equip" | "restore" | nil
local retryCount = 0

local wasMounted = false
local wasSwimming = false
local summonPending = false

-- Deduplication state for debug output. Keys cleared at the start of each
-- mount/swim cycle so the "equipping X" line prints once per cycle rather
-- than every 2-second retry tick.
local lastDebugState = {}

local retryFrame = CreateFrame("Frame")
retryFrame:Hide()
local retryElapsed = 0

-- ============================================================================
-- DEBUG OUTPUT
-- ============================================================================

--[[
  Print a debug message if debug mode is enabled.
  Always prints (subject to the debug flag) - use debugOnce for messages
  that could fire on every retry tick.
]]
local function debug(...)
    if not speedswap_character.debug then return end
    print("|cffff9900SpeedSwap debug:|r", ...)
end

--[[
  Print a debug message only if its content differs from the last message
  printed under the same key. Prevents retry-loop spam while still showing
  a message when the state genuinely changes.

  @param key string - Deduplication key (cleared when a new cycle starts)
  @param ... - Message parts, joined with spaces for comparison
]]
local function debugOnce(key, ...)
    if not speedswap_character.debug then return end
    local msg = string.join(" ", tostringall(...))
    if lastDebugState[key] == msg then return end
    lastDebugState[key] = msg
    print("|cffff9900SpeedSwap debug:|r", ...)
end

--[[
  Print a user-facing message (not gated by debug mode).
]]
local function msg(...)
    print("|cff00ccffSpeedSwap:|r", ...)
end

-- ============================================================================
-- RETRY LOOP
-- ============================================================================

local function stopRetry()
    retryFrame:Hide()
end

local function startRetry()
    retryElapsed = 0
    retryCount = 0
    retryFrame:Show()
end

--[[
  Check whether the player is currently mounted in a state where speed
  gear makes sense (not on a taxi, not in an instance).

  @return boolean
]]
local function shouldHaveSpeedGear()
    return IsMounted() and not UnitOnTaxi("player") and not IsInInstance()
end

--[[
  Try to advance the pending mount action (equip or restore).
  Clears the pending flag and logs success if the action completed.
]]
local function tryMountAction()
    local gearSwap = Addon.gearSwap

    if pendingMountAction == "equip" then
        -- If we shouldn't have speed gear anymore (dismounted mid-retry),
        -- abandon the equip attempt
        if not shouldHaveSpeedGear() then
            pendingMountAction = nil
            return
        end

        -- Log intended swap (deduplicated) before attempting
        local equippedID = GetInventoryItemID("player", TRINKET_SLOT)
        if not gearSwap:isSpeedTrinket(equippedID) then
            debugOnce("equip_trinket",
                "Mounted: equipping speed trinket - was",
                gearSwap:getItemNameByID(equippedID))
        end

        if gearSwap:tryMountEquip() then
            if retryCount > 1 then
                debug("Equipped after", retryCount, "retries")
            end
            pendingMountAction = nil
        end

    elseif pendingMountAction == "restore" then
        -- Log intended restore (deduplicated) before attempting
        if speedswap_character.savedTrinketID then
            debugOnce("restore_trinket",
                "Dismounted: restoring",
                gearSwap:getItemNameByID(speedswap_character.savedTrinketID))
        end

        if gearSwap:tryMountRestore() then
            if retryCount > 1 then
                debug("Restored after", retryCount, "retries")
            end
            pendingMountAction = nil
        end
    end
end

--[[
  Try to advance the pending swim action (equip or restore belt).
]]
local function trySwimAction()
    local gearSwap = Addon.gearSwap

    if pendingSwimAction == "equip" then
        if not IsSwimming() then
            pendingSwimAction = nil
            return
        end
        if gearSwap:trySwimEquip() then
            pendingSwimAction = nil
        end
    elseif pendingSwimAction == "restore" then
        if gearSwap:trySwimRestore() then
            pendingSwimAction = nil
        end
    end
end

local function processRetry()
    retryCount = retryCount + 1
    if pendingMountAction then tryMountAction() end
    if pendingSwimAction  then trySwimAction()  end
    if not pendingMountAction and not pendingSwimAction then
        stopRetry()
    end
end

retryFrame:SetScript("OnUpdate", function(_, elapsed)
    retryElapsed = retryElapsed + elapsed
    if retryElapsed < RETRY_INTERVAL then return end
    retryElapsed = 0
    processRetry()
end)

-- ============================================================================
-- SPEED LDB INTEGRATION (optional)
-- ============================================================================

--[[
  If the Speed addon's LDB object is present, briefly change its text to
  show the speed delta for 3 seconds. Silent no-op if Speed isn't loaded.

  @param beforeSpeed number - GetUnitSpeed("player") value captured before the swap
]]
local function flashSpeedDelta(beforeSpeed)
    local lib = LibStub and LibStub("LibDataBroker-1.1", true)
    if not lib then return end
    local speedObj = lib:GetDataObjectByName("Speed")
    if not speedObj then return end

    local afterSpeed = GetUnitSpeed("player")
    local beforePct = beforeSpeed / 7 * 100
    local afterPct  = afterSpeed  / 7 * 100
    local delta = afterPct - beforePct

    if math.abs(delta) < 0.1 then return end

    local savedText = speedObj.text
    local sign = delta > 0 and "+" or ""
    speedObj.text = string.format("Speed: %d%% %s%d%%", afterPct, sign, delta)

    C_Timer.After(3, function()
        -- Only revert if nothing else has clobbered our message since
        local currentText = speedObj.text
        if currentText:find("%+") or currentText:find("%-") then
            speedObj.text = savedText
        end
    end)
end

-- ============================================================================
-- STATE CHANGE HANDLING
-- ============================================================================

--[[
  Inspect current mount state and queue an equip or restore if it changed.
  Called from the event handler.
]]
local function checkMountState()
    if not speedswap_character.autoEquip then return end

    local isMounted = shouldHaveSpeedGear()

    if isMounted and not wasMounted then
        local beforeSpeed = GetUnitSpeed("player")
        pendingMountAction = "equip"
        lastDebugState["equip_trinket"] = nil
        tryMountAction()
        if pendingMountAction then
            startRetry()
        else
            -- Immediate swap succeeded; flash delta shortly after gear applies
            C_Timer.After(0.5, function() flashSpeedDelta(beforeSpeed) end)
        end
    elseif not isMounted and wasMounted then
        pendingMountAction = "restore"
        lastDebugState["restore_trinket"] = nil
        tryMountAction()
        if pendingMountAction then startRetry() end
    end

    wasMounted = isMounted
end

--[[
  Inspect current swim state and queue a belt equip or restore if it changed.
]]
local function checkSwimState()
    if not speedswap_character.swimBelt then return end

    local isSwimming = IsSwimming()

    if isSwimming and not wasSwimming then
        pendingSwimAction = "equip"
        trySwimAction()
        if pendingSwimAction then startRetry() end
    elseif not isSwimming and wasSwimming then
        pendingSwimAction = "restore"
        trySwimAction()
        if pendingSwimAction then startRetry() end
    end

    wasSwimming = isSwimming
end

-- ============================================================================
-- EVENT HANDLER
-- ============================================================================

local watcher = CreateFrame("Frame")
watcher:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
watcher:RegisterEvent("CONFIRM_SUMMON")
watcher:RegisterEvent("BAG_UPDATE")

watcher:SetScript("OnEvent", function(_, event)
    local gearSwap = Addon.gearSwap

    if event == "BAG_UPDATE" then
        gearSwap:scanBagsForEnchantedGear()
        return
    end

    if event == "CONFIRM_SUMMON" then
        local summoner = C_SummonInfo.GetSummonConfirmSummoner()
        local area = C_SummonInfo.GetSummonConfirmAreaName()
        msg(string.format("Summon from %s to %s. %s | mounted=%s instance=%s",
            summoner or "unknown", area or "unknown", gearSwap:trinketStateString(),
            tostring(IsMounted()), tostring(IsInInstance())))
        summonPending = true
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        if summonPending then
            summonPending = false
            msg(string.format("Arrived. %s | mounted=%s instance=%s taxi=%s",
                gearSwap:trinketStateString(), tostring(IsMounted()),
                tostring(IsInInstance()), tostring(UnitOnTaxi("player"))))
        end

        -- Zoning into an instance with speed gear still equipped: restore
        if IsInInstance() then
            local equippedID = GetInventoryItemID("player", TRINKET_SLOT)
            if gearSwap:isSpeedTrinket(equippedID) and speedswap_character.savedTrinketID then
                debug("Zone-in: in instance with speed trinket, restoring")
                pendingMountAction = "restore"
                tryMountAction()
                if pendingMountAction then startRetry() end
            end
        end

        wasMounted = shouldHaveSpeedGear()
        wasSwimming = IsSwimming()
        return
    end

    if event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        checkMountState()
        checkSwimState()
    end
end)

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Called from main.lua after login to restore gear if the player logged out
  while speed gear was still equipped (e.g., crashed while mounted).
]]
function gearState:restoreOnLogin()
    local gearSwap = Addon.gearSwap

    if not IsMounted() then
        local needsRestore = false

        if speedswap_character.savedTrinketID then
            local equippedID = GetInventoryItemID("player", TRINKET_SLOT)
            if gearSwap:isSpeedTrinket(equippedID) then
                needsRestore = true
                debug("Login: speed trinket still equipped, queuing restore")
            else
                speedswap_character.savedTrinketID = nil
            end
        end

        if needsRestore then
            pendingMountAction = "restore"
            tryMountAction()
            if pendingMountAction then startRetry() end
        end
    end

    if speedswap_character.savedWaistID and not IsSwimming() then
        local equippedID = GetInventoryItemID("player", 6)
        if equippedID == 7052 then
            pendingSwimAction = "restore"
            trySwimAction()
            if pendingSwimAction then startRetry() end
        else
            speedswap_character.savedWaistID = nil
        end
    end

    wasMounted = shouldHaveSpeedGear()
    wasSwimming = IsSwimming()
end

--[[
  Return a snapshot of current state for /speedswap status.

  @return table - { pendingMount, pendingSwim, trinketSummary }
]]
function gearState:status()
    return {
        pendingMount = pendingMountAction,
        pendingSwim = pendingSwimAction,
        trinketSummary = Addon.gearSwap:trinketStateString(),
    }
end

-- ============================================================================
-- EXPORT
-- ============================================================================

Addon.gearState = gearState
