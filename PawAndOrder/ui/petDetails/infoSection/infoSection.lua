--[[
  ui/petDetails/infoSection.lua
  Pet Information Section
  
  Displays pet details including icon, name, stats, description, and abilities.
  Extracted from petDetails.lua to separate concerns.
  
  Responsibilities:
    - Pet icon and name display
    - Level, family, flags (cageable/unique/upgradeable)
    - Stats line (health/power/speed)
    - Description text
    - Abilities grid with tooltips
    - Source label with tooltip
    - Filter match highlighting
  
  Dependencies: constants, petUtils, uiUtils, abilityTooltips, abilityUtils
  Internal module: Addon.infoSection (not exposed as public API)
]]

local ADDON_NAME, Addon = ...

-- Module references (set in initialize)
local constants, petUtils, uiUtils

-- Panel reference (set in initialize)
local detailPanel = nil

-- Layout constants for info section
local LAYOUT = {
  -- Icon and name
  ICON_SIZE = 64,
  ICON_LEFT = 12,
  ICON_TOP = 12,
  NAME_LEFT_OFFSET = 15,
  NAME_TOP_OFFSET = -3,
  NAME_WIDTH = 450,

  -- Spacing between sections
  LINE_SPACING = 5,
  DESC_TOP_OFFSET = 10,
  ABILITIES_TOP_OFFSET = 70,
  ABILITIES_HEADER_GAP = 8,  -- Space between "Abilities:" and first row of abilities
  DESC_SIDE_PADDING = 16,

  -- Ability frames
  ABILITY_COLUMNS = 3,
  ABILITY_SPACING = 5,
  ABILITY_ROW_HEIGHT = 35,
  ABILITY_ICON_SIZE = 30,

  -- Companion model (replaces abilities for non-battle pets)
  COMPANION_MODEL_HEIGHT = 160,
  COMPANION_MODEL_WIDTH  = 240,

  -- Source label
  SOURCE_BOTTOM = 10,
  SOURCE_RIGHT = 10,

  -- Colors (RGB 0-1)
  BG_COLOR = {0.08, 0.08, 0.08, 0.9},
  STATS_COLOR = {0.8, 0.8, 0.8},
  SOURCE_COLOR = {0.7, 0.7, 0.7},
}

-- Semantic constants
local BULLET = " • "
local MAX_ABILITIES = 6

-- Inline stat icons for breed-aware stats line
-- PetBattle-StatIcons is a 2x2 atlas: Power(TL), Quality(TR), Speed(BL), Health(BR)
-- Format: |Tpath:h:w:ox:oy:dimx:dimy:left:right:top:bottom|t
local STAT_ICON_PATH = "Interface\\PetBattles\\PetBattle-StatIcons"
local STAT_INLINE = {
  H = "|T" .. STAT_ICON_PATH .. ":12:12:0:0:128:128:64:128:64:128|t ",
  P = "|T" .. STAT_ICON_PATH .. ":12:12:0:0:128:128:0:64:0:64|t ",
  S = "|T" .. STAT_ICON_PATH .. ":12:12:0:0:128:128:0:64:64:128|t ",
}

--[[
  Parse breed text to determine which stats are emphasized.
  Returns three booleans: showHealth, showPower, showSpeed.
  B (Balanced) maps to no icon. Duplicate letters (S/S) still produce one flag.
]]
local function getBreedStatFlags(breedText)
  if not breedText or breedText == "" then return false, false, false end
  local clean = breedText:match("^([^%d%%]+)") or breedText
  clean = clean:gsub("%s+", "")
  local first, second = clean:match("^(%a)/(%a)$")
  if not first then return false, false, false end
  local showH = (first == "H" or second == "H")
  local showP = (first == "P" or second == "P")
  local showS = (first == "S" or second == "S")
  return showH, showP, showS
end

-- Maps source label text to filter keywords (see filterSource.lua)
local SOURCE_FILTER_MAP = {
  ["pet battle"] = "wild",
  ["vendor"] = "vendor",
  ["drop"] = "drop",
  ["achievement"] = "achievement",
  ["quest"] = "quest",
  ["promotion"] = "promotion",
  ["world event"] = "event",
  ["profession"] = "profession",
  ["in-game shop"] = 'source:"in-game shop"',
  ["pet store"] = 'source:"in-game shop"',
}

local infoSection = {}

--[[
  Initialize info section module
  Stores references needed for display operations.
  
  @param panel frame - The detail panel frame
  @param deps table - Dependencies {constants, petUtils, uiUtils}
]]
function infoSection:initialize(panel, deps)
  detailPanel = panel
  constants = deps.constants
  petUtils = deps.petUtils
  uiUtils = deps.uiUtils
end

--[[
  Create Header Elements
  Creates the pet icon and name font string at the top of the panel
]]
local function createHeaderElements()
  -- Pet icon
  detailPanel.icon = detailPanel:CreateTexture(nil, "ARTWORK")
  detailPanel.icon:SetSize(LAYOUT.ICON_SIZE, LAYOUT.ICON_SIZE)
  detailPanel.icon:SetPoint("TOPLEFT", detailPanel, "TOPLEFT",
    LAYOUT.ICON_LEFT, -LAYOUT.ICON_TOP)

  -- Invisible frame over icon for tooltip capture and drag
  detailPanel.iconFrame = CreateFrame("Frame", nil, detailPanel)
  detailPanel.iconFrame:SetAllPoints(detailPanel.icon)
  detailPanel.iconFrame:EnableMouse(true)
  detailPanel.iconFrame:RegisterForDrag("LeftButton")
  -- Raise above dragFrame so icon can be dragged independently
  detailPanel.iconFrame:SetFrameLevel(detailPanel:GetFrameLevel() + 3)
  
  detailPanel.iconFrame:SetScript("OnEnter", function(self)
    if not detailPanel.currentPetData then
      return
    end
    
    local petData = detailPanel.currentPetData
    local petTooltips = Addon.petTooltips
    if not petTooltips then return end
    
    petTooltips:show(self, petData.petID, petData.speciesID, {anchor = "right"})
  end)
  detailPanel.iconFrame:SetScript("OnLeave", function()
    if Addon.petTooltips then
      Addon.petTooltips:hide()
    end
  end)
  
  -- Drag from icon
  detailPanel.iconFrame:SetScript("OnDragStart", function()
    local petData = detailPanel.currentPetData
    if not petData or not petData.petID or not petData.owned or petData.isCaged then return end
    
    C_PetJournal.PickupPet(petData.petID)
    
    local teamSection = Addon.teamSection
    if teamSection and teamSection.showDropTargets then
      teamSection:showDropTargets()
    end
  end)

  -- Pet name
  detailPanel.name = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  detailPanel.name:SetPoint("TOPLEFT", detailPanel.icon, "TOPRIGHT",
    LAYOUT.NAME_LEFT_OFFSET, LAYOUT.NAME_TOP_OFFSET)
  detailPanel.name:SetWidth(LAYOUT.NAME_WIDTH)
  detailPanel.name:SetJustifyH("LEFT")

  -- "Companion Pet" label shown after the name on the same line for non-battle species.
  -- Anchored to name:RIGHT so it follows the name text length dynamically.
  detailPanel.companionSubtitle = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  detailPanel.companionSubtitle:SetPoint("LEFT", detailPanel.name, "RIGHT", 8, 0)
  detailPanel.companionSubtitle:SetText("Companion Pet")
  detailPanel.companionSubtitle:SetTextColor(0.6, 0.6, 0.6)
  detailPanel.companionSubtitle:Hide()
  
  -- Large drag frame covering icon + name + info line for drag-to-team
  -- Positioned after name exists so we can anchor to it
  detailPanel.dragFrame = CreateFrame("Frame", nil, detailPanel)
  detailPanel.dragFrame:SetPoint("TOPLEFT", detailPanel.icon, "TOPLEFT", 0, 0)
  detailPanel.dragFrame:SetPoint("RIGHT", detailPanel.name, "RIGHT", 0, 0)
  -- Height covers icon + name line + level/family line (icon height + some extra)
  detailPanel.dragFrame:SetHeight(LAYOUT.ICON_SIZE + 20)
  detailPanel.dragFrame:EnableMouse(true)
  detailPanel.dragFrame:RegisterForDrag("LeftButton")
  -- Lower frame level so clickable elements (levelFrame, familyFrame) can be clicked
  detailPanel.dragFrame:SetFrameLevel(detailPanel:GetFrameLevel() + 1)
  
  -- Drag from info area to add pet to team
  detailPanel.dragFrame:SetScript("OnDragStart", function(self)
    local petData = detailPanel.currentPetData
    if not petData or not petData.petID or not petData.owned or petData.isCaged then return end
    
    -- Pick up the pet to cursor
    C_PetJournal.PickupPet(petData.petID)
    
    -- Show drop targets in team section
    local teamSection = Addon.teamSection
    if teamSection and teamSection.showDropTargets then
      teamSection:showDropTargets()
    end
  end)
  
  -- Clickable name frame overlaying pet name for filter-on-click
  -- Above dragFrame so it receives clicks, but still supports drag pass-through
  detailPanel.nameFrame = CreateFrame("Button", nil, detailPanel)
  detailPanel.nameFrame:SetHeight(20)
  detailPanel.nameFrame:SetFrameLevel(detailPanel:GetFrameLevel() + 4)
  detailPanel.nameFrame:RegisterForDrag("LeftButton")
  
  -- Hover background
  detailPanel.nameFrame.hoverBg = detailPanel.nameFrame:CreateTexture(nil, "BACKGROUND")
  detailPanel.nameFrame.hoverBg:SetAllPoints()
  detailPanel.nameFrame.hoverBg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
  detailPanel.nameFrame.hoverBg:Hide()
  
  -- Helper to resolve name filter token from current pet
  local function getNameFilterToken()
    local curPet = detailPanel.currentPetData
    if not curPet then return nil end
    local petName = curPet.customName or curPet.speciesName or curPet.name
    if not petName or petName == "" then return nil end
    if petName:find(" ") then return '"' .. petName .. '"' end
    return petName
  end
  
  detailPanel.nameFrame:SetScript("OnEnter", function(self)
    self.hoverBg:Show()
    local token = getNameFilterToken()
    if token and Addon.tooltip then
      local curPet = detailPanel.currentPetData or {}
      local displayName = curPet.customName or curPet.speciesName or curPet.name or ""
      Addon.tooltip:showWithHints(self, displayName, uiUtils:getFilterHints(token))
    end
  end)
  
  detailPanel.nameFrame:SetScript("OnLeave", function(self)
    self.hoverBg:Hide()
    if Addon.tooltip then Addon.tooltip:hide() end
  end)
  
  uiUtils:attachFilterClick(detailPanel.nameFrame, function()
    return getNameFilterToken()
  end)
  
  -- Pass drag through to team section
  detailPanel.nameFrame:SetScript("OnDragStart", function()
    local curPet = detailPanel.currentPetData
    if not curPet or not curPet.petID or not curPet.owned or curPet.isCaged then return end
    C_PetJournal.PickupPet(curPet.petID)
    local teamSection = Addon.teamSection
    if teamSection and teamSection.showDropTargets then
      teamSection:showDropTargets()
    end
  end)
end

--[[
  Create Info Elements
  Creates level text, family, flags, stats line, and description
]]
local function createInfoElements()
  -- Level text
  detailPanel.levelText = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  -- Standard anchor; for companions this is overridden in update() to sit below companionSubtitle
  detailPanel.levelText:SetPoint("TOPLEFT", detailPanel.name, "BOTTOMLEFT", 0, -LAYOUT.LINE_SPACING)
  detailPanel.levelText:SetJustifyH("LEFT")
  detailPanel.levelText:SetTextColor(1, 1, 1)

  -- Clickable level frame (created on first use, same pattern as familyFrame)
  detailPanel.levelFrame = nil

  -- Bullet separator before family
  detailPanel.familyBullet = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  -- Position set dynamically in update()
  detailPanel.familyBullet:SetJustifyH("LEFT")
  detailPanel.familyBullet:SetText(" • ")
  detailPanel.familyBullet:SetTextColor(1, 1, 1)

  -- Family frame (created on first use)
  detailPanel.familyFrame = nil

  -- Bullets for flags
  detailPanel.cageableBullet = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  detailPanel.cageableBullet:SetText(" • ")
  detailPanel.cageableBullet:SetTextColor(1, 1, 1)
  
  detailPanel.uniqueBullet = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  detailPanel.uniqueBullet:SetText(" • ")
  detailPanel.uniqueBullet:SetTextColor(1, 1, 1)
  
  detailPanel.upgradeableBullet = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  detailPanel.upgradeableBullet:SetText(" • ")
  detailPanel.upgradeableBullet:SetTextColor(1, 1, 1)
  
  -- Clickable flag frames (created on first use)
  detailPanel.cageableFrame = nil
  detailPanel.uniqueFrame = nil
  detailPanel.upgradeableFrame = nil

  -- Stats line
  detailPanel.stats = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  detailPanel.stats:SetPoint("TOPLEFT", detailPanel.levelText, "BOTTOMLEFT", 0, -LAYOUT.LINE_SPACING)
  detailPanel.stats:SetTextColor(unpack(LAYOUT.STATS_COLOR))

  -- Description text
  detailPanel.desc = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  detailPanel.desc:SetPoint("TOPLEFT", detailPanel.icon, "BOTTOMLEFT", 0, -LAYOUT.DESC_TOP_OFFSET)
  detailPanel.desc:SetWidth(455)
  detailPanel.desc:SetJustifyH("LEFT")
  detailPanel.desc:SetJustifyV("TOP")
  
  -- Make description italic
  local descFont, descSize, descFlags = detailPanel.desc:GetFont()
  detailPanel.desc:SetFont(descFont, descSize, "ITALIC")
  detailPanel.desc:SetSpacing(2)
end

--[[
  Create Abilities Section
  Creates the "Abilities:" header
]]
local function createAbilitiesSection()
  detailPanel.abilitiesHeader = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  detailPanel.abilitiesHeader:SetPoint("TOPLEFT", detailPanel.icon, "BOTTOMLEFT",
    0, -LAYOUT.ABILITIES_TOP_OFFSET)
  detailPanel.abilitiesHeader:SetText("Abilities:")

  -- Model frame for companion (non-battle) pets — shown instead of abilities.
  -- Anchors and height are set dynamically in update() against detailBg,
  -- so no initial positioning here.
  detailPanel.companionModel = CreateFrame("PlayerModel", nil, detailPanel)
  detailPanel.companionModel:SetCamDistanceScale(1)
  detailPanel.companionModel:Hide()
end

--[[
  Create Source Label
  Creates the source label with border highlighting for inline display in info line
]]
local function createSourceLabel()
  detailPanel.sourceFrame = CreateFrame("Button", nil, detailPanel)
  -- Position set dynamically in update() as part of info line chain
  detailPanel.sourceFrame:SetSize(120, 16)
  -- Raise frame level above dragFrame so tooltip works
  detailPanel.sourceFrame:SetFrameLevel(detailPanel:GetFrameLevel() + 5)
  
  -- Hover background
  detailPanel.sourceFrame.hoverBg = detailPanel.sourceFrame:CreateTexture(nil, "BACKGROUND")
  detailPanel.sourceFrame.hoverBg:SetAllPoints()
  detailPanel.sourceFrame.hoverBg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
  detailPanel.sourceFrame.hoverBg:Hide()
  
  detailPanel.sourceLabel = detailPanel.sourceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  detailPanel.sourceLabel:SetPoint("LEFT", detailPanel.sourceFrame, "LEFT", uiUtils:getSpaceWidth(), 0)
  detailPanel.sourceLabel:SetJustifyH("LEFT")
  detailPanel.sourceLabel:SetTextColor(unpack(LAYOUT.SOURCE_COLOR))
  
  -- Highlight texture for filter match (anchored to text with padding for texture border)
  detailPanel.sourceHighlight = detailPanel:CreateTexture(nil, "BACKGROUND", nil, 7)
  detailPanel.sourceHighlight:SetTexture(375515)  -- ui-character-tab-highlight-yellow
  detailPanel.sourceHighlight:SetBlendMode("ADD")
  detailPanel.sourceHighlight:SetAlpha(0.6)
  detailPanel.sourceHighlight:SetPoint("TOPLEFT", detailPanel.sourceLabel, "TOPLEFT", -40, 32)
  detailPanel.sourceHighlight:SetPoint("BOTTOMRIGHT", detailPanel.sourceLabel, "BOTTOMRIGHT", 40, -30)
  detailPanel.sourceHighlight:Hide()
  
  -- Bullet separator (created here, positioned dynamically)
  detailPanel.sourceBullet = detailPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  detailPanel.sourceBullet:SetText(BULLET)
  detailPanel.sourceBullet:SetTextColor(1, 1, 1)
end

--[[
  Create Ability Frame
  Creates a single ability button with icon, name, and tooltip support.
  
  @param parent frame - Parent frame for the ability button
  @return frame - Configured ability button frame
]]
local function createAbilityFrame(parent, highlightParent)
  local frame = CreateFrame("Button", nil, parent)
  frame:SetSize(220, 24)

  -- Background highlight
  local bg = frame:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
  frame.bg = bg

  -- Ability icon
  frame.icon = frame:CreateTexture(nil, "ARTWORK")
  frame.icon:SetSize(LAYOUT.ABILITY_ICON_SIZE, LAYOUT.ABILITY_ICON_SIZE)
  frame.icon:SetPoint("LEFT", frame, "LEFT", 0, 0)

  -- Level requirement text (centered on icon with strong shadow)
  frame.levelReq = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.levelReq:SetPoint("CENTER", frame.icon, "CENTER", 0, 0)
  frame.levelReq:SetTextColor(1, 1, 0)
  frame.levelReq:SetShadowOffset(2, -2)
  frame.levelReq:SetShadowColor(0, 0, 0, 1)
  frame.levelReq:Hide()

  -- Ability name text
  frame.nameText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  frame.nameText:SetPoint("LEFT", frame.icon, "RIGHT", 4, 0)
  frame.nameText:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
  frame.nameText:SetJustifyH("LEFT")

  -- Tooltip on hover
  frame:SetScript("OnEnter", function(self)
    self.bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
    if not self.abilityID then return end

    if Addon.abilityTooltips:show(self, {anchor = "right"}, self.abilityID, self.petID, self.speciesID, self.petLevel) then
      local name = C_PetJournal.GetPetAbilityInfo(self.abilityID)
      if name then
        local token = name:find(" ") and ('"' .. name .. '"') or name
        Addon.tooltip:hints(uiUtils:getFilterHints(token), {separator = true})
      end
      Addon.tooltip:done()
    end
  end)

  frame:SetScript("OnLeave", function(self)
    self.bg:SetColorTexture(0.1, 0.1, 0.1, 0.3)
    Addon.tooltip:hide()
  end)
  
  -- Click to toggle filter by ability name
  uiUtils:attachFilterClick(frame, function(self)
    if not self.abilityID then return nil end
    local name = C_PetJournal.GetPetAbilityInfo(self.abilityID)
    if not name then return nil end
    return name:find(" ") and ('"' .. name .. '"') or name
  end)

  -- Highlight texture for filter matches (sized dynamically since nameText stretches full width)
  frame.highlight = (highlightParent or parent):CreateTexture(nil, "BACKGROUND", nil, 7)
  frame.highlight:SetTexture(375515)  -- ui-character-tab-highlight-yellow
  frame.highlight:SetBlendMode("ADD")
  frame.highlight:SetAlpha(0.6)
  frame.highlight:Hide()
  
  return frame
end

--[[
  Show ability highlight
  Positions and sizes based on actual text width, not the stretched nameText region
]]
local function showAbilityHighlight(frame)
  if not frame or not frame.highlight or not frame.nameText then return end
  
  local textWidth = frame.nameText:GetStringWidth()
  local textHeight = frame.nameText:GetStringHeight()
  local hPadding = 40
  local vPaddingTop = 32
  local vPaddingBottom = 30
  
  frame.highlight:ClearAllPoints()
  frame.highlight:SetWidth(textWidth + hPadding * 2)
  frame.highlight:SetHeight(textHeight + vPaddingTop + vPaddingBottom)
  frame.highlight:SetPoint("TOPLEFT", frame.nameText, "TOPLEFT", -hPadding, vPaddingTop)
  frame.highlight:Show()
end

--[[
  Format Level Text
  @param petData table - Pet data
  @return string, number - Level text and alpha value
]]
local function formatLevelText(petData)
  local opts = Addon.options and Addon.options.GetAll and Addon.options:GetAll()
  local fadeLevelOpacity = opts and opts.fadeLevelOpacity

  if petData.owned then
    local levelText = "Level " .. tostring(petData.level)
    local alpha = 1.0

    if fadeLevelOpacity and petData.level < 25 then
      alpha = 0.4 + (petData.level - 1) * (0.6 / 24)
    end

    return levelText, alpha
  else
    return "Unowned", 1.0
  end
end

--[[
  Build Family Text
  @param petData table - Pet data
  @return string - Colored family text
]]
local function buildFamilyText(petData)
  local familyName = petData.familyName or "Unknown"
  local typeColors = constants.PET_TYPE_COLORS
  local color = typeColors and typeColors[petData.petType] or {r = 1, g = 1, b = 1}

  local colorCode = string.format("|cff%02x%02x%02x",
    color.r * 255, color.g * 255, color.b * 255)

  return colorCode .. familyName .. "|r"
end

--[[
  Update Ability Display
  Populates the ability grid.
  
  @param petData table - Pet data
  @param matchContext table|nil - Filter match context
]]
local function updateAbilityDisplay(petData, matchContext)
  for _, frame in ipairs(detailPanel.abilityFrames) do
    frame:Hide()
    if frame.highlight then
      frame.highlight:Hide()
    end
  end

  if not petData.speciesID then return end

  local abilities = C_PetJournal.GetPetAbilityList(petData.speciesID)
  if not abilities then return end

  -- Use stored width from parent (top-down sizing)
  local panelWidth = detailPanel.panelWidth or 500
  local abilityWidth = math.floor((panelWidth - 40) / LAYOUT.ABILITY_COLUMNS)

  for i, abilityID in ipairs(abilities) do
    if i > MAX_ABILITIES then break end

    local frame = detailPanel.abilityFrames[i]
    if not frame then
      frame = createAbilityFrame(detailPanel, detailPanel)
      detailPanel.abilityFrames[i] = frame
    end

    local row = math.ceil(i / LAYOUT.ABILITY_COLUMNS)
    local col = ((i - 1) % LAYOUT.ABILITY_COLUMNS) + 1
    local xOffset = (col - 1) * (abilityWidth + LAYOUT.ABILITY_SPACING)
    local yOffset = -(row - 1) * LAYOUT.ABILITY_ROW_HEIGHT - LAYOUT.ABILITIES_HEADER_GAP

    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", detailPanel.abilitiesHeader, "BOTTOMLEFT", xOffset, yOffset)
    frame:SetWidth(abilityWidth)

    local name, icon, petType = C_PetJournal.GetPetAbilityInfo(abilityID)
    frame.abilityID = abilityID
    -- Caged pets have synthetic petIDs that journal APIs reject; pass nil so
    -- tooltipParser:createAbilityInfo falls back to default stats (same as unowned view)
    frame.petID = petData.isCaged and nil or petData.petID
    frame.petLevel = petData.level
    frame.speciesID = petData.speciesID
    frame.abilityName = name
    frame.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    frame.nameText:SetText(name or "Unknown")
    
    -- Size frame to content
    local textWidth = frame.nameText:GetStringWidth()
    local charWidth = frame.nameText:GetStringWidth() / max(1, string.len(name or "Unknown"))
    local iconWidth = LAYOUT.ABILITY_ICON_SIZE
    local spacing = 4
    local padding = charWidth * 2
    local frameWidth = iconWidth + spacing + textWidth + padding
    frame:SetWidth(frameWidth)

    -- Level requirement display
    local levelReq = Addon.abilityUtils:getLevelRequirement(i)
    if levelReq then
      if petData.owned then
        if petData.level and petData.level < levelReq then
          frame.levelReq:SetText(levelReq)
          frame.levelReq:Show()
          frame.icon:SetDesaturated(true)
        else
          frame.levelReq:Hide()
          frame.icon:SetDesaturated(false)
        end
      else
        frame.levelReq:SetText(levelReq)
        frame.levelReq:Show()
        frame.icon:SetDesaturated(levelReq > 1)
      end
    else
      frame.levelReq:Hide()
      frame.icon:SetDesaturated(false)
    end

    -- Filter match highlighting
    if matchContext and matchContext.abilities and matchContext.abilities[abilityID] then
      showAbilityHighlight(frame)
    else
      frame.highlight:Hide()
    end

    frame:Show()
  end
end

--[[
  Create all UI elements
  Called by petDetails after panel is created.
]]
function infoSection:create()
  if not detailPanel then return end
  
  createHeaderElements()
  createInfoElements()
  createAbilitiesSection()
  createSourceLabel()
  
  detailPanel.abilityFrames = {}
end

--[[
  Update pet display
  Main entry point for updating the info section with pet data.
  
  @param petData table|nil - Pet data, or nil to clear
  @param matchContext table|nil - Filter match context for highlighting
]]
function infoSection:update(petData, matchContext)
  if not detailPanel then return end
  
  -- Store current data
  detailPanel.currentPetData = petData
  detailPanel.currentMatchContext = matchContext

  if not petData then
    -- Clear display
    detailPanel.icon:Hide()
    detailPanel.name:SetText("")
    detailPanel.nameFrame:Hide()
    if detailPanel.upgradeArrow then
      detailPanel.upgradeArrow:Hide()
    end
    detailPanel.levelText:Hide()
    if detailPanel.levelFrame then
      detailPanel.levelFrame:Hide()
    end
    if detailPanel.familyBullet then
      detailPanel.familyBullet:Hide()
    end
    if detailPanel.familyFrame then
      detailPanel.familyFrame:Hide()
    end
    detailPanel.cageableBullet:Hide()
    if detailPanel.cageableFrame then
      detailPanel.cageableFrame:Hide()
    end
    detailPanel.uniqueBullet:Hide()
    if detailPanel.uniqueFrame then
      detailPanel.uniqueFrame:Hide()
    end
    detailPanel.upgradeableBullet:Hide()
    if detailPanel.upgradeableFrame then
      detailPanel.upgradeableFrame:Hide()
    end
    detailPanel.stats:SetText("")
    detailPanel.stats:Hide()
    detailPanel.desc:SetText("")
    detailPanel.sourceLabel:Hide()
    detailPanel.sourceHighlight:Hide()

    for _, frame in ipairs(detailPanel.abilityFrames) do
      frame:Hide()
      if frame.highlight then
        frame.highlight:Hide()
      end
    end

    detailPanel.abilitiesHeader:Hide()
    if detailPanel.companionModel then detailPanel.companionModel:Hide() end
    if detailPanel.companionSubtitle then detailPanel.companionSubtitle:Hide() end
    return
  end

  -- Update icon
  detailPanel.icon:SetTexture(petData.icon)
  detailPanel.icon:Show()

  -- Update name with breed and rarity coloring
  local displayName = petData.name or "Unknown"
  
  if petData.owned and petData.breedText and petData.breedText ~= "" then
    local cleanBreed = petData.breedText:match("^([^%d%%]+)") or petData.breedText
    cleanBreed = cleanBreed:gsub("%s+$", "")
    cleanBreed = cleanBreed:gsub(" ", " ")
    
    local rarity = petData.rarity or 2
    local color = petUtils:getRarityColor(rarity)
    local dimR = math.floor(color.r * 0.75 * 255)
    local dimG = math.floor(color.g * 0.75 * 255)
    local dimB = math.floor(color.b * 0.75 * 255)
    local breedColor = string.format("|cff%02x%02x%02x", dimR, dimG, dimB)
    displayName = displayName .. " " .. breedColor .. "(" .. cleanBreed .. ")|r"
  end
  
  -- Create upgrade arrow if needed
  if not detailPanel.upgradeArrow then
    detailPanel.upgradeArrow = detailPanel:CreateTexture(nil, "OVERLAY")
    detailPanel.upgradeArrow:SetSize(16, 16)
  end
  
  -- Show upgrade arrow if pet can be upgraded (below Rare)
  if petData.owned and petData.rarity and petData.rarity < 4 then
    local iconPath = "Interface\\AddOns\\PawAndOrder\\blue_arrow.png"
    if petData.rarity < 3 then
      -- Poor or Common → green arrow (upgrading to Uncommon)
      iconPath = "Interface\\AddOns\\PawAndOrder\\green_arrow.png"
    end
    detailPanel.upgradeArrow:SetTexture(iconPath)
    local nameWidth = detailPanel.name:GetStringWidth()
    detailPanel.upgradeArrow:SetPoint("LEFT", detailPanel.name, "LEFT", nameWidth + 5, 0)
    detailPanel.upgradeArrow:Show()
  else
    if detailPanel.upgradeArrow then
      detailPanel.upgradeArrow:Hide()
    end
  end
  
  detailPanel.name:SetText(displayName)
  
  -- Color name by rarity; unowned species use lavender (white reads as Common rarity)
  if petData.owned and petData.rarity then
    local color = petUtils:getRarityColor(petData.rarity)
    detailPanel.name:SetTextColor(color.r, color.g, color.b)
  else
    detailPanel.name:SetTextColor(0.88, 0.82, 1.0)
  end

  -- Position nameFrame overlay to match name text
  local nameWidth = detailPanel.name:GetStringWidth()
  detailPanel.nameFrame:SetWidth(nameWidth + 8)
  detailPanel.nameFrame:ClearAllPoints()
  detailPanel.nameFrame:SetPoint("LEFT", detailPanel.name, "LEFT", -4, 0)
  detailPanel.nameFrame:Show()

  -- Update level with optional fade and clickable overlay
  local levelText, levelAlpha = formatLevelText(petData)
  detailPanel.levelText:SetText(levelText)
  detailPanel.levelText:SetTextColor(1, 1, 1)
  detailPanel.levelText:SetAlpha(levelAlpha)
  detailPanel.levelText:Show()

  -- Create or update clickable level frame (overlays levelText)
  if petData.owned and petData.level then
    if not detailPanel.levelFrame then
      detailPanel.levelFrame = CreateFrame("Button", nil, detailPanel)
      detailPanel.levelFrame:SetHeight(16)
      -- Raise above dragFrame so clicks work
      detailPanel.levelFrame:SetFrameLevel(detailPanel:GetFrameLevel() + 5)
      
      -- Hover background (same pattern as createClickableFilterTerm)
      detailPanel.levelFrame.hoverBg = detailPanel.levelFrame:CreateTexture(nil, "BACKGROUND")
      detailPanel.levelFrame.hoverBg:SetAllPoints()
      detailPanel.levelFrame.hoverBg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
      detailPanel.levelFrame.hoverBg:Hide()
      
      detailPanel.levelFrame:SetScript("OnEnter", function(self)
        self.hoverBg:Show()
        
        local curPet = detailPanel.currentPetData
        if not curPet or not curPet.level then return end
        local lvl = curPet.level
        
        local tip = Addon.tooltip
        if tip then
          tip:show(self)
          tip:minWidth(200)
          tip:header("Level " .. lvl, {color = {1, 0.82, 0}})
          
          -- Fetch XP fresh from API (cached data may be stale)
          if lvl < 25 and curPet.petID and not curPet.isCaged then
            local _, _, _, xp, maxXp = C_PetJournal.GetPetInfoByPetID(curPet.petID)
            xp = xp or 0
            maxXp = maxXp or 1
            tip:progressBar(xp, maxXp, {
              label = tostring(lvl + 1),
            })
          elseif lvl >= 25 then
            tip:text("Max Level", {color = {0.5, 0.9, 0.5}})
          end
          
          -- Queue position (if leveling tab is enabled and pet is sub-25)
          local tabs = Addon.tabs
          local levelingLogic = Addon.levelingLogic
          if lvl < 25 and tabs and tabs.isEnabled and tabs:isEnabled("leveling") and levelingLogic then
            local queuePos = nil
            local totalCount = levelingLogic.getTotalCount and levelingLogic:getTotalCount() or 0
            
            -- Check if pinned first
            if levelingLogic.isPinned and levelingLogic:isPinned(curPet.petID) then
              queuePos = 1
            else
              local preview = levelingLogic.getQueuePreview and levelingLogic:getQueuePreview(totalCount)
              if preview then
                for pos, entry in ipairs(preview) do
                  if entry.pet and entry.pet.petID == curPet.petID then
                    queuePos = pos
                    break
                  end
                end
              end
            end
            
            tip:space(10)
            if queuePos then
              tip:text("Queue Position: " .. queuePos .. " / " .. totalCount, {color = {0.7, 0.9, 1}})
            else
              tip:text("Not in leveling queue", {color = {0.5, 0.5, 0.5}})
            end
          end
          
          -- Click hints
          tip:hints(uiUtils:getFilterHints("level:" .. lvl), {separator = true})
          tip:done()
        end
      end)
      
      detailPanel.levelFrame:SetScript("OnLeave", function(self)
        self.hoverBg:Hide()
        if Addon.tooltip then Addon.tooltip:hide() end
      end)
    end
    
    -- Click handler reads level dynamically from currentPetData
    uiUtils:attachFilterClick(detailPanel.levelFrame, function()
      local curPet = detailPanel.currentPetData
      if not curPet or not curPet.level then return nil end
      return "level:" .. curPet.level
    end)
    
    -- Size and position to match levelText
    local textWidth = detailPanel.levelText:GetStringWidth()
    detailPanel.levelFrame:SetWidth(textWidth + 8)  -- 4px padding each side
    detailPanel.levelFrame:ClearAllPoints()
    detailPanel.levelFrame:SetPoint("LEFT", detailPanel.levelText, "LEFT", -4, 0)
    detailPanel.levelFrame:SetAlpha(levelAlpha)
    detailPanel.levelFrame:Show()
  else
    -- Not owned - hide level frame
    if detailPanel.levelFrame then
      detailPanel.levelFrame:Hide()
    end
  end

  -- Update family with clickable frame
  local familyText = buildFamilyText(petData)
  local familyName = petData.familyName or "Unknown"
  local filterToken = "family:" .. familyName

  -- Show "Companion Pet" inline with name for non-battle species
  local canBattle = petData.canBattle
  if canBattle == false then
    -- Anchor after actual text content, bottom-aligned to the name baseline
    detailPanel.companionSubtitle:ClearAllPoints()
    detailPanel.companionSubtitle:SetPoint("BOTTOMLEFT", detailPanel.name, "BOTTOMLEFT",
      detailPanel.name:GetStringWidth() + 8, 0)
    detailPanel.companionSubtitle:Show()
  else
    detailPanel.companionSubtitle:Hide()
  end

  -- levelText always anchors off name:BOTTOMLEFT — subtitle is on the name line, not below it
  detailPanel.familyBullet:ClearAllPoints()
  detailPanel.familyBullet:SetPoint("LEFT", detailPanel.levelText, "RIGHT", 0, 0)
  
  if not detailPanel.familyFrame or detailPanel.lastFamilyName ~= familyName then
    if detailPanel.familyFrame then
      detailPanel.familyFrame:Hide()
    end
    detailPanel.familyFrame = uiUtils:createClickableFilterTerm(detailPanel, familyText, filterToken)
    detailPanel.familyFrame:SetFrameLevel(detailPanel:GetFrameLevel() + 5)
    detailPanel.lastFamilyName = familyName
    detailPanel.familyFrame.hasFamilyTooltip = false  -- Reset tooltip flag for new frame
  end
  
  detailPanel.familyFrame:ClearAllPoints()
  detailPanel.familyFrame:SetPoint("LEFT", detailPanel.familyBullet, "RIGHT", 0, 0)
  detailPanel.familyFrame:Show()
  detailPanel.familyBullet:Show()
  
  -- Add family matchup tooltip (once per frame)
  if not detailPanel.familyFrame.hasFamilyTooltip then
    detailPanel.familyFrame.hasFamilyTooltip = true
    
    -- Store original scripts to chain
    local originalOnEnter = detailPanel.familyFrame:GetScript("OnEnter")
    local originalOnLeave = detailPanel.familyFrame:GetScript("OnLeave")
    
    detailPanel.familyFrame:SetScript("OnEnter", function(self)
      if originalOnEnter then originalOnEnter(self) end
      if self.petType and uiUtils then
        uiUtils:showFamilyMatchupTooltip(self.petType, self)
      end
    end)
    
    detailPanel.familyFrame:SetScript("OnLeave", function(self)
      if originalOnLeave then originalOnLeave(self) end
      if Addon.tooltip then Addon.tooltip:hide() end
    end)
  end
  
  -- Store petType on frame for tooltip
  detailPanel.familyFrame.petType = petData.petType

  -- Update flags with dynamic positioning
  local lastElement = detailPanel.familyFrame

  -- Cageable flag
  if petData.tradable then
    if not detailPanel.cageableFrame then
      detailPanel.cageableFrame = uiUtils:createClickableFilterTerm(detailPanel, "Cageable")
      detailPanel.cageableFrame:SetFrameLevel(detailPanel:GetFrameLevel() + 5)
      
      -- Custom tooltip with flavor text and cage icon
      detailPanel.cageableFrame:SetScript("OnEnter", function(self)
        self.hoverBg:Show()
        local tip = Addon.tooltip
        if tip then
          tip:show(self)
          tip:reserveIcon(32, -12)
          tip:header("Cageable", {color = {1, 0.82, 0}})
          tip:text("This pet can be placed in a cage and traded with other players or bought and sold on the Auction House.", {
            color = {1, 1, 1}, wrap = true, font = "small",
          })
          tip:hints(uiUtils:getFilterHints("cageable"), {separator = true})
          tip:done()
          
          local icon = tip:texture("cageableIcon")
          local tipFrame = tip:frame()
          icon:ClearAllPoints()
          icon:SetSize(32, 32)
          icon:SetTexture(646379)  -- INV_Pet_PetTrap01
          icon:SetTexCoord(0, 1, 0, 1)
          icon:SetAlpha(0.8)
          icon:SetPoint("TOPRIGHT", tipFrame, "TOPRIGHT", -12, -35)
          icon:Show()
        end
      end)
      
      detailPanel.cageableFrame:SetScript("OnLeave", function(self)
        self.hoverBg:Hide()
        if Addon.tooltip then Addon.tooltip:hide() end
      end)
    end
    
    detailPanel.cageableBullet:ClearAllPoints()
    detailPanel.cageableBullet:SetPoint("LEFT", lastElement, "RIGHT", 0, 0)
    detailPanel.cageableBullet:Show()
    
    local bulletWidth = detailPanel.cageableBullet:GetStringWidth()
    detailPanel.cageableFrame:ClearAllPoints()
    detailPanel.cageableFrame:SetPoint("LEFT", lastElement, "RIGHT", bulletWidth, 0)
    detailPanel.cageableFrame:Show()
    lastElement = detailPanel.cageableFrame
  else
    detailPanel.cageableBullet:Hide()
    if detailPanel.cageableFrame then
      detailPanel.cageableFrame:Hide()
    end
  end

  -- Unique flag
  if petData.unique then
    if not detailPanel.uniqueFrame then
      detailPanel.uniqueFrame = uiUtils:createClickableFilterTerm(detailPanel, "Unique")
      detailPanel.uniqueFrame:SetFrameLevel(detailPanel:GetFrameLevel() + 5)
      
      -- Custom tooltip with flavor text and diamond icon
      detailPanel.uniqueFrame:SetScript("OnEnter", function(self)
        self.hoverBg:Show()
        local tip = Addon.tooltip
        if tip then
          tip:show(self)
          tip:reserveIcon(32, -12)
          tip:header("Unique", {color = {1, 0.82, 0}})
          tip:text("Only one of this species can be learned at a time.", {
            color = {1, 1, 1}, wrap = true, font = "small",
          })
          tip:hints(uiUtils:getFilterHints("unique"), {separator = true})
          tip:done()
          
          local icon = tip:texture("uniqueIcon")
          local tipFrame = tip:frame()
          icon:ClearAllPoints()
          icon:SetSize(32, 32)
          icon:SetTexture("Interface\\AddOns\\PawAndOrder\\textures\\grey-diamond.png")
          icon:SetTexCoord(0, 1, 0, 1)
          icon:SetAlpha(0.8)
          icon:SetPoint("TOPRIGHT", tipFrame, "TOPRIGHT", -12, -35)
          icon:Show()
        end
      end)
      
      detailPanel.uniqueFrame:SetScript("OnLeave", function(self)
        self.hoverBg:Hide()
        if Addon.tooltip then Addon.tooltip:hide() end
      end)
    end
    
    detailPanel.uniqueBullet:ClearAllPoints()
    detailPanel.uniqueBullet:SetPoint("LEFT", lastElement, "RIGHT", 0, 0)
    detailPanel.uniqueBullet:Show()
    
    local bulletWidth = detailPanel.uniqueBullet:GetStringWidth()
    detailPanel.uniqueFrame:ClearAllPoints()
    detailPanel.uniqueFrame:SetPoint("LEFT", lastElement, "RIGHT", bulletWidth, 0)
    detailPanel.uniqueFrame:Show()
    lastElement = detailPanel.uniqueFrame
  else
    detailPanel.uniqueBullet:Hide()
    if detailPanel.uniqueFrame then
      detailPanel.uniqueFrame:Hide()
    end
  end

  -- Upgradeable flag
  local showUpgradeable = false
  if petData.owned and petData.rarity and petData.rarity < 4 and petUtils then
    local allStones = petUtils:scanBattleStones(petData.petType, petData.rarity)
    local ranges = constants.FAMILY_STONE_RANGES
    
    for _, stone in ipairs(allStones) do
      if not constants.UNIVERSAL_STONE_IDS[stone.itemID] then
        if (stone.itemID >= ranges.polished.min and stone.itemID <= ranges.polished.max) or
           (stone.itemID >= ranges.flawless.min and stone.itemID <= ranges.flawless.max) then
          showUpgradeable = true
          break
        end
      end
    end
  end
  
  if showUpgradeable then
    if not detailPanel.upgradeableFrame then
      local blueColorCode = "|cff0070dd"
      detailPanel.upgradeableFrame = uiUtils:createClickableFilterTerm(detailPanel, "Upgradeable", "upgrade", blueColorCode)
      detailPanel.upgradeableFrame:SetFrameLevel(detailPanel:GetFrameLevel() + 5)
    end
    
    detailPanel.upgradeableBullet:ClearAllPoints()
    detailPanel.upgradeableBullet:SetPoint("LEFT", lastElement, "RIGHT", 0, 0)
    detailPanel.upgradeableBullet:Show()
    
    local bulletWidth = detailPanel.upgradeableBullet:GetStringWidth()
    detailPanel.upgradeableFrame:ClearAllPoints()
    detailPanel.upgradeableFrame:SetPoint("LEFT", lastElement, "RIGHT", bulletWidth, 0)
    detailPanel.upgradeableFrame:Show()
    lastElement = detailPanel.upgradeableFrame
  else
    detailPanel.upgradeableBullet:Hide()
    if detailPanel.upgradeableFrame then
      detailPanel.upgradeableFrame:Hide()
    end
  end

  -- Source in info line (after flags)
  if petData.sourceText and petData.sourceText ~= "" then
    local sourceLabel
    
    -- When both World Event and Vendor exist, prefer Vendor (World Event becomes a requirement)
    -- This matches how the tooltip renders: shows "Vendor" header with "Requirement: Event Name"
    if petData.sourceText:match("World Event:") and petData.sourceText:match("Vendor:") then
      sourceLabel = "Vendor"
    elseif petData.sourceText:match("^([^:]+):") then
      sourceLabel = petData.sourceText:match("^([^:]+)")
    else
      sourceLabel = petData.sourceText
    end
    
    detailPanel.sourceLabel:SetText(sourceLabel)
    detailPanel.sourceLabel:SetTextColor(unpack(LAYOUT.SOURCE_COLOR))
    
    -- Store full source text and pet icon for tooltip
    detailPanel.sourceFrame.sourceText = petData.sourceText
    detailPanel.sourceFrame.petIcon = petData.icon
    detailPanel.sourceFrame.speciesID = petData.speciesID
    
    -- Map source label to filter keyword for click-to-filter
    -- Strip color codes before matching (Blizzard wraps sourceText)
    local cleanLabel = (sourceLabel or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower():match("^%s*(.-)%s*$")
    detailPanel.sourceFrame.filterToken = SOURCE_FILTER_MAP[cleanLabel] or cleanLabel
    
    local textWidth = detailPanel.sourceLabel:GetStringWidth()
    local spaceWidth = uiUtils:getSpaceWidth()
    detailPanel.sourceFrame:SetWidth(textWidth + (spaceWidth * 2))
    detailPanel.sourceFrame:SetHeight(16)
    
    -- Position source with bullet separator after last element
    detailPanel.sourceBullet:ClearAllPoints()
    detailPanel.sourceBullet:SetPoint("LEFT", lastElement, "RIGHT", 0, 0)
    detailPanel.sourceBullet:Show()
    
    local bulletWidth = detailPanel.sourceBullet:GetStringWidth()
    detailPanel.sourceFrame:ClearAllPoints()
    detailPanel.sourceFrame:SetPoint("LEFT", lastElement, "RIGHT", bulletWidth, 0)
    detailPanel.sourceFrame:Show()
    detailPanel.sourceLabel:Show()
    
    -- Source highlight for filter matches
    if matchContext and matchContext.source then
      detailPanel.sourceHighlight:Show()
    else
      detailPanel.sourceHighlight:Hide()
    end

    -- Source tooltip + hover + click (set once, delegates to sourceTooltip module)
    if not detailPanel.sourceFrame.hasTooltip then
      detailPanel.sourceFrame.hasTooltip = true
      
      detailPanel.sourceFrame:SetScript("OnEnter", function(self)
        self.hoverBg:Show()
        if not self.sourceText then return end
        local st = Addon.sourceTooltip
        if st then
          st:show(self, self.sourceText, {
            hints = self.filterToken and uiUtils:getFilterHints(self.filterToken) or nil,
            petIcon = self.petIcon,
            speciesID = self.speciesID,
          })
        end
      end)
      
      detailPanel.sourceFrame:SetScript("OnLeave", function(self)
        self.hoverBg:Hide()
        local st = Addon.sourceTooltip
        if st then
          st:hide()
        end
      end)
      
      uiUtils:attachFilterClick(detailPanel.sourceFrame, function(self)
        return self.filterToken
      end, {
        ctrl = function()
          local st = Addon.sourceTooltip
          if st then st:setWaypoint() end
        end,
        alt = function()
          -- TODO: show quest series popup
        end,
      })
    end
  else
    detailPanel.sourceBullet:Hide()
    detailPanel.sourceFrame:Hide()
    detailPanel.sourceLabel:Hide()
    detailPanel.sourceHighlight:Hide()
  end

  -- Update stats with breed-aware icons
  local maxHealth, power, speed = petUtils:getPetStats(petData)
  if petData.owned and maxHealth and power and speed then
    local showH, showP, showS = getBreedStatFlags(petData.breedText)
    local hPrefix = showH and STAT_INLINE.H or ""
    local pPrefix = showP and STAT_INLINE.P or ""
    local sPrefix = showS and STAT_INLINE.S or ""
    local statsText = string.format("%s%d Health%s%s%d Power%s%s%d Speed",
      hPrefix, maxHealth, BULLET, pPrefix, power, BULLET, sPrefix, speed)
    detailPanel.stats:SetText(statsText)
    detailPanel.stats:Show()
  else
    detailPanel.stats:Hide()
  end

  -- Update description
  detailPanel.desc:SetText(petData.description or "...")

  -- Abilities or companion model
  if canBattle == false then
    -- Non-battle companion: hide abilities, show 3D model on the right side.
    -- Desc is narrowed to left ~58% to make room. Model occupies right ~42%.
    -- ClearModel() forces a full refresh so switching between companions
    -- doesn't leave the previous creature displayed.
    detailPanel.abilitiesHeader:Hide()
    for _, frame in ipairs(detailPanel.abilityFrames) do
      frame:Hide()
      if frame.highlight then frame.highlight:Hide() end
    end

    local panelWidth = detailPanel.panelWidth or 500
    -- Desc uses full panel width; PlayerModel frame renders on top so any text behind
    -- the model is simply occluded — no need to pre-narrow the text area.
    local descWidth = math.max(160, panelWidth - (LAYOUT.DESC_SIDE_PADDING * 2))
    detailPanel.desc:SetWidth(descWidth)

    -- displayID is index 12 from GetPetInfoBySpeciesID — matches how teamSection renders models
    local displayID = select(12, C_PetJournal.GetPetInfoBySpeciesID(petData.speciesID))
    detailPanel.companionModel:ClearAllPoints()
    -- Flush to detailBg top (y=0) so tall creatures don't clip; SOURCE_BOTTOM padding at bottom
    detailPanel.companionModel:SetPoint("TOPRIGHT", detailPanel.detailBg, "TOPRIGHT",
      -LAYOUT.DESC_SIDE_PADDING, 0)
    detailPanel.companionModel:SetPoint("BOTTOMRIGHT", detailPanel.detailBg, "BOTTOMRIGHT",
      -LAYOUT.DESC_SIDE_PADDING, LAYOUT.SOURCE_BOTTOM)
    detailPanel.companionModel:SetWidth(LAYOUT.COMPANION_MODEL_WIDTH)
    if displayID and displayID > 0 then
      detailPanel.companionModel:ClearModel()
      detailPanel.companionModel:SetDisplayInfo(displayID)
    end
    detailPanel.companionModel:Show()
  else
    -- Restore full desc width for non-companion
    local panelWidth = detailPanel.panelWidth or 500
    local descWidth = math.max(160, panelWidth - (LAYOUT.DESC_SIDE_PADDING * 2))
    detailPanel.desc:SetWidth(descWidth)
    detailPanel.companionModel:Hide()
    detailPanel.abilitiesHeader:Show()
    updateAbilityDisplay(petData, matchContext)
  end
end

--[[
  Handle resize
  Updates dynamic layout elements when panel is resized.
  Uses passed width instead of querying GetWidth() (top-down sizing).
  
  @param width number - Panel width from parent
]]
function infoSection:onResize(width)
  if not detailPanel then return end

  local panelWidth = width or detailPanel.panelWidth or 500
  
  -- Store for other functions to use
  detailPanel.panelWidth = panelWidth

  -- Update text widths
  local nameWidth = math.max(120, panelWidth - 20 - LAYOUT.ICON_SIZE - 20 - 20)
  detailPanel.name:SetWidth(nameWidth)

  local descWidth = math.max(160, panelWidth - (LAYOUT.DESC_SIDE_PADDING * 2))
  detailPanel.desc:SetWidth(descWidth)

  -- Reflow ability frames
  local abilityWidth = math.floor((panelWidth - 40) / LAYOUT.ABILITY_COLUMNS)

  for i, frame in ipairs(detailPanel.abilityFrames) do
    if frame:IsShown() then
      local row = math.ceil(i / LAYOUT.ABILITY_COLUMNS)
      local col = ((i - 1) % LAYOUT.ABILITY_COLUMNS) + 1
      local xOffset = (col - 1) * (abilityWidth + LAYOUT.ABILITY_SPACING)
      local yOffset = -(row - 1) * LAYOUT.ABILITY_ROW_HEIGHT - LAYOUT.ABILITIES_HEADER_GAP

      frame:ClearAllPoints()
      frame:SetPoint("TOPLEFT", detailPanel.abilitiesHeader, "BOTTOMLEFT", xOffset, yOffset)
      frame:SetWidth(abilityWidth)
    end
  end
end

--[[
  Update highlighting
  Updates match highlighting without full refresh.
  
  @param matchContext table|nil - Match context for current filter
]]
function infoSection:updateHighlighting(matchContext)
  if not detailPanel then return end
  
  -- Update source highlighting
  if matchContext and matchContext.source then
    detailPanel.sourceHighlight:Show()
  else
    detailPanel.sourceHighlight:Hide()
  end
  
  -- Update ability highlighting
  for _, frame in ipairs(detailPanel.abilityFrames) do
    if frame:IsShown() and frame.abilityID then
      if matchContext and matchContext.abilities and matchContext.abilities[frame.abilityID] then
        showAbilityHighlight(frame)
      else
        frame.highlight:Hide()
      end
    end
  end
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("infoSection", {"constants", "petUtils", "uiUtils", "abilityTooltips", "abilityUtils"}, function()
    return true
  end)
end

-- Export as internal module (not public API)
Addon.infoSection = infoSection
return infoSection