--[[
  ui/levelingQueue/ghostCard.lua
  Ghost Card Creator for Drag Operations
  
  Creates visual ghost copy of queue card that follows cursor during drag.
  Replicates essential visual elements (priority badge, name, summary, count).
  
  Dependencies: None (standalone utility)
  Exports: Addon.levelingQueueGhostCard
]]

local ADDON_NAME, Addon = ...

local ghostCard = {}

-- Layout constants (from parent)
local LAYOUT = {
    CARD_PADDING = 10,
    PRIORITY_SIZE = 24,
}

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

local function copyBackdrop(ghost, sourceCard)
    ghost:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    
    local r, g, b, a = sourceCard:GetBackdropColor()
    ghost:SetBackdropColor(r, g, b, a)
    ghost:SetBackdropBorderColor(0.3, 0.3, 0.35, 1)
end

local function copyPriorityBadge(ghost, sourceCard)
    if not sourceCard.priorityBadge then return nil end
    
    local ghostPriorityBadge = CreateFrame("Frame", nil, ghost, "BackdropTemplate")
    ghostPriorityBadge:SetSize(LAYOUT.PRIORITY_SIZE, LAYOUT.PRIORITY_SIZE)
    ghostPriorityBadge:SetPoint("LEFT", ghost, "LEFT", LAYOUT.CARD_PADDING, 0)
    ghostPriorityBadge:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    
    local pr, pg, pb, pa = sourceCard.priorityBadge:GetBackdropColor()
    ghostPriorityBadge:SetBackdropColor(pr, pg, pb, pa)
    ghostPriorityBadge:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    local priorityText = ghostPriorityBadge:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    priorityText:SetPoint("CENTER")
    priorityText:SetTextColor(1, 1, 1)
    priorityText:SetText(sourceCard.priorityBadge.text:GetText())
    
    return ghostPriorityBadge
end

local function copyNameAndSummary(ghost, sourceCard, ghostPriorityBadge)
    if not sourceCard.nameText or not ghostPriorityBadge then return end
    
    local nameText = ghost:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", ghostPriorityBadge, "TOPRIGHT", 10, -2)
    nameText:SetPoint("RIGHT", ghost, "RIGHT", -180, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    nameText:SetText(sourceCard.nameText:GetText())
    
    if sourceCard.summaryText then
        local summaryText = ghost:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        summaryText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -2)
        summaryText:SetPoint("RIGHT", ghost, "RIGHT", -180, 0)
        summaryText:SetJustifyH("LEFT")
        summaryText:SetTextColor(0.6, 0.6, 0.6)
        summaryText:SetWordWrap(false)
        summaryText:SetText(sourceCard.summaryText:GetText())
    end
end

local function copyCountBadge(ghost, sourceCard)
    if not sourceCard.countBadge then return end
    
    local countBadge = ghost:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countBadge:SetPoint("RIGHT", ghost, "RIGHT", -LAYOUT.CARD_PADDING, 0)
    countBadge:SetTextColor(1, 1, 1)
    countBadge:SetText(sourceCard.countBadge:GetText())
end

local function setupCursorFollow(ghost)
    ghost:SetScript("OnUpdate", function(self)
        local scale = UIParent:GetEffectiveScale()
        local x, y = GetCursorPosition()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    end)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Create ghost card that follows cursor
  
  @param sourceCard frame - Source queue card to copy
  @return frame - Ghost card frame
]]
function ghostCard:create(sourceCard)
    if not sourceCard then return nil end
    
    local ghost = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    ghost:SetFrameStrata("TOOLTIP")
    ghost:SetSize(sourceCard:GetWidth(), sourceCard:GetHeight())
    ghost:SetAlpha(0.7)
    
    copyBackdrop(ghost, sourceCard)
    local ghostPriorityBadge = copyPriorityBadge(ghost, sourceCard)
    copyNameAndSummary(ghost, sourceCard, ghostPriorityBadge)
    copyCountBadge(ghost, sourceCard)
    setupCursorFollow(ghost)
    
    ghost:Show()
    return ghost
end

--[[
  Destroy ghost card
  
  @param ghost frame - Ghost card to destroy
]]
function ghostCard:destroy(ghost)
    if not ghost then return end
    ghost:Hide()
    ghost:SetScript("OnUpdate", nil)
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("levelingQueueGhostCard", {}, function()
        return true
    end)
end

Addon.levelingQueueGhostCard = ghostCard
return ghostCard
