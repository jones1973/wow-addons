--[[
  logic/professionWindow.lua
  Crafty Profession Window controller

  Owns one capability: silently operate the trade skill window. Open a profession
  off-screen, learn when its window is loaded and readable, and restore the UI
  when done. Two consumers use it:

    - professionHarvester: opens each profession in turn to scan it.
    - crafter:             opens one profession to craft from it.

  Both need exactly this: "open profession X silently, tell me when it is ready,
  put the UI back when I am finished." The hard-won pieces live here once:

  FRAME HIDING. The trade skill window is moved far off-screen and its OnShow
  script is nil-ed during operation, so the player never sees it flash open. The
  original position and OnShow are saved and restored.

  RE-ENTRANCY GUARD. CastSpellByName fires TRADE_SKILL_SHOW synchronously once
  Blizzard_TradeSkillUI is loaded, so the show handler can re-enter mid-open. An
  explicit state flag means the handler only acts when we are actually waiting
  for a show, and the flag is cleared before the onReady callback runs - so a
  synchronous re-open from within the callback is handled as a fresh open, not a
  re-entry of the current one.

  AUTO-CLOSE. Opening a profession auto-closes the previously open one (each cast
  fires TRADE_SKILL_CLOSE for the prior window, then TRADE_SKILL_SHOW for the
  new). So callers that open several in a row do not need to close between them;
  only the final window needs an explicit close (closeCurrent).

  Dependencies: events
  Exports: Addon.professionWindow
]]

local ADDON_NAME, Addon = ...

local professionWindow = {}

local events

-- The frame WoW uses for the trade skill window on this client.
local TRADE_SKILL_FRAME_NAME = "TradeSkillFrame"

-- State: we are either idle, or waiting for a TRADE_SKILL_SHOW after a cast.
local STATE_IDLE    = "idle"
local STATE_OPENING = "opening"
local STATE_WAITING_LIST = "waiting_list"  -- shown, but list not populated yet
local state = STATE_IDLE
local deferredOurs   -- whether the open being waited on was Crafty's own

local fireReady  -- forward declaration (defined after onTradeSkillShow)

local pendingOnReady = nil    -- callback to fire when the awaited window opens
local sessionActive = false   -- whether the event subscriptions are active

-- ============================================================================
-- INTERNAL: sound suppression
-- ============================================================================
--
-- The TradeSkillFrame plays its open/close sound from its own OnShow/OnHide
-- scripts (confirmed: GetScript("OnShow") == TradeSkillFrame_OnShow). To make a
-- programmatic open/close silent, we nil BOTH scripts around the action and
-- restore them after - the show/hide still happens, just without the sound. A
-- profession SWAP is a single open that also auto-closes the previous window, so
-- the same bracket must cover both the OnHide (old auto-closing) and OnShow (new
-- showing); wrapping the whole cast in one silent bracket does that.
--
-- Policy (decided by callers via the `audible` flag, not here): only the open
-- when Crafty opens, and the close when Crafty closes, are audible. Every
-- profession swap in between is silent.

local function tradeFrame()
    return _G[TRADE_SKILL_FRAME_NAME]
end

-- Run `action` with the trade frame's OnShow/OnHide suppressed (silent) unless
-- `audible` is true, in which case the scripts are left intact and the action's
-- show/hide sounds normally. Scripts are always restored afterward.
local function withSound(audible, action)
    local f = tradeFrame()
    if audible or not f then
        action()
        return
    end
    local onShow = f:GetScript("OnShow")
    local onHide = f:GetScript("OnHide")
    f:SetScript("OnShow", nil)
    f:SetScript("OnHide", nil)
    action()
    f:SetScript("OnShow", onShow)
    f:SetScript("OnHide", onHide)
end

-- ============================================================================
-- INTERNAL: the show handler
-- ============================================================================

--[[
  TRADE_SKILL_SHOW: the just-cast profession's window is open and loaded. Only
  acts when OPENING (waiting for this show). The state is cleared and the
  callback captured locally BEFORE invoking it, so a synchronous re-open from
  within the callback (the next open) is treated as a fresh open, not a re-entry.
]]
local function onTradeSkillShow()
    -- shift -> let the Blizzard profession window show (Crafty does not suppress
    -- or take over). No modifier -> Crafty takes over.
    if IsShiftKeyDown() then return end

    -- A linked tradeskill (another player's, opened from a chat link) is data
    -- Crafty does not display. Let Blizzard's frame show it rather than
    -- suppressing it into nothing - checked before hiding, since suppression
    -- would otherwise hide a window Crafty then declines to adopt.
    if C_TradeSkillUI.IsTradeSkillLinked() then return end

    professionWindow.hideFrameOffscreen()

    -- The list may not be populated at SHOW: TRADE_SKILL_SHOW can fire with
    -- GetNumTradeSkills()==0, the list filling in on a later TRADE_SKILL_UPDATE.
    -- This is true for external opens (cooking fire, Wunderbar, trainer) as much
    -- as Crafty's own casts, so the wait-for-list applies to ANY open, not just
    -- STATE_OPENING. Dropping a show with an empty list was the "open 3 times
    -- before it shows" bug: external opens never engaged the wait.
    if GetNumTradeSkills() == 0 then
        -- Carried across the wait: STATE_WAITING_LIST is reached by external
        -- opens as much as by Crafty's own, so the state alone no longer says
        -- who started this one.
        deferredOurs = state == STATE_OPENING
        state = STATE_WAITING_LIST
        return
    end

    -- List is populated. If Crafty cast this open, fire its pendingOnReady chain.
    local ours = state == STATE_OPENING
    if ours then
        fireReady()
    end

    -- Any open window with a populated list -> tell the UI to adopt and show.
    --
    -- `external` is the only thing that separates a profession button pressed
    -- out in the world from Crafty opening the same profession itself. Both
    -- arrive here identically, and by then the viewed profession has already
    -- been set to the one being opened - so without this a card click looks
    -- exactly like re-pressing the button for the profession on screen.
    events:emit("PROFESSION:OPENED", { external = not ours })
end

-- Fire the captured onReady callback, clearing state first so a synchronous
-- re-open from within the callback is treated as a fresh open.
fireReady = function()
    state = STATE_IDLE
    local cb = pendingOnReady
    pendingOnReady = nil

    professionWindow.hideFrameOffscreen()
    if cb then cb() end
end

-- The skill list populated/changed after a show; if we were waiting for it,
-- fire now.
local function onTradeSkillUpdate()
    if IsShiftKeyDown() then return end
    if GetNumTradeSkills() == 0 then return end
    -- Only act when completing a deferred open (the show fired before the list
    -- was populated). TRADE_SKILL_UPDATE also fires on every craft/skill-up while
    -- the window is open; emitting PROFESSION:OPENED then would re-run the scan
    -- and full rebuild, wiping surgical inserts (e.g. a just-learned recipe).
    if state == STATE_WAITING_LIST then
        local ours = deferredOurs
        deferredOurs = nil
        fireReady()
        events:emit("PROFESSION:OPENED", { external = not ours })
    end
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Move the trade skill window off-screen so operation is invisible. Exposed so
  callers can re-hide after the window re-shows (e.g. after a craft cast).
]]
-- Saved original OnHide of the Blizzard trade frame, so it can be restored when
-- the session ends. The frame's OnHide tears down the trade-skill session; we
-- neutralize it while suppressing so the session survives being hidden.
local savedOnHide = nil
local onHideSaved = false

--[[
  Genuinely hide the Blizzard trade-skill frame while keeping the trade-skill
  session alive. The frame's own OnHide would close the session, so we save and
  null it before hiding, then HideUIPanel. Idempotent; callers re-hide whenever
  the frame re-shows (e.g. a trainer re-anchors it, or after a craft cast).
]]
function professionWindow.hideFrameOffscreen()
    local f = tradeFrame()
    if not f then return end
    if not onHideSaved then
        savedOnHide = f:GetScript("OnHide")
        onHideSaved = true
    end
    f:SetScript("OnHide", nil)
    HideUIPanel(f)
end

--[[
  Begin a session: subscribe to the trade-skill events. Call when Crafty opens,
  before the first profession open. Idempotent within a session.
]]
function professionWindow:beginSession()
    if sessionActive then return end
    sessionActive = true
    state = STATE_IDLE
    pendingOnReady = nil
end

--[[
  Open a profession's window by the name to cast (the caller has already resolved
  any open-spell substitution, e.g. Mining -> Smelting). Off-screen, held open;
  opening auto-closes any previously open profession. onReady fires once the
  window is open and populated, driven by the TRADE_SKILL_SHOW event.

  No timeout/stall guard: the only professions we open are ones enumerate()
  cleared as having a craftable window, so TRADE_SKILL_SHOW will fire. Advancing
  the open chain must stay in the event-driven path - CastSpellByName for trade
  skills is allowed from the event context, but firing it from a C_Timer callback
  taints the path and the game blocks it as a protected function.

  @param castName string - the spell/profession name to cast to open the window
  @param onReady fn       - called when the window is ready (from TRADE_SKILL_SHOW)
  @param audible bool     - if true, the open sound plays
]]
function professionWindow:open(castName, onReady, audible)
    state = STATE_OPENING
    pendingOnReady = onReady

    withSound(audible, function()
        self.hideFrameOffscreen()
        CastSpellByName(castName)
    end)
end


-- genuinely hidden while Crafty holds it (HideUIPanel), so frame visibility is
-- NOT the signal - a held session reports its skill list regardless. Read the
-- session state from the API: a populated trade-skill list means it is open.
function professionWindow:isOpen()
    return GetNumTradeSkills() > 0
end

-- The profID of the profession whose window is genuinely open right now, read
-- live from the game - never cached. Returns nil when nothing is open, or when
-- the open window is a linked preview of another player's tradeskill (not ours).
--
-- GetTradeSkillLine() returns the open profession's NAME as its first value
-- (reliable on this client; the id return is not), and "UNKNOWN" when no session
-- is open. The frame being genuinely hidden while Crafty holds it does NOT affect
-- this - a held session still reports its line. We resolve the name to a profID
-- via the castless enumerate, since profID (not name) is the identity we key on.
function professionWindow:liveOpenProfID()
    if C_TradeSkillUI.IsTradeSkillLinked() then return nil end

    local name = GetTradeSkillLine()
    if not name or name == "UNKNOWN" then return nil end

    -- Windowed only: this resolves the name of an OPEN trade window.
    for _, p in ipairs(Addon.professionHarvester:enumerate()) do
        if p.name == name and p.windowed then return p.profID end
    end
    return nil
end

--[[
  Close the open trade-skill window.
  @param audible bool - if true, the close sound plays (only the Crafty-close).
]]
function professionWindow:closeCurrent(audible)
    withSound(audible, function()
        CloseTradeSkill()
    end)
end

--[[
  End the session: unsubscribe. Call when Crafty closes, after closeCurrent.
]]
function professionWindow:endSession()
    -- Restore the Blizzard frame's OnHide neutralized during suppression.
    local f = tradeFrame()
    if f and onHideSaved then
        f:SetScript("OnHide", savedOnHide)
    end
    savedOnHide = nil
    onHideSaved = false

    state = STATE_IDLE
    pendingOnReady = nil
    sessionActive = false
end

-- Read the live list index for a recipeID in the currently open profession, by
-- walking the window's recipe rows and matching the parsed recipeID. Returns nil
-- if not found (recipe not in the open profession). Used by the crafter to map a
-- stored recipeID to the ephemeral index DoTradeSkill needs.
function professionWindow:indexForRecipe(recipeID)
    for i = 1, GetNumTradeSkills() do
        local link = GetTradeSkillRecipeLink(i)
        if link then
            local id = tonumber(link:match("enchant:(%d+)"))
            if id == recipeID then
                return i
            end
        end
    end
    return nil
end

function professionWindow:initialize()
    events = Addon.events
    if not events then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444professionWindow: Missing dependencies|r")
        return false
    end
    -- Listen for the trade window opening from load, not session start: a plain
    -- click (Wunderbar, trainer, slash) must be caught and decided even before
    -- any Crafty session exists, since that show is how Crafty opens.
    events:subscribe("TRADE_SKILL_SHOW", onTradeSkillShow)
    events:subscribe("TRADE_SKILL_UPDATE", onTradeSkillUpdate)
    return true
end

Addon.professionWindow = professionWindow

if Addon.registerModule then
    Addon.registerModule("professionWindow", {"events"}, function()
        return professionWindow:initialize()
    end)
end
