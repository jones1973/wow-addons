--[[
  logic/crafter.lua
  Crafty Crafter

  Crafts a recipe. The first crafting capability: open the recipe's profession
  (silently, via professionWindow), resolve the stored recipeID to the live trade
  skill list index, and call DoTradeSkill.

  WHY OPENING IS PART OF CRAFTING. DoTradeSkill(index) acts on the currently open
  profession's window, and the index is ephemeral - it only exists while that
  window is open. Our data keys on recipeID (stable), so crafting must open the
  right profession and map recipeID -> index at craft time. Opening the window in
  the background is therefore a core part of crafting, not a queue-only concern:
  you craft a recipe, Crafty opens its profession off-screen, crafts, done.

  VERIFIED API (warcraft.wiki.gg, MoP/Classic is pre-7.0.3 so the legacy index
  API applies, not C_TradeSkillUI.CraftRecipe):
    DoTradeSkill(index [, repeat]) - index is the live 1-based list position;
    repeat is optional. If repeat exceeds what the player can make, no error -
    crafting halts when bags or materials run out.

  FIRST STEP SCOPE: craft the given recipe `count` times (default 1). No queue,
  no cross-character chaining - just prove a single craft works end to end,
  including the silent open. The window is left off-screen during the craft; this
  build is also the test of whether an off-screen window completes a craft.

  Dependencies: utils, events, ledger, professionWindow, recipeCatalog
  Exports: Addon.crafter
]]

local ADDON_NAME, Addon = ...

local crafter = {}

local utils, events, ledger, professionWindow, recipeCatalog

local crafting = false   -- guard against overlapping craft requests
local craftingRecipe     -- what the open order is crafting
local lastCraftEndedAt   -- GetTime() stamp of the last craft's completion

--[[
  Craft a recipe `count` times. Opens the recipe's profession off-screen,
  resolves the live index, and issues DoTradeSkill.

  @param recipeID number
  @param count number|nil - times to craft; defaults to 1
  @return boolean - whether the craft was started
]]
function crafter:craft(recipeID, count)
    -- Refuse only while a cast is ACTUALLY in flight, which the client answers
    -- and a flag of ours can only approximate. `crafting` is set and cleared by
    -- us, so an order that stops without any cast event leaves it set for the
    -- session - and gating on it would then block every later craft.
    if UnitCastingInfo("player") then
        utils:chat("a craft is already in progress")
        return false
    end

    -- Nothing is casting, so whatever the last order was doing, it is over.
    -- Asking for a new craft IS the proof - the same reasoning the probe uses,
    -- and it needs no timer to reach it.
    if crafting then self:abandonOrder() end

    -- The profession this recipe belongs to, and its localized name (needed to
    -- open it via CastSpellByName).
    local profID = recipeCatalog:professionOf(recipeID)
    if not profID then
        utils:chat("craft: unknown recipe " .. tostring(recipeID))
        return false
    end
    local profName = ledger:getProfessionName(profID)
    if not profName then
        utils:chat("craft: no profession name for prof " .. tostring(profID))
        return false
    end

    count = count or 1
    crafting = true
    craftingRecipe = recipeID

    -- Craft on the live session. The profession should already be open (the
    -- crafting window holds it open for the active profession), so in the common
    -- case we craft directly with no open. But the user may have ESC'd the hidden
    -- frame shut, or be crafting a recipe from a different profession than the one
    -- displayed - so ensure the correct profession is open first, silently.
    local function doCraft()
        local index = professionWindow:indexForRecipe(recipeID)
        if not index then
            utils:chat("craft: recipe " .. tostring(recipeID)
                .. " not found in open profession " .. tostring(profName))
            self:finish()
            return
        end
        DoTradeSkill(index, count)
        self:awaitCraftEnd(count)
    end

    if professionWindow:liveOpenProfID() == profID then
        -- Right profession already open - craft directly, no window churn.
        doCraft()
    else
        -- Need this profession open. Silent (audible = false): crafting must not
        -- play the open sound. The session is held open afterward.
        local openName = Addon.professionHarvester:openNameFor(profID, profName)
        professionWindow:open(openName, doCraft, false)
    end

    return true
end

--[[
  Wait for the ORDER to finish, then end the window session.

  DoTradeSkill(index, count) is ONE ORDER of COUNT CASTS - the client runs the
  repeat itself. Ending on the first UNIT_SPELLCAST_SUCCEEDED treated a cast as
  the order, so CRAFT:COMPLETE fired after cast one and everything downstream
  ran while the repeat was still going.

  An order ends when the asked-for casts have landed, or when the client stops
  queuing them. Field-captured, every cause:

    movement          UNIT_SPELLCAST_INTERRUPTED, four times over 150ms
    no bag space      UNIT_SPELLCAST_FAILED_QUIET, twice, after
                      UI_ERROR_MESSAGE "Inventory is full."
    out of reagents   NOTHING AT ALL - no cast event of any kind
    all casts done    no event; the count reaches zero

  Out of reagents is why UPDATE_TRADESKILL_RECAST is watched. It arrives in the
  same tick as every success that has another craft behind it, and not on the
  last one - so a success WITHOUT it is the client saying it will not queue
  another, whatever the reason. That covers the silent case without asking why
  the order stopped.

  A halt reaching none of these leaves `crafting` true for the session, which
  keeps the Stop button out and makes recentlyCrafted() true - so the next
  recipe learned from anywhere is attributed as a discovery.

  NO TIMEOUT ON THE ORDER. Cast times are per-recipe and a long order can run
  for minutes; any span picked here would be a guess about the slowest recipe,
  and being wrong ends the order early - which is the bug this replaces. The
  one timeout that remains guards a DIFFERENT thing: DoTradeSkill starting
  nothing at all.
]]
function crafter:awaitCraftEnd(count)
    local remaining = count or 1

    -- One teardown, shared with the abandon path. Reachable twice - a halt can
    -- arrive as FAILED and INTERRUPTED together - and events:unsubscribe errors
    -- on a nil id, so the second call must find nothing left to do.
    local function endOrder()
        if not self._castSuccessSub then return end
        self:abandonOrder()
        self:finish()
    end

    -- Set by UPDATE_TRADESKILL_RECAST, read on the frame after a success: the
    -- recast arrives about eight events later in the SAME tick, so a next-frame
    -- read sees it if it is coming.
    local recastSeen = false
    local announced = false

    -- A cast STARTING is what proves the order exists, and it is the earliest
    -- moment that is true: DoTradeSkill can decline outright - a missing tool -
    -- and then no cast event of any kind arrives. Waiting for the first SUCCESS
    -- instead left the order unannounced for the length of a cast, so the Stop
    -- button appeared only after the first craft had already finished.
    local function onStart(_, unit)
        if unit ~= "player" or announced then return end
        announced = true
        if self._castTimeout then
            self._castTimeout:Cancel()
            self._castTimeout = nil
        end
        events:emit("CRAFT:ORDER_START",
            { recipeID = craftingRecipe, count = remaining })
    end

    local function onSuccess(_, unit)
        if unit ~= "player" then return end
        remaining = remaining - 1
        -- The count lives here, where the order is run. A consumer showing it
        -- reads this rather than counting the same casts a second time.
        events:emit("CRAFT:PROGRESS", { remaining = remaining })
        if remaining <= 0 then
            endOrder()
            return
        end

        -- Casts still owed: the client only queues another if it can. No
        -- recast by the next frame means it cannot, and running out of
        -- reagents says so no other way.
        recastSeen = false
        C_Timer.After(0, function()
            if not recastSeen then endOrder() end
        end)
    end

    local function onHalt(_, unit)
        if unit ~= "player" then return end
        endOrder()
    end

    self._castStartSub      = events:subscribe("UNIT_SPELLCAST_START", onStart)
    self._castSuccessSub    = events:subscribe("UNIT_SPELLCAST_SUCCEEDED", onSuccess)
    self._castFailSub       = events:subscribe("UNIT_SPELLCAST_FAILED", onHalt)
    self._castQuietSub      = events:subscribe("UNIT_SPELLCAST_FAILED_QUIET", onHalt)
    self._castInterruptSub  = events:subscribe("UNIT_SPELLCAST_INTERRUPTED", onHalt)
    self._recastSub         = events:subscribe("UPDATE_TRADESKILL_RECAST", function()
        recastSeen = true
    end)

    -- REFUSAL GUARD. DoTradeSkill can decline the click outright - a missing
    -- tool, an anvil out of reach - and when it does, no cast event of any kind
    -- follows. `crafting` was set just before the call, and nothing would clear
    -- it: recentlyCrafted() reads that flag, so it would stay true and every
    -- recipe learned afterwards would be attributed to a discovery.
    --
    -- Cancelled by the first cast STARTING, not by the first success, so a
    -- recipe whose cast runs longer than this is never abandoned mid-cast.
    --
    -- Torn down without announcing completion: nothing was crafted, and
    -- CRAFT:COMPLETE means an order finished. Firing it here would run the band
    -- check and the cooldown sweep over a craft that never happened.
    self._castTimeout = C_Timer.NewTimer(5, function()
        self._castTimeout = nil
        if self._castSuccessSub then self:abandonOrder() end
    end)
end

--[[
  End the craft: close the window session and clear the guard.
]]
--[[
  Tear down a stranded order without announcing it as complete.

  A silent stop is not a completion: CRAFT:COMPLETE would run the band check and
  the cooldown sweep against an order that did not finish. Only the bookkeeping
  is cleared.
]]
function crafter:abandonOrder()
    if self._castTimeout then
        self._castTimeout:Cancel()
        self._castTimeout = nil
    end
    -- events:unsubscribe errors on a nil id, and these are already nil when an
    -- order ended normally before this ran.
    if self._castStartSub then events:unsubscribe(self._castStartSub) end
    if self._castSuccessSub then events:unsubscribe(self._castSuccessSub) end
    if self._castFailSub then events:unsubscribe(self._castFailSub) end
    if self._castQuietSub then events:unsubscribe(self._castQuietSub) end
    if self._castInterruptSub then events:unsubscribe(self._castInterruptSub) end
    if self._recastSub then events:unsubscribe(self._recastSub) end
    self._castStartSub, self._castSuccessSub, self._castFailSub = nil, nil, nil
    self._castQuietSub, self._castInterruptSub, self._recastSub = nil, nil, nil
    crafting = false
end

function crafter:finish()
    -- The session is held open by the crafting window for the active profession;
    -- a craft does not close it. Just clear the in-progress flag and announce.
    crafting = false
    lastCraftEndedAt = GetTime()
    events:emit("CRAFT:COMPLETE", {})
end

--[[
  Whether a craft is in progress or ended within the last two seconds. This
  classifies a learn event as a discovery (crafts are the only discovery
  mechanism) versus a trainer or bag learn. The two-second window exists
  because UNIT_SPELLCAST_SUCCEEDED (which ends the craft) is client-immediate
  while NEW_RECIPE_LEARNED is a server message - the discovery a craft procs
  arrives a round-trip later. WHICH recipe discovered it needs no crafter
  state at all: crafting acts on the selection, and a discovery does not
  change the selection - the current recipe is the discoverer.

  @return boolean
]]
--[[
  The recipe the open order is crafting, or nil between orders.

  @return number|nil - recipeID
]]
function crafter:currentRecipe()
    return craftingRecipe
end

function crafter:recentlyCrafted()
    if crafting then return true end
    return lastCraftEndedAt ~= nil and (GetTime() - lastCraftEndedAt) <= 2.0
end

function crafter:initialize()
    utils = Addon.utils
    events = Addon.events
    ledger = Addon.ledger
    professionWindow = Addon.professionWindow
    recipeCatalog = Addon.recipeCatalog

    if not utils or not events or not ledger or not professionWindow or not recipeCatalog then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444crafter: Missing dependencies|r")
        return false
    end

    return true
end

Addon.crafter = crafter

if Addon.registerModule then
    Addon.registerModule("crafter", {"utils", "events", "ledger", "professionWindow", "recipeCatalog"}, function()
        return crafter:initialize()
    end)
end
