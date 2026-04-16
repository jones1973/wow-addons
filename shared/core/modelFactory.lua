--[[
  core/modelFactory.lua
  Pet Model Factory
  
  Centralized factory for creating and managing pet 3D models using ModelScene.
  Supports multiple modes:
  
  ROTATION MODES:
  
  CONTINUOUS (default):
  - Constant smooth rotation between random angles
  - Ease-in-out interpolation
  - Resize-aware (pauses during resize)
  
  PERIODIC (opt-in):
  - Waits for initial delay before first rotation
  - Rotates to new angle, then waits for interval
  - Ideal for celebration displays where subtle movement adds life
  
  WALKING MODE (opt-in):
  - Physical movement within frame boundaries
  - Walk animation while moving, idle when stopped
  - Turns to face movement direction
  - Random waypoints or consumer-defined path
  - Configurable speed and pause duration
  
  Usage:
    local model, controls = modelFactory:create(parent, width, height)
    modelFactory:setPet(model, petID)
    
    -- Continuous rotation (always moving)
    controls:enableRotation({ minAngle = -45, maxAngle = 45 })
    
    -- Periodic rotation (occasional movement)
    controls:enableRotation({
      minAngle = -20,
      maxAngle = 20,
      duration = {1.5, 2.5},
      mode = "periodic",
      initialDelay = {3, 8},
      interval = {5, 15},
    })
    
    -- Walking mode
    controls:enableWalking({ speed = 50, boundaries = frame:GetRect() })
    
    -- Cleanup
    controls:disable()
  
  Dependencies: None (standalone)
  Exports: Addon.modelFactory
]]

local ADDON_NAME, Addon = ...

local modelFactory = {}

-- ============================================================================
-- STATE MANAGEMENT
-- ============================================================================

-- Model state tracking: { [model] = { mode, config, state } }
local modelStates = {}

-- Shared update frames
local rotationFrame = nil
local walkingFrame = nil

-- Animation IDs (verified from Blizzard code)
local ANIM_IDLE = 0
local ANIM_DEAD = 6
local ANIM_BATTLE_STAND = 742
local ANIM_WALK = 4  -- Best guess, may need experimentation

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

--[[
  Generate random angle in radians within min/max degrees
]]
local function randomAngle(minDeg, maxDeg)
  local range = maxDeg - minDeg
  return (minDeg + math.random() * range) * (math.pi / 180)
end

--[[
  Generate random duration within range
]]
local function randomDuration(min, max)
  return min + math.random() * (max - min)
end

--[[
  Ease-in-out interpolation (same as teamSection)
]]
local function easeInOut(progress)
  if progress < 0.5 then
    return 2 * progress * progress
  else
    return 1 - ((-2 * progress + 2) ^ 2) / 2
  end
end

--[[
  Calculate distance between two points
]]
local function distance(x1, y1, x2, y2)
  local dx = x2 - x1
  local dy = y2 - y1
  return math.sqrt(dx * dx + dy * dy)
end

--[[
  Calculate angle from point1 to point2 (for facing direction)
]]
local function angleToPoint(x1, y1, x2, y2)
  return math.atan2(y2 - y1, x2 - x1)
end

-- ============================================================================
-- MODEL CREATION
-- ============================================================================

--[[
  Create a pet model frame using ModelScene
  
  @param parent frame - Parent frame
  @param width number - Model width
  @param height number - Model height
  @return frame - ModelScene frame
  @return table - Control interface
]]
function modelFactory:create(parent, width, height)
  local modelScene = CreateFrame("ModelScene", nil, parent, "ModelSceneMixinTemplate")
  modelScene:SetSize(width, height)
  
  -- Initialize state
  modelStates[modelScene] = {
    mode = nil,  -- "rotation" or "walking"
    config = {},
    state = {},
    petID = nil,
    speciesID = nil,
    displayID = nil,
  }
  
  -- Create control interface
  local controls = {}
  
  --[[
    Enable rotation mode
    @param config table - {
      minAngle: number (degrees, default -45),
      maxAngle: number (degrees, default 45),
      duration: {min, max} (seconds, default {0.5, 1.5}),
      mode: "continuous" | "periodic" (default "continuous"),
      initialDelay: {min, max} (seconds, periodic only, default {3, 8}),
      interval: {min, max} (seconds between rotations, periodic only, default {5, 15}),
    }
  ]]
  function controls:enableRotation(config)
    config = config or {}
    local mState = modelStates[modelScene]
    local rotationMode = config.mode or "continuous"
    mState.mode = "rotation"
    mState.config = {
      minAngle = config.minAngle or -45,
      maxAngle = config.maxAngle or 45,
      durationMin = config.duration and config.duration[1] or 0.5,
      durationMax = config.duration and config.duration[2] or 1.5,
      rotationMode = rotationMode,
      initialDelayMin = config.initialDelay and config.initialDelay[1] or 3,
      initialDelayMax = config.initialDelay and config.initialDelay[2] or 8,
      intervalMin = config.interval and config.interval[1] or 5,
      intervalMax = config.interval and config.interval[2] or 15,
    }
    
    local now = GetTime()
    
    if rotationMode == "periodic" then
      -- Periodic: wait for initial delay before first rotation
      local initialDelay = randomDuration(mState.config.initialDelayMin, mState.config.initialDelayMax)
      mState.state = {
        currentAngle = randomAngle(mState.config.minAngle, mState.config.maxAngle),
        rotating = false,
        nextRotationTime = now + initialDelay,
      }
      -- Apply initial angle immediately
      if modelScene:IsVisible() then
        local actor = modelScene:GetActorByTag("unwrapped")
        if actor then
          actor:SetYaw(mState.state.currentAngle)
        end
      end
    else
      -- Continuous: start rotating immediately
      mState.state = {
        currentAngle = 0,
        targetAngle = randomAngle(mState.config.minAngle, mState.config.maxAngle),
        startAngle = 0,
        startTime = now,
        duration = randomDuration(mState.config.durationMin, mState.config.durationMax),
      }
    end
    
    -- Start rotation frame if not running
    if not rotationFrame or not rotationFrame:IsShown() then
      modelFactory:startRotationUpdates()
    end
  end
  
  --[[
    Enable walking mode
    @param config table - { speed, boundaries, waypoints, pauseDuration }
  ]]
  function controls:enableWalking(config)
    config = config or {}
    local mState = modelStates[modelScene]
    mState.mode = "walking"
    mState.config = {
      speed = config.speed or 50,  -- pixels per second
      boundaries = config.boundaries,  -- {left, right, top, bottom}
      waypoints = config.waypoints or "random",
      walkAnimation = config.walkAnimation or ANIM_WALK,
      idleAnimation = config.idleAnimation or ANIM_IDLE,
      pauseMin = config.pauseDuration and config.pauseDuration[1] or 2,
      pauseMax = config.pauseDuration and config.pauseDuration[2] or 5,
    }
    mState.state = {
      x = 0,
      y = 0,
      targetX = nil,
      targetY = nil,
      moving = false,
      pauseUntil = nil,
    }
    
    -- Set initial position (center of boundaries)
    if mState.config.boundaries then
      local bounds = mState.config.boundaries
      mState.state.x = (bounds.left + bounds.right) / 2
      mState.state.y = (bounds.top + bounds.bottom) / 2
    end
    
    -- Start walking frame if not running
    if not walkingFrame or not walkingFrame:IsShown() then
      modelFactory:startWalkingUpdates()
    end
  end
  
  --[[
    Disable all animations
  ]]
  function controls:disable()
    local mState = modelStates[modelScene]
    if mState then
      mState.mode = nil
      mState.state = {}
    end
  end
  
  --[[
    Pause animations (for resize)
  ]]
  function controls:pause()
    local mState = modelStates[modelScene]
    if mState and mState.state then
      mState.state.paused = true
    end
  end
  
  --[[
    Resume animations (after resize)
  ]]
  function controls:resume()
    local mState = modelStates[modelScene]
    if mState and mState.state then
      mState.state.paused = false
    end
  end
  
  --[[
    Normalize model scale using bounding box.
    Makes different-sized pets appear similar size.
    
    @param targetHeight number - Target model height (default 1.8)
    @return boolean - Success
  ]]
  function controls:normalizeScale(targetHeight)
    targetHeight = targetHeight or 1.8
    
    local mState = modelStates[modelScene]
    if not mState or not mState.actor then return false end
    
    local actor = mState.actor
    local minX, minY, minZ, maxX, maxY, maxZ = actor:GetActiveBoundingBox()
    
    if not minY or not maxY then return false end
    
    local modelHeight = maxY - minY
    if modelHeight <= 0 then return false end
    
    local scale = targetHeight / modelHeight
    actor:SetScale(scale)
    
    return true
  end
  
  return modelScene, controls
end

-- ============================================================================
-- PET MANAGEMENT
-- ============================================================================

--[[
  Set pet on model by petID
  
  @param modelScene frame - ModelScene frame
  @param petID string - Pet ID
  @return boolean - Success
]]
function modelFactory:setPet(modelScene, petID)
  if not modelScene or not petID then
    self:clear(modelScene)
    return false
  end
  
  local mState = modelStates[modelScene]
  if not mState then return false end
  
  -- Get pet info
  local speciesID, _, _, _, _, displayID = C_PetJournal.GetPetInfoByPetID(petID)
  if not speciesID or not displayID or displayID == 0 then
    self:clear(modelScene)
    return false
  end
  
  -- Get scene IDs - Blizzard returns card and loadout scene IDs
  -- Use loadout scene ID (second return) as it's designed for display without background
  local cardSceneID, loadoutSceneID = C_PetJournal.GetPetModelSceneInfoBySpeciesID(speciesID)
  local sceneID = loadoutSceneID or cardSceneID
  if not sceneID then
    self:clear(modelScene)
    return false
  end
  
  -- Transition to scene
  modelScene:TransitionToModelSceneID(sceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_DISCARD, true)
  
  -- Get actor - try "pet" tag first (loadout scenes), then "unwrapped" (card scenes)
  local actor = modelScene:GetActorByTag("pet") or modelScene:GetActorByTag("unwrapped")
  if not actor then
    self:clear(modelScene)
    return false
  end
  
  actor:SetModelByCreatureDisplayID(displayID, true)
  actor:SetAnimationBlendOperation(Enum.ModelBlendOperation.None)
  actor:SetAnimation(ANIM_IDLE, -1)
  
  -- Store pet info and actor reference
  mState.petID = petID
  mState.speciesID = speciesID
  mState.displayID = displayID
  mState.actor = actor  -- Store for rotation
  
  return true
end

--[[
  Clear model
]]
function modelFactory:clear(modelScene)
  if not modelScene then return end
  
  local mState = modelStates[modelScene]
  if mState then
    -- Clear the actor model if we have a reference
    if mState.actor then
      mState.actor:SetModelByCreatureDisplayID(0, true)
    end
    mState.petID = nil
    mState.speciesID = nil
    mState.displayID = nil
    mState.actor = nil
  end
end

-- ============================================================================
-- ROTATION MODE UPDATES
-- ============================================================================

function modelFactory:startRotationUpdates()
  if not rotationFrame then
    rotationFrame = CreateFrame("Frame")
    rotationFrame:SetScript("OnUpdate", function(self, elapsed)
      local now = GetTime()
      local anyActive = false
      
      for modelScene, mState in pairs(modelStates) do
        if mState.mode == "rotation" and not mState.state.paused then
          local state = mState.state
          local config = mState.config
          
          if config.rotationMode == "periodic" then
            -- Periodic mode: rotate on intervals
            if state.rotating then
              -- Currently rotating - interpolate
              local progress = (now - state.startTime) / state.duration
              
              if progress >= 1 then
                -- Rotation complete
                state.currentAngle = state.targetAngle
                state.rotating = false
                state.nextRotationTime = now + randomDuration(config.intervalMin, config.intervalMax)
              else
                -- Interpolate
                local easedProgress = easeInOut(progress)
                state.currentAngle = state.startAngle + (state.targetAngle - state.startAngle) * easedProgress
              end
              
              -- Apply rotation (periodic mode)
              if modelScene:IsVisible() and mState.actor then
                mState.actor:SetYaw(state.currentAngle)
              end
              anyActive = true
            elseif state.nextRotationTime and now >= state.nextRotationTime then
              -- Time to start a new rotation
              state.rotating = true
              state.startAngle = state.currentAngle
              state.targetAngle = randomAngle(config.minAngle, config.maxAngle)
              state.startTime = now
              state.duration = randomDuration(config.durationMin, config.durationMax)
              anyActive = true
            else
              -- Waiting for next rotation
              anyActive = true
            end
          else
            -- Continuous mode: always rotating
            if state.startTime and state.targetAngle and state.duration then
              local progress = (now - state.startTime) / state.duration
              
              if progress >= 1 then
                -- Rotation complete, start new one
                state.currentAngle = state.targetAngle
                state.startAngle = state.currentAngle
                state.targetAngle = randomAngle(config.minAngle, config.maxAngle)
                state.startTime = now
                state.duration = randomDuration(config.durationMin, config.durationMax)
                anyActive = true
              else
                -- Interpolate
                local easedProgress = easeInOut(progress)
                state.currentAngle = state.startAngle + (state.targetAngle - state.startAngle) * easedProgress
                anyActive = true
              end
              
              -- Apply rotation (continuous mode)
              if modelScene:IsVisible() and mState.actor then
                mState.actor:SetYaw(state.currentAngle)
              end
            end
          end
        end
      end
      
      if not anyActive then
        self:Hide()
      end
    end)
  end
  
  rotationFrame:Show()
end

-- ============================================================================
-- WALKING MODE UPDATES
-- ============================================================================

function modelFactory:startWalkingUpdates()
  if not walkingFrame then
    walkingFrame = CreateFrame("Frame")
    walkingFrame:SetScript("OnUpdate", function(self, elapsed)
      local now = GetTime()
      
      for modelScene, mState in pairs(modelStates) do
        if mState.mode == "walking" and not mState.state.paused then
          local state = mState.state
          local config = mState.config
          local actor = modelScene:GetActorByTag("unwrapped")
          
          if actor and modelScene:IsVisible() then
            -- Check if paused
            local shouldProcess = true
            if state.pauseUntil then
              if now < state.pauseUntil then
                shouldProcess = false
              else
                state.pauseUntil = nil
              end
            end
            
            if shouldProcess then
              -- Generate new target if needed
              if not state.targetX or not state.targetY then
                if config.boundaries then
                  local bounds = config.boundaries
                  state.targetX = bounds.left + math.random() * (bounds.right - bounds.left)
                  state.targetY = bounds.top - math.random() * (bounds.top - bounds.bottom)
                end
              end
              
              -- Move towards target
              if state.targetX and state.targetY then
                local dist = distance(state.x, state.y, state.targetX, state.targetY)
                
                if dist < 2 then
                  -- Reached target
                  state.x = state.targetX
                  state.y = state.targetY
                  state.targetX = nil
                  state.targetY = nil
                  state.moving = false
                  
                  -- Set idle animation
                  actor:SetAnimation(config.idleAnimation, -1)
                  
                  -- Pause before next waypoint
                  state.pauseUntil = now + randomDuration(config.pauseMin, config.pauseMax)
                else
                  -- Move towards target
                  state.moving = true
                  
                  local moveDistance = config.speed * elapsed
                  local ratio = math.min(moveDistance / dist, 1)
                  
                  state.x = state.x + (state.targetX - state.x) * ratio
                  state.y = state.y + (state.targetY - state.y) * ratio
                  
                  -- Set walk animation
                  actor:SetAnimation(config.walkAnimation, -1)
                  
                  -- Face movement direction
                  local angle = angleToPoint(state.x, state.y, state.targetX, state.targetY)
                  actor:SetYaw(angle)
                  
                  -- Move frame
                  modelScene:ClearAllPoints()
                  modelScene:SetPoint("CENTER", modelScene:GetParent(), "BOTTOMLEFT", state.x, state.y)
                end
              end
            end
          end
        end
      end
    end)
  end
  
  walkingFrame:Show()
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
  Addon.registerModule("modelFactory", {}, function()
    return true
  end)
end

Addon.modelFactory = modelFactory
return modelFactory