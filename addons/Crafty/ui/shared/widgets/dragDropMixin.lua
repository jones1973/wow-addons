--[[
  ui/shared/widgets/dragDropMixin.lua
  Drag/Drop Mixin — list reordering, constrained to a group

  Reusable drag-to-reorder for a list of frames. Distinguishes clicks from drags
  through WoW's own RegisterForDrag + OnDragStart/OnDragStop, so a plain click
  never starts a reorder - only button-held-plus-movement does.

  The drop target is resolved by what the cursor is actually OVER at release
  (GetMouseFoci), not by pixel math against a fixed item height. Hovering
  detection is robust to headers, gaps, and rows of differing height, and reads
  directly as "drop it on that row". This is the same mechanism PAO's working
  drag uses on this client.

  Reordering is constrained to a GROUP: each draggable declares its group id, and
  a drop only reorders when source and target share it. A drop onto another
  group is refused (the item snaps back), which is what a grouped list wants -
  you reorder within a section, you do not fling an item across sections.

  Contract:
    mixin:applyTo(frame, {
        handle?      = frame,               -- the grab area (default: frame)
        group        = <any>,               -- group id; drop must match to reorder
        index        = function() -> n,     -- this frame's current position
        target       = function(overFrame)  -- the frame the cursor is over ->
                          -> group, index,  -- its group and index, or nil
        onReorder    = function(from, to),  -- commit the move
    })
    Optional visual hooks set on the frame after applyTo:
      frame.onDragVisualStart(self)
      frame.onDragVisualEnd(self)

  Dependencies: none
  Exports: Addon.dragDropMixin
]]

local _, Addon = ...

local dragDropMixin = {}

-- Only one drag at a time.
local activeDrag

local mixinMethods = {}

function mixinMethods:startDrag()
    local opts = self._dragOpts
    if opts.canDrag and not opts.canDrag() then return end
    activeDrag = { frame = self, opts = opts }
    self:SetFrameStrata("DIALOG")
    self:StartMoving()
    if self.onDragVisualStart then self:onDragVisualStart() end
end

-- The frame under the cursor at drop, and its group/index. Walks the mouse foci
-- (topmost first) and asks the consumer's target() to identify any it owns.
local function resolveDropTarget(opts)
    local foci = GetMouseFoci()
    if not foci then return nil end
    for _, f in ipairs(foci) do
        local group, index = opts.target(f)
        if group ~= nil and index ~= nil then
            return group, index
        end
    end
    return nil
end

function mixinMethods:endDrag()
    if not activeDrag or activeDrag.frame ~= self then return end
    local opts = activeDrag.opts
    self:StopMovingOrSizing()
    self:SetFrameStrata("MEDIUM")
    activeDrag = nil
    if self.onDragVisualEnd then self:onDragVisualEnd() end

    -- Resolve where it was dropped. A drop with no recognised target, or onto a
    -- different group, is a no-op: the list re-lays out and the frame returns to
    -- its place.
    local fromIndex = opts.index()
    local group, toIndex = resolveDropTarget(opts)
    if group == nil or group ~= opts.group then return end
    if toIndex == fromIndex then return end

    -- Insert-position correction: dragging DOWN past the target, the target's
    -- index shifts up by one once the source is removed, so the item lands
    -- correctly above it.
    local insertIndex = toIndex
    if fromIndex < toIndex then insertIndex = toIndex - 1 end
    if insertIndex ~= fromIndex then
        opts.onReorder(fromIndex, insertIndex)
    end
end

function mixinMethods:cancelDrag()
    if not activeDrag or activeDrag.frame ~= self then return end
    self:StopMovingOrSizing()
    self:SetFrameStrata("MEDIUM")
    activeDrag = nil
    if self.onDragVisualEnd then self:onDragVisualEnd() end
end

function mixinMethods:isDragging()
    return activeDrag ~= nil and activeDrag.frame == self
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function dragDropMixin:applyTo(frame, opts)
    for name, method in pairs(mixinMethods) do
        frame[name] = method
    end
    frame._dragOpts = opts

    frame:SetMovable(true)
    frame:SetClampedToScreen(true)

    local handle = opts.handle or frame
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart", function() frame:startDrag() end)
    handle:SetScript("OnDragStop", function() frame:endDrag() end)
end

function dragDropMixin:isAnyDragActive()
    return activeDrag ~= nil
end

function dragDropMixin:cancelActiveDrag()
    if activeDrag and activeDrag.frame then
        activeDrag.frame:cancelDrag()
    end
end

Addon.dragDropMixin = dragDropMixin
return dragDropMixin
