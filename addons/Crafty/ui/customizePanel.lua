--[[
  ui/customizePanel.lua
  Customize Activities — slide-out drawer

  Opened from the rail's Customize button. A drawer that slides out FROM the rail
  (originating at the rail's right edge, where the button lives) rightward over
  the detail pane, which dims beneath it. The rail stays fully visible - it is
  what you are editing against - so this is a context-preserving side drawer, not
  a modal or a takeover. Clicking outside it, or Escape, dismisses it.

  It renders the viewed profession's display options through the shared options
  engine, bound to the per-character crafty_config store. First slice: display
  options (condense wording, class tag); the structural tuning (reorder, hide)
  will render into this same drawer next.

  Presentation chosen from UX best practice: a side drawer wins when the user
  edits in-context and needs the surrounding layout to stay oriented; a centre
  modal (the reflexive, easy-to-ship choice) is wrong here because it separates
  the user from the very thing they are arranging.

  Dependencies: optionsPanelRender (load-time global), theme, motion, utils
  Exports: Addon.customizePanel
]]

local ADDON_NAME, Addon = ...

local customizePanel = {}

-- Drawer state, built once against the host window and reused.
local drawer          -- the sliding panel frame
local dim             -- the overlay dimming the detail while open
local host            -- Crafty's main window (parent)
local railFrame       -- the rail frame (drawer's left edge anchors to its right)
local railInstance    -- the rail's api, for entering/leaving its edit mode
local detailFrame     -- the detail pane the drawer overlays
local content         -- the current options render's frame
local isOpen = false

local ANIM_SEC   = 0.18
local WIDTH_PAD  = 20    -- drawer inset around the options content

-- Per-profession display-option defaults, read/written under
-- crafty_config.display[<profID>].
local DEFAULTS = { condenseNames = false, showClassTag = false }

local function displayStore(profID)
    local cfg = crafty_config
    cfg.display = cfg.display or {}
    cfg.display[profID] = cfg.display[profID] or {}
    return cfg.display[profID]
end

local function schemaFor()
    return {
        { kind = "group", label = "Display", children = {
            { kind = "checkbox", key = "condenseNames",
              label = "Condense repetitive wording",
              tooltip = "Drop the repeated leading word from recipe names." },
            { kind = "checkbox", key = "showClassTag",
              label = "Show class on class-specific recipes",
              tooltip = "Append the class name to class-restricted recipes." },
        }},
    }
end

-- ============================================================================
-- FRAME CONSTRUCTION (once)
-- ============================================================================

local function build()
    -- The dim covers the whole workspace - everything right of the rail (the
    -- recipe list and the detail) - so the editing surface (rail + drawer) reads
    -- apart from the dimmed, passive content. It sits beneath the drawer and
    -- closes on click (click-outside-to-dismiss).
    dim = CreateFrame("Button", nil, host)
    dim:SetPoint("TOPLEFT", railFrame, "TOPRIGHT", 0, 0)
    dim:SetPoint("BOTTOMRIGHT", detailFrame, "BOTTOMRIGHT", 0, 0)
    dim:SetFrameStrata("HIGH")
    local tex = dim:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetColorTexture(0, 0, 0, 0.45)
    dim:SetScript("OnClick", function() customizePanel:close() end)
    dim:Hide()

    -- The drawer: left edge pinned to the rail's right edge, full height of the
    -- workspace, width animated open. Above the dim. Cut from the rail's
    -- material - the shared panel backdrop, coloured with SURFACE.PANEL and a
    -- warm hairline border - so it reads as the rail extending, not a foreign box.
    drawer = CreateFrame("Frame", "CraftyCustomizeDrawer", host, "BackdropTemplate")
    drawer:SetPoint("TOPLEFT", railFrame, "TOPRIGHT", 0, 0)
    drawer:SetPoint("BOTTOMLEFT", railFrame, "BOTTOMRIGHT", 0, 0)
    drawer:SetWidth(1)
    drawer:SetFrameStrata("HIGH")
    drawer:SetFrameLevel(dim:GetFrameLevel() + 10)
    local ct = Addon.theme.crafty
    drawer:SetBackdrop(ct.PANEL_BACKDROP)
    -- The drawer is part of the editing surface, so it wears the edit tint (not
    -- the passive panel fill) - it and the rail share the cool mode colour, set
    -- apart from the dimmed warm workspace.
    local ef = ct.EDIT.FILL
    drawer:SetBackdropColor(ef.r, ef.g, ef.b, ef.a)
    local eb = ct.EDIT.BORDER
    drawer:SetBackdropBorderColor(eb.r, eb.g, eb.b, eb.a)
    drawer:Hide()

    -- Title in the gold heading colour (the "this is a header" signal), matching
    -- the rail's group headings.
    local title = drawer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 12, -12)
    title:SetText("Customize Activities")
    local th = ct.TEXT.HEADING
    title:SetTextColor(th.r, th.g, th.b)
    drawer._title = title

    local close = CreateFrame("Button", nil, drawer, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)
    close:SetScript("OnClick", function() customizePanel:close() end)
end

-- ============================================================================
-- OPEN / CLOSE
-- ============================================================================

-- Render the options content into the drawer for a profession, returning the
-- target width (content + padding) the drawer should open to.
local function renderContent(profID)
    if content then content:Hide(); content = nil end
    local handle = Addon.optionsPanelRender({
        parent   = drawer,
        schema   = schemaFor(),
        sv       = displayStore(profID),
        defaults = DEFAULTS,
        width    = 360,
    })
    handle.frame:SetPoint("TOPLEFT", drawer, "TOPLEFT", WIDTH_PAD / 2, -40)
    content = handle.frame
    return handle.frame:GetWidth() + WIDTH_PAD
end

function customizePanel:toggle(profID, hostFrame, rail, detail, railApi)
    if isOpen then
        self:close()
    else
        self:open(profID, hostFrame, rail, detail, railApi)
    end
end

--[[
  Open the drawer for a profession. The composer passes its frames (host, rail
  frame, detail) and the rail instance, so the drawer anchors and can drive the
  rail's edit mode without reaching for globals.
]]
function customizePanel:open(profID, hostFrame, rail, detail, railApi)
    host, railFrame, detailFrame, railInstance = hostFrame, rail, detail, railApi
    if not drawer then build() end
    if isOpen then return end
    isOpen = true

    -- Enter edit mode: rail + drawer wear the cool tint, set apart from the
    -- dimmed workspace.
    railInstance:setEditMode(true)

    local targetW = renderContent(profID)

    dim:Show()
    drawer:SetWidth(1)
    drawer:Show()
    -- Slide open: motion:run steps with elapsed time; tween width 1 -> target.
    Addon.motion:run(drawer, function(elapsed)
        local u = math.min(elapsed / ANIM_SEC, 1)
        drawer:SetWidth(1 + (targetW - 1) * u)
        return u >= 1
    end)
end

function customizePanel:close()
    if not isOpen then return end
    isOpen = false
    -- Leave edit mode: the rail returns to its passive fill.
    railInstance:setEditMode(false)
    local startW = drawer:GetWidth()
    Addon.motion:run(drawer, function(elapsed)
        local u = math.min(elapsed / ANIM_SEC, 1)
        drawer:SetWidth(startW * (1 - u))
        if u >= 1 then
            drawer:Hide()
            dim:Hide()
            return true
        end
        return false
    end)
end

function customizePanel:initialize()
    return true
end

if Addon.registerModule then
    Addon.registerModule("customizePanel", {"theme", "motion"},
        function() return customizePanel:initialize() end)
end

Addon.customizePanel = customizePanel
return customizePanel
