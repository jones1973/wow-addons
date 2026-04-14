--[[
  ui/petList/petList.lua
  Pet List Section Coordinator
  
  Coordinates the left side listing section including:
  - filterSection: Filter box, chips, info panel
  - listingSection: Scrollable pet list
  - rarityBar: Rarity filter bar at bottom
  
  This module creates the container frame and routes events between children.
  Children communicate via events, not direct calls.
  
  Event subscriptions:
  - FILTER:TEXT_CHANGED -> triggers listing refresh
  - FILTER:HEIGHT_CHANGED -> adjusts listing top offset
  - PETLIST:RARITY_STATS -> updates rarity bar
  
  Dependencies: utils, constants, events, filterSection, listingSection, rarityBar
  Exports: Addon.petList
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in petList.lua.|r")
    return {}
end

local utils = Addon.utils
local constants, events
local filterSection, listingSection, rarityBar

local petList = {}

-- UI elements
local petListFrame = nil

-- State
local currentSortType = nil
local currentSortDir = "asc"
local currentSelectedPetID = nil
local onPetSelectedCallback = nil

--[[
  Get base collection filter from headerBar
  @return boolean|nil - true=owned, false=unowned, nil=all
]]
local function getBaseCollectionFilter()
    local headerBar = Addon.headerBar
    if headerBar then
        local collectionState = headerBar:getCollectionFilter()
        if collectionState == "owned" then
            return true
        elseif collectionState == "unowned" then
            return false
        end
    end
    return nil
end

--[[
  Trigger a list refresh with current settings
  @param filterText string|nil - Filter text (fetched from filterSection if nil)
]]
local function triggerRefresh(filterText)
    if not listingSection then return end
    
    local effectiveFilterText = filterText
    if effectiveFilterText == nil and filterSection then
        effectiveFilterText = filterSection:getFilterText()
    end
    
    listingSection:refresh(currentSortType, effectiveFilterText, currentSelectedPetID, currentSortDir, getBaseCollectionFilter())
end

--[[
  Handle filter text changed event
  Triggers a listing refresh with the new filter.
  
  @param eventName string
  @param payload table - {filterText, categories}
]]
local function onFilterTextChanged(eventName, payload)
    local filterText = payload and payload.filterText or ""
    triggerRefresh(filterText)
end

--[[
  Handle sort changed event
  Updates sort settings and refreshes list.
  
  @param eventName string
  @param payload table - {sort, direction}
]]
local function onSortChanged(eventName, payload)
    if payload then
        currentSortType = payload.sort or currentSortType
        currentSortDir = payload.direction or currentSortDir
    end
    triggerRefresh(nil)
end

--[[
  Handle collection filter changed event
  Refreshes list with new collection filter.
  
  @param eventName string
  @param payload table - {filter}
]]
local function onCollectionChanged(eventName, payload)
    triggerRefresh(nil)
end

--[[
  Handle filter height changed event
  Adjusts listing section top offset.
  
  @param eventName string
  @param payload table - {totalHeight, chipsHeight, panelHeight}
]]
local function onFilterHeightChanged(eventName, payload)
    if not listingSection then return end
    local L = constants.LAYOUT
    local filterHeight = payload and payload.totalHeight or 0
    -- Add inner padding at top and section gap below filter
    local totalOffset = (L and L.INNER_PADDING or 8) + filterHeight + (L and L.SECTION_GAP or 8)
    listingSection:setTopOffset(totalOffset)
end

--[[
  Handle rarity stats updated event
  Updates rarity bar with new counts.
  
  @param eventName string
  @param payload table - {stats, petCount}
]]
local function onRarityStatsUpdated(eventName, payload)
    if not rarityBar then return end
    if payload and payload.stats then
        rarityBar:update(payload.stats)
    end
end

--[[
  Handle pet selection
  Updates state and forwards to callback.
  
  @param petData table
  @param petID string
  @param matchContext table
]]
local function handlePetSelected(petData, petID, matchContext)
    currentSelectedPetID = petID
    if onPetSelectedCallback then
        onPetSelectedCallback(petData, petID, matchContext)
    end
end

--[[
  Create main pet list frame
  Builds the container frame with background.
  
  @param parent frame - Parent frame to attach to
  @param bounds table - Layout bounds with positioning info
]]
function petList:createFrame(parent, bounds)
    if not parent or not bounds then return end
    
    local L = constants.LAYOUT
    local listWidth = constants.LIST_WIDTH
    local edgePad = bounds.edgePadding ~= nil and bounds.edgePadding or L.EDGE_PADDING
    local contentTop = bounds.contentTop or -L.CONTENT_TOP
    
    -- Main container frame
    petListFrame = CreateFrame("Frame", nil, parent)
    petListFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", edgePad, contentTop)
    petListFrame:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", edgePad, edgePad)
    petListFrame:SetWidth(listWidth)
    
    -- Background covers entire section
    local bg = petListFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(L.SECTION_BG_COLOR))
    
    -- Initialize filter section
    if filterSection then
        filterSection:initialize(petListFrame, listWidth)
    end
    
    -- Create listing section
    if listingSection then
        listingSection:create(petListFrame, listWidth, handlePetSelected)
        -- Set top offset to account for filter section
        local filterHeight = 26
        local topOffset = (bounds.innerPadding or L.INNER_PADDING) + filterHeight + L.SECTION_GAP
        listingSection:setTopOffset(topOffset)
        -- Set bottom offset to account for rarity bar
        local rarityBarHeight = constants.RARITY_BAR_HEIGHT or 12
        listingSection:setBottomOffset(rarityBarHeight + 8)
    end
    
    -- Initialize rarity bar at bottom
    if rarityBar then
        rarityBar:initialize(petListFrame, function(newFilterText)
            petList:setFilterTextAndChips(newFilterText)
        end)
    end
    
    -- Subscribe to child events
    if events then
        events:subscribe("FILTER:TEXT_CHANGED", onFilterTextChanged)
        events:subscribe("FILTER:HEIGHT_CHANGED", onFilterHeightChanged)
        events:subscribe("PETLIST:RARITY_STATS", onRarityStatsUpdated)
        events:subscribe("HEADER:SORT_CHANGED", onSortChanged)
        events:subscribe("HEADER:COLLECTION_CHANGED", onCollectionChanged)
    end
end

--[[
  Refresh pet list display
  
  @param sortType string - Primary sort field
  @param filterText string - Filter text
  @param selectedPetID string - Currently selected pet's petID
  @param sortDir string - Sort direction
  @param baseCollectionFilter boolean|nil - Base owned filter from headerBar (true=owned, false=unowned, nil=all)
]]
function petList:refresh(sortType, filterText, selectedPetID, sortDir, baseCollectionFilter)
    currentSortType = sortType or currentSortType
    currentSortDir = sortDir or currentSortDir
    currentSelectedPetID = selectedPetID or currentSelectedPetID
    
    -- Get filter text from filterSection if not provided
    local effectiveFilterText = filterText
    if effectiveFilterText == nil and filterSection then
        effectiveFilterText = filterSection:getFilterText()
    end
    
    if listingSection then
        listingSection:refresh(currentSortType, effectiveFilterText, currentSelectedPetID, currentSortDir, baseCollectionFilter)
    end
end

--[[
  Update selection highlighting
  
  @param selectedPetID string - PetID of selected pet
]]
function petList:updateSelection(selectedPetID)
    currentSelectedPetID = selectedPetID
    if listingSection then
        listingSection:updateSelection(selectedPetID)
    end
end

--[[
  Set filter text and trigger update
  
  @param text string - New filter text
]]
function petList:setFilterText(text)
    if filterSection then
        filterSection:setFilterText(text)
    end
end

--[[
  Set filter text and trigger full update
  Single entry point for external filter updates.
  
  @param text string - New filter text
]]
function petList:setFilterTextAndChips(text)
    if filterSection then
        filterSection:setFilterText(text)
    end
end

--[[
  Get current filter text
  
  @return string
]]
function petList:getFilterText()
    if filterSection then
        return filterSection:getFilterText()
    end
    return ""
end

--[[
  Adjust scroll frame position for dynamic content
  Used for chips height changes.
  
  @param offset number - Vertical offset
]]
function petList:setTopOffset(offset)
    if listingSection then
        listingSection:setTopOffset(offset)
    end
end

--[[
  Handle window resize
]]
function petList:onResize()
    if listingSection then
        listingSection:onResize()
    end
end

--[[
  Pet operation handlers
  Called by dialogs after pet operations.
]]
function petList:onPetRenamed(petData)
    if Addon.petCache then
        Addon.petCache:updatePet(petData.petID)
    end
    if events then
        events:emit("COLLECTION:PET_RENAMED", {
            petID = petData.petID,
            speciesID = petData.speciesID,
            timestamp = time()
        })
    end
end

function petList:onPetReleased(petData)
    if Addon.petCache then
        Addon.petCache:removePet(petData.petID)
    end
    if events then
        events:emit("COLLECTION:PET_RELEASED", {
            petID = petData.petID,
            speciesID = petData.speciesID,
            timestamp = time()
        })
    end
end

function petList:onPetCaged(petData)
    if Addon.petCache then
        Addon.petCache:removePet(petData.petID)
    end
    if events then
        events:emit("COLLECTION:PET_CAGED", {
            petID = petData.petID,
            speciesID = petData.speciesID,
            timestamp = time()
        })
    end
end

function petList:onPetFavorited(petData, isFavorite)
    if Addon.petCache then
        Addon.petCache:updatePet(petData.petID)
    end
    if events then
        events:emit("COLLECTION:PET_FAVORITED", {
            petID = petData.petID,
            speciesID = petData.speciesID,
            isFavorite = isFavorite,
            timestamp = time()
        })
    end
end

--[[
  Initialize pet list module
  
  @param parentFrame frame - Parent frame
  @param callback function - Selection callback
  @param bounds table - Layout bounds
]]
function petList:initialize(parentFrame, callback, bounds)
    if petListFrame then return end
    
    constants = Addon.constants
    events = Addon.events
    filterSection = Addon.filterSection
    listingSection = Addon.listingSection
    rarityBar = Addon.rarityBar
    
    if not constants then
        utils:error("petList: constants not available")
        return
    end
    
    onPetSelectedCallback = callback
    petList:createFrame(parentFrame, bounds)
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("petList", {"utils", "constants", "events", "filterSection", "listingSection", "rarityBar"}, function()
        return true
    end)
end

Addon.petList = petList
return petList