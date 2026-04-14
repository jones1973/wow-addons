--[[
  ui/shared/slotPicker.lua
  Shared Battle Slot Picker Popup
  
  Provides a popup for selecting which battle slot to place a pet in.
  Shows current pet in each slot with icon and level.
  
  Used by:
  - levelingPreview (manual slot selection)
  - levelingCelebration (level 25 celebration auto-slot)
  
  Dependencies: None (standalone)
  Exports: Addon.slotPicker
]]

local ADDON_NAME, Addon = ...

local slotPicker = {}

-- UI elements
local popup = nil
local slotButtons = {}

-- Callback when slot selected
local onSlotSelected = nil

-- ============================================================================
-- POPUP CREATION
-- ============================================================================

local function createPopup()
    if popup then return end
    
    -- Main popup frame
    popup = CreateFrame("Frame", "PAOSlotPickerPopup", UIParent, "BackdropTemplate")
    popup:SetSize(500, 320)
    popup:SetPoint("CENTER")
    popup:SetFrameStrata("DIALOG")
    popup:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    popup:SetBackdropColor(0, 0, 0, 1)
    popup:Hide()
    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", function(self) self:StartMoving() end)
    popup:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -5, -5)
    
    -- Title
    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", popup, "TOP", 0, -16)
    title:SetText("Select Battle Slot")
    
    -- Instruction text
    local instruction = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instruction:SetPoint("TOP", title, "BOTTOM", 0, -8)
    instruction:SetText("Choose which slot to place this pet:")
    instruction:SetTextColor(0.8, 0.8, 0.8)
    
    -- Create 3 slot buttons
    local slotWidth = 140
    local slotHeight = 180
    local slotGap = 15
    local totalWidth = (slotWidth * 3) + (slotGap * 2)
    local startX = -(totalWidth / 2) + (slotWidth / 2)
    
    for slot = 1, 3 do
        -- Use UIPanelButtonTemplate for stylish red background
        local btn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
        btn:SetSize(slotWidth, slotHeight)
        btn:SetPoint("TOP", instruction, "BOTTOM", startX + ((slot - 1) * (slotWidth + slotGap)), -25)
        
        -- Slot number
        local slotNum = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        slotNum:SetPoint("TOP", btn, "TOP", 0, -8)
        slotNum:SetText("Slot " .. slot)
        btn.slotNum = slotNum
        
        -- Model scene for pet (larger for zoom effect)
        local modelSize = 110
        local modelScene = CreateFrame("ModelScene", nil, btn, "ModelSceneMixinTemplate")
        modelScene:SetSize(modelSize, modelSize)
        modelScene:SetPoint("TOP", slotNum, "BOTTOM", 0, -4)
        modelScene:EnableMouse(false)  -- Let button handle all mouse events
        btn.modelScene = modelScene
        
        -- Pet name (will show tooltip if truncated)
        local petName = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        petName:SetPoint("TOP", modelScene, "BOTTOM", 0, -4)
        petName:SetWidth(slotWidth - 10)
        petName:SetJustifyH("CENTER")
        petName:SetWordWrap(false)
        btn.petName = petName
        
        -- Pet level
        local level = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        level:SetPoint("TOP", petName, "BOTTOM", 0, -2)
        btn.level = level
        
        btn:SetScript("OnClick", function()
            if onSlotSelected then
                onSlotSelected(slot)
            end
            popup:Hide()
        end)
        
        slotButtons[slot] = btn
    end
    
    -- Cancel button
    local cancelBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    cancelBtn:SetSize(80, 22)
    cancelBtn:SetPoint("BOTTOM", popup, "BOTTOM", 0, 16)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        popup:Hide()
    end)
    
    -- ESC key closes popup
    popup:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            popup:Hide()
        end
    end)
end

-- ============================================================================
-- SLOT BUTTON UPDATE
-- ============================================================================

local function updateSlotButton(slot)
    if not slotButtons[slot] then return end
    
    local btn = slotButtons[slot]
    local petID = C_PetJournal.GetPetLoadOutInfo(slot)
    
    if petID then
        local speciesID, customName, level, _, _, displayID, _, petName = C_PetJournal.GetPetInfoByPetID(petID)
        
        -- Get breed info
        local breedText = ""
        if Addon.breedDetection then
            local breedID, confidence, detectedBreedName = Addon.breedDetection:detectBreedByPetID(petID)
            if detectedBreedName then
                breedText = " (" .. detectedBreedName .. ")"
            end
        end
        
        -- Update model
        if btn.modelScene and speciesID then
            if not displayID then
                local _, _, _, _, _, _, _, _, _, _, _, did = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
                displayID = did
            end
            
            if displayID and C_PetJournal.GetPetModelSceneInfoBySpeciesID then
                local sceneID = C_PetJournal.GetPetModelSceneInfoBySpeciesID(speciesID)
                if sceneID then
                    btn.modelScene:TransitionToModelSceneID(sceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_MAINTAIN, true)
                    local actor = btn.modelScene:GetActorByTag("unwrapped")
                    if actor then
                        actor:SetModelByCreatureDisplayID(displayID, true)
                        actor:SetAnimationBlendOperation(Enum.ModelBlendOperation.None)
                        actor:SetYaw(math.rad(math.random(-45, 45)))
                    end
                end
            end
        end
        
        -- Set pet name with breed
        local displayName = customName or petName or "Pet"
        local fullName = displayName .. breedText
        
        if btn.petName then
            btn.petName:SetText(fullName)
        end
        
        -- Store full name for tooltip
        btn.fullPetName = fullName
        
        -- Set level
        if btn.level and level then
            btn.level:SetText("Level " .. level)
            btn.level:SetTextColor(level == 25 and 1 or 0.7, level == 25 and 0.85 or 0.7, level == 25 and 0 or 0.7)
        else
            btn.level:SetText("")
        end
        
        -- Tooltip shows full name with breed
        btn:SetScript("OnEnter", function(self)
            if self.fullPetName then
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(self.fullPetName, 1, 1, 1)
                GameTooltip:Show()
            end
        end)
        
        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)
    else
        -- Empty slot
        if btn.petName then
            btn.petName:SetText("")
        end
        if btn.level then
            btn.level:SetText("|cff888888Empty|r")
        end
        
        btn.fullPetName = nil
        
        -- No tooltip for empty slots
        btn:SetScript("OnEnter", nil)
        btn:SetScript("OnLeave", nil)
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Show slot picker popup
  
  @param callback function - Called with (slotIndex) when slot selected
  @param targetPetID string - Optional. PetID being placed (for future use)
]]
function slotPicker:show(callback, targetPetID)
    if not popup then
        createPopup()
    end
    
    onSlotSelected = callback
    
    -- Update all slot buttons with current pets
    for slot = 1, 3 do
        updateSlotButton(slot)
    end
    
    popup:Show()
end

--[[
  Hide slot picker popup
]]
function slotPicker:hide()
    if popup then
        popup:Hide()
    end
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("slotPicker", {"breedDetection"}, function()
        return true
    end)
end

Addon.slotPicker = slotPicker
return slotPicker