-- main.lua - Application Entry Point
--
-- Owns the initialization sequence:
--   1. File-load: configure shared modules (slash prefix, options defaults,
--      identity strings), register all SavedVariables.
--   2. ADDON_LOADED: initialize SVs via svRegistry, attach persistence
--      adapter, then run dependency-ordered module init.
--
-- The dependency system exposes initializeAllModules but does NOT
-- independently listen for ADDON_LOADED - main.lua calls it directly.

local ADDON_NAME, Addon = ...

-- Expose addon to global namespace for /dump debugging
PS = Addon

-- Addon identity (used by shared modules for display strings)
Addon.displayName = "Pawn Shop"

if not Addon.utils then
    print("|cffff4444Error - Addon.utils not available in main.lua.|r")
    return
end

-- ============================================================================
-- SHARED MODULE CONFIGURATION (file-load time, before ADDON_LOADED)
-- ============================================================================

-- persistence.lua holds Pawn Shop's defaults/categories and registers them
-- with the shared options module.
if Addon.persistence and Addon.persistence.configureOptions then
    Addon.persistence:configureOptions()
end

-- Slash prefix appears in /ps help output.
if Addon.commands and Addon.commands.setSlash then
    Addon.commands:setSlash("ps")
end

-- escapeHandler: no main frame to manage yet (the AH tab is not modal and
-- doesn't need ESC-to-close). If we add modal popups that need ESC
-- escaping in the future, setMainFrame goes here.

-- ============================================================================
-- SAVEDVARIABLE REGISTRATION
-- ============================================================================

local svr = Addon.svRegistry
if svr then
    -- Account-wide
    svr:register("ps_settings",  { version = 1 })
    svr:register("ps_tools",     { version = 1 })

    -- Scan cache: dev iteration convenience. Holds the last scan's auctions
    -- so /reload doesn't force a re-scan. Version-bumped SVs get wiped on
    -- schema change, which is the right behavior for this cache.
    svr:register("ps_scanCache", { version = 1, createDefault = function()
        return { auctions = {}, scannedAt = 0 }
    end })

    -- Per-character
    svr:register("ps_character", { version = 1 })
end

-- ============================================================================
-- ADDON_LOADED - INITIALIZATION SEQUENCE
-- ============================================================================

local evt = CreateFrame("Frame")
evt:RegisterEvent("ADDON_LOADED")
evt:SetScript("OnEvent", function(self, event, arg1)
    if arg1 ~= ADDON_NAME then return end

    -- Step 1: Initialize all SavedVariables (version check, create defaults)
    if svr then
        svr:initializeAll("ps_tools")
    end

    -- Step 2: Attach shared modules to Pawn Shop's SavedVariables.
    -- Hydrates options from ps_settings, drains errorHandler buffer to
    -- ps_tools.errors. Must happen AFTER SV init and BEFORE module init.
    if Addon.persistence and Addon.persistence.attach then
        Addon.persistence:attach()
    end

    -- Step 3: Initialize all modules synchronously, in dependency order.
    if Addon.dependency and Addon.dependency.initializeAllModules then
        Addon.dependency.initializeAllModules()
    else
        print("|cffff4444Error - Dependency system not available|r")
    end

    self:UnregisterEvent("ADDON_LOADED")
end)

-- Slash commands: /ps is primary, /pshop is alias.
SLASH_PS1 = "/ps"
SLASH_PS2 = "/pshop"
SlashCmdList["PS"] = function(msg)
    if Addon.commands then
        Addon.commands:execute(msg)
    else
        print("|cff33ff99PS|r: Command system not loaded")
    end
end
