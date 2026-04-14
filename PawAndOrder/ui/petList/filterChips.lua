--[[
  ui/filterChips.lua
  Removable Filter Chips Component
  
  Displays removable filter chips below the search box, one chip per filter term.
  Each chip shows the filter keyword and an 'x' to remove it. Clicking a chip
  removes that term from the filter. Dynamically adjusts pet list top offset to
  accommodate chip height.
  
  Visual Example:
    [beast x] [rare x] [flying x]
  
  Integration:
    - Parent provides callback to update filter text when chip removed
    - Component manages chip creation, layout, and cleanup
    - Notifies infoPanel of height changes (which updates petList offset)
  
  Dependencies: utils
  Exports: Addon.filterChips
]]

local ADDON_NAME, Addon = ...

local filterChips = {}

-- Module reference (lazy-loaded)
local utils

-- UI State
local chipsFrame = nil
local onFilterChangeCallback = nil
local activeChips = {}
local chipPool = {}
local measureButton = nil  -- Reusable button for text measurement

-- Layout constants
local CHIP_HEIGHT = 20
local CHIP_SPACING = 4
local CHIP_TEXT_PADDING = 20
local CONTAINER_SPACING = 5

-- Terms to skip (handled by headerBar dropdown)
local SKIP_TERMS = {
    ["owned"] = true,
    ["unowned"] = true,
    ["!owned"] = true,
    ["!unowned"] = true,
}

--[[
  Strip quotes from term for display only
  The original term with quotes is preserved for filter reconstruction.
  
  @param term string - Filter term (may have quotes)
  @return string - Display text with " x" suffix
]]
local function getDisplayText(term)
    local display = term:match('^"(.-)"$') or term:match("^'(.-)'$") or term
    return display:lower() .. " x"
end

--[[
  Measure chip width using reusable hidden button
  Avoids creating/destroying buttons just to measure text.
  
  @param text string - Text to measure
  @return number - Width including padding
]]
local function measureChipWidth(text)
    if not measureButton then
        measureButton = CreateFrame("Button", nil, UIParent, "UIPanelButtonTemplate")
        measureButton:SetHeight(CHIP_HEIGHT)
        measureButton:Hide()
    end
    measureButton:SetText(text)
    return measureButton:GetTextWidth() + CHIP_TEXT_PADDING
end

--[[
  Initialize filter chips component
  Creates the container frame and stores the filter change callback.
  
  @param parentFrame frame - Parent frame to attach chips to
  @param filterBox frame - Filter box frame for positioning
  @param width number - Width of chip container
  @param callback function - Called when chip removed: function(newFilterText)
]]
function filterChips:initialize(parentFrame, filterBox, width, callback)
    if chipsFrame then return end
    
    utils = Addon.utils
    onFilterChangeCallback = callback
    
    chipsFrame = CreateFrame("Frame", nil, parentFrame)
    chipsFrame:SetPoint("TOPLEFT", filterBox, "BOTTOMLEFT", -7, -CONTAINER_SPACING)
    chipsFrame:SetSize(width, 50)
end

--[[
  Clear all existing chips
  Returns chips to pool for reuse.
]]
local function clearChips()
    if not chipsFrame then return end
    
    for _, chip in ipairs(activeChips) do
        chip:Hide()
        chip:ClearAllPoints()
        table.insert(chipPool, chip)
    end
    activeChips = {}
end

--[[
  Get or create a chip button
  Reuses pooled chips when available.
  
  @return Button - Chip button frame
]]
local function acquireChip()
    local chip = table.remove(chipPool)
    if not chip then
        chip = CreateFrame("Button", nil, chipsFrame, "UIPanelButtonTemplate")
        chip:SetHeight(CHIP_HEIGHT)
    end
    return chip
end

--[[
  Create a single chip button
  Builds a removable chip button for a filter term.
  
  @param term string - Filter term to display
  @param termIndex number - Index in terms array
  @param allTerms table - Complete array of filter terms
  @param xOffset number - Horizontal position
  @param yOffset number - Vertical position (for wrapping)
  @return number - Width of created chip
]]
local function createChip(term, termIndex, allTerms, xOffset, yOffset)
    local chip = acquireChip()
    chip:SetPoint("TOPLEFT", chipsFrame, "TOPLEFT", xOffset, yOffset or 0)
    chip:SetText(getDisplayText(term))
    
    chip:SetScript("OnClick", function()
        local remaining = {}
        for i, t in ipairs(allTerms) do
            if i ~= termIndex then
                table.insert(remaining, t)
            end
        end
        
        local newFilterText = (#remaining > 0) and table.concat(remaining, " ") or ""
        if onFilterChangeCallback then
            onFilterChangeCallback(newFilterText)
        end
    end)
    
    local width = chip:GetTextWidth() + CHIP_TEXT_PADDING
    chip:SetWidth(width)
    chip:Show()
    
    table.insert(activeChips, chip)
    
    return width
end

--[[
  Render filter chips from filter text
  Parses filter text into terms, creates a chip for each term with wrapping,
  and updates pet list offset to accommodate chip height.
  
  Note: owned/unowned terms are skipped since they're handled by headerBar dropdown.
  
  @param filterText string - Space-delimited filter terms
]]
function filterChips:render(filterText)
    if not chipsFrame then return end
    
    clearChips()
    
    -- Parse and filter terms
    local allTokens = utils:tokenize(filterText or "")
    local terms = {}
    for _, term in ipairs(allTokens) do
        if not SKIP_TERMS[term:lower()] then
            table.insert(terms, term)
        end
    end
    
    local chipHeight = 0
    
    if #terms > 0 then
        local containerWidth = chipsFrame:GetWidth()
        local xOffset = 0
        local yOffset = 0
        
        for i, term in ipairs(terms) do
            local displayText = getDisplayText(term)
            local chipWidth = measureChipWidth(displayText)
            
            -- Check if chip fits on current row
            if xOffset > 0 and xOffset + chipWidth > containerWidth then
                xOffset = 0
                yOffset = yOffset - (CHIP_HEIGHT + CHIP_SPACING)
            end
            
            createChip(term, i, terms, xOffset, yOffset)
            xOffset = xOffset + chipWidth + CHIP_SPACING
        end
        
        chipHeight = math.abs(yOffset) + CHIP_HEIGHT + CONTAINER_SPACING
    end
    
    -- Notify info panel of chips height change (infoPanel updates petList offset)
    if Addon.infoPanel and Addon.infoPanel.setChipsHeight then
        Addon.infoPanel:setChipsHeight(chipHeight)
    end
end

--[[
  Show chips frame
  Makes the chips container visible.
]]
function filterChips:show()
    if chipsFrame then
        chipsFrame:Show()
    end
end

--[[
  Hide chips frame
  Conceals the chips container.
]]
function filterChips:hide()
    if chipsFrame then
        chipsFrame:Hide()
    end
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("filterChips", {"utils"}, function()
        return true
    end)
end

Addon.filterChips = filterChips
return filterChips