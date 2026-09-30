--[[
  ui/shared/optionsPanel/render.lua
  Options Panel Renderer

  Turns a normalized schema into a live panel of controls bound to a caller SV.
  Four-phase lifecycle: Normalize (done before render) -> Render (build frame +
  controls) -> Refresh (push SV values in, suppressed; apply predicates) ->
  Teardown.

  The renderer speaks ONE language to every control (the common widget contract:
  parent/label/value/onChange config in, GetValue/SetValue(value, suppress)/
  SetEnabled/SetShown surface out). No adapter, no per-widget translation.

  Visual styling goes through the theme system (Addon.theme): the panel backdrop
  is skinned via theme.style:skinPanel and text colours come from
  theme.tokens.TEXT.*. This is what lets the panel inherit ElvUI (or any active
  style) instead of hardcoded paint. Spacing comes from the 8pt scale.

  Sizing: width is caller-driven (opts.width, defaulting when omitted); height is
  content-driven -- the panel measures its laid-out controls and sizes itself to
  fit. The consumer owns any host WINDOW sizing (it can read frame:GetHeight()).

  Public:
    render(opts) -> handle
      opts = { parent, schema, sv, defaults, title?, width? }
    handle:Refresh() / handle:SyncValues() / handle:Show() / handle:Hide()
    handle.frame

  Dependencies: normalize, confirmModal, theme, and the control widgets
                (labeledToggle, slider, dropdown, textBox)
  Exports: Addon.optionsPanelRender
]]

local ADDON_NAME, Addon = ...

-- ============================================================================
-- SPACING (8pt grid scale -- no arbitrary numbers)
-- ============================================================================

local SPACE = {
    TINY   = 4,
    SMALL  = 8,
    MEDIUM = 12,
    BASE   = 16,
    LARGE  = 24,
}

local EDGE            = SPACE.LARGE             -- content padding from edge (24)
local ROW_GAP         = SPACE.MEDIUM           -- gap after a control row (12)
local GROUP_GAP_ABOVE = SPACE.LARGE            -- space above a group header (24)
local GROUP_GAP_BELOW = SPACE.SMALL            -- header to first child (8)
local INDENT          = SPACE.BASE             -- child indent under a group (16)
local TITLE_BAND      = SPACE.LARGE + SPACE.SMALL  -- title row height (32)

local KIND_HEIGHT = {
    checkbox       = SPACE.LARGE,                 -- 24
    slider         = SPACE.LARGE + SPACE.LARGE,   -- 48
    dropdown       = SPACE.LARGE + SPACE.BASE,    -- 40
    dropdownLegacy = SPACE.LARGE + SPACE.BASE,    -- 40
    text           = SPACE.LARGE + SPACE.BASE,    -- 40
    search         = SPACE.LARGE + SPACE.BASE,    -- 40
    segmented      = SPACE.LARGE + SPACE.BASE,    -- 40
    radio          = SPACE.LARGE + SPACE.LARGE + SPACE.BASE,  -- 64 (multi-row)
}
local GROUP_HEADER_H = SPACE.LARGE              -- 24
local ACTION_H       = SPACE.LARGE + SPACE.TINY -- 28

local DEFAULT_WIDTH = 380  -- the panel width when the caller specifies none

local KIND_WIDGET = {
    checkbox       = "labeledToggle",
    slider         = "slider",
    dropdown       = "dropdown",
    dropdownLegacy = "dropdownLegacy",
    text           = "textBox",
    search         = "searchBox",
    segmented      = "segmentedControl",
    radio          = "radioControl",
}

-- Kinds whose widget draws its own caption from `label`. For kinds NOT listed
-- here (textBox, searchBox), the renderer draws the caption itself. checkbox is
-- self-captioning too (labeledToggle includes its label inline to the right).
local SELF_CAPTION = {
    checkbox       = true,
    slider         = true,
    dropdown       = true,
    dropdownLegacy = true,
    segmented      = true,
    radio          = true,
}

-- ============================================================================
-- THEME HELPERS
-- ============================================================================

local function applyTextColor(fontString, token)
    if token then
        fontString:SetTextColor(token.r, token.g, token.b)
    else
        fontString:SetTextColor(1, 0.82, 0)
    end
end

local function textToken(name)
    return Addon.theme.tokens.TEXT[name]
end

-- ============================================================================
-- CONFIG BUILDER
-- ============================================================================

local function controlConfig(node, parent, onEdit)
    local cfg = {
        parent   = parent,
        label    = node.label,
        value    = node.get(),
        tooltip  = node.tooltip,
        onChange = function(v) onEdit(v) end,
    }
    if node.kind == "slider" then
        cfg.min, cfg.max, cfg.step = node.min, node.max, node.step
    elseif node.kind == "dropdown" or node.kind == "dropdownLegacy"
        or node.kind == "segmented" or node.kind == "radio" then
        cfg.choices = node.choices
    elseif node.kind == "text" or node.kind == "search" then
        cfg.numeric = node.numeric
    end
    return cfg
end

-- ============================================================================
-- PANEL FRAME
-- ============================================================================

local Render = {}

-- Build the content frame the controls render into. This is NOT a window: no
-- title bar, close button, escape handling, or drag. Those are window chrome,
-- owned by the consumer that creates the window and places this frame in it.
-- The renderer's job is render(schema -> frame); the frame holds controls.
-- Width is caller-driven (opts.width) so the panel fits any host, from a
-- narrow embedded pane to a wide standalone dialog; height is content-driven.
local function buildPanelFrame(parent, width)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(width, 100)
    -- Backdrop through the active theme style, so the panel inherits Blizzard /
    -- ElvUI / any registered look rather than painting itself. The theme is a
    -- core system present in every consumer, so it is used directly.
    Addon.theme.style:skinPanel(frame)
    return frame
end

-- ============================================================================
-- TREE WALK
-- ============================================================================

local function renderNodes(nodes, parent, live, startY, indent, width, onPredicates, onStoreChanged)
    local y = startY
    for _, node in ipairs(nodes) do
        if node.kind == "group" then
            y = y - GROUP_GAP_ABOVE
            local hdr = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            hdr:SetPoint("TOPLEFT", EDGE + indent, y)
            hdr:SetText(node.label or "")
            applyTextColor(hdr, textToken("EMPHASIS_SOFT"))
            y = y - GROUP_HEADER_H - GROUP_GAP_BELOW
            y = renderNodes(node.children, parent, live, y, indent + INDENT, width, onPredicates, onStoreChanged)

        elseif node.kind == "action" then
            local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
            btn:SetSize(width - (EDGE * 2) - indent, ACTION_H)
            btn:SetPoint("TOPLEFT", EDGE + indent, y)
            btn:SetText(node.label or "Action")
            local runIt, confirm = node.run, node.confirm
            btn:SetScript("OnClick", function()
                if confirm then
                    Addon.optionsPanelConfirm({
                        title = confirm.title, body = confirm.body,
                        confirmText = confirm.confirmText,
                        onConfirm = function()
                            if runIt then runIt() end
                            if onStoreChanged then onStoreChanged() end
                        end,
                    })
                else
                    if runIt then runIt() end
                    if onStoreChanged then onStoreChanged() end
                end
            end)
            y = y - ACTION_H - ROW_GAP

        else
            local thisNode = node
            local onEdit = function(value)
                thisNode.set(value)
                -- Predicates only. The edited control already holds this value
                -- (it is where the value came from), and no other control's value
                -- depends on it -- only their visible/disabled predicates might.
                if onPredicates then onPredicates() end
            end
            local widgetName = KIND_WIDGET[node.kind]
            local widget = widgetName and Addon[widgetName]
            if widget then
                -- Some widgets self-caption from their `label` (slider, dropdown,
                -- dropdownLegacy, segmented, radio). textBox/searchBox do not, so
                -- the renderer draws the caption for those kinds and offsets the
                -- control below it.
                local labelOffset = 0
                if not SELF_CAPTION[node.kind] and node.label and node.label ~= "" then
                    local cap = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    cap:SetPoint("TOPLEFT", EDGE + indent, y)
                    cap:SetText(node.label)
                    applyTextColor(cap, textToken("PRIMARY"))
                    labelOffset = SPACE.BASE
                end

                local control = widget:create(controlConfig(node, parent, onEdit))
                local cframe = control.frame or control
                cframe:SetPoint("TOPLEFT", EDGE + indent, y - labelOffset)
                live[#live + 1] = { resolved = node, control = control }

                -- Optional infoTip: a (i) help icon placed after the control,
                -- shown when the descriptor carries rich `info`. Anchor to the
                -- right of the control's own label when it has one anchored to the
                -- side (e.g. a checkbox, whose `frame` is just the small box and
                -- whose label sits to its right) -- otherwise anchoring to the
                -- frame's right edge drops the icon on top of the label.
                if node.info and Addon.infoTip then
                    local tip = Addon.infoTip:create(parent, node.info)
                    if tip then
                        local anchorTo = (control.label and control.label.GetRight)
                            and control.label or cframe
                        tip:SetPoint("LEFT", anchorTo, "RIGHT", SPACE.SMALL, 0)
                    end
                end

                local measured = cframe.GetHeight and cframe:GetHeight()
                local h = (measured and measured > 0) and measured
                          or (KIND_HEIGHT[node.kind] or SPACE.LARGE)
                y = y - h - labelOffset - ROW_GAP
            else
                local stub = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
                stub:SetPoint("TOPLEFT", EDGE + indent, y)
                stub:SetText("[" .. tostring(node.kind) .. ": unsupported]")
                y = y - SPACE.LARGE - ROW_GAP
            end
        end
    end
    return y
end

-- ============================================================================
-- PUBLIC: render
-- ============================================================================

function Render.render(opts)
    assert(opts and opts.parent, "render requires opts.parent")
    assert(opts.schema, "render requires opts.schema")
    assert(opts.sv, "render requires opts.sv (the SavedVariable table)")
    assert(opts.defaults, "render requires opts.defaults (caller-supplied)")

    local ctx = { sv = opts.sv, defaults = opts.defaults }

    local N = Addon.optionsPanelNormalize
    local result = N.normalize(opts.schema, ctx)
    if not result.ok then
        error("optionsPanel: schema invalid:\n" .. table.concat(result.errors, "\n"))
    end

    local width = opts.width or DEFAULT_WIDTH
    local frame = buildPanelFrame(opts.parent, width)
    local startY = -EDGE

    local live = {}
    local handle
    -- An edit re-evaluates predicates only. It does NOT push values into
    -- controls: each control received its value at construction (in its config)
    -- and owns it thereafter; the store and the control are already in sync
    -- because the control is where the value came from. The only thing an edit
    -- can change for OTHER controls is whether their visible/disabled predicate
    -- now resolves differently (e.g. a child shown only when a master is on).
    local function applyPredicates()
        for _, entry in ipairs(live) do
            local r, c = entry.resolved, entry.control
            if c.SetShown then c:SetShown(r.visible() and true or false) end
            if c.SetEnabled then c:SetEnabled(not (r.disabled() and true or false)) end
        end
    end
    local function onStoreChanged() if handle then handle:SyncValues() end end
    local endY = renderNodes(result.tree, frame, live, startY, 0, width, applyPredicates, onStoreChanged)

    -- Content-driven sizing: size the content frame to fit its laid-out controls
    -- plus bottom padding, so nothing overflows. The consumer owns the window
    -- size; if it wants to fit this content it can read frame:GetHeight().
    local contentHeight = (-endY) + EDGE
    frame:SetSize(width, contentHeight)

    handle = { frame = frame, _live = live }

    -- Re-apply predicates (visible/disabled). Exposed so a consumer can call it
    -- after changing the store out-of-band. It never pushes values, so it cannot
    -- clobber in-progress input.
    function handle:Refresh()
        applyPredicates()
    end

    -- Re-pull every control's value from the store. For OUT-OF-BAND store
    -- changes only -- e.g. a Reset that wipes the SV, after which controls must
    -- re-display their (now default) values. NOT called on per-edit refresh: a
    -- normal edit leaves the store and the control already in sync. Suppressed so
    -- the push never echoes as a user edit.
    function handle:SyncValues()
        for _, entry in ipairs(self._live) do
            local r, c = entry.resolved, entry.control
            if c.SetValue then c:SetValue(r.get(), true) end
        end
        applyPredicates()
    end

    function handle:Show() self.frame:Show(); applyPredicates() end
    function handle:Hide() self.frame:Hide() end

    -- Apply predicates once for the initial visible/disabled state. (Values are
    -- already set: each control was constructed with its value.)
    applyPredicates()

    return handle
end

Addon.optionsPanelRender = Render.render
return Render
