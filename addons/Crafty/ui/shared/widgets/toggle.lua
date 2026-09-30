--[[
  ui/shared/widgets/toggle.lua
  Toggle Widget — Checkbox or Radio Button

  A small interactive control that is either on or off. Two styles:
    "checkbox" — independent on/off; click flips state.
    "radio"    — coordinated on/off; click sets this one ON and any other
                 radio sharing its group OFF.

  The toggle carries NO caption of its own. A caption is a separate
  clickableLabel bound to the toggle (or the labeledToggle composition), so the
  caption is styled and click-coupled as a control in its own right rather than
  the toggle reaching for a template-created label.

  Visuals come from the theme's active style: create() skins the control through
  theme.style:skinCheckbox, so it inherits the Blizzard or ElvUI look (or any
  registered strategy) instead of hardcoded textures.

  Conforms to the shared control contract the options renderer speaks:
    create(cfg) -> control
      cfg = { parent, value, tooltip?, onChange?, style?, size? }
    control:SetValue(value, suppress)   set state; fires onChange unless suppress
    control:GetValue()                  -> boolean
    control:SetEnabled(bool)            (inherited from the frame)
    control:SetShown(bool)              (inherited from the frame)
  Plus, for radio coordination:
    control:bindToGroup(group)          radio only — joins a coordination group
    toggle.newGroup()                   -> group

  Usage:
    local cb = Addon.toggle:create({
        parent  = frame,
        value   = true,
        tooltip = "Hide owned",
        onChange = function(v) end,
    })

  Dependencies: theme (for skinning)
  Exports: Addon.toggle
]]

local _, Addon = ...

local toggle = {}

-- ============================================================================
-- GROUPS — the "only one radio checked at a time" coordinator
-- ============================================================================

function toggle.newGroup()
    local g = { members = {} }

    function g:add(member)
        self.members[#self.members + 1] = member
    end

    -- A member became checked: uncheck every other member, firing each one's
    -- onChange(false) so consumers stay in sync.
    function g:select(selected)
        for i = 1, #self.members do
            local m = self.members[i]
            if m ~= selected and m:GetChecked() then
                m:SetChecked(false)
                if m._onChange then m._onChange(false) end
            end
        end
    end

    return g
end

-- ============================================================================
-- FACTORY
-- ============================================================================

function toggle:create(config)
    if not config or not config.parent then
        error("toggle:create requires config.parent")
    end
    local style = config.style or "checkbox"
    local size  = config.size or 24
    if style ~= "checkbox" and style ~= "radio" then
        error("toggle:create: style must be 'checkbox' or 'radio'")
    end

    local template = (style == "radio") and "UIRadioButtonTemplate"
                                        or  "UICheckButtonTemplate"
    local frame = CreateFrame("CheckButton", nil, config.parent, template)
    frame:SetSize(size, size)
    frame:SetChecked(config.value and true or false)
    frame._onChange = config.onChange
    frame._toggleStyle = style
    frame._group = nil

    -- Styled through the active theme strategy (Blizzard / ElvUI / ...), so the
    -- control looks native to whatever skin is in use. The theme is a core
    -- system present in every consumer, so it is used directly.
    Addon.theme.style:skinCheckbox(frame, { radio = (style == "radio") })

    if config.tooltip then
        frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(config.tooltip, nil, nil, nil, nil, true)
            GameTooltip:Show()
        end)
        frame:SetScript("OnLeave", GameTooltip_Hide)
    end

    -- Radio-only: join a coordination group. Idempotent for the same group.
    function frame:bindToGroup(group)
        if self._toggleStyle ~= "radio" then
            error("toggle:bindToGroup is radio-only")
        end
        if self._group == group then return end
        if self._group then error("toggle:bindToGroup: already in a group") end
        self._group = group
        group:add(self)
    end

    -- Contract: current state.
    function frame:GetValue()
        return self:GetChecked() and true or false
    end

    -- Contract: set state, firing onChange unless suppress. Used both by
    -- consumers and by the options renderer syncing the control to the store.
    function frame:SetValue(value, suppress)
        local newVal = value and true or false
        if self:GetChecked() == newVal then return end
        self:SetChecked(newVal)
        if newVal and self._group then self._group:select(self) end
        if not suppress and self._onChange then self._onChange(newVal) end
    end

    -- Click: the template flips the visual; we add the onChange fire and radio
    -- group sync. A radio cannot be unchecked by clicking itself.
    frame:SetScript("OnClick", function(self)
        local newVal = self:GetChecked() and true or false
        if self._toggleStyle == "radio" and not newVal then
            self:SetChecked(true)
            return
        end
        if newVal and self._group then self._group:select(self) end
        if self._onChange then self._onChange(newVal) end
    end)

    return frame
end

Addon.toggle = toggle
return toggle
