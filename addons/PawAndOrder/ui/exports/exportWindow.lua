-- ui/exports/exportWindow.lua - Data Export Window with Registry Integration
-- luacheck: globals ChatFontNormal pao_settings pao_ability C_Timer GetTime UIParent
local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in exportWindow.|r")
    return
end

local utils = Addon.utils

-- Configuration
local MIN_FILTER_LENGTH = 3
local FILTER_DEBOUNCE_DELAY = 0.3
local MAX_DISPLAYED_MATCHES = 500

-- State
local exportWindow
local filterTimer

-- Magic number cache for abilities
local magicNumberCache = {}
local function buildMagicNumberCache()
    if next(magicNumberCache) then return end
    
    if pao_ability then
        for id, ability in pairs(pao_ability) do
            if ability.name then
                magicNumberCache[tonumber(id)] = ability.name
            end
        end
    end
end

-- Expand magic numbers in filter text
local function expandMagicNumbers(value, filterText)
    local expansions = {}
    
    if magicNumberCache[value] then
        table.insert(expansions, magicNumberCache[value])
    end
    
    return expansions
end

-- Recursive search through table values
local function searchTableValues(tbl, filterText, visitedTables)
    if type(tbl) ~= "table" then
        return false
    end
    
    if not filterText or filterText == "" then
        return false
    end
    
    buildMagicNumberCache()
    
    visitedTables = visitedTables or {}
    if visitedTables[tbl] then
        return false
    end
    visitedTables[tbl] = true
    
    local lowerFilter = filterText:lower()
    local uiUtils = Addon.uiUtils
    
    for key, value in pairs(tbl) do
        local valueType = type(value)
        
        if valueType == "string" and value ~= "" then
            local cleanValue = uiUtils:stripColorCodes(value):lower()
            if cleanValue:find(lowerFilter, 1, true) then
                return true
            end
        elseif valueType == "number" then
            local expandedTexts = expandMagicNumbers(value, filterText)
            for _, expandedText in ipairs(expandedTexts) do
                local cleanText = uiUtils:stripColorCodes(expandedText):lower()
                if cleanText:find(lowerFilter, 1, true) then
                    return true
                end
            end
        elseif valueType == "table" then
            if searchTableValues(value, filterText, visitedTables) then
                return true
            end
        end
    end
    
    return false
end

-- Create filtered export with match limiting
local function createFilteredExport(data, filterText)
    if not filterText or filterText == "" or #filterText < MIN_FILTER_LENGTH then
        return Addon.exportFormatter.toLuaTable(data), 0, 0
    end
    
    if not data then
        return "-- No data available", 0, 0
    end
    
    if type(data) ~= "table" then
        return "-- Data is not a table", 0, 0
    end
    
    if not Addon.exportFormatter then
        return "-- Export formatter not loaded", 0, 0
    end
    
    local matchingItems = {}
    local totalMatches = 0
    
    for key, value in pairs(data) do
        if searchTableValues(value, filterText) then
            table.insert(matchingItems, {key = key, value = value})
            totalMatches = totalMatches + 1
        end
    end
    
    if totalMatches == 0 then
        return "-- No matches found for \"" .. filterText .. "\"", 0, 0
    end
    
    local filteredData = {}
    local displayedMatches = 0
    
    for i, item in ipairs(matchingItems) do
        if displayedMatches >= MAX_DISPLAYED_MATCHES then
            break
        end
        filteredData[item.key] = item.value
        displayedMatches = displayedMatches + 1
    end
    
    local result = Addon.exportFormatter.toLuaTable(filteredData)
    
    if totalMatches > MAX_DISPLAYED_MATCHES then
        result = result .. "\n\n-- Showing " .. displayedMatches .. " of " .. totalMatches .. " matches"
    end
    
    return result, displayedMatches, totalMatches
end

-- Debounced filter application
local function scheduleFilterUpdate(frame)
    if filterTimer then
        filterTimer:Cancel()
    end
    
    filterTimer = C_Timer.NewTimer(FILTER_DEBOUNCE_DELAY, function()
        if frame and frame.Refresh then
            local startTime = GetTime()
            frame:Refresh()
            local endTime = GetTime()
            
            if endTime - startTime > 1.0 then
                utils:debug("Export filter took " .. string.format("%.2f", endTime - startTime) .. " seconds")
            end
        end
        filterTimer = nil
    end)
end

-- Estimate text height for dynamic sizing
local function estimateTextHeight(text, width, fontName)
    local font = _G[fontName] or ChatFontNormal
    local _, fontHeight = font:GetFont()
    if not fontHeight then fontHeight = 14 end
    
    local charWidth = fontHeight * 0.6
    local charsPerLine = math.max(1, math.floor(width / charWidth))
    local lines = math.ceil(#text / charsPerLine)
    
    return lines * fontHeight * 1.2
end

-- Save window position and size
local function saveWindowSettings(frame)
    if not frame then return end
    
    pao_settings = pao_settings or {}
    pao_settings.exportWindow = pao_settings.exportWindow or {}
    
    local point, _, relativePoint, x, y = frame:GetPoint()
    pao_settings.exportWindow.point = point
    pao_settings.exportWindow.relativePoint = relativePoint
    pao_settings.exportWindow.x = x
    pao_settings.exportWindow.y = y
    pao_settings.exportWindow.width = frame:GetWidth()
    pao_settings.exportWindow.height = frame:GetHeight()
end

-- Load window position and size
local function loadWindowSettings(frame)
    if not frame or not pao_settings or not pao_settings.exportWindow then
        return
    end
    
    local settings = pao_settings.exportWindow
    
    if settings.width and settings.height then
        frame:SetSize(settings.width, settings.height)
    end
    
    if settings.point and settings.x and settings.y then
        frame:ClearAllPoints()
        frame:SetPoint(settings.point, UIParent, settings.relativePoint or settings.point, settings.x, settings.y)
    end
end

-- Create the export window
local function createWindow()
    local frame = Addon.popupFactory:create({
        title = "Data Export",
        icon = "Interface\\Icons\\INV_Misc_Book_09",
        width = 650,
        height = 550
    })
    
    -- Layout constants
    local PADDING_H = 16        -- Horizontal padding from frame edge
    local PADDING_BOTTOM = 16   -- Bottom padding
    local BOTTOM_BAR_HEIGHT = 32
    
    -- Enable resizing
    frame:SetResizable(true)

    -- Resize handle
    local resize = CreateFrame("Button", nil, frame)
    resize:SetSize(16, 16)
    resize:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resize:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    
    resize:SetScript("OnMouseDown", function(self)
        frame:StartSizing("BOTTOMRIGHT")
    end)
    
    resize:SetScript("OnMouseUp", function(self)
        frame:StopMovingOrSizing()
        saveWindowSettings(frame)
        if frame.Refresh then
            frame:Refresh()
        end
    end)

    -- Filter row (label + input on same line)
    local filterLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    filterLabel:SetPoint("TOPLEFT", frame.contentAnchor, "TOPLEFT", PADDING_H, -8)
    filterLabel:SetText("Filter (min " .. MIN_FILTER_LENGTH .. " chars):")
    
    local textBox = Addon.textBox
    local filterBox = textBox:create({
        parent = frame,
        width = 200,
        maxLetters = 50,
        placeholder = "Search...",
        onTextChanged = function(text)
            frame.filterText = text
            scheduleFilterUpdate(frame)
        end,
        onEscapePressed = function()
            -- textBox already clears focus
        end,
    })
    filterBox:SetPoint("LEFT", filterLabel, "RIGHT", 8, 0)

    -- Scroll frame (main content area)
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", filterLabel, "BOTTOMLEFT", 0, -10)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, PADDING_BOTTOM + BOTTOM_BAR_HEIGHT + 8)

    -- Edit box (scrollable content)
    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(scroll:GetWidth() - 20)
    editBox:SetAutoFocus(false)
    scroll:SetScrollChild(editBox)
    
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    
    editBox:SetScript("OnTextChanged", function(self)
        if self.originalText and self:GetText() ~= self.originalText then
            self:SetText(self.originalText)
            self:HighlightText()
        end
    end)

    -- Bottom bar
    local bottomBar = CreateFrame("Frame", nil, frame)
    bottomBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PADDING_H, PADDING_BOTTOM)
    bottomBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PADDING_H, PADDING_BOTTOM)
    bottomBar:SetHeight(BOTTOM_BAR_HEIGHT)

    -- Select All button
    local selectBtn = CreateFrame("Button", nil, bottomBar, "UIPanelButtonTemplate")
    selectBtn:SetSize(90, 24)
    selectBtn:SetPoint("RIGHT", bottomBar, "RIGHT", 0, 0)
    selectBtn:SetText("Select All")
    selectBtn:SetScript("OnClick", function()
        frame.editBox:SetFocus()
        frame.editBox:HighlightText()
    end)

    -- Match counter
    local matchCounter = bottomBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    matchCounter:SetPoint("RIGHT", selectBtn, "LEFT", -12, 0)
    matchCounter:SetText("")

    frame.editBox = editBox
    frame.scroll = scroll
    frame.filterBox = filterBox
    frame.filterLabel = filterLabel
    frame.selectBtn = selectBtn
    frame.matchCounter = matchCounter
    frame.filterText = ""

    function frame:Refresh()
        if not Addon.exportFormatter then
            self.editBox:SetText("Export formatter not loaded")
            self.editBox.originalText = "Export formatter not loaded"
            self.matchCounter:SetText("")
            return
        end

        local startTime = GetTime()
        
        local filteredData, displayedMatches, totalMatches = createFilteredExport(self.data, self.filterText)
        
        local endTime = GetTime()
        local processingTime = endTime - startTime
        
        if processingTime > 0.5 then
            utils:debug("Export processing took " .. string.format("%.2f", processingTime) .. " seconds")
        end
        
        self.editBox:SetText(filteredData)
        self.editBox.originalText = filteredData

        if self.filterText and #self.filterText >= MIN_FILTER_LENGTH then
            if totalMatches == 0 then
                self.matchCounter:SetText("|cFFFF0000No matches|r")
            elseif totalMatches > MAX_DISPLAYED_MATCHES then
                self.matchCounter:SetText("|cFFFF8000Showing " .. displayedMatches .. " of " .. totalMatches .. "|r")
            elseif totalMatches == 1 then
                self.matchCounter:SetText("|cFF00FF001 match|r")
            else
                self.matchCounter:SetText("|cFF00FF00" .. totalMatches .. " matches|r")
            end
        else
            self.matchCounter:SetText("")
        end

        local scrollWidth = self.scroll:GetWidth() - 20
        if scrollWidth > 0 then
            self.editBox:SetWidth(scrollWidth)
            local textHeight = estimateTextHeight(filteredData, scrollWidth, "ChatFontNormal")
            self.editBox:SetHeight(math.max(textHeight + 20, self.scroll:GetHeight()))
        end
    end

    frame:SetScript("OnHide", function(self)
        saveWindowSettings(self)
        if filterTimer then
            filterTimer:Cancel()
            filterTimer = nil
        end
    end)

    exportWindow = frame
end

-- Show export window with data
local function showExportWindow(data)
    if not exportWindow then
        createWindow()
        loadWindowSettings(exportWindow)
    end

    exportWindow.data = data
    exportWindow.filterText = ""
    if exportWindow.filterBox then
        exportWindow.filterBox:SetText("")
    end
    if exportWindow.matchCounter then
        exportWindow.matchCounter:SetText("")
    end
    exportWindow:Refresh()
    exportWindow:Show()
end

-- Module interface
Addon.ui = Addon.ui or {}
Addon.ui.showExportWindow = showExportWindow

-- Event-driven initialization
local evt = CreateFrame("Frame")
evt:RegisterEvent("ADDON_LOADED")
evt:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= "PawAndOrder" then
        return
    end

    if not Addon.commands then
        utils:debug("Export: Commands system not available yet")
        return
    end

    if not Addon.exports then
        utils:debug("Export: Exports registry not available yet")
        return
    end

    Addon.commands:register({
        command = "export",
        aliases = {"dump", "view"},
        handler = function(args)
            local dataType = args.type:lower()
            
            -- Get data from exports registry
            local data = Addon.exports:get(dataType)
            
            if not data then
                local validTypes = table.concat(Addon.exports:getAllNames(), ", ")
                if validTypes == "" then
                    utils:error("No export types registered yet")
                else
                    utils:error("Invalid type: " .. tostring(dataType) .. ". Valid types: " .. validTypes)
                end
                return
            end
            
            showExportWindow(data)
        end,
        help = "Open data export window",
        usage = "export |cFFFFCC9A<type>|r",
        args = {
            {
                name = "type",
                required = true,
                description = "Data to export (use /pao export to see valid types)",
            }
        },
        detailedHelp = [[
Opens a scrollable export window with section-aware filtering.

Export types are dynamically registered by data modules.
Available types shown in error message when invalid type used.

Filtering requires minimum ]] .. MIN_FILTER_LENGTH .. [[ characters to prevent UI freezes.
Magic number expansion: ability IDs are expanded to ability names in filters.
]],
        category = "Development"
    })
end)