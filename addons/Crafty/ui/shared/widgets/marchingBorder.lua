--[[
  ui/shared/widgets/marchingBorder.lua   [SHARED: pending sync to monorepo shared/]
  MarchingBorder — segments that crawl a frame's perimeter

  The "this is active, act now" affordance: a dashed border whose segments
  travel around a frame, the way a selection marquee does in an image editor.
  It decorates any frame and owns nothing about it — attach one to a button, a
  row, a card, whatever needs to say "I am live".

  A border is N short segments spaced evenly around the host's perimeter. Each
  tick advances every segment by the same distance along that perimeter, so
  the whole dashed outline appears to march. A segment's position maps to a
  point on one of the four edges by walking the perimeter length; that is the
  entire trick.

  It runs on its OWN frame, never the host's OnUpdate — the host may be a
  secure frame we must not script, and a decoration has no business owning its
  subject's update handler regardless.

  Usage:
    local march = Addon.marchingBorder:create(hostFrame, {
        color   = { r, g, b },   -- defaults to brand primary
        count   = 12,            -- segments; default scales to perimeter
        speed   = 40,            -- pixels/sec around the border; default 40
        segment = 6,             -- segment length in px; default 6
        thickness = 2,           -- px; default 2
        inset   = 0,             -- px outside (negative) or inside the host
    })
    march:start()
    march:stop()
    march:setColor(r, g, b)

  The host's current size is read at start and whenever restarted, so attach
  to a frame whose size is settled (or restart after it resizes).

  Dependencies: theme
  Exports: Addon.marchingBorder
]]

local ADDON_NAME, Addon = ...

local marchingBorder = {}

local DEFAULTS = {
    count     = nil,   -- derived from perimeter when absent
    speed     = 40,
    segment   = 6,
    thickness = 2,
    inset     = 0,
}

-- A dashed segment as a plain colored texture. Kept minimal: the effect is in
-- the motion, not the sprite.
local function makeSegment(parent, color, thickness)
    local tex = parent:CreateTexture(nil, "OVERLAY")
    tex:SetColorTexture(color.r, color.g, color.b, 1)
    tex:SetHeight(thickness)
    return tex
end

function marchingBorder:create(host, opts)
    if not host then
        error("marchingBorder:create requires a host frame")
    end
    opts = opts or {}

    local color = opts.color or Addon.theme.tokens.BRAND.PRIMARY
    local speed     = opts.speed     or DEFAULTS.speed
    local segLen    = opts.segment   or DEFAULTS.segment
    local thickness = opts.thickness or DEFAULTS.thickness
    local inset     = opts.inset     or DEFAULTS.inset

    local instance = {}

    -- The driver frame: parented to the host so it hides/shows and is
    -- stripped with it, but its OWN OnUpdate carries the march. The host's is
    -- never touched.
    local frame = CreateFrame("Frame", nil, host)
    frame:SetPoint("TOPLEFT", host, "TOPLEFT", inset, -inset)
    frame:SetPoint("BOTTOMRIGHT", host, "BOTTOMRIGHT", -inset, inset)
    frame:Hide()

    local segments = {}
    local timer = 0

    -- Geometry, recomputed on start: perimeter and the cumulative edge lengths
    -- that let a scalar position map to an (x, y) on the border.
    local geo = {}
    local function measure()
        local w, h = frame:GetWidth(), frame:GetHeight()
        geo.w, geo.h = w, h
        geo.perimeter = 2 * (w + h)
        -- Cumulative distance at which each edge ends, walking clockwise from
        -- the top-left: across the top, down the right, across the bottom,
        -- up the left.
        geo.top    = w
        geo.right  = w + h
        geo.bottom = w + h + w
        -- (left ends at the full perimeter)
    end

    -- Map a distance along the perimeter to a point relative to the frame's
    -- BOTTOMLEFT, and the orientation the segment should take there.
    local function pointAt(dist)
        dist = dist % geo.perimeter
        if dist <= geo.top then
            return dist, geo.h, "h"                       -- top edge, L→R
        elseif dist <= geo.right then
            return geo.w, geo.h - (dist - geo.top), "v"   -- right edge, T→B
        elseif dist <= geo.bottom then
            return geo.w - (dist - geo.right), 0, "h"     -- bottom edge, R→L
        else
            return 0, dist - geo.bottom, "v"              -- left edge, B→T
        end
    end

    local function layout()
        local count = opts.count
            or math.max(4, math.floor(geo.perimeter / (segLen * 3)))
        -- Grow or shrink the pool to the needed count.
        for i = #segments + 1, count do
            segments[i] = makeSegment(frame, color, thickness)
        end
        for i = count + 1, #segments do
            segments[i]:Hide()
        end
        instance._count = count
        instance._spacing = geo.perimeter / count
    end

    local function place()
        for i = 1, instance._count do
            local seg = segments[i]
            local dist = (instance._spacing * (i - 1) + timer * speed)
            local x, y, orient = pointAt(dist)
            seg:ClearAllPoints()
            if orient == "h" then
                seg:SetSize(segLen, thickness)
            else
                seg:SetSize(thickness, segLen)
            end
            seg:SetPoint("CENTER", frame, "BOTTOMLEFT", x, y)
            seg:Show()
        end
    end

    function instance:start()
        measure()
        if geo.perimeter == 0 then return end
        layout()
        timer = 0
        place()
        frame:Show()
        frame:SetScript("OnUpdate", function(_, dt)
            timer = timer + dt
            place()
        end)
    end

    function instance:stop()
        frame:SetScript("OnUpdate", nil)
        frame:Hide()
    end

    function instance:setColor(r, g, b)
        color = { r = r, g = g, b = b }
        for _, seg in ipairs(segments) do
            seg:SetColorTexture(r, g, b, 1)
        end
    end

    function instance:isRunning()
        return frame:GetScript("OnUpdate") ~= nil
    end

    return instance
end

Addon.marchingBorder = marchingBorder

return marchingBorder
