local addonName, ns = ...

-- Layout constants
local FRAME_WIDTH = 1050
local FRAME_HEIGHT = 550
local LEFT_WIDTH = 260
local ROW_HEIGHT = 24
local SECTION_HEADER_HEIGHT = 28
local CHAIN_INDENT = 20
local FACTION_ROW_HEIGHT = 60
local FACTION_ROW_GAP = 2
local FONT_NORMAL = 12
local FONT_HEADER = 13
local FONT_SMALL = 11

-- Colors
local COLOR = {
    title       = { r = 0.2, g = 1.0, b = 0.6 },
    headerText  = { r = 0.9, g = 0.8, b = 0.5 },
    complete    = { r = 0.45, g = 0.45, b = 0.45 },
    available   = { r = 1.0, g = 1.0, b = 1.0 },
    locked      = { r = 0.6, g = 0.45, b = 0.2 },
    rep         = { r = 1.0, g = 0.82, b = 0.0 },
    group       = { r = 1.0, g = 0.3, b = 0.3 },
    daily       = { r = 0.3, g = 0.6, b = 1.0 },
    turnIn      = { r = 0.6, g = 0.8, b = 0.4 },
    dungeon     = { r = 0.5, g = 0.7, b = 1.0 },
    factionBg   = { r = 0.12, g = 0.12, b = 0.12, a = 0.9 },
    factionSel  = { r = 0.18, g = 0.28, b = 0.18, a = 0.95 },
    factionHov  = { r = 0.16, g = 0.16, b = 0.16, a = 0.9 },
    sectionBg   = { r = 0.1, g = 0.1, b = 0.1, a = 0.6 },
    readyBg     = { r = 0.15, g = 0.3, b = 0.15, a = 0.4 },
    repBarBg    = { r = 0.2, g = 0.2, b = 0.2, a = 1.0 },
    repBarFill  = { r = 0.3, g = 0.7, b = 0.3, a = 1.0 },
    tabActive   = { r = 0.15, g = 0.25, b = 0.15, a = 0.8 },
    tabInactive = { r = 0.12, g = 0.12, b = 0.12, a = 0.6 },
}

-- Quest status textures (file paths, confirmed working in TBC Anniversary)
local TEXTURE_QUEST_AVAILABLE = "Interface\\GossipFrame\\AvailableQuestIcon"  -- yellow !
local TEXTURE_QUEST_TURN_IN   = "Interface\\GossipFrame\\ActiveQuestIcon"     -- yellow ?
local TEXTURE_QUEST_COMPLETE  = "Interface\\RaidFrame\\ReadyCheck-Ready"       -- green checkmark

-- Backdrops
local BACKDROP_MAIN = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local BACKDROP_PANEL = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

-- State
local factionSelected = nil
local frameMain = nil
local activeTab = "plan"
local hideCompleted = false
local chainRowPool = {}
local sectionHeaderPool = {}

-- Helpers

local function fontCreate(parent, size, color)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetFont("Fonts\\FRIZQT__.TTF", size or FONT_NORMAL, "")
    if color then
        fs:SetTextColor(color.r, color.g, color.b, 1)
    end
    return fs
end

-- Rep bar that uses percentage fill via a sub-frame

local function repBarCreate(parent)
    local bar = CreateFrame("Frame", nil, parent)
    bar:SetHeight(8)

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(COLOR.repBarBg.r, COLOR.repBarBg.g, COLOR.repBarBg.b, COLOR.repBarBg.a)

    local fill = CreateFrame("Frame", nil, bar)
    fill:SetPoint("TOPLEFT")
    fill:SetPoint("BOTTOMLEFT")
    fill:SetWidth(1)

    local fillTex = fill:CreateTexture(nil, "ARTWORK")
    fillTex:SetAllPoints()
    fillTex:SetColorTexture(COLOR.repBarFill.r, COLOR.repBarFill.g, COLOR.repBarFill.b, COLOR.repBarFill.a)

    bar.fillFrame = fill
    bar.pct = 0

    bar:SetScript("OnSizeChanged", function(self, width)
        if width and width > 0 then
            self.fillFrame:SetWidth(math.max(1, width * self.pct))
        end
    end)

    return bar
end

local function repBarUpdate(bar, current, max)
    if max <= 0 then max = 1 end
    bar.pct = current / max
    local width = bar:GetWidth()
    if width and width > 0 then
        bar.fillFrame:SetWidth(math.max(1, width * bar.pct))
    end
end

-- Section header from pool

local function sectionHeaderGet(parent, poolIndex)
    if sectionHeaderPool[poolIndex] then
        sectionHeaderPool[poolIndex]:Show()
        return sectionHeaderPool[poolIndex]
    end

    local header = CreateFrame("Frame", nil, parent)
    header:SetHeight(SECTION_HEADER_HEIGHT)

    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(COLOR.sectionBg.r, COLOR.sectionBg.g, COLOR.sectionBg.b, COLOR.sectionBg.a)

    local text = fontCreate(header, FONT_HEADER, COLOR.headerText)
    text:SetPoint("LEFT", 8, 0)
    header.label = text

    sectionHeaderPool[poolIndex] = header
    return header
end

-- Chain row from pool

local CONNECTOR_WIDTH = 2
local CONNECTOR_X = 8 -- pixels from left edge of row
local CONNECTOR_COLOR = { 0.4, 0.7, 0.4, 0.5 }

local function chainRowGet(parent, poolIndex)
    if chainRowPool[poolIndex] then
        local row = chainRowPool[poolIndex]
        row:SetParent(parent)
        row:Show()
        return row
    end

    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0)
    row.bg = bg

    -- Top half of connector line (from top of row to vertical center)
    local lineTop = row:CreateTexture(nil, "ARTWORK")
    lineTop:SetWidth(CONNECTOR_WIDTH)
    lineTop:SetColorTexture(unpack(CONNECTOR_COLOR))
    lineTop:SetPoint("TOP", row, "TOPLEFT", CONNECTOR_X, 0)
    lineTop:SetPoint("BOTTOM", row, "LEFT", CONNECTOR_X, 0)
    lineTop:Hide()
    row.lineTop = lineTop

    -- Bottom half of connector line (from vertical center to bottom of row)
    local lineBottom = row:CreateTexture(nil, "ARTWORK")
    lineBottom:SetWidth(CONNECTOR_WIDTH)
    lineBottom:SetColorTexture(unpack(CONNECTOR_COLOR))
    lineBottom:SetPoint("TOP", row, "LEFT", CONNECTOR_X, 0)
    lineBottom:SetPoint("BOTTOM", row, "BOTTOMLEFT", CONNECTOR_X, 0)
    lineBottom:Hide()
    row.lineBottom = lineBottom

    -- Quest status icon (!, ?, checkmark)
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(14, 14)
    icon:Hide()
    row.icon = icon

    local nameText = fontCreate(row, FONT_NORMAL)
    nameText:SetPoint("RIGHT", row, "RIGHT", -120, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    row.nameText = nameText

    local repText = fontCreate(row, FONT_SMALL, COLOR.rep)
    repText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    repText:SetJustifyH("RIGHT")
    repText:SetWidth(60)
    row.repText = repText

    local tagText = fontCreate(row, FONT_SMALL)
    tagText:SetPoint("RIGHT", repText, "LEFT", -4, 0)
    tagText:SetJustifyH("RIGHT")
    tagText:SetWidth(50)
    row.tagText = tagText

    chainRowPool[poolIndex] = row
    return row
end

local function chainRowConfigure(row, data)
    -- Reset visuals
    row.bg:SetColorTexture(0, 0, 0, 0)
    row.icon:Hide()
    row.icon:SetTexCoord(0, 1, 0, 1)
    row.icon:SetDesaturated(false)
    row.repText:SetText("")
    row.tagText:SetText("")
    row.lineTop:Hide()
    row.lineBottom:Hide()

    -- Clear dynamic anchors on icon and name
    row.icon:ClearAllPoints()
    row.nameText:ClearAllPoints()

    if not data then
        row.nameText:SetPoint("LEFT", 4, 0)
        row.nameText:SetPoint("RIGHT", row, "RIGHT", -120, 0)
        row.nameText:SetText("")
        return
    end

    local leftOffset = 4

    -- Status icon and colors
    if data.isComplete then
        row.icon:SetTexture(TEXTURE_QUEST_COMPLETE)
        row.icon:SetSize(12, 12)
        row.icon:Show()
        row.nameText:SetTextColor(COLOR.complete.r, COLOR.complete.g, COLOR.complete.b)
    elseif data.turnInReady then
        row.icon:SetTexture(TEXTURE_QUEST_TURN_IN)
        row.icon:SetSize(14, 14)
        row.icon:Show()
        row.nameText:SetTextColor(COLOR.available.r, COLOR.available.g, COLOR.available.b)
        row.bg:SetColorTexture(COLOR.readyBg.r, COLOR.readyBg.g, COLOR.readyBg.b, COLOR.readyBg.a)
    elseif data.inQuestLog then
        row.nameText:SetTextColor(COLOR.available.r, COLOR.available.g, COLOR.available.b)
        row.bg:SetColorTexture(COLOR.readyBg.r, COLOR.readyBg.g, COLOR.readyBg.b, COLOR.readyBg.a)
    elseif data.isAvailable then
        row.icon:SetTexture(TEXTURE_QUEST_AVAILABLE)
        row.icon:SetSize(14, 14)
        row.icon:Show()
        row.nameText:SetTextColor(COLOR.available.r, COLOR.available.g, COLOR.available.b)
    elseif data.nodeType then
        row.icon:Hide()
    else
        -- Locked: no icon, just muted text
        row.nameText:SetTextColor(COLOR.locked.r, COLOR.locked.g, COLOR.locked.b)
    end

    -- Position icon and name
    if row.icon:IsShown() then
        row.icon:SetPoint("LEFT", row, "LEFT", leftOffset, 0)
        row.nameText:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    else
        row.nameText:SetPoint("LEFT", row, "LEFT", leftOffset, 0)
    end
    row.nameText:SetPoint("RIGHT", row, "RIGHT", -120, 0)

    -- Name
    row.nameText:SetText(data.nameDisplay or "")

    -- Rep
    if data.repAmount and data.repAmount > 0 then
        row.repText:SetText("+" .. data.repAmount)
    elseif data.repPerUnit then
        row.repText:SetText(data.repPerUnit .. "/ea")
    end

    -- Tags
    local tags = {}
    if data.isGroupQuest then table.insert(tags, "|cffff4d4dGroup|r") end
    if data.ahTag then table.insert(tags, "|cff4de94dAH|r") end
    if #tags > 0 then
        row.tagText:SetText(table.concat(tags, " "))
    end
end

-- Flowchart rendering for quest chains

local FC_BOX_W = 170
local FC_BOX_H = 28
local FC_H_GAP = 14
local FC_V_GAP = 20
local FC_LINE_W = 2
local FC_CHAIN_GAP = 20

local FC_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local FC_COLORS = {
    complete  = { bg = { 0.15, 0.22, 0.15, 0.9 }, border = { 0.3, 0.45, 0.3, 0.7 }, line = { 0.3, 0.5, 0.3, 0.5 } },
    inLog     = { bg = { 0.18, 0.30, 0.18, 0.95 }, border = { 0.3, 0.75, 0.3, 0.9 }, line = { 0.3, 0.8, 0.3, 0.7 } },
    available = { bg = { 0.25, 0.25, 0.12, 0.9 }, border = { 0.65, 0.6, 0.2, 0.8 }, line = { 0.6, 0.6, 0.2, 0.6 } },
    locked    = { bg = { 0.12, 0.12, 0.12, 0.85 }, border = { 0.3, 0.3, 0.3, 0.4 }, line = { 0.3, 0.3, 0.3, 0.35 } },
}

local fcBoxPool = {}
local fcLinePool = {}
local fcBoxCount = 0
local fcLineCount = 0

local function fcBoxGet(parent)
    fcBoxCount = fcBoxCount + 1
    if fcBoxPool[fcBoxCount] then
        local box = fcBoxPool[fcBoxCount]
        box:SetParent(parent)
        box:ClearAllPoints()
        box:Show()
        return box
    end

    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetSize(FC_BOX_W, FC_BOX_H)
    box:SetBackdrop(FC_BACKDROP)
    box:EnableMouse(true)

    local icon = box:CreateTexture(nil, "ARTWORK")
    icon:SetSize(12, 12)
    icon:SetPoint("LEFT", 4, 0)
    icon:Hide()
    box.icon = icon

    local nameText = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    nameText:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    nameText:SetPoint("LEFT", icon, "RIGHT", 3, 0)
    nameText:SetPoint("RIGHT", box, "RIGHT", -32, 0)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    box.nameText = nameText

    local repText = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    repText:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    repText:SetPoint("RIGHT", box, "RIGHT", -4, 0)
    repText:SetJustifyH("RIGHT")
    repText:SetTextColor(1, 0.82, 0, 1)
    box.repText = repText

    box:SetScript("OnEnter", function(self)
        if not self.questID then return end
        local info = ns.questTooltipInfo(self.questID)
        if not info then return end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

        -- Title
        GameTooltip:AddLine(info.nameDisplay, 1, 0.82, 0)

        -- Quest type tag
        if info.questTag then
            local tagLine = info.questTag
            if info.suggestedGroup and info.suggestedGroup > 0 then
                tagLine = tagLine .. " (" .. info.suggestedGroup .. " players)"
            end
            GameTooltip:AddLine(tagLine, 1.0, 0.5, 0.2)
        end

        GameTooltip:AddLine(" ")

        -- Info lines (labeled, PAO style)
        if info.questGiver then
            GameTooltip:AddDoubleLine("Quest Giver:", info.questGiver, 0.5, 0.5, 0.5, 0.8, 0.8, 0.8)
        end
        if info.turnInNPC then
            GameTooltip:AddDoubleLine("Turn in:", info.turnInNPC, 0.5, 0.5, 0.5, 0.8, 0.8, 0.8)
        end
        if info.zone then
            GameTooltip:AddDoubleLine("Zone:", info.zone, 0.5, 0.5, 0.5, 0.8, 0.8, 0.8)
        end
        if self.repAmount and self.repAmount > 0 then
            GameTooltip:AddDoubleLine("Reputation:", "+" .. self.repAmount, 0.5, 0.5, 0.5, 1, 0.82, 0)
        end

        -- Action hints
        if TomTom then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine("|cff4de94d.|r Ctrl-click to set waypoint", 0.5, 0.8, 0.5)
        end

        GameTooltip:Show()
    end)

    box:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    fcBoxPool[fcBoxCount] = box
    return box
end

local function fcLineGet(parent)
    fcLineCount = fcLineCount + 1
    if fcLinePool[fcLineCount] then
        local line = fcLinePool[fcLineCount]
        line:SetParent(parent)
        line:ClearAllPoints()
        line:Show()
        return line
    end

    local line = parent:CreateTexture(nil, "BACKGROUND")
    fcLinePool[fcLineCount] = line
    return line
end

local function fcReset()
    for i = 1, fcBoxCount do fcBoxPool[i]:Hide() end
    for i = 1, fcLineCount do fcLinePool[i]:Hide() end
    fcBoxCount = 0
    fcLineCount = 0
end

-- Layout pass 1: calculate subtree pixel width and depth
local function fcCalcLayout(node)
    if #node.children == 0 then
        node.subtreeWidth = FC_BOX_W
        node.treeDepth = 0
        return
    end

    local totalWidth = 0
    local maxDepth = 0
    for i, child in ipairs(node.children) do
        fcCalcLayout(child)
        totalWidth = totalWidth + child.subtreeWidth
        if i > 1 then totalWidth = totalWidth + FC_H_GAP end
        if child.treeDepth > maxDepth then maxDepth = child.treeDepth end
    end

    node.subtreeWidth = math.max(FC_BOX_W, totalWidth)
    node.treeDepth = maxDepth + 1
end

-- Layout pass 2: assign pixel positions
-- Root at top (row 0), children below
local function fcAssignPositions(node, centerX, row)
    node.posX = centerX - FC_BOX_W / 2
    node.posY = row * (FC_BOX_H + FC_V_GAP)

    if #node.children == 0 then return end

    if #node.children == 1 then
        fcAssignPositions(node.children[1], centerX, row + 1)
        return
    end

    -- Multiple children: spread horizontally below
    local totalChildWidth = 0
    for i, child in ipairs(node.children) do
        totalChildWidth = totalChildWidth + child.subtreeWidth
        if i > 1 then totalChildWidth = totalChildWidth + FC_H_GAP end
    end

    local startX = centerX - totalChildWidth / 2
    for _, child in ipairs(node.children) do
        local childCenterX = startX + child.subtreeWidth / 2
        fcAssignPositions(child, childCenterX, row + 1)
        startX = startX + child.subtreeWidth + FC_H_GAP
    end
end

-- Draw a line segment (vertical or horizontal)
local function fcDrawLine(parent, x1, y1, x2, y2, color, startY)
    local line = fcLineGet(parent)
    line:SetColorTexture(unpack(color))

    if math.abs(x1 - x2) < 1 then
        -- Vertical
        local topY = math.min(y1, y2)
        local botY = math.max(y1, y2)
        line:SetPoint("TOPLEFT", parent, "TOPLEFT", x1 - FC_LINE_W / 2, startY - topY)
        line:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", x1 + FC_LINE_W / 2, startY - botY)
    else
        -- Horizontal
        local leftX = math.min(x1, x2)
        local rightX = math.max(x1, x2)
        line:SetPoint("TOPLEFT", parent, "TOPLEFT", leftX, startY - y1)
        line:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", rightX, startY - y1 - FC_LINE_W)
    end
end

-- Get the status color set for a node
local function fcNodeColors(node)
    if node.isComplete then return FC_COLORS.complete end
    if node.turnInReady or node.inQuestLog then return FC_COLORS.inLog end
    if node.isAvailable then return FC_COLORS.available end
    return FC_COLORS.locked
end

-- Render a box for a node
local function fcRenderBox(node, parent, startY)
    local box = fcBoxGet(parent)
    box:SetPoint("TOPLEFT", parent, "TOPLEFT", node.posX, startY - node.posY)
    box.questID = node.questID
    box.repAmount = node.repAmount

    local colors = fcNodeColors(node)
    box:SetBackdropColor(unpack(colors.bg))
    box:SetBackdropBorderColor(unpack(colors.border))

    -- Icon
    box.icon:Hide()
    if node.isComplete then
        box.icon:SetTexture(TEXTURE_QUEST_COMPLETE)
        box.icon:SetSize(10, 10)
        box.icon:Show()
        box.nameText:SetTextColor(0.5, 0.5, 0.5)
    elseif node.turnInReady then
        box.icon:SetTexture(TEXTURE_QUEST_TURN_IN)
        box.icon:SetSize(12, 12)
        box.icon:Show()
        box.nameText:SetTextColor(1, 1, 1)
    elseif node.inQuestLog then
        box.nameText:SetTextColor(1, 1, 1)
    elseif node.isAvailable then
        box.icon:SetTexture(TEXTURE_QUEST_AVAILABLE)
        box.icon:SetSize(12, 12)
        box.icon:Show()
        box.nameText:SetTextColor(1, 1, 1)
    else
        box.nameText:SetTextColor(0.5, 0.4, 0.3)
    end

    box.nameText:SetText(node.nameDisplay or "")

    if node.repAmount and node.repAmount > 0 then
        box.repText:SetText("+" .. node.repAmount)
    else
        box.repText:SetText("")
    end
end

-- Recursively render a forward chain tree: boxes and connecting lines
local function fcRenderChain(node, parent, startY)
    fcRenderBox(node, parent, startY)

    if #node.children == 0 then return end

    local nodeCenterX = node.posX + FC_BOX_W / 2
    local nodeBottomY = node.posY + FC_BOX_H

    if #node.children == 1 then
        local child = node.children[1]
        fcRenderChain(child, parent, startY)

        local childCenterX = child.posX + FC_BOX_W / 2
        local childTopY = child.posY
        local lineColor = fcNodeColors(child).line
        fcDrawLine(parent, nodeCenterX, nodeBottomY, childCenterX, childTopY, lineColor, startY)
        return
    end

    -- Multiple children: branch with horizontal bar
    local midY = nodeBottomY + FC_V_GAP / 2
    local lineColor = fcNodeColors(node).line

    -- Vertical from this node down to horizontal bar
    fcDrawLine(parent, nodeCenterX, nodeBottomY, nodeCenterX, midY, lineColor, startY)

    local leftmostX, rightmostX

    for _, child in ipairs(node.children) do
        fcRenderChain(child, parent, startY)

        local childCenterX = child.posX + FC_BOX_W / 2
        local childTopY = child.posY
        local childLineColor = fcNodeColors(child).line

        -- Vertical from horizontal bar down to child
        fcDrawLine(parent, childCenterX, midY, childCenterX, childTopY, childLineColor, startY)

        if not leftmostX or childCenterX < leftmostX then leftmostX = childCenterX end
        if not rightmostX or childCenterX > rightmostX then rightmostX = childCenterX end
    end

    -- Horizontal bar connecting all children
    if leftmostX and rightmostX and leftmostX ~= rightmostX then
        fcDrawLine(parent, leftmostX, midY, rightmostX, midY, lineColor, startY)
    end
end

-- Main frame

local function frameMainCreate()
    -- Restore saved size or use defaults
    local savedWidth = ns.db and ns.db.frameWidth or FRAME_WIDTH
    local savedHeight = ns.db and ns.db.frameHeight or FRAME_HEIGHT

    local f = CreateFrame("Frame", "NowWhatFrame", UIParent, "BackdropTemplate")
    f:SetSize(savedWidth, savedHeight)
    f:SetPoint("CENTER")
    f:SetBackdrop(BACKDROP_MAIN)
    f:SetBackdropColor(0.06, 0.06, 0.06, 0.97)
    f:SetMovable(true)
    f:SetResizable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetResizeBounds(700, 400, 1600, 900)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetFrameStrata("HIGH")

    -- Resize grip
    local resizeBtn = CreateFrame("Frame", nil, f)
    resizeBtn:SetSize(16, 16)
    resizeBtn:SetPoint("BOTTOMRIGHT", -4, 4)
    resizeBtn:EnableMouse(true)

    local resizeTex = resizeBtn:CreateTexture(nil, "OVERLAY")
    resizeTex:SetAllPoints()
    resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeBtn:SetScript("OnMouseDown", function()
        f:StartSizing("BOTTOMRIGHT")
    end)
    resizeBtn:SetScript("OnMouseUp", function()
        f:StopMovingOrSizing()
        local w, h = f:GetSize()
        if ns.db then
            ns.db.frameWidth = math.floor(w)
            ns.db.frameHeight = math.floor(h)
        end
        -- Update content width and re-render
        local newContentWidth = math.floor(w) - LEFT_WIDTH - 48
        if f.contentRight then
            f.contentRight:SetWidth(newContentWidth)
        end
        ns.uiRefresh()
    end)
    resizeBtn:SetScript("OnEnter", function()
        resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    end)
    resizeBtn:SetScript("OnLeave", function()
        resizeTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    end)

    -- Title
    local titleText = fontCreate(f, 14, COLOR.title)
    titleText:SetPoint("TOPLEFT", 12, -10)
    titleText:SetText("Now What?")

    -- Close
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Tabs
    local function tabCreate(label, xAnchor, anchorTo)
        local tab = CreateFrame("Button", nil, f)
        tab:SetSize(80, 22)
        if anchorTo then
            tab:SetPoint("LEFT", anchorTo, "RIGHT", 4, 0)
        else
            tab:SetPoint("TOPLEFT", 12, -30)
        end
        local bg = tab:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        tab.bg = bg
        local text = fontCreate(tab, FONT_NORMAL)
        text:SetPoint("CENTER")
        text:SetText(label)
        tab.label = text
        return tab
    end

    f.tabPlan = tabCreate("Plan")
    f.tabAgenda = tabCreate("Agenda", nil, f.tabPlan)

    local function tabSetActive(tabName)
        activeTab = tabName
        -- Plan tab
        if tabName == "plan" then
            f.tabPlan.bg:SetColorTexture(COLOR.tabActive.r, COLOR.tabActive.g, COLOR.tabActive.b, COLOR.tabActive.a)
            f.tabPlan.label:SetTextColor(COLOR.title.r, COLOR.title.g, COLOR.title.b)
            f.tabAgenda.bg:SetColorTexture(COLOR.tabInactive.r, COLOR.tabInactive.g, COLOR.tabInactive.b, COLOR.tabInactive.a)
            f.tabAgenda.label:SetTextColor(COLOR.locked.r, COLOR.locked.g, COLOR.locked.b)
            if f.panelLeft then f.panelLeft:Show() end
            if f.panelRight then f.panelRight:Show() end
            if f.panelAgenda then f.panelAgenda:Hide() end
        else
            f.tabAgenda.bg:SetColorTexture(COLOR.tabActive.r, COLOR.tabActive.g, COLOR.tabActive.b, COLOR.tabActive.a)
            f.tabAgenda.label:SetTextColor(COLOR.title.r, COLOR.title.g, COLOR.title.b)
            f.tabPlan.bg:SetColorTexture(COLOR.tabInactive.r, COLOR.tabInactive.g, COLOR.tabInactive.b, COLOR.tabInactive.a)
            f.tabPlan.label:SetTextColor(COLOR.locked.r, COLOR.locked.g, COLOR.locked.b)
            if f.panelLeft then f.panelLeft:Hide() end
            if f.panelRight then f.panelRight:Hide() end
            if f.panelAgenda then f.panelAgenda:Show() end
        end
    end

    f.tabPlan:SetScript("OnClick", function() tabSetActive("plan") end)
    f.tabAgenda:SetScript("OnClick", function() tabSetActive("agenda") end)

    local contentTop = -56

    -- Left panel
    local panelLeft = CreateFrame("Frame", nil, f, "BackdropTemplate")
    panelLeft:SetPoint("TOPLEFT", 8, contentTop)
    panelLeft:SetPoint("BOTTOMLEFT", 8, 8)
    panelLeft:SetWidth(LEFT_WIDTH)
    panelLeft:SetBackdrop(BACKDROP_PANEL)
    panelLeft:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
    f.panelLeft = panelLeft

    local labelFactions = fontCreate(panelLeft, FONT_SMALL, { r = 0.6, g = 0.6, b = 0.6 })
    labelFactions:SetPoint("TOPLEFT", 8, -6)
    labelFactions:SetText("FACTION GOALS")

    local scrollLeft = CreateFrame("ScrollFrame", nil, panelLeft, "UIPanelScrollFrameTemplate")
    scrollLeft:SetPoint("TOPLEFT", 4, -22)
    scrollLeft:SetPoint("BOTTOMRIGHT", -24, 4)

    local contentLeft = CreateFrame("Frame", nil, scrollLeft)
    contentLeft:SetWidth(LEFT_WIDTH - 28)
    contentLeft:SetHeight(1)
    scrollLeft:SetScrollChild(contentLeft)
    f.contentLeft = contentLeft

    -- Right panel
    local panelRight = CreateFrame("Frame", nil, f, "BackdropTemplate")
    panelRight:SetPoint("TOPLEFT", panelLeft, "TOPRIGHT", 4, 0)
    panelRight:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)
    panelRight:SetBackdrop(BACKDROP_PANEL)
    panelRight:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
    f.panelRight = panelRight

    local labelDetail = fontCreate(panelRight, FONT_HEADER, { r = 0.7, g = 0.7, b = 0.7 })
    labelDetail:SetPoint("TOPLEFT", 8, -6)
    labelDetail:SetText("Select a faction")
    f.labelDetail = labelDetail

    local labelSummary = fontCreate(panelRight, FONT_SMALL, COLOR.rep)
    labelSummary:SetPoint("TOPLEFT", labelDetail, "BOTTOMLEFT", 0, -2)
    f.labelSummary = labelSummary

    -- Hide completed toggle
    local toggleBtn = CreateFrame("Button", nil, panelRight)
    toggleBtn:SetSize(120, 18)
    toggleBtn:SetPoint("TOPRIGHT", panelRight, "TOPRIGHT", -28, -8)
    local toggleBg = toggleBtn:CreateTexture(nil, "BACKGROUND")
    toggleBg:SetAllPoints()
    toggleBg:SetColorTexture(0.15, 0.15, 0.15, 0.7)
    local toggleText = fontCreate(toggleBtn, FONT_SMALL, { r = 0.7, g = 0.7, b = 0.7 })
    toggleText:SetPoint("CENTER")
    toggleText:SetText("Hide Completed")
    toggleBtn.label = toggleText
    toggleBtn:SetScript("OnClick", function()
        hideCompleted = not hideCompleted
        if hideCompleted then
            toggleBtn.label:SetTextColor(COLOR.title.r, COLOR.title.g, COLOR.title.b)
            toggleBg:SetColorTexture(COLOR.tabActive.r, COLOR.tabActive.g, COLOR.tabActive.b, COLOR.tabActive.a)
        else
            toggleBtn.label:SetTextColor(0.7, 0.7, 0.7)
            toggleBg:SetColorTexture(0.15, 0.15, 0.15, 0.7)
        end
        if factionSelected then
            populateRightPanel(factionSelected)
        end
    end)
    f.toggleBtn = toggleBtn

    local scrollRight = CreateFrame("ScrollFrame", nil, panelRight, "UIPanelScrollFrameTemplate")
    scrollRight:SetPoint("TOPLEFT", 4, -42)
    scrollRight:SetPoint("BOTTOMRIGHT", -24, 4)

    local contentRight = CreateFrame("Frame", nil, scrollRight)
    contentRight:SetWidth(savedWidth - LEFT_WIDTH - 48)
    contentRight:SetHeight(1)
    scrollRight:SetScrollChild(contentRight)
    f.contentRight = contentRight

    -- Agenda panel (placeholder, same area as left+right combined)
    local panelAgenda = CreateFrame("Frame", nil, f, "BackdropTemplate")
    panelAgenda:SetPoint("TOPLEFT", 8, contentTop)
    panelAgenda:SetPoint("BOTTOMRIGHT", -8, 8)
    panelAgenda:SetBackdrop(BACKDROP_PANEL)
    panelAgenda:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
    panelAgenda:Hide()
    f.panelAgenda = panelAgenda

    local agendaLabel = fontCreate(panelAgenda, FONT_HEADER, { r = 0.7, g = 0.7, b = 0.7 })
    agendaLabel:SetPoint("TOPLEFT", 12, -12)
    agendaLabel:SetText("Combined Agenda — coming soon")

    local agendaNote = fontCreate(panelAgenda, FONT_NORMAL, COLOR.locked)
    agendaNote:SetPoint("TOPLEFT", agendaLabel, "BOTTOMLEFT", 0, -8)
    agendaNote:SetText("This view will combine all faction goals into a single prioritized action list,\ngrouped by zone, with overlapping objectives highlighted.")

    -- Initialize tabs
    tabSetActive("plan")

    table.insert(UISpecialFrames, "NowWhatFrame")
    f:Hide()
    return f
end

-- Populate left panel

local factionRowFrames = {}

local function populateLeftPanel()
    if not frameMain then return end

    ns.reputationsRead()

    local goals = ns.charDb.goalsActive
    if not goals then return end

    for _, row in pairs(factionRowFrames) do
        row:Hide()
    end

    local index = 0
    for factionID, standingTarget in pairs(goals) do
        index = index + 1

        local row = factionRowFrames[index]
        if not row then
            row = CreateFrame("Button", nil, frameMain.contentLeft)
            row:SetHeight(FACTION_ROW_HEIGHT)

            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            row.bg = bg

            local nameText = fontCreate(row, FONT_NORMAL, COLOR.available)
            nameText:SetPoint("TOPLEFT", 8, -5)
            nameText:SetJustifyH("LEFT")
            row.nameText = nameText

            local standingText = fontCreate(row, FONT_SMALL, { r = 0.7, g = 0.7, b = 0.7 })
            standingText:SetPoint("TOPLEFT", 8, -21)
            standingText:SetJustifyH("LEFT")
            row.standingText = standingText

            local repBar = repBarCreate(row)
            repBar:SetPoint("BOTTOMLEFT", 8, 6)
            repBar:SetPoint("BOTTOMRIGHT", -8, 6)
            row.repBar = repBar

            row:SetScript("OnEnter", function(self)
                if factionSelected ~= self.factionID then
                    self.bg:SetColorTexture(COLOR.factionHov.r, COLOR.factionHov.g, COLOR.factionHov.b, COLOR.factionHov.a)
                end
            end)
            row:SetScript("OnLeave", function(self)
                if factionSelected ~= self.factionID then
                    self.bg:SetColorTexture(COLOR.factionBg.r, COLOR.factionBg.g, COLOR.factionBg.b, COLOR.factionBg.a)
                end
            end)

            factionRowFrames[index] = row
        end

        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frameMain.contentLeft, "TOPLEFT", 2, -((index - 1) * (FACTION_ROW_HEIGHT + FACTION_ROW_GAP)) - 2)
        row:SetPoint("RIGHT", frameMain.contentLeft, "RIGHT", -2, 0)

        local plan = ns.planBuild(factionID, standingTarget)
        row.factionID = factionID
        row.nameText:SetText(plan.nameDisplay)
        row.standingText:SetText(string.format("%s  %d/%d   ->   %s",
            ns.STANDING_NAME[plan.standingCurrent] or "?",
            plan.valueCurrent, plan.valueMax,
            ns.STANDING_NAME[plan.standingTarget] or "?"))

        repBarUpdate(row.repBar, plan.valueMax - plan.valueCurrent, plan.valueMax)

        if factionSelected == factionID then
            row.bg:SetColorTexture(COLOR.factionSel.r, COLOR.factionSel.g, COLOR.factionSel.b, COLOR.factionSel.a)
        else
            row.bg:SetColorTexture(COLOR.factionBg.r, COLOR.factionBg.g, COLOR.factionBg.b, COLOR.factionBg.a)
        end

        row:SetScript("OnClick", function(self)
            factionSelected = self.factionID
            populateLeftPanel()
            populateRightPanel(self.factionID)
        end)

        row:Show()
    end

    frameMain.contentLeft:SetHeight(index * (FACTION_ROW_HEIGHT + FACTION_ROW_GAP) + 4)
end

-- Populate right panel

function populateRightPanel(factionID)
    if not frameMain then return end

    local contentRight = frameMain.contentRight

    -- Hide everything
    for _, row in pairs(chainRowPool) do row:Hide() end
    for _, header in pairs(sectionHeaderPool) do header:Hide() end
    fcReset()

    local factionMeta = ns.dataReputations[factionID]
    local factionName = factionMeta and factionMeta.nameDisplay or ("Faction " .. factionID)
    local standingTarget = ns.charDb.goalsActive[factionID] or ns.STANDING_EXALTED
    local plan = ns.planBuild(factionID, standingTarget)

    frameMain.labelDetail:SetText(factionName)
    frameMain.labelSummary:SetText(string.format("%s (%d/%d)  ->  %s  |  %d rep needed  |  ~%d from quests",
        ns.STANDING_NAME[plan.standingCurrent] or "?",
        plan.valueCurrent, plan.valueMax,
        ns.STANDING_NAME[plan.standingTarget] or "?",
        plan.repNeeded,
        plan.repFromQuests))

    local yOffset = 0
    local rowIndex = 0
    local sectionIndex = 0
    local rightWidth = contentRight:GetWidth()

    -- Helper: place a section header
    local function placeSection(label)
        sectionIndex = sectionIndex + 1
        local header = sectionHeaderGet(contentRight, sectionIndex)
        header:ClearAllPoints()
        header:SetPoint("TOPLEFT", contentRight, "TOPLEFT", 0, yOffset)
        header:SetPoint("RIGHT", contentRight, "RIGHT", 0, 0)
        header.label:SetText(label)
        yOffset = yOffset - SECTION_HEADER_HEIGHT
    end

    -- Helper: place a data row
    local function placeRow(data, indent)
        rowIndex = rowIndex + 1
        local row = chainRowGet(contentRight, rowIndex)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", contentRight, "TOPLEFT", indent or 0, yOffset)
        row:SetPoint("RIGHT", contentRight, "RIGHT", -4, 0)
        chainRowConfigure(row, data)
        yOffset = yOffset - ROW_HEIGHT
    end

    -- Helper: place an info line (no icon)
    local function placeInfo(text, color)
        rowIndex = rowIndex + 1
        local row = chainRowGet(contentRight, rowIndex)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", contentRight, "TOPLEFT", 8, yOffset)
        row:SetPoint("RIGHT", contentRight, "RIGHT", -4, 0)
        chainRowConfigure(row, nil)
        row.icon:Hide()
        row.nameText:SetText(text)
        row.nameText:SetTextColor(color.r, color.g, color.b)
        yOffset = yOffset - ROW_HEIGHT
    end

    -- SECTION: Quests (flowchart)
    placeSection("Quests")

    fcReset()

    local chains = ns.chainsForFaction(factionID)

    if #chains == 0 then
        placeInfo("No uncompleted quests", COLOR.complete)
    else
        for _, chain in ipairs(chains) do
            fcCalcLayout(chain)
            local totalHeight = (chain.treeDepth + 1) * (FC_BOX_H + FC_V_GAP) - FC_V_GAP
            local centerX = rightWidth / 2

            fcAssignPositions(chain, centerX, 0)
            fcRenderChain(chain, contentRight, yOffset)

            yOffset = yOffset - totalHeight - FC_CHAIN_GAP
        end
    end

    -- SECTION: Dailies
    yOffset = yOffset - 8
    placeSection("Dailies")

    local dailies = ns.dailiesForFaction(factionID)
    if #dailies > 0 then
        for _, daily in ipairs(dailies) do
            daily.nodeType = "daily"
            daily.isDaily = true
            placeRow(daily, 8)
            chainRowPool[rowIndex].nameText:SetTextColor(COLOR.daily.r, COLOR.daily.g, COLOR.daily.b)
            chainRowPool[rowIndex].icon:Hide()
        end
    else
        placeInfo("No dailies for this faction", COLOR.complete)
    end

    -- SECTION: Repeatable Turn-ins
    yOffset = yOffset - 8
    placeSection("Repeatable Turn-ins")

    local hasRepeatables = false

    -- Repeatable quests from Questie
    local repeatables = ns.repeatablesForFaction(factionID)
    for _, rep in ipairs(repeatables) do
        hasRepeatables = true
        rep.nodeType = "repeatable"
        placeRow(rep, 8)
        chainRowPool[rowIndex].nameText:SetTextColor(COLOR.turnIn.r, COLOR.turnIn.g, COLOR.turnIn.b)
        chainRowPool[rowIndex].icon:Hide()
    end

    -- Static turn-in data
    local turnIns = ns.dataTurnIns[factionID]
    if turnIns and plan.repRemaining > 0 then
        for _, turnIn in ipairs(turnIns) do
            if plan.standingCurrent < turnIn.standingMax then
                hasRepeatables = true
                local turnInsNeeded, itemsNeeded = ns.turnInsCalculate(turnIn, plan.repRemaining)
                placeRow({
                    nodeType = "turnIn",
                    nameDisplay = string.format("%s x%d  (%d turn-ins)", turnIn.nameDisplay, itemsNeeded, turnInsNeeded),
                    repPerUnit = turnIn.repPerTurnIn,
                    ahTag = turnIn.isTradeable,
                    isAvailable = true,
                }, 8)
                chainRowPool[rowIndex].nameText:SetTextColor(COLOR.turnIn.r, COLOR.turnIn.g, COLOR.turnIn.b)
                chainRowPool[rowIndex].icon:Hide()
            end
        end
    end

    if not hasRepeatables then
        placeInfo(plan.repRemaining > 0 and "None available at current standing" or "Not needed", COLOR.complete)
    end

    -- SECTION: Dungeons
    yOffset = yOffset - 8
    placeSection("Dungeons")

    local dungeons = ns.dungeonsForFaction(factionID)
    local hasDungeons = false

    for _, dungeon in ipairs(dungeons) do
        -- Normal
        local capNormal = dungeon.standingCapNormal
        if not capNormal or plan.standingCurrent < capNormal then
            hasDungeons = true
            local capLabel = capNormal and ("  (to " .. ns.STANDING_NAME[capNormal] .. ")") or ""
            placeRow({
                nodeType = "dungeon",
                nameDisplay = string.format("%s (Normal)  ~%d rep/run%s", dungeon.nameDisplay, dungeon.repPerRunNormal, capLabel),
                isAvailable = true,
            }, 8)
            chainRowPool[rowIndex].nameText:SetTextColor(COLOR.dungeon.r, COLOR.dungeon.g, COLOR.dungeon.b)
            chainRowPool[rowIndex].icon:Hide()
        end

        -- Heroic
        local capHeroic = dungeon.standingCapHeroic
        if not capHeroic or plan.standingCurrent < capHeroic then
            hasDungeons = true
            placeRow({
                nodeType = "dungeon",
                nameDisplay = string.format("%s (Heroic)  ~%d rep/run", dungeon.nameDisplay, dungeon.repPerRunHeroic),
                isAvailable = true,
            }, 8)
            chainRowPool[rowIndex].nameText:SetTextColor(COLOR.dungeon.r, COLOR.dungeon.g, COLOR.dungeon.b)
            chainRowPool[rowIndex].icon:Hide()
        end
    end

    if not hasDungeons then
        placeInfo("No dungeon rep sources", COLOR.complete)
    end

    contentRight:SetHeight(math.abs(yOffset) + 8)
end

-- Toggle

function ns.uiToggle()
    if not frameMain then
        frameMain = frameMainCreate()
    end

    if frameMain:IsShown() then
        frameMain:Hide()
    else
        populateLeftPanel()
        frameMain:Show()

        if not factionSelected then
            local goals = ns.charDb.goalsActive
            if goals then
                for factionID in pairs(goals) do
                    factionSelected = factionID
                    break
                end
            end
        end

        populateLeftPanel()
        if factionSelected then
            populateRightPanel(factionSelected)
        end
    end
end

function ns.uiRefresh()
    if frameMain and frameMain:IsShown() then
        populateLeftPanel()
        if factionSelected then
            populateRightPanel(factionSelected)
        end
    end
end

-- Slash commands

ns.commandRegister("show", function()
    ns.uiToggle()
end, "Open the NowWhat window")

local originalHandler = SlashCmdList["NOWWHAT"]
SlashCmdList["NOWWHAT"] = function(input)
    if input == "" then
        ns.uiToggle()
    else
        originalHandler(input)
    end
end