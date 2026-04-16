--[[
  ui/shared/dragDropMixin.lua
  Drag/Drop Mixin for List Reordering
  
  Provides reusable drag-and-drop behavior for reordering items in a list.
  Does NOT handle WoW's native cursor system (battle pets, items) - that's
  widget-specific.
  
  Uses RegisterForDrag + OnDragStart/OnDragStop to distinguish clicks from drags:
  - Quick clicks do NOT trigger reordering
  - Only drags (button held + movement) trigger OnDragStart
  - This is WoW's built-in click vs drag distinction
  
  Usage:
    local mixin = Addon.dragDropMixin
    
    -- Apply to a frame
    mixin:applyTo(card, {
        handle = card.dragHandle,       -- Optional: specific drag handle (default: frame itself)
        container = scrollChild,        -- Parent container for position calculations
        itemHeight = 60,                -- Height of each item + gap
        getItemCount = function() return #items end,
        onReorder = function(fromIndex, toIndex) ... end,
        canDrag = function() return not isEditing end,  -- Optional: conditional dragging
    })
  
  Visual hooks (set on frame after applyTo):
    frame.onDragVisualStart = function(self) ... end
    frame.onDragVisualEnd = function(self) ... end
  
  Dependencies: None (standalone mixin)
  Exports: Addon.dragDropMixin
]]

local ADDON_NAME, Addon = ...

local dragDropMixin = {}

-- Active drag state (only one drag at a time)
local activeDrag = nil

-- ============================================================================
-- MIXIN METHODS (copied to target frame)
-- ============================================================================

local mixinMethods = {}

--[[
  Start dragging this frame
  Called internally by mouse handlers.
]]
function mixinMethods:startDrag()
    local opts = self._dragOpts
    if not opts then return end
    
    -- Check if dragging is allowed
    if opts.canDrag and not opts.canDrag() then
        return
    end
    
    -- Store drag state
    activeDrag = {
        frame = self,
        startY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale(),
        originalIndex = self._dragIndex or 1,
        opts = opts,
    }
    
    -- Visual feedback
    self:SetFrameStrata("DIALOG")
    self:StartMoving()
    
    -- Custom visual hook
    if self.onDragVisualStart then
        self:onDragVisualStart()
    end
end

--[[
  End dragging this frame
  Calculates new position and triggers reorder callback.
]]
function mixinMethods:endDrag()
    if not activeDrag or activeDrag.frame ~= self then
        return
    end
    
    local opts = activeDrag.opts
    
    -- Stop movement
    self:StopMovingOrSizing()
    self:SetFrameStrata("MEDIUM")
    
    -- Calculate new index based on Y position
    local frameTop = self:GetTop()
    local containerTop = opts.container:GetTop()
    local relativeY = containerTop - frameTop
    local newIndex = math.floor(relativeY / opts.itemHeight) + 1
    
    -- Clamp to valid range
    local itemCount = opts.getItemCount and opts.getItemCount() or 1
    newIndex = math.max(1, math.min(newIndex, itemCount))
    
    -- Trigger reorder if position changed
    if newIndex ~= activeDrag.originalIndex and opts.onReorder then
        opts.onReorder(activeDrag.originalIndex, newIndex)
    end
    
    -- Custom visual hook
    if self.onDragVisualEnd then
        self:onDragVisualEnd()
    end
    
    -- Clear state
    activeDrag = nil
end

--[[
  Cancel dragging without reordering
]]
function mixinMethods:cancelDrag()
    if not activeDrag or activeDrag.frame ~= self then
        return
    end
    
    self:StopMovingOrSizing()
    self:SetFrameStrata("MEDIUM")
    
    if self.onDragVisualEnd then
        self:onDragVisualEnd()
    end
    
    activeDrag = nil
end

--[[
  Set the current index of this draggable item
  Call this when refreshing the list.
  
  @param index number - Current position in list
]]
function mixinMethods:setDragIndex(index)
    self._dragIndex = index
end

--[[
  Check if this frame is currently being dragged
  
  @return boolean
]]
function mixinMethods:isDragging()
    return activeDrag and activeDrag.frame == self
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Apply drag/drop behavior to a frame
  
  @param frame frame - Target frame
  @param opts table - Configuration:
    - handle: frame - Drag handle (default: frame itself)
    - container: frame - Parent for position calculations
    - itemHeight: number - Height of item + gap
    - getItemCount: function - Returns total item count
    - onReorder: function(fromIndex, toIndex) - Reorder callback
    - canDrag: function - Optional, returns true if dragging allowed
]]
function dragDropMixin:applyTo(frame, opts)
    if not frame or not opts then
        return
    end
    
    -- Validate required options
    if not opts.container then
        if Addon.utils then
            Addon.utils:error("dragDropMixin: container is required")
        end
        return
    end
    
    if not opts.itemHeight or opts.itemHeight <= 0 then
        if Addon.utils then
            Addon.utils:error("dragDropMixin: itemHeight must be positive")
        end
        return
    end
    
    -- Copy mixin methods to frame
    for name, method in pairs(mixinMethods) do
        frame[name] = method
    end
    
    -- Store options on frame
    frame._dragOpts = opts
    frame._dragIndex = 1
    
    -- Make frame movable
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    
    -- Setup drag handle (or frame itself)
    local handle = opts.handle or frame
    
    -- Enable mouse and register for drag
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    
    -- OnDragStart - only fires after button held + movement (not on quick clicks)
    handle:SetScript("OnDragStart", function(self, button)
        frame:startDrag()
    end)
    
    -- OnDragStop - fires when drag ends
    handle:SetScript("OnDragStop", function(self)
        frame:endDrag()
    end)
end

--[[
  Check if any drag operation is active
  
  @return boolean
]]
function dragDropMixin:isAnyDragActive()
    return activeDrag ~= nil
end

--[[
  Cancel any active drag operation
]]
function dragDropMixin:cancelActiveDrag()
    if activeDrag and activeDrag.frame then
        activeDrag.frame:cancelDrag()
    end
end

-- ============================================================================
-- EXPORTS
-- ============================================================================

Addon.dragDropMixin = dragDropMixin

return dragDropMixin