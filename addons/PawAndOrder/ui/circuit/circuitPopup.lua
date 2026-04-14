--[[
  ui/circuit/circuitPopup.lua
  Pet Battle Circuit UI - Planning and Tracking Interface
  
  Provides the main circuit configuration popup where users select NPCs and configure
  return locations, plus a persistent tracker bar that monitors progress during active
  circuits. Uses three-level collapsible continent sections (continent → category → NPC)
  with tri-state checkboxes and portal icons for optimal UX.
  
  Uses extracted UI components (checkboxTree, dropdown, circuitTracker) for clean,
  reusable patterns while maintaining circuit-specific orchestration. Battle event
  handling extracted to circuitBattleHandler, NPC filtering to circuitNpcFilter.
  
  Listens to internal circuit events for state updates, maintaining clean separation
  between logic and UI layers through event-driven architecture.
  
  Dependencies: utils, commands, circuit, waypoint, location, popupFactory, events, npcUtils, 
                circuitPersistence, circuitConstants, circuitBattleHandler, circuitNpcFilter,
                checkboxTree, dropdown, circuitTracker, actionButton
  
  Exports: Addon.circuitUI
]]

local addonName, Addon = ...

Addon.circuitUI = {}
local circuitUI = Addon.circuitUI


-- UI state
local popupFrame = nil
local scrollFrame = nil
local scrollChild = nil
local checkboxTreeState = nil
local returnDropdown = nil
local selectedNpcs = {}
local selectedReturnType = "none"
local stagingSelections = {}  -- Persist selections during current session (not saved to disk)

-- Restoration tracking
local restorationComplete = false

-- Zone change debounce (prevents rapid zone-hopping from triggering multiple route recalculations)
local ZONE_CHANGE_DEBOUNCE = 2.0  -- seconds to wait before processing zone change
local pendingZoneChangeTimer = nil

--[[
  Get continent display name using location module
  Helper function for translating continent IDs to human-readable names.
  
  @param continentId number|string - Continent ID or special key like "darkmoon"
  @return string - Human-readable continent display name
]]
local function getContinentDisplayName(continentId)
  -- Special case for Darkmoon (string key - should not occur with faction mapping)
  if continentId == "darkmoon" then
    return "Darkmoon Faire"
  end
  
  -- Use location module for real continent IDs
  if type(continentId) == "number" and Addon.location then
    local name = Addon.location:getContinentName(continentId)
    if name and name ~= "Unknown" then
      return name
    end
  end
  
  -- Fallback
  return "Unknown Continent"
end

--[[
  Get zone name for an NPC from its first location's mapID
  
  @param npc table - NPC data with locations array
  @return string - Zone name or "Unknown"
]]
local function getZoneName(npc)
  if not npc then return "Unknown" end
  
  local loc = Addon.location:getNpcLocation(npc)
  if loc and loc.mapID then
    return Addon.location:getZoneByMapID(loc.mapID)
  end
  
  return "Unknown"
end

--[[
  Initialize the circuit UI system
  Registers commands, creates tracker frame, sets up event handlers and timers.
  
  @return boolean - true if initialization successful, false otherwise
]]
function circuitUI:initialize()
  local constants = Addon.circuitConstants
  local persistence = Addon.circuitPersistence
  
  self:registerCommands()
  
  -- Create tracker using extracted component
  local tracker = Addon.circuitTracker:create()
  if not tracker then
    Addon.utils:debug("circuitUI:initialize - Failed to create tracker frame")
    return false
  end
  
  -- Battle event wiring is handled by circuitBattleHandler:initialize()
  
  Addon.events:subscribe("ZONE_CHANGED_NEW_AREA", function()
    -- Debounce zone changes to prevent rapid zone-hopping from triggering multiple updates
    -- Cancel any pending zone change processing
    if pendingZoneChangeTimer then
      pendingZoneChangeTimer:Cancel()
      pendingZoneChangeTimer = nil
    end
    
    -- Schedule zone change processing after debounce period
    pendingZoneChangeTimer = C_Timer.NewTimer(ZONE_CHANGE_DEBOUNCE, function()
      pendingZoneChangeTimer = nil
      self:onZoneChanged()
    end)
  end)
  
  -- Also check on login/reload for route recalculation
  Addon.events:subscribe("PLAYER_ENTERING_WORLD", function()
    self:onZoneChanged()
  end)
  
  -- Register for internal circuit events
  Addon.events:subscribe("CIRCUIT:STARTED", function(eventName, payload)
    Addon.circuitTracker:update()
  end, circuitUI)
  
  Addon.events:subscribe("CIRCUIT:CONTINENT_STARTED", function(eventName, payload)
    Addon.circuitTracker:update()
  end, circuitUI)
  
  Addon.events:subscribe("CIRCUIT:PROGRESS_UPDATED", function(eventName, payload)
    Addon.circuitTracker:update()
    -- Refresh popup if visible to show updated completion status
    if popupFrame and popupFrame:IsVisible() then
      self:refreshNpcList()
    end
  end, circuitUI)
  
  Addon.events:subscribe("CIRCUIT:COMPLETED", function(eventName, payload)
    self:onCircuitComplete()
  end, circuitUI)
  
  Addon.events:subscribe("CIRCUIT:CANCELLED", function(eventName, payload)
    Addon.circuitTracker:hide()
  end, circuitUI)
  
  Addon.events:subscribe("CIRCUIT:RESUMED", function(eventName, payload)
    Addon.circuitTracker:update()
  end, circuitUI)
  
  Addon.events:subscribe("CIRCUIT:SUSPENDED", function(eventName, payload)
    Addon.circuitTracker:update()
  end, circuitUI)
  
  Addon.events:subscribe("CIRCUIT:DAILY_RESET_DETECTED", function(eventName, payload)
    Addon.circuitTracker:showDailyResetPrompt()
  end, circuitUI)
  
  -- Restore circuit state after 3 seconds to ensure all modules are ready
  C_Timer.After(3, function()
    self:restoreCircuitState()
  end)
  
  -- Start daily reset checker using constant from data layer
  C_Timer.NewTicker(constants.TIMING.RESET_CHECK_INTERVAL, function()
    local state = persistence:getCircuitState()
    if state.active then
      Addon.circuitBattleHandler:checkDailyReset()
    end
  end)
  
  return true
end

--[[
  Restore circuit state after full addon initialization
  Called by 3-second timer to ensure all modules are ready.
  Restores tracker display and waypoint for active circuits.
]]
function circuitUI:restoreCircuitState()
  -- Prevent double restoration
  if restorationComplete then
    return
  end
  
  local persistence = Addon.circuitPersistence
  
  persistence:initialize()
  local state = persistence:getCircuitState()
  
  if not state.active then
    return
  end
  
  Addon.utils:debug("Restoring circuit state from timer")
  
  -- Check for location changes and adapt if needed
  if Addon.circuit and Addon.circuit.checkAndAdaptToLocation then
    Addon.circuit:checkAndAdaptToLocation()
  end
  
  -- Always update tracker display (adaptation may have occurred)
  Addon.circuitTracker:update()
  
  -- Restore waypoint if there's a current NPC and circuit is not suspended
  local currentNpcId = persistence:getCurrentNpc()
  if currentNpcId and not state.suspended then
    local npc = Addon.npcUtils:getNpcData(currentNpcId)
    if npc and npc.locations and npc.locations[1] then
      local loc = npc.locations[1]
      Addon.waypoint:set(loc.mapID, loc.x, loc.y, npc.name, getZoneName(npc))
      Addon.utils:debug(string.format("Restored waypoint: %s at %s (%.1f, %.1f)", 
        npc.name, getZoneName(npc), loc.x, loc.y))
    else
      Addon.utils:debug("Warning: Could not restore waypoint - NPC data not found for ID: " .. tostring(currentNpcId))
    end
  end
  
  -- Mark restoration as complete
  restorationComplete = true
end

--[[
  Register slash commands for circuit control
  Registers /pao circuit [resume|suspend] commands.
]]
function circuitUI:registerCommands()
  Addon.commands:register({
    command = "circuit",
    handler = function(parsed)
      local action = parsed.action or ""
      if action == "resume" then
        self:resumeCircuit()
      elseif action == "suspend" then
        self:suspendCircuit()
      elseif action == "cancel" then
        self:cancelCircuit()
      elseif action == "reroute" then
        if Addon.circuit then Addon.circuit:reroute() end
      else
        self:show()
      end
    end,
    help = "Open pet battle circuit planner",
    usage = "circuit [resume|suspend|cancel|reroute]",
    args = {
      {name = "action", required = false, description = "Action: resume, suspend, cancel, or reroute"}
    },
    category = "Pet Battles"
  })
end

--[[
  Handle circuit completion
  Called when circuit finishes successfully.
  Hides tracker. Completion message already shown by circuit:complete().
]]
function circuitUI:onCircuitComplete()
  Addon.circuitTracker:hide()
end

--[[
  Handle zone change events
  Monitors for continent changes to auto-resume suspended circuits and
  adapts routes when player location changes during active circuits.
]]
function circuitUI:onZoneChanged()
  local persistence = Addon.circuitPersistence
  
  -- Check for location adaptation if circuit is active (not suspended)
  if persistence:isCircuitActive() then
    if Addon.circuit and Addon.circuit.checkAndAdaptToLocation then
      Addon.circuit:checkAndAdaptToLocation()
    end
    return
  end
  
  -- Handle suspended circuit continent arrival
  if not persistence:isCircuitSuspended() then
    return
  end
  
  -- Check if player arrived at required continent
  local currentContinent = nil
  if Addon.location and Addon.location.getCurrentPlayerLocation then
    local playerLoc = Addon.location:getCurrentPlayerLocation()
    currentContinent = playerLoc.continent
  end
  
  local state = persistence:getCircuitState()
  
  if currentContinent == state.currentContinent then
    Addon.utils:notify("Arrived at circuit continent! Resuming circuit...")
    Addon.circuit:resume()
  end
end

--[[
  Show upcoming waypoints in chat
  Displays next N waypoints from current continent route.
]]
function circuitUI:showUpcomingWaypoints()
  local constants = Addon.circuitConstants
  local persistence = Addon.circuitPersistence
  local state = persistence:getCircuitState()
  
  if not state.active then
    Addon.utils:chat("No active circuit.")
    return
  end
  
  Addon.utils:notify("|cff33ff99=== Upcoming Waypoints ===|r")
  
  -- Show current NPC
  local currentNpcId = persistence:getCurrentNpc()
  if currentNpcId then
    local npc = Addon.npcUtils:getNpcData(currentNpcId)
    if npc then
      Addon.utils:chat(string.format("|cff00ff00→ Current:|r %s (%s)", npc.name, getZoneName(npc)))
    end
  end
  
  -- Show remaining NPCs on current continent
  local shown = 0
  local continentQueue = persistence:getContinentQueue()
  if #continentQueue > 0 then
    local continentData = continentQueue[1]
    for i, npcId in ipairs(continentData.npcIds) do
      local npc = Addon.npcUtils:getNpcData(npcId)
      if npc then
        Addon.utils:chat(string.format("%d. %s (%s)", i, npc.name, getZoneName(npc)))
        shown = shown + 1
        if shown >= constants.UI.MAX_WAYPOINTS_SHOWN then
          break
        end
      end
    end
  end
  
  -- Show total remaining
  local remaining = Addon.circuit:getRemainingBattleCount()
  if remaining > shown + 1 then
    Addon.utils:chat(string.format("|cffaaaaaa... and %d more|r", remaining - shown - 1))
  end
end

--[[
  Resume a suspended circuit
  Re-activates circuit if paused for continent travel.
]]
function circuitUI:resumeCircuit()
  local persistence = Addon.circuitPersistence
  
  if not persistence:isCircuitSuspended() then
    Addon.utils:chat("No suspended circuit to resume.")
    return
  end
  
  Addon.circuit:resume()
end

--[[
  Suspend active circuit
  Pauses circuit temporarily without canceling.
]]
function circuitUI:suspendCircuit()
  local persistence = Addon.circuitPersistence
  
  if not persistence:isCircuitActive() then
    Addon.utils:chat("No active circuit to suspend.")
    return
  end
  
  Addon.circuit:suspend()
end

--[[
  Cancel active or suspended circuit
  Terminates circuit and clears all state.
]]
function circuitUI:cancelCircuit()
  local persistence = Addon.circuitPersistence
  local state = persistence:getCircuitState()
  
  if not state.active then
    Addon.utils:chat("No active circuit to cancel.")
    return
  end
  
  Addon.circuit:cancel()
end

--[[
  Update start button state based on current NPC selections
  Enables button if NPCs selected, disables if empty.
]]
function circuitUI:updateStartButton()
  if not self.startButton then return end
  
  local persistence = Addon.circuitPersistence
  local hasActiveCircuit = persistence and (persistence:isCircuitActive() or persistence:isCircuitSuspended())
  
  -- Update button text based on circuit state (actionButton uses setText)
  if hasActiveCircuit then
    self.startButton:setText("Start New Circuit")
  else
    self.startButton:setText("Start Circuit")
  end
  
  if #selectedNpcs > 0 then
    self.startButton:setEnabled(true)
  else
    self.startButton:setEnabled(false)
  end
end

--[[
  Recalculate scroll child height based on visible frames
  Called after tree creation and after expand/collapse to achieve accordion effect.
]]
function circuitUI:recalculateScrollHeight()
  if not scrollChild or not checkboxTreeState then
    return
  end
  
  -- Get height from tree's own structure
  local visibleHeight = checkboxTreeState.getVisibleHeight()
  
  -- Set scroll child height
  scrollChild:SetHeight(visibleHeight)
  
  -- Force scroll frame to update (required for MoP)
  if scrollFrame then
    scrollFrame:UpdateScrollChildRect()
    -- Reset scroll position to top if we're shrinking
    if scrollFrame:GetVerticalScroll() > 0 then
      local maxScroll = scrollFrame:GetVerticalScrollRange()
      if scrollFrame:GetVerticalScroll() > maxScroll then
        scrollFrame:SetVerticalScroll(0)
      end
    end
    
    -- Dim scrollbar when scrolling isn't needed (always visible for stable layout)
    local scrollBar = _G["PAOCircuitScrollFrameScrollBar"]
    if scrollBar then
      local frameHeight = scrollFrame:GetHeight()
      if visibleHeight > frameHeight then
        scrollBar:SetAlpha(1.0)
      else
        scrollBar:SetAlpha(0.3)
      end
    end
  end
end

--[[
  Create circuit configuration popup
  Builds main popup window with three-level NPC tree and start button.
  Uses popupFactory for frame creation and checkboxTree for continent hierarchy.
]]
function circuitUI:createPopup()
  local constants = Addon.circuitConstants
  
  -- Use popupFactory (guaranteed by dependency system)
  popupFrame = Addon.popupFactory:create({
    title = "Pet Battle Circuit",
    icon = 643856,
    width = constants.UI.POPUP_WIDTH,
    height = constants.UI.POPUP_HEIGHT,
    closeable = true,
  })
  
  if not popupFrame then
    Addon.utils:debug("createPopup: Failed to create frame via popupFactory")
    return
  end
  
  -- Hook OnHide to save staging selections when popup closes
  popupFrame:HookScript("OnHide", function()
    stagingSelections = Addon.utils:shallowCopy(selectedNpcs)
    Addon.utils:debug(string.format("Saved %d selections to staging", #stagingSelections))
  end)
  
  -- Description text
  local descText = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  descText:SetPoint("TOP", popupFrame.contentAnchor, "TOP", 0, -8)
  descText:SetWidth(450)
  descText:SetJustifyH("CENTER")
  descText:SetText("Plan an optimized route through pet battle tamers.\nSelect battles below and PAO will create the shortest path.")
  descText:SetTextColor(0.8, 0.8, 0.8)
  
  -- Scrollable NPC tree (three levels: continent → category → NPC)
  scrollFrame = CreateFrame("ScrollFrame", "PAOCircuitScrollFrame", popupFrame, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", popupFrame, "TOPLEFT", 24, -(popupFrame.HEADER_HEIGHT + 50))
  scrollFrame:SetPoint("BOTTOMRIGHT", popupFrame, "BOTTOMRIGHT", -40, 110)
  
  scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetSize(380, 1)
  scrollFrame:SetScrollChild(scrollChild)
  
  -- Start button using PAO actionButton for consistent styling
  local actionButton = Addon.actionButton
  local startButton = actionButton:create(popupFrame, {
    text = "Start Circuit",
    size = "large",
    style = 1,
    onClick = function()
      self:onStartCircuit()
    end,
  })
  startButton:SetPoint("BOTTOMRIGHT", popupFrame, "BOTTOMRIGHT", -24, 24)
  
  -- Return location section - vertically centered to button
  local returnLabel = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  returnLabel:SetPoint("LEFT", popupFrame, "LEFT", 24, 0)
  returnLabel:SetPoint("TOP", startButton, "TOP", 0, 0)
  returnLabel:SetPoint("BOTTOM", startButton, "BOTTOM", 0, 0)
  returnLabel:SetText("Return to:")
  
  -- Create return location dropdown using unified dropdown:create()
  local questGiver = constants:getQuestGiverForFaction()
  
  returnDropdown = Addon.dropdown:create({
    parent = popupFrame,
    name = "PAOReturnLocationDropdown",
    width = 200,
    options = {
      { value = constants.RETURN_TYPES.NONE, text = "None" },
      { value = constants.RETURN_TYPES.CURRENT, text = "Current Location" },
      { value = constants.RETURN_TYPES.QUEST_GIVER, text = questGiver.name .. " (Fabled Quest Giver)", displayText = questGiver.name },
    },
    defaultValue = constants.RETURN_TYPES.NONE,
    onChange = function(value)
      selectedReturnType = value
    end,
  })
  returnDropdown:SetPoint("LEFT", returnLabel, "RIGHT", 5, 0)
  
  self.popupFrame = popupFrame
  self.startButton = startButton
  self.returnDropdown = returnDropdown
end

--[[
  Refresh the NPC checkbox tree
  Clears existing tree and rebuilds three-level hierarchy: continent → category → NPC.
  Uses checkboxTree component with tri-state continent checkboxes and portal icons.
]]
function circuitUI:refreshNpcList()
  if not scrollChild then 
    Addon.utils:debug("circuitUI:refreshNpcList - scrollChild not available")
    return 
  end
  
  -- Destroy previous tree if exists
  if checkboxTreeState then
    Addon.checkboxTree:destroy(checkboxTreeState)
  end
  
  -- Get available NPCs with portal tags
  local availableNpcs = Addon.circuitNpcFilter:getAvailableForCircuit()
  
  -- Get circuit completion status if circuit is active
  local persistence = Addon.circuitPersistence
  local circuitCompletedNpcs = {}
  if persistence:isCircuitActive() then
    local completedList = persistence:getCompletedNpcs()
    for _, npcId in ipairs(completedList) do
      circuitCompletedNpcs[npcId] = true
    end
  end
  
  -- Debug: Check if we have any NPCs
  local totalNpcs = Addon.circuitNpcFilter:countTotalNpcs(availableNpcs)
  
  Addon.utils:debug(string.format("circuitUI:refreshNpcList - Found %d total NPCs", totalNpcs))
  
  if totalNpcs == 0 then
    Addon.utils:debug("circuitUI:refreshNpcList - No NPCs found in database")
    
    -- Show message in scroll area
    local noDataText = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noDataText:SetPoint("TOP", scrollChild, "TOP", 0, -16)
    noDataText:SetText("No pet battle NPCs found in database.\nDefeat some tamers to populate the database.")
    noDataText:SetTextColor(1, 0.5, 0.5)
    
    -- Update button state
    self:updateStartButton()
    return
  end
  
  -- Get unique continents from NPC data (with faction-aware mapping)
  local continentIds = Addon.circuitNpcFilter:getUniqueContinents(availableNpcs)
  
  -- Build three-level continent hierarchy
  local continents = {}
  
  for _, continentId in ipairs(continentIds) do
    -- Filter NPCs for this continent
    local continentNpcs = Addon.circuitNpcFilter:filterByContinent(availableNpcs, continentId)
    local continentTotal = Addon.circuitNpcFilter:countTotalNpcs(continentNpcs)
    
    if continentTotal > 0 then
      local categories = {}
      
      -- Build categories for this continent
      local categoryOrder = Addon.circuitNpcFilter:getCategoryDisplayOrder()
      
      for _, catInfo in ipairs(categoryOrder) do
        local categoryNpcs = continentNpcs[catInfo.key]
        
        if categoryNpcs and #categoryNpcs > 0 then
          -- Create shallow copy to avoid mutating shared data
          local sortedNpcs = {}
          for i, npc in ipairs(categoryNpcs) do
            sortedNpcs[i] = npc
          end
          
          -- Sort NPCs alphabetically by name
          table.sort(sortedNpcs, function(a, b)
            local nameA = a.npc and a.npc.name or "Unknown"
            local nameB = b.npc and b.npc.name or "Unknown"
            return nameA < nameB
          end)
          
          local items = {}
          
          for _, npcInfo in ipairs(sortedNpcs) do
            -- Add blank spacer before Jeremy for visual separation
            if npcInfo.needsSeparator then
              table.insert(items, {
                id = "spacer_" .. npcInfo.id,
                label = "",  -- Blank line
                disabled = true,
                isSpacer = true
              })
            end
            
            table.insert(items, {
              id = npcInfo.id,
              label = npcInfo.npc and string.format("%s (%s)", npcInfo.npc.name, getZoneName(npcInfo.npc)) or "Unknown",
              disabled = npcInfo.disabled,
              disabledReason = npcInfo.disabledReason,
              completed = npcInfo.completed or circuitCompletedNpcs[npcInfo.id],  -- Quest completion OR circuit completion
              bagIcon = npcInfo.bagIcon,
              bagName = npcInfo.bagName,
              bagContents = npcInfo.bagContents,
              portalIcon = npcInfo.portalIcon
            })
          end
          
          table.insert(categories, {
            key = catInfo.key,
            name = catInfo.displayName,
            items = items
          })
        end
      end
      
      -- Add continent to hierarchy
      table.insert(continents, {
        id = continentId,
        name = getContinentDisplayName(continentId),
        categories = categories
      })
    end
  end
  
  -- Create three-level checkbox tree
  checkboxTreeState = Addon.checkboxTree:create({
    parent = scrollChild,
    startY = -10,
    continents = continents,
    initialSelection = selectedNpcs,
    onSelectionChanged = function(newSelectedIds)
      selectedNpcs = newSelectedIds
      self:updateStartButton()
    end,
    onExpandCollapse = function()
      -- Recalculate visible height for accordion effect
      self:recalculateScrollHeight()
    end,
    canSelect = function(item)
      -- Exclude completed items from bulk selection
      -- Users can still manually select them
      return not item.completed
    end
  })
  
  -- Set initial scroll height (only continent headers visible)
  self:recalculateScrollHeight()
  
  -- Update button state after refresh
  self:updateStartButton()
  
  Addon.utils:debug(string.format("Created tree with %d continents", #continents))
end

--[[
  Handle Start Circuit button click
  Validates selections and initiates circuit via logic layer.
]]
function circuitUI:onStartCircuit()
  if #selectedNpcs == 0 then
    Addon.utils:notify("Please select at least one NPC for the circuit.")
    return
  end
  
  -- Reset restoration flag for new circuit
  restorationComplete = false
  
  -- Clear staging selections (committed to circuit now)
  wipe(stagingSelections)
  
  Addon.circuit:start(selectedNpcs, selectedReturnType)
  
  -- Hide popup when circuit starts
  if popupFrame then
    popupFrame:Hide()
  end
  
  Addon.circuitTracker:update()
end

--[[
  Show the circuit configuration popup
  Creates popup if needed, restores previous selections, refreshes NPC list.
]]
function circuitUI:show()
  if not popupFrame then
    self:createPopup()
  end
  
  if not popupFrame then
    Addon.utils:error("Failed to create circuit popup window.")
    return
  end
  
  local persistence = Addon.circuitPersistence
  local state = persistence:getCircuitState()
  
  -- Restore selections: prioritize active circuit, fallback to staging
  if (state.active or state.suspended) and state.selectedNpcIds and #state.selectedNpcIds > 0 then
    -- Active circuit exists - restore from saved state
    selectedNpcs = Addon.utils:shallowCopy(state.selectedNpcIds)
  elseif #stagingSelections > 0 then
    -- No active circuit - restore from staging (current session)
    selectedNpcs = Addon.utils:shallowCopy(stagingSelections)
  end
  -- Note: If neither exists, selectedNpcs retains whatever was there (empty or from previous session)
  
  -- Restore return type: prioritize active circuit, fallback to user preference
  if state.lastReturnType and (state.active or state.suspended) then
    -- Active/suspended circuit - use saved return type
    selectedReturnType = state.lastReturnType
  else
    -- New circuit - use default from top-level settings
    selectedReturnType = Addon.options:Get("defaultReturnLocation") or "none"
  end
  
  -- Update dropdown display to match selected return type
  if self.returnDropdown then
    self.returnDropdown:SetValue(selectedReturnType, true)  -- silent=true, don't trigger onChange
  end
  
  -- Refresh NPC list and show popup
  self:refreshNpcList()
  popupFrame:Show()
  
  Addon.utils:debug("Circuit popup shown")
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("circuitUI", {
    "utils", "commands", "circuit", "waypoint", "location", "popupFactory", "events", 
    "npcUtils", "circuitPersistence", "circuitConstants", "circuitBattleHandler", 
    "circuitNpcFilter", "checkboxTree", "dropdown", "circuitTracker", "actionButton"
  }, function()
    if circuitUI.initialize then
      return circuitUI:initialize()
    end
    return true
  end)
end

return circuitUI