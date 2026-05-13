--[[
  ui/shared/widgets/panel.lua
  Panel frame factories with composable animations

  A panel is a backdrop-styled frame, typically used as the body of a
  modal, sidebar, dropdown surface, or any visually distinct region.
  This module provides:

  - panel:opaque(parent, opts)
      Factory for a frame with an opaque WHITE8X8 fill and configurable
      border. Returns a Frame instance with all standard frame methods
      plus :withAnimation() for composable show/hide animations.

  - frame:withAnimation(opts)
      Returns a controller object that drives composed visual transforms
      on the frame across show/hide. Multiple transforms run in
      parallel against a single 0..1 progress value. Mid-animation
      reversals are supported (call :hide() while showing, :show()
      while hiding — direction flips, progress continues).

  Why composable transforms instead of named methods like
  :slideIn() / :fadeIn():
  Animations frequently combine. A panel might wipe AND fade; a
  modal might pop in (scale) AND fade. Naming each combination
  bloats the API surface. Describing animations as data ({type,
  from, to, ...} entries) means new transform types register into
  an internal table and consumers just list what they want.

  Available transform types (extend by adding to the TRANSFORMS table
  below):

    type = "fade"
      Animates frame alpha.
      from = number, to = number (0..1)

    type = "wipe"
      Animates the frame's width or height while keeping its anchor
      fixed, producing a "grow out from anchor" reveal. Used with
      clipsChildren=true on the controller so the frame's contents
      reveal naturally as the dimension grows.
      axis = "x" | "y"  (default "x" = animate width)
      from = number, to = number (pixel size for the chosen axis)

  Usage (wipe — panel grows out from a sibling frame's edge):

    local p = panel:opaque(UIParent, {})
    p:SetSize(280, 460)

    local ctrl = p:withAnimation({
        anchor = {
            relativeTo    = mainFrame,
            point         = "TOPLEFT",
            relativePoint = "TOPRIGHT",
            x = 0, y = 0,
        },
        transforms = {
            { type = "wipe", axis = "x", from = 0, to = 280 },
        },
        clipsChildren = true,   -- contents reveal as width grows
        duration = 0.2,
    })

    ctrl:show()    -- play forward (0 -> 1)
    ctrl:hide()    -- play reverse (current -> 0)
    ctrl:toggle()  -- inverse of current direction
    ctrl:isOpen()  -- true if shown or animating in; false if hidden
                   -- or animating out

  Dependencies: None
  Exports: Addon.panel
]]

local ADDON_NAME, Addon = ...

local panel = {}

-- ============================================================================
-- TRANSFORM REGISTRY
-- ============================================================================
--
-- Each entry in TRANSFORMS is a handler with:
--
--   apply(frame, t, progress, ctx)   [REQUIRED]
--       Per-tick. Apply this transform to the frame at the given
--       progress (0..1).
--
--   setup(frame, t, ctx)             [OPTIONAL]
--       Called once before the first apply, on the first :show() of
--       a controller. Capture any frame state needed for the rest of
--       the animation (e.g., wipe captures the non-animated
--       dimension here so the consumer can SetSize before show()).
--
--   reset(frame, t, ctx)             [OPTIONAL]
--       Called when a controller is being torn down (camp rule).
--       Restore any frame state the transform mutated, leaving the
--       frame in the resting state it was in before any apply ran.
--       Currently called from the controller's :destroy() method
--       (see ANIMATION CONTROLLER section); transforms get reset
--       so the next controller starts from a clean slate.
--
-- Arguments:
--   frame    - the panel being animated
--   t        - the {type, ...} entry from the consumer's transforms list
--   progress - 0..1 (apply only)
--   ctx      - controller-local context table; transforms stash state
--              here across calls. Pre-populated with ctx.baseAnchor.
--
-- New animation types extend this table. No API change required.

local function lerp(a, b, t)
    return a + (b - a) * t
end

local TRANSFORMS = {
    fade = {
        apply = function(frame, t, progress, _ctx)
            local a = lerp(t.from or 0, t.to or 1, progress)
            frame:SetAlpha(a)
        end,

        reset = function(frame, _t, _ctx)
            frame:SetAlpha(1)
        end,
    },

    wipe = {
        setup = function(frame, t, ctx)
            -- Capture pre-animation frame state. The consumer may
            -- have set the frame size before show(); we want wipe
            -- to respect that AND we want reset to be able to
            -- restore the frame's full size when the controller
            -- tears down.
            local axis = t.axis or "x"
            if axis == "x" then
                ctx._wipeBaseHeight = frame:GetHeight()
                ctx._wipeFullWidth  = frame:GetWidth()
            else
                ctx._wipeBaseWidth  = frame:GetWidth()
                ctx._wipeFullHeight = frame:GetHeight()
            end
        end,

        apply = function(frame, t, progress, ctx)
            -- Animate width (axis="x") or height (axis="y") while
            -- preserving the other dimension. The non-animated
            -- dimension is captured in setup; we trust the contract
            -- and don't fall back to GetHeight/GetWidth here.
            local axis = t.axis or "x"
            local size = lerp(t.from or 0, t.to or 0, progress)
            if axis == "x" then
                frame:SetSize(size, ctx._wipeBaseHeight)
            else
                frame:SetSize(ctx._wipeBaseWidth, size)
            end

            -- Anchor the frame to its resting position. Wipe doesn't
            -- move the frame (only resizes it), but the controller
            -- doesn't anchor either; without this, a wipe-only
            -- consumer ends up with a frame that has no anchor and
            -- never renders.
            local a = ctx.baseAnchor
            if a and a.relativeTo then
                frame:ClearAllPoints()
                frame:SetPoint(
                    a.point or "TOPLEFT",
                    a.relativeTo,
                    a.relativePoint or "TOPLEFT",
                    a.x or 0,
                    a.y or 0
                )
            end
        end,

        reset = function(frame, t, ctx)
            -- Restore the frame to its full pre-animation size.
            local axis = t.axis or "x"
            if axis == "x" then
                frame:SetSize(ctx._wipeFullWidth, ctx._wipeBaseHeight)
            else
                frame:SetSize(ctx._wipeBaseWidth, ctx._wipeFullHeight)
            end
        end,
    },
}

-- ============================================================================
-- ANIMATION CONTROLLER
-- ============================================================================

--[[
  Build a controller bound to `frame` with the given options.
  Internal helper, called by frame:withAnimation.
]]
local function buildController(frame, opts)
    if not opts or not opts.transforms or #opts.transforms == 0 then
        error("withAnimation: opts.transforms must be a non-empty list")
    end

    local controller = {}
    local progress = 0           -- 0..1
    local direction = nil        -- "forward" | "reverse" | nil (idle)
    local duration = opts.duration or 0.2
    local transforms = opts.transforms
    local baseAnchor = opts.anchor
    local clipsChildren = opts.clipsChildren and true or false
    local reparentToAnchor = opts.reparentToAnchor
    if reparentToAnchor == nil then reparentToAnchor = true end

    -- Per-controller context handed to each transform's apply(). Lets
    -- a transform stash state across ticks within one animation.
    local ctx = { baseAnchor = baseAnchor }

    -- One-time setup the first time show() is called. We defer to
    -- show() rather than doing it at controller-build time because
    -- the consumer might build the controller before its anchor frame
    -- is fully positioned.
    local setupDone = false
    -- Frame state snapshotted at first show() so destroy() can restore
    -- it. We don't snapshot strata because the controller doesn't
    -- change strata — only level via the reparenting path.
    local originalParent
    local originalLevel
    local function setupOnce()
        if setupDone then return end
        setupDone = true

        originalParent = frame:GetParent()
        originalLevel  = frame:GetFrameLevel()

        if reparentToAnchor and baseAnchor and baseAnchor.relativeTo then
            frame:SetParent(baseAnchor.relativeTo)
            -- Keep the panel beneath the anchor's content. Useful for
            -- transforms that DO have the panel overlap the anchor
            -- mid-animation (slide-from-behind), and harmless for
            -- transforms that don't (wipe).
            frame:SetFrameLevel(baseAnchor.relativeTo:GetFrameLevel() - 1)
        end

        -- Apply clipsChildren preference. Done once at setup; toggling
        -- this mid-animation isn't supported.
        if clipsChildren then
            frame:SetClipsChildren(true)
        end

        -- Per-transform setup hook. Each transform that needs to
        -- capture pre-animation frame state does so here, before the
        -- first apply runs. Transforms without a setup field skip
        -- this silently.
        for i = 1, #transforms do
            local t = transforms[i]
            local handler = TRANSFORMS[t.type]
            if not handler then
                error("withAnimation: unknown transform type '" .. tostring(t.type) .. "'")
            end
            if handler.setup then
                handler.setup(frame, t, ctx)
            end
        end
    end

    --[[
      Apply every transform at the current progress. Called per-tick
      and on initial snaps.
    ]]
    local function applyAll()
        for i = 1, #transforms do
            local t = transforms[i]
            local handler = TRANSFORMS[t.type]
            if not handler then
                error("withAnimation: unknown transform type '" .. tostring(t.type) .. "'")
            end
            handler.apply(frame, t, progress, ctx)
        end
    end

    --[[
      OnUpdate driver. Walks progress toward the direction's target
      each frame; when reached, releases itself and either stays shown
      (forward) or hides the frame (reverse).
    ]]
    local function onTick(self, elapsed)
        if not direction then return end

        local delta = elapsed / duration
        if direction == "forward" then
            progress = math.min(1, progress + delta)
            applyAll()
            if progress >= 1 then
                direction = nil
                self:SetScript("OnUpdate", nil)
            end
        else  -- "reverse"
            progress = math.max(0, progress - delta)
            applyAll()
            if progress <= 0 then
                direction = nil
                self:SetScript("OnUpdate", nil)
                frame:Hide()
            end
        end
    end

    function controller:show()
        setupOnce()
        direction = "forward"
        frame:Show()
        applyAll()  -- snap to current progress immediately so first
                    -- visible frame is correct, before OnUpdate fires
        frame:SetScript("OnUpdate", onTick)
    end

    function controller:hide()
        if not frame:IsShown() then return end
        direction = "reverse"
        frame:SetScript("OnUpdate", onTick)
    end

    function controller:toggle()
        if self:isOpen() then
            self:hide()
        else
            self:show()
        end
    end

    function controller:isOpen()
        if not frame:IsShown() then return false end
        if direction == "reverse" then return false end
        return true
    end

    --[[
      Tear down the controller and restore the frame to its
      pre-animation state. Call before discarding the controller
      (e.g., when a consumer rebuilds with different transforms) so
      the next controller starts from a clean slate.

      The reset chain:
        1. Stop any in-flight animation
        2. Hide the frame (no visible artifact during teardown)
        3. Per-transform reset (camp rule)
        4. Controller-level reset (parent, frame level, clipsChildren)

      After destroy, the controller is unusable — calls to show/hide/
      etc. are no-ops or undefined. Discard the reference.
    ]]
    function controller:destroy()
        -- Stop animation
        direction = nil
        frame:SetScript("OnUpdate", nil)

        -- Hide so any reset that mutates visible state isn't seen
        frame:Hide()

        -- Per-transform reset (camp rule). Only run if setup has run;
        -- otherwise transforms have nothing to reset and ctx is empty
        -- of the keys their reset would read.
        if setupDone then
            for i = 1, #transforms do
                local t = transforms[i]
                local handler = TRANSFORMS[t.type]
                if handler and handler.reset then
                    handler.reset(frame, t, ctx)
                end
            end
        end

        -- Controller-level reset
        if clipsChildren then
            frame:SetClipsChildren(false)
        end
        if originalParent then
            frame:SetParent(originalParent)
        end
        if originalLevel then
            frame:SetFrameLevel(originalLevel)
        end
    end

    return controller
end

-- ============================================================================
-- FACTORY
-- ============================================================================

--[[
  Create an opaque panel frame. Backdrop fills with WHITE8X8 (truly
  opaque, unlike UI-Tooltip-Background which has baked-in per-pixel
  alpha).

  @param parent Frame
  @param opts table - {
      name           = string|nil,    -- optional global frame name
      edgeFile       = string,        -- border texture (default tooltip border)
      edgeSize       = number,        -- border size (default 12)
      insets         = {left,right,top,bottom},
      r,g,b,a        = backdrop color,
      strata         = explicit frame strata,
      parentStrata   = bool — inherit from parent,
      level          = explicit frame level,
  }
  @return Frame with an extra :withAnimation(opts) method.
]]
function panel:opaque(parent, opts)
    opts = opts or {}

    local insets = opts.insets or {
        left = 3, right = 3, top = 3, bottom = 3,
    }

    local frame = CreateFrame("Frame", opts.name, parent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = opts.edgeFile or "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false,
        edgeSize = opts.edgeSize or 12,
        insets   = insets,
    })

    frame:SetBackdropColor(
        opts.r or 0.05,
        opts.g or 0.05,
        opts.b or 0.07,
        opts.a or 1.0
    )

    if opts.strata then
        frame:SetFrameStrata(opts.strata)
    elseif opts.parentStrata and parent and parent.GetFrameStrata then
        frame:SetFrameStrata(parent:GetFrameStrata())
    end

    if opts.level then
        frame:SetFrameLevel(opts.level)
    elseif parent and parent.GetFrameLevel then
        frame:SetFrameLevel(parent:GetFrameLevel() + 10)
    end

    --[[
      Build an animation controller bound to this frame. See module
      header for option schema and behavior.
    ]]
    function frame:withAnimation(animOpts)
        return buildController(self, animOpts)
    end

    return frame
end

Addon.panel = panel
return panel
