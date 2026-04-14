--[[
  ui/petList/contextMenu_listing.lua
  Pet List Context Menu
  
  Right-click context menu for owned pets in the pet list.
  Uses the shared contextMenu factory for consistent styling and spacing.
  
  Menu order (matches Pet Journal + extras):
  - Summon
  - Rename...
  - Set Favorite
  - Release...
  - Put in Cage...
  ---
  - Set in Battle Slot
  - Filter to this Species
  --- (debug only)
  - Dump Pet Info... (debug only)
  
  Dependencies: contextMenu (factory), petList, events
  Exports: Addon.petListContextMenu
]]

local ADDON_NAME, Addon = ...

local petListContextMenu = {}

-- Dump frame for pet info display
local dumpFrame = nil

-- ============================================================================
-- DUMP FRAME
-- ============================================================================

--[[
  Create dump frame for displaying pet info
  Scrollable text area with Copy All and Close buttons.
]]
local function createDumpFrame()
    if dumpFrame then return dumpFrame end
    
    local frame = CreateFrame("Frame", "PAOPetDumpFrame", UIParent, "BackdropTemplate")
    frame:SetSize(500, 400)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()
    
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.95)
    
    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOP", 0, -16)
    frame.title:SetText("Pet Info Dump")
    
    -- Close button (X)
    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", 2, 2)
    
    -- Scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", "PAOPetDumpScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -36, 50)
    
    -- Edit box for text (selectable)
    local editBox = CreateFrame("EditBox", "PAOPetDumpEditBox", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetFontObject(GameFontHighlightSmall)
    editBox:SetWidth(scrollFrame:GetWidth() - 10)
    editBox:SetAutoFocus(false)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scrollFrame:SetScrollChild(editBox)
    frame.editBox = editBox
    
    -- Copy All button
    frame.copyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.copyButton:SetSize(100, 24)
    frame.copyButton:SetPoint("BOTTOMLEFT", 16, 16)
    frame.copyButton:SetText("Copy All")
    frame.copyButton:SetScript("OnClick", function()
        editBox:SetFocus()
        editBox:HighlightText()
    end)
    
    -- Close button (bottom)
    frame.closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    frame.closeBtn:SetSize(100, 24)
    frame.closeBtn:SetPoint("BOTTOMRIGHT", -16, 16)
    frame.closeBtn:SetText("Close")
    frame.closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    dumpFrame = frame
    return frame
end

--[[
  Show dump frame with pet info text
]]
local function showDumpFrame(text, petName)
    local frame = createDumpFrame()
    frame.title:SetText("Pet Info: " .. (petName or "Unknown"))
    frame.editBox:SetText(text)
    frame.editBox:SetCursorPosition(0)
    frame:Show()
end


--[[
  Generate pet dump text (debug)
  Per spec 9.1: focused identity, stats, state, cache-vs-live delta.
  No abilities (species-level data, shown in species dump instead).
]]
local function generatePetDumpText(petData)
    local lines = {}

    -- Identity (focused on what's unique to this individual pet)
    table.insert(lines, "=== Identity ===")
    table.insert(lines, "petID: " .. tostring(petData.petID or "nil"))
    table.insert(lines, "speciesID: " .. tostring(petData.speciesID or "nil"))
    table.insert(lines, "customName: " .. tostring(petData.customName or "nil"))
    table.insert(lines, "name: " .. tostring(petData.name or petData.speciesName or "nil"))
    table.insert(lines, "level: " .. tostring(petData.level or "nil"))
    table.insert(lines, "rarity: " .. tostring(petData.rarity or "nil"))

    local breedDetection = Addon.breedDetection
    if petData.isCaged then
        -- Breed data was detected at scan time from hyperlink stats
        table.insert(lines, "breedID: " .. tostring(petData.breedID or "nil"))
        table.insert(lines, "breedText: " .. tostring(petData.breedText or "nil"))
        table.insert(lines, "confidence: n/a (caged - from hyperlink stats)")
    elseif breedDetection and petData.petID then
        local breedID, confidence, breedText = breedDetection:detectBreedByPetID(petData.petID)
        table.insert(lines, "breedID: " .. tostring(breedID or "nil"))
        table.insert(lines, "breedText: " .. tostring(breedText or "nil"))
        table.insert(lines, "confidence: " .. (confidence and (confidence .. "%") or "nil"))
    end
    table.insert(lines, "")

    -- Stats
    table.insert(lines, "=== Stats ===")
    if petData.isCaged then
        table.insert(lines, "health: n/a / " .. tostring(petData.maxHealth or "nil"))
        table.insert(lines, "power: " .. tostring(petData.power or "nil"))
        table.insert(lines, "speed: " .. tostring(petData.speed or "nil"))
    elseif petData.petID then
        local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petData.petID)
        table.insert(lines, "health: " .. tostring(health or "nil") .. " / " .. tostring(maxHealth or "nil"))
        table.insert(lines, "power: " .. tostring(power or "nil"))
        table.insert(lines, "speed: " .. tostring(speed or "nil"))
    end
    table.insert(lines, "")

    -- State
    table.insert(lines, "=== State ===")
    table.insert(lines, "isFavorite: " .. tostring(petData.isFavorite))
    local isSummoned = not petData.isCaged and petData.petID and (C_PetJournal.GetSummonedPetGUID() == petData.petID)
    table.insert(lines, "isSummoned: " .. tostring(isSummoned or false))

    -- Battle slot assignment
    local battleSlot = nil
    if not petData.isCaged and petData.petID then
        for slot = 1, 3 do
            local slotPetID = C_PetJournal.GetPetLoadOutInfo(slot)
            if slotPetID == petData.petID then
                battleSlot = slot
                break
            end
        end
    end
    table.insert(lines, "battleSlot: " .. (battleSlot and tostring(battleSlot) or "none"))
    table.insert(lines, "isCaged: " .. tostring(petData.isCaged or false))
    table.insert(lines, "")

    -- Cache vs Live (only for journal pets; caged pets have no live journal entry)
    if not petData.isCaged and petData.petID then
        table.insert(lines, "=== Cache vs Live ===")
        local speciesID, customName, level, xp, maxXp, displayID, isFavorite, name, icon, petType,
              creatureID, sourceText, description, isWild, canBattle, tradable, unique, obtainable =
              C_PetJournal.GetPetInfoByPetID(petData.petID)

        local diffs = {}
        if petData.speciesID ~= speciesID then
            table.insert(diffs, string.format("  speciesID: cache=%s live=%s",
                tostring(petData.speciesID), tostring(speciesID)))
        end
        if (petData.customName or nil) ~= (customName or nil) then
            table.insert(diffs, string.format("  customName: cache=%s live=%s",
                tostring(petData.customName), tostring(customName)))
        end
        if petData.level ~= level then
            table.insert(diffs, string.format("  level: cache=%s live=%s",
                tostring(petData.level), tostring(level)))
        end
        if petData.petType ~= petType then
            table.insert(diffs, string.format("  petType: cache=%s live=%s",
                tostring(petData.petType), tostring(petType)))
        end
        if petData.isFavorite ~= isFavorite then
            table.insert(diffs, string.format("  isFavorite: cache=%s live=%s",
                tostring(petData.isFavorite), tostring(isFavorite)))
        end
        if petData.isWild ~= isWild then
            table.insert(diffs, string.format("  isWild: cache=%s live=%s",
                tostring(petData.isWild), tostring(isWild)))
        end
        if petData.canBattle ~= canBattle then
            table.insert(diffs, string.format("  canBattle: cache=%s live=%s",
                tostring(petData.canBattle), tostring(canBattle)))
        end

        -- Rarity from stats API (separate from GetPetInfoByPetID)
        local _, _, _, _, liveRarity = C_PetJournal.GetPetStats(petData.petID)
        if petData.rarity ~= liveRarity then
            table.insert(diffs, string.format("  rarity: cache=%s live=%s",
                tostring(petData.rarity), tostring(liveRarity)))
        end

        if #diffs > 0 then
            for _, diff in ipairs(diffs) do
                table.insert(lines, diff)
            end
        else
            table.insert(lines, "Cache: all fields match live API.")
        end
    end

    return table.concat(lines, "\n")
end


-- ============================================================================
-- MENU BUILDING
-- ============================================================================

--[[
  Build menu definition for a pet
  @param petData table - Pet data
  @return table - Menu definition for contextMenu factory
]]
local function buildMenuDef(petData)
    local petID = petData.petID
    local petList = Addon.petList
    local items = {}

    -- ========================================
    -- CAGED PET MENU (separate from journal pets)
    -- Caged pets live in bags with synthetic petIDs. No journal APIs accept them.
    -- ========================================
    if petData.isCaged then
        local bag, slot
        if petID then
            bag, slot = petID:match("^caged:(%d+):(%d+)$")
        end
        bag, slot = tonumber(bag), tonumber(slot)

        table.insert(items, {
            text = "Learn Pet...",
            func = function()
                Addon.dialogs:showUncageConfirm({
                    bag         = bag,
                    slot        = slot,
                    speciesName = petData.speciesName,
                    icon        = petData.icon,
                })
            end
        })

        table.insert(items, {
            text = "Filter to this Species",
            func = function()
                local speciesName = petData.speciesName or ""
                local filterText = string.format('species:"%s"', speciesName)
                if Addon.petList and Addon.petList.setFilterText then
                    Addon.petList:setFilterText(filterText)
                elseif Addon.filterSection and Addon.filterSection.setFilterText then
                    Addon.filterSection:setFilterText(filterText)
                end
            end
        })

        if pao_settings and pao_settings.debugMode then
            table.insert(items, { separator = true })
            table.insert(items, {
                text = "Dump Pet Info...",
                func = function()
                    local dumpText = generatePetDumpText(petData)
                    local displayName = petData.speciesName or "Caged Pet"
                    showDumpFrame(dumpText, displayName)
                end
            })
        end

        return { items = items }
    end

    -- ========================================
    -- STANDARD PET JOURNAL ORDER
    -- ========================================
    
    -- Summon/Dismiss
    if C_PetJournal.PetIsSummonable and C_PetJournal.PetIsSummonable(petID) then
        local isSummoned = (C_PetJournal.GetSummonedPetGUID() == petID)
        table.insert(items, {
            text = isSummoned and PET_DISMISS or BATTLE_PET_SUMMON,
            func = function()
                C_PetJournal.SummonPetByGUID(petID)
            end
        })
    end
    
    -- Rename...
    table.insert(items, {
        text = BATTLE_PET_RENAME .. "...",
        func = function()
            local displayName = petData.customName or petData.speciesName or "Pet"
            StaticPopup_Show("PAO_PET_RENAME", displayName, nil, petData)
        end
    })
    
    -- Favorite/Unfavorite
    local isFavorite = C_PetJournal.PetIsFavorite and C_PetJournal.PetIsFavorite(petID)
    table.insert(items, {
        text = isFavorite and BATTLE_PET_UNFAVORITE or BATTLE_PET_FAVORITE,
        func = function()
            C_PetJournal.SetFavorite(petID, isFavorite and 0 or 1)
            if petList then
                petList:onPetFavorited(petData, not isFavorite)
            end
        end
    })
    
    -- Release...
    if C_PetJournal.PetCanBeReleased and C_PetJournal.PetCanBeReleased(petID) then
        local isSlotted = C_PetJournal.PetIsSlotted and C_PetJournal.PetIsSlotted(petID)
        local inBattle = C_PetBattles.IsInBattle()
        table.insert(items, {
            text = BATTLE_PET_RELEASE .. "...",
            disabled = isSlotted or inBattle,
            func = function()
                local displayName = petData.customName or petData.speciesName or "Pet"
                StaticPopup_Show("PAO_PET_RELEASE", displayName, nil, petData)
            end
        })
    end
    
    -- Put in Cage...
    if C_PetJournal.PetIsTradable and C_PetJournal.PetIsTradable(petID) then
        local isSlotted = C_PetJournal.PetIsSlotted and C_PetJournal.PetIsSlotted(petID)
        local isHurt = C_PetJournal.PetIsHurt and C_PetJournal.PetIsHurt(petID)
        local cageText = BATTLE_PET_PUT_IN_CAGE .. "..."
        if isSlotted then
            cageText = (BATTLE_PET_PUT_IN_CAGE_SLOTTED or "Put in Cage (Slotted)") .. "..."
        elseif isHurt then
            cageText = (BATTLE_PET_PUT_IN_CAGE_HEALTH or "Put in Cage (Injured)") .. "..."
        end
        table.insert(items, {
            text = cageText,
            disabled = isSlotted or isHurt,
            func = function()
                local displayName = petData.customName or petData.speciesName or "Pet"
                StaticPopup_Show("PAO_PET_CAGE", displayName, nil, petData)
            end
        })
    end
    
    -- ========================================
    -- SEPARATOR
    -- ========================================
    table.insert(items, { separator = true })
    
    -- ========================================
    -- PAO EXTRAS
    -- ========================================
    
    -- Set in Battle Slot (submenu)
    table.insert(items, {
        text = "Set in Battle Slot",
        submenu = {
            {
                text = "Slot 1",
                func = function()
                    C_PetJournal.SetPetLoadOutInfo(1, petID)
                    if Addon.events then Addon.events:emit("LOADOUT:CHANGED", { slot = 1, petID = petID }) end
                end
            },
            {
                text = "Slot 2",
                func = function()
                    C_PetJournal.SetPetLoadOutInfo(2, petID)
                    if Addon.events then Addon.events:emit("LOADOUT:CHANGED", { slot = 2, petID = petID }) end
                end
            },
            {
                text = "Slot 3",
                func = function()
                    C_PetJournal.SetPetLoadOutInfo(3, petID)
                    if Addon.events then Addon.events:emit("LOADOUT:CHANGED", { slot = 3, petID = petID }) end
                end
            }
        }
    })
    
    -- Filter to this Species
    table.insert(items, {
        text = "Filter to this Species",
        func = function()
            local speciesName = petData.speciesName or ""
            local filterText = string.format('species:"%s"', speciesName)
            if Addon.petList and Addon.petList.setFilterText then
                Addon.petList:setFilterText(filterText)
            elseif Addon.filterSection and Addon.filterSection.setFilterText then
                Addon.filterSection:setFilterText(filterText)
            end
        end
    })
    
    -- ========================================
    -- DEBUG (debug mode only)
    -- ========================================
    if pao_settings and pao_settings.debugMode then
        table.insert(items, { separator = true })
        table.insert(items, {
            text = "Dump Pet Info...",
            func = function()
                local dumpText = generatePetDumpText(petData)
                local displayName = petData.customName or petData.speciesName or "Pet"
                showDumpFrame(dumpText, displayName)
            end
        })
    end
    
    return { items = items }
end

-- ============================================================================
-- SPECIES CONTEXT MENU
-- ============================================================================

--[[
  Generate species dump text (debug)
]]
local function generateSpeciesDumpText(speciesID)
    local lines = {}

    local petName, _, petType, _, sourceText, _, _, canBattle, tradable, unique =
        C_PetJournal.GetPetInfoBySpeciesID(speciesID)

    table.insert(lines, "=== Species Info ===")
    table.insert(lines, "speciesID: " .. tostring(speciesID))
    table.insert(lines, "name: " .. tostring(petName or "nil"))
    table.insert(lines, "petType: " .. tostring(petType or "nil"))
    table.insert(lines, "sourceText: " .. tostring(sourceText or "nil"))
    local sourceTypeEnum = Addon.data and Addon.data.speciesSourceType and Addon.data.speciesSourceType[speciesID] or -1
    table.insert(lines, "sourceTypeEnum: " .. tostring(sourceTypeEnum))
    table.insert(lines, "canBattle: " .. tostring(canBattle))
    table.insert(lines, "tradable: " .. tostring(tradable))
    table.insert(lines, "unique: " .. tostring(unique))
    table.insert(lines, "")

    -- Abilities (all 6 with cooldown, turns, type, parsed description)
    table.insert(lines, "=== Abilities ===")
    local idTable, levelTable = {}, {}
    C_PetJournal.GetPetAbilityList(speciesID, idTable, levelTable)
    if idTable then
        local tooltipParser = Addon.tooltipParser
        for i, abilityID in ipairs(idTable) do
            local _, abilityName, _, maxCooldown, unparsedDesc, numTurns, abilityPetType =
                C_PetBattles.GetAbilityInfoByID(abilityID)
            local lvl = levelTable and levelTable[i] or "?"
            table.insert(lines, string.format("[%d] %s (ID: %d, Lv: %s)", i, abilityName or "Unknown", abilityID, tostring(lvl)))
            table.insert(lines, string.format("    Cooldown: %s, Turns: %s, Type: %s",
                tostring(maxCooldown or 0), tostring(numTurns or 1), tostring(abilityPetType or "?")))
            if unparsedDesc then
                if tooltipParser then
                    local abilityInfo = tooltipParser:createAbilityInfo(abilityID, nil, speciesID)
                    if abilityInfo then
                        local parsedDesc = tooltipParser:parseText(abilityInfo, unparsedDesc)
                        local cleanDesc = parsedDesc:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                        table.insert(lines, "    Desc: " .. cleanDesc)
                    else
                        table.insert(lines, "    Raw: " .. unparsedDesc)
                    end
                else
                    table.insert(lines, "    Raw: " .. unparsedDesc)
                end
            end
            table.insert(lines, "")
        end
    end
    table.insert(lines, "")

    -- Possible Breeds (from breedDetection species data)
    table.insert(lines, "=== Possible Breeds ===")
    local breedDetection = Addon.breedDetection
    if breedDetection and breedDetection.getSpeciesData then
        local speciesData = breedDetection:getSpeciesData(speciesID)
        if speciesData and speciesData.breeds then
            for _, breedID in ipairs(speciesData.breeds) do
                local breedName = breedDetection:getBreedName(breedID) or "?"
                table.insert(lines, string.format("  %s (ID: %d)", breedName, breedID))
            end
        else
            table.insert(lines, "(no breed data)")
        end
    else
        table.insert(lines, "(breedDetection not available)")
    end
    table.insert(lines, "")

    -- Owned Pets (with level, rarity, breed for each)
    table.insert(lines, "=== Owned Pets ===")
    local petCache = Addon.petCache
    local cagedCount = 0
    if petCache and petCache.getPetsBySpecies then
        local ownedPets = petCache:getPetsBySpecies(speciesID)
        if ownedPets and #ownedPets > 0 then
            for _, pet in ipairs(ownedPets) do
                if pet.isCaged then
                    cagedCount = cagedCount + 1
                else
                    local breedStr = "?"
                    if breedDetection and pet.petID then
                        local bID, conf, bText = breedDetection:detectBreedByPetID(pet.petID)
                        if bText then
                            breedStr = string.format("%s (%d%%)", bText, conf or 0)
                        end
                    end
                    table.insert(lines, string.format("  %s  L%d  R%d  %s",
                        tostring(pet.petID), pet.level or 0, pet.rarity or 0, breedStr))
                end
            end
            if cagedCount > 0 then
                table.insert(lines, string.format("  Caged: %d", cagedCount))
            end
        else
            table.insert(lines, "(none owned)")
        end
    else
        table.insert(lines, "(petCache not available)")
    end
    table.insert(lines, "")

    -- Collection
    table.insert(lines, "=== Collection ===")
    if petCache and petCache.getPetsBySpecies then
        local allPets = petCache:getPetsBySpecies(speciesID)
        local totalOwned = allPets and #allPets or 0
        table.insert(lines, "totalOwned: " .. tostring(totalOwned))
        if cagedCount > 0 then
            table.insert(lines, "caged: " .. tostring(cagedCount))
        end
    end

    return table.concat(lines, "\n")
end

--[[
  Build menu definition for a species header
  @param speciesID number - Species ID
  @return table - Menu definition for contextMenu factory
]]
local function buildSpeciesMenuDef(speciesID)
    if not speciesID then return { items = {} } end
    local items = {}

    -- Species name for display
    local speciesName = C_PetJournal.GetPetInfoBySpeciesID(speciesID) or "Unknown"

    -- Filter to this Species
    table.insert(items, {
        text = "Filter to this Species",
        func = function()
            local filterText = string.format('species:"%s"', speciesName)
            if Addon.petList and Addon.petList.setFilterText then
                Addon.petList:setFilterText(filterText)
            elseif Addon.filterSection and Addon.filterSection.setFilterText then
                Addon.filterSection:setFilterText(filterText)
            end
        end
    })

    -- Debug dump (debug-gated)
    if pao_settings and pao_settings.debugMode then
        table.insert(items, { separator = true })
        table.insert(items, {
            text = "Dump Species Info...",
            func = function()
                local dumpText = generateSpeciesDumpText(speciesID)
                showDumpFrame(dumpText, speciesName)
            end
        })
    end

    return { items = items }
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Show context menu for pet
  
  @param petData table - Pet data structure
]]
function petListContextMenu:show(petData)
    if not petData or not petData.petID or not petData.owned then return end
    
    local contextMenuFactory = Addon.contextMenu
    if not contextMenuFactory then
        Addon.utils:error("contextMenu factory not available")
        return
    end
    
    local menuDef = buildMenuDef(petData)
    -- New API: contextMenu:show(menuDef, context) - no "cursor" argument
    contextMenuFactory:show(menuDef, petData)
end

--[[
  Show context menu for a species header (right-click on species row)

  @param speciesID number - Species ID
]]
function petListContextMenu:showSpecies(speciesID)
    if not speciesID then return end

    local contextMenuFactory = Addon.contextMenu
    if not contextMenuFactory then
        Addon.utils:error("contextMenu factory not available")
        return
    end

    local menuDef = buildSpeciesMenuDef(speciesID)
    contextMenuFactory:show(menuDef, { speciesID = speciesID })
end

Addon.petListContextMenu = petListContextMenu
return petListContextMenu