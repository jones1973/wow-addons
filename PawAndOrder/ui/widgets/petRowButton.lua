--[[
  ui/petList/petRowButton.lua
  Pet Row Button Factory (Stateless)
  
  Creates and updates pet list row buttons. Stateless design allows
  multiple consumers (listingSection, levelingPreview, etc.)
  
  Responsibilities:
  - Create button frames with all child elements
  - Update button display from pet data
  - Handle hover, selection, and click events
  - Badge display (unique, duplicate, cageable)
  - Family icon with recent pet glow
  - Upgrade indicator for battle stones
  
  Usage:
    local btn = petRowButton:create(parent, height, callbacks)
    petRowButton:update(btn, petData, selectedPetID, matchContext)
    -- Caller handles positioning
  
  Dependencies: utils, constants, petUtils
  Exports: Addon.petRowButton
]]

local ADDON_NAME, Addon = ...

local petRowButton = {}

-- Module references (resolved at init)
local utils, constants, petUtils

-- Reusable tables (avoid allocation churn during refresh)
local badgeBuffer = {}              -- Reused for badge population
local battleStoneCache = {}         -- [petType-rarity] = stones result

-- ============================================================================
-- BUTTON CREATION
-- ============================================================================

--[[
  Create a pet button with all child elements
  
  @param parent frame - Parent frame for the button
  @param height number - Button height in pixels
  @param callbacks table|nil - Optional {onSelected, onContextMenu}
  @return frame - Button frame ready for use
]]
function petRowButton:create(parent, height, callbacks)
    if not parent then
        error("petRowButton:create requires parent frame")
    end
    
    height = height or (constants and constants.LIST_ENTRY_HEIGHT) or 40
    callbacks = callbacks or {}
    
    local btn = CreateFrame("Frame", nil, parent)
    btn:SetSize(parent:GetWidth(), height)
    btn:SetFrameLevel(parent:GetFrameLevel() + 1)
    btn:EnableMouse(true)
    
    -- Store height for later use
    btn.rowHeight = height
    
    -- Hover highlight (lighter than selection)
    btn.hoverBg = btn:CreateTexture(nil, "BACKGROUND")
    btn.hoverBg:SetAllPoints()
    btn.hoverBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.hoverBg:SetVertexColor(1, 1, 1, 0.08)
    btn.hoverBg:Hide()
    
    -- Upgrade highlight (green tint for upgradeable pets)
    btn.upgradeBg = btn:CreateTexture(nil, "BACKGROUND", nil, -1)
    btn.upgradeBg:SetAllPoints()
    btn.upgradeBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.upgradeBg:Hide()
    
    -- Selection highlight
    btn.selectedBg = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
    btn.selectedBg:SetAllPoints()
    btn.selectedBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.selectedBg:SetVertexColor(0.67, 0.51, 0.93, 0.25)  -- Lavender
    btn.selectedBg:Hide()
    
    -- Badge frame for status icons
    btn.badgeFrame = CreateFrame("Frame", nil, btn)
    btn.badgeFrame:SetSize(33, height)
    btn.badgeFrame:SetPoint("LEFT", btn, "LEFT", 0, 0)

    -- Icon comes after badge column
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetSize(height - 4, height - 4)
    btn.icon:SetPoint("LEFT", btn.badgeFrame, "RIGHT", 2, 0)
    
    -- Icon frame for tooltip capture (over the icon texture)
    btn.iconFrame = CreateFrame("Frame", nil, btn)
    btn.iconFrame:SetAllPoints(btn.icon)
    btn.iconFrame:EnableMouse(true)
    btn.iconFrame:SetScript("OnEnter", function(self)
        local rowBtn = self:GetParent()
        rowBtn.hoverBg:Show()
        
        local petData = rowBtn.petData
        if not petData then return end
        
        local petTooltips = Addon.petTooltips
        if petTooltips then
            petTooltips:show(self, petData.petID, petData.speciesID, {anchor = "left"})
        end
    end)
    btn.iconFrame:SetScript("OnLeave", function(self)
        local rowBtn = self:GetParent()
        rowBtn.hoverBg:Hide()
        if Addon.petTooltips then
            Addon.petTooltips:hide()
        end
    end)
    
    -- Enable dragging from icon frame
    btn.iconFrame:RegisterForDrag("LeftButton")
    btn.iconFrame:SetScript("OnDragStart", function(self)
        local rowBtn = self:GetParent()
        if rowBtn.petData and rowBtn.petData.owned and rowBtn.petData.petID then
            C_PetJournal.PickupPet(rowBtn.petData.petID)
            if Addon.petDetails and Addon.petDetails.showDropTargets then
                Addon.petDetails:showDropTargets()
            end
        end
    end)
    
    -- Badge icons (up to 2)
    btn.badgeIcons = {}
    for i = 1, 2 do
        local iconFrame = CreateFrame("Frame", nil, btn.badgeFrame)
        iconFrame:SetSize(14, 14)
        
        local icon = iconFrame:CreateTexture(nil, "OVERLAY")
        icon:SetSize(14, 14)
        icon:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
        iconFrame.icon = icon
        
        iconFrame:SetScript("OnEnter", function(self)
            -- Show row highlight
            local rowBtn = self:GetParent():GetParent()
            if rowBtn and rowBtn.hoverBg then
                rowBtn.hoverBg:Show()
            end
            -- Badge labels are short single words - GameTooltip auto-sizes to content
            if self.tooltipText then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(self.tooltipText, 1, 1, 1)
                GameTooltip:Show()
            end
        end)
        
        iconFrame:SetScript("OnLeave", function(self)
            -- Hide row highlight
            local rowBtn = self:GetParent():GetParent()
            if rowBtn and rowBtn.hoverBg then
                rowBtn.hoverBg:Hide()
            end
            GameTooltip:Hide()
        end)
        
        iconFrame:Hide()
        btn.badgeIcons[i] = iconFrame
    end
    
    -- Level background
    btn.levelBG = btn:CreateTexture(nil, "BACKGROUND")
    btn.levelBG:SetSize(20, 20)
    btn.levelBG:SetPoint("BOTTOMRIGHT", btn.icon, "BOTTOMRIGHT", -1, 1)
    btn.levelBG:SetColorTexture(0, 0, 0)
    btn.levelBG:SetAlpha(0.7)
    
    -- Level text
    btn.levelText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.levelText:SetPoint("BOTTOMRIGHT", btn.icon, "BOTTOMRIGHT", -3, 3)
    btn.levelText:SetTextColor(1, 1, 1)
    btn.levelText:SetShadowOffset(1, -1)
    
    -- Name text
    btn.nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.nameText:SetPoint("LEFT", btn.icon, "RIGHT", 4, 0)
    btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
    btn.nameText:SetJustifyH("LEFT")
    btn.nameText:SetWordWrap(true)
    btn.nameText:SetMaxLines(2)
    
    -- Family icon on right side
    btn.familyIcon = btn:CreateTexture(nil, "OVERLAY", nil, 2)
    btn.familyIcon:SetSize(30, 30)
    btn.familyIcon:SetPoint("RIGHT", btn, "RIGHT", -8, 0)
    btn.familyIcon:SetTexCoord(0.80, 0.92, 0.80, 0.92)
    btn.familyIcon:SetBlendMode("ADD")
    
    -- Glow texture for recent pets (behind family icon)
    btn.familyGlow = btn:CreateTexture(nil, "OVERLAY", nil, 1)
    btn.familyGlow:SetSize(36, 36)
    btn.familyGlow:SetPoint("CENTER", btn.familyIcon, "CENTER", 0, 0)
    btn.familyGlow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    btn.familyGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
    btn.familyGlow:SetVertexColor(1, 0.85, 0.4, 0.8)  -- Warm golden glow
    btn.familyGlow:SetBlendMode("ADD")
    btn.familyGlow:Hide()
    
    -- Frame over family icon for tooltip capture
    btn.familyFrame = CreateFrame("Frame", nil, btn)
    btn.familyFrame:SetAllPoints(btn.familyIcon)
    btn.familyFrame:EnableMouse(true)
    btn.familyFrame:SetScript("OnEnter", function(self)
        local rowBtn = self:GetParent()
        rowBtn.hoverBg:Show()
        
        -- Show acquisition tooltip if recent
        local petData = rowBtn.petData
        if petData and petData.petID then
            local petAcquisitions = Addon.petAcquisitions
            if petAcquisitions and petAcquisitions:isRecent(petData.petID) then
                local tip = Addon.tooltip
                local dateStr = petAcquisitions:getAcquiredDateFormatted(petData.petID)
                if tip and dateStr then
                    tip:show(self, {anchor = "TOPLEFT", relPoint = "BOTTOMLEFT", offsetY = -5})
                    tip:header("Recently Acquired")
                    tip:space(3)
                    tip:text("Acquired: " .. dateStr, {color = {0.7, 0.7, 0.7}})
                    tip:done()
                end
            end
        end
    end)
    btn.familyFrame:SetScript("OnLeave", function(self)
        local rowBtn = self:GetParent()
        rowBtn.hoverBg:Hide()
        if Addon.tooltip then
            Addon.tooltip:hide()
        end
    end)
    
    -- Main button hover
    btn:SetScript("OnEnter", function(self)
        self.hoverBg:Show()
    end)
    
    btn:SetScript("OnLeave", function(self)
        self.hoverBg:Hide()
    end)
    
    -- Click handling (uses callbacks passed at creation)
    btn:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" and self.petData and self.petData.owned then
            -- Show context menu (don't select - user just wants to act on it)
            if callbacks.onContextMenu then
                callbacks.onContextMenu(self, self.petData)
            end
        elseif button == "LeftButton" then
            -- Shift-click: insert pet link into chat
            if IsShiftKeyDown() and self.petData and self.petData.petID then
                local link = C_PetJournal.GetBattlePetLink(self.petData.petID)
                if link and ChatEdit_InsertLink(link) then
                    return  -- Link inserted, don't change selection
                end
            end
            
            if callbacks.onSelected and self.petData then
                callbacks.onSelected(self.petData, self.petData.petID, self.matchContext)
            end
        end
    end)
    
    -- Drag support for owned pets
    btn:RegisterForDrag("LeftButton")
    btn:SetScript("OnDragStart", function(self)
        if self.petData and self.petData.owned and self.petData.petID then
            C_PetJournal.PickupPet(self.petData.petID)
            if Addon.petDetails and Addon.petDetails.showDropTargets then
                Addon.petDetails:showDropTargets()
            end
        end
    end)
    
    return btn
end

-- ============================================================================
-- BUTTON UPDATE
-- ============================================================================

--[[
  Begin a new refresh cycle
  Clears per-refresh caches. Call before updating buttons in a batch.
]]
function petRowButton:beginRefresh()
    wipe(battleStoneCache)
end

--[[
  Update a pet button with pet data
  Does NOT handle positioning - caller is responsible for SetPoint.
  
  @param btn frame - Button to update
  @param petData table - Pet data
  @param selectedPetID string - Currently selected pet ID
  @param matchContext table - Filter match context (optional)
  @param opts table - Optional display options:
    - showBadges: boolean - Show badge column (default: true)
]]
function petRowButton:update(btn, petData, selectedPetID, matchContext, opts)
    if not petData then
        btn:Hide()
        return
    end
    
    opts = opts or {}
    local showBadges = opts.showBadges ~= false  -- Default true
    
    btn.petData = petData
    btn.matchContext = matchContext
    
    local isSelected = (selectedPetID == petData.petID)
    
    -- Hide all badges first
    for i = 1, 2 do
        btn.badgeIcons[i]:Hide()
        btn.badgeIcons[i].tooltipText = nil
    end
    
    -- Handle badge frame visibility and icon positioning
    if showBadges then
        btn.badgeFrame:Show()
        btn.badgeFrame:SetWidth(33)
        btn.icon:ClearAllPoints()
        btn.icon:SetPoint("LEFT", btn.badgeFrame, "RIGHT", 2, 0)
        
        -- Populate badge buffer then hand off to shared renderer
        wipe(badgeBuffer)

        -- Slot 1: unique or duplicate indicator
        if petData.unique then
            table.insert(badgeBuffer, {texture = "Interface\\AddOns\\PawAndOrder\\textures\\grey-diamond.png", tooltip = "Unique"})
        elseif petData.duplicateCount and petData.duplicateCount > 1 then
            table.insert(badgeBuffer, {texture = "Interface\\AddOns\\PawAndOrder\\textures\\grey-dot.png", tooltip = petData.duplicateCount .. " of this breed"})
        end

        -- Slot 2: cage (already caged) or cageable (tradable, not yet caged)
        if petData.isCaged then
            table.insert(badgeBuffer, {texture = "Interface\\AddOns\\PawAndOrder\\textures\\cage.png", tooltip = "Caged"})
        elseif petData.tradable then
            table.insert(badgeBuffer, {texture = "Interface\\AddOns\\PawAndOrder\\textures\\cage.png", tooltip = "Cageable"})
        end

        local uiUtils = Addon.uiUtils
        if uiUtils then
            uiUtils:renderBadges(btn.badgeIcons, btn.badgeFrame, badgeBuffer)
        end
    else
        -- Hide badge frame entirely and reposition icon
        btn.badgeFrame:Hide()
        btn.badgeFrame:SetWidth(0)
        btn.icon:ClearAllPoints()
        btn.icon:SetPoint("LEFT", btn, "LEFT", 2, 0)
    end
    
    -- Set pet info
    btn.icon:SetTexture(petData.icon)
    
    if petData.owned then
        btn.levelText:SetText(petData.level)
        btn.levelText:Show()
        btn.icon:SetDesaturated(false)
    else
        btn.levelText:SetText("")
        btn.levelText:Hide()
        btn.icon:SetDesaturated(true)
    end
    
    -- Family icon
    local uiUtils = Addon.uiUtils
    if petData.petType and petData.canBattle ~= false and uiUtils and uiUtils.setFamilyIcon then
        if uiUtils:setFamilyIcon(btn.familyIcon, petData.petType, "faded-color") then
            btn.familyIcon:SetSize(20, 25)
            
            -- Check if pet is recent and show glow
            local petAcquisitions = Addon.petAcquisitions
            local isRecent = petAcquisitions and petData.petID and petAcquisitions:isRecent(petData.petID)
            if isRecent then
                btn.familyIcon:SetAlpha(1.0)  -- Full alpha for recent
                btn.familyGlow:Show()
            else
                local saturation = Addon.options and Addon.options:Get("familyIconSaturation") or 0.3
                btn.familyIcon:SetAlpha(saturation)
                btn.familyGlow:Hide()
            end
            btn.familyIcon:Show()
        else
            btn.familyIcon:SetTexture(nil)
            btn.familyIcon:Hide()
            btn.familyGlow:Hide()
        end
    else
        btn.familyIcon:Hide()
        btn.familyGlow:Hide()
    end
    
    -- Name display with breed (shared formatter handles color codes and truncation)
    btn.nameText:SetText(petUtils:formatPetDisplayName(petData, 50))
    
    -- Selection highlighting
    if petData.owned and petUtils then
        local rarity = petData.rarity or 2
        local color = petUtils:getRarityColor(rarity)
        btn.nameText:SetTextColor(color.r, color.g, color.b)
        
        if isSelected then
            btn.selectedBg:Show()
        else
            btn.selectedBg:Hide()
        end
    else
        btn.nameText:SetTextColor(0.5, 0.5, 0.5)
        if isSelected then
            btn.selectedBg:Show()
        else
            btn.selectedBg:Hide()
        end
    end
    
    -- Battle stone upgrade indicator (only for owned pets below Rare)
    btn.upgradeBg:Hide()  -- Reset
    if petData.owned and petData.rarity and petData.rarity < 4 and petUtils and constants then
        -- Check cache first, scan if not present
        local cacheKey = petData.petType .. "-" .. petData.rarity
        local stones = battleStoneCache[cacheKey]
        if stones == nil then
            stones = petUtils:scanBattleStones(petData.petType, petData.rarity) or false
            battleStoneCache[cacheKey] = stones
        end
        
        if stones and #stones > 0 then
            local upgradeColor = constants.UPGRADE_COLORS and constants.UPGRADE_COLORS.background
            if upgradeColor then
                btn.upgradeBg:SetVertexColor(upgradeColor.r, upgradeColor.g, upgradeColor.b, upgradeColor.a or 0.15)
                btn.upgradeBg:Show()
            end
        end
    end
    
    btn:Show()
end

-- ============================================================================
-- INITIALIZATION (lightweight - just resolves module references)
-- ============================================================================

function petRowButton:initialize()
    utils = Addon.utils
    constants = Addon.constants
    petUtils = Addon.petUtils
    
    if not utils or not constants or not petUtils then
        print("|cff33ff99PAO|r: |cffff4444petRowButton: Missing dependencies|r")
        return false
    end
    
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("petRowButton", {"utils", "constants", "petUtils"}, function()
        return petRowButton:initialize()
    end)
end

Addon.petRowButton = petRowButton
return petRowButton