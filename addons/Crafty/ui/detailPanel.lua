--[[
  ui/detailPanel.lua
  Detail Panel Component

  The right panel's contents: the selected recipe's detail (icon, name, yield,
  cooldown, requirements, description, can-make count, reagent breakdown) and
  the craft controls (quantity cluster + Create).

  Renders from the selection: subscribes to EVENT.RECIPE_SELECTED and renders
  whatever arrives (nil clears the panel). rerender() re-renders the current
  recipe in place for data-only changes (bag scans, cooldown sweeps,
  skill-ups) - the composer gates those on window visibility.

  Live-window facts (tools, description, craft verb) are read directly from
  the open trade-skill window with no open-state checks: rendering happens
  only while the composer holds the profession session open.

  Usage:
    local detail = Addon.detailPanel:create({
        parent = panelFrame,
        onStationMissing = function() ... end,  -- a craft attempt hit an
                                                -- unmet station requirement
        onReagentNavigate = function(nav) ... end,  -- a craftable reagent was
                                                    -- clicked: {itemID,
                                                    -- recipeID, profID,
                                                    -- prefill, owed}
    })
    detail:rerender()      -- re-render the current recipe (no-op when none)
    detail:visibleIcon()   -- the detail icon frame when shown, else nil (the
                           -- craft-origin fallback for arrival attribution)

  Dependencies: ledger, craftability, recipeCatalog, recipeView, cooldownData,
                professionWindow, crafter, rowStack, textBox, theme, events
  Exports: Addon.detailPanel
]]

local ADDON_NAME, Addon = ...

local detailPanel = {}

-- Detail-panel reagent lines are single-line and compact - independent of the
-- taller wrapping list row height.
local CONVERT_TILE_HEIGHT = 32
local REAGENT_ROW_HEIGHT = 28
-- What the quantity cluster and Create need at the panel's foot: 12 inset,
-- two 24px rows, a 6px gap between them, and 8 clear of the last reagent.
local CONTROLS_RESERVE = 12 + 24 + 6 + 24 + 8
local REAGENT_ICON       = 24
local REAGENT_ICON_GAP   = 8

-- THE GAME'S OWN WORD where the game has one, so the caption arrives in the
-- player's language rather than in ours.
--
-- Checked against the client's global-string table, not assumed:
--   CREATE_PROFESSION      'Create'        - the trade-skill button's own label
--   BINDING_NAME_STOPCASTING 'Stop Casting'
-- and there is NO string for Mill or Prospect, because this client has no such
-- button to label - milling is cast at a bag stack, not clicked in a frame. Nor
-- is there a bare CREATE or STOP: those were guesses, and they fell through to
-- the English every time.
--
-- The spell NAMES are the wrong strings for a button. They are "Milling" and
-- "Prospecting" - what the ability is called, not what the button does.
local function gameWord(key, fallback)
    return _G[key] or fallback
end

function detailPanel:create(config)
    local theme         = Addon.theme
    local tint          = theme.derive.tint
    local ledger        = Addon.ledger
    local craftability  = Addon.craftability
    local recipeCatalog = Addon.recipeCatalog
    local recipeView    = Addon.recipeView
    local cooldownData  = Addon.cooldownData
    local events        = Addon.events
    local EVT_SELECTED  = Addon.constants.EVENT.RECIPE_SELECTED

    local panelRight = config.parent

    local instance = {}
    local currentRecipeID   -- the recipe the panel currently shows (the selection)
    local craftCountBox

    -- The conversion view's state. Milling and prospecting are casts at a bag
    -- slot, so the grid's rows and the verb button are SECURE buttons
    -- carrying spell + target-bag + target-slot (the Molinari pattern - the
    -- only mechanism the client permits an addon for this).
    local convertContent, convertStack
    local convertTarget      -- the item being converted FOR (the selection)
    local convertVerb        -- "milling" | "prospecting"
    local convertSource      -- the source item the verb is pointed at
    -- The total a conversion visit exists to cover, held so choosing a
    -- source can turn it into that source's cast count (each source converts
    -- at its own rate, so the number cannot be known before the pick).
    local convertOwed   -- the errand's TOTAL need; the shortfall derives from it
    -- Defined once craftButton exists (their subject), called from the tile
    -- factory built before it: declared here so both close over the locals.
    local selectConvertSource, pointAt, renderConversion, followTile
    -- The frames that cast. Both are parented to UIParent, because
    -- SecureActionButtonTemplate protects its parents and nothing needs to
    -- move UIParent - inside the panel they would make the window itself
    -- unmovable by our own code. Declared here because the content frame's
    -- OnHide (built below, before they exist) hides them.
    local altOverlay      -- hovers the hovered row; casts on alt-click
    local verbOverlay     -- sits over the Mill/Prospect button; casts on click

    -- ------------------------------------------------------------------
    -- Craft quantity memory
    -- ------------------------------------------------------------------

    -- The entered craft quantity: whatever is in the box, floored at 1 (an empty
    -- or zero box means "one", the button's base meaning).
    local function craftQuantity()
        local n = craftCountBox and tonumber(craftCountBox:GetText())
        if not n or n < 1 then return 1 end
        return math.floor(n)
    end

    -- Per-recipe quantity memory, persisted per character. Quantity is a property
    -- of the recipe ("I make these in twenties"), not of the box: selecting a
    -- recipe recalls its number, editing writes it back. Only non-default values
    -- are stored.
    -- While an ORDER runs the box is a countdown, not an intention: the total
    -- is fixed when the order starts and the box shows what is left, so
    -- stopping part-way leaves a correct number to resume from.
    local orderRemaining
    -- A mill or prospect is one cast, but it is a CAST - about 1.4 seconds of
    -- it, with SENT / START / SUCCEEDED like any craft - so there is something
    -- to call off and the stop button belongs there too. Declared here because
    -- the stop button's handler closes over it and is built further down.
    local conversionCasting = false
    local paintStopButton   -- forward: the stop button's handler closes over it
    -- Forward-declared: the craft button's handler closes over this, and the
    -- frames it needs are built further down. Declared after, it would resolve
    -- as a global and be nil when the button is clicked.
    local leaveOrder

    -- The box is independent of the recipe list: selecting a recipe leaves the
    -- number alone. A quantity is what the player is doing now, not a property
    -- of the recipe, and re-deriving it on every selection fought that.
    local function syncQuantityBox() end

    -- ------------------------------------------------------------------
    -- Frames
    -- ------------------------------------------------------------------

    -- Difficulty progression bar: the recipe's whole orange->grey arc, full
    -- width, at the very top of the detail - the first thing the eye meets.
    local difficultyBar = Addon.difficultyBar:create(panelRight, {
        anchor = { "TOPLEFT", panelRight, "TOPLEFT", 12, -10 },
        rightInset = 12,
    })

    -- Recipe icon, beneath the bar. A Button, because it takes the mouse to show
    -- the depicted item's tooltip and a button is the primitive that owns both a
    -- face and the mouse. It is created shown and stays shown: a render changes
    -- its texture and the item it depicts, never its visibility. Showing a
    -- mouse-enabled frame beneath the cursor fires OnEnter synchronously, and
    -- these renders run inside an event dispatch, so revealing it there would put
    -- tooltip code inside that dispatch.
    local detailIcon = CreateFrame("Button", nil, panelRight)
    detailIcon:SetSize(40, 40)
    detailIcon:SetPoint("TOPLEFT", difficultyBar.frame, "BOTTOMLEFT", 0, -10)

    local detailIconTex = detailIcon:CreateTexture(nil, "ARTWORK")
    detailIconTex:SetAllPoints(detailIcon)
    detailIconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- trim default icon border

    detailIcon:SetScript("OnEnter", function(self)
        -- A recipe that creates no item - a pure enchant - has none to show.
        if not self.itemID then return end
        -- GameTooltip, not the family tooltip: this is a real item tooltip, and
        -- only SetItemByID composes one.
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(self.itemID)
        GameTooltip:Show()
    end)
    detailIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Name, right of the icon.
    local detailName = panelRight:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    detailName:SetPoint("TOPLEFT", detailIcon, "TOPRIGHT", 10, -2)
    detailName:SetPoint("RIGHT", panelRight, "RIGHT", -12, 0)

    -- Yield and skill-up trail the name, in the SMALL secondary font: they are
    -- facts about crafting it, not part of what it is called, and setting them
    -- in the name's own font would read as though they were.
    local nameSuffix = panelRight:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    nameSuffix:SetJustifyH("LEFT")
    tint(nameSuffix, theme.crafty.TEXT.LABEL)
    detailName:SetJustifyH("LEFT")
    detailName:SetText("")
    tint(detailName, theme.crafty.TEXT.TITLE)

    -- Info line under the name: yield and skill-up.
    local detailInfo = panelRight:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    detailInfo:SetPoint("TOPLEFT", detailName, "BOTTOMLEFT", 0, -4)
    detailInfo:SetJustifyH("LEFT")
    tint(detailInfo, theme.crafty.TEXT.LABEL)

    -- Cooldown line (the detail-panel home for cooldown text).
    local detailCooldown = panelRight:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    detailCooldown:SetPoint("TOPLEFT", detailIcon, "BOTTOMLEFT", 0, -8)
    detailCooldown:SetPoint("RIGHT", panelRight, "RIGHT", -12, 0)
    detailCooldown:SetJustifyH("LEFT")
    detailCooldown:SetWordWrap(true)
    detailCooldown:SetSpacing(2)
    detailCooldown:Hide()

    -- Shared-cooldown note: its OWN FontString (neutral color) so the cooldown
    -- line above can be colored for availability without recoloring this note.
    local detailCooldownNote = panelRight:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    detailCooldownNote:SetPoint("TOPLEFT", detailCooldown, "BOTTOMLEFT", 0, -2)
    detailCooldownNote:SetPoint("RIGHT", panelRight, "RIGHT", -12, 0)
    detailCooldownNote:SetJustifyH("LEFT")
    detailCooldownNote:SetWordWrap(true)
    detailCooldownNote:SetSpacing(2)
    tint(detailCooldownNote, theme.crafty.TEXT.LABEL)
    detailCooldownNote:Hide()

    -- Requirements (tools) line.

    -- Description block.
    local detailDesc = panelRight:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    detailDesc:SetPoint("TOPLEFT", detailCooldownNote, "BOTTOMLEFT", 0, -6)
    detailDesc:SetPoint("RIGHT", panelRight, "RIGHT", -12, 0)
    detailDesc:SetJustifyH("LEFT")
    detailDesc:SetWordWrap(true)
    detailDesc:SetSpacing(2)
    tint(detailDesc, theme.crafty.TEXT.BODY)
    detailDesc:Hide()

    -- "Can make from bags" count.
    local detailCount = panelRight:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    detailCount:SetPoint("TOPLEFT", detailDesc, "BOTTOMLEFT", 0, -10)
    detailCount:SetText("")
    tint(detailCount, theme.crafty.TEXT.VALUE)

    local reagentHeader = panelRight:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    reagentHeader:SetPoint("TOPLEFT", detailCount, "BOTTOMLEFT", 0, -12)
    reagentHeader:SetText("Reagents")
    tint(reagentHeader, theme.crafty.TEXT.HEADING)

    -- Reagent lines use rowStack directly rather than reactiveList. Indented
    -- under the "Reagents" header so they read as subordinate to it rather
    -- than a flush continuation of the panel.
    --
    -- BOUNDED, not grown: anchored to the quantity cluster's anchor as well as
    -- to the header, so its height is whatever the panel actually has left. A
    -- frame that grows downward instead runs under the controls when the list
    -- is long, and the rows below the fold are simply unreachable.
    local reagentContent = CreateFrame("Frame", nil, panelRight)
    reagentContent:SetPoint("TOPLEFT", reagentHeader, "BOTTOMLEFT", 12, -4)
    reagentContent:SetPoint("RIGHT", panelRight, "RIGHT", -12, 0)
    -- To the panel's own bottom, less the space the quantity cluster and the
    -- Create button occupy: two rows of 24 plus their gaps and inset. Anchored
    -- to panelRight rather than to craftAnchor because that anchor is built
    -- further down, and a frame cannot anchor to one that does not exist yet.
    reagentContent:SetPoint("BOTTOM", panelRight, "BOTTOM", 0, CONTROLS_RESERVE)

    -- A SCROLLER, not a scrollBox: that widget reserves a gutter and draws a
    -- bar, and a bar is chrome standing in a panel that usually does not need
    -- one. This shows nothing at all until the rows overrun, and then two
    -- pulsing arrows inside the frame - present only in the direction there is
    -- more to see.
    local reagentScroller = Addon.edgeScroller:create({ parent = reagentContent })

    local reagentStack
    reagentStack = Addon.rowStack:create({
        -- Scrolled, so a long reagent list stays reachable rather than running
        -- under the controls. The widget shows its scrollbar only on overflow,
        -- so a two-reagent recipe looks exactly as it did.
        --
        -- Sized 1x1 at construction and then told to fill reagentContent
        -- below: the panel flexes with the window, so there is no width or
        -- height to give here that would still be true a moment later.
        content    = reagentScroller:getContent(),
        kinds = {
            row = {
                height  = REAGENT_ROW_HEIGHT,
                factory = function(parent)
                    local row = CreateFrame("Button", nil, parent)
                    row:RegisterForClicks("LeftButtonUp")

                    -- The reagent's own icon, carrying the item's own tooltip.
                    -- Its own frame rather than a texture on the row: the row
                    -- already owns a hover that speaks about the CRAFTING path
                    -- ("need 3 more - click to craft"), and what the item is
                    -- is a different question. Pointing at the icon answers
                    -- the second without displacing the first.
                    local icon = CreateFrame("Button", nil, row)
                    icon:SetSize(REAGENT_ICON, REAGENT_ICON)
                    icon:SetPoint("LEFT", row, "LEFT", 0, 0)
                    icon.tex = icon:CreateTexture(nil, "ARTWORK")
                    icon.tex:SetAllPoints(icon)
                    icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- trim the border
                    -- Clicks pass through: a frame that takes mouse input is a
                    -- dead patch in the row beneath it, and this row's click is
                    -- how a short reagent is navigated to.
                    icon:SetPropagateMouseClicks(true)
                    -- The icon shows the depicted item's real tooltip only. The
                    -- row's own hover (the Crafty tooltip answering "how many do
                    -- I need") belongs to the text, not the icon - stacking both
                    -- on the icon put two tooltips over one cursor.
                    icon:SetScript("OnEnter", function(self)
                        if not self.itemID then return end
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetItemByID(self.itemID)
                        GameTooltip:Show()
                    end)
                    icon:SetScript("OnLeave", function()
                        GameTooltip:Hide()
                    end)
                    row.icon = icon

                    local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    fs:SetPoint("LEFT", icon, "RIGHT", REAGENT_ICON_GAP, 0)
                    fs:SetJustifyH("LEFT")
                    row.text = fs
                    return row
                end,
                render = function(row, item)
                    -- Count colors carry hierarchy, not celebration: a MET
                    -- count is the normal state and renders quiet neutral;
                    -- only a shortage takes the one state accent (red - it
                    -- is genuinely blocking). The numbers themselves carry
                    -- the meaning, so color is never the sole signal.
                    -- A vendor reagent is never a shortage: not holding it is
                    -- an errand, and it does not gate the craft count. The row
                    -- still shows what you hold - saying nothing would make the
                    -- panel disagree with the count above it - but the number
                    -- stays quiet and the line says where to get it.
                    -- Three states, not two: holding enough reads satisfied
                    -- (green); a real shortage reads danger (red); a vendor
                    -- reagent does not gate the craft, so its number stays quiet
                    -- (the "vendor" tag beside it says where to get it).
                    local haveEnough = item.haveBags >= item.need
                    local countToken
                    if item.vendor and not haveEnough then
                        countToken = theme.crafty.REAGENT.VENDOR
                    elseif haveEnough then
                        countToken = theme.crafty.REAGENT.SATISFIED
                    else
                        countToken = theme.crafty.REAGENT.SHORT
                    end
                    local count = string.format("%s/%d",
                        theme.derive.inline(countToken, item.haveBags), item.need)
                    if item.vendor and item.haveBags < item.need then
                        count = count .. "  " .. theme.derive.inline(
                            theme.crafty.TEXT.DISABLED, "vendor")
                    end

                    -- A reagent THIS character can craft is a live line: a
                    -- door to a side quest. Brand-tinted, tooltipped with the
                    -- path, and clicking walks through it - the composer
                    -- records the journey and navigates. The deficit rides
                    -- along: how many are owed against the goal's current
                    -- quantity, and how many casts of the producer cover it.
                    -- Blue is the window's interactivity hue - the one family
                    -- with no collision here: the difficulty spectrum never
                    -- reaches it and the state pair does not use it. Hover
                    -- brightens the line (color is never the sole carrier of
                    -- "clickable").
                    -- A reagent is a door if this character can produce it -
                    -- by crafting, or by converting (pigments and gems are
                    -- milled and prospected, never crafted).
                    local prodRecipe, prodProf = recipeView:knownProducerOf(item.id)
                    local convVerb, convProf
                    if not prodRecipe then
                        convVerb, convProf = recipeView:conversionRouteTo(item.id)
                    end
                    if (prodRecipe and prodRecipe ~= currentRecipeID) or convVerb then
                        local link = theme.tokens.STATE.INFO
                        tint(row.text, link)
                        row:SetScript("OnEnter", function(self)
                            self.text:SetTextColor(
                                link.r + (1 - link.r) * 0.45,
                                link.g + (1 - link.g) * 0.45,
                                link.b + (1 - link.b) * 0.45)
                            -- Deficit computed LIVE at hover (bags move), so
                            -- the tooltip answers "how many do I need"
                            -- before the click does anything.
                            local owed = item.need * craftQuantity()
                            local have = ledger:getItemCount(item.id)
                            local short = owed - ((have and have.bags) or 0)
                            Addon.tooltip:show(self, { atCursor = true })
                            Addon.tooltip:header("Craftable - "
                                .. (ledger:getProfessionName(prodProf) or ""))
                            Addon.tooltip:row("", short > 0
                                and ("Need " .. short .. " more - click to craft")
                                or "Have enough - click to view")
                            Addon.tooltip:done()
                        end)
                        row:SetScript("OnLeave", function(self)
                            tint(self.text, link)
                            Addon.tooltip:hide()
                        end)
                        row:SetScript("OnClick", function()
                            if not config.onReagentNavigate then return end
                            -- The ORDER's total, not one craft's: six inks at
                            -- two pigment each is twelve, and the errand exists
                            -- to cover the whole order.
                            local owed = item.need * craftQuantity()
                            local deficit = owed - item.haveBags
                            if convVerb then
                                -- The conversion view IS the destination: the
                                -- item itself, with its sources. The total owed
                                -- rides along, and the view shows what is short
                                -- of it - a number that follows the bags, since
                                -- a probabilistic yield has no cast count.
                                config.onReagentNavigate({
                                    itemID   = item.id,
                                    recipeID = item.id,
                                    kind     = "convert",
                                    profID   = convProf,
                                    owed     = owed,
                                })
                                return
                            end
                            local _, yieldLo = recipeCatalog:output(prodRecipe)
                            local perCast = (yieldLo and yieldLo > 0) and yieldLo or 1
                            local prefill = deficit > 0
                                and math.ceil(deficit / perCast) or 1
                            config.onReagentNavigate({
                                itemID   = item.id,
                                recipeID = prodRecipe,
                                profID   = prodProf,
                                prefill  = prefill,
                                owed     = owed,
                            })
                        end)
                    else
                        tint(row.text, theme.crafty.TEXT.BODY)
                        row:SetScript("OnEnter", nil)
                        row:SetScript("OnLeave", nil)
                        row:SetScript("OnClick", nil)
                    end

                    -- Reagent name is a derivation of the itemID. On a cold client
                    -- cache (first view of a fresh session) the synchronous lookup
                    -- returns nil; rather than paint a placeholder, resolve the
                    -- item asynchronously and set the text when it loads. The wait
                    -- is genuine deferred data, not a guard: ContinueOnItemLoad
                    -- fires once the client has the item, immediately if already
                    -- cached. Guarded on row identity so a recycled row that has
                    -- since moved to a different reagent is not overwritten by a
                    -- late callback.
                    row.icon.tex:SetTexture(C_Item.GetItemIconByID(item.id))
                    row.icon.itemID = item.id

                    local itemID = item.id
                    local obj = Item:CreateFromItemID(itemID)
                    obj:ContinueOnItemLoad(function()
                        if row.text and item.id == itemID then
                            row.text:SetText(obj:GetItemName() .. "  " .. count)
                        end
                    end)
                end,
                -- Reagent lines are not interactive.
                chrome = { hover = false, selection = false },
            },
        },
    })

    -- ------------------------------------------------------------------
    -- Craft controls
    -- ------------------------------------------------------------------

    -- The conversion view's content area, in the position the reagent list
    -- occupies (the two views never coexist).
    -- Column headers. Without them the tile rows carry three unlabelled
    -- numbers and the reader has to infer what each is - "22%" in particular
    -- says nothing about WHAT is 22% likely.
    local convertHeader = CreateFrame("Frame", nil, panelRight)
    convertHeader:SetPoint("TOPLEFT", detailInfo, "BOTTOMLEFT", 0, -8)
    convertHeader:SetPoint("RIGHT", panelRight, "RIGHT", -12, 0)
    convertHeader:SetHeight(16)
    convertHeader:Hide()

    local function convertColumn(text, ...)
        local fs = convertHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        tint(fs, theme.crafty.TEXT.HEADING)
        fs:SetText(text)
        fs:SetPoint(...)
        return fs
    end
    -- Aligned to the tile's own columns: icon 28 + 2 inset + 8 gap = 38 to the
    -- name, which is 150 wide before the yield.
    convertColumn("Source", "LEFT", convertHeader, "LEFT", 38, 0)
    convertColumn("Chance", "LEFT", convertHeader, "LEFT", 38 + 150 + 8, 0)
    convertColumn("Have", "RIGHT", convertHeader, "RIGHT", -4, 0)

    convertContent = CreateFrame("Frame", nil, panelRight)
    convertContent:SetPoint("TOPLEFT", convertHeader, "BOTTOMLEFT", 0, -2)
    convertContent:SetPoint("RIGHT", panelRight, "RIGHT", -12, 0)
    convertContent:SetHeight(1)
    convertContent:Hide()
    -- The overlay is parented to UIParent (it must be - see below), so the
    -- window closing does not hide it. This frame's visibility is the signal
    -- that the grid is gone, whichever way it went.
    convertContent:SetScript("OnHide", function()
        altOverlay:attach(nil, nil)
        verbOverlay:attach(nil, nil)
    end)

    -- The conversion grid: one row per source. The rows are PLAIN - they
    -- render, hover, and select like any list row, and they live in the panel
    -- where clipping and dragging are free.
    --
    -- The casting is not theirs. Two client facts, both field-established,
    -- allow exactly one arrangement:
    --   * only SecureActionButtonTemplate dispatches action attributes here
    --     (InsecureActionButtonTemplate exists but is silent), and
    --   * that template protects its parents, so such a frame cannot live in
    --     a frame we lay out - the layout's own SetPoint is then refused.
    -- So a single secure button lives under UIParent (nothing needs to move
    -- UIParent, so its protection costs nothing) and hovers over whichever
    -- row the mouse is on, carrying that row's attributes. It is the frame
    -- the cursor is actually over, so it owns the click: alt casts, a plain
    -- click selects. This is Molinari's arrangement, for Molinari's reason.
    convertStack = Addon.rowStack:create({
        content = convertContent,
        kinds = {
            tile = {
                height  = CONVERT_TILE_HEIGHT,
                factory = function(parent)
                    local row = CreateFrame("Button", nil, parent)
                    -- Hook, never SetScript: the widget attaches its own hover
                    -- chrome to this script at creation, and replacing it
                    -- silently discards the row's highlight.
                    row:HookScript("OnEnter", function(self)
                        if self.item then followTile(self, self.item) end
                    end)

                    -- The icon is a BUTTON so it can own a tooltip, exactly as
                    -- the reagent rows do: the row already owns a hover that
                    -- speaks about the conversion, and what the item IS is a
                    -- different question. Pointing at the icon answers the
                    -- second without displacing the first - and a tooltip over
                    -- the whole row would cover the numbers being read.
                    local icon = CreateFrame("Button", nil, row)
                    icon:SetSize(28, 28)
                    icon:SetPoint("LEFT", row, "LEFT", 2, 0)
                    icon.tex = icon:CreateTexture(nil, "ARTWORK")
                    icon.tex:SetAllPoints(icon)
                    icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    -- The icon owns a tooltip but NOT the row's behaviour: a
                    -- frame that takes mouse input is a dead patch in the row
                    -- beneath it, and this one sits where the eye goes first.
                    -- Clicks pass through, and its hover re-raises the row's -
                    -- which is what attaches the alt-cast overlay.
                    icon:SetPropagateMouseClicks(true)
                    icon:SetScript("OnEnter", function(self)
                        local parent = self:GetParent()
                        local rowEnter = parent:GetScript("OnEnter")
                        if rowEnter then rowEnter(parent) end
                        if not self.itemID then return end
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetItemByID(self.itemID)
                        GameTooltip:Show()
                    end)
                    icon:SetScript("OnLeave", function(self)
                        GameTooltip:Hide()
                        local parent = self:GetParent()
                        local rowLeave = parent:GetScript("OnLeave")
                        if rowLeave then rowLeave(parent) end
                    end)
                    row.icon = icon

                    local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    name:SetPoint("LEFT", icon, "RIGHT", 8, 0)
                    name:SetJustifyH("LEFT")
                    name:SetWidth(150)
                    name:SetWordWrap(false)
                    row.name = name

                    -- What a cast of this source gives for the target item.
                    local yield = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    yield:SetPoint("LEFT", name, "RIGHT", 8, 0)
                    yield:SetJustifyH("LEFT")
                    row.yield = yield

                    -- What you hold, in casts.
                    local casts = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    casts:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                    casts:SetJustifyH("RIGHT")
                    row.casts = casts
                    return row
                end,
                render = function(row, item)
                    row.icon.tex:SetTexture(C_Item.GetItemIconByID(item.id))
                    row.icon.itemID = item.id
                    -- The YIELD rides in the name, as a recipe's does: "1-3"
                    -- describes what you get, so it belongs to the thing rather
                    -- than to a column the eye has to correlate back.
                    local qty = item.qty and (item.qty[1] == item.qty[2]
                        and tostring(item.qty[1])
                        or (item.qty[1] .. "-" .. item.qty[2])) or nil
                    local name = recipeView:itemName(item.id) or ("item " .. item.id)
                    row.name:SetText(qty and (name .. " (" .. qty .. ")") or name)

                    -- Chance the target appears AT ALL in a cast - independent
                    -- per-cast presence, not a share of a distribution. Rounded:
                    -- the sample sizes behind these numbers do not support
                    -- decimals. The column header names it.
                    local pct = math.floor(item.chance * 100 + 0.5)
                    row.yield:SetText(pct .. "%")
                    tint(row.yield, item.tier == "primary"
                        and theme.crafty.TEXT.VALUE or theme.crafty.TEXT.LABEL)

                    -- Holdings in the unit that matters: casts, not items.
                    row.casts:SetText(item.casts > 0 and (item.casts .. "x") or "-")
                    tint(row.casts, item.casts > 0
                        and theme.crafty.TEXT.VALUE or theme.crafty.TEXT.DISABLED)
                    tint(row.name, item.casts > 0
                        and theme.crafty.TEXT.BODY or theme.crafty.TEXT.DISABLED)
                    row.icon.tex:SetDesaturated(item.casts == 0)

                    -- The caster follows whatever row the mouse is on; the
                    -- factory's hook reads this to know what it is over.
                    row.item = item
                end,
                onClick = function(item)
                    selectConvertSource(item.id)
                end,
                chrome = { hover = true, selection = true },
            },
        },
    })

    -- The scroll surface fills its parent, which is what carries the real
    -- geometry: reagentContent flexes with the window, so the size given at
    -- construction could not have been right for long.
    -- Create is the panel's one crafting verb, holding the terminal
    -- bottom-right slot. It crafts the entered quantity (shift-click: the
    -- bag-limited max). DoTradeSkill repeats natively and halts on empty
    -- materials.
    -- Create's REST POSITION as a frame of its own: the quantity cluster
    -- chains off this anchor, not off the button, so the button's
    -- acknowledgment hop moves the button alone - quantity is not a party to
    -- the nod.
    local craftAnchor = CreateFrame("Frame", nil, panelRight)
    craftAnchor:SetSize(100, 24)
    craftAnchor:SetPoint("BOTTOMRIGHT", panelRight, "BOTTOMRIGHT", -12, 12)

    -- The verb serves both masters: crafting runs from its OnClick script,
    -- and converting runs from action attributes on the same click.
    --
    -- Plain: a secure template here would protect panelRight and the window
    -- above it, and the nod moves this button. Crafting runs from its OnClick
    -- script; converting is the overlay's job (the only frame that can cast),
    -- so this button is disabled while a conversion is shown and the grid
    -- rows carry the verb.
    local craftButton = CreateFrame("Button", nil, panelRight,
        "UIPanelButtonTemplate")
    craftButton:SetSize(100, 24)
    craftButton:SetPoint("CENTER", craftAnchor, "CENTER", 0, 0)
    craftButton:RegisterForClicks("AnyUp")
    craftButton:SetText(gameWord("CREATE_PROFESSION", "Create"))
    craftButton:SetScript("OnClick", function()
        -- Converting casts at a bag slot, which only the secure overlay can
        -- do; this button cannot be secure (it lives in a panel that moves).
        -- The conversion view therefore casts from its rows.
        if convertTarget then return end
        if not currentRecipeID then return end

        -- Station check: the live window colors unmet tool requirements red
        -- in the tools text ("Requires: Cooking Fire" with no fire nearby).
        -- An unmet station means this craft is about to fail - let the native
        -- error say WHY while the band's tool cluster nods to say WHERE the
        -- remedy is. The craft attempt still goes out (the client's error is
        -- the authoritative verdict, not our text parse).
        local idx = Addon.professionWindow:indexForRecipe(currentRecipeID)
        local toolsText = idx and GetTradeSkillTools(idx)
        if toolsText and toolsText ~= "" then
            if toolsText:lower():find("|cffff2020", 1, true) then
                if config.onStationMissing then config.onStationMissing() end
            end
        end

        -- Mid-order the button is the stop control: the order model already
        -- knows one is running, so this is a real state rather than a guess,
        -- and it beats making the player press ESC or walk away.
        --
        -- StopTradeSkillRepeat, not SpellStopCasting. The latter is PROTECTED
        -- and an addon calling it raises ADDON_ACTION_FORBIDDEN. This one is
        -- built for exactly this - it is what Blizzard's own frame calls to end
        -- a Create All - and it ends the QUEUE rather than the cast in flight,
        -- so the craft already paid for still completes.
        -- Stopping is not handled here: the craft button is plain, and
        -- cancelling a cast in flight needs a SECURE click. stopButton sits over
        -- this one while an order runs and takes the click instead.
        if orderRemaining then return end

        local n = IsShiftKeyDown() and Addon.craftability:fromBags(currentRecipeID)
            or craftQuantity()
        if n > 0 then
            Addon.crafter:craft(currentRecipeID, n)
        end
    end)
    craftButton:Disable()

    -- QUANTITY CLUSTER, right-aligned against Create and vertically centred on
    -- it: 1  max  next  +5  [-] [box] [+]  Create.
    --
    -- Anchored right to left off Create, so the whole row hangs off the one
    -- fixed point and nothing drifts when a label's width changes.
    --
    -- All four are one-shot SETTERS, not modes. They write a number into the
    -- box and their job ends there - the box is the single statement of what
    -- will be crafted, and nothing recomputes behind it.
    local function setQuantity(n)
        craftCountBox:SetText(tostring(math.max(1, math.floor(n or 1))))
    end

    -- Width is MEASURED from the caption, never assigned. A caption flush with
    -- the button's sides is hard to read and hard to hit, and a short caption
    -- suffers most - "1" sized to its glyph is a target a few pixels wide.
    --
    -- QTY_BTN_PAD is per side. QTY_BTN_MIN is the floor, so one- and two-
    -- character captions get a target the size of a word rather than the size
    -- of their text: WCAG 2.5.5 asks 44px for a comfortable pointer target,
    -- and Fitts's law says acquisition time rises as the target shrinks. The
    -- height is held at 24 to sit on the same line as the box and Create.
    local QTY_BTN_PAD, QTY_BTN_MIN = 14, 44

    local function quantityButton(text, onClick)
        local b = CreateFrame("Button", nil, panelRight, "UIPanelButtonTemplate")
        b:SetText(text)
        local w = b:GetFontString():GetStringWidth() + QTY_BTN_PAD * 2
        b:SetSize(math.max(QTY_BTN_MIN, math.ceil(w)), 24)
        b:SetScript("OnClick", onClick)
        return b
    end

    local plusFive = quantityButton("+5", function()
        setQuantity(craftQuantity() + 5)
    end)
    local nextBtn = quantityButton("next", function()
        if currentRecipeID then
            setQuantity(recipeView:craftsToNextBand(currentRecipeID))
        end
    end)
    local maxBtn = quantityButton("max", function()
        if currentRecipeID then
            setQuantity(Addon.craftability:fromBags(currentRecipeID))
        end
    end)
    local oneBtn = quantityButton("1", function() setQuantity(1) end)

    -- One step per click. Shift-for-ten was a stand-in for a bulk control; +5
    -- is that control, and two ways to do one thing is one too many.
    local plus = quantityButton("+", function() setQuantity(craftQuantity() + 1) end)

    craftCountBox = Addon.textBox:create({
        parent = panelRight,
        width = 56,   -- room for three digits without ambiguity
        height = 24,
        numeric = true,
        text = "1",
    })

    local minus = quantityButton("-", function() setQuantity(craftQuantity() - 1) end)

    -- Right to left off Create, every control centred on the same line.
    -- TWO ROWS, both right-aligned on Create.
    --
    -- Measured, not chosen: at these button widths the seven controls plus the
    -- box plus Create need 488px and the right panel has 442. The alternative
    -- was shrinking the buttons back below a comfortable target, which is what
    -- made them hard to hit in the first place.
    --
    -- The split is also the honest grouping - setting a number and nudging one
    -- are different acts, and they now read as different rows instead of as
    -- seven buttons in a line.
    local QTY_GAP, ROW_GAP = 4, 6

    -- Lower row: the box, its steppers, and Create.
    plus:SetPoint("RIGHT", craftAnchor, "LEFT", -12, 0)
    craftCountBox:SetPoint("RIGHT", plus, "LEFT", -QTY_GAP, 0)
    minus:SetPoint("RIGHT", craftCountBox, "LEFT", -QTY_GAP, 0)

    -- Upper row: the setters, sitting directly above the box they write into.
    plusFive:SetPoint("BOTTOMRIGHT", plus, "TOPRIGHT", 0, ROW_GAP)
    nextBtn:SetPoint("RIGHT", plusFive, "LEFT", -QTY_GAP, 0)
    maxBtn:SetPoint("RIGHT", nextBtn, "LEFT", -QTY_GAP, 0)
    oneBtn:SetPoint("RIGHT", maxBtn, "LEFT", -QTY_GAP, 0)

    -- STOP, immediately - cast included.
    --
    -- SpellStopCasting is protected and an addon calling it raises
    -- ADDON_ACTION_FORBIDDEN. StopTradeSkillRepeat is allowed but only ends the
    -- QUEUE: the cast already in flight still completes, which is exactly the
    -- wasted craft stopping is meant to avoid.
    --
    -- A secure button running "/stopcasting" cancels the cast itself, because
    -- the click is a hardware event and the macro runs in that context. So this
    -- sits OVER the craft button while an order runs and takes the click; the
    -- craft button underneath stays plain, which is what lets the panel move
    -- and the nod animate it.
    --
    -- The attributes are set ONCE at creation and never change, so nothing
    -- protected happens mid-order. Combat is handled by a driver rather than by
    -- our own Hide, which combat would refuse.
    local stopButton = CreateFrame("Button", "CraftyStopOverlay", panelRight,
        "SecureActionButtonTemplate, UIPanelButtonTemplate")
    stopButton:SetAllPoints(craftButton)
    stopButton:SetFrameStrata("DIALOG")
    -- OPAQUE. UIPanelButtonTemplate's art is transparent through the middle, so
    -- the button underneath reads straight through it and both captions appear
    -- at once. A backing texture is what makes this a cover rather than a
    -- transparency laid over one.
    local stopBacking = stopButton:CreateTexture(nil, "BACKGROUND")
    stopBacking:SetPoint("TOPLEFT", 2, -2)
    stopBacking:SetPoint("BOTTOMRIGHT", -2, 2)
    -- L1 at full opacity: the token carries 0.95 for panels layered over the
    -- world, and 5% of the caption below is still the caption below.
    local sb = theme.tokens.NEUTRAL.L1
    stopBacking:SetColorTexture(sb.r, sb.g, sb.b, 1)
    stopButton:SetText("Stop")
    -- Registered to the edge the client acts on, as the conversion caster
    -- below does. A secure button registered for the OTHER edge accepts the
    -- click and runs its scripts while the secure action performs nothing, and
    -- says nothing about it.
    local function stopMatchKeyDirection()
        stopButton:RegisterForClicks(C_CVar.GetCVarBool("ActionButtonUseKeyDown")
            and "AnyDown" or "AnyUp")
    end
    stopMatchKeyDirection()
    stopButton:RegisterEvent("CVAR_UPDATE")
    stopButton:SetScript("OnEvent", function(_self, _event, cvar)
        if cvar == "ActionButtonUseKeyDown" then stopMatchKeyDirection() end
    end)
    stopButton:SetAttribute("type", "macro")
    stopButton:SetAttribute("macrotext", "/stopcasting")
    stopButton:Hide()
    RegisterAttributeDriver(stopButton, "visibility", "[combat] hide")

    -- The macro cancels the cast; the queue behind it is ours to end, and so is
    -- the bookkeeping - neither is protected.
    stopButton:SetScript("PostClick", function()
        -- The macro cancelled the cast; the rest is bookkeeping. A conversion
        -- has no order behind it, so these are no-ops there and the cast being
        -- cancelled is the whole of it.
        StopTradeSkillRepeat()
        Addon.crafter:abandonOrder()
        leaveOrder()
        conversionCasting = false
        paintStopButton()
    end)

    -- The stop button is shown exactly while an order is running. Combat is the
    -- one thing that can hold it back: Show and Hide are refused on a secure
    -- frame in combat, so the state is re-asserted when combat ends rather than
    -- left until the next order, which would leave this one unstoppable.
    function paintStopButton()
        if InCombatLockdown() then return end
        stopButton:SetShown(orderRemaining ~= nil or conversionCasting)
    end

    local stopRegen = CreateFrame("Frame")
    stopRegen:RegisterEvent("PLAYER_REGEN_ENABLED")
    stopRegen:SetScript("OnEvent", paintStopButton)

    -- The box counts down while an order runs, so it reads as work remaining
    -- rather than as an intention already spent. Stopping part-way therefore
    -- leaves a correct number to resume from.
    -- ONE owner of the button's label. Render runs on bag updates and skill
    -- changes, mid-order included, so any second writer of this text overwrites
    -- whatever the order state had put there.
    local craftVerb = gameWord("CREATE_PROFESSION", "Create")

    -- The craft button keeps its own verb. Stopping is a different button that
    -- covers it, so the label underneath never has to lie about what a click
    -- will do.
    local function paintCraftButton()
        craftButton:SetText(craftVerb)
    end

    local function setCraftVerb(verb)
        craftVerb = verb or gameWord("CREATE_PROFESSION", "Create")
        paintCraftButton()
    end

    -- The box holds what is still SHORT of the errand's total, so it follows
    -- the bags rather than the casts: a mill that procs nothing changes
    -- neither, and one that yields three moves the number by three. Recomputed
    -- rather than decremented, which also makes it true when the pigment
    -- arrives from anywhere else.
    local function conversionShortfall()
        if not (convertOwed and convertOwed > 0 and convertTarget) then return nil end
        local have = Addon.ledger:getItemCount(convertTarget)
        return math.max(0, convertOwed - (have.bags or 0))
    end

    local function refreshConversionShortfall()
        local short = conversionShortfall()
        if short then craftCountBox:SetText(tostring(short)) end
    end

    local function enterOrder(total)
        orderRemaining = total
        craftCountBox:SetText(tostring(total))
        paintStopButton()
    end

    -- Displayed, not counted. The crafter owns the order's remaining casts
    -- because it is the thing running the order; counting the same events here
    -- would be a second answer to one question.
    local function showRemaining(n)
        orderRemaining = n > 0 and n or nil
        if orderRemaining then craftCountBox:SetText(tostring(orderRemaining)) end
        paintStopButton()
    end

    function leaveOrder()
        if not orderRemaining then return end
        orderRemaining = nil
        paintStopButton()
    end

    events:subscribe("CRAFT:ORDER_START", function(_, payload)
        if payload and payload.count then enterOrder(payload.count) end
    end)
    events:subscribe("CRAFT:COMPLETE", leaveOrder)
    -- The conversion's own cast, watched directly: it runs from a secure
    -- button rather than through crafter, so no order announces it.
    events:subscribe("UNIT_SPELLCAST_START", function(_, unit)
        -- Any player cast while the conversion view is open is this view's:
        -- the only thing castable from here is its verb.
        if unit == "player" and convertTarget then
            conversionCasting = true
            paintStopButton()
        end
    end)
    local function conversionCastEnded(_, unit)
        if unit ~= "player" or not conversionCasting then return end
        conversionCasting = false
        paintStopButton()
    end
    events:subscribe("UNIT_SPELLCAST_SUCCEEDED", conversionCastEnded)
    events:subscribe("UNIT_SPELLCAST_INTERRUPTED", conversionCastEnded)
    events:subscribe("UNIT_SPELLCAST_FAILED_QUIET", conversionCastEnded)
    events:subscribe("UNIT_SPELLCAST_FAILED", conversionCastEnded)

    events:subscribe("CRAFT:PROGRESS", function(_, payload)
        if payload then showRemaining(payload.remaining) end
    end)

    -- ------------------------------------------------------------------
    -- Rendering
    -- ------------------------------------------------------------------

    -- The {r,g,b} color for a recipe's output item quality, derived live from
    -- the output item's ID (the catalog owns the output item; quality is a live
    -- item fact). Falls back to near-white when there is no output item
    -- (enchants) or the item is not cached yet - the fallback is a neutral
    -- default, justified because the name must render a color synchronously and
    -- no quality is a legitimate steady state for enchant recipes, not an error
    -- to surface.
    -- The trailing yield / skill-up, laid out after the name's actual text so
    -- it sits beside it rather than at a fixed offset the name may overrun.
    local function setNameSuffix(recipeID)
        local _, low, high = recipeCatalog:output(recipeID)
        local name = recipeView:name(recipeID) or ""

        local text = ""
        if high and high > 1 and not name:find("%(%d+%-?%d*%)$") then
            text = "(" .. (high > low and (low .. "-" .. high) or high) .. ")"
        end
        -- The same tag the list uses, icon and colour included, so the two
        -- cannot drift.
        local tag = recipeView:skillUpTag(recipeID)
        if tag then text = (text ~= "" and (text .. " ") or "") .. tag end

        nameSuffix:ClearAllPoints()
        nameSuffix:SetPoint("LEFT", detailName, "LEFT",
                            detailName:GetStringWidth() + 8, 0)
        nameSuffix:SetText(text)
    end

    local function qualityColor(recipeID)
        local itemID = recipeCatalog:output(recipeID)
        if itemID and itemID ~= 0 then
            local q = select(3, GetItemInfo(itemID))
            if q then
                local r, g, b = GetItemQualityColor(q)
                return r, g, b
            end
        end
        return 0.9, 0.9, 0.9
    end

    -- Render the detail pane's body for a recipe, with the profession window
    -- guaranteed open. Live-window facts (tools, description, craft verb) are
    -- read directly, no open-state checks - render confirms the recipe valid
    -- before calling this.
    -- Point an action button at a castable stack of the source item, in the
    -- vocabulary the client's click resolver actually reads (Molinari's, which
    -- ships one-click milling on this client):
    --   * the target slot is written BEFORE the spell,
    --   * the spell attribute takes the spell ID, not its name,
    --   * the type attribute is button-specific ("type1" = left click). A
    --     wildcard "type*" is a different lookup and never matches a click,
    --     which is silent rather than an error.
    -- Attribute writes are forbidden in combat (a client-enforced failure
    -- state), so a lockdown leaves the button as it stands; the next bag scan
    -- or render re-points it.
    pointAt = function(btn, sourceItemID)
        if InCombatLockdown() then return end
        local info = recipeCatalog:conversionVerbInfo(convertVerb)
        local bag, slot = Addon.conversionStacks:find(sourceItemID)
        if not info or not bag then
            btn:SetAttribute("type1", nil)
            btn:SetAttribute("spell", nil)
            return
        end
        btn:SetAttribute("target-bag", bag)
        btn:SetAttribute("target-slot", slot)
        btn:SetAttribute("spell", info.spellID)
        btn:SetAttribute("type1", "spell")
    end

    -- A caster is a projection of a target: a secure button that hangs over
    -- some frame and casts the conversion verb at some source's bag stack.
    --
    -- Parented to UIParent because SecureActionButtonTemplate protects its
    -- parents, and a protected frame inside the panel would make the window
    -- unmovable by our own code. It cannot be anchored to the frame it covers
    -- either (that frame moves): it reads a rect and places itself against
    -- the screen.
    --
    -- Visibility is DERIVED, never commanded. A caster is shown exactly when
    -- it is attached to a live frame and armed with a castable stack. Callers
    -- state the target; resolve() is the only writer of position, attributes,
    -- and shown-ness.
    --
    -- The modifier is the third term of the projection: WHICH click casts.
    -- Over a list row, a plain click already means "select this source", so
    -- casting is alt-. Over the verb button there is no other meaning, so
    -- casting is the plain click ("").
    local function makeCaster(name, modifier, look, parent)
        local caster = CreateFrame("Button", name, parent or UIParent,
            look and ("SecureActionButtonTemplate, " .. look)
                or "SecureActionButtonTemplate")

        -- A caster with no button-look of its own sits over a row that cannot
        -- show its own hover, so it says for itself that a click here does
        -- something: a marching border that crawls the row while armed.
        local march
        if not look then
            march = Addon.marchingBorder:create(caster, { inset = -1 })
        end
        caster:SetFrameStrata("DIALOG")
        caster:Hide()

        -- ONE driver, both conditions. The client answers questions we cannot -
        -- "is the key down", "are we fighting" - and may act on a protected
        -- frame for them where we may not. A second RegisterAttributeDriver on
        -- the same attribute REPLACES the first, so combat and the modifier
        -- have to share an expression.
        --
        -- A modified caster exists only while its modifier is held: the row
        -- beneath owns the mouse the rest of the time, which is what keeps the
        -- list hoverable.
        --
        -- Combat has no else clause, and for a caster with no modifier that is
        -- the whole expression. An unmatched driver leaves the frame alone -
        -- SecureStateDriver acts only on the literal "show"/"hide" - so it can
        -- only ever take the frame away, and never fights resolve() over
        -- showing it.
        if modifier ~= "" then
            RegisterAttributeDriver(caster, "visibility",
                "[combat] hide; [mod:" .. modifier:gsub("%-$", "") .. "] show; hide")
        else
            RegisterAttributeDriver(caster, "visibility", "[combat] hide")
        end




        if not look then
            caster:HookScript("OnHide", function(self)
                if self.shining then
                    march:stop()
                    self.shining = false
                end
            end)
        end

        -- The click DIRECTION must match the client's action-button setting.
        -- The dispatcher fires on the edge named by ActionButtonUseKeyDown; a
        -- button registered for the other edge accepts the click, runs its
        -- scripts, and performs nothing - silently.
        local function matchKeyDirection()
            caster:RegisterForClicks(C_CVar.GetCVarBool("ActionButtonUseKeyDown")
                and "AnyDown" or "AnyUp")
        end
        matchKeyDirection()
        caster:RegisterEvent("CVAR_UPDATE")
        caster:SetScript("OnEvent", function(_self, _event, cvar)
            if cvar == "ActionButtonUseKeyDown" then matchKeyDirection() end
        end)

        local function resolve()
            local over, itemID = caster.overFrame, caster.itemID

            -- In combat this frame is untouchable: ClearAllPoints and Hide are
            -- as protected as SetPoint, so standing it down is the same blocked
            -- action as arming it. Leave it entirely alone - the visibility
            -- driver below takes it off screen, and PLAYER_REGEN_ENABLED
            -- re-resolves once we are allowed to place it again.
            if InCombatLockdown() then return end

            if not over or not itemID then
                if not parent then caster:ClearAllPoints() end
                if modifier == "" then caster:Hide() end
                if look and caster.lastOver then caster.lastOver:Show() end
                if march and caster.shining then
                    march:stop()
                    caster.shining = false
                end
                return
            end
            caster.lastOver = over
            if not parent then
                -- Unparented: it hangs over a frame it cannot be anchored to
                -- (a pooled row is re-anchored on every render, and the client
                -- refuses that for a protected frame), so it reads a rect and
                -- places itself against the screen.
                local left, bottom, width, height = over:GetScaledRect()
                if not left then
                    caster:ClearAllPoints()
                    return
                end
                local ui = UIParent:GetEffectiveScale()
                caster:ClearAllPoints()
                caster:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT",
                    left / ui, bottom / ui)
                caster:SetSize(width / ui, height / ui)
            end
            if look then caster:SetText(over:GetText()) end

            -- Molinari's vocabulary: slot first, spell (by ID) last, type
            -- scoped to the exact click. pointAt arms "type1" (a plain left
            -- click); a modified caster moves that to its own modifier, and a
            -- click without the modifier then carries no action and lands in
            -- PostClick instead.
            local castAttr = modifier .. "type1"
            -- Clear the whole action first: pointAt leaves "type1" untouched
            -- when it finds no stack, and a modified caster's own attribute
            -- is not pointAt's to clear - a survivor from the last row would
            -- arm this one at the wrong item.
            caster:SetAttribute("type1", nil)
            caster:SetAttribute(castAttr, nil)
            pointAt(caster, itemID)
            if modifier ~= "" and caster:GetAttribute("type1") then
                caster:SetAttribute(castAttr, "spell")
                caster:SetAttribute("type1", nil)
            end
            local armed = caster:GetAttribute(castAttr) ~= nil
            -- The frame beneath is decoration while a caster with a look is
            -- standing in for it: two buttons in one place would be a lie.
            if look then over:SetShown(not armed) end
            if modifier == "" then
                caster:SetShown(armed)
            elseif armed then
                -- The driver hides on release; it does not show. Arming is
                -- what makes this frame exist, and the modifier is what takes
                -- it away again.
                caster:Show()
                if march and not caster.shining then
                    march:start()
                    caster.shining = true
                end
            elseif not parent then
                -- The driver knows the modifier; it cannot know there is
                -- nothing to cast. An unarmed caster keeps no position, so
                -- the modifier reveals a frame that covers nothing and the
                -- row beneath keeps its click.
                caster:ClearAllPoints()
                caster:SetSize(1, 1)
            end
        end

        -- A driver restores visibility but not anchors, so without this the
        -- frame would come out of combat placed where it was when it went in.
        -- Registered here, below resolve(), because resolve is a local and a
        -- reference from above it would capture a nil global instead.
        local regen = CreateFrame("Frame")
        regen:RegisterEvent("PLAYER_REGEN_ENABLED")
        regen:SetScript("OnEvent", resolve)

        -- Point this caster at a frame and a source; nil either to say there
        -- is nothing to cast here.
        function caster:attach(overFrame, itemID)
            -- Nothing moved, nothing to do. Setting state and acting on it are
            -- two things, and the modifier watcher fires on every Alt press
            -- anywhere in the game - with this panel closed that is nil over
            -- nil, forever, and resolving it did the full protected dance to
            -- change nothing.
            if self.overFrame == overFrame and self.itemID == itemID then return end

            if parent and overFrame and not self.anchored then
                -- Anchored ONCE, for good: our code may not re-anchor a frame
                -- this button has protected, and it never needs to - it rides
                -- its parent.
                self:SetAllPoints(overFrame)
                self.anchored = true
            end
            self.overFrame, self.itemID = overFrame, itemID
            resolve()
        end

        -- A conversion cast is the only moment the source item is known: the
        -- loot that follows is this item's yield, and factCheck compares it
        -- against the shipped range. Recorded on the click itself because
        -- nothing downstream can recover which item was consumed.
        caster:SetScript("PreClick", function(self)
            if self.itemID and Addon.factCheck then
                Addon.factCheck:noteConversion(self.itemID)
            end
            if self.armRepoint then self:armRepoint() end
            -- A conversion is an order of one cast, so the box counts down the
            -- same way a craft's does. It has no crafter behind it - the cast
            -- is a secure click, not a DoTradeSkill - so the click IS the
            -- progress event.
            refreshConversionShortfall()
        end)

        -- RE-POINT AFTER A CAST. The target slot is a function of what is in
        -- the bags, and a cast is the one thing that changes it: five come off
        -- the slot this button is aimed at, and a stack of seven leaves two
        -- behind. attach() cannot see this - the frame and the item are the
        -- same as they were, so it decides nothing moved and returns - which
        -- left the button aimed at a slot too short to cast while the panel
        -- correctly reported casts remaining elsewhere in the bags.
        --
        -- Armed from PreClick, acted on after the bags settle: the stack is
        -- not consumed yet when the click goes out, and BAG_UPDATE_DELAYED is
        -- the client saying what the bags now hold. One shot, because only a
        -- cast moves this - it is not a standing subscription.
        --
        -- PreClick rather than PostClick because PostClick already has owners
        -- here (see altOverlay) and a second SetScript would silently replace
        -- one of them.
        local repointWatch = CreateFrame("Frame")
        repointWatch:SetScript("OnEvent", function(w)
            w:UnregisterEvent("BAG_UPDATE_DELAYED")
            resolve()
        end)
        caster.armRepoint = function() repointWatch:RegisterEvent("BAG_UPDATE_DELAYED") end



        return caster
    end

    -- Over a row: alt casts, and a plain click carries no action so it lands
    -- in this caster's PostClick, meaning what a click on the row means.
    -- Invisible: the row beneath draws itself, and its hover chrome is the
    -- widget's own (a row's OnEnter hook, not this frame's business).
    altOverlay  = makeCaster("CraftyConvertOverlay", "alt-")

    -- Over the verb button: the click casts, because that is the button's
    -- entire meaning in this view. It carries the button's template, so it
    -- IS the button here - real hover, real text colour, real pressed state,
    -- none of which a bare frame covering a button can reproduce. The panel's
    -- own button hides beneath it while a conversion is showing.
    verbOverlay = makeCaster("CraftyConvertVerbOverlay", "",
        "UIPanelButtonTemplate", panelRight)

    -- The row the cursor is on, Alt or no Alt: hovering is what makes a row
    -- the candidate, and the modifier is what makes it armed.
    local hoveredRow, hoveredItem

    followTile = function(rowFrame, item)
        hoveredRow, hoveredItem = rowFrame, item
        -- Only while Alt is held: without the modifier this caster has no
        -- business existing, and a caster sitting on a row is a row that
        -- cannot show its own hover.
        if IsAltKeyDown() then
            altOverlay:attach(rowFrame, item.id)
        end
    end

    -- Selecting the row acted on, whichever way it was clicked.
    --
    -- An ALT-click has already cast by the time this runs, and a plain click
    -- carries no action at all - this caster arms only the alt- modifier - so
    -- it lands here having done nothing else. Both mean the same thing about
    -- the row: it becomes the selected one, so the verb button points where
    -- you last worked.
    --
    -- ONE handler. SetScript replaces rather than adds, so a second write here
    -- silently discards the first - and the two that were here differed, one
    -- of them gated on the modifier.
    altOverlay:SetScript("PostClick", function(self)
        if self.itemID then selectConvertSource(self.itemID) end
    end)

    -- The modifier can go down while the cursor already rests on a row - no
    -- OnEnter fires for that - so the candidate row is armed here instead.
    -- Releasing detaches, and the row has its mouse back.
    local modWatcher = CreateFrame("Frame")
    modWatcher:RegisterEvent("MODIFIER_STATE_CHANGED")
    modWatcher:SetScript("OnEvent", function()
        if IsAltKeyDown() and hoveredRow and hoveredRow:IsMouseOver() then
            altOverlay:attach(hoveredRow, hoveredItem.id)
        else
            altOverlay:attach(nil, nil)
        end
    end)


    -- MILLING ADVANCES TOWARD A GOAL.
    --
    -- One rule, with the goal supplied or not: keep going while there is more
    -- to do. Arriving from a reagent shortfall supplies one - the deficit - and
    -- arriving directly supplies none, which is the unbounded version of the
    -- same sentence rather than a second behaviour.
    --
    -- The deficit is re-read from the bags rather than counted down, so it is
    -- true however the pigment arrived - milled here, bought, mailed in.
    local function conversionGoalMet()
        local short = conversionShortfall()
        if not short then return false end   -- no goal: only an empty bag stops this
        return short == 0
    end

    -- The next source with something to cast, in the order already on screen -
    -- the tile list sorts castable first, then by chance. Announced, because
    -- the verb button silently re-aiming at a different herb is a change the
    -- player did not make: the tile lights, it flares, and a sound plays.
    local function advanceConversionSource()
        for _, src in ipairs(recipeCatalog:conversionSources(convertTarget) or {}) do
            if Addon.conversionStacks:casts(src.sourceID) > 0 then
                -- ANNOUNCED. The verb button silently re-aiming at a different
                -- herb is a change the player did not make, and the selection
                -- highlight alone is easy to miss while watching the count.
                --
                -- The flare is the stack's own: it owns the tile's layout, so
                -- it is the only thing that can move one without becoming a
                -- second authority on where the tile sits.
                selectConvertSource(src.sourceID)
                convertStack:flare(src.sourceID)
                -- 888 is LEVELUP, the one kit verified present on this client
                -- (see factCheck's discovery chime).
                PlaySound(888)
                return true
            end
        end
        return false   -- nothing castable anywhere
    end

    -- Choose the source the verb will consume: the tile lights and the verb
    -- points at it.
    selectConvertSource = function(sourceItemID)
        convertSource = sourceItemID
        convertStack:setSelected(sourceItemID)
        verbOverlay:attach(craftButton, sourceItemID)
        craftButton:SetEnabled(Addon.conversionStacks:casts(sourceItemID) > 0)
    end

    renderConversion = function(itemID)
        local verb = recipeView:conversionRouteTo(itemID)
        convertTarget, convertVerb, convertSource = itemID, verb, nil

        detailIconTex:SetTexture(C_Item.GetItemIconByID(itemID))
        detailIcon.itemID = itemID
        detailName:SetText(recipeView:itemName(itemID) or "")
        nameSuffix:SetText("")
        tint(detailName, theme.crafty.TEXT.TITLE)
        detailInfo:SetText(verb == "prospecting" and "Prospected from" or "Milled from")
        detailCount:SetText("")
        difficultyBar:hide()
        detailCooldown:Hide()
        detailCooldownNote:Hide()
        detailDesc:Hide()
        reagentStack:release()
        reagentHeader:Hide()

        local items = {}
        for _, src in ipairs(recipeCatalog:conversionSources(itemID) or {}) do
            items[#items + 1] = {
                kind   = "tile",
                id     = src.sourceID,
                chance = src.chance,
                qty    = src.qty,
                tier   = src.tier,
                casts  = Addon.conversionStacks:casts(src.sourceID),
            }
        end
        -- What you can act on now leads; the rest keeps its chance order.
        table.sort(items, function(a, b)
            local ah, bh = a.casts > 0, b.casts > 0
            if ah ~= bh then return ah end
            if a.chance ~= b.chance then return a.chance > b.chance end
            return a.id < b.id
        end)
        -- render returns the laid-out height, which is the content frame's
        -- size (the widget's contract).
        convertContent:SetHeight(convertStack:render(items))
        convertHeader:Show()
        convertContent:Show()

        -- OUR words, because the client has none: it defines no Mill or
        -- Prospect caption, having no such button. Imperative, to match
        -- Create - the spell names are "Milling" and "Prospecting", which
        -- name the ability rather than tell the button what it does.
        setCraftVerb(verb == "prospecting" and "Prospect" or "Mill")
        craftButton:Disable()

        -- WHAT YOU NEED, not how many casts it might take. A probabilistic
        -- yield has no honest cast count - the old estimate turned a shortfall
        -- of 10 into "23", a number derived from chance that nobody asked for.
        -- Mill until you have 10; if it takes five extra tries, so be it.
        --
        -- Set here rather than when a source is chosen, because the shortfall
        -- is a property of the errand and does not change with the herb.
        local short = conversionShortfall()
        if short then instance:prefillQuantity(short) end
    end

    local function renderBody(recipeID)

        -- Icon: the recipe's display icon (item icon, spell texture for
        -- enchants), derived by the one derivation home.
        local outItem = recipeCatalog:output(recipeID)
        detailIconTex:SetTexture(recipeView:icon(recipeID))
        -- The tooltip is the crafted ITEM, even where the icon is a spell
        -- texture (enchants). Nil for a recipe that creates no item.
        detailIcon.itemID = outItem

        -- Name, quality-colored (quality stays useful in detail).
        detailName:SetText(recipeView:name(recipeID))
        setNameSuffix(recipeID)
        detailName:SetTextColor(qualityColor(recipeID))

        -- The action verb ("Enchant", "Smelt") is a localized fact read from
        -- the open window (guaranteed open here). The window is the better
        -- source when it answers: it knows this recipe, where the shipped table
        -- knows only the profession.
        local verb
        local idx = Addon.professionWindow:indexForRecipe(recipeID)
        if idx then
            local _, _, _, _, altVerb = GetTradeSkillInfo(idx)
            verb = altVerb
        end
        -- When it does not answer, an AUGMENTING recipe still has a better
        -- word than "Create": what its profession calls modifying an item -
        -- Enchant, Inscribe, Emboss - from SkillLine.AlternateVerb_lang.
        -- Nothing is created, so "Create" was never right for these.
        setCraftVerb(verb or recipeCatalog:augmentVerb(recipeID))

        -- Dead when the reagents are not there. The client refuses the craft
        -- outright, so a live button invites a click that cannot be honoured -
        -- and it is the only element on the panel that would say otherwise,
        -- with the reagent rows and "Can make from bags" both already showing
        -- the shortfall.
        --
        -- A missing TOOL is deliberately still clickable: the native error
        -- names the station and the band's tool cluster nods toward it, which
        -- says more than a greyed button would.
        craftButton:SetEnabled(craftability:fromBags(recipeID) > 0)

        -- Info line: the tool requirement, and how many you are carrying.
        --
        -- Yield and skill-up moved into the NAME, where they read as part of
        -- what the recipe is rather than as a second line to correlate.
        --
        -- Info line: the tool requirement, then how many of the OUTPUT you are
        -- carrying.
        --
        -- The FIRST return only. GetTradeSkillTools returns pairs - name, then
        -- whether the player has it - and the first return is already the whole
        -- comma-joined, localized list with a red colour code around any tool
        -- the player is missing. That red IS the have/have-not answer, and a
        -- tool is not consumed: holding one and holding five are the same
        -- state, so a count beside it says nothing the colour has not said.
        --
        -- The count that matters is the OUTPUT - how many of the thing this
        -- recipe makes you already have, which is what decides whether to craft
        -- at all.
        local parts = {}
        local toolIdx = Addon.professionWindow:indexForRecipe(recipeID)
        local toolText = toolIdx and GetTradeSkillTools(toolIdx)
        if toolText and toolText ~= "" then
            parts[#parts + 1] = "Requires: " .. toolText
        end
        -- NAMED, because "Requires: Cooking Fire   You have 0" reads as "you
        -- have no Cooking Fires". The count is about the OUTPUT and has to say
        -- so when it sits next to a requirement.
        local outID = recipeCatalog:output(recipeID)
        if outID and outID > 0 then
            local n = GetItemCount(outID, true)
            local itemName = recipeView:itemName(outID)
            parts[#parts + 1] = itemName
                and string.format("You have %d %s", n, itemName)
                or string.format("You have %d", n)
        end
        detailInfo:SetText(table.concat(parts, "   "))

        -- Cooldown: a live expiry reads as a countdown in danger, a ready
        -- cooldown reads as ready in success, and a recipe without one says
        -- nothing. The shared-cooldown note is its own neutral line, because
        -- "this shares with related recipes" is a different fact from "it is
        -- ready in 4h" and colouring them together would conflate them.
        local expiry = ledger:getCooldown(recipeID)
        local shared = cooldownData:isShared(recipeID)
        if expiry then
            detailCooldown:SetText(string.format("%s (in %s)",
                recipeView:formatReadyClock(expiry),
                recipeView:formatDuration(expiry - time())))
            local d = theme.tokens.STATE.DANGER
            detailCooldown:SetTextColor(d.r, d.g, d.b)
            detailCooldown:Show()
        elseif cooldownData:hasCooldown(recipeID) then
            local secs = cooldownData:durationSeconds(recipeID)
            local label
            if cooldownData:isDailyReset(recipeID) then
                label = "Daily cooldown (ready)"
            elseif secs then
                label = "Cooldown: " .. recipeView:formatDuration(secs) .. " (ready)"
            else
                label = "Cooldown (ready)"
            end
            detailCooldown:SetText(label)
            local sc = theme.tokens.STATE.SUCCESS
            detailCooldown:SetTextColor(sc.r, sc.g, sc.b)
            detailCooldown:Show()
        else
            detailCooldown:Hide()
        end

        if shared and (expiry or cooldownData:hasCooldown(recipeID)) then
            detailCooldownNote:SetText("Shares a cooldown with related recipes.")
            detailCooldownNote:Show()
        else
            detailCooldownNote:Hide()
        end

        -- Description: trade-skill flavor text read from the open window
        -- (guaranteed open here).
        local descText
        local descIdx = Addon.professionWindow:indexForRecipe(recipeID)
        if descIdx then descText = GetTradeSkillDescription(descIdx) end
        if descText and descText ~= "" then
            detailDesc:SetText(descText)
            detailDesc:Show()
        else
            detailDesc:Hide()
        end

        local crafts = craftability:fromBags(recipeID)
        detailCount:SetText("Can make from bags: |cffffffff" .. crafts .. "|r")

        difficultyBar:show(recipeView:skillProgress(recipeID))

        reagentScroller:contentChanged(
            reagentStack:render(craftability:reagentBreakdown(recipeID)))
    end

    -- Render the detail pane for a recipe (nil, or an id with no catalog entry,
    -- clears it). The profession window is held open by the active session
    -- (opened from an input-driven path where casting is allowed, then kept open
    -- via HideUIPanel with its trade-skill data live), so the body reads
    -- live-window facts directly - render performs no open action itself. render
    -- must stay a pure render: it is reached from event-driven paths (e.g. a
    -- scan completing), and casting to open the window from there is blocked as
    -- tainted.
    local function render(id, kind)
        if kind == "convert" then
            currentRecipeID = nil
            renderConversion(id)
            return
        end

        convertTarget, convertVerb, convertSource = nil, nil, nil
        altOverlay:attach(nil, nil)
        verbOverlay:attach(nil, nil)
        convertHeader:Hide()
        convertContent:Hide()
        reagentHeader:Show()
        setCraftVerb(nil)
        currentRecipeID = id
        local recipeID = id

        if not recipeCatalog:professionOf(recipeID) then
            detailName:SetText("")
            detailCount:SetText("")
            difficultyBar:hide()
            detailIconTex:SetTexture(nil)
            detailIcon.itemID = nil
            detailInfo:SetText("")
            detailCooldown:Hide()
            detailCooldownNote:Hide()
            detailDesc:Hide()
            reagentStack:release()
            craftButton:Disable()
            return
        end

        syncQuantityBox(recipeID)
        renderBody(recipeID)
    end

    -- The selection IS the render input: whatever the recipe panel (or the
    -- tray, through it) selects, this panel shows.
    events:subscribe(EVT_SELECTED, function(_, payload)
        render(payload and payload.id, payload and payload.kind)
    end)

    -- Hop the craft verb in place - the acknowledgment gesture, spoken when
    -- this button's cast just landed on a tool target (the composer relays
    -- the tool's hop here so the two partners in the action nod together).
    function instance:nudgeCraft()
        Addon.motion:hop(craftButton, function(dy)
            craftButton:ClearAllPoints()
            craftButton:SetPoint("CENTER", craftAnchor, "CENTER", 0, dy)
        end)
    end

    --[[
      The goal this visit exists to meet, or nil for a visit with none.

      The TOTAL the errand needs, not the shortfall: the shortfall is a bag
      fact and changes with every pigment that arrives, so it is derived rather
      than stored. Storing both would be two sources for one number.

      SET ON EVERY convert navigation, not only the ones that carry a goal, so a
      visit with no errand clears the last one's. The errand path passes a
      number; every other route passes nil.

      @param n number|nil
    ]]
    --[[
      The quantity currently in the box.

      A journey crumb records it so returning to a level restores the number
      you left with. Without it the box keeps whatever the deepest screen had -
      walking back from six inks turned a two-inscription order into six.

      @return number
    ]]
    function instance:quantity()
        return craftQuantity()
    end

    function instance:setConversionErrand(n)
        convertOwed = n
    end

    -- Show a visit-specific quantity: a detour arrives pre-filled with the
    -- deficit it exists to cover. Programmatic SetText does not fire the
    -- user-input write-back, so the recipe's REMEMBERED quantity is
    -- untouched - this number belongs to the visit, not the recipe.
    function instance:prefillQuantity(n)
        if not craftCountBox then return end
        craftCountBox:SetText(tostring(n))
        -- The visit's number announces itself: a brief brand pulse on the
        -- text, decaying back to normal - the box cannot hop (the stepper
        -- chain anchors through it), so color carries the attention.
        local b = theme.tokens.BRAND.PRIMARY
        Addon.motion:run(craftCountBox, function(elapsed)
            local t = elapsed / 0.8
            if t >= 1 then
                craftCountBox:SetTextColor(1, 1, 1)
                return true
            end
            local mix = 1 - t
            craftCountBox:SetTextColor(
                1 + (b.r - 1) * mix, 1 + (b.g - 1) * mix, 1 + (b.b - 1) * mix)
        end)
    end

    -- Re-render the current recipe in place, for data-only changes (bag scans,
    -- cooldown sweeps, skill-ups). No-op when nothing is shown.
    function instance:rerender()
        -- The conversion view lives on bag facts (casts held, which stack the
        -- verb points at), so a bag scan re-renders it like any recipe -
        -- keeping the chosen source if it is still castable.
        if convertTarget then
            local keep = convertSource
            renderConversion(convertTarget)
            if keep and Addon.conversionStacks:casts(keep) > 0 then
                selectConvertSource(keep)
            elseif keep then
                -- The source ran dry. Either the goal is met and the run is
                -- over, or there is more to do and the next castable source
                -- takes over - so milling a bag of mixed herbs does not stop
                -- at every stack boundary.
                --
                -- 888 is LEVELUP, the one kit verified present on this client
                -- (see factCheck's discovery chime). Done sounds the same
                -- whether the goal was a deficit or an empty bag.
                if conversionGoalMet() or not advanceConversionSource() then
                    PlaySound(888)
                end
            end
            return
        end
        if currentRecipeID then render(currentRecipeID) end
    end

    -- The detail icon when it is shown, else nil: the craft-origin fallback for
    -- arrival attribution (a Craftable filter can drop a recipe's row the moment
    -- the craft consumes the last materials; the icon still represents it).
    function instance:visibleIcon()
        return detailIconTex:GetTexture() and detailIcon or nil
    end

    return instance
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("detailPanel",
        {"ledger", "craftability", "recipeCatalog", "recipeView", "cooldownData",
         "professionWindow", "crafter", "rowStack", "textBox", "theme", "events",
         "motion", "utils"})
end

Addon.detailPanel = detailPanel
return detailPanel
