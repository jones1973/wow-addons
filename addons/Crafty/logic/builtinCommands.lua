--[[
  logic/builtinCommands.lua
  Crafty Built-In Commands

  Registers Crafty's slash subcommands with the shared commands module.
  Build 1: a window toggle and a debug toggle.

  Dependencies: commands, options, craftingWindow
  Exports: none (registration side-effect only)
]]

local ADDON_NAME, Addon = ...

local builtinCommands = {}

local commands, options, craftingWindow

function builtinCommands:initialize()
    commands = Addon.commands
    options = Addon.options
    craftingWindow = Addon.craftingWindow

    if not commands then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444builtinCommands: Missing dependencies|r")
        return false
    end

    commands:register({
        command = "show",
        aliases = { "open", "window" },
        handler = function()
            if craftingWindow then craftingWindow:show() end
        end,
        help = "Open the crafting window",
        usage = "show",
        category = "General",
    })

    commands:register({
        command = "debug",
        handler = function()
            if options then
                local now = options:Get("debugMode")
                options:Set("debugMode", not now)
                print("|cff33ff99Crafty|r: debug " .. (not now and "ON" or "OFF"))
            end
        end,
        help = "Toggle debug output",
        usage = "debug",
        category = "General",
    })

    return true
end

if Addon.registerModule then
    Addon.registerModule("builtinCommands", {"commands", "options", "craftingWindow"}, function()
        return builtinCommands:initialize()
    end)
end

Addon.builtinCommands = builtinCommands
return builtinCommands
