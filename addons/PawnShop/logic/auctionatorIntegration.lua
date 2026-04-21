--[[
  logic/auctionatorIntegration.lua
  Auctionator Addon Integration

  Sends item names to Auctionator as a temporary shopping list. Used when
  the user Ctrl-clicks a row in the Pawn Shop grid: we collect the item
  names (one for single rows, two for pair rows) and hand them off.

  Dispatch mirrors how Skillet's Auctionator plugin does it:
    - Classic/TBC Auctionator exposes Atr_SelectPane + Atr_SearchAH
    - Retail Auctionator exposes Auctionator.API.v1.MultiSearchExact or
      ...MultiSearch

  We prefer exact-match on retail since our items have specific names with
  random suffixes ("of the Owl", etc.).

  Dependencies: utils
  Exports: Addon.auctionatorIntegration
]]

local ADDON_NAME, Addon = ...

local auctionatorIntegration = {}

-- Module references
local utils

-- Default list label used if caller doesn't supply one. Shows up in
-- Auctionator's shopping-list dropdown.
local DEFAULT_LIST_LABEL = "Pawn Shop"

-- ============================================================================
-- AVAILABILITY
-- ============================================================================

--[[
  Returns true if Auctionator is loaded and exposes one of the search APIs
  we know how to drive. Useful for gating UI (gray out the "Send to
  Auctionator" button if Auctionator isn't present).

  @return boolean
]]
function auctionatorIntegration:isAvailable()
    if Atr_SelectPane and Atr_SearchAH then return true end
    if Auctionator and Auctionator.API and Auctionator.API.v1 then
        return Auctionator.API.v1.MultiSearchExact ~= nil
            or Auctionator.API.v1.MultiSearch ~= nil
    end
    return false
end

-- ============================================================================
-- SEND TO AUCTIONATOR
-- ============================================================================

--[[
  Hand a list of item names to Auctionator as a temporary shopping list.

  @param names table - array of item name strings (1+ entries)
  @param label string|nil - optional shopping-list display name
  @return boolean - true if a search API was successfully invoked
]]
function auctionatorIntegration:sendNames(names, label)
    if not names or #names == 0 then return false end
    label = label or DEFAULT_LIST_LABEL

    -- TBC/Classic Auctionator. BUY_TAB = 3 per Skillet's plugin.
    if Atr_SelectPane and Atr_SearchAH then
        Atr_SelectPane(3)
        Atr_SearchAH(label, names)
        return true
    end

    -- Retail Auctionator API v1.
    if Auctionator and Auctionator.API and Auctionator.API.v1 then
        if Auctionator.API.v1.MultiSearchExact then
            Auctionator.API.v1.MultiSearchExact(label, names)
            return true
        elseif Auctionator.API.v1.MultiSearch then
            Auctionator.API.v1.MultiSearch(label, names)
            return true
        end
    end

    utils:chat("Auctionator search API not found; is Auctionator loaded?")
    return false
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function auctionatorIntegration:initialize()
    utils = Addon.utils
    if not utils then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444auctionatorIntegration: Missing utils|r")
        return false
    end
    return true
end

if Addon.registerModule then
    Addon.registerModule("auctionatorIntegration", {"utils"}, function()
        return auctionatorIntegration:initialize()
    end)
end

Addon.auctionatorIntegration = auctionatorIntegration
return auctionatorIntegration
