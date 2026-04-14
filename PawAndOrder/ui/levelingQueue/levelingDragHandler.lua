--[[
  ui/levelingQueue/levelingDragHandler.lua
  Drag and Drop Handler for Queue Reordering
  
  Manages drag-and-drop operations for queue card reordering:
  - Setup drag handlers on cards
  - Perform reorder using GetMouseFoci detection
  - Reset cards after drag completion
  - Coordinate with escape handler for click-to-drop mode
  
  Dependencies: dragFeedback, ghostCard, autoScroll
  Exports: Addon.levelingDragHandler
]]

local ADDON_NAME, Addon = ...

local dragHandler = {}

-- Module references
local dragFeedback, ghostCard, autoScroll, levelingLogic

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function setupHoverBehavior(widget, card, dragState, editingQueueIdGetter)
    widget:SetScript("OnEnter", function()
        if not dragState.sourceQueueId and not editingQueueIdGetter() and card.hoverBg then
            card.hoverBg:Show()
        end
    end)
    widget:SetScript("OnLeave", function()
        if not dragState.sourceQueueId and card.hoverBg and not card:IsMouseOver() then
            card.hoverBg:Hide()
        end
    end)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Setup drag handlers on a queue card
  
  @param card frame - Queue card frame
  @param dragState table - Shared drag state
  @param scrollChild frame - Scroll child for positioning
  @param layout table - Layout constants
  @param editingQueueIdGetter function - Returns current editing queue ID
  @param refreshCallback function - Called after reorder
]]
function dragHandler:setupCard(card, dragState, scrollChild, layout, editingQueueIdGetter, refreshCallback)
    if not card then return end
    
    card:EnableMouse(true)
    card:RegisterForDrag("LeftButton")
    
    setupHoverBehavior(card, card, dragState, editingQueueIdGetter)
    
    card:SetScript("OnDragStart", function(self)
        if editingQueueIdGetter() then return end
        
        local queueId = self.queueId
        if not queueId then return end
        
        dragState.sourceQueueId = queueId
        dragState.sourceCard = self
        
        dragState.ghostCard = ghostCard:create(self)
        
        local index = self.displayIndex
        if index then
            local yOff = -(index - 1) * (layout.CARD_HEIGHT + layout.CARD_GAP)
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", layout.DRAG_SHIFT_X, yOff)
            self:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", layout.DRAG_SHIFT_X, yOff)
        end
        
        dragFeedback:applyDragVisuals(self, 0.6)
        
        if self.hoverBg then
            self.hoverBg:Hide()
        end
        
        autoScroll:start(dragState.scrollFrame, dragState, layout)
        dragFeedback:playPickupSound()
        
        if dragState.escapeHandler then
            dragState.escapeHandler:show()
        end
    end)
    
    card:SetScript("OnDragStop", function(self)
        -- Escape handler's OnUpdate polling handles drop/cancel
    end)
end

--[[
  Perform reorder operation using GetMouseFoci detection
  
  @param sourceQueueId string - Source queue ID being dragged
  @param dragState table - Shared drag state
  @param refreshCallback function - Called after reorder
  @return boolean - True if reorder succeeded
]]
function dragHandler:performReorder(sourceQueueId, dragState, refreshCallback)
    local mouseFoci = GetMouseFoci()
    local targetFrame = mouseFoci and mouseFoci[1]
    local targetQueueId = targetFrame and targetFrame.queueId
    
    if not targetQueueId or targetQueueId == sourceQueueId then
        return false
    end
    
    local queues = levelingLogic:getQueues()
    if not queues then return false end
    
    local sourceIndex, targetIndex
    for i, q in ipairs(queues) do
        if q.id == sourceQueueId then sourceIndex = i end
        if q.id == targetQueueId then targetIndex = i end
    end
    
    if not sourceIndex or not targetIndex then return false end
    
    -- Clear drag visuals BEFORE reorder to prevent stale alpha values.
    -- Cards get reassigned during refresh, so we must cleanup on source card NOW.
    if dragState.sourceCard then
        dragFeedback:removeDragVisuals(dragState.sourceCard)
        dragState.sourceCard._dragVisualsCleared = true
    end
    
    if dragState.ghostCard then
        ghostCard:destroy(dragState.ghostCard)
        dragState.ghostCard = nil
    end
    
    local newOrder = {}
    for i, q in ipairs(queues) do
        if i ~= sourceIndex then
            table.insert(newOrder, q.id)
        end
    end
    
    local insertIndex = targetIndex
    if sourceIndex < targetIndex then
        insertIndex = targetIndex - 1
    end
    
    table.insert(newOrder, insertIndex, sourceQueueId)
    
    levelingLogic:reorderQueues(newOrder)
    if refreshCallback then
        refreshCallback()
    end
    dragFeedback:playDropSound()
    
    return true
end

--[[
  Reset cards after drag operation (success or cancel)
  
  @param dragState table - Shared drag state
  @param queueCards table - Array of queue card frames
  @param scrollChild frame - Scroll child for positioning
  @param layout table - Layout constants
]]
function dragHandler:resetCards(dragState, queueCards, scrollChild, layout)
    if dragState.escapeHandler then
        dragState.escapeHandler:hide()
    end
    
    if dragState.ghostCard then
        ghostCard:destroy(dragState.ghostCard)
        dragState.ghostCard = nil
    end
    
    if dragState.sourceCard then
        if not dragState.sourceCard._dragVisualsCleared then
            dragFeedback:removeDragVisuals(dragState.sourceCard)
        end
        dragState.sourceCard._dragVisualsCleared = nil
        
        local index = dragState.sourceCard.displayIndex
        if index then
            local yOff = -(index - 1) * (layout.CARD_HEIGHT + layout.CARD_GAP)
            dragState.sourceCard:ClearAllPoints()
            dragState.sourceCard:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOff)
            dragState.sourceCard:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, yOff)
        end
    end
    
    for _, card in ipairs(queueCards) do
        if card.hoverBg then
            card.hoverBg:Hide()
        end
    end
    
    autoScroll:stop()
    
    dragState.sourceQueueId = nil
    dragState.sourceCard = nil
    dragState.inClickToDropMode = false
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function dragHandler:initialize()
    dragFeedback = Addon.dragFeedback
    ghostCard = Addon.levelingQueueGhostCard
    autoScroll = Addon.levelingQueueAutoScroll
    levelingLogic = Addon.levelingLogic
    
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("levelingDragHandler", {
        "dragFeedback", "levelingQueueGhostCard", "levelingQueueAutoScroll", "levelingLogic"
    }, function()
        return dragHandler:initialize()
    end)
end

Addon.levelingDragHandler = dragHandler
return dragHandler
