--[[
  ui/levelingQueue/cardUpdate.lua
  Queue Card Update Logic
  
  Handles updating queue card visual state based on queue data:
  - Edit mode vs normal mode switching
  - Card positioning and height
  - Populate form fields and display elements
  - Apply dimming and color states
  
  Dependencies: levelingLogic, levelingDefaults, levelingQueueEditForm
  Exports: Addon.levelingQueueCardUpdate
]]

local ADDON_NAME, Addon = ...

local cardUpdate = {}

-- Module references
local levelingLogic, levelingDefaults, levelingQueueEditForm

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function updateCardEditMode(card, queue, index, layout)
    local wasAlreadyEditing = card.editForm:IsShown()
    
    card:SetHeight(layout.EDIT_HEIGHT)
    card.editForm:Show()
    card.editBtn:Hide()
    
    card.nameText:Hide()
    card.summaryText:Hide()
    card.countBadge:Hide()
    card.priorityBadge:Hide()
    
    -- UICheckButtonTemplate includes multiple textures (border, highlight, etc)
    -- that may not all hide with :Hide() alone. SetAlpha(0) ensures complete invisibility.
    card.toggle:Hide()
    card.toggle:SetAlpha(0)
    
    card:SetAlpha(1)
    card:SetBackdropColor(unpack(layout.CARD_BG_EDITING))
    
    -- Only populate fields when entering edit mode, not on refresh
    if not wasAlreadyEditing then
        card.nameInput:SetText(queue.name or "")
        card.filterInput:SetText(queue.filter or "")
        
        card.sortField = queue.sortField or levelingDefaults.DEFAULT_SORT_FIELD
        card.sortDir = queue.sortDir or levelingDefaults.DEFAULT_SORT_DIR
        
        if card.sortControl and card.sortControl.SetValue then
            card.sortControl:SetValue(card.sortField, card.sortDir, true)
        end
    end
end

local function updateCardNormalMode(card, queue, index, isDisabled, editingQueueId, layout)
    card:SetHeight(layout.CARD_HEIGHT)
    card.editForm:Hide()
    card.editBtn:Show()
    card.editBtn:Enable()
    
    card.nameText:Show()
    card.summaryText:Show()
    card.countBadge:Show()
    card.priorityBadge:Show()
    
    card.toggle:Show()
    card.toggle:SetAlpha(1)
    
    if editingQueueId then
        card:SetAlpha(layout.CARD_DIM_ALPHA)
    elseif isDisabled then
        card:SetAlpha(0.6)
    else
        card:SetAlpha(1)
    end
    
    if isDisabled and not editingQueueId then
        card:SetBackdropColor(unpack(layout.CARD_BG_DISABLED))
    else
        card:SetBackdropColor(unpack(layout.CARD_BG))
    end
    
    card.priorityBadge.text:SetText(tostring(index))
    if queue.enabled then
        card.priorityBadge:SetBackdropColor(unpack(layout.PRIORITY_ACTIVE))
    else
        card.priorityBadge:SetBackdropColor(unpack(layout.PRIORITY_INACTIVE))
    end
    
    card.nameText:SetText(queue.name or "Unnamed Queue")
    
    local summary = queue.filter or "(all pets)"
    if summary == "" then summary = "(all pets)" end
    local sortInfo = levelingDefaults.SORT_BY_ID[queue.sortField]
    local sortName = sortInfo and sortInfo.text or (queue.sortField or "Level")
    local dirIndicator = (queue.sortDir == "desc") and " (desc)" or ""
    summary = summary .. " - " .. sortName .. dirIndicator
    card.summaryText:SetText(summary)
    
    local count = levelingLogic:getQueueCount(queue.id)
    card.countBadge:SetText(tostring(count))
    
    card.toggle:SetChecked(queue.enabled)
end

local function updateCardPosition(card, index, editingQueueId, layout)
    local yOff = -(index - 1) * (layout.CARD_HEIGHT + layout.CARD_GAP)
    
    if editingQueueId then
        for i = 1, index - 1 do
            local q = levelingLogic:getQueues()[i]
            if q and q.id == editingQueueId then
                yOff = yOff - (layout.EDIT_HEIGHT - layout.CARD_HEIGHT)
                break
            end
        end
    end
    
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", card:GetParent(), "TOPLEFT", 0, yOff)
    card:SetPoint("TOPRIGHT", card:GetParent(), "TOPRIGHT", 0, yOff)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Update queue card visual state
  
  @param card frame - Queue card frame to update
  @param queue table - Queue data
  @param index number - Display position (1-based)
  @param editingQueueId string|nil - Currently editing queue ID (if any)
  @param layout table - Layout constants
]]
function cardUpdate:update(card, queue, index, editingQueueId, layout)
    card.queueId = queue.id
    card.displayIndex = index
    
    if card.setDragIndex then
        card:setDragIndex(index)
    end
    
    local isEditing = (editingQueueId == queue.id)
    local isDisabled = not queue.enabled
    
    if isEditing then
        updateCardEditMode(card, queue, index, layout)
    else
        updateCardNormalMode(card, queue, index, isDisabled, editingQueueId, layout)
    end
    
    updateCardPosition(card, index, editingQueueId, layout)
    card:Show()
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function cardUpdate:initialize()
    levelingLogic = Addon.levelingLogic
    levelingDefaults = Addon.levelingDefaults
    levelingQueueEditForm = Addon.levelingQueueEditForm
    
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("levelingQueueCardUpdate", {
        "levelingLogic", "levelingDefaults", "levelingQueueEditForm"
    }, function()
        return cardUpdate:initialize()
    end)
end

Addon.levelingQueueCardUpdate = cardUpdate
return cardUpdate