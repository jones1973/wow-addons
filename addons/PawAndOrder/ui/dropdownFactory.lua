--[[
  ui/dropdownFactory.lua
  Reusable Dropdown Widget Factory
  
  Provides standardized dropdown builders for common UI patterns across the addon.
  Extends the base UIDropDownMenu pattern with specific builders for continent filtering,
  return location selection, and generic data-driven dropdowns.
  
  All dropdowns use consistent styling, anchoring, and callback patterns to ensure
  uniform behavior across the addon's UI.
  
  Dependencies: utils, location, circuitConstants
  Exports: Addon.dropdownFactory
]]

local addonName, Addon = ...

Addon.dropdownFactory = {}
local dropdownFactory = Addon.dropdownFactory

--[[
  Create a continent filter dropdown
  Builds a dropdown populated with available continents from NPC database,
  plus an "All Continents" option for unfiltered view.
  
  @param parent Frame - Parent frame to attach dropdown to
  @param availableNpcs table - NPC data organized by category (used to determine available continents)
  @param onContinentChanged function - Callback(continentId) fired when selection changes
  @return Frame - The created dropdown frame
  @return function - getCurrentSelection() method to query selected continent
]]
function dropdownFactory:createContinentFilter(parent, availableNpcs, onContinentChanged)
  local dropdown = CreateFrame("Frame", "PAOContinentFilterDropdown", parent, "UIDropDownMenuTemplate")
  
  UIDropDownMenu_SetWidth(dropdown, 200)
  UIDropDownMenu_SetText(dropdown, "Select Continent")  -- Placeholder, will be set by caller
  
  local currentSelection = nil  -- Will be set when user selects or programmatically via setSelection
  
  -- Build list of available continents from NPC data
  local function getAvailableContinents()
    local continents = {}
    local seen = {}
    
    -- Scan all NPC categories for unique continents
    for _, category in pairs(availableNpcs) do
      for _, npc in ipairs(category) do
        -- Support both npcInfo objects (.continent) and raw NPC data (.locations[1].continent)
        local cid = npc.continent or (npc.locations and npc.locations[1] and npc.locations[1].continent)
        if cid and not seen[cid] then
          seen[cid] = true
          table.insert(continents, cid)
        end
      end
    end
    
    -- Sort continents by ID for consistent ordering
    table.sort(continents, function(a, b)
      -- Handle special "darkmoon" string key
      if type(a) == "string" then return false end
      if type(b) == "string" then return true end
      return a < b
    end)
    
    return continents
  end
  
  UIDropDownMenu_Initialize(dropdown, function(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    
    -- Individual continent options (removed "All Continents")
    local continents = getAvailableContinents()
    for _, continentId in ipairs(continents) do
      local continentName = "Unknown"
      
      if continentId == "darkmoon" then
        continentName = "Darkmoon Faire"
      elseif Addon.location then
        continentName = Addon.location:getContinentName(continentId) or "Unknown"
      end
      
      info.text = continentName
      info.value = continentId
      info.func = function()
        currentSelection = continentId
        UIDropDownMenu_SetText(dropdown, continentName)
        CloseDropDownMenus()
        if onContinentChanged then
          onContinentChanged(continentId)
        end
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
  
  -- Return dropdown and accessor for current selection
  local accessor = {
    getCurrentSelection = function()
      return currentSelection
    end,
    setSelection = function(continentId)
      currentSelection = continentId
      
      -- Update display text
      local displayText = "Unknown"
      if continentId == "darkmoon" then
        displayText = "Darkmoon Faire"
      elseif Addon.location then
        displayText = Addon.location:getContinentName(continentId) or "Unknown"
      end
      
      UIDropDownMenu_SetText(dropdown, displayText)
    end
  }
  
  return dropdown, accessor
end

--[[
  Create a return location picker dropdown
  Builds a dropdown with circuit return location options: None, Current Location,
  and faction-specific Quest Giver. Uses circuit constants for quest giver data.
  
  @param parent Frame - Parent frame to attach dropdown to
  @param onReturnTypeChanged function - Callback(returnType) fired when selection changes
  @return Frame - The created dropdown frame
  @return function - getCurrentSelection() method to query selected return type
]]
function dropdownFactory:createReturnLocationPicker(parent, onReturnTypeChanged)
  local constants = Addon.circuitConstants
  local dropdown = CreateFrame("Frame", "PAOReturnLocationDropdown", parent, "UIDropDownMenuTemplate")
  
  UIDropDownMenu_SetWidth(dropdown, 200)
  UIDropDownMenu_SetText(dropdown, "None")
  
  local currentSelection = constants.RETURN_TYPES.NONE
  
  UIDropDownMenu_Initialize(dropdown, function(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.notCheckable = true
    
    -- None option
    info.text = "None"
    info.value = constants.RETURN_TYPES.NONE
    info.func = function()
      currentSelection = constants.RETURN_TYPES.NONE
      UIDropDownMenu_SetText(dropdown, "None")
      CloseDropDownMenus()
      if onReturnTypeChanged then
        onReturnTypeChanged(constants.RETURN_TYPES.NONE)
      end
    end
    UIDropDownMenu_AddButton(info)
    
    -- Current Location option
    info.text = "Current Location"
    info.value = constants.RETURN_TYPES.CURRENT
    info.func = function()
      currentSelection = constants.RETURN_TYPES.CURRENT
      UIDropDownMenu_SetText(dropdown, "Current Location")
      CloseDropDownMenus()
      if onReturnTypeChanged then
        onReturnTypeChanged(constants.RETURN_TYPES.CURRENT)
      end
    end
    UIDropDownMenu_AddButton(info)
    
    -- Quest Giver option (faction-aware)
    local questGiver = constants:getQuestGiverForFaction()
    local questGiverText = questGiver.name .. " (Fabled Quest Giver)"
    
    info.text = questGiverText
    info.value = constants.RETURN_TYPES.QUEST_GIVER
    info.func = function()
      currentSelection = constants.RETURN_TYPES.QUEST_GIVER
      UIDropDownMenu_SetText(dropdown, questGiverText)
      CloseDropDownMenus()
      if onReturnTypeChanged then
        onReturnTypeChanged(constants.RETURN_TYPES.QUEST_GIVER)
      end
    end
    UIDropDownMenu_AddButton(info)
  end)
  
  -- Return dropdown and accessor for current selection
  local accessor = {
    getCurrentSelection = function()
      return currentSelection
    end
  }
  
  return dropdown, accessor
end

--[[
  Create a generic data-driven dropdown
  Builds a dropdown from an array of items with text/value pairs. Useful for
  any dropdown that doesn't need special logic beyond selection.
  
  @param parent Frame - Parent frame to attach dropdown to
  @param config table - Configuration object:
    {
      name = string,                    -- Optional name for frame identification
      width = number,                   -- Dropdown width in pixels
      items = {                         -- Array of dropdown items
        {text = string, value = any}
      },
      defaultText = string,             -- Initial display text
      onSelectionChanged = function(value, text) end -- Callback when selection changes
    }
  
  @return Frame - The created dropdown frame
  @return function - getCurrentSelection() method to query selected value
]]
function dropdownFactory:createGeneric(parent, config)
  local name = config.name or nil
  local width = config.width or 150
  local items = config.items or {}
  local defaultText = config.defaultText or "Select..."
  local onSelectionChanged = config.onSelectionChanged or function() end
  
  local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
  UIDropDownMenu_SetWidth(dropdown, width)
  UIDropDownMenu_SetText(dropdown, defaultText)
  
  local currentSelection = nil
  
  UIDropDownMenu_Initialize(dropdown, function(self, level)
    for _, item in ipairs(items) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = item.text
      info.value = item.value
      info.notCheckable = true
      info.func = function()
        currentSelection = item.value
        UIDropDownMenu_SetText(dropdown, item.text)
        CloseDropDownMenus()
        onSelectionChanged(item.value, item.text)
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
  
  -- Return dropdown and accessor for current selection
  local accessor = {
    getCurrentSelection = function()
      return currentSelection
    end
  }
  
  return dropdown, accessor
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("dropdownFactory", {"utils", "location", "circuitConstants"}, function()
    return true
  end)
end

return dropdownFactory