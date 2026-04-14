--[[
  ui/shared/petChip.lua
  Pet Chip Factory

  Creates variable-width pill-shaped chip frames for the species view chip tray.

  Chip content (left to right):
    [rarity pip 7px] [4px] [level] [4px] [breed] [4px] [customName] [4px] [star] [cage icon]

  Caged chips: right-click context menu, no drag. Distinguished by square pip and cage icon.
  Normal chips: click selects, right-click context menu, drag to battle slot, hover tooltip.

  Width is calculated from measured text content + icon widths + padding.

  Usage:
    local chip = petChip:create(parent, callbacks)
    petChip:update(chip, petData, selectedPetID)
    local w = chip:GetWidth()  -- for tray layout

  Dependencies: utils, constants, petUtils
  Exports: Addon.petChip
]]

local ADDON_NAME, Addon = ...

local petChip = {}

-- Module references (resolved at init)
local utils, constants, petUtils

-- Layout constants (8pt grid)
local CHIP_HEIGHT = 22
local CHIP_PADDING_H = 8          -- SMALL: horizontal padding inside chip
local ELEMENT_GAP = 4             -- TINY: between inline elements
local PIP_SIZE = 7
local CAGE_ICON_SIZE = 14

-- Pip texture paths
local PIP_CIRCLE = "Interface\\AddOns\\PawAndOrder\\textures\\pip-circle.png"
local PIP_SQUARE = "Interface\\Buttons\\WHITE8x8"

-- Colors
local CHIP_BG_COLOR = { 0.15, 0.15, 0.15, 0.8 }
local CHIP_BG_SELECTED = { 0.67, 0.51, 0.93, 0.3 }
local CHIP_BG_HOVER = { 0.25, 0.25, 0.25, 0.9 }
local CAGE_ICON_COLOR = { 0.9, 0.6, 0.1 }   -- Amber: matches cageGlow border
local CUSTOM_NAME_COLOR = { 1, 0.82, 0.5 }  -- Warm gold for custom names


-- Pip colors (cached on init)
local pipColors = nil

local function cachePipColors()
    if pipColors or not constants or not constants.RARITY_COLORS then return end
    pipColors = {}
    for i = 1, 6 do
        local c = constants.RARITY_COLORS[i]
        if c then pipColors[i] = { c.r, c.g, c.b } end
    end
end

-- ============================================================================
-- CHIP CREATION
-- ============================================================================

--[[
  Create a chip frame with all child elements.

  @param parent frame - Parent frame (the chip tray)
  @param callbacks table - {onSelected = function(petID), onContextMenu = function(petData, chip)}
  @return frame - Chip frame
]]
function petChip:create(parent, callbacks)
    if not parent then
        error("petChip:create requires parent frame")
    end

    callbacks = callbacks or {}

    local chip = CreateFrame("Frame", nil, parent)
    chip:SetHeight(CHIP_HEIGHT)
    chip:SetFrameLevel(parent:GetFrameLevel() + 2)
    chip:EnableMouse(true)

    chip.callbacks = callbacks

    -- Background
    chip.bg = chip:CreateTexture(nil, "BACKGROUND")
    chip.bg:SetAllPoints()
    chip.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    chip.bg:SetVertexColor(unpack(CHIP_BG_COLOR))

    -- Selected highlight (overlays bg)
    chip.selectedBg = chip:CreateTexture(nil, "BACKGROUND", nil, 1)
    chip.selectedBg:SetAllPoints()
    chip.selectedBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    chip.selectedBg:SetVertexColor(unpack(CHIP_BG_SELECTED))
    chip.selectedBg:Hide()

    -- Recent pet glow (golden border around chip edges)
    local GLOW_COLOR = { 1, 0.85, 0.4, 0.8 }
    local GLOW_SIZE = 1.5
    chip.recentGlow = {}
    chip.recentGlow.top = chip:CreateTexture(nil, "BORDER")
    chip.recentGlow.top:SetTexture("Interface\\Buttons\\WHITE8x8")
    chip.recentGlow.top:SetVertexColor(unpack(GLOW_COLOR))
    chip.recentGlow.top:SetHeight(GLOW_SIZE)
    chip.recentGlow.top:SetPoint("TOPLEFT", chip, "TOPLEFT", 0, 0)
    chip.recentGlow.top:SetPoint("TOPRIGHT", chip, "TOPRIGHT", 0, 0)
    chip.recentGlow.bottom = chip:CreateTexture(nil, "BORDER")
    chip.recentGlow.bottom:SetTexture("Interface\\Buttons\\WHITE8x8")
    chip.recentGlow.bottom:SetVertexColor(unpack(GLOW_COLOR))
    chip.recentGlow.bottom:SetHeight(GLOW_SIZE)
    chip.recentGlow.bottom:SetPoint("BOTTOMLEFT", chip, "BOTTOMLEFT", 0, 0)
    chip.recentGlow.bottom:SetPoint("BOTTOMRIGHT", chip, "BOTTOMRIGHT", 0, 0)
    chip.recentGlow.left = chip:CreateTexture(nil, "BORDER")
    chip.recentGlow.left:SetTexture("Interface\\Buttons\\WHITE8x8")
    chip.recentGlow.left:SetVertexColor(unpack(GLOW_COLOR))
    chip.recentGlow.left:SetWidth(GLOW_SIZE)
    chip.recentGlow.left:SetPoint("TOPLEFT", chip, "TOPLEFT", 0, 0)
    chip.recentGlow.left:SetPoint("BOTTOMLEFT", chip, "BOTTOMLEFT", 0, 0)
    chip.recentGlow.right = chip:CreateTexture(nil, "BORDER")
    chip.recentGlow.right:SetTexture("Interface\\Buttons\\WHITE8x8")
    chip.recentGlow.right:SetVertexColor(unpack(GLOW_COLOR))
    chip.recentGlow.right:SetWidth(GLOW_SIZE)
    chip.recentGlow.right:SetPoint("TOPRIGHT", chip, "TOPRIGHT", 0, 0)
    chip.recentGlow.right:SetPoint("BOTTOMRIGHT", chip, "BOTTOMRIGHT", 0, 0)
    chip.recentGlow.top:Hide()
    chip.recentGlow.bottom:Hide()
    chip.recentGlow.left:Hide()
    chip.recentGlow.right:Hide()
    chip.recentGlow._hidden = true

    -- Rarity pip
    chip.pip = chip:CreateTexture(nil, "ARTWORK")
    chip.pip:SetSize(PIP_SIZE, PIP_SIZE)
    chip.pip:SetPoint("LEFT", chip, "LEFT", CHIP_PADDING_H, 0)

    -- Level text
    chip.levelText = chip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chip.levelText:SetPoint("LEFT", chip.pip, "RIGHT", ELEMENT_GAP, 0)
    chip.levelText:SetTextColor(1, 1, 1)

    -- Breed text
    chip.breedText = chip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chip.breedText:SetPoint("LEFT", chip.levelText, "RIGHT", ELEMENT_GAP, 0)

    -- Custom name text (warm gold, only shown if pet has one)
    chip.customNameText = chip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chip.customNameText:SetPoint("LEFT", chip.breedText, "RIGHT", ELEMENT_GAP, 0)
    chip.customNameText:SetTextColor(unpack(CUSTOM_NAME_COLOR))

    -- Favorite star
    chip.starText = chip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    chip.starText:SetTextColor(1, 0.82, 0)
    -- Anchored dynamically based on which elements are visible

    -- Cage icon (for caged pets)
    chip.cageIcon = chip:CreateTexture(nil, "ARTWORK")
    chip.cageIcon:SetSize(CAGE_ICON_SIZE, CAGE_ICON_SIZE)
    chip.cageIcon:SetTexture("Interface\\AddOns\\PawAndOrder\\textures\\cage.png")
    chip.cageIcon:Hide()

    -- Amber border glow for caged pets (same pattern as recentGlow)
    local CAGE_GLOW_COLOR = { 0.9, 0.6, 0.1, 0.9 }
    chip.cageGlow = {}
    chip.cageGlow.top = chip:CreateTexture(nil, "BORDER")
    chip.cageGlow.top:SetTexture("Interface\\Buttons\\WHITE8x8")
    chip.cageGlow.top:SetVertexColor(unpack(CAGE_GLOW_COLOR))
    chip.cageGlow.top:SetHeight(GLOW_SIZE)
    chip.cageGlow.top:SetPoint("TOPLEFT", chip, "TOPLEFT", 0, 0)
    chip.cageGlow.top:SetPoint("TOPRIGHT", chip, "TOPRIGHT", 0, 0)
    chip.cageGlow.bottom = chip:CreateTexture(nil, "BORDER")
    chip.cageGlow.bottom:SetTexture("Interface\\Buttons\\WHITE8x8")
    chip.cageGlow.bottom:SetVertexColor(unpack(CAGE_GLOW_COLOR))
    chip.cageGlow.bottom:SetHeight(GLOW_SIZE)
    chip.cageGlow.bottom:SetPoint("BOTTOMLEFT", chip, "BOTTOMLEFT", 0, 0)
    chip.cageGlow.bottom:SetPoint("BOTTOMRIGHT", chip, "BOTTOMRIGHT", 0, 0)
    chip.cageGlow.left = chip:CreateTexture(nil, "BORDER")
    chip.cageGlow.left:SetTexture("Interface\\Buttons\\WHITE8x8")
    chip.cageGlow.left:SetVertexColor(unpack(CAGE_GLOW_COLOR))
    chip.cageGlow.left:SetWidth(GLOW_SIZE)
    chip.cageGlow.left:SetPoint("TOPLEFT", chip, "TOPLEFT", 0, 0)
    chip.cageGlow.left:SetPoint("BOTTOMLEFT", chip, "BOTTOMLEFT", 0, 0)
    chip.cageGlow.right = chip:CreateTexture(nil, "BORDER")
    chip.cageGlow.right:SetTexture("Interface\\Buttons\\WHITE8x8")
    chip.cageGlow.right:SetVertexColor(unpack(CAGE_GLOW_COLOR))
    chip.cageGlow.right:SetWidth(GLOW_SIZE)
    chip.cageGlow.right:SetPoint("TOPRIGHT", chip, "TOPRIGHT", 0, 0)
    chip.cageGlow.right:SetPoint("BOTTOMRIGHT", chip, "BOTTOMRIGHT", 0, 0)
    chip.cageGlow.top:Hide()
    chip.cageGlow.bottom:Hide()
    chip.cageGlow.left:Hide()
    chip.cageGlow.right:Hide()

    -- Hover/click scripts
    chip:SetScript("OnEnter", function(self)
        local petData = self.petData
        if not petData then return end

        self.bg:SetVertexColor(unpack(CHIP_BG_HOVER))

        if self.isCaged then
            if Addon.petTooltips then
                Addon.petTooltips:showForCaged(self, petData, { anchor = "cursor" })
            end
        elseif Addon.petTooltips then
            Addon.petTooltips:show(self, petData.petID, petData.speciesID, { anchor = "cursor" })
        end
    end)

    chip:SetScript("OnLeave", function(self)
        if self.isSelected then
            self.bg:SetVertexColor(unpack(CHIP_BG_SELECTED))
        else
            self.bg:SetVertexColor(unpack(CHIP_BG_COLOR))
        end

        -- If a context menu is open, keep tooltip alive until menu closes
        local menuRenderer = Addon.menuRenderer
        if menuRenderer and menuRenderer:isVisible() then
            self:SetScript("OnUpdate", function(me)
                if not menuRenderer:isVisible() then
                    if Addon.petTooltips then Addon.petTooltips:hide() end
                    me:SetScript("OnUpdate", nil)
                end
            end)
        else
            if Addon.petTooltips then Addon.petTooltips:hide() end
        end
    end)

    chip:SetScript("OnMouseUp", function(self, button)
        local petData = self.petData
        if not petData then return end

        if self.isCaged then
            if button == "LeftButton" and self.callbacks.onSelected then
                self.callbacks.onSelected(petData, petData.petID)
            elseif button == "RightButton" and self.callbacks.onContextMenu then
                self.callbacks.onContextMenu(petData, self)
            end
            return
        end

        if button == "LeftButton" then
            if self.callbacks.onSelected and petData.petID then
                self.callbacks.onSelected(petData, petData.petID)
            end
        elseif button == "RightButton" then
            if self.callbacks.onContextMenu then
                self.callbacks.onContextMenu(petData, self)
            end
        end
    end)

    -- Drag support (normal chips only)
    chip:RegisterForDrag("LeftButton")
    chip:SetScript("OnDragStart", function(self)
        if self.isCaged then return end
        local petData = self.petData
        if petData and petData.petID then
            C_PetJournal.PickupPet(petData.petID)
            if Addon.petDetails and Addon.petDetails.showDropTargets then
                Addon.petDetails:showDropTargets()
            end
        end
    end)

    return chip
end

-- ============================================================================
-- CHIP UPDATE
-- ============================================================================

--[[
  Update a chip with pet data and calculate its width.

  @param chip frame - Chip from create()
  @param petData table - Full pet data entry (from petGrouping chips array)
  @param selectedPetID string|nil - Currently selected petID for highlight
]]
function petChip:update(chip, petData, selectedPetID)
    if not petData then
        chip:Hide()
        return
    end

    chip.petData = petData
    chip.isCaged = petData.isCaged or false
    chip.isSelected = (selectedPetID and selectedPetID == petData.petID) or false

    cachePipColors()

    local isCaged = chip.isCaged
    local runningWidth = CHIP_PADDING_H

    -- ========================================================================
    -- Rarity pip
    -- ========================================================================
    local rarity = petData.rarity or 2
    local color = pipColors and pipColors[rarity] or { 1, 1, 1 }

    if isCaged then
        chip.pip:SetTexture(PIP_SQUARE)
    else
        chip.pip:SetTexture(PIP_CIRCLE)
    end
    chip.pip:SetTexCoord(0, 1, 0, 1)
    chip.pip:SetVertexColor(color[1], color[2], color[3])
    chip.pip:Show()
    runningWidth = runningWidth + PIP_SIZE + ELEMENT_GAP

    -- ========================================================================
    -- Level text
    -- ========================================================================
    chip.levelText:SetText(tostring(petData.level or "?"))
    chip.levelText:Show()
    runningWidth = runningWidth + chip.levelText:GetStringWidth() + ELEMENT_GAP

    -- ========================================================================
    -- Breed text
    -- ========================================================================
    local breedDisplay = ""
    if petData.breedText and petData.breedText ~= "" then
        breedDisplay = string.gsub(petData.breedText, " %(%d+%%%)", "")
        breedDisplay = breedDisplay:gsub("%s+$", "")
    end

    if breedDisplay ~= "" then
        if petUtils then
            local rarityColor = petUtils:getRarityColor(rarity)
            local dimR, dimG, dimB
            dimR = math.floor(rarityColor.r * 0.75 * 255)
            dimG = math.floor(rarityColor.g * 0.75 * 255)
            dimB = math.floor(rarityColor.b * 0.75 * 255)
            chip.breedText:SetText(string.format("|cff%02x%02x%02x%s|r", dimR, dimG, dimB, breedDisplay))
        else
            chip.breedText:SetText(breedDisplay)
            chip.breedText:SetTextColor(0.7, 0.7, 0.7)
        end
        chip.breedText:Show()
        runningWidth = runningWidth + chip.breedText:GetStringWidth() + ELEMENT_GAP
    else
        chip.breedText:SetText("")
        chip.breedText:Hide()
    end

    -- ========================================================================
    -- Custom name (only if pet has one and it differs from species name)
    -- ========================================================================
    local customName = petData.customName
    local hasCustomName = customName and customName ~= "" and customName ~= petData.speciesName and customName ~= petData.name
    if hasCustomName and not isCaged then
        chip.customNameText:SetText(customName)
        chip.customNameText:Show()
        runningWidth = runningWidth + chip.customNameText:GetStringWidth() + ELEMENT_GAP
    else
        chip.customNameText:SetText("")
        chip.customNameText:Hide()
    end

    -- ========================================================================
    -- Favorite star
    -- ========================================================================
    local lastVisibleElement = chip.customNameText:IsShown() and chip.customNameText
        or chip.breedText:IsShown() and chip.breedText
        or chip.levelText

    -- petCache uses "favorite", petGrouping may pass through raw data
    local isFavorite = petData.isFavorite or petData.favorite
    if isFavorite and not isCaged then
        chip.starText:ClearAllPoints()
        chip.starText:SetPoint("LEFT", lastVisibleElement, "RIGHT", ELEMENT_GAP, 0)
        chip.starText:SetText("*")
        chip.starText:Show()
        runningWidth = runningWidth + chip.starText:GetStringWidth() + ELEMENT_GAP
    else
        chip.starText:SetText("")
        chip.starText:Hide()
    end

    -- ========================================================================
    -- Cage icon (replaces star position for caged pets)
    -- ========================================================================
    if isCaged then
        chip.cageIcon:ClearAllPoints()
        chip.cageIcon:SetPoint("LEFT", lastVisibleElement, "RIGHT", ELEMENT_GAP, 0)
        chip.cageIcon:SetVertexColor(unpack(CAGE_ICON_COLOR))
        chip.cageIcon:Show()
        runningWidth = runningWidth + CAGE_ICON_SIZE + ELEMENT_GAP
    else
        chip.cageIcon:Hide()
    end

    -- ========================================================================
    -- Final width
    -- ========================================================================
    runningWidth = runningWidth - ELEMENT_GAP + CHIP_PADDING_H
    chip:SetWidth(math.max(runningWidth, 40))

    -- ========================================================================
    -- Background state
    -- ========================================================================
    if chip.isSelected then
        chip.selectedBg:Show()
        chip.bg:SetVertexColor(unpack(CHIP_BG_SELECTED))
    else
        chip.selectedBg:Hide()
        chip.bg:SetVertexColor(unpack(CHIP_BG_COLOR))
    end

    -- Recent pet glow (golden border for newly acquired pets)
    local showGlow = false
    if not isCaged and petData.petID then
        local petAcquisitions = Addon.petAcquisitions
        if petAcquisitions and petAcquisitions:isRecent(petData.petID) then
            showGlow = true
        end
    end
    if showGlow and chip.recentGlow._hidden then
        chip.recentGlow.top:Show()
        chip.recentGlow.bottom:Show()
        chip.recentGlow.left:Show()
        chip.recentGlow.right:Show()
        chip.recentGlow._hidden = false
    elseif not showGlow and not chip.recentGlow._hidden then
        chip.recentGlow.top:Hide()
        chip.recentGlow.bottom:Hide()
        chip.recentGlow.left:Hide()
        chip.recentGlow.right:Hide()
        chip.recentGlow._hidden = true
    end

    chip:SetAlpha(1.0)
    chip.cageGlow.top:Hide()
    chip.cageGlow.bottom:Hide()
    chip.cageGlow.left:Hide()
    chip.cageGlow.right:Hide()

    chip:Show()
end

-- ============================================================================
-- POOL MANAGEMENT
-- ============================================================================

--[[
  Reclaim all chips in a pool (hide and reset).

  @param chips table - Array of chip frames
]]
function petChip:reclaimAll(chips)
    if not chips then return end
    for _, chip in ipairs(chips) do
        chip:Hide()
        chip:ClearAllPoints()
        chip.petData = nil
        chip.isSelected = false
        chip.isCaged = false
        if chip.recentGlow then
            chip.recentGlow.top:Hide()
            chip.recentGlow.bottom:Hide()
            chip.recentGlow.left:Hide()
            chip.recentGlow.right:Hide()
            chip.recentGlow._hidden = true
        end
        if chip.cageGlow then
            chip.cageGlow.top:Hide()
            chip.cageGlow.bottom:Hide()
            chip.cageGlow.left:Hide()
            chip.cageGlow.right:Hide()
        end
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function petChip:initialize()
    utils = Addon.utils
    constants = Addon.constants
    petUtils = Addon.petUtils

    if not utils or not constants or not petUtils then
        print("|cff33ff99PAO|r: |cffff4444petChip: Missing dependencies|r")
        return false
    end

    cachePipColors()
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("petChip", {"utils", "constants", "petUtils"}, function()
        return petChip:initialize()
    end)
end

Addon.petChip = petChip
return petChip