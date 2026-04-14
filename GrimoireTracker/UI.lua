---------------------------------------------------------------------------
-- GrimoireTracker  -  UI.lua
-- PortraitFrameTemplate, vertical tabs (left), spells + model (right).
---------------------------------------------------------------------------

local GT = GrimoireTracker

---------------------------------------------------------------------------
-- Colors
---------------------------------------------------------------------------
local CLR = {
    maxed   = "|cff00ff00",   -- green
    avail   = "|cffffff00",   -- yellow
    unavail = "|cffff4444",   -- red
    name    = "|cffcc99ff",   -- lavender (spell names)
    rank    = "|cffe6cc80",   -- warm gold (rank text)
    caption = "|cffffffff",   -- white (labels)
    dim     = "|cff666666",   -- gray
    warn    = "|cffff9900",   -- orange
    warlock = "|cff8788ee",   -- class color
}
GT.CLR = CLR

---------------------------------------------------------------------------
-- Shared content background
---------------------------------------------------------------------------
local CONTENT_BG = { 0.12, 0.12, 0.12, 0.95 }

---------------------------------------------------------------------------
-- Layout constants
---------------------------------------------------------------------------
local ICON_SIZE   = 48
local TEXT_H      = 18
local SPELL_GAP   = 14
local PAD         = 16
local INSET       = 6

-- Portrait clearance (tabs start well below portrait)
local TAB_TOP_Y   = -66

-- Vertical tab column
local TAB_COL_W      = 130       -- divider sits at this X from left inset
local TAB_ACTIVE_EXT = 8         -- active tab extends past divider (hides right rounding)
local TAB_INACT_IND  = 6         -- inactive indent from left
local TAB_INACT_GAP  = 1         -- inactive gap from divider (close!)
local TAB_H          = 30
local TAB_SPACING    = 3
local TAB_PAD_H      = 10
local TAB_ACCENT     = 3         -- accent bar width

-- Content padding
local CONTENT_PAD = SPELL_GAP

-- Spell column (text on top of model, so no separate model width)
local SPELL_COL_W = 300
local TEXT_LEFT   = ICON_SIZE + 10

-- Frame width
local FRAME_W     = INSET + TAB_COL_W + 1 + PAD + SPELL_COL_W
                    + PAD + INSET  -- ~475px

-- Demon display IDs
local DEMON_DISPLAY = {
    Imp        = 4449,
    Voidwalker = 1132,
    Succubus   = 4162,
    Incubus    = 4162,
    Felhunter  = 850,
    Felguard   = 17252,
}

-- Universal camera (same for all demons)
local MODEL_CAMERA = { dist = 1.8, facing = 0.4 }

-- Per-pet accent colors
local PET_ACCENT = {
    Imp        = { 1.0, 0.55, 0.26 },
    Voidwalker = { 0.43, 0.56, 0.98 },
    Succubus   = { 0.93, 0.51, 0.93 },
    Incubus    = { 0.93, 0.51, 0.93 },
    Felhunter  = { 0.31, 0.82, 0.77 },
    Felguard   = { 0.80, 0.27, 0.27 },
}

---------------------------------------------------------------------------
-- Tab colors
---------------------------------------------------------------------------
local TAB_COLORS = {
    activeBg      = CONTENT_BG,
    activeBorder  = { 0.40, 0.35, 0.55, 1 },
    activeText    = { 1.0, 0.82, 0.0, 1 },
    inactiveBg    = { 0.08, 0.08, 0.10, 0.6 },
    inactiveBorder= { 0.22, 0.22, 0.26, 0.7 },
    inactiveText  = { 0.50, 0.50, 0.50, 1 },
    hoverBg       = { 0.16, 0.14, 0.20, 0.9 },
    hoverBorder   = { 0.30, 0.28, 0.38, 0.9 },
    hoverText     = { 0.85, 0.85, 0.85, 1 },
    contentBorder = { 0.40, 0.35, 0.55, 1 },
}

---------------------------------------------------------------------------
-- Border thickness for manual tab edges
---------------------------------------------------------------------------
local TAB_BORDER = 1

---------------------------------------------------------------------------
-- Spell block pool
---------------------------------------------------------------------------
local MAX_LINES = 4
local blockPool = {}

local HOVER_BG = { 0.18, 0.16, 0.22, 1.0 }  -- slightly lighter, fully opaque
local HOVER_PAD = 4  -- extra px around block for the hover bg

local function AllocBlock(parent)
    for _, b in ipairs(blockPool) do
        if not b._used then
            b._used = true
            b:SetParent(parent)
            b.icon:SetDesaturated(false)
            b.icon:SetTexture(nil)
            b.icon:SetSize(ICON_SIZE, ICON_SIZE)
            for _, ln in ipairs(b.lines) do
                ln:SetText("")
                ln:SetWordWrap(false)
                ln:Hide()
            end
            if b.hitFrame then
                b.hitFrame:Hide()
                b.hitFrame:SetScript("OnEnter", nil)
                b.hitFrame:SetScript("OnLeave", nil)
            end
            b.hoverBg:Hide()
            b:Show()
            return b
        end
    end

    local b = CreateFrame("Frame", nil, parent)
    b:SetSize(SPELL_COL_W, ICON_SIZE)
    b:EnableMouse(true)

    -- Hover background (behind everything)
    b.hoverBg = b:CreateTexture(nil, "ARTWORK", nil, -1)
    b.hoverBg:SetPoint("TOPLEFT", -HOVER_PAD, HOVER_PAD)
    b.hoverBg:SetPoint("BOTTOMRIGHT", HOVER_PAD, -HOVER_PAD)
    b.hoverBg:SetColorTexture(HOVER_BG[1], HOVER_BG[2],
                               HOVER_BG[3], HOVER_BG[4])
    b.hoverBg:Hide()

    b:SetScript("OnEnter", function(self) self.hoverBg:Show() end)
    b:SetScript("OnLeave", function(self)
        if self.hitFrame and self.hitFrame:IsShown()
           and self.hitFrame:IsMouseOver() then
            return  -- mouse moved to tooltip hit area, keep bg
        end
        self.hoverBg:Hide()
    end)

    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetSize(ICON_SIZE, ICON_SIZE)
    b.icon:SetPoint("TOPLEFT", 0, 0)

    b.lines = {}
    for i = 1, MAX_LINES do
        local template = (i == 1) and "GameFontNormal" or "GameFontNormalSmall"
        local ln = b:CreateFontString(nil, "OVERLAY", template)
        ln:SetJustifyH("LEFT")
        ln:SetPoint("TOPLEFT", b, "TOPLEFT",
                     TEXT_LEFT, -((i - 1) * TEXT_H))
        ln:SetPoint("RIGHT", b, "RIGHT", -2, 0)
        ln:Hide()
        b.lines[i] = ln
    end

    -- Hit frame for "ranks left" tooltip
    b.hitFrame = CreateFrame("Frame", nil, b)
    b.hitFrame:SetHeight(TEXT_H)
    b.hitFrame:EnableMouse(true)
    b.hitFrame:Hide()

    b._used = true
    table.insert(blockPool, b)
    return b
end

local function FreeBlocks()
    for _, b in ipairs(blockPool) do
        b._used = false
        b.hoverBg:Hide()
        if b.hitFrame then b.hitFrame:Hide() end
        b:Hide()
    end
end

---------------------------------------------------------------------------
-- Apply tab visual state
---------------------------------------------------------------------------
local function ApplyTabState(btn, state)
    local bg, br, tx
    if state == "active" then
        bg = TAB_COLORS.activeBg
        br = TAB_COLORS.activeBorder
        tx = TAB_COLORS.activeText
    elseif state == "hover" then
        bg = TAB_COLORS.hoverBg
        br = TAB_COLORS.hoverBorder
        tx = TAB_COLORS.hoverText
    else
        bg = TAB_COLORS.inactiveBg
        br = TAB_COLORS.inactiveBorder
        tx = TAB_COLORS.inactiveText
    end

    btn.bg:SetColorTexture(bg[1], bg[2], bg[3], bg[4])
    btn.label:SetTextColor(tx[1], tx[2], tx[3], tx[4])

    if state == "active" then
        -- Active: top + left + bottom borders, right open to merge into content
        btn.borderTop:SetColorTexture(br[1], br[2], br[3], br[4])
        btn.borderTop:Show()
        btn.borderLeft:SetColorTexture(br[1], br[2], br[3], br[4])
        btn.borderLeft:Show()
        btn.borderBottom:SetColorTexture(br[1], br[2], br[3], br[4])
        btn.borderBottom:Show()
        btn.borderRight:Hide()
        if btn.lineCover then
            btn.lineCover:SetColorTexture(bg[1], bg[2], bg[3], 1.0)
            btn.lineCover:Show()
        end
        if btn.accent then
            local ac = PET_ACCENT[btn.pet] or { 0.6, 0.5, 0.8 }
            btn.accent:SetColorTexture(ac[1], ac[2], ac[3], 1)
            btn.accent:Show()
        end
    else
        -- Inactive/hover: no borders at all — just bg + text
        btn.borderTop:Hide()
        btn.borderLeft:Hide()
        btn.borderBottom:Hide()
        btn.borderRight:Hide()
        if btn.lineCover then btn.lineCover:Hide() end
        if btn.accent then btn.accent:Hide() end
    end

    if btn.badge then
        btn.badge:SetAlpha(state == "inactive" and 0.5 or 1.0)
    end
end

---------------------------------------------------------------------------
-- Compute frame height
---------------------------------------------------------------------------
local function ComputeFixedHeight(knownPets)
    local maxSpells = 0
    for _, pet in ipairs(knownPets) do
        local n = GT.SPELL_ORDER[pet] and #GT.SPELL_ORDER[pet] or 0
        if n > maxSpells then maxSpells = n end
    end
    local blockH = math.max(ICON_SIZE, MAX_LINES * TEXT_H)
    local spellH = maxSpells * (blockH + SPELL_GAP) - SPELL_GAP

    local tabH = #knownPets * (TAB_H + TAB_SPACING) - TAB_SPACING

    local contentH = math.max(spellH, tabH)
    return math.abs(TAB_TOP_Y) + CONTENT_PAD + contentH + CONTENT_PAD
end

---------------------------------------------------------------------------
-- Build main frame
---------------------------------------------------------------------------
local function CreateMainFrame()
    local f = CreateFrame("Frame", "GrimoireTrackerFrame", UIParent,
                          "PortraitFrameTemplate")
    f:SetSize(FRAME_W, 300)

    if GT.db and GT.db.windowX and GT.db.windowY then
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT",
                    GT.db.windowX, GT.db.windowY)
    else
        f:SetPoint("CENTER")
    end

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if GT.db then
            GT.db.windowX = self:GetLeft()
            GT.db.windowY = self:GetTop()
        end
    end)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    table.insert(UISpecialFrames, "GrimoireTrackerFrame")

    -- Portrait
    local PORTRAIT_ICON = "Interface\\Icons\\INV_Misc_Book_06"
    if f.SetPortraitTextureRaw then
        f:SetPortraitTextureRaw(PORTRAIT_ICON)
    elseif f.portrait then
        f.portrait:SetTexture(PORTRAIT_ICON)
    end

    -- Title
    if f.SetTitle then
        f:SetTitle("Grimoire Tracker")
    else
        f.titleText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        f.titleText:SetPoint("TOP", 0, -5)
        f.titleText:SetText("Grimoire Tracker")
    end

    -- Subtitle (centered between title bar bottom and tab top)
    local HEADER_BOTTOM = -24  -- bottom of PortraitFrameTemplate title area
    local subtitleY = (HEADER_BOTTOM + TAB_TOP_Y) / 2
    f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.subtitle:SetPoint("TOP", f, "TOP", 0, subtitleY)

    -------------------------------------------------------------------
    -- Tab area anchor (left side, below portrait)
    -------------------------------------------------------------------
    f.tabBar = CreateFrame("Frame", nil, f)
    f.tabBar:SetPoint("TOPLEFT", f, "TOPLEFT", INSET, TAB_TOP_Y)
    f.tabBar:SetSize(TAB_COL_W, 1)

    -- Vertical divider line (right edge of tab column)
    f.tabBorderLine = f:CreateTexture(nil, "ARTWORK", nil, 0)
    f.tabBorderLine:SetWidth(1)
    f.tabBorderLine:SetPoint("TOPLEFT", f, "TOPLEFT",
                              INSET + TAB_COL_W, TAB_TOP_Y)
    f.tabBorderLine:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT",
                              INSET + TAB_COL_W, INSET)
    local bc = TAB_COLORS.contentBorder
    f.tabBorderLine:SetColorTexture(bc[1], bc[2], bc[3], bc[4])

    -------------------------------------------------------------------
    -- Content background (right of divider)
    -------------------------------------------------------------------
    f.contentBg = CreateFrame("Frame", nil, f)
    f.contentBg:SetPoint("TOPLEFT", f, "TOPLEFT",
                          INSET + TAB_COL_W + 1, TAB_TOP_Y)
    f.contentBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -INSET, INSET)
    f.contentBg:SetFrameLevel(f:GetFrameLevel() + 2)

    local bgTex = f.contentBg:CreateTexture(nil, "BACKGROUND")
    bgTex:SetAllPoints()
    bgTex:SetColorTexture(CONTENT_BG[1], CONTENT_BG[2],
                           CONTENT_BG[3], CONTENT_BG[4])

    -- Top border on content area only (right of divider)
    f.contentTopBorder = f.contentBg:CreateTexture(nil, "BORDER")
    f.contentTopBorder:SetHeight(1)
    f.contentTopBorder:SetPoint("TOPLEFT", f.contentBg, "TOPLEFT", 0, 0)
    f.contentTopBorder:SetPoint("TOPRIGHT", f.contentBg, "TOPRIGHT", 0, 0)
    f.contentTopBorder:SetColorTexture(bc[1], bc[2], bc[3], bc[4])

    -------------------------------------------------------------------
    -- Tab buttons (manual borders — real tab appearance)
    -------------------------------------------------------------------
    f.tabs = {}
    for _, pet in ipairs(GT.PET_ORDER) do
        local btn = CreateFrame("Button", nil, f.tabBar)
        btn:SetHeight(TAB_H)
        btn:SetFrameLevel(f.contentBg:GetFrameLevel() + 1)

        -- Background fill
        btn.bg = btn:CreateTexture(nil, "BACKGROUND")
        btn.bg:SetAllPoints()

        -- Manual 1px borders: top, left, bottom, right
        btn.borderTop = btn:CreateTexture(nil, "BORDER")
        btn.borderTop:SetHeight(TAB_BORDER)
        btn.borderTop:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        btn.borderTop:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)

        btn.borderBottom = btn:CreateTexture(nil, "BORDER")
        btn.borderBottom:SetHeight(TAB_BORDER)
        btn.borderBottom:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
        btn.borderBottom:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)

        btn.borderLeft = btn:CreateTexture(nil, "BORDER")
        btn.borderLeft:SetWidth(TAB_BORDER)
        btn.borderLeft:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        btn.borderLeft:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)

        btn.borderRight = btn:CreateTexture(nil, "BORDER")
        btn.borderRight:SetWidth(TAB_BORDER)
        btn.borderRight:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
        btn.borderRight:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)

        -- Accent bar (left edge, visible when active)
        btn.accent = btn:CreateTexture(nil, "ARTWORK")
        btn.accent:SetWidth(TAB_ACCENT)
        btn.accent:SetPoint("TOPLEFT", btn, "TOPLEFT",
                             TAB_BORDER + 2, -(TAB_BORDER + 2))
        btn.accent:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT",
                             TAB_BORDER + 2, TAB_BORDER + 2)
        btn.accent:Hide()

        -- lineCover: masks the vertical divider when active
        btn.lineCover = btn:CreateTexture(nil, "OVERLAY")
        btn.lineCover:SetWidth(TAB_ACTIVE_EXT + 2)
        btn.lineCover:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
        btn.lineCover:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        btn.lineCover:Hide()

        -- Label
        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.label:SetJustifyH("LEFT")
        btn.label:SetPoint("LEFT", btn, "LEFT",
                            TAB_BORDER + TAB_ACCENT + TAB_PAD_H, 0)
        btn.label:SetText(pet)

        -- Badge (right side)
        btn.badge = btn:CreateFontString(nil, "OVERLAY",
                                          "GameFontNormalSmall")
        btn.badge:SetPoint("RIGHT", btn, "RIGHT", -TAB_PAD_H, 0)
        btn.badge:Hide()

        -- Strikethrough
        btn.strike = btn:CreateTexture(nil, "OVERLAY", nil, 1)
        btn.strike:SetHeight(1)
        btn.strike:SetPoint("LEFT", btn.label, "LEFT", -2, 0)
        btn.strike:SetPoint("RIGHT", btn.label, "RIGHT", 2, 0)
        btn.strike:SetColorTexture(0.6, 0.6, 0.6, 0.8)
        btn.strike:Hide()

        btn.pet = pet
        btn._isSelected = false

        btn:SetScript("OnClick", function() GT:RefreshUI(pet) end)
        btn:SetScript("OnEnter", function(self)
            if not self._isSelected then ApplyTabState(self, "hover") end
        end)
        btn:SetScript("OnLeave", function(self)
            ApplyTabState(self, self._isSelected and "active" or "inactive")
        end)

        ApplyTabState(btn, "inactive")
        f.tabs[pet] = btn
    end

    -------------------------------------------------------------------
    -- Content origins
    -------------------------------------------------------------------
    local contentLeftX = INSET + TAB_COL_W + 1 + PAD
    local contentTopY  = TAB_TOP_Y - CONTENT_PAD

    -------------------------------------------------------------------
    -- Pet model (fills content area, BEHIND text)
    -------------------------------------------------------------------
    f.model = CreateFrame("PlayerModel", nil, f.contentBg)
    f.model:SetAllPoints(f.contentBg)
    f.model:SetFrameLevel(f.contentBg:GetFrameLevel())

    -------------------------------------------------------------------
    -- Spell column (ON TOP of model)
    -------------------------------------------------------------------
    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", f, "TOPLEFT", contentLeftX, contentTopY)
    f.content:SetSize(SPELL_COL_W, 1)
    f.content:SetFrameLevel(f.contentBg:GetFrameLevel() + 5)

    -------------------------------------------------------------------
    -- Unscanned message
    -------------------------------------------------------------------
    f.unscanned = CreateFrame("Frame", nil, f)
    f.unscanned:SetPoint("TOPLEFT", f, "TOPLEFT", contentLeftX, contentTopY)
    f.unscanned:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT",
                          -INSET, CONTENT_PAD)
    f.unscanned:SetFrameLevel(f.contentBg:GetFrameLevel() + 5)

    f.unscannedIcon = f.unscanned:CreateTexture(nil, "ARTWORK")
    f.unscannedIcon:SetSize(ICON_SIZE, ICON_SIZE)
    f.unscannedIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    f.unscannedText = f.unscanned:CreateFontString(nil, "OVERLAY",
                                                    "GameFontNormal")
    f.unscannedText:SetWidth(300)
    f.unscannedText:SetJustifyH("CENTER")
    f.unscannedText:SetWordWrap(true)

    f.unscanned:Hide()
    f:Hide()
    return f
end

---------------------------------------------------------------------------
-- Layout vertical tabs
--   Active:  x=0,             width = TAB_COL_W + TAB_ACTIVE_EXT
--   Inactive: x=TAB_INACT_IND, width = TAB_COL_W - TAB_INACT_IND - TAB_INACT_GAP
---------------------------------------------------------------------------
local function LayoutTabs(f, knownPets)
    local ty = 0
    for _, pet in ipairs(knownPets) do
        local tab = f.tabs[pet]
        if tab then
            tab:ClearAllPoints()
            if tab._isSelected then
                tab:SetWidth(TAB_COL_W + TAB_ACTIVE_EXT)
                tab:SetPoint("TOPLEFT", f.tabBar, "TOPLEFT", 0, -ty)
            else
                tab:SetWidth(TAB_COL_W - TAB_INACT_IND - TAB_INACT_GAP)
                tab:SetPoint("TOPLEFT", f.tabBar, "TOPLEFT",
                              TAB_INACT_IND, -ty)
            end
            tab:Show()
            ty = ty + TAB_H + TAB_SPACING
        end
    end
    f.tabBar:SetHeight(math.max(ty - TAB_SPACING, 1))
end

---------------------------------------------------------------------------
-- Update pet model (universal camera, behind text)
---------------------------------------------------------------------------
local function UpdateModel(f, pet)
    if not f.model then return end
    local displayID = DEMON_DISPLAY[pet]
    if displayID then
        f.model:ClearModel()
        f.model:SetDisplayInfo(displayID)
        C_Timer.After(0, function()
            if f.model:IsVisible() then
                f.model:SetCamDistanceScale(MODEL_CAMERA.dist)
                f.model:SetPosition(0, 0, 0)
                f.model:SetFacing(MODEL_CAMERA.facing)
            end
        end)
        f.model:Show()
    else
        f.model:Hide()
    end
end

---------------------------------------------------------------------------
-- Center unscanned
---------------------------------------------------------------------------
local function CenterUnscanned(f)
    local textH = f.unscannedText:GetStringHeight()
    local totalH = ICON_SIZE + 8 + textH
    local halfH  = totalH / 2

    f.unscannedIcon:ClearAllPoints()
    f.unscannedIcon:SetPoint("TOP", f.unscanned, "CENTER", 0, halfH)

    f.unscannedText:ClearAllPoints()
    f.unscannedText:SetPoint("TOP", f.unscannedIcon, "BOTTOM", 0, -8)
    f.unscannedText:SetPoint("LEFT", f.unscanned, "LEFT", 0, 0)
    f.unscannedText:SetPoint("RIGHT", f.unscanned, "RIGHT", 0, 0)
end

---------------------------------------------------------------------------
-- "Ranks left" tooltip
---------------------------------------------------------------------------
local function ShowRankTooltip(frame, s)
    local pet = GT:FindPetForSpell(s.spellName)
    if not pet then return end
    local ranks = GT.GRIMOIRE_RANKS[pet][s.spellName]
    if not ranks then return end

    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:AddLine(s.spellName .. " — Remaining Ranks", 1, 0.82, 0)

    local playerLevel = UnitLevel("player")
    for _, entry in ipairs(ranks) do
        local rank, reqLevel = entry[1], entry[2]
        if rank > s.knownRank then
            local line = "Rank " .. rank .. "  (Level " .. reqLevel .. ")"
            local cost = GT:GetPrice(pet, s.spellName, rank)
            if cost and cost > 0 then
                line = line .. "  " .. GT:FormatCostPlain(cost)
            end
            if playerLevel >= reqLevel then
                GameTooltip:AddLine(line, 0, 1, 0)
            else
                GameTooltip:AddLine(line, 1, 0.27, 0.27)
            end
        end
    end

    GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Draw one spell block
---------------------------------------------------------------------------
local function DrawSpell(parent, s, yOff)
    local iconPath = GT.SPELL_ICONS[s.spellName]
    if not iconPath then
        print("|cff9370dbGT:|r WARNING: No icon for spell '" ..
              s.spellName .. "'")
        iconPath = "Interface\\Icons\\INV_Misc_QuestionMark"
    end

    local blk = AllocBlock(parent)
    blk:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -yOff)
    blk:SetWidth(SPELL_COL_W)
    blk.icon:SetTexture(iconPath)
    blk.icon:Show()

    local lineCount = 0

    if s.status == "unscanned" then
        blk.icon:SetDesaturated(true)
        local t = CLR.name .. s.spellName .. "|r"
        if s.maxRank > 1 then t = t .. CLR.dim .. " (Rank ?)|r" end
        blk.lines[1]:SetText(t)
        blk.lines[1]:Show()
        lineCount = 1

    elseif s.status == "maxed" then
        local rankBit = ""
        if s.maxRank > 1 then
            rankBit = " " .. CLR.maxed .. "(Rank " .. s.knownRank .. ")|r"
        else
            rankBit = " " .. CLR.maxed .. "(Learned)|r"
        end
        blk.lines[1]:SetText(CLR.name .. s.spellName .. "|r" .. rankBit)
        blk.lines[1]:Show()
        lineCount = 1

    else
        local rankBit = ""
        if s.maxRank > 1 then
            if s.knownRank > 0 then
                rankBit = " " .. CLR.avail ..
                          "(Rank " .. s.knownRank .. ")|r"
            else
                rankBit = " " .. CLR.avail .. "(unlearned)|r"
            end
        end
        blk.lines[1]:SetText(CLR.name .. s.spellName .. "|r" .. rankBit)
        blk.lines[1]:Show()
        lineCount = 1

        if s.nextRank then
            lineCount = lineCount + 1
            local pet = GT:FindPetForSpell(s.spellName)
            local cost = pet and GT:GetPrice(pet, s.spellName, s.nextRank)
            local costStr = ""
            if cost and cost > 0 then
                costStr = "  " .. GT:FormatCostText(cost)
            end
            if s.status == "available" then
                if s.maxRank > 1 then
                    blk.lines[2]:SetText(CLR.caption .. "Buy " ..
                        CLR.avail .. "Rank " .. s.nextRank ..
                        " (Lvl " .. s.nextReqLevel .. ")|r" .. costStr)
                else
                    blk.lines[2]:SetText(CLR.caption .. "Buy " ..
                        CLR.avail .. "grimoire (Lvl " ..
                        s.nextReqLevel .. ")|r" .. costStr)
                end
            else
                if s.maxRank > 1 then
                    blk.lines[2]:SetText(CLR.caption .. "Next: " ..
                        CLR.unavail .. "Rank " .. s.nextRank ..
                        " (Lvl " .. s.nextReqLevel .. ")|r" .. costStr)
                else
                    blk.lines[2]:SetText(CLR.caption .. "Requires " ..
                        CLR.unavail .. "Lvl " .. s.nextReqLevel .. "|r" ..
                        costStr)
                end
            end
            blk.lines[2]:Show()
        end

        if s.remainingCount > 0 then
            lineCount = lineCount + 1
            local w = s.remainingCount == 1 and "rank" or "ranks"
            local c = (s.remainingCount == 1) and CLR.maxed or CLR.caption
            blk.lines[lineCount]:SetText(c ..
                s.remainingCount .. " " .. w .. " left|r")
            blk.lines[lineCount]:Show()

            blk.hitFrame:ClearAllPoints()
            blk.hitFrame:SetPoint("TOPLEFT", blk, "TOPLEFT",
                                   TEXT_LEFT, -((lineCount - 1) * TEXT_H))
            blk.hitFrame:SetPoint("RIGHT", blk, "RIGHT", -2, 0)
            blk.hitFrame:Show()
            blk.hitFrame:SetScript("OnEnter", function(self)
                blk.hoverBg:Show()
                ShowRankTooltip(self, s)
            end)
            blk.hitFrame:SetScript("OnLeave", function()
                blk.hoverBg:Hide()
                GameTooltip:Hide()
            end)
        end
    end

    local textH  = lineCount * TEXT_H
    local blockH = math.max(ICON_SIZE, textH)
    blk:SetHeight(blockH)
    return blockH + SPELL_GAP
end

---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------
function GT:RefreshUI(petFamily)
    if not self.mainFrame then
        self.mainFrame = CreateMainFrame()
    end
    local f = self.mainFrame

    local knownPets = {}
    for _, pet in ipairs(GT.PET_ORDER) do
        if self:KnowsPet(pet) then
            table.insert(knownPets, pet)
        end
    end

    if #knownPets == 0 then
        f:Hide()
        return
    end

    f:SetHeight(ComputeFixedHeight(knownPets))

    local petKnown = false
    for _, p in ipairs(knownPets) do
        if p == petFamily then petKnown = true; break end
    end
    if not petKnown then petFamily = nil end

    petFamily = petFamily or self.selectedPet
    if petFamily then
        local ok = false
        for _, p in ipairs(knownPets) do
            if p == petFamily then ok = true; break end
        end
        if not ok then petFamily = nil end
    end
    if not petFamily and self.db and self.db.lastTab then
        for _, p in ipairs(knownPets) do
            if p == self.db.lastTab then petFamily = p; break end
        end
    end
    petFamily = petFamily or knownPets[1]
    self.selectedPet = petFamily
    if self.db then self.db.lastTab = petFamily end

    -- Subtitle
    f.subtitle:SetText(CLR.caption .. "Level " .. UnitLevel("player") ..
        " " .. CLR.warlock .. "Warlock|r")

    -- Hide all tabs
    for _, tab in pairs(f.tabs) do
        tab:Hide()
        tab._isSelected = false
    end

    -- Set tab states
    for _, pet in ipairs(knownPets) do
        local tab = f.tabs[pet]
        if not tab then break end

        if pet == petFamily then
            tab._isSelected = true
            ApplyTabState(tab, "active")
        else
            ApplyTabState(tab, "inactive")
        end

        if self:HasScannedPet(pet) then
            local _, avail = self:GetSummary(pet)
            if avail > 0 then
                tab.badge:SetText(CLR.avail .. tostring(avail) .. "|r")
                tab.badge:Show()
            else
                tab.badge:Hide()
            end
            tab.strike:Hide()
        else
            tab.badge:Hide()
            tab.strike:Show()
        end
    end

    LayoutTabs(f, knownPets)
    UpdateModel(f, petFamily)
    FreeBlocks()

    if not self:HasScannedPet(petFamily) then
        f.content:Hide()
        f.unscannedText:SetText(CLR.warn ..
            petFamily .. " has not been scanned yet.\n" ..
            "Summon this pet to detect learned grimoires.|r")
        f.unscanned:Show()
        C_Timer.After(0, function() CenterUnscanned(f) end)
    else
        f.unscanned:Hide()
        f.content:Show()

        local vis = self:GetAllSpellStatuses(petFamily)
        local yOff = 0
        for _, s in ipairs(vis) do
            yOff = yOff + DrawSpell(f.content, s, yOff)
        end
        f.content:SetHeight(yOff)
    end

    if not f:IsShown() then f:Show() end
end

---------------------------------------------------------------------------
-- Login message
---------------------------------------------------------------------------
local lf = CreateFrame("Frame")
lf:RegisterEvent("PLAYER_LOGIN")
lf:SetScript("OnEvent", function()
    local _, cls = UnitClass("player")
    if cls ~= "WARLOCK" then return end
    print("|cff9370dbGrimoire Tracker|r loaded. " ..
          "Type |cff00ff00/grimoire|r or |cff00ff00/gt|r to open.")
end)