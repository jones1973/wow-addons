--[[
  main.lua
]]

local ADDON_NAME, Addon = ...

MOBSTER = Addon

local DEFAULTS = {
    watchList     = {},
    soundEnabled  = true,
    markEnabled   = true,
}

local function initSavedVars()
    mobster_character = mobster_character or {}

    if mobster_character.version ~= Addon.constants.SV_VERSION then
        wipe(mobster_character)
        mobster_character.version = Addon.constants.SV_VERSION
    end

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
        table.insert(mobster_character.watchList, rest)
        Addon.scanner:resetTracking()
        Addon.watchList:refresh()
        Addon.utils:chat("Added: " .. rest)

    elseif cmd == "remove" and rest ~= "" then
        local lower = rest:lower()
        for i = #mobster_character.watchList, 1, -1 do
            local entry = mobster_character.watchList[i]
            local entryName = (type(entry) == "string") and entry or entry.name
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
