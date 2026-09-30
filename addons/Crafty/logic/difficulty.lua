--[[
  logic/difficulty.lua
  Crafty recipe difficulty

  Derives a recipe's difficulty band from the character's profession rank against
  the recipe's static color thresholds (recipeCatalog:colors = {orange, yellow,
  green, grey} skill levels). Difficulty is NOT stored - it is a function of
  (rank, thresholds) and is computed at display time:

    - the current character uses their live/stored rank
    - an alt uses that alt's stored rank

  Storing the difficulty would freeze it: a recipe learned at low rank (orange)
  stays orange in the saved value even after leveling past it. Deriving from rank
  recomputes correctly every render and works for characters who are not logged
  in (the cross-character view), which a live GetTradeSkillInfo string cannot do.

  Threshold semantics (colors = {o, y, g, grey}):
    rank <  o     -> unavailable  (skill too low to craft)
    o <= rank < y -> orange       (guaranteed skill-up)
    y <= rank < g -> yellow       (good skill-up chance)
    g <= rank < grey -> green     (low skill-up chance)
    rank >= grey  -> grey         (no skill-up)

  Colors come from theme tokens so they match the rest of the UI.

  Dependencies: theme
  Exports: Addon.difficulty
]]

local ADDON_NAME, Addon = ...

local difficulty = {}

local theme

-- Difficulty bands.
difficulty.UNAVAILABLE = "unavailable"
difficulty.ORANGE      = "orange"
difficulty.YELLOW      = "yellow"
difficulty.GREEN       = "green"
difficulty.GREY        = "grey"

-- Which colors[] threshold a band begins at. The colors array is
-- {orange, yellow, green, grey}, so a band's entry value is the rank at which
-- the recipe first shows that band.
difficulty.BAND_INDEX = {
    [difficulty.ORANGE] = 1,
    [difficulty.YELLOW] = 2,
    [difficulty.GREEN]  = 3,
    [difficulty.GREY]   = 4,
}

--[[
  Derive the difficulty band from a character's rank and the recipe's static
  color thresholds.

  @param rank number - the character's current rank in the recipe's profession
  @param colors table - {orange, yellow, green, grey} threshold skill levels
  @return band string (one of the constants above), or nil if inputs are missing
    (no rank for this character, or no thresholds for this recipe)
]]
--[[
  A recipe's band thresholds in the scale the player reads.

  The floor is the LEARN requirement, not colors[1]. They coincide for most
  recipes - one that is orange the moment you acquire it starts its orange band
  where it becomes available - but a recipe acquired past its orange range has
  no orange tier at all and carries colors[1]=0 while still being gated (Smelt
  Tin: bands 40/57/75, trained at 50, arrives yellow). The floor is what you can
  ACQUIRE at; the orange band is simply floor..yellow, empty when that is empty.
  The game gates learning on the reported rank, so the floor is already in that
  scale and does not move.

  The other three are difficulty boundaries, written in trained skill, and
  shifting them by the character's skill bonus is the whole reconciliation. It
  lives here because this is the only module that reads stored thresholds.
  Builds a new table - the catalog's colors are shared static.

  @param colors table|nil - {orange, yellow, green, grey} in trained skill
  @param learn number|nil - the skill the recipe can be acquired at
  @param bonus number - the character's skill bonus in the recipe's profession
  @return table|nil - {floor, yellow, green, grey} in reported skill
]]
function difficulty:thresholds(colors, learn, bonus)
    if not colors then return nil end
    return { learn or colors[1], colors[2] + bonus, colors[3] + bonus, colors[4] + bonus }
end

function difficulty:bandForSkill(rank, colors)
    if not rank or not colors then return nil end
    local o, y, g, grey = colors[1], colors[2], colors[3], colors[4]
    if not o then return nil end
    -- A stored threshold is the FIRST rank of the band it names, matching the
    -- semantics at the top of this file: a yellow of 30 means yellow from 30.
    -- Field-verified against the game's own coloring - Spice Bread turned
    -- yellow, green and grey at exactly its stored 30/35/40.
    if rank < o then return self.UNAVAILABLE end
    if grey and rank >= grey then return self.GREY end
    if g and rank >= g then return self.GREEN end
    if y and rank >= y then return self.YELLOW end
    return self.ORANGE
end

--[[
  Return the {r,g,b} color for a difficulty band, or nil if no band (caller uses
  a default).

  @param band string - one of the band constants (from bandForSkill)
]]
function difficulty:colorForBand(band)
    if not band then return nil end

    local t = theme.tokens.DIFFICULTY
    if band == self.UNAVAILABLE then
        return t.UNAVAILABLE.r, t.UNAVAILABLE.g, t.UNAVAILABLE.b
    elseif band == self.ORANGE then
        return t.ORANGE.r, t.ORANGE.g, t.ORANGE.b
    elseif band == self.YELLOW then
        return t.YELLOW.r, t.YELLOW.g, t.YELLOW.b
    elseif band == self.GREEN then
        return t.GREEN.r, t.GREEN.g, t.GREEN.b
    else
        return t.GREY.r, t.GREY.g, t.GREY.b
    end
end

--[[
  Where the character sits within a recipe's difficulty progression: the band
  they are in, the skill level at which it next changes, the band it becomes,
  and how far through the current band they are (0 at its start, 1 at its end).

  This is what turns "orange" into "orange, 3 skill-ups from yellow, 60% of the
  way there" - the progression the game hides.

  @param rank number - current rank in the recipe's profession
  @param colors table - {orange, yellow, green, grey} threshold skill levels
  @return table or nil:
    {
      band       = current band constant,
      nextBand   = the band it becomes (nil if already grey),
      nextAt     = skill level of the next transition (nil if grey),
      toNext     = skill points until the next transition (nil if grey),
      progress   = 0..1 through the current band (nil if band has no span),
    }
]]
function difficulty:transition(rank, colors)
    if not rank or not colors then return nil end
    local o, y, g, grey = colors[1], colors[2], colors[3], colors[4]
    if not o then return nil end

    local band = self:bandForSkill(rank, colors)
    if not band then return nil end

    -- The (start, next-threshold, next-band) triple for the band we are in.
    local start, nextAt, nextBand
    if band == self.UNAVAILABLE then
        start, nextAt, nextBand = nil, o, self.ORANGE
    elseif band == self.ORANGE then
        start, nextAt, nextBand = o, y, self.YELLOW
    elseif band == self.YELLOW then
        start, nextAt, nextBand = y, g, self.GREEN
    elseif band == self.GREEN then
        start, nextAt, nextBand = g, grey, self.GREY
    else -- GREY
        start, nextAt, nextBand = grey, nil, nil
    end

    local toNext, progress
    if nextAt then
        toNext = nextAt - rank
        if start and nextAt > start then
            progress = (rank - start) / (nextAt - start)
            if progress < 0 then progress = 0 elseif progress > 1 then progress = 1 end
        end
    end

    return {
        band     = band,
        nextBand = nextBand,
        nextAt   = nextAt,
        toNext   = toNext,
        progress = progress,
    }
end

function difficulty:initialize()
    theme = Addon.theme
    if not theme then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444difficulty: Missing dependencies|r")
        return false
    end
    return true
end

Addon.difficulty = difficulty

if Addon.registerModule then
    Addon.registerModule("difficulty", {"theme"}, function()
        return difficulty:initialize()
    end)
end
