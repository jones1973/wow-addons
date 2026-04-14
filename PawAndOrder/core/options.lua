-- core/options.lua
local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in options.lua. This is a critical initialization error.|r")
    return {}
end

local utils = Addon.utils

Addon.options = Addon.options or {}
local options = Addon.options

-- Default settings
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
    -- Recency settings
    recentPetDays = 14,
    recentAchievementDays = 14,
    -- Pet Listing defaults
    defaultSort = "name",
    defaultSortDir = "asc",
    defaultFilterMode = "all",
    fadeLevelOpacity = true,
    showNonCombatPets = true,
    familyIconSaturation = 0.3,
    showFilterInfoPanels = true,
    displayMode = "pets",  -- "pets" (flat list) or "species" (grouped by species)
	-- Pet Battle defaults
	autoTargetAfterWithdraw = false,
	wildPetMarkEnabled = true,
	wildPetMarkMode = "fixed",
	wildPetMarkIcon = 8,
	forfeitButtonBehavior = "enhanced",  -- "enhanced", "standard", "disabled"
	-- Circuit defaults
	defaultCircuitContinent = 424, -- Pandaria
	showCircuitOptimization = true,
	defaultReturnLocation = "none", -- "none", "current", or "questgiver"
	-- Notification defaults
	level25Action = "popup",  -- "disabled", "popup", "journal"
}
-- Define categories as source of truth (maintainable, DRY)
local settingsByCategory = {
    listing = {
        "defaultSort",
        "defaultSortDir",
        "defaultFilterMode",
        "fadeLevelOpacity",
        "showNonCombatPets",
        "familyIconSaturation",
        "showFilterInfoPanels",
        "displayMode",
        "familyIconAlpha",
        "showUnowned",
    },
    circuit = {
        "defaultCircuitContinent",
        "showCircuitOptimization",
        "defaultReturnLocation",
    },
    battle = {
        "autoTargetAfterWithdraw",
        "wildPetMarkEnabled",
        "wildPetMarkMode",
        "wildPetMarkIcon",
        "forfeitButtonBehavior",
    },
    general = {
        "showRareByColor",
        "uiLayout",
        "defaultFilterFamily",
        "favoriteList",
        "autoSave",
        "tooltipDetail",
        "showTrainerPopup",
        "debugMode",
        "recentPetDays",
        "recentAchievementDays",
    },
    notifications = {
        "level25Action",
    }
}

-- Build reverse lookup for O(1) access in options:Set()
local settingCategories = {}
for category, settings in pairs(settingsByCategory) do
    for _, setting in ipairs(settings) do
        settingCategories[setting] = category
    end
end

-- Callback system
options.callbacks = {}

function options:initialize()
    -- pao_settings table created by svRegistry before module init.
    -- Fill in defaults for any missing keys.
    for k, v in pairs(defaults) do
        if pao_settings[k] == nil then
            pao_settings[k] = v
        end
    end
    
    -- Development mode: drop legacy migrations entirely
    self.settings = pao_settings
    
    -- Register callback for debug setting
    self:RegisterCallback("debugMode", function(val)
        if Addon.utils then
            Addon.utils:setDebugEnabled(val)
        end
    end)
    
    -- Immediately apply stored debug setting
    local stored = self.settings.debugMode
    self:TriggerCallbacks("debugMode", stored)
end

function options:Get(key)
    if self.settings and self.settings[key] ~= nil then
        return self.settings[key]
    end
    return defaults[key]
end

function options:Set(key, val)
    if not self.settings then
        utils:error("self.settings is nil in Set")
        return
    end
    
    if self.settings[key] == val then
        return
    end
    
    local oldVal = self.settings[key]
    self.settings[key] = val
    self:TriggerCallbacks(key, val)
    
    -- Fire events for settings changes
    if Addon.events then
        local category = settingCategories[key]
        if category then
            -- Map category to event
            local categoryEvents = {
                listing = "SETTING:LISTING_CHANGED",
                circuit = "SETTING:CIRCUIT_CHANGED",
                battle = "SETTING:BATTLE_CHANGED",
                general = "SETTING:GENERAL_CHANGED",
                notifications = "SETTING:NOTIFICATIONS_CHANGED",
            }
            local eventName = categoryEvents[category]
            
            if eventName then
                Addon.events:emit(eventName, {
                    name = key,
                    oldValue = oldVal,
                    newValue = val,
                    category = category
                })
                utils:debug(string.format("Fired event %s for setting %s", tostring(eventName), tostring(key)))
            end
        end
    end
    
    utils:debug(string.format("Setting %s: %s -> %s", tostring(key), tostring(oldVal), tostring(val)))
    utils:debug(string.format("pao_settings.%s = %s", tostring(key), tostring(pao_settings[key])))
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

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("options", {"utils"}, function()
        if options.initialize then
            return options:initialize()
        end
        return true
    end)
end

return options