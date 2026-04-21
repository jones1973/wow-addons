--[[
  logic/linkKey.lua
  Stable Item Link Deduplication Key

  Auction item links include a per-listing uniqueID that makes every auction
  appear unique even when the items are otherwise identical. This module
  extracts a stable key (itemID + enchantID + 4 gem slots + suffixID) suitable
  for deduping "same equippable thing" across multiple auction listings.

  Dependencies: none
  Exports: Addon.linkKey
]]

local ADDON_NAME, Addon = ...

local linkKey = {}

--[[
  Extract a stable dedup key from an item link.
  Keeps the first 7 fields of the item payload - itemID through suffixID -
  which together define a unique equippable thing. Drops uniqueID and level
  which vary per-listing.

  @param link string - Full item link or nil
  @return string - Stable key, or the original link if unparseable, or nil if input nil
]]
function linkKey:compute(link)
    if not link then return nil end
    local payload = link:match("|Hitem:([^|]+)|h")
    if not payload then return link end
    local parts = {}
    for p in (payload .. ":"):gmatch("([^:]*):") do
        table.insert(parts, p)
        if #parts >= 7 then break end
    end
    return table.concat(parts, ":")
end

if Addon.registerModule then
    Addon.registerModule("linkKey", {}, function()
        return true
    end)
end

Addon.linkKey = linkKey
return linkKey
