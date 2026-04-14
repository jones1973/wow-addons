--[[
  ui/shared/dragFeedback.lua
  Shared Visual and Audio Feedback for Drag Operations
  
  Provides consistent drag/drop feedback across different drag systems:
  - Visual feedback: desaturation/dimming during drag
  - Audio feedback: pickup and drop sounds
  
  Usage:
    -- On drag start
    dragFeedback:applyDragVisuals(sourceFrame)
    dragFeedback:playPickupSound()
    
    -- On successful drop
    dragFeedback:removeDragVisuals(sourceFrame)
    dragFeedback:playDropSound()
    
    -- On cancelled drag
    dragFeedback:removeDragVisuals(sourceFrame)
  
  Dependencies: None (standalone utility)
  Exports: Addon.dragFeedback
]]

local ADDON_NAME, Addon = ...

local dragFeedback = {}

-- Sound Kit IDs for drag operations (MoP Classic)
local SOUND_PICKUP = 837  -- Pet pickup sound (SOUNDKIT.UI_PET_BATTLE_PET_PICKUP)
local SOUND_DROP = 838    -- Pet drop sound (SOUNDKIT.UI_PET_BATTLE_PET_DROP)

-- Store original state for restoration
local originalState = {}

--[[
  Apply drag visuals to a frame
  Desaturates/dims the frame to indicate it's being dragged.
  
  @param frame frame - Frame to apply visuals to
  @param alpha number - Optional alpha (default 0.5 for 50% opacity)
]]
function dragFeedback:applyDragVisuals(frame, alpha)
    if not frame then return end
    
    alpha = alpha or 0.5
    
    -- Store original state
    if not originalState[frame] then
        originalState[frame] = {
            alpha = frame:GetAlpha(),
            desaturated = frame.IsDesaturated and frame:IsDesaturated() or false
        }
    end
    
    -- Apply drag visuals
    frame:SetAlpha(alpha)
    
    -- Desaturate if supported
    if frame.SetDesaturated then
        frame:SetDesaturated(true)
    end
end

--[[
  Remove drag visuals from a frame
  Restores frame to original state.
  
  @param frame frame - Frame to restore
]]
function dragFeedback:removeDragVisuals(frame)
    if not frame then return end
    
    local stored = originalState[frame]
    if stored then
        frame:SetAlpha(stored.alpha)
        
        if frame.SetDesaturated then
            frame:SetDesaturated(stored.desaturated)
        end
        
        originalState[frame] = nil
    else
        -- Fallback to defaults
        frame:SetAlpha(1.0)
        if frame.SetDesaturated then
            frame:SetDesaturated(false)
        end
    end
end

--[[
  Play sound when drag operation starts
]]
function dragFeedback:playPickupSound()
    PlaySound(SOUND_PICKUP)
end

--[[
  Play sound when drag operation completes successfully
]]
function dragFeedback:playDropSound()
    PlaySound(SOUND_DROP)
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("dragFeedback", {}, function()
        return true
    end)
end

-- Export
Addon.dragFeedback = dragFeedback
return dragFeedback