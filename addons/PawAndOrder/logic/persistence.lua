--[[
  core/persistence.lua (PAO-specific)

  Bridges shared in-memory modules to PAO's SavedVariables.
  Shared modules (options, tabs, errorHandler) hold state in memory and
  emit events. This file wires them to pao_settings and pao_tools.

  Lifecycle:
    1. main.lua calls persistence:configureOptions() / configureTabs() at file load
       to set defaults and categories (pure configuration, no SV access).
    2. main.lua calls persistence:attach() inside ADDON_LOADED, after svRegistry
       has ensured the SVs exist.

  Dependencies: options, tabs, errorHandler, events, svRegistry
  Exports: Addon.persistence
]]

local ADDON_NAME, Addon = ...

local persistence = {}

-- ============================================================================
-- OPTIONS CONFIGURATION
-- ============================================================================

--[[
  Register PAO's option defaults and category mapping with the shared options
  module. Called at file load time before svRegistry runs.
]]
function persistence:configureOptions()
    local defaults = {
        showRareByColor = true,
        showUnowned = false,
        uiLayout = "tabs",
        defaultFilterFamily = nil,
        favoriteList = {},
        autoSave = true,
        tooltipDetail = true,
        showTrainerPopup = true,
        debugMode = false,
        recentPetDays = 14,
        recentAchievementDays = 14,
        defaultSort = "name",
        defaultSortDir = "asc",
        defaultFilterMode = "all",
        fadeLevelOpacity = true,
        showNonCombatPets = true,
        familyIconSaturation = 0.3,
        showFilterInfoPanels = true,
        displayMode = "pets",
        autoTargetAfterWithdraw = false,
        wildPetMarkEnabled = true,
        wildPetMarkMode = "fixed",
        wildPetMarkIcon = 8,
        forfeitButtonBehavior = "enhanced",
        defaultCircuitContinent = 424,
        showCircuitOptimization = true,
        defaultReturnLocation = "none",
        level25Action = "popup",
    }

    local categories = {
        listing = {
            "defaultSort", "defaultSortDir", "defaultFilterMode",
            "fadeLevelOpacity", "showNonCombatPets", "familyIconSaturation",
            "showFilterInfoPanels", "displayMode", "familyIconAlpha",
            "showUnowned",
        },
        circuit = {
            "defaultCircuitContinent", "showCircuitOptimization",
            "defaultReturnLocation",
        },
        battle = {
            "autoTargetAfterWithdraw", "wildPetMarkEnabled",
            "wildPetMarkMode", "wildPetMarkIcon", "forfeitButtonBehavior",
        },
        general = {
            "showRareByColor", "uiLayout", "defaultFilterFamily",
            "favoriteList", "autoSave", "tooltipDetail", "showTrainerPopup",
            "debugMode", "recentPetDays", "recentAchievementDays",
        },
        notifications = {
            "level25Action",
        },
    }

    Addon.options:setDefaults(defaults)
    Addon.options:setCategories(categories)
end

-- ============================================================================
-- ATTACH (called from main.lua after svRegistry:initializeAll)
-- ============================================================================

--[[
  Wire shared modules to PAO's SavedVariables.
  Call AFTER svRegistry:initializeAll() has created/migrated pao_settings
  and pao_tools. Safe to call exactly once per session.
]]
function persistence:attach()
    -- OPTIONS: hydrate from pao_settings, persist on change
    Addon.options:hydrate(pao_settings)

    -- Mirror settings table reference for any legacy code reading Addon.db
    Addon.db = pao_settings

    -- Settings changes: write back to pao_settings.
    -- The shared options module has already applied the value in memory;
    -- we just mirror it to the SavedVariable.
    local function mirrorSetting(eventName, payload)
        if payload and payload.name ~= nil then
            pao_settings[payload.name] = payload.newValue
        end
    end
    Addon.events:subscribe("SETTING:LISTING_CHANGED",       mirrorSetting)
    Addon.events:subscribe("SETTING:CIRCUIT_CHANGED",       mirrorSetting)
    Addon.events:subscribe("SETTING:BATTLE_CHANGED",        mirrorSetting)
    Addon.events:subscribe("SETTING:GENERAL_CHANGED",       mirrorSetting)
    Addon.events:subscribe("SETTING:NOTIFICATIONS_CHANGED", mirrorSetting)

    -- TABS: hydrate from pao_settings.tabs, persist on change
    pao_settings.tabs = pao_settings.tabs or {}
    Addon.tabs:setInitialStates(pao_settings.tabs)

    Addon.events:subscribe("TABS:STATE_CHANGED", function(_, payload)
        if payload and payload.id ~= nil then
            pao_settings.tabs[payload.id] = payload.enabled
        end
    end)

    -- ERRORHANDLER: drain in-memory buffer into pao_tools, then persist new errors.
    -- Errors captured during file load (before this attach runs) are flushed now.
    pao_tools.errors = pao_tools.errors or {}
    pao_tools.sessionId = Addon.errorHandler:getSessionId()

    for _, entry in ipairs(Addon.errorHandler:getCapturedErrors()) do
        if #pao_tools.errors < 100 then
            table.insert(pao_tools.errors, entry)
        end
    end

    Addon.errorHandler:onError(function(entry)
        if #pao_tools.errors < 100 then
            table.insert(pao_tools.errors, entry)
        end
    end)
end

Addon.persistence = persistence
return persistence
