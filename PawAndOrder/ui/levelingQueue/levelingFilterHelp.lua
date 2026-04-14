--[[
  ui/levelingQueue/levelingFilterHelp.lua
  Leveling Filter Help Popup
  
  Modal popup showing available filter syntax for leveling queues.
  Similar to filterHelp.lua in pet collection but focused on leveling.
  
  Dependencies: utils
  Exports: Addon.levelingFilterHelp
]]

local ADDON_NAME, Addon = ...

local levelingFilterHelp = {}

-- Module references
local utils

-- UI state
local popup = nil
local overlay = nil

-- Layout
local LAYOUT = {
    WIDTH = 480,
    MAX_HEIGHT = 500,
    PADDING = 16,
    SECTION_GAP = 12,
    ROW_HEIGHT = 18,
}

-- Filter syntax sections
local SECTIONS = {
    {
        title = "RARITY",
        items = {
            { code = "rare", desc = "Rare quality pets" },
            { code = "uncommon", desc = "Uncommon quality pets" },
            { code = "!rare", desc = "NOT rare (common, uncommon, poor)" },
        },
    },
    {
        title = "OWNERSHIP",
        items = {
            { code = "unique", desc = "Pets you own exactly one copy of" },
            { code = "copies:>1", desc = "Pets with multiple copies" },
            { code = "copies:1", desc = "Pets with exactly 1 copy" },
        },
    },
    {
        title = "FAMILY",
        items = {
            { code = "beast", desc = "Beast family pets" },
            { code = "dragonkin", desc = "Dragonkin, flying, mechanical, etc." },
            { code = "family-bottom:3", desc = "Pets from your 3 smallest families" },
            { code = "family-top:3", desc = "Pets from your 3 largest families" },
        },
    },
    {
        title = "LEVEL",
        items = {
            { code = "level:<10", desc = "Pets below level 10" },
            { code = "level:1-9", desc = "Pets level 1 through 9" },
            { code = "level:1", desc = "Exactly level 1" },
        },
    },
    {
        title = "COMBINING FILTERS",
        items = {
            { code = "rare beast", desc = "Rare AND Beast" },
            { code = "rare !mechanical", desc = "Rare but NOT Mechanical" },
            { code = "unique level:<10", desc = "Unique pets below level 10" },
        },
    },
    {
        title = "NOTES",
        notes = {
            "All queues implicitly filter to owned pets below level 25",
            "Empty filter = all levelable pets",
            "Filters are case-insensitive",
        },
    },
}

-- ============================================================================
-- POPUP CREATION
-- ============================================================================

local function createPopup()
    if popup then return popup end
    
    -- Overlay
    overlay = CreateFrame("Frame", nil, UIParent)
    overlay:SetFrameStrata("DIALOG")
    overlay:SetAllPoints()
    overlay:EnableMouse(true)
    overlay:SetScript("OnMouseDown", function()
        levelingFilterHelp:hide()
    end)
    overlay:Hide()
    
    local overlayBg = overlay:CreateTexture(nil, "BACKGROUND")
    overlayBg:SetAllPoints()
    overlayBg:SetColorTexture(0, 0, 0, 0.5)
    
    -- Popup frame
    popup = CreateFrame("Frame", "PAOLevelingFilterHelp", UIParent, "BackdropTemplate")
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(overlay:GetFrameLevel() + 10)
    popup:SetSize(LAYOUT.WIDTH, 400)
    popup:SetPoint("CENTER")
    popup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    popup:SetBackdropColor(0.08, 0.08, 0.12, 1)
    popup:SetBackdropBorderColor(0.4, 0.4, 0.5, 1)
    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
    popup:Hide()
    
    -- Header
    local header = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", popup, "TOPLEFT", LAYOUT.PADDING, -LAYOUT.PADDING)
    header:SetText("Filter Syntax")
    header:SetTextColor(1, 0.82, 0)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -4, -4)
    closeBtn:SetScript("OnClick", function()
        levelingFilterHelp:hide()
    end)
    
    -- Scroll frame for content
    local scrollFrame = CreateFrame("ScrollFrame", nil, popup, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", popup, "TOPLEFT", LAYOUT.PADDING, -LAYOUT.PADDING - 30)
    scrollFrame:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -LAYOUT.PADDING - 22, LAYOUT.PADDING)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    popup.scrollChild = scrollChild
    
    -- Populate content
    local yOff = 0
    
    for _, section in ipairs(SECTIONS) do
        -- Section title
        local title = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, yOff)
        title:SetText(section.title)
        title:SetTextColor(0.5, 0.7, 1)
        yOff = yOff - 20
        
        if section.items then
            for _, item in ipairs(section.items) do
                -- Code
                local code = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                code:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOff)
                code:SetWidth(140)
                code:SetJustifyH("LEFT")
                code:SetText(item.code)
                code:SetTextColor(0.5, 1, 0.5)
                
                -- Description
                local desc = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                desc:SetPoint("LEFT", code, "RIGHT", 10, 0)
                desc:SetText(item.desc)
                desc:SetTextColor(0.7, 0.7, 0.7)
                
                yOff = yOff - LAYOUT.ROW_HEIGHT
            end
        elseif section.notes then
            for _, note in ipairs(section.notes) do
                local noteText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                noteText:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, yOff)
                noteText:SetText(note)
                noteText:SetTextColor(0.6, 0.6, 0.6)
                yOff = yOff - LAYOUT.ROW_HEIGHT
            end
        end
        
        yOff = yOff - LAYOUT.SECTION_GAP
    end
    
    scrollChild:SetHeight(math.abs(yOff) + 20)
    
    -- Adjust popup height based on content
    local contentHeight = math.abs(yOff) + LAYOUT.PADDING * 2 + 40
    popup:SetHeight(math.min(contentHeight, LAYOUT.MAX_HEIGHT))
    
    -- ESC to close
    table.insert(UISpecialFrames, "PAOLevelingFilterHelp")
    
    return popup
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function levelingFilterHelp:show()
    createPopup()
    overlay:Show()
    popup:Show()
end

function levelingFilterHelp:hide()
    if overlay then overlay:Hide() end
    if popup then popup:Hide() end
end

function levelingFilterHelp:toggle()
    if popup and popup:IsVisible() then
        self:hide()
    else
        self:show()
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function levelingFilterHelp:initialize()
    utils = Addon.utils
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("levelingFilterHelp", {"utils"}, function()
        return levelingFilterHelp:initialize()
    end)
end

Addon.levelingFilterHelp = levelingFilterHelp
return levelingFilterHelp
