-- main.lua - Application Entry Point
-- Owns the initialization sequence: SV registration, SV init, module init.
-- The dependency system exposes initializeAllModules but does NOT
-- independently listen for ADDON_LOADED — this file calls it directly.
local ADDON_NAME, Addon = ...

-- Expose addon to global namespace for debugging and external access
PAO = Addon

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in main.lua. This is a critical initialization error.|r")
    return
end

-- ============================================================================
-- SHARED MODULE CONFIGURATION (file-load time, before ADDON_LOADED)
-- Shared modules (options, tabs, errorHandler, commands) are addon-agnostic.
-- persistence.lua holds PAO's defaults/categories and the slash prefix.
-- ============================================================================

if Addon.persistence and Addon.persistence.configureOptions then
    Addon.persistence:configureOptions()
end

if Addon.commands and Addon.commands.setSlash then
    Addon.commands:setSlash("pao")
end

-- ============================================================================
-- SAVEDVARIABLE REGISTRATION
-- Declare all SVs with version and default factory.
-- Version bump = stale data wiped on next login (development behavior).
-- Individual modules can take ownership of their registration over time
-- by calling svRegistry:register() during file load.
-- ============================================================================

local svr = Addon.svRegistry
if svr then
    -- Account-wide
    svr:register("pao_settings",      { version = 1 })
    svr:register("pao_circuit",       { version = 1, createDefault = function()
        -- Deferred: circuitData is loaded by the time initializeAll runs
        if Addon.circuitData then
            return Addon.circuitData:createDefaultCircuitState()
        end
        return {}
    end })
    svr:register("pao_ability",       { version = 1 })
    svr:register("pao_npc",           { version = 1 })
    svr:register("pao_species",       { version = 1 })
    svr:register("pao_edgeCasePets",  { version = 1 })
    svr:register("pao_petAcquired",   { version = 1 })
    svr:register("pao_leveling",      { version = 1 })
    svr:register("pao_tools",         { version = 1 })

    -- Per-character
    svr:register("pao_character",     { version = 1 })
end

-- ============================================================================
-- ADDON_LOADED — INITIALIZATION SEQUENCE
-- ============================================================================

local evt = CreateFrame("Frame")
evt:RegisterEvent("ADDON_LOADED")
evt:SetScript("OnEvent", function(self, event, arg1)
    if arg1 ~= ADDON_NAME then return end

    -- Step 1: Initialize all SavedVariables (version check, create defaults)
    -- Must happen before module init so SVs exist when modules access them.
    if svr then
        svr:initializeAll("pao_tools")
    end

    -- Step 2: Attach shared modules to PAO's SavedVariables.
    -- Hydrates options from pao_settings, tabs from pao_settings.tabs,
    -- flushes errorHandler buffer to pao_tools.errors.
    -- Must happen AFTER SV init and BEFORE module init.
    if Addon.persistence and Addon.persistence.attach then
        Addon.persistence:attach()
    end

    -- Step 3: Initialize all modules synchronously.
    -- All files are loaded by now (WoW loads .toc synchronously before
    -- firing ADDON_LOADED), so every registerModule call has already run.
    if Addon.dependency and Addon.dependency.initializeAllModules then
        Addon.dependency.initializeAllModules()
    else
        print("|cffff4444Error - Dependency system not available|r")
    end

    self:UnregisterEvent("ADDON_LOADED")
end)

SLASH_PAO1 = "/pao"
SlashCmdList["PAO"] = function(msg)
    if Addon.commands then
        Addon.commands:execute(msg)
    else
        print("|cff33ff99PAO|r: Command system not loaded")
    end
end