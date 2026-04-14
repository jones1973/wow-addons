--[[
  ui/shared/speciesRowButton.lua
  Species Row Button Factory (Stateless)

  Creates and updates species header rows for species view.
  Handles two modes:
    - "species": Owned species with expand arrow, badges, icon, name, pips, family icon
    - "unowned": Desaturated icon, muted name, no pips, no arrow, aligned spacers

  Layout (left to right, species mode):
    [expand arrow 16px] [badge col 33px] [species icon 36x36] [8px] [name] [4px] [pips] [8px] [family icon]

  Layout (unowned mode):
    [16px spacer] [33px spacer] [icon 36x36 desat] [8px] [muted name] [family icon]

  Row height: 43px (2px above icon, 1px below icon, 36px icon, 4px frame)

  Usage:
    local btn = speciesRowButton:create(parent, height, callbacks)
    speciesRowButton:update(btn, displayEntry, containsSelectedPet)

  Dependencies: utils, constants, uiUtils, petUtils
  Exports: Addon.speciesRowButton
]]

local ADDON_NAME, Addon = ...

local speciesRowButton = {}

-- Module references (resolved at init)
local utils, constants, uiUtils, petUtils

-- Layout constants (8pt grid)
local ROW_HEIGHT = 43
local ARROW_COL_WIDTH = 16
local ARROW_SIZE = 16
local BADGE_COL_WIDTH = 33
local ICON_SIZE = 36
local ICON_GAP = 8              -- SMALL: icon to name
local PIP_SIZE = 7
-- Common (rarity 2) and Uncommon (rarity 3) pips render at 6px — slightly
-- smaller to visually de-emphasize lower qualities against higher-rarity pips.
local PIP_SIZE_SMALL = 6
local PIP_GAP = 4               -- TINY: between pips
local PIP_LEFT_MARGIN = 4       -- TINY: name to first pip
local PIP_RIGHT_MARGIN = 8      -- SMALL: last pip to family icon
local FAMILY_ICON_WIDTH = 20
local FAMILY_ICON_HEIGHT = 25
local FAMILY_RIGHT_PAD = 8      -- SMALL: family icon to right edge
local BADGE_ICON_SIZE = 14

-- Icon vertical offset: 2px above, 1px below → 0.5px up from center
local ICON_Y_OFFSET = 0.5

-- Arrow textures (matching checkboxTree expand/collapse pattern)
local ARROW_EXPANDED = "Interface\\AddOns\\PawAndOrder\\textures\\collapse_arrow.png"
local ARROW_COLLAPSED = "Interface\\AddOns\\PawAndOrder\\textures\\expand_arrow.png"

-- Pip texture paths
local PIP_CIRCLE = "Interface\\AddOns\\PawAndOrder\\textures\\pip-circle.png"
-- Square texture is ONLY used for caged pets sitting in the player's bags.
-- It is NOT a rarity indicator. Rarity is conveyed by color alone.
local PIP_SQUARE = "Interface\\Buttons\\WHITE8x8"

-- Badge texture paths
local BADGE_UNIQUE = "Interface\\AddOns\\PawAndOrder\\textures\\grey-diamond.png"
local BADGE_CAGEABLE = "Interface\\AddOns\\PawAndOrder\\textures\\cage.png"

-- Pip rarity colors (cached from constants on init)
local pipColors = nil

local function cachePipColors()
    if pipColors or not constants or not constants.RARITY_COLORS then return end
    pipColors = {}
    for i = 1, 6 do
        local c = constants.RARITY_COLORS[i]
        if c then
            pipColors[i] = { c.r, c.g, c.b }
        end
    end
end

-- ============================================================================
-- BUTTON CREATION
-- ============================================================================

--[[
  Create a species row button with all child elements.

  @param parent frame - Parent frame for the button
  @param height number - Button height in pixels (default ROW_HEIGHT)
  @param callbacks table - {onToggle = function(speciesID), onSelect = function(speciesID, entry), onContextMenu = function(speciesID, btn, entryType)}
  @return frame - Button frame ready for use
]]
function speciesRowButton:create(parent, height, callbacks)
    if not parent then
        error("speciesRowButton:create requires parent frame")
    end

    height = height or ROW_HEIGHT
    callbacks = callbacks or {}

    local btn = CreateFrame("Frame", nil, parent)
    btn:SetSize(parent:GetWidth(), height)
    btn:SetFrameLevel(parent:GetFrameLevel() + 1)
    btn:EnableMouse(true)

    btn.rowHeight = height
    btn.callbacks = callbacks

    -- Hover highlight
    btn.hoverBg = btn:CreateTexture(nil, "BACKGROUND")
    btn.hoverBg:SetAllPoints()
    btn.hoverBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.hoverBg:SetVertexColor(1, 1, 1, 0.08)
    btn.hoverBg:Hide()

    -- Selection tint (species contains the selected pet)
    btn.selectionTint = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
    btn.selectionTint:SetAllPoints()
    btn.selectionTint:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.selectionTint:SetVertexColor(0.67, 0.51, 0.93, 0.12)
    btn.selectionTint:Hide()

    -- Expanded background (visual grouping with chip tray)
    btn.expandedBg = btn:CreateTexture(nil, "BACKGROUND", nil, -1)
    btn.expandedBg:SetAllPoints()
    btn.expandedBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn.expandedBg:SetVertexColor(0.67, 0.51, 0.93, 0.08)
    btn.expandedBg:Hide()

    -- Expand/collapse arrow texture (matching checkboxTree)
    btn.arrow = btn:CreateTexture(nil, "ARTWORK")
    btn.arrow:SetSize(ARROW_SIZE, ARROW_SIZE)
    btn.arrow:SetPoint("LEFT", btn, "LEFT", 0, 0)
    btn.arrow:SetTexture(ARROW_COLLAPSED)

    -- Badge column (between arrow and icon)
    btn.badgeFrame = CreateFrame("Frame", nil, btn)
    btn.badgeFrame:SetSize(BADGE_COL_WIDTH, height)
    btn.badgeFrame:SetPoint("LEFT", btn, "LEFT", ARROW_COL_WIDTH, 0)

    -- Badge icons (up to 2: unique, cageable)
    btn.badgeIcons = {}
    for i = 1, 2 do
        local iconFrame = CreateFrame("Frame", nil, btn.badgeFrame)
        iconFrame:SetSize(BADGE_ICON_SIZE, BADGE_ICON_SIZE)
        iconFrame:EnableMouse(true)

        local icon = iconFrame:CreateTexture(nil, "OVERLAY")
        icon:SetSize(BADGE_ICON_SIZE, BADGE_ICON_SIZE)
        icon:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
        iconFrame.icon = icon

        iconFrame:SetScript("OnEnter", function(self)
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
            local rowBtn = self:GetParent():GetParent()
            if rowBtn and rowBtn.hoverBg then
                rowBtn.hoverBg:Hide()
            end
            GameTooltip:Hide()
        end)

        iconFrame:Hide()
        btn.badgeIcons[i] = iconFrame
    end

    -- Species icon
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetSize(ICON_SIZE, ICON_SIZE)
    btn.icon:SetPoint("LEFT", btn.badgeFrame, "RIGHT", 2, ICON_Y_OFFSET)

    -- Species name
    btn.nameText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btn.nameText:SetPoint("LEFT", btn.icon, "RIGHT", ICON_GAP, 0)
    btn.nameText:SetJustifyH("LEFT")
    btn.nameText:SetWordWrap(true)

    -- Pip container
    btn.pipFrame = CreateFrame("Frame", nil, btn)
    btn.pipFrame:SetSize(1, PIP_SIZE)
    btn.pipFrame:SetPoint("LEFT", btn.nameText, "RIGHT", PIP_LEFT_MARGIN, 0)
    btn.pips = {}

    -- Family icon (right side)
    btn.familyIcon = btn:CreateTexture(nil, "OVERLAY", nil, 2)
    btn.familyIcon:SetSize(FAMILY_ICON_WIDTH, FAMILY_ICON_HEIGHT)
    btn.familyIcon:SetPoint("RIGHT", btn, "RIGHT", -FAMILY_RIGHT_PAD, 0)
    btn.familyIcon:SetBlendMode("ADD")

    -- Glow texture for species containing recent pets (behind family icon)
    btn.familyGlow = btn:CreateTexture(nil, "OVERLAY", nil, 1)
    btn.familyGlow:SetSize(FAMILY_ICON_WIDTH + 16, FAMILY_ICON_HEIGHT + 11)
    btn.familyGlow:SetPoint("CENTER", btn.familyIcon, "CENTER", 0, 0)
    btn.familyGlow:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
    btn.familyGlow:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
    btn.familyGlow:SetVertexColor(1, 0.85, 0.4, 0.8)
    btn.familyGlow:SetBlendMode("ADD")
    btn.familyGlow:Hide()

    -- Invisible button over the arrow column to capture expand/collapse clicks.
    -- Intercepts left-clicks in the arrow area before they reach btn, so that
    -- clicking the row body (outside the arrow) fires onSelect instead.
    btn.arrowButton = CreateFrame("Button", nil, btn)
    btn.arrowButton:SetSize(ARROW_COL_WIDTH, height)
    btn.arrowButton:SetPoint("LEFT", btn, "LEFT", 0, 0)
    btn.arrowButton:SetFrameLevel(btn:GetFrameLevel() + 1)
    btn.arrowButton:RegisterForClicks("LeftButtonDown")
    btn.arrowButton:SetScript("OnClick", function(self)
        local rowBtn = self:GetParent()
        if not rowBtn.speciesData then return end
        if rowBtn.speciesData.type == "species" and rowBtn.callbacks.onToggle then
            rowBtn.callbacks.onToggle(rowBtn.speciesData.speciesID)
        end
    end)

    -- Hover/click scripts
    btn:SetScript("OnEnter", function(self)
        self.hoverBg:Show()
    end)

    btn:SetScript("OnLeave", function(self)
        self.hoverBg:Hide()
    end)

    btn:SetScript("OnMouseDown", function(self, button)
        if not self.speciesData then return end
        if button == "LeftButton" then
            if self.callbacks.onSelect then
                self.callbacks.onSelect(self.speciesData.speciesID, self.speciesData)
            end
        elseif button == "RightButton" then
            if self.callbacks.onContextMenu then
                self.callbacks.onContextMenu(self.speciesData.speciesID, self, self.speciesData.type)
            end
        end
    end)

    return btn
end

-- ============================================================================
-- PIP MANAGEMENT
-- ============================================================================

local function ensurePips(btn, count)
    for i = #btn.pips + 1, count do
        local pip = btn.pipFrame:CreateTexture(nil, "OVERLAY")
        pip:SetSize(PIP_SIZE, PIP_SIZE)
        btn.pips[i] = pip
    end

    for i = 1, count do
        local pip = btn.pips[i]
        pip:ClearAllPoints()
        if i == 1 then
            pip:SetPoint("LEFT", btn.pipFrame, "LEFT", 0, 0)
        else
            pip:SetPoint("LEFT", btn.pips[i - 1], "RIGHT", PIP_GAP, 0)
        end
        pip:Show()
    end

    for i = count + 1, #btn.pips do
        btn.pips[i]:Hide()
    end

    if count > 0 then
        local totalWidth = (count * PIP_SIZE) + ((count - 1) * PIP_GAP)
        btn.pipFrame:SetSize(totalWidth, PIP_SIZE)
        btn.pipFrame:Show()
    else
        btn.pipFrame:SetSize(1, PIP_SIZE)
        btn.pipFrame:Hide()
    end
end

local function stylePip(pip, rarity, isCaged)
    cachePipColors()

    local color = pipColors and pipColors[rarity]
    if not color then
        color = { 1, 1, 1 }
    end

    -- Common (2) and Uncommon (3) render slightly smaller to visually
    -- de-emphasize lower qualities relative to Rare+ pips.
    local size = (rarity == 2 or rarity == 3) and PIP_SIZE_SMALL or PIP_SIZE
    pip:SetSize(size, size)

    if isCaged then
        pip:SetTexture(PIP_SQUARE)
    else
        pip:SetTexture(PIP_CIRCLE)
    end
    pip:SetTexCoord(0, 1, 0, 1)
    pip:SetVertexColor(color[1], color[2], color[3])
end

-- ============================================================================
-- BADGE MANAGEMENT
-- ============================================================================

local badgeBuffer = {}

local function updateBadges(btn, entry)
    if entry.type == "unowned" then
        -- renderBadges will clear icons; nothing else to do for unowned rows
        local uiUtils = Addon.uiUtils
        if uiUtils then uiUtils:renderBadges(btn.badgeIcons, btn.badgeFrame, {}) end
        return
    end

    wipe(badgeBuffer)

    -- Check if any owned pet in this species is currently caged in bags
    local hasCaged = false
    if entry.pets then
        for _, pet in ipairs(entry.pets) do
            if pet.isCaged then
                hasCaged = true
                break
            end
        end
    end

    -- unique and tradable are species-level properties; every pet in the group
    -- shares the same value, so reading from pets[1] avoids a redundant API call.
    -- Unowned entries have no pets array, so fall back to the API.
    local firstPet = entry.pets and entry.pets[1]
    local unique, tradable
    if firstPet then
        unique   = firstPet.unique
        tradable = firstPet.tradable
    else
        local _, _, _, _, _, _, _, _, apiTradable, apiUnique =
            C_PetJournal.GetPetInfoBySpeciesID(entry.speciesID)
        unique   = apiUnique
        tradable = apiTradable
    end

    -- Slot 1: unique indicator
    if unique then
        table.insert(badgeBuffer, { texture = BADGE_UNIQUE, tooltip = "Unique" })
    end

    -- Slot 2: caged supersedes cageable (pet is already out of the journal)
    if hasCaged then
        table.insert(badgeBuffer, { texture = BADGE_CAGEABLE, tooltip = "Caged" })
    elseif tradable then
        table.insert(badgeBuffer, { texture = BADGE_CAGEABLE, tooltip = "Cageable" })
    end

    local uiUtils = Addon.uiUtils
    if uiUtils then
        uiUtils:renderBadges(btn.badgeIcons, btn.badgeFrame, badgeBuffer)
    end
end

-- ============================================================================
-- BUTTON UPDATE
-- ============================================================================

--[[
  Update a species row button with display entry data.

  @param btn frame - Button to update (from create())
  @param entry table - Display entry from petGrouping:group()
  @param containsSelectedPet boolean - True if this species contains the selected pet
]]
function speciesRowButton:update(btn, entry, containsSelectedPet)
    if not entry then
        btn:Hide()
        return
    end

    btn.speciesData = entry

    local isUnowned = (entry.type == "unowned")

    -- ========================================================================
    -- Arrow
    -- ========================================================================
    if isUnowned then
        btn.arrow:Hide()
    elseif entry.isExpanded then
        btn.arrow:SetTexture(ARROW_EXPANDED)
        btn.arrow:Show()
    else
        btn.arrow:SetTexture(ARROW_COLLAPSED)
        btn.arrow:Show()
    end

    -- ========================================================================
    -- Badges
    -- ========================================================================
    updateBadges(btn, entry)

    -- ========================================================================
    -- Species icon
    -- ========================================================================
    local _, speciesIcon = C_PetJournal.GetPetInfoBySpeciesID(entry.speciesID)
    if speciesIcon then
        btn.icon:SetTexture(speciesIcon)
    else
        btn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    btn.icon:SetDesaturated(isUnowned)

    -- ========================================================================
    -- Species name
    -- ========================================================================
    local displayName = entry.speciesName or "Unknown"
    btn.nameText:SetText(displayName)

    if isUnowned then
        btn.nameText:SetTextColor(0.70, 0.60, 1.0)
    elseif petUtils then
        local color = petUtils:getRarityColor(entry.bestRarity or 2)
        btn.nameText:SetTextColor(color.r, color.g, color.b)
    else
        btn.nameText:SetTextColor(1, 1, 1)
    end

    -- ========================================================================
    -- Pips
    -- ========================================================================
    if isUnowned or not entry.pips then
        ensurePips(btn, 0)
    else
        ensurePips(btn, #entry.pips)
        for i, pipData in ipairs(entry.pips) do
            stylePip(btn.pips[i], pipData.rarity, pipData.isCaged)
        end
    end

    -- ========================================================================
    -- Name right anchor (constrained so pips + family icon fit)
    -- ========================================================================
    btn.nameText:ClearAllPoints()
    btn.nameText:SetPoint("LEFT", btn.icon, "RIGHT", ICON_GAP, 0)
    if not isUnowned and entry.pips and #entry.pips > 0 then
        local pipsWidth = (#entry.pips * PIP_SIZE) + ((#entry.pips - 1) * PIP_GAP) + PIP_LEFT_MARGIN + PIP_RIGHT_MARGIN
        local familyWidth = FAMILY_ICON_WIDTH + FAMILY_RIGHT_PAD
        btn.nameText:SetPoint("RIGHT", btn, "RIGHT", -(familyWidth + pipsWidth), 0)
    else
        btn.nameText:SetPoint("RIGHT", btn.familyIcon, "LEFT", -ICON_GAP, 0)
    end

    btn.pipFrame:ClearAllPoints()
    btn.pipFrame:SetPoint("LEFT", btn.nameText, "RIGHT", PIP_LEFT_MARGIN, 0)

    -- ========================================================================
    -- Family icon
    -- ========================================================================
    local hasRecentPet = false
    if not isUnowned and entry.pets then
        local petAcquisitions = Addon.petAcquisitions
        if petAcquisitions then
            for _, pet in ipairs(entry.pets) do
                if pet.petID and petAcquisitions:isRecent(pet.petID) then
                    hasRecentPet = true
                    break
                end
            end
        end
    end

    if entry.familyType and entry.familyType > 0 and uiUtils and uiUtils.setFamilyIcon then
        if uiUtils:setFamilyIcon(btn.familyIcon, entry.familyType, "faded-color") then
            btn.familyIcon:SetSize(FAMILY_ICON_WIDTH, FAMILY_ICON_HEIGHT)
            if isUnowned then
                btn.familyIcon:SetAlpha(0.15)
                btn.familyGlow:Hide()
            elseif hasRecentPet then
                btn.familyIcon:SetAlpha(1.0)
                btn.familyGlow:Show()
            else
                local saturation = math.min(1.0, (Addon.options and Addon.options:Get("familyIconSaturation") or 0.3) + 0.2)
                btn.familyIcon:SetAlpha(saturation)
                btn.familyGlow:Hide()
            end
            btn.familyIcon:Show()
        else
            btn.familyIcon:Hide()
            btn.familyGlow:Hide()
        end
    else
        btn.familyIcon:Hide()
        btn.familyGlow:Hide()
    end

    -- ========================================================================
    -- Selection tint
    -- ========================================================================
    if containsSelectedPet and not isUnowned then
        btn.selectionTint:Show()
    else
        btn.selectionTint:Hide()
    end

    -- ========================================================================
    -- Expanded background (visual grouping with chip tray)
    -- ========================================================================
    if not isUnowned and entry.isExpanded then
        btn.expandedBg:Show()
    else
        btn.expandedBg:Hide()
    end

    btn:Show()
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function speciesRowButton:initialize()
    utils = Addon.utils
    constants = Addon.constants
    uiUtils = Addon.uiUtils
    petUtils = Addon.petUtils

    if not utils or not constants or not uiUtils or not petUtils then
        print("|cff33ff99PAO|r: |cffff4444speciesRowButton: Missing dependencies|r")
        return false
    end

    cachePipColors()
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("speciesRowButton", {"utils", "constants", "uiUtils", "petUtils"}, function()
        return speciesRowButton:initialize()
    end)
end

Addon.speciesRowButton = speciesRowButton
return speciesRowButton