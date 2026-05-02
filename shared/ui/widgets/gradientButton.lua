--[[
  ui/shared/gradientButton.lua
  Gradient Button Component
  
  Reusable button factory that creates professional-looking buttons with:
  - Gradient background
  - Border
  - Text with shadow
  - Hover highlight
  
  Pure UI component with no business logic or layout assumptions.
  
  Dependencies: none
  Exports: Addon.gradientButton
]]

local ADDON_NAME, Addon = ...

local gradientButton = {}

--[[
  Create Gradient Button
  Creates a professional-looking button with gradient background, border, and text.
  
  @param parent frame - Parent frame
  @param text string - Button text
  @param width number - Button width
  @param height number - Button height
  @return button - Button frame with .text property for text updates
]]
function gradientButton:create(parent, text, width, height)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetSize(width, height)
  
  -- Gradient background texture
  btn.bg = btn:CreateTexture(nil, "BACKGROUND")
  btn.bg:SetAllPoints()
  btn.bg:SetTexture("Interface\\Buttons\\UI-Panel-Button-Up")
  btn.bg:SetTexCoord(0, 0.625, 0, 0.6875)
  
  -- Border frame
  btn.border = CreateFrame("Frame", nil, btn)
  btn.border:SetAllPoints()
  
  -- Top border
  btn.borderTop = btn.border:CreateTexture(nil, "OVERLAY")
  btn.borderTop:SetHeight(1)
  btn.borderTop:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
  btn.borderTop:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
  btn.borderTop:SetColorTexture(0.3, 0.3, 0.3, 1)
  
  -- Bottom border
  btn.borderBottom = btn.border:CreateTexture(nil, "OVERLAY")
  btn.borderBottom:SetHeight(1)
  btn.borderBottom:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
  btn.borderBottom:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
  btn.borderBottom:SetColorTexture(0.1, 0.1, 0.1, 1)
  
  -- Left border
  btn.borderLeft = btn.border:CreateTexture(nil, "OVERLAY")
  btn.borderLeft:SetWidth(1)
  btn.borderLeft:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
  btn.borderLeft:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
  btn.borderLeft:SetColorTexture(0.2, 0.2, 0.2, 1)
  
  -- Right border
  btn.borderRight = btn.border:CreateTexture(nil, "OVERLAY")
  btn.borderRight:SetWidth(1)
  btn.borderRight:SetPoint("TOPRIGHT", btn, "TOPRIGHT", 0, 0)
  btn.borderRight:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
  btn.borderRight:SetColorTexture(0.2, 0.2, 0.2, 1)
  
  -- Text
  btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  btn.text:SetPoint("CENTER", btn, "CENTER", 0, 0)
  btn.text:SetText(text)
  btn.text:SetTextColor(1, 1, 1, 1)
  btn.text:SetShadowOffset(1, -1)
  btn.text:SetShadowColor(0, 0, 0, 1)
  
  -- Hover highlight
  btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
  btn.highlight:SetAllPoints()
  btn.highlight:SetColorTexture(1, 1, 1, 0.1)
  btn.highlight:SetBlendMode("ADD")
  
  return btn
end

-- Register with addon
Addon.gradientButton = gradientButton

-- Self-register with dependency system
if Addon.registerModule then
  Addon.registerModule("gradientButton", {}, function()
    return true
  end)
end

return gradientButton