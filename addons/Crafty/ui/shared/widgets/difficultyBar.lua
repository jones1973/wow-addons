--[[
  ui/shared/widgets/difficultyBar.lua   [SHARED: pending sync to monorepo shared/]
  DifficultyBar — where a recipe sits in its color progression

  The game tells you a recipe is "yellow" and hides everything else: how far
  into yellow you are, and how close green is. This bar shows it. The filled
  portion is the current band's color and grows as you level through the band;
  the track ahead is tinted the NEXT band's color, so you literally see the
  color you are heading into before you reach it.

  Fed a difficulty:transition() result:
    { band, nextBand, nextAt, toNext, progress }
  progress (0..1) drives the fill; band and nextBand drive the two colors.
  A grey band (no next break) fills fully in grey with no lead-in. A nil or
  unavailable transition hides the bar.

  Usage:
    local bar = Addon.difficultyBar:create(parent, {
        width = 180, height = 10,
        anchor = { "TOPLEFT", someFrame, "BOTTOMLEFT", 0, -6 },
    })
    bar:show(transition)   -- a difficulty:transition() table, or nil to hide
    bar:hide()

  Dependencies: theme, difficulty
  Exports: Addon.difficultyBar
]]

local ADDON_NAME, Addon = ...

local difficultyBar = {}

local DEFAULT_W, DEFAULT_H = 180, 10

function difficultyBar:create(parent, opts)
    if not parent then error("difficultyBar:create requires a parent") end
    opts = opts or {}

    local theme      = Addon.theme
    local difficulty = Addon.difficulty

    local width  = opts.width  or DEFAULT_W
    local height = opts.height or DEFAULT_H

    local instance = {}

    -- The frame stacks: a dark trough, a "next band" lead-in wash over the
    -- whole track, then the current-band fill over the filled portion, then a
    -- label. Ordering by draw layer keeps the fill above the lead-in.
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(width, height + 16)   -- bar + label beneath
    if opts.anchor then
        frame:SetPoint(unpack(opts.anchor))
    end

    local trough = frame:CreateTexture(nil, "BACKGROUND")
    trough:SetPoint("TOPLEFT")
    trough:SetSize(width, height)
    local tb = theme.tokens.SURFACE.PANEL_RAISED
    trough:SetColorTexture(tb.r, tb.g, tb.b, 1)

    -- The next-band lead-in: fills the whole track faintly, so the unfilled
    -- remainder reads as "the color you are heading toward".
    local lead = frame:CreateTexture(nil, "ARTWORK")
    lead:SetPoint("TOPLEFT")
    lead:SetSize(width, height)

    -- The current-band fill, sized to progress.
    local fill = frame:CreateTexture(nil, "OVERLAY")
    fill:SetPoint("TOPLEFT")
    fill:SetSize(1, height)

    -- A hairline border so the bar reads as a contained element.
    local edge = CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
    edge:SetPoint("TOPLEFT", -1, 1)
    edge:SetPoint("BOTTOMRIGHT", trough, "BOTTOMRIGHT", 1, -1)
    edge:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    local nb = theme.tokens.NEUTRAL.L4
    edge:SetBackdropBorderColor(nb.r, nb.g, nb.b, 1)

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", trough, "BOTTOMLEFT", 0, -3)
    label:SetJustifyH("LEFT")

    -- Present the progression, or hide if there is nothing to show.
    function instance:show(tr)
        if not tr or tr.band == difficulty.UNAVAILABLE then
            frame:Hide()
            return
        end

        local cr, cg, cb = difficulty:colorForBand(tr.band)

        -- Fill: the current band's color, grown to progress. A band with no
        -- measurable span (or grey) fills fully.
        local p = tr.progress or (tr.nextBand and 0 or 1)
        fill:SetSize(math.max(1, width * p), height)
        fill:SetColorTexture(cr, cg, cb, 0.95)

        -- Lead-in: the next band's color, faint, across the whole track - the
        -- destination shown before arrival. None when grey (no next band).
        if tr.nextBand then
            local nr, ng, nbv = difficulty:colorForBand(tr.nextBand)
            lead:SetColorTexture(nr, ng, nbv, 0.22)
            lead:Show()
        else
            lead:Hide()
        end

        -- Label: visual first, this is the supporting detail. Honest about
        -- certainty - skill-ups are only guaranteed at orange.
        if tr.nextBand and tr.toNext then
            local nbName = tr.nextBand:gsub("^%l", string.upper)
            label:SetFormattedText("%d to %s", tr.toNext, nbName)
            label:SetTextColor(cr, cg, cb)
        else
            label:SetText("Maxed for skill-ups")
            label:SetTextColor(cr, cg, cb)
        end

        frame:Show()
    end

    function instance:hide()
        frame:Hide()
    end

    frame:Hide()
    return instance
end

Addon.difficultyBar = difficultyBar

return difficultyBar
