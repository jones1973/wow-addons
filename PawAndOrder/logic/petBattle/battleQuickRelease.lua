--[[
  logic/petBattle/battleQuickRelease.lua
  Quick Release from Battle
  
  Two entry points, same popup:
  1. Shift-click enemy pet icon → Single species filter
  2. Click forfeit button → All enemy species filter + explainer text
  
  Features:
  - Scrollable list of your pets matching enemy species
  - Breed match highlighting (subtle background)
  - Forfeits battle on release to re-engage same wild pet
  
  Settings:
  - forfeitButtonBehavior: "enhanced" (click=popup), "standard" (shift=popup), "disabled"
  
  Dependencies: events, utils, petCache, breedDetection, constants, tooltip, infoTip, options
  Exports: Addon.battleQuickRelease
]]

local ADDON_NAME, Addon = ...

local battleQuickRelease = {}

-- Module references (resolved at init)
local events, utils, petCache, breedDetection, constants, tooltip, infoTip, options

-- State
local initialized = false
local hooked = false
local forfeitHooked = false
local canQuickRelease = true  -- False after any enemy pet dies

-- Popup frame reference
local popupFrame = nil

-- Current popup state
local currentEnemyBreedIDs = {}  -- breedIDs of enemies for highlighting matches
local currentEnemyBreedInfo = {} -- {breedName, speciesName} for display

-- ============================================================================
-- LAYOUT CONSTANTS
-- ============================================================================

local L = {
  POPUP_WIDTH = 400,
  POPUP_PADDING = 20,
  SCROLL_INSET = 10,
  SCROLLBAR_WIDTH = 20,  -- Width reserved for scrollbar
  CONTENT_WIDTH = 320,  -- POPUP_WIDTH - POPUP_PADDING * 2 - SCROLL_INSET * 2 - SCROLLBAR_WIDTH
  
  ROW_HEIGHT = 52,
  ROW_GAP = 10,
  ROW_PADDING = 10,  -- Internal row padding
  ICON_SIZE = 38,
  BUTTON_WIDTH = 72,
  BUTTON_HEIGHT = 28,
  
  SCROLL_HEIGHT = 280,  -- Room for ~4.5 rows with new sizing
  
  TITLE_GAP = 12,
  SECTION_GAP = 20,
  BUTTON_GAP = 12,
  FOOTER_GAP = 24,  -- Space between list and bottom buttons
  
  ENEMY_COLUMN_GAP = 28,  -- Gap between enemy team and possible breeds columns
  ENEMY_HEADER_HEIGHT = 12,  -- Height of header text
  ENEMY_HEADER_GAP = 7,  -- Gap between header underline and data
  ENEMY_ROW_HEIGHT = 18,  -- Height of each enemy row (~14px text + 4px gap)
  
  BREED_MATCH_COLOR = {0.3, 0.5, 0.3, 0.6},
}

-- Random phrases for the release prompt
local RELEASE_PHRASES = {
  "Release one to make room:",
  "Select one for release:",
  "Cut one loose:",
  "Grant one parole:",
  "Set one free:",
  "One must go:",
  "Time served:",
  "Commute a sentence:",
  "Early release candidate:",
  "Pick a volunteer:",
}

-- Info tip content
local INFO_TIP_CONTENT = {
  title = "Quick Release",
  brief = "Release one of your pets to make room for new pets of that species.",
  description = "Release one of your duplicate pets to make room, then re-engage the same wild pet you were fighting.",
  sections = {
    {
      label = "Shortcut:",
      text = "Shift-click any enemy pet icon before an enemy dies to open this popup filtered to that species.",
      labelColor = {r = 0.7, g = 0.7, b = 1},
    },
    {
      label = "Note:",
      text = "Once an enemy pet dies, the wild pet you attacked will despawn on forfeit.",
      labelColor = {r = 1, g = 0.7, b = 0.7},
    },
  },
  settingsHint = "Settings: Pet Battle → Forfeit Button Behavior",
}

-- ============================================================================
-- FORWARD DECLARATIONS
-- ============================================================================

local releaseAndForfeit
local showPopup

-- ============================================================================
-- PET ROW CREATION
-- ============================================================================

local function createPetRow(parent, index)
  local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  row:SetSize(L.CONTENT_WIDTH, L.ROW_HEIGHT)
  
  row:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
  })
  row:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
  row:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
  
  -- Separator line above (shown only between different species)
  -- Positioned in the middle of the gap: ROW_GAP above line, line, ROW_GAP below line (to row)
  local separator = row:CreateTexture(nil, "OVERLAY")
  separator:SetHeight(1)
  separator:SetPoint("BOTTOMLEFT", row, "TOPLEFT", 8, L.ROW_GAP)
  separator:SetPoint("BOTTOMRIGHT", row, "TOPRIGHT", -8, L.ROW_GAP)
  separator:SetColorTexture(0.5, 0.5, 0.5, 0.8)
  row.separator = separator
  
  -- Species icon (left side, with padding)
  local icon = row:CreateTexture(nil, "ARTWORK")
  icon:SetSize(L.ICON_SIZE, L.ICON_SIZE)
  icon:SetPoint("LEFT", row, "LEFT", L.ROW_PADDING, 0)
  row.icon = icon
  
  -- Level text (fixed width, right of icon with gap)
  local levelText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  levelText:SetPoint("LEFT", icon, "RIGHT", 12, 0)
  levelText:SetWidth(30)
  levelText:SetJustifyH("RIGHT")
  row.levelText = levelText
  
  -- Breed text (fixed width, right of level with gap)
  local breedText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  breedText:SetPoint("LEFT", levelText, "RIGHT", 12, 0)
  breedText:SetWidth(44)
  breedText:SetJustifyH("CENTER")
  row.breedText = breedText
  
  -- Rarity text (right of breed with gap)
  local rarityText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  rarityText:SetPoint("LEFT", breedText, "RIGHT", 12, 0)
  rarityText:SetWidth(72)
  rarityText:SetJustifyH("LEFT")
  row.rarityText = rarityText
  
  -- Release button (right side, with padding)
  local releaseBtn = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
  releaseBtn:SetSize(L.BUTTON_WIDTH, L.BUTTON_HEIGHT)
  releaseBtn:SetPoint("RIGHT", row, "RIGHT", -L.ROW_PADDING, 0)
  releaseBtn:SetText("Release")
  row.releaseBtn = releaseBtn
  
  -- Release button tooltip
  releaseBtn:SetScript("OnEnter", function(self)
    if tooltip then
      tooltip:show(self, "ANCHOR_RIGHT")
      tooltip:header("Release this pet")
      tooltip:space(4)
      tooltip:text("Forfeits match and releases this pet from your collection. Your team pets will lose 10% health.", {color = {1, 0.6, 0.2}, wrap = true})
      tooltip:done()
    end
  end)
  releaseBtn:SetScript("OnLeave", function()
    if tooltip then tooltip:hide() end
  end)
  
  row:Hide()
  return row
end

-- ============================================================================
-- POPUP CREATION
-- ============================================================================

local function createPopupFrame()
  local frame = CreateFrame("Frame", "PAOQuickReleasePopup", UIParent, "BackdropTemplate")
  frame:SetSize(L.POPUP_WIDTH, 400)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:SetFrameLevel(100)
  frame:EnableMouse(true)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
  })
  frame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
  
  -- Close button (standard position)
  local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
  closeBtn:SetScript("OnClick", function() frame:Hide() end)
  frame.closeBtn = closeBtn
  
  -- Title (centered)
  local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOP", frame, "TOP", 0, -L.POPUP_PADDING)
  title:SetText("Quick Release")
  frame.title = title
  
  -- Explainer text (only shown when from forfeit button)
  local explainer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  explainer:SetPoint("TOP", title, "BOTTOM", 0, -L.TITLE_GAP)
  explainer:SetPoint("LEFT", frame, "LEFT", L.POPUP_PADDING, 0)
  explainer:SetPoint("RIGHT", frame, "RIGHT", -L.POPUP_PADDING, 0)
  explainer:SetJustifyH("CENTER")
  explainer:SetText("You are forfeiting.\n\nRelease a pet to make room, then re-engage the same wild pet.")
  explainer:SetTextColor(1, 1, 1)
  frame.explainer = explainer
  
  -- Enemy breed info container (two columns: Enemy Team | Possible Breeds)
  local enemyInfoContainer = CreateFrame("Frame", nil, frame)
  enemyInfoContainer:SetPoint("LEFT", frame, "LEFT", L.POPUP_PADDING, 0)
  enemyInfoContainer:SetPoint("RIGHT", frame, "RIGHT", -L.POPUP_PADDING, 0)
  enemyInfoContainer:SetHeight(90)  -- Will be adjusted dynamically
  frame.enemyInfoContainer = enemyInfoContainer
  
  -- Column headers (positions set dynamically in showPopup)
  local speciesHeader = enemyInfoContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  speciesHeader:SetPoint("TOPLEFT", enemyInfoContainer, "TOPLEFT", 0, 0)
  speciesHeader:SetText("Enemy Team")
  speciesHeader:SetTextColor(0.75, 0.55, 1)  -- Lavender
  frame.speciesHeader = speciesHeader
  
  -- Underline for species header
  local speciesUnderline = enemyInfoContainer:CreateTexture(nil, "ARTWORK")
  speciesUnderline:SetHeight(1)
  speciesUnderline:SetPoint("TOPLEFT", speciesHeader, "BOTTOMLEFT", 0, -1)
  speciesUnderline:SetPoint("TOPRIGHT", speciesHeader, "BOTTOMRIGHT", 0, -1)
  speciesUnderline:SetColorTexture(0.75, 0.55, 1, 0.6)
  frame.speciesUnderline = speciesUnderline
  
  local breedsHeader = enemyInfoContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  breedsHeader:SetText("Possible Breeds")
  breedsHeader:SetTextColor(0.75, 0.55, 1)  -- Lavender
  frame.breedsHeader = breedsHeader
  
  -- Underline for breeds header
  local breedsUnderline = enemyInfoContainer:CreateTexture(nil, "ARTWORK")
  breedsUnderline:SetHeight(1)
  breedsUnderline:SetPoint("TOPLEFT", breedsHeader, "BOTTOMLEFT", 0, -1)
  breedsUnderline:SetPoint("TOPRIGHT", breedsHeader, "BOTTOMRIGHT", 0, -1)
  breedsUnderline:SetColorTexture(0.75, 0.55, 1, 0.6)
  frame.breedsUnderline = breedsUnderline
  
  -- Pre-create row fontstrings (up to 3 enemies)
  -- Row Y offset: header height + underline (1px) + gap
  local dataStartY = -(L.ENEMY_HEADER_HEIGHT + 1 + L.ENEMY_HEADER_GAP)
  frame.enemyRows = {}
  for i = 1, 3 do
    local rowY = dataStartY - (i - 1) * L.ENEMY_ROW_HEIGHT
    
    local speciesText = enemyInfoContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    speciesText:SetPoint("TOPLEFT", enemyInfoContainer, "TOPLEFT", 0, rowY)
    speciesText:SetJustifyH("LEFT")
    
    local breedsText = enemyInfoContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    breedsText:SetTextColor(1, 1, 1)  -- White base; inline color codes handle highlighting
    breedsText:SetJustifyH("LEFT")
    
    frame.enemyRows[i] = {species = speciesText, breeds = breedsText, rowY = rowY}
  end
  
  -- Release prompt label (position set dynamically in showPopup)
  local promptLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  promptLabel:SetTextColor(1, 0.82, 0)
  frame.promptLabel = promptLabel
  
  -- Info tip (next to prompt label - position set dynamically)
  if infoTip then
    local infoBtn = infoTip:create(frame, INFO_TIP_CONTENT)
    if infoBtn then
      infoBtn:SetFrameLevel(frame:GetFrameLevel() + 10)
      frame.infoBtn = infoBtn
    end
  end
  
  -- Scroll frame container (leave room for scrollbar on right)
  local scrollContainer = CreateFrame("Frame", nil, frame)
  scrollContainer:SetPoint("LEFT", frame, "LEFT", L.POPUP_PADDING + L.SCROLL_INSET, 0)
  scrollContainer:SetPoint("RIGHT", frame, "RIGHT", -L.POPUP_PADDING - L.SCROLL_INSET - L.SCROLLBAR_WIDTH, 0)
  scrollContainer:SetHeight(L.SCROLL_HEIGHT)
  frame.scrollContainer = scrollContainer
  
  -- Scroll frame
  local scrollFrame = CreateFrame("ScrollFrame", nil, scrollContainer, "UIPanelScrollFrameTemplate")
  scrollFrame:SetAllPoints()
  frame.scrollFrame = scrollFrame
  
  -- Scroll child (content)
  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetWidth(L.CONTENT_WIDTH)
  scrollFrame:SetScrollChild(scrollChild)
  frame.scrollChild = scrollChild
  
  -- Pre-create row pool
  frame.petRows = {}
  for i = 1, 10 do
    local row = createPetRow(scrollChild, i)
    frame.petRows[i] = row
  end
  
  -- Bottom buttons with proper spacing
  local forfeitBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  forfeitBtn:SetSize(90, 28)
  forfeitBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", L.POPUP_PADDING, L.POPUP_PADDING)
  forfeitBtn:SetText("Forfeit")
  forfeitBtn:SetScript("OnClick", function()
    frame:Hide()
    C_PetBattles.ForfeitGame()
  end)
  forfeitBtn:SetScript("OnEnter", function(self)
    if tooltip then
      tooltip:show(self, "ANCHOR_RIGHT")
      tooltip:header("Forfeit battle")
      tooltip:space(4)
      tooltip:text("Forfeits battle. Your pets will lose 10% health.", {color = {0.7, 0.7, 0.7}})
      tooltip:done()
    end
  end)
  forfeitBtn:SetScript("OnLeave", function()
    if tooltip then tooltip:hide() end
  end)
  frame.forfeitBtn = forfeitBtn
  
  local dismissBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  dismissBtn:SetSize(90, 28)
  dismissBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -L.POPUP_PADDING, L.POPUP_PADDING)
  dismissBtn:SetText("Dismiss")
  dismissBtn:SetScript("OnClick", function() frame:Hide() end)
  dismissBtn:SetScript("OnEnter", function(self)
    if tooltip then
      tooltip:show(self, "ANCHOR_RIGHT")
      tooltip:header("Close popup")
      tooltip:space(4)
      tooltip:text("Continue the battle", {color = {0.7, 0.7, 0.7}})
      tooltip:done()
    end
  end)
  dismissBtn:SetScript("OnLeave", function()
    if tooltip then tooltip:hide() end
  end)
  frame.dismissBtn = dismissBtn
  
  -- ESC to close
  table.insert(UISpecialFrames, "PAOQuickReleasePopup")
  
  frame:Hide()
  return frame
end

-- ============================================================================
-- POPUP DISPLAY
-- ============================================================================

--[[
  Show the quick release popup.
  
  @param ownedPets table - Array of pets to display
  @param enemyBreedIDs table - Array of enemy breed IDs for match highlighting
  @param fromForfeit boolean - Whether opened via forfeit button (shows explainer)
  @param targetSpeciesID number|nil - Specific species being targeted (shift-click)
]]
showPopup = function(ownedPets, enemyBreedIDs, fromForfeit, targetSpeciesID)
  if not popupFrame then
    popupFrame = createPopupFrame()
  end
  
  currentEnemyBreedIDs = enemyBreedIDs or {}
  
  -- Build breed ID lookup for fast matching
  local enemyBreedLookup = {}
  for _, breedID in ipairs(currentEnemyBreedIDs) do
    enemyBreedLookup[breedID] = true
  end
  
  -- Gather enemy species and their possible breeds
  local enemySpeciesData = {}
  local ALL_BREED_COUNT = 10  -- Total number of possible breeds
  local targetPossibleBreeds = nil  -- Possible breeds for targeted species only
  
  if C_PetBattles.IsInBattle() then
    local numEnemies = C_PetBattles.GetNumPets(Enum.BattlePetOwner.Enemy) or 0
    
    for i = 1, numEnemies do
      local speciesID = C_PetBattles.GetPetSpeciesID(Enum.BattlePetOwner.Enemy, i)
      if speciesID then
        local speciesName = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
        local possibleBreeds = nil
        local isTarget = (targetSpeciesID and speciesID == targetSpeciesID)
        
        -- Get rarity for coloring
        local rarity = C_PetBattles.GetBreedQuality(Enum.BattlePetOwner.Enemy, i) or 3
        
        -- Detect this enemy's actual breed
        local detectedBreedName = "?"
        local detectedBreedID = nil
        if breedDetection and breedDetection.detectBreedInBattle then
          detectedBreedID = breedDetection:detectBreedInBattle(Enum.BattlePetOwner.Enemy, i)
          if detectedBreedID then
            detectedBreedName = breedDetection:getBreedName(detectedBreedID) or "?"
          end
        end
        
        -- Get possible breeds from species data
        if breedDetection and breedDetection.getSpeciesData then
          local speciesData = breedDetection:getSpeciesData(speciesID)
          if speciesData and speciesData.breeds then
            possibleBreeds = speciesData.breeds
          end
        end
        
        -- Build breeds text with detected breed highlighted
        local breedsText = ""
        if not possibleBreeds or #possibleBreeds >= ALL_BREED_COUNT then
          breedsText = "|cff808080All|r"
        else
          local breedParts = {}
          for _, breedID in ipairs(possibleBreeds) do
            local name = breedDetection and breedDetection:getBreedName(breedID) or tostring(breedID)
            if breedID == detectedBreedID then
              -- Highlight detected breed (white/bright)
              table.insert(breedParts, "|cffffffff" .. name .. "|r")
            else
              -- Gray for other breeds
              table.insert(breedParts, "|cff808080" .. name .. "|r")
            end
          end
          breedsText = table.concat(breedParts, ", ")
        end
        
        -- Store target's breeds for display
        if isTarget then
          targetPossibleBreeds = breedsText
        end
        
        -- Format: "Name (breed)"
        local displayName = string.format("%s (%s)", speciesName or "Unknown", detectedBreedName)
        
        table.insert(enemySpeciesData, {
          speciesID = speciesID,
          name = displayName,
          breeds = breedsText,
          isTarget = isTarget,
          rarity = rarity
        })
      end
    end
  end
  
  -- Populate enemy info rows
  local enemyRowCount = math.min(#enemySpeciesData, 3)
  for i = 1, 3 do
    local row = popupFrame.enemyRows[i]
    if i <= enemyRowCount then
      local data = enemySpeciesData[i]
      row.species:SetText(data.name)
      
      -- Get rarity color
      local rarityColor = constants:GetRarityColor(data.rarity)
      local r, g, b = rarityColor.r, rarityColor.g, rarityColor.b
      
      -- Show breeds: only for target if one specified, otherwise show all
      if targetSpeciesID then
        -- Single target mode: only show breeds for the targeted species
        if data.isTarget then
          row.breeds:SetText(data.breeds)
          row.species:SetTextColor(r, g, b)
        else
          row.breeds:SetText("")
          -- Dim non-targeted (50% brightness)
          row.species:SetTextColor(r * 0.5, g * 0.5, b * 0.5)
        end
      else
        -- Forfeit mode: show all breeds in rarity color
        row.breeds:SetText(data.breeds)
        row.species:SetTextColor(r, g, b)
      end
      
      row.species:Show()
      row.breeds:Show()
    else
      row.species:Hide()
      row.breeds:Hide()
    end
  end
  
  -- Calculate max width of enemy team column
  local maxEnemyWidth = popupFrame.speciesHeader:GetStringWidth()
  for i = 1, enemyRowCount do
    local width = popupFrame.enemyRows[i].species:GetStringWidth()
    if width > maxEnemyWidth then
      maxEnemyWidth = width
    end
  end
  
  -- Position breeds column based on enemy column width
  local breedsColumnX = maxEnemyWidth + L.ENEMY_COLUMN_GAP
  popupFrame.breedsHeader:ClearAllPoints()
  popupFrame.breedsHeader:SetPoint("TOPLEFT", popupFrame.enemyInfoContainer, "TOPLEFT", breedsColumnX, 0)
  
  for i = 1, 3 do
    local row = popupFrame.enemyRows[i]
    row.breeds:ClearAllPoints()
    row.breeds:SetPoint("TOPLEFT", popupFrame.enemyInfoContainer, "TOPLEFT", breedsColumnX, row.rowY)
  end
  
  -- Show/hide enemy info container
  local hasEnemyInfo = enemyRowCount > 0
  if hasEnemyInfo then
    popupFrame.speciesHeader:Show()
    popupFrame.speciesUnderline:Show()
    popupFrame.breedsHeader:Show()
    popupFrame.breedsUnderline:Show()
    popupFrame.enemyInfoContainer:Show()
  else
    popupFrame.speciesHeader:Hide()
    popupFrame.speciesUnderline:Hide()
    popupFrame.breedsHeader:Hide()
    popupFrame.breedsUnderline:Hide()
    popupFrame.enemyInfoContainer:Hide()
  end
  
  -- Title and explainer based on entry point
  if fromForfeit then
    popupFrame.title:SetText("Quick Release")
    popupFrame.explainer:Show()
  else
    popupFrame.title:SetText("Make room for a new friend?")
    popupFrame.explainer:Hide()
  end
  
  -- Random release phrase
  local phrase = RELEASE_PHRASES[math.random(#RELEASE_PHRASES)]
  popupFrame.promptLabel:SetText(phrase)
  
  -- Hide all rows first
  for i = 1, #popupFrame.petRows do
    popupFrame.petRows[i]:Hide()
  end
  
  -- Sort owned pets: by species, then by level (lowest first)
  table.sort(ownedPets, function(a, b)
    if a.speciesID ~= b.speciesID then
      return (a.speciesID or 0) < (b.speciesID or 0)
    end
    return (a.level or 0) < (b.level or 0)
  end)
  
  -- Populate pet rows
  local rowCount = math.min(#ownedPets, #popupFrame.petRows)
  for i = 1, rowCount do
    local pet = ownedPets[i]
    local row = popupFrame.petRows[i]
    
    -- Icon
    row.icon:SetTexture(pet.icon or "Interface\\Icons\\INV_Box_PetCarrier_01")
    
    -- Level
    row.levelText:SetText(pet.level or "?")
    row.levelText:SetTextColor(0.9, 0.9, 0.9)
    
    -- Breed
    local breedName = pet.breedText or (pet.breedID and breedDetection and breedDetection:getBreedName(pet.breedID)) or "?"
    breedName = breedName:gsub(" %(%d+%%%)", "")  -- Strip confidence
    row.breedText:SetText(breedName)
    row.breedText:SetTextColor(1, 1, 1)
    
    -- Rarity
    local rarityName = constants:GetRarityName(pet.rarity)
    local rarityColor = constants:GetRarityColor(pet.rarity)
    row.rarityText:SetText(rarityName)
    row.rarityText:SetTextColor(rarityColor.r, rarityColor.g, rarityColor.b)
    
    -- Breed match = subtle green background with darker border
    local isBreedMatch = enemyBreedLookup[pet.breedID]
    if isBreedMatch then
      row:SetBackdropColor(unpack(L.BREED_MATCH_COLOR))
      row:SetBackdropBorderColor(0.1, 0.1, 0.1, 1)  -- Dark border to separate from green
    else
      row:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
      row:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end
    
    -- Release button action
    row.releaseBtn:SetScript("OnClick", function()
      popupFrame:Hide()
      releaseAndForfeit(pet)
    end)
    
    row.petData = pet
    row:Show()
  end
  
  -- Position rows with species-based separators
  local yOffset = 0
  local prevSpeciesID = nil
  local separatorCount = 0
  
  for i = 1, rowCount do
    local pet = ownedPets[i]
    local row = popupFrame.petRows[i]
    local showSeparator = (i > 1 and pet.speciesID ~= prevSpeciesID)
    
    -- Add gap before this row
    if i > 1 then
      if showSeparator then
        -- Gap for separator: ROW_GAP above line + 1px line + ROW_GAP below line
        yOffset = yOffset + L.ROW_GAP + 1 + L.ROW_GAP
        separatorCount = separatorCount + 1
      else
        yOffset = yOffset + L.ROW_GAP
      end
    end
    
    -- Show/hide separator
    if row.separator then
      row.separator:SetShown(showSeparator)
    end
    
    -- Position row
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", popupFrame.scrollChild, "TOPLEFT", 0, -yOffset)
    
    -- Add row height for next iteration
    yOffset = yOffset + L.ROW_HEIGHT
    prevSpeciesID = pet.speciesID
  end
  
  -- Calculate content dimensions (accounting for separator gaps)
  local extraSeparatorHeight = separatorCount * (L.ROW_GAP + 1)  -- Extra gap per separator
  local contentHeight = rowCount * L.ROW_HEIGHT + (rowCount - 1) * L.ROW_GAP + extraSeparatorHeight + 2  -- +2 for bottom border visibility
  if contentHeight < L.ROW_HEIGHT then contentHeight = L.ROW_HEIGHT end
  local needsScroll = contentHeight > L.SCROLL_HEIGHT
  
  -- Calculate Y positions based on known heights
  local titleHeight = 24
  local explainerHeight = 52  -- 3 lines (with blank line)
  -- Enemy info: header (14) + rows (16 each) + spacing (8)
  local enemyInfoHeight = hasEnemyInfo and (L.ENEMY_HEADER_HEIGHT + 1 + L.ENEMY_HEADER_GAP + enemyRowCount * L.ENEMY_ROW_HEIGHT + L.SECTION_GAP) or 0
  local promptHeight = 20
  
  local titleY = -L.POPUP_PADDING
  local explainerY = titleY - titleHeight - L.TITLE_GAP
  local enemyInfoY, promptY
  
  if fromForfeit then
    enemyInfoY = explainerY - explainerHeight - L.SECTION_GAP
  else
    enemyInfoY = titleY - titleHeight - L.SECTION_GAP
  end
  
  if hasEnemyInfo then
    promptY = enemyInfoY - enemyInfoHeight
  else
    promptY = enemyInfoY
  end
  
  local scrollY = promptY - promptHeight - L.TITLE_GAP
  
  -- Position enemy info container
  popupFrame.enemyInfoContainer:ClearAllPoints()
  popupFrame.enemyInfoContainer:SetPoint("TOPLEFT", popupFrame, "TOPLEFT", L.POPUP_PADDING, enemyInfoY)
  popupFrame.enemyInfoContainer:SetPoint("TOPRIGHT", popupFrame, "TOPRIGHT", -L.POPUP_PADDING, enemyInfoY)
  popupFrame.enemyInfoContainer:SetHeight(enemyInfoHeight)
  
  -- Position prompt label
  popupFrame.promptLabel:ClearAllPoints()
  popupFrame.promptLabel:SetPoint("TOPLEFT", popupFrame, "TOPLEFT", L.POPUP_PADDING, promptY)
  
  -- Position info tip next to prompt label
  if popupFrame.infoBtn then
    popupFrame.infoBtn:ClearAllPoints()
    popupFrame.infoBtn:SetPoint("LEFT", popupFrame.promptLabel, "RIGHT", 8, 0)
  end
  
  -- Calculate display height (needsScroll and contentHeight already calculated above)
  local displayHeight = needsScroll and L.SCROLL_HEIGHT or contentHeight
  
  popupFrame.scrollChild:SetHeight(math.max(contentHeight, 1))
  
  -- Position scroll container (reserve scrollbar space only when needed)
  local scrollbarOffset = needsScroll and L.SCROLLBAR_WIDTH or 0
  popupFrame.scrollContainer:ClearAllPoints()
  popupFrame.scrollContainer:SetPoint("TOPLEFT", popupFrame, "TOPLEFT", L.POPUP_PADDING + L.SCROLL_INSET, scrollY)
  popupFrame.scrollContainer:SetPoint("TOPRIGHT", popupFrame, "TOPRIGHT", -L.POPUP_PADDING - L.SCROLL_INSET - scrollbarOffset, scrollY)
  popupFrame.scrollContainer:SetHeight(displayHeight)
  
  -- Adjust row widths based on scroll state
  local rowWidth = needsScroll and L.CONTENT_WIDTH or (L.CONTENT_WIDTH + L.SCROLLBAR_WIDTH)
  popupFrame.scrollChild:SetWidth(rowWidth)
  for i = 1, #popupFrame.petRows do
    popupFrame.petRows[i]:SetWidth(rowWidth)
  end
  
  -- Show/hide scrollbar
  local scrollBar = popupFrame.scrollFrame.ScrollBar
  if scrollBar then
    scrollBar:SetShown(needsScroll)
  end
  
  -- Calculate total popup height (using FOOTER_GAP for more space before buttons)
  local footerHeight = L.POPUP_PADDING + 28 + L.FOOTER_GAP
  local totalHeight = math.abs(scrollY) + displayHeight + footerHeight
  popupFrame:SetHeight(totalHeight)
  
  -- Forfeit button always visible
  popupFrame.forfeitBtn:Show()
  
  popupFrame:Show()
end

-- ============================================================================
-- ACTIONS
-- ============================================================================

releaseAndForfeit = function(pet)
  if not pet or not pet.petID then return end
  
  local petName = pet.customName or pet.speciesName or "Unknown pet"
  local speciesName = pet.speciesName or "Unknown species"
  local displayName = pet.customName and string.format("%s (%s)", pet.customName, speciesName) or speciesName
  
  -- Check if wild pet marking is enabled
  local willMark = false
  if Addon.options and Addon.options.Get then
    willMark = Addon.options:Get("wildPetMarkEnabled")
  end
  
  -- Queue the release after forfeit
  C_Timer.After(0.1, function()
    C_PetJournal.ReleasePetByID(pet.petID)
    
    -- Notify
    if Addon.notifications and Addon.notifications.show then
      local msg = string.format("Released %s", displayName)
      if willMark then
        msg = msg .. " - Look for the raid marker!"
      end
      Addon.notifications:show({
        message = msg,
        duration = 4,
      })
    end
    
    UIErrorsFrame:AddMessage(string.format("Released %s", displayName), 0.2, 1.0, 0.6, 1.0)
  end)
  
  -- Forfeit the battle
  C_PetBattles.ForfeitGame()
end

-- ============================================================================
-- GATHER OWNED PETS FOR SPECIES
-- ============================================================================

local function getOwnedPetsForSpecies(speciesIDs)
  if not petCache or not petCache:isInitialized() then return {} end
  
  local speciesLookup = {}
  for _, id in ipairs(speciesIDs) do
    speciesLookup[id] = true
  end
  
  local result = {}
  local allPets = petCache:getAllPets()
  for _, pet in pairs(allPets) do
    if pet.owned and speciesLookup[pet.speciesID] then
      table.insert(result, pet)
    end
  end
  
  return result
end

-- ============================================================================
-- ENEMY PET DATA GATHERING
-- ============================================================================

local function getEnemyPetData()
  if not C_PetBattles.IsInBattle() then return {}, {} end
  
  local speciesIDs = {}
  local breedIDs = {}
  local seenSpecies = {}
  
  local numEnemies = C_PetBattles.GetNumPets(Enum.BattlePetOwner.Enemy) or 0
  for i = 1, numEnemies do
    local speciesID = C_PetBattles.GetPetSpeciesID(Enum.BattlePetOwner.Enemy, i)
    if speciesID and not seenSpecies[speciesID] then
      seenSpecies[speciesID] = true
      table.insert(speciesIDs, speciesID)
    end
    
    -- Get breed using centralized detection
    local breedID
    if breedDetection and breedDetection.detectBreedInBattle then
      breedID = breedDetection:detectBreedInBattle(Enum.BattlePetOwner.Enemy, i)
    end
    if breedID then
      table.insert(breedIDs, breedID)
    end
  end
  
  return speciesIDs, breedIDs
end

local function getEnemyPetDataForSlot(petIndex)
  if not C_PetBattles.IsInBattle() then return {}, {} end
  
  local speciesID = C_PetBattles.GetPetSpeciesID(Enum.BattlePetOwner.Enemy, petIndex)
  if not speciesID then return {}, {} end
  
  local breedIDs = {}
  local breedID
  if breedDetection and breedDetection.detectBreedInBattle then
    breedID = breedDetection:detectBreedInBattle(Enum.BattlePetOwner.Enemy, petIndex)
  end
  if breedID then
    table.insert(breedIDs, breedID)
  end
  
  return {speciesID}, breedIDs
end

-- ============================================================================
-- ENEMY PET CLICK HANDLER (shift-click entry)
-- ============================================================================

local function onEnemyPetShiftClick(frame)
  if not frame.petOwner or not frame.petIndex then return end
  if frame.petOwner ~= Enum.BattlePetOwner.Enemy then return end
  
  if not canQuickRelease then
    if utils then
      utils:debug("QuickRelease: Enemy died, cannot use quick release")
    end
    return
  end
  
  local speciesIDs, breedIDs = getEnemyPetDataForSlot(frame.petIndex)
  if #speciesIDs == 0 then return end
  
  local speciesID = speciesIDs[1]
  local speciesName = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
  
  local ownedPets = getOwnedPetsForSpecies(speciesIDs)
  
  if #ownedPets == 0 then
    StaticPopup_Show("PAO_QUICK_RELEASE_NO_PETS", speciesName or "this pet")
    return
  end
  
  showPopup(ownedPets, breedIDs, false, speciesID)
end

-- ============================================================================
-- HOOK ENEMY PET FRAMES
-- ============================================================================

local function hookEnemyFrames()
  if hooked then return end
  
  local enemyFrames = {
    PetBattleFrame and PetBattleFrame.Enemy2,
    PetBattleFrame and PetBattleFrame.Enemy3,
  }
  
  -- Also hook the active enemy frame
  local activeEnemy = PetBattleFrame and PetBattleFrame.ActiveEnemy
  if activeEnemy then
    table.insert(enemyFrames, activeEnemy)
  end
  
  for _, frame in ipairs(enemyFrames) do
    if frame and not frame.paoHooked then
      frame:HookScript("OnClick", function(self, button)
        if IsShiftKeyDown() and button == "LeftButton" then
          onEnemyPetShiftClick(self)
        end
      end)
      frame.paoHooked = true
    end
  end
  
  hooked = true
end

-- ============================================================================
-- FORFEIT BUTTON HANDLER
-- ============================================================================

local function onForfeitButtonClick()
  if not canQuickRelease then
    -- Past point of no return, just forfeit normally
    C_PetBattles.ForfeitGame()
    return
  end
  
  local speciesIDs, breedIDs = getEnemyPetData()
  if #speciesIDs == 0 then
    C_PetBattles.ForfeitGame()
    return
  end
  
  local ownedPets = getOwnedPetsForSpecies(speciesIDs)
  
  if #ownedPets == 0 then
    -- No pets to release, just forfeit
    C_PetBattles.ForfeitGame()
    return
  end
  
  showPopup(ownedPets, breedIDs, true)
end

-- ============================================================================
-- FORFEIT BUTTON HOOK
-- ============================================================================

local function hookForfeitButton()
  if forfeitHooked then return end
  
  local forfeitBtn = PetBattleFrame and PetBattleFrame.BottomFrame and PetBattleFrame.BottomFrame.ForfeitButton
  if not forfeitBtn then
    if utils then utils:debug("QuickRelease: Forfeit button not found") end
    return
  end
  
  forfeitBtn:SetScript("OnClick", function(self, button, down)
    local behavior = options and options:Get("forfeitButtonBehavior") or "enhanced"
    
    if behavior == "disabled" then
      PetBattleForfeitButton_OnClick(self)
      return
    end
    
    local shiftDown = IsShiftKeyDown()
    local shouldShowPopup = false
    
    if behavior == "enhanced" then
      shouldShowPopup = not shiftDown
    else  -- "standard"
      shouldShowPopup = shiftDown
    end
    
    if shouldShowPopup then
      onForfeitButtonClick()
    else
      PetBattleForfeitButton_OnClick(self)
    end
  end)
  
  forfeitHooked = true
  if utils then utils:debug("QuickRelease: Forfeit button hooked") end
end

-- ============================================================================
-- STATIC POPUP
-- ============================================================================

StaticPopupDialogs["PAO_QUICK_RELEASE_NO_PETS"] = {
  text = "You don't own any %s to release.",
  button1 = OKAY,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
}

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function battleQuickRelease:initialize()
  if initialized then return true end
  
  events = Addon.events
  utils = Addon.utils
  petCache = Addon.petCache
  breedDetection = Addon.breedDetection
  constants = Addon.constants
  tooltip = Addon.tooltip
  infoTip = Addon.infoTip
  options = Addon.options
  
  if not events or not utils or not constants then
    print("|cff33ff99PAO|r: |cffff4444battleQuickRelease: Missing dependencies|r")
    return false
  end
  
  events:subscribe("PET_BATTLE_OPENING_DONE", function()
    canQuickRelease = true
    hookEnemyFrames()
    hookForfeitButton()
  end)
  
  -- Track enemy death = point of no return (wild pet despawns after any enemy dies)
  events:subscribe("PET_BATTLE_HEALTH_CHANGED", function(_, petOwner, petIndex)
    if not canQuickRelease then return end  -- Already locked
    if petOwner ~= Enum.BattlePetOwner.Enemy then return end  -- Only care about enemies
    
    if C_PetBattles.GetHealth(petOwner, petIndex) == 0 then
      canQuickRelease = false
      if utils then utils:debug("QuickRelease: Enemy pet died, quick release disabled") end
    end
  end)
  
  events:subscribe("PET_BATTLE_CLOSE", function()
    canQuickRelease = true
    if popupFrame then
      popupFrame:Hide()
    end
  end)
  
  initialized = true
  return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
  Addon.registerModule("battleQuickRelease", {"events", "utils", "constants", "petCache", "breedDetection", "tooltip", "infoTip", "options"}, function()
    return battleQuickRelease:initialize()
  end)
end

Addon.battleQuickRelease = battleQuickRelease
return battleQuickRelease