--[[
  ui/checkboxTree.lua
  Reusable Hierarchical Checkbox Tree Widget
  
  Provides a flexible three-level checkbox tree component for grouped selections with
  automatic parent/child synchronization. Supports continents as top-level collapsible
  sections with tri-state checkboxes, categories as mid-level groups, and individual
  NPCs as selectable items.
  
  Dependencies: utils, circuitConstants
  Exports: Addon.checkboxTree
]]

local addonName, Addon = ...

Addon.checkboxTree = {}
local checkboxTree = Addon.checkboxTree

function checkboxTree:create(config)
  local constants = Addon.circuitConstants
  
  if not config or not config.parent then
    Addon.utils:error("checkboxTree:create - parent frame required")
    return nil
  end
  
  local parent = config.parent
  local yOffset = config.startY or -10
  local continents = config.continents or {}
  local onSelectionChanged = config.onSelectionChanged or function() end
  local onExpandCollapse = config.onExpandCollapse or function() end  -- NEW: Callback for accordion effect
  local canSelect = config.canSelect or function() return true end  -- Filter for bulk selection
  
  local allFrames = {}
  local expandedContinents = {}
  local continentFramesInOrder = {}  -- Track continents for repositioning
  
  -- Initialize selectedIds
  local selectedIds = {}
  if config.initialSelection and type(config.initialSelection) == "table" then
    for _, id in ipairs(config.initialSelection) do
      table.insert(selectedIds, id)
    end
  end
  
  -- Selection helpers
  local function isSelected(id)
    for _, selectedId in ipairs(selectedIds) do
      if selectedId == id then return true end
    end
    return false
  end
  
  local function removeSelection(id)
    for i, selectedId in ipairs(selectedIds) do
      if selectedId == id then
        table.remove(selectedIds, i)
        return
      end
    end
  end
  
  local function addSelection(id)
    if not isSelected(id) then
      table.insert(selectedIds, id)
    end
  end
  
  -- Add background behind checkbox for visibility against dark backgrounds
  local function addCheckboxBackground(checkbox, size)
    local bg = checkbox:CreateTexture(nil, "BACKGROUND")
    bg:SetPoint("CENTER", checkbox, "CENTER", 0, 0)
    bg:SetSize(size or 18, size or 18)
    bg:SetColorTexture(0.15, 0.15, 0.18, 1.0)  -- Match dropdown background
    checkbox.background = bg
  end
  
  -- Count selected items in continent
  local function countContinentSelection(continentData)
    local selected, total = 0, 0
    for _, category in ipairs(continentData.categories or {}) do
      for _, item in ipairs(category.items or {}) do
        if not item.disabled then
          total = total + 1
          if isSelected(item.id) then
            selected = selected + 1
          end
        end
      end
    end
    return selected, total
  end
  
  -- Count selected items in a category's checkboxes
  local function countCategorySelection(categoryCheckboxes)
    local selected, total = 0, 0
    for _, itemCb in ipairs(categoryCheckboxes) do
      if not itemCb.disabled then
        total = total + 1
        if itemCb:GetChecked() then
          selected = selected + 1
        end
      end
    end
    return selected, total
  end
  
  -- Update continent tri-state checkbox
  local function updateContinentCheckbox(continentCheck, continentData)
    local selected, total = countContinentSelection(continentData)
    
    if selected == 0 then
      continentCheck:SetChecked(false)
      continentCheck:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    elseif selected == total then
      continentCheck:SetChecked(true)
      continentCheck:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    else
      -- Partially checked
      continentCheck:SetChecked(true)
      continentCheck:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
    end
  end
  
  -- Update category tri-state checkbox
  local function updateCategoryCheckbox(categoryCheck, categoryCheckboxes)
    local selected, total = 0, 0
    
    for _, itemCb in ipairs(categoryCheckboxes) do
      if not itemCb.disabled then
        total = total + 1
        if itemCb:GetChecked() then
          selected = selected + 1
        end
      end
    end
    
    if total == 0 then
      -- All disabled
      categoryCheck:SetChecked(false)
      categoryCheck:Disable()
      categoryCheck:SetAlpha(0.5)
    else
      categoryCheck:Enable()
      categoryCheck:SetAlpha(1.0)
      
      if selected == 0 then
        categoryCheck:SetChecked(false)
        categoryCheck:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
      elseif selected == total then
        categoryCheck:SetChecked(true)
        categoryCheck:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
      else
        -- Partially checked
        categoryCheck:SetChecked(true)
        categoryCheck:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check-Disabled")
      end
    end
  end
  
  -- Reposition all frames after expand/collapse for accordion effect
  local function repositionAllFrames()
    local currentY = -10  -- Starting Y position
    
    for _, continentInfo in ipairs(continentFramesInOrder) do
      -- Position continent header
      continentInfo.frame:ClearAllPoints()
      continentInfo.frame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, currentY)
      currentY = currentY - constants.UI.CATEGORY_HEIGHT
      
      -- If expanded, position categories and items
      if expandedContinents[continentInfo.id] then
        for _, catFrame in ipairs(continentInfo.categoryFrames) do
          -- Position category label
          catFrame:ClearAllPoints()
          catFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, currentY)
          currentY = currentY - constants.UI.CATEGORY_HEIGHT
          
          -- Position all item frames
          for _, itemFrame in ipairs(catFrame.itemFrames or {}) do
            itemFrame:ClearAllPoints()
            itemFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 50, currentY)
            currentY = currentY - constants.UI.CHECKBOX_HEIGHT
          end
          
          -- Category spacing
          currentY = currentY - 5
        end
      end
    end
  end
  
  -- Create single item
  local function createItem(itemData, categoryCheckboxes, continentCheck, currentY)
    -- Handle spacer items (blank lines)
    if itemData.isSpacer then
      local spacerFrame = CreateFrame("Frame", nil, parent)
      spacerFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 50, currentY)
      spacerFrame:SetSize(320, constants.UI.CHECKBOX_HEIGHT)
      table.insert(allFrames, spacerFrame)
      currentY = currentY - constants.UI.CHECKBOX_HEIGHT
      return currentY, spacerFrame, nil
    end
    
    -- Item frame
    local itemFrame = CreateFrame("Frame", nil, parent)
    itemFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 50, currentY)
    itemFrame:SetSize(320, constants.UI.CHECKBOX_HEIGHT)
    table.insert(allFrames, itemFrame)
    
    -- Item checkbox
    local itemCheck = CreateFrame("CheckButton", nil, itemFrame, "UICheckButtonTemplate")
    itemCheck:SetPoint("LEFT", itemFrame, "LEFT", 0, 0)
    itemCheck:SetSize(18, 18)
    addCheckboxBackground(itemCheck, 16)
    itemCheck.itemId = itemData.id
    itemCheck.itemData = itemData
    itemCheck.disabled = itemData.disabled or false
    table.insert(allFrames, itemCheck)
    table.insert(categoryCheckboxes, itemCheck)
    
    -- Pre-select if needed
    if isSelected(itemData.id) then
      itemCheck:SetChecked(true)
    end
    
    -- Handle disabled state
    if itemData.disabled then
      itemCheck:Disable()
      itemCheck:SetAlpha(0.5)
    end
    
    -- Optional icon (bag icon takes priority over portal icon)
    local labelOffsetX = 5
    if itemData.bagIcon then
      -- Show bag icon for NPCs that give pet supply bags
      local bagTexture = itemFrame:CreateTexture(nil, "ARTWORK")
      bagTexture:SetSize(16, 16)
      bagTexture:SetPoint("LEFT", itemCheck, "RIGHT", 5, 0)
      bagTexture:SetTexture(itemData.bagIcon)  -- Using texture ID
      labelOffsetX = 25
      
      -- Add tooltip to bag icon showing contents
      if itemData.bagContents then
        local bagIconFrame = CreateFrame("Frame", nil, itemFrame)
        bagIconFrame:SetAllPoints(bagTexture)
        bagIconFrame:EnableMouse(true)
        bagIconFrame:SetScript("OnEnter", function(self)
          local tip = Addon.tooltip
          tip:show(self, { anchor = "TOPLEFT", relPoint = "TOPRIGHT", offsetX = 5, offsetY = 0 })
          tip:header(itemData.bagName or "Pet Supplies", {color = {1, 1, 1}})
          tip:text("May contain:", {color = {0.8, 0.8, 0.8}})
          
          -- WoW quality colors for items
          local COLOR_RARE = {0, 0.44, 0.87}        -- Blue for rare items and pets
          local COLOR_UNCOMMON = {0.3, 0.9, 0.3}    -- Green for toys
          local COLOR_COMMON = {1, 1, 1}            -- White for regular items
          
          -- Format contents with pet collection counts
          for _, content in ipairs(itemData.bagContents) do
            local line = "  " .. content.name
            local color = COLOR_COMMON
            
            if content.type == "pet" and content.speciesID then
              -- Get formatted ownership string (e.g., "2/3")
              local ownedString = C_PetJournal.GetOwnedBattlePetString(content.speciesID)
              if ownedString and ownedString ~= "" then
                line = line .. " (" .. ownedString .. ")"
              end
              
              color = COLOR_RARE  -- Rare blue for pets
            elseif content.type == "toy" then
              line = line .. " (toy)"
              color = COLOR_UNCOMMON  -- Uncommon green for toys
            elseif content.name:find("Battle%-Stone") then
              color = COLOR_RARE  -- Rare blue for battle-stones
            end
            
            tip:text(line, {color = color})
          end
          
          tip:done()
        end)
        bagIconFrame:SetScript("OnLeave", function(self)
          Addon.tooltip:hide()
        end)
      end
    elseif itemData.portalIcon then
      -- Show portal icon for NPCs that require portal travel
      local portalTexture = itemFrame:CreateTexture(nil, "ARTWORK")
      portalTexture:SetSize(16, 16)
      portalTexture:SetPoint("LEFT", itemCheck, "RIGHT", 5, 0)
      portalTexture:SetTexture(itemData.portalIcon)
      labelOffsetX = 25
    end
    
    -- Item label
    local itemLabel = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    itemLabel:SetPoint("LEFT", itemCheck, "RIGHT", labelOffsetX, 0)
    itemLabel:SetText(itemData.label)
    
    if itemData.disabled then
      itemLabel:SetTextColor(0.5, 0.5, 0.5)
    elseif itemData.completed then
      itemLabel:SetTextColor(0.7, 0.7, 0.7)  -- Dimmed for completed
    end
    
    -- Add strikethrough line for completed non-repeatable quests
    if itemData.completed and itemData.disabled then
      local strikethrough = itemFrame:CreateTexture(nil, "OVERLAY")
      strikethrough:SetHeight(1)
      strikethrough:SetColorTexture(0.5, 0.5, 0.5, 0.8)
      strikethrough:SetPoint("LEFT", itemLabel, "LEFT", 0, 0)
      strikethrough:SetPoint("RIGHT", itemLabel, "RIGHT", 0, 0)
    end
    
    -- Make label clickable to toggle checkbox
    itemLabel:SetScript("OnMouseUp", function(self, button)
      if button == "LeftButton" and not itemCheck.disabled then
        itemCheck:Click()
      end
    end)
    itemLabel:EnableMouse(true)
    
    -- Tooltip on label (same as frame tooltip)
    itemLabel:SetScript("OnEnter", function(self)
      if itemData.disabled and itemData.disabledReason then
        local tip = Addon.tooltip
        tip:show(self, { anchor = "TOPLEFT", relPoint = "TOPRIGHT", offsetX = 5, offsetY = 0 })
        tip:header(itemData.disabledReason, {color = {1, 0.5, 0.5}})
        tip:done()
      elseif itemData.completed then
        local tip = Addon.tooltip
        tip:show(self, { anchor = "TOPLEFT", relPoint = "TOPRIGHT", offsetX = 5, offsetY = 0 })
        tip:header("Completed today", {color = {0.5, 1, 0.5}})
        tip:done()
      end
    end)
    itemLabel:SetScript("OnLeave", function(self)
      Addon.tooltip:hide()
    end)
    
    -- Tooltip on entire item frame (checkbox + icon + label)
    itemFrame:EnableMouse(true)
    itemFrame:SetScript("OnEnter", function(self)
      if itemData.disabled and itemData.disabledReason then
        local tip = Addon.tooltip
        tip:show(self, { anchor = "TOPLEFT", relPoint = "TOPRIGHT", offsetX = 5, offsetY = 0 })
        tip:header(itemData.disabledReason, {color = {1, 0.5, 0.5}})
        tip:done()
      elseif itemData.completed then
        local tip = Addon.tooltip
        tip:show(self, { anchor = "TOPLEFT", relPoint = "TOPRIGHT", offsetX = 5, offsetY = 0 })
        tip:header("Completed today", {color = {0.5, 1, 0.5}})
        tip:done()
      end
    end)
    itemFrame:SetScript("OnLeave", function(self)
      Addon.tooltip:hide()
    end)
    
    -- Item checkbox click handler (will be set after all items created)
    itemCheck.categoryCheckboxes = categoryCheckboxes
    itemCheck.continentCheck = continentCheck
    
    currentY = currentY - constants.UI.CHECKBOX_HEIGHT
    return currentY, itemFrame, itemCheck
  end
  
  -- Create category section
  local function createCategory(categoryData, continentCheck, currentY)
    -- Category frame
    local categoryFrame = CreateFrame("Frame", nil, parent)
    categoryFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 30, currentY)
    categoryFrame:SetSize(340, constants.UI.CATEGORY_HEIGHT)
    table.insert(allFrames, categoryFrame)
    
    -- Category checkbox
    local categoryCheck = CreateFrame("CheckButton", nil, categoryFrame, "UICheckButtonTemplate")
    categoryCheck:SetPoint("LEFT", categoryFrame, "LEFT", 0, 0)
    categoryCheck:SetSize(20, 20)
    addCheckboxBackground(categoryCheck, 18)
    table.insert(allFrames, categoryCheck)
    
    -- Category label (gold color, positioned after checkbox)
    local categoryLabel = categoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    categoryLabel:SetPoint("LEFT", categoryCheck, "RIGHT", 5, 0)
    categoryLabel:SetTextColor(1, 0.82, 0)  -- Gold color
    categoryCheck.categoryLabel = categoryLabel
    categoryCheck.categoryName = categoryData.name
    
    -- Make label clickable to toggle category checkbox
    categoryLabel:SetScript("OnMouseUp", function(self, button)
      if button == "LeftButton" then
        categoryCheck:Click()
      end
    end)
    categoryLabel:EnableMouse(true)
    
    currentY = currentY - constants.UI.CATEGORY_HEIGHT
    
    -- Create all item checkboxes for this category
    local categoryCheckboxes = {}
    local itemFrames = {}
    
    for _, itemData in ipairs(categoryData.items or {}) do
      local itemY, itemFrame, itemCheck = createItem(itemData, categoryCheckboxes, continentCheck, currentY)
      currentY = itemY
      table.insert(itemFrames, itemFrame)
    end
    
    -- Store checkboxes reference and create label update function
    categoryCheck.categoryCheckboxes = categoryCheckboxes
    local function updateCategoryLabel()
      local selected, total = countCategorySelection(categoryCheckboxes)
      categoryLabel:SetText(string.format("%s (%d/%d)", categoryData.name, selected, total))
    end
    categoryCheck.updateLabel = updateCategoryLabel
    updateCategoryLabel()  -- Set initial label
    
    -- Set up click handlers for all items now that they're created
    for _, itemCheck in ipairs(categoryCheckboxes) do
      itemCheck:SetScript("OnClick", function(self)
        if self:GetChecked() then
          addSelection(self.itemId)
        else
          removeSelection(self.itemId)
        end
        
        -- Update category checkbox with tri-state
        updateCategoryCheckbox(categoryCheck, categoryCheckboxes)
        
        -- Update category label with counts
        updateCategoryLabel()
        
        -- Update continent
        updateContinentCheckbox(continentCheck, continentCheck.continentData)
        local selected, total = countContinentSelection(continentCheck.continentData)
        continentCheck.continentLabel:SetText(string.format("%s (%d selected)", continentCheck.continentData.name, selected))
        
        onSelectionChanged(selectedIds)
      end)
    end
    
    -- Category checkbox click handler
    categoryCheck:SetScript("OnClick", function(self)
      local isChecked = self:GetChecked()
      
      -- Select/deselect all non-disabled children (respecting canSelect for bulk select)
      for _, childCb in ipairs(categoryCheckboxes) do
        if not childCb.disabled then
          if isChecked then
            -- Only select if canSelect allows
            if canSelect(childCb.itemData) then
              childCb:SetChecked(true)
              addSelection(childCb.itemId)
            end
          else
            childCb:SetChecked(false)
            removeSelection(childCb.itemId)
          end
        end
      end
      
      -- Update category label with counts
      updateCategoryLabel()
      
      -- Update continent
      updateContinentCheckbox(continentCheck, continentCheck.continentData)
      local selected, total = countContinentSelection(continentCheck.continentData)
      continentCheck.continentLabel:SetText(string.format("%s (%d selected)", continentCheck.continentData.name, selected))
      
      onSelectionChanged(selectedIds)
    end)
    
    -- Set initial category checkbox state with tri-state
    updateCategoryCheckbox(categoryCheck, categoryCheckboxes)
    
    categoryFrame.itemFrames = itemFrames
    categoryFrame.categoryCheckboxes = categoryCheckboxes
    categoryFrame.categoryCheck = categoryCheck  -- Store for continent checkbox updates
    
    currentY = currentY - 5  -- Spacing after category
    return currentY, categoryFrame
  end
  
  -- Create continent section
  local function createContinent(continentData, currentY)
    local continentId = continentData.id
    
    -- Count selectable items
    local totalItems = 0
    for _, cat in ipairs(continentData.categories or {}) do
      for _, item in ipairs(cat.items or {}) do
        if not item.disabled then
          totalItems = totalItems + 1
        end
      end
    end
    
    if totalItems == 0 then
      return currentY
    end
    
    -- All continents start collapsed
    expandedContinents[continentId] = false
    
    -- Continent header frame (clickable for expand/collapse)
    local continentFrame = CreateFrame("Frame", nil, parent)
    continentFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, currentY)
    continentFrame:SetSize(360, constants.UI.CATEGORY_HEIGHT)
    continentFrame:EnableMouse(true)
    table.insert(allFrames, continentFrame)
    
    -- Expand/collapse indicator icon (positioned first, on the left)
    local expandIndicator = continentFrame:CreateTexture(nil, "ARTWORK")
    expandIndicator:SetSize(16, 16)
    expandIndicator:SetPoint("LEFT", continentFrame, "LEFT", 0, 0)
    expandIndicator:SetTexture(expandedContinents[continentId] and 
      "Interface\\AddOns\\PawAndOrder\\textures\\collapse_arrow.png" or 
      "Interface\\AddOns\\PawAndOrder\\textures\\expand_arrow.png")
    
    -- Continent checkbox (positioned after expand indicator)
    local continentCheck = CreateFrame("CheckButton", nil, continentFrame, "UICheckButtonTemplate")
    continentCheck:SetPoint("LEFT", expandIndicator, "RIGHT", 5, 0)
    continentCheck:SetSize(24, 24)
    addCheckboxBackground(continentCheck, 22)
    table.insert(allFrames, continentCheck)
    
    -- Continent label with selection count (positioned after checkbox)
    local continentLabel = continentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    continentLabel:SetPoint("LEFT", continentCheck, "RIGHT", 5, 0)
    local selected, total = countContinentSelection(continentData)
    continentLabel:SetText(string.format("%s (%d selected)", continentData.name, selected))
    
    -- Make label clickable to toggle continent checkbox
    continentLabel:SetScript("OnMouseUp", function(self, button)
      if button == "LeftButton" then
        continentCheck:Click()
        return true  -- Stop event propagation to prevent expand/collapse
      end
    end)
    continentLabel:EnableMouse(true)
    
    -- Store references
    continentCheck.continentData = continentData
    continentCheck.continentLabel = continentLabel
    continentCheck.expandIndicator = expandIndicator
    continentCheck.categoryFrames = {}
    
    -- Set initial checkbox state
    updateContinentCheckbox(continentCheck, continentData)
    
    -- Continent checkbox click handler
    continentCheck:SetScript("OnClick", function(self)
      local isChecked = self:GetChecked()
      
      -- Select/deselect all non-disabled items (respecting canSelect for bulk select)
      for _, category in ipairs(self.continentData.categories or {}) do
        for _, item in ipairs(category.items or {}) do
          if not item.disabled then
            if isChecked then
              -- Only select if canSelect allows
              if canSelect(item) then
                addSelection(item.id)
              end
            else
              removeSelection(item.id)
            end
          end
        end
      end
      
      -- Update all child checkboxes visually (including category checkboxes with tri-state)
      for _, catFrame in ipairs(self.categoryFrames) do
        -- Update item checkboxes first
        for _, itemCb in ipairs(catFrame.categoryCheckboxes or {}) do
          if not itemCb.disabled then
            if isChecked then
              -- Only check if canSelect allows
              if canSelect(itemCb.itemData) then
                itemCb:SetChecked(true)
              end
            else
              itemCb:SetChecked(false)
            end
          end
        end
        
        -- Update category checkbox with tri-state
        if catFrame.categoryCheck then
          updateCategoryCheckbox(catFrame.categoryCheck, catFrame.categoryCheckboxes)
          -- Update category label with counts
          if catFrame.categoryCheck.updateLabel then
            catFrame.categoryCheck.updateLabel()
          end
        end
      end
      
      -- Update label
      local selected, total = countContinentSelection(self.continentData)
      self.continentLabel:SetText(string.format("%s (%d selected)", self.continentData.name, selected))
      
      onSelectionChanged(selectedIds)
    end)
    
    -- Expand/collapse click handler on the FRAME (only trigger on arrow icon area)
    continentFrame:SetScript("OnMouseUp", function(self, button)
      if button == "LeftButton" then
        -- Get cursor position relative to frame
        local scale = self:GetEffectiveScale()
        local left = self:GetLeft() * scale
        local cursorX = GetCursorPosition()
        local relativeX = (cursorX - left) / scale
        
        -- Only expand/collapse if clicked on leftmost 30 pixels (arrow icon area)
        if relativeX <= 30 then
          local isExpanded = expandedContinents[continentId]
          expandedContinents[continentId] = not isExpanded
          
          -- Update indicator icon
          expandIndicator:SetTexture(expandedContinents[continentId] and 
            "Interface\\AddOns\\PawAndOrder\\textures\\collapse_arrow.png" or 
            "Interface\\AddOns\\PawAndOrder\\textures\\expand_arrow.png")
          
          -- Show/hide all category frames and their items
          for i, catFrame in ipairs(continentCheck.categoryFrames) do
            if expandedContinents[continentId] then
              catFrame:Show()
              for j, itemFrame in ipairs(catFrame.itemFrames or {}) do
                itemFrame:Show()
              end
            else
              catFrame:Hide()
              for _, itemFrame in ipairs(catFrame.itemFrames or {}) do
                itemFrame:Hide()
              end
            end
          end
          
          -- Reposition all frames for accordion effect
          repositionAllFrames()
          
          -- Notify parent to recalculate scroll height for accordion effect
          onExpandCollapse()
        end
      end
    end)
    
    currentY = currentY - constants.UI.CATEGORY_HEIGHT
    
    -- Create all categories
    for _, categoryData in ipairs(continentData.categories or {}) do
      if categoryData.items and #categoryData.items > 0 then
        local catY, categoryFrame = createCategory(categoryData, continentCheck, currentY)
        currentY = catY
        if categoryFrame then
          table.insert(continentCheck.categoryFrames, categoryFrame)
          -- Show if continent starts expanded (Pandaria), hide otherwise
          if expandedContinents[continentId] then
            categoryFrame:Show()
            for _, itemFrame in ipairs(categoryFrame.itemFrames or {}) do
              itemFrame:Show()
            end
          else
            categoryFrame:Hide()
            for _, itemFrame in ipairs(categoryFrame.itemFrames or {}) do
              itemFrame:Hide()
            end
          end
        end
      end
    end
    
    -- Store continent info for repositioning
    table.insert(continentFramesInOrder, {
      id = continentId,
      frame = continentFrame,
      categoryFrames = continentCheck.categoryFrames
    })
    
    return currentY
  end
  
  -- Build all continents
  for _, continentData in ipairs(continents) do
    yOffset = createContinent(continentData, yOffset)
  end
  
  -- Position all frames in collapsed state initially (accordion effect)
  repositionAllFrames()
  
  -- Return tree state
  return {
    frames = allFrames,
    selectedIds = selectedIds,
    yOffset = yOffset,
    
    -- Get current expansion state (which continents are expanded)
    getExpansionState = function()
      return expandedContinents
    end,
    
    -- Calculate visible height based on tree structure and expansion state
    getVisibleHeight = function()
      local height = 20  -- Top padding
      
      for _, continentData in ipairs(continents) do
        -- Continent header always visible
        height = height + constants.UI.CATEGORY_HEIGHT
        
        -- If expanded, add categories and items
        if expandedContinents[continentData.id] then
          for _, category in ipairs(continentData.categories or {}) do
            if category.items and #category.items > 0 then
              -- Category label
              height = height + constants.UI.CATEGORY_HEIGHT
              -- All items
              height = height + (#category.items * constants.UI.CHECKBOX_HEIGHT)
              -- Spacing after category
              height = height + 5
            end
          end
        end
      end
      
      height = height + 20  -- Bottom padding
      return height
    end,
    
    refresh = function()
      for _, frame in ipairs(allFrames) do
        frame:Hide()
      end
      wipe(allFrames)
      wipe(selectedIds)
      return checkboxTree:create(config)
    end
  }
end

function checkboxTree:destroy(treeState)
  if not treeState or not treeState.frames then
    return
  end
  
  for _, frame in ipairs(treeState.frames) do
    frame:Hide()
    frame:SetParent(nil)
  end
  
  wipe(treeState.frames)
  wipe(treeState.selectedIds)
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("checkboxTree", {"utils", "circuitConstants", "tooltip"}, function()
    return true
  end)
end

return checkboxTree