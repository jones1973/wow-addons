--[[
  core/npcNameFilter.lua
  Junk-NPC-name detection

  Single source of truth for "is this NPC name an internal data
  artifact that shouldn't surface to the user?"

  Consumers (nameTypeahead, itemDropIndex's resolveStaging) call
  :isJunk(name) to filter NPC names returned from Questie.

  Public API:
    npcNameFilter:isJunk(name)  → boolean

  Exports: Addon.npcNameFilter
]]

local _, Addon = ...

local npcNameFilter = {}

-- ============================================================================
-- PATTERNS
-- ============================================================================
--
-- Each entry is a Lua pattern. CI_PATTERNS are matched against the
-- name lower-cased; CS_PATTERNS are matched against the original
-- name. Hits → junk.

-- Case-insensitive substring patterns. Most filters live here.
local CI_PATTERNS = {
    -- Broad junk-class words. Real NPCs containing these strings as
    -- substrings are rare; data-artifact mobs containing them are
    -- frequent.
    "quest",
    "credit",
    "dummy",
    "doodad",
    "bunny",
    "trigger",
    "placeholder",

    -- Bracketed/parenthesized marker tags.
    "%[ph%]",
    "%(ph%)",
    "dnd",

    -- "test" matched only at the start of a word so we don't catch
    -- "fastest", "contest", etc. Lua frontier pattern triggers when
    -- the previous char is not a word char and the next is.
    "%f[%w]test",

    -- "test" followed by "!" or a digit catches dev/test names like
    -- "BurkeTest01" and "Druid 40 (fastest!)" which the word-start
    -- pattern misses (the "test" is mid-word).
    "test[!%d]",
}

-- Case-sensitive patterns. UNUSED is here because Questie's data
-- distinguishes capitalised debug markers (UNUSED, NOT USED) from
-- common lowercase use of the same letters in real names.
local CS_PATTERNS = {
    "UNUSED",
}

-- Prefix-style internal markers preserved from earlier rounds.
-- Matched against the original name, case-sensitive, anchored.
local CS_PREFIX_PATTERNS = {
    "^%[DNT%]",
    "^<TXT>",
    "^<NYI>",
    "^<BETA>",
}

-- ============================================================================
-- API
-- ============================================================================

--[[
  Return true if the given name matches any junk pattern. nil or
  empty name → true (treat as junk so it doesn't surface anywhere).
]]
function npcNameFilter:isJunk(name)
    if not name or name == "" then return true end

    local lower = name:lower()
    for _, pat in ipairs(CI_PATTERNS) do
        if lower:find(pat) then return true end
    end

    for _, pat in ipairs(CS_PATTERNS) do
        if name:find(pat) then return true end
    end

    for _, pat in ipairs(CS_PREFIX_PATTERNS) do
        if name:find(pat) then return true end
    end

    return false
end

function npcNameFilter:initialize()
    return true
end

Addon.npcNameFilter = npcNameFilter
return npcNameFilter
