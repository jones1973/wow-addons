--[[
  logic/professionHarvester.lua
  Crafty Profession Harvester

  Opens each of the character's professions in sequence, off-screen, scans it
  into the ledger, then restores the UI. This is how Crafty populates the
  current character's recipe knowledge without the player manually opening every
  profession.

  Why a sequencer and not a loop: opening a profession is asynchronous (the cast
  requests the window; the window opens and fires TRADE_SKILL_SHOW when ready)
  and opening one profession closes another. So professions are queued and
  advanced one at a time, each driven by the update event - the same shape PAO
  uses to prime achievements.

  Identity comes from GetProfessionInfo (name at position 1, skill-line id at
  position 7); GetTradeSkillLine does not return the id reliably on MoP, so the
  harvester is the authority on which profession it opened and passes that
  identity into the scan.

  Firing model (build 1): runs once per session, on first Crafty open. Only
  professions not yet scanned this session are queued. The user's prior UI is
  restored by closing the trade skill window and leaving Crafty's window up.

  Dependencies: events, professionWindow, recipeScanner
  Exports: Addon.professionHarvester
]]

local ADDON_NAME, Addon = ...

local professionHarvester = {}

local events, professionWindow, recipeScanner

-- Harvest queue and progress.
local queue = {}           -- array of { profID, name, rank, category }
local active = nil         -- the profession currently being opened/scanned
local running = false


-- Gathering professions whose window cannot be opened/scanned (opening never
-- fires TRADE_SKILL_SHOW). This is a PROPERTY of the profession, reported as
-- `windowed = false`, not a reason to omit it: the character has the skill
-- whether or not Crafty can open anything for it, and a herbalist at 218 must
-- not read as a character without Herbalism. Mining (186) is NOT here - it has
-- a craftable smelting window (see OPEN_SPELL_OVERRIDE).
local WINDOWLESS_GATHERING = {
    [182] = true,  -- Herbalism
    [393] = true,  -- Skinning
    [356] = true,  -- Fishing
    [794] = true,  -- Archaeology
}

-- A profession whose craftable window is opened by casting a DIFFERENT spell
-- than the profession itself. There is no DB2 flag for "this skill has a
-- crafting side-skill", so this single fact is hardcoded. profID -> open spell.
-- Mining's craftable window is Smelting (2656); casting "Mining" opens nothing.
local OPEN_SPELL_OVERRIDE = {
    [186] = 2656,  -- Mining -> Smelting
}

-- Resolve the name to cast to OPEN a profession's window. Public so other
-- open-callers (the live session, the crafter) share this one substitution
-- rather than duplicating it. Normally the profession's own name; for an
-- override, the override spell's name.
function professionHarvester:openNameFor(profID, profName)
    local override = OPEN_SPELL_OVERRIDE[profID]
    if override then
        return C_Spell.GetSpellName(override) or profName
    end
    return profName
end

local function openNameFor(profID, profName)
    return professionHarvester:openNameFor(profID, profName)
end

--[[
  Enumerate the character's CURRENT craftable professions from live game state.
  Reads GetProfessions / GetProfessionInfo every call, so profession changes are
  reflected immediately. Windowless gathering professions are excluded. Each
  record carries the open name (with the Mining->Smelting substitution applied)
  so every consumer opens the right window without knowing the special case.

  EVERY profession the character has, including the ones whose window cannot be
  opened. Callers asking about the CHARACTER (what is my skill, what is this
  called, did a profession appear or vanish) want all of them; callers asking
  about opening or crafting something filter on `windowed`. Both questions are
  real and each caller means exactly one, so answering only the second for
  everyone made a skill you have indistinguishable from one you do not.

  GetProfessions returns six FIXED slots - prof1, prof2, archaeology, fishing,
  cooking, firstAid - with nil holes for professions the character lacks. Slots 1
  and 2 are primary, cooking and first aid are secondary, archaeology and fishing
  are their own. Note even primary slots can be gathering (Herbalism/Mining), so
  windowedness is by skill line, not slot.

  @return array of { profID, name, openName, rank, maxRank, bonus, itemBonus,
                     windowed, category }
]]
-- A racial skill bonus (Goblin +15 Alchemy, Gnome +15 Engineering, Blood Elf
-- +10 Enchanting, and so on) is folded into both the reported rank and the cap,
-- so part of the reported rank is not trained skill. Every tier cap is a
-- multiple of 75 and every bonus is smaller than 75, so whatever the cap carries
-- above the ladder is exactly that part.
--
-- An item's skill bonus is a different thing and is not this. It arrives in
-- GetProfessionInfo's rankModifier, leaves the reported rank as the true trained
-- skill, and the game does not apply it to recipe difficulty - a miner at 65
-- wearing +10 still sees the colors of 65. Nothing here wants it.
local TIER_CAP_STEP = 75

local function skillBonus(maxRank)
    return maxRank % TIER_CAP_STEP
end

function professionHarvester:enumerate()
    local p1, p2, arch, fish, cook, firstAid = GetProfessions()
    local indices    = { p1, p2, arch, fish, cook, firstAid }
    local categories = { "primary", "primary", "secondary", "secondary",
                         "secondary", "secondary" }

    local out = {}
    for slot = 1, 6 do
        local i = indices[slot]
        if i then
            -- GetProfessionInfo: name(1), icon(2), rank(3), maxRank(4),
            -- numAbilities(5), spelloffset(6), skillLine(7), rankModifier(8).
            -- rank and maxRank are as the game reports them - what the band
            -- shows, and what recipe learn levels gate on.
            local name, icon, rank, maxRank, _, _, skillLineID, rankModifier = GetProfessionInfo(i)
            if name and skillLineID then
                out[#out + 1] = {
                    profID   = skillLineID,
                    name     = name,
                    icon     = icon,
                    openName = openNameFor(skillLineID, name),
                    rank     = rank,
                    maxRank  = maxRank,
                    bonus    = skillBonus(maxRank),
                    -- An item's skill bonus, kept separate from `bonus` and
                    -- deliberately not part of it. It does not move recipe
                    -- difficulty - a miner at 65 wearing +10 still sees the
                    -- colors of 65 - but it does extend GATHERING reach, which
                    -- is a different question with a different answer.
                    itemBonus = rankModifier,
                    windowed  = not WINDOWLESS_GATHERING[skillLineID],
                    category = categories[slot],
                }
            end
        end
    end
    return out
end

-- ============================================================================
-- INTERNAL: the sequencer
--
-- The harvester walks its queue, opening each profession and scanning it when
-- ready. Opening a DIFFERENT profession auto-closes the previous, so no close is
-- needed between professions. But casting a profession's open-spell when THAT
-- profession's window is already open TOGGLES it closed - so when the profession
-- we want is already the open one (the common case: the live session holds the
-- active profession open), we scan it directly without casting.
-- ============================================================================

--[[
  Scan the profession in `active` (its window is open and ready), then advance.
]]
local openNext  -- forward declaration (defined below; referenced here)
local function scanActiveAndAdvance()
    local scanned = active
    active = nil
    recipeScanner:scanOpen(scanned.profID, scanned.name, scanned.rank,
        scanned.category)
    openNext()
end

--[[
  Open the next queued profession, scanning happens once its window is ready.
  When the queue is empty, the harvest is done: close the last window and finish.
]]
openNext = function()
    active = table.remove(queue, 1)
    if not active then
        professionWindow:closeCurrent()  -- final window has no next-open to close it
        professionHarvester:finish()
        return
    end

    -- If the profession we want is already the open one, its window is ready -
    -- scan it directly. Casting its open-spell would toggle it closed. The open
    -- path hides the frame off-screen; since we skip it here, hide explicitly so
    -- an already-on-screen window doesn't stay visible.
    if professionWindow:liveOpenProfID() == active.profID then
        professionWindow.hideFrameOffscreen()
        scanActiveAndAdvance()
        return
    end

    professionWindow:open(active.openName, scanActiveAndAdvance, false)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Build the queue from the character's professions and start the harvest. Used
  by the rescan control - a deliberate, hardware-blessed request, so its chained
  profession-opening casts are permitted. (There is no automatic on-open harvest;
  professions are scanned lazily when made active.)
]]
--[[
  Whether a sweep is in progress.

  A sweep opens and scans every profession in turn, so anything that reacts to a
  scan by addressing the player - rather than by recording a fact - has to know
  the difference between "you opened this" and "we walked past it".

  @return boolean
]]
function professionHarvester:isSweeping()
    return running
end

function professionHarvester:run(force)
    if running then return end

    active = nil
    -- Windowed only: the queue exists to OPEN each profession in turn.
    queue = {}
    for _, prof in ipairs(self:enumerate()) do
        if prof.windowed then queue[#queue + 1] = prof end
    end
    if #queue == 0 then return end

    running = true
    professionWindow:beginSession()
    openNext()
end

--[[
  Finish the harvest: end the window session, mark done for the session.
]]
function professionHarvester:finish()
    professionWindow:endSession()
    running = false
    events:emit("HARVEST:COMPLETE", {})
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function professionHarvester:initialize()
    events = Addon.events
    recipeScanner = Addon.recipeScanner
    professionWindow = Addon.professionWindow

    if not events or not professionWindow then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444professionHarvester: Missing dependencies|r")
        return false
    end

    return true
end

if Addon.registerModule then
    Addon.registerModule("professionHarvester", {"events", "professionWindow", "recipeScanner"}, function()
        return professionHarvester:initialize()
    end)
end

Addon.professionHarvester = professionHarvester
return professionHarvester
