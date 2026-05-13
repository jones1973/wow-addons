--[[
  ui/shared/widgets/mixins/overflowTooltipMixin.lua
  Hover-tooltip-on-truncated-text capability

  Mixin that shows a tooltip with the full text on hover when a
  tracked FontString has been truncated by WoW because its content
  exceeds the FontString's laid-out width.

  The mixin configures the FontString itself (word-wrap on, single-
  line cap) so WoW renders a trailing ellipsis on overflow. It then
  asks the FontString directly whether truncation occurred via
  IsTruncated() at hover time.

  Contract — target must:
    - be mouse-enabled
    - tolerate state at self._overflowTooltip
    - allow HookScript on OnEnter/OnLeave

  Provides:
    InitOverflowTooltip()
        Call once at frame construction.

    SetOverflowText(fontString, fullText)
        Call each render. Configures the FontString for ellipsis
        truncation, sets the text, and arms the hover handler.
]]

local _, Addon = ...

local overflowTooltipMixin = {}

-- Configure a FontString for ellipsis truncation. Idempotent.
-- The two wrap flags together tell WoW to lay out the text on a
-- single line and append "…" when it overflows the FontString's
-- width. SetJustifyV("TOP") pins the visible text to the
-- FontString's top edge so rows align consistently regardless of
-- whether truncation occurred.
local function configureForTruncation(fontString)
    fontString:SetWordWrap(true)
    fontString:SetMaxLines(1)
    fontString:SetJustifyV("TOP")
end

function overflowTooltipMixin:InitOverflowTooltip()
    self:HookScript("OnEnter", function(frame)
        local cfg = frame._overflowTooltip
        if not cfg or not cfg.fs or not cfg.fullText then return end
        if not cfg.fs:IsTruncated() then return end
        Addon.tooltip:showSimple(frame, cfg.fullText, { anchor = "right" })
    end)
    self:HookScript("OnLeave", function() Addon.tooltip:hide() end)
end

function overflowTooltipMixin:SetOverflowText(fontString, fullText)
    if not fontString or not fullText or fullText == "" then
        if fontString then fontString:SetText(fullText or "") end
        self._overflowTooltip = nil
        return
    end

    configureForTruncation(fontString)
    fontString:SetText(fullText)
    self._overflowTooltip = { fs = fontString, fullText = fullText }
end

Addon.overflowTooltipMixin = overflowTooltipMixin
return overflowTooltipMixin
