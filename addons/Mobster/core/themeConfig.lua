--[[
  themeConfig.lua
  Mobster's brand and chat configuration

  Installs Mobster's brand anchors (deep blood red primary, tarnished
  gold secondary) into the shared theme module and configures the chat
  prefix. Runs at file-load time after theme.lua, before any UI code.

  See THEME.md §14 (Mobster — Noir) for the brand rationale.

  Dependencies: theme (loaded by the .toc immediately before this file)
  Exports: nothing — installs configuration into Addon.theme
]]

local ADDON_NAME, Addon = ...
local theme = Addon.theme

theme.brand.set({
    primary   = { r = 0.55, g = 0.10, b = 0.12 },  -- deep blood red
    secondary = { r = 0.78, g = 0.62, b = 0.22 },  -- tarnished gold
})

theme.chat.set({
    prefix      = "Mobster",
    prefixColor = theme.tokens.BRAND.PRIMARY,
})
