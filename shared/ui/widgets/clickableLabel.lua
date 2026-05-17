--[[
  ui/shared/widgets/clickableLabel.lua
  Clickable Label Widget

  A FontString-backed label with a transparent click overlay. When
  clicked, it fires the target's Click(). When the cursor enters
  either the label or the target, both brighten as one unit; when
  the cursor leaves, both return to normal color.

  Used standalone (with an onClick handler) or bound to a toggle
  (the common case — labeled checkbox or radio).

  Usage — standalone:
    local lbl = Addon.clickableLabel:create({
        parent  = frame,
        text    = "Click me",
        onClick = function() ... end,
    })

  Usage — bound to a toggle:
    local cb  = Addon.toggle:create({ parent = frame, style = "checkbox", ... })
    local lbl = Addon.clickableLabel:create({ parent = frame, text = "Sound" })
    lbl:bindTo(cb)
    -- Clicking lbl now calls cb:Click(); hover on either brightens both.

  The label's FontString is reachable as label.fs for callers that
  need to anchor things relative to it or query GetStringWidth.

  Dependencies: none
  Exports: Addon.clickableLabel
]]

local _, Addon = ...

local clickableLabel = {}

-- Padding around the label text for the click/hit area. Small forgiving
-- buffer so cursor doesn't need pixel-perfect placement.
local HIT_PAD = 2

-- ============================================================================
-- FACTORY
-- ============================================================================

function clickableLabel:create(config)
    if not config or not config.parent then
        error("clickableLabel:create requires config.parent")
    end
    local text     = config.text or ""
    local fontTpl  = config.font or "GameFontNormal"

    -- The "frame" returned IS the click overlay (a Button), with the
    -- FontString as its child. Anchoring the overlay anchors the label.
    local frame = CreateFrame("Button", nil, config.parent)
    frame:RegisterForClicks("LeftButtonUp")

    -- Anchor the FontString only at TOPLEFT — letting it grow to its
    -- natural text width. Two-point anchoring (TOPLEFT + BOTTOMRIGHT)
    -- would chain the FontString's bounds to the button's bounds,
    -- which we haven't sized yet — GetStringWidth then returns a
    -- clipped width and we size the button to that, locking the text
    -- truncated forever.
    local fs = frame:CreateFontString(nil, "OVERLAY", fontTpl)
    fs:SetPoint("TOPLEFT", HIT_PAD, -HIT_PAD)
    fs:SetJustifyH("LEFT")
    fs:SetText(text)
    frame.fs = fs

    -- Size the overlay to match the rendered text + hit padding.
    -- GetStringWidth/Height return the actual rendered dimensions.
    -- Callers can override by calling SetSize after creation.
    local function autosize()
        local w = fs:GetStringWidth() + HIT_PAD * 2
        local h = fs:GetStringHeight() + HIT_PAD * 2
        frame:SetSize(math.max(w, 1), math.max(h, 1))
    end
    autosize()

    --[[
      Update the label text. Re-autosizes the click area to fit.
    ]]
    function frame:setText(newText)
        fs:SetText(newText or "")
        autosize()
    end

    -- Hover state: track who's hovered so we don't fight ourselves when
    -- the cursor moves from label to bound target (or vice versa).
    -- _hoverCount = number of mouse-in sources currently active.
    frame._hoverCount = 0

    local function brighten()
        fs:SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g,
                        HIGHLIGHT_FONT_COLOR.b, 1)
    end
    local function normal()
        fs:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g,
                        NORMAL_FONT_COLOR.b, 1)
    end
    normal()  -- initial color

    local function hoverEnter()
        frame._hoverCount = frame._hoverCount + 1
        if frame._hoverCount == 1 then brighten() end
    end
    local function hoverLeave()
        frame._hoverCount = frame._hoverCount - 1
        if frame._hoverCount <= 0 then
            frame._hoverCount = 0
            normal()
        end
    end

    frame:SetScript("OnEnter", hoverEnter)
    frame:SetScript("OnLeave", hoverLeave)

    -- onClick installed lazily — either explicit (config.onClick) or
    -- via bindTo. They're exclusive: bindTo replaces any prior handler.
    if config.onClick then
        frame:SetScript("OnClick", config.onClick)
    end

    --[[
      Bind this label to a target frame that has Click()/HookScript.
      Clicking the label calls target:Click(); hovering the label
      brightens the label, and hovering the target also brightens the
      label (so box and caption read as one unit). The target is
      expected to be a toggle but any clickable frame works.

      The target's own visual hover (e.g. Blizzard checkbox highlight)
      is unchanged by this binding — only the label's text color is
      driven by combined hover state.

      Calling bindTo more than once is a no-op for the second target;
      one label per target.
    ]]
    function frame:bindTo(target)
        if self._boundTo then
            error("clickableLabel:bindTo: already bound")
        end
        self._boundTo = target

        self:SetScript("OnClick", function()
            if target.Click then target:Click() end
        end)

        -- Mirror hover state: cursor on target → brighten label too.
        target:HookScript("OnEnter", hoverEnter)
        target:HookScript("OnLeave", hoverLeave)
    end

    return frame
end

Addon.clickableLabel = clickableLabel
return clickableLabel
