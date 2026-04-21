--[[
  logic/builtinCommands.lua
  Pawn Shop's Addon-Specific Slash Commands

  The shared commands module ships /help, /deps, /svs, /errors generically.
  This file registers Pawn Shop's own commands:

    /ps pawn             -- dump Pawn scores for currently equipped MH + OH
    /ps pawn <link>      -- dump Pawn scores for a specific item (shift-click)
    /ps debug [on|off]   -- toggle debug logging (shorthand for the option)

  Dependencies: commands, utils, options, pawnIntegration
  Exports: none (just registers commands)
]]

local ADDON_NAME, Addon = ...

local builtinCommands = {}

function builtinCommands:initialize()
    local commands        = Addon.commands
    local utils           = Addon.utils
    local options         = Addon.options
    local pawnIntegration = Addon.pawnIntegration

    if not commands or not utils or not options or not pawnIntegration then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444builtinCommands: Missing deps|r")
        return false
    end

    -- ========================================================================
    -- /ps pawn
    -- ========================================================================

    commands:register({
        command = "pawn",
        handler = function(args)
            local rest = args.link or ""

            -- No arg: dump currently equipped MH + OH.
            if rest == "" then
                local mh = GetInventoryItemLink("player", 16)
                local oh = GetInventoryItemLink("player", 17)
                pawnIntegration:dumpForLink(mh, "MH (equipped, slot 16)")
                pawnIntegration:dumpForLink(oh, "OH (equipped, slot 17)")
                return
            end

            -- Try to find an item link in the argument string (shift-click
            -- insert, or a raw link pasted in).
            local link = rest:match("(|c%x+|Hitem:.-|h%[.-%]|h|r)")
            if not link then
                link = rest:match("(|Hitem:.-|h.-|h)")
            end
            if not link then
                utils:chat("Couldn't parse an item link from: " .. rest)
                return
            end
            pawnIntegration:dumpForLink(link, "Item")
        end,
        help = "Dump Pawn scores for equipped MH+OH, or a shift-clicked item",
        usage = "pawn [<item link>]",
        args = {
            { name = "link", required = false, description = "Shift-click an item to include" },
        },
        category = "Debug",
    })

    -- ========================================================================
    -- /ps debug [on|off]
    -- ========================================================================

    commands:register({
        command = "debug",
        handler = function(args)
            local val = args.state
            if val == nil or val == "" then
                -- Toggle
                local cur = options:Get("debugMode")
                options:Set("debugMode", not cur)
                utils:chat("debug: " .. (options:Get("debugMode") and "on" or "off"))
            elseif val == "on" or val == "true" or val == "1" then
                options:Set("debugMode", true)
                utils:chat("debug: on")
            elseif val == "off" or val == "false" or val == "0" then
                options:Set("debugMode", false)
                utils:chat("debug: off")
            else
                utils:chat("debug: unknown state '" .. tostring(val) .. "'; use on|off or nothing to toggle")
            end
        end,
        help = "Toggle debug logging (scan/eval phase markers to chat)",
        usage = "debug [on|off]",
        args = {
            { name = "state", required = false, description = "on, off, or empty to toggle" },
        },
        category = "Debug",
    })

    return true
end

if Addon.registerModule then
    Addon.registerModule("builtinCommands", {"commands", "utils", "options", "pawnIntegration"}, function()
        return builtinCommands:initialize()
    end)
end

return builtinCommands
