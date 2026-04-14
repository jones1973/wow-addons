--[[
  ui/headerBar.lua
  Header Bar Component
  
  Displays controls above the pet list and details panel:
  - Left side (over pet list): Collection dropdown, Sort dropdown, Pet count
  - Right side (over details): Achievement points, Summon Random, Heal
  
  The collection dropdown sets a "base filter" for owned/unowned that is applied
  independently from the filter text - no chip, no filter text modification.
  
  Dependencies: constants, utils, events, petCache, petSorting, dropdown
  Exports: Addon.headerBar
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in headerBar.lua.|r")
    return {}
end

local utils = Addon.utils
local constants, events, petCache, petSorting, dropdown, actionButton, petActions

local headerBar = {}

-- UI State
local headerFrame = nil
local leftSection = nil
local rightSection = nil

-- Dropdown frames
local collectionDropdown = nil
local sortDropdown = nil

-- Display elements
local petCountText = nil
local funnelIcon = nil
local summonRandomBtn = nil
local healBtn = nil
local modeToggleBtn = nil

-- State
local currentCollectionFilter = "all"  -- "all", "owned", "unowned"
local currentSort = "name"
local currentSortDir = "asc"
local currentFilteredCount = 0
local currentBaseCount = 0

-- Layout constants
local HEADER_HEIGHT = 44  -- Match constants.LAYOUT.HEADER_HEIGHT (40px buttons + 4px padding)
local DROPDOWN_WIDTH = 115
local BUTTON_WIDTH = 95
local BUTTON_HEIGHT = 24
local SPACING = 8

-- Collection filter options with icons
local COLLECTION_OPTIONS = {
    { value = "all", text = "All Pets", icon = "Interface\\AddOns\\PawAndOrder\\textures\\filter-all.png" },
    { value = "owned", text = "Owned", icon = "Interface\\AddOns\\PawAndOrder\\textures\\filter-owned.png" },
    { value = "unowned", text = "Unowned", icon = "Interface\\AddOns\\PawAndOrder\\textures\\filter-unowned.png" },
}

-- Sort options (populated from petSorting)
local sortOptions = nil

-- Forward declarations
local updateSortDirectionArrow

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Get current collection filter state
  @return string - "all", "owned", or "unowned"
]]
function headerBar:getCollectionFilter()
    return currentCollectionFilter
end

--[[
  Set collection filter and notify listeners
  @param value string - "all", "owned", or "unowned"
]]
function headerBar:setCollectionFilter(value)
    if value ~= "all" and value ~= "owned" and value ~= "unowned" then
        value = "all"
    end
    
    if value == currentCollectionFilter then return end
    
    currentCollectionFilter = value
    
    -- Update dropdown display
    if collectionDropdown then
        collectionDropdown:SetValue(value, true)
    end
    
    -- Emit event for mainFrame to refresh
    if events then
        events:emit("HEADER:COLLECTION_CHANGED", { filter = value })
    end
end

--[[
  Get current sort settings
  @return string, string - sort field, direction ("asc"/"desc")
]]
function headerBar:getSort()
    return currentSort, currentSortDir
end

--[[
  Set sort and notify listeners
  @param field string - Sort field
  @param direction string - "asc" or "desc"
]]
function headerBar:setSort(field, direction)
    local changed = (field ~= currentSort) or (direction ~= currentSortDir)
    
    currentSort = field or "name"
    currentSortDir = direction or "asc"
    
    -- Update dropdown display
    if sortDropdown then
        sortDropdown:SetValue(currentSort, true)
    end
    
    -- Update direction arrow
    updateSortDirectionArrow()
    
    -- Emit event for mainFrame to refresh
    if changed and events then
        events:emit("HEADER:SORT_CHANGED", { sort = currentSort, direction = currentSortDir })
    end
end

--[[
  Update filtered count display
  @param filtered number - Number of pets matching current filter
  @param base number - Number of pets after dropdown filter (denominator)
]]
function headerBar:updateFilteredCount(filtered, base)
    currentFilteredCount = filtered or 0
    if base then
        currentBaseCount = base
    end
    self:updatePetCountDisplay()
end

--[[
  Update pet count display text
  Shows: filtered / base
]]
function headerBar:updatePetCountDisplay()
    if petCountText then
        petCountText:SetText(string.format("%d / %d", currentFilteredCount, currentBaseCount))
        -- Update tooltip frame width
        if headerBar.updateFilterCountFrameWidth then
            headerBar.updateFilterCountFrameWidth()
        end
    end
end

--[[
  Get header height
  @return number - Height of header bar
]]
function headerBar:getHeight()
    return HEADER_HEIGHT
end

-- ============================================================================
-- SORT DIRECTION ARROW
-- ============================================================================

updateSortDirectionArrow = function()
    if not sortDropdown or not sortDropdown.sortDirArrow then return end
    
    if currentSortDir == "asc" then
        sortDropdown.sortDirArrow:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
    else
        sortDropdown.sortDirArrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
    end
end

-- ============================================================================
-- UI CREATION
-- ============================================================================

local function createHeaderButton(parent, text, width, onClick, tooltipText)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, BUTTON_HEIGHT)
    btn:SetText(text)
    btn:SetScript("OnClick", onClick)
    
    if tooltipText then
        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(tooltipText, 1, 1, 1)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return btn
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

--[[
  Initialize header bar
  Creates the header frame and all child controls.
  
  @param parentFrame frame - Parent frame (mainFrame's frame)
  @param listWidth number - Width of pet list section
  @param detailWidth number - Width of detail section
  @param yOffset number - Y offset from parent top (negative)
  @param edgePadding number|nil - Edge padding (defaults to L.EDGE_PADDING)
]]
function headerBar:initialize(parentFrame, listWidth, detailWidth, yOffset, edgePadding)
    if headerFrame then return end
    
    constants = Addon.constants
    events = Addon.events
    petCache = Addon.petCache
    petSorting = Addon.petSorting
    dropdown = Addon.dropdown
    actionButton = Addon.actionButton
    petActions = Addon.petActions
    
    local L = constants.LAYOUT
    local actualEdgePadding = edgePadding or L.EDGE_PADDING
    
    -- Load sort options
    if petSorting then
        sortOptions = petSorting:getSortOptions()
    end
    
    -- Create main header frame
    -- Use explicit width (WoW doesn't derive width synchronously from two-point anchors)
    headerFrame = CreateFrame("Frame", nil, parentFrame)
    headerFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", actualEdgePadding, yOffset)
    headerFrame:SetWidth(parentFrame:GetWidth() - 2 * actualEdgePadding)
    headerFrame:SetHeight(HEADER_HEIGHT)
    
    -- Hook parent resize to update width
    parentFrame:HookScript("OnSizeChanged", function(self, w, h)
        if headerFrame then
            headerFrame:SetWidth(w - 2 * actualEdgePadding)
        end
    end)
    
    -- ========================================
    -- LEFT SECTION (over pet list)
    -- ========================================
    leftSection = CreateFrame("Frame", nil, headerFrame)
    leftSection:SetPoint("TOPLEFT", headerFrame, "TOPLEFT", 0, 0)
    leftSection:SetSize(listWidth, HEADER_HEIGHT)
    
    -- Collection dropdown (icon + text)
    collectionDropdown = dropdown:create({
        parent = leftSection,
        name = "PAOCollectionDropdown",
        width = DROPDOWN_WIDTH,
        title = "Show",
        icon = true,
        options = COLLECTION_OPTIONS,
        defaultValue = currentCollectionFilter,
        tooltip = "Collection Filter\nFilter pets by ownership status",
        onChange = function(value)
            headerBar:setCollectionFilter(value)
        end,
    })
    collectionDropdown:SetPoint("LEFT", leftSection, "LEFT", 0, 0)
    
    -- Sort dropdown (text + direction arrow on left)
    sortDropdown = dropdown:create({
        parent = leftSection,
        name = "PAOSortDropdown",
        width = DROPDOWN_WIDTH,
        title = "Sort By",
        options = sortOptions or {{ value = "name", text = "Name" }},
        defaultValue = currentSort,
        onClick = function(self, button)
            if IsShiftKeyDown() then
                -- Toggle direction on shift+click
                headerBar:setSort(currentSort, currentSortDir == "asc" and "desc" or "asc")
                return false  -- Don't show menu
            end
            return true  -- Show menu
        end,
        onChange = function(value)
            headerBar:setSort(value, currentSortDir)
        end,
    })
    sortDropdown:SetPoint("LEFT", collectionDropdown, "RIGHT", SPACING, 0)
    
    -- Sort direction arrow on left side (custom addition)
    local sortDirArrow = sortDropdown:CreateTexture(nil, "OVERLAY")
    sortDirArrow:SetSize(14, 14)
    sortDirArrow:SetPoint("LEFT", sortDropdown, "LEFT", 4, 0)
    sortDirArrow:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
    sortDropdown.sortDirArrow = sortDirArrow
    
    -- Reposition text to right of direction arrow
    sortDropdown.text:ClearAllPoints()
    sortDropdown.text:SetPoint("LEFT", sortDirArrow, "RIGHT", 4, 0)
    sortDropdown.text:SetPoint("RIGHT", sortDropdown, "RIGHT", -18, 0)
    
    -- Sort tooltip (override factory tooltip)
    sortDropdown:SetScript("OnEnter", function(self)
        -- Trigger hover colors
        self.background:SetColorTexture(0.15, 0.15, 0.15, 0.9)
        self.border:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Sort Options", 1, 1, 1)
        GameTooltip:AddLine("Click: Change sort field", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Shift+Click: Toggle direction", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    sortDropdown:SetScript("OnLeave", function(self)
        self.background:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        self.border:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        GameTooltip:Hide()
    end)
    
    -- Filtered pet count with funnel icon
    local iconSize = 24  -- Fixed size for icons
    funnelIcon = leftSection:CreateTexture(nil, "ARTWORK")
    funnelIcon:SetSize(iconSize, iconSize)
    funnelIcon:SetPoint("LEFT", sortDropdown, "RIGHT", SPACING + 4, 0)
    funnelIcon:SetTexture("Interface\\AddOns\\PawAndOrder\\textures\\filter-funnel.png")
    
    petCountText = leftSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    petCountText:SetPoint("LEFT", funnelIcon, "RIGHT", 4, 0)
    petCountText:SetText("0 / 0")
    
    -- Tooltip frame for filter count
    local filterCountFrame = CreateFrame("Frame", nil, leftSection)
    filterCountFrame:SetPoint("LEFT", funnelIcon, "LEFT", -4, 0)
    filterCountFrame:SetHeight(iconSize + 8)
    
    local function updateFilterCountFrameWidth()
        local textWidth = petCountText:GetStringWidth()
        filterCountFrame:SetWidth(iconSize + textWidth + 12)
    end
    headerBar.updateFilterCountFrameWidth = updateFilterCountFrameWidth
    updateFilterCountFrameWidth()
    
    -- Build dynamic description for base count based on current filter state
    local function getBaseDescription()
        local parts = {"Total"}
        
        -- Collection filter
        if currentCollectionFilter == "owned" then
            table.insert(parts, "owned")
        elseif currentCollectionFilter == "unowned" then
            table.insert(parts, "unowned")
        end
        
        -- Battle/non-battle setting
        local showNonCombat = true
        if Addon.options and Addon.options.GetAll then
            local opts = Addon.options:GetAll()
            if opts then
                showNonCombat = opts.showNonCombatPets ~= false
            end
        end
        if not showNonCombat then
            table.insert(parts, "battle")
        end
        
        table.insert(parts, "pets")
        return table.concat(parts, " ")
    end
    
    filterCountFrame:SetScript("OnEnter", function(self)
        local tip = Addon.tooltip
        if tip then
            tip:show(self, {anchor = "TOPLEFT", relPoint = "BOTTOMLEFT", offsetY = -5})
            tip:header("Filter Results", {color = {1, 0.82, 0}})
            tip:space(4)
            tip:text(string.format("|cff88ff88%d|r - Pets matching current filters", currentFilteredCount), {wrap = true})
            tip:space(2)
            tip:text(string.format("|cff88ccff%d|r - %s", currentBaseCount, getBaseDescription()), {wrap = true})
            tip:done()
        end
    end)
    
    filterCountFrame:SetScript("OnLeave", function()
        if Addon.tooltip then
            Addon.tooltip:hide()
        end
    end)
    
    -- ========================================
    -- RIGHT SECTION (over details)
    -- ========================================
    rightSection = CreateFrame("Frame", nil, headerFrame)
    rightSection:SetPoint("TOPRIGHT", headerFrame, "TOPRIGHT", 0, 0)
    rightSection:SetSize(detailWidth, HEADER_HEIGHT)
    
    -- Button widths for consistent sizing
    local HEADER_BUTTON_WIDTH = 140  -- Accommodate "Bandage (99+)..."
    local BUTTON_RIGHT_PADDING = 12  -- Match ICON_LEFT for consistent side padding
    local BUTTON_VERTICAL_PADDING = 2  -- Top/bottom padding
    
    -- Heal button (rightmost) - uses SecureActionButtonTemplate for spell casting
    -- PreClick sets up spell attributes based on cooldown state
    -- PostClick handles bandage popup when spell is on cooldown
    local HEAL_SPELL_ID = 125439  -- Revive Battle Pets
    
    healBtn = actionButton:create(rightSection, {
        text = "Heal",
        icon = 644389,
        iconSide = "left",
        secure = true,
        secureName = "PAO_HealButton",
        preClick = function(self, mouseButton)
            if mouseButton ~= "LeftButton" then return end
            
            -- Check cooldown state
            local start, duration = GetSpellCooldown(HEAL_SPELL_ID)
            local onCooldown = start and duration and duration > 0 and (start + duration > GetTime())
            
            if not onCooldown then
                -- Spell ready - set up secure spell cast
                self:SetAttribute("type", "spell")
                self:SetAttribute("spell", HEAL_SPELL_ID)
                self._showBandagePopup = false
                self._spellWasCast = true
            else
                -- On cooldown - clear secure action, will handle in PostClick
                self:SetAttribute("type", nil)
                self:SetAttribute("spell", nil)
                self._spellWasCast = false
                
                -- Check if we have bandages
                if petActions and petActions:hasBandages() then
                    self._showBandagePopup = true
                else
                    self._showBandagePopup = false
                    self._showCooldownMessage = true
                end
            end
        end,
        postClick = function(self, mouseButton)
            if mouseButton ~= "LeftButton" then return end
            
            if self._showBandagePopup then
                self._showBandagePopup = false
                if petActions then
                    petActions:showBandageConfirmation()
                end
            elseif self._showCooldownMessage then
                self._showCooldownMessage = false
                if petActions then
                    local start, duration = petActions:getHealCooldown()
                    local remaining = (start + duration) - GetTime()
                    local minutes = math.floor(remaining / 60)
                    local seconds = math.floor(remaining % 60)
                    if Addon.utils then
                        Addon.utils:chat(string.format("Revive Battle Pets on cooldown (%d:%02d). No bandages available.", minutes, seconds))
                    end
                end
            elseif self._spellWasCast then
                -- Spell cast via secure action - emit internal event after delay
                self._spellWasCast = false
                C_Timer.After(0.5, function()
                    if Addon.events then
                        Addon.events:emit("TEAM:PETS_HEALED")
                    end
                end)
            end
        end,
        tooltip = "Heal all battle pets",
        size = "medium",
        style = 1,
        fixedWidth = HEADER_BUTTON_WIDTH,
    })
    healBtn:SetPoint("RIGHT", rightSection, "RIGHT", -BUTTON_RIGHT_PADDING, 0)
    
    -- Override OnEnter to build dynamic tooltip with injured/dead pets
    healBtn:SetScript("OnEnter", function(self)
        -- Apply hover style (from actionButton)
        if self._styleNum and self.bg then
            local style = self._styleNum
            if style == 1 then
                self.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
            elseif style == 2 then
                self.bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)
            elseif style == 3 then
                self.bg:SetColorTexture(0.25, 0.25, 0.25, 0.8)
            end
        end
        
        -- Build dynamic tooltip
        local injuredCount = 0
        local injuredPets = {}
        if Addon.petCache and Addon.petCache:isInitialized() then
            injuredCount = Addon.petCache:getInjuredCount()
            injuredPets = Addon.petCache:getInjuredPets()
        end
        
        -- Get cooldown state
        local onCooldown = false
        if petActions then
            local start, duration = petActions:getHealCooldown()
            onCooldown = start and duration and duration > 0 and (start + duration > GetTime())
        end
        
        -- Determine base text
        local baseText
        if injuredCount == 0 then
            baseText = "No pets need healing"
        elseif onCooldown then
            local hasBandages = petActions and petActions.hasBandages and petActions:hasBandages() or false
            if hasBandages then
                baseText = "Use bandages to heal injured pets\n(Revive Battle Pets on cooldown)"
            else
                baseText = "Revive Battle Pets is on cooldown\nNo bandages available"
            end
        else
            baseText = "Heal all battle pets"
        end
        
        -- Build tooltip
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        
        if injuredCount == 0 then
            GameTooltip:SetText(baseText, 1, 1, 1)
        else
            -- Header in gold
            GameTooltip:SetText(baseText, 1, 0.82, 0)
            GameTooltip:AddLine(" ")  -- Spacing
            
            -- Pet list
            local maxToShow = 5
            local shown = 0
            
            for i, pet in ipairs(injuredPets) do
                if shown >= maxToShow then
                    local remaining = injuredCount - shown
                    GameTooltip:AddLine(string.format("  ...and %d more", remaining), 0.7, 0.7, 0.7)
                    break
                end
                
                local name = pet.customName or pet.name or "Unknown"
                local rarity = pet.rarity or 2
                local rarityColor = constants:GetRarityColor(rarity)
                
                GameTooltip:AddLine("  • " .. name, rarityColor.r, rarityColor.g, rarityColor.b)
                
                shown = shown + 1
            end
        end
        
        GameTooltip:Show()
    end)
    
    healBtn:SetScript("OnLeave", function(self)
        -- Apply normal style (from actionButton)
        if self._styleNum and self.bg then
            local style = self._styleNum
            if style == 1 then
                self.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
            elseif style == 2 then
                self.bg:SetColorTexture(0.05, 0.05, 0.05, 0.8)
            elseif style == 3 then
                self.bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)
            end
        end
        
        GameTooltip:Hide()
    end)
    
    -- Update heal button state (text, enabled)
    local function updateHealButtonState()
        if not petActions or not healBtn then return end
        
        -- Get cooldown info
        local start, duration = petActions:getHealCooldown()
        local onCooldown = start and duration and duration > 0 and (start + duration > GetTime())
        
        -- Get injured pet count from petCache
        local injuredCount = 0
        if Addon.petCache and Addon.petCache:isInitialized() then
            injuredCount = Addon.petCache:getInjuredCount()
        end
        
        -- Format count display
        local countStr = ""
        if injuredCount > 0 then
            if injuredCount > 99 then
                countStr = " (99+)"
            else
                countStr = " (" .. injuredCount .. ")"
            end
        end
        
        -- Check bandage availability
        local hasBandages = petActions.hasBandages and petActions:hasBandages() or false
        
        -- Update button based on state
        if onCooldown then
            -- Spell on cooldown
            healBtn:setCooldown(start, duration)
            
            if injuredCount == 0 then
                healBtn:setText("Heal")
                healBtn:setEnabled(false)
            elseif hasBandages then
                -- Has bandages - show Bandage option
                healBtn:setText("Bandage" .. countStr .. "...")
                healBtn:setEnabled(true)
            else
                -- No bandages - keep Heal text, disabled with cooldown showing
                healBtn:setText("Heal" .. countStr)
                healBtn:setEnabled(false)
            end
        else
            -- Spell ready - show Heal
            healBtn:setText("Heal" .. countStr)
            healBtn:setCooldown(0, 0)
            
            if injuredCount == 0 then
                healBtn:setEnabled(false)
            else
                healBtn:setEnabled(true)
            end
        end
    end
    
    -- Update heal state periodically
    local healStateUpdater = CreateFrame("Frame", nil, rightSection)
    healStateUpdater:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 0.5 then
            self.elapsed = 0
            updateHealButtonState()
        end
    end)
    
    -- Update heal state when window shows (catches state changes while hidden)
    headerFrame:SetScript("OnShow", function()
        updateHealButtonState()
    end)
    
    -- Summon Random button
    -- Icon: Custom random paw icon
    summonRandomBtn = actionButton:create(rightSection, {
        text = "Random",
        icon = "Interface\\AddOns\\PawAndOrder\\textures\\random-paw.png",
        iconSide = "left",
        onClick = function()
            if petActions then
                petActions:summonRandom(false)
            end
        end,
        tooltip = "Summon a random companion pet",
        size = "medium",
        style = 1,
        fixedWidth = HEADER_BUTTON_WIDTH,
    })
    summonRandomBtn:SetPoint("RIGHT", healBtn, "LEFT", -SPACING, 0)
    
    -- Display mode toggle (dev convenience - toggles pets/species without settings)
    local function getModeText()
        local mode = Addon.options and Addon.options:Get("displayMode") or "pets"
        if mode == "species" then return "Species" end
        return "Pets"
    end
    
    modeToggleBtn = actionButton:create(rightSection, {
        text = getModeText(),
        iconSide = "left",
        onClick = function()
            if not Addon.options then return end
            local current = Addon.options:Get("displayMode") or "pets"
            local newMode = (current == "pets") and "species" or "pets"
            Addon.options:Set("displayMode", newMode)
            modeToggleBtn:setText(newMode == "species" and "Species" or "Pets")
        end,
        tooltip = "Toggle display mode (Pets / Species)",
        size = "medium",
        style = 1,
        fixedWidth = 100,
    })
    modeToggleBtn:SetPoint("RIGHT", summonRandomBtn, "LEFT", -SPACING, 0)
    
    -- Initialize direction arrow
    updateSortDirectionArrow()
    
    -- Subscribe to cache events for pet count updates
    if events then
        events:subscribe("CACHE:INITIALIZED", function()
            headerBar:refreshPetCount()
        end)
        events:subscribe("CACHE:COLLECTION_CHANGED", function()
            headerBar:refreshPetCount()
        end)
        
        -- Subscribe to filtered count updates from pet list
        events:subscribe("PETLIST:FILTERED_COUNT", function(eventName, payload)
            if payload then
                headerBar:updateFilteredCount(payload.filtered, payload.base)
            end
        end)
        
        -- Subscribe to heal-related events for button state updates
        events:subscribe("PET_JOURNAL_PETS_HEALED", function(eventName)
            updateHealButtonState()
        end)
        events:subscribe("TEAM:PETS_HEALED", function()
            updateHealButtonState()
        end)
        events:subscribe("PET_BATTLE_OVER", function(eventName)
            C_Timer.After(0.1, updateHealButtonState)
        end)
        
        -- Update heal state when pets tab is shown (catches changes while hidden)
        events:subscribe("TABS:CONTENT_SHOWN", function(eventName, payload)
            if payload and payload.id == "pets" then
                updateHealButtonState()
            end
        end)
    end
    
    -- Initial pet count
    headerBar:refreshPetCount()
    
    -- Initial heal button state
    C_Timer.After(0.1, updateHealButtonState)
end

--[[
  Refresh pet count from cache
  Emits COLLECTION:COUNTS for status bar (owned/total)
]]
function headerBar:refreshPetCount()
    if not petCache then
        petCache = Addon.petCache
    end
    
    if petCache and petCache:isInitialized() then
        local owned = petCache:getOwnedCount()
        local total = petCache:getTotalCount()
        
        -- Emit collection counts for status bar
        if events then
            events:emit("COLLECTION:COUNTS", {
                owned = owned,
                total = total
            })
        end
    end
end

--[[
  Apply default settings from options (called on first show)
  @param opts table - Options from Addon.options:GetAll()
]]
function headerBar:applyDefaults(opts)
    if not opts then return end
    
    -- Apply default collection filter
    local mode = opts.defaultFilterMode or "all"
    currentCollectionFilter = mode
    if collectionDropdown then
        collectionDropdown:SetValue(mode, true)
    end
    
    -- Apply default sort
    currentSort = opts.defaultSort or "name"
    currentSortDir = opts.defaultSortDir or "asc"
    if sortDropdown then
        sortDropdown:SetValue(currentSort, true)
    end
    updateSortDirectionArrow()
end

--[[
  Handle resize - update section widths
  @param listWidth number - New list section width
  @param detailWidth number - New detail section width
]]
function headerBar:onResize(listWidth, detailWidth)
    if leftSection then
        leftSection:SetWidth(listWidth)
    end
    if rightSection then
        rightSection:SetWidth(detailWidth)
    end
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("headerBar", {"constants", "utils", "events", "petSorting", "dropdown", "actionButton", "petActions"}, function()
        return true
    end)
end

Addon.headerBar = headerBar
return headerBar