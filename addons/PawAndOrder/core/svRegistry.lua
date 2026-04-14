--[[
  core/svRegistry.lua
  SavedVariable Registry

  Centralized declaration, versioning, and initialization for all SavedVariables.
  Replaces the scattered pattern where each module initializes its own SV.

  Each SV is registered with a version number, a factory function for first-run
  creation, and optional migration functions for schema changes. During
  ADDON_LOADED (before module init), the registry checks every registered SV:

  - Missing (nil)      -> create from factory, stamp version
  - No version tracked -> legacy data from before registry, stamp as v1
  - Version < current  -> run migration chain (v2, v3, v4...) in sequence
  - Version == current -> leave untouched

  Migrations modify only the fields that changed. Data that hasn't changed
  is never touched. The factory only runs on first install.

  Version numbers are stored centrally in pao_tools.svVersions, NOT on
  individual SVs. This avoids polluting flat key-value SVs (like pao_npc,
  pao_edgeCasePets) where keys are data and metadata keys would be iterated
  as data.

  Usage:
    Addon.svRegistry:register("pao_circuit", {
        version = 3,
        createDefault = function()
            return { active = false, state = "inactive", selectedNpcIds = {} }
        end,
        migrations = {
            [2] = function(sv)
                if sv.waypointHidden == nil then sv.waypointHidden = false end
            end,
            [3] = function(sv)
                sv.startContinent = sv.lastContinent
                sv.lastContinent = nil
            end,
        },
    })

  Dependencies: None (must load before everything that touches SVs)
  Exports: Addon.svRegistry
]]

local ADDON_NAME, Addon = ...

local svRegistry = {}

-- Registration storage: name -> { version, createDefault, migrations }
local registered = {}

-- ============================================================================
-- REGISTRATION
-- ============================================================================

--[[
  Register a SavedVariable with version, factory, and optional migrations.

  @param name string - Global SV name (must match .toc SavedVariables entry)
  @param config table:
    - version number - Current schema version (bump when structure changes)
    - createDefault function - Returns a fresh default table (first install only)
    - migrations table|nil - { [versionNum] = function(sv) } migration functions
]]
function svRegistry:register(name, config)
    if not name or type(name) ~= "string" then
        error("svRegistry:register requires a string name", 2)
    end

    if registered[name] then
        print(string.format("|cff33ff99%s|r: svRegistry: '%s' registered twice", ADDON_NAME, name))
    end

    registered[name] = {
        version = (config and config.version) or 1,
        createDefault = (config and config.createDefault) or function() return {} end,
        migrations = (config and config.migrations) or {},
    }
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

--[[
  Initialize all registered SavedVariables.
  Called once from main.lua's ADDON_LOADED handler, BEFORE module init.

  @param versionStoreName string - Name of the tooling SV that holds version data
                                   (e.g., "pao_tools"). Bootstrapped if nil.
  @return number, number - changed count, total count
]]
function svRegistry:initializeAll(versionStoreName)
    if not versionStoreName or type(versionStoreName) ~= "string" then
        error("svRegistry:initializeAll requires a version store SV name", 2)
    end

    -- Bootstrap the version store SV — it holds the version registry.
    _G[versionStoreName] = _G[versionStoreName] or {}
    local store = _G[versionStoreName]
    store.svVersions = store.svVersions or {}

    local versions = store.svVersions
    local changedCount = 0
    local totalCount = 0

    -- Remember store name for debug command
    svRegistry.versionStoreName = versionStoreName

    for name, config in pairs(registered) do
        totalCount = totalCount + 1
        local sv = _G[name]
        local tracked = versions[name]

        if not sv then
            -- First install: create from factory
            _G[name] = config.createDefault()
            versions[name] = config.version
            changedCount = changedCount + 1

        elseif not tracked then
            -- Legacy data from before svRegistry existed.
            -- Stamp as v1, leave data intact. Run migrations if current > 1.
            versions[name] = 1
            if 1 < config.version then
                self:runMigrations(name, sv, 1, config)
                changedCount = changedCount + 1
            end

        elseif tracked < config.version then
            -- Schema changed: run migration chain
            self:runMigrations(name, sv, tracked, config)
            changedCount = changedCount + 1
        end
        -- Version matches current: leave untouched
    end

    return changedCount, totalCount
end

--[[
  Run migration chain for a SV from its current version to the target version.
  Migrations run in sequence: v2, v3, v4, etc.

  @param name string - SV name (for error reporting)
  @param sv table - The SavedVariable table
  @param fromVersion number - Current version
  @param config table - Registration config with version and migrations
]]
function svRegistry:runMigrations(name, sv, fromVersion, config)
    local store = _G[svRegistry.versionStoreName]
    local versions = store.svVersions

    for v = fromVersion + 1, config.version do
        local migrateFn = config.migrations[v]
        if migrateFn then
            local ok, err = pcall(migrateFn, sv)
            if not ok then
                if Addon.utils then
                    Addon.utils:error(string.format(
                        "svRegistry: Migration failed for '%s' v%d: %s",
                        name, v, tostring(err)))
                else
                    print(string.format(
                        "|cff33ff99%s|r: |cffff4444svRegistry: Migration failed for '%s' v%d: %s|r",
                        ADDON_NAME, name, v, tostring(err)))
                end
            end
        end
        -- No migration function = schema-compatible bump (new optional fields default to nil)
        versions[name] = v
    end
end

-- ============================================================================
-- DEBUG
-- ============================================================================

--[[
  Print status of all registered SVs.
]]
function svRegistry:debug()
    local output = Addon.utils and function(msg) Addon.utils:chat(msg, true) end or print

    output("=== SavedVariable Registry ===")

    local names = {}
    for name in pairs(registered) do
        table.insert(names, name)
    end
    table.sort(names)

    local store = svRegistry.versionStoreName and _G[svRegistry.versionStoreName]
    local versions = (store and store.svVersions) or {}

    for _, name in ipairs(names) do
        local config = registered[name]
        local sv = _G[name]
        local tracked = versions[name] or "none"
        local entryCount = 0
        if sv then
            for _ in pairs(sv) do entryCount = entryCount + 1 end
        end

        local status
        if not sv then
            status = "|cffff4444MISSING|r"
        elseif tracked ~= config.version then
            status = string.format("|cffff8800STALE|r (v%s, need v%s)",
                tostring(tracked), tostring(config.version))
        else
            status = "|cff00ff00OK|r"
        end

        output(string.format("  %s: v%s, %d entries  %s",
            name, tostring(config.version), entryCount, status))
    end
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

-- Register a module for the debug command (runs after commands system is ready)
if Addon.registerModule then
    Addon.registerModule("svRegistryCommands", {"commands"}, function()
        if Addon.commands then
            Addon.commands:register({
                command = "svs",
                handler = function() svRegistry:debug() end,
                help = "Show SavedVariable registry status",
                usage = "svs",
                category = "Debug"
            })
        end
        return true
    end)
end

Addon.svRegistry = svRegistry
return svRegistry
