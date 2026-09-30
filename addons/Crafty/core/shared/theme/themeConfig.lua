--[[
  themeConfig.lua
  Crafty's brand and chat configuration

  Installs Crafty's brand anchors into the shared theme module and configures
  the chat prefix. Runs at file-load time after theme.lua, before any UI code.

  Brand rationale: a crafting addon. Primary is a warm forge-amber - the heat
  and metal of creation. Secondary is a cool slate-blue - the precision and
  tooling counterpoint. If these do not land, they are a two-line change here.

  Dependencies: theme (loaded immediately before this file)
  Exports: nothing - installs configuration into Addon.theme
]]

local ADDON_NAME, Addon = ...
local theme = Addon.theme

theme.brand.set({
    primary   = { r = 0.85, g = 0.55, b = 0.18 },  -- forge amber
    secondary = { r = 0.32, g = 0.45, b = 0.62 },  -- slate blue
})

theme.chat.set({
    prefix      = "Crafty",
    prefixColor = theme.tokens.BRAND.PRIMARY,
})
