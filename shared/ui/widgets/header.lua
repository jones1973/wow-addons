--[[
  ui/shared/header.lua
  Column Header Widget

  Reusable column header for tabular UIs. Supports:
    - Click-to-sort with up/down arrow indicator
    - Click-the-gear-to-filter with popup textbox
    - Active-filter dot indicator before the label
    - Hover highlight
    - Style-driven appearance (default BASIC; callers can extend/override)

  Behavior is configured per-header; appearance is configured via a
  separate `style` object so the same widget can render different
  looks across addons.

  ============================================================================
  Usage:
    local h = Addon.header:create({
        parent      = headerFrame,
        columnKey   = "lvl",            -- unique id; appears in event payloads
        label       = "Lvl",
        width       = 92,
        height      = 24,

        sortable    = true,
        preSort     = function(currentDir)
                          return true     -- (allow [, forcedDir])
                      end,

        filterable     = true,
        filterValue    = function() return options:Get("levelCap") end,
        filterCommit   = function(v) options:Set("levelCap", v) end,
        isFilterActive = function(v) return v and v > 1 end,
        popup = {
            kind        = "number",
            placeholder = "Level cap",
            min = 1, max = 100,
        },

        style = Addon.header.styles.BASIC,   -- optional; defaults to BASIC
    })

  ============================================================================
  Events:
    HEADER:SORT_CHANGED   { columnKey, direction }
    HEADER:FILTER_CHANGED { columnKey, value }

  Subscribers filter by `columnKey` to handle their own headers.

  ============================================================================
  Dependencies: utils, events, textBox
  Exports: Addon.header
]]

local ADDON_NAME, Addon = ...

local header = {}

-- ============================================================================
-- STYLE
-- ============================================================================

--[[
  A style object describes the visual appearance of a header. All fields
  are required when defining a new style; the BASIC style below is the
  reference structure.

  Callers can use BASIC directly, or build their own by deep-merging
  via header.extend(BASIC, overrides).
]]
header.styles = {}

header.styles.BASIC = {
    background = {
        -- Solid color fill. For texture-based backgrounds, callers can
        -- override with { texture = path, leftWidth, rightWidth, texCoords }.
        bgColor    = {0.1, 0.1, 0.1, 0.9},
    },
    highlight = {
        -- Hover overlay. Color-tint or texture-file based.
        color     = {1, 1, 1, 0.15},
        blendMode = "ADD",
    },
    font           = "GameFontHighlight",
    textInsetLeft  = 6,
    arrow = {
        up   = "Interface\\Buttons\\Arrow-Up-Up",
        down = "Interface\\Buttons\\Arrow-Down-Up",
        size = { 8, 8 },
        color = nil,    -- nil = no vertex tint
    },
    gear = {
        file       = "Interface\\Worldmap\\Gear_64Grey",
        sizeOffset = -4,    -- gear size = header height + sizeOffset
        color      = {0.85, 0.85, 0.85, 1},
        hoverColor = {1, 1, 1, 1},
    },
    activeFilterDot = string.char(226, 128, 162) .. " ",   -- "• " (UTF-8 bullet)
    popup = {
        bgColor      = {0.05, 0.05, 0.05, 0.95},
        borderColor  = {0.4, 0.4, 0.4, 1},
        borderSize   = 1,
        padding      = 24,
        width        = 240,
    },
}

--[[
  Shallow-merge two style tables, with `overrides` winning. Sub-tables
  (background, highlight, arrow, gear, popup) are themselves merged
  shallowly: caller's nested keys overlay base nested keys.

  @param base table   - reference style (typically a header.styles.X)
  @param overrides table - caller's customizations
  @return new style table
]]
function header.extend(base, overrides)
    if not overrides then return base end
    local merged = {}
    for k, v in pairs(base) do
        if type(v) == "table" then
            merged[k] = {}
            for sk, sv in pairs(v) do merged[k][sk] = sv end
        else
            merged[k] = v
        end
    end
    for k, v in pairs(overrides) do
        if type(v) == "table" and type(merged[k]) == "table" then
            for sk, sv in pairs(v) do merged[k][sk] = sv end
        else
            merged[k] = v
        end
    end
    return merged
end

-- ============================================================================
-- BUILDERS
-- ============================================================================

--[[
  Build the parchment/textured background for a header.

  Two cases:
    1. style.background.bgColor only: solid backdrop fill.
    2. style.background.texture set: 3-slice texture (left + middle + right)
       with explicit pixel widths and texCoords. Used for AH-tab parchment
       look. Caller's style is responsible for providing all of:
         texture, leftWidth, rightWidth, texCoords.left/middle/right
]]
local function buildBackground(btn, style)
    local bg = style.background
    if bg.texture then
        local left = btn:CreateTexture(nil, "BACKGROUND")
        left:SetTexture(bg.texture)
        left:SetSize(bg.leftWidth, btn:GetHeight())
        left:SetPoint("TOPLEFT")
        if bg.texCoords and bg.texCoords.left then
            left:SetTexCoord(unpack(bg.texCoords.left))
        end

        local right = btn:CreateTexture(nil, "BACKGROUND")
        right:SetTexture(bg.texture)
        right:SetSize(bg.rightWidth, btn:GetHeight())
        right:SetPoint("TOPRIGHT")
        if bg.texCoords and bg.texCoords.right then
            right:SetTexCoord(unpack(bg.texCoords.right))
        end

        local middle = btn:CreateTexture(nil, "BACKGROUND")
        middle:SetTexture(bg.texture)
        middle:SetPoint("LEFT", left, "RIGHT")
        middle:SetPoint("RIGHT", right, "LEFT")
        middle:SetHeight(btn:GetHeight())
        if bg.texCoords and bg.texCoords.middle then
            middle:SetTexCoord(unpack(bg.texCoords.middle))
        end
        btn._bgLeft, btn._bgMiddle, btn._bgRight = left, middle, right
    elseif bg.bgColor then
        local fill = btn:CreateTexture(nil, "BACKGROUND")
        fill:SetColorTexture(unpack(bg.bgColor))
        fill:SetAllPoints(btn)
        btn._bgFill = fill
    end
end

local function buildHighlight(btn, style)
    local hl = style.highlight
    if not hl then return end
    local tex = btn:CreateTexture(nil, "HIGHLIGHT")
    if hl.file then
        tex:SetTexture(hl.file)
    elseif hl.color then
        tex:SetColorTexture(unpack(hl.color))
    end
    if hl.blendMode then tex:SetBlendMode(hl.blendMode) end
    tex:SetAllPoints(btn)
end

local function buildLabel(btn, label, style)
    local fs = btn:CreateFontString(nil, "ARTWORK", style.font)
    fs:SetPoint("LEFT", btn, "LEFT", style.textInsetLeft, 0)
    fs:SetJustifyH("LEFT")
    fs:SetJustifyV("MIDDLE")
    fs:SetText(label)
    btn._labelFs = fs
    btn._labelText = label
    return fs
end

local function buildArrow(btn, style, anchorTo, anchorOffset)
    local arrow = btn:CreateTexture(nil, "OVERLAY")
    arrow:SetTexture(style.arrow.up)    -- placeholder; updated on direction change
    arrow:SetSize(unpack(style.arrow.size))
    arrow:SetPoint("LEFT", anchorTo, "RIGHT", anchorOffset or 3, -1)
    if style.arrow.color then
        arrow:SetVertexColor(unpack(style.arrow.color))
    end
    arrow:Hide()
    btn._arrow = arrow
    return arrow
end

local function buildGear(btn, style)
    local h = btn:GetHeight()
    local gearSize = h + style.gear.sizeOffset
    local gearBtn = CreateFrame("Button", nil, btn)
    gearBtn:SetSize(gearSize, gearSize)
    gearBtn:SetPoint("RIGHT", btn, "RIGHT", -2, 0)
    gearBtn:SetFrameLevel(btn:GetFrameLevel() + 2)

    local tex = gearBtn:CreateTexture(nil, "OVERLAY")
    tex:SetTexture(style.gear.file)
    tex:SetAllPoints(gearBtn)
    tex:SetVertexColor(unpack(style.gear.color))
    gearBtn._tex = tex

    -- Same hover treatment as the parent header so the gear visually
    -- behaves as part of the header band.
    if style.highlight then
        local hl = gearBtn:CreateTexture(nil, "HIGHLIGHT")
        if style.highlight.file then
            hl:SetTexture(style.highlight.file)
        elseif style.highlight.color then
            hl:SetColorTexture(unpack(style.highlight.color))
        end
        if style.highlight.blendMode then hl:SetBlendMode(style.highlight.blendMode) end
        hl:SetAllPoints(gearBtn)
    end

    gearBtn:SetScript("OnEnter", function(self)
        self._tex:SetVertexColor(unpack(style.gear.hoverColor))
    end)
    gearBtn:SetScript("OnLeave", function(self)
        self._tex:SetVertexColor(unpack(style.gear.color))
    end)

    return gearBtn
end

-- ============================================================================
-- POPUP (filter dialog)
-- ============================================================================

--[[
  Build the filter popup. Hidden until the gear is clicked.

  Layout (top-down): title text, textbox, Done button. Visual character
  matches Browse's "Sort Prices By" popup -- bordered frame, padding
  around content, explicit commit button.

  @param parentBtn  - the gear button (popup anchors to its BOTTOMRIGHT)
  @param popupCfg   - { kind, title, placeholder, min?, max? }
  @param style      - the style object
  @param onCommit   - function(value) called on successful commit
]]
local function buildPopup(parentBtn, popupCfg, style, onCommit)
    local pStyle = style.popup
    local PAD    = pStyle.padding or 12
    local W      = pStyle.width or 200
    local TITLE_H, HELPER_H, BOX_H, BTN_H, GAP, HELPER_GAP = 16, 14, 24, 24, 8, 16
    local hasHelper = popupCfg.helper and popupCfg.helper ~= ""
    local totalH = PAD + TITLE_H
                 + (hasHelper and (4 + HELPER_H) or 0)
                 + HELPER_GAP + BOX_H + GAP + BTN_H + PAD

    local frame = CreateFrame("Frame", nil, parentBtn, "BackdropTemplate")
    frame:SetSize(W, totalH)
    frame:SetPoint("TOPRIGHT", parentBtn, "BOTTOMRIGHT", 0, -4)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileEdge = true,
        tileSize = 32,
        edgeSize = 32,
        insets   = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    frame:SetBackdropColor(1, 1, 1, 1)
    frame:SetBackdropBorderColor(1, 1, 1, 1)

    -- Inner dark card: 70% black rectangle inset 10px from edges, gives
    -- the popup interior the dark look behind content while preserving
    -- the parchment-stone border. Matches Blizzard's BrowsePriceOptionsFrame.
    local innerBg = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
    innerBg:SetColorTexture(0, 0, 0, 0.7)
    innerBg:SetPoint("TOPLEFT", 10, -10)
    innerBg:SetPoint("BOTTOMRIGHT", -10, 10)

    frame:Hide()

    -- Title text, left-aligned (matches stock BrowsePriceOptionsFrame)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -PAD)
    title:SetJustifyH("LEFT")
    title:SetText(popupCfg.title or popupCfg.placeholder or "Filter")

    -- Optional helper text below the title, left-aligned
    local helper
    if hasHelper then
        helper = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        helper:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
        helper:SetWidth(W - (PAD * 2))
        helper:SetJustifyH("LEFT")
        helper:SetText(popupCfg.helper)
    end

    -- Done button (anchored at bottom; we'll wire its OnClick after
    -- creating the textbox so the button can read the textbox's value).
    local doneBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    doneBtn:SetSize(110, BTN_H)
    doneBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, PAD)
    doneBtn:SetText("Done")

    -- Commit logic. Reads textbox, clamps if numeric, fires onCommit, closes.
    local box
    local function commit()
        if not box then return end
        local text = box:GetText() or ""
        local value
        if popupCfg.kind == "number" then
            value = tonumber(text)
            if value then
                if popupCfg.min and value < popupCfg.min then value = popupCfg.min end
                if popupCfg.max and value > popupCfg.max then value = popupCfg.max end
            end
        else
            value = text
        end
        if onCommit then onCommit(value) end
        frame:Hide()
    end
    doneBtn:SetScript("OnClick", commit)

    if Addon.textBox and Addon.textBox.create then
        local isNumeric = popupCfg.kind == "number"
        local boxWidth = isNumeric and 80 or (W - (PAD * 2))
        box = Addon.textBox:create({
            parent          = frame,
            width           = boxWidth,
            height          = BOX_H,
            placeholder     = popupCfg.placeholder or "",
            numeric         = isNumeric,
            onEnterPressed  = commit,
            onEscapePressed = function() frame:Hide() end,
        })
        box:SetPoint("TOP", helper or title, "BOTTOM", 0, -HELPER_GAP)
        if isNumeric then box:SetJustifyH("RIGHT") end
    end

    frame._box = box
    return frame
end

-- ============================================================================
-- HEADER INSTANCE
-- ============================================================================

-- Forward-declare so :create can attach this as the metatable index
-- before invoking instance methods. Method definitions follow below.
header._instanceMethods = {}

-- Registry of widget instances by group name. Headers in the same
-- group close each other's popups when one opens (so only one popup
-- in a group is visible at a time). Group membership is opt-in via
-- config.group; widgets without a group don't participate.
header._groups = {}

local function registerGroup(instance, groupName)
    if not groupName then return end
    header._groups[groupName] = header._groups[groupName] or {}
    table.insert(header._groups[groupName], instance)
end

local function closeSiblingsInGroup(groupName, exceptInstance)
    if not groupName then return end
    local list = header._groups[groupName]
    if not list then return end
    for _, sibling in ipairs(list) do
        if sibling ~= exceptInstance and sibling._popup and sibling._popup:IsShown() then
            sibling._popup:Hide()
        end
    end
end

--[[
  Close all popups belonging to a group. Useful for tab-switch / hide
  scenarios where the caller wants every header in a logical group to
  reset its popup visibility.
]]
function header:closeAllInGroup(groupName)
    closeSiblingsInGroup(groupName, nil)
end

--[[
  Create a header. Returns an instance with public methods.

  @param config table (see file header for full shape)
  @return header instance
]]
function header:create(config)
    local style = config.style or self.styles.BASIC

    local btn = CreateFrame("Button", nil, config.parent)
    btn:SetSize(config.width, config.height)

    buildBackground(btn, style)
    buildHighlight(btn, style)
    local labelFs = buildLabel(btn, config.label, style)

    local instance = {
        _btn       = btn,
        _config    = config,
        _style     = style,
        _direction = nil,    -- "asc" | "desc" | nil
    }

    -- ARROW (sortable only)
    if config.sortable then
        buildArrow(btn, style, labelFs, 3)
        btn:SetScript("OnClick", function()
            local current = instance._direction
            local newDir
            if current == "asc" then newDir = "desc"
            elseif current == "desc" then newDir = "asc"
            else newDir = "asc"
            end

            -- preSort can veto or coerce
            if config.preSort then
                local allow, forced = config.preSort(current)
                if not allow then return end
                if forced then newDir = forced end
            end

            instance._direction = newDir
            instance:_repaintArrow()

            if Addon.events and Addon.events.emit then
                Addon.events:emit("HEADER:SORT_CHANGED", {
                    columnKey = config.columnKey,
                    direction = newDir,
                })
            end
        end)
    end

    -- GEAR + POPUP (filterable only)
    if config.filterable then
        local gearBtn = buildGear(btn, style)
        local popup
        gearBtn:SetScript("OnClick", function()
            -- preFilter can veto
            if config.preFilter then
                local allow = config.preFilter()
                if not allow then return end
            end
            if not popup then
                popup = buildPopup(gearBtn, config.popup or {}, style, function(value)
                    if config.filterCommit then config.filterCommit(value) end
                    instance:redrawIndicator()
                    if Addon.events and Addon.events.emit then
                        Addon.events:emit("HEADER:FILTER_CHANGED", {
                            columnKey = config.columnKey,
                            value     = value,
                        })
                    end
                end)
                instance._popup = popup
            end
            if popup:IsShown() then
                popup:Hide()
            else
                -- Close any sibling popups in our group first, so only
                -- one popup in the group is visible at a time.
                closeSiblingsInGroup(config.group, instance)

                -- Pre-populate with current value
                if popup._box and config.filterValue then
                    local cur = config.filterValue()
                    popup._box:SetText(cur and tostring(cur) or "")
                end
                popup:Show()
                if popup._box and popup._box.SetFocus then
                    popup._box:SetFocus()
                end
            end
        end)
        instance._gearBtn = gearBtn
    end

    -- Attach methods before invoking any of them on the instance.
    setmetatable(instance, { __index = header._instanceMethods })

    -- Register for group-based popup mutual exclusion (if config.group set).
    registerGroup(instance, config.group)

    -- Initial dot indicator
    instance:redrawIndicator()

    return instance
end

-- ============================================================================
-- INSTANCE METHODS
-- ============================================================================

function header._instanceMethods:_repaintArrow()
    local arrow = self._btn._arrow
    if not arrow then return end
    if self._direction == "asc" then
        arrow:SetTexture(self._style.arrow.up)
        arrow:Show()
    elseif self._direction == "desc" then
        arrow:SetTexture(self._style.arrow.down)
        arrow:Show()
    else
        arrow:Hide()
    end
end

--[[
  Set the active sort direction without firing the event. Used when
  panel layout changes externally (e.g., initial render, programmatic
  sort). Pass nil to clear.
]]
function header._instanceMethods:setActiveSort(direction)
    self._direction = direction
    self:_repaintArrow()
end

--[[
  Re-evaluate isFilterActive(filterValue()) and update the dot prefix.
  Called automatically on filter commit. Callers invoke this when the
  filter value changes outside the popup (e.g., reset).
]]
function header._instanceMethods:redrawIndicator()
    local fs = self._btn._labelFs
    if not fs then return end
    local active = false
    if self._config.isFilterActive and self._config.filterValue then
        active = self._config.isFilterActive(self._config.filterValue())
    end
    local prefix = active and (self._style.activeFilterDot or "") or ""
    fs:SetText(prefix .. (self._btn._labelText or self._config.label or ""))
end

function header._instanceMethods:setLabel(text)
    self._btn._labelText = text
    self:redrawIndicator()
end

function header._instanceMethods:getFrame()
    return self._btn
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("header", { "utils", "events", "textBox" }, function()
        return true
    end)
end

Addon.header = header
return header
