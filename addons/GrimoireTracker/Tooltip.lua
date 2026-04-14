---------------------------------------------------------------------------
-- GrimoireTracker  -  Tooltip.lua
-- Injects grimoire rank / availability / cost into pet spell tooltips.
--
-- Format:
--   Maxed:     "7/7"  (green)
--   Available: "6/7 · Available · 85s"  (green + gold)
--   Future:    "6/7 · Next at 60 · 1g 20s"  (red + gold)
--   Unscanned: "?/7 · Summon pet to scan"  (orange)
---------------------------------------------------------------------------

local GT = GrimoireTracker

-- Colors (tooltip-safe, no |c codes needed - use AddLine color args)
local C_GREEN  = { 0, 1, 0 }
local C_RED    = { 1, 0.27, 0.27 }
local C_ORANGE = { 1, 0.6, 0 }
local C_GOLD   = { 0.9, 0.8, 0.5 }

---------------------------------------------------------------------------
-- Build the tooltip line for a given spell + current rank
---------------------------------------------------------------------------
local function BuildTooltipLine(spellName, currentRank)
    local pet = GT:FindPetForSpell(spellName)
    if not pet then return nil, nil end

    local ranks = GT.GRIMOIRE_RANKS[pet][spellName]
    if not ranks then return nil, nil end

    local maxRank    = ranks[#ranks][1]
    local isBaseline = GT.BASELINE[pet] and GT.BASELINE[pet][spellName]

    -- For baseline spells, the actual max rank includes the auto-learned 1.
    -- But GRIMOIRE_RANKS already lists the highest vendor rank as the max.
    -- currentRank comes from the spellbook (always >= 1 for visible spells).

    -- If maxed
    if currentRank >= maxRank then
        return currentRank .. "/" .. maxRank, C_GREEN
    end

    local playerLevel = UnitLevel("player")

    -- Find next rank above currentRank
    local nextRank, nextLevel
    for _, entry in ipairs(ranks) do
        if entry[1] > currentRank then
            nextRank  = entry[1]
            nextLevel = entry[2]
            break
        end
    end

    if not nextRank then
        -- Shouldn't happen, but safety
        return currentRank .. "/" .. maxRank, C_GREEN
    end

    local line = currentRank .. "/" .. maxRank

    if playerLevel >= nextLevel then
        line = line .. " \194\183 |cff00ff00Available|r"
    else
        line = line .. " \194\183 |cffff4444Next at " .. nextLevel .. "|r"
    end

    -- Append cost if cached
    local cost = GT:GetPrice(pet, spellName, nextRank)
    if cost and cost > 0 then
        line = line .. " \194\183 " .. GT:FormatCostText(cost)
    end

    if playerLevel >= nextLevel then
        return line, C_GREEN
    else
        return line, C_GOLD
    end
end

---------------------------------------------------------------------------
-- Hook: Pet Spellbook tooltips  (SetSpellBookItem)
---------------------------------------------------------------------------
hooksecurefunc(GameTooltip, "SetSpellBookItem", function(self, slot, bookType)
    if bookType ~= "pet" then return end
    if not GT.GRIMOIRE_RANKS then return end

    local name, subText = GetSpellBookItemName(slot, bookType)
    if not name then return end

    -- Only process spells we track
    if not GT:FindPetForSpell(name) then return end

    -- Get current rank from subtext
    local currentRank = 1
    if subText and subText ~= "" then
        currentRank = tonumber(subText:match("(%d+)")) or 1
    end

    local line, color = BuildTooltipLine(name, currentRank)
    if line then
        self:AddLine(" ")  -- blank separator
        self:AddLine(line, color[1], color[2], color[3])
        self:Show()
    end
end)

---------------------------------------------------------------------------
-- Hook: Pet Action Bar tooltips  (SetPetAction)
---------------------------------------------------------------------------
if GameTooltip.SetPetAction then
    hooksecurefunc(GameTooltip, "SetPetAction", function(self, slot)
        if not GT.GRIMOIRE_RANKS then return end

        local name = GetPetActionInfo(slot)
        if not name then return end

        -- Only process spells we track
        if not GT:FindPetForSpell(name) then return end

        -- Get current rank from the pet spellbook
        local currentRank = 1
        local numPetSpells = HasPetSpells()
        if numPetSpells then
            for i = 1, numPetSpells do
                local sName, sSubText = GetSpellBookItemName(i, "pet")
                if sName == name then
                    if sSubText and sSubText ~= "" then
                        currentRank = tonumber(sSubText:match("(%d+)"))
                                      or 1
                    end
                    break
                end
            end
        end

        local line, color = BuildTooltipLine(name, currentRank)
        if line then
            self:AddLine(" ")
            self:AddLine(line, color[1], color[2], color[3])
            self:Show()
        end
    end)
end