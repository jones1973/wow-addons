--[[
  ui/optionsPanel.lua - Complete Options System
  
  Features:
  - Tab-based organization
  - Alt+Click labels to reset individual options
  - Reset All button in footer with change tracking
  - Extended help system (? icons)
  - Validation and dependency frameworks
  
  Dependencies: utils, petSorting, location, npcUtils
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in optionsPanel.lua.|r")
    return {}
end

local utils = Addon.utils
local optionsPanel = {}

-- Configuration constants
local PADDING = 16
local CHECKBOX_HEIGHT = 32
local DROPDOWN_HEIGHT = 54
local HEADER_HEIGHT = 32
local DROPDOWN_WIDTH = 110
local TAB_HEIGHT = 30
local FOOTER_HEIGHT = 50

-- Store references to all widgets
local allWidgets = {}
local activeHelpFrame = nil
local tabsSectionContainer = nil  -- Reference to tabs section for external refresh

--[[
  OPTION DEFINITIONS
  
  Fields:
  - type: header, checkbox, dropdown
  - key: SavedVariable key
  - label: Display text
  - tooltip: Hover description
  - extendedHelp: {title, description, why, example, technicalNote, related}
  - requiresReload: Show reload icon
  - enabledIf: function() return boolean end
  - validate: function(value) return valid, errorMsg end
  - onChange: function(value)
  - items: Array or function returning items (dropdowns)
  - displayText: function(value) return text end (dropdowns)
]]

local tabbedOptions = {
    {
        name = "General",
        options = {
            {type = "header", text = "General Settings"},
            {
                type = "checkbox",
                key = "showTrainerPopup",
                label = "Show Trainer Popup on level up",
                tooltip = "Display a popup window when you level up with suggestions for trainers to visit."
            },
            {
                type = "checkbox",
                key = "debugMode",
                label = "Enable Debug Mode",
                tooltip = "Show detailed debug messages in chat for addon development and troubleshooting.",
                onChange = function(value)
                    if Addon.utils then
                        Addon.utils:setDebugEnabled(value)
                    end
                end
            },
            {type = "header", text = "Recency Settings"},
            {
                type = "slider",
                key = "recentPetDays",
                label = "Recent Pet Days",
                tooltip = "Pets acquired within this many days are considered 'recent' and show a glow indicator. Also used by the 'recent' filter token.",
                min = 1,
                max = 90,
                step = 1,
                displayText = function(value) return tostring(math.floor(value)) .. " days" end,
            },
            {
                type = "slider",
                key = "recentAchievementDays",
                label = "Recent Achievement Days",
                tooltip = "Achievements completed within this many days appear in the 'Recent' section of the Achievements tab.",
                min = 1,
                max = 90,
                step = 1,
                displayText = function(value) return tostring(math.floor(value)) .. " days" end,
            },
        }
    },
    {
        name = "Pet Battle",
        options = {
            {type = "header", text = "Battle Settings"},
            {
                type = "checkbox",
                key = "autoTargetAfterWithdraw",
                label = "Auto-target wild pet after withdrawal",
                tooltip = "Automatically target the wild pet when you withdraw your current pet during battle."
            },
            {
                type = "checkbox",
                key = "wildPetMarkEnabled",
                label = "Mark wild pets with raid icons",
                tooltip = "Automatically marks wild battle pets with raid target icons when you target them. Makes it easy to find them again after forfeiting a battle."
            },
            {
                type = "dropdown",
                key = "wildPetMarkMode",
                label = "Marking Mode",
                tooltip = "How to select raid icons:\n- Fixed: Always use the same icon\n- Random: Shuffle icons 1-8 once, then cycle through shuffled order\n- Sequential: Cycle through icons 1->8->1 without randomization",
                enabledIf = function() return Addon.options:Get("wildPetMarkEnabled") end,
                items = {
                    {text = "Fixed Icon", value = "fixed"},
                    {text = "Random Order", value = "random"},
                    {text = "Sequential (1-8)", value = "sequential"}
                }
            },
            {
                type = "dropdown",
                key = "wildPetMarkIcon",
                label = "Fixed Icon Selection",
                tooltip = "Which raid icon to use when Marking Mode is set to Fixed",
                enabledIf = function() 
                    return Addon.options:Get("wildPetMarkEnabled") and 
                           Addon.options:Get("wildPetMarkMode") == "fixed"
                end,
                items = {
                    {text = "Star (Yellow)", value = 1, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1"},
                    {text = "Circle (Orange)", value = 2, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2"},
                    {text = "Diamond (Purple)", value = 3, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3"},
                    {text = "Triangle (Green)", value = 4, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4"},
                    {text = "Moon (White)", value = 5, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5"},
                    {text = "Square (Blue)", value = 6, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6"},
                    {text = "Cross (Red)", value = 7, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7"},
                    {text = "Skull (White)", value = 8, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"}
                }
            },
            {type = "header", text = "Quick Release"},
            {
                type = "dropdown",
                key = "forfeitButtonBehavior",
                label = "Forfeit Button Behavior",
                tooltip = "Controls what happens when you click the Forfeit button during a wild battle.\n\nEnhanced: Click shows quick release popup, Shift+click forfeits normally\nStandard: Click forfeits normally, Shift+click shows popup\nDisabled: Button always forfeits normally",
                extendedHelp = {
                    title = "Forfeit Button Behavior",
                    description = "The Quick Release feature lets you release one of your duplicate pets to make room for a capture, then re-engage the same wild pet.",
                    why = "This saves time when farming specific breeds or rarities. Instead of forfeiting, opening your journal, releasing a pet, finding the wild pet again, and starting a new battle - you can do it all in one step.",
                    example = "Fighting a rare P/P breed you want? Click forfeit, select that enemy, choose which of your pets to release, and you're back in battle with the same wild pet."
                },
                items = {
                    {text = "Enhanced (click = popup)", value = "enhanced"},
                    {text = "Standard (shift = popup)", value = "standard"},
                    {text = "Disabled", value = "disabled"}
                }
            },
        }
    },
    {
        name = "Notifications",
        options = {
            {type = "header", text = "Level 25 Celebration"},
            {
                type = "dropdown",
                key = "level25Action",
                label = "When pet reaches level 25",
                tooltip = "What happens when one of your battle pets reaches level 25 during battle.",
                items = {
                    {text = "Nothing (disabled)", value = "disabled"},
                    {text = "Show celebration popup", value = "popup"},
                    {text = "Popup + open journal", value = "journal"},
                }
            },
        }
    },
    {
        name = "Collection",
        options = {
            {type = "header", text = "List Display"},
            {
                type = "dropdown",
                key = "displayMode",
                label = "Display Mode",
                tooltip = "How pets are organized in the list.\n\nPets: One row per individual pet (classic layout).\nSpecies: Groups pets by species with expandable chip trays showing individual pets.",
                width = DROPDOWN_WIDTH,
                extendedHelp = {
                    title = "Display Mode",
                    description = "Controls how the pet list is organized. Pets mode shows one row per individual pet. Species mode groups pets by species, with compact 'chips' for each individual pet inside an expandable tray.",
                    why = "Species mode gives you a quick overview of your collection at the species level, with rarity pips showing collection completeness at a glance. Pets mode is the traditional flat list.",
                    example = "If you have 3 Alpine Hares, Species mode shows one Alpine Hare row with 3 colored pips. Click to expand and see each individual pet as a chip showing level, breed, and rarity."
                },
                items = {
                    {text = "Pets (Individual)", value = "pets"},
                    {text = "Species (Grouped)", value = "species"},
                }
            },
            {
                type = "dropdown",
                key = "defaultSort",
                label = "Default Sort",
                tooltip = "Default sort order for the pet list when opening the addon.",
                width = DROPDOWN_WIDTH,
                extendedHelp = {
                    title = "Default Sort Order",
                    description = "Controls how pets are sorted in the main pet list when you first open Paw and Order.",
                    why = "Different sorting orders help with different tasks. Sort by level to see which pets need leveling, by rarity to focus on upgrading quality, or by family for team building.",
                    example = "If you're focused on leveling pets, set this to 'Level' with 'Descending' direction to see your lowest level pets first."
                },
                items = function()
                    return Addon.petSorting and Addon.petSorting.getSortOptions 
                        and Addon.petSorting:getSortOptions() 
                        or {
                            {text = "Name", value = "name"},
                            {text = "Level", value = "level"},
                            {text = "Rarity", value = "rarity"},
                        }
                end
            },
            {
                type = "dropdown",
                key = "defaultSortDir",
                label = "Sort Direction",
                tooltip = "Default sort direction (ascending or descending).",
                width = DROPDOWN_WIDTH,
                items = function()
                    return {
                        {text = "Ascending", value = "asc"},
                        {text = "Descending", value = "desc"},
                    }
                end
            },
            {
                type = "dropdown",
                key = "defaultFilterMode",
                label = "Default Filter",
                tooltip = "Default filter mode when opening the addon (show all pets, only owned, or only unowned).",
                width = DROPDOWN_WIDTH,
                items = function()
                    return {
                        {text = "All", value = "all"},
                        {text = "Owned", value = "owned"},
                        {text = "Unowned", value = "unowned"},
                    }
                end
            },
            {
                type = "checkbox",
                key = "fadeLevelOpacity",
                label = "Fade Level by Progress",
                tooltip = "Fade level text opacity from 40% (level 1) to 100% (level 25) to show progression.",
                extendedHelp = {
                    title = "Fade Level by Progress",
                    description = "Adjusts the opacity of level text in the pet details panel based on how close the pet is to max level (25). Lower level pets appear more transparent, gradually becoming fully opaque as they approach level 25.",
                    why = "This visual cue helps you quickly identify which pets need leveling. Low-level pets 'fade into the background' while max-level pets stand out clearly, making it easier to prioritize your leveling efforts at a glance.",
                    example = "A level 1 pet displays at 40% opacity (very faint), while a level 25 pet displays at 100% opacity (fully visible). A level 13 pet would be around 70% opacity, halfway between the two extremes.",
                    images = {
                        {path = "Interface\\AddOns\\PawAndOrder\\textures\\level-opacity-low.png", caption = "Level 1 (40% opacity)"},
                        {path = "Interface\\AddOns\\PawAndOrder\\textures\\level-opacity-high.png", caption = "Level 25 (100% opacity)"}
                    }
                }
            },
            {
                type = "checkbox",
                key = "showNonCombatPets",
                label = "Show Non-Combat Pets",
                tooltip = "Display pets that cannot be used in pet battles (companion-only pets)."
            },
            {
                type = "checkbox",
                key = "showFilterInfoPanels",
                label = "Show filter information panels",
                tooltip = "Display contextual information about active filters below the filter chips."
            },
        }
    },
    {
        name = "Circuit",
        options = {
            {type = "header", text = "Circuit Planning"},
            {
                type = "dropdown",
                key = "defaultCircuitContinent",
                label = "Default Circuit Continent",
                tooltip = "Default continent to use when creating a new circuit.",
                width = DROPDOWN_WIDTH,
                extendedHelp = {
                    title = "Default Circuit Continent",
                    description = "Sets which continent's NPCs are shown first when you create a new circuit.",
                    why = "Saves time by pre-selecting the continent where you're currently leveling pets or farming battles.",
                    example = "If you're working on Pandaria tamers, set this to 'Pandaria' so you don't have to change it each time."
                },
                items = function()
                    local continents = {}
                    local seen = {}
                    
                    if Addon.npcUtils and Addon.npcUtils.getAllNpcs then
                        local allNpcs = Addon.npcUtils:getAllNpcs()
                        
                        for _, npc in pairs(allNpcs) do
                            local continent = npc.locations and npc.locations[1] and npc.locations[1].continent
                            if continent and not seen[continent] then
                                seen[continent] = true
                                local contName = "Unknown"
                                if type(continent) == "string" and continent == "darkmoon" then
                                    contName = "Darkmoon Faire"
                                elseif Addon.location then
                                    contName = Addon.location:getContinentName(continent) or "Unknown"
                                end
                                table.insert(continents, {
                                    id = continent,
                                    name = contName,
                                    text = contName,
                                    value = continent
                                })
                            end
                        end
                    end
                    
                    table.sort(continents, function(a, b) return a.name < b.name end)
                    return continents
                end,
                displayText = function(value)
                    if value == "darkmoon" then
                        return "Darkmoon Faire"
                    elseif Addon.location then
                        return Addon.location:getContinentName(value) or "Unknown"
                    end
                    return "Unknown"
                end
            },
            {
                type = "checkbox",
                key = "showCircuitOptimization",
                label = "Show route optimization in chat",
                tooltip = "Display a message showing how much shorter the optimized route is compared to nearest neighbor.",
                extendedHelp = {
                    title = "Route Optimization Display",
                    description = "When you start a circuit, shows a message in chat comparing the optimized route to a simple nearest-neighbor approach.",
                    why = "Helps you understand if circuit optimization is saving you significant travel time. Educational for understanding the value of route optimization.",
                    example = "\"Optimized route: 23% shorter than nearest neighbor\" means you'll spend 23% less time flying between NPCs.",
                    technicalNote = "\"Nearest neighbor\" visits the closest unvisited NPC first, which often creates backtracking. The optimizer finds more efficient routes using pathfinding algorithms."
                }
            },
            {
                type = "dropdown",
                key = "defaultReturnLocation",
                label = "Default Return Location",
                tooltip = "Default return destination when starting a new circuit. The circuit will set a waypoint to this location after completion.",
                width = DROPDOWN_WIDTH,
                extendedHelp = {
                    title = "Default Return Location",
                    description = "Sets where you want to return after completing a circuit. This choice is used as the default when starting new circuits.",
                    why = "Saves time if you consistently return to the same location (like a quest giver for daily turn-ins). You can still change it for individual circuits.",
                    example = "Set to 'Quest Giver' if you always turn in daily quests after circuits. Set to 'None' if you prefer to continue exploring after finishing.",
                },
                items = {
                    {text = "None", value = "none"},
                    {text = "Current Location", value = "current"},
                    {text = "Quest Giver", value = "questgiver"}
                },
                displayText = function(value)
                    if value == "current" then
                        return "Current Location"
                    elseif value == "questgiver" then
                        return "Quest Giver"
                    else
                        return "None"
                    end
                end
            },
        }
    },
    {
        name = "Tabs",
        options = {
            {type = "header", text = "Tab Visibility"},
            {
                type = "tabsSection",
                tooltip = "Enable or disable tabs in the main window. At least one tab must remain enabled."
            },
        }
    },
}

--[[
  Widget Factory System
]]

local function setDropdownText(dropdown, text, icon)
    local displayText = text
    if icon then
        displayText = "|T" .. icon .. ":0|t " .. text
    end
    if UIDropDownMenu_SetText then
        UIDropDownMenu_SetText(dropdown, displayText)
    elseif dropdown.Text then
        dropdown.Text:SetText(displayText)
    end
end

local function createReloadIndicator(parent)
    local icon = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    icon:SetText("[R]")
    icon:SetTextColor(1, 0.8, 0)
    return icon
end

local function checkEnabled(config)
    if not config.enabledIf then return true end
    -- pcall: User-provided enabledIf function may error
    local success, result = pcall(config.enabledIf)
    if not success then
        utils:error("Error checking enabledIf for " .. tostring(config.key))
        return true
    end
    return result
end

local function validateValue(config, value)
    if not config.validate then return true, nil end
    -- pcall: User-provided validate function may error
    local success, valid, errorMsg = pcall(config.validate, value)
    if not success then
        utils:error("Error validating " .. tostring(config.key))
        return false, "Validation error"
    end
    return valid, errorMsg
end

local function getFriendlyName(key)
    for _, tabDef in ipairs(tabbedOptions) do
        for _, config in ipairs(tabDef.options) do
            if config.key == key then
                return config.label
            end
        end
    end
    return key
end

local function formatValue(value)
    if type(value) == "boolean" then
        return value and "enabled" or "disabled"
    elseif type(value) == "string" then
        return value
    elseif type(value) == "number" then
        return tostring(value)
    else
        return tostring(value)
    end
end

--[[
  Extended Help System
]]

local function showExtendedHelp(config, anchorTo)
    if activeHelpFrame then
        activeHelpFrame:Hide()
        activeHelpFrame = nil
    end
    
    if not config.extendedHelp then return end
    
    local help = config.extendedHelp
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetFrameStrata("TOOLTIP")
    frame:SetWidth(350)
    frame:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 10, 0)
    
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.95)
    
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
        activeHelpFrame = nil
    end)
    
    -- Click anywhere on frame to close
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function(self)
        self:Hide()
        activeHelpFrame = nil
    end)
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -12)
    title:SetText(help.title or "Help")
    title:SetTextColor(1, 0.82, 0)
    
    local yOffset = -40
    
    -- Description (always present)
    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
    desc:SetWidth(320)
    desc:SetJustifyH("LEFT")
    desc:SetText(help.description or "")
    yOffset = yOffset - (desc:GetStringHeight() + 16)
    
    -- Why section (always present)
    local whyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    whyLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
    whyLabel:SetText("Why use this:")
    whyLabel:SetTextColor(0.7, 0.7, 1)
    yOffset = yOffset - 18
    
    local why = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    why:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
    why:SetWidth(320)
    why:SetJustifyH("LEFT")
    why:SetText(help.why or "")
    yOffset = yOffset - (why:GetStringHeight() + 16)
    
    -- Example section (always present)
    local exLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    exLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
    exLabel:SetText("Example:")
    exLabel:SetTextColor(0.7, 1, 0.7)
    yOffset = yOffset - 18
    
    local ex = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ex:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
    ex:SetWidth(320)
    ex:SetJustifyH("LEFT")
    ex:SetText(help.example or "")
    yOffset = yOffset - (ex:GetStringHeight() + 16)
    
    -- Technical note section (optional)
    if help.technicalNote then
        local techLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        techLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
        techLabel:SetText("Technical note:")
        techLabel:SetTextColor(1, 0.7, 0.7)
        yOffset = yOffset - 18
        
        local tech = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tech:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
        tech:SetWidth(320)
        tech:SetJustifyH("LEFT")
        tech:SetText(help.technicalNote)
        yOffset = yOffset - (tech:GetStringHeight() + 12)
    end
    
    -- Images section (optional)
    if help.images and #help.images > 0 then
        local imagesLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        imagesLabel:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, yOffset)
        imagesLabel:SetText("Visual comparison:")
        imagesLabel:SetTextColor(1, 0.82, 0.5)
        yOffset = yOffset - 22
        
        -- Display images side by side
        local imageWidth = 150
        local imageHeight = 100
        local imageSpacing = 10
        
        for i, imageData in ipairs(help.images) do
            local xOffset = 12 + ((i - 1) * (imageWidth + imageSpacing))
            
            -- Image texture
            local imgFrame = CreateFrame("Frame", nil, frame)
            imgFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, yOffset)
            imgFrame:SetSize(imageWidth, imageHeight)
            
            local img = imgFrame:CreateTexture(nil, "ARTWORK")
            img:SetAllPoints()
            img:SetTexture(imageData.path)
            
            -- Image border
            local border = imgFrame:CreateTexture(nil, "OVERLAY")
            border:SetAllPoints()
            border:SetColorTexture(0.3, 0.3, 0.3, 0.5)
            border:SetDrawLayer("OVERLAY", 1)
            
            -- Caption below image
            local caption = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            caption:SetPoint("TOP", imgFrame, "BOTTOM", 0, -4)
            caption:SetWidth(imageWidth)
            caption:SetJustifyH("CENTER")
            caption:SetText(imageData.caption or "")
            caption:SetTextColor(0.8, 0.8, 0.8)
        end
        
        yOffset = yOffset - (imageHeight + 30)
    end
    
    -- Set final height based on content
    frame:SetHeight(math.abs(yOffset) + 20)
    
    frame:Show()
    activeHelpFrame = frame
end

local function createHelpIcon(parent, config)
    if not config.extendedHelp then return nil end
    
    local helpBtn = CreateFrame("Button", nil, parent)
    helpBtn:SetSize(14, 14)
    
    local bg = helpBtn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.3, 0.5, 0.8, 0.8)
    
    local text = helpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER")
    text:SetText("?")
    text:SetTextColor(1, 1, 1)
    
    helpBtn:SetScript("OnEnter", function(self)
        bg:SetColorTexture(0.4, 0.6, 1, 1)
    end)
    helpBtn:SetScript("OnLeave", function(self)
        bg:SetColorTexture(0.3, 0.5, 0.8, 0.8)
    end)
    helpBtn:SetScript("OnClick", function(self)
        showExtendedHelp(config, self)
    end)
    
    return helpBtn
end

local function createHeader(parent, config, yOffset)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, yOffset)
    header:SetText(config.text)
    return header, HEADER_HEIGHT
end

local function createCheckbox(parent, config, yOffset)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, yOffset)
    checkbox.Text:SetText(config.label)
    checkbox.config = config
    
    if Addon.options and Addon.options.Get then
        checkbox:SetChecked(Addon.options:Get(config.key))
    end
    
    checkbox:SetScript("OnClick", function(self)
        local value = self:GetChecked() and true or false
        local valid, errorMsg = validateValue(config, value)
        if not valid then
            utils:error("Invalid value for " .. config.label .. ": " .. (errorMsg or "validation failed"))
            self:SetChecked(not value)
            return
        end
        
        if Addon.options and Addon.options.Set then
            Addon.options:Set(config.key, value)
        end
        if config.onChange then
            config.onChange(value)
        end
        optionsPanel:refreshDependencies()
    end)
    
    checkbox.Text:EnableMouse(true)
    checkbox.Text:SetScript("OnMouseUp", function(self, button)
        if IsAltKeyDown() then
            optionsPanel:resetToDefault(config.key)
        elseif checkbox:IsEnabled() then
            checkbox:Click()
        end
    end)
    
    if config.requiresReload then
        local reloadIcon = createReloadIndicator(checkbox)
        reloadIcon:SetPoint("LEFT", checkbox.Text, "RIGHT", 4, 0)
    end
    
    if config.tooltip then
        checkbox:SetScript("OnEnter", function(self)
            local tip = Addon.tooltip
            tip:show(self, { anchor = "TOPLEFT", relPoint = "TOPRIGHT", offsetX = 5, offsetY = 0 })
            tip:header(config.label, {color = {1, 0.82, 0}})
            tip:space(3)
            tip:text(config.tooltip, {wrap = true})
            if config.requiresReload then
                tip:space(8)
                tip:text("[R] Requires /reload to take effect", {color = {1, 0.8, 0}, wrap = true})
            end
            tip:done()
        end)
        checkbox:SetScript("OnLeave", function() Addon.tooltip:hide() end)
        
        checkbox.Text:SetScript("OnEnter", function(self)
            local tip = Addon.tooltip
            tip:show(self, { anchor = "TOPLEFT", relPoint = "TOPRIGHT", offsetX = 5, offsetY = 0 })
            tip:header(config.label, {color = {1, 0.82, 0}})
            tip:space(3)
            tip:text(config.tooltip, {wrap = true})
            if config.requiresReload then
                tip:space(8)
                tip:text("[R] Requires /reload to take effect", {color = {1, 0.8, 0}, wrap = true})
            end
            tip:done()
        end)
        checkbox.Text:SetScript("OnLeave", function() Addon.tooltip:hide() end)
    end
    
    -- Help icon
    local helpIcon = createHelpIcon(checkbox, config)
    if helpIcon then
        helpIcon:SetPoint("LEFT", checkbox.Text, "RIGHT", config.requiresReload and 20 or 4, 0)
    end
    
    return checkbox, CHECKBOX_HEIGHT
end

local function createDropdown(parent, config, yOffset)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, yOffset)
    container:SetSize(460, DROPDOWN_HEIGHT)
    container.config = config
    
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    label:SetText(config.label)
    
    if config.requiresReload then
        local reloadIcon = createReloadIndicator(container)
        reloadIcon:SetPoint("LEFT", label, "RIGHT", 4, 0)
    end
    
    local dropdown = CreateFrame("Frame", "PAODropdown_" .. config.key, container, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", -16, -4)
    UIDropDownMenu_SetWidth(dropdown, config.width or DROPDOWN_WIDTH)
    dropdown.config = config
    dropdown.label = label  -- Store label reference for dependency updates
    
    if UIDropDownMenu_SetAnchor then
        UIDropDownMenu_SetAnchor(dropdown, -12, 0, "TOPRIGHT", dropdown, "BOTTOMRIGHT")
    else
        dropdown:HookScript("OnMouseDown", function()
            if DropDownList1 then
                DropDownList1:ClearAllPoints()
                DropDownList1:SetPoint("TOPRIGHT", dropdown, "BOTTOMRIGHT", -12, 0)
            end
        end)
    end
    
    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local items = type(config.items) == "function" and config.items() or config.items
        for _, item in ipairs(items) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text
            info.value = item.value
            if item.icon then
                info.icon = item.icon
                info.tCoordLeft = 0
                info.tCoordRight = 1
                info.tCoordTop = 0
                info.tCoordBottom = 1
            end
            info.func = function()
                local valid, errorMsg = validateValue(config, item.value)
                if not valid then
                    utils:error("Invalid value for " .. config.label .. ": " .. (errorMsg or "validation failed"))
                    return
                end
                
                if Addon.options and Addon.options.Set then
                    Addon.options:Set(config.key, item.value)
                    setDropdownText(dropdown, item.text, item.icon)
                end
                if config.onChange then
                    config.onChange(item.value)
                end
                optionsPanel:refreshDependencies()
            end
            info.notCheckable = true
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    label:EnableMouse(true)
    label:SetScript("OnMouseUp", function(self, button)
        if IsAltKeyDown() then
            optionsPanel:resetToDefault(config.key)
        end
    end)
    
    if config.tooltip then
        label:SetScript("OnEnter", function(self)
            local tip = Addon.tooltip
            tip:show(self, { anchor = "TOPLEFT", relPoint = "TOPRIGHT", offsetX = 5, offsetY = 0 })
            tip:header(config.label, {color = {1, 0.82, 0}})
            tip:space(3)
            tip:text(config.tooltip, {wrap = true})
            if config.requiresReload then
                tip:space(8)
                tip:text("[R] Requires /reload to take effect", {color = {1, 0.8, 0}, wrap = true})
            end
            tip:done()
        end)
        label:SetScript("OnLeave", function() Addon.tooltip:hide() end)
    end
    
    -- Help icon
    local helpIcon = createHelpIcon(container, config)
    if helpIcon then
        helpIcon:SetPoint("LEFT", label, "RIGHT", config.requiresReload and 20 or 4, 0)
    end
    
    return dropdown, DROPDOWN_HEIGHT
end

--[[
  Create Slider Widget
]]
local function createSlider(parent, config, yOffset)
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, yOffset)
    container:SetSize(200, CHECKBOX_HEIGHT + 20)  -- Narrower width for slider
    container.config = config
    
    -- Label (same as dropdown style)
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    label:SetText(config.label)
    
    local labelFrame = CreateFrame("Button", nil, container)
    labelFrame:SetAllPoints(label)
    labelFrame:RegisterForClicks("AnyUp")
    labelFrame:SetScript("OnClick", function(self, button)
        if IsAltKeyDown() then
            optionsPanel:resetToDefault(config.key)
        end
    end)
    labelFrame:SetScript("OnEnter", function(self)
        local tip = Addon.tooltip
        tip:show(self, { anchor = "TOPLEFT", relPoint = "TOPRIGHT", offsetX = 5, offsetY = 0 })
        tip:header(config.label, {color = {1, 0.82, 0}})
        tip:space(3)
        if config.tooltip then
            tip:text(config.tooltip, {wrap = true})
        end
        tip:space(8)
        tip:text("Alt+Click to reset to default", {color = {0.7, 0.7, 1}, wrap = true})
        tip:done()
    end)
    labelFrame:SetScript("OnLeave", function() Addon.tooltip:hide() end)
    
    -- Value display (aligned with label at top)
    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valueText:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
    container.valueText = valueText
    
    -- Slider (positioned below label like dropdown)
    local slider = CreateFrame("Slider", nil, container)
    slider:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -8)
    slider:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, -8)
    slider:SetHeight(16)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(config.min or 0, config.max or 1)
    slider:SetValueStep(config.step or 0.1)
    slider:SetObeyStepOnDrag(true)
    slider.config = config
    
    local bgTexture = slider:CreateTexture(nil, "BACKGROUND")
    bgTexture:SetAllPoints()
    bgTexture:SetColorTexture(0.15, 0.15, 0.15, 0.5)
    
    local thumbTexture = slider:CreateTexture(nil, "ARTWORK")
    thumbTexture:SetSize(12, 20)
    thumbTexture:SetColorTexture(0.8, 0.8, 0.8, 1)
    slider:SetThumbTexture(thumbTexture)
    
    slider:SetScript("OnValueChanged", function(self, value)
        if not Addon.options or not Addon.options.Set then return end
        
        -- Update display
        local displayText = "Unknown"
        if config.displayText then
            displayText = config.displayText(value)
        else
            displayText = string.format("%.2f", value)
        end
        valueText:SetText(displayText)
        
        -- Save setting
        Addon.options:Set(config.key, value)
        
        -- Trigger onChange if provided
        if config.onChange then
            config.onChange(value)
        end
    end)
    
    container.slider = slider
    
    -- Initialize value
    if Addon.options and Addon.options.Get then
        local currentValue = Addon.options:Get(config.key)
        if currentValue ~= nil then
            slider:SetValue(currentValue)
        end
    end
    
    return container, CHECKBOX_HEIGHT + 20
end

--[[
  Create tabs section - dynamically generates checkboxes for each registered tab.
  Tab changes require reload to take effect. Saves directly to pao_settings
  without updating live tab state.
]]
local function createTabsSection(parent, config, yOffset)
    local tabs = Addon.tabs
    if not tabs or not tabs.getAll then
        -- Tabs system not available yet
        local placeholder = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        placeholder:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, yOffset)
        placeholder:SetText("Tab settings not available")
        placeholder:SetTextColor(0.7, 0.7, 0.7)
        return placeholder, 24
    end
    
    local container = CreateFrame("Frame", nil, parent)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, yOffset)
    container:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -PADDING, yOffset)
    
    local allTabs = tabs:getAll()
    local localYOffset = 0
    local checkboxes = {}
    
    -- Capture live state (what's actually enabled right now, won't change until reload)
    local liveState = {}
    for _, tabConfig in ipairs(allTabs) do
        liveState[tabConfig.id] = tabs:isEnabled(tabConfig.id)
    end
    
    -- Helper to get pending state from settings
    local function getPendingState(tabId)
        if pao_settings and pao_settings.tabs and pao_settings.tabs[tabId] ~= nil then
            return pao_settings.tabs[tabId]
        end
        -- Fall back to live state (no pending change)
        return liveState[tabId]
    end
    
    -- Helper to check if any tab has pending changes
    local function hasPendingChanges()
        for tabId, liveEnabled in pairs(liveState) do
            if getPendingState(tabId) ~= liveEnabled then
                return true
            end
        end
        return false
    end
    
    -- Helper to count how many tabs would be enabled after pending changes
    local function countPendingEnabled()
        local count = 0
        for tabId, _ in pairs(liveState) do
            if getPendingState(tabId) then
                count = count + 1
            end
        end
        return count
    end
    
    -- Forward declaration
    local updateReloadButton
    
    for _, tabConfig in ipairs(allTabs) do
        local checkbox = CreateFrame("CheckButton", nil, container, "InterfaceOptionsCheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", container, "TOPLEFT", 0, localYOffset)
        checkbox.Text:SetText(tabConfig.name)
        checkbox.tabId = tabConfig.id
        checkbox.liveState = liveState[tabConfig.id]
        
        -- [R] reload indicator
        local reloadIcon = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        reloadIcon:SetPoint("LEFT", checkbox.Text, "RIGHT", 6, 0)
        reloadIcon:SetText("|cffffd700[R]|r")
        reloadIcon:Hide()
        checkbox.reloadIcon = reloadIcon
        
        -- Set initial state from pending (saved) value
        checkbox:SetChecked(getPendingState(tabConfig.id))
        
        -- Show [R] if pending differs from live
        if getPendingState(tabConfig.id) ~= liveState[tabConfig.id] then
            reloadIcon:Show()
        end
        
        -- OnClick handler - save to settings, don't update live state
        checkbox:SetScript("OnClick", function(self)
            local enabled = self:GetChecked()
            
            -- Check if this would disable the last tab (in pending state)
            if not enabled then
                local pendingEnabledCount = countPendingEnabled()
                -- If only 1 would be enabled and we're trying to disable it
                if pendingEnabledCount <= 1 and getPendingState(tabConfig.id) then
                    self:SetChecked(true)
                    if Addon.utils then
                        Addon.utils:chat("Cannot hide the last tab.")
                    end
                    return
                end
            end
            
            -- Save to pao_settings directly (don't call tabs:setEnabled)
            if not pao_settings then pao_settings = {} end
            if not pao_settings.tabs then pao_settings.tabs = {} end
            pao_settings.tabs[tabConfig.id] = enabled
            
            -- Update [R] indicator
            if enabled ~= self.liveState then
                self.reloadIcon:Show()
            else
                self.reloadIcon:Hide()
            end
            
            -- Update reload button visibility
            updateReloadButton()
        end)
        
        -- Tooltip
        checkbox:SetScript("OnEnter", function(self)
            local tip = Addon.tooltip
            if tip then
                tip:show(self, { anchor = "TOPLEFT", relPoint = "TOPRIGHT", offsetX = 5, offsetY = 0 })
                tip:header(tabConfig.name .. " Tab", {color = {1, 1, 1}})
                tip:text("Show or hide this tab in the main window.", {wrap = true})
                tip:space(8)
                tip:text("[R] Requires /reload to take effect", {color = {1, 0.8, 0}, wrap = true})
                tip:done()
            end
        end)
        checkbox:SetScript("OnLeave", function()
            if Addon.tooltip then Addon.tooltip:hide() end
        end)
        
        table.insert(checkboxes, checkbox)
        localYOffset = localYOffset - CHECKBOX_HEIGHT
    end
    
    -- Reload UI button (shown when pending changes exist)
    local reloadBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    reloadBtn:SetSize(120, 24)
    reloadBtn:SetPoint("TOPLEFT", container, "TOPLEFT", 0, localYOffset - 8)
    reloadBtn:SetText("Reload UI")
    reloadBtn:Hide()
    
    reloadBtn:SetScript("OnClick", function()
        ReloadUI()
    end)
    
    reloadBtn:SetScript("OnEnter", function(self)
        local tip = Addon.tooltip
        if tip then
            tip:show(self, { anchor = "TOPLEFT", relPoint = "TOPRIGHT", offsetX = 5, offsetY = 0 })
            tip:header("Reload UI", {color = {1, 1, 1}})
            tip:text("Apply pending tab changes by reloading the interface.", {wrap = true})
            tip:done()
        end
    end)
    reloadBtn:SetScript("OnLeave", function()
        if Addon.tooltip then Addon.tooltip:hide() end
    end)
    
    container.reloadBtn = reloadBtn
    
    -- Update reload button visibility
    updateReloadButton = function()
        if hasPendingChanges() then
            reloadBtn:Show()
        else
            reloadBtn:Hide()
        end
    end
    
    -- Initial check
    updateReloadButton()
    
    local totalHeight = (#allTabs * CHECKBOX_HEIGHT) + (hasPendingChanges() and 40 or 0)
    container:SetHeight(totalHeight)
    container.checkboxes = checkboxes
    
    -- Refresh function - sync checkbox states and [R] indicators
    container.Refresh = function(self)
        for _, cb in ipairs(self.checkboxes) do
            if cb.tabId then
                local pending = getPendingState(cb.tabId)
                cb:SetChecked(pending)
                
                if pending ~= cb.liveState then
                    cb.reloadIcon:Show()
                else
                    cb.reloadIcon:Hide()
                end
            end
        end
        updateReloadButton()
    end
    
    return container, totalHeight + 40  -- Extra space for potential reload button
end

local widgetFactories = {
    header = createHeader,
    checkbox = createCheckbox,
    dropdown = createDropdown,
    slider = createSlider,
    tabsSection = createTabsSection,
}

--[[
  Tab System
]]

local function createTabButton(parent, tabName, index, totalTabs, previousButton)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(120, TAB_HEIGHT)
    
    if index == 1 then
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, -PADDING)
    else
        button:SetPoint("LEFT", previousButton, "RIGHT", 2, 0)
    end
    
    local bg = button:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    button.bg = bg
    
    local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText(tabName)
    button.text = text
    
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.3, 0.3, 0.3, 0.5)
    
    return button
end

local function setTabActive(button, active)
    if active then
        button.bg:SetColorTexture(0.3, 0.3, 0.3, 1.0)
        button.text:SetFontObject("GameFontNormalLarge")
    else
        button.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        button.text:SetFontObject("GameFontNormal")
    end
end

--[[
  Reset Functions
]]

function optionsPanel:resetToDefault(key)
    if not Addon.options or not Addon.options.GetDefault or not Addon.options.Set then
        utils:error("Options system not available")
        return
    end
    
    local defaultValue = Addon.options:GetDefault(key)
    if defaultValue ~= nil then
        Addon.options:Set(key, defaultValue)
        self:refreshAllWidgets()
        utils:chat("Reset '" .. key .. "' to default")
    end
end

function optionsPanel:resetAllToDefaults()
    if not Addon.options or not Addon.options.GetDefault or not Addon.options.Set or not Addon.options.Get then
        utils:error("Options system not available")
        return
    end
    
    StaticPopupDialogs["PAO_RESET_CONFIRM"] = {
        text = "Reset ALL Paw and Order settings to defaults?\n\nThis affects all tabs and cannot be undone.",
        button1 = "Reset All",
        button2 = "Cancel",
        OnAccept = function()
            local changes = {}
            
            for _, tabDef in ipairs(tabbedOptions) do
                for _, config in ipairs(tabDef.options) do
                    if config.key then
                        local currentValue = Addon.options:Get(config.key)
                        local defaultValue = Addon.options:GetDefault(config.key)
                        
                        if defaultValue ~= nil and currentValue ~= defaultValue then
                            table.insert(changes, {
                                key = config.key,
                                label = getFriendlyName(config.key),
                                oldValue = currentValue,
                                newValue = defaultValue
                            })
                            Addon.options:Set(config.key, defaultValue)
                        end
                    end
                end
            end
            
            optionsPanel:refreshAllWidgets()
            
            if #changes == 0 then
                utils:chat("All settings were already at their defaults")
            else
                utils:chat("Settings reset to defaults:")
                for _, change in ipairs(changes) do
                    utils:chat(string.format("%s: %s -> %s", 
                        change.label, 
                        formatValue(change.oldValue), 
                        formatValue(change.newValue)))
                end
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    StaticPopup_Show("PAO_RESET_CONFIRM")
end

--[[
  Refresh Functions
]]

function optionsPanel:refreshDependencies()
    for _, widget in ipairs(allWidgets) do
        if widget.config and widget.config.enabledIf then
            local enabled = checkEnabled(widget.config)
            
            if widget:IsObjectType("CheckButton") then
                if enabled then
                    widget:Enable()
                    widget.Text:SetTextColor(1, 1, 1)
                else
                    widget:Disable()
                    widget.Text:SetTextColor(0.5, 0.5, 0.5)
                end
            elseif widget:IsObjectType("Frame") then
                if enabled then
                    UIDropDownMenu_EnableDropDown(widget)
                    if widget.label then
                        widget.label:SetTextColor(1, 1, 1)
                    end
                else
                    UIDropDownMenu_DisableDropDown(widget)
                    if widget.label then
                        widget.label:SetTextColor(0.5, 0.5, 0.5)
                    end
                end
            end
        end
    end
end

function optionsPanel:refreshAllWidgets()
    if not Addon.options or not Addon.options.Get then return end
    if #allWidgets == 0 then return end  -- Not yet initialized
    
    for _, widget in ipairs(allWidgets) do
        if widget.config and widget.config.key then
            if widget:IsObjectType("CheckButton") then
                widget:SetChecked(Addon.options:Get(widget.config.key))
            elseif widget:IsObjectType("Frame") then
                if widget.config.type == "dropdown" then
                    local currentValue = Addon.options:Get(widget.config.key)
                    local displayText = "Unknown"
                    local displayIcon = nil
                    
                    if widget.config.displayText then
                        displayText = widget.config.displayText(currentValue)
                    else
                        local items = type(widget.config.items) == "function" and widget.config.items() or widget.config.items
                        for _, item in ipairs(items) do
                            if item.value == currentValue then
                                displayText = item.text
                                displayIcon = item.icon
                                break
                            end
                        end
                    end
                    
                    setDropdownText(widget, displayText, displayIcon)
                elseif widget.slider then
                    -- This is a slider container
                    local currentValue = Addon.options:Get(widget.config.key)
                    if currentValue ~= nil then
                        widget.slider:SetValue(currentValue)
                    end
                end
            end
        end
    end
    
    self:refreshDependencies()
end

--[[
  Create Panel
  
  Creates a shell frame and registers with Blizzard's settings system.
  Content is built lazily on first show to avoid login-time overhead.
]]

function optionsPanel:create(parent)
    local panel = CreateFrame("Frame", ADDON_NAME.."OptionsPanel", parent)
    panel.name = "Paw and Order"
    
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    else
        InterfaceOptions_AddCategory(panel)
    end
    
    -- Lazy initialization: build content on first show
    panel:SetScript("OnShow", function(self)
        if not self.initialized then
            optionsPanel:buildContent(self)
            self.initialized = true
        end
        optionsPanel:refreshAllWidgets()
        if tabsSectionContainer and tabsSectionContainer.Refresh then
            tabsSectionContainer:Refresh()
        end
    end)
    
    optionsPanel.frame = panel
    return panel
end

--[[
  Build Content
  
  Creates all widgets, tabs, and footer. Called on first panel show.
]]

function optionsPanel:buildContent(panel)
    allWidgets = {}
    
    local tabButtons = {}
    local tabContainers = {}
    
    for i, tabDef in ipairs(tabbedOptions) do
        local previousButton = tabButtons[i - 1]
        local button = createTabButton(panel, tabDef.name, i, #tabbedOptions, previousButton)
        table.insert(tabButtons, button)
        
        local container = CreateFrame("Frame", nil, panel)
        container:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -(PADDING + TAB_HEIGHT + 8))
        container:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, FOOTER_HEIGHT)
        container:Hide()
        
        local yOffset = -PADDING
        
        for _, config in ipairs(tabDef.options) do
            local factory = widgetFactories[config.type]
            if factory then
                local widget, height = factory(container, config, yOffset)
                yOffset = yOffset - height - 8
                
                if config.key then
                    table.insert(allWidgets, widget)
                end
                
                -- Store tabsSection reference for external refresh
                if config.type == "tabsSection" then
                    tabsSectionContainer = widget
                end
            else
                utils:error("Unknown option type: " .. tostring(config.type))
            end
        end
        
        table.insert(tabContainers, container)
        
        button:SetScript("OnClick", function()
            for j, btn in ipairs(tabButtons) do
                setTabActive(btn, j == i)
                tabContainers[j]:SetShown(j == i)
            end
        end)
    end
    
    -- Footer with Reset All button
    local footer = CreateFrame("Frame", nil, panel)
    footer:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    footer:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0, 0)
    footer:SetHeight(FOOTER_HEIGHT)
    
    local separator = footer:CreateTexture(nil, "BACKGROUND")
    separator:SetPoint("TOPLEFT", footer, "TOPLEFT", PADDING, 0)
    separator:SetPoint("TOPRIGHT", footer, "TOPRIGHT", -PADDING, 0)
    separator:SetHeight(1)
    separator:SetColorTexture(0.4, 0.4, 0.4, 1)
    
    local resetAllBtn = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    resetAllBtn:SetSize(220, 32)
    resetAllBtn:SetPoint("CENTER", footer, "CENTER", 0, -4)
    resetAllBtn:SetText("Reset All Settings to Defaults")
    resetAllBtn:GetFontString():SetTextColor(1, 0.8, 0.8)
    
    resetAllBtn:SetScript("OnClick", function()
        optionsPanel:resetAllToDefaults()
    end)
    
    resetAllBtn:SetScript("OnEnter", function(self)
        local tip = Addon.tooltip
        tip:show(self, { anchor = "BOTTOM", relPoint = "TOP", offsetX = 0, offsetY = 5 })
        tip:header("Reset All Settings", {color = {1, 1, 1}})
        tip:text("Resets all addon settings across all tabs to their default values.", {wrap = true})
        tip:space(8)
        tip:text("Tip: Alt+click any option label to reset just that setting.", {color = {0.7, 0.7, 1}, wrap = true})
        tip:done()
    end)
    resetAllBtn:SetScript("OnLeave", function() Addon.tooltip:hide() end)
    
    if #tabButtons > 0 then
        setTabActive(tabButtons[1], true)
        tabContainers[1]:Show()
    end
end

if Addon.registerModule then
    Addon.registerModule("optionsPanel", {"utils", "petSorting", "location", "npcUtils", "tooltip", "tabs", "petsTab", "achievementsTab"}, function()
        optionsPanel:create()
        return true
    end)
end

Addon.optionsPanel = optionsPanel
return optionsPanel