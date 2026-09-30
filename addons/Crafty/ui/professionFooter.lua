--[[
  ui/professionFooter.lua
  Where you stand in the PROFESSION, spanning the width of the frame.

  Deliberately not beside the recipe bar. That one is recipe-scoped and lives in
  the detail panel; this is profession-scoped and spans everything, and the
  placement should say which is which. Spanning also means it is ambient rather
  than focal - it is not competing for the eye.

  SCALE. 1 to the profession's CEILING - the whole road, not the current tier's
  cap. A level-1 character's cap is 75; a bar drawn to that would end at the
  first milestone and redraw its whole geometry every tier. No conversion is
  needed: the ceiling carries the racial and learn requirements gate on the
  reported rank, so every number here is already in the scale the player reads.

  HARD STOP. The current tier cap is a real wall - skill will not pass it until
  the next tier is trained - so the road beyond it is shaded rather than drawn
  as open track.

  MARKS. Every tier unlock, plus the next actionable recipe. Each carries its
  own hover, because a tick means something specific and a bar-wide tooltip
  cannot say which one you are pointing at. Tiers are the structure of the road
  and read first; the recipe mark is one stop along it and defers.

  Dependencies: professionProgress, theme, tooltip
  Exports: Addon.professionFooter
]]

local ADDON_NAME, Addon = ...

local progress, theme

local HEIGHT     = 14
local TRACK_H    = 6
local TICK_W     = 2
local HOVER_W    = 9    -- the grab area for a tick, wider than the tick itself

-- A tier is the structure of the road; the next recipe is one stop along it.
-- The tier marks read first, and the recipe mark defers to them.
local TIER_H     = 14
local TIER_W     = 3
local RECIPE_H   = 8

local professionFooter = {}

-- "Requires: 65, Engineering (350)", with either number red when it is not met.
-- Colored inline rather than per-row because the unmet part is a NUMBER inside a
-- sentence, not a cell: tokens carry a `code` for exactly this.
local function needs(value, have, token)
    if have and have >= value then return tostring(value) end
    return "|c" .. token.code .. value .. "|r"
end

local function requirementLine(tier, profName, rank)
    local red = theme.tokens.STATE.DANGER
    local parts = "Requires: "
    if tier.level and tier.level > 0 then
        parts = parts .. needs(tier.level, UnitLevel("player"), red) .. ", "
    end
    return parts .. (profName or "") .. " (" .. needs(tier.rank, rank, red) .. ")"
end

-- Tokens are {r, g, b, a} records, not arrays.
local function paint(tex, token)
    tex:SetColorTexture(token.r, token.g, token.b, token.a)
end

function professionFooter:create(parent)
    local instance = {}
    local profID, model

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetHeight(HEIGHT)

    local track = frame:CreateTexture(nil, "BACKGROUND")
    track:SetHeight(TRACK_H)
    track:SetPoint("LEFT", frame, "LEFT", 0, 0)
    track:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    paint(track, theme.tokens.BAR.BACKGROUND)

    -- Beyond the current cap: shaded, because skill cannot go there until the
    -- next tier is trained. Anchored to the frame's right edge so it follows a
    -- resize; only its left edge is computed.
    local capped = frame:CreateTexture(nil, "ARTWORK")
    capped:SetHeight(TRACK_H)
    capped:SetPoint("RIGHT", frame, "RIGHT", 0, 0)
    paint(capped, theme.crafty.SURFACE.INSET)

    -- The fill is a frame, not a texture: the "where do I stand" tooltip belongs
    -- to the progress itself, and the empty road ahead of the marker should not
    -- answer for it.
    local fill = CreateFrame("Frame", nil, frame)
    fill:SetHeight(TRACK_H)
    fill:SetPoint("LEFT", frame, "LEFT", 0, 0)
    fill:EnableMouse(true)
    fill.tex = fill:CreateTexture(nil, "OVERLAY")
    fill.tex:SetAllPoints(fill)
    paint(fill.tex, theme.tokens.BAR.FILL_DEFAULT)

    -- Ticks are pooled: their count is bounded by the tier ladder plus one, and
    -- a profession switch reuses them rather than leaking a set per switch.
    -- Each is a frame, not a texture, because each carries its own hover.
    local ticks = {}

    local function tickAt(i)
        local t = ticks[i]
        if not t then
            t = CreateFrame("Frame", nil, frame)
            t:SetSize(HOVER_W, TIER_H)
            t:EnableMouse(true)
            t.mark = t:CreateTexture(nil, "OVERLAY")
            t.mark:SetPoint("CENTER", t, "CENTER", 0, 0)
            t:SetScript("OnEnter", function(self)
                Addon.tooltip:show(self, { anchor = "above" })
                if self.tier then
                    -- The trainer's own two lines: what this is, then what it
                    -- takes. The tier's NAME comes from its spell, so no table
                    -- of "Apprentice/Journeyman/..." is needed here.
                    Addon.tooltip:header(GetSpellInfo(self.tier.spell)
                                         or ("Tier at " .. self.tier.rank))
                    Addon.tooltip:text(requirementLine(self.tier, model.profName, model.rank))
                else
                    Addon.tooltip:header(self.title)
                    for _, line in ipairs(self.lines or {}) do
                        -- text(), not row(): a row is two columns and an empty
                        -- left one leaves the value drawn over its neighbour.
                        Addon.tooltip:text(line)
                    end
                end
                Addon.tooltip:done()
            end)
            t:SetScript("OnLeave", function() Addon.tooltip:hide() end)
            ticks[i] = t
        end
        return t
    end

    -- Fraction of the bar a rank sits at. Rank 1 is the left edge, the ceiling
    -- the right.
    local function fractionOf(rank, ceiling)
        if ceiling <= 1 then return 0 end
        return (rank - 1) / (ceiling - 1)
    end

    -- All geometry lives here and nowhere else, so a resize is a re-layout
    -- rather than a rebuild. Ticks sit INSIDE the track: a mark at rank 1 or at
    -- the ceiling would otherwise hang half its width past the padded edge.
    local function layout()
        if not model then return end
        local width = frame:GetWidth()
        if not width or width <= 0 then return end
        local inner = width - TICK_W
        local function xOf(rank)
            return TICK_W / 2 + inner * fractionOf(rank, model.ceiling)
        end

        fill:SetWidth(math.max(1, xOf(model.rank)))

        local capX = xOf(model.cap)
        if model.cap < model.ceiling then
            capped:SetWidth(math.max(1, width - capX))
            capped:Show()
        else
            capped:Hide()
        end

        local n = 0
        local function mark(rank, token, w, h, title, lines, tier)
            n = n + 1
            local t = tickAt(n)
            t.mark:SetSize(w, h)
            paint(t.mark, token)
            t:SetPoint("CENTER", frame, "LEFT", xOf(rank), 0)
            t.title, t.lines, t.tier = title, lines, tier
            t:Show()
        end

        for _, tier in ipairs(model.tiers) do
            local gated = tier.rank > model.cap
            mark(tier.rank,
                 gated and theme.tokens.NEUTRAL.L5 or theme.tokens.NEUTRAL.L7,
                 TIER_W, TIER_H, nil, nil, tier)
        end
        if model.next then
            -- A rank can carry more than one recipe, and naming only the first
            -- would make the others invisible.
            -- Gold: the fill is soft green and the tier marks are light grey,
            -- so neither a brighter grey nor a green would separate from them.
            -- Warm reads as "for you" where a red or amber would read as a
            -- problem.
            mark(model.next.rank, theme.crafty.TEXT.HEADING, TICK_W, RECIPE_H,
                 "Next recipe at " .. model.next.rank, model.next.names)
        end
        for i = n + 1, #ticks do ticks[i]:Hide() end
    end

    frame:SetScript("OnSizeChanged", layout)

    function instance:getFrame() return frame end

    function instance:refresh(newProfID)
        profID = newProfID or profID
        model = profID and progress:forProfession(profID)
        if not model then
            frame:Hide()
            return
        end
        frame:Show()
        layout()
    end

    -- The progress itself: where you stand, and what you have walked past.
    fill:SetScript("OnEnter", function(self)
        if not model then return end
        Addon.tooltip:show(self, { anchor = "above" })
        Addon.tooltip:header(model.rank .. " / " .. model.ceiling)
        if model.cap < model.ceiling then
            Addon.tooltip:row("Cap", tostring(model.cap) .. " until the next tier is trained")
        end
        if #model.missed > 0 then
            -- Behind the marker: requirements already passed and never picked
            -- up. This is the answer to "why am I not getting skill-ups".
            Addon.tooltip:row("Can learn now", tostring(#model.missed))
            for i = 1, math.min(#model.missed, 5) do
                local m = model.missed[i]
                Addon.tooltip:row("  " .. m.rank, m.name .. " (" .. m.how .. ")")
            end
        end
        Addon.tooltip:done()
    end)
    fill:SetScript("OnLeave", function() Addon.tooltip:hide() end)

    return instance
end

function professionFooter:initialize()
    progress = Addon.professionProgress
    theme    = Addon.theme
    return true
end

if Addon.registerModule then
    Addon.registerModule("professionFooter",
        {"professionProgress", "theme", "tooltip"},
        function()
            return professionFooter:initialize()
        end)
end

Addon.professionFooter = professionFooter
return professionFooter
