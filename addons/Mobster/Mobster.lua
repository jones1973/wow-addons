local addonName, ns = ...

------------------------------------------------------------------------
-- Defaults & State
------------------------------------------------------------------------
local DEFAULTS = {
    watchList = {},
    soundEnabled = true,
    markEnabled = true,
    framePos = nil,
}

local SCAN_INTERVAL = 0.5
local ALERT_SOUND = 8959 -- Raid Warning

local previousGUIDs = {}       -- {[guid] = name}
local iconAssignments = {}     -- {[guid] = iconIndex}
local freeIcons = {}           -- {[iconIndex] = true}
local elapsed = 0
local scanning = false

-- Icon priority: skull first, then down
local ICON_ORDER = {8, 7, 6, 5, 4, 3, 2, 1}

------------------------------------------------------------------------
-- Utility
------------------------------------------------------------------------
local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[Mobster]|r " .. msg)
end

local function InitIcons()
    wipe(freeIcons)
    for i = 1, 8 do
        freeIcons[i] = true
    end
end

local function AllocIcon()
    for _, icon in ipairs(ICON_ORDER) do
        if freeIcons[icon] then
            freeIcons[icon] = nil
            return icon
        end
    end
    return nil
end

local function FreeIcon(icon)
    if icon then freeIcons[icon] = true end
end

local function IsGrouped()
    return IsInGroup() or IsInRaid()
end

local function MatchesWatchList(name)
    if not name or not MobsterCharDB or #MobsterCharDB.watchList == 0 then
        return false
    end
    local lower = name:lower()
    for _, pattern in ipairs(MobsterCharDB.watchList) do
        if lower:find(pattern:lower(), 1, true) then
            return true
        end
    end
    return false
end

------------------------------------------------------------------------
-- Nameplate Scanning
------------------------------------------------------------------------
local function ScanNameplates()
    if not MobsterCharDB or #MobsterCharDB.watchList == 0 then return end

    -- Build current set
    local currentGUIDs = {}
    local plates = C_NamePlate.GetNamePlates()
    for _, plateFrame in ipairs(plates) do
        local unit = plateFrame.namePlateUnitToken
        if unit
            and UnitCanAttack("player", unit)
            and not UnitIsDead(unit)
        then
            local name = UnitName(unit)
            if name and MatchesWatchList(name) then
                local guid = UnitGUID(unit)
                if guid then
                    currentGUIDs[guid] = { name = name, unit = unit }
                end
            end
        end
    end

    -- Free icons for GUIDs that left
    for guid in pairs(previousGUIDs) do
        if not currentGUIDs[guid] and iconAssignments[guid] then
            FreeIcon(iconAssignments[guid])
            iconAssignments[guid] = nil
        end
    end

    -- Find new GUIDs (present now but not previously)
    local newByName = {} -- {[name] = count}
    local hasNew = false
    for guid, info in pairs(currentGUIDs) do
        if not previousGUIDs[guid] then
            hasNew = true
            newByName[info.name] = (newByName[info.name] or 0) + 1

            -- Mark if solo and marking enabled
            if not IsGrouped() and MobsterCharDB.markEnabled then
                local icon = AllocIcon()
                if icon then
                    SetRaidTarget(info.unit, icon)
                    iconAssignments[guid] = icon
                end
            end
        end
    end

    -- Alert on new mobs
    if hasNew then
        if MobsterCharDB.soundEnabled then
            PlaySound(ALERT_SOUND, "Master")
        end

        if IsGrouped() then
            local parts = {}
            for name, count in pairs(newByName) do
                if count > 1 then
                    parts[#parts + 1] = name .. " (" .. count .. ")"
                else
                    parts[#parts + 1] = name
                end
            end
            Print("Found: " .. table.concat(parts, ", "))
        end
    end

    previousGUIDs = currentGUIDs
end

------------------------------------------------------------------------
-- Core Frame (event handling + ticker)
------------------------------------------------------------------------
local core = CreateFrame("Frame", "MobsterCore", UIParent)

core:SetScript("OnUpdate", function(_, dt)
    if not scanning then return end
    elapsed = elapsed + dt
    if elapsed >= SCAN_INTERVAL then
        elapsed = 0
        ScanNameplates()
    end
end)

core:RegisterEvent("ADDON_LOADED")
core:RegisterEvent("GROUP_ROSTER_UPDATE")
core:RegisterEvent("PLAYER_ENTERING_WORLD")

core:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if not MobsterCharDB then
            MobsterCharDB = {}
        end
        for k, v in pairs(DEFAULTS) do
            if MobsterCharDB[k] == nil then
                if type(v) == "table" then
                    MobsterCharDB[k] = {}
                else
                    MobsterCharDB[k] = v
                end
            end
        end
        InitIcons()
        scanning = true
        ns:BuildUI()
        Print("Loaded. Type /mob to open.")

    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Reset tracking on group changes; existing marks stay but we stop adding
        wipe(iconAssignments)
        InitIcons()
        wipe(previousGUIDs)

    elseif event == "PLAYER_ENTERING_WORLD" then
        wipe(previousGUIDs)
        wipe(iconAssignments)
        InitIcons()
    end
end)

------------------------------------------------------------------------
-- UI
------------------------------------------------------------------------
local rows = {}

local function MakeRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(218, 22)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * 24)

    local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", 4, 0)
    text:SetJustifyH("LEFT")
    text:SetWidth(180)
    row.text = text

    local del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    del:SetSize(22, 22)
    del:SetPoint("RIGHT", 0, 0)
    del:SetText("X")
    del.index = index
    del:SetScript("OnClick", function(self)
        table.remove(MobsterCharDB.watchList, self.index)
        wipe(previousGUIDs)
        ns:RefreshList()
    end)
    row.del = del

    return row
end

function ns:RefreshList()
    local list = MobsterCharDB.watchList
    -- Create/update rows
    for i, entry in ipairs(list) do
        if not rows[i] then
            rows[i] = MakeRow(ns.scrollChild, i)
        end
        local row = rows[i]
        row.text:SetText(entry)
        row.del.index = i
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -(i - 1) * 24)
        row:Show()
    end
    -- Hide extras
    for i = #list + 1, #rows do
        rows[i]:Hide()
    end
    ns.scrollChild:SetHeight(math.max(1, #list * 24))
end

function ns:BuildUI()
    local ui = CreateFrame("Frame", "MobsterUI", UIParent, "BackdropTemplate")
    ui:SetSize(280, 360)
    ui:SetPoint("CENTER")
    ui:SetMovable(true)
    ui:SetClampedToScreen(true)
    ui:EnableMouse(true)
    ui:SetFrameStrata("DIALOG")
    ui:RegisterForDrag("LeftButton")
    ui:SetScript("OnDragStart", ui.StartMoving)
    ui:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint()
        MobsterCharDB.framePos = { point, x, y }
    end)
    ui:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    -- Restore position
    if MobsterCharDB.framePos then
        ui:ClearAllPoints()
        local p = MobsterCharDB.framePos
        ui:SetPoint(p[1], UIParent, p[1], p[2], p[3])
    end

    ui:Hide()
    ns.ui = ui

    -- Title
    local title = ui:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("Mobster")

    -- Close button
    local close = CreateFrame("Button", nil, ui, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    -- Scroll area
    local scroll = CreateFrame("ScrollFrame", "MobsterScroll", ui, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 16, -42)
    scroll:SetPoint("BOTTOMRIGHT", -36, 105)

    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(218, 1)
    scroll:SetScrollChild(child)
    ns.scrollChild = child

    -- Separator line above input area
    local sep = ui:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("LEFT", 16, 0)
    sep:SetPoint("RIGHT", -16, 0)
    sep:SetPoint("BOTTOM", 0, 96)
    sep:SetColorTexture(0.4, 0.4, 0.4, 0.6)

    -- Edit box + Add button
    local edit = CreateFrame("EditBox", "MobsterEdit", ui, "InputBoxTemplate")
    edit:SetSize(178, 24)
    edit:SetPoint("BOTTOMLEFT", 22, 68)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(60)

    local addBtn = CreateFrame("Button", nil, ui, "UIPanelButtonTemplate")
    addBtn:SetSize(50, 24)
    addBtn:SetPoint("LEFT", edit, "RIGHT", 6, 0)
    addBtn:SetText("Add")

    local function DoAdd()
        local text = edit:GetText():trim()
        if text ~= "" then
            table.insert(MobsterCharDB.watchList, text)
            edit:SetText("")
            wipe(previousGUIDs)
            ns:RefreshList()
        end
        edit:ClearFocus()
    end

    addBtn:SetScript("OnClick", DoAdd)
    edit:SetScript("OnEnterPressed", DoAdd)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- Sound checkbox
    local soundCB = CreateFrame("CheckButton", "MobsterSoundCB", ui, "UICheckButtonTemplate")
    soundCB:SetPoint("BOTTOMLEFT", 14, 34)
    soundCB:SetSize(24, 24)
    soundCB:SetChecked(MobsterCharDB.soundEnabled)
    soundCB:SetScript("OnClick", function(self)
        MobsterCharDB.soundEnabled = self:GetChecked() and true or false
    end)
    local soundLbl = soundCB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    soundLbl:SetPoint("LEFT", soundCB, "RIGHT", 2, 0)
    soundLbl:SetText("Sound")

    -- Mark checkbox
    local markCB = CreateFrame("CheckButton", "MobsterMarkCB", ui, "UICheckButtonTemplate")
    markCB:SetPoint("LEFT", soundLbl, "RIGHT", 20, 0)
    markCB:SetSize(24, 24)
    markCB:SetChecked(MobsterCharDB.markEnabled)
    markCB:SetScript("OnClick", function(self)
        MobsterCharDB.markEnabled = self:GetChecked() and true or false
    end)
    local markLbl = markCB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    markLbl:SetPoint("LEFT", markCB, "RIGHT", 2, 0)
    markLbl:SetText("Mark (solo only)")

    -- Initial list population
    ns:RefreshList()
end

------------------------------------------------------------------------
-- Slash Commands
------------------------------------------------------------------------
SLASH_MOBSTER1 = "/mob"
SlashCmdList["MOBSTER"] = function(msg)
    msg = (msg or ""):trim()

    if msg == "" then
        if ns.ui then
            if ns.ui:IsShown() then ns.ui:Hide() else ns.ui:Show() end
        end
        return
    end

    local cmd, rest = msg:match("^(%S+)%s*(.*)")
    cmd = cmd and cmd:lower() or ""
    rest = rest and rest:trim() or ""

    if cmd == "add" and rest ~= "" then
        table.insert(MobsterCharDB.watchList, rest)
        wipe(previousGUIDs)
        if ns.RefreshList then ns:RefreshList() end
        Print("Added: " .. rest)

    elseif cmd == "remove" and rest ~= "" then
        local lower = rest:lower()
        for i = #MobsterCharDB.watchList, 1, -1 do
            if MobsterCharDB.watchList[i]:lower():find(lower, 1, true) then
                Print("Removed: " .. MobsterCharDB.watchList[i])
                table.remove(MobsterCharDB.watchList, i)
                break
            end
        end
        wipe(previousGUIDs)
        if ns.RefreshList then ns:RefreshList() end

    else
        Print("Usage:")
        Print("  /mob  — toggle UI")
        Print("  /mob add <partial>  — add to watch list")
        Print("  /mob remove <partial>  — remove from watch list")
    end
end