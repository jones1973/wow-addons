--[[
  ui/shared/escapeHandler.lua
  Full-Screen Drag Escape Handler
  
  Provides full-screen ESC capture and click detection during drag operations.
  Uses OnUpdate polling to detect mouse clicks without blocking hover events on
  drop targets. Pattern matches team section implementation.
  
  Usage:
    local handler = Addon.escapeHandler:create({
        onCancel = function() ... end,     -- ESC pressed
        onClick = function(button) ... end, -- Subsequent clicks after first release
        onRelease = function() ... end     -- First mouse release
    })
    
    -- Start drag mode
    handler:show()
    
    -- End drag mode
    handler:hide()
  
  Dependencies: None (standalone utility)
  Exports: Addon.escapeHandler
]]

local ADDON_NAME, Addon = ...

local escapeHandler = {}

-- Active handlers registry (for cleanup)
local activeHandlers = {}

--[[
  Create a new escape handler instance
  
  @param callbacks table - Handler callbacks:
    - onCancel: function() - Called when ESC pressed or drag cancelled
    - onClick: function(button) - Called on mouse click
    - onRelease: function() - Optional, called on first mouse release (for click-to-drop transition)
  @return table - Handler instance with :show() and :hide() methods
]]
function escapeHandler:create(callbacks)
    if not callbacks or not callbacks.onCancel then
        if Addon.utils then
            Addon.utils:error("escapeHandler:create requires onCancel callback")
        end
        return nil
    end
    
    local instance = {}
    local frame = nil
    local isFirstRelease = false
    
    -- Create the full-screen frame
    local function createFrame()
        if frame then return frame end
        
        frame = CreateFrame("Frame", nil, UIParent)
        frame:SetAllPoints(UIParent)
        frame:SetFrameStrata("FULLSCREEN")
        frame:EnableKeyboard(false)
        frame:EnableMouse(false)
        frame:Hide()
        frame:SetPropagateKeyboardInput(true)
        
        -- ESC key handler
        frame:SetScript("OnKeyDown", function(self, key)
            if key == "ESCAPE" then
                -- Call cleanup FIRST
                if callbacks.onCancel then
                    callbacks.onCancel()
                end
                -- THEN consume the ESC (matches team section pattern)
                self:SetPropagateKeyboardInput(false)
            end
        end)
        
        -- Mouse polling handler (uses OnUpdate to detect clicks without blocking hover)
        -- This pattern allows drop target frames to receive OnEnter/OnLeave events
        -- while still detecting mouse button state changes
        frame.wasButtonDown = false
        frame:SetScript("OnUpdate", function(self)
            local isButtonDown = IsMouseButtonDown("LeftButton")
            
            -- Detect button release (was down, now up)
            if self.wasButtonDown and not isButtonDown then
                -- First release - transition to click-to-drop
                if isFirstRelease then
                    isFirstRelease = false
                    if callbacks.onRelease then
                        callbacks.onRelease()
                    end
                else
                    -- Subsequent click - handle drop/cancel
                    if callbacks.onClick then
                        callbacks.onClick("LeftButton")
                    end
                end
            end
            
            self.wasButtonDown = isButtonDown
        end)
        
        return frame
    end
    
    -- Show handler (enable capture)
    function instance:show()
        if not frame then
            createFrame()
        end
        
        isFirstRelease = true
        frame.wasButtonDown = IsMouseButtonDown("LeftButton")
        
        frame:EnableKeyboard(true)
        frame:EnableMouse(false)  -- Keep false to allow hover events on drop targets
        frame:SetFrameStrata("FULLSCREEN")
        frame:SetPropagateKeyboardInput(true)
        frame:Show()
        
        -- Temporarily remove PAO from UISpecialFrames (prevent ESC from closing window)
        for i = #UISpecialFrames, 1, -1 do
            if UISpecialFrames[i] == "PawAndOrderMainFrame" then
                table.remove(UISpecialFrames, i)
                break
            end
        end
        
        activeHandlers[instance] = true
    end
    
    -- Hide handler (disable capture)
    function instance:hide()
        if not frame then return end
        
        frame:EnableKeyboard(false)
        frame:EnableMouse(false)
        frame:SetPropagateKeyboardInput(true)  -- Reset for next use
        frame:SetFrameStrata("BACKGROUND")
        frame:Hide()
        
        isFirstRelease = false
        frame.wasButtonDown = false
        
        -- Restore PAO to UISpecialFrames immediately (team section did this)
        local found = false
        for i = 1, #UISpecialFrames do
            if UISpecialFrames[i] == "PawAndOrderMainFrame" then
                found = true
                break
            end
        end
        if not found then
            table.insert(UISpecialFrames, "PawAndOrderMainFrame")
        end
        
        activeHandlers[instance] = nil
    end
    
    -- Cleanup
    function instance:destroy()
        instance:hide()
        if frame then
            frame:SetScript("OnKeyDown", nil)
            frame:SetScript("OnMouseUp", nil)
            frame = nil
        end
        activeHandlers[instance] = nil
    end
    
    return instance
end

--[[
  Hide all active handlers
  Utility for cleanup on logout or major state changes
]]
function escapeHandler:hideAll()
    for handler in pairs(activeHandlers) do
        handler:hide()
    end
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("escapeHandler", {}, function()
        return true
    end)
end

-- Export
Addon.escapeHandler = escapeHandler
return escapeHandler