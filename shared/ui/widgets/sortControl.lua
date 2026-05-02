--[[
  ui/shared/sortControl.lua
  Sort Control Factory
  
  Creates standardized sort controls with dropdown + direction arrow.
  Matches the pattern used in header bar for consistency.
  
  Features:
  - Arrow inside dropdown on left side
  - Shift+click dropdown to toggle direction
  - Click arrow to toggle direction
  - Returns current sort field and direction
  
  Usage:
    local control = sortControl:create({
        parent = frame,
        width = 150,
        options = {
            { value = "level", text = "Level" },
            { value = "name", text = "Name" },
        },
        defaultField = "level",
        defaultDir = "asc",
        onChange = function(field, dir) ... end,
    })
    
    control:SetValue("name", "desc")
    local field, dir = control:GetValue()
  
  Dependencies: dropdown
  Exports: Addon.sortControl
]]

local ADDON_NAME, Addon = ...

local sortControl = {}

-- Module reference
local dropdown

-- ============================================================================
-- FACTORY
-- ============================================================================

--[[
  Create a sort control.
  
  @param config table - Configuration:
    - parent frame (required) - Parent frame
    - width number - Control width (default 150)
    - options table - Sort field options (required)
    - defaultField string - Initial sort field
    - defaultDir string - Initial direction ("asc" or "desc")
    - onChange function(field, dir) - Called when sort changes
  @return table - Control with methods
]]
function sortControl:create(config)
    if not config or not config.parent then
        error("sortControl:create requires config.parent")
    end
    
    if not dropdown then
        dropdown = Addon.dropdown
        if not dropdown then
            error("sortControl:create requires dropdown module")
        end
    end
    
    local width = config.width or 150
    local options = config.options or {}
    local currentField = config.defaultField or (options[1] and options[1].value)
    local currentDir = config.defaultDir or "asc"
    
    -- Container frame
    local container = CreateFrame("Frame", nil, config.parent)
    container:SetSize(width, 30)
    
    -- Create dropdown
    local dd = dropdown:create({
        parent = container,
        width = width,
        height = 30,
        options = options,
        defaultValue = currentField,
        onClick = function(self, button)
            -- Shift+click toggles direction without opening menu
            if IsShiftKeyDown() then
                currentDir = (currentDir == "desc") and "asc" or "desc"
                container:updateArrow()
                if config.onChange then
                    config.onChange(currentField, currentDir)
                end
                return false  -- Don't show menu
            end
            return true  -- Show menu
        end,
        onChange = function(value)
            currentField = value
            if config.onChange then
                config.onChange(currentField, currentDir)
            end
        end,
    })
    dd:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    
    -- Sort direction arrow (inside dropdown, left side)
    local arrow = dd:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(14, 14)
    arrow:SetPoint("LEFT", dd, "LEFT", 4, 0)
    arrow:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
    container.arrow = arrow
    
    -- Reposition dropdown text to right of arrow
    dd.text:ClearAllPoints()
    dd.text:SetPoint("LEFT", arrow, "RIGHT", 4, 0)
    dd.text:SetPoint("RIGHT", dd, "RIGHT", -18, 0)
    
    -- Tooltip on entire container
    container:EnableMouse(true)
    container:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Shift+click to toggle direction", 1, 1, 1)
        GameTooltip:Show()
    end)
    container:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Store references
    container.dropdown = dd
    
    -- ========================================================================
    -- PUBLIC METHODS
    -- ========================================================================
    
    --[[
      Update arrow texture based on direction.
    ]]
    function container:updateArrow()
        if currentDir == "desc" then
            arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
        else
            arrow:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
        end
    end
    
    --[[
      Get current sort field and direction.
      @return string, string - field, direction
    ]]
    function container:GetValue()
        return currentField, currentDir
    end
    
    --[[
      Set sort field and direction.
      @param field string
      @param dir string - "asc" or "desc"
      @param silent boolean - If true, don't trigger onChange
    ]]
    function container:SetValue(field, dir, silent)
        currentField = field
        currentDir = dir or "asc"
        dd:SetValue(field, true)  -- Update dropdown silently
        self:updateArrow()
        
        if not silent and config.onChange then
            config.onChange(currentField, currentDir)
        end
    end
    
    --[[
      Set enabled state.
      @param enabled boolean
    ]]
    function container:SetEnabled(enabled)
        dd:SetEnabled(enabled)
        arrowBtn:SetEnabled(enabled)
    end
    
    -- Initial arrow state
    container:updateArrow()
    
    return container
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("sortControl", {"dropdown"}, function()
        dropdown = Addon.dropdown
        return true
    end)
end

Addon.sortControl = sortControl
return sortControl