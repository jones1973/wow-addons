--[[
  ui/shared/widgets/labeledToggle.lua
  Labeled Toggle — a checkbox/radio with a clickable, styled caption

  Composes the agnostic toggle with a clickableLabel bound to it: clicking
  either the box or the caption flips the state, and hovering either brightens
  the caption as one unit. This is the checkbox-with-label the options renderer
  maps `checkbox` to, so it conforms to the same control contract as any other
  option control.

  Conforms to the shared control contract:
    create(cfg) -> control
      cfg = { parent, label, value, tooltip?, onChange?, style?, size?, gap? }
    control:SetValue(value, suppress)
    control:GetValue()
    control:SetEnabled(bool)
    control:SetShown(bool)

  The control's own frame is the toggle (anchor it to position the unit); the
  caption is anchored to its right and moves with it. control.label exposes the
  caption for callers that need its width or independent anchoring.

  Dependencies: toggle, clickableLabel
  Exports: Addon.labeledToggle
]]

local _, Addon = ...

local labeledToggle = {}

local DEFAULT_GAP = 4

function labeledToggle:create(config)
    if not config or not config.parent then
        error("labeledToggle:create requires config.parent")
    end

    local cb = Addon.toggle:create({
        parent   = config.parent,
        style    = config.style,
        value    = config.value,
        size     = config.size,
        tooltip  = config.tooltip,
        onChange = config.onChange,
    })

    local lbl = Addon.clickableLabel:create({
        parent = config.parent,
        text   = config.label or "",
        font   = config.font,
    })
    lbl:SetPoint("LEFT", cb, "RIGHT", config.gap or DEFAULT_GAP, 0)
    lbl:bindTo(cb)

    -- The unit's control surface IS the toggle; expose the caption alongside.
    -- setLabel lets the renderer update the caption text (and re-fit the hit
    -- area) without reaching into the composition.
    cb.label = lbl
    function cb:setLabel(text) self.label:setText(text) end

    return cb
end

Addon.labeledToggle = labeledToggle
return labeledToggle
