--[[
  ui/levelingQueue/levelingQueue.lua
  Leveling Queue List Panel
  
  Left panel showing queue cards with:
    - Priority badge
    - Name and filter summary
    - Pet count
    - Enable/disable toggle
    - Edit button
    - Inline edit form (expands card)
  
  Visual language matches achievementList (60px rows, proper padding).
  
  Dependencies: utils, events, constants, levelingLogic, levelingDefaults, levelingQueueEditForm,
                ghostCard, autoScroll, levelingDragHandler, cardUpdate
  Exports: Addon.levelingQueue
]]

local ADDON_NAME, Addon = ...

local levelingQueue = {}

-- Module references
local utils, events, constants, levelingLogic, levelingDefaults, levelingFilterHelp
local textBox, escapeHandler, levelingQueueEditForm
local ghostCard, autoScroll, levelingDragHandler, cardUpdate
local contextMenu

-- Layout references (resolved during initialize)
local L = nil  -- levelingDefaults.LAYOUT
local C = nil  -- constants.LAYOUT

-- UI state
local parentFrame = nil
local scrollFrame = nil
local scrollChild = nil
local queueCards = {}
local editingQueueId = nil

-- Drag state
local dragState = {
    sourceQueueId = nil,
    sourceCard = nil,
    ghostCard = nil,
    escapeHandler = nil,
    inClickToDropMode = false,
    scrollFrame = nil,  -- Reference for autoScroll
}

-- Forward declarations
local performReorder, resetCardsAfterDrag

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function setupHoverBehavior(widget, card)
    widget:SetScript("OnEnter", function()
        if not dragState.sourceQueueId and not editingQueueId and card.hoverBg then
            card.hoverBg:Show()
        end
    end)
    widget:SetScript("OnLeave", function()
        if not dragState.sourceQueueId and card.hoverBg and not card:IsMouseOver() then
            card.hoverBg:Hide()
        end
    end)
end

local function getEditingQueueId()
    return editingQueueId
end

-- ============================================================================
-- QUEUE CARD CREATION
-- ============================================================================

local function createQueueCard(index)
    local card = CreateFrame("Frame", nil, scrollChild, "BackdropTemplate")
    card:SetHeight(L.CARD_HEIGHT)
    card:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    card:SetBackdropColor(unpack(L.CARD_BG))
    card:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
    
    local hoverBg = card:CreateTexture(nil, "BACKGROUND", nil, 1)
    hoverBg:SetAllPoints()
    hoverBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    hoverBg:SetVertexColor(1, 1, 1, L.HOVER_ALPHA)
    hoverBg:Hide()
    card.hoverBg = hoverBg
    
    -- Priority badge
    local priorityBadge = CreateFrame("Frame", nil, card, "BackdropTemplate")
    priorityBadge:SetSize(L.PRIORITY_SIZE, L.PRIORITY_SIZE)
    priorityBadge:SetPoint("LEFT", card, "LEFT", L.CARD_PADDING, 0)
    priorityBadge:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    priorityBadge:SetBackdropColor(unpack(L.PRIORITY_INACTIVE))
    priorityBadge:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    priorityBadge:EnableMouse(true)
    
    local priorityText = priorityBadge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    priorityText:SetPoint("CENTER")
    priorityText:SetTextColor(1, 1, 1)
    priorityBadge.text = priorityText
    card.priorityBadge = priorityBadge
    
    setupHoverBehavior(priorityBadge, card)
    
    -- Queue name
    local nameText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", priorityBadge, "TOPRIGHT", 10, -2)
    nameText:SetPoint("RIGHT", card, "RIGHT", -180, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    card.nameText = nameText
    
    -- Filter summary
    local summaryText = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    summaryText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
    summaryText:SetPoint("RIGHT", card, "RIGHT", -180, 0)
    summaryText:SetJustifyH("LEFT")
    summaryText:SetTextColor(0.6, 0.6, 0.6)
    summaryText:SetWordWrap(false)
    card.summaryText = summaryText
    
    -- Pet count badge
    local countBadge = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countBadge:SetPoint("RIGHT", card, "RIGHT", -L.CARD_PADDING - L.BUTTON_WIDTH - L.TOGGLE_SIZE - 24, 0)
    countBadge:SetWidth(L.COUNT_WIDTH)
    countBadge:SetJustifyH("RIGHT")
    countBadge:SetTextColor(0.7, 0.7, 0.7)
    card.countBadge = countBadge
    
    -- Enable/disable toggle
    local toggle = CreateFrame("CheckButton", nil, card, "UICheckButtonTemplate")
    toggle:SetSize(L.TOGGLE_SIZE, L.TOGGLE_SIZE)
    toggle:SetPoint("RIGHT", card, "RIGHT", -L.CARD_PADDING - L.BUTTON_WIDTH - 8, 0)
    toggle:SetScript("OnClick", function(self)
        local queueId = card.queueId
        if queueId and levelingLogic then
            levelingLogic:setQueueEnabled(queueId, self:GetChecked())
        end
    end)
    card.toggle = toggle
    
    setupHoverBehavior(toggle, card)
    
    -- Edit button
    local editBtn = CreateFrame("Button", nil, card, "UIPanelButtonTemplate")
    editBtn:SetSize(L.BUTTON_WIDTH, L.BUTTON_HEIGHT)
    editBtn:SetPoint("RIGHT", card, "RIGHT", -L.CARD_PADDING, 0)
    editBtn:SetText("Edit")
    editBtn:SetScript("OnClick", function()
        if card.queueId then
            levelingQueue:startEditing(card.queueId)
        end
    end)
    card.editBtn = editBtn
    
    setupHoverBehavior(editBtn, card)
    
    -- Edit form container
    local editFormContainer = CreateFrame("Frame", nil, card)
    editFormContainer:SetPoint("TOPLEFT", card, "TOPLEFT", L.CARD_PADDING, -L.CARD_PADDING)
    editFormContainer:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -L.CARD_PADDING, L.CARD_PADDING)
    editFormContainer:Hide()
    card.editForm = editFormContainer
    
    if levelingQueueEditForm then
        levelingQueueEditForm:create(card, editFormContainer)
    end
    
    if levelingDragHandler then
        levelingDragHandler:setupCard(card, dragState, scrollChild, L, getEditingQueueId, function()
            levelingQueue:refresh()
        end)
    end
    
    -- Context menu on right-click
    card:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and not editingQueueId then
            levelingQueue:showContextMenu(self)
        end
    end)
    
    return card
end

-- ============================================================================
-- DRAG AND DROP
-- ============================================================================

performReorder = function(sourceQueueId)
    if not levelingDragHandler then return false end
    return levelingDragHandler:performReorder(sourceQueueId, dragState, function()
        levelingQueue:refresh()
    end)
end

resetCardsAfterDrag = function()
    if not levelingDragHandler then return end
    levelingDragHandler:resetCards(dragState, queueCards, scrollChild, L)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function levelingQueue:createContent(parent)
    parentFrame = parent
    
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", C.INNER_PADDING, -C.INNER_PADDING)
    header:SetText("Queues")
    header:SetTextColor(1, 0.82, 0)
    
    local hint = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("LEFT", header, "RIGHT", 8, 0)
    hint:SetText("drag to reorder")
    hint:SetTextColor(0.5, 0.5, 0.5)
    
    local newBtn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    newBtn:SetSize(68, 22)
    newBtn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -C.INNER_PADDING, -C.INNER_PADDING + 2)
    newBtn:SetText("New...")
    newBtn:SetScript("OnClick", function()
        levelingQueue:addNewQueue()
    end)
    
    scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", C.INNER_PADDING, -C.INNER_PADDING - 28)
    scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.INNER_PADDING - 22, C.INNER_PADDING)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local step = L.CARD_HEIGHT + L.CARD_GAP
        local newScroll = current - (delta * step)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)
    
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    
    dragState.scrollFrame = scrollFrame
end

function levelingQueue:refresh()
    if not scrollChild then return end
    
    local queues = levelingLogic:getQueues()
    
    -- ScrollChild width must be set explicitly after scrollFrame is sized.
    -- During initial creation, GetWidth() may return nil or 0 before layout pass.
    local frameWidth = scrollFrame:GetWidth()
    if frameWidth and frameWidth > 0 then
        scrollChild:SetWidth(frameWidth)
    end
    
    for i, queue in ipairs(queues) do
        local card = queueCards[i]
        if not card then
            card = createQueueCard(i)
            queueCards[i] = card
        end
        if cardUpdate then
            cardUpdate:update(card, queue, i, editingQueueId, L)
        end
    end
    
    for i = #queues + 1, #queueCards do
        queueCards[i]:Hide()
    end
    
    local totalHeight = 0
    for i, queue in ipairs(queues) do
        if queue.id == editingQueueId then
            totalHeight = totalHeight + L.EDIT_HEIGHT + L.CARD_GAP
        else
            totalHeight = totalHeight + L.CARD_HEIGHT + L.CARD_GAP
        end
    end
    scrollChild:SetHeight(math.max(totalHeight, 10))
end

function levelingQueue:startEditing(queueId)
    editingQueueId = queueId
    self:refresh()
    
    if scrollFrame and queueId then
        local queues = levelingLogic:getQueues()
        local cardIndex = nil
        for i, q in ipairs(queues) do
            if q.id == queueId then
                cardIndex = i
                break
            end
        end
        
        if cardIndex then
            local yOff = (cardIndex - 1) * (L.CARD_HEIGHT + L.CARD_GAP)
            local cardBottom = yOff + L.EDIT_HEIGHT
            
            local viewHeight = scrollFrame:GetHeight()
            local currentScroll = scrollFrame:GetVerticalScroll()
            
            if yOff < currentScroll then
                scrollFrame:SetVerticalScroll(yOff)
            elseif cardBottom > currentScroll + viewHeight then
                scrollFrame:SetVerticalScroll(cardBottom - viewHeight)
            end
        end
    end
    
    if Addon.levelingTab and Addon.levelingTab.setEditingQueue then
        Addon.levelingTab:setEditingQueue(queueId)
    end
end

function levelingQueue:triggerEditPreviewRefresh(card)
    if not card or not Addon.levelingPreview then return end
    
    local tempQueue = {
        id = card.queueId,
        name = card.nameInput and card.nameInput:GetText() or "Temp",
        filter = card.filterInput and card.filterInput:GetText() or "",
        sortField = card.sortField or levelingDefaults.DEFAULT_SORT_FIELD,
        sortDir = card.sortDir or levelingDefaults.DEFAULT_SORT_DIR,
        enabled = true,
    }
    
    Addon.levelingPreview:refreshEditWithQueue(tempQueue)
end

function levelingQueue:saveEditing(queueId)
    if not queueId then return end
    
    local card = nil
    for _, c in ipairs(queueCards) do
        if c.queueId == queueId then
            card = c
            break
        end
    end
    
    if not card then return end
    
    local updates = {
        name = card.nameInput:GetText(),
        filter = card.filterInput:GetText(),
        sortField = card.sortField or levelingDefaults.DEFAULT_SORT_FIELD,
        sortDir = card.sortDir or levelingDefaults.DEFAULT_SORT_DIR,
    }
    
    levelingLogic:updateQueue(queueId, updates)
    
    editingQueueId = nil
    self:refresh()
    
    if Addon.levelingTab and Addon.levelingTab.setEditingQueue then
        Addon.levelingTab:setEditingQueue(nil)
    end
end

function levelingQueue:cancelEditing()
    editingQueueId = nil
    self:refresh()
    
    if Addon.levelingTab and Addon.levelingTab.setEditingQueue then
        Addon.levelingTab:setEditingQueue(nil)
    end
end

function levelingQueue:deleteQueue(queueId)
    if not queueId then return end
    
    StaticPopupDialogs["PAO_DELETE_QUEUE"] = {
        text = "Delete this queue?",
        button1 = "Delete",
        button2 = "Cancel",
        OnAccept = function()
            levelingLogic:deleteQueue(queueId)
            if editingQueueId == queueId then
                editingQueueId = nil
            end
            levelingQueue:refresh()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }
    StaticPopup_Show("PAO_DELETE_QUEUE")
end

function levelingQueue:duplicateQueue(queueId)
    if not queueId then return end
    levelingLogic:duplicateQueue(queueId)
    self:refresh()
end

function levelingQueue:addNewQueue()
    local newQueue = levelingLogic:addQueue({
        name = "New Queue",
        filter = "",
        sortField = levelingDefaults.DEFAULT_SORT_FIELD,
        sortDir = levelingDefaults.DEFAULT_SORT_DIR,
        enabled = true,
    })
    
    if newQueue then
        self:startEditing(newQueue.id)
    end
end

function levelingQueue:moveQueueUp(queueId)
    if not queueId then return end
    local queues = levelingLogic:getQueues()
    local currentIndex = nil
    
    for i, q in ipairs(queues) do
        if q.id == queueId then
            currentIndex = i
            break
        end
    end
    
    if not currentIndex or currentIndex == 1 then return end
    
    -- Swap priorities
    local temp = queues[currentIndex - 1].priority
    queues[currentIndex - 1].priority = queues[currentIndex].priority
    queues[currentIndex].priority = temp
    
    levelingLogic:sortQueues()
    levelingLogic:save()
    self:refresh()
end

function levelingQueue:moveQueueDown(queueId)
    if not queueId then return end
    local queues = levelingLogic:getQueues()
    local currentIndex = nil
    
    for i, q in ipairs(queues) do
        if q.id == queueId then
            currentIndex = i
            break
        end
    end
    
    if not currentIndex or currentIndex == #queues then return end
    
    -- Swap priorities
    local temp = queues[currentIndex + 1].priority
    queues[currentIndex + 1].priority = queues[currentIndex].priority
    queues[currentIndex].priority = temp
    
    levelingLogic:sortQueues()
    levelingLogic:save()
    self:refresh()
end

function levelingQueue:showContextMenu(card)
    if not contextMenu or not card or not card.queueId then return end
    
    local queues = levelingLogic:getQueues()
    local displayIndex = card.displayIndex or 1
    
    contextMenu:show("cursor", {
        items = {
            {
                text = "Edit",
                func = function(ctx)
                    levelingQueue:startEditing(ctx.queueId)
                end
            },
            { separator = true },
            {
                text = "Delete",
                func = function(ctx)
                    levelingQueue:deleteQueue(ctx.queueId)
                end
            },
            {
                text = "Duplicate",
                func = function(ctx)
                    levelingQueue:duplicateQueue(ctx.queueId)
                end
            },
            { separator = true },
            {
                text = "Move Up",
                disabled = function(ctx)
                    return ctx.displayIndex == 1
                end,
                func = function(ctx)
                    levelingQueue:moveQueueUp(ctx.queueId)
                end
            },
            {
                text = "Move Down",
                disabled = function(ctx)
                    local queues = levelingLogic:getQueues()
                    return ctx.displayIndex == #queues
                end,
                func = function(ctx)
                    levelingQueue:moveQueueDown(ctx.queueId)
                end
            }
        }
    }, {
        queueId = card.queueId,
        displayIndex = displayIndex
    })
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function levelingQueue:initialize()
    utils = Addon.utils
    events = Addon.events
    constants = Addon.constants
    levelingLogic = Addon.levelingLogic
    levelingDefaults = Addon.levelingDefaults
    levelingFilterHelp = Addon.levelingFilterHelp
    textBox = Addon.textBox
    escapeHandler = Addon.escapeHandler
    levelingQueueEditForm = Addon.levelingQueueEditForm
    contextMenu = Addon.contextMenu
    
    -- Resolve layout references
    L = levelingDefaults and levelingDefaults.LAYOUT
    C = constants and constants.LAYOUT
    
    ghostCard = Addon.levelingQueueGhostCard
    autoScroll = Addon.levelingQueueAutoScroll
    levelingDragHandler = Addon.levelingDragHandler
    cardUpdate = Addon.levelingQueueCardUpdate
    
    if escapeHandler then
        dragState.escapeHandler = escapeHandler:create({
            onCancel = function()
                resetCardsAfterDrag()
            end,
            onRelease = function()
                if performReorder(dragState.sourceQueueId) then
                    resetCardsAfterDrag()
                else
                    dragState.inClickToDropMode = true
                end
            end,
            onClick = function(button)
                if button == "LeftButton" then
                    performReorder(dragState.sourceQueueId)
                end
                resetCardsAfterDrag()
            end
        })
    end
    
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("levelingQueue", {
        "utils", "events", "constants", "levelingLogic", "levelingDefaults", 
        "textBox", "escapeHandler", "levelingQueueEditForm", "contextMenu",
        "levelingQueueGhostCard", "levelingQueueAutoScroll", "levelingDragHandler", "levelingQueueCardUpdate"
    }, function()
        return levelingQueue:initialize()
    end)
end

Addon.levelingQueue = levelingQueue
return levelingQueue