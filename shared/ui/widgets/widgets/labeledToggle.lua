--[[
  ui/shared/widgets/labeledToggle.lua
  Labeled Toggle — Convenience Wrapper

  The common shape: a toggle (checkbox or radio) with a clickable
  label to its right. Clicking either toggles the state; hovering
  either brightens the label.

  This is the default shape for nearly all toggle UX. For the rare
  cases where the label needs to be separated from the toggle (column
  layouts, label-spans-multiple-toggles, cross-frame), use toggle and
  clickableLabel directly and call clickableLabel:bindTo(toggle).

  Usage:
    local lt = Addon.labeledToggle:create({
        parent   = frame,
        style    = "checkbox",         -- or "radio"
        label    = "Hide owned",
        checked  = true,
        gap      = 4,                  -- pixels between toggle and label
        onChange = function(checked) end,
    })

    -- Position via the returned table — anchor TO the toggle (left
    -- edge of the unit). The label is anchored relative to toggle and
    -- moves with it.
    lt.toggle:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 16, 8)

    -- Radio coordination, when style="radio":
    local group = Addon.toggle.newGroup()
    lt.toggle:bindToGroup(group)

  Returns: { toggle = <Toggle frame>, label = <ClickableLabel frame> }
  Direct access lets callers anchor either independently or query the
  toggle's checked state.

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
        checked  = config.checked,
        size     = config.size,
        onChange = config.onChange,
    })

    local lbl = Addon.clickableLabel:create({
        parent = config.parent,
        text   = config.label or "",
        font   = config.font,
    })
    lbl:SetPoint("LEFT", cb, "RIGHT", config.gap or DEFAULT_GAP, 0)
    lbl:bindTo(cb)

    return { toggle = cb, label = lbl }
end

Addon.labeledToggle = labeledToggle
return labeledToggle
