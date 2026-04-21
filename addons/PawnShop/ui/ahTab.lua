--[[
  ui/ahTab.lua
  Auction House Tab and Event Wiring

  Adds a "Pawn Shop" tab to the AuctionFrame and owns the WoW event
  handlers that drive the scan/eval pipeline from AH state:

    AUCTION_HOUSE_SHOW       -> create panel+tab, restore scan cache
    AUCTION_HOUSE_CLOSED     -> cancel any in-flight eval
    AUCTION_ITEM_LIST_UPDATE -> forward to scan:onListUpdate
    GET_ITEM_INFO_RECEIVED   -> forward to eval:scheduleResolve

  Kept separate from panel.lua because it's specifically about Blizzard AH
  integration -- the panel itself is content-only and doesn't know how it
  got shown.

  Dependencies: utils, events, panel, scan, eval
  Exports: Addon.ahTab
]]

local ADDON_NAME, Addon = ...

local ahTab = {}

-- Module references
local utils, events, panel, scan, eval

-- Tab frame and assigned tab index.
local tabFrame = nil
local tabID    = nil

-- WoW event frame (one per addon is already the convention, but this is
-- the AH-specific subset; a general event dispatcher would be overkill).
local eventFrame = nil

-- ============================================================================
-- TAB CREATION
-- ============================================================================

--[[
  Claim the next tab slot after Blizzard's existing AH tabs and wire up
  the click hook to show/hide our panel.

  Blizzard's AuctionFrame has 3 built-in tabs (Browse, Bid, Auctions) in
  TBC/MoP. We scan for the highest numbered AuctionFrameTabN and add
  ourselves at N+1.
]]
local function createTab()
    if tabFrame then return end

    local lastID, lastTab = 0, nil
    for i = 1, 20 do
        local t = _G["AuctionFrameTab" .. i]
        if t then
            lastID  = i
            lastTab = t
        else
            break
        end
    end
    if lastID == 0 then
        utils:error("ahTab: no existing AuctionFrameTab found; cannot add Pawn Shop tab")
        return
    end

    local ourID = lastID + 1
    tabFrame = CreateFrame("Button", "AuctionFrameTab" .. ourID,
                           AuctionFrame, "AuctionTabTemplate")
    tabFrame:SetID(ourID)
    tabFrame:SetText("Pawn Shop")
    tabFrame:SetNormalFontObject("GameFontHighlightSmall")
    tabFrame:SetPoint("LEFT", lastTab, "RIGHT", -8, 0)
    PanelTemplates_SetNumTabs(AuctionFrame, ourID)
    PanelTemplates_DeselectTab(tabFrame)
    tabID = ourID

    -- Hook the built-in tab click dispatcher to toggle our panel on/off.
    hooksecurefunc("AuctionFrameTab_OnClick", function(self, _button, _down, index)
        local id = index or (self and self:GetID())
        if id == tabID then
            -- Our tab clicked: hide Blizzard's content frames, show our panel.
            if AuctionFrameBrowse   then AuctionFrameBrowse:Hide()   end
            if AuctionFrameBid      then AuctionFrameBid:Hide()      end
            if AuctionFrameAuctions then AuctionFrameAuctions:Hide() end
            panel:show()
            PanelTemplates_SetTab(AuctionFrame, tabID)
        else
            -- Another tab clicked: hide our panel.
            panel:hide()
        end
    end)
end

-- ============================================================================
-- WOW EVENT HANDLING
-- ============================================================================

local function onAuctionHouseShow()
    panel:ensureCreated()
    createTab()

    -- First time we see the AH this session: try to restore cached scan
    -- data so the grid isn't empty after a reload. Trigger eval on the
    -- cached set so the user sees results immediately.
    if #scan:getAuctions() == 0 then
        local count, _age = scan:restoreFromCache()
        if count and count > 0 then
            eval:start()
        end
    end
end

local function onAuctionHouseClosed()
    -- Cancel any in-flight eval. Scan is either idle or will complete on
    -- its own (the server-side getAll doesn't care about AH state).
    eval:cancel()
end

local function onEvent(_, event, arg1)
    if     event == "AUCTION_HOUSE_SHOW"        then onAuctionHouseShow()
    elseif event == "AUCTION_HOUSE_CLOSED"      then onAuctionHouseClosed()
    elseif event == "AUCTION_ITEM_LIST_UPDATE"  then scan:onListUpdate()
    elseif event == "GET_ITEM_INFO_RECEIVED"    then eval:scheduleResolve()
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ahTab:initialize()
    utils  = Addon.utils
    events = Addon.events
    panel  = Addon.panel
    scan   = Addon.scan
    eval   = Addon.eval

    if not utils or not events or not panel or not scan or not eval then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444ahTab: Missing dependencies|r")
        return false
    end

    eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
    eventFrame:RegisterEvent("AUCTION_HOUSE_CLOSED")
    eventFrame:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
    eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    eventFrame:SetScript("OnEvent", onEvent)

    return true
end

if Addon.registerModule then
    Addon.registerModule("ahTab", {"utils", "events", "panel", "scan", "eval"}, function()
        return ahTab:initialize()
    end)
end

Addon.ahTab = ahTab
return ahTab
