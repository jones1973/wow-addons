--[[
  ui/levelingQueue/levelingPreview.lua
  Leveling Preview Panel
  
  LIVE MODE:
    - Compact hero with 3D model
    - Stats summary
    - Queue flow text
    - Scrollable pet list (coming up)
    - Pin section
  
  EDIT MODE:
    - Match count
    - Level/Family/Rarity distribution bars
    - Scrollable pet list preview
    - Empty state with hint
  
  Uses petRowButton for consistent pet row display.
  
  Dependencies: utils, events, constants, levelingLogic, petCache, petRowButton
  Exports: Addon.levelingPreview
]]

local ADDON_NAME, Addon = ...

local levelingPreview = {}

-- Module references
local utils, events, constants, levelingLogic, petCache, petRowButton, actionButton, slotPicker

-- Layout constants
local LAYOUT = {
    PADDING = 12,
    SECTION_GAP = 12,
    LIST_LABEL_GAP = 3,  -- Gap below "Coming Up" label
    
    -- Hero
    HERO_MODEL_SIZE = 90,
    HERO_TEXT_GAP = 4,
    
    -- Bars
    BAR_HEIGHT = 14,
    BAR_GAP = 3,
    
    -- Colors
    MUTED = {0.5, 0.5, 0.5},
    GOLD = {1, 0.82, 0},
    SECTION_LABEL = {0.9, 0.85, 0.7},  -- Warm off-white
    BAR_BG = {0.15, 0.15, 0.18, 1},
    BAR_FILL_LEVEL = {0.7, 0.5, 0.2, 1},
    BAR_FILL_FAMILY = {0.35, 0.5, 0.35, 1},
    BAR_FILL_RARE = {0.3, 0.5, 0.8, 1},
    
    -- Caption spacing
    CAPTION_TOP = 3,
    CAPTION_BOTTOM = 3,
}

-- Level buckets
local LEVEL_BUCKETS = {
    {min = 1, max = 5, label = "1-5"},
    {min = 6, max = 10, label = "6-10"},
    {min = 11, max = 15, label = "11-15"},
    {min = 16, max = 20, label = "16-20"},
    {min = 21, max = 24, label = "21-24"},
}

-- UI state
local parentFrame = nil
local editingQueueId = nil

-- Live mode elements
local liveContainer = nil
local heroIconFrame = nil
local heroIcon = nil
local heroName = nil
local heroDetail = nil
local heroSource = nil
local heroSlotBtn = nil
local liveStatsText = nil
local liveScrollFrame = nil
local liveScrollChild = nil
local liveRows = {}
local pinSection = nil

-- Live distribution elements (collapsible)
local liveDistExpanded = false
local liveDistContainer = nil
local liveDistToggle = nil
local liveLevelBars = {}
local liveFamilyBars = {}
local liveRarityBar = nil
local liveDistHeight = 0  -- Calculated height when expanded

-- Edit mode elements
local editContainer = nil
local matchCount = nil
local matchLabel = nil
local levelBars = {}
local familyBars = {}
local familyLabel = nil
local rarityBar = nil
local rarityLabel = nil
local previewSeparator = nil
local previewLabel = nil
local editScrollFrame = nil
local editScrollChild = nil
local editRows = {}
local emptyStateFrame = nil

-- Edit mode positioning (for dynamic flow)
local familyBaseY = 0  -- Y where family bars start

-- ============================================================================
-- HORIZONTAL BAR COMPONENT
-- ============================================================================

local function createBar(parent, height)
    local bar = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bar:SetHeight(height)
    bar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    bar:SetBackdropColor(unpack(LAYOUT.BAR_BG))
    
    local fill = bar:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT")
    fill:SetPoint("BOTTOMLEFT")
    fill:SetTexture("Interface\\Buttons\\WHITE8x8")
    bar.fill = fill
    
    local label = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", bar, "LEFT", 4, 0)
    label:SetTextColor(0.9, 0.9, 0.9)
    bar.label = label
    
    -- Percentage column (rightmost)
    local pctLabel = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pctLabel:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    pctLabel:SetWidth(32)
    pctLabel:SetJustifyH("RIGHT")
    pctLabel:SetTextColor(0.6, 0.6, 0.6)
    bar.pctLabel = pctLabel
    
    -- Count column (left of percentage)
    local countLabel = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countLabel:SetPoint("RIGHT", pctLabel, "LEFT", -4, 0)
    countLabel:SetWidth(28)
    countLabel:SetJustifyH("RIGHT")
    countLabel:SetTextColor(0.8, 0.8, 0.8)
    bar.countLabel = countLabel
    
    return bar
end

local function updateBar(bar, percent, count, label, color, total)
    percent = math.max(0, math.min(1, percent or 0))
    local barWidth = bar:GetWidth()
    if barWidth > 0 then
        bar.fill:SetWidth(math.max(1, barWidth * percent))
    end
    if color then
        bar.fill:SetVertexColor(unpack(color))
    end
    if label then
        bar.label:SetText(label)
    end
    -- Count and percentage in separate columns
    if count then
        bar.countLabel:SetText(tostring(count))
        local pct = total and total > 0 and math.floor((count / total) * 100 + 0.5) or 0
        bar.pctLabel:SetText(pct .. "%")
    else
        bar.countLabel:SetText("")
        bar.pctLabel:SetText("")
    end
end

-- ============================================================================
-- LIVE MODE
-- ============================================================================

local function createLiveMode(parent)
    local container = CreateFrame("Frame", nil, parent)
    container:SetAllPoints()
    
    local yOff = -LAYOUT.PADDING
    
    -- Hero section (extra height for breathing room)
    local heroFrame = CreateFrame("Frame", nil, container)
    heroFrame:SetPoint("TOPLEFT", container, "TOPLEFT", LAYOUT.PADDING, yOff)
    heroFrame:SetPoint("TOPRIGHT", container, "TOPRIGHT", -LAYOUT.PADDING, yOff)
    heroFrame:SetHeight(LAYOUT.HERO_MODEL_SIZE + 4)  -- Slight extra for breathing room
    
    -- Model frame
    heroIconFrame = CreateFrame("Frame", nil, heroFrame, "BackdropTemplate")
    heroIconFrame:SetSize(LAYOUT.HERO_MODEL_SIZE, LAYOUT.HERO_MODEL_SIZE)
    heroIconFrame:SetPoint("LEFT", heroFrame, "LEFT", 0, 0)
    heroIconFrame:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    })
    heroIconFrame:SetBackdropBorderColor(unpack(LAYOUT.GOLD))
    
    local modelScene = CreateFrame("ModelScene", nil, heroIconFrame, "ModelSceneMixinTemplate")
    modelScene:SetSize(LAYOUT.HERO_MODEL_SIZE - 4, LAYOUT.HERO_MODEL_SIZE - 4)
    modelScene:SetPoint("CENTER")
    heroIconFrame.modelScene = modelScene
    
    heroIcon = heroIconFrame:CreateTexture(nil, "ARTWORK")
    heroIcon:SetSize(LAYOUT.HERO_MODEL_SIZE - 4, LAYOUT.HERO_MODEL_SIZE - 4)
    heroIcon:SetPoint("CENTER")
    heroIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    heroIcon:Hide()
    
    -- Hero text (more vertical spacing)
    heroName = heroFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heroName:SetPoint("TOPLEFT", heroIconFrame, "TOPRIGHT", 10, -4)
    heroName:SetPoint("RIGHT", heroFrame, "RIGHT", 0, 0)
    heroName:SetJustifyH("LEFT")
    
    heroDetail = heroFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heroDetail:SetPoint("TOPLEFT", heroName, "BOTTOMLEFT", 0, -LAYOUT.HERO_TEXT_GAP)
    heroDetail:SetTextColor(0.8, 0.8, 0.8)
    
    heroSource = heroFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    heroSource:SetPoint("TOPLEFT", heroDetail, "BOTTOMLEFT", 0, -LAYOUT.HERO_TEXT_GAP)
    heroSource:SetTextColor(unpack(LAYOUT.MUTED))
    
    heroSlotBtn = actionButton:create(heroFrame, {
        text = "Slot in Team...",
        onClick = function()
            if not slotPicker then return end
            
            -- Get the hero petID
            local pet = levelingLogic and levelingLogic:getNextPet()
            if not pet then return end
            
            slotPicker:show(function(slotIndex)
                -- Place pet in selected slot
                C_PetJournal.SetPetLoadOutInfo(slotIndex, pet.petID)
                
                if events then
                    events:emit("LOADOUT:CHANGED")
                end
            end, pet.petID)
        end,
        tooltip = "Choose which slot to place this pet in",
        size = "small",
        style = 1,
    })
    heroSlotBtn:SetPoint("BOTTOMLEFT", heroIconFrame, "BOTTOMRIGHT", 10, 2)
    
    yOff = yOff - LAYOUT.HERO_MODEL_SIZE - 4 - LAYOUT.SECTION_GAP
    
    -- Distribution toggle (clickable header)
    liveDistToggle = CreateFrame("Button", nil, container)
    liveDistToggle:SetPoint("TOPLEFT", container, "TOPLEFT", LAYOUT.PADDING, yOff)
    liveDistToggle:SetPoint("TOPRIGHT", container, "TOPRIGHT", -LAYOUT.PADDING, yOff)
    liveDistToggle:SetHeight(18)
    
    local toggleArrow = liveDistToggle:CreateTexture(nil, "ARTWORK")
    toggleArrow:SetSize(12, 12)
    toggleArrow:SetPoint("LEFT", liveDistToggle, "LEFT", 0, 0)
    toggleArrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
    liveDistToggle.arrow = toggleArrow
    
    liveStatsText = liveDistToggle:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    liveStatsText:SetPoint("LEFT", toggleArrow, "RIGHT", 4, 0)
    liveStatsText:SetJustifyH("LEFT")
    
    liveDistToggle:SetScript("OnClick", function()
        liveDistExpanded = not liveDistExpanded
        levelingPreview:refresh()
    end)
    liveDistToggle:SetScript("OnEnter", function(self)
        liveStatsText:SetTextColor(1, 1, 0.8)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Click to " .. (liveDistExpanded and "hide" or "show") .. " distribution breakdown", 1, 1, 1)
        GameTooltip:Show()
    end)
    liveDistToggle:SetScript("OnLeave", function(self)
        liveStatsText:SetTextColor(1, 1, 1)
        GameTooltip:Hide()
    end)
    
    yOff = yOff - 18
    
    -- Distribution container (shown when expanded)
    liveDistContainer = CreateFrame("Frame", nil, container)
    liveDistContainer:SetPoint("TOPLEFT", container, "TOPLEFT", LAYOUT.PADDING, yOff)
    liveDistContainer:SetPoint("TOPRIGHT", container, "TOPRIGHT", -LAYOUT.PADDING, yOff)
    liveDistContainer:Hide()
    
    local distYOff = -LAYOUT.CAPTION_TOP  -- 3px above Level
    
    -- Level section
    local levelLabel = liveDistContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelLabel:SetPoint("TOPLEFT", liveDistContainer, "TOPLEFT", 0, distYOff)
    levelLabel:SetText("Level")
    levelLabel:SetTextColor(unpack(LAYOUT.SECTION_LABEL))
    
    distYOff = distYOff - 12 - LAYOUT.CAPTION_BOTTOM  -- 3px below caption
    
    for i, bucket in ipairs(LEVEL_BUCKETS) do
        local bar = createBar(liveDistContainer, LAYOUT.BAR_HEIGHT)
        bar:SetPoint("TOPLEFT", liveDistContainer, "TOPLEFT", 0, distYOff - (i-1) * (LAYOUT.BAR_HEIGHT + LAYOUT.BAR_GAP))
        bar:SetPoint("TOPRIGHT", liveDistContainer, "TOPRIGHT", 0, distYOff - (i-1) * (LAYOUT.BAR_HEIGHT + LAYOUT.BAR_GAP))
        bar.fill:SetVertexColor(unpack(LAYOUT.BAR_FILL_LEVEL))
        bar.label:SetText(bucket.label)
        liveLevelBars[i] = bar
    end
    
    distYOff = distYOff - #LEVEL_BUCKETS * (LAYOUT.BAR_HEIGHT + LAYOUT.BAR_GAP) - LAYOUT.SECTION_GAP
    
    -- Family section (scrollable, no scrollbar)
    local familyLabel = liveDistContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    familyLabel:SetPoint("TOPLEFT", liveDistContainer, "TOPLEFT", 0, distYOff)
    familyLabel:SetText("Family")
    familyLabel:SetTextColor(unpack(LAYOUT.SECTION_LABEL))
    
    distYOff = distYOff - 12 - LAYOUT.CAPTION_BOTTOM  -- 3px below caption
    
    -- Family scroll frame (show 5 bars, scroll to see all 10)
    local familyVisibleRows = 5
    local familyScrollHeight = familyVisibleRows * (LAYOUT.BAR_HEIGHT + LAYOUT.BAR_GAP) - LAYOUT.BAR_GAP
    
    local familyScrollFrame = CreateFrame("ScrollFrame", nil, liveDistContainer)
    familyScrollFrame:SetPoint("TOPLEFT", liveDistContainer, "TOPLEFT", 0, distYOff)
    familyScrollFrame:SetPoint("TOPRIGHT", liveDistContainer, "TOPRIGHT", 0, distYOff)
    familyScrollFrame:SetHeight(familyScrollHeight)
    familyScrollFrame:EnableMouseWheel(true)
    familyScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local step = LAYOUT.BAR_HEIGHT + LAYOUT.BAR_GAP
        local newScroll = math.max(0, math.min(current - delta * step, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)
    liveDistContainer.familyScrollFrame = familyScrollFrame
    
    local familyScrollChild = CreateFrame("Frame", nil, familyScrollFrame)
    familyScrollChild:SetWidth(1)  -- Will be updated
    familyScrollChild:SetHeight(10 * (LAYOUT.BAR_HEIGHT + LAYOUT.BAR_GAP))
    familyScrollFrame:SetScrollChild(familyScrollChild)
    liveDistContainer.familyScrollChild = familyScrollChild
    
    for i = 1, 10 do
        local bar = createBar(familyScrollChild, LAYOUT.BAR_HEIGHT)
        bar:SetPoint("TOPLEFT", familyScrollChild, "TOPLEFT", 0, -(i-1) * (LAYOUT.BAR_HEIGHT + LAYOUT.BAR_GAP))
        bar:SetPoint("TOPRIGHT", familyScrollChild, "TOPRIGHT", 0, -(i-1) * (LAYOUT.BAR_HEIGHT + LAYOUT.BAR_GAP))
        bar.fill:SetVertexColor(unpack(LAYOUT.BAR_FILL_FAMILY))
        liveFamilyBars[i] = bar
    end
    
    distYOff = distYOff - familyScrollHeight - LAYOUT.SECTION_GAP
    
    -- Rarity section
    local rarityLabel = liveDistContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rarityLabel:SetPoint("TOPLEFT", liveDistContainer, "TOPLEFT", 0, distYOff)
    rarityLabel:SetText("Rarity")
    rarityLabel:SetTextColor(unpack(LAYOUT.SECTION_LABEL))
    
    distYOff = distYOff - 12 - LAYOUT.CAPTION_BOTTOM  -- 3px below caption
    
    liveRarityBar = createBar(liveDistContainer, LAYOUT.BAR_HEIGHT)
    liveRarityBar:SetPoint("TOPLEFT", liveDistContainer, "TOPLEFT", 0, distYOff)
    liveRarityBar:SetPoint("TOPRIGHT", liveDistContainer, "TOPRIGHT", 0, distYOff)
    liveRarityBar.fill:SetVertexColor(unpack(LAYOUT.BAR_FILL_RARE))
    
    distYOff = distYOff - LAYOUT.BAR_HEIGHT - LAYOUT.SECTION_GAP
    
    -- Store total height
    liveDistHeight = -distYOff
    liveDistContainer:SetHeight(liveDistHeight)
    
    yOff = yOff - LAYOUT.SECTION_GAP
    
    -- Store base Y for scroll frame (used for dynamic positioning)
    local baseScrollY = yOff
    
    -- Coming up label
    local listLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    listLabel:SetPoint("TOPLEFT", container, "TOPLEFT", LAYOUT.PADDING, yOff)
    listLabel:SetText("Coming Up")
    listLabel:SetTextColor(unpack(LAYOUT.SECTION_LABEL))
    container.listLabel = listLabel
    container.baseScrollY = baseScrollY
    
    yOff = yOff - 16 - LAYOUT.LIST_LABEL_GAP
    
    -- Scroll frame for pet list (with bottom padding)
    liveScrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    liveScrollFrame:SetPoint("TOPLEFT", container, "TOPLEFT", LAYOUT.PADDING, yOff)
    liveScrollFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -LAYOUT.PADDING - 22, 34 + LAYOUT.PADDING)
    
    liveScrollChild = CreateFrame("Frame", nil, liveScrollFrame)
    liveScrollChild:SetWidth(liveScrollFrame:GetWidth())
    liveScrollChild:SetHeight(1)
    liveScrollFrame:SetScrollChild(liveScrollChild)
    
    -- Pin section
    pinSection = CreateFrame("Frame", nil, container)
    pinSection:SetHeight(24)
    pinSection:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", LAYOUT.PADDING, LAYOUT.PADDING)
    pinSection:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -LAYOUT.PADDING, LAYOUT.PADDING)
    
    local pinLabel = pinSection:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    pinLabel:SetPoint("LEFT", pinSection, "LEFT", 0, 0)
    pinLabel:SetText("Pinned:")
    pinLabel:SetTextColor(unpack(LAYOUT.MUTED))
    
    local pinName = pinSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pinName:SetPoint("LEFT", pinLabel, "RIGHT", 6, 0)
    pinName:SetTextColor(unpack(LAYOUT.GOLD))
    pinSection.petName = pinName
    
    local clearBtn = CreateFrame("Button", nil, pinSection, "UIPanelButtonTemplate")
    clearBtn:SetSize(50, 20)
    clearBtn:SetPoint("RIGHT", pinSection, "RIGHT", 0, 0)
    clearBtn:SetText("Clear")
    clearBtn:SetScript("OnClick", function()
        levelingLogic:clearPinnedPet()
    end)
    pinSection.clearBtn = clearBtn
    
    return container
end

local function updateLiveMode()
    if not liveContainer then return end
    
    -- Get preview
    local preview = levelingLogic:getQueuePreview(100)
    local nextPet = preview[1]
    
    -- Hero
    if nextPet and nextPet.pet then
        local pet = nextPet.pet
        heroIconFrame:Show()
        
        local modelScene = heroIconFrame.modelScene
        local displaySuccess = false
        
        if modelScene and pet.speciesID and C_PetJournal then
            local displayID = pet.displayID
            if not displayID then
                local _, _, _, _, _, _, _, _, _, _, _, did = C_PetJournal.GetPetInfoBySpeciesID(pet.speciesID)
                displayID = did
            end
            
            if displayID and C_PetJournal.GetPetModelSceneInfoBySpeciesID then
                local sceneID = C_PetJournal.GetPetModelSceneInfoBySpeciesID(pet.speciesID)
                if sceneID then
                    modelScene:TransitionToModelSceneID(sceneID, CAMERA_TRANSITION_TYPE_IMMEDIATE, CAMERA_MODIFICATION_TYPE_MAINTAIN, true)
                    local actor = modelScene:GetActorByTag("unwrapped")
                    if actor then
                        actor:SetModelByCreatureDisplayID(displayID, true)
                        actor:SetAnimationBlendOperation(Enum.ModelBlendOperation.None)
                        actor:SetYaw(math.rad(math.random(-45, 45)))
                        displaySuccess = true
                    end
                end
            end
        end
        
        if displaySuccess then
            modelScene:Show()
            heroIcon:Hide()
        else
            modelScene:Hide()
            heroIcon:SetTexture(pet.icon)
            heroIcon:Show()
        end
        
        local rarityColor = pet.rarity == 4 and "|cff0070dd" or pet.rarity == 3 and "|cff1eff00" or "|cffffffff"
        heroName:SetText(rarityColor .. (pet.name or "Unknown") .. "|r")
        heroDetail:SetText(string.format("Level %d  -  %s", pet.level or 1, pet.familyName or "Unknown"))
        
        local queueCount = levelingLogic:getQueueCount(nextPet.queueId)
        heroSource:SetText(nextPet.queueId == "pinned" and "|cffffd700Pinned|r" or string.format("from %s (%d left)", nextPet.queueName or "?", queueCount))
        heroSlotBtn:Enable()
    else
        heroIconFrame:Hide()
        heroName:SetText("|cff666666No pets to level|r")
        heroDetail:SetText("")
        heroSource:SetText("")
        heroSlotBtn:Disable()
    end
    
    -- Stats
    local queues = levelingLogic:getQueues()
    local total, rareCount, familySet = 0, 0, {}
    for _, q in ipairs(queues) do
        if q.enabled then
            local pets = levelingLogic:evaluateQueue(q)
            for _, pet in ipairs(pets) do
                total = total + 1
                if pet.rarity == 4 then rareCount = rareCount + 1 end
                if pet.familyName then familySet[pet.familyName] = true end
            end
        end
    end
    local familyCount = 0
    for _ in pairs(familySet) do familyCount = familyCount + 1 end
    
    -- Update toggle arrow
    if liveDistToggle and liveDistToggle.arrow then
        if liveDistExpanded then
            liveDistToggle.arrow:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
        else
            liveDistToggle.arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
        end
    end
    
    -- Update stats text (order: Level, Family, Rarity - matches distribution order)
    -- Colors match bar fill colors
    local levelColor = string.format("|cff%02x%02x%02x", 
        math.floor(LAYOUT.BAR_FILL_LEVEL[1] * 255), 
        math.floor(LAYOUT.BAR_FILL_LEVEL[2] * 255), 
        math.floor(LAYOUT.BAR_FILL_LEVEL[3] * 255))
    local familyColor = string.format("|cff%02x%02x%02x", 
        math.floor(LAYOUT.BAR_FILL_FAMILY[1] * 255), 
        math.floor(LAYOUT.BAR_FILL_FAMILY[2] * 255), 
        math.floor(LAYOUT.BAR_FILL_FAMILY[3] * 255))
    local rareColor = string.format("|cff%02x%02x%02x", 
        math.floor(LAYOUT.BAR_FILL_RARE[1] * 255), 
        math.floor(LAYOUT.BAR_FILL_RARE[2] * 255), 
        math.floor(LAYOUT.BAR_FILL_RARE[3] * 255))
    
    liveStatsText:SetText(string.format("%s%d|r to level  %s%d|r families  %s%d|r rares", 
        levelColor, total, familyColor, familyCount, rareColor, rareCount))
    
    -- Handle distribution expansion
    if liveDistExpanded and liveDistContainer then
        liveDistContainer:Show()
        
        -- Collect all pets for distribution calculation
        local allPets = {}
        for _, q in ipairs(queues) do
            if q.enabled then
                local pets = levelingLogic:evaluateQueue(q)
                for _, pet in ipairs(pets) do
                    table.insert(allPets, pet)
                end
            end
        end
        
        local totalPets = #allPets
        
        -- Calculate level distribution
        local levelCounts = {}
        for _, bucket in ipairs(LEVEL_BUCKETS) do
            levelCounts[bucket.label] = 0
        end
        
        local familyCounts = {}
        
        for _, pet in ipairs(allPets) do
            local level = pet.level or 1
            for _, bucket in ipairs(LEVEL_BUCKETS) do
                if level >= bucket.min and level <= bucket.max then
                    levelCounts[bucket.label] = levelCounts[bucket.label] + 1
                    break
                end
            end
            
            local fam = pet.familyName or "Unknown"
            familyCounts[fam] = (familyCounts[fam] or 0) + 1
        end
        
        -- Update level bars
        local maxLevel = 1
        for _, c in pairs(levelCounts) do if c > maxLevel then maxLevel = c end end
        
        for i, bucket in ipairs(LEVEL_BUCKETS) do
            local bar = liveLevelBars[i]
            if bar then
                local count = levelCounts[bucket.label]
                updateBar(bar, count / maxLevel, count, bucket.label, LAYOUT.BAR_FILL_LEVEL, totalPets)
                bar:Show()
            end
        end
        
        -- Sort and update family bars (all 10)
        local sortedFamilies = {}
        for fam, count in pairs(familyCounts) do
            table.insert(sortedFamilies, {name = fam, count = count})
        end
        table.sort(sortedFamilies, function(a, b) return a.count > b.count end)
        
        -- Update scroll child width
        if liveDistContainer.familyScrollChild then
            local scrollWidth = liveDistContainer.familyScrollFrame:GetWidth()
            if scrollWidth and scrollWidth > 0 then
                liveDistContainer.familyScrollChild:SetWidth(scrollWidth)
            end
        end
        
        local maxFam = sortedFamilies[1] and sortedFamilies[1].count or 1
        for i = 1, 10 do
            local bar = liveFamilyBars[i]
            if bar then
                local fam = sortedFamilies[i]
                if fam then
                    updateBar(bar, fam.count / maxFam, fam.count, fam.name, LAYOUT.BAR_FILL_FAMILY, totalPets)
                    bar:Show()
                else
                    bar:Hide()
                end
            end
        end
        
        -- Rarity bar
        if liveRarityBar and totalPets > 0 then
            local rarePercent = rareCount / totalPets
            updateBar(liveRarityBar, rarePercent, rareCount, "Rare", LAYOUT.BAR_FILL_RARE, totalPets)
            liveRarityBar:Show()
        elseif liveRarityBar then
            updateBar(liveRarityBar, 0, 0, "Rare", LAYOUT.BAR_FILL_RARE, 0)
            liveRarityBar:Show()
        end
        
        -- Reposition list elements
        if liveContainer.listLabel then
            local newY = liveContainer.baseScrollY - liveDistHeight
            liveContainer.listLabel:ClearAllPoints()
            liveContainer.listLabel:SetPoint("TOPLEFT", liveContainer, "TOPLEFT", LAYOUT.PADDING, newY)
            
            local scrollY = newY - 16 - LAYOUT.LIST_LABEL_GAP
            liveScrollFrame:ClearAllPoints()
            liveScrollFrame:SetPoint("TOPLEFT", liveContainer, "TOPLEFT", LAYOUT.PADDING, scrollY)
            liveScrollFrame:SetPoint("BOTTOMRIGHT", liveContainer, "BOTTOMRIGHT", -LAYOUT.PADDING - 22, 34 + LAYOUT.PADDING)
        end
    elseif liveDistContainer then
        liveDistContainer:Hide()
        
        -- Reset list positions
        if liveContainer.listLabel then
            liveContainer.listLabel:ClearAllPoints()
            liveContainer.listLabel:SetPoint("TOPLEFT", liveContainer, "TOPLEFT", LAYOUT.PADDING, liveContainer.baseScrollY)
            
            local scrollY = liveContainer.baseScrollY - 16 - LAYOUT.LIST_LABEL_GAP
            liveScrollFrame:ClearAllPoints()
            liveScrollFrame:SetPoint("TOPLEFT", liveContainer, "TOPLEFT", LAYOUT.PADDING, scrollY)
            liveScrollFrame:SetPoint("BOTTOMRIGHT", liveContainer, "BOTTOMRIGHT", -LAYOUT.PADDING - 22, 34 + LAYOUT.PADDING)
        end
    end
    
    -- Pet list (skip hero)
    local entryHeight = constants.LIST_ENTRY_HEIGHT
    local listCount = #preview - 1
    liveScrollChild:SetHeight(math.max(1, listCount * entryHeight))
    
    -- Update scroll child width
    local scrollWidth = liveScrollFrame:GetWidth()
    if scrollWidth and scrollWidth > 0 then
        liveScrollChild:SetWidth(scrollWidth)
    end
    
    for i = 2, #preview do
        local entry = preview[i]
        local idx = i - 1
        if not liveRows[idx] then
            liveRows[idx] = petRowButton:create(liveScrollChild, entryHeight, nil)
        end
        local row = liveRows[idx]
        petRowButton:update(row, entry.pet, nil, nil)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", liveScrollChild, "TOPLEFT", 0, -(idx - 1) * entryHeight)
        row:SetPoint("TOPRIGHT", liveScrollChild, "TOPRIGHT", 0, -(idx - 1) * entryHeight)
        row:SetHeight(entryHeight)  -- Explicit height
    end
    for i = #preview, #liveRows do
        if liveRows[i] then liveRows[i]:Hide() end
    end
    
    -- Pin
    local pinnedID = levelingLogic:getPinnedPetID()
    if pinnedID then
        local pet = petCache and petCache:getPet(pinnedID)
        pinSection.petName:SetText(pet and pet.name or "(invalid)")
        pinSection.clearBtn:Enable()
    else
        pinSection.petName:SetText("None")
        pinSection.clearBtn:Disable()
    end
end

-- ============================================================================
-- EDIT MODE
-- ============================================================================

local function createEditMode(parent)
    local container = CreateFrame("Frame", nil, parent)
    container:SetAllPoints()
    
    local yOff = -LAYOUT.PADDING
    
    -- Match count
    matchCount = container:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    matchCount:SetPoint("TOP", container, "TOP", 0, yOff)
    matchCount:SetFont(matchCount:GetFont(), 26, "")
    
    matchLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    matchLabel:SetPoint("TOP", matchCount, "BOTTOM", 0, -2)
    matchLabel:SetText("pets match")
    matchLabel:SetTextColor(unpack(LAYOUT.MUTED))
    
    yOff = yOff - 46 - LAYOUT.SECTION_GAP
    
    -- Level bars
    yOff = yOff - LAYOUT.CAPTION_TOP  -- 3px above
    local levelLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    levelLabel:SetPoint("TOPLEFT", container, "TOPLEFT", LAYOUT.PADDING, yOff)
    levelLabel:SetText("Level")
    levelLabel:SetTextColor(unpack(LAYOUT.SECTION_LABEL))
    
    yOff = yOff - 12 - LAYOUT.CAPTION_BOTTOM  -- 3px below
    
    for i, bucket in ipairs(LEVEL_BUCKETS) do
        local bar = createBar(container, LAYOUT.BAR_HEIGHT)
        bar:SetPoint("TOPLEFT", container, "TOPLEFT", LAYOUT.PADDING, yOff - (i-1) * (LAYOUT.BAR_HEIGHT + LAYOUT.BAR_GAP))
        bar:SetPoint("TOPRIGHT", container, "TOPRIGHT", -LAYOUT.PADDING, yOff - (i-1) * (LAYOUT.BAR_HEIGHT + LAYOUT.BAR_GAP))
        bar.fill:SetVertexColor(unpack(LAYOUT.BAR_FILL_LEVEL))
        bar.label:SetText(bucket.label)
        levelBars[i] = bar
    end
    
    yOff = yOff - #LEVEL_BUCKETS * (LAYOUT.BAR_HEIGHT + LAYOUT.BAR_GAP) - LAYOUT.SECTION_GAP
    
    -- Family bars
    familyLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    familyLabel:SetPoint("TOPLEFT", container, "TOPLEFT", LAYOUT.PADDING, yOff)
    familyLabel:SetText("Family")
    familyLabel:SetTextColor(unpack(LAYOUT.SECTION_LABEL))
    
    yOff = yOff - 12 - LAYOUT.CAPTION_BOTTOM  -- 3px below
    familyBaseY = yOff  -- Store for dynamic repositioning
    
    for i = 1, 10 do
        local bar = createBar(container, LAYOUT.BAR_HEIGHT)
        bar:SetPoint("TOPLEFT", container, "TOPLEFT", LAYOUT.PADDING, yOff - (i-1) * (LAYOUT.BAR_HEIGHT + LAYOUT.BAR_GAP))
        bar:SetPoint("TOPRIGHT", container, "TOPRIGHT", -LAYOUT.PADDING, yOff - (i-1) * (LAYOUT.BAR_HEIGHT + LAYOUT.BAR_GAP))
        bar.fill:SetVertexColor(unpack(LAYOUT.BAR_FILL_FAMILY))
        bar:Hide()
        familyBars[i] = bar
    end
    
    -- Rarity bar (will be dynamically positioned)
    rarityLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    rarityLabel:SetText("Rarity")
    rarityLabel:SetTextColor(unpack(LAYOUT.SECTION_LABEL))
    
    rarityBar = createBar(container, LAYOUT.BAR_HEIGHT + 2)
    rarityBar.fill:SetVertexColor(unpack(LAYOUT.BAR_FILL_RARE))
    
    -- Separator line before preview (will be dynamically positioned)
    previewSeparator = container:CreateTexture(nil, "ARTWORK")
    previewSeparator:SetHeight(1)
    previewSeparator:SetColorTexture(0.4, 0.4, 0.4, 0.5)
    
    -- Preview label (will be dynamically positioned)
    previewLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    previewLabel:SetText("Preview")
    previewLabel:SetTextColor(unpack(LAYOUT.SECTION_LABEL))
    
    -- Scroll frame for pet list (will be dynamically positioned)
    editScrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    editScrollFrame:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -LAYOUT.PADDING - 22, LAYOUT.PADDING)
    
    editScrollChild = CreateFrame("Frame", nil, editScrollFrame)
    editScrollChild:SetWidth(editScrollFrame:GetWidth())
    editScrollChild:SetHeight(1)
    editScrollFrame:SetScrollChild(editScrollChild)
    
    -- Empty state
    emptyStateFrame = CreateFrame("Frame", nil, container)
    emptyStateFrame:SetAllPoints()
    emptyStateFrame:Hide()
    
    local emptyText = emptyStateFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    emptyText:SetPoint("CENTER", emptyStateFrame, "CENTER", 0, 20)
    emptyText:SetText("No pets match")
    emptyText:SetTextColor(0.5, 0.5, 0.5)
    
    local emptyHint = emptyStateFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyHint:SetPoint("TOP", emptyText, "BOTTOM", 0, -8)
    emptyHint:SetText("Check filter syntax or try different terms")
    emptyHint:SetTextColor(unpack(LAYOUT.MUTED))
    
    return container
end

local function updateEditMode(overrideQueue)
    if not editContainer or (not editingQueueId and not overrideQueue) then return end
    
    local queue = overrideQueue or levelingLogic:getQueue(editingQueueId)
    if not queue then return end
    
    local pets = levelingLogic:evaluateQueue(queue)
    local totalCount = #pets
    
    matchCount:SetText(tostring(totalCount))
    
    if totalCount == 0 then
        emptyStateFrame:Show()
        for _, bar in ipairs(levelBars) do bar:Hide() end
        for _, bar in ipairs(familyBars) do bar:Hide() end
        rarityBar:Hide()
        rarityLabel:Hide()
        editScrollFrame:Hide()
        return
    end
    
    emptyStateFrame:Hide()
    editScrollFrame:Show()
    rarityBar:Show()
    rarityLabel:Show()
    
    -- Calculate distributions
    local levelCounts = {}
    for _, bucket in ipairs(LEVEL_BUCKETS) do
        levelCounts[bucket.label] = 0
    end
    
    local familyCounts = {}
    local rareCount = 0
    
    for _, pet in ipairs(pets) do
        local level = pet.level or 1
        for _, bucket in ipairs(LEVEL_BUCKETS) do
            if level >= bucket.min and level <= bucket.max then
                levelCounts[bucket.label] = levelCounts[bucket.label] + 1
                break
            end
        end
        
        local fam = pet.familyName or "Unknown"
        familyCounts[fam] = (familyCounts[fam] or 0) + 1
        
        if pet.rarity == 4 then rareCount = rareCount + 1 end
    end
    
    -- Update level bars
    local maxLevel = 1
    for _, c in pairs(levelCounts) do if c > maxLevel then maxLevel = c end end
    
    for i, bucket in ipairs(LEVEL_BUCKETS) do
        local bar = levelBars[i]
        local count = levelCounts[bucket.label]
        updateBar(bar, count / maxLevel, count, bucket.label, LAYOUT.BAR_FILL_LEVEL, totalCount)
        bar:Show()
    end
    
    -- Sort and update family bars
    local sortedFamilies = {}
    for fam, count in pairs(familyCounts) do
        table.insert(sortedFamilies, {name = fam, count = count})
    end
    table.sort(sortedFamilies, function(a, b) return a.count > b.count end)
    
    local maxFam = sortedFamilies[1] and sortedFamilies[1].count or 1
    local visibleFamilyCount = 0
    for i = 1, 10 do
        local bar = familyBars[i]
        local fam = sortedFamilies[i]
        if fam then
            updateBar(bar, fam.count / maxFam, fam.count, fam.name, LAYOUT.BAR_FILL_FAMILY, totalCount)
            bar:Show()
            visibleFamilyCount = visibleFamilyCount + 1
        else
            bar:Hide()
        end
    end
    
    -- Dynamic repositioning: flow elements up based on visible family count
    local yOff = familyBaseY - visibleFamilyCount * (LAYOUT.BAR_HEIGHT + LAYOUT.BAR_GAP) - LAYOUT.SECTION_GAP
    
    -- Reposition rarity section
    rarityLabel:ClearAllPoints()
    rarityLabel:SetPoint("TOPLEFT", editContainer, "TOPLEFT", LAYOUT.PADDING, yOff)
    
    yOff = yOff - 12 - LAYOUT.CAPTION_BOTTOM
    
    rarityBar:ClearAllPoints()
    rarityBar:SetPoint("TOPLEFT", editContainer, "TOPLEFT", LAYOUT.PADDING, yOff)
    rarityBar:SetPoint("TOPRIGHT", editContainer, "TOPRIGHT", -LAYOUT.PADDING, yOff)
    
    -- Rarity bar
    local rarePercent = rareCount / totalCount
    updateBar(rarityBar, rarePercent, rareCount, "Rare", LAYOUT.BAR_FILL_RARE, totalCount)
    
    yOff = yOff - LAYOUT.BAR_HEIGHT - 2 - LAYOUT.SECTION_GAP - 4  -- Extra space before separator
    
    -- Separator line
    previewSeparator:ClearAllPoints()
    previewSeparator:SetPoint("TOPLEFT", editContainer, "TOPLEFT", LAYOUT.PADDING, yOff)
    previewSeparator:SetPoint("TOPRIGHT", editContainer, "TOPRIGHT", -LAYOUT.PADDING, yOff)
    
    yOff = yOff - LAYOUT.SECTION_GAP
    
    -- Reposition preview section
    previewLabel:ClearAllPoints()
    previewLabel:SetPoint("TOPLEFT", editContainer, "TOPLEFT", LAYOUT.PADDING, yOff)
    
    yOff = yOff - 12 - LAYOUT.CAPTION_BOTTOM - LAYOUT.LIST_LABEL_GAP
    
    -- Reposition scroll frame
    editScrollFrame:ClearAllPoints()
    editScrollFrame:SetPoint("TOPLEFT", editContainer, "TOPLEFT", LAYOUT.PADDING, yOff)
    editScrollFrame:SetPoint("BOTTOMRIGHT", editContainer, "BOTTOMRIGHT", -LAYOUT.PADDING - 22, LAYOUT.PADDING)
    
    -- Pet list (up to 100)
    local entryHeight = constants.LIST_ENTRY_HEIGHT
    local listCount = math.min(100, totalCount)
    editScrollChild:SetHeight(math.max(1, listCount * entryHeight))
    
    -- Update scroll child width
    local scrollWidth = editScrollFrame:GetWidth()
    if scrollWidth and scrollWidth > 0 then
        editScrollChild:SetWidth(scrollWidth)
    end
    
    for i = 1, listCount do
        if not editRows[i] then
            editRows[i] = petRowButton:create(editScrollChild, entryHeight, nil)
        end
        local row = editRows[i]
        petRowButton:update(row, pets[i], nil, nil)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", editScrollChild, "TOPLEFT", 0, -(i - 1) * entryHeight)
        row:SetPoint("TOPRIGHT", editScrollChild, "TOPRIGHT", 0, -(i - 1) * entryHeight)
        row:SetHeight(entryHeight)  -- Explicit height
    end
    for i = listCount + 1, #editRows do
        if editRows[i] then editRows[i]:Hide() end
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function levelingPreview:createContent(parent)
    parentFrame = parent
    liveContainer = createLiveMode(parent)
    editContainer = createEditMode(parent)
    editContainer:Hide()
    liveContainer:Show()
end

function levelingPreview:setEditingQueue(queueId)
    editingQueueId = queueId
    if queueId then
        liveContainer:Hide()
        editContainer:Show()
    else
        editContainer:Hide()
        liveContainer:Show()
    end
    self:refresh()
end

--[[
  Refresh edit mode with a temporary queue (for live preview while editing).
  @param queue table - Queue with filter/sortField/sortDir
]]
function levelingPreview:refreshEditWithQueue(queue)
    if not editContainer then return end
    updateEditMode(queue)
end

function levelingPreview:refresh()
    if not parentFrame then return end
    if editingQueueId then
        updateEditMode()
    else
        updateLiveMode()
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function levelingPreview:initialize()
    utils = Addon.utils
    events = Addon.events
    constants = Addon.constants
    levelingLogic = Addon.levelingLogic
    petCache = Addon.petCache
    petRowButton = Addon.petRowButton
    actionButton = Addon.actionButton
    slotPicker = Addon.slotPicker
    return true
end

if Addon.registerModule then
    Addon.registerModule("levelingPreview", {
        "utils", "events", "constants", "levelingLogic", "petCache", "petRowButton", "actionButton", "slotPicker"
    }, function()
        return levelingPreview:initialize()
    end)
end

Addon.levelingPreview = levelingPreview
return levelingPreview