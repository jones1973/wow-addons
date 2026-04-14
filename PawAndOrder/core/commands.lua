-- core/commands.lua (add built-in command registration)
local _, Addon = ...
local utils = Addon.utils

local commands = {}
commands._registry = {}

function commands:register(spec)
    assert(spec.command and spec.handler and spec.help and spec.usage,
        "Command spec must include command, handler, help, usage")
    spec.aliases = spec.aliases or {}
    spec.category = spec.category or "General"
    self._registry[spec.command] = spec
    for _, alias in ipairs(spec.aliases) do
        self._registry[alias] = spec
    end
end

function commands:execute(msg)
    local args = {}
    for word in msg:gmatch("%S+") do table.insert(args, word) end
    local cmd = table.remove(args, 1)
    
    if not cmd or cmd == "" then
        self:showHelp()
        return
    end
    
    local spec = self._registry[cmd]
    if not spec then
        utils:error(("Unknown command '%s'. Type |cFFFFFF00/pao help|r for available commands"):format(cmd))
        return
    end
    local parsed = {}
    for i, def in ipairs(spec.args or {}) do
        parsed[def.name] = args[i]
    end
    spec.handler(parsed)
end

function commands:showHelp(name)
    if name then
        local spec = self._registry[name]
        if not spec then
            utils:error(("No help for '%s'"):format(name))
            return
        end
        print(("|cFFFFD100Command:|r %s"):format(spec.usage))
        print(("|cFFFFD100%s|r"):format(spec.help))
        if spec.args then
            print("|cFFFFD100Arguments:|r")
            for _,a in ipairs(spec.args) do
                local br = a.required and "<%s>" or "[%s]"
                print(("  "..br.."  %s"):format(a.name, a.description))
            end
        end
        if spec.detailedHelp then
            print(spec.detailedHelp)
        end
    else
        local cats={}
        for _,spec in pairs(self._registry) do
            cats[spec.category] = cats[spec.category] or {}
            if not cats[spec.category][spec.command] then
                cats[spec.category][spec.command] = spec
            end
        end
        for category,cmds in pairs(cats) do
            print(("|cFFFFD100%s|r:"):format(category))
            for _,spec in pairs(cmds) do
                local aliasTxt = #spec.aliases>0 and "|"..table.concat(spec.aliases,"|") or ""
                local usageArgs = spec.usage:match("%S+%s*(.*)")
                print(("  %s%s %s - %s"):format(spec.command, aliasTxt, usageArgs, spec.help))
            end
        end
        print("Type |cFFFFFF00/pao help <|cFFFFCC9Acommand|r>|r for details.")
    end
end

function commands:registerBuiltInCommands()
    -- Help command
    self:register({
        command = "help",
        handler = function(args) self:showHelp(args.command) end,
        help = "Show help for commands",
        usage = "help [|cFFFFCC9Acommand|r]",
        args = {
            {name = "command", required = false, description = "Specific command to get help for"}
        },
        detailedHelp = [[
❓ List all commands or show detailed help for one command.

Usage: /pao help
       /pao help <|cFFFFCC9Acommand|r>
]],
        category = "General"
    })
    
    -- Version command
    self:register({
        command = "version",
        handler = function() 
            print("|cff33ff99PAO|r version 2.1.0 - Battle Pet Assistant")
        end,
        help = "Show addon version",
        usage = "version",
        detailedHelp = "ℹ️ Display Paw and Order version information.",
        category = "General"
    })
    
    -- Debug command
    self:register({
        command = "debug",
        handler = function()
            pao_settings.debugMode = not pao_settings.debugMode
            utils:notify("Debug mode: " .. (pao_settings.debugMode and "|cff00ff00ON|r" or "|cffff4444OFF|r"))
        end,
        help = "Toggle debug mode",
        usage = "debug",
        detailedHelp = "🐞 Toggle debugging messages on/off.",
        category = "General"
    })

	-- Debug dependencies command
	self:register({
		command = "deps",
		aliases = {"dependencies"},
		handler = function()
			if Addon.debugDependencies then
				Addon.debugDependencies()
			else
				utils:error("Dependency debug function not available")
			end
		end,
		help = "Show module dependency status",
		usage = "deps",
		category = "Debug"
	})
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("commands", {"utils"}, function()
        if commands.registerBuiltInCommands then
            commands:registerBuiltInCommands()
            return true
        end
        return false
    end)
end

Addon.commands = commands
return commands