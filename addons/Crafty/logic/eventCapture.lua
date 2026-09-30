--[[
  eventCapture - a development tool.

  Records every event the client sends while armed, and on disarm shows them in
  a window whose text is already selected, so the whole capture leaves the game
  with one Ctrl-C. Blizzard's own event log answers the same question but only
  through a screenshot, which is how several findings this addon needed arrived
  as pictures that had to be read back by eye.

  ARMED OR NOT, nothing in between. A firehose left running is a list that grows
  for the session, so this registers on arm and unregisters on disarm - and
  holds nothing at all while disarmed.

  Its own frame, not the shared event frame: disarming is UnregisterAllEvents,
  which on the shared frame would tear down every subscription in the addon.

  COMBAT_LOG_EVENT_UNFILTERED is skipped. Its arguments do not arrive through
  ... at all - Blizzard's event log special-cases it and reads
  CombatLogGetCurrentEventInfo() instead - so a line for it would carry a name
  and nothing else, at the highest event rate in the game.

  Dependencies: utils
  Exports: Addon.eventCapture
]]
local ADDON_NAME, Addon = ...
local utils
local eventCapture = {}

local lines            -- captured text, dropped when the window closes
local startedAt
local watcher
local window

-- One argument, rendered so its type survives: a string that looks like a
-- number is a different fact from a number.
local function showArg(v)
    if type(v) == "string" then return '"' .. v .. '"' end
    return tostring(v)
end

local function record(event, ...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[i] = showArg((select(i, ...)))
    end
    lines[#lines + 1] = string.format("%8.3f  %s(%s)",
        GetTime() - startedAt, event, table.concat(parts, ", "))
end

--[[
  How many events are held right now, or nil when disarmed. The menu reads this
  to say what stopping would yield.

  @return number|nil
]]
function eventCapture:count()
    return lines and #lines
end

function eventCapture:isArmed()
    return lines ~= nil
end

--[[
  The window is built on first use and reused after: it holds one capture at a
  time, and the text is dropped with the capture when it closes.
]]
local function showWindow(text)
    if not window then
        window = CreateFrame("Frame", ADDON_NAME .. "EventCapture", UIParent,
            "BackdropTemplate")
        window:SetSize(700, 500)
        window:SetPoint("CENTER")
        window:SetFrameStrata("DIALOG")
        window:SetMovable(true)
        window:EnableMouse(true)
        window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", window.StartMoving)
        window:SetScript("OnDragStop", window.StopMovingOrSizing)
        -- The game's own dialog backdrop rather than Crafty's panel look: this
        -- is a development window, not part of the addon's surface, and copying
        -- the panel's backdrop table here would make a second definition of it.
        window:SetBackdrop({
            bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })

        local title = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", 12, -10)
        title:SetText("Event capture")

        local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4)
        -- The capture dies with the window: this holds a session's events and
        -- there is no second reader.
        close:SetScript("OnClick", function()
            window:Hide()
            window.box:SetText("")
            lines = nil
        end)

        local scroll = CreateFrame("ScrollFrame", nil, window,
            "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 12, -34)
        scroll:SetPoint("BOTTOMRIGHT", -30, 12)

        local box = CreateFrame("EditBox", nil, scroll)
        box:SetMultiLine(true)
        box:SetAutoFocus(false)
        box:SetFontObject("GameFontHighlightSmall")
        box:SetWidth(650)
        -- Escape gives the text back rather than closing: this is a scratch
        -- surface, and the close button is the way out.
        box:SetScript("OnEscapePressed", box.ClearFocus)
        scroll:SetScrollChild(box)
        window.box = box
    end

    window.box:SetText(text)
    window:Show()
    -- Selected and focused, so the capture leaves with one keystroke.
    window.box:HighlightText()
    window.box:SetFocus()
end

--[[
  Start recording. Every event, from now, held in memory only.
]]
function eventCapture:arm()
    if lines then return end
    lines, startedAt = {}, GetTime()

    if not watcher then
        watcher = CreateFrame("Frame")
        watcher:SetScript("OnEvent", function(_, event, ...)
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then return end
            record(event, ...)
        end)
    end
    watcher:RegisterAllEvents()
    utils:chat("event capture armed")
end

--[[
  Stop recording and show what was caught, pre-selected for copying.
]]
function eventCapture:disarm()
    if not lines then return end
    watcher:UnregisterAllEvents()
    showWindow(table.concat(lines, "\n"))
end

function eventCapture:initialize()
    utils = Addon.utils
    return true
end

Addon.eventCapture = eventCapture

if Addon.registerModule then
    Addon.registerModule("eventCapture", { "utils" }, function()
        return eventCapture:initialize()
    end)
end
