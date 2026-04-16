--[[
  main.lua
  Speed - Movement Speed Display

  Shows the player's current movement speed as a percentage of base run speed
  (7 yards/sec = 100%). Provides an on-screen draggable frame and a
  LibDataBroker-1.1 data source for bar addons like Titan Panel.

  Works on any WoW client - no expansion-specific APIs.

  Exports: Speed (global, for /dump debugging)
]]

local ADDON_NAME, Addon = ...

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local BASE_SPEED = 7       -- Yards per second at 100% run speed
local UPDATE_INTERVAL = 0.3
local ROUND_TOLERANCE = 0.05  -- Values within this of an integer display as whole numbers

-- ============================================================================
-- GLOBAL ACCESS
-- ============================================================================

-- External name for /dump debugging. Only set here, never used internally.
Speed = Addon

-- ============================================================================
-- STATE
-- ============================================================================

local speedFrame   -- The draggable on-screen display
local speedText    -- The fontstring on speedFrame
local dataObject   -- LDB data source

-- ============================================================================
-- HELPERS
-- ============================================================================

--[[
  Format a speed percentage for display.
  Rounds to a whole number when within tolerance (avoids floating-point noise
  like "206.00%"). Shows one decimal for genuinely non-integer values
  (e.g., 391.4% from stacked bonuses).

  @param pct number - Speed percentage (0-based, where 100 = base run speed)
  @return string - Formatted display text (e.g., "206%" or "391.4%")
]]
local function formatSpeed(pct)
    local rounded = math.floor(pct + 0.5)
    if math.abs(pct - rounded) < ROUND_TOLERANCE then
        return string.format("%d%%", rounded)
    end
    return string.format("%.1f%%", pct)
end

-- ============================================================================
-- DISPLAY FRAME
-- ============================================================================

--[[
  Build the on-screen speed display frame.
  Anonymous frame - no global namespace pollution needed since we don't
  access it via _G or require it for UISpecialFrames.

  @return frame - The created display frame
]]
local function buildDisplayFrame()
    local frame = CreateFrame("Frame", nil, UIParent)
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
        speed_settings.point = point
        speed_settings.relPoint = relPoint
        speed_settings.xOfs = xOfs
        speed_settings.yOfs = yOfs
    end)

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER", frame, "CENTER", 0, 0)
    text:SetTextColor(1, 1, 1, 1)
    text:SetText("100%")

    speedText = text
    return frame
end

-- ============================================================================
-- LDB DATA OBJECT
-- ============================================================================

--[[
  Register the LibDataBroker data source.
  Display addons (Titan Panel, ChocolateBar, etc.) pick this up automatically
  and render the text, icon, tooltip, and click handlers in their own frames.

  @return table - The LDB data object proxy
]]
local function buildDataObject()
    local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
    return ldb:NewDataObject(ADDON_NAME, {
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
                if speedFrame:IsShown() then
                    speedFrame:Hide()
                    speed_settings.shown = false
                else
                    speedFrame:Show()
                    speed_settings.shown = true
                end
            end
        end,
    })
end

-- ============================================================================
-- UPDATE TICKER
-- ============================================================================

--[[
  Start the speed-polling ticker.
  Runs independently of frame visibility so the LDB text updates even when
  the on-screen frame is hidden.
]]
local function startTicker()
    local ticker = CreateFrame("Frame")
    local elapsedAcc = 0

    ticker:SetScript("OnUpdate", function(_, elapsed)
        elapsedAcc = elapsedAcc + elapsed
        if elapsedAcc < UPDATE_INTERVAL then return end
        elapsedAcc = 0

        local speed = GetUnitSpeed("player")
        local pct = speed / BASE_SPEED * 100
        local display = formatSpeed(pct)

        speedText:SetText(display)
        dataObject.text = "Speed: " .. display
    end)
end

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

local function handleSlash(msg)
    msg = strtrim(msg or ""):lower()

    if msg == "reset" then
        speedFrame:ClearAllPoints()
        speedFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        speed_settings.point = "CENTER"
        speed_settings.relPoint = "CENTER"
        speed_settings.xOfs = 0
        speed_settings.yOfs = 0
        print("|cff00ccffSpeed:|r Frame position reset.")

    elseif msg == "toggle" or msg == "" then
        if speedFrame:IsShown() then
            speedFrame:Hide()
            speed_settings.shown = false
            print("|cff00ccffSpeed:|r Frame hidden.")
        else
            speedFrame:Show()
            speed_settings.shown = true
            print("|cff00ccffSpeed:|r Frame shown.")
        end

    else
        print("|cff00ccffSpeed|r commands:")
        print("  /speed - Toggle display frame")
        print("  /speed reset - Reset frame position to center")
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

--[[
  Apply SavedVariable defaults with nil-coalescing.
  Preserves any existing values, only fills in missing keys.
]]
local function initSavedVariables()
    speed_settings = speed_settings or {}

    local defaults = {
        shown = true,
        point = "CENTER",
        relPoint = "CENTER",
        xOfs = 0,
        yOfs = 0,
    }

    for k, v in pairs(defaults) do
        if speed_settings[k] == nil then
            speed_settings[k] = v
        end
    end
end

--[[
  Apply persisted frame position and visibility.
  Called after the frame is built but before first show.
]]
local function restoreFrameState()
    speedFrame:ClearAllPoints()
    speedFrame:SetPoint(
        speed_settings.point,
        UIParent,
        speed_settings.relPoint,
        speed_settings.xOfs,
        speed_settings.yOfs
    )

    if speed_settings.shown then
        speedFrame:Show()
    else
        speedFrame:Hide()
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, arg1)
    if arg1 ~= ADDON_NAME then return end

    initSavedVariables()

    speedFrame = buildDisplayFrame()
    dataObject = buildDataObject()
    restoreFrameState()
    startTicker()

    self:UnregisterEvent("ADDON_LOADED")
end)

-- ============================================================================
-- SLASH COMMAND REGISTRATION
-- ============================================================================

SLASH_SPEED1 = "/speed"
SlashCmdList["SPEED"] = handleSlash
