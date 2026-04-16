--[[
  core/errorHandler.lua (shared)
  Global Error Capture

  Installs a custom error handler via seterrorhandler() that captures
  uncaught Lua errors originating from this addon. Errors are held in
  an in-memory ring buffer. An addon-specific adapter can persist them
  to a SavedVariable by calling getCapturedErrors() and subscribing to
  new errors via onError().

  The original error handler is preserved and always called, so Blizzard's
  error popup still works normally.

  Dependencies: None (must load at file-load time to catch init errors)
  Exports: Addon.errorHandler
]]

local ADDON_NAME, Addon = ...

local errorHandler = {}

-- Maximum stored errors (prevent unbounded memory growth)
local MAX_STORED_ERRORS = 100

-- In-memory error buffer
local errors = {}

-- Session ID for grouping errors from the same play session
local sessionId = date("%Y-%m-%d %H:%M:%S")

-- Subscribers notified on each captured error
local errorCallbacks = {}

--[[
  Install the global error handler.
  Runs at file load time so it catches init errors from the dependency system.
]]
local function install()
    local originalHandler = geterrorhandler()

    seterrorhandler(function(err)
        local stack = debugstack(2, 5, 0)

        -- Only capture errors from this addon (folder name appears in stack)
        if stack and stack:find(ADDON_NAME) then
            if #errors < MAX_STORED_ERRORS then
                local entry = {
                    error = tostring(err),
                    stack = stack,
                    time = date("%H:%M:%S"),
                    session = sessionId,
                }
                table.insert(errors, entry)

                -- Notify subscribers (adapter uses this to persist)
                for _, fn in ipairs(errorCallbacks) do
                    -- pcall: a broken callback shouldn't prevent the Blizzard handler from running
                    pcall(fn, entry)
                end
            end
        end

        -- Always pass through to original handler
        return originalHandler(err)
    end)
end

-- ============================================================================
-- PUBLIC API (used by adapter)
-- ============================================================================

--[[
  Get all errors captured so far this session.
  Called by the adapter during ADDON_LOADED to drain the buffer into the SV.
  @return table - array of { error, stack, time, session }
]]
function errorHandler:getCapturedErrors()
    return errors
end

--[[
  Get the current session ID.
  @return string
]]
function errorHandler:getSessionId()
    return sessionId
end

--[[
  Register a callback for new errors.
  Called once per error after it is added to the buffer.
  @param fn function - function(entry)
]]
function errorHandler:onError(fn)
    if type(fn) == "function" then
        table.insert(errorCallbacks, fn)
    end
end

--[[
  Clear the in-memory error buffer.
]]
function errorHandler:clearErrors()
    errors = {}
end

--[[
  Dump captured errors to chat.
]]
function errorHandler:showErrors()
    if #errors == 0 then
        print("|cff33ff99" .. ADDON_NAME .. "|r: No captured errors.")
        return
    end

    print("|cff33ff99" .. ADDON_NAME .. "|r: " .. #errors .. " captured error(s):")
    for i, entry in ipairs(errors) do
        print(string.format("|cffff4444[%d] %s|r %s", i, entry.time or "?", entry.error or "?"))
        if entry.stack then
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

-- Install immediately at file load time (before any module init)
install()

-- Register the /errors command during init (commands system available by then)
if Addon.registerModule then
    Addon.registerModule("errorHandler", {"commands"}, function()
        if Addon.commands then
            Addon.commands:register({
                command = "errors",
                handler = function(args)
                    local action = args.action or ""
                    if action == "clear" then
                        errorHandler:clearErrors()
                        print("|cff33ff99" .. ADDON_NAME .. "|r: Error log cleared.")
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
