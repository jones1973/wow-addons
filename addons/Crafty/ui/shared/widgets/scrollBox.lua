--[[
  ui/shared/widgets/scrollBox.lua   [SHARED: pending sync to monorepo shared/]
  ScrollBox — thin-scrollbar scroll container around a single content frame

  A scroll container with a thin custom scrollbar. It wraps a content frame
  the consumer fills with anything (pooled rows, a text block, a stack of
  widgets) and scrolls it vertically. The scrollbar is a slim hand-built
  Slider (track + thumb) — the modern thin MinimalScrollBar templates do not
  exist on MoP Classic / TBC Anniversary, so the thin look is built directly.

  ScrollBox knows nothing about what it scrolls. It is the orthogonal "scroll"
  capability, composable onto rowStack (see rowStack's optional scroll) or any
  other content-frame-owning widget, or used directly.

  Overflow-aware: the scrollbar shows only when content exceeds the visible
  height, and hides when it fits. A thin gutter is always reserved on the
  right so content width does not jump when the bar appears/disappears; with
  a slim bar the empty gutter is visually negligible.

  ScrollBox owns:
    - A ScrollFrame + content frame (the surface the consumer fills).
    - A thin Slider scrollbar (track + thumb), shown on overflow only.
    - Mousewheel scrolling and slider/scroll synchronization.

  ScrollBox does NOT own:
    - Anything about the content's structure. The consumer sizes the content
      frame's height (or a composing widget like rowStack does) and calls
      contentChanged() so the box recomputes overflow.

  Usage:
    local box = Addon.scrollBox:create({ parent = panel, width = 260, height = 400 })
    local content = box:getContent()    -- fill this frame; anchor children to it
    -- ... after the content's height changes ...
    box:contentChanged()                -- recompute scroll range + bar visibility

    box:getFrame()        -- outer frame (position/size this)
    box:getScrollFrame()  -- the ScrollFrame (escape hatch)
    box:scrollTo(0)       -- set vertical scroll offset (clamped)
    box:reset()           -- scroll back to top

  Dependencies: theme (scrollbar colors)
  Exports: Addon.scrollBox
]]

local _, Addon = ...

local scrollBox = {}

-- Thin scrollbar geometry.
local BAR_WIDTH      = 6      -- slim track width
local THUMB_WIDTH    = 6
local BAR_GUTTER     = 8      -- reserved space on the right (bar + small inset)
local WHEEL_STEP     = 40     -- pixels per mousewheel notch

function scrollBox:create(config)
    if not config then
        error("scrollBox:create requires config")
    end
    if not config.parent then
        error("scrollBox:create requires config.parent")
    end
    if type(config.width) ~= "number" or type(config.height) ~= "number" then
        error("scrollBox:create requires numeric config.width and config.height")
    end

    local instance = {}

    -- Outer frame: consumers position/size this.
    local frame = CreateFrame("Frame", nil, config.parent)
    frame:SetSize(config.width, config.height)

    -- ScrollFrame fills the frame minus the reserved bar gutter.
    local scrollFrame = CreateFrame("ScrollFrame", config.scrollFrameName, frame)
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", -BAR_GUTTER, 0)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(config.width - BAR_GUTTER, 1)
    scrollFrame:SetScrollChild(content)

    -- Thin scrollbar: a Slider with a custom track + thumb, in the gutter.
    local bar = CreateFrame("Slider", nil, frame)
    bar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    bar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    bar:SetWidth(BAR_WIDTH)
    bar:SetValueStep(1)
    bar:SetMinMaxValues(0, 100)
    bar:SetValue(0)
    bar:SetOrientation("VERTICAL")

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    local trackColor = Addon.theme.tokens.SURFACE.ROW_ALT
    track:SetColorTexture(trackColor.r, trackColor.g, trackColor.b, 0.5)

    local thumb = bar:CreateTexture(nil, "OVERLAY")
    local thumbColor = Addon.theme.tokens.SURFACE.ROW_HOVER
    thumb:SetColorTexture(thumbColor.r, thumbColor.g, thumbColor.b, 0.9)
    thumb:SetWidth(THUMB_WIDTH)
    bar:SetThumbTexture(thumb)
    bar:Hide()

    -- Keep slider position synced when scrolled, and scroll when the slider
    -- moves. The slider runs 0..100 as a percentage of the scroll range.
    local function scrollToOffset(offset)
        local max = scrollFrame:GetVerticalScrollRange()
        local clamped = math.max(0, math.min(max, offset))
        scrollFrame:SetVerticalScroll(clamped)
        if max > 0 then
            bar:SetValue((clamped / max) * 100)
        end
    end

    bar:SetScript("OnValueChanged", function(_, value)
        local max = scrollFrame:GetVerticalScrollRange()
        scrollFrame:SetVerticalScroll((value / 100) * max)
    end)

    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        scrollToOffset(scrollFrame:GetVerticalScroll() - delta * WHEEL_STEP)
    end)

    -- ====================================================================
    -- PUBLIC API
    -- ====================================================================

    -- The frame consumers fill. Anchor children to it; it scrolls.
    function instance:getContent()
        return content
    end

    function instance:getFrame()
        return frame
    end

    function instance:getScrollFrame()
        return scrollFrame
    end

    -- Recompute scroll range and bar visibility after content height changes.
    -- Show the bar only when content overflows the visible area.
    function instance:contentChanged()
        -- Keep the scroll child's width matched to the scrollframe (the outer
        -- frame may have been resized/re-anchored by the consumer since create).
        local w = scrollFrame:GetWidth()
        if w and w > 0 then
            content:SetWidth(w)
        end
        scrollFrame:UpdateScrollChildRect()
        local range = scrollFrame:GetVerticalScrollRange()
        if range > 0 then
            bar:Show()
            -- Clamp current scroll into the new range.
            local cur = scrollFrame:GetVerticalScroll()
            if cur > range then
                scrollToOffset(range)
            end
        else
            bar:Hide()
            scrollFrame:SetVerticalScroll(0)
            bar:SetValue(0)
        end
    end

    function instance:scrollTo(offset)
        scrollToOffset(offset)
    end

    function instance:reset()
        scrollToOffset(0)
    end

    return instance
end

if Addon.registerModule then
    Addon.registerModule("scrollBox", {"theme"})
end

Addon.scrollBox = scrollBox
return scrollBox
