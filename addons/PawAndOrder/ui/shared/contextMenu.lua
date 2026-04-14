--[[
  ui/shared/contextMenu.lua
  Context Menu API
  
  Thin wrapper around menuRenderer for context menu use cases.
  Provides cursor-anchored and frame-anchored context menus.
  
  Usage:
    -- Show at cursor (most common)
    contextMenu:show({
      items = {
        { text = "Edit", func = function(ctx) ... end },
        { separator = true },
        { text = "Delete", func = function(ctx) ... end, disabled = function(ctx) return ctx.protected end },
        { text = "Submenu", submenu = { ... } },
      }
    }, { id = "123", protected = false })
    
    -- Show anchored to frame
    contextMenu:showAt(button, "TOPLEFT", menuDef, context)
  
  Dependencies: menuRenderer
  Exports: Addon.contextMenu
]]

local ADDON_NAME, Addon = ...

local contextMenu = {}

-- Module reference (resolved on first use)
local menuRenderer

-- ============================================================================
-- HELPER
-- ============================================================================

local function getRenderer()
    if not menuRenderer then
        menuRenderer = Addon.menuRenderer
        if not menuRenderer then
            error("contextMenu requires menuRenderer module")
        end
    end
    return menuRenderer
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Show context menu at cursor position
  
  @param menuDef table - Menu definition:
    {
      spacing = number (optional),
      items = {
        { text = "Item", func = function(ctx) ... end },
        { text = "Disabled", disabled = true/function(ctx) },
        { text = "Checked", checkable = true, checked = true/function(ctx) },
        { text = "Icon", icon = fileID, iconCoords = {l,r,t,b} },
        { separator = true },
        { text = "Submenu", submenu = { ... } }
      }
    }
  @param context table - Context data passed to all callbacks
]]
function contextMenu:show(menuDef, context)
    local renderer = getRenderer()
    
    renderer:show({
        anchor = "cursor",
        items = menuDef.items,
        spacing = menuDef.spacing,
        context = context or {},
    })
end

--[[
  Show context menu anchored to a frame
  
  @param anchor frame - Frame to anchor to
  @param anchorPoint string - Point on menu (e.g., "TOPLEFT")
  @param menuDef table - Menu definition (same as show())
  @param context table - Context data passed to all callbacks
]]
function contextMenu:showAt(anchor, anchorPoint, menuDef, context)
    local renderer = getRenderer()
    
    renderer:show({
        anchor = anchor,
        anchorPoint = anchorPoint or "TOPLEFT",
        anchorRelPoint = "BOTTOMLEFT",
        items = menuDef.items,
        spacing = menuDef.spacing,
        context = context or {},
    })
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("contextMenu", {"menuRenderer"}, function()
        return true
    end)
end

Addon.contextMenu = contextMenu
return contextMenu