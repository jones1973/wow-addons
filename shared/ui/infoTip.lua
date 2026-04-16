--[[
  ui/shared/infoTip.lua
  Reusable Info Tip Component
  
  Provides an (i) icon that:
  - Hover: Shows brief tooltip via Addon.tooltip
  - Click: Opens expanded help panel with structured content
  
  Content structure:
  - title: Panel header (gold text)
  - brief: Short hover tooltip text
  - description: Main explanation
  - sections: Array of {label, text, color} for additional sections
  - settingsHint: Optional "Settings: Category → Option" text
  
  Dependencies: utils, tooltip
  Exports: Addon.infoTip
]]

local ADDON_NAME, Addon = ...

local infoTip = {}

-- Track active help frame (only one at a time)
local activeHelpFrame = nil

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local ICON_SIZE = 20
local PANEL_WIDTH = 320
local PADDING = 12
local SECTION_GAP = 12

-- ============================================================================
-- EXPANDED HELP PANEL
-- ============================================================================

--[[
  Show expanded help panel.
  
  @param content table - {title, description, sections, settingsHint}
  @param anchorTo frame - Frame to anchor panel to
]]
local function showExpandedHelp(content, anchorTo)
  -- Close any existing panel
  if activeHelpFrame then
    activeHelpFrame:Hide()
    activeHelpFrame = nil
  end
  
  if not content then return end
  
  local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
  frame:SetFrameStrata("TOOLTIP")
  frame:SetWidth(PANEL_WIDTH)
  frame:SetClampedToScreen(true)
  
  -- Try to position to the right, but allow left if needed
  frame:SetPoint("TOPLEFT", anchorTo, "TOPRIGHT", 8, 4)
  
  frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  frame:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
  
  -- Close button
  local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
  closeBtn:SetScript("OnClick", function()
    frame:Hide()
    activeHelpFrame = nil
  end)
  
  -- Click anywhere on frame to close
  frame:EnableMouse(true)
  frame:SetScript("OnMouseDown", function(self)
    self:Hide()
    activeHelpFrame = nil
  end)
  
  local yOffset = -PADDING
  
  -- Title (gold)
  if content.title then
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, yOffset)
    title:SetPoint("RIGHT", frame, "RIGHT", -32, 0)
    title:SetText(content.title)
    title:SetTextColor(1, 0.82, 0)
    title:SetJustifyH("LEFT")
    yOffset = yOffset - (title:GetStringHeight() + SECTION_GAP)
  end
  
  -- Description
  if content.description then
    local desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, yOffset)
    desc:SetWidth(PANEL_WIDTH - PADDING * 2)
    desc:SetJustifyH("LEFT")
    desc:SetText(content.description)
    yOffset = yOffset - (desc:GetStringHeight() + SECTION_GAP)
  end
  
  -- Additional sections
  if content.sections then
    for _, section in ipairs(content.sections) do
      -- Section label
      local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      label:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, yOffset)
      label:SetText(section.label or "")
      if section.labelColor then
        label:SetTextColor(section.labelColor.r or 0.7, section.labelColor.g or 0.7, section.labelColor.b or 1)
      else
        label:SetTextColor(0.7, 0.7, 1)
      end
      yOffset = yOffset - (label:GetStringHeight() + 4)
      
      -- Section text
      local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      text:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, yOffset)
      text:SetWidth(PANEL_WIDTH - PADDING * 2)
      text:SetJustifyH("LEFT")
      text:SetText(section.text or "")
      if section.textColor then
        text:SetTextColor(section.textColor.r or 1, section.textColor.g or 1, section.textColor.b or 1)
      end
      yOffset = yOffset - (text:GetStringHeight() + SECTION_GAP)
    end
  end
  
  -- Settings hint (gray, at bottom)
  if content.settingsHint then
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hint:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, yOffset)
    hint:SetWidth(PANEL_WIDTH - PADDING * 2)
    hint:SetJustifyH("LEFT")
    hint:SetText(content.settingsHint)
    hint:SetTextColor(0.6, 0.6, 0.6)
    yOffset = yOffset - (hint:GetStringHeight() + 8)
  end
  
  -- Set final height
  frame:SetHeight(math.abs(yOffset) + PADDING)
  
  frame:Show()
  activeHelpFrame = frame
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Create an info tip icon.
  
  @param parent frame - Parent frame
  @param content table - {title, brief, description, sections, settingsHint}
  @return frame - The info tip button
]]
function infoTip:create(parent, content)
  if not parent or not content then return nil end
  
  local btn = CreateFrame("Button", nil, parent)
  btn:SetSize(ICON_SIZE, ICON_SIZE)
  
  -- Circle background (transparent with subtle border feel)
  local bg = btn:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.5, 0.5, 0.5, 0.2)
  
  -- (i) text (subtle gray, slightly larger for 20px icon)
  local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("CENTER", 0, 0)
  text:SetText("i")
  text:SetTextColor(0.7, 0.7, 0.7)
  btn.iconText = text
  
  -- Hover: brief tooltip
  btn:SetScript("OnEnter", function(self)
    bg:SetColorTexture(0.5, 0.6, 0.8, 0.4)
    text:SetTextColor(1, 1, 1)
    
    if content.brief and Addon.tooltip then
      local tipModule = Addon.tooltip
      tipModule:show(self, "ANCHOR_RIGHT")
      tipModule:header(content.title or "Info")
      tipModule:space(3)
      tipModule:text(content.brief, {color = {0.8, 0.8, 0.8}})
      tipModule:done()
    end
  end)
  
  btn:SetScript("OnLeave", function(self)
    bg:SetColorTexture(0.5, 0.5, 0.5, 0.2)
    text:SetTextColor(0.7, 0.7, 0.7)
    
    if Addon.tooltip then
      Addon.tooltip:hide()
    end
  end)
  
  -- Click: expanded panel
  btn:SetScript("OnClick", function(self)
    showExpandedHelp(content, self)
  end)
  
  btn.content = content
  
  return btn
end

--[[
  Update content of an existing info tip.
  
  @param btn frame - Info tip button from create()
  @param content table - New content
]]
function infoTip:setContent(btn, content)
  if btn then
    btn.content = content
  end
end

--[[
  Close any open expanded help panel.
]]
function infoTip:closePanel()
  if activeHelpFrame then
    activeHelpFrame:Hide()
    activeHelpFrame = nil
  end
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
  Addon.registerModule("infoTip", {"utils", "tooltip"}, function()
    return true
  end)
end

Addon.infoTip = infoTip
return infoTip