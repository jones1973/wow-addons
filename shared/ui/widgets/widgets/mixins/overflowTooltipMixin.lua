--[[
  ui/shared/widgets/mixins/overflowTooltipMixin.lua
  Hover-tooltip-on-truncated-text capability

  Mixin that shows a tooltip with the full text on hover when a
  tracked FontString has been truncated by WoW because its content
  exceeds the FontString's laid-out width.

  Expects the FontString to already be configured for single-line
  ellipsis truncation by its creator (WordWrap=true + MaxLines=1).
  Detects truncation at hover time via IsTruncated().

  Contract — target must:
    - be mouse-enabled
    - tolerate state at self._overflowTooltip
    - allow HookScript on OnEnter/OnLeave

  Provides:
    InitOverflowTooltip()
        Call once at frame construction.

    SetOverflowText(fontString, fullText)
        Call each render. Sets the text and arms the hover handler.
]]

local _, Addon = ...

local overflowTooltipMixin = {}

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

    fontString:SetText(fullText)
    self._overflowTooltip = { fs = fontString, fullText = fullText }
end

Addon.overflowTooltipMixin = overflowTooltipMixin
return overflowTooltipMixin
