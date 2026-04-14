---------------------------------------------------------------------------
-- GrimoireTracker  -  Vendor.lua
-- Highlights recommended grimoires at the demon trainer (all pets).
-- Popup with per-pet sections, expandable rank radio buttons, auto-use.
--
-- Highlighting: lavender additive border + row tint, both pulsing.
-- Tooltip parsing handles TBC Anniversary and other client formats.
---------------------------------------------------------------------------

local GT = GrimoireTracker

---------------------------------------------------------------------------
-- Hidden scanning tooltip
---------------------------------------------------------------------------
local scanTip = CreateFrame("GameTooltip", "GTScanTooltip", nil,
                            "GameTooltipTemplate")
scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")

local function GetTooltipLines()
    local lines = {}
    for i = 1, scanTip:NumLines() do
        local region = _G["GTScanTooltipTextLeft" .. i]
        if region then
            local text = region:GetText()
            if text then table.insert(lines, text) end
        end
    end
    return lines
end

---------------------------------------------------------------------------
-- Tooltip parsing
-- TBC Anniversary: "Use: Teaches Imp Firebolt (Rank 2)."
---------------------------------------------------------------------------
local REQ_LEVEL = "Requires Level (%d+)"

local function ExtractFromLines(lines)
    local petFamily, spellName, rank
    local reqLevel = 0
    for _, text in ipairs(lines) do
        if not petFamily then
            local body = text:match("^Use: (.+)") or text

            -- Strip "your" if present
            local inner = body:match("Teaches your (.+)") or
                          body:match("Teaches (.+)")
            if inner then
                -- Handle "Succubus or Incubus <Spell> (Rank N)"
                -- and    "Succubus or Incubus <Spell>."
                local rest = inner:match("^Succubus or Incubus (.+)")
                local pet
                if rest then
                    pet  = "Succubus"
                    inner = rest
                else
                    -- Normal: first word is pet, rest is spell
                    pet, inner = inner:match("^(%S+) (.+)")
                end

                if pet and pet ~= "your" and inner then
                    local spell, r = inner:match("^(.+) %(Rank (%d+)%)")
                    if spell then
                        petFamily = pet
                        spellName = spell:match("^(.-)%s*$")
                        rank      = tonumber(r)
                    else
                        -- Single-rank: "SpellName."
                        spell = inner:match("^(.-)%.")
                        if spell and spell ~= "" then
                            petFamily = pet
                            spellName = spell:match("^(.-)%s*$")
                            rank      = 1
                        end
                    end
                end
            end
        end
        local lvl = text:match(REQ_LEVEL)
        if lvl then reqLevel = tonumber(lvl) end
    end
    return petFamily, spellName, rank, reqLevel
end

local function ParseGrimoireTooltip(merchantIndex)
    scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
    scanTip:ClearLines()
    scanTip:SetMerchantItem(merchantIndex)
    local lines = GetTooltipLines()
    if #lines == 0 then
        local link = GetMerchantItemLink(merchantIndex)
        if link then
            scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
            scanTip:ClearLines()
            scanTip:SetHyperlink(link)
            lines = GetTooltipLines()
        end
    end
    if #lines == 0 then return nil, nil, nil, 0 end
    return ExtractFromLines(lines)
end

---------------------------------------------------------------------------
-- Highlight management  -  Lavender border + row tint, both pulsing.
---------------------------------------------------------------------------
local highlights = {}

local function EnsureHighlight(slot)
    if highlights[slot] then return highlights[slot] end
    local itemButton = _G["MerchantItem" .. slot .. "ItemButton"]
    local slotFrame  = _G["MerchantItem" .. slot]
    if not itemButton or not slotFrame then return nil end

    local border = itemButton:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetVertexColor(0.7, 0.4, 1.0, 1)
    local w, h = itemButton:GetSize()
    border:SetSize(w * 1.7, h * 1.7)
    border:SetPoint("CENTER", itemButton, "CENTER")

    local ag = border:CreateAnimationGroup()
    ag:SetLooping("BOUNCE")
    local p = ag:CreateAnimation("Alpha")
    p:SetFromAlpha(1); p:SetToAlpha(0.35)
    p:SetDuration(0.8); p:SetSmoothing("IN_OUT")

    local tint = slotFrame:CreateTexture(nil, "ARTWORK", nil, 7)
    tint:SetAllPoints(slotFrame)
    tint:SetColorTexture(0.55, 0.30, 0.80, 0.35)

    local tAG = tint:CreateAnimationGroup()
    tAG:SetLooping("BOUNCE")
    local tp = tAG:CreateAnimation("Alpha")
    tp:SetFromAlpha(1); tp:SetToAlpha(0.3)
    tp:SetDuration(0.8); tp:SetSmoothing("IN_OUT")

    highlights[slot] = { border=border, tint=tint, animGroup=ag, tintAG=tAG }
    return highlights[slot]
end

local function ShowHighlight(slot)
    local h = EnsureHighlight(slot)
    if h then
        h.border:Show(); h.tint:Show()
        h.animGroup:Play(); h.tintAG:Play()
    end
end

local function HideAllHighlights()
    for _, h in pairs(highlights) do
        h.border:Hide(); h.tint:Hide()
        h.animGroup:Stop(); h.tintAG:Stop()
    end
end

---------------------------------------------------------------------------
-- Merchant index -> visible slot
---------------------------------------------------------------------------
local function MerchantIndexToSlot(mIdx)
    local page    = MerchantFrame.page or 1
    local perPage = MERCHANT_ITEMS_PER_PAGE or 10
    local first = (page - 1) * perPage + 1
    if mIdx >= first and mIdx <= first + perPage - 1 then
        return mIdx - first + 1
    end
    return nil
end

---------------------------------------------------------------------------
-- Build data: collect ALL affordable ranks per spell per pet.
--
-- Returns:
--   bestRecs  - flat list, highest rank per spell (for highlighting)
--   allByPet  - { [pet] = { [spell] = { {merchantIdx, rank, cost, itemName}, ... } } }
--               each spell's ranks sorted descending (highest first)
---------------------------------------------------------------------------
local lastBestRecs = {}
local lastAllByPet = {}

local function BuildRecommendedList()
    local numItems = GetMerchantNumItems()
    if not numItems or numItems == 0 then return {}, {}, 0 end
    if not GT.db then return {}, {}, 0 end

    local playerLevel = UnitLevel("player")
    local allRanks    = {}   -- [pet][spell] = list of rank entries
    local unresolved  = 0    -- grimoire items whose tooltip hasn't loaded

    for i = 1, numItems do
        local itemName, _, price = GetMerchantItemInfo(i)
        if itemName then
            local petFamily, spellName, rank, reqLevel =
                ParseGrimoireTooltip(i)

            if petFamily and spellName and rank
               and GT.GRIMOIRE_RANKS[petFamily]
               and GT:HasScannedPet(petFamily) then

                local knownRank = (GT.db.learned[petFamily]
                    and GT.db.learned[petFamily][spellName]) or 0

                if rank > knownRank
                   and (reqLevel <= 0 or playerLevel >= reqLevel) then
                    if not allRanks[petFamily] then
                        allRanks[petFamily] = {}
                    end
                    if not allRanks[petFamily][spellName] then
                        allRanks[petFamily][spellName] = {}
                    end
                    table.insert(allRanks[petFamily][spellName], {
                        merchantIdx = i,
                        rank        = rank,
                        cost        = price or 0,
                        itemName    = itemName,
                    })
                end
            elseif not petFamily and itemName:find("^Grimoire") then
                -- Item looks like a grimoire but tooltip didn't parse
                unresolved = unresolved + 1
            end
        end
    end

    -- Sort ranks descending; build flat best-rec list for highlighting
    local bestRecs = {}
    local allByPet = {}
    for pet, spells in pairs(allRanks) do
        allByPet[pet] = {}
        for spell, ranks in pairs(spells) do
            table.sort(ranks, function(a, b) return a.rank > b.rank end)
            allByPet[pet][spell] = ranks
            -- Best = first entry (highest rank)
            table.insert(bestRecs, {
                merchantIdx = ranks[1].merchantIdx,
                petFamily   = pet,
                spellName   = spell,
                rank        = ranks[1].rank,
                cost        = ranks[1].cost,
                itemName    = ranks[1].itemName,
            })
        end
    end

    return bestRecs, allByPet, unresolved
end

---------------------------------------------------------------------------
-- Bag scan: returns set of grimoire item names currently in bags
---------------------------------------------------------------------------
local _GetContainerNumSlots = C_Container and C_Container.GetContainerNumSlots
                              or GetContainerNumSlots
local _GetContainerItemLink = C_Container and C_Container.GetContainerItemLink
                              or GetContainerItemLink

local bagGrimoires = {}  -- [itemName] = true

local function ScanBagsForGrimoires()
    wipe(bagGrimoires)
    for bag = 0, 4 do
        local slots = _GetContainerNumSlots(bag)
        if slots and slots > 0 then
            for slot = 1, slots do
                local link = _GetContainerItemLink(bag, slot)
                if link then
                    local name = GetItemInfo(link)
                    if name and name:find("^Grimoire of ") then
                        bagGrimoires[name] = true
                    end
                end
            end
        end
    end
end

---------------------------------------------------------------------------
-- Apply highlights to merchant frame
---------------------------------------------------------------------------
local SpellKey      -- forward declaration (defined later with popup state)
local pState        -- forward declaration
local FindRankData  -- forward declaration
local function HighlightMerchant()
    HideAllHighlights()
    if not MerchantFrame or not MerchantFrame:IsShown() then return end
    if not GT.db then return end

    local pet = GT:GetActivePetFamily()
    if pet then GT:ScanPetSpellbook() end

    lastBestRecs, lastAllByPet = BuildRecommendedList()
    ScanBagsForGrimoires()

    -- Highlight the selected rank (or best if no selection), skip if in bags
    for _, rec in ipairs(lastBestRecs) do
        local key = SpellKey(rec.petFamily, rec.spellName)
        local selRank = pState and pState.selected[key]
        local idx = rec.merchantIdx
        local itemName = rec.itemName

        if selRank and lastAllByPet[rec.petFamily]
           and lastAllByPet[rec.petFamily][rec.spellName] then
            local r = FindRankData(
                lastAllByPet[rec.petFamily][rec.spellName], selRank)
            if r then
                idx = r.merchantIdx
                itemName = r.itemName
            end
        end

        -- Skip highlight if this grimoire is already in bags
        if not (itemName and bagGrimoires[itemName]) then
            local slot = MerchantIndexToSlot(idx)
            if slot then ShowHighlight(slot) end
        end
    end
end

---------------------------------------------------------------------------
-- Cost formatting  -  Natural gold, 2-digit silver/copper
---------------------------------------------------------------------------
local function FormatCost(copper)
    if not copper or copper <= 0 then
        return "|cffffd7000g|r |cffc0c0c000s|r |cffeda55f00c|r"
    end
    local g = math.floor(copper / 10000)
    local s = math.floor((copper % 10000) / 100)
    local c = copper % 100
    return string.format(
        "|cffffd700%dg|r |cffc0c0c0%02ds|r |cffeda55f%02dc|r",
        g, s, c)
end

---------------------------------------------------------------------------
-- Pet color helper
---------------------------------------------------------------------------
local function PetCC(pet)
    local c = GT.PET_COLORS and GT.PET_COLORS[pet]
    return c and ("|c" .. c) or GT.CLR.name
end

---------------------------------------------------------------------------
-- Popup constants & state
---------------------------------------------------------------------------
local POPUP_BD = {
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    tile     = true, tileSize = 32, edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
}
local POPUP_W        = 400
local POPUP_ICON     = 28       -- pet icon size
local POPUP_SP_ICON  = 20       -- spell icon size (smaller = child)
local POPUP_ROW_H    = 32       -- pet row height
local POPUP_SP_ROW_H = 24       -- spell row height
local POPUP_PET_GAP  = 18
local POPUP_INDENT   = 34
local POPUP_CB_SIZE  = 22
local POPUP_RADIO_SZ = 18
local POPUP_COST_W   = 130

local buyAllFrame
local popupSpells  = {}   -- { cb, pet, spell, ranks, key }
local popupPetCBs  = {}

-- Persistent state across popup refreshes (within one merchant visit)
pState = {
    selected = {},   -- [key] = rank number  (radio selection)
    expanded = {},   -- [key] = bool
    checked  = {},   -- [key] = bool
}
SpellKey = function(pet, spell) return pet .. ":" .. spell end

-- Find a rank entry in a ranks list by rank number
FindRankData = function(ranks, rank)
    for _, r in ipairs(ranks) do
        if r.rank == rank then return r end
    end
    return nil
end

---------------------------------------------------------------------------
-- Widget pools
---------------------------------------------------------------------------
local poolCBs, poolIcons, poolLabels, poolRadios, poolBtns, poolClicks
    = {},{},{},{},{},{}
local poolIdxCB, poolIdxIcon, poolIdxLabel, poolIdxRadio, poolIdxBtn,
    poolIdxClick = 0, 0, 0, 0, 0, 0

local function HideAllPopupWidgets()
    for _, w in ipairs(poolCBs)    do w:Hide() end
    for _, w in ipairs(poolIcons)  do w:Hide() end
    for _, w in ipairs(poolLabels) do w:Hide() end
    for _, w in ipairs(poolRadios) do w:Hide() end
    for _, w in ipairs(poolBtns)   do w:Hide() end
    for _, w in ipairs(poolClicks) do w:Hide(); w:SetScript("OnClick", nil) end
    poolIdxCB, poolIdxIcon, poolIdxLabel, poolIdxRadio, poolIdxBtn,
        poolIdxClick = 0, 0, 0, 0, 0, 0
    wipe(popupSpells)
    wipe(popupPetCBs)
end

-- Checkbox (with indeterminate dash support)
local function AllocCheckbox(parent, size)
    poolIdxCB = poolIdxCB + 1
    local cb = poolCBs[poolIdxCB]
    if not cb then
        cb = CreateFrame("CheckButton", nil, parent)
        cb.bg = cb:CreateTexture(nil, "BACKGROUND")
        cb.bg:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
        cb.bg:SetAllPoints()
        cb.check = cb:CreateTexture(nil, "ARTWORK")
        cb.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        cb.check:SetAllPoints()
        cb.dash = cb:CreateTexture(nil, "ARTWORK")
        cb.dash:SetColorTexture(0.8, 0.7, 1.0, 0.9)
        cb.dash:SetSize(size * 0.5, 3)
        cb.dash:SetPoint("CENTER", 0, 0)
        cb.dash:Hide()
        cb.hl = cb:CreateTexture(nil, "HIGHLIGHT")
        cb.hl:SetTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
        cb.hl:SetAllPoints(); cb.hl:SetBlendMode("ADD")
        poolCBs[poolIdxCB] = cb
    end
    cb:SetParent(parent); cb:SetSize(size, size)
    cb:SetChecked(true); cb.check:Show(); cb.dash:Hide()
    cb.dash:SetSize(size * 0.5, 3)
    cb.bg:SetDesaturated(false); cb.bg:SetAlpha(1)
    cb:Enable()
    cb:ClearAllPoints(); cb:Show()
    return cb
end

-- Radio button (simple dot-in-circle)
local function AllocRadio(parent, size)
    poolIdxRadio = poolIdxRadio + 1
    local rb = poolRadios[poolIdxRadio]
    if not rb then
        rb = CreateFrame("CheckButton", nil, parent)
        -- Unchecked ring (always visible)
        rb.bg = rb:CreateTexture(nil, "BACKGROUND")
        rb.bg:SetTexture("Interface\\Buttons\\UI-RadioButton")
        rb.bg:SetTexCoord(0, 0.25, 0, 1)  -- unchecked state
        rb.bg:SetAllPoints()
        -- Checked dot (shown when selected)
        rb.sel = rb:CreateTexture(nil, "OVERLAY")
        rb.sel:SetTexture("Interface\\Buttons\\UI-RadioButton")
        rb.sel:SetTexCoord(0.25, 0.5, 0, 1)  -- checked state
        rb.sel:SetAllPoints()
        rb.sel:Hide()
        -- Highlight
        rb.hl = rb:CreateTexture(nil, "HIGHLIGHT")
        rb.hl:SetTexture("Interface\\Buttons\\UI-RadioButton")
        rb.hl:SetTexCoord(0.5, 0.75, 0, 1)  -- highlight state
        rb.hl:SetAllPoints()
        rb.hl:SetBlendMode("ADD")
        poolRadios[poolIdxRadio] = rb
    end
    rb:SetParent(parent); rb:SetSize(size, size)
    rb:SetChecked(false); rb.sel:Hide()
    rb.bg:SetDesaturated(false); rb.bg:SetAlpha(1)
    rb:Enable()
    rb:ClearAllPoints(); rb:Show()
    return rb
end

-- Icon (always on buyAllFrame)
local function AllocIcon(size)
    poolIdxIcon = poolIdxIcon + 1
    local ic = poolIcons[poolIdxIcon]
    if not ic then
        ic = buyAllFrame:CreateTexture(nil, "ARTWORK")
        poolIcons[poolIdxIcon] = ic
    end
    ic:SetSize(size, size); ic:ClearAllPoints()
    ic:SetDesaturated(false); ic:SetAlpha(1)
    ic:Show()
    return ic
end

-- Label (always on buyAllFrame)
local function AllocLabel(template)
    poolIdxLabel = poolIdxLabel + 1
    local lb = poolLabels[poolIdxLabel]
    if not lb then
        lb = buyAllFrame:CreateFontString(nil, "OVERLAY", template)
        poolLabels[poolIdxLabel] = lb
    end
    lb:SetFontObject(_G[template] or GameFontNormal)
    lb:SetWidth(0)  -- clear fixed width
    lb:SetJustifyH("LEFT")
    lb:ClearAllPoints(); lb:SetText(""); lb:Show()
    return lb
end

-- Small clickable button (chevron toggle)
local function AllocBtn(parent, size)
    poolIdxBtn = poolIdxBtn + 1
    local btn = poolBtns[poolIdxBtn]
    if not btn then
        btn = CreateFrame("Button", nil, parent)
        btn.tex = btn:CreateTexture(nil, "ARTWORK")
        btn.tex:SetAllPoints()
        poolBtns[poolIdxBtn] = btn
    end
    btn:SetParent(parent); btn:SetSize(size, size)
    btn:ClearAllPoints(); btn:Show()
    btn.tex:Show()
    if btn.label then btn.label:Hide() end
    return btn
end

-- Click-catcher: invisible button overlaying a FontString to forward clicks
local function ClickOnLabel(fontString, onClick)
    poolIdxClick = poolIdxClick + 1
    local cc = poolClicks[poolIdxClick]
    if not cc then
        cc = CreateFrame("Button", nil, buyAllFrame)
        poolClicks[poolIdxClick] = cc
    end
    cc:SetParent(fontString:GetParent() or buyAllFrame)
    cc:ClearAllPoints()
    cc:SetAllPoints(fontString)
    cc:SetFrameLevel((fontString:GetParent()
        and fontString:GetParent():GetFrameLevel() or 0) + 10)
    cc:SetScript("OnClick", onClick)
    cc:Show()
    return cc
end

---------------------------------------------------------------------------
-- Update "Buy All" / "Buy Selected" and total
---------------------------------------------------------------------------
local function UpdateBuyButton()
    if not buyAllFrame then return end
    local f = buyAllFrame
    local totalAll, totalChecked, selectedCost = 0, 0, 0

    for _, sp in ipairs(popupSpells) do
        totalAll = totalAll + 1
        if sp.cb:GetChecked() then
            totalChecked = totalChecked + 1
            local r = FindRankData(sp.ranks, pState.selected[sp.key])
            if r then selectedCost = selectedCost + r.cost end
        end
    end

    if totalChecked == totalAll and totalAll > 0 then
        f.buyBtn:SetText("Buy All")
    else
        f.buyBtn:SetText("Buy Selected")
    end
    f.totalText:SetText(GT.CLR.caption .. "Total:  " ..
                         FormatCost(selectedCost) .. "|r")
    f.buyBtn:SetEnabled(totalChecked > 0)
end

---------------------------------------------------------------------------
-- Sync pet checkbox (all / none / indeterminate)
---------------------------------------------------------------------------
local function SyncPetCheckbox(petCB)
    local total, checked = 0, 0
    for _, sp in ipairs(popupSpells) do
        if sp.pet == petCB.pet and sp.cb:IsEnabled() then
            total = total + 1
            if sp.cb:GetChecked() then checked = checked + 1 end
        end
    end
    if total == 0 or checked == total then
        petCB:SetChecked(total > 0); petCB.check:SetShown(total > 0)
        petCB.dash:Hide()
    elseif checked == 0 then
        petCB:SetChecked(false); petCB.check:Hide(); petCB.dash:Hide()
    else
        petCB:SetChecked(false); petCB.check:Hide(); petCB.dash:Show()
    end
end

---------------------------------------------------------------------------
-- Create popup frame (once)
---------------------------------------------------------------------------
local function CreateBuyAllFrame()
    local f = CreateFrame("Frame", "GrimoireTrackerBuyAll", UIParent,
                          "BackdropTemplate")
    f:SetSize(POPUP_W, 100)
    f:SetBackdrop(POPUP_BD)
    f:SetBackdropColor(0.1, 0.08, 0.15, 0.95)
    f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if MerchantFrame and MerchantFrame:IsShown() then
            self._defaultLeft = (MerchantFrame:GetRight() or 0) + 2
            self._defaultTop  = MerchantFrame:GetTop() or 0
        end
        self:StartMoving()
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self._userMoved = true
        if self._defaultLeft and self._defaultTop then
            local dx = math.abs((self:GetLeft() or 0) - self._defaultLeft)
            local dy = math.abs((self:GetTop()  or 0) - self._defaultTop)
            if dx < 40 and dy < 40 then
                self._userMoved = false
                self:ClearAllPoints()
                self:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 2, 0)
            end
        end
    end)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("DIALOG")

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOP", 0, -14)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() f:Hide() end)

    f.sep = f:CreateTexture(nil, "ARTWORK")
    f.sep:SetColorTexture(0.4, 0.3, 0.6, 0.5)
    f.sep:SetHeight(1)
    f.sep:SetPoint("TOPLEFT", 14, -36)
    f.sep:SetPoint("TOPRIGHT", -14, -36)

    f.totalText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.totalText:SetJustifyH("RIGHT")

    f.sepBottom = f:CreateTexture(nil, "ARTWORK")
    f.sepBottom:SetColorTexture(0.4, 0.3, 0.6, 0.3)
    f.sepBottom:SetHeight(1)

    f.buyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.buyBtn:SetSize(140, 26)
    f.buyBtn:SetText("Buy All")

    -- Loading state
    f.loadingText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.loadingText:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.loadingText:SetText(GT.CLR.name .. "Scanning grimoires...|r")
    f.loadingText:Hide()

    f.loadingAG = f.loadingText:CreateAnimationGroup()
    f.loadingAG:SetLooping("BOUNCE")
    local pulse = f.loadingAG:CreateAnimation("Alpha")
    pulse:SetFromAlpha(1); pulse:SetToAlpha(0.3)
    pulse:SetDuration(0.6); pulse:SetSmoothing("IN_OUT")

    f:Hide()
    return f
end

---------------------------------------------------------------------------
-- Show popup in loading state
---------------------------------------------------------------------------
local function ShowLoadingPopup()
    if not buyAllFrame then buyAllFrame = CreateBuyAllFrame() end
    local f = buyAllFrame
    HideAllPopupWidgets()

    f.title:SetText(GT.CLR.name .. "Best Available Grimoires|r")

    -- Position
    if not f._userMoved then
        f:ClearAllPoints()
        if MerchantFrame and MerchantFrame:IsShown() then
            f:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 2, 0)
        else
            f:SetPoint("TOP", UIParent, "TOP", 0, -80)
        end
    end

    -- Hide content elements
    f.sepBottom:Hide()
    f.totalText:SetText("")
    f.buyBtn:Hide()

    -- Show loading
    f.loadingText:Show()
    f.loadingAG:Play()

    f:SetHeight(110)
    f:Show()
end

---------------------------------------------------------------------------
-- Show / refresh popup
---------------------------------------------------------------------------
local function ShowBuyAllPopup()
    if not buyAllFrame then buyAllFrame = CreateBuyAllFrame() end
    local f = buyAllFrame

    -- Hide loading state
    f.loadingText:Hide()
    f.loadingAG:Stop()

    HideAllPopupWidgets()
    ScanBagsForGrimoires()

    -- Determine which pets to show
    local petOrder = {}
    for _, pet in ipairs(GT.PET_ORDER) do
        if lastAllByPet[pet] and GT:KnowsPet(pet)
           and GT:HasScannedPet(pet) then
            local n = 0
            for _ in pairs(lastAllByPet[pet]) do n = n + 1 end
            if n > 0 then table.insert(petOrder, pet) end
        end
    end

    if #petOrder == 0 then f:Hide(); return end

    f.title:SetText(GT.CLR.name .. "Best Available Grimoires|r")

    -- Position: default to MerchantFrame top-right; respect user drag
    if not f._userMoved then
        f:ClearAllPoints()
        if MerchantFrame and MerchantFrame:IsShown() then
            f:SetPoint("TOPLEFT", MerchantFrame, "TOPRIGHT", 2, 0)
        else
            f:SetPoint("TOP", UIParent, "TOP", 0, -80)
        end
    end

    local yOff = -66   -- content start below separator

    for pi, pet in ipairs(petOrder) do
        local spells = lastAllByPet[pet]
        if pi > 1 then yOff = yOff - POPUP_PET_GAP end

        local petCC = PetCC(pet)

        -- Ordered spell list following SPELL_ORDER, with fallback
        local orderedSpells = {}
        if GT.SPELL_ORDER[pet] then
            for _, sp in ipairs(GT.SPELL_ORDER[pet]) do
                if spells[sp] then
                    table.insert(orderedSpells, {name=sp, ranks=spells[sp]})
                end
            end
        end
        for sp, ranks in pairs(spells) do
            local found = false
            for _, o in ipairs(orderedSpells) do
                if o.name == sp then found = true; break end
            end
            if not found then
                table.insert(orderedSpells, {name=sp, ranks=ranks})
            end
        end

        ---------------------------------------------------------------
        -- Pet header: [checkbox] [icon] PetName (count)
        ---------------------------------------------------------------
        local petCB = AllocCheckbox(f, POPUP_CB_SIZE)
        petCB:SetPoint("TOPLEFT", f, "TOPLEFT", 14, yOff)
        petCB.pet = pet

        local petIcon = AllocIcon(POPUP_ICON)
        petIcon:SetPoint("LEFT", petCB, "RIGHT", 4, 0)
        local petIconPath = GT.PET_ICONS and GT.PET_ICONS[pet]
        petIcon:SetTexture(petIconPath and petIconPath ~= ""
            and petIconPath or "Interface\\Icons\\INV_Misc_QuestionMark")

        local petLabel = AllocLabel("GameFontNormal")
        petLabel:SetJustifyH("LEFT")
        petLabel:SetPoint("LEFT", petIcon, "RIGHT", 6, 0)
        petLabel:SetText(petCC .. pet ..
                         " (" .. #orderedSpells .. ")|r")
        local thisPetCBRef = petCB
        ClickOnLabel(petLabel, function() thisPetCBRef:Click() end)

        yOff = yOff - (POPUP_ROW_H + 1)
        table.insert(popupPetCBs, petCB)

        ---------------------------------------------------------------
        -- Spell rows
        ---------------------------------------------------------------
        for _, spInfo in ipairs(orderedSpells) do
            local spell = spInfo.name
            local ranks = spInfo.ranks
            local key   = SpellKey(pet, spell)

            -- Defaults: highest rank, checked
            if pState.selected[key] == nil then
                pState.selected[key] = ranks[1].rank
            end
            if pState.checked[key] == nil then
                pState.checked[key] = true
            end

            -- Find data for selected rank
            local selRank = pState.selected[key]
            local selData = FindRankData(ranks, selRank)
            if not selData then
                selData = ranks[1]
                pState.selected[key] = ranks[1].rank
            end

            -- Check if selected rank's grimoire is already in bags
            local inBags = selData.itemName and bagGrimoires[selData.itemName]
            if inBags then
                pState.checked[key] = false
            end

            -- Spell checkbox
            local spCB = AllocCheckbox(f, POPUP_CB_SIZE)
            spCB:SetPoint("TOPLEFT", f, "TOPLEFT",
                           14 + POPUP_INDENT, yOff)
            if inBags then
                spCB:SetChecked(false)
                spCB.check:Hide()
                spCB:Disable()
                spCB.bg:SetDesaturated(true)
                spCB.bg:SetAlpha(0.4)
            else
                spCB:SetChecked(pState.checked[key])
                if pState.checked[key] then
                    spCB.check:Show()
                else
                    spCB.check:Hide()
                end
                spCB:Enable()
                spCB.bg:SetDesaturated(false)
                spCB.bg:SetAlpha(1)
            end

            -- Spell icon
            local spIcon = AllocIcon(POPUP_SP_ICON)
            spIcon:SetPoint("LEFT", spCB, "RIGHT", 4, 0)
            local iconPath = GT.SPELL_ICONS and GT.SPELL_ICONS[spell]
                or "Interface\\Icons\\INV_Misc_QuestionMark"
            spIcon:SetTexture(iconPath)
            spIcon:SetDesaturated(inBags and true or false)
            if inBags then spIcon:SetAlpha(0.4) else spIcon:SetAlpha(1) end

            -- Spell label: show selected rank
            local spLabel = AllocLabel("GameFontHighlightSmall")
            spLabel:SetJustifyH("LEFT")
            spLabel:SetPoint("LEFT", spIcon, "RIGHT", 6, 0)
            local label
            if inBags then
                label = GT.CLR.dim .. spell
                if selData.rank > 1 or #ranks > 1 then
                    label = label .. " (Rank " .. selData.rank .. ")"
                end
                label = label .. "  (In Bags)|r"
            else
                label = GT.CLR.name .. spell .. "|r"
                if selData.rank > 1 or #ranks > 1 then
                    label = label .. " " .. GT.CLR.rank ..
                            "(Rank " .. selData.rank .. ")|r"
                end
            end
            spLabel:SetText(label)
            local thisSpCB = spCB
            if not inBags then
                ClickOnLabel(spLabel, function() thisSpCB:Click() end)
            end

            -- Cost of selected rank
            local costLbl = AllocLabel("GameFontHighlightSmall")
            costLbl:SetJustifyH("RIGHT")
            costLbl:SetWidth(POPUP_COST_W)
            costLbl:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, yOff)
            if inBags then
                costLbl:SetText(GT.CLR.dim .. "--|r")
            else
                costLbl:SetText(FormatCost(selData.cost))
                ClickOnLabel(costLbl, function() thisSpCB:Click() end)
            end

            -- Inline expand/collapse button (only if multiple ranks)
            local hasMulti = #ranks > 1
            if hasMulti then
                local isExp = pState.expanded[key]
                local chevBtn = AllocBtn(f, 20)
                chevBtn:SetSize(16, 16)
                chevBtn:SetPoint("LEFT", spLabel, "RIGHT", 2, 0)
                if isExp then
                    chevBtn.tex:SetTexture(
                        "Interface\\Buttons\\UI-MinusButton-Up")
                else
                    chevBtn.tex:SetTexture(
                        "Interface\\Buttons\\UI-PlusButton-Up")
                end
                chevBtn.tex:SetTexCoord(0, 1, 0, 1)
                chevBtn.tex:SetVertexColor(1, 1, 1, 1)
                chevBtn.tex:Show()
                chevBtn:SetHighlightTexture(
                    "Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
                if chevBtn.label then chevBtn.label:Hide() end
                local thisKey = key
                chevBtn:SetScript("OnClick", function()
                    pState.expanded[thisKey] = not pState.expanded[thisKey]
                    ShowBuyAllPopup()
                end)
            end

            -- Store spell entry
            table.insert(popupSpells, {
                cb    = spCB,
                pet   = pet,
                spell = spell,
                ranks = ranks,
                key   = key,
            })

            -- Wire spell checkbox
            local thisPetCB = petCB
            local thisKey   = key
            spCB:SetScript("OnClick", function(self)
                local c = self:GetChecked()
                pState.checked[thisKey] = c
                if c then self.check:Show() else self.check:Hide() end
                PlaySound(c and 856 or 857)
                SyncPetCheckbox(thisPetCB)
                UpdateBuyButton()
            end)

            yOff = yOff - POPUP_SP_ROW_H

            -----------------------------------------------------------
            -- Expanded rank radio buttons
            -----------------------------------------------------------
            if hasMulti and pState.expanded[key] then
                for _, rData in ipairs(ranks) do
                    local isSel = (rData.rank == pState.selected[key])
                    local rankInBags = rData.itemName
                                      and bagGrimoires[rData.itemName]

                    local rb = AllocRadio(f, POPUP_RADIO_SZ)
                    rb:SetPoint("TOPLEFT", f, "TOPLEFT",
                                 14 + POPUP_INDENT + POPUP_CB_SIZE + 4, yOff)

                    if rankInBags then
                        rb:SetChecked(false)
                        rb.sel:Hide()
                        rb:Disable()
                        rb.bg:SetDesaturated(true)
                        rb.bg:SetAlpha(0.4)
                    else
                        rb:SetChecked(isSel)
                        if isSel then rb.sel:Show() else rb.sel:Hide() end
                        rb:Enable()
                        rb.bg:SetDesaturated(false)
                        rb.bg:SetAlpha(1)
                    end

                    local rLabel = AllocLabel("GameFontHighlightSmall")
                    rLabel:SetJustifyH("LEFT")
                    rLabel:SetPoint("LEFT", rb, "RIGHT", 4, 0)
                    if rankInBags then
                        rLabel:SetText(GT.CLR.dim ..
                            "Rank " .. rData.rank .. "  (In Bags)|r")
                    else
                        rLabel:SetText((isSel and "|cffffffff" or "|cffaa88cc")
                                       .. "Rank " .. rData.rank .. "|r")
                    end

                    local rCost = AllocLabel("GameFontHighlightSmall")
                    rCost:SetJustifyH("RIGHT")
                    rCost:SetWidth(POPUP_COST_W)
                    rCost:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, yOff)
                    if rankInBags then
                        rCost:SetText(GT.CLR.dim .. "--|r")
                    else
                        rCost:SetText(FormatCost(rData.cost))
                    end

                    if not rankInBags then
                        local thisRank = rData.rank
                        local thisKey2 = key
                        rb:SetScript("OnClick", function()
                            pState.selected[thisKey2] = thisRank
                            PlaySound(856)
                            ShowBuyAllPopup()
                            HighlightMerchant()
                        end)
                        local thisRb = rb
                        ClickOnLabel(rLabel, function() thisRb:Click() end)
                        ClickOnLabel(rCost, function() thisRb:Click() end)
                    end

                    yOff = yOff - POPUP_SP_ROW_H
                end
            end
        end

        -- Wire pet checkbox
        local thisPet = pet
        petCB:SetScript("OnClick", function(self)
            local wasIndet = self.dash:IsShown()
            local shouldCheck = wasIndet or self:GetChecked()
            self:SetChecked(shouldCheck)
            if shouldCheck then
                self.check:Show(); PlaySound(856)
            else
                self.check:Hide(); PlaySound(857)
            end
            self.dash:Hide()
            for _, sp in ipairs(popupSpells) do
                if sp.pet == thisPet and sp.cb:IsEnabled() then
                    sp.cb:SetChecked(shouldCheck)
                    pState.checked[sp.key] = shouldCheck
                    if shouldCheck then
                        sp.cb.check:Show()
                    else
                        sp.cb.check:Hide()
                    end
                end
            end
            UpdateBuyButton()
        end)

        -- Sync initial pet checkbox state
        SyncPetCheckbox(petCB)
    end

    -------------------------------------------------------------------
    -- Bottom: separator, total, buy button
    -------------------------------------------------------------------
    yOff = yOff - 14
    f.sepBottom:ClearAllPoints()
    f.sepBottom:SetPoint("TOPLEFT", f, "TOPLEFT", 14, yOff)
    f.sepBottom:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, yOff)
    f.sepBottom:Show()

    yOff = yOff - 14
    f.totalText:ClearAllPoints()
    f.totalText:SetPoint("TOPRIGHT", f, "TOPRIGHT", -16, yOff)
    f.totalText:SetWidth(POPUP_W - 28)

    yOff = yOff - 31
    f.buyBtn:ClearAllPoints()
    f.buyBtn:SetPoint("TOP", f, "TOPLEFT", POPUP_W / 2, yOff)
    f.buyBtn:Show()

    yOff = yOff - 38
    f:SetHeight(math.abs(yOff))
    f:Show()
    UpdateBuyButton()

    -- Wire buy button
    f.buyBtn:SetScript("OnClick", function()
        local toBuy = {}

        for _, sp in ipairs(popupSpells) do
            if sp.cb:GetChecked() then
                local r = FindRankData(sp.ranks, pState.selected[sp.key])
                if r then
                    table.insert(toBuy, {
                        merchantIdx = r.merchantIdx,
                        itemName    = r.itemName,
                        petFamily   = sp.pet,
                    })
                end
            end
        end

        -- Buy all selected grimoires
        for _, item in ipairs(toBuy) do
            BuyMerchantItem(item.merchantIdx, 1)
        end

        -- Rescan spellbook after delay; BAG_UPDATE handles popup/highlights
        C_Timer.After(0.5, function()
            local p = GT:GetActivePetFamily()
            if p then GT:ScanPetSpellbook() end
            GT:UpdateIfVisible(p)
        end)
    end)
end

---------------------------------------------------------------------------
-- Throttled scan entry point
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- Cache ALL grimoire prices for tooltip use  (runs on every vendor scan)
---------------------------------------------------------------------------
local function CacheVendorPrices()
    if not GT.db then return end
    local numItems = GetMerchantNumItems()
    if not numItems or numItems == 0 then return end

    for i = 1, numItems do
        local itemName, _, price = GetMerchantItemInfo(i)
        if itemName and price and price > 0 then
            local petFamily, spellName, rank = ParseGrimoireTooltip(i)
            if petFamily and spellName and rank then
                GT:CachePrice(petFamily, spellName, rank, price)
            end
        end
    end
end

local MAX_SCAN_RETRIES = 10
local scanRetryCount   = 0

local function DoScan()
    if not MerchantFrame or not MerchantFrame:IsShown() then return end

    local p = GT:GetActivePetFamily()
    if p then GT:ScanPetSpellbook() end
    CacheVendorPrices()

    local recs, byPet, unresolved = BuildRecommendedList()
    lastBestRecs, lastAllByPet = recs, byPet

    if unresolved > 0 and scanRetryCount < MAX_SCAN_RETRIES then
        scanRetryCount = scanRetryCount + 1
        -- Show loading state if not already showing content
        if not buyAllFrame or not buyAllFrame:IsShown()
           or buyAllFrame.loadingText:IsShown() then
            ShowLoadingPopup()
        end
        C_Timer.After(0.3, DoScan)
        return
    end

    -- All resolved (or max retries hit) — show real content
    scanRetryCount = 0
    HighlightMerchant()
    if #lastBestRecs > 0 then
        ShowBuyAllPopup()
    elseif buyAllFrame then
        buyAllFrame:Hide()
    end
end

---------------------------------------------------------------------------
-- Vendor grimoire data dump (copyable frame)
-- Usage: /gt dump  while a merchant window is open.
-- Scans every merchant item, extracts pet/spell/rank/level/cost.
---------------------------------------------------------------------------
local dumpFrame

local function CreateDumpFrame()
    local f = CreateFrame("Frame", "GTDumpFrame", UIParent, "BackdropTemplate")
    f:SetSize(500, 400)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("DIALOG")

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("Vendor Grimoire Dump")

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -4, -4)

    local sf = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 14, -38)
    sf:SetPoint("BOTTOMRIGHT", -32, 14)

    local eb = CreateFrame("EditBox", nil, sf)
    eb:SetMultiLine(true)
    eb:SetAutoFocus(false)
    eb:SetFontObject(GameFontHighlightSmall)
    eb:SetWidth(sf:GetWidth() or 440)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    sf:SetScrollChild(eb)

    f.editBox = eb
    f.scrollFrame = sf
    return f
end

function GT.DumpVendorGrimoires()
    local numItems = GetMerchantNumItems()
    if not numItems or numItems == 0 then return end

    local entries = {}
    for i = 1, numItems do
        local itemName, _, price = GetMerchantItemInfo(i)
        if itemName then
            local petFamily, spellName, rank, reqLevel =
                ParseGrimoireTooltip(i)
            if petFamily and spellName and rank then
                table.insert(entries, {
                    pet   = petFamily,
                    spell = spellName,
                    rank  = rank,
                    level = reqLevel,
                    cost  = price or 0,
                    item  = itemName,
                })
            end
        end
    end

    if #entries == 0 then return end

    -- Sort by pet, then spell, then rank
    table.sort(entries, function(a, b)
        if a.pet ~= b.pet then return a.pet < b.pet end
        if a.spell ~= b.spell then return a.spell < b.spell end
        return a.rank < b.rank
    end)

    -- Build text
    local lines = {}
    table.insert(lines, "-- Vendor Grimoire Dump  " ..
                        date("%Y-%m-%d %H:%M:%S"))
    table.insert(lines, "-- Total grimoires found: " .. #entries)
    table.insert(lines, "-- Format: Pet | Spell | Rank | ReqLevel | Cost(c)")
    table.insert(lines, "")

    local curPet = nil
    for _, e in ipairs(entries) do
        if e.pet ~= curPet then
            if curPet then table.insert(lines, "") end
            curPet = e.pet
            table.insert(lines, "-- " .. e.pet)
        end
        table.insert(lines, string.format(
            "  %s | %s | Rank %d | Level %d | %d copper",
            e.pet, e.spell, e.rank, e.level, e.cost))
    end

    -- Also output in Data.lua format
    table.insert(lines, "")
    table.insert(lines, "-- GRIMOIRE_RANKS format: {rank, reqLevel}")
    curPet = nil
    for _, e in ipairs(entries) do
        if e.pet ~= curPet then
            if curPet then table.insert(lines, "    },") end
            curPet = e.pet
            table.insert(lines, '    ["' .. e.pet .. '"] = {')
        end
        -- Group by spell (just list raw entries)
        table.insert(lines, string.format(
            '        -- %s Rank %d: {%d, %d},',
            e.spell, e.rank, e.rank, e.level))
    end
    if curPet then table.insert(lines, "    },") end

    local text = table.concat(lines, "\n")

    if not dumpFrame then dumpFrame = CreateDumpFrame() end
    dumpFrame.editBox:SetText(text)
    dumpFrame.editBox:SetWidth(dumpFrame.scrollFrame:GetWidth())
    dumpFrame:Show()
    dumpFrame.editBox:HighlightText()
    dumpFrame.editBox:SetFocus()
end

---------------------------------------------------------------------------
-- Hook merchant frame
---------------------------------------------------------------------------
local function HookMerchant()
    if GT._merchantHooked then return end
    GT._merchantHooked = true
    local hook = "MerchantFrame_Update"
    if not _G[hook] then
        hook = "MerchantFrame_UpdateMerchantInfo"
    end
    if _G[hook] then
        hooksecurefunc(hook, function()
            scanRetryCount = 0
            C_Timer.After(0.15, DoScan)
        end)
    end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")
local bagUpdateTimer  -- cancel-and-reschedule for BAG_UPDATE dedup
eventFrame:RegisterEvent("MERCHANT_SHOW")
eventFrame:RegisterEvent("MERCHANT_CLOSED")
eventFrame:RegisterEvent("MERCHANT_UPDATE")
eventFrame:RegisterEvent("BAG_UPDATE")

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "MERCHANT_SHOW" then
        HookMerchant()
        scanRetryCount = 0
        C_Timer.After(0.15, DoScan)
    elseif event == "MERCHANT_CLOSED" then
        scanRetryCount = 0
        HideAllHighlights()
        if buyAllFrame then
            buyAllFrame:Hide()
            buyAllFrame._userMoved = false
        end
        if dumpFrame then dumpFrame:Hide() end
        wipe(pState.expanded)
        wipe(pState.selected)
        wipe(pState.checked)
    elseif event == "MERCHANT_UPDATE" then
        scanRetryCount = 0
        C_Timer.After(0.2, DoScan)
    elseif event == "BAG_UPDATE" then
        if buyAllFrame and buyAllFrame:IsShown() then
            if bagUpdateTimer then bagUpdateTimer:Cancel() end
            bagUpdateTimer = C_Timer.NewTimer(0.15, function()
                bagUpdateTimer = nil
                if buyAllFrame and buyAllFrame:IsShown() then
                    ShowBuyAllPopup()
                    UpdateBuyButton()
                    HighlightMerchant()
                end
            end)
        end
    end
end)