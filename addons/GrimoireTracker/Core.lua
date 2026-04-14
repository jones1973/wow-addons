---------------------------------------------------------------------------
-- GrimoireTracker  -  Core.lua
-- Database, spellbook scanning, status classification, events,
-- level-up notifications, price caching.
---------------------------------------------------------------------------

local GT = GrimoireTracker
local BOOKTYPE_PET = "pet"

---------------------------------------------------------------------------
-- Saved-variable bootstrap (SavedVariablesPerCharacter)
---------------------------------------------------------------------------
function GT:InitDB()
    GrimoireTrackerDB = GrimoireTrackerDB or {}
    GrimoireTrackerDB.learned     = GrimoireTrackerDB.learned or {}
    GrimoireTrackerDB.scannedPets = GrimoireTrackerDB.scannedPets or {}
    GrimoireTrackerDB.prices      = GrimoireTrackerDB.prices or {}
    -- windowX, windowY, lastTab are created on demand
    self.db = GrimoireTrackerDB
end

---------------------------------------------------------------------------
-- Get the currently active pet family (or nil).
---------------------------------------------------------------------------
function GT:GetActivePetFamily()
    if not HasPetSpells() then return nil end
    local family = UnitCreatureFamily("pet")
    if not family then return nil end
    if not self.GRIMOIRE_RANKS[family] then
        family = family:sub(1, 1):upper() .. family:sub(2):lower()
    end
    if not self.GRIMOIRE_RANKS[family] then return nil end
    return family
end

---------------------------------------------------------------------------
-- Does the player know how to summon a given pet family?
---------------------------------------------------------------------------
local SUMMON_SPELLS = {
    Imp        = "Summon Imp",
    Voidwalker = "Summon Voidwalker",
    Succubus   = "Summon Succubus",
    Felhunter  = "Summon Felhunter",
    Felguard   = "Summon Felguard",
}

function GT:KnowsPet(pet)
    local spell = SUMMON_SPELLS[pet]
    if not spell then return false end
    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        for j = offset + 1, offset + numSpells do
            local name = GetSpellBookItemName(j, "spell")
            if name == spell then return true end
            if pet == "Succubus" and name == "Summon Incubus" then
                return true
            end
        end
    end
    return false
end

---------------------------------------------------------------------------
-- PET SPELLBOOK SCANNING
---------------------------------------------------------------------------
function GT:ScanPetSpellbook()
    if not self.db then return nil end
    local numSpells = HasPetSpells()
    if not numSpells or numSpells == 0 then return nil end

    local family = self:GetActivePetFamily()
    if not family then return nil end

    if not self.db.learned[family] then
        self.db.learned[family] = {}
    end

    for i = 1, numSpells do
        local spellName, subName = GetSpellBookItemName(i, BOOKTYPE_PET)
        if spellName then
            local rank = 1
            if subName and subName ~= "" then
                rank = tonumber(subName:match("(%d+)")) or 1
            end
            local prev = self.db.learned[family][spellName] or 0
            if rank > prev then
                self.db.learned[family][spellName] = rank
            end
        end
    end

    self.db.scannedPets[family] = true
    return family
end

---------------------------------------------------------------------------
-- STATUS CLASSIFICATION
---------------------------------------------------------------------------
function GT:GetSpellStatus(petFamily, spellName)
    local ranks = self.GRIMOIRE_RANKS[petFamily]
        and self.GRIMOIRE_RANKS[petFamily][spellName]
    if not ranks then return nil end

    local playerLevel = UnitLevel("player")
    local scanned     = self.db.scannedPets[petFamily]
    local knownRank   = (self.db.learned[petFamily]
        and self.db.learned[petFamily][spellName]) or 0
    local isBaseline  = self.BASELINE[petFamily]
        and self.BASELINE[petFamily][spellName] or false
    local maxRank     = ranks[#ranks][1]

    if not scanned then
        if isBaseline and playerLevel >= ranks[1][2] then
            knownRank = 1
        else
            knownRank = 0
        end
    end

    local remainingCount = 0
    for _, entry in ipairs(ranks) do
        if entry[1] > knownRank then
            remainingCount = remainingCount + 1
        end
    end

    local result = {
        spellName      = spellName,
        isBaseline     = isBaseline,
        maxRank        = maxRank,
        knownRank      = knownRank,
        nextRank       = nil,
        nextReqLevel   = nil,
        status         = "maxed",
        remainingCount = remainingCount,
        availableRanks = {},
    }

    if not scanned then
        result.status = "unscanned"
        return result
    end

    if knownRank >= maxRank then
        result.status = "maxed"
        return result
    end

    local availableRanks = {}     -- {rank, reqLevel} pairs buyable now
    local firstFutureRank, firstFutureLevel

    for _, entry in ipairs(ranks) do
        if entry[1] > knownRank then
            if playerLevel >= entry[2] then
                table.insert(availableRanks, { entry[1], entry[2] })
            else
                if not firstFutureRank then
                    firstFutureRank  = entry[1]
                    firstFutureLevel = entry[2]
                end
            end
        end
    end

    result.availableRanks = availableRanks

    if #availableRanks > 0 then
        -- nextRank = highest available (the best rank player can buy now)
        result.nextRank     = availableRanks[#availableRanks][1]
        result.nextReqLevel = availableRanks[#availableRanks][2]
        result.status       = "available"
    elseif firstFutureRank then
        result.nextRank     = firstFutureRank
        result.nextReqLevel = firstFutureLevel
        result.status       = "future"
    end

    return result
end

function GT:GetAllSpellStatuses(petFamily)
    local order = self.SPELL_ORDER[petFamily]
    if not order then return {} end
    local results = {}
    for _, spellName in ipairs(order) do
        local s = self:GetSpellStatus(petFamily, spellName)
        if s then table.insert(results, s) end
    end
    return results
end

function GT:GetSummary(petFamily)
    local statuses = self:GetAllSpellStatuses(petFamily)
    local maxed, available, future, unscanned = 0, 0, 0, 0
    for _, s in ipairs(statuses) do
        if s.status == "maxed" then maxed = maxed + 1
        elseif s.status == "available" then available = available + 1
        elseif s.status == "future" then future = future + 1
        elseif s.status == "unscanned" then unscanned = unscanned + 1
        end
    end
    return maxed, available, future, unscanned
end

function GT:HasScannedPet(petFamily)
    return self.db and self.db.scannedPets[petFamily] == true
end

function GT:UpdateIfVisible(petFamily)
    if self.mainFrame and self.mainFrame:IsShown() then
        self:RefreshUI(petFamily or self.selectedPet)
    end
end

---------------------------------------------------------------------------
-- PRICE CACHE  (populated from vendor visits, stored in SavedVariables)
---------------------------------------------------------------------------
function GT:GetPrice(petFamily, spellName, rank)
    local p = self.db and self.db.prices
    if not p or not p[petFamily] then return nil end
    if not p[petFamily][spellName] then return nil end
    return p[petFamily][spellName][rank]
end

function GT:CachePrice(petFamily, spellName, rank, copper)
    if not self.db then return end
    self.db.prices = self.db.prices or {}
    if not self.db.prices[petFamily] then
        self.db.prices[petFamily] = {}
    end
    if not self.db.prices[petFamily][spellName] then
        self.db.prices[petFamily][spellName] = {}
    end
    self.db.prices[petFamily][spellName][rank] = copper
end

---------------------------------------------------------------------------
-- Cost formatting  (gold/silver/copper with WoW coin icons)
---------------------------------------------------------------------------
local GOLD_ICON   = "|TInterface\\MoneyFrame\\UI-GoldIcon:0|t"
local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:0|t"
local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:0|t"

function GT:FormatCostText(copper)
    if not copper or copper <= 0 then return "" end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    local parts = {}
    if g > 0 then table.insert(parts, g .. GOLD_ICON) end
    if s > 0 or g > 0 then
        table.insert(parts, string.format("%d", s) .. SILVER_ICON)
    end
    if c > 0 and g == 0 then
        table.insert(parts, string.format("%d", c) .. COPPER_ICON)
    end
    return table.concat(parts, " ")
end

function GT:FormatCostPlain(copper)
    if not copper or copper <= 0 then return "" end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    local parts = {}
    if g > 0 then table.insert(parts, g .. "g") end
    if s > 0 then table.insert(parts, s .. "s") end
    if c > 0 and g == 0 then table.insert(parts, c .. "c") end
    return table.concat(parts, " ")
end

---------------------------------------------------------------------------
-- Reverse lookup: find which pet owns a spell name
---------------------------------------------------------------------------
function GT:FindPetForSpell(spellName)
    for pet, spells in pairs(self.GRIMOIRE_RANKS) do
        if spells[spellName] then return pet end
    end
    return nil
end

---------------------------------------------------------------------------
-- LEVEL-UP NOTIFICATIONS
---------------------------------------------------------------------------
local PREFIX = "|cff9370dbGrimoire Tracker|r"

function GT:NotifyNewGrimoires(newLevel)
    if not newLevel then return end

    local newlyAvailable = {}

    for _, pet in ipairs(self.PET_ORDER) do
        if self:KnowsPet(pet) then
            local spells = self.GRIMOIRE_RANKS[pet]
            if spells then
                for spellName, ranks in pairs(spells) do
                    local knownRank = 0
                    if self.db and self.db.learned[pet] then
                        knownRank = self.db.learned[pet][spellName] or 0
                    end
                    if knownRank == 0 and self.BASELINE[pet]
                       and self.BASELINE[pet][spellName] then
                        knownRank = 1
                    end

                    for _, entry in ipairs(ranks) do
                        local rank, reqLevel = entry[1], entry[2]
                        if reqLevel == newLevel and rank > knownRank then
                            local display
                            if #ranks == 1 then
                                display = "|cffcc99ff" .. spellName .. "|r"
                            else
                                display = "|cffcc99ff" .. spellName ..
                                          "|r |cffe6cc80Rank " ..
                                          rank .. "|r"
                            end
                            table.insert(newlyAvailable, display)
                        end
                    end
                end
            end
        end
    end

    if #newlyAvailable == 0 then return end

    PlaySound(8959)  -- treasure ding
    print(PREFIX .. " |cff00ff00New grimoires available!|r")
    print("  " .. table.concat(newlyAvailable, ", "))
end

---------------------------------------------------------------------------
-- EVENT HANDLING
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("PET_BAR_UPDATE")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "GrimoireTracker" then
        GT:InitDB()
        C_Timer.After(1, function() GT:ScanPetSpellbook() end)

    elseif event == "PLAYER_LEVEL_UP" then
        local newLevel = arg1
        GT:ScanPetSpellbook()
        GT:NotifyNewGrimoires(newLevel)
        GT:UpdateIfVisible()

    elseif event == "UNIT_PET" and arg1 == "player" then
        C_Timer.After(0.5, function()
            local family = GT:ScanPetSpellbook()
            GT:UpdateIfVisible(family)
        end)

    elseif event == "PET_BAR_UPDATE" or event == "SPELLS_CHANGED" then
        C_Timer.After(0.3, function()
            GT:ScanPetSpellbook()
            GT:UpdateIfVisible()
        end)

    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
            if GT.db then GT:ScanPetSpellbook() end
        end)
    end
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
SLASH_GRIMOIRETRACKER1 = "/grimoire"
SLASH_GRIMOIRETRACKER2 = "/gt"
SlashCmdList["GRIMOIRETRACKER"] = function(msg)
    msg = (msg or ""):lower():trim()

    if msg == "show" then msg = "" end

    if msg == "reset" then
        GrimoireTrackerDB = nil
        GT:InitDB()
        local family = GT:ScanPetSpellbook()
        if family then
            print("|cff9370dbGrimoireTracker:|r Data reset. Rescanned " ..
                  family .. ".")
        else
            print("|cff9370dbGrimoireTracker:|r Data reset.")
        end
        GT:UpdateIfVisible(family)
        return
    end

    if msg == "dump" then
        if GT.DumpVendorGrimoires then
            GT.DumpVendorGrimoires()
        else
            print("|cff9370dbGrimoireTracker:|r Dump not available.")
        end
        return
    end

    -- Toggle window.
    if GT.mainFrame and GT.mainFrame:IsShown() then
        GT.mainFrame:Hide()
    else
        local activePet = GT:GetActivePetFamily()
        GT:RefreshUI(activePet or GT.selectedPet or "Imp")
    end
end