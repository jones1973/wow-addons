----------------------------------------------------------------------
-- Speed
-- Shows your current movement speed as a percentage.
-- Normal run speed = 100%
-- Supports LibDataBroker (LDB) for bar addons.
-- Works on any WoW client.
----------------------------------------------------------------------

local ADDON_NAME = "Speed"
local BASE_SPEED = 7 -- yards per second at 100% run speed

SpeedDB = SpeedDB or {}

----------------------------------------------------------------------
-- LDB data object
----------------------------------------------------------------------
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:NewDataObject(ADDON_NAME, {
    type = "data source",
    text = "Speed: 0%",
    label = ADDON_NAME,
    icon = "Interface\\Icons\\Ability_Rogue_Sprint",
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("Speed", 1, 1, 1)
        tooltip:AddLine(" ")
        local speed = GetUnitSpeed("player")
        local pct = speed / BASE_SPEED * 100
        tooltip:AddDoubleLine("Current Speed:", string.format("%.1f%%", pct), 1, 1, 1, 1, 1, 0)
        tooltip:AddDoubleLine("Yards / sec:", string.format("%.1f", speed), 1, 1, 1, 0.8, 0.8, 0.8)
        tooltip:AddLine(" ")
        tooltip:AddLine("Left-click to toggle display frame.", 0, 1, 0)
    end,
    OnClick = function(_, button)
        if button == "LeftButton" then
            if SpeedFrame:IsShown() then
                SpeedFrame:Hide()
                SpeedDB.shown = false
            else
                SpeedFrame:Show()
                SpeedDB.shown = true
            end
        end
    end,
})

----------------------------------------------------------------------
-- Display frame
----------------------------------------------------------------------
local frame = CreateFrame("Frame", "SpeedFrame", UIParent)
frame:SetWidth(70)
frame:SetHeight(24)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:RegisterForDrag("LeftButton")

frame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, xOfs, yOfs = self:GetPoint()
    SpeedDB.point = point
    SpeedDB.relPoint = relPoint
    SpeedDB.xOfs = xOfs
    SpeedDB.yOfs = yOfs
end)

local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.5)

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
text:SetPoint("CENTER", frame, "CENTER", 0, 0)
text:SetTextColor(1, 1, 1, 1)
text:SetText("100%")

----------------------------------------------------------------------
-- Speed display update
----------------------------------------------------------------------
local ticker = CreateFrame("Frame")
local elapsed_acc = 0
local UPDATE_INTERVAL = 0.3

ticker:SetScript("OnUpdate", function(self, elapsed)
    elapsed_acc = elapsed_acc + elapsed
    if elapsed_acc < UPDATE_INTERVAL then return end
    elapsed_acc = 0

    local speed = GetUnitSpeed("player")
    local pct = speed / BASE_SPEED * 100
    local display

    local rounded = math.floor(pct + 0.5)
    if math.abs(pct - rounded) < 0.05 then
        display = string.format("%d%%", rounded)
    else
        display = string.format("%.1f%%", pct)
    end

    text:SetText(display)
    dataobj.text = "Speed: " .. display
end)

----------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------
local init = CreateFrame("Frame")
init:RegisterEvent("PLAYER_LOGIN")
init:SetScript("OnEvent", function(self, event)
    SpeedDB = SpeedDB or {}

    if SpeedDB.point then
        frame:ClearAllPoints()
        frame:SetPoint(SpeedDB.point, UIParent, SpeedDB.relPoint, SpeedDB.xOfs, SpeedDB.yOfs)
    end

    if SpeedDB.shown == false then
        frame:Hide()
    else
        SpeedDB.shown = true
        frame:Show()
    end

    self:UnregisterEvent("PLAYER_LOGIN")
end)

----------------------------------------------------------------------
-- Slash commands
----------------------------------------------------------------------
SLASH_SPEED1 = "/speed"
SlashCmdList["SPEED"] = function(msg)
    msg = strtrim(msg or ""):lower()
    if msg == "reset" then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        SpeedDB.point = "CENTER"
        SpeedDB.relPoint = "CENTER"
        SpeedDB.xOfs = 0
        SpeedDB.yOfs = 0
        print("|cff00ccffSpeed:|r Frame position reset.")
    elseif msg == "toggle" or msg == "" then
        if frame:IsShown() then
            frame:Hide()
            SpeedDB.shown = false
            print("|cff00ccffSpeed:|r Frame hidden.")
        else
            frame:Show()
            SpeedDB.shown = true
            print("|cff00ccffSpeed:|r Frame shown.")
        end
    else
        print("|cff00ccffSpeed|r commands:")
        print("  /speed - Toggle display frame")
        print("  /speed reset - Reset frame position to center")
    end
end
