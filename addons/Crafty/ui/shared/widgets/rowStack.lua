--[[
  ui/shared/widgets/rowStack.lua   [SHARED: pending sync to monorepo shared/]
  RowStack — pooled, positioned vertical rows from an ordered array

  The primitive beneath listView. A rowStack renders an ordered array of
  items into a vertical stack of pooled frames inside a content frame the
  consumer supplies. It is the "stacked rows" soul shared by almost every
  list-shaped UI in the family — but WITHOUT scroll, sort, filter, or
  grouping. Those live one layer up in listView.

  Use rowStack directly for static or short stacks that do not scroll:
  reagent lines, key/value detail blocks, small fixed menus. Use listView
  when you need scrolling, sorting, filtering, or grouping; listView is
  itself built on a rowStack.

  RowStack owns:
    - Pools per kind (lazy, one per kind), via Addon.pool.
    - Per-kind render specs (height, factory, render), keyed by item.kind.
    - Click / double-click dispatch (manual double-click timing for TBC
      Classic, which has no OnDoubleClick).
    - Optional standard chrome: hover + selection paint, on by default for
      interactive kinds, opt-out per kind. Painted below consumer content.
    - Single selection state (nullable), if the consumer wires clicks to it.

  RowStack does NOT own:
    - Any scroll frame. The consumer (or listView) supplies the parent
      content frame; rowStack lays rows out from its top, downward, and
      reports the total height via render().
    - Row visuals beyond chrome. Columns, icons, colors, tooltips are all
      consumer-rendered in factory/render.
    - Ordering. The caller passes an already-ordered array to render();
      rowStack does not sort, filter, or group.

  Usage:
    local rs = Addon.rowStack:create({
        content    = someFrame,        -- frame rows are parented to + sized within

        kinds = {
            row = {
                height  = 18,
                factory = function(parent) ... return frame end,
                render  = function(frame, item, ctx) ... end,  -- ctx = { isSelected, identity }
                chrome  = { hover = true, selection = true },  -- optional; defaults on
            },
        },

        onClick       = function(item, kind, identity) ... end,  -- optional
        onDoubleClick = function(item, kind, identity) ... end,  -- optional
        onContextMenu = function(item, kind, identity, frame) ... end,  -- optional
    })

    local totalHeight = rs:render(orderedArray)   -- lay out; returns content height
    rs:getSelected();  rs:setSelected(id);  rs:clearSelection()
    rs:release()                                   -- release all rows (no render)

  Each item in the array must carry a `kind` field naming its spec; a
  single-kind stack may omit it and rowStack defaults to "row".

  Dependencies: pool, theme (chrome tokens: SURFACE.ROW_HOVER / ROW_SELECTED)
  Exports: Addon.rowStack
]]

local _, Addon = ...

local rowStack = {}

-- Manual double-click timing window (TBC Classic Button has no
-- OnDoubleClick).
local DOUBLE_CLICK_INTERVAL = 0.4

-- Default kind name when an item carries no `kind` field.
local DEFAULT_KIND = "row"

-- ============================================================================
-- SPEC VALIDATION
-- ============================================================================

local function validateKindSpec(kind, spec)
    if type(spec) ~= "table" then
        error("rowStack: kinds." .. kind .. " must be a table")
    end
    if type(spec.height) ~= "number" then
        error("rowStack: kinds." .. kind .. ".height must be a number")
    end
    if type(spec.factory) ~= "function" then
        error("rowStack: kinds." .. kind .. ".factory must be a function")
    end
    if type(spec.render) ~= "function" then
        error("rowStack: kinds." .. kind .. ".render must be a function")
    end
    if spec.chrome ~= nil then
        if type(spec.chrome) ~= "table" then
            error("rowStack: kinds." .. kind .. ".chrome must be a table")
        end
        local c = spec.chrome
        if c.hover ~= nil and type(c.hover) ~= "boolean" then
            error("rowStack: kinds." .. kind .. ".chrome.hover must be a boolean")
        end
        if c.selection ~= nil and type(c.selection) ~= "boolean" then
            error("rowStack: kinds." .. kind .. ".chrome.selection must be a boolean")
        end
    end
    if spec.onClick ~= nil and type(spec.onClick) ~= "function" then
        error("rowStack: kinds." .. kind .. ".onClick must be a function")
    end
end

-- ============================================================================
-- INSTANCE
-- ============================================================================

function rowStack:create(config)
    if not config then
        error("rowStack:create requires config")
    end
    if type(config.kinds) ~= "table" or next(config.kinds) == nil then
        error("rowStack:create requires config.kinds with at least one kind")
    end
    for kind, spec in pairs(config.kinds) do
        validateKindSpec(kind, spec)
    end

    -- Two surfaces. Either:
    --   config.content = a frame the consumer owns (no scroll), OR
    --   config.scroll  = { parent, width, height } to wrap rows in a scrollBox
    --                    (thin scrollbar, on-demand). rowStack renders into the
    --                    scrollBox's content and recomputes overflow each render.
    local scrollBoxInstance, content
    if config.scroll then
        local s = config.scroll
        if not s.parent or type(s.width) ~= "number" or type(s.height) ~= "number" then
            error("rowStack:create: config.scroll requires parent, width, height")
        end
        scrollBoxInstance = Addon.scrollBox:create({
            parent = s.parent,
            width  = s.width,
            height = s.height,
            scrollFrameName = s.scrollFrameName,
        })
        content = scrollBoxInstance:getContent()
    elseif config.content then
        content = config.content
    else
        error("rowStack:create requires config.content (a frame) or config.scroll spec")
    end

    local kinds         = config.kinds

    local onClick            = config.onClick
    local onDoubleClick      = config.onDoubleClick
    local onContextMenu      = config.onContextMenu
    local onSelectionChanged = config.onSelectionChanged

    local selectedIdentity = nil

    -- Pools, one per kind, lazily created.
    local pools = {}

    -- identity → frame for currently-rendered rows; rebuilt each render.
    local identityToFrame = {}

    -- Ordered list of currently-rendered identities (top to bottom). Lets the
    -- surgical ops (appendRow/removeRow) know the bottom offset and re-flow rows
    -- below a removed one without a full rebuild.
    local renderOrder = {}

    -- Double-click pair state.
    local lastClickTime  = 0
    local lastClickFrame = nil

    local instance = {}

    -- ====================================================================
    -- INTERNAL: click wiring
    -- ====================================================================

    local function fireClick(self, button)
        local item     = self._rsItem
        local kind     = self._rsKind
        local identity = self._rsIdentity

        if button == "RightButton" then
            if onContextMenu then
                onContextMenu(item, kind, identity, self)
            end
            return
        end

        local now      = GetTime()
        local isDouble = (self == lastClickFrame)
            and ((now - lastClickTime) < DOUBLE_CLICK_INTERVAL)

        if isDouble and onDoubleClick then
            lastClickTime  = 0
            lastClickFrame = nil
            onDoubleClick(item, kind, identity)
        else
            lastClickTime  = now
            lastClickFrame = self
            -- A click belongs to the row's kind: if that kind defines its own
            -- onClick, it handles the click; otherwise the stack's onClick does.
            local kindSpec = kinds[kind]
            if kindSpec and kindSpec.onClick then
                kindSpec.onClick(item, kind, identity)
            elseif onClick then
                onClick(item, kind, identity)
            end
        end
    end

    local function wireRowClicks(rowFrame)
        if not rowFrame.RegisterForClicks then return end  -- not a Button
        if onContextMenu then
            rowFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        else
            rowFrame:RegisterForClicks("LeftButtonUp")
        end
        rowFrame:SetScript("OnClick", fireClick)
    end

    -- ====================================================================
    -- INTERNAL: standard row chrome (hover + selection paint)
    -- ====================================================================

    -- Resolve a kind's chrome settings, applying defaults (both on).
    -- Returns nil for kinds that paint nothing.
    local function resolveChrome(kind)
        local c = kinds[kind].chrome or {}
        local hover     = c.hover ~= false      -- default on
        local selection = c.selection ~= false  -- default on
        local stripe    = c.stripe == true      -- default off (opt-in)
        if not hover and not selection and not stripe then return nil end
        local surface = Addon.theme.tokens.SURFACE
        return {
            hover         = hover,
            selection     = selection,
            stripe        = stripe,
            hoverColor    = c.hoverColor    or surface.ROW_HOVER,
            selectedColor = c.selectedColor or surface.ROW_SELECTED,
            stripeColor   = c.stripeColor   or surface.ROW_ALT,
        }
    end

    -- Repaint a row's chrome for its current state. Selection wins over hover,
    -- hover over the alternating stripe. The stripe is the base layer: on odd
    -- rows (by layout position) it shows when the row is neither selected nor
    -- hovered, so the list reads as a table.
    local function paintChrome(rowFrame)
        local cfg = rowFrame._rsChrome
        local tex = rowFrame._rsChromeTex
        if not cfg or not tex then return end
        local color
        if cfg.selection and rowFrame._rsSelected then
            color = cfg.selectedColor
        elseif cfg.hover and rowFrame._rsHovered then
            color = cfg.hoverColor
        elseif cfg.stripe and rowFrame._rsIndex and (rowFrame._rsIndex % 2 == 0) then
            color = cfg.stripeColor
        end
        if color then
            tex:SetColorTexture(color.r, color.g, color.b, color.a)
            tex:Show()
        else
            tex:Hide()
        end
    end

    -- Attach chrome texture + hover handlers once per pooled frame.
    local function attachChrome(rowFrame, kind)
        local cfg = resolveChrome(kind)
        if not cfg then return end
        rowFrame._rsChrome = cfg

        local tex = rowFrame:CreateTexture(nil, "BACKGROUND")
        tex:SetAllPoints()
        tex:Hide()
        rowFrame._rsChromeTex = tex

        if cfg.hover then
            rowFrame:HookScript("OnEnter", function(self)
                self._rsHovered = true
                paintChrome(self)
            end)
            rowFrame:HookScript("OnLeave", function(self)
                self._rsHovered = false
                paintChrome(self)
            end)
        end
    end

    -- ====================================================================
    -- INTERNAL: pools
    -- ====================================================================

    local function getRowPool(kind)
        local existing = pools[kind]
        if existing then return existing end

        local spec = kinds[kind]
        if not spec then
            error("rowStack: no kind spec for '" .. tostring(kind) .. "'")
        end

        local pool = Addon.pool:new(function()
            local f = spec.factory(content)
            wireRowClicks(f)
            attachChrome(f, kind)
            return f
        end)
        pools[kind] = pool
        return pool
    end

    local function releaseAllPools()
        for _, pool in pairs(pools) do
            pool:releaseAll()
        end
    end

    -- ====================================================================
    -- INTERNAL: layout
    -- ====================================================================

    local function placeRow(rowFrame, y)
        rowFrame:ClearAllPoints()
        rowFrame:SetPoint("TOPLEFT",  0, -y)
        rowFrame:SetPoint("TOPRIGHT", 0, -y)
        rowFrame:Show()
    end

    -- Lay out one item at offset y; return the offset just below it. index is the
    -- item's 1-based position in the current layout, used for stripe parity.
    local function renderItem(item, y, index)
        local kind = item.kind or DEFAULT_KIND
        local spec = kinds[kind]
        if not spec then
            error("rowStack: item has unknown kind '" .. tostring(kind) .. "'")
        end

        local rowFrame = getRowPool(kind):acquire()
        local identity = item.id

        local h = item._height or spec.height
        rowFrame:SetHeight(h)
        rowFrame._rsItem     = item
        rowFrame._rsKind     = kind
        rowFrame._rsIdentity = identity
        rowFrame._rsIndex    = index

        identityToFrame[identity] = rowFrame

        placeRow(rowFrame, y)
        rowFrame._rsHovered  = false
        rowFrame._rsSelected = (identity == selectedIdentity)
        paintChrome(rowFrame)
        spec.render(rowFrame, item, {
            isSelected = (identity == selectedIdentity),
            identity   = identity,
        })

        return y + h
    end

    local function rerenderForIdentity(identity)
        if not identity then return end
        local rowFrame = identityToFrame[identity]
        if not rowFrame then return end
        local kind = rowFrame._rsKind
        local spec = kinds[kind]
        rowFrame._rsSelected = (identity == selectedIdentity)
        paintChrome(rowFrame)
        spec.render(rowFrame, rowFrame._rsItem, {
            isSelected = (identity == selectedIdentity),
            identity   = identity,
        })
    end

    -- ====================================================================
    -- PUBLIC API
    -- ====================================================================

    --[[
      Lay out an already-ordered array of items, top-down. Releases all
      prior rows first. Returns the total height of the rendered stack
      (>= 1), so the caller can size the content frame.
    ]]
    function instance:render(items)
        releaseAllPools()
        identityToFrame = {}
        renderOrder = {}

        items = items or {}
        local y = 0
        for i = 1, #items do
            y = renderItem(items[i], y, i)
            renderOrder[#renderOrder + 1] = items[i].id
        end
        local height = math.max(1, y)

        -- When scrolling, size the scroll content to the rendered height and
        -- recompute overflow (bar show/hide). When bare, the consumer owns the
        -- content frame's height.
        if scrollBoxInstance then
            content:SetHeight(height)
            scrollBoxInstance:contentChanged()
        end
        return height
    end

    -- Release every row without rendering new ones.
    function instance:release()
        releaseAllPools()
        identityToFrame = {}
        renderOrder = {}
    end

    -- Total laid-out height of the current rows (sum of frame heights).
    local function currentHeight()
        local h = 0
        for i = 1, #renderOrder do
            local f = identityToFrame[renderOrder[i]]
            if f then h = h + f:GetHeight() end
        end
        return math.max(1, h)
    end

    local function sizeContent()
        if scrollBoxInstance then
            content:SetHeight(currentHeight())
            scrollBoxInstance:contentChanged()
        end
    end

    --[[
      Surgical primitives. These touch ONE row (plus, for removeRow, a cheap
      reposition of the rows below it). They do NOT recompute order, filter, or
      grouping - the caller decides what changes and where. A full
      sort/filter/group pass is render(stream), used only on the trigger cases
      (fresh open, filter change, dataset replacement, refresh-to-pure).
    ]]

    -- Add one row at the bottom of the current stack. The new row's identity
    -- must not already be rendered.
    function instance:appendRow(item)
        local identity = item.id
        if identityToFrame[identity] then return end  -- already shown; use updateRow
        local y = currentHeight()
        if #renderOrder == 0 then y = 0 end
        renderItem(item, y)
        renderOrder[#renderOrder + 1] = identity
        sizeContent()
    end

    -- Insert one row directly after the row with `afterIdentity`, pushing every
    -- row below it down. A purely positional insert - it does NOT consult filter,
    -- sort, or grouping; the caller has decided this row belongs at this spot.
    -- If afterIdentity is not currently rendered, the row appends at the bottom.
    -- The new row's identity must not already be rendered.
    -- Reach a rendered row's frame by identity (e.g. to decorate it). Returns nil
    -- if not currently rendered.
    function instance:frameFor(identity)
        return identityToFrame[identity]
    end

    -- Remove one row by identity; re-flow the rows below it upward.
    function instance:removeRow(identity)
        local target = identityToFrame[identity]
        if not target then return end

        -- Find its position in the order.
        local pos
        for i = 1, #renderOrder do
            if renderOrder[i] == identity then pos = i; break end
        end

        -- Release the frame and drop it from tracking/order.
        local pool = pools[target._rsKind]
        if pool then pool:release(target) end
        identityToFrame[identity] = nil
        if pos then table.remove(renderOrder, pos) end

        -- Re-flow everything from the removed position downward.
        local y = 0
        for i = 1, #renderOrder do
            local f = identityToFrame[renderOrder[i]]
            if f then
                if i >= (pos or 1) then placeRow(f, y) end
                y = y + f:GetHeight()
            end
        end
        sizeContent()
    end

    -- Re-render one row in place (its item content changed, e.g. a derived
    -- display value updated). Position and height unchanged.
    function instance:updateRow(item)
        local identity = item.id
        local rowFrame = identityToFrame[identity]
        if not rowFrame then return end
        rowFrame._rsItem = item
        local kind = rowFrame._rsKind
        local spec = kinds[kind]
        rowFrame._rsSelected = (identity == selectedIdentity)
        paintChrome(rowFrame)
        spec.render(rowFrame, item, {
            isSelected = (identity == selectedIdentity),
            identity   = identity,
        })
    end

    -- Re-render every currently-rendered row's content in place, pulling fresh
    -- items from the provider. No re-projection: the set of rows and their order
    -- are unchanged - only their drawn content updates (e.g. skill-up recolors a
    -- difficulty band). A row inserted past the active filter is NOT dropped,
    -- because the filter is not re-run.
    function instance:redrawVisible(itemFor)
        for i = 1, #renderOrder do
            self:updateRow(itemFor(renderOrder[i]))
        end
    end

    -- Is a row for this identity currently on screen?
    function instance:isRendered(identity)
        return identityToFrame[identity] ~= nil
    end

    function instance:getSelected()
        return selectedIdentity
    end

    function instance:setSelected(identity)
        if identity == selectedIdentity then return end
        local previous = selectedIdentity
        selectedIdentity = identity
        rerenderForIdentity(previous)
        rerenderForIdentity(identity)
        if onSelectionChanged then
            onSelectionChanged(identity)
        end
    end

    function instance:clearSelection()
        self:setSelected(nil)
    end

    -- The frame this stack lays rows into (escape hatch).
    function instance:getContent()
        return content
    end

    -- The composing scrollBox (nil for a bare, non-scrolling stack). Use its
    -- getFrame() to position a scrolling stack.
    function instance:getScrollBox()
        return scrollBoxInstance
    end

    -- Look up the live frame for an identity (nil if not currently rendered).
    function instance:frameFor(identity)
        return identityToFrame[identity]
    end

    --[[
      Mark a row as newly arrived at: the same gold the profession band uses
      when something is learned for a profession you are not looking at.

      Lives here because the stack lays these rows out - a caller wanting to
      mark one would have to know where it sits, which would make it a second
      authority on that layout.

      @param identity any - the row to mark; silent if it is not rendered
    ]]
    function instance:flare(identity)
        local row = identityToFrame[identity]
        if not row then return end

        local wash = row.flareWash
        if not wash then
            wash = row:CreateTexture(nil, "BACKGROUND")
            wash:SetAllPoints(row)
            row.flareWash = wash
        end

        local g = Addon.theme.tokens.TEXT.EMPHASIS
        wash:SetColorTexture(g.r, g.g, g.b, 0.15)
        wash:Show()
        Addon.motion:run(row, function(elapsed)
            local u = elapsed / 1.2
            if u >= 1 then
                wash:Hide()
                return true
            end
            -- Held, then faded: gold that blinks is missed by anyone who was
            -- not already looking at the row.
            wash:SetAlpha(u < 0.6 and 1 or (1 - (u - 0.6) / 0.4))
        end)
    end

    return instance
end

if Addon.registerModule then
    Addon.registerModule("rowStack", {"pool", "scrollBox", "theme", "motion"})
end

Addon.rowStack = rowStack
return rowStack
