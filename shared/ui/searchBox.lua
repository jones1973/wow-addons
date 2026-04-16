--[[
  ui/shared/searchBox.lua
  Search Box Factory
  
  Creates search input EditBoxes by extending textBox with:
    - Clear button (X icon) that appears when text is present
  
  All other features (placeholder, word selection, insets) come from textBox.
  
  Usage:
    local box = searchBox:create({
        parent = parentFrame,
        name = "MySearchBox",
        width = 150,
        height = 28,
        placeholder = "Search...",
        showClearButton = true,
        maxLetters = 100,
        onTextChanged = function(text) ... end,
        onClear = function() ... end,
    })
  
  Dependencies: textBox
  Exports: Addon.searchBox
]]

local ADDON_NAME, Addon = ...

local searchBox = {}

-- Default configuration
local DEFAULTS = {
    width = 150,
    height = nil,  -- nil = auto-size from textBox
    placeholder = "Search...",
    showClearButton = true,
    maxLetters = 100,
    
    -- Clear button styling
    clearButtonSize = 16,
    clearButtonOffset = -8,
}

-- ============================================================================
-- FACTORY
-- ============================================================================

--[[
  Create a search box.
  
  @param config table - Configuration options:
    - parent frame (required) - Parent frame
    - name string - Unique frame name
    - width number - Box width (default 150)
    - height number - Box height (default 28)
    - placeholder string - Placeholder text (default "Search...")
    - showClearButton boolean - Show X clear button (default true)
    - maxLetters number - Maximum input length (default 100)
    - onTextChanged function(text) - Called when text changes
    - onClear function() - Called when clear button clicked
    - onEscapePressed function() - Called when ESC pressed
    - onEnterPressed function(text) - Called when Enter pressed
  @return frame - The EditBox frame
]]
function searchBox:create(config)
    if not config or not config.parent then
        error("searchBox:create requires config.parent")
        return nil
    end
    
    -- Get textBox factory
    local textBox = Addon.textBox
    if not textBox then
        error("searchBox:create requires textBox module")
        return nil
    end
    
    -- Resolve configuration
    local showClearButton = config.showClearButton ~= false
    local width = config.width or DEFAULTS.width
    local height = config.height or DEFAULTS.height
    
    -- Wrap the onTextChanged callback to handle clear button visibility
    local originalOnTextChanged = config.onTextChanged
    local box  -- Forward declaration for closure
    
    local function wrappedOnTextChanged(text, userInput)
        -- Update clear button visibility
        if box and box.clearButton then
            if text and text ~= "" then
                box.clearButton:Show()
            else
                box.clearButton:Hide()
            end
        end
        
        -- Call original callback
        if originalOnTextChanged then
            originalOnTextChanged(text, userInput)
        end
    end
    
    -- Create base textBox with wrapped callback
    box = textBox:create({
        parent = config.parent,
        name = config.name or (ADDON_NAME .. "SearchBox" .. tostring(math.random(100000))),
        width = width,
        height = height,
        placeholder = config.placeholder or DEFAULTS.placeholder,
        maxLetters = config.maxLetters or DEFAULTS.maxLetters,
        onTextChanged = wrappedOnTextChanged,
        onEscapePressed = config.onEscapePressed,
        onEnterPressed = config.onEnterPressed,
        onFocusGained = config.onFocusGained,
        onFocusLost = config.onFocusLost,
    })
    
    if not box then
        return nil
    end
    
    -- Store searchBox-specific config
    box._searchBoxConfig = config
    
    -- ========================================================================
    -- CLEAR BUTTON
    -- ========================================================================
    
    if showClearButton then
        local clearBtn = CreateFrame("Button", nil, box)
        clearBtn:SetSize(DEFAULTS.clearButtonSize, DEFAULTS.clearButtonSize)
        clearBtn:SetPoint("RIGHT", box, "RIGHT", DEFAULTS.clearButtonOffset, 0)
        clearBtn:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
        clearBtn:SetHighlightTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
        clearBtn:GetHighlightTexture():SetAlpha(0.5)
        clearBtn:Hide()  -- Hidden until text is entered
        
        clearBtn:SetScript("OnClick", function()
            box:SetText("")
            box:ClearFocus()
            box:UpdatePlaceholder()
            
            -- Hide the button
            clearBtn:Hide()
            
            -- Call onClear callback
            if config.onClear then
                config.onClear()
            end
        end)
        
        -- Default tooltip
        clearBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Clear", 1, 1, 1)
            GameTooltip:Show()
        end)
        clearBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        box.clearButton = clearBtn
    end
    
    -- ========================================================================
    -- LEGACY API COMPATIBILITY
    -- ========================================================================
    
    -- Alias methods for backward compatibility with existing code
    -- that uses SetSearchText/GetSearchText instead of SetBoxText/GetBoxText
    
    --[[
      Set the search text programmatically (alias for SetBoxText).
      @param text string
    ]]
    function box:SetSearchText(text)
        self:SetBoxText(text)
        -- Update clear button visibility
        if self.clearButton then
            if text and text ~= "" then
                self.clearButton:Show()
            else
                self.clearButton:Hide()
            end
        end
    end
    
    --[[
      Get the current search text (alias for GetBoxText).
      @return string
    ]]
    function box:GetSearchText()
        return self:GetBoxText()
    end
    
    return box
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("searchBox", {"textBox"}, function()
        return true
    end)
end

Addon.searchBox = searchBox
return searchBox