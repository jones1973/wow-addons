--[[
  core/options.lua (shared)

  In-memory key-value store with defaults, callbacks, and change events.
  SavedVariable persistence is NOT handled here — an addon-specific adapter
  subscribes to SETTING:* events and hydrates via options:hydrate().

  Public API:
    options:setDefaults(table)         -- register default values
    options:setCategories(table)       -- register category mapping for events
    options:hydrate(sourceTable)       -- load initial values silently (no callbacks)
    options:Get(key)                   -- read value, falling back to default
    options:Set(key, value)            -- write value, fire callbacks and events
    options:GetAll()                   -- get the full settings table
    options:GetDefault(key)            -- read the default for a key
    options:RegisterCallback(key, fn)  -- fn called on every Set of key

  Change events (one per category):
    SETTING:<CATEGORY>_CHANGED { name, oldValue, newValue, category }

  Dependencies: utils, events (optional — if absent, events are not emitted)
  Exports: Addon.options
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cffff4444Error - Addon.utils not available in options.lua|r")
    return {}
end

local utils = Addon.utils

Addon.options = Addon.options or {}
local options = Addon.options

-- Configuration set by the host addon (via setDefaults / setCategories)
local defaults = {}
local settingCategories = {}  -- key -> category name

-- In-memory store
options.settings = {}
options.callbacks = {}

-- ============================================================================
-- CONFIGURATION (called by addon before hydrate)
-- ============================================================================

--[[
  Register default values for settings.
  Keys present in hydration data override these; missing keys fall back here.

  @param tbl table - { key = defaultValue, ... }
]]
function options:setDefaults(tbl)
    defaults = tbl or {}
end

--[[
  Register category mapping for change events.
  When Set() changes a key in a category, SETTING:<CATEGORY>_CHANGED fires.

  @param tbl table - { categoryName = { "key1", "key2", ... }, ... }
]]
function options:setCategories(tbl)
    settingCategories = {}
    for category, keys in pairs(tbl or {}) do
        for _, key in ipairs(keys) do
            settingCategories[key] = category
        end
    end
end

-- ============================================================================
-- HYDRATION (called by adapter during ADDON_LOADED, before module init)
-- ============================================================================

--[[
  Load initial values from a source table without firing callbacks.
  Missing keys use registered defaults.

  This MUST run before any code calls Get() or Set(), so callbacks aren't
  triggered during startup hydration.

  @param source table - typically a SavedVariable contents
]]
function options:hydrate(source)
    source = source or {}

    -- Apply source values directly
    for k, v in pairs(source) do
        self.settings[k] = v
    end

    -- Fill in any missing keys from defaults
    for k, v in pairs(defaults) do
        if self.settings[k] == nil then
            self.settings[k] = v
        end
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function options:Get(key)
    if self.settings[key] ~= nil then
        return self.settings[key]
    end
    return defaults[key]
end

function options:Set(key, val)
    if self.settings[key] == val then
        return
    end

    local oldVal = self.settings[key]
    self.settings[key] = val
    self:TriggerCallbacks(key, val)

    if Addon.events then
        local category = settingCategories[key]
        if category then
            local eventName = "SETTING:" .. category:upper() .. "_CHANGED"
            Addon.events:emit(eventName, {
                name = key,
                oldValue = oldVal,
                newValue = val,
                category = category,
            })
        end
    end

    utils:debug(string.format("Setting %s: %s -> %s",
        tostring(key), tostring(oldVal), tostring(val)))
end

function options:RegisterCallback(key, fn)
    if not self.callbacks[key] then
        self.callbacks[key] = {}
    end
    table.insert(self.callbacks[key], fn)
end

function options:TriggerCallbacks(key, val)
    for _, fn in ipairs(self.callbacks[key] or {}) do
        fn(val, key)
    end
end

function options:GetAll()
    return self.settings
end

function options:GetDefault(key)
    return defaults[key]
end

-- Self-register with dependency system.
-- The addon's persistence adapter calls setDefaults, setCategories, and
-- hydrate BEFORE this init runs, so Get/Set are ready from here on.
if Addon.registerModule then
    Addon.registerModule("options", {"utils"}, function()
        -- Apply debug-setting callback if the addon registered a debugMode key
        if defaults.debugMode ~= nil then
            options:RegisterCallback("debugMode", function(val)
                if Addon.utils and Addon.utils.setDebugEnabled then
                    Addon.utils:setDebugEnabled(val)
                end
            end)
            -- Apply stored debug setting immediately
            options:TriggerCallbacks("debugMode", options:Get("debugMode"))
        end
        return true
    end)
end

return options
