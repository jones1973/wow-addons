local addonName, ns = ...

-- Event frame
local frameEvent = CreateFrame("Frame")
local eventsRegistered = {}

local function eventRegister(event, handler)
    if not eventsRegistered[event] then
        frameEvent:RegisterEvent(event)
        eventsRegistered[event] = {}
    end
    table.insert(eventsRegistered[event], handler)
end

frameEvent:SetScript("OnEvent", function(self, event, ...)
    local handlers = eventsRegistered[event]
    if not handlers then return end
    for _, handler in ipairs(handlers) do
        handler(event, ...)
    end
end)

ns.eventRegister = eventRegister

-- Saved variables defaults
local DEFAULTS_GLOBAL = {
    versionData = 1,
    frameWidth = 1050,
    frameHeight = 550,
}

local DEFAULTS_CHAR = {
    goalsActive = {},   -- { [factionID] = standingTarget }
    itemsSelected = {}, -- { [itemID] = true }
    itemsExcluded = {}, -- { [questID] = true } (quests the user unchecked)
}

local function defaultsApply(target, defaults)
    for k, v in pairs(defaults) do
        if target[k] == nil then
            if type(v) == "table" then
                target[k] = {}
                defaultsApply(target[k], v)
            else
                target[k] = v
            end
        end
    end
end

-- Initialization
local function onAddonLoaded(event, loadedAddon)
    if loadedAddon ~= addonName then return end

    NowWhatDB = NowWhatDB or {}
    NowWhatCharDB = NowWhatCharDB or {}

    defaultsApply(NowWhatDB, DEFAULTS_GLOBAL)
    defaultsApply(NowWhatCharDB, DEFAULTS_CHAR)

    ns.db = NowWhatDB
    ns.charDb = NowWhatCharDB

    ns.characterStateInit()

    print("|cff33ff99NowWhat|r loaded. Type /nw for commands.")
end

eventRegister("ADDON_LOADED", onAddonLoaded)

-- Slash commands
SLASH_NOWWHAT1 = "/nw"
SLASH_NOWWHAT2 = "/nowwhat"

local commandHandlers = {}

ns.commandRegister = function(cmd, handler, description)
    commandHandlers[cmd] = { handler = handler, description = description }
end

SlashCmdList["NOWWHAT"] = function(input)
    local cmd, args = input:match("^(%S+)%s*(.*)")
    cmd = cmd and cmd:lower() or "help"

    local entry = commandHandlers[cmd]
    if entry then
        entry.handler(args)
    else
        print("|cff33ff99NowWhat|r commands:")
        for name, data in pairs(commandHandlers) do
            print(string.format("  /nw %s - %s", name, data.description))
        end
    end
end
