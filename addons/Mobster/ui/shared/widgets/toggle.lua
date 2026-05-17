--[[
  ui/shared/widgets/toggle.lua
  Toggle Widget — Checkbox or Radio Button

  A small interactive widget that's either on or off. Two styles:
    "checkbox" — independent on/off, click flips state.
    "radio"    — coordinated on/off, click sets this one ON and any
                 other radio sharing the same group OFF.

  No label. Use clickableLabel + bindTo (or the labeledToggle
  convenience wrapper) when you want a clickable caption alongside.

  Usage:
    local cb = Addon.toggle:create({
        parent  = frame,
        style   = "checkbox",  -- or "radio"
        checked = true,
        size    = 24,          -- optional, default 24
        onChange = function(checked) end,
    })

    -- Radio coordination: create a group object, bind radios to it.
    local group = Addon.toggle.newGroup()
    local r1 = Addon.toggle:create({ parent = f, style = "radio",
                                     checked = true, onChange = ... })
    r1:bindToGroup(group)
    local r2 = Addon.toggle:create({ parent = f, style = "radio",
                                     onChange = ... })
    r2:bindToGroup(group)
    -- Clicking r2 now turns r1 off (and fires r1's onChange(false)).

  Returns: the toggle frame, which is either a CheckButton (checkbox)
  or CheckButton + UIRadioButtonTemplate (radio). Both expose
  :GetChecked() / :SetChecked(bool) / :Click() per the Blizzard
  template. Additional methods:
    :bindToGroup(group)         radio only — joins a coordination group
    :setChecked(bool, silent)   like SetChecked but fires onChange
                                unless silent=true

  Dependencies: none
  Exports: Addon.toggle
]]

local _, Addon = ...

local toggle = {}

-- ============================================================================
-- GROUPS
-- ============================================================================
--
-- A group is a tiny object that owns the "only one radio checked at a
-- time" state for its members. Created with Addon.toggle.newGroup();
-- radios join via :bindToGroup(group). When any member is clicked,
-- the group notifies all others to uncheck.

function toggle.newGroup()
    local g = { members = {} }

    function g:add(member)
        self.members[#self.members + 1] = member
    end

    --[[
      Called by a member when it becomes checked. Tells all other
      members to uncheck. Each uncheck fires the other's onChange(false)
      so consumers stay in sync.
    ]]
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
-- TOGGLE FACTORY
-- ============================================================================

function toggle:create(config)
    if not config or not config.parent then
        error("toggle:create requires config.parent")
    end
    local style   = config.style or "checkbox"
    local size    = config.size or 24
    local checked = config.checked and true or false

    if style ~= "checkbox" and style ~= "radio" then
        error("toggle:create: style must be 'checkbox' or 'radio'")
    end

    -- Blizzard templates: UICheckButtonTemplate (checkbox) and
    -- UIRadioButtonTemplate (radio). Both create a CheckButton frame
    -- with the appropriate textures.
    local template = (style == "radio") and "UIRadioButtonTemplate"
                                       or  "UICheckButtonTemplate"

    local frame = CreateFrame("CheckButton", nil, config.parent, template)
    frame:SetSize(size, size)
    frame:SetChecked(checked)
    frame._onChange = config.onChange
    frame._toggleStyle = style
    frame._group = nil

    --[[
      Bind to a group. Radio-only. Idempotent — calling again with the
      same group is a no-op. Changing groups isn't supported (would
      require removing from the previous group's members; not needed
      currently).
    ]]
    function frame:bindToGroup(group)
        if self._toggleStyle ~= "radio" then
            error("toggle:bindToGroup is radio-only")
        end
        if self._group == group then return end
        if self._group then
            error("toggle:bindToGroup: already in a group")
        end
        self._group = group
        group:add(self)
    end

    --[[
      Like Blizzard's SetChecked but also fires onChange. Pass
      silent=true to set state without firing (useful for syncing
      from external state changes).
    ]]
    function frame:setChecked(value, silent)
        local newVal = value and true or false
        if self:GetChecked() == newVal then return end
        self:SetChecked(newVal)
        if not silent and self._onChange then
            self._onChange(newVal)
        end
        -- Radio: notify group so peers uncheck.
        if newVal and self._group then
            self._group:select(self)
        end
    end

    -- Click behavior. The template already toggles visual state on
    -- click; we add the onChange fire and (for radio) group sync.
    frame:SetScript("OnClick", function(self)
        local newVal = self:GetChecked() and true or false

        -- Radio can't be unchecked by clicking itself (matches
        -- standard radio UX — to deselect, click another).
        if self._toggleStyle == "radio" and not newVal then
            self:SetChecked(true)
            return
        end

        if self._group and newVal then
            self._group:select(self)
        end
        if self._onChange then
            self._onChange(newVal)
        end
    end)

    return frame
end

Addon.toggle = toggle
return toggle
