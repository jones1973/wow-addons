local MAJOR, MINOR = "CallbackHandler-1.0", 7
local CallbackHandler = LibStub:NewLibrary(MAJOR, MINOR)
if not CallbackHandler then return end

local meta = {__index = function(tbl, key) tbl[key] = {} return tbl[key] end}

local function errorhandler(err)
    return geterrorhandler()(err)
end

local function Dispatch(handlers, ...)
    local index = next(handlers)
    if not index then return end
    repeat
        local method = handlers[index]
        if type(method) == "string" then
            xpcall(index[method], errorhandler, index, ...)
        elseif method then
            xpcall(method, errorhandler, ...)
        end
        index = next(handlers, index)
    until not index
end

function CallbackHandler:New(target, RegisterName, UnregisterName, UnregisterAllName)
    RegisterName = RegisterName or "RegisterCallback"
    UnregisterName = UnregisterName or "UnregisterCallback"
    UnregisterAllName = UnregisterAllName or "UnregisterAllCallbacks"

    local events = setmetatable({}, meta)
    local registry = {recurse = 0, events = events}

    function registry:Fire(eventname, ...)
        if not rawget(events, eventname) or not next(events[eventname]) then return end
        local oldrecurse = registry.recurse
        registry.recurse = oldrecurse + 1
        Dispatch(events[eventname], eventname, ...)
        registry.recurse = oldrecurse
        if registry.insertQueue and oldrecurse == 0 then
            for eventname2, callbacks in pairs(registry.insertQueue) do
                local first = not rawget(events, eventname2) or not next(events[eventname2])
                for self2, func in pairs(callbacks) do
                    events[eventname2][self2] = func
                    if first and registry.OnUsed then
                        registry.OnUsed(registry, target, eventname2)
                        first = nil
                    end
                end
            end
            registry.insertQueue = nil
        end
    end

    target[RegisterName] = function(self, eventname, method, ...)
        if type(eventname) ~= "string" then
            error("Usage: "..RegisterName.."(eventname, method): 'eventname' - string expected.", 2)
        end
        method = method or eventname
        if type(method) ~= "string" and type(method) ~= "function" then
            error("Usage: "..RegisterName.."(eventname, method): 'method' - string or function expected.", 2)
        end
        local first = not rawget(events, eventname) or not next(events[eventname])
        if select("#", ...) >= 1 then
            local arg = ...
            if type(method) == "string" then
                local origMethod = method
                method = function(s, ...) s[origMethod](s, arg, ...) end
            else
                local origMethod = method
                method = function(...) origMethod(arg, ...) end
            end
        end
        if registry.recurse < 1 then
            events[eventname][self] = method
            if first and registry.OnUsed then registry.OnUsed(registry, target, eventname) end
        else
            registry.insertQueue = registry.insertQueue or setmetatable({}, meta)
            registry.insertQueue[eventname][self] = method
        end
    end

    target[UnregisterName] = function(self, eventname)
        if not self or self == target then error("Usage: "..UnregisterName.."(eventname): bad 'self'", 2) end
        if type(eventname) ~= "string" then error("Usage: "..UnregisterName.."(eventname): 'eventname' - string expected.", 2) end
        if rawget(events, eventname) and events[eventname][self] then
            events[eventname][self] = nil
            if registry.OnUnused and not next(events[eventname]) then registry.OnUnused(registry, target, eventname) end
        end
        if registry.insertQueue and rawget(registry.insertQueue, eventname) and registry.insertQueue[eventname][self] then
            registry.insertQueue[eventname][self] = nil
        end
    end

    target[UnregisterAllName] = function(self)
        if self == target then error("Usage: "..UnregisterAllName.."(): supply a meaningful 'self'", 2) end
        for eventname, callbacks in pairs(events) do
            if callbacks[self] then
                callbacks[self] = nil
                if registry.OnUnused and not next(callbacks) then registry.OnUnused(registry, target, eventname) end
            end
        end
        if registry.insertQueue then
            for eventname, callbacks in pairs(registry.insertQueue) do
                if callbacks[self] then callbacks[self] = nil end
            end
        end
    end

    return registry
end
