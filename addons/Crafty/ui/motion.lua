--[[
  ui/motion.lua
  Motion Primitives

  The one animation driver and the easing vocabulary every animated component
  composes from. Choreography - WHAT moves and why - stays with the component
  that owns the frames; this module owns only the physics plumbing, so there
  is exactly one self-terminating OnUpdate pattern in the addon.

  run(frame, step, onDone)
    Drive step(elapsed, dt) every frame until it returns true, then detach
    and call onDone. The driver occupies the frame's OnUpdate slot: starting
    a new run on the same frame REPLACES the old one (the newcomer owns the
    motion) - callers that must not lose completion work on replacement keep
    their own queues (see the tray's settle queue).

  hop(frame, place)
    The acknowledgment gesture - a 3px sine hop over 0.2s. The active block,
    the ghost's owner, a tool that just served as a spell target, and the
    craft verb all speak it; place(dy) carries the caller's anchor knowledge
    (motion cannot know how a frame is seated). place(0) restores rest.

  tween(frame, dur, curve, onDone)
    The fixed-duration shape most gestures are: run with the clamp/complete
    boilerplate owned here. curve(u, elapsed) places the frame for u in
    [0,1]; curve(1) is guaranteed exactly once before onDone, so the final
    pose never depends on frame timing.

  delay(frame, seconds, fn)
    A staged start: hold, then fn. Occupies the frame's motion slot like any
    run, so a newcomer gesture cancels the wait with the same replacement
    rule as everything else.

  ease
    outQuad   - fast start, gentle stop: the workhorse slide
    outCubic  - harder brake: the emphatic push
    smooth    - smoothstep: ease in AND out, for travel with no impact
    arc       - sin(u*pi): rise-and-fall, for leaps and lobs
    strike    - the shoved-thing scoot: overshoot past the target, recoil to
                rest. strike(u, from, to, overPx, easeFn) returns the position
                for u in [0,1]; every knock and shove in the addon settles
                with this one shape.

  Dependencies: none
  Exports: Addon.motion
]]

local ADDON_NAME, Addon = ...

local motion = {}

motion.ease = {
    outQuad  = function(u) return 1 - (1 - u) * (1 - u) end,
    outCubic = function(u) return 1 - (1 - u) * (1 - u) * (1 - u) end,
    smooth   = function(u) return u * u * (3 - 2 * u) end,
    arc      = function(u) return math.sin(u * math.pi) end,
}

-- Overshoot-recoil: travel past the target by overPx (signed toward travel
-- direction), then settle back. The first 70% is the shove (easeFn shapes
-- it), the last 30% the recoil.
function motion.ease.strike(u, from, to, overPx, easeFn)
    local over = (to - from) + (to >= from and overPx or -overPx)
    if u < 0.7 then
        return from + over * easeFn(u / 0.7)
    end
    return from + over - (over - (to - from)) * ((u - 0.7) / 0.3)
end

-- Drive step(elapsed, dt) on the frame until it returns true. Self-
-- terminating; a new run on the same frame replaces this one.
function motion:run(frame, step, onDone)
    local elapsed = 0
    frame:SetScript("OnUpdate", function(f, dt)
        elapsed = elapsed + dt
        if step(elapsed, dt) then
            f:SetScript("OnUpdate", nil)
            if onDone then onDone() end
        end
    end)
end

-- Stop any motion running on the frame, leaving it exactly where it stands.
-- Snap paths that write final values directly MUST stop first: a snap does
-- not install a motion, so it cannot replace one - an in-flight spring would
-- survive the snap and resume toward its stale target next frame.
function motion:stop(frame)
    frame:SetScript("OnUpdate", nil)
end

-- Fixed-duration curve: u clamps to [0,1], curve(1) fires exactly once as
-- the final pose, then onDone.
function motion:tween(frame, dur, curve, onDone)
    self:run(frame, function(elapsed)
        local u = math.min(elapsed / dur, 1)
        curve(u, elapsed)
        return u >= 1
    end, onDone)
end

-- Hold for `seconds`, then fn. Replaceable like any motion on the frame.
function motion:delay(frame, seconds, fn)
    self:run(frame, function(elapsed)
        if elapsed >= seconds then
            fn()   -- fn may start a new motion, replacing this run
            return true
        end
    end)
end

-- The acknowledgment hop: 3px sine over 0.2s, seated back at rest.
function motion:hop(frame, place)
    self:run(frame, function(elapsed)
        local u = elapsed / 0.2
        if u >= 1 then
            place(0)
            return true
        end
        place(3 * math.sin(u * math.pi))
    end)
end

function motion:initialize()
    return true
end

Addon.motion = motion

if Addon.registerModule then
    Addon.registerModule("motion", {}, function()
        return motion:initialize()
    end)
end

return motion
