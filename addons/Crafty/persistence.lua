--[[
  persistence.lua
  Crafty Persistence Adapter

  Bridges the shared SavedVariable-agnostic modules (options, errorHandler) to
  Crafty's specific SV names and schema.

  Two lifecycle hooks called from main.lua:

    configureOptions()  - file-load time, before ADDON_LOADED. Registers option
                          defaults and categories (from data/settingDefaults.lua)
                          with Addon.options.

    attach()            - during ADDON_LOADED, after svRegistry:initializeAll()
                          creates/migrates SVs and before module init. Hydrates
                          shared modules from SVs and subscribes for persistence.

  The ledger SVs (crafty_recipe, crafty_character) are declared via
  svRegistry in main.lua; this adapter does not create them. It only bridges
  the shared in-memory modules to their SVs.

  Dependencies: options, events, errorHandler, data.settingDefaults
  Exports: Addon.persistence
]]

local ADDON_NAME, Addon = ...

local persistence = {}

local MAX_STORED_ERRORS = 100

-- ============================================================================
-- FILE-LOAD: register defaults + categories with the shared options module
-- ============================================================================

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
-- ADDON_LOADED: hydrate shared modules from SVs and wire persistence
-- ============================================================================

function persistence:attach()
    self:attachOptions()
    self:attachErrorHandler()
end

--[[
  Hydrate Addon.options from crafty_settings and mirror future changes back.
  The shared options module is flat (single source table); hydrate before
  subscribing so startup does not fire change events.
]]
function persistence:attachOptions()
    if not Addon.options or not Addon.events then return end

    crafty_settings = crafty_settings or {}
    Addon.options:hydrate(crafty_settings)

    Addon.events:subscribe("SETTING:GENERAL_CHANGED", function(_, payload)
        crafty_settings[payload.name] = payload.newValue
    end)
end

--[[
  Drain the errorHandler startup buffer into crafty_tools.errors and persist
  subsequent errors.
]]
function persistence:attachErrorHandler()
    if not Addon.errorHandler then return end

    crafty_tools = crafty_tools or {}
    crafty_tools.errors = crafty_tools.errors or {}

    for _, entry in ipairs(Addon.errorHandler:getCapturedErrors()) do
        if #crafty_tools.errors < MAX_STORED_ERRORS then
            table.insert(crafty_tools.errors, entry)
        end
    end

    Addon.errorHandler:onError(function(entry)
        if #crafty_tools.errors < MAX_STORED_ERRORS then
            table.insert(crafty_tools.errors, entry)
        end
    end)
end

Addon.persistence = persistence
return persistence
