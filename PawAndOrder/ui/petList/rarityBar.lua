--[[
  ui/rarityBar.lua
  Interactive Rarity Bar Component
  
  Displays a proportional bar showing distribution of pets across four rarity levels
  (Poor, Common, Uncommon, Rare). Supports interactive filtering via click/shift-click
  on segments, with hover tooltips and visual feedback. Segments dynamically resize
  based on pet counts and integrate with the main filter system.
  
  Interaction Model:
    - Click segment: Toggle that rarity in filter
    - Shift+Click segment: Isolate that rarity (exclusive filter)
    - Hover: Shows count and filter instructions
  
  Dependencies: constants, utils
  Exports: Addon.rarityBar
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in rarityBar.lua.|r")
    return {}
end

local utils = Addon.utils
local constants

local rarityBar = {}

-- Module state
local barFrame = nil
local segments = {}
local onFilterChangeCallback = nil

--[[
  Get rarity color from constants
  Safe accessor with fallback to white if rarity index invalid.
  
  @param rarity number - Rarity index (1-4: Poor, Common, Uncommon, Rare)
  @return table - Color table with r, g, b fields (0-1 range)
]]
local function getRarityColor(rarity)
    return constants.RARITY_COLORS[rarity] or {r=1, g=1, b=1}
end

--[[
  Create rarity bar frame with interactive segments
  Builds the bar container and creates all four rarity segments with hover/click
  handlers. Segments are positioned horizontally and sized proportionally.
  
  @param parent frame - Parent frame to attach rarity bar to
  @return frame - The created rarity bar frame
]]
local function createBarFrame(parent)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 6, 4)
    bar:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 4)
    bar:SetHeight(constants.RARITY_BAR_HEIGHT)
    
    return bar
end

--[[
  Create interactive rarity segment
  Builds a clickable segment for a single rarity level with hover effects,
  count display, and filter integration. Handles both toggle and isolate modes.
  
  @param parent frame - Parent bar frame
  @param rarityIndex number - Rarity index (1-4: Poor, Common, Uncommon, Rare)
  @return frame - Configured segment button
]]
local function createSegment(parent, rarityIndex)
    local seg = CreateFrame("Button", nil, parent)
    seg:SetHeight(7)
    seg.rarityIndex = rarityIndex
    seg.defaultHeight = 7
    seg.hoverHeight = 22
    seg.count = 0
    
    -- Main colored background
    local bg = seg:CreateTexture(nil, "ARTWORK")
    bg:SetAllPoints()
    bg:SetColorTexture(1, 1, 1)
    seg.bg = bg
    
    -- Apply initial color
    local col = getRarityColor(rarityIndex)
    seg.bg:SetVertexColor(col.r, col.g, col.b)
    
    -- Count text (only visible on hover)
    local countText = seg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    countText:SetPoint("CENTER")
    countText:SetTextColor(1, 1, 1)
    countText:SetShadowOffset(1, -1)
    countText:Hide()
    seg.countText = countText
    
    -- Click handler - integrates with main filter
    -- Click handler - integrates with main filter
    seg:SetScript("OnClick", function(self, button)
        if not onFilterChangeCallback then return end
        
        -- Get current filter text from petList
        local petList = Addon.petList
        if not petList or not petList.getFilterText then return end
        
        local filterText = petList:getFilterText()
        
        -- Parse existing filter terms
        local terms = {}
        for term in string.gmatch((filterText or ""):lower(), "%S+") do
            table.insert(terms, term)
        end
        
        -- Extract non-rarity terms and active rarity filters
        local nonRarityTerms = {}
        local activeRarities = {}
        
        for _, term in ipairs(terms) do
            local isRarityTerm = false
            for rIdx = 1, 4 do
                local rarityName = constants.RARITY_NAMES[rIdx]
                if rarityName and term == rarityName:lower() then
                    activeRarities[rIdx] = true
                    isRarityTerm = true
                    break
                end
            end
            if not isRarityTerm then
                table.insert(nonRarityTerms, term)
            end
        end
        
        local rarityClicked = self.rarityIndex
        
        -- Determine new rarity selection based on modifier
        if IsShiftKeyDown() then
            -- Shift-click: Isolate this rarity
            activeRarities = {[rarityClicked] = true}
        else
            -- Normal click: Toggle this rarity
            if activeRarities[rarityClicked] then
                activeRarities[rarityClicked] = nil
            else
                activeRarities[rarityClicked] = true
            end
        end
        
        -- Rebuild filter text using natural language keywords
        local newTerms = {}
        for _, term in ipairs(nonRarityTerms) do
            table.insert(newTerms, term)
        end
        
        -- Add rarity keywords back
        local rarityKeywords = {}
        for rarityId, _ in pairs(activeRarities) do
            local keyword = constants.RARITY_NAMES[rarityId]
            if keyword then
                table.insert(rarityKeywords, keyword:lower())
            end
        end
        table.sort(rarityKeywords)
        for _, keyword in ipairs(rarityKeywords) do
            table.insert(newTerms, keyword)
        end
        
        local newText = table.concat(newTerms, " ")
        if newText == "" then
            newText = nil
        end
        
        -- Trigger callback to update filter
        onFilterChangeCallback(newText)
    end)
    
    -- Hover effects - grow taller, brighten, show count
    seg:SetScript("OnEnter", function(self)
        self:SetHeight(self.hoverHeight)
        local c = getRarityColor(self.rarityIndex)
        self.bg:SetVertexColor(math.min(c.r*1.3, 1), math.min(c.g*1.3, 1), math.min(c.b*1.3, 1))
        
        if self.count and self.count > 0 then
            self.countText:SetText(self.count)
            self.countText:Show()
        end
        
        local tip = Addon.tooltip
        if tip then
            tip:showWithHints(
                self,
                "Filter " .. (constants.RARITY_NAMES[self.rarityIndex] or "Unknown"),
                {"Shift-Click to isolate", "Click to toggle"},
                { anchor = "BOTTOM", relPoint = "TOP", offsetX = 0, offsetY = 5 }
            )
        end
    end)
    
    seg:SetScript("OnLeave", function(self)
        self:SetHeight(self.defaultHeight)
        local c = getRarityColor(self.rarityIndex)
        self.bg:SetVertexColor(c.r, c.g, c.b)
        self.countText:Hide()
        local tip = Addon.tooltip
        if tip then
            tip:hide()
        end
    end)
    
    return seg
end

--[[
  Initialize rarity bar module
  Creates the bar frame and all segments. Must be called before use.
  
  @param parentFrame frame - Parent frame to attach bar to
  @param filterCallback function - Callback for filter changes: function(newFilterText)
]]
function rarityBar:initialize(parentFrame, filterCallback)
    if barFrame then return end
    
    constants = Addon.constants
    if not constants then
        utils:error("Dependency missing: constants not available in rarityBar")
        return
    end
    
    onFilterChangeCallback = filterCallback
    
    -- Create bar frame
    barFrame = createBarFrame(parentFrame)
    
    -- Create all four rarity segments (1=Poor, 2=Common, 3=Uncommon, 4=Rare)
    for i = 1, 4 do
        segments[i] = createSegment(barFrame, i)
    end
end

--[[
  Update rarity bar display
  Resizes segments proportionally based on pet counts and shows/hides segments
  appropriately. Handles zero-count case by showing all segments with equal width.
  
  @param rarityStats table - Map of rarity index to count: {[1]=count, [2]=count, ...}
]]
function rarityBar:update(rarityStats)
    if not barFrame or not rarityStats then
        if barFrame then barFrame:Hide() end
        return
    end
    
    local totalOwned = 0
    for i = 1, 4 do
        totalOwned = totalOwned + (rarityStats[i] or 0)
    end
    
    -- Get bar width
    local barWidth = barFrame:GetWidth()
    if not barWidth or barWidth <= 0 then
        barWidth = barFrame:GetParent():GetWidth() - 26
    end
    
    -- Handle zero-count case: show all segments equally
    if totalOwned == 0 then
        local equalWidth = math.floor(barWidth / 4)
        for i = 1, 4 do
            local seg = segments[i]
            if seg then
                seg.count = 0
                seg:ClearAllPoints()
                seg:SetPoint("LEFT", barFrame, "LEFT", (i - 1) * equalWidth, 0)
                seg:SetWidth(equalWidth)
                seg:SetHeight(seg.defaultHeight)
                seg:SetAlpha(0.3)
                
                local col = getRarityColor(i)
                seg.bg:SetVertexColor(col.r, col.g, col.b)
                seg:Show()
            end
        end
        barFrame:Show()
        return
    end
    
    -- Proportional widths with minimum for zero-count segments
    local minWidth = 10
    local zeroCountSegs = 0
    for i = 1, 4 do
        if (rarityStats[i] or 0) == 0 then
            zeroCountSegs = zeroCountSegs + 1
        end
    end
    
    local reservedWidth = zeroCountSegs * minWidth
    local availableWidth = barWidth - reservedWidth
    
    local xOffset = 0
    for i = 1, 4 do
        local seg = segments[i]
        if not seg then
            utils:error("Rarity bar segment " .. i .. " not found")
            return
        end
        
        local cnt = rarityStats[i] or 0
        seg.count = cnt
        
        if cnt > 0 then
            local segWidth = math.floor((cnt / totalOwned) * availableWidth)
            seg:ClearAllPoints()
            seg:SetPoint("LEFT", barFrame, "LEFT", xOffset, 0)
            seg:SetWidth(segWidth)
            seg:SetHeight(seg.defaultHeight)
            seg:SetAlpha(1.0)
            
            local col = getRarityColor(i)
            seg.bg:SetVertexColor(col.r, col.g, col.b)
            
            seg:Show()
            xOffset = xOffset + segWidth
        else
            -- Show segment with minimal width when count is 0
            seg:ClearAllPoints()
            seg:SetPoint("LEFT", barFrame, "LEFT", xOffset, 0)
            seg:SetWidth(minWidth)
            seg:SetHeight(seg.defaultHeight)
            seg:SetAlpha(0.3)
            
            local col = getRarityColor(i)
            seg.bg:SetVertexColor(col.r, col.g, col.b)
            
            seg:Show()
            xOffset = xOffset + minWidth
        end
    end
    
    barFrame:Show()
end

--[[
  Show rarity bar
  Makes the bar visible without updating contents.
]]
function rarityBar:show()
    if barFrame then
        barFrame:Show()
    end
end

--[[
  Hide rarity bar
  Conceals the bar without destroying it.
]]
function rarityBar:hide()
    if barFrame then
        barFrame:Hide()
    end
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("rarityBar", {"constants", "utils"}, function()
        return true
    end)
end

Addon.rarityBar = rarityBar
return rarityBar