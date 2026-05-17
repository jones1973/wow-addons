--[[
  core/shared/pool.lua   [SHARED: sync with monorepo shared/core/pool.lua]
  Generic Object Pool

  Reusable acquire/release pool for frames, fontstrings, textures, or any
  object that's expensive to create and cheap to reset. Each consumer creates
  its own pool instance with a factory function that builds new objects when
  the pool is empty.

  The pool is the single source of truth for which objects are currently
  checked out. Callers don't (and can't) maintain a parallel active list —
  the API doesn't accept one. This eliminates a class of drift bugs where
  caller-side tracking diverges from the pool's view of the world.

  Usage:
    local rowPool = Addon.pool:new(function()
        local row = CreateFrame("Button", nil, scrollChild)
        row:SetHeight(28)
        return row
    end)

    local row = rowPool:acquire()   -- reuses a released object, or creates
    row:Show()
    -- ... use row ...
    rowPool:release(row)            -- hides and returns to pool
    -- or, to release every active object at once:
    rowPool:releaseAll()

  Idempotency: release(obj) on an object the pool doesn't currently consider
  active is a no-op. Double-releases can't corrupt the available stack.

  Dependencies: None
  Exports: Addon.pool
]]

local ADDON_NAME, Addon = ...

local pool = {}

--[[
  Create a new pool instance.

  The factory takes no arguments. If the factory needs a parent frame or
  other context, it should close over that context at the call site:

    local rowPool = pool:new(function()
        return CreateFrame("Button", nil, scrollChild)
    end)

  @param factory function() - Builds a new object when the pool is empty.
  @return table - Pool instance with acquire / release / releaseAll / stats.
]]
function pool:new(factory)
    local instance = {}

    -- Stack of released (inactive) objects. New acquires pop from the top.
    local available = {}

    -- Set of currently-acquired objects, keyed by object reference. The
    -- pool owns this view; callers never see or mutate it directly.
    local active = {}

    -- Cached size of `active`, since Lua tables don't expose set
    -- cardinality cheaply. Maintained alongside every active mutation.
    local activeCount = 0

    --[[
      Acquire an object from the pool. Reuses a released object if one is
      available, otherwise calls the factory to build a new one. The
      returned object is recorded as active until released.

      @return any - The acquired object.
    ]]
    function instance:acquire()
        local obj
        local n = #available
        if n > 0 then
            obj = available[n]
            available[n] = nil
        else
            obj = factory()
        end
        active[obj] = true
        activeCount = activeCount + 1
        return obj
    end

    --[[
      Release a single object back to the pool. Hides the object (if it
      has a Hide method) and makes it available for future acquires.

      No-op if the object isn't currently active in this pool — guards
      against double-release and against releasing a foreign object. This
      means callers can release defensively without tracking state.

      @param obj any - Object previously returned by acquire().
    ]]
    function instance:release(obj)
        if not obj or not active[obj] then return end
        active[obj] = nil
        activeCount = activeCount - 1
        if obj.Hide then
            obj:Hide()
        end
        table.insert(available, obj)
    end

    --[[
      Release every currently-active object. Equivalent to calling
      release() on each active object, in unspecified order. Common use:
      rebuilding a list view from scratch, where every prior row should
      be returned to the pool before the new render places fresh ones.
    ]]
    function instance:releaseAll()
        -- Snapshot keys before mutating, so we don't iterate a table
        -- we're modifying. Safer than relying on next() semantics across
        -- Lua versions.
        local toRelease = {}
        for obj in pairs(active) do
            toRelease[#toRelease + 1] = obj
        end
        for i = 1, #toRelease do
            self:release(toRelease[i])
        end
    end

    --[[
      Pool statistics for debugging.
      @return number, number - available count, active count
    ]]
    function instance:stats()
        return #available, activeCount
    end

    return instance
end

-- No module registration needed — pool is a pure utility with no
-- dependencies. Available immediately at file load time via Addon.pool.
Addon.pool = pool
return pool
