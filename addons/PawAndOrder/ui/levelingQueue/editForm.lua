--[[
  ui/levelingQueue/editForm.lua
  Queue Edit Form Component
  
  Handles inline edit form that expands within a queue card:
    - Name input
    - Filter text with clear and info buttons
    - Sort control with direction toggle
    - Action buttons (Save, Cancel, Delete, Duplicate)
  
  Dependencies: textBox, filterTextbox, sortControl, actionButton, levelingLogic, levelingDefaults, levelingFilterHelp
  Exports: Addon.levelingQueueEditForm
]]

local ADDON_NAME, Addon = ...

local editForm = {}

-- Module references
local textBox, filterTextbox, sortControl, actionButton
local levelingLogic, levelingDefaults, levelingFilterHelp

-- Layout reference (resolved during initialize)
local L = nil  -- levelingDefaults.LAYOUT

-- Label alignment (left-justify to widest label: "Filter:")
local LABEL_OFFSET = 52  -- Space for label text + gap before input

-- ============================================================================
-- NAME SECTION
-- ============================================================================

local function createNameSection(editFormFrame, card)
    local yOff = 0
    local labelHeight = 12  -- Approximate GameFontNormalSmall height
    
    -- Name label (left-justified to LABEL_OFFSET)
    local nameLabel = editFormFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("TOPLEFT", editFormFrame, "TOPLEFT", 0, yOff - ((L.INPUT_HEIGHT - labelHeight) / 2))
    nameLabel:SetText("Name:")
    nameLabel:SetTextColor(0.7, 0.7, 0.7)
    
    -- Name input (starts at LABEL_OFFSET)
    local nameInput = textBox:create({
        parent = editFormFrame,
        width = 1,
        maxLetters = 50,
        placeholder = "Queue name...",
    })
    nameInput:SetHeight(L.INPUT_HEIGHT)
    nameInput:SetPoint("TOPLEFT", editFormFrame, "TOPLEFT", LABEL_OFFSET, yOff)
    nameInput:SetPoint("TOPRIGHT", editFormFrame, "TOPRIGHT", 0, yOff)
    card.nameInput = nameInput
    
    return yOff - L.INPUT_HEIGHT - L.INPUT_GAP
end

-- ============================================================================
-- FILTER SECTION
-- ============================================================================

local function createFilterSection(editFormFrame, card, yOff)
    local labelHeight = 12
    
    -- Filter label (left-justified to LABEL_OFFSET)
    local filterLabel = editFormFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterLabel:SetPoint("TOPLEFT", editFormFrame, "TOPLEFT", 0, yOff - ((L.INPUT_HEIGHT - labelHeight) / 2))
    filterLabel:SetText("Filter:")
    filterLabel:SetTextColor(0.7, 0.7, 0.7)
    
    -- Filter input with clear and info buttons (starts at LABEL_OFFSET)
    local filterInput = filterTextbox:create({
        parent = editFormFrame,
        width = 1,
        maxLetters = 200,
        placeholder = "e.g. rare flying level:1-24",
        onTextChanged = function(text, userInput)
            if userInput and Addon.levelingQueue then
                Addon.levelingQueue:triggerEditPreviewRefresh(card)
            end
        end,
        onClear = function()
            if Addon.levelingQueue then
                Addon.levelingQueue:triggerEditPreviewRefresh(card)
            end
        end,
        onInfoTipClick = function()
            if levelingFilterHelp then
                levelingFilterHelp:toggle()
            end
        end,
    })
    filterInput:SetHeight(L.INPUT_HEIGHT)
    filterInput:SetPoint("TOPLEFT", editFormFrame, "TOPLEFT", LABEL_OFFSET, yOff)
    filterInput:SetPoint("TOPRIGHT", editFormFrame, "TOPRIGHT", 0, yOff)
    card.filterInput = filterInput
    
    return yOff - L.INPUT_HEIGHT - L.INPUT_GAP
end

-- ============================================================================
-- SORT SECTION
-- ============================================================================

local function createSortSection(editFormFrame, card, yOff)
    local labelHeight = 12
    
    -- Sort label (left-justified to LABEL_OFFSET)
    local sortLabel = editFormFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sortLabel:SetPoint("TOPLEFT", editFormFrame, "TOPLEFT", 0, yOff - ((L.INPUT_HEIGHT - labelHeight) / 2))
    sortLabel:SetText("Sort:")
    sortLabel:SetTextColor(0.7, 0.7, 0.7)
    
    -- Sort control (starts at LABEL_OFFSET)
    if sortControl then
        local sortOptions = {}
        for _, sortInfo in ipairs(levelingDefaults.SORT_FIELDS) do
            table.insert(sortOptions, {
                value = sortInfo.id,
                text = sortInfo.text,
            })
        end
        
        local sortCtrl = sortControl:create({
            parent = editFormFrame,
            width = L.DROPDOWN_WIDTH,
            options = sortOptions,
            defaultField = card.sortField or levelingDefaults.DEFAULT_SORT_FIELD,
            defaultDir = card.sortDir or levelingDefaults.DEFAULT_SORT_DIR,
            onChange = function(field, dir)
                card.sortField = field
                card.sortDir = dir
                if Addon.levelingQueue then
                    Addon.levelingQueue:triggerEditPreviewRefresh(card)
                end
            end,
        })
        sortCtrl:SetPoint("TOPLEFT", editFormFrame, "TOPLEFT", LABEL_OFFSET, yOff)
        card.sortControl = sortCtrl
    end
    
    -- Return position after sort control
    return yOff - L.INPUT_HEIGHT - (L.INPUT_GAP * 1.5)
end

-- ============================================================================
-- ACTION BUTTONS
-- ============================================================================

local function createActionButtons(editFormFrame, card, yOff)
    -- Button row at fixed position
    local buttonYOff = -130
    
    local btnRow = CreateFrame("Frame", nil, editFormFrame)
    btnRow:SetHeight(L.BUTTON_HEIGHT)
    btnRow:SetPoint("TOPLEFT", editFormFrame, "TOPLEFT", 0, buttonYOff)
    btnRow:SetPoint("TOPRIGHT", editFormFrame, "TOPRIGHT", 0, buttonYOff)
    
    -- Delete button (leftmost)
    local deleteBtn = actionButton:create(btnRow, {
        text = "Delete",
        onClick = function()
            if Addon.levelingQueue then
                Addon.levelingQueue:deleteQueue(card.queueId)
            end
        end,
        size = "small",
        style = 1,
    })
    deleteBtn:SetPoint("LEFT", btnRow, "LEFT", 0, 0)
    card.deleteBtn = deleteBtn
    
    -- Duplicate button
    local dupeBtn = actionButton:create(btnRow, {
        text = "Duplicate",
        onClick = function()
            if Addon.levelingQueue then
                Addon.levelingQueue:duplicateQueue(card.queueId)
            end
        end,
        size = "small",
        style = 1,
    })
    dupeBtn:SetPoint("LEFT", deleteBtn, "RIGHT", 8, 0)
    card.dupeBtn = dupeBtn
    
    -- Cancel button (rightmost)
    local cancelBtn = actionButton:create(btnRow, {
        text = "Cancel",
        onClick = function()
            if Addon.levelingQueue then
                Addon.levelingQueue:cancelEditing()
            end
        end,
        size = "small",
        style = 1,
    })
    cancelBtn:SetPoint("RIGHT", btnRow, "RIGHT", 0, 0)
    card.cancelBtn = cancelBtn
    
    -- Save button (left of cancel)
    local saveBtn = actionButton:create(btnRow, {
        text = "Save",
        onClick = function()
            if Addon.levelingQueue then
                Addon.levelingQueue:saveEditing(card.queueId)
            end
        end,
        size = "small",
        style = 1,
    })
    saveBtn:SetPoint("RIGHT", cancelBtn, "LEFT", -8, 0)
    card.saveBtn = saveBtn
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function editForm:create(card, editFormFrame)
    local yOff = createNameSection(editFormFrame, card)
    yOff = createFilterSection(editFormFrame, card, yOff)
    yOff = createSortSection(editFormFrame, card, yOff)
    createActionButtons(editFormFrame, card, yOff)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function editForm:initialize()
    textBox = Addon.textBox
    filterTextbox = Addon.filterTextbox
    sortControl = Addon.sortControl
    actionButton = Addon.actionButton
    levelingLogic = Addon.levelingLogic
    levelingDefaults = Addon.levelingDefaults
    levelingFilterHelp = Addon.levelingFilterHelp
    
    -- Resolve layout reference
    L = levelingDefaults and levelingDefaults.LAYOUT
    
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("levelingQueueEditForm", {
        "textBox", "filterTextbox", "sortControl", "actionButton",
        "levelingLogic", "levelingDefaults", "levelingFilterHelp"
    }, function()
        return editForm:initialize()
    end)
end

Addon.levelingQueueEditForm = editForm
return editForm