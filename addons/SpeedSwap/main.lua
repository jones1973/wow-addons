--[[
  main.lua
  SpeedSwap - Application Entry Point

  Owns the initialization sequence: SavedVariable defaults on ADDON_LOADED,
  then wires up the slash command and triggers gear state restoration on
  login.

  Exports: SpeedSwap (global, for /dump debugging)
]]

local ADDON_NAME, Addon = ...

-- Global access for /dump debugging
SpeedSwap = Addon

-- ============================================================================
-- SAVED VARIABLE DEFAULTS
-- ============================================================================

--[[
  Initialize per-character SavedVariables with default values, preserving
  any existing keys. Safe to call multiple times - only fills in missing keys.
]]
local function initSavedVariables()
    speedswap_character = speedswap_character or {}

    local defaults = {
        autoEquip = true,
        swimBelt  = false,
        debug     = false,
    }

    for k, v in pairs(defaults) do
        if speedswap_character[k] == nil then
            speedswap_character[k] = v
        end
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        initSavedVariables()
        self:UnregisterEvent("ADDON_LOADED")

    elseif event == "PLAYER_LOGIN" then
        -- PLAYER_LOGIN fires after all addons are loaded and the world is
        -- ready. By now gearSwap and gearState have attached themselves
        -- to Addon via their file-scope registration.
        Addon.gearSwap:scanBagsForEnchantedGear()
        Addon.gearState:restoreOnLogin()
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- ============================================================================
-- SLASH COMMAND
-- ============================================================================

SLASH_SPEEDSWAP1 = "/speedswap"
SLASH_SPEEDSWAP2 = "/ss"
SlashCmdList["SPEEDSWAP"] = function(input)
    Addon.commands:dispatch(input)
end
