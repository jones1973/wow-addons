--[[
  nodeWatch - proof of concept.

  Hovering a gathering node you cannot work yet - ore or herb - says what it
  needs, where you are, and how far that is.

  A world object has no mouseover event. UPDATE_MOUSEOVER_UNIT is units only,
  and CURSOR_CHANGED is the drag cursor - Blizzard pairs it with GetCursorInfo
  for what you are carrying, not what you are pointing at. The only surface that
  names a vein is GameTooltip, so this hooks the tooltip's show and reads the
  first line. That is a hook rather than a subscription, and the reliability
  profile is different from everything else Crafty listens to.

  Gathering reach is rank + itemBonus, not rank + bonus. A Gnomish Army Knife
  raises what you can WORK without moving what colour anything is, which is why
  the harvester keeps the two apart. If a node you can reach still reports, that
  separation is wrong and this will show it.

  Dependencies: ledger, utils
  Exports: Addon.nodeWatch
]]

local ADDON_NAME, Addon = ...

local ledger, utils

local nodeWatch = {}

-- The tooltip re-shows continuously while the cursor rests on a node, so OnShow
-- is not "a new node" - it is "the tooltip is still up". Suppress only a repeat
-- of the SAME answer within a few seconds.
--
-- Keying on the node NAME is what the tooltip forces - it is the only thing
-- identifying a world object - so every Gromsblood is the same key and a memory
-- with no expiry would answer once and stay silent for the rest of a gathering
-- route. Hence the interval: not a guard against a failure state, but the span
-- over which repeating a number you have just read adds nothing.
--
-- Reach sits OUTSIDE the interval on purpose. A skill point changes the answer,
-- and waiting out a timer to say so would be wrong.
local REPEAT_QUIET = 5   -- seconds
local saidNode, saidReach, saidAt = nil, nil, 0

local function report()
    -- The tooltip belongs to a world object only when nothing owns it as UI and
    -- it is not describing a unit. Both are cheap, and both are wrong to skip:
    -- the tooltip is busy with frames constantly.
    if GameTooltip:GetUnit() then return end

    local line = GameTooltipTextLeft1 and GameTooltipTextLeft1:GetText()
    local node = line and Addon.data.gatheringNodes[line]
    if not node then return end

    -- Node names are unique across both gathering professions, so the name
    -- alone says which skill applies. Nil rank means the character does not
    -- have that profession at all - a different answer than "not yet", and not
    -- this module's to give.
    local rank, _, itemBonus = ledger:skillIn(node.prof)
    if not rank then return end

    local reach = rank + itemBonus
    if reach >= node.req then return end
    if line == saidNode and reach == saidReach
            and GetTime() - saidAt < REPEAT_QUIET then
        return
    end
    saidNode, saidReach, saidAt = line, reach, GetTime()

    utils:chat(line .. " needs " .. node.req .. " - you are at " .. reach
               .. (itemBonus > 0 and (" (" .. rank .. " +" .. itemBonus .. ")") or "")
               .. ", " .. (node.req - reach) .. " to go")
end

function nodeWatch:initialize()
    ledger = Addon.ledger
    utils  = Addon.utils

    GameTooltip:HookScript("OnShow", report)
    return true
end

if Addon.registerModule then
    Addon.registerModule("nodeWatch",
        {"ledger", "utils"},
        function()
            return nodeWatch:initialize()
        end)
end

Addon.nodeWatch = nodeWatch
return nodeWatch
