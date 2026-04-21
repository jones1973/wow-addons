--[[
  core/pool.lua
  Generic Object Pool

  Reusable acquire/release pool for frames, fontstrings, textures, or any
  object that's expensive to create and cheap to reset. Each consumer creates
  its own pool instance with a factory function that builds new objects when
  the pool is empty.

  Usage:
    local rowPool = Addon.pool:new(function(parent)
        local row = CreateFrame("Button", nil, parent)
        row:SetHeight(28)
        return row
    end)

    local row = rowPool:acquire(parentFrame)  -- reuses or creates
    row:Show()
    -- ... use row ...
    rowPool:release(row)                      -- hides and returns to pool

  Dependencies: None
  Exports: Addon.pool
]]

local ADDON_NAME, Addon = ...

local pool = {}

--[[
  Create a new pool instance.

  @param factory function(parent) - Creates a new object when pool is empty.
                                    Receives the parent argument from acquire().
  @return table - Pool instance with acquire/release/drain methods
]]
function pool:new(factory)
    local instance = {}
    local available = {}   -- Stack of released (inactive) objects
    local activeCount = 0  -- Number of currently acquired objects

    --[[
      Acquire an object from the pool.
      Returns a released object if one exists, otherwise calls factory.

      @param parent frame|nil - Parent argument passed to factory for new objects
      @return any - The acquired object
    ]]
    function instance:acquire(parent)
        local obj
        local n = #available
        if n > 0 then
            obj = available[n]
            available[n] = nil
        else
            obj = factory(parent)
        end
        activeCount = activeCount + 1
        return obj
    end

    --[[
      Release an object back to the pool.
      Hides the object (if it has a Hide method) and pushes it onto the
      available stack for reuse.

      @param obj any - The object to release
    ]]
    function instance:release(obj)
        if not obj then return end
        if obj.Hide then
            obj:Hide()
        end
        activeCount = activeCount - 1
        table.insert(available, obj)
    end

    --[[
      Release all active objects. Requires the caller to pass
      the active set since the pool doesn't track individual acquires.
      Convenience for "hide everything" scenarios like tooltip:hide().

      @param objects table - Array of objects to release
    ]]
    function instance:releaseAll(objects)
        for _, obj in ipairs(objects) do
            self:release(obj)
        end
    end

    --[[
      Get pool statistics for debugging.
      @return number, number - available count, active count
    ]]
    function instance:stats()
        return #available, activeCount
    end

    return instance
end

-- No module registration needed — pool is a pure utility with no dependencies.
-- Available immediately at file load time via Addon.pool.
Addon.pool = pool
return pool
