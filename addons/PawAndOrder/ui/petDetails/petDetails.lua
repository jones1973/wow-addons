--[[
  ui/petDetails/petDetails.lua
  Pet Details Panel Coordinator

  Coordinates the detail panel display, delegating to:
    - infoSection: Pet icon, name, stats, abilities, source
    - teamSection: Battle team display with drag/drop

  Responsibilities:
    - Panel creation and layout
    - Background frames for sections
    - Event handling for filter changes
    - Delegation to child modules

  Dependencies: constants, petUtils, uiUtils, teamActions, teamManagement
  Child modules: infoSection, teamSection
  Exports: Addon.petDetails
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
  print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in petDetails.lua|r")
  return {}
end

-- Module references (set in initialize)
local utils, constants, petUtils, uiUtils, teamActions, teamManagement, escapeHandler

-- Child modules (loaded in initialize)
local infoSection = nil
local teamSection = nil

-- Panel reference
local detailPanel = nil

-- Stored bounds from mainFrame
local bounds = nil

-- Fixed height for info section (parent owns vertical division)
-- Calculation: ICON_TOP(12) + ICON_SIZE(64) + ABILITIES_TOP_OFFSET(70) + header(14) + 
--              row2_offset(40) + frame_height(24) + bottom_padding(12) = 236
local INFO_SECTION_HEIGHT = 236

-- Gap between info section and team section (parent owns vertical division)
local SECTION_GAP = 12

local petDetails = {}

--[[
  Create Main Detail Panel
  Builds the detail panel frame and delegates UI creation to child modules.

  @param parent frame - Parent frame to attach detail panel to
]]
function petDetails:createPanel(parent)
  local L = constants.LAYOUT
  
  -- Use bounds from mainFrame (single source of truth)
  local detailTop = bounds.contentTop
  local detailLeft = constants.LIST_WIDTH + bounds.sectionGap + bounds.edgePadding
  
  detailPanel = CreateFrame("Frame", nil, parent)
  detailPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", detailLeft, detailTop)
  detailPanel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -bounds.edgePadding, bounds.edgePadding)

  -- Background (transparent base)
  local bg = detailPanel:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0, 0, 0, 0.15)
  detailPanel.bg = bg
  
  -- Detail section background (info section)
  -- Parent sets fixed height; infoSection positions content within these bounds
  detailPanel.detailBg = CreateFrame("Frame", nil, detailPanel)
  detailPanel.detailBg:SetFrameLevel(detailPanel:GetFrameLevel())
  detailPanel.detailBg:SetPoint("TOPLEFT", detailPanel, "TOPLEFT", 0, 0)
  detailPanel.detailBg:SetPoint("TOPRIGHT", detailPanel, "TOPRIGHT", 0, 0)
  detailPanel.detailBg:SetHeight(INFO_SECTION_HEIGHT)
  
  local detailBgTex = detailPanel.detailBg:CreateTexture(nil, "BACKGROUND")
  detailBgTex:SetAllPoints()
  detailBgTex:SetColorTexture(unpack(L.DETAIL_BG_COLOR))
  
  -- Team section background (anchors below info section with gap, fills to bottom)
  detailPanel.teamBg = CreateFrame("Frame", nil, detailPanel)
  detailPanel.teamBg:SetFrameLevel(detailPanel:GetFrameLevel())
  detailPanel.teamBg:SetPoint("TOPLEFT", detailPanel.detailBg, "BOTTOMLEFT", 0, -SECTION_GAP)
  detailPanel.teamBg:SetPoint("BOTTOMRIGHT", detailPanel, "BOTTOMRIGHT", 0, 0)
  
  local teamBgTex = detailPanel.teamBg:CreateTexture(nil, "BACKGROUND")
  teamBgTex:SetAllPoints()
  teamBgTex:SetColorTexture(unpack(L.DETAIL_BG_COLOR))

  -- Initialize infoSection with panel reference
  infoSection:initialize(detailPanel, {
    constants = constants,
    petUtils = petUtils,
    uiUtils = uiUtils
  })
  
  -- Initialize teamSection with panel reference
  teamSection:initialize(detailPanel, {
    constants = constants,
    petDetails = petDetails,
    uiUtils = uiUtils
  })

  -- Create UI elements via child modules
  infoSection:create()
  teamSection:create(teamActions, teamManagement)

  -- Initial empty state
  self:showPetDetail(nil)
  
  -- Note: teamSection:update() is called by onResize() which is triggered by OnShow
  -- This ensures proper top-down width propagation
end

--[[
  Show Pet Detail
  Main entry point for updating the detail panel with pet information.

  @param petData table|nil - Pet data from petList, or nil to clear display
  @param matchContext table|nil - Filter match context for highlighting
]]
function petDetails:showPetDetail(petData, matchContext)
  if not detailPanel then return end
  
  -- Store current pet for event-driven updates
  detailPanel.currentPetData = petData
  
  -- Delegate to infoSection
  infoSection:update(petData, matchContext)
  
  -- Hide team section elements when no pet selected
  if not petData then
    if detailPanel.teamHeader then
      detailPanel.teamHeader:Hide()
    end
    if detailPanel.teamSlots then
      for _, slotFrame in ipairs(detailPanel.teamSlots) do
        slotFrame:Hide()
      end
    end
  end
end

--[[
  Handle Resize
  Updates dynamic layout elements when the panel is resized.
  Stores width on panel and passes to children (top-down sizing).
  
  @param width number - Panel width from parent
]]
function petDetails:onResize(width)
  if not detailPanel then return end
  
  -- Store width for children to use
  detailPanel.panelWidth = width

  -- Delegate to child modules with width
  infoSection:onResize(width)
  teamSection:onResize(width)  -- Uses resize-specific handling (defers model rotation)
end

--[[
  Update Highlighting
  Updates match highlighting for the current pet without full refresh.

  @param matchContext table|nil - Match context for current filter
]]
function petDetails:updateHighlighting(matchContext)
  if infoSection then
    infoSection:updateHighlighting(matchContext)
  end
end

-- Team section delegation
function petDetails:refreshTeamDisplay()
  if teamSection and detailPanel then
    teamSection:update(detailPanel.panelWidth)
  end
end

function petDetails:showDropTargets(sourceSlot)
  if teamSection then
    teamSection:showDropTargets(sourceSlot)
  end
end

function petDetails:hideDropTargets()
  if teamSection then
    teamSection:hideDropTargets()
  end
end

--[[
  Initialize pet details module
  Sets up all UI components and registers event handlers.

  @param parent frame - Parent frame to attach detail panel to
  @param layoutBounds table - Layout bounds from mainFrame
]]
function petDetails:initialize(parent, layoutBounds)
  if detailPanel then return end

  utils = Addon.utils
  constants = Addon.constants
  petUtils = Addon.petUtils
  uiUtils = Addon.uiUtils
  teamActions = Addon.teamActions
  teamManagement = Addon.teamManagement
  escapeHandler = Addon.escapeHandler

  if not utils or not constants or not petUtils or not uiUtils or not teamActions or not teamManagement or not escapeHandler then
    utils:error("Dependency missing in " .. debugstack(2, 1, 0))
    return
  end
  
  -- Store bounds from mainFrame
  bounds = layoutBounds
  
  -- Load child modules (loaded via .toc before this file)
  infoSection = Addon.infoSection
  if not infoSection then
    utils:error("infoSection module not loaded")
    return
  end
  
  teamSection = Addon.teamSection
  if not teamSection then
    utils:error("teamSection module not loaded")
    return
  end
  
  -- Register for settings change events
  if Addon.events then
    Addon.events:subscribe("SETTING:LISTING_CHANGED", function(eventName, payload)
      if payload and payload.name == "fadeLevelOpacity" then
        if detailPanel and detailPanel.currentPetData then
          petDetails:showPetDetail(detailPanel.currentPetData)
        end
      end
    end, petDetails)
  end
  
  -- Register for filter change events
  if Addon.events then
    Addon.events:subscribe("FILTER:TEXT_CHANGED", function(eventName, payload)
      if not detailPanel or not detailPanel.currentPetData then return end
      
      local filterText = payload and payload.filterText or ""
      
      -- Get fresh match context for current pet
      if Addon.petFilters and filterText ~= "" then
        local context = Addon.petFilters:getMatchContext(detailPanel.currentPetData, filterText)
        petDetails:updateHighlighting(context)
      else
        petDetails:updateHighlighting(nil)
      end
    end)
  end
  
  -- Refresh detail panel when displayed pet is updated (rarity upgrade, rename, etc.)
  if Addon.events then
    Addon.events:subscribe("CACHE:PET_UPDATED", function(eventName, payload)
      if not detailPanel or not detailPanel.currentPetData then return end
      if payload and payload.petID == detailPanel.currentPetData.petID then
        -- Update stored reference and refresh display
        detailPanel.currentPetData = payload.pet
        petDetails:showPetDetail(payload.pet)
      end
    end)
  end

  -- Hide drop targets when pet cursor is cleared
  if Addon.events then
    Addon.events:subscribe("BATTLE_PET_CURSOR_CLEAR", function()
      if detailPanel then
        petDetails:hideDropTargets()
      end
    end)
  end

  -- Create escape handler for drag operations using shared module
  if escapeHandler then
    petDetails.escapeHandler = escapeHandler:create({
      onCancel = function()
        -- ESC pressed - clear cursor and hide drop targets
        ClearCursor()
        petDetails:hideDropTargets()
      end,
      onRelease = function()
        -- First mouse release - check if over drop target
        local cursorType, petID = GetCursorInfo()
        if cursorType == "battlepet" and petID then
          -- Check if over a drop target
          local overDropTarget = false
          local targetSlot = nil
          if detailPanel and detailPanel.teamSlots then
            for i = 1, 3 do
              local slot = detailPanel.teamSlots[i]
              if slot and slot.dropTarget and slot.dropTarget:IsShown() and MouseIsOver(slot.dropTarget) then
                overDropTarget = true
                targetSlot = slot
                break
              end
            end
          end
          
          if overDropTarget then
            -- Over drop target - drop immediately
            local handler = targetSlot.dropTarget:GetScript("OnReceiveDrag")
            if handler then
              handler(targetSlot.dropTarget)
            end
          else
            -- Not over drop target - transition to click-to-drop mode
            teamSection.isInitialDragRelease = false
          end
        end
      end,
      onClick = function(button)
        -- Subsequent click - check if over drop target
        local cursorType, petID = GetCursorInfo()
        if cursorType == "battlepet" and petID then
          local overDropTarget = false
          local targetSlot = nil
          if detailPanel and detailPanel.teamSlots then
            for i = 1, 3 do
              local slot = detailPanel.teamSlots[i]
              if slot and slot.dropTarget and slot.dropTarget:IsShown() and MouseIsOver(slot.dropTarget) then
                overDropTarget = true
                targetSlot = slot
                break
              end
            end
          end
          
          if overDropTarget and button == "LeftButton" then
            -- Over drop target - drop
            local handler = targetSlot.dropTarget:GetScript("OnMouseUp")
            if handler then
              handler(targetSlot.dropTarget, button)
            end
          else
            -- Not over drop target or wrong button - cancel
            ClearCursor()
            petDetails:hideDropTargets()
          end
        end
      end
    })
    
    -- Share escape handler with teamSection
    if petDetails.escapeHandler then
      teamSection:setEscapeHandler(petDetails.escapeHandler)
    end
  end

  self:createPanel(parent)
end

-- Module registration
if Addon.registerModule then
  Addon.registerModule("petDetails", {"utils", "constants", "petUtils", "uiUtils", "teamActions", "teamManagement", "escapeHandler"}, function()
    return true
  end)
end

Addon.petDetails = petDetails
return petDetails