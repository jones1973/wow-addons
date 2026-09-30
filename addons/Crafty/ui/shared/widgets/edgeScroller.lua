--[[
  edgeScroller - a scroll surface that shows nothing until it has to.

  A scrollbar is chrome, and a panel whose content usually fits should not carry
  one waiting to be needed. This draws no bar at all: when the content overruns,
  a small arrow pulses at the edge that has more behind it, and it goes when
  there is nothing more that way.

  Contrast scrollBox, which reserves a gutter and draws a bar whether or not it
  is needed. That is the right widget for a list that is always long - a recipe
  list - and the wrong one for a panel section that is three rows on most
  recipes and nine on a few.

  USE
    local sc = Addon.edgeScroller:create({ parent = someFrame })
    myStack = rowStack:create({ content = sc:getContent(), ... })
    sc:contentChanged(myStack:render(items))   -- the laid-out height

  Dependencies: theme, motion
  Exports: Addon.edgeScroller
]]
local ADDON_NAME, Addon = ...
local edgeScroller = {}

-- Enough to read as an arrow at a glance without taking room from the rows.
local ARROW_H = 10
local STEP    = 22       -- one row per wheel notch
-- The pulse: slow enough to read as "there is more", not as an alarm.
local PULSE_PERIOD = 1.6
local PULSE_MIN, PULSE_MAX = 0.25, 0.85

--[[
  @param config table - { parent }
  @return table - { getContent, contentChanged, getFrame }
]]
function edgeScroller:create(config)
    if not config or not config.parent then
        error("edgeScroller:create requires config.parent")
    end
    local theme, motion = Addon.theme, Addon.motion
    local instance = {}

    local scrollFrame = CreateFrame("ScrollFrame", nil, config.parent)
    scrollFrame:SetAllPoints(config.parent)
    scrollFrame:EnableMouseWheel(true)

    -- The scroll child carries the rows, which anchor to its left and right
    -- edges - so its WIDTH is load-bearing: at 1px every row renders 1px wide
    -- and the list is invisible while still reporting a plausible height.
    --
    -- Matched in contentChanged rather than from OnSizeChanged: this frame
    -- takes its size from anchors, and an anchor-derived size does not reliably
    -- raise OnSizeChanged before the first render.
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetPoint("TOPLEFT")
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    -- Arrows sit OVER the rows at the frame's edges rather than beside them:
    -- reserving a lane for them would cost the space they exist to say is
    -- being used.
    local function makeArrow(point, rotation)
        local a = scrollFrame:CreateTexture(nil, "OVERLAY")
        a:SetSize(ARROW_H * 2, ARROW_H)
        a:SetPoint(point, scrollFrame, point, 0, point == "TOP" and -1 or 1)
        a:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
        a:SetRotation(rotation)
        local c = theme.tokens.TEXT.EMPHASIS
        a:SetVertexColor(c.r, c.g, c.b)
        a:Hide()
        return a
    end
    local upArrow   = makeArrow("TOP", 0)
    local downArrow = makeArrow("BOTTOM", math.pi)

    -- One driver for both arrows: they pulse together or not at all, and a
    -- second timer would let them drift apart.
    local pulsing = false
    local function startPulse()
        if pulsing then return end
        pulsing = true
        motion:run(scrollFrame, function(elapsed)
            if not pulsing then return true end
            local u = (elapsed % PULSE_PERIOD) / PULSE_PERIOD
            local a = PULSE_MIN + (PULSE_MAX - PULSE_MIN)
                      * (0.5 - 0.5 * math.cos(u * 2 * math.pi))
            upArrow:SetAlpha(a)
            downArrow:SetAlpha(a)
        end)
    end

    local contentHeight = 0

    local function paintArrows()
        local viewport = scrollFrame:GetHeight() or 0
        local overrun = contentHeight - viewport
        if overrun <= 1 then
            upArrow:Hide()
            downArrow:Hide()
            pulsing = false
            motion:stop(scrollFrame)
            return
        end
        local offset = scrollFrame:GetVerticalScroll() or 0
        upArrow:SetShown(offset > 1)
        downArrow:SetShown(offset < overrun - 1)
        startPulse()
    end

    scrollFrame:SetScript("OnVerticalScroll", paintArrows)
    scrollFrame:SetScript("OnScrollRangeChanged", paintArrows)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local overrun = math.max(0, contentHeight - (self:GetHeight() or 0))
        local to = math.max(0, math.min(overrun,
            (self:GetVerticalScroll() or 0) - delta * STEP))
        self:SetVerticalScroll(to)
    end)

    --[[
      The frame rows are laid out in. Hand this to a rowStack as its content.
    ]]
    function instance:getContent()
        return content
    end

    function instance:getFrame()
        return scrollFrame
    end

    --[[
      Tell the scroller how tall its content became.

      @param height number - the laid-out height, as rowStack:render returns
    ]]
    function instance:contentChanged(height)
        contentHeight = height or 0
        -- Width first, and only when the frame has one: called before layout
        -- settles, GetWidth is 0 and writing that would blank the rows.
        local w = scrollFrame:GetWidth()
        if w and w > 0 then content:SetWidth(w) end
        content:SetHeight(math.max(1, contentHeight))
        -- Without this the scroll range is stale, so the arrows would test a
        -- range that never moved.
        scrollFrame:UpdateScrollChildRect()
        -- A shorter list can leave the view scrolled past its own end.
        local overrun = math.max(0, contentHeight - (scrollFrame:GetHeight() or 0))
        if (scrollFrame:GetVerticalScroll() or 0) > overrun then
            scrollFrame:SetVerticalScroll(overrun)
        end
        paintArrows()
    end

    return instance
end

Addon.edgeScroller = edgeScroller

if Addon.registerModule then
    Addon.registerModule("edgeScroller", { "theme", "motion" })
end
