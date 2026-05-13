--[[
  core/options.lua (shared)

  In-memory key-value store with two scopes (account / per-character),
  defaults, callbacks, and change events. SavedVariable persistence is
  NOT handled here — an addon-specific adapter subscribes to SETTING:*
  events and hydrates via options:hydrate().

  Public API:
    options:setDefaults(table)               -- register account-wide default values
    options:setCategories(table)             -- category mapping for events
    options:hydrate({account, character})    -- load initial values silently
    options:Get(key)                         -- char if set, else account, else default
    options:GetCharacter(key)                -- explicit char value or nil
    options:GetAccount(key)                  -- explicit account value or default
    options:SetCharacter(key, value)         -- write per-char override
    options:SetAccount(key, value)           -- write account-wide value
    options:PromoteCharacterToAccount(key)   -- char -> account, clear char
    options:ResetCharacterOverride(key)      -- clear char override
    options:GetAll()                         -- merged effective view
    options:GetDefault(key)                  -- registered default
    options:RegisterCallback(key, fn)        -- fn called on every effective-value change

  Change events (one per category):
    SETTING:<CATEGORY>_CHANGED { name, oldValue, newValue, category }
    Fires only when the EFFECTIVE value (what Get returns) changes.

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

-- In-memory store: account-wide values
options.settings = {}
-- In-memory store: per-character overrides
options.charSettings = {}
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
  Load initial values from SavedVariable tables without firing callbacks.
  Missing account-wide keys fall back to registered defaults.

  This MUST run before any code calls Get/SetAccount/SetCharacter, so
  callbacks aren't triggered during startup hydration.

  @param source table - { account = ps_settings, character = ps_character }
]]
function options:hydrate(source)
    source = source or {}
    local account   = source.account   or {}
    local character = source.character or {}

    -- Account-wide
    for k, v in pairs(account) do
        self.settings[k] = v
    end
    -- Fill in any missing account keys from registered defaults
    for k, v in pairs(defaults) do
        if self.settings[k] == nil then
            self.settings[k] = v
        end
    end

    -- Per-character overrides (no defaults — empty means "no override")
    for k, v in pairs(character) do
        self.charSettings[k] = v
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Read a setting. Per-character override wins; falls back to account
  value, then to registered default.
]]
function options:Get(key)
    if self.charSettings[key] ~= nil then
        return self.charSettings[key]
    end
    if self.settings[key] ~= nil then
        return self.settings[key]
    end
    return defaults[key]
end

--[[
  Read explicit per-character value. Returns nil if no override.
]]
function options:GetCharacter(key)
    return self.charSettings[key]
end

--[[
  Read explicit account value. Falls back to default if not set.
]]
function options:GetAccount(key)
    if self.settings[key] ~= nil then
        return self.settings[key]
    end
    return defaults[key]
end

local function fireChangeEvent(key, oldVal, newVal)
    if not Addon.events then return end
    local category = settingCategories[key]
    if not category then return end
    Addon.events:emit("SETTING:" .. category:upper() .. "_CHANGED", {
        name     = key,
        oldValue = oldVal,
        newValue = newVal,
        category = category,
    })
end

--[[
  Write a per-character override. Fires SETTING:<CATEGORY>_CHANGED.
]]
function options:SetCharacter(key, val)
    if self.charSettings[key] == val then return end
    local oldVal = self:Get(key)   -- effective value before the write
    self.charSettings[key] = val
    self:TriggerCallbacks(key, val)
    fireChangeEvent(key, oldVal, val)
    utils:debug(string.format("Setting (char) %s: %s -> %s",
        tostring(key), tostring(oldVal), tostring(val)))
end

--[[
  Write the account-wide value. Fires SETTING:<CATEGORY>_CHANGED only
  if there isn't a per-character override masking the value.
]]
function options:SetAccount(key, val)
    if self.settings[key] == val then return end
    local oldVal = self:Get(key)
    self.settings[key] = val
    -- If a per-char override exists, the effective value didn't change,
    -- so don't fire the event or run callbacks for value-changed semantics.
    -- Listeners that care about the account value specifically can be
    -- added later if a use case appears.
    if self.charSettings[key] == nil then
        self:TriggerCallbacks(key, val)
        fireChangeEvent(key, oldVal, val)
    end
    utils:debug(string.format("Setting (account) %s: %s -> %s",
        tostring(key), tostring(oldVal), tostring(val)))
end

--[[
  Promote the per-character override for a key into the account value,
  then clear the override. Used by "Save current as defaults" flows.
]]
function options:PromoteCharacterToAccount(key)
    if self.charSettings[key] == nil then return end
    local val = self.charSettings[key]
    self.charSettings[key] = nil
    self.settings[key] = val
    -- Effective value didn't change; don't fire event.
end

--[[
  Clear the per-character override for a key so reads fall through to
  the account value.
]]
function options:ResetCharacterOverride(key)
    if self.charSettings[key] == nil then return end
    local oldVal = self.charSettings[key]
    self.charSettings[key] = nil
    local newVal = self:Get(key)
    if newVal ~= oldVal then
        self:TriggerCallbacks(key, newVal)
        fireChangeEvent(key, oldVal, newVal)
    end
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
    -- Merged effective view: account values with per-char overrides.
    local out = {}
    for k, v in pairs(self.settings) do out[k] = v end
    for k, v in pairs(self.charSettings) do out[k] = v end
    return out
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
