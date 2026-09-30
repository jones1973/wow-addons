--[[
  ui/craftingWindow.lua
  Crafty Crafting Window (composer)

  The crafting-first spine: lists the open profession's known recipes
  (quality-colored), pick one, see its reagents and how many you can make from
  your bags. Current character, current open profession only - cross-character
  and pooled-inventory features hang off this spine in later builds.

  This file is the COMPOSER: it owns the window shell (chrome, titlebar
  status, resize grip, the rail-plus-workspace geometry), the viewed-profession
  and viewed-activity state, the live trade-skill session orchestration, and
  every event subscription - and delegates each region to its component:

    activityRail      the left navigation column: grouped activities
                      (professions, processing, secondary, gathering) and the
                      selected profession's tool shelf
    recipePanel       search, filter bar, sort headers, the recipe list, and
                      the selection (flows out on the events bus)
    detailPanel       the selected recipe's detail + craft controls
                      (renders from the selection event)
    newlyLearnedTray  the discovery tray under the list

  A rail selection is routed by activity kind: a profession runs the profession
  spine (session, scan, list); a processing verb (milling / prospecting /
  disenchanting) has no window yet and raises the placeholder over the
  workspace until its phase lands.

  UI layer only: frames and rendering. All data comes from the ledger,
  activityModel, and craftability logic modules; no scanning or math here.

  Dependencies: events, ledger, professionHarvester, professionWindow,
                recipeScanner, crafter, filterRegistry, recipeView, theme,
                contextMenu, tooltip, utils, activityModel, activityRail,
                newlyLearnedTray, recipePanel, detailPanel
  Exports: Addon.craftingWindow
]]

local ADDON_NAME, Addon = ...

local craftingWindow = {}

local events, ledger, utils, theme, recipeView

-- Component handles, built lazily on first show.
local mainFrame
local rail, recipePanel, detailPanel, tray, journeyStrip
local detailFrame   -- the detail pane frame; the customize drawer overlays it
local placeholder   -- workspace overlay shown while a not-yet-built activity
                    -- (a processing verb) is the viewed one; hidden for a
                    -- profession. Composer-owned scaffolding; each processing
                    -- phase removes its case as it builds the real destination.

-- The activity the rail highlights - the display truth for the rail, distinct
-- from viewedProfID (the profession spine's truth). For a profession activity
-- the two agree ("prof:"..profID); for a processing activity this holds the
-- model's activity id while viewedProfID keeps whatever profession session is
-- live in the background. The rail reads this through viewedActivityId().
local viewedActID

-- The crafting journey: a stack of detours. Each level records where the
-- traveler LEFT (to return to) and what they left to get (the owed reagent,
-- for the debt-paid nod). Window-level state - a journey spans professions
-- by definition.
local journey = {}

-- A navigation whose target profession must first be selected and scanned:
-- the scan-driven repopulate applies this instead of its default pick.
local pendingNav

-- The errand currently stood upon: where a journey navigation landed and the
-- debt it landed there to cover. Wandering off it (any selection that is not
-- a journey move) while the debt is UNPAID converts this position into a
-- crumb - the promise survives the wander. Wandering off paid is completion:
-- no crumb, the errand is done.
local journeyArrival

-- True while a selection is a journey move (navigation, return, or the
-- default pick a pending cross-profession navigation immediately replaces):
-- journey moves are never wanders.
local suppressWander

-- The profession currently being VIEWED - the display truth. Set by a block
-- pick or by adopting an externally-opened window. This is distinct from what
-- is actually open in the game (read live via
-- professionWindow:liveOpenProfID); the two are kept equal in the steady
-- state by eager opens, but viewed is a display fact that can outlive or
-- precede an open window (e.g. a future cross-character view of stored
-- recipes has no open window at all). Declared among the forwards: navigateTo
-- below compares against it.
local viewedProfID

local footer

local selectProfession       -- forward: navigateTo below crosses professions
local unlearnInFlightProfID  -- confirm-click through removal-event: while an
                             -- unlearn is in flight, the departure choreography
                             -- owns the band - adoption and the event tail may
                             -- establish sessions and repaint facts, but never
                             -- swap (the early-swap failure: the successor's
                             -- window opens before the server confirms the
                             -- removal, and any full adoption/refresh in that
                             -- window performs the swap ahead of the retire)
local returnToJourneyLevel   -- forward: the strip's onReturn is wired at build

-- Go to a recipe, crossing professions when needed. Same profession: a
-- straight select. Different: the full band swap runs and the scan-driven
-- repopulate applies the pending navigation instead of its default pick -
-- the journey is visible, not teleported.
-- A crumb's face: recipes show themselves, a conversion target shows the item
-- being converted for.
local function crumbFor(id, kind)
    if kind == "convert" then
        return { icon = C_Item.GetItemIconByID(id), name = recipeView:itemName(id) }
    end
    return { icon = recipeView:icon(id), name = recipeView:name(id) }
end

-- Go to a selection - a recipe, or a conversion target (the pigment/gem a
-- reagent click declared). Same door either way: the kind rides the one
-- selection path.
local function navigateTo(profID, id, kind, prefill, errand)
    journeyArrival = errand and {
        profID   = profID,
        recipeID = id,
        kind     = kind,
        itemID   = errand.itemID,
        owed     = errand.owed,
    } or nil
    if profID == viewedProfID then
        suppressWander = true
        -- Unconditionally, so a visit with no errand clears the last one's.
        -- The TOTAL owed, not the shortfall: the panel derives the shortfall
        -- from the bags so it stays true as pigment arrives.
        if kind == "convert" then
            detailPanel:setConversionErrand(errand and errand.owed)
        end
        recipePanel:select(id, kind)
        suppressWander = false
        if prefill then detailPanel:prefillQuantity(prefill) end
    else
        -- The errand's total rides along: a cross-profession detour resumes
        -- here, and without it the conversion view would arrive with no goal.
        pendingNav = { profID = profID, recipeID = id, kind = kind,
                       prefill = prefill, owed = errand and errand.owed }
        selectProfession(profID)
    end
end

-- Return to a journey level: everything nearer is popped (you are back
-- there; it is your position again, not a promise).
returnToJourneyLevel = function(level)
    local target = journey[level]
    if not target then return end
    for i = #journey, level, -1 do journey[i] = nil end
    journeyStrip:popTo(level)
    -- The crumb's own errand (if it had one) is stood upon again.
    navigateTo(target.profID, target.recipeID, target.kind, target.quantity,
        target.itemID and { itemID = target.itemID, owed = target.owed } or nil)
end

-- Window geometry.
local FOOTER_STRIP = 18   -- the footer's height plus the gap above it
-- The rail (fixed) sits left of the list+detail workspace, so the window is
-- wider than the old top-band layout by the rail's width plus its gap. The
-- default gives the detail pane the room it had before the rail existed.
local FRAME_WIDTH  = 1248
local FRAME_HEIGHT = 560
-- How far the grip may take it. Named because a restored size is clamped to
-- the same range: a saved 1200 that outgrew a later ceiling would otherwise be
-- silently rounded down with nothing to explain it.
local FRAME_MIN_W, FRAME_MIN_H = 986, 400
local FRAME_MAX_W, FRAME_MAX_H = 1440, 900
-- Workspace split. The list takes this fraction of the space beside the rail,
-- clamped so neither pane starves: the list never below LIST_MIN (skill + name
-- columns), the detail never below DETAIL_MIN (recipe name, reagents, craft
-- button). FRAME_MIN_W is the width at which both floors are exactly met, so
-- the grip can never crush a pane.
local LIST_FRACTION = 0.54
local LIST_MIN      = 360
local DETAIL_MIN    = 380
local PANEL_PADDING = 12
local PANEL_GAP     = 6

-- One tempo for every workhorse motion (band slides, tray spring).
local MOTION_SECONDS = 0.35

-- Inset panel backdrop (tooltip-style), shared with the band's blocks and the
-- tray; the main frame's chrome comes from theme.style:skinWindowChrome.
-- The panel material's backdrop shape lives in the theme (theme.crafty.
-- PANEL_BACKDROP), shared by every pane - rail, list, detail, drawer - so the
-- shape is defined once. Aliased locally for the several uses below.
local BACKDROP_PANEL = Addon.theme.crafty.PANEL_BACKDROP

-- The journey strip is a breadcrumb trail, not an input: fill only, no edge
-- box, so its empty stretch never reads as a place to type. Its crumb chips
-- carry their own borders. Its fill is the slate secondary - the cool
-- structural counterpoint to the warm work surfaces, deployed here where
-- navigation lives.
local BACKDROP_TRAIL = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true, tileSize = 16,
}

local LOGO_PATH = "Interface\\AddOns\\" .. ADDON_NAME .. "\\textures\\crafty-icon.png"

-- ============================================================================
-- VIEWED PROFESSION (display truth)
-- ============================================================================

--[[
  The viewed profession's profID (display truth). Pure read: returns the current
  viewedProfID if it is still a real profession, else the first profession - WITHOUT
  writing. viewedProfID is only ever assigned by deliberate events (initViewed,
  block pick, adopt), never as a side effect of reading.

  @return number|nil - profID, or nil if the character has no professions yet
]]
local function viewedProfession()
    -- Windowed only: this chooses what the band shows and the panels render,
    -- and a gathering skill has no window to open or recipes to list.
    local profs = Addon.professionHarvester:enumerate()
    if viewedProfID then
        for _, p in ipairs(profs) do
            if p.profID == viewedProfID and p.windowed then return viewedProfID end
        end
    end
    for _, p in ipairs(profs) do
        if p.windowed then return p.profID end
    end
    return nil
end

-- Deliberately establish viewedProfID from the persisted pick (if still valid)
-- or the first profession. Called at a defined moment (window show), not as a
-- read side effect. Idempotent.
local function initViewedProfession()
    if not viewedProfID then
        viewedProfID = ledger:getViewedProfID()
    end
    viewedProfID = viewedProfession()
end

-- The activity id the rail should highlight. Derived from viewedActID when a
-- processing activity is viewed, else from the viewed profession - a profession
-- activity's id is "prof:"..profID, so the rail lights the right row without
-- the composer tracking a redundant second copy of the profession case.
local function viewedActivityId()
    if viewedActID then return viewedActID end
    local profID = viewedProfession()
    return profID and ("prof:" .. profID) or nil
end

-- Route a rail selection by activity kind. A profession activity flows into the
-- profession spine unchanged; a processing activity has no window to open and
-- no recipe list to scan yet, so it becomes the viewed activity and the
-- workspace shows the placeholder - the profession session held in the
-- background is left untouched, since a later phase will drive the conversion
-- engine off the bags with no profession window at all.
local selectActivity   -- forward: defined once selectProfession exists below

-- The live profession entry for a profID from the castless enumerate, or nil.
-- Name, rank, category and open-name all come live from the game, never storage.
local function liveProfInfo(profID)
    for _, p in ipairs(Addon.professionHarvester:enumerate()) do
        if p.profID == profID then return p end
    end
    return nil
end

local function liveOpenName(profID)
    return liveProfInfo(profID).openName
end

-- ============================================================================
-- LIVE SESSION ORCHESTRATION
-- ============================================================================

-- Open (and hold open) the live trade-skill session for the active profession,
-- and scan it. Opening a profession's window is a blessed action (it follows
-- from the user opening Crafty or selecting the profession), so the scan - which
-- needs the window open - runs here in the ready callback. This is the lazy
-- harvest: each profession is scanned the first time it is made active, instead
-- of auto-cycling every profession from one (possibly unblessed) trigger.
-- audible=true only for the open that accompanies Crafty opening; profession
-- changes pass false so the swap is silent.
local function activateProfession(audible, targetProfID)
    local profID = targetProfID or viewedProfession()
    if not profID then return end
    Addon.professionWindow:beginSession()

    local function scan()
        local info = liveProfInfo(profID)
        Addon.recipeScanner:scanOpen(profID, info.name, info.rank, info.category)
    end

    -- Verify against what's actually open. If the viewed profession's window is
    -- already up, scan it directly: no TRADE_SKILL_SHOW will fire for a window
    -- that is already showing, and re-casting its open-spell would TOGGLE it
    -- closed.
    --
    -- Otherwise open it and scan NOTHING here. The open fires TRADE_SKILL_SHOW,
    -- whose handler scans - "the ready callback" and "the show event" are two
    -- names for the same moment, and scanning on both ran every profession's
    -- walk twice, along with everything subscribed to RECIPES_SCANNED.
    if Addon.professionWindow:liveOpenProfID() == profID then
        scan()
    else
        Addon.professionWindow:open(liveOpenName(profID), nil, audible)
    end
end

-- Close the held trade-skill session. audible=true only when Crafty closes.
local function deactivateProfession(audible)
    Addon.professionWindow:closeCurrent(audible)
    Addon.professionWindow:endSession()
end

-- Unlearn a profession. AbandonSkill takes the SKILL LINE ID - the vendor's
-- own unlearn dialog passes it straight through (Blizzard_StaticPopup_Game,
-- UNLEARN_SKILL) - which is the profID Crafty already holds.
local function unlearnProfession(profID)
    if not AbandonSkill then
        Addon.utils:chat("This client exposes no unlearn call - unlearn from the spellbook; Crafty will follow.")
        return
    end
    AbandonSkill(profID)
    -- This click is the only hardware event in the whole unlearn flow - the
    -- removal event arrives later with no cast privilege. Ride it: swap the
    -- live session to the successor now, so the deferred selection that
    -- follows the server event finds its window already open.
    if mainFrame and mainFrame:IsShown() then
        for _, p in ipairs(Addon.professionHarvester:enumerate()) do
            if p.profID ~= profID and p.windowed then
                unlearnInFlightProfID = profID
                deactivateProfession(false)
                activateProfession(false, p.profID)
                break
            end
        end
    end
end

StaticPopupDialogs["CRAFTY_UNLEARN_PROFESSION"] = {
    text = "Unlearn %s?\n\nAll skill and recipes for it are lost.",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self, data) unlearnProfession(data) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true,
}

-- Make a profession the viewed one: load its saved filter/sort state into the
-- controls and the list, lay the rail out, show its pending discoveries, and
-- swap the live session to it silently.
function selectProfession(value, noSession)
    viewedProfID = value
    -- A profession is a real crafting destination: leave any processing-activity
    -- view and take the placeholder down.
    viewedActID = nil
    if placeholder then placeholder:Hide() end
    ledger:setViewedProfID(value)
    -- The selection belongs to the outgoing profession; the repopulate that
    -- follows this profession's scan re-establishes one.
    recipePanel:resetSelection()
    -- Filters/sort are per character-profession: load this profession's
    -- saved state, push it into the filter-bar controls, and re-project.
    Addon.filterRegistry:restore()
    rail:refresh()
    if footer then footer:refresh(viewedProfID) end
    recipePanel:syncToRegistry()
    tray:layout()   -- show this profession's pending discoveries immediately
    -- Swap the live session to the newly selected profession, silently.
    -- noSession: a selection made from a server-event context (profession
    -- learned/unlearned) has no hardware click in its stack, and the open
    -- spell's CastSpellByName is blocked there. The session activates on the
    -- next real interaction instead, which carries its own privilege.
    if not noSession then
        activateProfession(false)
    else
        -- With no session there is no scan, and the scan handler is the
        -- normal path's list rebuild. The panel's wholesale rebuild is
        -- ledger-driven and needs neither: run it directly. A later
        -- activation's scan refreshes on top.
        recipePanel:repopulate()
    end
end

-- A rail selection, routed by activity kind. Professions run the full spine;
-- processing verbs (no window, no scan) become the viewed activity and raise
-- the placeholder over the workspace. The rail is refreshed either way so the
-- picked row lights immediately.
selectActivity = function(activity)
    if activity.kind == "profession" then
        selectProfession(activity.profID)
    else
        viewedActID = activity.id
        rail:refresh()
        if placeholder then
            placeholder.label:SetText(placeholder.textFor(activity))
            placeholder:Show()
        end
    end
end

-- ============================================================================
-- ARRIVAL ATTRIBUTION (where a learn came from, as a screen frame)
-- ============================================================================

-- The screen frame representing a craft's recipe: its list row, or the detail
-- pane's icon when the recipe is the current selection but its row is not
-- rendered (a Craftable filter can drop the row the moment the craft consumes
-- the last materials).
local function craftOriginFrame(recipeID)
    local row = recipePanel:frameFor(recipeID)
    if row then return row, "row" end
    local selID, selKind = recipePanel:selected()
    if selKind == "recipe" and recipeID == selID then
        local icon = detailPanel:visibleIcon()
        if icon then return icon, "detail" end
    end
    return nil
end

-- Where the learning came from, as a point in UIParent space.
--
-- A click is what learned it, and the cursor is on that click - which the
-- trainer's Learn button, a technique book in the bags, and anything a
-- replacement bag addon draws all have in common. Frame names do not: bags were
-- found through Blizzard's ContainerFrame globals, which Baganator and its like
-- leave hidden, so the bag case silently fell through to the last resort and the
-- flight started inside Crafty.
--
-- A discovery has no click - it arrives a server round-trip after the craft that
-- procced it, with the cursor wherever the player left it - so the craft keeps
-- priority over the cursor rather than being replaced by it.
--
-- Returns x, y, where. Nil when nothing is attributable.
local function pointOf(frame)
    local cx, cy = frame:GetCenter()
    if not cx then return nil end
    local s = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
    return cx * s, cy * s
end

local function learnOriginPoint()
    local recentCraft = Addon.crafter:recentlyCrafted()
    local selected, selectedKind = recipePanel:selected()
    if recentCraft and selected and selectedKind == "recipe" then
        local frame, where = craftOriginFrame(selected)
        if frame then
            local x, y = pointOf(frame)
            if x then return x, y, "craft-fresh " .. where end
        end
    end

    local mx, my = GetCursorPosition()
    if mx then
        local ui = UIParent:GetEffectiveScale()
        return mx / ui, my / ui, "cursor"
    end

    -- Nothing clicked and no craft: a high-latency discovery is the likeliest
    -- story, and the current recipe is still its discoverer.
    if selected then
        local frame, where = craftOriginFrame(selected)
        if frame then
            local x, y = pointOf(frame)
            if x then return x, y, "craft-stale " .. where end
        end
    end
    return nil
end

-- ============================================================================
-- FRAME CONSTRUCTION (lazy)
-- ============================================================================

-- Window geometry survives a reload. Stored as the point itself rather than as
-- screen coordinates: a point is what SetPoint takes back, and it stays correct
-- across a resolution change.
--
-- SIZE TOO, and in the same place: dragging the grip changes both, and a window
-- that came back where you left it but not the size you left it is the odd
-- half-memory.
local function saveGeometry()
    crafty_window = crafty_window or {}
    local point, _, relPoint, x, y = mainFrame:GetPoint()
    crafty_window.pos = { point = point, relPoint = relPoint, x = x, y = y }
    crafty_window.size = { w = mainFrame:GetWidth(), h = mainFrame:GetHeight() }
end

local function restoreGeometry()
    local sz = crafty_window and crafty_window.size
    if sz and sz.w and sz.h then
        -- Clamped, because the bounds are ours to change and a size saved
        -- under the old ones would otherwise be quietly rounded.
        mainFrame:SetSize(
            math.max(FRAME_MIN_W, math.min(FRAME_MAX_W, sz.w)),
            math.max(FRAME_MIN_H, math.min(FRAME_MAX_H, sz.h)))
    else
        mainFrame:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
    end

    local p = crafty_window and crafty_window.pos
    mainFrame:ClearAllPoints()
    if p and p.point then
        mainFrame:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    else
        mainFrame:SetPoint("CENTER")
    end
end

local function buildFrame()
    mainFrame = CreateFrame("Frame", ADDON_NAME .. "MainFrame", UIParent, "BackdropTemplate")
    -- Hide before wiring any lifecycle scripts. A new frame is shown by default,
    -- and the OnHide handler below tears down the trade-skill session (it means
    -- "the user closed Crafty"). Construction is not a user action, so the frame
    -- must reach its resting hidden state BEFORE OnHide exists - otherwise the
    -- shown->hidden transition of starting hidden fires OnHide during the build,
    -- closing a trade window that happens to be open (the first-adopt close bug).
    mainFrame:Hide()
    restoreGeometry()
    mainFrame:SetMovable(true)
    mainFrame:SetResizable(true)
    mainFrame:EnableMouse(true)
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetFrameStrata("HIGH")
    -- Move on mouse-down rather than RegisterForDrag. RegisterForDrag waits for
    -- the cursor to travel a threshold before it calls StartMoving, so the frame
    -- begins moving from a point several pixels from where you pressed and stays
    -- offset by that gap for the whole drag - which is why the grab never feels
    -- like it is where you grabbed. Pressing starts it at the pixel you pressed.
    mainFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then self:StartMoving() end
    end)
    mainFrame:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
            self:StopMovingOrSizing()
            saveGeometry()
        end
    end)

    -- Closing Crafty (close button, ESC, or Hide) closes the held profession
    -- session - this is the close the user hears (audible).
    mainFrame:SetScript("OnHide", function()
        deactivateProfession(true)
    end)

    -- ESC-to-close.
    table.insert(UISpecialFrames, ADDON_NAME .. "MainFrame")

    -- Themed window chrome: stone titlebar tinted with the brand color, a
    -- portrait ring holding Crafty's logo, title, close, and About. The theme
    -- builds all of it and returns contentTop - the Y offset below the titlebar
    -- where body content begins.
    local chrome = theme.style:skinWindowChrome(mainFrame, {
        title   = "Crafty",
        icon    = LOGO_PATH,
        onAbout = function()
            theme.chat:line("Crafty v" ..
                (GetAddOnMetadata and GetAddOnMetadata(ADDON_NAME, "Version") or "0.3.0"))
        end,
    })
    local contentTop = chrome.contentTop

    -- Right-click the addon portrait icon for options (rescan lives here rather
    -- than as a standing button - a rare, deliberate action). The behavior is
    -- attached to the real portrait frame the chrome exposes, so it tracks the
    -- icon's actual position/size with no separate hit region to keep in sync.
    local portrait = chrome.portrait
    if portrait then
        portrait:EnableMouse(true)
        portrait:SetScript("OnMouseUp", function(_, button)
            if button ~= "RightButton" then return end
            local capture = Addon.eventCapture
            Addon.contextMenu:show({
                items = {
                    { text = "Rescan professions", func = function()
                        Addon.professionHarvester:run(true)
                    end },
                    -- The label carries the state: armed, it says what
                    -- stopping would hand back.
                    { text = capture:isArmed()
                            and ("Stop event capture (" .. capture:count() .. ")")
                            or "Start event capture",
                      func = function()
                          if capture:isArmed() then
                              capture:disarm()
                          else
                              capture:arm()
                          end
                      end },
                },
            })
        end)
        portrait:SetScript("OnEnter", function(self)
            Addon.tooltip:show(self, { anchor = "bottom" })
            Addon.tooltip:header("Crafty")
            Addon.tooltip:row("", "Right-click for options")
            Addon.tooltip:done()
        end)
        portrait:SetScript("OnLeave", function() Addon.tooltip:hide() end)
    end

    -- Window-open status in the titlebar: a colored dot plus label, polled once a
    -- second against liveOpenProfID(). Green/"Window open" when a profession
    -- window is genuinely open (the state Crafty holds during a session),
    -- red/"Window closed" otherwise. Anchored left of the close/About cluster.
    if chrome.bar then
        local status = CreateFrame("Frame", nil, chrome.bar)
        status:SetSize(120, 16)
        status:SetPoint("RIGHT", chrome.bar, "RIGHT", -56, 0)

        local dot = status:CreateTexture(nil, "OVERLAY")
        dot:SetTexture("Interface\\Buttons\\WHITE8x8")
        dot:SetSize(8, 8)
        dot:SetPoint("RIGHT", status, "RIGHT", 0, 0)

        local label = status:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("RIGHT", dot, "LEFT", -5, 0)
        label:SetJustifyH("RIGHT")

        local function refreshStatus()
            local open = Addon.professionWindow:liveOpenProfID() ~= nil
            local token = open and theme.tokens.STATE.SUCCESS or theme.tokens.STATE.DANGER
            dot:SetVertexColor(token.r, token.g, token.b)
            label:SetText(open and "Window open" or "Window closed")
            label:SetTextColor(token.r, token.g, token.b)
        end
        refreshStatus()
        -- Poll via OnUpdate on the status frame (a child of the window), throttled
        -- to ~1s. WoW only fires OnUpdate while the frame is shown, so polling runs
        -- only while Crafty is visible and stops automatically when it is hidden -
        -- no free-running timer left ticking after the window closes.
        local elapsed = 0
        status:SetScript("OnUpdate", function(_, dt)
            elapsed = elapsed + dt
            if elapsed >= 1 then
                elapsed = 0
                refreshStatus()
            end
        end)
    end

    -- Resize grip (bottom-right). The chrome does not provide resizing.
    local grip = CreateFrame("Frame", nil, mainFrame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -4, 4)
    grip:EnableMouse(true)
    local gripTex = grip:CreateTexture(nil, "OVERLAY")
    gripTex:SetAllPoints()
    gripTex:SetTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() mainFrame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        mainFrame:StopMovingOrSizing()
        saveGeometry()
    end)
    mainFrame:SetResizeBounds(FRAME_MIN_W, FRAME_MIN_H, FRAME_MAX_W, FRAME_MAX_H)

    -- The titlebar's portrait ring overhangs the top-LEFT of the content area -
    -- over the rail, not the workspace. So the rail's top is lowered to clear
    -- the ring, while the workspace (journey strip, panels) starts high at the
    -- titlebar's content line and keeps its full height.
    --
    -- The titlebar's portrait ring overhangs the top-LEFT of the content area.
    -- Rather than lower only the rail (which reads lopsided), all three columns
    -- start at one lowered line, and the band between the titlebar and that line
    -- is a fixed lane the breadcrumb (journey strip) occupies. The columns never
    -- move; the breadcrumb appears in space already set aside for it.
    --
    -- The lane is one control row tall - enough for the breadcrumb strip - which
    -- also clears the ring: the ring reaches ~21px below contentTop (a 72px ring
    -- anchored 13px above a frame top whose contentTop is 38px down), and the
    -- lane is taller than that.
    local CRUMB_LANE = 30
    local columnTop  = contentTop - CRUMB_LANE

    -- The activity rail: a fixed-width column down the left edge, from the
    -- column line to the bottom of the frame. Navigation lives here; the
    -- workspace (list + detail) rides to its right. The rail owns the
    -- profession/processing/secondary/gathering activities and the tool shelf.
    rail = Addon.activityRail:create({
        parent  = mainFrame,
        viewed  = viewedActivityId,
        onSelect = function(activity) selectActivity(activity) end,
        onContext = function(activity, row)
            -- Only a windowed primary can be unlearned (game rule); processing
            -- rows, secondaries and gathering get no menu.
            if activity.kind ~= "profession" then return end
            local info = liveProfInfo(activity.profID)
            if not info or info.category == "secondary" then return end
            local name = Addon.ledger:getProfessionName(activity.profID) or ""
            Addon.contextMenu:showAt(row, "TOPLEFT", {
                items = {
                    { text = "Unlearn " .. name .. "...", color = {1, 0.4, 0.4},
                      func = function()
                          local dialog = StaticPopup_Show("CRAFTY_UNLEARN_PROFESSION", name)
                          if dialog then dialog.data = activity.profID end
                      end },
                },
            }, {})
        end,
        onCustomize = function()
            -- Opens the customize surface for the viewed profession, rendering
            -- its display options through the shared options engine.
            local profID = viewedProfession()
            if profID then
                Addon.customizePanel:toggle(profID, mainFrame, rail:getFrame(),
                                            detailFrame, rail)
            end
        end,
        -- Target-tool nods, both routed to the craft verb: on completion the
        -- verb hops with the celebrating tool; on an idle click the verb's
        -- nod IS the answer - "start here."
        onToolTargeted   = function() detailPanel:nudgeCraft() end,
        onToolIdleTarget = function() detailPanel:nudgeCraft() end,
        backdrop      = BACKDROP_PANEL,
        motionSeconds = MOTION_SECONDS,
    })
    rail:getFrame():SetPoint("TOPLEFT", mainFrame, "TOPLEFT", PANEL_PADDING, columnTop)
    rail:getFrame():SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT",
                             PANEL_PADDING, PANEL_PADDING)

    -- The workspace begins to the right of the rail. Everything below (panels,
    -- footer) anchors off this left edge, not the window's.
    local workLeft = PANEL_PADDING + rail:width() + PANEL_GAP

    -- The breadcrumb lane: the reserved band above the panels, right of the
    -- rail. The journey strip lives here, height 0 until a detour exists, then
    -- springing open WITHIN the lane - the panels below never move.
    journeyStrip = Addon.journeyStrip:create({
        parent    = mainFrame,
        backdrop  = BACKDROP_TRAIL,
        motionSeconds = MOTION_SECONDS,
        onReturn  = function(level) returnToJourneyLevel(level) end,
        onDismiss = function()
            -- Abandoning clears the guidance, never the position.
            wipe(journey)
            journeyArrival = nil
            journeyStrip:clear()
        end,
    })
    -- Anchored bottom-up in the lane so it grows upward toward the titlebar,
    -- leaving the panels' top edge fixed.
    journeyStrip:getFrame():SetPoint("BOTTOMLEFT", mainFrame, "TOPLEFT", workLeft, columnTop)
    journeyStrip:getFrame():SetPoint("BOTTOMRIGHT", mainFrame, "TOPRIGHT", -PANEL_PADDING, columnTop)

    -- Left panel: recipe list + its filter/sort controls (the search lives at
    -- the top of this panel). Fixed at the column line - the breadcrumb no
    -- longer pushes it. Its WIDTH is a fraction of the workspace, recomputed on
    -- resize (below), so the list and detail shrink together rather than the
    -- detail absorbing all the loss.
    local panelLeft = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    panelLeft:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", workLeft, columnTop)
    panelLeft:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT",
                       workLeft, PANEL_PADDING + FOOTER_STRIP)
    panelLeft:SetBackdrop(BACKDROP_PANEL)
    local pb = theme.crafty.SURFACE.PANEL
    panelLeft:SetBackdropColor(pb.r, pb.g, pb.b, pb.a)

    -- Right panel: recipe detail. Fills from the list's right edge to the frame
    -- right, so setting the list width alone splits the workspace.
    local panelRight = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    detailFrame = panelRight
    panelRight:SetPoint("TOPLEFT", panelLeft, "TOPRIGHT", PANEL_GAP, 0)
    panelRight:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT",
                        -PANEL_PADDING, PANEL_PADDING + FOOTER_STRIP)

    -- Split the workspace between list and detail. The list takes LIST_FRACTION
    -- of the space left after the rail, but never less than LIST_MIN nor so much
    -- that the detail drops below DETAIL_MIN - both panes stay usable at every
    -- width the grip allows. Recomputed on every resize.
    local function splitWorkspace()
        local avail = mainFrame:GetWidth() - workLeft - PANEL_GAP - PANEL_PADDING
        local listW = avail * LIST_FRACTION
        listW = math.max(LIST_MIN, math.min(listW, avail - DETAIL_MIN))
        panelLeft:SetWidth(listW)
    end
    splitWorkspace()

    -- Resizing the frame re-splits the workspace so the list and detail track
    -- the new width together. OnSizeChanged fires throughout a grip drag, so the
    -- split stays correct live, not just on release.
    mainFrame:SetScript("OnSizeChanged", splitWorkspace)

    -- Profession footer: spans the workspace beneath both panels, right of the
    -- rail. Profession-scoped where the recipe bar is recipe-scoped, and the
    -- placement says so.
    footer = Addon.professionFooter:create(mainFrame)
    -- Aligned to the panels' CONTENT edge. A panel's backdrop insets its content
    -- by BACKDROP_PANEL.insets, so matching the panel FRAME would leave the
    -- footer sitting proud of everything above it.
    local inset = BACKDROP_PANEL.insets.left
    footer:getFrame():SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT",
                               workLeft + inset, PANEL_PADDING)
    footer:getFrame():SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT",
                               -(PANEL_PADDING + inset), PANEL_PADDING)
    panelRight:SetBackdrop(BACKDROP_PANEL)
    panelRight:SetBackdropColor(pb.r, pb.g, pb.b, pb.a)

    -- Processing placeholder: a workspace overlay raised when a not-yet-built
    -- activity is viewed. Spans both panels; hidden for professions. Composer
    -- scaffolding - each processing phase deletes its branch as it ships the
    -- real destination.
    placeholder = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    placeholder:SetPoint("TOPLEFT", panelLeft, "TOPLEFT", 0, 0)
    placeholder:SetPoint("BOTTOMRIGHT", panelRight, "BOTTOMRIGHT", 0, 0)
    placeholder:SetFrameLevel(panelRight:GetFrameLevel() + 10)
    placeholder:SetBackdrop(BACKDROP_PANEL)
    placeholder:SetBackdropColor(pb.r, pb.g, pb.b, pb.a)
    placeholder:Hide()
    placeholder.label = placeholder:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    placeholder.label:SetPoint("CENTER")
    placeholder.label:SetJustifyH("CENTER")
    theme.derive.tint(placeholder.label, theme.crafty.TEXT.LABEL)
    -- The message a viewed processing activity shows until its phase lands.
    function placeholder.textFor(activity)
        return (activity.name or "This activity") .. "\nis coming in a later build."
    end

    recipePanel = Addon.recipePanel:create({
        parent = panelLeft,
        viewed = viewedProfession,
    })

    detailPanel = Addon.detailPanel:create({
        parent = panelRight,
        -- A craft that ran into a missing station: the rail's tool shelf is
        -- where the remedy lives - it nods.
        onStationMissing = function() rail:nodTools() end,
        -- A craftable reagent clicked: a DECLARATION of service to the
        -- recipe it was clicked from. From the journey's live position, the
        -- chain deepens; from anywhere else - however the journey's promises
        -- relate to this reagent - the old journey ends and a new one roots
        -- here. The reagent's identity is irrelevant; the clicked-from
        -- recipe is everything.
        onReagentNavigate = function(nav)
            local fromID, fromKind = recipePanel:selected()
            if not fromID then return end
            local deepening = journeyArrival
                and journeyArrival.recipeID == fromID
                and (journeyArrival.kind or "recipe") == (fromKind or "recipe")
            if not deepening and #journey > 0 then
                wipe(journey)
                journeyArrival = nil
                journeyStrip:clear()
            end
            journey[#journey + 1] = {
                profID   = viewedProfID,
                recipeID = fromID,
                kind     = fromKind,
                itemID   = nav.itemID,
                owed     = nav.owed,
                -- The number being worked at when this level was left, so
                -- returning stands on it again rather than on the deeper
                -- screen's.
                quantity = detailPanel:quantity(),
                paid     = false,
            }
            journeyStrip:push(crumbFor(fromID, fromKind))
            navigateTo(nav.profID, nav.recipeID, nav.kind, nav.prefill,
                { itemID = nav.itemID, owed = nav.owed })
        end,
    })

    tray = Addon.newlyLearnedTray:create({
        parent   = panelLeft,
        viewed   = viewedProfession,
        rowKind  = recipePanel:recipeRowKind(),
        -- The tray's height lifts the recipe list's bottom off the panel by the
        -- same amount - one variable driving both frames, so they can never
        -- disagree. The 4px gap between list and tray exists only while the
        -- tray is open.
        onHeight = function(h)
            recipePanel:liftBottom(h == 0 and 6 or (6 + h + 4))
        end,
        onSelect = function(recipeID) recipePanel:select(recipeID, "recipe") end,
        backdrop = BACKDROP_PANEL,
        motionSeconds = MOTION_SECONDS,
    })
    -- The tray hangs off the list's bottom corners - x and y both follow the
    -- list by construction, so the two can never disagree.
    tray:getFrame():SetPoint("TOPLEFT", recipePanel:listFrame(), "BOTTOMLEFT", 0, -4)
    tray:getFrame():SetPoint("TOPRIGHT", recipePanel:listFrame(), "BOTTOMRIGHT", 0, -4)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function craftingWindow:toggle()
    if not mainFrame then buildFrame() end
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        initViewedProfession()
        rail:refresh()
        if footer then footer:refresh(viewedProfID) end
        activateProfession(true)
    end
end

function craftingWindow:show()
    if not mainFrame then buildFrame() end
    mainFrame:Show()
    initViewedProfession()
    rail:refresh()
    if footer then footer:refresh(viewedProfID) end
    activateProfession(true)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function craftingWindow:initialize()
    events = Addon.events
    ledger = Addon.ledger
    utils = Addon.utils
    theme = Addon.theme
    recipeView = Addon.recipeView

    if not events or not ledger or not utils or not theme or not recipeView
        or not Addon.activityRail or not Addon.newlyLearnedTray
        or not Addon.recipePanel or not Addon.detailPanel then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444craftingWindow: Missing dependencies|r")
        return false
    end

    local constants = Addon.constants

    -- Refresh the list whenever a scan completes, if the window is open.
    events:subscribe(constants.EVENT.RECIPES_SCANNED, function(_, payload)
        local profID = payload and payload.prof
        if not profID then return end

        -- The one place the recipe list rebuilds: a scan finished for the
        -- profession currently being viewed. Gated on viewedProfID so a harvester
        -- sweep (which scans every profession) does not rebuild the list for
        -- professions the user is not looking at.
        if mainFrame and mainFrame:IsShown() and profID == viewedProfID then
            local navigating = pendingNav and pendingNav.profID == viewedProfID
            if navigating then suppressWander = true end
            recipePanel:repopulate()
            tray:layout()
            -- A cross-profession navigation lands here: the scan for its
            -- target finished, so the detour's real destination replaces the
            -- repopulate's default pick.
            if navigating then
                if pendingNav.kind == "convert" then
                    detailPanel:setConversionErrand(pendingNav.owed)
                end
                recipePanel:select(pendingNav.recipeID, pendingNav.kind)
                if pendingNav.prefill then
                    detailPanel:prefillQuantity(pendingNav.prefill)
                end
                pendingNav = nil
                suppressWander = false
            end
        end

        -- Name-resolution check: names are derived live (spell/item), which can
        -- come back unresolved. After a scan, verify every known recipe in the
        -- scanned profession resolved to a real name; chat the ids that did not,
        -- so an unnamed recipe is never silently missed.
        local unresolved = {}
        for _, recipeID in ipairs(ledger:getKnownRecipes(profID)) do
            local nm = recipeView:name(recipeID)
            if not nm or nm == ("recipe:" .. recipeID) then
                unresolved[#unresolved + 1] = recipeID
            end
        end
        if #unresolved > 0 then
            utils:chat(("NAMECHECK prof=%d unresolved=%d: %s")
                :format(profID, #unresolved, table.concat(unresolved, ",")))
        end
    end)

    -- Wandering off an unpaid errand converts it into a crumb: the promise
    -- ("I still owe bolts to the carpet") survives the user's detour from
    -- the detour. Journey moves are suppressed; a paid errand wandered from
    -- is simply complete.
    events:subscribe(constants.EVENT.RECIPE_SELECTED, function(_, payload)
        local id, kind = payload and payload.id, payload and payload.kind
        if suppressWander or not journeyArrival then return end
        if id == journeyArrival.recipeID
            and (kind or "recipe") == (journeyArrival.kind or "recipe") then return end
        local a = journeyArrival
        journeyArrival = nil
        if a.owed then
            local have = ledger:getItemCount(a.itemID)
            if have and (have.bags or 0) >= a.owed then return end
        end
        journey[#journey + 1] = {
            profID   = a.profID,
            recipeID = a.recipeID,
            kind     = a.kind,
            itemID   = a.itemID,
            owed     = a.owed,
            quantity = detailPanel:quantity(),
            paid     = false,
        }
        journeyStrip:push(crumbFor(a.recipeID, a.kind))
    end)

    -- A tool's cooldown starts and ends without anything else changing, so
    -- neither a bag scan nor a refresh would notice it. Spell tools report
    -- through SPELL_UPDATE_COOLDOWN, item tools through BAG_UPDATE_COOLDOWN.
    local function repaintToolCooldowns()
        if mainFrame and mainFrame:IsShown() then rail:repaintTools() end
    end
    events:subscribe("SPELL_UPDATE_COOLDOWN", repaintToolCooldowns)
    events:subscribe("BAG_UPDATE_COOLDOWN", repaintToolCooldowns)

    events:subscribe(constants.EVENT.BAGS_SCANNED, function()
        if mainFrame and mainFrame:IsShown() then
            detailPanel:rerender()
            rail:repaintTools()   -- item-tool counts and availability live in bags
            -- Debt-paid nods: a journey level whose owed count is now
            -- covered gets its crumb's acknowledgment hop, once.
            for level, entry in ipairs(journey) do
                if not entry.paid and entry.owed then
                    local have = ledger:getItemCount(entry.itemID)
                    if have and (have.bags or 0) >= entry.owed then
                        entry.paid = true
                        journeyStrip:nodCrumb(level)
                    end
                end
            end
        end
    end)

    -- A trade window opened with no modifier (slash, Wunderbar, trainer, or
    -- Crafty's own cast): adopt it. Read what is actually open, make it the viewed
    -- profession, scan it, then refresh the band/list - in that order, so the
    -- scan's RECIPES_SCANNED gate and the band both see the adopted profession
    -- rather than a stale prior one. A linked window reads as nil (another
    -- player's data) and is not adopted.
    events:subscribe("PROFESSION:OPENED", function(_, payload)
        local openProfID = Addon.professionWindow:liveOpenProfID()
        if not openProfID then return end

        -- An unlearn is in flight: whatever window this is, establish its
        -- session and scan, but leave the viewed profession alone - the swap
        -- belongs to the departure choreography.
        if unlearnInFlightProfID then
            Addon.professionWindow:beginSession()
            local info = liveProfInfo(openProfID)
            Addon.recipeScanner:scanOpen(openProfID, info.name, info.rank, info.category)
            return
        end

        -- TOGGLE, for EXTERNAL opens only - a profession button out in the
        -- world, the spellbook, a macro. A profession button is a toggle
        -- everywhere else in the game and Crafty stands in for the window it
        -- opens, so pressing the one already on screen means "I am done here".
        --
        -- Crafty's own opens are excluded because they are indistinguishable
        -- otherwise: selecting a profession card sets the viewed profession
        -- BEFORE opening its window, so by the time this fires the two always
        -- match and every card click would close the window.
        if payload and payload.external
                and mainFrame and mainFrame:IsShown()
                and viewedProfID == openProfID then
            mainFrame:Hide()   -- OnHide closes the trade window and ends the session
            return
        end

        if not mainFrame then buildFrame() end
        mainFrame:Show()

        viewedProfID = openProfID          -- adopt the open window as viewed
        ledger:setViewedProfID(openProfID) -- last-viewed persists across sessions

        -- Filter/sort state is per profession: now that the viewed profession is
        -- established, restore this profession's saved state and push it into the
        -- controls BEFORE the scan triggers the list rebuild (which applies the
        -- active filter/sort). Without this the fresh-open path would build the
        -- list against a not-yet-restored (empty) filter state.
        Addon.filterRegistry:restore()
        recipePanel:syncToRegistry()

        -- Establish the held session for the adopted profession WITHOUT casting.
        -- This runs inside the PROFESSION:OPENED event handler, where CastSpellByName
        -- is blocked as tainted. The window is already open (the event fired because
        -- it opened), so there is nothing to cast: just begin the session to hold it
        -- and scan directly. activateProfession must NOT be used here - its "not
        -- open" branch calls open()/CastSpellByName, and if liveOpenProfID flickers
        -- during event dispatch it would take that branch and taint.
        Addon.professionWindow:beginSession()
        local info = liveProfInfo(openProfID)
        Addon.recipeScanner:scanOpen(openProfID, info.name, info.rank, info.category)
        rail:refresh()
        if footer then footer:refresh(viewedProfID) end
    end)

    -- Harvest done: it owned the trade-skill window while cycling professions.
    -- Now establish the live session for the active profession (held open for
    -- crafting) and refresh the list. This is the deferred activation from
    -- Crafty-open when a harvest ran.
    events:subscribe("HARVEST:COMPLETE", function()
        if mainFrame and mainFrame:IsShown() then
            activateProfession(true)
            rail:refresh()
            if footer then footer:refresh(viewedProfID) end
        end
    end)

    -- A cooldown sweep changes cooldown DATA, which is shown in the detail panel
    -- of the selected recipe. It does not change the set of rows or their colors,
    -- so it only refreshes the current detail - no list operation.
    events:subscribe("COOLDOWNS:SWEPT", function()
        if mainFrame and mainFrame:IsShown() then
            detailPanel:rerender()
        end
    end)

    -- Difficulty is derived from current rank at render, so a skill-up changes
    -- the band colors. The set of rows is unchanged, so redraw the visible rows'
    -- content in place - NOT a re-projection, which would re-run the filter and
    -- drop a recipe inserted past it (e.g. a just-learned recipe).
    local knownProfSet   -- profID set snapshot; nil until the first enumerate
    events:subscribe("SKILL_LINES_CHANGED", function()
        -- Profession-set diff runs regardless of window state: an unlearn
        -- must purge the ledger even with Crafty closed. UI reactions
        -- (band layout, selection handoff) apply only to a shown window.
        -- Every profession, windowed or not: unlearning Herbalism must purge
        -- its ledger record as surely as unlearning Alchemy. Only a WINDOWED
        -- one can become the viewed card, so `added` ignores the rest.
        local live = Addon.professionHarvester:enumerate()
        local liveSet, added = {}, nil
        for _, prof in ipairs(live) do
            liveSet[prof.profID] = true
            if knownProfSet and not knownProfSet[prof.profID] and prof.windowed then
                added = prof.profID
            end
        end
        local removed = {}
        if knownProfSet then
            for profID in pairs(knownProfSet) do
                if not liveSet[profID] then removed[#removed + 1] = profID end
            end
        end
        knownProfSet = liveSet

        for _, profID in ipairs(removed) do
            ledger:forgetProfession(profID)
            Addon.newlyLearnedTray:clear(profID)
            if mainFrame and mainFrame:IsShown() then
                -- Departure first, successor second: the card trembles out in
                -- place, and only then does the next one bound over (or the
                -- band close ranks, when the departed was not the viewed one).
                local wasViewed = viewedProfID == profID
                rail:retire(profID, function()
                    if wasViewed then
                        local fallback
                        for _, prof in ipairs(live) do
                            if prof.windowed then
                                fallback = prof.profID
                                break
                            end
                        end
                        if fallback then
                            selectProfession(fallback, true)
                        else
                            viewedProfID = nil
                            rail:refresh()
                            if footer then footer:refresh(viewedProfID) end
                        end
                    else
                        rail:refresh()
                        if footer then footer:refresh(viewedProfID) end
                    end
                    -- The flight ends when the choreography ends: the removal
                    -- event fires twice, and the second lands mid-tremble -
                    -- clearing at detection let its tail refresh perform the
                    -- swap on top of the trembler.
                    if profID == unlearnInFlightProfID then
                        unlearnInFlightProfID = nil
                    end
                end)
            else
                if viewedProfID == profID then
                    viewedProfID = nil
                end
                if profID == unlearnInFlightProfID then
                    unlearnInFlightProfID = nil
                end
            end
        end
        if added and mainFrame and mainFrame:IsShown() then
            -- A profession learned with Crafty open becomes the viewed one
            -- immediately, through the standard selection choreography.
            selectProfession(added, true)
        end

        if mainFrame and mainFrame:IsShown() and not unlearnInFlightProfID then
            recipePanel:redrawVisible()
            detailPanel:rerender()
            rail:refresh()   -- rank text on the blocks; an unchanged
                             -- signature makes this the facts-only path,
                             -- so in-flight choreography is untouched
            if footer then footer:refresh(viewedProfID) end
        end
    end)

    -- A recipe can be learned with no profession window open (trainer, bag item,
    -- discovery, level-up). The event gives only the spellID; record it from the
    -- static data (which knows its profession and facts). A discovery then lands
    -- in two places, each doing its own job: the tray announces it (always, one
    -- consistent spot), and the main list's model gains the row like any other -
    -- visible iff it passes the active filter, sorted like everything else.
    -- Learned while the window is closed or another profession is viewed, the
    -- tray shows it on the next look (the scan-driven repopulate lays the tray
    -- out from the pending set).
    events:subscribe("NEW_RECIPE_LEARNED", function(_, spellID)
        if not spellID then return end
        local profID = ledger:recordLearnedRecipe(spellID)
        if not profID then return end
        Addon.newlyLearnedTray:add(profID, spellID)   -- module-level store:
                                                      -- the window may never
                                                      -- have been built
        if mainFrame and mainFrame:IsShown() and profID == viewedProfID then
            recipePanel:addRecipe(spellID)   -- sorted into place now, so the
                                             -- ghost flies to its real home
            tray:arrive(spellID, function()
                -- Flies when the source is on screen; lands with the bloom
                -- either way.
                return learnOriginPoint()
            end)
        elseif mainFrame and mainFrame:IsShown() then
            -- Learned for a profession you are not looking at. The tray already
            -- holds it, but nothing on screen says so - mark the card instead,
            -- and leave the mark until that profession is viewed.
            rail:arrived(profID)
        end
    end)

    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("craftingWindow",
        {"events", "ledger", "professionHarvester", "professionWindow",
         "recipeScanner", "crafter", "filterRegistry", "recipeView", "theme",
         "contextMenu", "tooltip", "utils", "factCheck",
         "activityModel", "activityRail", "newlyLearnedTray", "recipePanel",
         "detailPanel", "professionFooter",
         "journeyStrip"},
        function()
            return craftingWindow:initialize()
        end)
end

Addon.craftingWindow = craftingWindow
return craftingWindow
