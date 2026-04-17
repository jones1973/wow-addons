--[[
  logic/scanner.lua
  Nameplate scanner and alert dispatcher

  Scans visible nameplates every SCAN_INTERVAL seconds for living, attackable
  mobs whose names partial-match entries in the watch list. On each tick,
  compares the current matched GUID set to the previous set; only newly-seen
  GUIDs trigger alerts. A mob that leaves nameplate range and returns will
  re-trigger because its GUID is absent from the previous set on re-entry.

  Behavior forks on group status:
    Solo:    mark each new mob with a distinct raid icon (skull → cross → ...)
    Grouped: no marks; print a summary line to chat

  Polling note: nameplate events exist (NAME_PLATE_UNIT_ADDED/REMOVED) but
  they fire per-unit, not as a batch. The user's spec explicitly wants
  per-scan batched output ("Found: Mob A (2), Mob B (1)"), so an OnUpdate
  tick that rebuilds the visible set is the simplest fit.

  Dependencies: constants, utils
  Exports: Addon.scanner
]]

local ADDON_NAME, Addon = ...

local scanner = {}

-- Module references (resolved at init, not at file load)
local constants, utils

-- Internal state
local previousGUIDs    = {} -- {[guid] = true}  - matched GUIDs from last tick
local iconAssignments  = {} -- {[guid] = iconIndex}
local freeIcons        = {} -- {[iconIndex] = true}
local elapsed          = 0
local lastSoundTime    = 0  -- GetTime() of last alert sound
local tickerFrame

-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

local function initIcons()
    wipe(freeIcons)
    for i = 1, 8 do
        freeIcons[i] = true
    end
end

--[[
  Take the next available raid icon in priority order.

  @return number|nil - Icon index 1-8, or nil if all 8 are in use
]]
local function allocIcon()
    for _, icon in ipairs(constants.ICON_ORDER) do
        if freeIcons[icon] then
            freeIcons[icon] = nil
            return icon
        end
    end
    return nil
end

local function releaseIcon(icon)
    if icon then freeIcons[icon] = true end
end

local function isGrouped()
    return IsInGroup() or IsInRaid()
end

--[[
  Unpack a watch list entry into (pattern, zone). Freeform entries are
  stored as plain strings (no zone constraint); Questie-picked entries
  are {pattern = ..., zone = ...} tables.

  @param entry string|table
  @return string|nil pattern, string|nil zone
]]
local function entryFields(entry)
    local t = type(entry)
    if t == "string" then
        return entry, nil
    elseif t == "table" then
        return entry.pattern, entry.zone
    end
    return nil, nil
end

--[[
  Test a mob name against the watch list using case-insensitive substring match.
  Zone-locked entries only match when the player is in the constrained zone.

  @param name string - Mob name from UnitName
  @param currentZone string - Result of GetZoneText() for this tick
  @return boolean
]]
local function matchesWatchList(name, currentZone)
    local list = mobster_character and mobster_character.watchList
    if not name or not list or #list == 0 then
        return false
    end
    local lower = name:lower()
    for _, entry in ipairs(list) do
        local pattern, zone = entryFields(entry)
        if pattern and lower:find(pattern:lower(), 1, true) then
            if (not zone) or zone == currentZone then
                return true
            end
        end
    end
    return false
end

--[[
  Walk visible nameplates and return matching attackable living mobs.
  Iterates "nameplate1"–"nameplate40" unit tokens directly rather than
  going through C_NamePlate.GetNamePlates(), which avoids Classic client
  quirks with the .namePlateUnitToken property on returned frames.

  @return table - {[guid] = {name = string, unit = string}}
]]
local MAX_NAMEPLATES = 40

local function collectMatches()
    local matches = {}
    -- Cache zone once per scan rather than once per plate.
    local currentZone = GetZoneText()
    for i = 1, MAX_NAMEPLATES do
        local unit = "nameplate" .. i
        if UnitExists(unit)
            and UnitCanAttack("player", unit)
            and not UnitIsDead(unit)
        then
            local name = UnitName(unit)
            if name and matchesWatchList(name, currentZone) then
                local guid = UnitGUID(unit)
                if guid then
                    matches[guid] = { name = name, unit = unit }
                end
            end
        end
    end
    return matches
end

local function tick()
    local list = mobster_character and mobster_character.watchList
    if not list or #list == 0 then return end

    local current = collectMatches()

    -- Free icons for GUIDs that left our tracked set
    for guid in pairs(previousGUIDs) do
        if not current[guid] and iconAssignments[guid] then
            releaseIcon(iconAssignments[guid])
            iconAssignments[guid] = nil
        end
    end

    -- Detect new GUIDs and act on them
    local newByName = {}
    local hasNew = false
    for guid, info in pairs(current) do
        if not previousGUIDs[guid] then
            hasNew = true
            newByName[info.name] = (newByName[info.name] or 0) + 1

            if not isGrouped() and mobster_character.markEnabled then
                local icon = allocIcon()
                if icon then
                    SetRaidTarget(info.unit, icon)
                    iconAssignments[guid] = icon
                end
            end
        end
    end

    if hasNew then
        local now = GetTime()
        if mobster_character.soundEnabled
            and (now - lastSoundTime) >= constants.SOUND_COOLDOWN
        then
            PlaySound(constants.ALERT_SOUND, "Master")
            lastSoundTime = now
        end

        if isGrouped() then
            local parts = {}
            for name, count in pairs(newByName) do
                if count > 1 then
                    parts[#parts + 1] = name .. " (" .. count .. ")"
                else
                    parts[#parts + 1] = name
                end
            end
            utils:chat("Found: " .. table.concat(parts, ", "))
        end
    end

    -- Rebuild previousGUIDs from current (GUID-only view for next comparison)
    wipe(previousGUIDs)
    for guid in pairs(current) do
        previousGUIDs[guid] = true
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Clear all tracked state. Call after the watch list changes so previously-
  visible mobs get re-evaluated against the new list on the next scan.
  Also called on zone changes and group-composition changes.
]]
function scanner:resetTracking()
    wipe(previousGUIDs)
    wipe(iconAssignments)
    initIcons()
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function scanner:initialize()
    constants = Addon.constants
    utils     = Addon.utils

    if not constants or not utils then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444scanner: Missing dependencies|r")
        return false
    end

    initIcons()

    tickerFrame = CreateFrame("Frame")
    tickerFrame:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        if elapsed >= constants.SCAN_INTERVAL then
            elapsed = 0
            tick()
        end
    end)

    tickerFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    tickerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    tickerFrame:SetScript("OnEvent", function()
        -- On group change or zone change, stop trusting our tracked set.
        scanner:resetTracking()
    end)

    return true
end

Addon.scanner = scanner
return scanner
