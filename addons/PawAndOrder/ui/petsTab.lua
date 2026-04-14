--[[
  ui/petsTab.lua
  Pets Tab Content
  
  Manages the pet collection tab content:
    - Creates wrapper frame containing headerBar, petList, petDetails
    - Registers "pets" tab with tabs system
    - Handles pet selection, filtering, and sorting
    - Coordinates child components
  
  All pet collection UI is contained within this tab's wrapper frame.
  Tab switching is handled by the tabs system showing/hiding this frame.
  
  Dependencies: constants, utils, events, tabs, petList, petDetails, 
                petSorting, petUtils, petFilters, headerBar
  Exports: Addon.petsTab
]]

local ADDON_NAME, Addon = ...

local petsTab = {}

-- Module references (resolved at init)
local constants, utils, events, tabs
local petList, petDetails, petUtils
local headerBar

-- UI elements
local wrapperFrame = nil

-- Session state
local filterText = ""
local selectedPetID = nil
local firstShow = true
local lastDisplayMode = nil  -- Track mode changes across re-opens

-- Species mode uses a wider list to accommodate badges + pips
local SPECIES_LIST_EXTRA_WIDTH = 29

--[[
  Get current list width based on display mode.
  Species mode adds extra width for badge column and pip strip.
  @return number - List panel width in pixels
]]
local function getListWidth()
    local displayMode = Addon.options and Addon.options:Get("displayMode") or "pets"
    if displayMode == "species" then
        return constants.LIST_WIDTH + SPECIES_LIST_EXTRA_WIDTH
    end
    return constants.LIST_WIDTH
end

-- ============================================================================
-- CONTENT CREATION
-- ============================================================================

--[[
  Create the pets tab content.
  Called by tabs system during initializeContent.
  
  @param contentArea frame - Parent frame from tabs system
  @return frame - The wrapper frame containing all pets content
]]
local function createContent(contentArea)
    if wrapperFrame then return wrapperFrame end
    
    -- Create wrapper frame that fills content area
    wrapperFrame = CreateFrame("Frame", ADDON_NAME .. "PetsContent", contentArea)
    wrapperFrame:SetAllPoints(contentArea)
    
    -- Calculate layout dimensions
    local L = constants.LAYOUT
    local listWidth = getListWidth()
    
    -- Header bar (sort/collection dropdowns, pet count, heal/random buttons)
    -- Positioned at top of wrapper, no edge padding (wrapper handles it)
    -- Note: detailWidth set to 0 initially, updated via TABS:CONTENT_SHOWN event
    local headerTop = 0
    headerBar:initialize(wrapperFrame, listWidth, 0, headerTop, 0)
    
    -- Content positioning - listing extends up (no gap), detail keeps gap
    local listingContentTop = headerTop - L.HEADER_HEIGHT  -- Listing extends up
    local detailContentTop = headerTop - L.HEADER_HEIGHT - 4  -- Detail keeps 4px gap
    
    -- Pet list (filter box, chips, scroll list)
    local listBounds = {
        contentTop = listingContentTop,
        edgePadding = 0,  -- No additional edge padding, wrapper handles it
        innerPadding = L.INNER_PADDING,
        sectionGap = L.SECTION_GAP,
    }
    
    petList:initialize(wrapperFrame, function(petData, petID, matchContext)
        selectedPetID = petID
        petDetails:showPetDetail(petData, matchContext)
        petList:updateSelection(petID)
    end, listBounds)
    
    -- Details panel
    local detailBounds = {
        contentTop = detailContentTop,
        edgePadding = 0,
        sectionGap = L.SECTION_GAP,
    }
    petDetails:initialize(wrapperFrame, detailBounds)
    
    -- ========================================================================
    -- Event subscriptions
    -- ========================================================================
    
    -- Note: HEADER:SORT_CHANGED and HEADER:COLLECTION_CHANGED are handled by petList
    -- which correctly fetches filter text from filterSection
    
    -- Collection changes
    local function refreshOnCollectionChange(eventName, payload)
        petsTab:refreshPetList()
    end
    
    events:subscribe("COLLECTION:PET_RENAMED", refreshOnCollectionChange)
    -- Note: PET_RELEASED handled surgically by listingSection (removePet)
    events:subscribe("COLLECTION:PET_FAVORITED", refreshOnCollectionChange)
    events:subscribe("COLLECTION:UPDATED", refreshOnCollectionChange)
    
    -- Cage refresh: CagePetByID fires COLLECTION:PET_CAGED before the cage
    -- item appears in bags. We snapshot the caged pet count, then on each
    -- BAG_UPDATE check if a new cage arrived (count increased). petUtils
    -- invalidates its scan cache on BAG_UPDATE (subscribed earlier in init
    -- order), so our handler always gets a fresh scan.
    local pendingCageRefresh = false
    local preCageScanCount = 0
    
    events:subscribe("COLLECTION:PET_CAGED", function()
        local current = Addon.petUtils and Addon.petUtils:scanCagedPets() or {}
        preCageScanCount = #current
        pendingCageRefresh = true
    end)
    
    events:subscribe("BAG_UPDATE", function()
        if not pendingCageRefresh then return end
        local caged = Addon.petUtils and Addon.petUtils:scanCagedPets() or {}
        if #caged > preCageScanCount then
            pendingCageRefresh = false
            petsTab:refreshPetList()
        end
    end)
    
    -- PET_JOURNAL_PET_DELETED fires for cage/release via Blizzard UI.
    -- For PAO-initiated cages, BAG_UPDATE handles the refresh above.
    -- For Blizzard-UI operations where we don't get COLLECTION:PET_CAGED,
    -- this is the only signal — defer slightly so bags settle.
    events:subscribe("PET_JOURNAL_PET_DELETED", function()
        if not pendingCageRefresh then
            C_Timer.After(0.3, function()
                petsTab:refreshPetList()
            end)
        end
    end)
    
    -- Display mode changed (from toggle button or options panel)
    events:subscribe("SETTING:LISTING_CHANGED", function(eventName, payload)
        if not payload or payload.name ~= "displayMode" then return end
        if not wrapperFrame or not wrapperFrame:IsVisible() then return end
        lastDisplayMode = payload.newValue
        -- Recalculate widths for the new mode then refresh
        petsTab:onResize(wrapperFrame:GetWidth(), wrapperFrame:GetHeight())
        petsTab:refreshPetList()
        -- Scroll to show the selected pet in the new mode
        if selectedPetID and Addon.listingSection then
            Addon.listingSection:ensureSelectedVisible()
        end
    end)
    
    -- Listen for summoned pet changes (rarity upgrades from battle stones)
    events:subscribe("UPDATE_SUMMONPETS_ACTION", function(eventName)
        local summonedGUID = C_PetJournal.GetSummonedPetGUID()
        if not summonedGUID or not petUtils then return end
        
        -- Get current stats from API
        local _, _, _, _, newRarity = C_PetJournal.GetPetStats(summonedGUID)
        if not newRarity then return end
        
        -- Find pet in cache
        local cachedPets = petUtils:getAllPetData()
        if not cachedPets then return end
        
        for _, pet in ipairs(cachedPets) do
            if pet.petID == summonedGUID and pet.owned then
                -- Check if rarity changed
                if pet.rarity ~= newRarity then
                    -- Fire internal event (cache will update via event system)
                    events:emit("COLLECTION:UPDATED", {
                        source = "rarity_change",
                        petID = summonedGUID,
                        oldRarity = pet.rarity,
                        newRarity = newRarity,
                        timestamp = time()
                    })
                end
                break
            end
        end
    end)
    
    -- Window resize
    events:subscribe("MAINFRAME:RESIZED", function(eventName, payload)
        petsTab:onResize(payload.width, payload.height)
    end)
    
    -- Tab selected (immediate) - for non-layout-dependent setup
    events:subscribe("TABS:SELECTED", function(eventName, payload)
        if payload.id ~= "pets" then return end
        
        -- Apply defaults on first show
        if firstShow then
            local opts = Addon.options and Addon.options.GetAll and Addon.options:GetAll() or nil
            if headerBar then
                headerBar:applyDefaults(opts)
            end
            
            -- Sync filter to petList
            if petList and petList.setFilterTextAndChips then
                petList:setFilterTextAndChips(filterText or "")
            else
                petsTab:refreshPetList()
            end
            
            firstShow = false
            lastDisplayMode = Addon.options and Addon.options:Get("displayMode") or "pets"
        end
    end)
    
    -- Tab content shown (deferred) - for layout-dependent operations
    events:subscribe("TABS:CONTENT_SHOWN", function(eventName, payload)
        if payload.id ~= "pets" then return end
        if not wrapperFrame then return end
        
        -- Detect display mode change (e.g. user changed setting while PAO was closed)
        local currentMode = Addon.options and Addon.options:Get("displayMode") or "pets"
        local modeChanged = (lastDisplayMode ~= nil and lastDisplayMode ~= currentMode)
        lastDisplayMode = currentMode
        
        -- Now frame is laid out, trigger resize chain
        local width = wrapperFrame:GetWidth()
        
        if width and width > 0 then
            local currentListWidth = getListWidth()
            local detailWidth = width - currentListWidth - L.SECTION_GAP
            
            -- Update header bar widths
            if headerBar and headerBar.onResize then
                headerBar:onResize(currentListWidth, detailWidth)
            end
            
            -- Update pet details (triggers teamSection:update)
            if petDetails and petDetails.onResize then
                petDetails:onResize(detailWidth)
            end
            
            -- Update pet list
            if petList and petList.onResize then
                petList:onResize()
            end
        end
        
        -- Refresh after resize so the new mode renders with correct dimensions
        if modeChanged then
            petsTab:refreshPetList()
        end
    end)
    
    return wrapperFrame
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Refresh pet list display.
  Triggers pet list to re-render with current sort, filter, and selection.
]]
function petsTab:refreshPetList()
    if not petList then return end
    
    local currentSort, currentSortDir = "name", "asc"
    if headerBar then
        currentSort, currentSortDir = headerBar:getSort()
    end
    
    -- Get base collection filter from headerBar
    local baseCollectionFilter = nil
    if headerBar then
        local collectionState = headerBar:getCollectionFilter()
        if collectionState == "owned" then
            baseCollectionFilter = true
        elseif collectionState == "unowned" then
            baseCollectionFilter = false
        end
    end
    
    -- Get current filter text from petList (authoritative source)
    local currentFilterText = petList:getFilterText()
    
    petList:refresh(currentSort, currentFilterText, selectedPetID, currentSortDir, baseCollectionFilter)
end

--[[
  Set filter text and trigger full update.
  
  @param text string - New filter text
]]
function petsTab:setFilterTextAndChips(text)
    filterText = text or ""
    if petList and petList.setFilterTextAndChips then
        petList:setFilterTextAndChips(filterText)
    end
    -- Ensure refresh uses current headerBar sort settings
    self:refreshPetList()
end

--[[
  Get current filter text.
  @return string
]]
function petsTab:getFilterText()
    if petList and petList.getFilterText then
        return petList:getFilterText()
    end
    return filterText or ""
end

--[[
  Handle resize.
  @param width number - Window width
  @param height number - Window height
]]
function petsTab:onResize(width, height)
    if not wrapperFrame or not wrapperFrame:IsVisible() then return end
    
    local L = constants.LAYOUT
    local listWidth = getListWidth()
    local detailWidth = wrapperFrame:GetWidth() - listWidth - L.SECTION_GAP
    
    -- Notify header bar of resize
    if headerBar and headerBar.onResize then
        headerBar:onResize(listWidth, detailWidth)
    end
    
    if petList and petList.onResize then
        petList:onResize()
    end
    
    if petDetails and petDetails.onResize then
        petDetails:onResize(detailWidth)
    end
end

--[[
  Get wrapper frame.
  @return frame|nil
]]
function petsTab:getFrame()
    return wrapperFrame
end

-- ============================================================================
-- TAB REGISTRATION
-- ============================================================================

--[[
  Register the pets tab with the tabs system.
]]
local function registerTab()
    if not tabs then
        if utils then utils:error("petsTab: tabs system not available") end
        return
    end
    
    tabs:register({
        id = "pets",
        name = "Pets",
        icon = 132599,  -- PetJournalPortrait icon
        order = 10,
        default = true,
        createContent = createContent,
    })
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

--[[
  Initialize the pets tab module.
  @return boolean
]]
function petsTab:initialize()
    -- Load module dependencies
    constants = Addon.constants
    utils = Addon.utils
    events = Addon.events
    tabs = Addon.tabs
    petList = Addon.petList
    petDetails = Addon.petDetails
    petUtils = Addon.petUtils
    headerBar = Addon.headerBar
    
    if not constants then
        print("|cff33ff99PAO|r: |cffff4444Error - petsTab: constants not available|r")
        return false
    end
    
    if not tabs then
        print("|cff33ff99PAO|r: |cffff4444Error - petsTab: tabs system not available|r")
        return false
    end
    
    -- Register the tab (content created later by tabs:initializeContent)
    registerTab()
    
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("petsTab", {
        "constants", "utils", "events", "tabs",
        "petList", "petDetails", "petSorting", "petUtils", "petFilters",
        "headerBar", "familyUtils", "counterProvider"
    }, function()
        return petsTab:initialize()
    end)
end

Addon.petsTab = petsTab
return petsTab