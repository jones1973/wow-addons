--[[
  ui/difficultyBar.lua
  Difficulty Progression Bar

  A recipe's whole life, at a glance: from the skill where it becomes craftable
  (orange) through the skill where it stops granting points (grey), with the
  character's current skill marked within it. The game shows only today's
  color; this shows the arc and where you stand on it.

  LAYOUT ALONG THE BAR (left to right):
    [ can't-yet cap ][ orange | yellow | green ][ maxed cap ]
  Each tier's PIXEL width is proportional to sqrt(its skill span), so a long
  tier (a 100-point orange) does not crush short ones, while within a tier
  placement is linear. The numbers shown are always real skill values and the
  marker sits at the real skill; only the widths compress. The two caps are a
  FIXED width - "below orange" and "past grey" as visible states.

  MARKER: a downward arrow at the current skill, two copies (light behind,
  dark in front) so it reads on any tier colour.

  LABELS: the tier-boundary skill numbers below the bar, each coloured by the
  tier that starts there; plus the current skill, bright and neutral.

  LENS: an always-on magnifier on the bar, centred over the current skill,
  showing the slice beneath it taller (a vertical magnifier). It clamps within
  the bar ends: near a boundary it pins to the edge, marker riding off-centre.
  Its own sub-component (createLens), since it owns its clip, canvas, segment
  textures and marker, and works in its own coordinate space.

  This is crafting's own component (a recipe-difficulty artifact), not a shared
  widget.

  Usage:
    local bar = Addon.difficultyBar:create(panelRight, {
        anchor = { "TOPLEFT", someFrame, "BOTTOMLEFT", 0, -8 },
        rightInset = 12,   -- distance from parent's right edge
    })
    bar:show(colors, rank)   -- colors = {o,y,g,grey}; rank = current skill
    bar:hide()

  Dependencies: theme, difficulty
  Exports: Addon.difficultyBar
]]

local ADDON_NAME, Addon = ...

local difficultyBar = {}

local BAR_H       = 6
local CAP_W       = 16     -- fixed width of the can't-yet / maxed caps
local MARKER_W    = 3
local LABEL_GAP   = 3
local LENS_PX     = 90     -- lens width (the slice of bar it shows)
local LENS_H      = 16     -- lens height

local ARROW      = "Interface\\ChatFrame\\ChatFrameExpandArrow"
local ARROW_W    = 12
local ARROW_H    = 12

-- A down-pointing arrow marker: two stacked copies of the (right-pointing,
-- rotated) arrow texture - a wider light one behind, a narrower dark one in
-- front - so it reads on any tier colour. Returns a table with place(x, yOff)
-- and hide(). `grow` widens the halo/core pair (the lens uses a larger arrow).
local function makeArrow(parent, anchorRegion, anchorPoint, grow)
    grow = grow or 0
    local edge = parent:CreateTexture(nil, "ARTWORK")
    edge:SetTexture(ARROW)
    edge:SetRotation(-math.pi / 2)   -- right-pointing texture -> points down
    edge:SetVertexColor(1, 1, 1, 1)
    edge:SetSize(ARROW_W + 3 + grow, ARROW_H + 3 + grow)
    local core = parent:CreateTexture(nil, "OVERLAY")
    core:SetTexture(ARROW)
    core:SetRotation(-math.pi / 2)
    core:SetVertexColor(0, 0, 0, 1)
    core:SetSize(ARROW_W + grow, ARROW_H + grow)

    return {
        place = function(x, yOff)
            for _, t in ipairs({ core, edge }) do
                t:ClearAllPoints()
                t:SetPoint("CENTER", anchorRegion, anchorPoint, x, yOff or 0)
                t:Show()
            end
        end,
        hide = function()
            core:Hide(); edge:Hide()
        end,
    }
end

--[[
  The lens sub-component: a fixed frame that sits on the bar, centred over the
  current skill, showing the slice of bar beneath it taller (a vertical
  magnifier). It owns its clip, canvas, per-band textures and marker, and maps
  bar-x into its own interior x. show() is handed the bar geometry it needs.
]]
local function createLens(barFrame, bandColor)
    local lens = CreateFrame("Frame", nil, barFrame, BackdropTemplateMixin and "BackdropTemplate")
    lens:SetFrameStrata("HIGH")
    lens:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    lens:Hide()

    local clip = CreateFrame("Frame", nil, lens)
    clip:SetPoint("TOPLEFT", 3, -3)
    clip:SetPoint("BOTTOMRIGHT", -3, 3)
    clip:SetClipsChildren(true)

    local canvas = CreateFrame("Frame", nil, clip)
    canvas:SetPoint("TOPLEFT", clip, "TOPLEFT", 0, 0)
    canvas:SetPoint("BOTTOMRIGHT", clip, "BOTTOMRIGHT", 0, 0)

    local segs = {}
    local arrow = makeArrow(canvas, canvas, "LEFT", 2)

    local instance = {}

    -- Show the lens for the given bar geometry. skillToX maps a skill to bar-x;
    -- bands is the {from,to,band} list; rank is the current skill.
    function instance:show(width, skillToX, bands, rank)
        local half = LENS_PX / 2
        -- Centre on the current skill's bar-x, clamped so the lens stays on bar.
        local cx = math.max(half, math.min(width - half, skillToX(rank)))
        local lensLo, lensHi = cx - half, cx + half

        lens:SetSize(LENS_PX, LENS_H)
        lens:ClearAllPoints()
        lens:SetPoint("CENTER", barFrame, "TOPLEFT", cx, -BAR_H / 2)

        local innerW = LENS_PX - 6
        -- Map a bar-x into the lens interior [0, innerW].
        local function toLens(barX) return innerW * (barX - lensLo) / (lensHi - lensLo) end

        for i, band in ipairs(bands) do
            local a = math.max(skillToX(band.from), lensLo)
            local b2 = math.min(skillToX(band.to), lensHi)
            local t = segs[i]
            if not t then t = canvas:CreateTexture(nil, "ARTWORK"); segs[i] = t end
            if b2 - a < 1 then
                t:Hide()
            else
                local lx = toLens(a)
                t:ClearAllPoints()
                t:SetPoint("TOPLEFT", canvas, "TOPLEFT", lx, 0)
                t:SetPoint("BOTTOMLEFT", canvas, "BOTTOMLEFT", lx, 0)
                t:SetWidth(toLens(b2) - lx)
                local r, gg, b = bandColor(band.band)
                t:SetColorTexture(r, gg, b, 0.95)
                t:Show()
            end
        end
        for i = #bands + 1, #segs do segs[i]:Hide() end

        -- The marker, kept fully inside so it never clips at an edge (at skill
        -- == bar start it maps to x=0 and would render half off the border).
        local mkBarX = skillToX(rank)
        if mkBarX >= lensLo and mkBarX <= lensHi then
            local halfMk = (MARKER_W + 5) / 2
            local mkx = math.max(halfMk, math.min(innerW - halfMk, toLens(mkBarX)))
            arrow.place(mkx, 0)
        else
            arrow.hide()
        end

        lens:Show()
    end

    function instance:hide() lens:Hide() end

    return instance
end

function difficultyBar:create(parent, opts)
    if not parent then error("difficultyBar:create requires a parent") end
    opts = opts or {}

    local theme      = Addon.theme
    local difficulty = Addon.difficulty
    local rightInset = opts.rightInset or 12
    local function bandColor(band) return difficulty:colorForBand(band) end

    local instance = {}

    -- Full-width frame: left anchor from opts, right edge to the parent. Height
    -- is the bar plus a gap plus the row of number labels beneath it.
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(BAR_H + LABEL_GAP + 9)
    if opts.anchor then frame:SetPoint(unpack(opts.anchor)) end
    frame:SetPoint("RIGHT", parent, "RIGHT", -rightInset, 0)

    -- Trough behind everything (bar height only).
    local trough = frame:CreateTexture(nil, "BACKGROUND")
    trough:SetPoint("TOPLEFT")
    trough:SetPoint("TOPRIGHT")
    trough:SetHeight(BAR_H)
    local tb = theme.crafty.SURFACE.FILTER_BAR
    trough:SetColorTexture(tb.r, tb.g, tb.b, 1)

    -- Three band segments and two caps, sized on show.
    local capLeft  = frame:CreateTexture(nil, "ARTWORK")
    local capRight = frame:CreateTexture(nil, "ARTWORK")
    local segO = frame:CreateTexture(nil, "ARTWORK")
    local segY = frame:CreateTexture(nil, "ARTWORK")
    local segG = frame:CreateTexture(nil, "ARTWORK")

    -- The caps carry meaning: LEFT is "can't yet" (below orange) in the
    -- unavailable red; RIGHT is "maxed" (past grey) in grey. Muted so the
    -- colour span between them leads the eye.
    local capLeftColor  = theme.tokens.DIFFICULTY.UNAVAILABLE
    local capRightColor = theme.tokens.DIFFICULTY.GREY

    local marker = makeArrow(frame, frame, "TOPLEFT", 0)

    -- Boundary labels (pooled) and the current-skill label.
    local boundaryLabels = {}
    local function boundaryLabel(i)
        if not boundaryLabels[i] then
            local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetFont(fs:GetFont(), 10)
            boundaryLabels[i] = fs
        end
        return boundaryLabels[i]
    end
    local currentLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    currentLabel:SetFont(currentLabel:GetFont(), 12)

    -- Border hugs the bar only, not the label row beneath it.
    local edge = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
    edge:SetPoint("TOPLEFT", -1, 1)
    edge:SetPoint("TOPRIGHT", 1, 1)
    edge:SetHeight(BAR_H + 2)
    edge:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    local nb = theme.tokens.NEUTRAL.L4
    edge:SetBackdropBorderColor(nb.r, nb.g, nb.b, 1)

    local lens = createLens(frame, bandColor)

    -- Geometry for the current render, filled by show(): tier boundaries and
    -- each tier's pixel range under the sqrt-width layout.
    local G = nil

    -- Build the sqrt-per-section layout: each tier's pixel width is
    -- proportional to sqrt(its skill span), so a long tier does not crush short
    -- ones. Fills G.bounds - {lo, hi, xLo, xHi} per tier - across [CAP_W,
    -- width-CAP_W]. Empty for a single-point recipe (total span zero).
    local function layoutSections()
        local span = G.width - 2 * CAP_W
        local tiers = {
            { lo = G.o, hi = G.y },
            { lo = G.y, hi = G.g },
            { lo = G.g, hi = G.grey },
        }
        local totalW = 0
        for _, t in ipairs(tiers) do
            t.w = math.sqrt(math.max(0, t.hi - t.lo))
            totalW = totalW + t.w
        end
        G.bounds = {}
        if totalW == 0 then return end
        local x = CAP_W
        for _, t in ipairs(tiers) do
            local w = span * (t.w / totalW)
            G.bounds[#G.bounds + 1] = { lo = t.lo, hi = t.hi, xLo = x, xHi = x + w }
            x = x + w
        end
    end

    -- Map a skill to an x-offset in the bar, honouring the sqrt layout: find
    -- the tier it falls in, place linearly within that tier's pixel range.
    local function skillToX(skill)
        if not G.bounds or #G.bounds == 0 then return CAP_W end
        if skill <= G.o then return G.bounds[1].xLo end
        if skill >= G.grey then return G.bounds[#G.bounds].xHi end
        for _, b in ipairs(G.bounds) do
            if skill >= b.lo and skill <= b.hi then
                if b.hi == b.lo then return b.xLo end
                return b.xLo + (b.xHi - b.xLo) * (skill - b.lo) / (b.hi - b.lo)
            end
        end
        return G.bounds[#G.bounds].xHi
    end

    -- The three bands, as {from, to, band} - the shared description the bar
    -- segments, the labels, and the lens all read from.
    local function bandList()
        return {
            { from = G.o, to = G.y,    band = difficulty.ORANGE },
            { from = G.y, to = G.g,    band = difficulty.YELLOW },
            { from = G.g, to = G.grey, band = difficulty.GREEN },
        }
    end

    ----------------------------------------------------------------------------
    -- Render steps, each owning one part of the bar. show() composes them.
    ----------------------------------------------------------------------------

    local function renderCaps()
        capLeft:ClearAllPoints()
        capLeft:SetPoint("TOPLEFT"); capLeft:SetHeight(BAR_H); capLeft:SetWidth(CAP_W)
        capLeft:SetColorTexture(capLeftColor.r, capLeftColor.g, capLeftColor.b, 0.55)
        capRight:ClearAllPoints()
        capRight:SetPoint("TOPRIGHT"); capRight:SetHeight(BAR_H); capRight:SetWidth(CAP_W)
        capRight:SetColorTexture(capRightColor.r, capRightColor.g, capRightColor.b, 0.55)
    end

    local function renderSegments(fillA)
        local tex = { segO, segY, segG }
        for i, band in ipairs(bandList()) do
            local t = tex[i]
            local x1, x2 = skillToX(band.from), skillToX(band.to)
            -- A zero-width band (its thresholds coincide) is skipped, not drawn
            -- as a stray pixel.
            if x2 - x1 < 1 then
                t:Hide()
            else
                t:ClearAllPoints()
                t:SetPoint("TOPLEFT", frame, "TOPLEFT", x1, 0)
                t:SetHeight(BAR_H)
                t:SetWidth(x2 - x1)
                local r, gg, b = bandColor(band.band)
                t:SetColorTexture(r, gg, b, fillA)
                t:Show()
            end
        end
    end

    -- The arrow at the current skill. Returns its x (or nil when not shown), so
    -- the labels can avoid colliding with it. Retired recipes drop it - you
    -- have moved on and the skill is on the card.
    local function renderMarker(rank, retired)
        if not (rank and not retired) then marker.hide(); return nil end
        local markerX = skillToX(rank)
        marker.place(markerX, -ARROW_H / 2 + 3)
        return markerX
    end

    -- Tier-boundary skill numbers below the bar. Normally the four boundaries,
    -- each coloured by the tier occupied at that skill (a zero-width tier never
    -- colours a label - the next real tier does). A single-point recipe
    -- (o==grey) has no tier layout, so its two true endpoints are labelled at
    -- the bar's physical ends instead.
    local function renderBoundaryLabels(markerX)
        local o, grey = G.o, G.grey
        local points
        if grey > o then
            local function startBand(skill)
                return difficulty:bandForSkill(skill, { o, G.y, G.g, grey }) or difficulty.ORANGE
            end
            points = {
                { skill = o,    band = startBand(o), x = skillToX(o) },
                { skill = G.y,  band = startBand(G.y), x = skillToX(G.y) },
                { skill = G.g,  band = startBand(G.g), x = skillToX(G.g) },
                { skill = grey, band = difficulty.GREY, x = skillToX(grey) },
            }
        else
            points = {
                { skill = o,    band = difficulty.GREY, x = CAP_W },
                { skill = grey, band = difficulty.GREY, x = G.width - CAP_W },
            }
        end

        local shown, lastX = 0, nil
        for _, pt in ipairs(points) do
            -- Skip a label on the same x as the previous (collapsed tiers) or
            -- too close to the current-skill label.
            local dupe = lastX and math.abs(pt.x - lastX) < 10
            if not dupe and not (markerX and math.abs(pt.x - markerX) < 14) then
                shown = shown + 1
                local fs = boundaryLabel(shown)
                fs:SetText(tostring(pt.skill))
                local r, gg, b = bandColor(pt.band)
                if r then fs:SetTextColor(r, gg, b) end
                fs:ClearAllPoints()
                fs:SetPoint("TOP", frame, "TOPLEFT", pt.x, -(BAR_H + LABEL_GAP))
                fs:Show()
                lastX = pt.x
            end
        end
        for i = shown + 1, #boundaryLabels do boundaryLabels[i]:Hide() end
    end

    -- The current-skill number: the live value, bright and neutral (it marks
    -- the player, not a tier). Gone when retired, like the marker.
    local function renderCurrentLabel(rank, retired, markerX)
        if rank and not retired then
            local c = theme.crafty.TEXT.VALUE
            currentLabel:SetText(tostring(rank))
            currentLabel:SetTextColor(c.r, c.g, c.b)
            currentLabel:ClearAllPoints()
            currentLabel:SetPoint("TOP", frame, "TOPLEFT", markerX, -(BAR_H + LABEL_GAP))
            currentLabel:Show()
        else
            currentLabel:Hide()
        end
    end

    local function renderLens(rank, retired)
        if rank and not retired and rank >= G.o and rank <= G.grey then
            lens:show(G.width, skillToX, bandList(), rank)
        else
            lens:hide()
        end
    end

    ----------------------------------------------------------------------------

    -- Every section's geometry is computed from the frame's width at show time,
    -- so a resize invalidates all of it. Remembering the inputs makes a resize a
    -- re-show rather than a rebuild.
    local lastShown

    frame:SetScript("OnSizeChanged", function(_, w)
        if lastShown and w and w > 0 then instance:show(lastShown.colors, lastShown.rank) end
    end)

    function instance:show(colors, rank)
        if not colors or not colors[1] then frame:Hide(); return end
        lastShown = { colors = colors, rank = rank }
        local o, y, g, grey = colors[1], colors[2], colors[3], colors[4]

        local width = frame:GetWidth()
        if not width or width <= 0 then
            -- Width not resolved yet (first layout); defer one frame.
            C_Timer.After(0, function() instance:show(colors, rank) end)
            return
        end

        G = { width = width, o = o, y = y, g = g, grey = grey }
        layoutSections()

        -- A retired (grey) recipe can no longer be levelled from: the fill dims
        -- hard so it reads as retired, and the marker/current-label/lens drop.
        local retired = (difficulty:bandForSkill(rank, colors) == difficulty.GREY)
        local fillA = retired and 0.28 or 0.9

        renderCaps()
        renderSegments(fillA)
        local markerX = renderMarker(rank, retired)
        renderBoundaryLabels(markerX)
        renderCurrentLabel(rank, retired, markerX)
        renderLens(rank, retired)

        frame:Show()
    end

    function instance:hide()
        lastShown = nil
        frame:Hide()
        lens:hide()
    end

    instance.frame = frame

    frame:Hide()
    return instance
end

Addon.difficultyBar = difficultyBar

return difficultyBar
