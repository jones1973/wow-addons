--[[
  persistence.lua
  Pawn Shop's Adapter Between Shared Modules and SavedVariables

  The shared modules (options, tabs, errorHandler) hold state in memory
  and are SavedVariable-agnostic by design. This adapter bridges them to
  Pawn Shop's specific SV names and schema.

  Two lifecycle hooks:

    configureOptions()  -- Called at file-load time (from main.lua), before
                           ADDON_LOADED. Registers option defaults and category
                           mapping with Addon.options.

    attach()            -- Called during ADDON_LOADED after SV init but before
                           module init. Hydrates shared modules from SVs and
                           subscribes to change events for persistence.

  We don't use tabs in Pawn Shop currently (single AH tab panel), so the
  tabs persistence isn't wired up - would be straightforward to add later.

  Dependencies: options, events, errorHandler, data.settingDefaults,
                data.settingCategories
  Exports: Addon.persistence
]]

local ADDON_NAME, Addon = ...

local persistence = {}

-- Maximum captured errors to keep in the SV (ring buffer cap).
local MAX_STORED_ERRORS = 100

-- ============================================================================
-- FILE-LOAD TIME: register defaults + categories with shared options module
-- ============================================================================

--[[
  Called from main.lua at file-load time, BEFORE ADDON_LOADED.
  Reads default values from data/settingDefaults.lua and registers them
  with the shared options module.
]]
function persistence:configureOptions()
    if not Addon.options then return end
    if not Addon.data then return end

    if Addon.data.settingDefaults then
        Addon.options:setDefaults(Addon.data.settingDefaults)
    end
    if Addon.data.settingCategories then
        Addon.options:setCategories(Addon.data.settingCategories)
    end
end

-- ============================================================================
-- ADDON_LOADED: hydrate shared modules from SVs and wire up persistence
-- ============================================================================

--[[
  Called from main.lua during ADDON_LOADED, AFTER svRegistry:initializeAll()
  creates/migrates the SVs and BEFORE dependency:initializeAllModules()
  runs module init.

  Order within attach matters: hydrate before subscribing so we don't fire
  "changed" events for every stored value during startup.
]]
function persistence:attach()
    self:attachOptions()
    self:attachErrorHandler()
end

--[[
  Wire Addon.options to ps_settings.
  Hydrates the in-memory store from the SV, then subscribes to every
  SETTING:<CATEGORY>_CHANGED event to mirror changes back to the SV.
]]
function persistence:attachOptions()
    if not Addon.options or not Addon.events then return end

    ps_settings = ps_settings or {}
    Addon.options:hydrate(ps_settings)

    -- Categories defined in data/settingDefaults.lua map to these events.
    -- One handler per category keeps things explicit and easy to extend.
    local categories = { "GENERAL", "DISPLAY", "FILTER" }
    for _, category in ipairs(categories) do
        Addon.events:subscribe("SETTING:" .. category .. "_CHANGED", function(_, payload)
            ps_settings[payload.name] = payload.newValue
        end)
    end
end

--[[
  Wire Addon.errorHandler to ps_tools.errors.
  Drains the in-memory buffer (errors captured during file-load / init)
  into the SV, then subscribes for any subsequent errors.
]]
function persistence:attachErrorHandler()
    if not Addon.errorHandler then return end

    ps_tools = ps_tools or {}
    ps_tools.errors = ps_tools.errors or {}

    -- Drain startup buffer
    for _, entry in ipairs(Addon.errorHandler:getCapturedErrors()) do
        if #ps_tools.errors < MAX_STORED_ERRORS then
            table.insert(ps_tools.errors, entry)
        end
    end

    -- Persist future errors as they happen
    Addon.errorHandler:onError(function(entry)
        if #ps_tools.errors < MAX_STORED_ERRORS then
            table.insert(ps_tools.errors, entry)
        end
    end)
end

-- ============================================================================
-- PER-CHARACTER OVERRIDE ACCESSORS
-- ============================================================================

-- Pawn Shop has two-tier settings: per-character overrides that fall back
-- to account-wide defaults. Account-wide values live in Addon.options
-- (backed by ps_settings). Per-character overrides live in ps_character.
--
-- Usage:
--   local lvl = Addon.persistence:getCharacterSetting("levelTolerance")
--   Addon.persistence:setCharacterSetting("levelTolerance", 5)
--   Addon.persistence:resetCharacterSetting("levelTolerance")

--[[
  Read a setting with per-character override precedence.
  Returns character value if set, else account-wide options value, else default.

  @param key string
  @return value
]]
function persistence:getCharacterSetting(key)
    ps_character = ps_character or {}
    if ps_character[key] ~= nil then
        return ps_character[key]
    end
    if Addon.options then
        return Addon.options:Get(key)
    end
end

--[[
  Write a per-character override. This does NOT change the account-wide
  default - it sets a character-specific value that shadows it.

  @param key string
  @param value any
]]
function persistence:setCharacterSetting(key, value)
    ps_character = ps_character or {}
    ps_character[key] = value
end

--[[
  Clear a per-character override so the setting falls back to the
  account-wide default.

  @param key string
]]
function persistence:resetCharacterSetting(key)
    if ps_character then
        ps_character[key] = nil
    end
end

--[[
  "Save as defaults for all characters": copy the current character's
  per-character overrides into the account-wide options, then clear the
  per-character table so everything uses the new defaults.

  Called by the options-screen "Save as Defaults" button.
]]
function persistence:saveCharacterAsDefaults()
    if not ps_character or not Addon.options then return end
    for key, val in pairs(ps_character) do
        Addon.options:Set(key, val)
    end
    ps_character = {}
end

Addon.persistence = persistence
return persistence
