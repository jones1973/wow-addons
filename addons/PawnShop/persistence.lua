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
    self:attachScanData()
end

--[[
  Wire Addon.options to the SVs. Hydrates account-wide values from
  ps_settings and per-character overrides from ps_character. Subscribes
  to SETTING:<CATEGORY>_CHANGED events to mirror changes back to the
  appropriate SV: if a per-character override exists for the changed
  key, mirror to ps_character; otherwise mirror to ps_settings.
]]
function persistence:attachOptions()
    if not Addon.options or not Addon.events then return end

    ps_settings  = ps_settings  or {}
    ps_character = ps_character or {}
    Addon.options:hydrate({
        account   = ps_settings,
        character = ps_character,
    })

    -- Categories defined in data/settingDefaults.lua map to these events.
    -- After a Set, the new value lives in either charSettings or settings
    -- inside options. Mirror to the matching SV.
    local categories = { "GENERAL", "DISPLAY", "FILTER" }
    for _, category in ipairs(categories) do
        Addon.events:subscribe("SETTING:" .. category .. "_CHANGED", function(_, payload)
            local key = payload.name
            local charVal = Addon.options:GetCharacter(key)
            if charVal ~= nil then
                ps_character[key] = charVal
            else
                ps_settings[key] = payload.newValue
                ps_character[key] = nil    -- defensive: ensure no stale override
            end
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

--[[
  Pawn's currently-visible scales for the current character. Used as a
  scale-mismatch heuristic on restore (we cache against this set; if the
  user's visible scales change before next session, the cache may not
  reflect what they care about).

  Returns an array of scale internal names. Empty array if Pawn isn't
  loaded or has no scales.
]]
local function currentVisibleScales()
    local out = {}
    if not PawnCommon or not PawnCommon.Scales then return out end
    if not PawnIsScaleVisible then return out end
    for scaleName, _ in pairs(PawnCommon.Scales) do
        if PawnIsScaleVisible(scaleName) then
            table.insert(out, scaleName)
        end
    end
    return out
end

--[[
  Wire eval rows to ps_scanData. On EVAL:COMPLETE, snapshot the current
  rows + scale registry for restore-after-reload. On SCAN:STARTED, wipe
  the cache so we don't restore stale data over a fresh in-progress scan.

  Restore happens lazily, driven by ahTab on AUCTION_HOUSE_SHOW. See
  persistence:restoreScanIfFresh below.
]]
function persistence:attachScanData()
    if not Addon.events then return end

    ps_scanData = ps_scanData or {}

    Addon.events:subscribe("EVAL:COMPLETE", function(_, payload)
        -- Don't re-persist when we just hydrated FROM the SV.
        if payload and payload.restored then return end
        if not Addon.eval or not Addon.eval.serialize then return end

        local blob = Addon.eval:serialize()
        ps_scanData = {
            rows              = blob.rows,
            scaleOrder        = blob.scaleOrder,
            scaleDisplayOrder = blob.scaleDisplayOrder,
            trackedScales     = blob.trackedScales,
            scannedAt         = time(),
            visibleScales     = currentVisibleScales(),
        }
    end)

    Addon.events:subscribe("SCAN:STARTED", function()
        ps_scanData = {}
    end)
end

--[[
  Restore eval state from ps_scanData and emit EVAL:COMPLETE so panel
  renders. Returns true if data was restored, false otherwise.

  Caller should only invoke this on a fresh AH open before any scan has
  run this session -- otherwise we'd clobber live in-progress eval state.

  @return boolean restored, number|nil scannedAt, table|nil visibleScales
]]
function persistence:restoreScanIfFresh()
    if not ps_scanData then return false end
    if not ps_scanData.rows then return false end
    if #ps_scanData.rows == 0 then return false end
    if not Addon.eval or not Addon.eval.hydrate then return false end

    Addon.eval:hydrate({
        rows              = ps_scanData.rows,
        scaleOrder        = ps_scanData.scaleOrder,
        scaleDisplayOrder = ps_scanData.scaleDisplayOrder,
        trackedScales     = ps_scanData.trackedScales,
    })
    return true, ps_scanData.scannedAt, ps_scanData.visibleScales
end

Addon.persistence = persistence
return persistence
