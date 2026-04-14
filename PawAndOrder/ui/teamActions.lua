--[[
  ui/teamActions.lua
  Team Actions UI Module
  
  Creates team management button header with:
  - 2 action buttons (Random, Find Battle)
  
  Heal functionality is now in the header bar.
  
  Dependencies: actionButton, events
  Exports: Addon.teamActions
]]

local ADDON_NAME, Addon = ...

local teamActions = {}

-- Module references (set in init)
local actionButton, events

-- Layout constants
local BUTTON_SPACING = 8
local HEADER_HEIGHT = 44  -- Match constants.LAYOUT.HEADER_HEIGHT
local BUTTON_WIDTH = 150  -- Fixed width for standard padding around icon/text
local RIGHT_PADDING = 12  -- Match ICON_LEFT for consistent side padding

--[[
  Update Find Battle Button
  Updates button text based on queue state.
  
  @param button frame - Find Battle button
  @param isQueued boolean - Current queue state
]]
local function updateFindBattleButton(button, isQueued)
  if isQueued then
    button:setText("Leave Queue")
  else
    button:setText("Find Battle")
  end
end

--[[
  Create Team Actions Header
  Creates button header with 2 action buttons.
  Positions itself relative to parent and handles dynamic sizing.
  
  @param parentFrame frame - Parent detail panel
  @param callbacks table - {
      onFindBattle = function(),
      onRandom = function(),
      getQueueState = function() return boolean
    }
  @return frame - Header frame
]]
function teamActions:create(parentFrame, callbacks)
  if not callbacks then
    print("|cff33ff99PAO|r: |cffff4444Error - teamActions:create requires callbacks parameter|r")
    return nil
  end
  
  local headerFrame = CreateFrame("Frame", nil, parentFrame)
  headerFrame:SetHeight(HEADER_HEIGHT)
  
  -- Position will be set by petDetails relative to team background
  headerFrame:SetPoint("LEFT", parentFrame, "LEFT", 0, 0)
  headerFrame:SetPoint("RIGHT", parentFrame, "RIGHT", 0, 0)
  
  -- Create buttons (right-justified, Find Battle rightmost)
  local buttons = {}
  
  -- Find Battle button (rightmost)
  -- Icon: 643856 = Find Battle icon
  buttons.findBattle = actionButton:create(headerFrame, {
    text = "Find Battle",
    icon = 643856,
    iconSide = "left",
    onClick = function(self)
      if callbacks.onFindBattle then
        callbacks.onFindBattle()
      end
      if callbacks.getQueueState then
        updateFindBattleButton(self, callbacks.getQueueState())
      end
    end,
    tooltip = "Queue for a PvP pet battle",
    size = "medium",
    style = 1,
    fixedWidth = BUTTON_WIDTH,
  })
  buttons.findBattle:SetPoint("RIGHT", headerFrame, "RIGHT", -RIGHT_PADDING, 0)
  
  -- Random button - left of Find Battle
  -- Icon: Custom random paw icon with "Team" text
  buttons.random = actionButton:create(headerFrame, {
    text = "Random Team",
    icon = "Interface\\AddOns\\PawAndOrder\\textures\\random-paw-team.png",
    iconSide = "left",
    onClick = function()
      if callbacks.onRandom then
        callbacks.onRandom()
      end
    end,
    tooltip = "Fill team slots with random level 25 rare pets",
    size = "medium",
    style = 1,
    fixedWidth = BUTTON_WIDTH,
  })
  buttons.random:SetPoint("RIGHT", buttons.findBattle, "LEFT", -BUTTON_SPACING, 0)
  
  -- Store button references and callbacks
  headerFrame.buttons = buttons
  headerFrame.callbacks = callbacks
  
  -- Register for queue status updates
  if events and callbacks.getQueueState then
    events:subscribe("PET_BATTLE_QUEUE_STATUS", function()
      updateFindBattleButton(buttons.findBattle, callbacks.getQueueState())
    end)
  end
  
  -- Update queue state when shown
  headerFrame:SetScript("OnShow", function(self)
    if callbacks.getQueueState then
      updateFindBattleButton(buttons.findBattle, callbacks.getQueueState())
    end
  end)
  
  -- Show the frame
  headerFrame:Show()
  
  return headerFrame
end

-- Register with addon
Addon.teamActions = teamActions

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("teamActions", {"actionButton", "events"}, function()
    actionButton = Addon.actionButton
    events = Addon.events
    return true
  end)
end

return teamActions