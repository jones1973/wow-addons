--[[
  ui/achievementList/achRow.lua
  Achievement Row Component (Accordion Style)
  
  Provides expandable achievement rows:
    - Click to expand/collapse inline details
    - Shows description, criteria (with pet collection status), reward
    - Pet name on right side for pet rewards
    - Bigger pet reward icon with hover tooltip
    - Points displayed in shield graphic
    - Animated expand/collapse
  
  Dependencies: achievementData, achievementLogic
  Exports: Addon._achRow (internal module)
]]

local ADDON_NAME, Addon = ...

local achRow = {}

-- Module references
local achievementData, achievementLogic

-- Layout constants
local ROW_HEIGHT_COLLAPSED = 60
local ICON_SIZE = 40
local PET_ICON_SIZE = 28
local POINTS_SIZE = 40  -- Same size as achievement icon
local PADDING = 8
local PROGRESS_BAR_WIDTH = 90
local PROGRESS_BAR_HEIGHT = 8
local EXPANSION_PADDING = 12
local CRITERIA_HORIZONTAL_PADDING = ICON_SIZE / 2  -- Align criteria with center of achievement icon
local CRITERIA_HEIGHT = 26
local CRITERIA_SPACING = 2
local ANIMATION_DURATION = 0.15

-- Track expanded achievement ID (not row reference) for persistence across re-renders
local expandedAchievementId = nil

-- Callback for when expansion changes (to notify list to re-layout)
local onExpansionChanged = nil

-- Callback for navigating to a sub-achievement
local onNavigateToAchievement = nil

-- ============================================================================
-- POINTS SHIELD
-- ============================================================================

local function createPointsShield(parent)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(POINTS_SIZE, POINTS_SIZE)
    
    -- Shield background
    local shield = container:CreateTexture(nil, "ARTWORK")
    shield:SetAllPoints()
    shield:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Shields")
    shield:SetTexCoord(0, 0.5, 0, 0.5)  -- Gold shield (completed)
    container.shield = shield
    
    -- Points text
    local points = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    points:SetPoint("CENTER", -1, 0)
    points:SetTextColor(1, 1, 1)
    container.pointsText = points
    
    function container:SetPoints(pts, completed)
        self.pointsText:SetText(pts or "0")
        -- Use same shield graphic for both, just desaturate for incomplete
        self.shield:SetTexCoord(0, 0.5, 0, 0.5)
        if completed then
            self.shield:SetDesaturated(false)
        else
            self.shield:SetDesaturated(true)
        end
    end
    
    return container
end

-- ============================================================================
-- PET NAME DISPLAY
-- ============================================================================

local function createPetNameDisplay(parent)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(150, 20)
    container:EnableMouse(true)
    
    -- Pet name (right-justified)
    local name = container:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    name:SetPoint("RIGHT", container, "RIGHT", 0, 0)
    name:SetJustifyH("RIGHT")
    container.nameText = name
    
    -- Pet icon (paw print) - to the left of name
    local icon = container:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("RIGHT", name, "LEFT", -4, 0)
    icon:SetTexture("Interface\\Icons\\tracking_wildpet")
    container.icon = icon
    
    -- State
    container.speciesID = nil
    container.petOwned = false
    
    function container:SetPetInfo(speciesID, petName, owned)
        self.speciesID = speciesID
        self.petOwned = owned
        self.petName = petName
        
        if petName then
            self.nameText:SetText(petName)
            if owned then
                self.nameText:SetTextColor(unpack(achievementData.COLORS.PET_NAME_OWNED))
            else
                self.nameText:SetTextColor(unpack(achievementData.COLORS.PET_NAME_MISSING))
            end
            self:Show()
        else
            self:Hide()
        end
    end
    
    -- Hover to show BattlePet tooltip
    container:SetScript("OnEnter", function(self)
        if self.speciesID then
            local petTooltips = Addon.petTooltips
            if petTooltips then
                petTooltips:showForSpecies(self, self.speciesID, {anchor = "right"})
            end
        end
    end)
    
    container:SetScript("OnLeave", function()
        if Addon.petTooltips then
            Addon.petTooltips:hide()
        end
    end)
    
    return container
end

-- ============================================================================
-- EXPANSION CONTENT
-- ============================================================================

local function createExpansionContent(parent)
    local expansion = CreateFrame("Frame", nil, parent)
    expansion:SetPoint("TOPLEFT", parent, "BOTTOMLEFT", 0, 0)
    expansion:SetPoint("TOPRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    expansion:SetHeight(1)  -- Will be resized dynamically
    
    -- Background
    local bg = expansion:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(achievementData.COLORS.EXPANSION_BG))
    
    -- Description (no longer used, but kept for compatibility)
    local desc = expansion:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    desc:SetPoint("TOPLEFT", expansion, "TOPLEFT", EXPANSION_PADDING + ICON_SIZE + PADDING, -EXPANSION_PADDING)
    desc:SetPoint("RIGHT", expansion, "RIGHT", -EXPANSION_PADDING, 0)
    desc:SetJustifyH("LEFT")
    desc:SetTextColor(0.9, 0.9, 0.9)
    desc:SetWordWrap(true)
    desc:Hide()
    expansion.descText = desc
    
    -- Criteria container (positioned directly from expansion top)
    local criteriaFrame = CreateFrame("Frame", nil, expansion)
    criteriaFrame:SetPoint("TOPLEFT", expansion, "TOPLEFT", CRITERIA_HORIZONTAL_PADDING, -EXPANSION_PADDING)
    criteriaFrame:SetPoint("RIGHT", expansion, "RIGHT", -CRITERIA_HORIZONTAL_PADDING, 0)
    expansion.criteriaFrame = criteriaFrame
    
    -- Separator line between incomplete and complete sections
    local separatorLine = criteriaFrame:CreateTexture(nil, "ARTWORK")
    separatorLine:SetHeight(1)
    separatorLine:SetColorTexture(0.5, 0.5, 0.5, 0.8)
    separatorLine:Hide()
    expansion.separatorLine = separatorLine
    
    -- Criteria rows pool
    expansion.criteriaRows = {}
    
    -- Reward button (for tooltip support)
    local rewardButton = CreateFrame("Button", nil, expansion)
    rewardButton:SetHeight(20)
    rewardButton:EnableMouse(true)
    
    local reward = rewardButton:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    reward:SetPoint("LEFT", rewardButton, "LEFT", 0, 0)
    reward:SetJustifyH("LEFT")
    reward:SetTextColor(0.4, 0.7, 1.0)
    rewardButton.text = reward
    
    rewardButton:SetScript("OnEnter", function(self)
        if self.tooltipFunc then
            self.tooltipFunc(self)
        end
    end)
    rewardButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    expansion.rewardButton = rewardButton
    expansion.rewardText = reward  -- Keep reference for compatibility
    
    expansion:Hide()
    return expansion
end

--[[
  Create or reuse a criteria row.
]]
local function getCriteriaRow(expansion, index)
    if expansion.criteriaRows[index] then
        return expansion.criteriaRows[index]
    end
    
    local row = CreateFrame("Button", nil, expansion.criteriaFrame)
    row:SetHeight(CRITERIA_HEIGHT)
    row:RegisterForClicks("LeftButtonUp")
    
    -- Completion indicator (checkmark/x)
    local check = row:CreateTexture(nil, "ARTWORK")
    check:SetSize(14, 14)
    check:SetPoint("LEFT", 0, 0)
    row.checkmark = check
    
    -- Sub-achievement icon (larger, shown for completed sub-achievements)
    local subIcon = row:CreateTexture(nil, "ARTWORK")
    subIcon:SetSize(24, 24)
    subIcon:SetPoint("LEFT", check, "RIGHT", 4, 0)
    subIcon:Hide()
    row.subIcon = subIcon
    
    -- Criteria name (positioned dynamically based on whether subIcon is shown)
    local name = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    name:SetPoint("LEFT", check, "RIGHT", 4, 0)
    name:SetPoint("RIGHT", row, "RIGHT", -50, 0)
    name:SetJustifyH("LEFT")
    name:SetWordWrap(false)
    row.nameText = name
    
    -- Progress/quantity text
    local progress = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    progress:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    progress:SetJustifyH("RIGHT")
    row.progressText = progress
    
    -- State for tooltips and navigation
    row.speciesID = nil
    row.criteriaName = nil
    row.subAchievementId = nil
    row.isSubAchievementTracked = false  -- Is the sub-achievement in PAO's list?
    
    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.subAchievementId then
            GameTooltip:SetHyperlink(GetAchievementLink(self.subAchievementId))
            if self.isSubAchievementTracked then
                GameTooltip:AddLine("Click to scroll to achievement", 0.7, 0.7, 0.7)
            else
                GameTooltip:AddLine("Click to open Achievement Window", 0.7, 0.7, 0.7)
            end
            GameTooltip:Show()
        elseif self.speciesID and self.criteriaName then
            GameTooltip:SetText(self.criteriaName, 1, 1, 1)
            
            if self.petOwned then
                GameTooltip:AddLine("Collected", 0.4, 0.8, 0.4)
            else
                GameTooltip:AddLine("Not Collected", 0.8, 0.4, 0.4)
                
                -- Show source location only for uncollected pets
                local speciesName, speciesIcon, petType, creatureID, sourceText = 
                    C_PetJournal.GetPetInfoBySpeciesID(self.speciesID)
                if sourceText and sourceText ~= "" then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(sourceText, 1, 1, 1, true)  -- true for word wrap
                end
            end
            
            GameTooltip:Show()
        elseif self.fullDisplayName and self.nameText then
            -- Show tooltip if text is truncated
            local displayedWidth = self.nameText:GetStringWidth()
            local availableWidth = self.nameText:GetWidth()
            if displayedWidth > availableWidth then
                GameTooltip:SetText(self.fullDisplayName, 1, 1, 1)
                GameTooltip:Show()
            end
        end
    end)
    row:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function(self)
        if self.subAchievementId then
            if self.isSubAchievementTracked and onNavigateToAchievement then
                onNavigateToAchievement(self.subAchievementId)
            else
                -- Open Blizzard's Achievement UI and navigate to this achievement
                if not AchievementFrame then
                    AchievementFrame_LoadUI()
                end
                if AchievementFrame then
                    AchievementFrame_SelectAchievement(self.subAchievementId)
                end
            end
        end
    end)
    
    expansion.criteriaRows[index] = row
    return row
end

--[[
  Populate expansion content for an achievement.
  Returns the calculated height, or 0 if expansion has no content.
]]
local function populateExpansion(expansion, achievement)
    local height = EXPANSION_PADDING
    
    -- Criteria
    local criteria = achievement.criteria or {}
    local criteriaHeight = 0
    
    -- Skip criteria display for single non-sub-achievement criteria
    -- (the description already tells you what to do)
    local showCriteria = true
    if #criteria == 1 and not criteria[1].isSubAchievement then
        showCriteria = false
    end
    
    -- Separate criteria into incomplete and completed
    local incomplete = {}
    local completed = {}
    for i, c in ipairs(criteria) do
        if c.completed then
            table.insert(completed, c)
        else
            table.insert(incomplete, c)
        end
    end
    
    -- Sort both alphabetically
    local function sortAlpha(a, b)
        return (a.name or "") < (b.name or "")
    end
    table.sort(incomplete, sortAlpha)
    table.sort(completed, sortAlpha)
    
    -- Hide all existing rows first
    for _, row in ipairs(expansion.criteriaRows) do
        row:Hide()
        row:ClearAllPoints()
    end
    
    -- Reset separator line
    expansion.separatorLine:Hide()
    
    -- Only render criteria if we should show them
    if showCriteria and (#incomplete > 0 or #completed > 0) then
        local frameWidth = expansion:GetWidth() - CRITERIA_HORIZONTAL_PADDING * 2
        local columnGap = 8
        local checkmarkWidth = 14 + 4  -- checkmark (14px) + padding
        local subIconWidth = 24 + 4    -- sub-achievement icon (24px) + padding
        local textPadding = 8          -- padding after text
        local rowIndex = 0
        
        -- Create measurement FontString if needed (must match nameText font)
        if not expansion.measureText then
            expansion.measureText = expansion:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            expansion.measureText:Hide()
        end
        
        -- Helper: build display text for a criteria
        local function getDisplayText(c, isComplete)
            local text = c.name or ""
            if not isComplete and c.required and c.required > 1 then
                text = text .. " (" .. (c.quantity or 0) .. "/" .. c.required .. ")"
            end
            return text
        end
        
        -- Helper: measure text width
        local function measureText(text)
            expansion.measureText:SetText(text)
            return expansion.measureText:GetStringWidth()
        end
        
        -- Helper: calculate number of columns for a section based on item count and estimated fit
        -- Returns: numColumns
        local function calcNumColumns(items, isComplete)
            if #items == 0 then return 1 end
            
            -- Measure max text width across all items (for fit estimation)
            local maxTextWidth = 0
            for _, c in ipairs(items) do
                local text = getDisplayText(c, isComplete)
                local width = measureText(text)
                if c.isSubAchievement then
                    width = width + subIconWidth
                end
                maxTextWidth = math.max(maxTextWidth, width)
            end
            
            -- Estimated column width for fit calculation
            local estColumnWidth = checkmarkWidth + maxTextWidth + textPadding
            
            -- How many columns CAN fit?
            local maxPossibleColumns = math.max(1, math.floor((frameWidth + columnGap) / (estColumnWidth + columnGap)))
            
            -- How many columns SHOULD we use based on item count thresholds?
            local desiredColumns = 1
            local itemCount = #items
            if itemCount > 6 then
                desiredColumns = 4
            elseif itemCount > 4 then
                desiredColumns = 3
            elseif itemCount > 2 then
                desiredColumns = 2
            end
            
            -- Use the lesser of desired and max possible
            return math.min(desiredColumns, maxPossibleColumns)
        end
        
        -- Helper: render a section of criteria (column-major) with variable column widths
        -- Returns: rowIndex (updated), sectionHeight
        local function renderSection(items, isComplete, startRowIndex, yOffset)
            if #items == 0 then return startRowIndex, 0 end
            
            local MIN_COLUMN_WIDTH = 80  -- Prevent overly narrow columns
            
            -- Helper: distribute items into N columns and measure their widths
            -- Returns: columns table, columnWidths table, totalWidth
            local function distributeAndMeasure(numCols)
                local cols = {}
                for col = 1, numCols do
                    cols[col] = {}
                end
                local perColumn = math.ceil(#items / numCols)
                for i, c in ipairs(items) do
                    local itemIndex = i - 1
                    local col = math.floor(itemIndex / perColumn) + 1
                    col = math.min(col, numCols)
                    table.insert(cols[col], c)
                end
                
                local widths = {}
                local total = 0
                for col = 1, numCols do
                    local maxTextWidth = 0
                    for _, c in ipairs(cols[col]) do
                        local text = getDisplayText(c, isComplete)
                        local width = measureText(text)
                        if c.isSubAchievement then
                            width = width + subIconWidth
                        end
                        maxTextWidth = math.max(maxTextWidth, width)
                    end
                    widths[col] = math.max(MIN_COLUMN_WIDTH, checkmarkWidth + maxTextWidth + textPadding)
                    total = total + widths[col]
                end
                -- Add gaps between columns
                if numCols > 1 then
                    total = total + (numCols - 1) * columnGap
                end
                
                return cols, widths, total
            end
            
            -- Start with calculated number of columns
            local numColumns = calcNumColumns(items, isComplete)
            local columns, columnWidths, totalWidth = distributeAndMeasure(numColumns)
            local itemsPerColumn = math.ceil(#items / numColumns)
            
            -- Keep adding columns while they fit (max = one column per item)
            while numColumns < #items do
                local extraCols, extraWidths, extraTotal = distributeAndMeasure(numColumns + 1)
                if extraTotal <= frameWidth then
                    -- Extra column fits! Use it and try another.
                    numColumns = numColumns + 1
                    columns = extraCols
                    columnWidths = extraWidths
                    totalWidth = extraTotal
                    itemsPerColumn = math.ceil(#items / numColumns)
                else
                    -- Doesn't fit, stop trying
                    break
                end
            end
            
            local numRows = itemsPerColumn
            
            -- Calculate cumulative x offsets for each column
            local columnXOffsets = {}
            local xPos = 0
            for col = 1, numColumns do
                columnXOffsets[col] = xPos
                xPos = xPos + columnWidths[col] + columnGap
            end
            
            -- Render items
            local localRowIndex = startRowIndex
            
            for i, c in ipairs(items) do
                localRowIndex = localRowIndex + 1
                local row = getCriteriaRow(expansion, localRowIndex)
                row:ClearAllPoints()
                
                -- Column-major: fill down columns first, then across
                local itemIndex = i - 1  -- 0-based
                local col = math.floor(itemIndex / itemsPerColumn) + 1
                col = math.min(col, numColumns)
                local rowNum = itemIndex % itemsPerColumn
                
                row:SetWidth(columnWidths[col])
                
                local xOffset = columnXOffsets[col]
                local yPos = yOffset + (rowNum * (CRITERIA_HEIGHT + CRITERIA_SPACING))
                
                row:SetPoint("TOPLEFT", expansion.criteriaFrame, "TOPLEFT", xOffset, -yPos)
                
                -- Checkmark
                row.checkmark:Show()
                if isComplete then
                    row.checkmark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
                    row.checkmark:SetVertexColor(1, 1, 1)
                else
                    row.checkmark:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
                    row.checkmark:SetVertexColor(0.6, 0.6, 0.6)
                end
                
                -- Sub-achievement icon
                row.nameText:ClearAllPoints()
                if c.isSubAchievement and c.subAchievement then
                    row.subIcon:SetTexture(c.subAchievement.icon)
                    row.subIcon:SetDesaturated(not isComplete)
                    row.subIcon:Show()
                    row.nameText:SetPoint("LEFT", row.subIcon, "RIGHT", 4, 0)
                    row.subAchievementId = c.subAchievementId
                    -- Check if this sub-achievement is in PAO's tracked list
                    row.isSubAchievementTracked = achievementLogic and achievementLogic:getAchievement(c.subAchievementId) ~= nil
                else
                    row.subIcon:Hide()
                    row.nameText:SetPoint("LEFT", row.checkmark, "RIGHT", 4, 0)
                    row.subAchievementId = nil
                    row.isSubAchievementTracked = false
                end
                row.nameText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                
                -- Build display name with progress for incomplete
                local displayName = getDisplayText(c, isComplete)
                row.nameText:SetText(displayName)
                
                -- Store full name for tooltip if truncated
                row.fullDisplayName = displayName
                
                if isComplete then
                    row.nameText:SetTextColor(unpack(achievementData.COLORS.CRITERIA_COMPLETE))
                else
                    row.nameText:SetTextColor(unpack(achievementData.COLORS.CRITERIA_INCOMPLETE))
                end
                
                -- Hide the separate progress text (now inline)
                row.progressText:Hide()
                
                -- Pet tooltip support
                row.speciesID = c.speciesID
                row.criteriaName = c.name
                row.petOwned = c.petOwned
                
                row:Show()
            end
            
            -- Section height
            local sectionHeight = numRows * (CRITERIA_HEIGHT + CRITERIA_SPACING)
            
            return localRowIndex, sectionHeight
        end
        
        -- Render incomplete section first (at top)
        local incompleteHeight = 0
        rowIndex, incompleteHeight = renderSection(incomplete, false, rowIndex, 0)
        
        -- Add separator line if both sections have items
        local separatorGap = 0
        if #incomplete > 0 and #completed > 0 then
            separatorGap = 13  -- Gap: 4px above line + 1px line + 8px below
            expansion.separatorLine:ClearAllPoints()
            expansion.separatorLine:SetPoint("TOPLEFT", expansion.criteriaFrame, "TOPLEFT", 0, -(incompleteHeight + 4))
            expansion.separatorLine:SetPoint("TOPRIGHT", expansion.criteriaFrame, "TOPRIGHT", 0, -(incompleteHeight + 4))
            expansion.separatorLine:Show()
        else
            expansion.separatorLine:Hide()
        end
        
        -- Render completed section below incomplete
        local completedHeight = 0
        rowIndex, completedHeight = renderSection(completed, true, rowIndex, incompleteHeight + separatorGap)
        
        criteriaHeight = incompleteHeight + separatorGap + completedHeight
    end  -- end if showCriteria
    
    expansion.criteriaFrame:SetHeight(criteriaHeight)
    height = height + criteriaHeight
    
    -- Hide reward in expansion (rewards are shown in row preview area)
    expansion.rewardButton:Hide()
    
    height = height + EXPANSION_PADDING
    
    return height
end

--[[
  Check if an achievement has expansion content worth showing.
  Returns true if there are criteria to display.
  (Rewards are shown in the row preview, not expansion)
]]
local function hasExpansionContent(achievement)
    local criteria = achievement.criteria or {}
    
    -- Check if criteria should be shown
    if #criteria > 1 then
        return true
    elseif #criteria == 1 and criteria[1].isSubAchievement then
        return true
    end
    
    return false
end

-- ============================================================================
-- ROW MIXIN
-- ============================================================================

local AchievementRowMixin = {}

function AchievementRowMixin:SetAchievement(achievement)
    self.achievement = achievement
    
    -- Check if this achievement should be expanded (restore state after re-render)
    local shouldBeExpanded = (expandedAchievementId == achievement.id)
    
    -- Icon
    if self.icon then
        self.icon:SetTexture(achievement.icon)
        if achievement.completed then
            self.icon:SetDesaturated(false)
            self.icon:SetVertexColor(1, 1, 1)
        else
            self.icon:SetDesaturated(true)
            self.icon:SetVertexColor(0.8, 0.8, 0.8)
        end
    end
    
    -- Name
    if self.nameText then
        self.nameText:SetText(achievement.name)
        local r, g, b = achievementData:getStateColor(achievement.completed, achievement.progress > 0)
        self.nameText:SetTextColor(r, g, b)
    end
    
    -- Description preview (full description, wraps)
    if self.descPreview then
        self.descPreview:SetText(achievement.description or "")
    end
    
    -- Points shield
    if self.pointsShield then
        self.pointsShield:SetPoints(achievement.points or 0, achievement.completed)
    end
    
    -- Progress bar (only for incomplete with progress)
    if self.progressBar then
        if achievement.completed then
            -- Completed - hide bar
            self.progressBar:Hide()
            if self.progressText then
                self.progressText:Hide()
            end
        elseif achievement.userOwnsPet then
            -- Pet owned but achievement not complete - hide bar, show text
            self.progressBar:Hide()
            if self.progressText then
                self.progressText:SetText("Pet Owned")
                self.progressText:SetTextColor(0.4, 0.8, 0.4)
                self.progressText:Show()
            end
        elseif achievement.hasQuantityProgress or achievement.totalCriteria > 1 then
            -- In progress
            self.progressBar:Show()
            self.progressBar:SetMinMaxValues(0, 1)
            self.progressBar:SetValue(achievement.progress)
            self.progressBar:SetStatusBarColor(unpack(achievementData.COLORS.PROGRESS_FILL))
            
            if self.progressText then
                if achievement.hasQuantityProgress then
                    self.progressText:SetText(string.format("%d / %d", 
                        achievement.totalQuantity or 0, achievement.totalRequired or 0))
                else
                    self.progressText:SetText(string.format("%d / %d", 
                        achievement.completedCriteria, achievement.totalCriteria))
                end
                self.progressText:SetTextColor(0.8, 0.8, 0.8)
                self.progressText:Show()
            end
        else
            -- No progress tracking (single criteria)
            self.progressBar:Hide()
            if self.progressText then
                self.progressText:Hide()
            end
        end
    end
    
    -- Pet name display (right side, only if pet reward)
    -- Title display (right side, only if title reward, mutually exclusive with pet)
    if self.petNameDisplay then
        if achievement.isPetReward and achievement.rewardText then
            local petName = achievementData:parsePetNameFromReward(achievement.rewardText)
            self.petNameDisplay:SetPetInfo(achievement.speciesID, petName, achievement.userOwnsPet)
            if self.titleDisplay then self.titleDisplay:Hide() end
            if self.rewardDisplay then self.rewardDisplay:Hide() end
        elseif achievement.isTitleReward and achievement.rewardText then
            self.petNameDisplay:Hide()
            if self.rewardDisplay then self.rewardDisplay:Hide() end
            if self.titleDisplay then
                local titleName = achievementData:parseTitleFromReward(achievement.rewardText)
                if titleName then
                    -- Apply gender formatting
                    local displayTitle = titleName
                    if titleName:find("/") then
                        local playerSex = UnitSex("player")  -- 1=unknown, 2=male, 3=female
                        if playerSex == 3 then  -- Female
                            displayTitle = titleName:gsub("/[^%s]+", "")
                        else  -- Male or unknown
                            displayTitle = titleName:gsub("[^%s]+/", "")
                        end
                    end
                    
                    self.titleDisplay.text:SetText(displayTitle)
                    self.titleDisplay.titleName = titleName  -- Keep original for tooltip logic
                    self.titleDisplay.achievementName = achievement.name
                    self.titleDisplay:Show()
                else
                    self.titleDisplay:Hide()
                end
            end
        else
            self.petNameDisplay:Hide()
            if self.titleDisplay then self.titleDisplay:Hide() end
            
            -- Generic reward (not pet or title)
            if self.rewardDisplay then
                if achievement.rewardText and achievement.rewardText ~= "" then
                    -- Clean the reward text (strip "Reward:" etc)
                    local cleanedText = achievementData:cleanRewardText(achievement.rewardText)
                    self.rewardDisplay.text:SetText(cleanedText)
                    self.rewardDisplay.rewardString = cleanedText
                    
                    -- Check if it's an unlock reward
                    self.rewardDisplay.isUnlock = achievementData:isUnlockReward(achievement.rewardText)
                    
                    -- Get item ID if known
                    self.rewardDisplay.itemID = achievementData:getRewardItemID(achievement.rewardText)
                    
                    -- Set appropriate icon
                    local icon = achievementData:getRewardIcon(achievement.rewardText)
                    self.rewardDisplay.icon:SetTexture(icon)
                    
                    -- Set color based on reward type and completion
                    local color = achievementData:getRewardColor(achievement.rewardText, achievement.completed)
                    self.rewardDisplay.text:SetTextColor(unpack(color))
                    
                    self.rewardDisplay:Show()
                else
                    self.rewardDisplay:Hide()
                end
            end
        end
    end
    
    -- Completion date (under trophy icon)
    if self.dateText then
        if achievement.completed and achievement.completionDate then
            self.dateText:SetText(achievement.completionDate)
            self.dateText:Show()
        else
            self.dateText:Hide()
        end
    end
    
    -- Handle expansion state
    local canExpand = hasExpansionContent(achievement)
    
    if shouldBeExpanded and canExpand then
        self.isExpanded = true
        -- Load details on-demand if not already loaded
        if achievementLogic and not achievement.detailsLoaded then
            achievementLogic:loadDetailsFor(achievement)
        end
        if self.expansion then
            local expansionHeight = populateExpansion(self.expansion, achievement)
            self.expansion:SetHeight(expansionHeight)
            self.expansionHeight = expansionHeight
            self.expansion:Show()
        end
        self.background:SetColorTexture(unpack(achievementData.COLORS.ROW_BG_EXPANDED))
    else
        self.isExpanded = false
        self.expansionHeight = 0
        if self.expansion then
            self.expansion:Hide()
        end
        self.background:SetColorTexture(unpack(achievementData.COLORS.ROW_BG_NORMAL))
    end
    
    -- Expand indicator (hide if no content to expand)
    if self.expandIndicator then
        if canExpand then
            self.expandIndicator:Show()
            self:UpdateExpandIndicator()
        else
            self.expandIndicator:Hide()
        end
    end
    
    -- Track if this row can expand
    self.canExpand = canExpand
end

function AchievementRowMixin:UpdateExpandIndicator()
    if self.expandIndicator then
        if self.isExpanded then
            self.expandIndicator:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
        else
            self.expandIndicator:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
        end
    end
end

function AchievementRowMixin:Expand()
    if self.isExpanded then return end
    if not self.achievement then return end
    if not self.canExpand then return end  -- No content to show
    
    self.isExpanded = true
    expandedAchievementId = self.achievement.id
    
    -- Load details on-demand if not already loaded
    if achievementLogic and not self.achievement.detailsLoaded then
        achievementLogic:loadDetailsFor(self.achievement)
    end
    
    -- Populate and show expansion
    if self.expansion then
        local expansionHeight = populateExpansion(self.expansion, self.achievement)
        self.expansion:SetHeight(expansionHeight)
        self.expansionHeight = expansionHeight
        self.expansion:Show()
    end
    
    self:UpdateExpandIndicator()
    self.background:SetColorTexture(unpack(achievementData.COLORS.ROW_BG_EXPANDED))
    
    if onExpansionChanged then
        onExpansionChanged(self, true)
    end
end

function AchievementRowMixin:Collapse()
    if not self.isExpanded then return end
    
    self.isExpanded = false
    if self.achievement and expandedAchievementId == self.achievement.id then
        expandedAchievementId = nil
    end
    
    if self.expansion then
        self.expansion:Hide()
    end
    self.expansionHeight = 0
    
    self:UpdateExpandIndicator()
    self.background:SetColorTexture(unpack(achievementData.COLORS.ROW_BG_NORMAL))
    
    if onExpansionChanged then
        onExpansionChanged(self, false)
    end
end

function AchievementRowMixin:Toggle()
    if self.isExpanded then
        self:Collapse()
    else
        self:Expand()
    end
end

function AchievementRowMixin:GetTotalHeight()
    if self.isExpanded then
        return ROW_HEIGHT_COLLAPSED + (self.expansionHeight or 0)
    end
    return ROW_HEIGHT_COLLAPSED
end

function AchievementRowMixin:OnEnter()
    if self.highlight and not self.isExpanded then
        self.highlight:Show()
    end
end

function AchievementRowMixin:OnLeave()
    if self.highlight then
        self.highlight:Hide()
    end
end

function AchievementRowMixin:OnClick(button)
    if button == "LeftButton" then
        if IsShiftKeyDown() then
            local link = GetAchievementLink(self.achievement.id)
            if link then
                ChatEdit_InsertLink(link)
            end
        else
            self:Toggle()
        end
    end
end

-- ============================================================================
-- ROW CREATION
-- ============================================================================

function achRow:createRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT_COLLAPSED)
    
    -- Background
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("TOPLEFT")
    bg:SetPoint("TOPRIGHT")
    bg:SetHeight(ROW_HEIGHT_COLLAPSED)
    bg:SetColorTexture(unpack(achievementData.COLORS.ROW_BG_NORMAL))
    row.background = bg
    
    -- Highlight
    local highlight = row:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(bg)
    highlight:SetColorTexture(unpack(achievementData.COLORS.ROW_BG_HOVER))
    highlight:Hide()
    row.highlight = highlight
    
    -- Expand indicator (left side)
    local expandIndicator = row:CreateTexture(nil, "ARTWORK")
    expandIndicator:SetSize(14, 14)
    expandIndicator:SetPoint("LEFT", row, "LEFT", 4, 0)
    expandIndicator:SetTexture("Interface\\Buttons\\UI-PlusButton-Up")
    row.expandIndicator = expandIndicator
    
    -- Icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", expandIndicator, "RIGHT", 4, 0)
    row.icon = icon
    
    -- Icon border
    local iconBorder = row:CreateTexture(nil, "OVERLAY")
    iconBorder:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    iconBorder:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    iconBorder:SetTexture("Interface\\Common\\WhiteIconFrame")
    row.iconBorder = iconBorder
    
    -- Name
    local nameText = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", PADDING, -2)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    row.nameText = nameText
    
    -- Progress bar (inline after name)
    local progressBar = CreateFrame("StatusBar", nil, row)
    progressBar:SetSize(PROGRESS_BAR_WIDTH, PROGRESS_BAR_HEIGHT)
    progressBar:SetPoint("LEFT", nameText, "RIGHT", 8, 0)
    progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progressBar:SetStatusBarColor(unpack(achievementData.COLORS.PROGRESS_FILL))
    
    local progressBg = progressBar:CreateTexture(nil, "BACKGROUND")
    progressBg:SetAllPoints()
    progressBg:SetColorTexture(unpack(achievementData.COLORS.PROGRESS_BG))
    
    row.progressBar = progressBar
    
    -- Progress text (after progress bar)
    local progressText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    progressText:SetPoint("LEFT", progressBar, "RIGHT", 4, 0)
    progressText:SetTextColor(0.8, 0.8, 0.8)
    row.progressText = progressText
    
    -- Description preview (second line, under name - wraps)
    local descPreview = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    descPreview:SetPoint("TOPLEFT", icon, "TOPRIGHT", PADDING, -21)  -- 3px gap from name (was -18)
    descPreview:SetPoint("RIGHT", row, "RIGHT", -140, 0)
    descPreview:SetJustifyH("LEFT")
    descPreview:SetWordWrap(true)
    descPreview:SetMaxLines(2)
    descPreview:SetTextColor(0.7, 0.7, 0.7)
    row.descPreview = descPreview
    
    -- Points shield (right side)
    local pointsShield = createPointsShield(row)
    pointsShield:SetPoint("RIGHT", row, "RIGHT", -PADDING, 6)
    row.pointsShield = pointsShield
    
    -- Completion date (under trophy icon)
    -- Completion date (bottom right, under trophy area)
    local dateText = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    dateText:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", -PADDING, 4)
    dateText:SetTextColor(0.5, 0.8, 0.5)
    dateText:Hide()
    row.dateText = dateText
    
    -- Pet name display (right-justified to trophy)
    local petNameDisplay = createPetNameDisplay(row)
    petNameDisplay:SetPoint("RIGHT", pointsShield, "LEFT", -8, 0)
    row.petNameDisplay = petNameDisplay
    
    -- Title display (button with tooltip, right-justified to trophy)
    local titleDisplay = CreateFrame("Button", nil, row)
    titleDisplay:SetSize(150, 20)
    titleDisplay:EnableMouse(true)
    
    -- Title text (right side of container)
    local titleText = titleDisplay:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    titleText:SetPoint("RIGHT", titleDisplay, "RIGHT", 0, 0)
    titleText:SetTextColor(1.0, 0.82, 0.0)
    titleText:SetJustifyH("RIGHT")
    titleDisplay.text = titleText
    
    -- Title icon (scroll) - to the LEFT of text
    local titleIcon = titleDisplay:CreateTexture(nil, "ARTWORK")
    titleIcon:SetSize(18, 18)
    titleIcon:SetPoint("RIGHT", titleText, "LEFT", -4, 0)
    titleIcon:SetTexture("Interface\\ICONS\\INV_Misc_Note_01")
    titleDisplay.icon = titleIcon
    
    titleDisplay.titleName = nil
    titleDisplay.achievementName = nil
    
    titleDisplay:SetScript("OnEnter", function(self)
        if self.titleName then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Title Preview", 1, 0.82, 0)
            
            local playerName = UnitName("player") or "Player"
            local playerSex = UnitSex("player")  -- 1=unknown, 2=male, 3=female
            local titleName = self.titleName
            
            -- Handle gendered titles (e.g., "the Crazy Cat Lady/Man")
            if titleName:find("/") then
                local femaleVariant, maleVariant = titleName:match("(.+)/(.+)")
                if femaleVariant and maleVariant then
                    -- Find the gendered word and replace
                    if playerSex == 3 then  -- Female
                        -- Keep first part before /
                        titleName = titleName:gsub("/[^%s]+", "")
                    else  -- Male or unknown
                        -- Replace with second part after /
                        titleName = titleName:gsub("[^%s]+/", "")
                    end
                end
            end
            
            -- Detect prefix vs suffix title
            -- "The" or "the" at start = suffix title
            local preview
            if titleName:match("^[Tt]he%s") then
                -- Suffix: "Janstorm the Explorer"
                preview = playerName .. " " .. titleName:gsub("^The%s", "the ")
            else
                -- Prefix: "Ambassador Janstorm"
                preview = titleName .. " " .. playerName
            end
            
            GameTooltip:AddLine(preview, 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    titleDisplay:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    titleDisplay:SetPoint("RIGHT", pointsShield, "LEFT", -8, 0)
    titleDisplay:Hide()
    row.titleDisplay = titleDisplay
    
    -- Generic reward display (for non-pet/non-title rewards)
    local rewardDisplay = CreateFrame("Button", nil, row)
    rewardDisplay:SetSize(200, 20)
    rewardDisplay:EnableMouse(true)
    
    -- Reward text (right side of container)
    local rewardText = rewardDisplay:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    rewardText:SetPoint("RIGHT", rewardDisplay, "RIGHT", 0, 0)
    rewardText:SetTextColor(0.4, 0.7, 1.0)  -- Reward blue
    rewardText:SetJustifyH("RIGHT")
    rewardDisplay.text = rewardText
    
    -- Reward icon - to the LEFT of text
    local rewardIcon = rewardDisplay:CreateTexture(nil, "ARTWORK")
    rewardIcon:SetSize(18, 18)
    rewardIcon:SetPoint("RIGHT", rewardText, "LEFT", -4, 0)
    rewardDisplay.icon = rewardIcon
    
    rewardDisplay.rewardString = nil
    rewardDisplay.isUnlock = false
    rewardDisplay.itemID = nil
    
    rewardDisplay:SetScript("OnEnter", function(self)
        if self.rewardString then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            
            if self.isUnlock then
                -- Unlock-type reward
                GameTooltip:SetText("Unlocks", 1, 0.82, 0)
                GameTooltip:AddLine(self.rewardString, 1, 1, 1)
            elseif self.itemID then
                -- Item reward - try to show item tooltip
                GameTooltip:SetItemByID(self.itemID)
            else
                GameTooltip:SetText(self.rewardString, 1, 1, 1)
            end
            GameTooltip:Show()
        end
    end)
    rewardDisplay:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    rewardDisplay:SetPoint("RIGHT", pointsShield, "LEFT", -8, 0)
    rewardDisplay:Hide()
    row.rewardDisplay = rewardDisplay
    
    -- Expansion content
    local expansion = createExpansionContent(row)
    row.expansion = expansion
    
    -- State
    row.isExpanded = false
    row.expansionHeight = 0
    
    -- Apply mixin
    Mixin(row, AchievementRowMixin)
    
    -- Scripts
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:SetScript("OnEnter", row.OnEnter)
    row:SetScript("OnLeave", row.OnLeave)
    row:SetScript("OnClick", row.OnClick)
    
    -- Repopulate expansion when row width changes (for resize handling)
    row:SetScript("OnSizeChanged", function(self, width, height)
        if self.isExpanded and self.expansion and self.achievement then
            local expansionHeight = populateExpansion(self.expansion, self.achievement)
            self.expansion:SetHeight(expansionHeight)
            self.expansionHeight = expansionHeight
        end
    end)
    
    return row
end

function achRow:getRowHeight()
    return ROW_HEIGHT_COLLAPSED
end

function achRow:setOnExpansionChanged(callback)
    onExpansionChanged = callback
end

function achRow:setOnNavigateToAchievement(callback)
    onNavigateToAchievement = callback
end

function achRow:collapseAll()
    expandedAchievementId = nil
end

function achRow:initialize(deps)
    achievementData = deps.achievementData
    achievementLogic = deps.achievementLogic
end

-- Self-register
if Addon.registerModule then
    Addon.registerModule("_achRow", {"petTooltips"}, function()
        return true
    end)
end

Addon.achRow = achRow
return achRow