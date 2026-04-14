--[[
  ui/levelingQueue/autoScroll.lua
  Auto-Scroll During Drag Operations
  
  Provides smooth auto-scrolling when dragging near scroll frame edges.
  Scrolls ~2 cards at a time for incremental, predictable movement.
  
  Dependencies: None (standalone utility)
  Exports: Addon.levelingQueueAutoScroll
]]

local ADDON_NAME, Addon = ...

local autoScroll = {}

-- Auto-scroll frame (singleton)
local scrollAutoScrollFrame = nil

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Start auto-scrolling during drag operation
  
  @param scrollFrame frame - ScrollFrame to auto-scroll
  @param dragState table - Drag state with sourceQueueId field
  @param layout table - Layout constants (CARD_HEIGHT, CARD_GAP, AUTOSCROLL_EDGE_THRESHOLD, AUTOSCROLL_CARDS_PER_STEP)
]]
function autoScroll:start(scrollFrame, dragState, layout)
    if scrollAutoScrollFrame then
        scrollAutoScrollFrame:SetScript("OnUpdate", nil)
    end
    
    if not dragState.sourceQueueId then
        return
    end
    
    if not scrollAutoScrollFrame then
        scrollAutoScrollFrame = CreateFrame("Frame")
    end
    
    scrollAutoScrollFrame:SetScript("OnUpdate", function(self, elapsed)
        if not dragState.sourceQueueId or not scrollFrame then
            self:SetScript("OnUpdate", nil)
            return
        end
        
        local frameTop = scrollFrame:GetTop()
        local frameBottom = scrollFrame:GetBottom()
        if not frameTop or not frameBottom then return end
        
        local scale = UIParent:GetEffectiveScale()
        local _, cursorY = GetCursorPosition()
        cursorY = cursorY / scale
        
        local cardScrollAmount = (layout.CARD_HEIGHT + layout.CARD_GAP) * layout.AUTOSCROLL_CARDS_PER_STEP
        local scrollSpeed = cardScrollAmount * elapsed * 3
        
        local current = scrollFrame:GetVerticalScroll()
        local maxScroll = scrollFrame:GetVerticalScrollRange()
        
        if cursorY < frameBottom + layout.AUTOSCROLL_EDGE_THRESHOLD and current < maxScroll then
            local newScroll = math.min(current + scrollSpeed, maxScroll)
            scrollFrame:SetVerticalScroll(newScroll)
        end
        
        if cursorY > frameTop - layout.AUTOSCROLL_EDGE_THRESHOLD and current > 0 then
            local newScroll = math.max(current - scrollSpeed, 0)
            scrollFrame:SetVerticalScroll(newScroll)
        end
    end)
end

--[[
  Stop auto-scrolling
]]
function autoScroll:stop()
    if scrollAutoScrollFrame then
        scrollAutoScrollFrame:SetScript("OnUpdate", nil)
    end
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("levelingQueueAutoScroll", {}, function()
        return true
    end)
end

Addon.levelingQueueAutoScroll = autoScroll
return autoScroll
