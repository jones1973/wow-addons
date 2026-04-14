--[[
  ui/filterHelp.lua
  Filter Documentation Frame
  
  Accordion sections with floating preview panel.
  Dynamic-width token boxes. Use-case focused examples.
  
  Dependencies: utils, petCache, petFilters, petRowButton
  Exports: Addon.filterHelp
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in filterHelp.lua.|r")
    return {}
end

local filterHelp = {}

-- UI elements
local helpFrame = nil
local tabButtons = {}
local contentScrollFrame = nil
local currentScrollChild = nil
local floatingPreview = nil

-- Accordion state
local expandedSection = {}

-- Layout
local FRAME_WIDTH = 680
local FRAME_HEIGHT = 450
local TAB_WIDTH = 150
local TAB_HEIGHT = 28
local TAB_SPACING = 1
local PREVIEW_BUTTON_COUNT = 5

-- Spacing
local SECTION_GAP = 12
local CONTENT_INDENT = 12
local ELEMENT_GAP = 10
local CAPTION_HEIGHT = 20
local TOKEN_LINE_HEIGHT = 16
local EXAMPLE_LINE_HEIGHT = 36

-- Colors
local COLORS = {
    headerGold = {1, 0.82, 0},
    subHeaderGreen = {0.5, 0.9, 0.5},
    filterLavender = {0.75, 0.55, 0.95},
    filterLavenderHover = {0.85, 0.7, 1},
    textLight = {0.88, 0.88, 0.88},
    textMuted = {0.55, 0.55, 0.55},
    tokenText = {0.9, 0.82, 0.6},
    
    captionBg = {0.18, 0.15, 0.12, 1},
    captionText = {0.8, 0.74, 0.62},
    
    activeBg = {0.12, 0.12, 0.14, 1},
    activeBorder = {0.4, 0.4, 0.45, 1},
    activeText = {1, 0.82, 0, 1},
    
    inactiveBg = {0.06, 0.06, 0.08, 1},
    inactiveBorder = {0.25, 0.25, 0.3, 1},
    inactiveText = {0.55, 0.55, 0.55, 1},
    
    hoverBg = {0.1, 0.1, 0.12, 1},
    hoverText = {0.85, 0.85, 0.85, 1},
    
    contentBg = {0.12, 0.12, 0.14, 1},
    contentBorder = {0.4, 0.4, 0.45, 1},
    tokenBoxBg = {0.06, 0.06, 0.08, 0.95},
    sectionHeaderBg = {0.15, 0.14, 0.12, 1},
    previewBg = {0.08, 0.08, 0.10, 1},
}

local CATEGORIES = {
    {name = "Quick Reference", id = "quickref"},
    {name = "How It Works", id = "howitworks"},
    {name = "Pet Attributes", id = "attributes"},
    {name = "Acquisition", id = "acquisition"},
    {name = "Collection", id = "collection"},
    {name = "Combat", id = "combat"},
    {name = "Conditions", id = "conditions"},
}

-- Section ID mapping for quick reference navigation
local SECTION_MAPPING = {
    ["Text search"] = {tab = "howitworks", section = "how_text"},
    ["Negation"] = {tab = "howitworks", section = "how_neg"},
    ["Rarity"] = {tab = "attributes", section = "attr_rarity"},
    ["Family"] = {tab = "attributes", section = "attr_family"},
    ["Level"] = {tab = "attributes", section = "attr_level"},
    ["Source"] = {tab = "acquisition", section = "acq_source"},
    ["Location"] = {tab = "acquisition", section = "acq_location"},
    ["Ownership"] = {tab = "collection", section = "coll_ownership"},
    ["Count"] = {tab = "collection", section = "coll_count"},
    ["Flags"] = {tab = "collection", section = "coll_flags"},
    ["Strong vs"] = {tab = "combat", section = "combat_vs"},
    ["Damage type"] = {tab = "combat", section = "combat_damage"},
    ["Counter"] = {tab = "combat", section = "combat_counter"},
    ["Spawn"] = {tab = "conditions", section = "cond_spawn"},
    ["Upgradeable"] = {tab = "conditions", section = "cond_upgrade"},
    ["Family rank"] = {tab = "conditions", section = "cond_family"},
}

-- ============================================================================
-- FLOATING PREVIEW PANEL
-- ============================================================================

local clickCatcher = nil

local function createFloatingPreview()
    -- Click catcher to dismiss preview when clicking elsewhere (content area only, not tabs)
    if not clickCatcher then
        clickCatcher = CreateFrame("Button", nil, helpFrame)
        clickCatcher:SetPoint("TOPLEFT", helpFrame, "TOPLEFT", TAB_WIDTH + 9, -28)
        clickCatcher:SetPoint("BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", -8, 8)
        clickCatcher:SetFrameStrata("HIGH")
        clickCatcher:Hide()
        clickCatcher:SetScript("OnClick", function()
            if floatingPreview then floatingPreview:Hide() end
            clickCatcher:Hide()
        end)
    end
    
    local panel = CreateFrame("Frame", ADDON_NAME .. "FilterHelpPreview", helpFrame, "BackdropTemplate")
    panel:SetSize(280, 260)
    panel:SetFrameStrata("DIALOG")
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    panel:SetBackdropColor(COLORS.previewBg[1], COLORS.previewBg[2], COLORS.previewBg[3], 0.98)
    panel:SetBackdropBorderColor(COLORS.contentBorder[1], COLORS.contentBorder[2], COLORS.contentBorder[3], 1)
    panel:Hide()
    
    panel:SetScript("OnShow", function() clickCatcher:Show() end)
    panel:SetScript("OnHide", function() clickCatcher:Hide() end)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, panel)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -4, -4)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetScript("OnClick", function() panel:Hide() end)
    
    -- Header
    panel.header = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    panel.header:SetPoint("TOPLEFT", panel, "TOPLEFT", 8, -6)
    panel.header:SetText("Preview")
    panel.header:SetTextColor(COLORS.captionText[1], COLORS.captionText[2], COLORS.captionText[3])
    
    -- Match count
    panel.matchCount = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    panel.matchCount:SetPoint("LEFT", panel.header, "RIGHT", 8, 0)
    panel.matchCount:SetTextColor(COLORS.textMuted[1], COLORS.textMuted[2], COLORS.textMuted[3])
    
    -- No results text
    panel.noResults = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.noResults:SetPoint("CENTER", panel, "CENTER", 0, 0)
    panel.noResults:SetText("No matching pets")
    panel.noResults:SetTextColor(COLORS.textMuted[1], COLORS.textMuted[2], COLORS.textMuted[3])
    panel.noResults:Hide()
    
    -- Pet buttons container
    panel.petButtons = {}
    panel.buttonsCreated = false
    
    return panel
end

local function ensurePreviewButtons()
    if floatingPreview.buttonsCreated then return true end
    
    local petRowButton = Addon.petRowButton
    if not petRowButton then return false end
    
    local buttonHeight = 38
    local spacing = 4
    local startY = 24
    
    for i = 1, PREVIEW_BUTTON_COUNT do
        local btn = petRowButton:create(floatingPreview, buttonHeight, {})
        btn:SetPoint("TOPLEFT", floatingPreview, "TOPLEFT", 6, -startY - ((i - 1) * (buttonHeight + spacing)))
        btn:SetPoint("RIGHT", floatingPreview, "RIGHT", -6, 0)
        btn:Hide()
        floatingPreview.petButtons[i] = btn
    end
    
    floatingPreview.buttonsCreated = true
    return true
end

local function showFloatingPreview(anchorFrame, filterText)
    if not floatingPreview then
        floatingPreview = createFloatingPreview()
    end
    
    if not ensurePreviewButtons() then return end
    
    local petCache = Addon.petCache
    local petFilters = Addon.petFilters
    local petRowButton = Addon.petRowButton
    
    if not petCache or not petFilters or not petRowButton then return end
    
    -- Check if filter contains ownership tokens
    local filterType = Addon.filterType
    local hasOwnershipToken = filterType and filterType.hasOwnershipToken(filterText)
    
    -- Get pets - all pets if ownership token present, owned only otherwise
    local allPets = petCache:getAllPets()
    local petsToFilter
    if hasOwnershipToken then
        petsToFilter = allPets
    else
        petsToFilter = {}
        for _, pet in ipairs(allPets) do
            if pet.owned then
                table.insert(petsToFilter, pet)
            end
        end
    end
    
    local matchingPets = petFilters:filter(petsToFilter, filterText)
    
    -- Hide all buttons first
    for i = 1, PREVIEW_BUTTON_COUNT do
        floatingPreview.petButtons[i]:Hide()
    end
    
    if not matchingPets or #matchingPets == 0 then
        -- Check for special upgrade filter message
        local noResultsText = "No matching pets"
        if filterText and filterText:lower():match("upgrade") then
            -- Check if a family is specified in the filter
            local familyUtils = Addon.familyUtils
            local specifiedFamily = nil
            if familyUtils and familyUtils.resolveFamily then
                -- Check for family names in the filter text
                for word in filterText:lower():gmatch("%S+") do
                    if word ~= "upgrade" and word ~= "upgradeable" then
                        local resolved = familyUtils:resolveFamily(word)
                        if resolved then
                            specifiedFamily = familyUtils:getFamilyNameFromType(resolved)
                            break
                        end
                    end
                end
            end
            
            -- Check if player has any family-specific battle stones
            local petUtils = Addon.petUtils
            local constants = Addon.constants
            local hasAnyStones = false
            
            if petUtils and petUtils.scanBattleStones and constants then
                -- Check a few common families
                for familyId = 1, 10 do
                    local stones = petUtils:scanBattleStones(familyId, 2) -- Check for common->rare upgrade
                    if stones and #stones > 0 then
                        for _, stone in ipairs(stones) do
                            if not constants.UNIVERSAL_STONE_IDS or not constants.UNIVERSAL_STONE_IDS[stone.itemID] then
                                hasAnyStones = true
                                break
                            end
                        end
                    end
                    if hasAnyStones then break end
                end
            end
            
            if not hasAnyStones then
                if specifiedFamily then
                    noResultsText = "No " .. specifiedFamily .. " battle stones in inventory"
                else
                    noResultsText = "No family battle stones in inventory"
                end
            end
        end
        
        floatingPreview.noResults:SetText(noResultsText)
        floatingPreview.noResults:Show()
        floatingPreview.matchCount:SetText("0 matches")
        floatingPreview:SetHeight(80)
    else
        floatingPreview.noResults:Hide()
        local count = math.min(#matchingPets, PREVIEW_BUTTON_COUNT)
        local countText = #matchingPets .. " match" .. (#matchingPets == 1 and "" or "es")
        if #matchingPets > PREVIEW_BUTTON_COUNT then
            countText = countText .. " (showing " .. count .. ")"
        end
        floatingPreview.matchCount:SetText(countText)
        
        local buttonHeight = 38
        local spacing = 4
        
        for i = 1, count do
            petRowButton:update(floatingPreview.petButtons[i], matchingPets[i], nil, nil, {showBadges = true})
            floatingPreview.petButtons[i]:Show()
        end
        
        floatingPreview:SetHeight(28 + (count * (buttonHeight + spacing)) + 8)
    end
    
    -- Position near the clicked element
    floatingPreview:ClearAllPoints()
    floatingPreview:SetPoint("TOPLEFT", anchorFrame, "BOTTOMLEFT", 0, -4)
    floatingPreview:Show()
end

local function hideFloatingPreview()
    if floatingPreview then
        floatingPreview:Hide()
    end
end

-- ============================================================================
-- CONTENT HELPERS
-- ============================================================================

local rebuildCurrentContent = nil
local currentTabId = nil

local function createAccordionSection(scrollChild, tabId, sectionId, title, yOffset, contentBuilder)
    local isExpanded = (expandedSection[tabId] == sectionId)
    
    local header = CreateFrame("Button", nil, scrollChild)
    header:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
    header:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -yOffset)
    header:SetHeight(SECTION_GAP + 24)
    
    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetPoint("TOPLEFT", header, "TOPLEFT", 0, -SECTION_GAP)
    headerBg:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    headerBg:SetColorTexture(COLORS.sectionHeaderBg[1], COLORS.sectionHeaderBg[2], COLORS.sectionHeaderBg[3], 1)
    
    local headerHighlight = header:CreateTexture(nil, "HIGHLIGHT")
    headerHighlight:SetPoint("TOPLEFT", headerBg, "TOPLEFT", 0, 0)
    headerHighlight:SetPoint("BOTTOMRIGHT", headerBg, "BOTTOMRIGHT", 0, 0)
    headerHighlight:SetColorTexture(1, 1, 1, 0.05)
    
    local arrow = header:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(14, 14)
    arrow:SetPoint("LEFT", header, "LEFT", 10, -SECTION_GAP/2)
    arrow:SetTexture(isExpanded and "Interface\\Buttons\\UI-MinusButton-Up" or "Interface\\Buttons\\UI-PlusButton-Up")
    
    local titleText = header:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    titleText:SetPoint("LEFT", arrow, "RIGHT", 8, 0)
    titleText:SetText(title)
    titleText:SetTextColor(COLORS.subHeaderGreen[1], COLORS.subHeaderGreen[2], COLORS.subHeaderGreen[3])
    
    local totalHeight = SECTION_GAP + 24
    
    if isExpanded then
        local content = CreateFrame("Frame", nil, scrollChild)
        content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -ELEMENT_GAP)
        content:SetWidth(scrollChild:GetWidth())
        
        local contentHeight = contentBuilder(content)
        content:SetHeight(contentHeight)
        totalHeight = totalHeight + ELEMENT_GAP + contentHeight
    end
    
    header:SetScript("OnClick", function()
        hideFloatingPreview()
        if expandedSection[tabId] == sectionId then
            expandedSection[tabId] = nil
        else
            expandedSection[tabId] = sectionId
        end
        if rebuildCurrentContent then rebuildCurrentContent() end
    end)
    
    return totalHeight
end

-- Measure text width for dynamic sizing
local function measureText(text, font)
    local temp = helpFrame:CreateFontString(nil, "ARTWORK", font or "GameFontNormalSmall")
    temp:SetText(text)
    local width = temp:GetStringWidth()
    temp:Hide()
    return width
end

-- Token box with dynamic width, left-justified content, 2px border
-- tokens can be strings or {text=, tooltip=} tables
local function createTokenBox(parent, label, tokens, yOffset)
    -- Normalize tokens and measure
    local normalizedTokens = {}
    local maxWidth = measureText(label, "GameFontNormalSmall")
    for _, token in ipairs(tokens) do
        local text = type(token) == "table" and token.text or token
        local tooltip = type(token) == "table" and token.tooltip or nil
        table.insert(normalizedTokens, {text = text, tooltip = tooltip})
        local w = measureText(text, "GameFontNormalSmall")
        if w > maxWidth then maxWidth = w end
    end
    
    local boxPadding = 10
    local boxWidth = maxWidth + (boxPadding * 2)
    
    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, -yOffset)
    box:SetWidth(boxWidth)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    box:SetBackdropColor(COLORS.tokenBoxBg[1], COLORS.tokenBoxBg[2], COLORS.tokenBoxBg[3], 1)
    box:SetBackdropBorderColor(COLORS.captionBg[1], COLORS.captionBg[2], COLORS.captionBg[3], 1)
    
    -- Caption background (inside border)
    local captionBg = box:CreateTexture(nil, "ARTWORK")
    captionBg:SetPoint("TOPLEFT", box, "TOPLEFT", 2, -2)
    captionBg:SetPoint("TOPRIGHT", box, "TOPRIGHT", -2, -2)
    captionBg:SetHeight(CAPTION_HEIGHT)
    captionBg:SetColorTexture(COLORS.captionBg[1], COLORS.captionBg[2], COLORS.captionBg[3], 1)
    
    -- Caption text (centered)
    local captionText = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    captionText:SetPoint("CENTER", captionBg, "CENTER", 0, 0)
    captionText:SetText(label)
    captionText:SetTextColor(COLORS.captionText[1], COLORS.captionText[2], COLORS.captionText[3])
    
    -- Tokens (left-justified, inside border)
    local innerY = 2 + CAPTION_HEIGHT + 8
    for _, tokenData in ipairs(normalizedTokens) do
        if tokenData.tooltip then
            -- Create a button for tooltip support
            local tokenBtn = CreateFrame("Button", nil, box)
            tokenBtn:SetPoint("TOPLEFT", box, "TOPLEFT", 2 + boxPadding, -innerY)
            tokenBtn:SetHeight(TOKEN_LINE_HEIGHT)
            
            local tokenText = tokenBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            tokenText:SetPoint("LEFT", tokenBtn, "LEFT", 0, 0)
            tokenText:SetText(tokenData.text)
            tokenText:SetTextColor(COLORS.tokenText[1], COLORS.tokenText[2], COLORS.tokenText[3])
            tokenBtn:SetWidth(tokenText:GetStringWidth())
            
            tokenBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(tokenData.tooltip, 1, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            tokenBtn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        else
            local tokenText = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            tokenText:SetPoint("TOPLEFT", box, "TOPLEFT", 2 + boxPadding, -innerY)
            tokenText:SetText(tokenData.text)
            tokenText:SetTextColor(COLORS.tokenText[1], COLORS.tokenText[2], COLORS.tokenText[3])
        end
        innerY = innerY + TOKEN_LINE_HEIGHT
    end
    
    local boxHeight = innerY + 8
    box:SetHeight(boxHeight)
    
    return boxWidth, boxHeight
end

-- Examples section: use case above, filter below
local function createExamplesSection(parent, examples, yOffset, maxWidth)
    local EXAMPLES_TOP_PADDING = 8
    local section = CreateFrame("Frame", nil, parent)
    section:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_INDENT, -(yOffset + EXAMPLES_TOP_PADDING))
    section:SetWidth(maxWidth)
    
    -- Caption with background
    local captionBg = section:CreateTexture(nil, "BACKGROUND")
    captionBg:SetPoint("TOPLEFT", section, "TOPLEFT", 0, 0)
    captionBg:SetWidth(72)
    captionBg:SetHeight(CAPTION_HEIGHT)
    captionBg:SetColorTexture(COLORS.captionBg[1], COLORS.captionBg[2], COLORS.captionBg[3], 1)
    
    local captionText = section:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    captionText:SetPoint("CENTER", captionBg, "CENTER", 0, 0)
    captionText:SetText("Examples")
    captionText:SetTextColor(COLORS.captionText[1], COLORS.captionText[2], COLORS.captionText[3])
    
    local innerY = CAPTION_HEIGHT + ELEMENT_GAP
    
    for _, ex in ipairs(examples) do
        local filterText = ex[1]
        local useCase = ex[2]
        
        -- Use case text (first line)
        local useCaseLabel = section:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        useCaseLabel:SetPoint("TOPLEFT", section, "TOPLEFT", 4, -innerY)
        useCaseLabel:SetWidth(maxWidth - 8)
        useCaseLabel:SetJustifyH("LEFT")
        useCaseLabel:SetText(useCase)
        useCaseLabel:SetTextColor(COLORS.textLight[1], COLORS.textLight[2], COLORS.textLight[3])
        
        local useCaseHeight = useCaseLabel:GetStringHeight()
        innerY = innerY + useCaseHeight + 4
        
        -- Clickable filter (second line, indented)
        local btn = CreateFrame("Button", nil, section)
        btn:SetPoint("TOPLEFT", section, "TOPLEFT", 12, -innerY)
        btn:SetHeight(18)
        
        local filterLabel = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        filterLabel:SetPoint("LEFT", btn, "LEFT", 0, 0)
        filterLabel:SetText("|cffBF8CF2" .. filterText .. "|r")
        btn.filterLabel = filterLabel
        btn.filterText = filterText
        
        local filterWidth = filterLabel:GetStringWidth()
        btn:SetWidth(filterWidth + 4)
        
        btn:SetScript("OnEnter", function(self)
            self.filterLabel:SetText("|cffD9B3FF" .. self.filterText .. "|r")
        end)
        btn:SetScript("OnLeave", function(self)
            self.filterLabel:SetText("|cffBF8CF2" .. self.filterText .. "|r")
        end)
        btn:SetScript("OnClick", function(self)
            showFloatingPreview(self, self.filterText)
        end)
        
        innerY = innerY + 26
    end
    
    local sectionHeight = innerY + 4
    section:SetHeight(sectionHeight)
    
    return sectionHeight + EXAMPLES_TOP_PADDING
end

local function createDescription(parent, text, yOffset, maxWidth)
    maxWidth = maxWidth or (parent:GetWidth() - CONTENT_INDENT * 2)
    
    local desc = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOPLEFT", parent, "TOPLEFT", CONTENT_INDENT, -yOffset)
    desc:SetWidth(maxWidth)
    desc:SetJustifyH("LEFT")
    desc:SetSpacing(2)
    desc:SetText(text)
    desc:SetTextColor(COLORS.textLight[1], COLORS.textLight[2], COLORS.textLight[3])
    
    return desc:GetStringHeight() + ELEMENT_GAP
end

local function createTabIntro(scrollChild, text, yOffset)
    local intro = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    intro:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 8, -yOffset)
    intro:SetWidth(scrollChild:GetWidth() - 16)
    intro:SetJustifyH("LEFT")
    intro:SetSpacing(2)
    intro:SetText(text)
    intro:SetTextColor(COLORS.textLight[1], COLORS.textLight[2], COLORS.textLight[3])
    
    return intro:GetStringHeight() + 16
end

-- Quick reference: columns layout, click navigates to tab AND opens section
local function createQuickRefColumns(scrollChild, yOffset)
    local col1X = 12
    local col2X = 220
    local rowHeight = 22
    local sectionGap = 16
    
    local columns = {
        { -- Left column
            {header = "Basics", items = {"Text search", "Negation"}},
            {header = "Pet Attributes", items = {"Rarity", "Family", "Level"}},
            {header = "Acquisition", items = {"Source", "Location"}},
        },
        { -- Right column
            {header = "Collection", items = {"Ownership", "Count", "Flags"}},
            {header = "Combat", items = {"Strong vs", "Damage type", "Counter"}},
            {header = "Conditions", items = {"Spawn", "Upgradeable", "Family rank"}},
        },
    }
    
    local maxY = 0
    
    for colIdx, colData in ipairs(columns) do
        local xPos = (colIdx == 1) and col1X or col2X
        local y = 0
        
        for _, section in ipairs(colData) do
            -- Section header
            local headerText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            headerText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", xPos, -(yOffset + y))
            headerText:SetText(section.header)
            headerText:SetTextColor(COLORS.subHeaderGreen[1], COLORS.subHeaderGreen[2], COLORS.subHeaderGreen[3])
            y = y + rowHeight
            
            -- Items
            for _, itemName in ipairs(section.items) do
                local mapping = SECTION_MAPPING[itemName]
                
                local btn = CreateFrame("Button", nil, scrollChild)
                btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", xPos + 8, -(yOffset + y))
                btn:SetHeight(rowHeight)
                
                local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                text:SetPoint("LEFT", btn, "LEFT", 0, 0)
                text:SetText(itemName)
                text:SetTextColor(COLORS.textLight[1], COLORS.textLight[2], COLORS.textLight[3])
                btn.text = text
                btn.mapping = mapping
                
                local textWidth = text:GetStringWidth()
                btn:SetWidth(textWidth + 4)
                
                btn:SetScript("OnEnter", function(self)
                    self.text:SetTextColor(COLORS.headerGold[1], COLORS.headerGold[2], COLORS.headerGold[3])
                end)
                btn:SetScript("OnLeave", function(self)
                    self.text:SetTextColor(COLORS.textLight[1], COLORS.textLight[2], COLORS.textLight[3])
                end)
                btn:SetScript("OnClick", function(self)
                    if self.mapping then
                        expandedSection[self.mapping.tab] = self.mapping.section
                        if tabButtons[self.mapping.tab] then
                            tabButtons[self.mapping.tab]:Click()
                        end
                    end
                end)
                
                y = y + rowHeight
            end
            
            y = y + sectionGap
        end
        
        if y > maxY then maxY = y end
    end
    
    return maxY
end

-- ============================================================================
-- CATEGORY CONTENT
-- ============================================================================

local function destroyScrollChild()
    hideFloatingPreview()
    if currentScrollChild then
        currentScrollChild:Hide()
        currentScrollChild:SetParent(nil)
        currentScrollChild = nil
    end
end

local function updateScrollbarVisibility()
    if not contentScrollFrame then return end
    contentScrollFrame:SetVerticalScroll(0)
end

local function createCategoryContent(scrollFrame, categoryId)
    destroyScrollChild()
    currentTabId = categoryId
    
    -- Auto-expand first section on each tab if none expanded
    local FIRST_SECTIONS = {
        howitworks = "how_text",
        attributes = "attr_rarity",
        acquisition = "acq_source",
        collection = "coll_ownership",
        combat = "combat_vs",
        conditions = "cond_spawn",
    }
    if not expandedSection[categoryId] and FIRST_SECTIONS[categoryId] then
        expandedSection[categoryId] = FIRST_SECTIONS[categoryId]
    end
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(scrollFrame:GetWidth() - 4)
    currentScrollChild = scrollChild
    
    -- Click on empty space hides preview
    scrollChild:EnableMouse(true)
    scrollChild:SetScript("OnMouseDown", function()
        hideFloatingPreview()
    end)
    
    rebuildCurrentContent = function()
        createCategoryContent(scrollFrame, currentTabId)
    end
    
    local y = 16
    
    -- ========================================================================
    -- QUICK REFERENCE
    -- ========================================================================
    if categoryId == "quickref" then
        y = y + createTabIntro(scrollChild, "Click any filter type to jump to its documentation.", y)
        y = y + createQuickRefColumns(scrollChild, y)
    
    -- ========================================================================
    -- HOW IT WORKS
    -- ========================================================================
    elseif categoryId == "howitworks" then
        y = y + createTabIntro(scrollChild, "Master these fundamentals to build powerful filters.", y)
        
        y = y + createAccordionSection(scrollChild, categoryId, "how_text", "Text Search", y, function(content)
            local cy = 0
            cy = cy + createDescription(content, "Search by pet name, family, or ability.", cy)
            
            local examples = {
                {"pandaren", "Pets with 'Pandaren' in name"},
                {"dragon howl", "Dragonkin with Howl ability"},
            }
            cy = cy + createExamplesSection(content, examples, cy, content:GetWidth() - CONTENT_INDENT)
            return cy
        end)
        
        y = y + createAccordionSection(scrollChild, categoryId, "how_or", "OR Logic (Same Category)", y, function(content)
            local cy = 0
            cy = cy + createDescription(content, "Multiple terms in same category = match ANY.", cy)
            
            local examples = {
                {"beast dragon", "Beast OR Dragonkin families"},
            }
            cy = cy + createExamplesSection(content, examples, cy, content:GetWidth() - CONTENT_INDENT)
            return cy
        end)
        
        y = y + createAccordionSection(scrollChild, categoryId, "how_and", "AND Logic (Different Categories)", y, function(content)
            local cy = 0
            cy = cy + createDescription(content, "Terms from different categories = match ALL.", cy)
            
            local examples = {
                {"rare beast 25", "Must be rare AND Beast AND level 25"},
            }
            cy = cy + createExamplesSection(content, examples, cy, content:GetWidth() - CONTENT_INDENT)
            return cy
        end)
        
        y = y + createAccordionSection(scrollChild, categoryId, "how_neg", "Negation (!)", y, function(content)
            local cy = 0
            cy = cy + createDescription(content, "Prefix with ! to exclude.", cy)
            
            local examples = {
                {"!owned", "Uncollected pets only"},
                {"beast !25", "Beasts not at max level"},
            }
            cy = cy + createExamplesSection(content, examples, cy, content:GetWidth() - CONTENT_INDENT)
            return cy
        end)
    
    -- ========================================================================
    -- PET ATTRIBUTES
    -- ========================================================================
    elseif categoryId == "attributes" then
        y = y + createTabIntro(scrollChild, "Filter by inherent pet properties.", y)
        
        y = y + createAccordionSection(scrollChild, categoryId, "attr_rarity", "Rarity", y, function(content)
            local cy = 0
            local boxWidth, boxHeight = createTokenBox(content, "Tokens", {"poor", "common", "uncommon", "rare"}, cy)
            local leftWidth = content:GetWidth() - boxWidth - CONTENT_INDENT - 12
            
            cy = cy + createDescription(content, "Pet quality affects stats. Rare is the highest.", cy, leftWidth)
            
            local examples = {
                {"!rare owned", "Show your pets that need upgrading"},
                {"rare 25", "Your battle-ready collection"},
            }
            cy = cy + createExamplesSection(content, examples, cy, leftWidth)
            return math.max(cy, boxHeight)
        end)
        
        y = y + createAccordionSection(scrollChild, categoryId, "attr_family", "Family", y, function(content)
            local cy = 0
            local boxWidth, boxHeight = createTokenBox(content, "Tokens", {
                "aquatic", "beast", "critter", "dragonkin", "elemental",
                "flying", "humanoid", "magic", "mechanical", "undead"
            }, cy)
            local leftWidth = content:GetWidth() - boxWidth - CONTENT_INDENT - 12
            
            cy = cy + createDescription(content, "Each family has combat strengths and a passive ability.", cy, leftWidth)
            
            local examples = {
                {"mechanical", "Review your Mechanical roster"},
                {"humanoid rare 25", "Battle-ready Humanoids"},
            }
            cy = cy + createExamplesSection(content, examples, cy, leftWidth)
            return math.max(cy, boxHeight)
        end)
        
        y = y + createAccordionSection(scrollChild, categoryId, "attr_level", "Level", y, function(content)
            local cy = 0
            local boxWidth, boxHeight = createTokenBox(content, "Syntax", {"N", ">N", "<N", ">=N", "<=N", "N-N", "", "N = 1-25"}, cy)
            local leftWidth = content:GetWidth() - boxWidth - CONTENT_INDENT - 12
            
            cy = cy + createDescription(content, "Filter by level using numbers, comparisons, or ranges.", cy, leftWidth)
            
            local examples = {
                {"owned !25", "Pets that need leveling"},
                {"rare 20-24", "Rare pets almost at max"},
            }
            cy = cy + createExamplesSection(content, examples, cy, leftWidth)
            return math.max(cy, boxHeight)
        end)
    
    -- ========================================================================
    -- ACQUISITION
    -- ========================================================================
    elseif categoryId == "acquisition" then
        y = y + createTabIntro(scrollChild, "Find pets by how they're obtained.", y)
        
        y = y + createAccordionSection(scrollChild, categoryId, "acq_source", "Source Type", y, function(content)
            local cy = 0
            local boxWidth, boxHeight = createTokenBox(content, "Tokens", {
                "wild", "vendor", "drop", "achievement (achi)",
                "quest", "promotion (promo)", "event", "profession (prof)",
                "pet battle (battle)", "", "Prefix: source:value"
            }, cy)
            local leftWidth = content:GetWidth() - boxWidth - CONTENT_INDENT - 12
            
            cy = cy + createDescription(content, "Filter by acquisition method. Use source: prefix for exact matching.", cy, leftWidth)
            
            local examples = {
                {"wild unowned", "Wild pets still needed"},
                {"source:vendor", "Only vendor pets (exact)"},
                {"battle", "Pets from Pet Battles"},
            }
            cy = cy + createExamplesSection(content, examples, cy, leftWidth)
            return math.max(cy, boxHeight)
        end)
        
        y = y + createAccordionSection(scrollChild, categoryId, "acq_location", "Location / Vendor", y, function(content)
            local cy = 0
            cy = cy + createDescription(content, "Search zones or vendor names.", cy)
            
            local examples = {
                {"stormwind", "Pets from Stormwind"},
                {"breanni", "Pets sold by vendor Breanni"},
            }
            cy = cy + createExamplesSection(content, examples, cy, content:GetWidth() - CONTENT_INDENT)
            return cy
        end)
    
    -- ========================================================================
    -- COLLECTION
    -- ========================================================================
    elseif categoryId == "collection" then
        y = y + createTabIntro(scrollChild, "Manage your collection efficiently.", y)
        
        y = y + createAccordionSection(scrollChild, categoryId, "coll_ownership", "Ownership", y, function(content)
            local cy = 0
            local boxWidth, boxHeight = createTokenBox(content, "Tokens", {"owned", "unowned"}, cy)
            local leftWidth = content:GetWidth() - boxWidth - CONTENT_INDENT - 12
            
            cy = cy + createDescription(content, "Overrides the dropdown filter.", cy, leftWidth)
            
            local examples = {
                {"unowned", "Pets you're missing"},
            }
            cy = cy + createExamplesSection(content, examples, cy, leftWidth)
            return math.max(cy, boxHeight)
        end)
        
        y = y + createAccordionSection(scrollChild, categoryId, "coll_count", "Count (Copies Owned)", y, function(content)
            local cy = 0
            local boxWidth, boxHeight = createTokenBox(content, "Syntax", {"count:N", "count:>=N", "count:<N", "count:N-N", "", "N = 0-3"}, cy)
            local leftWidth = content:GetWidth() - boxWidth - CONTENT_INDENT - 12
            
            cy = cy + createDescription(content, "Filter by how many copies of a species you own.", cy, leftWidth)
            
            local examples = {
                {"!unique count:<3", "Species you can still collect more of"},
                {"count:3 !rare", "Maxed species that need a rare upgrade"},
            }
            cy = cy + createExamplesSection(content, examples, cy, leftWidth)
            return math.max(cy, boxHeight)
        end)
        
        y = y + createAccordionSection(scrollChild, categoryId, "coll_flags", "Collection Flags", y, function(content)
            local cy = 0
            local synonymTooltip = "tradable and cageable are synonyms"
            local boxWidth, boxHeight = createTokenBox(content, "Tokens", {
                "unique",
                "duplicate (dupl)",
                {text = "tradable (trad)*", tooltip = synonymTooltip},
                {text = "cageable (cage)*", tooltip = synonymTooltip},
            }, cy)
            local leftWidth = content:GetWidth() - boxWidth - CONTENT_INDENT - 12
            
            cy = cy + createDescription(content, "Special collection properties.", cy, leftWidth)
            
            local examples = {
                {"unique unowned", "Unique pets you're missing"},
                {"trad rare 25", "Cageable battle-ready pets to sell"},
            }
            cy = cy + createExamplesSection(content, examples, cy, leftWidth)
            return math.max(cy, boxHeight)
        end)
    
    -- ========================================================================
    -- COMBAT
    -- ========================================================================
    elseif categoryId == "combat" then
        y = y + createTabIntro(scrollChild, "Build effective battle teams.", y)
        
        y = y + createAccordionSection(scrollChild, categoryId, "combat_vs", "vs:family - Strong Against", y, function(content)
            local cy = 0
            cy = cy + createDescription(content, "Find pets with abilities that deal +50% damage against a family.", cy)
            
            local examples = {
                {"vs:beast 25", "Prep for a battle against Beast pets"},
                {"vs:magic rare owned", "Your best options against Magic pets"},
            }
            cy = cy + createExamplesSection(content, examples, cy, content:GetWidth() - CONTENT_INDENT)
            return cy
        end)
        
        y = y + createAccordionSection(scrollChild, categoryId, "combat_damage", "family:damage - Damage Type", y, function(content)
            local cy = 0
            cy = cy + createDescription(content, "Find pets with abilities of a specific damage type.", cy)
            
            local examples = {
                {"mechanical:damage", "Pets with Mechanical-type attacks"},
                {"beast:damage !beast", "Non-Beasts with Beast damage"},
            }
            cy = cy + createExamplesSection(content, examples, cy, content:GetWidth() - CONTENT_INDENT)
            return cy
        end)
        
        y = y + createAccordionSection(scrollChild, categoryId, "combat_counter", "counter:family - Double Counter", y, function(content)
            local cy = 0
            cy = cy + createDescription(content, "Strong against target and target is weak against them.", cy)
            
            local examples = {
                {"counter:aquatic", "Counter Aquatic enemies"},
                {"counter:mech 25", "Max-level Mechanical counters"},
            }
            cy = cy + createExamplesSection(content, examples, cy, content:GetWidth() - CONTENT_INDENT)
            return cy
        end)
    
    -- ========================================================================
    -- CONDITIONS
    -- ========================================================================
    elseif categoryId == "conditions" then
        y = y + createTabIntro(scrollChild, "Filter by dynamic conditions.", y)
        
        y = y + createAccordionSection(scrollChild, categoryId, "cond_spawn", "conditional / cond", y, function(content)
            local cy = 0
            cy = cy + createDescription(content, "Wild pets that only spawn under specific conditions.", cy)
            
            local examples = {
                {"cond unowned", "Conditional spawns you still need"},
                {"cond wild", "All wild pets with spawn conditions"},
            }
            cy = cy + createExamplesSection(content, examples, cy, content:GetWidth() - CONTENT_INDENT)
            return cy
        end)
        
        y = y + createAccordionSection(scrollChild, categoryId, "cond_upgrade", "upgradeable / upgrade", y, function(content)
            local cy = 0
            cy = cy + createDescription(content, "Pets you can upgrade with stones in your bags.", cy)
            
            local examples = {
                {"upgrade", "All pets you can upgrade now"},
                {"upgrade beast", "Beasts ready for a stone"},
            }
            cy = cy + createExamplesSection(content, examples, cy, content:GetWidth() - CONTENT_INDENT)
            return cy
        end)
        
        y = y + createAccordionSection(scrollChild, categoryId, "cond_family", "family-bottom:N / family-top:N", y, function(content)
            local cy = 0
            cy = cy + createDescription(content, "Focus on your least or most represented families.", cy)
            
            local examples = {
                {"family-bottom:3 unowned", "Fill gaps in your 3 weakest families"},
                {"family-top:1 rare 25", "Battle-ready pets in your strongest family"},
            }
            cy = cy + createExamplesSection(content, examples, cy, content:GetWidth() - CONTENT_INDENT)
            return cy
        end)
    end
    
    scrollChild:SetHeight(math.max(y + 16, scrollFrame:GetHeight() + 1))
    C_Timer.After(0.01, updateScrollbarVisibility)
    
    return scrollChild
end

-- ============================================================================
-- TAB BUTTONS
-- ============================================================================

local function applyTabState(button, state)
    local bg, text
    
    if state == "active" then
        bg = COLORS.activeBg
        text = COLORS.activeText
        if button.borders then button.borders.right:Hide() end
        if button.lineCover then button.lineCover:Show() end
    elseif state == "hover" then
        bg = COLORS.hoverBg
        text = COLORS.hoverText
        if button.borders then button.borders.right:Show() end
        if button.lineCover then button.lineCover:Hide() end
    else
        bg = COLORS.inactiveBg
        text = COLORS.inactiveText
        if button.borders then button.borders.right:Show() end
        if button.lineCover then button.lineCover:Hide() end
    end
    
    if button.background then
        button.background:SetColorTexture(bg[1], bg[2], bg[3], bg[4] or 1)
    end
    
    if button.borders then
        local borderColor = (state == "active") and COLORS.activeBorder or COLORS.inactiveBorder
        button.borders.top:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
        button.borders.left:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
        button.borders.bottom:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
        button.borders.right:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4] or 1)
    end
    
    if button.label then
        button.label:SetTextColor(text[1], text[2], text[3], text[4] or 1)
    end
end

local function createTabButton(parent, categoryData, index)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(TAB_WIDTH, TAB_HEIGHT)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -((index - 1) * (TAB_HEIGHT + TAB_SPACING)))
    
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    btn.background = bg
    
    local lineCover = btn:CreateTexture(nil, "ARTWORK", nil, 7)
    lineCover:SetWidth(1)
    lineCover:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 1, 1)
    lineCover:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
    lineCover:SetColorTexture(COLORS.activeBg[1], COLORS.activeBg[2], COLORS.activeBg[3], 1)
    lineCover:Hide()
    btn.lineCover = lineCover
    
    local borders = {}
    borders.top = btn:CreateTexture(nil, "BORDER")
    borders.top:SetHeight(1)
    borders.top:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    borders.top:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    
    borders.left = btn:CreateTexture(nil, "BORDER")
    borders.left:SetWidth(1)
    borders.left:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    borders.left:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    
    borders.bottom = btn:CreateTexture(nil, "BORDER")
    borders.bottom:SetHeight(1)
    borders.bottom:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    borders.bottom:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    
    borders.right = btn:CreateTexture(nil, "BORDER")
    borders.right:SetWidth(1)
    borders.right:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
    borders.right:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    btn.borders = borders
    
    local label = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("CENTER", btn, "CENTER", 0, 0)
    label:SetText(categoryData.name)
    btn.label = label
    
    btn.categoryId = categoryData.id
    btn._isSelected = false
    
    btn:SetScript("OnEnter", function(self)
        if not self._isSelected then applyTabState(self, "hover") end
    end)
    btn:SetScript("OnLeave", function(self)
        applyTabState(self, self._isSelected and "active" or "inactive")
    end)
    
    applyTabState(btn, "inactive")
    tabButtons[categoryData.id] = btn
    return btn
end

-- ============================================================================
-- MAIN FRAME
-- ============================================================================

local function createHelpFrame()
    helpFrame = CreateFrame("Frame", ADDON_NAME .. "FilterHelp", UIParent, "PortraitFrameTemplate")
    helpFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    helpFrame:SetPoint("CENTER")
    helpFrame:EnableMouse(true)
    helpFrame:SetMovable(true)
    helpFrame:RegisterForDrag("LeftButton")
    helpFrame:SetScript("OnDragStart", helpFrame.StartMoving)
    helpFrame:SetScript("OnDragStop", helpFrame.StopMovingOrSizing)
    helpFrame:SetToplevel(true)
    helpFrame:Hide()
    
    table.insert(UISpecialFrames, ADDON_NAME .. "FilterHelp")
    
    helpFrame:SetTitle("Filter Reference")
    
    local PORTRAIT_ICON = "Interface\\AddOns\\PawAndOrder\\textures\\info-icon.png"
    if helpFrame.SetPortraitTextureRaw then
        helpFrame:SetPortraitTextureRaw(PORTRAIT_ICON)
    elseif helpFrame.portrait then
        helpFrame.portrait:SetTexture(PORTRAIT_ICON)
    end
    
    if helpFrame.portrait then
        helpFrame.portrait:SetSize(72, 72)
    end
    
    local PORTRAIT_CLEARANCE = 60
    local tabContainer = CreateFrame("Frame", nil, helpFrame)
    tabContainer:SetPoint("TOPLEFT", helpFrame, "TOPLEFT", 8, -(PORTRAIT_CLEARANCE + 8))
    tabContainer:SetSize(TAB_WIDTH, (#CATEGORIES * (TAB_HEIGHT + TAB_SPACING)))
    
    local verticalBorderLine = helpFrame:CreateTexture(nil, "BORDER", nil, 0)
    verticalBorderLine:SetWidth(1)
    verticalBorderLine:SetPoint("TOPLEFT", tabContainer, "TOPRIGHT", 0, 1)
    verticalBorderLine:SetPoint("BOTTOMLEFT", helpFrame, "BOTTOMLEFT", TAB_WIDTH + 8, 8)
    verticalBorderLine:SetColorTexture(COLORS.contentBorder[1], COLORS.contentBorder[2], COLORS.contentBorder[3], 1)
    
    local contentBg = helpFrame:CreateTexture(nil, "BACKGROUND")
    contentBg:SetPoint("TOPLEFT", helpFrame, "TOPLEFT", TAB_WIDTH + 9, -28)
    contentBg:SetPoint("BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", -8, 8)
    contentBg:SetColorTexture(COLORS.contentBg[1], COLORS.contentBg[2], COLORS.contentBg[3], COLORS.contentBg[4])
    
    contentScrollFrame = CreateFrame("ScrollFrame", ADDON_NAME .. "FilterHelpScroll", helpFrame, "UIPanelScrollFrameTemplate")
    contentScrollFrame:SetPoint("TOPLEFT", helpFrame, "TOPLEFT", TAB_WIDTH + 14, -32)
    contentScrollFrame:SetPoint("BOTTOMRIGHT", helpFrame, "BOTTOMRIGHT", -10, 12)
    contentScrollFrame:EnableMouse(true)
    contentScrollFrame:SetScript("OnMouseDown", function()
        hideFloatingPreview()
    end)
    
    -- Hide scrollbar - content is designed to fit
    local scrollBar = _G[contentScrollFrame:GetName() .. "ScrollBar"]
    if scrollBar then
        scrollBar:Hide()
        scrollBar:SetAlpha(0)
    end
    
    local buttons = {}
    for i, catData in ipairs(CATEGORIES) do
        local btn = createTabButton(tabContainer, catData, i)
        table.insert(buttons, btn)
        
        btn:SetScript("OnClick", function(self)
            for _, b in ipairs(buttons) do
                b._isSelected = false
                applyTabState(b, "inactive")
            end
            self._isSelected = true
            applyTabState(self, "active")
            createCategoryContent(contentScrollFrame, self.categoryId)
        end)
    end
    
    buttons[1]:Click()
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function filterHelp:createHelpIcon(filterBox)
    local helpIcon = CreateFrame("Button", nil, filterBox)
    helpIcon:SetSize(16, 16)
    helpIcon:SetPoint("RIGHT", filterBox, "RIGHT", -28, 0)
    
    helpIcon:SetNormalTexture("Interface\\Common\\help-i")
    helpIcon:SetHighlightTexture("Interface\\Common\\help-i")
    helpIcon:GetHighlightTexture():SetAlpha(0.5)
    
    helpIcon:SetScript("OnClick", function() filterHelp:show() end)
    helpIcon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Filter Help")
        GameTooltip:AddLine("Click for filter syntax guide", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    helpIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    return helpIcon
end

function filterHelp:show()
    if not helpFrame then createHelpFrame() end
    helpFrame:Show()
    helpFrame:Raise()  -- Bring to front if already open
end

function filterHelp:hide()
    if helpFrame then helpFrame:Hide() end
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("filterHelp", {"utils", "petCache", "petFilters", "petRowButton"}, function()
        return true
    end)
end

Addon.filterHelp = filterHelp
return filterHelp