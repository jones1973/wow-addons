--[[
  ui/shared/filterTextbox.lua
  Filter Textbox Factory
  
  Creates filter input boxes with clear and info buttons.
  Used consistently for all filter inputs across PAO.
  
  Features:
  - Clear button (X) - shows when text present
  - InfoTip button (?) - always visible, callback for consumer
  - Order: [textbox][clear][infoTip]
  
  Usage:
    local filter = filterTextbox:create({
        parent = frame,
        width = 300,
        placeholder = "Filter...",
        onTextChanged = function(text, userInput) ... end,
        onClear = function() ... end,
        onInfoTipClick = function() ... end,
    })
  
  Dependencies: textBox
  Exports: Addon.filterTextbox
]]

local ADDON_NAME, Addon = ...

local filterTextbox = {}

-- Module reference
local textBox

-- Button sizing
local BUTTON_SIZE = 20
local INFO_BUTTON_SIZE = 22  -- Slightly larger to match visual appearance of clear button
local BUTTON_SPACING = 2

-- ============================================================================
-- FACTORY
-- ============================================================================

--[[
  Create a filter textbox with clear and info buttons.
  
  @param config table - Configuration:
    - parent frame (required) - Parent frame
    - width number - Textbox width
    - height number - Textbox height (optional, auto-sizes to font)
    - placeholder string - Placeholder text
    - maxLetters number - Max input length (default 200)
    - onTextChanged function(text, userInput) - Text change callback
    - onClear function() - Clear button callback
    - onInfoTipClick function() - InfoTip button callback
  @return frame - The textbox with methods
]]
function filterTextbox:create(config)
    if not config or not config.parent then
        error("filterTextbox:create requires config.parent")
    end
    
    if not textBox then
        textBox = Addon.textBox
        if not textBox then
            error("filterTextbox:create requires textBox module")
        end
    end
    
    local clearBtn, infoBtn
    
    -- Wrap onTextChanged to manage clear button visibility
    local originalOnTextChanged = config.onTextChanged
    local function wrappedOnTextChanged(text, userInput)
        -- Show/hide clear button based on text
        if clearBtn then
            if text and text ~= "" then
                clearBtn:Show()
            else
                clearBtn:Hide()
            end
        end
        
        -- Call original callback
        if originalOnTextChanged then
            originalOnTextChanged(text, userInput)
        end
    end
    
    -- Create base textbox
    local box = textBox:create({
        parent = config.parent,
        width = config.width,
        height = config.height,
        placeholder = config.placeholder or "Filter...",
        maxLetters = config.maxLetters or 200,
        onTextChanged = wrappedOnTextChanged,
        onEscapePressed = config.onEscapePressed,
        onEnterPressed = config.onEnterPressed,
    })
    
    if not box then
        return nil
    end
    
    -- ========================================================================
    -- INFO TIP BUTTON (rightmost)
    -- ========================================================================
    
    infoBtn = CreateFrame("Button", nil, config.parent)
    infoBtn:SetSize(INFO_BUTTON_SIZE, INFO_BUTTON_SIZE)
    infoBtn:SetPoint("RIGHT", box, "RIGHT", -4, 0)
    infoBtn:SetNormalTexture("Interface\\Common\\help-i")
    infoBtn:SetHighlightTexture("Interface\\Common\\help-i")
    infoBtn:GetHighlightTexture():SetAlpha(0.5)
    
    if config.onInfoTipClick then
        infoBtn:SetScript("OnClick", function()
            config.onInfoTipClick()
        end)
    end
    
    infoBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Click for filter help", 1, 1, 1)
        GameTooltip:Show()
    end)
    infoBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    box.infoBtn = infoBtn
    
    -- ========================================================================
    -- CLEAR BUTTON (left of info tip)
    -- ========================================================================
    
    clearBtn = CreateFrame("Button", nil, config.parent)
    clearBtn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    clearBtn:SetPoint("RIGHT", infoBtn, "LEFT", -BUTTON_SPACING, 0)
    clearBtn:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    clearBtn:SetHighlightTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    clearBtn:GetHighlightTexture():SetAlpha(0.5)
    clearBtn:Hide()  -- Hidden until text entered
    
    clearBtn:SetScript("OnClick", function()
        box:SetText("")
        box:SetFocus()
        
        if config.onClear then
            config.onClear()
        end
    end)
    
    clearBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Clear filter", 1, 1, 1)
        GameTooltip:Show()
    end)
    clearBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    box.clearBtn = clearBtn
    
    -- ========================================================================
    -- ADDITIONAL METHODS
    -- ========================================================================
    
    --[[
      Set info tip tooltip text.
      @param text string
    ]]
    function box:SetInfoTipTooltip(text)
        if infoBtn then
            infoBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(text or "Click for help", 1, 1, 1)
                GameTooltip:Show()
            end)
        end
    end
    
    --[[
      Set clear button tooltip text.
      @param text string
    ]]
    function box:SetClearTooltip(text)
        if clearBtn then
            clearBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOP")
                GameTooltip:SetText(text or "Clear", 1, 1, 1)
                GameTooltip:Show()
            end)
        end
    end
    
    -- Initial state check
    if box:GetText() and box:GetText() ~= "" then
        clearBtn:Show()
    end
    
    return box
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("filterTextbox", {"textBox"}, function()
        textBox = Addon.textBox
        return true
    end)
end

Addon.filterTextbox = filterTextbox
return filterTextbox