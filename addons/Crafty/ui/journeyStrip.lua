--[[
  ui/journeyStrip.lua
  Journey Strip Component

  The window-level breadcrumb of a crafting detour: "I'm making X; X needs B;
  I've gone to make B." The journey spans professions by definition, so it
  lives in the window's own geometry - a strip in the reserved lane above the
  panels, height 0 when no journey exists, springing open within the lane on
  the first detour. The panels below hold a fixed top edge; the strip grows
  upward into the lane rather than pushing them.

  The chain reads as the journey, left to right: the ROOT GOAL leftmost, each
  new side quest entering at the right end and shoving the whole chain
  leftward to make room - the newest crumb always nearest where you stand.
  Clicking a crumb returns to it (everything nearer is popped); the X at the
  far-right terminal abandons the whole journey - it removes the guidance,
  not your position.

  Crumbs speak the acknowledgment hop: nodCrumb(level) when a level's debt
  is paid.

  Usage:
    local strip = Addon.journeyStrip:create({
        parent   = frame,
        onHeight = function(h) ... end,     -- optional: observe the strip height
        onReturn = function(level) ... end, -- crumb clicked: go back there
        onDismiss = function() ... end,     -- X clicked: abandon the journey
        backdrop = backdropTable,
        motionSeconds = 0.35,
    })
    strip:push({ icon = tex, name = "Living Steel Barbute" })
    strip:popTo(level)   -- returning to a crumb consumes it and all above
    strip:clear()
    strip:nodCrumb(level)
    strip:getFrame()

  Dependencies: motion, theme
  Exports: Addon.journeyStrip
]]

local ADDON_NAME, Addon = ...

local journeyStrip = {}

local STRIP_H     = 28
local CRUMB_H     = 22
local CRUMB_GAP   = 6
local ICON_SIZE   = 16
local EDGE_PAD    = 8

function journeyStrip:create(config)
    local motion = Addon.motion
    local ease   = motion.ease
    local theme  = Addon.theme
    local tint   = theme.derive.tint

    local MOTION = config.motionSeconds

    local instance = {}
    local crumbs = {}   -- level (1 = root) -> crumb button

    -- onHeight is an optional observer fired each animation frame with the
    -- strip's current height, for a parent that wants to track it. A parent
    -- that reserves a fixed lane for the strip does not, so it defaults to a
    -- no-op - cleaner than guarding the three per-frame call sites.
    local onHeight = config.onHeight or function() end

    local strip = CreateFrame("Frame", nil, config.parent, "BackdropTemplate")
    strip:SetBackdrop(config.backdrop)
    -- Slate wash: the journey trail is the cool structural counterpoint to the
    -- warm work surfaces. Over the dark window this reads as a distinct band.
    local ss = theme.tokens.BRAND.SECONDARY_TINT_HIGH
    strip:SetBackdropColor(ss.r, ss.g, ss.b, ss.a)
    strip:SetHeight(0)
    strip:SetClipsChildren(true)
    strip:Hide()

    -- The abandon affordance: far-right terminal, past the newest crumb.
    -- Dismissing removes the guidance, never your position.
    local dismiss = CreateFrame("Button", nil, strip)
    dismiss:SetSize(16, 16)
    dismiss:SetPoint("RIGHT", strip, "RIGHT", -EDGE_PAD, 0)
    local dtex = dismiss:CreateTexture(nil, "ARTWORK")
    dtex:SetAllPoints()
    Addon.icons.apply(dtex, "close", theme.crafty.TEXT.DISABLED)
    dismiss:SetScript("OnEnter", function(self)
        Addon.tooltip:show(self, { anchor = "bottom" })
        Addon.tooltip:header("Abandon journey")
        Addon.tooltip:row("", "Clears the breadcrumb; you stay where you are")
        Addon.tooltip:done()
    end)
    dismiss:SetScript("OnLeave", function() Addon.tooltip:hide() end)
    dismiss:SetScript("OnClick", function()
        if config.onDismiss then config.onDismiss() end
    end)

    -- ------------------------------------------------------------------
    -- The spring
    -- ------------------------------------------------------------------

    local function animateHeight(target)
        local from = strip:GetHeight()
        if math.abs(target - from) < 0.5 then
            -- Snapping while a spring is in flight (clear-then-reopen in one
            -- click) must kill the spring, or it resumes toward its stale
            -- target next frame and closes the strip over the new chain.
            motion:stop(strip)
            strip:SetHeight(target)
            onHeight(target)
            strip:SetShown(target > 0)
            return
        end
        strip:Show()
        motion:run(strip, function(elapsed)
            local t = elapsed / MOTION
            if t >= 1 then
                strip:SetHeight(target)
                onHeight(target)
                strip:SetShown(target > 0)
                return true
            end
            local h = from + (target - from) * ease.outQuad(t)
            strip:SetHeight(h)
            onHeight(h)
        end)
    end

    -- ------------------------------------------------------------------
    -- Crumbs
    -- ------------------------------------------------------------------

    -- Seat a crumb at its x (LEFT-relative), the one anchor writer.
    local function placeCrumb(crumb, x, dy)
        crumb.x = x
        crumb:ClearAllPoints()
        crumb:SetPoint("LEFT", strip, "LEFT", x, dy or 0)
    end

    -- The chain is right-anchored: the newest crumb sits just left of the X,
    -- each older one further left, the root furthest out. Returns each
    -- crumb's target x, computed from the right edge inward.
    local function chainTargets()
        local targets = {}
        local xRight = strip:GetWidth() - EDGE_PAD - 16 - CRUMB_GAP   -- left of the X
        for level = #crumbs, 1, -1 do
            local w = crumbs[level]:GetWidth()
            targets[level] = xRight - w
            xRight = xRight - w - CRUMB_GAP
        end
        return targets
    end

    local function makeCrumb(entry)
        local crumb = CreateFrame("Button", nil, strip, "BackdropTemplate")
        crumb:SetBackdrop(config.backdrop)
        local cs = theme.crafty.SURFACE.PANEL
        crumb:SetBackdropColor(cs.r, cs.g, cs.b, 1)
        local nb = theme.tokens.NEUTRAL.L4
        crumb:SetBackdropBorderColor(nb.r, nb.g, nb.b, 1)
        crumb:SetHeight(CRUMB_H)
        crumb.x = 0

        local hl = crumb:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.05)

        local icon = crumb:CreateTexture(nil, "ARTWORK")
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon:SetPoint("LEFT", crumb, "LEFT", 4, 0)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:SetTexture(entry.icon or "Interface\\Icons\\INV_Misc_QuestionMark")

        local name = crumb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        name:SetPoint("LEFT", icon, "RIGHT", 4, 0)
        name:SetJustifyH("LEFT")
        name:SetWordWrap(false)
        name:SetText(entry.name or "")
        tint(name, theme.crafty.TEXT.LABEL)
        -- Full names: the strip has the room, and a truncated crumb defeats
        -- its purpose. A very deep chain pushes the root off the left edge
        -- (clipped by the strip) - which is the design reading anyway: the
        -- root gets pushed further out as the journey deepens.
        local nameW = name:GetStringWidth()
        name:SetWidth(nameW)

        crumb:SetWidth(4 + ICON_SIZE + 4 + nameW + 6)

        crumb:SetScript("OnEnter", function(self)
            Addon.tooltip:show(self, { anchor = "bottom" })
            Addon.tooltip:header(entry.name or "")
            Addon.tooltip:row("", "Return to this recipe")
            Addon.tooltip:done()
        end)
        crumb:SetScript("OnLeave", function() Addon.tooltip:hide() end)
        crumb:SetScript("OnClick", function(self)
            if config.onReturn and self.level then config.onReturn(self.level) end
        end)
        return crumb
    end

    -- A quick leftward scoot with a small overshoot-recoil - the chain being
    -- shoved by the newcomer pushing its way in at the right end.
    local function scootCrumbTo(crumb, toX)
        local fromX = crumb.x
        if math.abs(toX - fromX) < 0.5 then
            placeCrumb(crumb, toX)
            return
        end
        local over = toX + (toX >= fromX and 2 or -2)
        motion:run(crumb, function(elapsed)
            local t = elapsed / 0.2
            if t >= 1 then
                placeCrumb(crumb, toX)
                return true
            end
            local x
            if t < 0.7 then
                x = fromX + (over - fromX) * ease.outCubic(t / 0.7)
            else
                x = over - (over - toX) * ((t - 0.7) / 0.3)
            end
            placeCrumb(crumb, x)
        end)
    end

    -- Lay every crumb out at its chain position (snap; resizes and pops).
    local function layoutChain()
        for level, crumb in pairs(crumbs) do crumb.level = level end
        local targets = chainTargets()
        for level, crumb in ipairs(crumbs) do
            placeCrumb(crumb, targets[level])
        end
    end

    strip:SetScript("OnSizeChanged", function(_, w)
        if w and w > 0 and #crumbs > 0 then layoutChain() end
    end)

    -- ------------------------------------------------------------------
    -- API
    -- ------------------------------------------------------------------

    -- A new side quest pushes its way in at the right end: the chain scoots
    -- left to make room and the newcomer slides in from beyond the X.
    function instance:push(entry)
        local crumb = makeCrumb(entry)
        crumbs[#crumbs + 1] = crumb
        crumb.level = #crumbs

        local targets = chainTargets()
        for level, c in ipairs(crumbs) do
            if c ~= crumb then
                scootCrumbTo(c, targets[level])
            end
        end
        -- The newcomer enters from off the right edge and settles into the
        -- slot the chain just vacated.
        placeCrumb(crumb, strip:GetWidth() + 4)
        local toX = targets[#crumbs]
        motion:run(crumb, function(elapsed)
            local t = elapsed / 0.3
            if t >= 1 then
                placeCrumb(crumb, toX)
                return true
            end
            placeCrumb(crumb, crumb.x + (toX - crumb.x) * ease.outCubic(t))
        end)

        if #crumbs == 1 then animateHeight(STRIP_H) end
        return #crumbs
    end

    -- Returning to a crumb consumes it and everything nearer: you are back
    -- at that level, so it is your position again, not a promise.
    function instance:popTo(level)
        for i = #crumbs, level, -1 do
            crumbs[i]:Hide()
            crumbs[i] = nil
        end
        if #crumbs == 0 then
            animateHeight(0)
        else
            layoutChain()
        end
    end

    function instance:clear()
        for i = #crumbs, 1, -1 do
            crumbs[i]:Hide()
            crumbs[i] = nil
        end
        animateHeight(0)
    end

    -- The debt-paid acknowledgment: this level's owed count is covered.
    function instance:nodCrumb(level)
        local crumb = crumbs[level]
        if not crumb then return end
        local baseX = crumb.x
        motion:hop(crumb, function(dy) placeCrumb(crumb, baseX, dy) end)
    end

    function instance:count() return #crumbs end
    function instance:getFrame() return strip end

    return instance
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("journeyStrip", {"motion", "theme", "tooltip"})
end

Addon.journeyStrip = journeyStrip
return journeyStrip
