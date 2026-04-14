--[[
  core/events.lua
  Unified Event System
  
  Single pub/sub system for both WoW game events and internal addon events.
  
  Convention:
    - WoW events: ALL_CAPS (e.g., PET_JOURNAL_LIST_UPDATE)
    - Addon events: NAMESPACE:NAME (e.g., "LISTING:FILTER_CHANGED")
  
  API:
    subId = events:subscribe(eventName, handler)  -- Returns subscription ID
    events:unsubscribe(subId)                     -- Remove by ID
    events:emit(eventName, payload)               -- Fire addon event
  
  Usage:
    -- Permanent subscriber (ignore return)
    events:subscribe("PET_JOURNAL_LIST_UPDATE", function(event, ...)
        -- handle WoW event
    end)
    
    -- Permanent subscriber for addon event
    events:subscribe("LISTING:FILTER_CHANGED", function(event, payload)
        print(payload.text)
    end)
    
    -- Temporary subscriber (store ID for later cleanup)
    local subId = events:subscribe("BATTLE:COMPLETE", handler)
    -- later...
    events:unsubscribe(subId)
    
    -- Emit addon event
    events:emit("LISTING:FILTER_CHANGED", { text = "beast" })
  
  Dependencies: None (lazy-loads utils for error reporting)
  Exports: Addon.events
]]

local ADDON_NAME, Addon = ...

local events = {}
local eventFrame = CreateFrame("Frame")

-- Handler storage: eventName -> { [subId] = handler }
local handlers = {}

-- Subscription tracking
local nextSubId = 1
local subIdToEvent = {}  -- subId -> eventName (for unsubscribe lookup)

-- Lazy-loaded utils reference
local utils = nil

--[[
  Check if event is a WoW event vs addon event.
  WoW events are ALL_CAPS without colons.
  Addon events use NAMESPACE:NAME format.
  
  @param eventName string
  @return boolean - true if WoW event
]]
local function isWoWEvent(eventName)
    return not eventName:find(":")
end

--[[
  Internal dispatch - calls all handlers for an event.
  Used by both WoW event frame and emit().
  Iterates over a snapshot to allow handlers to unsubscribe safely.
  
  @param eventName string
  @param ... any - Event arguments (WoW) or payload (addon)
]]
local function dispatch(eventName, ...)
    local eventHandlers = handlers[eventName]
    if not eventHandlers then return end
    
    -- Snapshot handler IDs to allow safe unsubscribe during iteration
    local handlerIds = {}
    for subId in pairs(eventHandlers) do
        table.insert(handlerIds, subId)
    end
    
    for _, subId in ipairs(handlerIds) do
        local handler = eventHandlers[subId]
        if handler then
            -- Isolate each handler: one failure must not prevent remaining
            -- handlers from running. Without this, handler #2 throwing stops
            -- handlers #3-5 from ever executing — silent downstream breakage.
            local ok, err = pcall(handler, eventName, ...)
            if not ok then
                -- Lazy-load utils for error reporting (events is pre-initialized,
                -- so utils may not exist yet during very early dispatch)
                if not utils then utils = Addon.utils end
                if utils then
                    utils:error(string.format("Handler error on '%s' (subId %d): %s",
                        eventName, subId, tostring(err)))
                else
                    print(string.format("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444Handler error on '%s': %s|r",
                        eventName, tostring(err)))
                end
            end
        end
    end
end

-- WoW events dispatch through here
eventFrame:SetScript("OnEvent", function(self, event, ...)
    dispatch(event, ...)
end)

--[[
  Subscribe to an event.
  Works for both WoW events and addon events.
  
  @param eventName string - Event name (WoW or addon)
  @param handler function - Callback: function(eventName, ...) for WoW, function(eventName, payload) for addon
  @return number - Subscription ID for later unsubscribe
]]
function events:subscribe(eventName, handler)
    if type(eventName) ~= "string" then
        error("events:subscribe - eventName must be a string", 2)
    end
    if type(handler) ~= "function" then
        error("events:subscribe - handler must be a function", 2)
    end
    
    -- Initialize handler table for this event
    if not handlers[eventName] then
        handlers[eventName] = {}
        
        -- Register with WoW if it's a WoW event
        if isWoWEvent(eventName) then
            eventFrame:RegisterEvent(eventName)
        end
    end
    
    -- Assign subscription ID
    local subId = nextSubId
    nextSubId = nextSubId + 1
    
    handlers[eventName][subId] = handler
    subIdToEvent[subId] = eventName
    
    return subId
end

--[[
  Unsubscribe from an event.
  
  @param subId number - Subscription ID returned from subscribe()
]]
function events:unsubscribe(subId)
    if type(subId) ~= "number" then
        error("events:unsubscribe - subId must be a number", 2)
    end
    
    local eventName = subIdToEvent[subId]
    if not eventName then return end
    
    subIdToEvent[subId] = nil
    
    if handlers[eventName] then
        handlers[eventName][subId] = nil
        
        -- If no handlers left, clean up
        if not next(handlers[eventName]) then
            handlers[eventName] = nil
            
            -- Unregister from WoW if it was a WoW event
            if isWoWEvent(eventName) then
                eventFrame:UnregisterEvent(eventName)
            end
        end
    end
end

--[[
  Emit an addon event.
  Only for addon events (NAMESPACE:NAME format).
  WoW events are fired by the game, not by us.
  
  @param eventName string - Addon event name
  @param payload any - Data to pass to handlers
]]
function events:emit(eventName, payload)
    if type(eventName) ~= "string" then
        error("events:emit - eventName must be a string", 2)
    end
    
    -- No subscribers - silently return
    if not handlers[eventName] then
        return
    end
    
    dispatch(eventName, payload)
end

--[[
  Get subscriber count for an event (debugging).
  
  @param eventName string
  @return number
]]
function events:getSubscriberCount(eventName)
    if not handlers[eventName] then return 0 end
    local count = 0
    for _ in pairs(handlers[eventName]) do
        count = count + 1
    end
    return count
end

--[[
  Get all registered events (debugging).
  
  @return table - Map of eventName -> subscriber count
]]
function events:getAllEvents()
    local result = {}
    for eventName, eventHandlers in pairs(handlers) do
        local count = 0
        for _ in pairs(eventHandlers) do count = count + 1 end
        result[eventName] = count
    end
    return result
end

--[[
  Debug output of all events and subscriber counts.
]]
function events:debug()
    if not utils then utils = Addon.utils end
    
    local function output(msg)
        if utils then
            utils:chat(msg, true)
        else
            print("PAO: " .. msg)
        end
    end
    
    output("=== Events Debug ===")
    
    local wowEvents = {}
    local addonEvents = {}
    
    for eventName, eventHandlers in pairs(handlers) do
        local count = 0
        for _ in pairs(eventHandlers) do count = count + 1 end
        
        if isWoWEvent(eventName) then
            table.insert(wowEvents, string.format("  %s: %d", eventName, count))
        else
            table.insert(addonEvents, string.format("  %s: %d", eventName, count))
        end
    end
    
    table.sort(wowEvents)
    table.sort(addonEvents)
    
    if #wowEvents > 0 then
        output("WoW Events:")
        for _, line in ipairs(wowEvents) do
            output(line)
        end
    end
    
    if #addonEvents > 0 then
        output("Addon Events:")
        for _, line in ipairs(addonEvents) do
            output(line)
        end
    end
    
    if #wowEvents == 0 and #addonEvents == 0 then
        output("No events registered")
    end
end

Addon.events = events
return events