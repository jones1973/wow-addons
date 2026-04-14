--[[
  logic/abilities/abilityTooltips.lua
  Ability Tooltip Formatting

  Centralizes ability tooltip formatting using the tooltip API
  for pixel-perfect spacing control:
  - Title with family icon
  - Duration/Cooldown/Hit Chance metadata (3px spacing)
  - Description (3px spacing)
  - Strong/Weak indicators

  Dependencies: constants, tooltipParser, tooltip
  Exports: Addon.abilityTooltips
]]

local ADDON_NAME, Addon = ...

local abilityTooltips = {}

-- Dependency checks
if not Addon.constants then
  print("|cff33ff99PAO|r: |cffff4444Error - Addon.constants not available in abilityTooltips.lua|r")
  return {}
end

if not Addon.tooltipParser then
  print("|cff33ff99PAO|r: |cffff4444Error - Addon.tooltipParser not available in abilityTooltips.lua|r")
  return {}
end

-- Strong matchup table (ability family -> target family it's strong against)
local STRONG_VS = {
  [1] = 2,   -- Humanoid > Dragonkin
  [2] = 6,   -- Dragonkin > Magic
  [3] = 9,   -- Flying > Aquatic
  [4] = 1,   -- Undead > Humanoid
  [5] = 4,   -- Critter > Undead
  [6] = 3,   -- Magic > Flying
  [7] = 10,  -- Elemental > Mechanical
  [8] = 5,   -- Beast > Critter
  [9] = 7,   -- Aquatic > Elemental
  [10] = 8   -- Mechanical > Beast
}

-- Weak matchup table (ability family -> target family it's weak against)
local WEAK_VS = {
  [1] = 8,   -- Humanoid < Beast
  [2] = 4,   -- Dragonkin < Undead
  [3] = 2,   -- Flying < Dragonkin
  [4] = 5,   -- Undead < Critter
  [5] = 8,   -- Critter < Beast
  [6] = 2,   -- Magic < Dragonkin
  [7] = 9,   -- Elemental < Aquatic
  [8] = 10,  -- Beast < Mechanical
  [9] = 3,   -- Aquatic < Flying
  [10] = 7   -- Mechanical < Elemental
}

-- Layout constants
local SPACING_AFTER_TITLE = 3
local SPACING_AFTER_METADATA = 3
local SPACING_AFTER_DESCRIPTION = 8
local ICON_SIZE = 32
local ICON_PADDING = 6

-- Colors
local COLOR_WHITE = {1, 1, 1}
local COLOR_LAVENDER = {0.88, 0.82, 1.0}
local COLOR_YELLOW = {1, 1, 0}

--[[
  Show ability tooltip with standard formatting.
  Sets up owner, family icon, padding, title, and formats ability details.
  Caller should call tooltip:done() after adding any extra content.

  @param owner frame - Frame that owns the tooltip
  @param posOpts table|string - Position options table or legacy anchor string
  @param abilityID number - Ability ID to display
  @param petID string - Pet GUID (optional, for stat calculations; nil for caged/unowned)
  @param speciesID number - Species ID (optional, for stat calculations)
  @param petLevel number - Pet level (optional, for locked ability display)
  @return boolean - True if tooltip was shown successfully
]]
function abilityTooltips:show(owner, posOpts, abilityID, petID, speciesID, petLevel)
  if not abilityID then return false end

  local tip = Addon.tooltip
  if not tip then return false end

  local id, name, icon, maxCooldown, desc, numTurns, petType =
    C_PetBattles.GetAbilityInfoByID(abilityID)

  if not name then return false end

  tip:show(owner, posOpts)

  -- Title
  tip:header(name)

  -- Set up family type icon in top-right corner
  if petType and PET_TYPE_SUFFIX and PET_TYPE_SUFFIX[petType] then
    local abilityIcon = tip:texture("abilityFamilyIcon")
    local frame = tip:frame()

    abilityIcon:ClearAllPoints()
    abilityIcon:SetSize(ICON_SIZE, ICON_SIZE)
    abilityIcon:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[petType])
    abilityIcon:SetTexCoord(0.796875, 0.492188, 0.503906, 0.65625)
    abilityIcon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -ICON_PADDING, -ICON_PADDING)
    abilityIcon:Show()

    tip:minWidth(200)
  end

  -- Format ability details (metadata, description, strong/weak)
  self:format(abilityID, petID, speciesID, petLevel)

  return true
end

--[[
  Format ability tooltip content below the title.
  Uses sequential API for pixel-perfect spacing.

  @param abilityID number - Ability ID
  @param petID string - Pet ID for parsing context (nil for caged/unowned)
  @param speciesID number - Species ID for parsing context (can be nil)
  @param petLevel number - Pet level (nil treated as 0, same as unowned view)
]]
function abilityTooltips:format(abilityID, petID, speciesID, petLevel)
  if not abilityID then return end

  local tip = Addon.tooltip
  if not tip then return end

  -- Get ability info from API (noStrongWeakHints = true for non-damaging abilities)
  local id, name, icon, maxCooldown, unparsedDesc, numTurns, petType, noStrongWeakHints =
    C_PetBattles.GetAbilityInfoByID(abilityID)

  if not name then return end

  -- Parse description to extract hit chance.
  -- tooltipParser:createAbilityInfo handles nil petID (unowned species view) by
  -- using default stats. No bifurcation needed.
  local parsedDesc = ""
  local hitChance = nil

  if unparsedDesc and unparsedDesc ~= "" then
    local tooltipParser = Addon.tooltipParser
    if tooltipParser then
      local abilityInfo = tooltipParser:createAbilityInfo(abilityID, petID, speciesID)
      parsedDesc = tooltipParser:parseText(abilityInfo, unparsedDesc)

      -- Extract hit chance from first line if present
      if parsedDesc and parsedDesc ~= "" then
        local firstLine = parsedDesc:match("^([^\n]+)")
        if firstLine then
          local uiUtils = Addon.uiUtils
          local cleanFirstLine = uiUtils and uiUtils:stripColorCodes(firstLine) or firstLine

          if cleanFirstLine:match("^%d+%%") or cleanFirstLine:match("^High ") or cleanFirstLine:match("^Low ") then
            hitChance = cleanFirstLine
            parsedDesc = parsedDesc:gsub("^[^\n]+[\r\n]*", "", 1)
            parsedDesc = parsedDesc:gsub("^[\r\n%s]+", "")
          end
        end
      end
    end
  end

  -- Space after title
  tip:space(SPACING_AFTER_TITLE)

  -- "Learned at level X" for abilities not yet unlocked by this pet.
  -- petLevel defaults to 0 when petID is nil (unowned species view), so all
  -- locked abilities correctly show their unlock requirement.
  -- Treated as a metadata line: no extra space after it. It flows directly into
  -- cooldown/duration/hit chance. The post-metadata space separates all of them
  -- from the description.
  local hasMetadata = false

  if speciesID then
    local abilityUtils = Addon.abilityUtils
    if abilityUtils then
      local abilityList = C_PetJournal.GetPetAbilityList(speciesID)
      if abilityList then
        for idx, listAbilityID in ipairs(abilityList) do
          if listAbilityID == abilityID then
            local levelReq = abilityUtils:getLevelRequirement(idx)
            -- petLevel is passed from the caller; nil means unowned/unknown (treat as 0)
            -- so all locked abilities correctly show their unlock requirement.
            local level = petLevel or 0
            if level < levelReq then
              tip:text("Learned at level " .. levelReq, {color = COLOR_YELLOW})
              tip:space(SPACING_AFTER_TITLE + SPACING_AFTER_METADATA)
              hasMetadata = true
            end
            break
          end
        end
      end
    end
  end

  -- Duration info (e.g., "3 Round Ability")
  if numTurns and numTurns > 1 then
    local roundText = numTurns == 1 and "Round" or "Rounds"
    tip:text(numTurns .. " " .. roundText .. " Ability", {color = COLOR_LAVENDER})
    hasMetadata = true
  end

  -- Cooldown (e.g., "4 Round Cooldown")
  if maxCooldown and maxCooldown > 0 then
    local roundText = maxCooldown == 1 and "Round" or "Rounds"
    tip:text(maxCooldown .. " " .. roundText .. " Cooldown", {color = COLOR_LAVENDER})
    hasMetadata = true
  end

  -- Hit chance
  if hitChance then
    local percentage = hitChance:match("^(%d+)%%")
    if percentage then
      tip:text(percentage .. "% Hit Chance", {color = COLOR_LAVENDER})
    else
      -- Handle "High" or "Low" accuracy without percentage
      tip:text(hitChance, {color = COLOR_LAVENDER})
    end
    hasMetadata = true
  end

  -- Description
  if parsedDesc and parsedDesc ~= "" then
    -- Always add 3px before description
    tip:space(3)
    -- Additional 3px if metadata exists
    if hasMetadata then
      tip:space(SPACING_AFTER_METADATA)
    end
    tip:text(parsedDesc, {wrap = true})
  end

  -- Strong/Weak indicators - only show for damaging abilities
  -- noStrongWeakHints is true for non-damaging abilities (heals, buffs, etc.)
  if petType and not noStrongWeakHints then
    local hasMatchups = STRONG_VS[petType] or WEAK_VS[petType]

    if hasMatchups then
      tip:space(SPACING_AFTER_DESCRIPTION)

      if STRONG_VS[petType] then
        local familyName = Addon.constants.PET_FAMILY_NAMES[STRONG_VS[petType]] or "Unknown"
        local strongText = "|TInterface\\PetBattles\\BattleBar-AbilityBadge-Strong:20|t Vs. " .. familyName
        tip:text(strongText)
      end

      if WEAK_VS[petType] then
        local familyName = Addon.constants.PET_FAMILY_NAMES[WEAK_VS[petType]] or "Unknown"
        local weakText = "|TInterface\\PetBattles\\BattleBar-AbilityBadge-Weak:20|t Vs. " .. familyName
        tip:text(weakText)
      end
    end
  end
end

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("abilityTooltips", {"constants", "tooltipParser", "tooltip", "abilityUtils"}, function()
    return true
  end)
end

Addon.abilityTooltips = abilityTooltips
return abilityTooltips