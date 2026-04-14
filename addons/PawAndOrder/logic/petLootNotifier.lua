--[[
  logic/petLootNotifier.lua
  Battle Pet Loot Notifications

  Watches all loot events for battle pet items and notifies the user
  with species name and owned count. Works for raid drops, reward bags,
  quest rewards, mailbox, or any other source of pet items.

  Identification:
  - battlepet: links have speciesID embedded in the link
  - Regular item links checked via GetItemInfoInstant classID (15/2)
  - Species matched by item name against pet journal

  Debounced by speciesID with a 5-second window to prevent spam
  when multiple people inspect the same loot.

  Dependencies: utils, events
  Exports: Addon.petLootNotifier
]]

local ADDON_NAME, Addon = ...

local petLootNotifier = {}
Addon.petLootNotifier = petLootNotifier

-- Module references
local utils, events

-- Pet item classification (MoP)
local PET_ITEM_CLASS = 15      -- Miscellaneous
local PET_ITEM_SUBCLASS = 2    -- Companion Pets

-- Debounce: speciesID -> expiry timestamp
local debounce = {}
local DEBOUNCE_WINDOW = 5  -- seconds

-- Species name -> speciesID reverse lookup (built on first use)
local speciesNameMap = nil

-- ============================================================================
-- HELPERS
-- ============================================================================

--[[
  Build reverse lookup from species name to speciesID.
  Scans the full pet journal once, caches result.
]]
local function ensureSpeciesNameMap()
  if speciesNameMap then return end
  speciesNameMap = {}

  local numPets = C_PetJournal.GetNumPets()
  if not numPets or numPets == 0 then return end

  local seen = {}
  for i = 1, numPets do
    local _, speciesID = C_PetJournal.GetPetInfoByIndex(i)
    if speciesID and not seen[speciesID] then
      seen[speciesID] = true
      local name = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
      if name then
        speciesNameMap[name] = speciesID
      end
    end
  end
end

--[[
  Try to extract speciesID from a battlepet: hyperlink.
  Format: |Hbattlepet:speciesID:level:quality:...|h[Name]|h
  @param link string - Full item/battlepet link
  @return number|nil - speciesID or nil
]]
local function parseSpeciesFromBattlepetLink(link)
  if not link then return nil end
  local speciesID = link:match("|Hbattlepet:(%d+)")
  return speciesID and tonumber(speciesID) or nil
end

--[[
  Try to extract itemID from a standard item hyperlink.
  Format: |Hitem:itemID:...|h[Name]|h
  @param link string - Full item link
  @return number|nil - itemID or nil
]]
local function parseItemID(link)
  if not link then return nil end
  local id = link:match("|Hitem:(%d+)")
  return id and tonumber(id) or nil
end

--[[
  Extract display name from any hyperlink (between [ and ]).
  @param link string - Full hyperlink
  @return string|nil
]]
local function parseLinkName(link)
  if not link then return nil end
  return link:match("%[(.-)%]")
end

--[[
  Check if an itemID is a companion pet via GetItemInfoInstant.
  @param itemID number
  @return boolean
]]
local function isPetItem(itemID)
  if not itemID or not GetItemInfoInstant then return false end
  local _, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID)
  return classID == PET_ITEM_CLASS and subClassID == PET_ITEM_SUBCLASS
end

--[[
  Find speciesID by item name, using the reverse lookup map.
  @param name string - Item/pet name
  @return number|nil - speciesID or nil
]]
local function findSpeciesByName(name)
  if not name then return nil end
  ensureSpeciesNameMap()
  return speciesNameMap and speciesNameMap[name] or nil
end

--[[
  Get owned count for a species.
  @param speciesID number
  @return number, number - numOwned, maxAllowed
]]
local function getOwnedCount(speciesID)
  -- C_PetJournal.GetNumCollectedInfo confirmed available in MoP
  if C_PetJournal.GetNumCollectedInfo then
    return C_PetJournal.GetNumCollectedInfo(speciesID)
  end
  return 0, 3
end

--[[
  Check debounce and record if fresh.
  @param speciesID number
  @return boolean - true if should notify (not debounced)
]]
local function checkDebounce(speciesID)
  local now = GetTime()

  -- Prune expired entries
  for id, expiry in pairs(debounce) do
    if expiry < now then
      debounce[id] = nil
    end
  end

  if debounce[speciesID] then
    return false  -- Still within window
  end

  debounce[speciesID] = now + DEBOUNCE_WINDOW
  return true
end

--[[
  Build and send the notification.
  @param speciesID number
  @param itemLink string|nil - Original item link for display
]]
local function notify(speciesID, itemLink)
  if not speciesID then return end
  if not checkDebounce(speciesID) then return end

  local name, icon = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
  if not name then return end

  local numOwned, maxAllowed = getOwnedCount(speciesID)
  local displayName = itemLink or name

  local ownedStr
  if numOwned == 0 then
    ownedStr = "|cffff4444Not collected|r"
  else
    ownedStr = string.format("|cffffffff%d|r/|cffffffff%d|r owned", numOwned, maxAllowed)
  end

  utils:notify(string.format("Pet: %s (%s)", displayName, ownedStr))
end

-- ============================================================================
-- LOOT HANDLER
-- ============================================================================

--[[
  Process a loot message for potential pet items.
  @param message string - CHAT_MSG_LOOT message text
]]
local function onLootMessage(eventName, message)
  if not message then return end

  -- Extract link(s) from the message
  -- CHAT_MSG_LOOT contains a single item link
  local link = message:match("(|c.-|H.-|h.-|h|r)")
  if not link then return end

  -- Path 1: battlepet: link (speciesID is embedded)
  local speciesID = parseSpeciesFromBattlepetLink(link)
  if speciesID then
    notify(speciesID, link)
    return
  end

  -- Path 2: Regular item link
  local itemID = parseItemID(link)
  if not itemID then return end

  -- Check if it's a pet item
  if not isPetItem(itemID) then return end

  -- Get species from item name
  local itemName = parseLinkName(link)
  speciesID = findSpeciesByName(itemName)

  if speciesID then
    notify(speciesID, link)
  else
    -- Couldn't match species — still notify that a pet item dropped
    utils:notify(string.format("Pet item: %s", link))
  end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function petLootNotifier:initialize()
  utils = Addon.utils
  events = Addon.events

  -- Watch all loot messages (self and group)
  events:subscribe("CHAT_MSG_LOOT", onLootMessage, petLootNotifier)

  return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
  Addon.registerModule("petLootNotifier", {
    "utils", "events"
  }, function()
    return petLootNotifier:initialize()
  end)
end

return petLootNotifier
