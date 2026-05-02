--[[
  ui/shared/filterTabStrip.lua
  Filter Tab Strip Factory

  A data-driven strip of tabs that filter a list view. Caller provides the
  tab list; the widget renders buttons, handles clicks, and fires a
  callback on selection.

  Supports two orientations:
    "horizontal" - tabs laid out left-to-right. Each tab's width auto-sizes
                   to its own content. Caller controls LEFT/RIGHT anchors;
                   widget controls its own height.
    "vertical"   - tabs laid out top-to-bottom. Strip width is fixed at the
                   caller-supplied `width` config; tabs all use that width.
                   Caller picks `width` to fit the widest expected label
                   plus pill content. Caller controls TOP/BOTTOM anchors;
                   widget controls its own width. When tab content exceeds
                   the strip's height, the widget shows up/down scroll
                   buttons (overlaid at top/bottom) and supports mousewheel
                   scrolling. Tabs outside the visible window are hidden.
                   :select() auto-scrolls the picked tab into view.

  This is NOT the same thing as core/tabs.lua. core/tabs.lua is the
  top-level multi-window tab system (static registrations, lazy content-
  frame creation per tab, SV-persisted enable states). This widget is for
  in-panel filter tabs: dynamic, session-only, all tabs render into the
  same content area.
    - core/tabs.lua        -> "Pets | Leaderboard | Settings" window tabs
    - filterTabStrip.lua   -> "Head | Neck | Chest | ..." list-filter tabs

  Horizontal usage:
    local strip = Addon.filterTabStrip:create({
        parent      = parentFrame,
        orientation = "horizontal",     -- default
        tabHeight   = 22,               -- optional
        spacing     = 2,                -- optional
        onSelect    = function(id) end,
    })
    strip:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    strip:SetPoint("RIGHT",   parent, "RIGHT",   0, 0)
    -- widget sets its own height based on tabHeight

  Vertical usage:
    local strip = Addon.filterTabStrip:create({
        parent      = parentFrame,
        orientation = "vertical",
        width       = 209,              -- required for vertical
        tabHeight   = 22,
        spacing     = 2,
        onSelect    = function(id) end,
    })
    strip:SetPoint("TOPLEFT",    parent, "TOPLEFT",    0, 0)
    strip:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    -- widget sets its own width to config.width

  Common API:
    strip:setTabs({
        { id = "head",  label = "Head",  count = 3,
          extraText = "+45%", extraColor = {1, 0.5, 0} },
        { id = "neck",  label = "Neck",  count = 1 },
        ...
    })
    strip:select("head")        -- or strip:selectFirst()
    strip:getSelected()         -- current tab id, or nil
    strip:hasTab("head")        -- does the current tab list include this id
    strip:getTabCount()

  Tab config fields:
    id         (required) - unique string identifier
    label      (required) - display text for the tab
    count      (optional) - integer, appended as "(N)" after the label
    extraText  (optional) - trailing text like "+45%"
    extraColor (optional) - {r, g, b} for extraText; defaults to white
    tooltip    (optional) - hover tooltip. Either a plain string (single
                            white line), or an array of line entries.
                            Each line entry is either a bare string or
                            {text, r, g, b} where color is optional. Use
                            the array form for multi-line tooltips.

  Dependencies: None (standalone factory)
  Exports: Addon.filterTabStrip
]]

local ADDON_NAME, Addon = ...

local filterTabStrip = {}

-- ============================================================================
-- STYLING CONSTANTS
-- ============================================================================

local DEFAULTS = {
    orientation = "horizontal",
    tabHeight   = 22,
    spacing     = 2,

    -- Horizontal padding inside each tab button
    padX = 10,
    -- Gap between label text and optional extraText
    gapExtra = 6,

    -- Fonts
    labelFont = "GameFontNormal",
    extraFont = "GameFontHighlightSmall",

    -- Backdrop: matches textBox.lua visual language
    backdrop = {
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    },

    -- Colors for unselected vs selected tab
    unselectedBg     = { 0.08, 0.08, 0.08, 0.85 },
    unselectedBorder = { 0.35, 0.35, 0.35, 1 },
    unselectedLabel  = { 0.82, 0.82, 0.82, 1 },

    selectedBg     = { 0.18, 0.16, 0.08, 0.95 },
    selectedBorder = { 1.00, 0.84, 0.00, 1 },      -- gold
    selectedLabel  = { 1.00, 1.00, 1.00, 1 },
}

-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

--[[
  Update a tab button's text and colors for its current config + selection.
  Does NOT set the button's width; callers do that (horizontal: per-tab
  natural width; vertical: uniform width). Returns the natural width the
  tab would need if auto-sized.
  @param btn Button
  @param config table - tab config
  @param selected boolean
  @param style table
  @return number - natural width in pixels
]]
local function renderTabContent(btn, config, selected, style)
    -- Create fontstrings lazily on first render
    if not btn.labelText then
        btn.labelText = btn:CreateFontString(nil, "OVERLAY", style.labelFont)
        btn.labelText:SetPoint("LEFT", btn, "LEFT", style.padX, 0)
        btn.labelText:SetJustifyV("MIDDLE")
    end
    if not btn.extraTextFS then
        btn.extraTextFS = btn:CreateFontString(nil, "OVERLAY", style.extraFont)
        btn.extraTextFS:SetJustifyV("MIDDLE")
    end

    -- Label: "Head" or "Head (3)"
    local labelStr = config.label or "?"
    if config.count and config.count > 0 then
        labelStr = labelStr .. string.format(" (%d)", config.count)
    end
    btn.labelText:SetText(labelStr)

    local c = selected and style.selectedLabel or style.unselectedLabel
    btn.labelText:SetTextColor(c[1], c[2], c[3], c[4])

    -- Extra (pill) text, anchored to the right of the label
    local extraW = 0
    if config.extraText and config.extraText ~= "" then
        btn.extraTextFS:SetText(config.extraText)
        local ec = config.extraColor
        if ec then
            btn.extraTextFS:SetTextColor(ec[1], ec[2], ec[3], ec[4] or 1)
        else
            btn.extraTextFS:SetTextColor(1, 1, 1, 1)
        end
        btn.extraTextFS:ClearAllPoints()
        btn.extraTextFS:SetPoint("LEFT", btn.labelText, "RIGHT", style.gapExtra, 0)
        btn.extraTextFS:Show()
        extraW = btn.extraTextFS:GetStringWidth() + style.gapExtra
    else
        btn.extraTextFS:Hide()
    end

    -- Backdrop colors
    if selected then
        btn:SetBackdropColor(unpack(style.selectedBg))
        btn:SetBackdropBorderColor(unpack(style.selectedBorder))
    else
        btn:SetBackdropColor(unpack(style.unselectedBg))
        btn:SetBackdropBorderColor(unpack(style.unselectedBorder))
    end

    return btn.labelText:GetStringWidth() + extraW + style.padX * 2
end

-- ============================================================================
-- FACTORY
-- ============================================================================

--[[
  Create a filter tab strip.
  @param config table - see file header for documentation
  @return Frame - the strip container, with additional methods attached
]]
function filterTabStrip:create(config)
    if not config or not config.parent then
        error("filterTabStrip:create requires config.parent")
        return nil
    end

    -- Merge config onto defaults into a per-strip style table.
    local style = {}
    for k, v in pairs(DEFAULTS) do style[k] = v end
    if config.orientation then style.orientation = config.orientation end
    if config.tabHeight   then style.tabHeight   = config.tabHeight   end
    if config.spacing     then style.spacing     = config.spacing     end
    -- width: fixed strip width for vertical strips. Caller picks a value
    -- wide enough to fit the widest expected label + pill. Ignored on
    -- horizontal strips (each horizontal tab sizes to its own content).
    if config.width       then style.width       = config.width       end

    if style.orientation ~= "horizontal" and style.orientation ~= "vertical" then
        error("filterTabStrip: orientation must be 'horizontal' or 'vertical'")
        return nil
    end

    local isVertical = style.orientation == "vertical"
    if isVertical and (not style.width or style.width <= 0) then
        error("filterTabStrip: vertical strips require config.width")
        return nil
    end

    local onSelect = config.onSelect

    -- Container frame. In horizontal mode we own height; in vertical, width.
    -- In either case the other dimension is set by caller-supplied anchors.
    local strip = CreateFrame("Frame", nil, config.parent)
    if isVertical then
        strip:SetWidth(style.width)
    else
        strip:SetHeight(style.tabHeight)
    end

    -- Per-strip state
    strip._tabButtons  = {}    -- pool of created Button frames (may exceed active tab count)
    strip._tabConfigs  = {}    -- parallel array of currently-rendered configs
    strip._tabById     = {}    -- id -> index into _tabConfigs
    strip._naturalW    = {}    -- parallel array of each tab's natural width
    strip._selectedId  = nil
    strip._style       = style

    -- Vertical scroll state. Populated by layout() each pass; the strip
    -- only scrolls when total tab content exceeds the strip height.
    -- Tabs outside the visible window are Hide()'d rather than clipped --
    -- works on any WoW version, sidesteps SetClipsChildren availability.
    strip._scrollOffset    = 0       -- 1st visible tab is _tabConfigs[scrollOffset+1]
    strip._maxScrollOffset = 0       -- clamp upper bound (set in layout)
    strip._tabsPerView     = 0       -- how many tabs fit (set in layout)
    strip._isScrollable    = false   -- overflow detected this layout pass
    strip._scrollBtnSize   = 12      -- height of up/down arrow buttons (vertical only)

    -- --------------------------------------------------------------------
    -- Vertical scroll: up/down arrow buttons + mousewheel.
    -- Created lazily here so they exist when layout() decides to show
    -- them. They sit at the top and bottom edges of the strip; tabs
    -- occupy the remaining vertical space when overflow is active.
    -- --------------------------------------------------------------------
    if isVertical then
        local function makeScrollBtn(direction, texture)
            local b = CreateFrame("Button", nil, strip)
            b:SetSize(style.width, strip._scrollBtnSize)
            b:SetNormalTexture(texture)
            b:SetHighlightTexture(texture, "ADD")
            b:GetNormalTexture():SetVertexColor(1, 0.82, 0)   -- gold like the chrome
            b:GetHighlightTexture():SetAlpha(0.4)
            b:SetScript("OnClick", function()
                strip:scroll(direction)
            end)
            b:Hide()
            return b
        end
        -- Reuse the dropdown arrow textures (already in this addon's
        -- texture set, single-arrow PNGs we control). UP rotates the
        -- DOWN arrow texture by 180 -- WoW's SetTexCoord can flip.
        local upTex   = "Interface\\AddOns\\PawnShop\\textures\\arrow-up"
        local downTex = "Interface\\AddOns\\PawnShop\\textures\\arrow-down"
        strip._upBtn   = makeScrollBtn(-1, upTex)
        strip._downBtn = makeScrollBtn( 1, downTex)
        strip._upBtn:SetPoint("TOPLEFT",     strip, "TOPLEFT",     0, 0)
        strip._upBtn:SetPoint("TOPRIGHT",    strip, "TOPRIGHT",    0, 0)
        strip._downBtn:SetPoint("BOTTOMLEFT",  strip, "BOTTOMLEFT",  0, 0)
        strip._downBtn:SetPoint("BOTTOMRIGHT", strip, "BOTTOMRIGHT", 0, 0)

        strip:EnableMouseWheel(true)
        strip:SetScript("OnMouseWheel", function(self, delta)
            if not self._isScrollable then return end
            -- Mousewheel up (delta=+1) shows earlier tabs (scroll offset down).
            self:scroll(-delta)
        end)
    end

    -- --------------------------------------------------------------------
    -- Internal: acquire or build a tab button at slot index i
    -- --------------------------------------------------------------------
    local function getTabButton(i)
        local btn = strip._tabButtons[i]
        if btn then return btn end

        btn = CreateFrame("Button", nil, strip, "BackdropTemplate")
        btn:SetHeight(style.tabHeight)
        btn:SetBackdrop(style.backdrop)
        btn:SetScript("OnClick", function(self)
            if self._tabId and self._tabId ~= strip._selectedId then
                strip:select(self._tabId)
            end
        end)
        btn:SetScript("OnEnter", function(self)
            if not self._tabId then return end
            local idx = strip._tabById[self._tabId]
            local tabConfig = idx and strip._tabConfigs[idx] or nil
            local tip = tabConfig and tabConfig.tooltip
            if not tip then return end

            -- Two accepted shapes:
            --   string                  -> single white line
            --   array of line entries   -> each entry is either a bare
            --     string or {text, r, g, b}; the widget walks the array
            --     and calls AddLine per entry, letting callers render
            --     multi-line tooltips (e.g. pair rows showing both
            --     equipped weapons) with optional per-line rarity color.
            if type(tip) == "string" then
                if tip ~= "" then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText(tip, 1, 1, 1, 1, true)
                    GameTooltip:Show()
                end
                return
            end

            if type(tip) ~= "table" or #tip == 0 then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            for i, line in ipairs(tip) do
                local text, r, g, b
                if type(line) == "string" then
                    text, r, g, b = line, 1, 1, 1
                else
                    text = line[1] or line.text or ""
                    r = line[2] or line.r or 1
                    g = line[3] or line.g or 1
                    b = line[4] or line.b or 1
                end
                if i == 1 then
                    GameTooltip:SetText(text, r, g, b, 1, true)
                else
                    GameTooltip:AddLine(text, r, g, b, true)
                end
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        strip._tabButtons[i] = btn
        return btn
    end

    -- --------------------------------------------------------------------
    -- Internal: re-anchor + re-size all visible tabs.
    -- Horizontal: chain LEFT->RIGHT, each tab keeps its own natural width.
    -- Vertical:   chain TOP->BOTTOM, all tabs use the max natural width,
    --             strip width is set to match.
    -- --------------------------------------------------------------------
    local function layout()
        local count = #strip._tabConfigs

        if isVertical then
            -- Strip width is fixed at style.width (validated nonzero in
            -- :create). Tabs all use that width; short labels leave slack
            -- on the right where the pill hugs.
            local W = style.width
            local stride = style.tabHeight + style.spacing
            local stripH = strip:GetHeight()

            -- Total content height if every tab were laid out flush.
            local contentH = (count > 0) and (count * stride - style.spacing) or 0

            -- Detect overflow. When overflowing, we reserve scrollBtnSize
            -- top and bottom for the up/down buttons; tabs fit between.
            local btnSize = strip._scrollBtnSize
            local needsScroll = contentH > stripH
            strip._isScrollable = needsScroll

            local viewportTop, viewportH
            if needsScroll then
                viewportTop = btnSize
                viewportH   = stripH - 2 * btnSize
                strip._upBtn:Show()
                strip._downBtn:Show()
            else
                viewportTop = 0
                viewportH   = stripH
                strip._upBtn:Hide()
                strip._downBtn:Hide()
                strip._scrollOffset = 0   -- reset when content shrinks
            end

            -- How many full tabs fit in the viewport.
            local tabsPerView
            if stride > 0 and viewportH > 0 then
                tabsPerView = math.floor((viewportH + style.spacing) / stride)
                if tabsPerView < 1 then tabsPerView = 1 end
            else
                tabsPerView = count
            end
            strip._tabsPerView = tabsPerView

            -- Clamp scroll offset to legal range.
            local maxOffset = math.max(0, count - tabsPerView)
            strip._maxScrollOffset = maxOffset
            if strip._scrollOffset > maxOffset then
                strip._scrollOffset = maxOffset
            end

            local prev = nil
            local visibleStart = strip._scrollOffset + 1
            local visibleEnd   = math.min(count, strip._scrollOffset + tabsPerView)

            for i = 1, count do
                local btn = strip._tabButtons[i]
                btn:ClearAllPoints()
                btn:SetWidth(W)

                if i >= visibleStart and i <= visibleEnd then
                    if prev then
                        btn:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -style.spacing)
                    else
                        btn:SetPoint("TOPLEFT", strip, "TOPLEFT", 0, -viewportTop)
                    end
                    btn:Show()
                    prev = btn
                else
                    btn:Hide()
                end

                -- Right-justify the pill so it hugs the right edge of
                -- the (now fixed-width) tab. renderTabContent anchored
                -- it to the right of the label; that's correct for
                -- horizontal strips but here the pill needs to align
                -- to the strip's right edge regardless of label length.
                if btn.extraTextFS and btn.extraTextFS:IsShown() then
                    btn.extraTextFS:ClearAllPoints()
                    btn.extraTextFS:SetPoint("RIGHT", btn, "RIGHT", -style.padX, 0)
                end
            end

            -- Enable/disable scroll buttons based on bounds.
            if needsScroll then
                if strip._scrollOffset > 0 then
                    strip._upBtn:Enable()
                    strip._upBtn:GetNormalTexture():SetVertexColor(1, 0.82, 0)
                else
                    strip._upBtn:Disable()
                    strip._upBtn:GetNormalTexture():SetVertexColor(0.4, 0.35, 0.2)
                end
                if strip._scrollOffset < maxOffset then
                    strip._downBtn:Enable()
                    strip._downBtn:GetNormalTexture():SetVertexColor(1, 0.82, 0)
                else
                    strip._downBtn:Disable()
                    strip._downBtn:GetNormalTexture():SetVertexColor(0.4, 0.35, 0.2)
                end
            end
        else
            local prev = nil
            for i = 1, count do
                local btn = strip._tabButtons[i]
                btn:ClearAllPoints()
                btn:SetWidth(strip._naturalW[i])
                if prev then
                    btn:SetPoint("LEFT", prev, "RIGHT", style.spacing, 0)
                else
                    btn:SetPoint("LEFT", strip, "LEFT", 0, 0)
                end
                btn:SetPoint("TOP", strip, "TOP", 0, 0)
                prev = btn
            end
        end
    end

    -- ====================================================================
    -- PUBLIC METHODS (attached to the strip frame)
    -- ====================================================================

    --[[
      Replace the tab list. Creates/updates/hides buttons as needed.
      Preserves the pool; buttons beyond the new count are hidden but kept
      for reuse. Does NOT change or fire selection; caller decides that.
      @param tabs table - array of tab configs
    ]]
    function strip:setTabs(tabs)
        tabs = tabs or {}

        self._tabConfigs = {}
        self._tabById    = {}
        self._naturalW   = {}

        -- Use a compact output index so malformed entries (missing id)
        -- don't leave holes that break ipairs() in layout().
        local out = 0
        for _, tabConfig in ipairs(tabs) do
            if tabConfig.id then
                out = out + 1
                self._tabConfigs[out] = tabConfig
                self._tabById[tabConfig.id] = out

                local btn = getTabButton(out)
                btn._tabId = tabConfig.id
                self._naturalW[out] = renderTabContent(btn, tabConfig,
                    tabConfig.id == self._selectedId, style)
                btn:Show()
            end
        end

        -- Hide any surplus buttons from prior renders
        for j = out + 1, #self._tabButtons do
            self._tabButtons[j]:Hide()
            self._tabButtons[j]._tabId = nil
        end

        -- If the currently-selected tab no longer exists, drop selection
        -- (but don't fire onSelect; caller drives selection policy).
        if self._selectedId and not self._tabById[self._selectedId] then
            self._selectedId = nil
        end

        layout()
    end

    --[[
      Adjust scroll offset by delta (vertical only). +1 = next tab toward
      bottom, -1 = previous tab toward top. Re-runs layout to repaint.
      No-op when not currently scrollable. Public so callers can wire
      external buttons / hotkeys if they want.
      @param delta number
    ]]
    function strip:scroll(delta)
        if not isVertical or not self._isScrollable then return end
        local newOffset = self._scrollOffset + (delta or 0)
        if newOffset < 0 then newOffset = 0 end
        if newOffset > self._maxScrollOffset then newOffset = self._maxScrollOffset end
        if newOffset == self._scrollOffset then return end
        self._scrollOffset = newOffset
        layout()
    end

    --[[
      Scroll so the tab with the given id is visible (vertical only).
      Used by select() so picking a tab off-screen brings it into view.
      No-op for horizontal strips or when scroll isn't active.
      @param tabId string
    ]]
    function strip:scrollIntoView(tabId)
        if not isVertical then return end
        local idx = self._tabById[tabId]
        if not idx then return end
        if not self._isScrollable then return end

        local first = self._scrollOffset + 1
        local last  = self._scrollOffset + self._tabsPerView
        if idx < first then
            self._scrollOffset = idx - 1
            layout()
        elseif idx > last then
            self._scrollOffset = idx - self._tabsPerView
            layout()
        end
    end

    --[[
      Select a tab by id. Re-renders affected buttons and fires onSelect.
      No-op if tabId is already selected or doesn't exist.
      @param tabId string
      @return boolean - true if selection changed
    ]]
    function strip:select(tabId)
        if tabId == self._selectedId then return false end
        if not self._tabById[tabId]   then return false end

        local prevId = self._selectedId
        self._selectedId = tabId

        -- Repaint old + new (content only; width is managed by layout).
        if prevId and self._tabById[prevId] then
            local idx = self._tabById[prevId]
            self._naturalW[idx] = renderTabContent(
                self._tabButtons[idx], self._tabConfigs[idx], false, style)
        end
        local idx = self._tabById[tabId]
        self._naturalW[idx] = renderTabContent(
            self._tabButtons[idx], self._tabConfigs[idx], true, style)

        -- Re-run layout: in horizontal mode a selection change can alter
        -- a tab's natural width slightly (different text color doesn't,
        -- but keeping this consistent is cheap); in vertical mode we need
        -- to recheck the max.
        layout()

        -- After layout has updated scroll bounds, ensure the newly-
        -- selected tab is visible (vertical scroll mode).
        self:scrollIntoView(tabId)

        if onSelect then onSelect(tabId) end
        return true
    end

    --[[
      Select the first tab in the current list. Returns false if empty.
      @return boolean
    ]]
    function strip:selectFirst()
        local first = self._tabConfigs[1]
        if not first then return false end
        -- If the first tab is already selected, still fire onSelect so the
        -- caller can react to a setTabs-triggered "fresh data" state.
        if first.id == self._selectedId then
            if onSelect then onSelect(first.id) end
            return true
        end
        return self:select(first.id)
    end

    --[[
      Currently selected tab id, or nil.
      @return string|nil
    ]]
    function strip:getSelected()
        return self._selectedId
    end

    --[[
      Does the current tab list contain this id?
      @param tabId string
      @return boolean
    ]]
    function strip:hasTab(tabId)
        return self._tabById[tabId] ~= nil
    end

    --[[
      Number of currently-rendered tabs.
      @return number
    ]]
    function strip:getTabCount()
        return #self._tabConfigs
    end

    return strip
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("filterTabStrip", {}, function()
        return true
    end)
end

Addon.filterTabStrip = filterTabStrip
return filterTabStrip
