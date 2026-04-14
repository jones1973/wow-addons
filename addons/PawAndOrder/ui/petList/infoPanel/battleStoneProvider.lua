--[[
  ui/infoPanel/battleStoneProvider.lua
  Info Panel Provider - Battle Stone Availability
  
  Displays helpful messages when the upgradeable filter is active but returns no results.
  Explains why there are no upgradeable pets (no stones, no matching stones, or no eligible pets).
  
  Messages:
  - "You have no battle-stones in your bags"
  - "You have no battle-stones matching your family filter"
  - "You have no pets that can be upgraded with your battle-stones"
  
  Dependencies: utils, infoPanel, petUtils
  Exports: Registered with infoPanel
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in battleStoneProvider.lua.|r")
    return
end

local utils = Addon.utils
local uiUtils = Addon.uiUtils
local infoPanel, petUtils

local battleStoneProvider = {}

--[[
  Check if player has any battle stones in bags
  Scans all bags for any type of battle stone (universal or family-specific)
  
  @return boolean - True if player has at least one battle stone
]]
local function hasAnyBattleStones()
    if not petUtils then return false end
    
    -- Check for any battle stone by scanning with nil family (universal check)
    -- We'll scan for both polished (rarity 1) and flawless (rarity 2)
    for rarity = 1, 2 do
        for family = 0, 10 do
            local stones = petUtils:scanBattleStones(family, rarity)
            if stones and #stones > 0 then
                return true
            end
        end
    end
    
    return false
end

--[[
  Check if player has battle stones matching the specified family
  
  @param familyFilter number - Pet family ID (1-10)
  @return boolean - True if player has stones for this family
]]
local function hasStonesForFamily(familyFilter)
    if not petUtils or not familyFilter then return false end
    
    -- Check for stones that work on this family (family-specific or universal)
    for rarity = 1, 2 do
        local stones = petUtils:scanBattleStones(familyFilter, rarity)
        if stones and #stones > 0 then
            return true
        end
    end
    
    return false
end

--[[
  Check if player has any pets that can be upgraded with their available stones
  Considers all owned pets below rare quality
  
  @return boolean - True if at least one pet can be upgraded
]]
local function hasUpgradeablePets()
    if not petUtils or not Addon.petUtils then return false end
    
    local pets = petUtils:getAllPetData()
    if not pets then return false end
    
    for _, pet in ipairs(pets) do
        if pet.owned and pet.rarity and pet.rarity < 4 then
            local stones = petUtils:scanBattleStones(pet.petType, pet.rarity)
            if stones and #stones > 0 then
                return true
            end
        end
    end
    
    return false
end

--[[
  Evaluate filter state for battle stone messages
  Shows info panel when upgradeable filter is active but returns no results
  
  @param filterText string - Raw filter text
  @param filterCategories table - Parsed filter categories
  @return boolean - True if should show panel
  @return table - Content data with message type
]]
local function evaluate(filterText, filterCategories)
    if not filterCategories or not filterCategories.upgradeable then
        -- Upgradeable filter not active - don't show panel
        return false, nil
    end
    
    -- Upgradeable filter is active - determine why there are no results
    local hasStones = hasAnyBattleStones()
    
    if not hasStones then
        -- Message 1: No battle stones at all
        return true, {
            messageType = "no_stones"
        }
    end
    
    -- Player has stones - check if family filter is limiting results
    if filterCategories.types and #filterCategories.types > 0 then
        -- Family filter is active - check if stones match
        local familyFilter = filterCategories.types[1]  -- Use first family filter
        if not hasStonesForFamily(familyFilter) then
            -- Message 2: No stones matching family filter
            return true, {
                messageType = "no_matching_stones",
                family = familyFilter
            }
        end
    end
    
    -- Player has stones, and they match any family filter - check for upgradeable pets
    if not hasUpgradeablePets() then
        -- Message 3: No pets that can use the stones
        return true, {
            messageType = "no_upgradeable_pets"
        }
    end
    
    -- All checks passed - don't show panel
    return false, nil
end

--[[
  Render battle stone info message
  
  @param container frame - Content container
  @param contentData table - Data from evaluate
  @param yOffset number - Y position
  @return number - Height used
]]
local function render(container, contentData, yOffset)
    if not contentData or not contentData.messageType then return 0 end
    
    -- Create info icon
    -- Create message text
    local text = uiUtils:createWrappedText(container, yOffset, true)
    
    -- Set message based on type
    local message
    if contentData.messageType == "no_stones" then
        message = "No upgradeable pets found: You have no battle-stones in your bags."
    elseif contentData.messageType == "no_matching_stones" then
        local familyName = Addon.constants and Addon.constants.PET_FAMILY_NAMES[contentData.family] or "this family"
        message = string.format("No upgradeable pets found: You have no battle-stones for %s pets.", familyName)
    elseif contentData.messageType == "no_upgradeable_pets" then
        message = "No upgradeable pets found: All your below-rare pets require battle-stones you don't have."
    else
        message = "No upgradeable pets found."
    end
    
    text:SetText(message)
    text:SetTextColor(0.9, 0.9, 0.9)
    
    -- Calculate height used
    local textHeight = text:GetStringHeight()
    local totalHeight = math.max(textHeight, infoPanel.LINE_HEIGHT)
    
    return totalHeight
end

--[[
  Initialize and register provider
]]
local function initialize()
    if not Addon.infoPanel then
        utils:error("battleStoneProvider: infoPanel not available")
        return false
    end
    
    if not Addon.petUtils then
        utils:error("battleStoneProvider: petUtils not available")
        return false
    end
    
    infoPanel = Addon.infoPanel
    petUtils = Addon.petUtils
    
    infoPanel:registerProvider({
        id = "battleStone",
        priority = 90,  -- Slightly lower priority than conflicts
        evaluate = evaluate,
        render = render
    })
    
    return true
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("battleStoneProvider", {"utils", "infoPanel", "petUtils"}, initialize)
end

battleStoneProvider.initialize = initialize
Addon.battleStoneProvider = battleStoneProvider
return battleStoneProvider