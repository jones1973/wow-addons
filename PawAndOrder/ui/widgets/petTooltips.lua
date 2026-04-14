--[[
  ui/shared/petTooltips.lua
  Pet Tooltip Builder
  
  Builds pet tooltips using the unified tooltip API.
  Pulls data from C_PetJournal APIs and renders with the shared tooltip.
  
  Usage:
    petTooltips:showForPetID(owner, petID, opts)      -- Owned pet with real stats
    petTooltips:showForSpecies(owner, speciesID, opts) -- Unowned or base stats
    petTooltips:show(owner, petID, speciesID, opts)   -- Auto-detect
    petTooltips:hide()
  
  Dependencies: tooltip, constants, petUtils
  Exports: Addon.petTooltips
]]

local ADDON_NAME, Addon = ...

local petTooltips = {}

-- ============================================================================
-- CONSTANTS (tooltip-specific only, rest from constants module)
-- ============================================================================

local STAT_TEXTURE = "Interface\\PetBattles\\PetBattle-StatIcons"
local STAT_ICONS = {
  health = {0, 0.5, 0, 0.5},
  power = {0.5, 1, 0, 0.5},
  speed = {0, 0.5, 0.5, 1},
}
local STAT_COLORS = {
  health = {0, 1, 0},
  power = {1, 0.82, 0},
  speed = {0.4, 0.8, 1},
}

-- Module references
local tooltip, constants, petUtils

-- ============================================================================
-- HELPERS
-- ============================================================================

local function getQualityColor(quality)
  -- API returns 1-based quality, petUtils expects 1-based - no conversion needed
  local c = petUtils:getRarityColor(quality)
  return {c.r, c.g, c.b}
end

local function getPetTypeName(petType)
  return constants:GetPetFamilyName(petType)
end

local function getPetTypeTexture(petType)
  return constants.FAMILY_ICON_PATHS[petType] or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- ============================================================================
-- TOOLTIP BUILDING
-- ============================================================================

local function buildTooltip(owner, opts, name, level, quality, petType, health, power, speed, speciesID, customName, petID, footerLines)
  if not tooltip then return end
  
  tooltip:show(owner, opts)
  
  -- Name with quality color
  local displayName = customName or name
  if customName and name then
    displayName = customName .. " (" .. name .. ")"
  end
  tooltip:header(displayName or "Unknown Pet", {color = getQualityColor(quality)})
  
  -- Level
  local levelText = BATTLE_PET_CAGE_TOOLTIP_LEVEL or "Level %d"
  tooltip:text(levelText:format(level or 1))
  
  tooltip:space(4)
  
  -- Pet type with icon
  tooltip:iconText(getPetTypeTexture(petType), getPetTypeName(petType), {
    iconSize = 20,
    iconCoords = {0.796875, 0.492188, 0.503906, 0.65625},
  })
  
  tooltip:space(4)
  
  -- Stats row
  tooltip:row(
    {icon = STAT_TEXTURE, iconCoords = STAT_ICONS.health, text = tostring(health or 0), color = STAT_COLORS.health, iconSize = 16},
    {icon = STAT_TEXTURE, iconCoords = STAT_ICONS.power, text = tostring(power or 0), color = STAT_COLORS.power, iconSize = 16},
    {icon = STAT_TEXTURE, iconCoords = STAT_ICONS.speed, text = tostring(speed or 0), color = STAT_COLORS.speed, iconSize = 16}
  )
  
  -- Collected count: journal owned + caged bag copies of this species
  if speciesID and C_PetJournal and C_PetJournal.GetNumCollectedInfo then
    local numCollected, maxCollected = C_PetJournal.GetNumCollectedInfo(speciesID)
    numCollected = numCollected or 0
    maxCollected = maxCollected or 3

    local cagedCount = 0
    if petUtils then
      local allCaged = petUtils:scanCagedPets()
      for _, c in ipairs(allCaged) do
        if c.speciesID == speciesID then
          cagedCount = cagedCount + 1
        end
      end
    end

    local total = numCollected + cagedCount
    tooltip:space(4)
    tooltip:text(string.format("Collected (%d/%d)", total, maxCollected),
      {color = {1, 0.82, 0}})
  end
  
  -- Recently acquired indicator
  if petID then
    local petAcquisitions = Addon.petAcquisitions
    if petAcquisitions and petAcquisitions:isRecent(petID) then
      local dateStr = petAcquisitions:getAcquiredDateFormatted(petID)
      tooltip:space(6)
      tooltip:text("Recently Acquired", {color = {1, 0.85, 0.4}})
      if dateStr then
        tooltip:text("Acquired: " .. dateStr, {color = {0.7, 0.7, 0.7}})
      end
    end
  end

  -- Optional footer lines (e.g. "Caged" indicator)
  -- Each line: {space, text, color} or {space, iconTexture, iconSize, text, iconColor, color}
  if footerLines then
    for _, line in ipairs(footerLines) do
      tooltip:space(line.space or 4)
      if line.iconTexture then
        tooltip:iconText(line.iconTexture, line.text, {
          iconSize = line.iconSize or 14,
          iconColor = line.iconColor,
          color = line.color,
        })
      else
        tooltip:text(line.text, {color = line.color})
      end
    end
  end

  tooltip:done()
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Show tooltip for an owned pet.
  @param owner frame
  @param petID string - Pet GUID
  @param opts table - Position options
]]
function petTooltips:showForPetID(owner, petID, opts)
  if not owner or not petID then return end
  
  local speciesID, customName, level, xp, maxXp, displayID, isFavorite, petName, 
        petIcon, petType = C_PetJournal.GetPetInfoByPetID(petID)
  
  if not speciesID then return end
  
  local health, maxHealth, power, speed, quality = C_PetJournal.GetPetStats(petID)
  
  buildTooltip(owner, opts, petName, level, quality, petType, maxHealth, power, speed, speciesID, customName, petID)
end

--[[
  Show tooltip for a pet species (unowned).
  @param owner frame
  @param speciesID number
  @param opts table - Position options
]]
function petTooltips:showForSpecies(owner, speciesID, opts)
  if not owner or not speciesID then return end
  
  local name, icon, petType = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
  if not name then return end
  
  -- Default stats for unowned
  buildTooltip(owner, opts, name, 1, 3, petType, 100, 10, 10, speciesID, nil)
end

--[[
  Show tooltip with explicit stats.
]]
function petTooltips:showWithStats(owner, speciesID, level, quality, health, power, speed, customName, opts)
  if not owner or not speciesID then return end
  
  local name, icon, petType = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
  if not name then return end
  
  buildTooltip(owner, opts, name, level, quality, petType, health, power, speed, speciesID, customName)
end

--[[
  Show tooltip for a caged pet (in bags as item 82800).
  Uses stats parsed from the battlepet hyperlink stored on petData.
  Appends a "Caged" indicator line after the standard content.
  @param owner frame
  @param petData table - Caged pet entry from scanCagedPets
  @param opts table - Position options
]]
function petTooltips:showForCaged(owner, petData, opts)
  if not owner or not petData then return end

  -- Prepend amber cage icon to name to immediately signal this pet is caged
  local CAGE_TEX = "Interface\\AddOns\\PawAndOrder\\textures\\cage.png"
  local nameWithIcon = "|T" .. CAGE_TEX .. ":14|t " .. (petData.speciesName or "Unknown Pet")

  buildTooltip(owner, opts,
    nameWithIcon, petData.level, petData.rarity, petData.petType,
    petData.maxHealth, petData.power, petData.speed,
    petData.speciesID, nil, nil,
    {
      { space = 6,
        iconTexture = CAGE_TEX,
        iconSize = 14,
        iconColor = {0.9, 0.6, 0.1},
        text = "Caged",
        color = {0.9, 0.6, 0.1} }
    })
end

--[[
  Auto-detect owned vs unowned vs caged.
]]
function petTooltips:show(owner, petID, speciesID, opts)
  if petID and type(petID) == "string" and petID:sub(1, 10) == "BattlePet-" then
    self:showForPetID(owner, petID, opts)
  elseif speciesID then
    self:showForSpecies(owner, speciesID, opts)
  end
end

--[[
  Hide tooltip.
]]
function petTooltips:hide()
  if tooltip then
    tooltip:hide()
  end
end

--[[
  Check if shown.
]]
function petTooltips:isShown()
  if tooltip then
    local frame = tooltip:frame()
    return frame and frame:IsShown()
  end
  return false
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
  Addon.registerModule("petTooltips", {"tooltip", "constants", "petUtils"}, function()
    tooltip = Addon.tooltip
    constants = Addon.constants
    petUtils = Addon.petUtils
    return true
  end)
end

Addon.petTooltips = petTooltips
return petTooltips