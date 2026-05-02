--[[
  shared/style/style.lua
  Visual Style / Skinning -- Registry & Dispatcher

  Single source of truth for visual styling across all addons in the
  monorepo. Strategies (one per UI overhaul, plus stock) register
  themselves at file-load time into Addon.style.strategies. This
  module's init phase picks the active strategy and caches it. Public
  skin methods dispatch to the active strategy with method-level
  fallback to stock for anything not implemented.

  ---------------------------------------------------------------------
  Lifecycle (relies on the platform's load phases):

    Phase 1 -- File-load (sequential per files.xml):
      Each strategy file writes itself into Addon.style.strategies.
      This file (style.lua) sets up Addon.style and exposes the
      dispatcher API. Order between this file and strategy files
      doesn't matter -- both this file and the strategies use
      defensive `Addon.style = Addon.style or {}` patterns.

    Phase 2 -- Module init:
      style:initialize() runs (via registerModule). It walks the
      strategies table, calls each detect(), and picks the active
      strategy by the rule below. Cached on the module.

    Phase 3 -- Use:
      Consumers call style:skinFrame(f), style:skinButton(b),
      style:skinEditBox(e). Dispatcher routes to active strategy if
      it implements that method, otherwise to stock.

  ---------------------------------------------------------------------
  Detection rule:

    Walk all strategies (excluding stock). Count those whose detect()
    returns true.

      Exactly 1 non-stock match  -> use that strategy
      0 or 2+ non-stock matches  -> use stock

    Stock is the fallback in two cases: nothing detected (normal
    stock user) and ambiguous detection (user has multiple UI
    overhauls -- their setup is broken regardless and we can't
    confidently match either). Naming "stock" explicitly in the
    dispatcher because the rule itself references it.

  ---------------------------------------------------------------------
  Strategy contract:

    Addon.style.strategies.NAME = {
        detect      = function() return ... end,    -- REQUIRED
        skinFrame   = function(frame)  ... end,     -- optional
        skinButton  = function(button) ... end,     -- optional
        skinEditBox = function(box)    ... end,     -- optional
    }

    Future methods (skinScrollbar, skinTooltip, etc.) can be added
    to the dispatcher and to specific strategies without touching
    other strategies. A strategy can omit any method except detect;
    method-level fallback to stock kicks in.

  Dependencies: utils (for debug logging only)
  Exports: Addon.style
]]

local ADDON_NAME, Addon = ...

-- Make the strategies table available from file-load time so strategy
-- files (regardless of files.xml order) can write into it.
Addon.style = Addon.style or {}
Addon.style.strategies = Addon.style.strategies or {}

local style = Addon.style

-- ============================================================================
-- INTERNAL STATE
-- ============================================================================

-- Resolved during initialize(). active is the chosen non-stock strategy
-- (or nil if none); stock is always the table at strategies.stock; both
-- are cached so dispatcher calls are constant-time.
local active = nil
local stock  = nil

-- ============================================================================
-- DETECTION & RESOLUTION
-- ============================================================================

--[[
  Walk strategies (excluding stock), call each detect(), return the
  set of names whose detect returned true.
]]
local function detectMatches()
    local matches = {}
    for name, strat in pairs(style.strategies) do
        if name ~= "stock" then
            local ok, isMatch = pcall(strat.detect)
            if ok and isMatch then
                table.insert(matches, name)
            end
        end
    end
    return matches
end

--[[
  Apply the detection rule and return the name of the active strategy.
  Always returns a name -- "stock" is the fallback for both no match
  and ambiguous match.
]]
local function resolveActive()
    local matches = detectMatches()
    if #matches == 1 then
        return matches[1]
    end
    return "stock"
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Returns the name of the currently active strategy. After init, this
  is one of the keys in style.strategies. Before init, returns nil.
  @return string | nil
]]
function style:detectedSkin()
    if active then return active._name end
    if stock  then return stock._name  end
    return nil
end

--[[
  Dispatch a skinning call to the active strategy, falling back to
  stock if the active strategy doesn't implement that method. If
  neither implements it, no-op (defensive; stock should always
  implement every public method).

  @param method string - one of "skinFrame", "skinButton", "skinEditBox"
  @param target frame|button|editbox - what to skin
]]
local function dispatch(method, target)
    if not target then return end

    if active and active[method] then
        active[method](target)
        return
    end
    if stock and stock[method] then
        stock[method](target)
    end
    -- Else no-op. A method missing from both active and stock means
    -- we added a method to the API but haven't implemented it
    -- anywhere yet -- treat as silent no-op rather than error so a
    -- partial rollout doesn't break addons.
end

function style:skinFrame(frame)    dispatch("skinFrame",    frame)  end
function style:skinButton(button)  dispatch("skinButton",   button) end
function style:skinEditBox(box)    dispatch("skinEditBox",  box)    end

--[[
  Apply a titlebar visual treatment to the top of a panel-style frame.
  Stock places text on the frame's chrome titlebar area, matching
  Blizzard's Browse/Make/Auctions-frame title placement. Skin
  strategies that hide chrome (ElvUI etc.) typically no-op since
  there's nothing to title against.

  @param frame  - the panel frame
  @param text   - the title string
]]
function style:skinTitlebar(frame, text)
    if not frame or not text then return end
    if active and active.skinTitlebar then
        active.skinTitlebar(frame, text)
        return
    end
    if stock and stock.skinTitlebar then
        stock.skinTitlebar(frame, text)
    end
end

-- ============================================================================
-- INITIALIZE
-- ============================================================================

function style:initialize()
    -- Stamp each registered strategy with its name so detectedSkin()
    -- can return a string. Done here rather than at registration time
    -- so strategies don't have to repeat their name in their data.
    for name, strat in pairs(self.strategies) do
        strat._name = name
    end

    stock = self.strategies.stock
    if not stock then
        if Addon.utils and Addon.utils.error then
            Addon.utils:error(
                "style: no stock strategy registered; " ..
                "skinning calls will be no-ops")
        end
    end

    local activeName = resolveActive()
    if activeName ~= "stock" then
        active = self.strategies[activeName]
    end
    -- If activeName is "stock", leave `active` nil so the dispatcher
    -- routes everything through `stock` directly.

    if Addon.utils and Addon.utils.debug then
        Addon.utils:debug(string.format(
            "style: active strategy = %s",
            self:detectedSkin() or "(none)"))
    end

    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("style", { "utils" }, function()
        return style:initialize()
    end)
end

return style
