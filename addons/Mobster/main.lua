--[[
  main.lua
]]

local ADDON_NAME, Addon = ...

MOBSTER = Addon

-- Per-character data. Only the watch list itself is character-scoped —
-- every preference (sound, mark, framePos, sort, filters, group
-- expand-state) lives in mobster_settings (account-wide).
local CHARACTER_DEFAULTS = {
    watchList = {},
}

-- Account-wide preferences. The toggle states for sound/mark live
-- here even though the filtering they govern is character-data driven
-- (party state, target GUID): the preference is "do I want this
-- behavior?", not "is this character configured for it?".
local SETTINGS_DEFAULTS = {
    soundEnabled = true,
    markEnabled  = true,
    framePos     = nil,
    filters      = nil,     -- bootstrapped to defaults inside itemAddPanel
    listSort     = nil,     -- reserved for sort direction
    expandedKeys = nil,     -- reserved for group expand state
}

-- 8-char hex identity, stable per entry. Used by listView to track
-- rows across refreshes without depending on array index.
--
-- Range is capped at 2^31-1 because Lua 5.1's math.random requires
-- both bounds fit in a signed 32-bit int; 0xffffffff overflows. The
-- 31-bit space (~2.1 billion values) is still vastly more than any
-- plausible watchList size needs to avoid collisions.
local function genId()
    return string.format("%08x", math.random(0, 0x7fffffff))
end

local function initSavedVars()
    -- Per-character init. Schema-version mismatch wipes; there is no
    -- in-place migration. The current schema requires every watchList
    -- entry to be a table with an _id, and every creation path
    -- (slash command, edit panel, itemAddPanel batch commit) goes
    -- through Addon.newEntry to ensure that.
    mobster_character = mobster_character or {}

    if mobster_character.version ~= Addon.constants.CHARACTER_SV_VERSION then
        wipe(mobster_character)
        mobster_character.version = Addon.constants.CHARACTER_SV_VERSION
    end

    for k, v in pairs(CHARACTER_DEFAULTS) do
        if mobster_character[k] == nil then
            if type(v) == "table" then
                mobster_character[k] = {}
            else
                mobster_character[k] = v
            end
        end
    end

    -- Account-wide init
    mobster_settings = mobster_settings or {}

    if mobster_settings.version ~= Addon.constants.SETTINGS_SV_VERSION then
        wipe(mobster_settings)
        mobster_settings.version = Addon.constants.SETTINGS_SV_VERSION
    end

    for k, v in pairs(SETTINGS_DEFAULTS) do
        if mobster_settings[k] == nil and v ~= nil then
            if type(v) == "table" then
                mobster_settings[k] = {}
            else
                mobster_settings[k] = v
            end
        end
    end
end

local function initModules()
    Addon.scanner:initialize()
    if Addon.questieHelpers and Addon.questieHelpers.initialize then
        Addon.questieHelpers:initialize()
    end
    if Addon.itemDropIndex and Addon.itemDropIndex.initialize then
        Addon.itemDropIndex:initialize()
    end
    if Addon.nameTypeahead and Addon.nameTypeahead.initialize then
        Addon.nameTypeahead:initialize()
    end
    if Addon.zoneTypeahead and Addon.zoneTypeahead.initialize then
        Addon.zoneTypeahead:initialize()
    end
    if Addon.reasonTypeahead and Addon.reasonTypeahead.initialize then
        Addon.reasonTypeahead:initialize()
    end
    Addon.editPanel:initialize()
    if Addon.itemAddPanel and Addon.itemAddPanel.initialize then
        Addon.itemAddPanel:initialize()
    end
    Addon.watchList:initialize()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, arg1)
    if arg1 ~= ADDON_NAME then return end

    initSavedVars()
    initModules()
    Addon.utils:chat("Loaded. Type /mob to open.")

    self:UnregisterEvent("ADDON_LOADED")
end)

-- Expose the entry-migration helper for slash commands and panels
-- that create new entries.
Addon.newEntry = function(fields)
    local e = fields or {}
    e._id = genId()
    return e
end

SLASH_MOBSTER1 = "/mob"
SlashCmdList["MOBSTER"] = function(msg)
    msg = (msg or ""):trim()

    if msg == "" then
        Addon.watchList:toggle()
        return
    end

    local cmd, rest = msg:match("^(%S+)%s*(.*)")
    cmd  = cmd  and cmd:lower()  or ""
    rest = rest and rest:trim() or ""

    if cmd == "add" and rest ~= "" then
        table.insert(mobster_character.watchList,
            Addon.newEntry({ name = rest }))
        Addon.scanner:resetTracking()
        Addon.watchList:refresh()
        Addon.utils:chat("Added: " .. rest)

    elseif cmd == "remove" and rest ~= "" then
        local lower = rest:lower()
        for i = #mobster_character.watchList, 1, -1 do
            local entry = mobster_character.watchList[i]
            local entryName = entry.name
            if entryName and entryName:lower():find(lower, 1, true) then
                Addon.utils:chat("Removed: " .. entryName)
                table.remove(mobster_character.watchList, i)
                break
            end
        end
        Addon.scanner:resetTracking()
        Addon.watchList:refresh()

    else
        Addon.utils:chat("Usage:")
        Addon.utils:chat("  /mob  - toggle UI")
        Addon.utils:chat("  /mob add <partial>  - add to watch list")
        Addon.utils:chat("  /mob remove <partial>  - remove from watch list")
    end
end
