-- UI/popupFactory.lua
-- Shared popup builder for Paw and Order
local ADDON_NAME, Addon = ...

local popupFactory = {}

function popupFactory:create(options)
    local title = options.title or "Popup"
    local icon = options.icon or "Interface\\Icons\\INV_Misc_Pet08"
    local width = options.width or 470
    local height = options.height or 325
    
    -- Create frame WITH BackdropTemplate for MoP compatibility (proven pattern)
    local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(width, height)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Use DIALOG instead of FULLSCREEN_DIALOG for better compatibility
    frame:SetFrameStrata("DIALOG")
    
    -- SetBackdrop works with BackdropTemplate (proven in working code)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    
    -- Layout constants
    local PADDING = 16
    local ICON_SIZE = 48
    local HEADER_HEIGHT = PADDING + ICON_SIZE + 8  -- padding + icon + gap
    
    -- Icon (top-left)
    local iconTexture
    if icon and icon ~= "" then
        iconTexture = frame:CreateTexture(nil, "ARTWORK", nil, 7)
        iconTexture:SetSize(ICON_SIZE, ICON_SIZE)
        iconTexture:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -PADDING)
        iconTexture:SetTexture(icon)
        frame.iconTexture = iconTexture
    end
    
    -- Title (beside icon, vertically centered with it)
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    if iconTexture then
        titleText:SetPoint("LEFT", iconTexture, "RIGHT", 10, 0)
    else
        titleText:SetPoint("TOPLEFT", frame, "TOPLEFT", PADDING, -PADDING - 12)
    end
    titleText:SetText(title)
    
    -- Content anchor - invisible frame that marks where content should start
    -- Consumers should anchor to this instead of hardcoding offsets
    local contentAnchor = CreateFrame("Frame", nil, frame)
    contentAnchor:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -HEADER_HEIGHT)
    contentAnchor:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -HEADER_HEIGHT)
    contentAnchor:SetHeight(1)
    frame.contentAnchor = contentAnchor
    frame.HEADER_HEIGHT = HEADER_HEIGHT  -- Expose for consumers who need the raw value
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)
    
    -- Store references
    frame.titleText = titleText
    
    return frame
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("popupFactory", {}, function()
        return true
    end)
end

Addon.popupFactory = popupFactory
return popupFactory