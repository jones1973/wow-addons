--[[
  logic/professionTools.lua
  Crafty profession tool actions (wrapper)

  The only thing that touches the tool data tables. The UI works in tool handles
  ({ id, kind }) and never sees the storage shape.

  Entry point is a profession id: forProfession(skillLine) returns the handles
  for that profession's tools. Per handle, the wrapper answers name/icon (derived
  from the id) and availability (kind-dispatched).

  The id-vs-spell mechanism is internal: the user sees one icon, enabled when
  usable, with a tooltip explaining why if not.

  Dependencies: none (reads Addon.data.toolActions / Addon.data.professionTools + WoW API)
  Casting is deliberately NOT here: CastSpellByName and UseItemByName are
  protected, and calling them from addon code is refused. A tool is cast by
  the secure caster in ui/activityRail.lua, which carries the tool's name
  as a button attribute so the click itself performs it.

  Exports: Addon.profTools
]]

local ADDON_NAME, Addon = ...

local profTools = {}

-- Item-backed kinds live in bags ("item" acts on use; "target" serves a
-- pending cast). Spell tools are known, not carried.
local function itemBacked(tool)
    return tool.kind == "item" or tool.kind == "target"
end

-- Tool handles for a profession (array of { id, kind }, possibly empty). kind is
-- resolved from toolActions, keyed by the id we start from - no reverse search.
function profTools:forProfession(skillLine)
    local ids = Addon.data.professionTools and Addon.data.professionTools[skillLine]
    if not ids then return {} end
    local out = {}
    for _, id in ipairs(ids) do
        local kind = Addon.data.toolActions and Addon.data.toolActions[id]
        if kind then
            out[#out + 1] = { id = id, kind = kind }
        end
    end
    return out
end

-- Display name, derived from the id (correctly localized; cannot drift).
function profTools:name(tool)
    if not tool then return "" end
    if not itemBacked(tool) then
        local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(tool.id)
        return (info and info.name) or ("spell:" .. tool.id)
    else
        local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(tool.id)
        return name or ("item:" .. tool.id)
    end
end

-- Display icon texture, derived from the id.
function profTools:icon(tool)
    if not tool then return nil end
    if not itemBacked(tool) then
        return C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(tool.id)
    else
        return select(5, GetItemInfoInstant(tool.id))
    end
end

-- Bag quantity for item-backed tools; nil for spell tools (a known spell has
-- no count). Drives the tool button's stack badge.
function profTools:count(tool)
    if not tool or not itemBacked(tool) then return nil end
    return GetItemCount(tool.id)
end

--[[
  The tool's active cooldown as GetTime()-based start and duration, or nil.

  Both kinds have one and they are read differently: a spell tool through
  C_Spell.GetSpellCooldown, which returns a table, and an item tool through
  C_Container.GetItemCooldown, which returns three values. Kind already decides
  every other behaviour here, so it decides this too.

  @param tool table
  @return number|nil start, number|nil duration
]]
function profTools:cooldown(tool)
    if not tool then return nil end
    local start, duration
    if not itemBacked(tool) then
        local info = C_Spell and C_Spell.GetSpellCooldown
                     and C_Spell.GetSpellCooldown(tool.id)
        if info then start, duration = info.startTime, info.duration end
    elseif C_Container and C_Container.GetItemCooldown then
        start, duration = C_Container.GetItemCooldown(tool.id)
    end
    -- A duration of 0 is "not on cooldown", and the global cooldown is not
    -- worth a swipe on a station button.
    if not start or not duration or duration <= 1.5 then return nil end
    if start + duration <= GetTime() then return nil end
    return start, duration
end

-- Whether the tool can currently be used: a known spell, or an item in bags.
-- Drives enabled/disabled - never hides the control. An id absent on this client
-- (e.g. the MoP-only anvil on TBC) reads as unavailable here, which is correct.
function profTools:isAvailable(tool)
    if not tool then return false end
    if not itemBacked(tool) then
        return IsSpellKnown(tool.id) == true or IsPlayerSpell(tool.id) == true
    else
        return GetItemCount(tool.id) > 0
    end
end

-- Why a tool is unavailable, for the disabled tooltip.
function profTools:unavailableReason(tool)
    if not tool then return "" end
    if not itemBacked(tool) then
        return "You have not learned " .. self:name(tool) .. "."
    else
        return "Requires " .. self:name(tool) .. " in your bags."
    end
end

-- Trigger the tool: cast the spell, use the item, or - for a target tool -
-- serve the pending cast. A target tool clicked with nothing awaiting a
-- target does NOT use the item: that click carries no action here (the UI
-- answers it with guidance toward the craft verb).
-- UseItemByName is the classic-native use call (C_Item.UseItemByID is
-- retail-only - field-confirmed nil on this client, 2026-07). It runs inside
-- the user's click, a hardware event - field-confirmed to both use items and
-- complete a pending enchant target from there.
function profTools:initialize()
    return true
end

Addon.profTools = profTools

if Addon.registerModule then
    Addon.registerModule("profTools", {}, function()
        return profTools:initialize()
    end)
end

return profTools
