--[[
  ui/petList/listingSection.lua
  Pet Listing Section Component
  
  Handles the scrollable pet list display:
  - Scroll frame with scrollbar
  - Pet buttons with icons, names, badges
  - Selection highlighting
  - Context menu for pet operations
  - Drag/drop support
  
  Emits events:
  - "PETLIST:FILTERED_COUNT" after render with filtered/base counts
  - "PETLIST:RARITY_STATS" after render with per-rarity counts
  
  Subscribes to events:
  - "COLLECTION:PET_RELEASED" - surgical removal
  - "CACHE:COLLECTION_CHANGED" - add (learn/swap) and remove (cage/release)
  - "CACHE:PET_UPDATED" - surgical single-pet update
  - "CACHE:INITIALIZED" - initial render when cache becomes available
  - "PETS:NEW_ACQUISITION" - re-render for recency glow
  
  Note: PET_RENAMED and PET_FAVORITED are coordinated by petsTab (full refresh).
  PET_CAGED triggers immediate removePet via CACHE:COLLECTION_CHANGED "removed",
  then petsTab waits for BAG_UPDATE (cage item arrived) before full refresh.
  
  Dependencies: utils, constants, events, petUtils, petFilters, petSorting,
                petRowButton, petGrouping, speciesRowButton, petChip
  Exports: Addon.listingSection
]]

local ADDON_NAME, Addon = ...

if not Addon.utils then
    print("|cff33ff99PAO|r: |cffff4444Error - Addon.utils not available in listingSection.lua.|r")
    return {}
end

local utils = Addon.utils
local constants, events, petUtils, petFilters, petSorting, petRowButton
local petGrouping, speciesRowButton, petChip

local listingSection = {}

-- UI elements
local listingSectionFrame = nil
local scrollFrame = nil
local scrollChild = nil
local petButtons = {}

-- State
local onPetSelectedCallback = nil
local lastFilterText = ""
local lastBaseCollectionFilter = nil
local storedTopOffset = 0
local storedBottomOffset = 0
local currentRarityStats = nil  -- Track for surgical updates
local currentVisibleCount = 0   -- Track visible button count

-- Callbacks for petRowButton
local rowCallbacks = nil

-- Species view state
local expandedSpecies = {}          -- {[speciesID] = true} for expanded species
local hasPerformedInitialSetup = false  -- Prevents auto-expand re-triggering
local speciesButtons = {}           -- Pool of speciesRowButton frames
local chipTrayFrames = {}           -- Pool of chip tray container frames
local chipPools = {}                -- chipPools[trayIndex] = array of chip frames
local currentSelectedPetID = nil    -- Unified selection across both display modes
local speciesCallbacks = nil        -- Callbacks for speciesRowButton
local chipCallbacks = nil           -- Callbacks for petChip

-- Cached state for surgical expand/collapse (avoids full refresh pipeline)
local cachedFiltered = nil          -- Last filtered pet array
local cachedSortType = nil          -- Last sort field
local cachedSortDir = nil           -- Last sort direction
local cachedCollectionStr = nil     -- Last collection filter string
local cachedShowNonCombat = nil     -- Last showNonCombat setting
local cachedFilterText = nil        -- Last filter text
local lastRenderedMode = nil        -- "pets" or "species" - detects stale mode renders
local pendingAnchor = nil           -- {mode, id, viewportY} for deferred viewport-anchored scroll

--[[
  Reposition scroll frame with current offsets
  Called by setTopOffset and setBottomOffset.
]]
local function repositionScrollFrame()
    if scrollFrame and listingSectionFrame then
        scrollFrame:ClearAllPoints()
        scrollFrame:SetPoint("TOPLEFT", listingSectionFrame, "TOPLEFT", 0, -storedTopOffset)
        scrollFrame:SetPoint("BOTTOMRIGHT", listingSectionFrame, "BOTTOMRIGHT", -18, storedBottomOffset)
    end
end

--[[
  Create button via petRowButton factory
  
  @return frame - Button frame
]]
local function createButton()
    return petRowButton:create(scrollChild, constants.LIST_ENTRY_HEIGHT, rowCallbacks)
end

--[[
  Update button via petRowButton factory
]]
local function updateButton(btn, petData, index, selectedPetID, matchContext)
    petRowButton:update(btn, petData, selectedPetID, matchContext)
    -- Positioning is our responsibility
    btn:ClearAllPoints()
    btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(index - 1) * constants.LIST_ENTRY_HEIGHT)
end


--[[
  Show context menu for pet
  Delegates to separate contextMenu module.
  
  @param button frame - Button clicked
  @param petData table - Pet data
]]
function listingSection:showContextMenu(button, petData)
    if Addon.petListContextMenu then
        Addon.petListContextMenu:show(petData)
    end
end

function listingSection:create(parent, width, onSelected)
    if listingSectionFrame then return listingSectionFrame end
    
    onPetSelectedCallback = onSelected
    
    -- Set up callbacks for petRowButton
    rowCallbacks = {
        onSelected = onPetSelectedCallback,
        onContextMenu = function(button, petData)
            listingSection:showContextMenu(button, petData)
        end
    }

    -- Set up callbacks for speciesRowButton
    speciesCallbacks = {
        onToggle = function(speciesID)
            listingSection:toggleSpecies(speciesID)
        end,
        onSelect = function(speciesID, entry)
            if entry.type == "species" and entry.pets and entry.pets[1] then
                -- Owned: expand (if not already), select best pet (petGrouping sorts best first)
                if not expandedSpecies[speciesID] then
                    listingSection:toggleSpecies(speciesID)
                end
                local bestPet = entry.pets[1]
                currentSelectedPetID = bestPet.petID
                if onPetSelectedCallback then
                    local matchCtx = petFilters and lastFilterText ~= "" and petFilters:getMatchContext(bestPet, lastFilterText) or nil
                    onPetSelectedCallback(bestPet, bestPet.petID, matchCtx)
                end
            elseif entry.type == "unowned" then
                -- Unowned: build species stub from entry data + API
                local name, icon, petType, _, sourceText, desc, _, canBattle, tradable, unique =
                    C_PetJournal.GetPetInfoBySpeciesID(speciesID)
                local stub = {
                    speciesID   = speciesID,
                    name        = entry.speciesName,
                    speciesName = entry.speciesName,
                    icon        = icon,
                    petType     = entry.familyType,
                    familyName  = entry.familyName,
                    description = desc,
                    sourceText  = sourceText,
                    canBattle   = canBattle,
                    tradable    = tradable,
                    unique      = unique,
                    owned       = false,
                    petID       = nil,
                }
                currentSelectedPetID = nil
                if onPetSelectedCallback then
                    onPetSelectedCallback(stub, nil, nil)
                end
            end
        end,
        onContextMenu = function(speciesID, btn, entryType)
            -- Species header context menu (placeholder for Phase 4+)
            if Addon.petListContextMenu and Addon.petListContextMenu.showSpecies then
                Addon.petListContextMenu:showSpecies(speciesID, entryType)
            end
        end,
    }

    -- Set up callbacks for petChip
    chipCallbacks = {
        onSelected = function(petData, petID)
            if not petData then return end
            currentSelectedPetID = petID
            if onPetSelectedCallback then
                local matchCtx = petFilters and lastFilterText ~= "" and petFilters:getMatchContext(petData, lastFilterText) or nil
                onPetSelectedCallback(petData, petID, matchCtx)
            end
        end,
        onContextMenu = function(petData, chip)
            if petData then
                listingSection:showContextMenu(chip, petData)
            end
        end,
    }
    
    listingSectionFrame = CreateFrame("Frame", nil, parent)
    listingSectionFrame:SetAllPoints()
    
    -- Scroll frame
    scrollFrame = CreateFrame("ScrollFrame", nil, listingSectionFrame)
    scrollFrame:SetPoint("TOPLEFT", listingSectionFrame, "TOPLEFT", 0, -storedTopOffset)
    scrollFrame:SetPoint("BOTTOMRIGHT", listingSectionFrame, "BOTTOMRIGHT", -18, storedBottomOffset)
    
    -- Scrollbar
    local scrollBar = CreateFrame("Slider", nil, scrollFrame)
    scrollBar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 18, 0)
    scrollBar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 18, 0)
    scrollBar:SetWidth(18)
    scrollBar:SetValueStep(1)
    scrollBar:SetMinMaxValues(0, 100)
    scrollBar:SetValue(0)
    scrollBar:EnableMouseWheel(true)
    
    local track = scrollBar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    track:SetColorTexture(0.15, 0.15, 0.15)
    track:SetAlpha(0.5)
    
    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(0.4, 0.4, 0.4)
    thumb:SetAlpha(0.7)
    thumb:SetWidth(16)
    scrollBar:SetThumbTexture(thumb)
    
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        local new = math.max(0, math.min(max, current - (delta * 40)))
        self:SetVerticalScroll(new)
        if max > 0 then
            scrollBar:SetValue((new / max) * 100)
        end
    end)
    
    scrollBar:SetScript("OnValueChanged", function(self, value)
        local max = scrollFrame:GetVerticalScrollRange()
        scrollFrame:SetVerticalScroll((value / 100) * max)
    end)
    
    scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetWidth(scrollFrame:GetWidth())
    scrollChild:SetHeight(1)
    
    scrollFrame.scrollBar = scrollBar
    
    return listingSectionFrame
end

--[[
  Set top offset for scroll area
  Adjusts scroll frame position when filter chips change height.
  
  @param offset number - Vertical offset in pixels
]]
function listingSection:setTopOffset(offset)
    storedTopOffset = offset or 0
    repositionScrollFrame()
end

--[[
  Set bottom offset for scroll area
  Leaves room for rarity bar at bottom.
  
  @param offset number - Pixels from bottom
]]
function listingSection:setBottomOffset(offset)
    storedBottomOffset = offset or 0
    repositionScrollFrame()
end

-- Chip tray layout constants
local TRAY_PADDING_TOP = 4
local TRAY_PADDING_BOTTOM = 4
local CHIP_ROW_HEIGHT = 26        -- 22px chip + 4px gap
local CHIP_H_GAP = 4              -- TINY spacing between chips
local ARROW_COL_WIDTH = 16
local BADGE_COL_WIDTH = 33
local SPECIES_ROW_HEIGHT = 44     -- 3px above icon, 36px icon, 1px below, 4px frame
-- Chip tray left offset: arrow + badge + 2px gap = where species icon starts
local TRAY_LEFT_OFFSET = ARROW_COL_WIDTH + BADGE_COL_WIDTH + 2

-- Shared background color for expanded species group (header + tray)
local EXPANDED_GROUP_BG = { 0.67, 0.51, 0.93, 0.08 }  -- Faint lavender card

--[[
  Create or retrieve a species row button from the pool.
  @param index number - Pool index
  @return frame - speciesRowButton frame
]]
local function getSpeciesButton(index)
    if not speciesButtons[index] then
        speciesButtons[index] = speciesRowButton:create(scrollChild, SPECIES_ROW_HEIGHT, speciesCallbacks)
    end
    return speciesButtons[index]
end

--[[
  Create or retrieve a chip tray frame from the pool.
  @param index number - Pool index
  @return frame - Chip tray container frame
]]
local function getChipTray(index)
    if not chipTrayFrames[index] then
        local tray = CreateFrame("Frame", nil, scrollChild)
        -- Points set in renderSpeciesView (full width for card background)

        -- Shared background with species header when expanded
        tray.bg = tray:CreateTexture(nil, "BACKGROUND")
        tray.bg:SetAllPoints()
        tray.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
        tray.bg:SetVertexColor(EXPANDED_GROUP_BG[1], EXPANDED_GROUP_BG[2], EXPANDED_GROUP_BG[3], EXPANDED_GROUP_BG[4])

        -- Selection tint matches speciesRowButton's selectionTint (same color, same alpha).
        -- Shown when the selected pet lives in this tray so both rows look identical.
        tray.selectionTint = tray:CreateTexture(nil, "BACKGROUND", nil, 1)
        tray.selectionTint:SetAllPoints()
        tray.selectionTint:SetTexture("Interface\\Buttons\\WHITE8x8")
        tray.selectionTint:SetVertexColor(0.67, 0.51, 0.93, 0.12)
        tray.selectionTint:Hide()

        -- Hover highlight (paired with species header via hover group)
        tray.hoverBg = tray:CreateTexture(nil, "BACKGROUND", nil, 1)
        tray.hoverBg:SetAllPoints()
        tray.hoverBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        tray.hoverBg:SetVertexColor(1, 1, 1, 0.08)
        tray.hoverBg:Hide()

        tray:EnableMouse(true)
        tray:SetScript("OnEnter", function(self)
            self.hoverBg:Show()
            if self.linkedButton and self.linkedButton.hoverBg then
                self.linkedButton.hoverBg:Show()
            end
        end)
        tray:SetScript("OnLeave", function(self)
            self.hoverBg:Hide()
            if self.linkedButton and self.linkedButton.hoverBg then
                self.linkedButton.hoverBg:Hide()
            end
        end)

        chipTrayFrames[index] = tray
        chipPools[index] = {}
    end
    return chipTrayFrames[index]
end

--[[
  Lay out chips in a tray with wrapping. Returns the tray height.

  @param tray frame - Chip tray container
  @param trayIndex number - Pool index for chip retrieval
  @param chips table - Array of pet data from petGrouping
  @param selectedPetID string|nil - Currently selected petID
  @return number - Total tray height in pixels
]]
local function layoutChipTray(tray, trayIndex, chips, selectedPetID)
    local pool = chipPools[trayIndex]
    if not pool then
        chipPools[trayIndex] = {}
        pool = chipPools[trayIndex]
    end

    -- Reclaim existing chips
    petChip:reclaimAll(pool)

    local trayWidth = tray:GetWidth()
    if trayWidth <= 0 then
        trayWidth = scrollChild and scrollChild:GetWidth() or 300
    end
    -- Chips start at species icon position, available width is from there to right edge
    local availWidth = trayWidth - TRAY_LEFT_OFFSET

    local xOffset = TRAY_LEFT_OFFSET
    local row = 0

    for i, chipData in ipairs(chips) do
        -- Get or create chip
        if not pool[i] then
            pool[i] = petChip:create(tray, chipCallbacks)
        end
        local chip = pool[i]

        -- Update chip content (calculates width)
        petChip:update(chip, chipData, selectedPetID)

        local chipWidth = chip:GetWidth()

        -- Wrap to next row if needed (check against available width from icon position)
        if (xOffset - TRAY_LEFT_OFFSET) + chipWidth > availWidth and xOffset > TRAY_LEFT_OFFSET then
            row = row + 1
            xOffset = TRAY_LEFT_OFFSET
        end

        -- Position chip
        chip:ClearAllPoints()
        chip:SetPoint("TOPLEFT", tray, "TOPLEFT", xOffset, -(TRAY_PADDING_TOP + row * CHIP_ROW_HEIGHT))
        chip:Show()

        xOffset = xOffset + chipWidth + CHIP_H_GAP
    end

    -- Hide excess pool chips
    for i = #chips + 1, #pool do
        pool[i]:Hide()
    end

    local totalRows = row + 1
    local trayHeight = TRAY_PADDING_TOP + (totalRows * CHIP_ROW_HEIGHT) + TRAY_PADDING_BOTTOM
    tray:SetHeight(trayHeight)
    return trayHeight
end

--[[
  Hide all species view elements (species buttons, chip trays, chips).
  Called when switching to pets mode or before species re-render.
]]
local function hideAllSpeciesElements()
    for _, btn in ipairs(speciesButtons) do
        btn:Hide()
    end
    for trayIdx, tray in ipairs(chipTrayFrames) do
        tray:Hide()
        if chipPools[trayIdx] then
            petChip:reclaimAll(chipPools[trayIdx])
        end
    end
end

--[[
  Schedule a viewport-anchored scroll after the layout engine catches up.
  Keeps the anchor item at the same pixel offset from the viewport top,
  so the screen reorganizes around a fixed visual point.

  Uses OnUpdate because SetVerticalScroll clamps to GetVerticalScrollRange(),
  which lags behind scrollChild:SetHeight() until the layout engine recomputes.

  @param mode string - "species" or "pets"
  @param anchorID number|string - speciesID (species mode) or petID (pets mode)
  @param viewportY number - anchor's pixel offset from viewport top before render
]]
local function scheduleAnchoredScroll(mode, anchorID, viewportY)
    if not anchorID then return end
    pendingAnchor = { mode = mode, id = anchorID, viewportY = viewportY }

    local retries = 0
    local MAX_RETRIES = 10  -- ~10 frames, safety valve
    scrollFrame:SetScript("OnUpdate", function(self)
        retries = retries + 1
        local anchor = pendingAnchor
        if not anchor or retries > MAX_RETRIES then
            pendingAnchor = nil
            self:SetScript("OnUpdate", nil)
            return
        end

        -- Wait until scroll range reflects the new content height (bidirectional)
        local expectedMax = math.max(0, scrollChild:GetHeight() - self:GetHeight())
        local currentMax = self:GetVerticalScrollRange()
        local diff = math.abs(currentMax - expectedMax)
        if diff > math.max(expectedMax * 0.1, 50) then
            return  -- Layout hasn't caught up yet, retry next frame
        end

        pendingAnchor = nil
        self:SetScript("OnUpdate", nil)

        -- Find anchor's new Y position in the re-rendered layout
        local newItemY
        if anchor.mode == "species" then
            for _, btn in ipairs(speciesButtons) do
                if btn:IsShown() and btn.speciesData
                    and btn.speciesData.speciesID == anchor.id then
                    local _, _, _, _, btnY = btn:GetPoint(1)
                    newItemY = math.abs(btnY or 0)
                    break
                end
            end
        else
            for i, btn in ipairs(petButtons) do
                if btn:IsShown() and btn.petData
                    and btn.petData.petID == anchor.id then
                    newItemY = (i - 1) * constants.LIST_ENTRY_HEIGHT
                    break
                end
            end
        end

        if newItemY then
            local scrollTo = math.max(0, newItemY - anchor.viewportY)
            local maxScroll = math.max(0, scrollChild:GetHeight() - self:GetHeight())
            scrollTo = math.min(scrollTo, maxScroll)
            self:SetVerticalScroll(scrollTo)
            if self.scrollBar and maxScroll > 0 then
                self.scrollBar:SetValue((scrollTo / maxScroll) * 100)
            end
        else
            -- Anchor filtered out — start from top
            self:SetVerticalScroll(0)
            if self.scrollBar then self.scrollBar:SetValue(0) end
        end
    end)
end

--[[
  Render species view display list.
  Called from refresh() when displayMode == "species".

  @param displayList table - From petGrouping:group()
  @param filtered table - Pre-grouped filtered pet array
  @param sortType string - Current sort field
  @param filterText string - Current filter text
  @param filterChanged boolean - Whether filter text changed since last render
  @return table, string - Rarity stats and selected pet ID
]]
local function renderSpeciesView(displayList, filtered, sortType, filterText, filterChanged)
    -- Save scroll position before re-render
    local savedScroll = scrollFrame and scrollFrame:GetVerticalScroll() or 0

    -- Capture viewport anchor BEFORE hiding elements. On filter changes, we want
    -- to keep the anchor species at the same pixel offset from the viewport top.
    local anchorSpeciesID, anchorViewportY
    if filterChanged then
        -- Try to anchor on the selected pet's species
        local targetSpeciesID
        if currentSelectedPetID then
            if currentSelectedPetID:find("^caged:") then
                if cachedFiltered then
                    for _, entry in ipairs(cachedFiltered) do
                        if entry.petID == currentSelectedPetID then
                            targetSpeciesID = entry.speciesID
                            break
                        end
                    end
                end
            else
                local petCache = Addon.petCache
                if petCache then
                    local selPet = petCache:getPet(currentSelectedPetID)
                    if selPet then targetSpeciesID = selPet.speciesID end
                end
            end
        end

        -- Find selected species' viewport-relative position from old render
        if targetSpeciesID then
            for _, btn in ipairs(speciesButtons) do
                if btn:IsShown() and btn.speciesData
                    and btn.speciesData.speciesID == targetSpeciesID then
                    local _, _, _, _, btnY = btn:GetPoint(1)
                    anchorViewportY = math.abs(btnY or 0) - savedScroll
                    anchorSpeciesID = targetSpeciesID
                    break
                end
            end
        end

        -- Fallback: anchor to species nearest the viewport top
        if not anchorSpeciesID then
            local bestDist = math.huge
            for _, btn in ipairs(speciesButtons) do
                if btn:IsShown() and btn.speciesData then
                    local _, _, _, _, btnY = btn:GetPoint(1)
                    local vpY = math.abs(btnY or 0) - savedScroll
                    -- Pick the first species at or below viewport top
                    if vpY >= -SPECIES_ROW_HEIGHT and vpY < bestDist then
                        bestDist = vpY
                        anchorSpeciesID = btn.speciesData.speciesID
                        anchorViewportY = vpY
                    end
                end
            end
        end
    end

    lastRenderedMode = "species"

    -- Hide pets mode buttons
    for _, btn in ipairs(petButtons) do
        btn:Hide()
    end

    -- Hide previous species elements
    hideAllSpeciesElements()

    local yOffset = 0
    local speciesBtnIdx = 0
    local trayIdx = 0
    local individualPetCount = 0
    local rarityStats = { [1] = 0, [2] = 0, [3] = 0, [4] = 0 }
    local firstSpeciesID = nil
    local firstPetID = nil
    local lastSpeciesBtn = nil   -- For hover group linking
    local lastContainsSelected = false  -- Carried from species entry to its chipTray

    for _, entry in ipairs(displayList) do
        if entry.type == "species" then
            speciesBtnIdx = speciesBtnIdx + 1
            local btn = getSpeciesButton(speciesBtnIdx)

            -- Check if selected pet belongs to this species.
            -- Caged pets have synthetic petIDs ("caged:bag:slot") not in petCache,
            -- so we check their speciesID directly from the entry's chips array.
            local containsSelected = false
            if currentSelectedPetID then
                if currentSelectedPetID:find("^caged:") then
                    -- Synthetic ID: species entries carry pets array, not chips
                    -- (chips live on the chipTray entry and are not set on species)
                    for _, pet in ipairs(entry.pets or {}) do
                        if pet.petID == currentSelectedPetID then
                            containsSelected = true
                            break
                        end
                    end
                else
                    local petCache = Addon.petCache
                    if petCache then
                        local selPet = petCache:getPet(currentSelectedPetID)
                        containsSelected = selPet and selPet.speciesID == entry.speciesID
                    end
                end
            end

            speciesRowButton:update(btn, entry, containsSelected)
            lastContainsSelected = containsSelected
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
            btn:SetWidth(scrollChild:GetWidth())
            btn:Show()
            yOffset = yOffset + SPECIES_ROW_HEIGHT

            -- Hover group: link button to its chip tray (if expanded)
            btn.linkedTray = nil
            btn:SetScript("OnEnter", function(self)
                self.hoverBg:Show()
                if self.linkedTray and self.linkedTray.hoverBg then
                    self.linkedTray.hoverBg:Show()
                end
            end)
            btn:SetScript("OnLeave", function(self)
                self.hoverBg:Hide()
                if self.linkedTray and self.linkedTray.hoverBg then
                    self.linkedTray.hoverBg:Hide()
                end
            end)
            lastSpeciesBtn = btn

            -- Count individual pets and rarity stats
            individualPetCount = individualPetCount + entry.petCount
            if entry.pips then
                for _, pip in ipairs(entry.pips) do
                    local r = pip.rarity
                    if r and r >= 1 and r <= 4 then
                        rarityStats[r] = rarityStats[r] + 1
                    end
                end
            end

            if not firstSpeciesID then
                firstSpeciesID = entry.speciesID
            end

        elseif entry.type == "chipTray" then
            trayIdx = trayIdx + 1
            local tray = getChipTray(trayIdx)

            tray:ClearAllPoints()
            tray:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
            tray:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)

            -- Full-width background for visual card grouping
            -- selectionTint matches species row when this tray contains the selected pet
            if lastContainsSelected then
                tray.selectionTint:Show()
            else
                tray.selectionTint:Hide()
            end

            local trayHeight = layoutChipTray(tray, trayIdx, entry.chips, currentSelectedPetID)
            tray:Show()

            -- Hover group: cross-link tray and its species header
            if lastSpeciesBtn then
                lastSpeciesBtn.linkedTray = tray
                tray.linkedButton = lastSpeciesBtn
            end

            yOffset = yOffset + trayHeight

            -- Track first pet for auto-setup (independent of selection state)
            if not firstPetID and entry.chips and entry.chips[1] and entry.chips[1].petID then
                firstPetID = entry.chips[1].petID
            end

        elseif entry.type == "unowned" then
            speciesBtnIdx = speciesBtnIdx + 1
            local btn = getSpeciesButton(speciesBtnIdx)

            speciesRowButton:update(btn, entry, false)
            btn.linkedTray = nil  -- Clear stale hover link from pool reuse
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
            btn:SetWidth(scrollChild:GetWidth())
            btn:Show()

            yOffset = yOffset + SPECIES_ROW_HEIGHT
        end
    end

    -- Update scroll height
    scrollChild:SetHeight(math.max(yOffset, 10))

    -- Auto-setup on first render: expand first species, select first pet
    if not hasPerformedInitialSetup and firstSpeciesID then
        if not expandedSpecies[firstSpeciesID] then
            -- First pass: expand first species and re-render to get chip data
            expandedSpecies[firstSpeciesID] = true
            return renderSpeciesView(
                petGrouping:group(filtered, sortType, "asc", expandedSpecies,
                    lastBaseCollectionFilter == true and "owned"
                    or lastBaseCollectionFilter == false and "unowned"
                    or "all",
                    true),
                filtered, sortType, filterText, filterChanged)
        end

        -- Second pass: first species is expanded, select first pet
        hasPerformedInitialSetup = true

        if firstPetID and onPetSelectedCallback then
            currentSelectedPetID = firstPetID
            local petCache = Addon.petCache
            if petCache then
                local petData = petCache:getPet(firstPetID)
                if petData then
                    onPetSelectedCallback(petData, firstPetID, nil)
                end
            end
        end
    end

    -- Emit events
    currentVisibleCount = individualPetCount
    currentRarityStats = rarityStats

    if events then
        events:emit("PETLIST:FILTERED_COUNT", {
            filtered = individualPetCount,
            base = #filtered
        })
        events:emit("PETLIST:RARITY_STATS", { stats = rarityStats, petCount = individualPetCount })
    end

    -- Scrollbar visibility
    if scrollFrame and scrollFrame.scrollBar then
        local viewHeight = scrollFrame:GetHeight()
        if yOffset > viewHeight then
            scrollFrame.scrollBar:Show()
        else
            scrollFrame.scrollBar:Hide()
        end
    end

    -- Scroll positioning after render:
    -- Filter changed + anchor captured: set scroll synchronously using the
    --   just-rendered button positions. Also schedule OnUpdate as backup for
    --   the loosening case where SetVerticalScroll gets clamped by a stale
    --   GetVerticalScrollRange(). For tightening (stale range > new range),
    --   the synchronous set is sufficient.
    -- Filter changed + no anchor (first render): start at top
    -- No filter change + no pending anchor: restore saved position
    -- No filter change + pending anchor: don't clobber the OnUpdate
    if scrollFrame then
        if filterChanged then
            if anchorSpeciesID then
                -- Find anchor's new Y in the just-rendered layout
                local newAnchorY
                for _, btn in ipairs(speciesButtons) do
                    if btn:IsShown() and btn.speciesData
                        and btn.speciesData.speciesID == anchorSpeciesID then
                        local _, _, _, _, btnY = btn:GetPoint(1)
                        newAnchorY = math.abs(btnY or 0)
                        break
                    end
                end

                if newAnchorY then
                    local scrollTo = math.max(0, newAnchorY - anchorViewportY)
                    local maxScroll = math.max(0, scrollChild:GetHeight() - scrollFrame:GetHeight())
                    scrollTo = math.min(scrollTo, maxScroll)
                    -- Synchronous set — works for tightening, may be clamped for loosening
                    scrollFrame:SetVerticalScroll(scrollTo)
                    if scrollFrame.scrollBar and maxScroll > 0 then
                        scrollFrame.scrollBar:SetValue((scrollTo / maxScroll) * 100)
                    end
                    -- OnUpdate backup: corrects if SetVerticalScroll was clamped
                    scheduleAnchoredScroll("species", anchorSpeciesID, anchorViewportY)
                else
                    -- Anchor species filtered out
                    scrollFrame:SetVerticalScroll(0)
                    if scrollFrame.scrollBar then
                        scrollFrame.scrollBar:SetValue(0)
                    end
                end
            else
                scrollFrame:SetVerticalScroll(0)
                if scrollFrame.scrollBar then
                    scrollFrame.scrollBar:SetValue(0)
                end
            end
        elseif not pendingAnchor then
            local maxScroll = scrollFrame:GetVerticalScrollRange()
            scrollFrame:SetVerticalScroll(math.min(savedScroll, maxScroll))
        end
    end

    return rarityStats, currentSelectedPetID
end

--[[
  Refresh the pet list display
  
  @param sortType string - Sort field
  @param filterText string - Filter text
  @param selectedPetID string - Currently selected pet
  @param sortDir string - Sort direction
  @param baseCollectionFilter boolean|nil - Base owned filter (true=owned, false=unowned, nil=all)
  @return table, string - Rarity stats and selected pet ID
]]
function listingSection:refresh(sortType, filterText, selectedPetID, sortDir, baseCollectionFilter)
    if not C_PetJournal then
        utils:error("C_PetJournal not available")
        return nil, nil
    end
    
    -- Check if filter text contains ownership tokens (owned/unowned/!owned/!unowned)
    -- These tokens override the collection dropdown
    local filterType = Addon.filterType
    local hasOwnershipToken = filterType and filterType.hasOwnershipToken(filterText)
    
    -- Override dropdown filter when ownership tokens present
    local effectiveCollectionFilter = baseCollectionFilter
    if hasOwnershipToken then
        effectiveCollectionFilter = nil
    end
    
    local filterChanged = (filterText ~= lastFilterText) or (effectiveCollectionFilter ~= lastBaseCollectionFilter)
    lastFilterText = filterText or ""
    lastBaseCollectionFilter = effectiveCollectionFilter
    
    -- Seed unified selection from caller (petsTab) when provided
    if selectedPetID then
        currentSelectedPetID = selectedPetID
    end
    
    -- Capture pets-mode viewport anchor BEFORE hiding buttons.
    -- Species mode captures its own anchor inside renderSpeciesView.
    local petsAnchorID, petsAnchorViewportY
    if filterChanged and currentSelectedPetID then
        local savedPetsScroll = scrollFrame and scrollFrame:GetVerticalScroll() or 0
        local entryH = constants.LIST_ENTRY_HEIGHT
        -- Try selected pet first
        for i, btn in ipairs(petButtons) do
            if btn:IsShown() and btn.petData
                and btn.petData.petID == currentSelectedPetID then
                petsAnchorViewportY = ((i - 1) * entryH) - savedPetsScroll
                petsAnchorID = currentSelectedPetID
                break
            end
        end
        -- Fallback: nearest visible pet to viewport top
        if not petsAnchorID then
            local bestDist = math.huge
            for i, btn in ipairs(petButtons) do
                if btn:IsShown() and btn.petData then
                    local vpY = ((i - 1) * entryH) - savedPetsScroll
                    if vpY >= -entryH and vpY < bestDist then
                        bestDist = vpY
                        petsAnchorID = btn.petData.petID
                        petsAnchorViewportY = vpY
                    end
                end
            end
        end
    end
    
    for _, btn in ipairs(petButtons) do
        btn:Hide()
    end
    
    -- Get pet data
    local pets, duplicateCounts, rarityStats = petUtils:getAllPetData(true)
    
    if not pets or #pets == 0 then
        return nil, nil
    end

    -- Merge caged pets from bags. C_PetJournal skips caged pets entirely (they become
    -- bag items), so they never enter petCache. scanCagedPets returns pipeline-compatible
    -- entries (owned=true, isCaged=true) that flow through filtering and grouping normally.
    local cagedPets = petUtils:scanCagedPets()
    if cagedPets and #cagedPets > 0 then
        for _, caged in ipairs(cagedPets) do
            table.insert(pets, caged)
        end
    end

    -- Get showNonCombat setting (default true if not set)
    local showNonCombat = true
    if Addon.options and Addon.options.GetAll then
        local opts = Addon.options:GetAll()
        if opts then
            showNonCombat = opts.showNonCombatPets ~= false
        end
    end
    
    -- Apply base filters: collection dropdown + showNonCombat (before text filters)
    -- Note: effectiveCollectionFilter is nil when ownership tokens override dropdown
    local baseFiltered = {}
    for _, pet in ipairs(pets) do
        local passesCollection = (effectiveCollectionFilter == nil) or (pet.owned == effectiveCollectionFilter)
        local passesNonCombat = showNonCombat or (pet.canBattle ~= false)
        
        if passesCollection and passesNonCombat then
            table.insert(baseFiltered, pet)
        end
    end
    
    -- Apply text filters
    local filtered, matchContexts = petFilters:filter(baseFiltered, filterText or "")
    
    -- ========================================================================
    -- SPECIES MODE BRANCH
    -- ========================================================================
    local displayMode = Addon.options and Addon.options:Get("displayMode") or "pets"
    if displayMode == "species" and petGrouping then
        -- Convert baseCollectionFilter to petGrouping's string format
        local collectionStr = "all"
        if effectiveCollectionFilter == true then
            collectionStr = "owned"
        elseif effectiveCollectionFilter == false then
            collectionStr = "unowned"
        end

        local displayList = petGrouping:group(
            filtered or {}, sortType, sortDir or "asc",
            expandedSpecies, collectionStr, showNonCombat)

        -- Cache for surgical toggle (expand/collapse skips re-filtering)
        cachedFiltered = filtered or {}
        cachedSortType = sortType
        cachedSortDir = sortDir or "asc"
        cachedCollectionStr = collectionStr
        cachedShowNonCombat = showNonCombat
        cachedFilterText = filterText

        return renderSpeciesView(displayList, filtered or {}, sortType, filterText, filterChanged)
    end
    
    -- ========================================================================
    -- PETS MODE (existing behavior)
    -- ========================================================================

    -- Clean up any species view elements from previous render
    hideAllSpeciesElements()
    
    lastRenderedMode = "pets"
    
    -- Cache state for surgical operations (same as species mode).
    -- Internal event handlers (CACHE:INITIALIZED, PETS:NEW_ACQUISITION) may need
    -- this state when falling back to refresh without explicit args.
    cachedFiltered = filtered or {}
    cachedSortType = sortType
    cachedSortDir = sortDir or "asc"
    cachedCollectionStr = effectiveCollectionFilter == true and "owned"
        or effectiveCollectionFilter == false and "unowned" or "all"
    cachedShowNonCombat = showNonCombat
    cachedFilterText = filterText
    
    -- Apply sorting
    local sorted = petSorting:sortPets(filtered or {}, {primary = sortType, dir = sortDir or "asc"})
    
    -- Determine effective selection (auto-select first pet if none selected)
    local effectiveSelectedPetID = currentSelectedPetID
    local autoSelected = false
    if not effectiveSelectedPetID and #sorted > 0 then
        effectiveSelectedPetID = sorted[1].petID
        currentSelectedPetID = effectiveSelectedPetID
        autoSelected = true
    end
    
    -- Update scroll area
    local entryHeight = constants.LIST_ENTRY_HEIGHT
    local totalHeight = #sorted * entryHeight
    scrollChild:SetHeight(math.max(totalHeight, 10))
    
    -- Begin batch update
    petRowButton:beginRefresh()

    -- Render filtered pets
    local filteredCount = 0
    for i, petData in ipairs(sorted) do
        filteredCount = filteredCount + 1
        local btn = petButtons[i] or createButton()
        petButtons[i] = btn

        local matchContext = matchContexts and matchContexts[petData.petID]
        updateButton(btn, petData, i, effectiveSelectedPetID, matchContext)
    end
    
    currentVisibleCount = filteredCount
    currentRarityStats = rarityStats
    
    -- Emit filtered count and base count for header/status bars
    -- base = count after dropdown filter (before text filters)
    -- filtered = count after all filters
    if events then
        events:emit("PETLIST:FILTERED_COUNT", { 
            filtered = filteredCount, 
            base = #baseFiltered 
        })
        events:emit("PETLIST:RARITY_STATS", { stats = rarityStats, petCount = filteredCount })
    end
    
    -- Update scrollbar
    if scrollFrame.scrollBar then
        local viewHeight = scrollFrame:GetHeight()
        if totalHeight > viewHeight then
            scrollFrame.scrollBar:Show()
        else
            scrollFrame.scrollBar:Hide()
        end
    end

    -- Determine if selected pet is in current results
    local foundSelected = nil
    for _, petData in ipairs(sorted) do
        if petData.petID == effectiveSelectedPetID then
            foundSelected = effectiveSelectedPetID
            break
        end
    end

    -- Scroll positioning:
    -- Auto-selected (first render, no prior selection): scroll to first pet
    -- Filter changed + anchor captured: set synchronously from known positions,
    --   OnUpdate backup for loosening where SetVerticalScroll gets clamped
    -- Filter changed + no anchor: start at top
    -- Otherwise: don't touch scroll position
    if autoSelected and sorted[1] and scrollFrame then
        listingSection:scrollToPet(sorted[1].petID)
    elseif filterChanged and petsAnchorID and scrollFrame then
        -- Find anchor's new position in sorted results
        local newAnchorY
        for i, petData in ipairs(sorted) do
            if petData.petID == petsAnchorID then
                newAnchorY = (i - 1) * entryHeight
                break
            end
        end

        if newAnchorY then
            local scrollTo = math.max(0, newAnchorY - petsAnchorViewportY)
            local maxScroll = math.max(0, scrollChild:GetHeight() - scrollFrame:GetHeight())
            scrollTo = math.min(scrollTo, maxScroll)
            scrollFrame:SetVerticalScroll(scrollTo)
            if scrollFrame.scrollBar and maxScroll > 0 then
                scrollFrame.scrollBar:SetValue((scrollTo / maxScroll) * 100)
            end
            -- OnUpdate backup for loosening
            scheduleAnchoredScroll("pets", petsAnchorID, petsAnchorViewportY)
        else
            scrollFrame:SetVerticalScroll(0)
            if scrollFrame.scrollBar then
                scrollFrame.scrollBar:SetValue(0)
            end
        end
    elseif filterChanged then
        if scrollFrame then
            scrollFrame:SetVerticalScroll(0)
            if scrollFrame.scrollBar then
                scrollFrame.scrollBar:SetValue(0)
            end
        end
    end

    -- Trigger callback for auto-selection so petDetails updates
    if autoSelected and onPetSelectedCallback and sorted[1] then
        local firstPet = sorted[1]
        local matchContext = matchContexts and matchContexts[firstPet.petID]
        onPetSelectedCallback(firstPet, firstPet.petID, matchContext)
    end
    
    return rarityStats, foundSelected
end

-- ============================================================================
-- SURGICAL RE-RENDER FROM CACHE
-- Common pattern: modify cachedFiltered, then re-render species view without
-- running the full refresh pipeline (which re-scans bags, re-filters from
-- scratch, and requires full sort/filter/selection state from the coordinator).
-- ============================================================================

--[[
  Re-render species view from cached filter/sort state.
  Falls back to doing nothing if no cached state exists (next explicit refresh
  from petsTab will populate it).

  @return boolean - true if re-render succeeded
]]
local function rerenderFromCache()
    if not cachedFiltered or not petGrouping then return false end
    local displayList = petGrouping:group(
        cachedFiltered, cachedSortType, cachedSortDir,
        expandedSpecies, cachedCollectionStr, cachedShowNonCombat)
    renderSpeciesView(displayList, cachedFiltered, cachedSortType,
        cachedFilterText, false)
    return true
end

--[[
  Update selection highlighting
  
  @param selectedPetID string - Pet ID to highlight
]]
function listingSection:updateSelection(selectedPetID)
    currentSelectedPetID = selectedPetID
    local displayMode = Addon.options and Addon.options:Get("displayMode") or "pets"
    
    -- Mode changed since last render (e.g. user changed setting) - full refresh needed
    if lastRenderedMode and lastRenderedMode ~= displayMode then
        listingSection:refresh()
        return
    end
    
    if displayMode == "species" then
        if not rerenderFromCache() then
            listingSection:refresh()
        end
        return
    end

    for _, btn in ipairs(petButtons) do
        if btn:IsShown() and btn.petData then
            if btn.petData.petID == selectedPetID then
                btn.selectedBg:Show()
            else
                btn.selectedBg:Hide()
            end
        end
    end
end

--[[
  Toggle expand/collapse state for a species.
  Accordion behavior: expanding one species collapses all others.

  @param speciesID number - Species to toggle
]]
function listingSection:toggleSpecies(speciesID)
    if not speciesID then return end
    if expandedSpecies[speciesID] then
        -- Collapsing: just remove this one
        expandedSpecies[speciesID] = nil
    else
        -- Expanding: collapse all others first (accordion)
        wipe(expandedSpecies)
        expandedSpecies[speciesID] = true
    end

    -- Surgical re-render: use cached filter results if available
    if not rerenderFromCache() then
        listingSection:refresh()
    end
end

--[[
  Scroll to show a specific pet
  
  @param petID string - Pet ID to scroll to
]]
function listingSection:scrollToPet(petID)
    if not petID or not scrollFrame then return end

    -- Species mode: variable-height layout, fixed-height math doesn't apply
    local displayMode = Addon.options and Addon.options:Get("displayMode") or "pets"
    if displayMode == "species" then return end
    
    for i, btn in ipairs(petButtons) do
        if btn:IsShown() and btn.petData and btn.petData.petID == petID then
            local entryHeight = constants.LIST_ENTRY_HEIGHT
            local targetOffset = (i - 1) * entryHeight
            local viewHeight = scrollFrame:GetHeight()
            
            -- Center the pet in view
            local scrollTo = math.max(0, targetOffset - (viewHeight / 2) + (entryHeight / 2))
            -- Compute maxScroll from known heights — GetVerticalScrollRange() may
            -- return stale values when called before the layout engine recomputes.
            local maxScroll = math.max(0, scrollChild:GetHeight() - viewHeight)
            scrollTo = math.min(scrollTo, maxScroll)
            
            scrollFrame:SetVerticalScroll(scrollTo)
            
            if scrollFrame.scrollBar and maxScroll > 0 then
                scrollFrame.scrollBar:SetValue((scrollTo / maxScroll) * 100)
            end
            break
        end
    end
end

--[[
  Ensure the currently selected pet is visible after a mode switch.
  Pets mode: scrolls to the pet row.
  Species mode: expands the species containing the selected pet and scrolls to it.
]]
function listingSection:ensureSelectedVisible()
    if not currentSelectedPetID or not scrollFrame then return end
    
    local displayMode = Addon.options and Addon.options:Get("displayMode") or "pets"
    
    if displayMode == "pets" then
        listingSection:scrollToPet(currentSelectedPetID)
        return
    end
    
    -- Species mode: find which species contains the selected pet
    local petCache = Addon.petCache
    if not petCache then return end
    
    local petData = petCache:getPet(currentSelectedPetID)
    if not petData or not petData.speciesID then return end
    
    local speciesID = petData.speciesID
    
    -- Expand this species if not already (accordion: collapse others)
    if not expandedSpecies[speciesID] then
        wipe(expandedSpecies)
        expandedSpecies[speciesID] = true
        -- Re-render with this species expanded
        if not rerenderFromCache() then
            listingSection:refresh()
        end
    end
    
    -- Scroll to the species row containing the selected pet
    for _, btn in ipairs(speciesButtons) do
        if btn:IsShown() and btn.speciesData and btn.speciesData.speciesID == speciesID then
            local _, _, _, _, btnY = btn:GetPoint(1)
            local targetOffset = btnY and math.abs(btnY) or 0
            local viewHeight = scrollFrame:GetHeight()
            local scrollTo = math.max(0, targetOffset - (viewHeight / 4))
            local maxScroll = math.max(0, scrollChild:GetHeight() - viewHeight)
            scrollTo = math.min(scrollTo, maxScroll)
            scrollFrame:SetVerticalScroll(scrollTo)
            if scrollFrame.scrollBar and maxScroll > 0 then
                scrollFrame.scrollBar:SetValue((scrollTo / maxScroll) * 100)
            end
            break
        end
    end
end

--[[
  Get currently visible pet buttons
  
  @return table - Array of visible buttons with petData
]]
function listingSection:getVisibleButtons()
    local visible = {}
    for _, btn in ipairs(petButtons) do
        if btn:IsShown() and btn.petData then
            table.insert(visible, btn)
        end
    end
    return visible
end

--[[
  Remove a pet from the list surgically (without full refresh)
  Updates button positions and scroll height.
  
  @param petID string - Pet ID to remove
  @return boolean - true if removed
]]
function listingSection:removePet(petID)
    if not petID then return false end

    -- Species mode: remove from cached data and re-render
    local displayMode = Addon.options and Addon.options:Get("displayMode") or "pets"
    if displayMode == "species" then
        if cachedFiltered then
            for i, entry in ipairs(cachedFiltered) do
                if entry.petID == petID then
                    table.remove(cachedFiltered, i)
                    break
                end
            end
        end
        rerenderFromCache()
        return true
    end
    
    local visibleButtons = {}
    local removedIndex = nil
    local removedRarity = nil
    
    -- Find visible buttons and the one to remove
    for i, btn in ipairs(petButtons) do
        if btn:IsShown() and btn.petData then
            if btn.petData.petID == petID then
                removedIndex = #visibleButtons + 1
                removedRarity = btn.petData.rarity
                btn:Hide()
            else
                table.insert(visibleButtons, btn)
            end
        end
    end
    
    if not removedIndex then
        return false
    end
    
    -- Reposition remaining buttons
    local entryHeight = constants.LIST_ENTRY_HEIGHT
    local visibleIndex = 0
    for i, btn in ipairs(visibleButtons) do
        visibleIndex = i
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * entryHeight)
    end
    
    -- Update scroll height
    scrollChild:SetHeight(math.max(visibleIndex * entryHeight, 10))
    
    -- Select the pet at the removed position (or the new last if removed was last)
    local selectIndex = removedIndex
    if selectIndex > visibleIndex then
        selectIndex = visibleIndex
    end
    
    local btnToSelect = visibleButtons[selectIndex]
    if btnToSelect and btnToSelect.petData then
        listingSection:updateSelection(btnToSelect.petData.petID)
        onPetSelectedCallback(btnToSelect.petData, btnToSelect.petData.petID, nil)
    end
    
    -- Update rarity stats (rarity is 1-4 in our stats table)
    if removedRarity and currentRarityStats then
        local r = removedRarity
        if r >= 1 and r <= 4 and currentRarityStats[r] and currentRarityStats[r] > 0 then
            currentRarityStats[r] = currentRarityStats[r] - 1
        end
        
        -- Fire updated rarity stats for rarityBar
        if events then
            events:emit("PETLIST:RARITY_STATS", {
                stats = currentRarityStats,
                petCount = visibleIndex
            })
        end
    end
    
    return true
end

--[[
  Add a newly acquired pet to the bottom of the list
  Only adds if pet matches current filter criteria.
  Sorts into proper position on next refresh.
  
  @param petID string - Pet ID to add
  @return boolean - true if added to list
]]
function listingSection:addPet(petID)
    if not petID then return false end

    -- Species mode: filter-check, add to cached data, re-render
    local displayMode = Addon.options and Addon.options:Get("displayMode") or "pets"
    if displayMode == "species" then
        local petCache = Addon.petCache
        local newPet = petCache and petCache:getPet(petID)
        if newPet and cachedFiltered then
            -- Filter-check before adding
            local passes = true
            if lastBaseCollectionFilter ~= nil and newPet.owned ~= lastBaseCollectionFilter then
                passes = false
            end
            if passes and lastFilterText and lastFilterText ~= "" then
                local result = petFilters:filter({newPet}, lastFilterText)
                passes = result and #result > 0
            end
            if passes then
                table.insert(cachedFiltered, newPet)
            end
        end
        rerenderFromCache()
        return true
    end
    
    -- Guard: UI must be created (scrollChild exists)
    if not scrollChild then
        -- UI not visible - skip, next refresh() will pick it up
        return false
    end
    
    -- Get pet data from cache
    local petCache = Addon.petCache
    if not petCache then return false end
    
    local petData = petCache:getPet(petID)
    if not petData then
        return false
    end
    
    -- Check base collection filter (owned/unowned)
    if lastBaseCollectionFilter ~= nil then
        if petData.owned ~= lastBaseCollectionFilter then
            return false
        end
    end
    
    -- Check text filter
    if lastFilterText and lastFilterText ~= "" then
        local filtered = petFilters:filter({petData}, lastFilterText)
        if not filtered or #filtered == 0 then
            return false
        end
    end
    
    -- Pet matches filter - add to bottom
    local entryHeight = constants.LIST_ENTRY_HEIGHT
    currentVisibleCount = currentVisibleCount + 1
    
    local btn = petButtons[currentVisibleCount] or createButton()
    petButtons[currentVisibleCount] = btn
    
    updateButton(btn, petData, currentVisibleCount, nil, nil)
    
    -- Update scroll height
    scrollChild:SetHeight(math.max(currentVisibleCount * entryHeight, 10))
    
    -- Update rarity stats
    if petData.rarity and currentRarityStats then
        local r = petData.rarity
        if r >= 1 and r <= 4 then
            currentRarityStats[r] = (currentRarityStats[r] or 0) + 1
        end
        
        if events then
            events:emit("PETLIST:RARITY_STATS", {
                stats = currentRarityStats,
                petCount = currentVisibleCount
            })
        end
    end
    
    return true
end

--[[
  Handle window resize
]]
function listingSection:onResize()
    if scrollChild then
        local listWidth = constants.LIST_WIDTH
        scrollChild:SetWidth(listWidth - 26)

        -- Resize pets mode buttons
        for _, btn in ipairs(petButtons) do
            btn:SetWidth(listWidth - 26)
        end

        -- Resize species mode elements
        for _, btn in ipairs(speciesButtons) do
            btn:SetWidth(listWidth - 26)
        end

        -- Chip trays re-flow on resize (cached data is still valid, just layout changes)
        local displayMode = Addon.options and Addon.options:Get("displayMode") or "pets"
        if displayMode == "species" then
            rerenderFromCache()
        end
    end
end

-- ============================================================================
-- CAGED-TO-LEARNED SWAP
-- When a caged pet is learned (from PAO or bags), the cage disappears from
-- inventory and a real journal pet appears. Rather than a full refresh (which
-- re-scans bags and may hit a timing window where the cage item still exists),
-- surgically remove the stale caged entry and insert the learned pet.
-- ============================================================================

--[[
  Find a caged entry in the current display data that matches a newly learned pet.
  Primary match: speciesID + level + rarity + breedID (exact).
  Fallback: speciesID + level + rarity when exactly one caged entry matches
  (handles cases where breed detection returns different results for hyperlink
  vs journal API).

  @param newPet table - Pet data from petCache for the newly learned pet
  @return table|nil - The matching caged entry, or nil if no match
]]
local function findMatchingCagedEntry(newPet)
    if not newPet or not newPet.speciesID then return nil end

    -- Collect all caged entries from the appropriate data source
    local cagedEntries = {}
    local displayMode = Addon.options and Addon.options:Get("displayMode") or "pets"

    if displayMode == "species" and cachedFiltered then
        for _, entry in ipairs(cachedFiltered) do
            if entry.isCaged and entry.speciesID == newPet.speciesID then
                table.insert(cagedEntries, entry)
            end
        end
    else
        for _, btn in ipairs(petButtons) do
            if btn:IsShown() and btn.petData and btn.petData.isCaged then
                if btn.petData.speciesID == newPet.speciesID then
                    table.insert(cagedEntries, btn.petData)
                end
            end
        end
    end

    if #cagedEntries == 0 then return nil end

    -- Pass 1: strict match (speciesID + level + rarity + breedID)
    for _, entry in ipairs(cagedEntries) do
        if entry.level == newPet.level
            and entry.rarity == newPet.rarity
            and (entry.breedID == newPet.breedID or (not entry.breedID and not newPet.breedID))
        then
            return entry
        end
    end

    -- Pass 2: relaxed match (speciesID + level + rarity, ignore breedID)
    -- Only used when exactly one candidate remains — avoids ambiguity
    local relaxedMatches = {}
    for _, entry in ipairs(cagedEntries) do
        if entry.level == newPet.level and entry.rarity == newPet.rarity then
            table.insert(relaxedMatches, entry)
        end
    end

    if #relaxedMatches == 1 then
        return relaxedMatches[1]
    end

    return nil
end

--[[
  Replace a caged display entry with its newly learned counterpart.
  The cage was consumed and the pet is now in the journal — swap them
  without a full refresh to preserve scroll position and selection.

  @param cagedEntry table - The caged entry to remove (from findMatchingCagedEntry)
  @param newPetID string - Real petID of the newly learned pet
  @param newPet table - Pet data from petCache
]]
local function swapCagedForLearned(cagedEntry, newPetID, newPet)
    local displayMode = Addon.options and Addon.options:Get("displayMode") or "pets"

    -- Transfer selection if the caged entry was selected
    if currentSelectedPetID and cagedEntry.petID
        and currentSelectedPetID == cagedEntry.petID then
        currentSelectedPetID = newPetID
    end

    if displayMode == "species" then
        -- Remove caged entry from cachedFiltered
        if cachedFiltered then
            for i, entry in ipairs(cachedFiltered) do
                if entry == cagedEntry then
                    table.remove(cachedFiltered, i)
                    break
                end
            end
        end

        -- Filter-check the new pet before adding to cachedFiltered
        local passes = true
        if lastBaseCollectionFilter ~= nil and newPet.owned ~= lastBaseCollectionFilter then
            passes = false
        end
        if passes and lastFilterText and lastFilterText ~= "" then
            local result = petFilters:filter({newPet}, lastFilterText)
            passes = result and #result > 0
        end

        if passes and cachedFiltered then
            table.insert(cachedFiltered, newPet)
        end

        -- Surgical re-render from updated cache
        rerenderFromCache()
    else
        -- Pets mode: remove caged button, add learned pet
        if cagedEntry.petID then
            listingSection:removePet(cagedEntry.petID)
        end
        listingSection:addPet(newPetID)
    end
end

--[[
  Initialize listing section module
]]
function listingSection:initialize()
    constants = Addon.constants
    events = Addon.events
    petUtils = Addon.petUtils
    petFilters = Addon.petFilters
    petSorting = Addon.petSorting
    petRowButton = Addon.petRowButton
    petGrouping = Addon.petGrouping
    speciesRowButton = Addon.speciesRowButton
    petChip = Addon.petChip
    
    if not constants or not events or not petUtils or not petFilters or not petSorting or not petRowButton then
        utils:error("listingSection: Missing required dependencies")
        return false
    end

    -- Species view modules are optional (graceful degradation to pets mode)
    
    -- Subscribe to collection events
    -- PET_RENAMED and PET_FAVORITED are coordinated by petsTab (full refresh).
    -- PET_CAGED goes through petCache → CACHE:COLLECTION_CHANGED "removed" (below)
    -- for immediate removal. petsTab waits for BAG_UPDATE (cage item in bags)
    -- before full refresh that adds the caged:bag:slot entry.
    -- listingSection handles surgical (non-refresh) updates only.
    if events then
        events:subscribe("COLLECTION:PET_RELEASED", function(eventName, payload)
            -- Surgical removal - no full refresh needed
            local petID = payload and (payload.petID or (payload.petData and payload.petData.petID))
            if petID then
                listingSection:removePet(petID)
            end
        end)
        
        events:subscribe("CACHE:COLLECTION_CHANGED", function(eventName, payload)
            if payload and payload.action == "added" and payload.petID then
                -- Check if this pet was learned from a cage in the current display.
                -- Match on speciesID+level+rarity+breedID to identify the exact cage.
                local petCache = Addon.petCache
                local newPet = petCache and petCache:getPet(payload.petID)
                if newPet then
                    local cagedEntry = findMatchingCagedEntry(newPet)
                    if cagedEntry then
                        swapCagedForLearned(cagedEntry, payload.petID, newPet)
                        return
                    end
                end
                listingSection:addPet(payload.petID)
            end
            if payload and payload.action == "removed" and payload.petID then
                -- Surgical removal — covers cage (petCache removes before bag
                -- updates) and release-via-Blizzard-UI. Harmless double-call
                -- with PET_RELEASED handler (returns false if already gone).
                listingSection:removePet(payload.petID)
            end
        end)
        
        events:subscribe("CACHE:PET_UPDATED", function(eventName, payload)
            -- Surgical update for single pet (rarity upgrade, rename, etc.)
            if payload and payload.petID and payload.pet then
                listingSection:updatePetButton(payload.petID, payload.pet)
            end
        end)
        
        events:subscribe("CACHE:INITIALIZED", function(eventName, payload)
            -- Pet data now available. Only refresh if no prior render has
            -- populated the cache — petsTab triggers a proper state-aware
            -- refresh on tab show, which should always come after this.
            if scrollChild and not cachedFiltered then
                listingSection:refresh()
            end
        end)
        
        -- Recency glow fix: petAcquisitions records timestamp AFTER petCache adds the pet,
        -- so the initial addPet render has no timestamp yet. Re-render once it exists.
        events:subscribe("PETS:NEW_ACQUISITION", function(eventName, payload)
            if not payload or not payload.petID then return end
            local displayMode = Addon.options and Addon.options:Get("displayMode") or "pets"
            if displayMode == "species" then
                -- Species mode: surgical re-render from cache
                if not rerenderFromCache() then
                    listingSection:refresh()
                end
            else
                -- Pets mode: find and re-render the specific button
                local petCache = Addon.petCache
                if petCache then
                    local petData = petCache:getPet(payload.petID)
                    if petData then
                        listingSection:updatePetButton(payload.petID, petData)
                    end
                end
            end
        end)
    end
    return true
end

--[[
  Surgically update a single pet button
  Finds the button displaying this pet and re-renders it.
  Updates rarity stats if rarity changed.
  
  @param petID string - Pet ID to update
  @param petData table - Updated pet data from cache
  @return boolean - true if button found and updated
]]
function listingSection:updatePetButton(petID, petData)
    if not petID or not petData then return false end

    -- Species mode: update in cached data and re-render
    local displayMode = Addon.options and Addon.options:Get("displayMode") or "pets"
    if displayMode == "species" then
        if cachedFiltered then
            for i, entry in ipairs(cachedFiltered) do
                if entry.petID == petID then
                    cachedFiltered[i] = petData
                    break
                end
            end
        end
        rerenderFromCache()
        return true
    end
    
    for i, btn in ipairs(petButtons) do
        if btn:IsShown() and btn.petData and btn.petData.petID == petID then
            local oldRarity = btn.petData.rarity
            local newRarity = petData.rarity
            
            -- Re-render the button with updated data
            updateButton(btn, petData, i, nil, nil)
            
            -- Update rarity stats if rarity changed
            if oldRarity ~= newRarity and currentRarityStats then
                if oldRarity and oldRarity >= 1 and oldRarity <= 4 then
                    currentRarityStats[oldRarity] = math.max(0, (currentRarityStats[oldRarity] or 0) - 1)
                end
                if newRarity and newRarity >= 1 and newRarity <= 4 then
                    currentRarityStats[newRarity] = (currentRarityStats[newRarity] or 0) + 1
                end
                
                if events then
                    events:emit("PETLIST:RARITY_STATS", {
                        stats = currentRarityStats,
                        petCount = currentVisibleCount
                    })
                end
            end
            
            return true
        end
    end
    
    return false
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("listingSection", {"utils", "constants", "events", "petUtils", "petFilters", "petSorting", "petTooltips", "petRowButton", "petGrouping", "speciesRowButton", "petChip"}, function()
        return listingSection:initialize()
    end)
end

Addon.listingSection = listingSection
return listingSection