--[[
  ui/newlyLearnedTray.lua
  Newly-Learned Tray Component

  New recipes land in a tray that springs up from the bottom of the recipe
  list - one consistent place for every discovery. Rows persist for the
  session (the tray is the session's record of what was learned); clicking a
  row selects it, reported out through config.onSelect. Height 0 when empty;
  springs up when discoveries land, and the composer lifts the recipe list's
  bottom by the same amount through config.onHeight - one variable driving
  both frames, so they can never disagree.

  The tray owns the pending set (per profession, learn order) and the arrival
  presentation: the spring, the bloom, and the leaf-fall ghost flight. A
  discovery's row does not appear until its arrival lands: each ghost flies
  to THE ROW ITS RECIPE WILL OCCUPY (tracked live - a burst inserts newer
  rows above mid-flight and the leaf follows its row down), the row stays
  invisible until touchdown, and the bloom fires over that row. Origin
  ATTRIBUTION stays with the composer (it knows the crafter, the selection,
  and the ambient frames); arrive() takes a resolver called at settle time,
  returning the origin frame or nil for a flightless landing (row + bloom at
  settle).

  Tray rows are real recipe rows: config.rowKind supplies the recipe list's
  own row kind (factory/render/height/chrome), so difficulty colors and
  cooldown clocks apply identically in both lists.

  Usage:
    local tray = Addon.newlyLearnedTray:create({
        parent   = panelFrame,
        viewed   = function() return profID end,
        rowKind  = recipePanel:recipeRowKind(),
        onHeight = function(h) ... end,      -- lift the list bottom
        onSelect = function(recipeID) ... end,
        backdrop = backdropTable,
        motionSeconds = 0.35,                -- spring tempo
    })
    Addon.newlyLearnedTray:add(profID, recipeID)
                                    -- record a discovery (dedupe by id);
                                    -- module-level, callable before any
                                    -- window exists
    tray:layout(onSettled)          -- project the viewed profession's pending
                                    -- set; spring to fit, then onSettled
    tray:arrive(recipeID, resolveOrigin)  -- a discovery's full arrival: row
                                          -- hidden, spring, flight from the
                                          -- x,y resolveOrigin() returns in
                                          -- UIParent space (nil = reveal at
                                          -- settle), reveal + bloom on landing
    tray:getFrame()                 -- anchor into the window

  Dependencies: reactiveList, theme, recipeView, difficulty
  Exports: Addon.newlyLearnedTray
]]

local ADDON_NAME, Addon = ...

local newlyLearnedTray = {}

local TRAY_MAX_ROWS       = 3
local TRAY_CAPTION_HEIGHT = 24

-- The pending set lives at MODULE scope, not on the instance: recipes are
-- learned with no window built (trainer, bag item, level-up), and those
-- discoveries must be waiting when the tray is first constructed. The store's
-- lifetime is the session; the frame's is lazy.
local newlyLearned = {}   -- profID -> array of { id = recipeID, seq = n }, learn order
local newlySeq = 0

-- Record a discovery into the pending set (dedupe by id: re-learning a recipe
-- already pending is the same announcement, not a second one). Callable before
-- any tray instance exists.
-- Drop a profession's entire pending set: its announcements die with the
-- profession (unlearn). A relearn starts clean.
function newlyLearnedTray:clear(profID)
    newlyLearned[profID] = nil
end

function newlyLearnedTray:add(profID, recipeID)
    local list = newlyLearned[profID]
    if not list then
        list = {}
        newlyLearned[profID] = list
    end
    for i = 1, #list do
        if list[i].id == recipeID then return end
    end
    newlySeq = newlySeq + 1
    list[#list + 1] = { id = recipeID, seq = newlySeq }
end

function newlyLearnedTray:create(config)
    local theme = Addon.theme
    local tint  = theme.derive.tint

    local viewed   = config.viewed
    local onHeight = config.onHeight
    local ROW_H    = config.rowKind.height
    local MOTION   = config.motionSeconds

    local trayFlash

    -- Arrivals in flight: their rows render INVISIBLE until touchdown - the
    -- landing is what puts the row there. rowByID tracks the live row frame
    -- per recipe (rows are recycled; _trayItemID guards staleness).
    local inFlight = {}
    local rowByID = {}

    -- Ghost frames are pooled: a trainer session learns recipes in quick
    -- succession, and each flight must live out its own physics while later
    -- ones launch. Acquired per launch, released on landing.
    local ghostPool = Addon.pool:new(function()
        local ghost = CreateFrame("Frame", nil, UIParent)
        ghost:SetFrameStrata("DIALOG")
        ghost:SetSize(220, ROW_H)
        local fs = ghost:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("CENTER")
        ghost.text = fs
        return ghost
    end)

    local instance = {}

    -- The tray is its own docked area: bordered, and surfaced at the theme's
    -- recessed stop (L0, one step below the panel base). Contents reveal with
    -- the spring, not before (clipped).
    local trayFrame = CreateFrame("Frame", nil, config.parent, "BackdropTemplate")
    trayFrame:SetBackdrop(config.backdrop)
    local ts = theme.crafty.SURFACE.INSET
    trayFrame:SetBackdropColor(ts.r, ts.g, ts.b, 1)
    trayFrame:SetHeight(0)
    trayFrame:SetClipsChildren(true)

    local trayCaption = trayFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    trayCaption:SetPoint("TOPLEFT", trayFrame, "TOPLEFT", 8, -8)
    tint(trayCaption, theme.tokens.EFFECT.NEW_LEARN_GLOW)
    trayCaption:SetText("Newly Learned")
    trayCaption:Hide()

    -- The recipe list's own row kind, wrapped: identical rows, plus the
    -- arrival veil (a row whose ghost is still airborne stays invisible).
    local trayRowKind = {}
    for k, v in pairs(config.rowKind) do trayRowKind[k] = v end
    trayRowKind.render = function(row, item)
        config.rowKind.render(row, item)
        row._trayItemID = item.id
        rowByID[item.id] = row
        row:SetAlpha(inFlight[item.id] and 0 or 1)
    end

    local trayList = Addon.reactiveList:create({
        parent = trayFrame,
        width  = config.parent:GetWidth(),   -- initial only: the two-corner anchors govern
        height = TRAY_MAX_ROWS * ROW_H,
        sort   = function(a, b) return a.seq > b.seq end,   -- newest learn at the top
        kinds  = { row = trayRowKind },
        -- Tray rows behave like list rows: select and show detail. They do
        -- not dismiss - the tray is the session's record of what was learned.
        onClick = function(item)
            config.onSelect(item.id)
        end,
    })
    trayList:getFrame():SetPoint("TOPLEFT", trayFrame, "TOPLEFT", 4, -TRAY_CAPTION_HEIGHT)
    trayList:getFrame():SetPoint("TOPRIGHT", trayFrame, "TOPRIGHT", -4, -TRAY_CAPTION_HEIGHT)
    trayList:getFrame():Hide()

    -- ------------------------------------------------------------------
    -- Pending set
    -- ------------------------------------------------------------------

    -- The pending newly-learned entries for the viewed profession.
    local function trayEntries()
        local profID = viewed()
        if not profID then return {} end
        local list = newlyLearned[profID]
        if not list then
            list = {}
            newlyLearned[profID] = list
        end
        return list
    end

    -- ------------------------------------------------------------------
    -- The spring
    -- ------------------------------------------------------------------

    -- Set the tray's height and report it out - the composer lifts the recipe
    -- list's bottom by the same amount, so the two can never disagree.
    local function setTrayHeight(h)
        trayFrame:SetHeight(h)
        onHeight(h)
    end

    -- Callbacks waiting for the spring to settle. Discoveries arrive in
    -- bursts (a trainer session), and each layout retargets the ONE spring on
    -- the tray frame - a retarget must fold the newcomer's callback into the
    -- waiting set, not replace the set (replacing dropped the earlier
    -- arrivals' flights). Every settle - retargeted or not - flushes the
    -- whole queue.
    local settleQueue = {}

    -- Fire everything waiting on the settle. Launches are staggered a beat
    -- apart so a burst leaves its origin as a stream of leaves, not one
    -- stacked frame of them.
    local function flushSettleQueue()
        local queue = settleQueue
        settleQueue = {}
        for i, cb in ipairs(queue) do
            if i == 1 then
                cb()
            else
                C_Timer.After((i - 1) * 0.12, cb)
            end
        end
    end

    -- Animate the tray to a target height with an ease-out ramp, then flush
    -- the settle queue. A layout arriving mid-spring replaces the MOTION
    -- (driver semantics), never the queue.
    local function animateTrayHeight(target)
        local from = trayFrame:GetHeight()
        if math.abs(target - from) < 0.5 then
            -- Snapping while a spring is in flight must kill the spring, or
            -- it resumes toward its stale target next frame (the journey
            -- strip's clear-then-reopen bug, same mechanism).
            Addon.motion:stop(trayFrame)
            setTrayHeight(target)
            flushSettleQueue()
            return
        end
        Addon.motion:run(trayFrame, function(elapsed)
            local t = elapsed / MOTION
            if t >= 1 then
                setTrayHeight(target)
                return true
            end
            setTrayHeight(from + (target - from) * Addon.motion.ease.outQuad(t))
        end, flushSettleQueue)
    end

    -- Project the viewed profession's pending set into the tray: contents, then
    -- the spring (height animates between 0 and caption + rows, capped at
    -- TRAY_MAX_ROWS with the list scrolling beyond the cap).
    function instance:layout(onSettled)
        if onSettled then
            settleQueue[#settleQueue + 1] = onSettled
        end
        local entries = trayEntries()
        local n = #entries
        trayList:replaceAll(entries)
        trayCaption:SetShown(n > 0)
        trayList:getFrame():SetShown(n > 0)
        local rows = math.min(n, TRAY_MAX_ROWS)
        trayList:getFrame():SetHeight(rows * ROW_H)
        local target = n == 0 and 0 or (TRAY_CAPTION_HEIGHT + rows * ROW_H + 8)
        animateTrayHeight(target)
    end

    -- ------------------------------------------------------------------
    -- Arrival presentation
    -- ------------------------------------------------------------------

    -- The visible row a recipe occupies (1 = top; newest-first by seq), capped
    -- at the tray's visible rows - arrivals beyond the cap land on the lowest
    -- visible row (their real row sits scrolled away).
    local function rowIndexOf(recipeID)
        local list = trayEntries()
        local me
        for _, e in ipairs(list) do
            if e.id == recipeID then me = e end
        end
        if not me then return nil end
        local idx = 1
        for _, e in ipairs(list) do
            if e.seq > me.seq then idx = idx + 1 end
        end
        return math.min(idx, TRAY_MAX_ROWS)
    end

    -- One-shot arrival bloom over a tray row - fired at an arrival's landing,
    -- over the row the landing just revealed.
    local function flashTrayArrival(rowIdx)
        if not trayFlash then
            trayFlash = CreateFrame("Frame", nil, trayFrame)
            local tex = trayFlash:CreateTexture(nil, "OVERLAY")
            tex:SetTexture("Interface\\SpellActivationOverlay\\IconAlert")
            tex:SetTexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
            tex:SetBlendMode("ADD")
            local g = theme.tokens.EFFECT.NEW_LEARN_GLOW
            tex:SetVertexColor(g.r, g.g, g.b)
            tex:SetAllPoints(trayFlash)
            trayFlash.tex = tex
        end
        local listFrame = trayList:getFrame()
        trayFlash:ClearAllPoints()
        trayFlash:SetPoint("TOP", listFrame, "TOP", 0,
            ROW_H * 0.3 - ((rowIdx or 1) - 1) * ROW_H)
        trayFlash:SetSize(listFrame:GetWidth() * 1.1, ROW_H * 1.6)
        trayFlash:Show()
        Addon.motion:run(trayFlash, function(elapsed)
            local t = elapsed / 0.8
            if t >= 1 then
                trayFlash:Hide()
                return true
            end
            -- Quick rise to full, longer decay to nothing.
            local a = t < 0.2 and (t / 0.2) or (1 - (t - 0.2) / 0.8)
            trayFlash.tex:SetAlpha(a * 0.8)
        end)
    end

    -- An arrival touches down (or settles flightless): the veil lifts - the
    -- row appears - and the bloom fires over it. A landing whose profession
    -- is no longer viewed just clears the veil (its row isn't on screen).
    local function landArrival(recipeID, launchProf)
        inFlight[recipeID] = nil
        if viewed() ~= launchProf then return end
        local idx = rowIndexOf(recipeID)
        local row = rowByID[recipeID]
        if row and row._trayItemID == recipeID then
            row:SetAlpha(1)
        end
        flashTrayArrival(idx)
    end

    -- A discovery's full arrival, owned end to end: the row renders veiled,
    -- the spring makes room, and at settle the origin is resolved - a frame
    -- launches the leaf-fall (the row appears when it LANDS); nil reveals at
    -- settle (bloom included).
    function instance:arrive(recipeID, resolveOrigin)
        inFlight[recipeID] = true
        local launchProf = viewed()
        self:layout(function()
            -- A POINT, not a frame: what learned a recipe is a click, and a
            -- click has a position but not always a frame we can name.
            local fx, fy
            if resolveOrigin then fx, fy = resolveOrigin() end
            if fx then
                self:launchGhost(recipeID, fx, fy, launchProf)
            else
                landArrival(recipeID, launchProf)
            end
        end)
    end

    -- The arrival flight: a ghost of the new recipe floats down from where
    -- the learning came from and settles onto THE ROW ITS RECIPE OCCUPIES -
    -- the target is tracked live each frame, so a burst inserting newer rows
    -- above mid-flight has the leaf follow its row down, and every leaf in
    -- the stream lands on its own row. Each flight flies its own pooled
    -- frame; the per-flight randomization below keeps concurrent leaves from
    -- moving in lockstep.
    function instance:launchGhost(recipeID, fx, fy, launchProf)
        launchProf = launchProf or viewed()
        if not fx then
            landArrival(recipeID, launchProf)
            return
        end

        local ui = UIParent:GetEffectiveScale()

        -- Destination: the recipe's OWN row, in UIParent space, read live
        -- every frame (the row moves as newer arrivals insert above; the
        -- window itself can move mid-flight).
        local listFrame = trayList:getFrame()
        local function rowTarget()
            local cx, cy = listFrame:GetCenter()
            if not cx then return nil end
            local fscale = listFrame:GetEffectiveScale() / ui
            local idx = rowIndexOf(recipeID) or 1
            local top = cy + listFrame:GetHeight() / 2
            return cx * fscale, (top - (idx - 0.5) * ROW_H) * fscale
        end
        local tx, ty = rowTarget()


        local ghost = ghostPool:acquire()
        ghost.text:SetText(Addon.recipeView:name(recipeID))
        local band = Addon.recipeView:band(recipeID)
        if band then
            ghost.text:SetTextColor(Addon.difficulty:colorForBand(band))
        else
            tint(ghost.text, theme.crafty.TEXT.BODY)
        end

        local GHOST_ALPHA = 0.55   -- ghostly: never fully solid

        -- Leaf-fall physics, randomized per flight. A falling leaf flutters: it
        -- glides side to side, descending fastest through the swing's extremes and
        -- hanging at mid-glide. Modeled as a sway oscillation around a centerline
        -- that steers from the origin's x to the tray's x as the descent
        -- progresses (steering tightens near the landing so it settles into the
        -- row). Sway period, amplitude, phase, and fall speed differ every flight;
        -- flight time is emergent from the physics, not a constant. Descent speed
        -- has a floor, so arrival is guaranteed and the handler self-terminates.
        local termV  = 220 + math.random() * 80          -- px/s terminal fall speed
        local omega  = 2.2 + math.random() * 1.2         -- rad/s sway frequency
        local amp    = 16 + math.random() * 18           -- px sway amplitude
        local phase  = math.random() * 2 * math.pi
        local span   = math.abs(ty - fy)
        local x, y   = fx, fy

        ghost:ClearAllPoints()
        ghost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", fx, fy)
        ghost:SetAlpha(GHOST_ALPHA)
        ghost:Show()

        Addon.motion:run(ghost, function(_, dt)
            -- The profession changed under the flight: its row left the
            -- screen. End quietly; the veil clears without a bloom.
            if viewed() ~= launchProf then
                ghostPool:release(ghost)
                inFlight[recipeID] = nil
                return true
            end
            local ntx, nty = rowTarget()
            if ntx then tx, ty = ntx, nty end

            phase = phase + omega * dt
            -- Fastest through the swing extremes, hanging at mid-glide.
            -- Direction reads live: the target row can move mid-flight.
            local dir = (ty <= y) and -1 or 1
            local vy = termV * (0.6 + 0.4 * math.abs(math.cos(phase)))
            y = y + dir * vy * dt

            local remaining = math.abs(ty - y)
            if remaining <= 4 or (dir < 0 and y <= ty) or (dir > 0 and y >= ty) then
                ghostPool:release(ghost)
                landArrival(recipeID, launchProf)   -- the landing IS the row
                return true
            end

            -- Centerline steers toward the tray as the descent progresses; sway
            -- tapers into the landing so the leaf settles rather than skids.
            local progress = span > 0 and (1 - remaining / span) or 1
            local center = fx + (tx - fx) * progress * progress * (3 - 2 * progress)
            local settle = math.min(1, remaining / 60)
            x = center + math.sin(phase) * amp * settle

            ghost:ClearAllPoints()
            ghost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
            -- Steady while drifting, melts over the last stretch of the fall.
            ghost:SetAlpha(remaining > 50 and GHOST_ALPHA or GHOST_ALPHA * (remaining / 50))
        end)
    end

    function instance:getFrame() return trayFrame end

    return instance
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("newlyLearnedTray", {"motion", "pool", "reactiveList", "theme", "recipeView", "difficulty"})
end

Addon.newlyLearnedTray = newlyLearnedTray
return newlyLearnedTray
