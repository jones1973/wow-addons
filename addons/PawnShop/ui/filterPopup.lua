--[[
  ui/filterPopup.lua
  Filter Popup

  Small popup anchored to the right edge of the panel. Contains:
    - Scale checkboxes (up to constants.MAX_SCALE_COLUMNS, 5)
    - Sort-by radio group (one of the enabled scales)
    - Level tolerance numeric input
    - Min upgrade % numeric input
    - Max price numeric input
    - Close button

  Changes apply live - every filter control writes through
  persistence:setCharacterSetting() which shadows the account-wide default
  in ps_character. The change fires a SETTING:FILTER_CHANGED or
  SETTING:DISPLAY_CHANGED event that the panel listens for.

  Clicking a filter button on the panel toggles this popup open/closed.

  Dependencies: utils, events, options, persistence, textBox, constants
  Exports: Addon.filterPopup
]]

local ADDON_NAME, Addon = ...

local filterPopup = {}

function filterPopup:initialize()
    return true
end

if Addon.registerModule then
    Addon.registerModule("filterPopup", {
        "utils", "events", "options", "textBox", "constants",
    }, function()
        return filterPopup:initialize()
    end)
end

Addon.filterPopup = filterPopup
return filterPopup
