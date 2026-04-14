--[[
  ui/petDetails/teamSection/teamSection.lua
  Team Display Section Component
  
  Extracted from petDetails.lua. Manages the "Current Team" section showing
  the 3 active battle pets with their names, abilities, health/XP bars, and models.
  Handles drag-and-drop for team reordering.
  
  Layout per column:
    - Health bar (4px, 8px when dead)
    - Pet name (2 lines max)
    - 3 Ability icons (clickable to swap)
    - Level + XP bar (hidden at 25)
    - Pet model (draggable for reorder)
  
  Dependencies: Initialized by petDetails with panel reference
  Used by: petDetails
]]

local ADDON_NAME, Addon = ...

local teamSection = {}

-- Module state (set via initialize)
local detailPanel = nil
local constants = nil
local petDetails = nil  -- Reference back to parent for callbacks
local uiUtils = nil
local dragFeedback = nil

-- Layout constants
local LAYOUT = {
  ICON_LEFT = 12,             -- Match infoSection abilities left edge
  ACTION_BUTTONS_GAP = 12,    -- Standard top padding for team section
  ACTION_BUTTONS_HEIGHT = 44, -- Height of action button row (match HEADER_HEIGHT)
  TEAM_SLOTS_TOP = 1,         -- Gap between action buttons and team slots (stretched up)
  
  -- Team layout dimensions
  ACTION_BAR_WIDTH = 40,
  HEALTH_BAR_TOP_OFFSET = 4,
  HEALTH_TO_NAME_GAP = 6,
  NAME_AREA_HEIGHT = 32,
  NAME_TO_ABILITY_GAP = 6,
  ABILITY_TO_XP_GAP = 9,
  COLUMN_SPACING = 8,
  BOTTOM_PADDING = 4,
  TEAM_HEADER_GAP = 8,
}

-- Resize and rotation state
local RESIZE_IDLE_DELAY = 0.3   -- Seconds to wait after resize stops before updating models
local ROTATION_DURATION_MIN = 0.5  -- Minimum rotation duration
local ROTATION_DURATION_MAX = 1.5  -- Maximum rotation duration
local MAX_ROTATION_DEGREES = 45 -- Maximum random facing angle in degrees

local resizeTimer = nil         -- Timer handle for deferred model update
local isResizing = false        -- True while resize is in progress
local rotationFrame = nil       -- OnUpdate frame for rotation interpolation

-- Per-slot rotation state: { [slotIndex] = { petID, currentFacing, targetFacing, startTime, duration } }
local slotRotationState = {}

--[[
  Initialize team section module
  Stores references needed for team display operations.
  
  @param panel frame - The detail panel frame
  @param deps table - Dependencies {constants, petDetails}
]]
function teamSection:initialize(panel, deps)
  detailPanel = panel
  constants = deps.constants
  petDetails = deps.petDetails
  uiUtils = deps.uiUtils
  dragFeedback = Addon.dragFeedback
  
  -- Register for Blizzard events to auto-refresh health bars
  if Addon.events then
    -- Heal spell finished (Revive Battle Pets) - Blizzard event
    Addon.events:subscribe("PET_JOURNAL_PETS_HEALED", function(eventName)
      if Addon.utils then Addon.utils:debug("PET_JOURNAL_PETS_HEALED (Blizzard) received") end
      if detailPanel and detailPanel:IsVisible() then
        teamSection:refreshHealthAfterHeal()
      end
    end)
    
    -- Internal heal event (from secure button or bandage)
    Addon.events:subscribe("TEAM:PETS_HEALED", function()
      if Addon.utils then Addon.utils:debug("TEAM:PETS_HEALED (internal) received") end
      if detailPanel and detailPanel:IsVisible() then
        teamSection:refreshHealthAfterHeal()
      end
    end)
    
    -- Battle ended - health/XP may have changed
    Addon.events:subscribe("PET_BATTLE_OVER", function(eventName)
      -- Small delay to let API update
      C_Timer.After(0.1, function()
        if detailPanel and detailPanel:IsVisible() then
          teamSection:update()
        end
      end)
    end)
    
    -- Pet leveled during battle
    Addon.events:subscribe("PET_BATTLE_LEVEL_CHANGED", function(eventName)
      if detailPanel and detailPanel:IsVisible() then
        teamSection:update()
      end
    end)
    
    -- Loadout changed (pet added/removed from team via context menu)
    Addon.events:subscribe("LOADOUT:CHANGED", function()
      if detailPanel and detailPanel:IsVisible() then
        teamSection:update()
      end
    end)
  end
end

--[[
  Create Team Section UI
  Creates the "Current Team:" header and 3 columns showing active battle pets.
  Each column contains name, abilities, health/XP bars, and pet model.
  
  @param teamActions table - Team action buttons module
  @param teamManagement table - Team management logic module
]]
function teamSection:create(teamActions, teamManagement)
  if not detailPanel then return end

  detailPanel.teamHeader = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  detailPanel.teamHeader:SetText("Current Team:")
  
  -- Create team action bar (vertical icon bar on right side)
  detailPanel.teamActionBar = CreateFrame("Frame", nil, detailPanel)
  detailPanel.teamActionBar:SetWidth(40)
  -- Height will be set by anchoring to teamBg
  
  -- No background - transparent
  -- Border moved to left side of team section
  
  local iconSize = 32
  local iconSpacing = 8
  local yOffset = -8
  
  -- Random Team icon
  local randomBtn = CreateFrame("Button", nil, detailPanel.teamActionBar)
  randomBtn:SetSize(iconSize, iconSize)
  randomBtn:SetPoint("TOP", detailPanel.teamActionBar, "TOP", 0, yOffset)
  
  local randomIcon = randomBtn:CreateTexture(nil, "ARTWORK")
  randomIcon:SetAllPoints()
  randomIcon:SetTexture("Interface\\AddOns\\PawAndOrder\\textures\\random-paw-team.png")
  
  -- Highlight on hover
  local randomHighlight = randomBtn:CreateTexture(nil, "HIGHLIGHT")
  randomHighlight:SetAllPoints()
  randomHighlight:SetColorTexture(1, 1, 1, 0.2)
  randomHighlight:SetBlendMode("ADD")
  
  randomBtn:SetScript("OnClick", function()
    if teamManagement then teamManagement:randomTeam() end
  end)
  randomBtn:SetScript("OnMouseDown", function(self)
    randomIcon:SetPoint("TOPLEFT", 1, -1)
    randomIcon:SetPoint("BOTTOMRIGHT", 1, -1)
  end)
  randomBtn:SetScript("OnMouseUp", function(self)
    randomIcon:SetAllPoints()
  end)
  randomBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Random Team", 1, 1, 1)
    GameTooltip:AddLine("Fill team with random level 25 rare pets", nil, nil, nil, true)
    GameTooltip:Show()
  end)
  randomBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  
  yOffset = yOffset - iconSize - iconSpacing
  
  -- Find Battle icon
  local battleBtn = CreateFrame("Button", nil, detailPanel.teamActionBar)
  battleBtn:SetSize(iconSize, iconSize)
  battleBtn:SetPoint("TOP", detailPanel.teamActionBar, "TOP", 0, yOffset)
  
  local battleIcon = battleBtn:CreateTexture(nil, "ARTWORK")
  battleIcon:SetAllPoints()
  battleIcon:SetTexture(643856)
  
  -- Highlight on hover
  local battleHighlight = battleBtn:CreateTexture(nil, "HIGHLIGHT")
  battleHighlight:SetAllPoints()
  battleHighlight:SetColorTexture(1, 1, 1, 0.2)
  battleHighlight:SetBlendMode("ADD")
  
  battleBtn:SetScript("OnClick", function()
    if teamManagement then teamManagement:findBattle() end
  end)
  battleBtn:SetScript("OnMouseDown", function(self)
    battleIcon:SetPoint("TOPLEFT", 1, -1)
    battleIcon:SetPoint("BOTTOMRIGHT", 1, -1)
  end)
  battleBtn:SetScript("OnMouseUp", function(self)
    battleIcon:SetAllPoints()
  end)
  battleBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    local isQueued = teamManagement and teamManagement:getQueueState()
    if isQueued then
      GameTooltip:SetText("Leave Queue", 1, 1, 1)
      GameTooltip:AddLine("Stop searching for PvP battle", nil, nil, nil, true)
    else
      GameTooltip:SetText("Find Battle", 1, 1, 1)
      GameTooltip:AddLine("Queue for PvP pet battle", nil, nil, nil, true)
    end
    GameTooltip:Show()
  end)
  battleBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  
  detailPanel.teamBattleBtn = battleBtn
  
  yOffset = yOffset - iconSize - iconSpacing
  
  -- Heal icon
  local healBtn = CreateFrame("Button", nil, detailPanel.teamActionBar)
  healBtn:SetSize(iconSize, iconSize)
  healBtn:SetPoint("TOP", detailPanel.teamActionBar, "TOP", 0, yOffset)
  
  local healIcon = healBtn:CreateTexture(nil, "ARTWORK")
  healIcon:SetAllPoints()
  healIcon:SetTexture(132091)
  
  -- Highlight on hover
  local healHighlight = healBtn:CreateTexture(nil, "HIGHLIGHT")
  healHighlight:SetAllPoints()
  healHighlight:SetColorTexture(1, 1, 1, 0.2)
  healHighlight:SetBlendMode("ADD")
  
  healBtn:SetScript("OnClick", function()
    if teamManagement then teamManagement:healPets() end
  end)
  healBtn:SetScript("OnMouseDown", function(self)
    healIcon:SetPoint("TOPLEFT", 1, -1)
    healIcon:SetPoint("BOTTOMRIGHT", 1, -1)
  end)
  healBtn:SetScript("OnMouseUp", function(self)
    healIcon:SetAllPoints()
  end)
  healBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Heal All Pets", 1, 1, 1)
    GameTooltip:AddLine("Use Revive Battle Pets spell or bandages", nil, nil, nil, true)
    GameTooltip:Show()
  end)
  healBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)
  
  -- Create 3 team slot columns (one per pet)
  detailPanel.teamSlots = {}
  for slotIndex = 1, 3 do
    local colFrame = CreateFrame("Frame", nil, detailPanel)
    colFrame.slotIndex = slotIndex
    
    -- Enable mouse interaction for drag-and-drop
    colFrame:EnableMouse(true)
    
    -- Clip children at frame edges (clips family icon at bottom/right as intended)
    colFrame:SetClipsChildren(true)
    
    -- Create drop target (covers model area only, shown during drag operations)
    colFrame.dropTarget = CreateFrame("Frame", nil, colFrame)
    colFrame.dropTarget:SetFrameLevel(colFrame:GetFrameLevel() + 20)
    colFrame.dropTarget.slotIndex = slotIndex
    
    -- Create background texture for visual feedback
    colFrame.dropTarget.bg = colFrame.dropTarget:CreateTexture(nil, "OVERLAY")
    colFrame.dropTarget.bg:SetAllPoints()
    colFrame.dropTarget.bg:SetColorTexture(1, 1, 1, 1)
    
    -- Start hidden and non-interactive
    colFrame.dropTarget:Hide()
    colFrame.dropTarget:EnableMouse(false)
    
    -- Create drag handle (always visible, covers drop zone area for initiating drags)
    colFrame.dragHandle = CreateFrame("Frame", nil, colFrame)
    colFrame.dragHandle:SetFrameLevel(colFrame:GetFrameLevel() + 1)  -- Below abilities but above base
    colFrame.dragHandle.slotIndex = slotIndex
    colFrame.dragHandle:EnableMouse(true)
    colFrame.dragHandle:RegisterForDrag("LeftButton")
    
    -- Hover effect - brighten on enter
    colFrame.dropTarget:SetScript("OnEnter", function(self)
      local r, g, b, a = self.bg:GetVertexColor()
      self.bg:SetVertexColor(math.min(1, r + 0.2), math.min(1, g + 0.2), math.min(1, b + 0.2), a)
    end)
    
    -- Hover effect - return to base on leave
    colFrame.dropTarget:SetScript("OnLeave", function(self)
      if self.baseColor then
        self.bg:SetVertexColor(self.baseColor.r, self.baseColor.g, self.baseColor.b, self.baseColor.a)
      end
    end)
    
    -- Handle drop with OnReceiveDrag
    colFrame.dropTarget:SetScript("OnReceiveDrag", function(self)
      local cursorType, petID = GetCursorInfo()
      if cursorType == "battlepet" and petID then
        -- Play drop sound immediately
        if dragFeedback then
          dragFeedback:playDropSound()
        end
        
        if teamSection.dragSourceSlot then
          -- Swap: get pet from target slot
          local targetPetID = C_PetJournal.GetPetLoadOutInfo(self.slotIndex)
          C_PetJournal.SetPetLoadOutInfo(self.slotIndex, petID)
          if targetPetID then
            C_PetJournal.SetPetLoadOutInfo(teamSection.dragSourceSlot, targetPetID)
          else
            C_PetJournal.SetPetLoadOutInfo(teamSection.dragSourceSlot, nil)
          end
          
          -- Restore visuals on source slot
          if dragFeedback and detailPanel and detailPanel.teamSlots then
            local sourceCol = detailPanel.teamSlots[teamSection.dragSourceSlot]
            if sourceCol then
              dragFeedback:removeDragVisuals(sourceCol)
            end
          end
          
          teamSection.dragSourceSlot = nil
        else
          C_PetJournal.SetPetLoadOutInfo(self.slotIndex, petID)
        end
        
        ClearCursor()
        teamSection:hideDropTargets()
        teamSection:update()
        if Addon.events then
          Addon.events:emit("LOADOUT:CHANGED")
        end
      end
    end)
    
    -- Also handle OnMouseUp for click-to-drop fallback
    colFrame.dropTarget:SetScript("OnMouseUp", function(self, button)
      if button == "LeftButton" then
        local cursorType, petID = GetCursorInfo()
        if cursorType == "battlepet" and petID then
          if teamSection.dragSourceSlot then
            local targetPetID = C_PetJournal.GetPetLoadOutInfo(self.slotIndex)
            C_PetJournal.SetPetLoadOutInfo(self.slotIndex, petID)
            if targetPetID then
              C_PetJournal.SetPetLoadOutInfo(teamSection.dragSourceSlot, targetPetID)
            else
              C_PetJournal.SetPetLoadOutInfo(teamSection.dragSourceSlot, nil)
            end
            teamSection.dragSourceSlot = nil
          else
            C_PetJournal.SetPetLoadOutInfo(self.slotIndex, petID)
          end
          ClearCursor()
          teamSection:hideDropTargets()
          teamSection:update()
          if Addon.events then
            Addon.events:emit("LOADOUT:CHANGED")
          end
        end
      end
    end)
    
    -- Background
    colFrame.bg = colFrame:CreateTexture(nil, "BACKGROUND")
    colFrame.bg:SetAllPoints()
    colFrame.bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)
    
    -- Pet name (wrapping enabled, at top)
    colFrame.nameText = colFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colFrame.nameText:SetPoint("TOPLEFT", colFrame, "TOPLEFT", 4, -4)
    colFrame.nameText:SetPoint("TOPRIGHT", colFrame, "TOPRIGHT", -4, -4)
    colFrame.nameText:SetJustifyH("CENTER")
    colFrame.nameText:SetWordWrap(true)
    colFrame.nameText:SetMaxLines(2)
    
    -- Clickable button over name area
    colFrame.nameButton = CreateFrame("Button", nil, colFrame)
    colFrame.nameButton:SetPoint("TOPLEFT", colFrame, "TOPLEFT", 0, 0)
    colFrame.nameButton:SetPoint("TOPRIGHT", colFrame, "TOPRIGHT", 0, 0)
    colFrame.nameButton:SetHeight(40)
    colFrame.nameButton:RegisterForClicks("LeftButtonUp")
    
    -- Abilities container (horizontal row of 3 icons)
    colFrame.abilities = {}
    for abilitySlot = 1, 3 do
      local abilityFrame = CreateFrame("Button", nil, colFrame)
      abilityFrame:SetSize(40, 40)
      abilityFrame:SetFrameLevel(colFrame:GetFrameLevel() + 2)  -- Above drag handle
      abilityFrame.slotIndex = slotIndex
      abilityFrame.abilitySlot = abilitySlot
      
      -- Background
      abilityFrame.bg = abilityFrame:CreateTexture(nil, "BACKGROUND")
      abilityFrame.bg:SetAllPoints()
      abilityFrame.bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
      
      -- Icon
      abilityFrame.icon = abilityFrame:CreateTexture(nil, "ARTWORK")
      abilityFrame.icon:SetSize(40, 40)
      abilityFrame.icon:SetPoint("CENTER", abilityFrame, "CENTER", 0, 0)
      
      -- Choice indicator background pill (dark semi-transparent)
      abilityFrame.choiceBg = abilityFrame:CreateTexture(nil, "ARTWORK", nil, 1)
      abilityFrame.choiceBg:SetSize(14, 14)
      abilityFrame.choiceBg:SetPoint("TOPRIGHT", abilityFrame, "TOPRIGHT", -3, -3)
      abilityFrame.choiceBg:SetColorTexture(0, 0, 0, 0.5)
      
      -- Choice indicator (1 or 2) - top right with pill behind
      abilityFrame.choiceText = abilityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      abilityFrame.choiceText:SetPoint("CENTER", abilityFrame.choiceBg, "CENTER", 0, 0)
      abilityFrame.choiceText:SetTextColor(1, 1, 0.5)
      abilityFrame.choiceText:SetShadowOffset(1, -1)
      abilityFrame.choiceText:SetShadowColor(0, 0, 0, 1)
      
      -- Click to swap abilities (uses cached frame data)
      abilityFrame:SetScript("OnClick", function(self)
        if not self.tier1ID or not self.tier2ID or not self.abilityID then return end
        
        -- Toggle to the other ability
        local newAbilityID = (self.abilityID == self.tier1ID) and self.tier2ID or self.tier1ID
        
        C_PetJournal.SetAbility(self.slotIndex, self.abilitySlot, newAbilityID)
        
        -- Emit event - let event handler update display
        if Addon.events then
          Addon.events:emit("LOADOUT:CHANGED")
        end
        
        -- Refresh tooltip after data is updated (deferred to ensure update() completes)
        C_Timer.After(0, function()
          if self:IsMouseOver() and self:GetScript("OnEnter") then
            self:GetScript("OnEnter")(self)
          end
        end)
      end)
      
      -- Tooltip on hover (uses cached frame data)
      abilityFrame:SetScript("OnEnter", function(self)
        if not self.abilityID or not self.petID or not self.speciesID then return end
        
        if not Addon.abilityTooltips:show(self, {anchor = "right"}, self.abilityID, self.petID, self.speciesID) then
          return
        end
        
        -- Show swap hint if alternate exists
        if self.alternateID then
          local tip = Addon.tooltip
          local altName, altIcon = C_PetJournal.GetPetAbilityInfo(self.alternateID)
          
          tip:space(8)
          tip:separator()
          tip:space(8)
          
          tip:text("Click to swap to:", {color = {1, 1, 1}})
          
          local swapIcon = ""
          if altIcon then
            swapIcon = "|T" .. altIcon .. ":25:25|t "
          end
          tip:space(6)
          tip:text(swapIcon .. "|cffe0d0ff" .. (altName or "Unknown") .. "|r", {wrap = true})
          tip:done()
        else
          Addon.tooltip:done()
        end
      end)
      
      abilityFrame:SetScript("OnLeave", function()
        Addon.tooltip:hide()
      end)
      
      colFrame.abilities[abilitySlot] = abilityFrame
    end
    
    -- Health bar (4px tall normally, 8px when dead)
    colFrame.healthBar = CreateFrame("StatusBar", nil, colFrame)
    colFrame.healthBar:SetHeight(4)
    colFrame.healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    colFrame.healthBar:SetStatusBarColor(0, 1, 0, 1)
    
    colFrame.healthText = colFrame.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colFrame.healthText:SetPoint("CENTER", colFrame.healthBar, "CENTER", 0, 0)
    colFrame.healthText:SetTextColor(1, 1, 1)
    
    -- XP bar (6px tall for colored portion, 3px background)
    colFrame.xpBar = CreateFrame("StatusBar", nil, colFrame)
    colFrame.xpBar:SetHeight(6)
    colFrame.xpBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    colFrame.xpBar:SetStatusBarColor(0.8, 0.7, 1, 1)
    
    local xpBg = colFrame.xpBar:CreateTexture(nil, "BACKGROUND")
    xpBg:SetHeight(3)
    xpBg:SetPoint("LEFT")
    xpBg:SetPoint("RIGHT")
    xpBg:SetPoint("TOP", 0, -1.5)
    xpBg:SetColorTexture(0.4, 0.4, 0.4, 1)
    
    colFrame.xpText = colFrame.xpBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    colFrame.xpText:SetPoint("CENTER", colFrame.xpBar, "CENTER", 0, 0)
    colFrame.xpText:SetTextColor(1, 1, 1)
    
    -- Level text (positioned to left of XP bar)
    colFrame.levelText = colFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    colFrame.levelText:SetJustifyH("RIGHT")
    colFrame.levelText:SetTextColor(1, 1, 1)
    
    -- Pet model
    colFrame.model = CreateFrame("PlayerModel", nil, colFrame)
    colFrame.model:SetSize(1, 1)
    colFrame.model.slotIndex = slotIndex
    
    if colFrame.model.SetBackdrop then
      colFrame.model:SetBackdrop(nil)
    end
    if colFrame.model.SetBackdropColor then
      colFrame.model:SetBackdropColor(0, 0, 0, 0)
    end
    
    -- Camera configuration (called by rotation system, not OnShow)
    colFrame.model.ConfigureCamera = function(self)
      self:SetCamDistanceScale(1)
      -- Apply current facing from rotation state
      local state = slotRotationState[self.slotIndex]
      if state and state.currentFacing then
        self:SetFacing(state.currentFacing)
      end
    end
    
    -- Don't randomize on show - rotation system handles facing
    
    -- Family icon (bottom right corner)
    -- Right/bottom overflow and get clipped by SetClipsChildren
    colFrame.familyIcon = colFrame:CreateTexture(nil, "OVERLAY")
    colFrame.familyIcon:SetSize(96, 96)
    colFrame.familyIcon:SetPoint("BOTTOMRIGHT", colFrame, "BOTTOMRIGHT", 24, -24)
   -- colFrame.familyIcon:SetDesaturated(true)    leave as original
   -- colFrame.familyIcon:SetAlpha(0.4)           leave as original
    colFrame.familyIcon:Hide()
    
    -- Family coverage icons (bottom left corner) - show Damage Taken (defensive)
    -- Semantic arrows: green down = resists (takes -33%, good), red up = weak to (takes +50%, bad)
    -- Parent to detailPanel to avoid SetClipsChildren clipping
    local coverageIconSize = 22
    local arrowSize = 18
    local coverageSpacing = 2
    local coverageBottomOffset = 8
    local coverageLeftOffset = 4
    
    -- Container frame for unified tooltip behavior
    local containerHeight = (coverageIconSize * 2) + coverageSpacing
    local containerWidth = coverageIconSize + arrowSize + 2
    colFrame.coverageContainer = CreateFrame("Frame", nil, detailPanel)
    colFrame.coverageContainer:SetSize(containerWidth, containerHeight)
    colFrame.coverageContainer:SetPoint("BOTTOMLEFT", colFrame, "BOTTOMLEFT", coverageLeftOffset, coverageBottomOffset)
    colFrame.coverageContainer:SetFrameStrata("HIGH")
    colFrame.coverageContainer:SetFrameLevel(100)
    colFrame.coverageContainer:EnableMouse(true)
    
    colFrame.coverageContainer:SetScript("OnEnter", function(self)
      if self.petType and uiUtils then
        uiUtils:showFamilyMatchupTooltip(self.petType, self, {showClickHints = false})
      end
    end)
    colFrame.coverageContainer:SetScript("OnLeave", function()
      if Addon.tooltip then Addon.tooltip:hide() end
    end)
    
    colFrame.coverageContainer:Hide()
    
    -- Resist icon (top) - family this pet resists (takes -33%)
    colFrame.strongFrame = CreateFrame("Frame", nil, colFrame.coverageContainer)
    colFrame.strongFrame:SetSize(coverageIconSize + arrowSize + 2, coverageIconSize)
    colFrame.strongFrame:SetPoint("TOPLEFT", colFrame.coverageContainer, "TOPLEFT", 0, 0)
    colFrame.strongFrame:EnableMouse(false)  -- Container handles mouse
    
    colFrame.strongIcon = colFrame.strongFrame:CreateTexture(nil, "ARTWORK")
    colFrame.strongIcon:SetSize(coverageIconSize, coverageIconSize)
    colFrame.strongIcon:SetPoint("LEFT", colFrame.strongFrame, "LEFT", 0, 0)
    
    colFrame.strongArrow = colFrame.strongFrame:CreateTexture(nil, "ARTWORK")
    colFrame.strongArrow:SetSize(arrowSize, arrowSize)
    colFrame.strongArrow:SetPoint("LEFT", colFrame.strongIcon, "RIGHT", 0, 0)
    colFrame.strongArrow:SetTexture("Interface\\Buttons\\UI-MicroStream-Green")
    -- No rotation - points down by default (green down = takes less damage = good)
    colFrame.strongArrow:SetAlpha(0.4)
    
    colFrame.strongFrame:Hide()
    
    -- Weak against icon (bottom) - family that counters this pet (takes +50%)
    colFrame.weakFrame = CreateFrame("Frame", nil, colFrame.coverageContainer)
    colFrame.weakFrame:SetSize(coverageIconSize + arrowSize + 2, coverageIconSize)
    colFrame.weakFrame:SetPoint("BOTTOMLEFT", colFrame.coverageContainer, "BOTTOMLEFT", 0, 0)
    colFrame.weakFrame:EnableMouse(false)  -- Container handles mouse
    
    colFrame.weakIcon = colFrame.weakFrame:CreateTexture(nil, "ARTWORK")
    colFrame.weakIcon:SetSize(coverageIconSize, coverageIconSize)
    colFrame.weakIcon:SetPoint("LEFT", colFrame.weakFrame, "LEFT", 0, 0)
    
    colFrame.weakArrow = colFrame.weakFrame:CreateTexture(nil, "ARTWORK")
    colFrame.weakArrow:SetSize(arrowSize, arrowSize)
    colFrame.weakArrow:SetPoint("LEFT", colFrame.weakIcon, "RIGHT", 0, 0)
    colFrame.weakArrow:SetTexture("Interface\\Buttons\\UI-MicroStream-Red")
    colFrame.weakArrow:SetRotation(math.rad(180))  -- Point up (red up = takes more damage = bad)
    colFrame.weakArrow:SetAlpha(0.4)
    
    colFrame.weakFrame:Hide()
    
    detailPanel.teamSlots[slotIndex] = colFrame
  end
  
  -- Create rotation interpolation frame (once)
  if not rotationFrame then
    rotationFrame = CreateFrame("Frame")
    rotationFrame:Hide()
    
    rotationFrame:SetScript("OnUpdate", function(self, elapsed)
      if isResizing then
        -- Pause interpolation during resize
        return
      end
      
      local now = GetTime()
      local allComplete = true
      
      for slotIndex = 1, 3 do
        local state = slotRotationState[slotIndex]
        if state and state.startTime and state.targetFacing and state.duration then
          local progress = (now - state.startTime) / state.duration
          
          if progress >= 1 then
            -- Rotation complete
            state.currentFacing = state.targetFacing
            state.startTime = nil
          else
            -- Interpolate (ease-in-out)
            local easedProgress = progress < 0.5 
              and 2 * progress * progress 
              or 1 - ((-2 * progress + 2) ^ 2) / 2
            
            local startFacing = state.startFacing or 0
            state.currentFacing = startFacing + (state.targetFacing - startFacing) * easedProgress
            allComplete = false
          end
          
          -- Apply facing to model
          if detailPanel and detailPanel.teamSlots and detailPanel.teamSlots[slotIndex] then
            local model = detailPanel.teamSlots[slotIndex].model
            if model and model:IsVisible() then
              model:SetFacing(state.currentFacing)
            end
          end
        end
      end
      
      if allComplete then
        self:Hide()
      end
    end)
  end
end

--[[
  Generate Random Facing Angle
  Returns a random facing in radians within MAX_ROTATION_DEGREES.
  
  @return number - Facing angle in radians
]]
local function generateRandomFacing()
  return (math.random() - 0.5) * 2 * (MAX_ROTATION_DEGREES * math.pi / 180)
end

--[[
  Generate Random Rotation Duration
  Returns a random duration between ROTATION_DURATION_MIN and ROTATION_DURATION_MAX.
  
  @return number - Duration in seconds
]]
local function generateRandomDuration()
  return ROTATION_DURATION_MIN + math.random() * (ROTATION_DURATION_MAX - ROTATION_DURATION_MIN)
end

--[[
  Update Models After Resize
  Called after resize stops. Updates model displayIDs and starts rotation
  interpolation for pets that changed or need new angles.
]]
local function updateModelsAfterResize()
  if not detailPanel or not detailPanel.teamSlots then return end
  
  isResizing = false
  local needsAnimation = false
  
  for slotIndex = 1, 3 do
    local colFrame = detailPanel.teamSlots[slotIndex]
    if not colFrame then break end
    
    local petID = C_PetJournal.GetPetLoadOutInfo(slotIndex)
    local state = slotRotationState[slotIndex] or {}
    slotRotationState[slotIndex] = state
    
    if petID then
      local _, _, _, _, _, displayID = C_PetJournal.GetPetInfoByPetID(petID)
      
      -- Check if pet changed
      local petChanged = (state.petID ~= petID)
      
      if petChanged then
        -- New pet - set displayID and generate new random facing
        state.petID = petID
        state.currentFacing = state.currentFacing or 0  -- Start from current or 0
        state.startFacing = state.currentFacing
        state.targetFacing = generateRandomFacing()
        state.startTime = GetTime()
        state.duration = generateRandomDuration()
        needsAnimation = true
        
        if displayID and displayID > 0 then
          colFrame.model:SetDisplayInfo(displayID)
        end
      else
        -- Same pet - generate new target angle, smooth turn from current
        state.startFacing = state.currentFacing or 0
        state.targetFacing = generateRandomFacing()
        state.startTime = GetTime()
        state.duration = generateRandomDuration()
        needsAnimation = true
      end
      
      -- Apply current facing immediately
      if state.currentFacing then
        colFrame.model:SetFacing(state.currentFacing)
      end
    else
      -- No pet in slot
      state.petID = nil
      state.currentFacing = nil
      state.targetFacing = nil
      state.startTime = nil
      state.duration = nil
    end
  end
  
  -- Start animation if needed
  if needsAnimation and rotationFrame then
    rotationFrame:Show()
  end
end

--[[
  Update Models Immediately
  Called for non-resize updates (heal, loadout change). Updates displayIDs
  and generates new facing angles with smooth interpolation.
]]
local function updateModelsImmediate()
  if not detailPanel or not detailPanel.teamSlots then return end
  
  local needsAnimation = false
  
  for slotIndex = 1, 3 do
    local colFrame = detailPanel.teamSlots[slotIndex]
    if not colFrame then break end
    
    local petID = C_PetJournal.GetPetLoadOutInfo(slotIndex)
    local state = slotRotationState[slotIndex] or {}
    slotRotationState[slotIndex] = state
    
    if petID then
      local _, _, _, _, _, displayID = C_PetJournal.GetPetInfoByPetID(petID)
      
      -- Check if pet changed
      local petChanged = (state.petID ~= petID)
      
      if petChanged then
        -- New pet - update displayID and start rotation
        state.petID = petID
        state.startFacing = state.currentFacing or 0
        state.targetFacing = generateRandomFacing()
        state.startTime = GetTime()
        state.duration = generateRandomDuration()
        needsAnimation = true
        
        if displayID and displayID > 0 then
          colFrame.model:SetDisplayInfo(displayID)
        end
      end
      -- Same pet - keep current facing, no animation needed
      
      -- Apply current facing
      if state.currentFacing then
        colFrame.model:SetFacing(state.currentFacing)
      elseif not petChanged then
        -- First time seeing this pet, set initial facing without animation
        state.currentFacing = generateRandomFacing()
        state.petID = petID
        colFrame.model:SetFacing(state.currentFacing)
      end
    else
      -- No pet in slot
      state.petID = nil
      state.currentFacing = nil
      state.targetFacing = nil
      state.startTime = nil
      state.duration = nil
    end
  end
  
  -- Start animation if needed
  if needsAnimation and rotationFrame then
    rotationFrame:Show()
  end
end

--[[
  Update Team Display
  Refreshes all 3 team slot columns with current pet data.
  Positions elements, updates health/XP bars, sets up ability click handlers.
  
  @param width number|nil - Panel width from parent (top-down sizing)
  @param isResizeUpdate boolean|nil - True if called during resize (defers model updates)
]]
--[[
  Calculate column widths for team display
  Uses distributeWidth utility for proper remainder distribution
  
  @param panelWidth number - Total panel width
  @return table - Array of column widths [1]=width1, [2]=width2, [3]=width3
]]
local function calculateColumnWidths(panelWidth)
  local sidePadding = LAYOUT.ICON_LEFT
  local actionBarWidth = LAYOUT.ACTION_BAR_WIDTH
  local rightPadding = LAYOUT.ICON_LEFT
  local availableWidth = panelWidth - sidePadding - rightPadding - actionBarWidth
  local totalGapWidth = LAYOUT.COLUMN_SPACING * 2
  
  return uiUtils:distributeWidth(availableWidth, 3, totalGapWidth)
end

function teamSection:update(width, isResizeUpdate)
  if not detailPanel or not detailPanel.teamHeader then return end
  
  -- Store width for later use
  if width then
    detailPanel.panelWidth = width
  end
  
  -- Handle resize: defer model updates until resize stops
  if isResizeUpdate then
    isResizing = true
    
    -- Cancel any pending timer
    if resizeTimer then
      resizeTimer:Cancel()
    end
    
    -- Start new timer for deferred model update
    resizeTimer = C_Timer.NewTimer(RESIZE_IDLE_DELAY, function()
      resizeTimer = nil
      updateModelsAfterResize()
    end)
  end
  
  
  -- Position "Current Team:" label at top of team section
  -- teamBg position is owned by petDetails (parent)
  detailPanel.teamHeader:ClearAllPoints()
  detailPanel.teamHeader:SetPoint("TOPLEFT", detailPanel.teamBg, "TOPLEFT", LAYOUT.ICON_LEFT, -4)
  detailPanel.teamHeader:Show()
  
  -- Calculate column dimensions
  local panelWidth = detailPanel.panelWidth or 500
  local colWidths = calculateColumnWidths(panelWidth)
  
  -- Update each team slot column
  local colXOffset = 0
  for slotIndex = 1, 3 do
    local colFrame = detailPanel.teamSlots[slotIndex]
    if not colFrame then break end
    
    local petID, activeAbility1, activeAbility2, activeAbility3, locked = C_PetJournal.GetPetLoadOutInfo(slotIndex)
    local colWidth = colWidths[slotIndex]
    
    if petID then
      local speciesID, customName, level, xp, maxXp, displayID, isFavorite, petName, petIcon, 
            petType, creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable = 
            C_PetJournal.GetPetInfoByPetID(petID)
      
      local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
      -- rarity is 1-based from API (1=Poor, 2=Common, 3=Uncommon, 4=Rare)
      rarity = rarity or 2  -- Default to Common
      
      -- Position column - anchor to top and bottom to fill available space
      local bottomPadding = LAYOUT.BOTTOM_PADDING
      colFrame:SetWidth(colWidth)
      colFrame:ClearAllPoints()
      -- Anchor to teamHeader bottom with padding for visual separation
      colFrame:SetPoint("TOPLEFT", detailPanel.teamHeader, "BOTTOMLEFT", colXOffset, -LAYOUT.TEAM_HEADER_GAP)
      -- Bottom anchor to panel (not teamBg - avoids anchor family issues)
      colFrame:SetPoint("BOTTOMLEFT", detailPanel, "BOTTOMLEFT", LAYOUT.ICON_LEFT + colXOffset, bottomPadding)
      
      -- Update pet name with breed
      local displayName = customName or petName or "Unknown"
      local breedName = ""
      if Addon.breedDetection then
        local breedID, confidence, detectedBreedName = Addon.breedDetection:detectBreedByPetID(petID)
        if detectedBreedName then
          breedName = detectedBreedName
        end
      end
      
      -- Get rarity color from constants (1-based)
      local rarityColor = constants.RARITY_COLORS[rarity] or constants.RARITY_COLORS[2]
      local colorCode = string.format("|cff%02x%02x%02x", 
        math.floor(rarityColor.r * 255), 
        math.floor(rarityColor.g * 255), 
        math.floor(rarityColor.b * 255))
      
      local nameWithBreed = displayName
      if breedName ~= "" then
        local formattedBreed = breedName
        if colWidth < 200 then
          formattedBreed = string.gsub(breedName, "/", "")
        end
        nameWithBreed = displayName .. " (" .. formattedBreed .. ")"
      end
      colFrame.nameText:SetText(string.format("%s%s|r", colorCode, nameWithBreed))
      
      -- Fixed positioning values
      local healthBarTopOffset = LAYOUT.HEALTH_BAR_TOP_OFFSET
      local healthToNameGap = LAYOUT.HEALTH_TO_NAME_GAP
      local nameAreaHeight = LAYOUT.NAME_AREA_HEIGHT
      local nameToAbilityGap = LAYOUT.NAME_TO_ABILITY_GAP
      local abilityToXpGap = LAYOUT.ABILITY_TO_XP_GAP
      
      local isDead = (health and health <= 0)
      
      -- Set column background color
      if isDead then
        colFrame.bg:SetColorTexture(0.3, 0.1, 0.1, 0.95)
      else
        colFrame.bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)
      end
      
      -- Health bar is always 4px, but RED and full when dead
      local healthBarHeight = 4
      
      -- Position health bar (same position whether alive or dead)
      colFrame.healthBar:ClearAllPoints()
      colFrame.healthBar:SetHeight(healthBarHeight)
      colFrame.healthBar:SetPoint("TOPLEFT", colFrame, "TOPLEFT", 4, -healthBarTopOffset)
      colFrame.healthBar:SetPoint("TOPRIGHT", colFrame, "TOPRIGHT", -4, -healthBarTopOffset)
      
      -- Update health bar
      if health and maxHealth then
        colFrame.healthBar:SetMinMaxValues(0, maxHealth)
        if isDead then
          colFrame.healthBar:SetStatusBarColor(1, 0, 0, 1)
          colFrame.healthBar:SetValue(maxHealth)
          colFrame.healthText:SetText("0%")
        else
          colFrame.healthBar:SetStatusBarColor(0, 1, 0, 1)
          colFrame.healthBar:SetValue(health)
          local healthPercent = math.floor((health / maxHealth) * 100)
          -- Hide health text when at full health (100%)
          if healthPercent >= 100 then
            colFrame.healthText:SetText("")
          else
            colFrame.healthText:SetText(healthPercent .. "%")
          end
        end
      end
      colFrame.healthBar:Show()
      
      -- Position name
      local nameYOffset = -(healthBarTopOffset + healthBarHeight + healthToNameGap)
      colFrame.nameText:ClearAllPoints()
      colFrame.nameText:SetPoint("TOPLEFT", colFrame, "TOPLEFT", 4, nameYOffset)
      colFrame.nameText:SetPoint("TOPRIGHT", colFrame, "TOPRIGHT", -4, nameYOffset)
      
      -- Get abilities
      local abilities = C_PetJournal.GetPetAbilityList(speciesID)
      local abilityYOffset = nameYOffset - nameAreaHeight - nameToAbilityGap
      
      if abilities and #abilities >= 6 then
        local activeAbilityIDs = {activeAbility1, activeAbility2, activeAbility3}
        local totalAbilitiesWidth = 40 * 3 + 4 * 2
        local abilityStartX = (colWidth - totalAbilitiesWidth) / 2
        
        for abilitySlot = 1, 3 do
          local abilityFrame = colFrame.abilities[abilitySlot]
          if abilityFrame then
            local xOffset = abilityStartX + (abilitySlot - 1) * 44
            abilityFrame:ClearAllPoints()
            abilityFrame:SetPoint("TOPLEFT", colFrame, "TOPLEFT", xOffset, abilityYOffset)
            
            -- Get ability pair for this slot
            local tier1ID = abilities[abilitySlot]
            local tier2ID = abilities[abilitySlot + 3]
            local activeAbilityID = activeAbilityIDs[abilitySlot]
            
            -- Determine which tier is active
            local activeChoiceIndex = (activeAbilityID == tier2ID) and 2 or 1
            
            if activeAbilityID then
              local name, icon = C_PetJournal.GetPetAbilityInfo(activeAbilityID)
              abilityFrame.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
              abilityFrame.choiceText:SetText(tostring(activeChoiceIndex))
              
              -- Cache all data needed by scripts (set once in create())
              abilityFrame.abilityID = activeAbilityID
              abilityFrame.petID = petID
              abilityFrame.speciesID = speciesID
              abilityFrame.tier1ID = tier1ID
              abilityFrame.tier2ID = tier2ID
              abilityFrame.alternateID = (activeAbilityID == tier1ID) and tier2ID or tier1ID
              
              abilityFrame:Show()
            else
              abilityFrame:Hide()
            end
          end
        end
      end
      
      -- Position level and XP bar
      local levelXpYOffset = abilityYOffset - 40 - abilityToXpGap
      
      if level and level < 25 then
        colFrame.levelText:SetText(level)
        colFrame.levelText:ClearAllPoints()
        colFrame.levelText:SetPoint("TOPLEFT", colFrame, "TOPLEFT", 4, levelXpYOffset)
        colFrame.levelText:Show()
        
        if xp and maxXp then
          colFrame.xpBar:ClearAllPoints()
          colFrame.xpBar:SetPoint("LEFT", colFrame.levelText, "RIGHT", 4, 0)
          colFrame.xpBar:SetPoint("RIGHT", colFrame, "RIGHT", -4, 0)
          colFrame.xpBar:SetMinMaxValues(0, maxXp)
          colFrame.xpBar:SetValue(xp)
          local xpPercent = math.floor((xp / maxXp) * 100)
          colFrame.xpText:SetText(xpPercent .. "%")
          colFrame.xpBar:Show()
        else
          colFrame.xpBar:Hide()
        end
      else
        colFrame.levelText:Hide()
        colFrame.xpBar:Hide()
      end
      
      -- Position model at bottom of slot
      local modelHeight = 143
      local modelWidth = colWidth - 8
      local modelBottomPadding = 4
      
      colFrame.model:ClearAllPoints()
      colFrame.model:SetSize(modelWidth, modelHeight)
      colFrame.model:SetPoint("BOTTOM", colFrame, "BOTTOM", 0, modelBottomPadding)
      
      -- Set displayID if not resizing (resize defers to updateModelsAfterResize)
      if not isResizing then
        local state = slotRotationState[slotIndex] or {}
        slotRotationState[slotIndex] = state
        
        if displayID and displayID > 0 then
          -- Check if pet changed
          local petChanged = (state.petID ~= petID)
          
          colFrame.model:SetDisplayInfo(displayID)
          
          if petChanged then
            -- New pet - start rotation animation
            state.petID = petID
            state.startFacing = state.currentFacing or 0
            state.targetFacing = generateRandomFacing()
            state.startTime = GetTime()
            state.duration = generateRandomDuration()
            state.currentFacing = state.startFacing
            
            if rotationFrame then
              rotationFrame:Show()
            end
          elseif not state.currentFacing then
            -- First time seeing this pet, set initial facing
            state.currentFacing = generateRandomFacing()
            state.petID = petID
          end
          
          -- Apply current facing
          if state.currentFacing then
            colFrame.model:SetFacing(state.currentFacing)
          end
        else
          colFrame.model:SetDisplayInfo(0)
        end
      else
        -- During resize, just set displayID without changing facing
        if displayID and displayID > 0 then
          colFrame.model:SetDisplayInfo(displayID)
          -- Preserve current facing if we have it
          local state = slotRotationState[slotIndex]
          if state and state.currentFacing then
            colFrame.model:SetFacing(state.currentFacing)
          end
        else
          colFrame.model:SetDisplayInfo(0)
        end
      end
      
      colFrame.model:EnableMouse(true)
      
      -- Update family icon
      if petType and uiUtils and uiUtils.setFamilyIcon then
        if uiUtils:setFamilyIcon(colFrame.familyIcon, petType, "faded-color") then
          colFrame.familyIcon:Show()
        else
          colFrame.familyIcon:Hide()
        end
      else
        colFrame.familyIcon:Hide()
      end
      
      -- Update family coverage icons (Damage Taken - defensive)
      -- Semantic arrows: green down = resists (takes -33%, good), red up = weak to (takes +50%, bad)
      local familyUtils = Addon.familyUtils
      
      if petType and familyUtils and uiUtils and constants and constants.FAMILY_ICON_PATHS then
        -- Get family IDs for defensive matchups (Damage Taken)
        local resistsType = familyUtils:getResistantToFamily(petType)
        local weakAgainstType = familyUtils:getWeakAgainstFamily(petType)
        
        local showContainer = false
        
        -- Show resist icon with green down-arrow (takes -33%, good)
        if resistsType and colFrame.strongFrame then
          if uiUtils:setFamilyIcon(colFrame.strongIcon, resistsType, "strong") then
            colFrame.strongIcon:Show()
            colFrame.strongArrow:Show()
            colFrame.strongFrame:Show()
            showContainer = true
          else
            colFrame.strongFrame:Hide()
          end
        elseif colFrame.strongFrame then
          colFrame.strongFrame:Hide()
        end
        
        -- Show weak against icon with red up-arrow (takes +50%, bad)
        if weakAgainstType and colFrame.weakFrame then
          if uiUtils:setFamilyIcon(colFrame.weakIcon, weakAgainstType, "strong") then
            colFrame.weakIcon:Show()
            colFrame.weakArrow:Show()
            colFrame.weakFrame:Show()
            showContainer = true
          else
            colFrame.weakFrame:Hide()
          end
        elseif colFrame.weakFrame then
          colFrame.weakFrame:Hide()
        end
        
        -- Show/hide container and store petType for tooltip
        if showContainer and colFrame.coverageContainer then
          colFrame.coverageContainer.petType = petType
          colFrame.coverageContainer:Show()
        elseif colFrame.coverageContainer then
          colFrame.coverageContainer:Hide()
        end
      else
        if colFrame.strongFrame then colFrame.strongFrame:Hide() end
        if colFrame.weakFrame then colFrame.weakFrame:Hide() end
        if colFrame.coverageContainer then colFrame.coverageContainer:Hide() end
      end
      
      -- Position drop target to cover abilities and model area
      colFrame.dropTarget:ClearAllPoints()
      colFrame.dropTarget:SetPoint("TOPLEFT", colFrame, "TOPLEFT", 4, abilityYOffset + 5)
      colFrame.dropTarget:SetPoint("BOTTOMRIGHT", colFrame, "BOTTOMRIGHT", -4, modelBottomPadding)
      
      -- Position drag handle to same area as drop target
      colFrame.dragHandle:ClearAllPoints()
      colFrame.dragHandle:SetPoint("TOPLEFT", colFrame, "TOPLEFT", 4, abilityYOffset + 5)
      colFrame.dragHandle:SetPoint("BOTTOMRIGHT", colFrame, "BOTTOMRIGHT", -4, modelBottomPadding)
      
      -- Drag handle OnDragStart
      colFrame.dragHandle:SetScript("OnDragStart", function(self)
        if petID then
          teamSection.dragSourceSlot = slotIndex
          C_PetJournal.PickupPet(petID)
          teamSection:showDropTargets(slotIndex)
          
          -- Apply drag visuals to source slot
          if dragFeedback and colFrame then
            dragFeedback:applyDragVisuals(colFrame, 0.5)
          end
        end
      end)
      
      -- Model click handler
      colFrame.model:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
          local familyName = _G["BATTLE_PET_NAME_"..petType] or "Unknown"
          
          local petData = {
            petID = petID,
            speciesID = speciesID,
            icon = petIcon,
            name = customName or petName,
            level = level,
            rarity = rarity,
            petType = petType,
            familyName = familyName,
            tradable = tradable,
            unique = unique,
            owned = true,
            description = description,
            sourceText = sourceText
          }
          
          if Addon.breedDetection then
            local breedID, confidence, detectedBreedName = Addon.breedDetection:detectBreedByPetID(petID)
            if detectedBreedName then
              petData.breedText = detectedBreedName
            end
          end
          
          if petDetails then
            petDetails:showPetDetail(petData)
          end
        end
      end)
      
      -- Name button click handler
      colFrame.nameButton:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
          local familyName = _G["BATTLE_PET_NAME_"..petType] or "Unknown"
          
          local petData = {
            petID = petID,
            speciesID = speciesID,
            icon = petIcon,
            name = customName or petName,
            level = level,
            rarity = rarity,
            petType = petType,
            familyName = familyName,
            tradable = tradable,
            unique = unique,
            owned = true,
            description = description,
            sourceText = sourceText
          }
          
          if Addon.breedDetection then
            local breedID, confidence, detectedBreedName = Addon.breedDetection:detectBreedByPetID(petID)
            if detectedBreedName then
              petData.breedText = detectedBreedName
            end
          end
          
          if petDetails then
            petDetails:showPetDetail(petData)
          end
        end
      end)
      
      -- Height is determined by anchoring to top and bottom
      
      colFrame:Show()
    else
      -- Hide coverage icons explicitly for empty slots
      if colFrame.strongFrame then colFrame.strongFrame:Hide() end
      if colFrame.weakFrame then colFrame.weakFrame:Hide() end
      colFrame:Hide()
    end
    
    -- Advance X offset for next column (width + spacing)
    colXOffset = colXOffset + colWidth + LAYOUT.COLUMN_SPACING
  end
  
  -- Position team background to fill remaining space
  -- teamBg position is owned by petDetails (parent owns vertical division)
  -- teamSection only positions content within teamBg bounds
  
  -- Add divider line between detail and team sections (in the gap)
  if detailPanel.detailBg and not detailPanel.teamDivider then
    local sectionGap = constants.LAYOUT and constants.LAYOUT.SECTION_GAP or 12
    detailPanel.teamDivider = detailPanel:CreateTexture(nil, "BORDER")
    detailPanel.teamDivider:SetHeight(2)
    detailPanel.teamDivider:SetPoint("TOPLEFT", detailPanel.detailBg, "BOTTOMLEFT", 0, -math.floor(sectionGap / 2))
    detailPanel.teamDivider:SetPoint("TOPRIGHT", detailPanel.detailBg, "BOTTOMRIGHT", 0, -math.floor(sectionGap / 2))
    detailPanel.teamDivider:SetColorTexture(0.2, 0.2, 0.2, 1)
  end
  
  -- Position team action bar on right side with proper padding
  if detailPanel.teamActionBar and detailPanel.teamBg then
    local LAYOUT = constants.LAYOUT or {}
    local rightPadding = LAYOUT.ICON_LEFT or 12  -- Same as left padding
    
    detailPanel.teamActionBar:ClearAllPoints()
    detailPanel.teamActionBar:SetPoint("TOPRIGHT", detailPanel.teamBg, "TOPRIGHT", -rightPadding, -8)
    detailPanel.teamActionBar:SetPoint("BOTTOMRIGHT", detailPanel.teamBg, "BOTTOMRIGHT", -rightPadding, 8)
  end
end

--[[
  Refresh Health After Heal
  Updates health bars to 100% without querying API.
  Called when we know pets were healed (PET_JOURNAL_PETS_HEALED event).
]]
function teamSection:refreshHealthAfterHeal()
  if not detailPanel or not detailPanel.teamSlots then 
    return 
  end
  
  for slotIndex = 1, 3 do
    local colFrame = detailPanel.teamSlots[slotIndex]
    if colFrame and colFrame:IsVisible() and colFrame.healthBar then
      -- Get maxHealth from current bar settings
      local _, maxHealth = colFrame.healthBar:GetMinMaxValues()
      
      if maxHealth and maxHealth > 0 then
        -- Set to full health
        colFrame.healthBar:SetValue(maxHealth)
        colFrame.healthBar:SetStatusBarColor(0, 1, 0, 1)  -- Green
        colFrame.healthText:SetText("")  -- Hide at full health
        
        -- Reset background to normal (not dead)
        colFrame.bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)
      end
    end
  end
end

--[[
  Show Drop Targets
  Makes drop target overlays visible for drag-and-drop operations.
  
  @param sourceSlot number|nil - Source slot index to exclude (for reordering)
]]
function teamSection:showDropTargets(sourceSlot)
  if not detailPanel or not detailPanel.teamSlots then 
    return 
  end
  
  -- Track that this is the initial drag (first mouse release)
  teamSection.isInitialDragRelease = true
  
  -- Enable ESC handler using shared module (handles frame setup and UISpecialFrames automatically)
  if teamSection.escapeHandler then
    teamSection.escapeHandler:show()
  end
  
  for i = 1, 3 do
    local colFrame = detailPanel.teamSlots[i]
    if colFrame and colFrame.dropTarget then
      -- Ensure dropTarget has size (covers full column if not set by update())
      local w, h = colFrame.dropTarget:GetSize()
      if not w or w == 0 or not h or h == 0 then
        -- Fallback sizing to cover full column
        colFrame.dropTarget:SetAllPoints(colFrame)
      end
      
      if sourceSlot and i == sourceSlot then
        colFrame.dropTarget:Hide()
        colFrame.dropTarget:EnableMouse(false)
        colFrame.dropTarget.bg:SetVertexColor(0, 0, 0, 0)
      else
        local petID = C_PetJournal.GetPetLoadOutInfo(i)
        if petID then
          local health, maxHealth, power, speed, rarityFromStats = C_PetJournal.GetPetStats(petID)
          local rarity = math.max(0, (rarityFromStats or 1) - 1)
          local color = ITEM_QUALITY_COLORS[rarity]
          if color then
            colFrame.dropTarget.baseColor = {r = color.r, g = color.g, b = color.b, a = 0.4}
            colFrame.dropTarget.bg:SetVertexColor(color.r, color.g, color.b, 0.4)
          else
            colFrame.dropTarget.baseColor = {r = 0.5, g = 0.5, b = 0.5, a = 0.4}
            colFrame.dropTarget.bg:SetVertexColor(0.5, 0.5, 0.5, 0.4)
          end
        else
          colFrame.dropTarget.baseColor = {r = 0.5, g = 0.5, b = 0.5, a = 0.4}
          colFrame.dropTarget.bg:SetVertexColor(0.5, 0.5, 0.5, 0.4)
        end
        
        colFrame.dropTarget:SetFrameStrata("FULLSCREEN_DIALOG")
        colFrame.dropTarget:SetFrameLevel(100)
        colFrame.dropTarget:Show()
        colFrame.dropTarget:EnableMouse(true)
      end
    end
  end
end

--[[
  Hide Drop Targets
  Conceals drop target overlays and restores normal state.
]]
function teamSection:hideDropTargets()
  if not detailPanel or not detailPanel.teamSlots then return end
  
  teamSection.dragSourceSlot = nil
  teamSection.isInitialDragRelease = nil
  
  -- Disable ESC handler using shared module (handles frame cleanup and UISpecialFrames automatically)
  if teamSection.escapeHandler then
    teamSection.escapeHandler:hide()
  end
  
  for i = 1, 3 do
    local colFrame = detailPanel.teamSlots[i]
    if colFrame and colFrame.dropTarget then
      colFrame.dropTarget:Hide()
      colFrame.dropTarget:EnableMouse(false)
      colFrame.dropTarget:SetFrameStrata("MEDIUM")
      
      -- Restore drag visuals in case drag was cancelled
      if dragFeedback then
        dragFeedback:removeDragVisuals(colFrame)
      end
    end
  end
end

--[[
  Set Escape Handler
  Stores reference to escape key handler frame for drag operations.
  
  @param handler frame - Escape handler frame
]]
function teamSection:setEscapeHandler(handler)
  teamSection.escapeHandler = handler
end

--[[
  Handle Resize
  Called when panel is resized. Defers model rotation updates until resize stops.
  
  @param width number - Panel width from parent
]]
function teamSection:onResize(width)
  self:update(width, true)  -- isResizeUpdate = true
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("teamSection", {"constants", "petUtils", "uiUtils", "tooltip", "abilityTooltips", "abilityUtils", "breedDetection"}, function()
    return true
  end)
end

-- Export for petDetails to reference (internal use only)
Addon.teamSection = teamSection

return teamSection