--[[
  main.lua
  Application Entry Point

  Owns the initialization sequence: SavedVariable defaults, schema check,
  then synchronous module initialization. Also registers the /mob slash
  command.

  Dependencies: constants, utils, scanner, typeahead, watchList
  Exports: MOBSTER (global alias for /dump debugging)
]]

local ADDON_NAME, Addon = ...

-- Single boundary between internal and external names
MOBSTER = Addon

-- Per-character SV defaults
local DEFAULTS = {
    watchList     = {},
    soundEnabled  = true,
    markEnabled   = true,
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function initSavedVars()
    mobster_character = mobster_character or {}

    -- Schema check. During development the version stays at SV_VERSION; if
    -- it doesn't match, wipe and start fresh. At release we'd replace the
    -- wipe with a migration chain.
    if mobster_character.version ~= Addon.constants.SV_VERSION then
        wipe(mobster_character)
        mobster_character.version = Addon.constants.SV_VERSION
    end

    -- Fill in missing keys without disturbing existing values
    for k, v in pairs(DEFAULTS) do
        if mobster_character[k] == nil then
            if type(v) == "table" then
                mobster_character[k] = {}
            else
                mobster_character[k] = v
            end
        end
    end
end

local function initModules()
    -- Manual topological order: logic before UI; typeahead before watchList
    -- because watchList's buildFrame calls Addon.typeahead:attach.
    Addon.scanner:initialize()
    if Addon.typeahead and Addon.typeahead.initialize then
        Addon.typeahead:initialize()
    end
    Addon.watchList:initialize()
end

-- ============================================================================
-- ADDON_LOADED
-- ============================================================================

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, arg1)
    if arg1 ~= ADDON_NAME then return end

    initSavedVars()
    initModules()
    Addon.utils:chat("Loaded. Type /mob to open.")

    self:UnregisterEvent("ADDON_LOADED")
end)

-- ============================================================================
-- SLASH COMMAND
-- ============================================================================

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
        -- Slash-add is always freeform (no Questie picker available here),
        -- so the entry is a plain string.
        table.insert(mobster_character.watchList, rest)
        Addon.scanner:resetTracking()
        Addon.watchList:refresh()
        Addon.utils:chat("Added: " .. rest)

    elseif cmd == "remove" and rest ~= "" then
        local lower = rest:lower()
        for i = #mobster_character.watchList, 1, -1 do
            local entry = mobster_character.watchList[i]
            -- Entries are strings (freeform) or tables (zone-locked).
            local pattern = (type(entry) == "string") and entry or entry.pattern
            if pattern and pattern:lower():find(lower, 1, true) then
                Addon.utils:chat("Removed: " .. pattern)
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
