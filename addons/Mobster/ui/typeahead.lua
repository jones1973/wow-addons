--[[
  ui/typeahead.lua
  NPC-name typeahead dropdown, backed by Questie's database

  Shows up to MAX_RESULTS rows below (visually above) the edit box as the user
  types. Each row is a (NPC name, zone) pair — NPCs that spawn in multiple
  zones produce one row per zone, so duplicates in different zones can be
  distinguished by the user.

  Integration model:

    The caller (watchList) owns the edit box's OnTextChanged script. It
    forwards user-driven text changes to typeahead:onQuery(text). This keeps
    programmatic SetText (e.g., when entering edit mode on an existing row)
    from popping the dropdown — the caller simply doesn't forward those.

  Questie loading: Questie's DB initializes asynchronously in staged
  coroutines, so it may not be ready at addon load. We resolve Questie
  references on every query and silently return no results if anything is
  missing. If Questie isn't installed at all, typeahead is a no-op and the
  addon degrades to its pre-typeahead UX.

  Dependencies: constants
  Exports: Addon.typeahead
]]

local ADDON_NAME, Addon = ...

local typeahead = {}

-- Module references (resolved at init)
local constants

-- UI state
local dropdown
local scrollFrame      -- scroll viewport inside the dropdown backdrop
local scrollContent    -- sized to fit all rows; scrolled inside scrollFrame
local rowPool          -- Addon.pool instance, created in attach()
local headerPool       -- Addon.pool instance, created in attach()
local activeRows    = {}  -- rows currently on-screen; released each showResults
local activeHeaders = {}  -- headers currently on-screen; released each showResults
local attachedEdit
local onPickFn
local configuredWidth

-- Debounce: bump token on every query; timer runs only if token unchanged.
local queryToken = 0

-- Zone name lookup cache so we don't hit Questie's l10n on every result.
-- Keyed by zoneId; value is the display string.
local zoneNameCache = {}

-- ============================================================================
-- FILE-LOCAL CONSTANTS
-- ============================================================================

local DEBOUNCE_SECONDS = 0.2
-- Sanity cap. Below this, every match is shown. Above this, we stop
-- building rows — protects against pathological 1-2 letter queries that
-- would make Questie's full NPCPointers scan + per-row spawn lookup
-- noticeably slow.
local MAX_RESULTS      = 100
local VISIBLE_MAX_ROWS = 7   -- rows visible without scrolling
local MIN_QUERY_LEN    = 2
local ROW_HEIGHT       = 36
local ROW_NAME_TOP     = 6   -- name fontstring y-offset from row top
local ROW_ZONE_TOP     = 20  -- zone fontstring y-offset from row top
local ROW_INSET        = 10  -- horizontal padding inside dropdown
local ROW_ZONE_INDENT  = 4   -- zone sits a touch indented under the name
local PAD              = 8   -- inner frame padding
local SCROLLBAR_W      = 20  -- gutter on the right for the scrollbar widget
local HEADER_HEIGHT    = 24  -- section header between current-zone and rest
local HEADER_INSET     = 10

-- Named so we can reach the scrollbar child via _G[name .. "ScrollBar"],
-- which UIPanelScrollFrameTemplate creates using the $parent pattern.
local SCROLL_FRAME_NAME = ADDON_NAME .. "TypeaheadScroll"

-- Color palette. Gold (Blizzard UI accent) signals "in your current zone";
-- the hover tint is a brighter blue than before so mouseover reads clearly
-- against the opaque dark background.
local BG_R,     BG_G,     BG_B,     BG_A     = 0.05, 0.05, 0.07, 1.0
local GOLD_R,   GOLD_G,   GOLD_B               = 1.00, 0.82, 0.00
local HL_R,     HL_G,     HL_B,     HL_A     = 0.35, 0.65, 1.00, 0.35
local ACCENT_W                                  = 3     -- gold stripe width
local HEADER_BG_ALPHA                           = 0.10  -- faint gold band

-- ============================================================================
-- QUESTIE ACCESS
-- ============================================================================

--[[
  Resolve Questie's modules. Returns nil for any piece that's not available.
  Called on every query so we tolerate Questie loading after us.

  @return table|nil QuestieDB
  @return table|nil QuestieSearch
  @return table|nil QuestieJourneyUtils
  @return function|nil l10n
]]
local function resolveQuestie()
    local loader = _G.QuestieLoader
    if not loader or not loader.ImportModule then
        return nil
    end

    -- ImportModule returns a module table or, if the module isn't registered,
    -- may error. We pcall each one defensively.
    local ok, qdb     = pcall(loader.ImportModule, loader, "QuestieDB")
    local _,  qs      = pcall(loader.ImportModule, loader, "QuestieSearch")
    local _,  qju     = pcall(loader.ImportModule, loader, "QuestieJourneyUtils")
    local _,  qlocale = pcall(loader.ImportModule, loader, "l10n")

    if not ok or not qdb or not qs or not qju or not qlocale then
        return nil
    end

    -- NPCPointers is populated late in Questie's init. If it isn't there yet,
    -- QuestieSearch:Search would iterate nothing and return empty — that's
    -- fine, but we bail here for clarity.
    if not qdb.NPCPointers then
        return nil
    end

    return qdb, qs, qju, qlocale
end

--[[
  Translate a Questie spawn zone id to a displayable zone name. Uses Questie's
  own canonical path (QuestieJourneyUtils:GetZoneName -> l10n) so the string
  matches what GetZoneText() returns in the client's locale. Results are
  cached for the session.

  @param zoneId number
  @param qju table QuestieJourneyUtils module
  @param l10n function Questie l10n callable
  @return string|nil Display name or nil if resolution failed
]]
local function zoneDisplayName(zoneId, qju, l10n)
    local cached = zoneNameCache[zoneId]
    if cached ~= nil then
        return cached
    end

    local ok, raw = pcall(qju.GetZoneName, qju, zoneId)
    if not ok or not raw then
        zoneNameCache[zoneId] = false
        return nil
    end

    local ok2, localized = pcall(l10n, raw)
    local result = (ok2 and localized) or raw
    zoneNameCache[zoneId] = result
    return result
end

-- ============================================================================
-- SEARCH
-- ============================================================================

--[[
  Query Questie for NPCs matching the text. Returns a list of {name, zone}
  entries, capped at MAX_RESULTS. An NPC produces one entry per zone it
  resolves in; if the NPC has no resolvable zone data at all (no spawns, or
  spawns whose zone ids don't translate) it still produces a single entry
  with zone=nil so the user can pick it as a freeform (zone-agnostic) match.
  Returns empty list if Questie isn't ready.

  @param text string
  @return table Array of {name=string, zone=string|nil}
]]
local function runQuery(text)
    local qdb, qs, qju, l10n = resolveQuestie()
    if not qdb then return {} end

    local ok, ids = pcall(qs.Search, qs, text, "npc", "chars")
    if not ok or not ids then return {} end

    local results = {}
    local seen = {}  -- dedupe on "name|zone" (zone may be empty string)

    -- Helper: push a {name, zone} entry if not already seen and under cap.
    -- Returns false when the cap is hit so the caller can break out.
    local function pushEntry(name, zone)
        if #results >= MAX_RESULTS then return false end
        local key = name .. "|" .. (zone or "")
        if seen[key] then return true end
        seen[key] = true
        results[#results + 1] = { name = name, zone = zone }
        return true
    end

    for id in pairs(ids) do
        if #results >= MAX_RESULTS then break end

        local name   = qdb.QueryNPCSingle(id, "name")
        local spawns = name and qdb.QueryNPCSingle(id, "spawns")

        if name then
            local producedAnyZoneRow = false

            if spawns then
                for zoneId in pairs(spawns) do
                    -- Note: we intentionally do NOT filter on whether the
                    -- zone entry contains coord pairs. Mobster only cares
                    -- that Questie associates the NPC with this zone; the
                    -- coords would be useful for map pins, which we don't
                    -- do.
                    local zone = zoneDisplayName(zoneId, qju, l10n)
                    if zone then
                        if not pushEntry(name, zone) then break end
                        producedAnyZoneRow = true
                    end
                end
            end

            -- Fallback: no spawns, or no spawn zones resolved to a name.
            -- Still surface the NPC — the user picked it for a reason, and
            -- a zoneless entry is a valid freeform watch-list item.
            if not producedAnyZoneRow then
                if not pushEntry(name, nil) then break end
            end
        end
    end

    -- Sort by name, then by zone. nil zones sort before any real zone name
    -- so an NPC's zoneless entry (when present) sits at the top of its group.
    table.sort(results, function(a, b)
        if a.name ~= b.name then return a.name < b.name end
        if a.zone == b.zone then return false end
        if a.zone == nil then return true  end
        if b.zone == nil then return false end
        return a.zone < b.zone
    end)

    return results
end

-- ============================================================================
-- DROPDOWN RENDERING
-- ============================================================================

--[[
  Factory for a single result row. The shared pool calls this when it
  needs a new row; recycling is handled by the pool.
]]
local function createResultRow()
    local row = CreateFrame("Button", nil, scrollContent)
    row:SetHeight(ROW_HEIGHT)

    -- Current-zone accent: gold stripe on the left edge, hidden by default.
    -- showResults toggles visibility based on whether the row's zone matches
    -- the player's current zone.
    local accent = row:CreateTexture(nil, "ARTWORK")
    accent:SetPoint("TOPLEFT", 0, 0)
    accent:SetPoint("BOTTOMLEFT", 0, 0)
    accent:SetWidth(ACCENT_W)
    accent:SetColorTexture(GOLD_R, GOLD_G, GOLD_B, 0.9)
    accent:Hide()
    row.accent = accent

    local hl = row:CreateTexture(nil, "BACKGROUND")
    hl:SetAllPoints()
    hl:SetColorTexture(HL_R, HL_G, HL_B, HL_A)
    hl:Hide()
    row.hl = hl

    -- Name on top. Anchored left and right so it flexes with dropdown width,
    -- no-wrap so a long name clips at the edge rather than overflowing into
    -- the next row's space.
    local nameFS = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameFS:SetPoint("TOPLEFT", ROW_INSET, -ROW_NAME_TOP)
    nameFS:SetPoint("TOPRIGHT", -ROW_INSET, -ROW_NAME_TOP)
    nameFS:SetJustifyH("LEFT")
    nameFS:SetWordWrap(false)
    row.nameFS = nameFS

    -- Zone below name, smaller, gray, indented.
    local zoneFS = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    zoneFS:SetPoint("TOPLEFT", ROW_INSET + ROW_ZONE_INDENT, -ROW_ZONE_TOP)
    zoneFS:SetPoint("TOPRIGHT", -ROW_INSET, -ROW_ZONE_TOP)
    zoneFS:SetJustifyH("LEFT")
    zoneFS:SetWordWrap(false)
    row.zoneFS = zoneFS

    row:SetScript("OnEnter", function(self) self.hl:Show() end)
    row:SetScript("OnLeave", function(self) self.hl:Hide() end)
    row:SetScript("OnClick", function(self)
        if onPickFn and self.data then
            onPickFn(self.data.name, self.data.zone)
        end
        typeahead:hide()
    end)

    return row
end

--[[
  Factory for a section header. Non-interactive. Visually subordinate to
  result rows: shorter, gold text on a faint gold band.
]]
local function createSectionHeader()
    local header = CreateFrame("Frame", nil, scrollContent)
    header:SetHeight(HEADER_HEIGHT)

    -- Faint gold band under the section title — just enough to register as
    -- a distinct band against the dark background.
    local bg = header:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(GOLD_R, GOLD_G, GOLD_B, HEADER_BG_ALPHA)

    -- GameFontNormal is Blizzard's native gold at 12pt, which is the right
    -- semantic color for a section header in the WoW UI vocabulary.
    local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", HEADER_INSET, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    header.text = text

    return header
end

local function showResults(results)
    if not dropdown then return end

    -- Release everything from the prior render back to its pool. The pool
    -- hides frames on release, so the viewport is clean before we lay out
    -- the next frame of results.
    rowPool:releaseAll(activeRows)
    headerPool:releaseAll(activeHeaders)

    if #results == 0 then
        dropdown:Hide()
        return
    end

    -- Partition by player's current zone. An empty GetZoneText() (e.g.,
    -- during a loading screen) will simply dump everything into `elsewhere`.
    local currentZone = GetZoneText() or ""
    local here, elsewhere = {}, {}
    for _, r in ipairs(results) do
        if currentZone ~= "" and r.zone == currentZone then
            here[#here + 1] = r
        else
            elsewhere[#elsewhere + 1] = r
        end
    end

    -- Only bother with section headers if both groups have content; a lone
    -- header on a single-group result set just adds visual noise.
    local showHeaders = (#here > 0) and (#elsewhere > 0)

    -- Build the render list as a mixed sequence of headers and rows. Each
    -- row carries a `here` flag so the placement loop can toggle the
    -- current-zone accent on it.
    local renderList = {}
    if showHeaders then
        renderList[#renderList + 1] = { kind = "header", text = "In " .. currentZone }
        for _, r in ipairs(here) do
            renderList[#renderList + 1] = { kind = "row", data = r, here = true }
        end
        renderList[#renderList + 1] = { kind = "header", text = "Other Zones" }
        for _, r in ipairs(elsewhere) do
            renderList[#renderList + 1] = { kind = "row", data = r, here = false }
        end
    else
        -- Single-group case: all rows share the same flag.
        local source  = (#here > 0) and here or elsewhere
        local isHere  = #here > 0
        for _, r in ipairs(source) do
            renderList[#renderList + 1] = { kind = "row", data = r, here = isHere }
        end
    end

    -- Place items top-to-bottom, tracking cumulative height.
    local y = 0
    for _, item in ipairs(renderList) do
        if item.kind == "header" then
            local header = headerPool:acquire()
            header.text:SetText(item.text)
            header:ClearAllPoints()
            header:SetPoint("TOPLEFT", 0, -y)
            header:SetPoint("TOPRIGHT", 0, -y)
            header:Show()
            activeHeaders[#activeHeaders + 1] = header
            y = y + HEADER_HEIGHT
        else
            local row = rowPool:acquire()
            local data = item.data
            row.nameFS:SetText(data.name)
            if data.zone then
                row.zoneFS:SetText("(" .. data.zone .. ")")
                row.zoneFS:Show()
            else
                row.zoneFS:SetText("")
                row.zoneFS:Hide()
            end
            row.data = data
            row.accent:SetShown(item.here)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -y)
            row:SetPoint("TOPRIGHT", 0, -y)
            row:Show()
            activeRows[#activeRows + 1] = row
            y = y + ROW_HEIGHT
        end
    end

    -- scrollContent holds every header + row; its height is the full extent.
    scrollContent:SetHeight(y)

    -- Dropdown viewport fits content, capped at VISIBLE_MAX_ROWS rows so
    -- it never crowds the title.
    local cap = VISIBLE_MAX_ROWS * ROW_HEIGHT
    local viewportH = math.min(y, cap)
    dropdown:SetHeight(viewportH + PAD * 2)

    -- Start each new query scrolled to the top.
    scrollFrame:SetVerticalScroll(0)

    -- Show the scrollbar when content exceeds the viewport.
    local scrollBar = _G[SCROLL_FRAME_NAME .. "ScrollBar"]
    if scrollBar then
        if y > viewportH then
            scrollBar:Show()
        else
            scrollBar:Hide()
        end
    end

    dropdown:Show()
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Handle a user-driven text change. Caller is responsible for NOT invoking
  this on programmatic SetText (e.g., when loading an existing entry into
  the edit box for editing). Debounces by DEBOUNCE_SECONDS; short queries
  hide the dropdown immediately.

  @param text string
]]
function typeahead:onQuery(text)
    queryToken = queryToken + 1
    local myToken = queryToken

    if (not text) or #text < MIN_QUERY_LEN then
        if dropdown then dropdown:Hide() end
        return
    end

    C_Timer.After(DEBOUNCE_SECONDS, function()
        -- Later keystroke landed before our timer fired; discard this one.
        if myToken ~= queryToken then return end
        -- Edit box may have been detached (e.g., if UI is being torn down).
        if not attachedEdit then return end
        -- If the edit box is no longer visible, don't surface the dropdown.
        if not attachedEdit:IsVisible() then return end

        showResults(runQuery(text))
    end)
end

--[[
  Force-hide the dropdown. Called on pick (internal), on Apply, on Esc, and
  on edit-mode entry.
]]
function typeahead:hide()
    queryToken = queryToken + 1  -- invalidate any in-flight debounced query
    if dropdown then dropdown:Hide() end
end

--[[
  Wire the typeahead to an edit box. Does not install script handlers on the
  edit box itself — the caller drives :onQuery(text) and :hide().

  @param editBox Frame The edit box the user types into
  @param parent Frame Frame to parent the dropdown to (typically the main UI)
  @param width number Desired dropdown width in pixels
  @param onPick function Callback(name, zone) when user picks a result
]]
function typeahead:attach(editBox, parent, width, onPick)
    attachedEdit     = editBox
    onPickFn         = onPick
    configuredWidth  = width

    dropdown = Addon.panel:opaque(parent, {
        parentStrata = true,
        r = BG_R, g = BG_G, b = BG_B, a = BG_A,
    })
    dropdown:SetWidth(width)

    -- Scroll viewport inside the dropdown backdrop. UIPanelScrollFrameTemplate
    -- brings its own scrollbar + mouse-wheel handler; we just reserve room
    -- for the scrollbar on the right so rows don't visually jump when the
    -- scrollbar shows or hides.
    scrollFrame = CreateFrame("ScrollFrame", SCROLL_FRAME_NAME, dropdown,
                              "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", PAD, -PAD)
    scrollFrame:SetPoint("BOTTOMRIGHT", -PAD - SCROLLBAR_W, PAD)

    -- scrollContent holds every row; its width matches the viewport, its
    -- height is set dynamically in showResults to the full list extent.
    scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(width - PAD * 2 - SCROLLBAR_W, 1)
    scrollFrame:SetScrollChild(scrollContent)

    -- Initialize the shared pools here — the factories close over
    -- scrollContent (as the parent for their CreateFrame calls), so the
    -- pools cannot be constructed at module load time.
    rowPool    = Addon.pool:new(createResultRow)
    headerPool = Addon.pool:new(createSectionHeader)

    -- Grow upward from above the edit box. The dropdown overlays the
    -- scroll area while the user is typing; that's intentional — the user's
    -- attention is on the input, and the dropdown disappears as soon as
    -- they pick or clear the text. The horizontal offset lines the
    -- dropdown's left edge up with the scroll-area left, not the edit box,
    -- which sits a bit inward due to InputBoxTemplate's decorative caps.
    dropdown:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT", -8, 10)
    dropdown:Hide()
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function typeahead:initialize()
    constants = Addon.constants

    if not constants then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444typeahead: Missing dependencies|r")
        return false
    end

    return true
end

Addon.typeahead = typeahead
return typeahead
