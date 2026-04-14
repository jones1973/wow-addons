--[[
  core/errorHandler.lua
  Global Error Capture

  Installs a custom error handler via seterrorhandler() that captures
  uncaught Lua errors originating from this addon. Errors are stored
  in pao_tools.errors for post-session review via /pao errors.

  This catches errors that happen when debug mode is off, during combat,
  or in rapid-fire event handlers where the Blizzard popup flashes too
  fast to read. The original error handler is preserved and always called,
  so Blizzard's error popup still works normally.

  Dependencies: None (must load before module init to catch init errors)
  Exports: Addon.errorHandler
]]

local ADDON_NAME, Addon = ...

local errorHandler = {}

-- Maximum stored errors (prevent unbounded SV growth)
local MAX_STORED_ERRORS = 100

--[[
  Install the global error handler.
  Called at file load time (not during module init) so it catches
  init errors from the dependency system.
]]
local function install()
    local originalHandler = geterrorhandler()

    seterrorhandler(function(err)
        local stack = debugstack(2, 5, 0)

        -- Only capture errors from this addon (folder name appears in stack)
        -- Runtime safety: this callback fires before svRegistry:initializeAll on
        -- first run (pao_tools is nil). Cannot rely on svRegistry here because
        -- errors during file loading happen before ADDON_LOADED.
        if stack and stack:find(ADDON_NAME) then
            pao_tools = pao_tools or {}
            pao_tools.errors = pao_tools.errors or {}

            -- Cap stored errors to prevent SV bloat
            if #pao_tools.errors < MAX_STORED_ERRORS then
                table.insert(pao_tools.errors, {
                    error = tostring(err),
                    stack = stack,
                    time = date("%H:%M:%S"),
                    session = pao_tools._sessionId or "?",
                })
            end
        end

        -- Always pass through to original handler
        return originalHandler(err)
    end)

    -- Tag current session so errors can be grouped.
    -- Same runtime safety as above — runs at file load, before svRegistry.
    pao_tools = pao_tools or {}
    pao_tools._sessionId = date("%Y-%m-%d %H:%M:%S")
end

--[[
  Dump captured errors to chat.
]]
function errorHandler:showErrors()
    pao_tools = pao_tools or {}
    local errors = pao_tools.errors or {}

    if #errors == 0 then
        print("|cff33ff99" .. ADDON_NAME .. "|r: No captured errors.")
        return
    end

    print("|cff33ff99" .. ADDON_NAME .. "|r: " .. #errors .. " captured error(s):")
    for i, entry in ipairs(errors) do
        print(string.format("|cffff4444[%d] %s|r %s", i, entry.time or "?", entry.error or "?"))
        if entry.stack then
            -- Print first 2 lines of stack for context
            local lines = 0
            for line in entry.stack:gmatch("[^\n]+") do
                lines = lines + 1
                if lines <= 2 then
                    print("  " .. line)
                end
            end
        end
    end
end

--[[
  Clear captured errors.
]]
function errorHandler:clearErrors()
    pao_tools = pao_tools or {}
    pao_tools.errors = {}
    print("|cff33ff99" .. ADDON_NAME .. "|r: Error log cleared.")
end

-- Install immediately at file load time
install()

-- Register commands during module init (commands system available by then)
if Addon.registerModule then
    Addon.registerModule("errorHandler", {"commands"}, function()
        if Addon.commands then
            Addon.commands:register({
                command = "errors",
                handler = function(args)
                    local action = args.action or ""
                    if action == "clear" then
                        errorHandler:clearErrors()
                    else
                        errorHandler:showErrors()
                    end
                end,
                help = "Show or clear captured errors",
                usage = "errors [clear]",
                args = {
                    {name = "action", required = false, description = "clear to reset error log"}
                },
                category = "Debug"
            })
        end
        return true
    end)
end

Addon.errorHandler = errorHandler
return errorHandler
