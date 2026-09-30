--[[
  ui/shared/textBox.lua
  Text Input Factory
  
  Creates properly-configured text input EditBoxes with:
    - Custom backdrop (no InputBoxTemplate baggage)
    - Proper text padding via insets
    - Placeholder text (shown when empty and unfocused)
    - Double-click word selection
    - Triple-click select all
    - Standard behaviors (autoFocus off, escape clears focus)
  
  Usage:
    local box = textBox:create({
        parent = parentFrame,
        name = "MyTextBox",
        width = 200,
        placeholder = "Enter text...",
        maxLetters = 100,
        numeric = false,
        onTextChanged = function(text) ... end,
        onEnterPressed = function(text) ... end,
        onEscapePressed = function() ... end,
    })
  
  Dependencies: None (standalone factory)
  Exports: Addon.textBox
]]

local ADDON_NAME, Addon = ...

local textBox = {}

-- Default configuration
local DEFAULTS = {
    width = 200,
    placeholder = "",
    maxLetters = 256,
    numeric = false,
    
    -- Text insets (padding from frame edges)
    insetLeft = 8,
    insetRight = 8,
    insetTop = 0,
    insetBottom = 0,
    
    -- Visual styling (rounded tooltip border)
    bgColor = {0.1, 0.1, 0.1, 0.8},
    borderColor = {0.4, 0.4, 0.4, 1},
    focusBorderColor = {0.6, 0.6, 0.6, 1},
    
    -- Word selection timing
    doubleClickTime = 0.3,
}

-- ============================================================================
-- HELPERS
-- ============================================================================

-- ============================================================================
-- FACTORY
-- ============================================================================

--[[
  Create a text input box.
  
  @param config table - Configuration options:
    - parent frame (required) - Parent frame
    - name string - Unique frame name (auto-generated if omitted)
    - width number - Box width (default 200)
    - height number - Box height (default: theme CONTROL.HEIGHT)
    - placeholder string - Placeholder text (default "")
    - maxLetters number - Maximum input length (default 256)
    - numeric boolean - Only allow numeric input (default false)
    - font string - Font object name (default: theme CONTROL.FONT_OBJECT)
    - onTextChanged function(text) - Called when text changes
    - onEnterPressed function(text) - Called when Enter pressed
    - onEscapePressed function() - Called when ESC pressed
    - onFocusGained function() - Called when focus gained
    - onFocusLost function() - Called when focus lost
  @return frame - The EditBox frame with additional methods
]]
function textBox:create(config)
    if not config or not config.parent then
        error("textBox:create requires config.parent")
        return nil
    end
    
    -- Resolve configuration
    local name = config.name or (ADDON_NAME .. "TextBox" .. tostring(math.random(100000)))
    local width = config.width or DEFAULTS.width
    local placeholder = config.placeholder or DEFAULTS.placeholder
    local maxLetters = config.maxLetters or DEFAULTS.maxLetters
    local numeric = config.numeric or DEFAULTS.numeric
    local font = config.font or Addon.theme.tokens.CONTROL.FONT_OBJECT
    local height = config.height or Addon.theme.tokens.CONTROL.HEIGHT
    
    -- Create raw EditBox (no template)
    local box = CreateFrame("EditBox", name, config.parent, "BackdropTemplate")
    box:SetSize(width, height)
    box:SetAutoFocus(false)
    box:SetMaxLetters(maxLetters)
    
    -- Set font (required for raw EditBox)
    box:SetFontObject(font)
    
    -- Apply backdrop (rounded tooltip style)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    box:SetBackdropColor(unpack(DEFAULTS.bgColor))
    box:SetBackdropBorderColor(unpack(DEFAULTS.borderColor))
    
    -- Apply text insets for proper padding
    box:SetTextInsets(
        DEFAULTS.insetLeft,
        DEFAULTS.insetRight,
        DEFAULTS.insetTop,
        DEFAULTS.insetBottom
    )
    
    -- Numeric mode. Right-aligned because that is what a number is: digits
    -- line up on the ones column, and a value growing from 1 to 100 grows
    -- leftward from a fixed edge instead of drifting.
    if numeric then
        box:SetNumeric(true)
        box:SetJustifyH("RIGHT")
    end
    
    -- Store config for reference
    box._textBoxConfig = config
    
    -- ========================================================================
    -- PLACEHOLDER TEXT
    -- ========================================================================
    
    local placeholderText = box:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    placeholderText:SetPoint("LEFT", box, "LEFT", DEFAULTS.insetLeft, 0)
    placeholderText:SetText(placeholder)
    box._placeholder = placeholderText
    
    local function updatePlaceholder()
        if box:GetText() == "" and not box:HasFocus() then
            placeholderText:Show()
        else
            placeholderText:Hide()
        end
    end
    
    -- Initial state
    updatePlaceholder()
    
    -- ========================================================================
    -- WORD SELECTION (DOUBLE/TRIPLE CLICK)
    -- ========================================================================
    
    local lastClickTime = 0
    local clickCount = 0
    
    -- Disable default select-all on focus, handle clicks manually
    box:SetScript("OnEditFocusGained", function(self)
        placeholderText:Hide()
        -- Highlight border on focus
        self:SetBackdropBorderColor(unpack(DEFAULTS.focusBorderColor))
        if config.onFocusGained then
            config.onFocusGained()
        end
    end)
    
    box:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            local now = GetTime()
            if now - lastClickTime < DEFAULTS.doubleClickTime then
                clickCount = clickCount + 1
            else
                clickCount = 1
            end
            lastClickTime = now
            
            if clickCount == 2 then
                -- Double-click: select word at cursor
                C_Timer.After(0, function()
                    local text = self:GetText()
                    local cursorPos = self:GetCursorPosition()
                    
                    if text and #text > 0 and cursorPos then
                        local wordStart = cursorPos
                        local wordEnd = cursorPos
                        
                        -- Scan backward for word start
                        while wordStart > 0 do
                            local char = text:sub(wordStart, wordStart)
                            if char:match("%s") then
                                break
                            end
                            wordStart = wordStart - 1
                        end
                        
                        -- Scan forward for word end
                        while wordEnd <= #text do
                            local char = text:sub(wordEnd, wordEnd)
                            if char:match("%s") then
                                break
                            end
                            wordEnd = wordEnd + 1
                        end
                        
                        if wordEnd > wordStart then
                            self:HighlightText(wordStart, wordEnd - 1)
                        end
                    end
                end)
            elseif clickCount >= 3 then
                -- Triple-click: select all
                C_Timer.After(0, function()
                    self:HighlightText()
                end)
                clickCount = 0
            end
        end
    end)
    
    -- ========================================================================
    -- EVENT HANDLERS
    -- ========================================================================
    
    box:SetScript("OnEditFocusLost", function(self)
        -- Clear any selection so it doesn't visually persist after
        -- focus moves to another field. Standard form-field behavior
        -- is "selected only while focused"; WoW's EditBox doesn't do
        -- this by default. SetCursorPosition(0) accompanies the
        -- clear because in TBC Classic 2.5.5 the selection rectangle
        -- can otherwise stay rendered even though the selection
        -- state itself is empty.
        self:ClearHighlightText()
        self:SetCursorPosition(0)
        updatePlaceholder()
        -- Restore normal border
        self:SetBackdropBorderColor(unpack(DEFAULTS.borderColor))
        if config.onFocusLost then
            config.onFocusLost()
        end
    end)
    
    -- Initial value is part of construction: set it BEFORE binding OnTextChanged
    -- so a control born with a value cannot fire "the value changed". Callers
    -- restoring persisted state pass config.text rather than SetText-ing after
    -- create (which would fire the change handler and trigger a render).
    if config.text and config.text ~= "" then
        box:SetText(config.text)
        box:SetCursorPosition(0)
        updatePlaceholder()
    end

    box:SetScript("OnTextChanged", function(self, userInput)
        updatePlaceholder()
        if self._suppressChange then return end
        if config.onTextChanged then
            config.onTextChanged(self:GetText(), userInput)
        end
    end)
    
    box:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        updatePlaceholder()
        if config.onEscapePressed then
            config.onEscapePressed()
        end
    end)
    
    box:SetScript("OnEnterPressed", function(self)
        if config.onEnterPressed then
            config.onEnterPressed(self:GetText())
        end
        self:ClearFocus()
    end)
    
    -- ========================================================================
    -- PUBLIC METHODS
    -- ========================================================================
    
    --[[
      Set the text programmatically. Cursor resets to position 0 so
      the visible portion of the field starts at the beginning of the
      text — without this, the EditBox's internal scroll position
      leaves long text appearing as a blank field with the visible
      window past the text's end. Consumers that want a different
      cursor position (e.g., focused field wanting select-all or
      append) call SetCursorPosition / HighlightText after.
      @param text string
    ]]
    function box:SetBoxText(text)
        self:SetText(text or "")
        self:SetCursorPosition(0)
        updatePlaceholder()
    end

    --[[
      Set the box's text. Fires onTextChanged unless silent=true (pass silent
      when syncing the control to external state, so the sync does not re-trigger
      the change handler). Consistent `set(value, silent)` across controls.
      @param text string
      @param silent boolean|nil
    ]]
    function box:set(text, silent)
        if silent then
            self._suppressChange = true
            self:SetBoxText(text)
            self._suppressChange = false
        else
            self:SetBoxText(text)
        end
    end
    
    --[[
      Select all text in the box. Standard "edit pre-populated value"
      affordance: caller does SetBoxText → SetFocus → SelectAll, and
      the user can type to replace or press End / right-arrow to
      keep the value and append. The focus-lost hook on this widget
      clears the selection automatically when focus moves away, so
      consumers don't need to manage the lifecycle.
    ]]
    function box:SelectAll()
        self:HighlightText()
    end

    --[[
      Get the current text.
      @return string
    ]]
    function box:GetBoxText()
        return self:GetText()
    end
    
    --[[
      Clear the text box and unfocus.
    ]]
    function box:Clear()
        self:SetText("")
        self:ClearFocus()
        updatePlaceholder()
    end
    
    --[[
      Update the placeholder text.
      @param text string
    ]]
    function box:SetPlaceholder(text)
        if self._placeholder then
            self._placeholder:SetText(text or "")
        end
    end
    
    --[[
      Get the placeholder text.
      @return string
    ]]
    function box:GetPlaceholder()
        if self._placeholder then
            return self._placeholder:GetText()
        end
        return ""
    end
    
    --[[
      Force placeholder visibility update.
      Call after programmatic text changes if needed.
    ]]
    function box:UpdatePlaceholder()
        updatePlaceholder()
    end
    
    return box
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("textBox", {})
end

Addon.textBox = textBox
return textBox