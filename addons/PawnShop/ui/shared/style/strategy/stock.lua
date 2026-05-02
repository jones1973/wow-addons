--[[
  shared/style/strategy/stock.lua
  Stock Blizzard Strategy

  The fallback skinning strategy. Always detects true (it's the floor),
  implements every public method so the dispatcher never has to no-op.

  Used in two cases:
    * No UI overhaul detected (default Blizzard user)
    * Multiple UI overhauls detected (ambiguous; can't confidently
      match either, so fall back to stock)

  Visual choices match Blizzard's parchment-and-dialog-border family
  (CharacterFrame, MailFrame, AuctionFrame stock look).

  Dependencies: none (pure data registration at file-load time)
  Exports: Addon.style.strategies.stock
]]

local ADDON_NAME, Addon = ...

Addon.style = Addon.style or {}
Addon.style.strategies = Addon.style.strategies or {}

local STOCK_BACKDROP = {
    bgFile   = "Interface\\FrameGeneral\\UI-Background-Rock",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 16,
    tile = true, tileSize = 32,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

Addon.style.strategies.stock = {
    -- Always matches. Stock is the floor.
    detect = function() return true end,

    skinFrame = function(frame)
        if frame.SetBackdrop then
            frame:SetBackdrop(STOCK_BACKDROP)
            frame:SetBackdropColor(1, 1, 1, 1)
        end
    end,

    -- UIPanelButtonTemplate already looks correct against stock
    -- parchment frames. No additional skinning needed.
    skinButton = function(button) end,

    -- textBox.lua's custom backdrop is designed to match the stock
    -- panel look. No additional skinning needed.
    skinEditBox = function(box) end,

    --[[
      Place a titlebar text on the panel's chrome top area. Blizzard's
      AH tab frames (Browse/Make/Auctions) put a centered FontString
      at TOP with y-offset -18 against the frame's own chrome -- no
      texture, just text. Match that.

      Reuses the same fontstring on repeated calls so the title can
      be updated without leaking frames.
    ]]
    skinTitlebar = function(frame, text)
        local fs = frame._stockTitlebar
        if not fs then
            -- Anchor the title text to the AH frame's chrome title bar
            -- region, not to our panel frame. The chrome's textures
            -- (UI-AuctionFrame-Browse-Top*) include a parchment ribbon
            -- and separator at y=-18; sitting our text there matches
            -- Blizzard's BrowseTitle/MakeAuctionTitle/etc. placement.
            fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            local anchorTo = _G.AuctionFrame or frame
            fs:SetPoint("TOP", anchorTo, "TOP", 0, -18)
            frame._stockTitlebar = fs
        end
        fs:SetText(text)
        fs:Show()
    end,
}
