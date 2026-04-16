--[[
  logic/builtinCommands.lua
  PAO-specific built-in slash commands.

  These used to live in core/commands.lua but are addon-specific
  (version string, SV-backed debug toggle) and belong here instead.

  Dependencies: commands, options, utils
  Exports: nothing (commands are registered during init)
]]

local ADDON_NAME, Addon = ...

local function initialize()
    if not Addon.commands then return false end
    local utils = Addon.utils

    Addon.commands:register({
        command = "version",
        handler = function()
            print("|cff33ff99PAO|r version 2.1.0 - Battle Pet Assistant")
        end,
        help = "Show addon version",
        usage = "version",
        category = "General",
    })

    Addon.commands:register({
        command = "debug",
        handler = function()
            local current = Addon.options:Get("debugMode")
            Addon.options:Set("debugMode", not current)
            local state = Addon.options:Get("debugMode")
                and "|cff00ff00ON|r"
                or "|cffff4444OFF|r"
            utils:notify("Debug mode: " .. state)
        end,
        help = "Toggle debug mode",
        usage = "debug",
        category = "General",
    })

    return true
end

if Addon.registerModule then
    Addon.registerModule("builtinCommands", {"commands", "options", "utils"}, initialize)
end
