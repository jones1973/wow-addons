-- main.lua - Crafty Application Entry Point
-- Owns the initialization sequence: SV registration at file-load, then at
-- ADDON_LOADED: SV init/migrate, shared-module attach, module init. No timers,
-- single ADDON_LOADED owner.
local ADDON_NAME, Addon = ...

-- Expose addon globally for /dump access. Assigned once, never used internally.
Crafty = Addon -- luacheck: ignore Crafty (exported for /dump, read externally)

-- Display name for shared utils chat prefix.
Addon.displayName = "Crafty"

if not Addon.utils then
    print("|cffff4444Error - Addon.utils not available in main.lua.|r")
    return
end

-- ============================================================================
-- SHARED MODULE CONFIGURATION (file-load time, before ADDON_LOADED)
-- ============================================================================

if Addon.persistence and Addon.persistence.configureOptions then
    Addon.persistence:configureOptions()
end

if Addon.commands and Addon.commands.setSlash then
    Addon.commands:setSlash("crafty")
end

-- ============================================================================
-- SAVEDVARIABLE REGISTRATION
-- Declare all SVs with version and default factory. Version bump wipes-and-
-- recreates on next login unless a migration is provided (single-user dev).
-- ============================================================================

local svr = Addon.svRegistry
if svr then
    local c = Addon.constants

    -- Account-wide settings (flat key-value; options module manages contents).
    svr:register("crafty_settings", { version = (c and c.SETTINGS_SV_VERSION) or 1 })

    -- Account-wide window geometry. Its own store because crafty_settings is
    -- the options module's, and hydrate() copies every key it finds - a
    -- position left there would become a phantom option.
    -- v2 clears any geometry saved under the old top-band layout, whose small
    -- default would restore and crush the rail-plus-workspace columns. A
    -- migration (not a bare version bump) is what svRegistry runs on an
    -- existing SV; it wipes the stored size/pos so the current default applies.
    svr:register("crafty_window", {
        version = 2,
        migrations = {
            [2] = function(sv)
                sv.size = nil
                sv.pos = nil
            end,
        },
    })

    -- Account-wide tooling (sv versions, captured errors).
    svr:register("crafty_tools", { version = 1 })

    -- Reality-check observations (design/reality-check.md): in-game facts vs
    -- static-data claims, exported into the merge pipeline as ground truth.
    svr:register("crafty_factcheck", { version = 1 })

    -- Per-character facts keyed by Name-Realm: known sets, cooldowns, inventory.
    svr:register("crafty_character", {
        version = (c and c.CHARACTER_SV_VERSION) or 1,
        createDefault = function()
            return { chars = {} }
        end,
    })

    -- Per-character private config (WoW-scoped to the character; other toons
    -- never see it). Home for toon-private settings like per-profession filter
    -- and sort state. Also self-hosts its own version registry for the
    -- per-character init pass.
    svr:register("crafty_config", {
        version = (c and c.CONFIG_SV_VERSION) or 1,
        perCharacter = true,
        createDefault = function()
            return { professions = {}, svVersions = {} }
        end,
    })
end

-- ============================================================================
-- ADDON_LOADED - INITIALIZATION SEQUENCE
-- ============================================================================

local evt = CreateFrame("Frame")
evt:RegisterEvent("ADDON_LOADED")
evt:SetScript("OnEvent", function(self, _, arg1)
    if arg1 ~= ADDON_NAME then return end

    -- Step 1: create/migrate all registered SVs. Account SVs track versions in
    -- crafty_tools; per-character SVs track versions in crafty_config itself, so
    -- each character migrates its own per-character data independently.
    if svr then
        svr:initializeAll("crafty_tools")
        svr:initializeAll("crafty_config", true)
    end

    -- Step 2: hydrate shared modules from SVs.
    if Addon.persistence and Addon.persistence.attach then
        Addon.persistence:attach()
    end

    -- Step 3: initialize all registered modules (synchronous; all files loaded).
    if Addon.dependency and Addon.dependency.initializeAllModules then
        Addon.dependency.initializeAllModules()
    else
        print("|cffff4444Error - Dependency system not available|r")
    end

    self:UnregisterEvent("ADDON_LOADED")
end)

-- ============================================================================
-- SLASH COMMAND - bare opens the window, subcommands route through the registry
-- ============================================================================

SLASH_CRAFTY1 = "/crafty" -- luacheck: ignore SLASH_CRAFTY1 (read by Blizzard SlashCmdList)
SlashCmdList["CRAFTY"] = function(msg)
    msg = (msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "" then
        if Addon.craftingWindow then
            Addon.craftingWindow:toggle()
        end
        return
    end
    if Addon.commands then
        Addon.commands:execute(msg)
    end
end
