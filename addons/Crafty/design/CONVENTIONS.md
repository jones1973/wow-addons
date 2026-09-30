# Addon Development Conventions

Generated from Paw and Order (PAO) — the reference implementation.
All new addons should follow these patterns unless there's a documented reason to deviate.

---

## 1. Project Structure

### File Organization

```
AddonName.toc
core\files.xml          -- Core systems (events, utils, commands, dependencies, data, options)
libs\                   -- External libraries (HereBeDragons, LibStub, etc.)
data\files.xml          -- Static data tables and persistence layers
logic\files.xml         -- Game logic, algorithms, business rules
ui\files.xml            -- Frames, rendering, user interaction
tools\files.xml         -- Non-production utilities (harvesters, extractors, debug tools)
main.lua                -- Application entry point (last in .toc)
```

### Separation of Concerns

UI files handle frames, rendering, and user interaction — never algorithms or data access.
Logic files handle algorithms, state management, and game event interpretation — never frame creation.
Data files hold static tables and persistence abstractions — never rendering or business rules.

If a file needs to touch two layers, that's a signal to split it or route through the event system.

### Reusable Core

The `core/` directory is a toolkit that any addon can drop in unchanged. If you have to edit a core file to use it in a different addon, it's not properly separated.

Core files get all addon identity from the vararg (`local ADDON_NAME, Addon = ...`). They never hardcode addon names, SavedVariable names, or domain-specific logic. This means the following are core — they work in any addon without modification:

- `events.lua` — pub/sub system
- `dependencies.lua` — module registration and topological init
- `commands.lua` — slash command registry
- `dataStore.lua` — generic CRUD with entity type registration
- `exports.lua` — data export registry
- `pool.lua` — frame/object pooling utility
- `errorHandler.lua` — global error capture
- `options.lua` — Get/Set/Callback infrastructure (not the setting definitions themselves)
- `utils.lua` — debug/chat/error/notify messaging (not domain-specific helpers)

Domain-specific helpers (pet utilities, NPC classification, quest chain logic) belong in `logic/`, even if they feel like "utilities." The test is: would another addon need this function? If not, it's not core.

Setting definitions (keys, defaults, categories, validation) are addon-specific configuration, not core infrastructure. Keep them in a separate file (e.g., `data/settingDefaults.lua`) that the generic `options.lua` consumes.

### TOC File

The `.toc` controls metadata, SavedVariables, and load order:

```toc
## Interface: 110002
## Title: Addon Display Name
## Notes: One-line description
## Author: Your Name
## Version: 1.0.0
## SavedVariables: prefix_settings, prefix_data
## SavedVariablesPerCharacter: prefix_character

## Core systems (events, utils, commands, dependencies, data access)
core\files.xml

## External libraries (HereBeDragons, LibStub, etc.)
libs\LibName\LibName.lua

## Static data tables and persistence layers
data\files.xml

## Non-production tools (harvesters, extractors, debug utilities)
tools\files.xml

## Game logic (algorithms, state management, business rules)
logic\files.xml

## UI (frames, rendering, user interaction)
ui\files.xml

## Application entry point — always last
main.lua
```

### Load Order

Core loads first because everything depends on `utils`, `events`, and the dependency resolver. Libraries load after core so they're available when data/logic files initialize. Static data loads before logic so logic modules can reference it during init. Logic loads before UI so UI modules can depend on logic. `main.lua` loads last — it wires the slash command and triggers initialization via `ADDON_LOADED`.

Within each layer, the `files.xml` manifest controls internal ordering. Shared/base modules load before modules that depend on them:

```xml
<Ui xmlns="http://www.blizzard.com/wow/ui/">
    <!-- Base systems first — these have no internal dependencies -->
    <Script file="utils.lua"/>
    <Script file="events.lua"/>
    <Script file="dependencies.lua"/>

    <!-- Systems that depend on utils/events -->
    <Script file="commands.lua"/>
    <Script file="options.lua"/>

    <!-- Higher-level modules that depend on the above -->
    <Script file="dataStore.lua"/>
    <Script file="location.lua"/>
</Ui>
```

### main.lua

The entry point is minimal, but it owns the initialization sequence. It exposes the addon globally, initializes SavedVariable defaults on `ADDON_LOADED`, then directly calls the dependency resolver. No timers, no second `ADDON_LOADED` listener — `main.lua` is the single owner of startup ordering.

```lua
-- main.lua - Application Entry Point
-- Owns the initialization sequence: SV defaults, then module init.
-- The dependency system exposes initializeAllModules but does NOT
-- independently listen for ADDON_LOADED — main.lua calls it directly.
local ADDON_NAME, Addon = ...

-- Global access for /dump debugging
MYADDON = Addon

local evt = CreateFrame("Frame")
evt:RegisterEvent("ADDON_LOADED")
evt:SetScript("OnEvent", function(self, event, arg1)
    if arg1 ~= ADDON_NAME then return end

    -- Step 1: Initialize SavedVariable defaults (nil-coalesce pattern)
    prefix_settings = prefix_settings or {}
    local defaults = { debugMode = false }
    for k, v in pairs(defaults) do
        if prefix_settings[k] == nil then
            prefix_settings[k] = v
        end
    end

    -- Step 2: Initialize all modules (synchronous — no timer)
    -- All files are loaded by now (WoW loads .toc synchronously before
    -- firing ADDON_LOADED), so every registerModule call has already run.
    if Addon.dependency and Addon.dependency.initializeAllModules then
        Addon.dependency.initializeAllModules()
    end

    self:UnregisterEvent("ADDON_LOADED")
end)

-- Single slash command; all functionality routes through subcommands
SLASH_MYADDON1 = "/myaddon"
SlashCmdList["MYADDON"] = function(msg)
    if Addon.commands then
        Addon.commands:execute(msg)
    end
end
```

---

## 2. Namespace & Naming

### The Addon Table

Every file receives the shared addon table via the vararg:

```lua
local ADDON_NAME, Addon = ...
```

All modules attach to `Addon`:

```lua
Addon.myModule = myModule
```

### External vs Internal Name

The addon has two names. The **internal name** is always `Addon` — generic by design. This is what makes core files reusable across projects: every file gets its identity from `local ADDON_NAME, Addon = ...`, so `events.lua`, `commands.lua`, `pool.lua`, etc. work in any addon without editing. If core files referenced `PAO` instead of `Addon`, you'd need find-and-replace across every file for each new project.

The **external name** (e.g., `PAO`) is the global exposed in `main.lua` for `/dump` access. It's assigned once, in one file, and never used internally.

```lua
-- main.lua only — the single boundary between internal and external names:
PAO = Addon

-- Everywhere else:
local ADDON_NAME, Addon = ...
-- Use Addon.whatever, never PAO.whatever
```

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Local variables, functions, methods | lowerCamelCase | `petCache`, `buildPetFromAPI` |
| Module tables | lowerCamelCase | `local circuitTracker = {}` |
| Constants (file-local) | UPPER_SNAKE_CASE | `local EDGE_PADDING = 20` |
| Constants (shared) | UPPER_SNAKE_CASE on a constants table | `constants.XP_BUFF` |
| Global SavedVariables | `prefix_` lowercase | `prefix_settings`, `prefix_npc` |
| Frame names (when needed) | ADDON_NAME prefix | `ADDON_NAME .. "OptionsPanel"` |
| Event names (WoW) | ALL_CAPS | `PET_JOURNAL_LIST_UPDATE` |
| Event names (addon) | NAMESPACE:NAME | `"CACHE:INITIALIZED"`, `"LEVELING:QUEUE_CHANGED"` |

### SavedVariable Naming

Settings containers use **plural** forms: `prefix_settings`.
Database containers use **singular**: `prefix_npc`, `prefix_pet`, `prefix_circuit`.
Per-character variables: `prefix_character`.
Shared tooling namespace: `prefix_tools`.

All SavedVariables must be declared in the `.toc` — WoW only persists globals listed there. Account-wide state goes in `SavedVariables`, per-character state in `SavedVariablesPerCharacter`. The initialization pattern (nil-coalesce with defaults) is covered in Section 7.

---

## 3. Module System & Dependencies

### Registration Pattern

Every module follows this exact structure:

```lua
--[[
  logic/myModule.lua
  Brief Description of What This Module Does

  Longer explanation if needed — what problem it solves, how it fits
  into the addon architecture, any non-obvious design decisions.

  Dependencies: utils, events, constants
  Exports: Addon.myModule
]]

local ADDON_NAME, Addon = ...

local myModule = {}

-- Module references (resolved at init, not at file load)
local utils, events, constants

-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

--[[
  Compute distance between two NPC locations.
  Uses world coordinates for cross-zone accuracy.

  @param a table - Location {mapID, x, y}
  @param b table - Location {mapID, x, y}
  @return number - Distance in yards
]]
local function computeDistance(a, b)
    -- HereBeDragons expects 0-1 range, our data stores 0-100
    return HBD:GetZoneDistance(a.mapID, a.x / 100, a.y / 100,
                              b.mapID, b.x / 100, b.y / 100)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Process a batch of NPCs for the current circuit.

  @param npcIds table - Array of NPC IDs (integers, not strings)
  @return table - Sorted array of valid NPCs
]]
function myModule:processBatch(npcIds)
    -- ...
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function myModule:initialize()
    -- Resolve module references HERE, not at file scope
    utils = Addon.utils
    events = Addon.events
    constants = Addon.constants

    if not utils or not events then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444myModule: Missing dependencies|r")
        return false
    end

    -- Subscribe to events, register commands, etc.

    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("myModule", {"utils", "events", "constants"}, function()
        return myModule:initialize()
    end)
end

Addon.myModule = myModule
return myModule
```

### Key Rules

**Never resolve module references at file scope.** At file load time, other modules may not exist yet. All `Addon.whatever` lookups happen inside `initialize()`.

**Declare dependencies explicitly.** The dependency array in `registerModule` is the contract. If you call `Addon.foo` at init time, `"foo"` must be in your dependency list.

**The dependency system handles initialization order.** It performs topological sort, detects circular dependencies, and initializes modules in the correct order. You never manually control init order.

**Pre-initialized modules** (`events`, `utils`) are available before the dependency system runs. They're declared in `PREINIT_MODULES` in `dependencies.lua`.

**Circular dependency escape hatch**: If module A depends on B and B depends on A, one side must omit the dependency and access the other module at runtime (via event handlers, which fire after all modules are initialized). Document this with a comment explaining why it's safe.

### Self-Registration Principle

All registration patterns in the addon follow the same shape: a registrar module loads first (earlier in file order), and consumer modules call `:register()` during their own initialization. This applies to module dependencies, tab registration, command registration, entity types, filter types, data exports, and classification rules. The registrar never reaches out to consumers — consumers always come to the registrar.

---

## 4. Event System

### Architecture

A single unified pub/sub system handles both WoW game events and internal addon events. There is **one event frame** for the entire addon. Individual modules never create their own event frames or call `RegisterEvent` directly.

### API

```lua
-- Subscribe (returns ID for later unsubscribe)
local subId = events:subscribe("EVENT_NAME", function(eventName, ...)
    -- handler receives event name as first arg, then WoW event args
end)

-- Unsubscribe (only needed for temporary subscriptions)
events:unsubscribe(subId)

-- Emit addon event (internal pub/sub only — never for WoW events)
events:emit("NAMESPACE:NAME", payload)
```

### Convention: WoW vs Addon Events

WoW events are `ALL_CAPS` without colons: `PET_BATTLE_OVER`, `ADDON_LOADED`.
Addon events use `NAMESPACE:NAME` format: `"CACHE:INITIALIZED"`, `"CIRCUIT:COMPLETED"`, `"SETTING:LISTING_CHANGED"`.

The colon is the discriminator — the system uses it to distinguish WoW events (which get `RegisterEvent`) from addon events (which are pure pub/sub).

### Handler Signatures

WoW events: `function(eventName, arg1, arg2, ...)` — same args as the WoW event.
Addon events: `function(eventName, payload)` — payload is a single table.

### Event-Driven Over Polling

Modules subscribe to events rather than polling state. If you need to react to a change, emit an event from the source and subscribe from the consumer. The only acceptable polling is throttled `OnUpdate` for visual feedback (e.g., mouse tracking during drag operations).

### Subscription Lifecycle

Most subscriptions are permanent (ignore the returned subId). For temporary subscriptions (e.g., waiting for a one-time event during initialization), store the subId and call `unsubscribe` when done.

The system snapshots handler IDs before dispatch, so handlers can safely unsubscribe during iteration.

### Handler Isolation

The dispatch loop `pcall`s each handler individually. If handler #2 of 5 throws, handlers 3-5 still run. Without isolation, one buggy subscriber silently breaks all downstream subscribers for that event — you see one error but actually have four problems (the original bug plus three features that stopped working for no visible reason).

```lua
-- In dispatch: pcall each handler so one failure doesn't stop the rest
for _, subId in ipairs(handlerIds) do
    local handler = eventHandlers[subId]
    if handler then
        -- Isolate: a bad handler must not prevent other handlers from running
        local ok, err = pcall(handler, eventName, ...)
        if not ok then
            reportHandlerError(eventName, subId, err)
        end
    end
end
```

The pcall here surfaces more errors, not fewer. Every handler that throws gets reported. This is the opposite of hiding failures.

### Event Payloads

When emitting an addon event, include data the emitter already has. Don't force every subscriber to re-query the API for context:

```lua
-- BAD: Subscribers all have to call GetPetLoadOutInfo themselves
events:emit("LOADOUT:CHANGED")

-- GOOD: Emitter already has this data — pass it along
events:emit("LOADOUT:CHANGED", {
    slot = slotIndex,
    oldPetID = previousPetID,
    newPetID = currentPetID,
})
```

This saves redundant API calls and makes handlers simpler. The emitter is the authority on what happened — subscribers shouldn't have to reconstruct it.

---

## 5. Command Registration

### Pattern

Commands are registered through `Addon.commands`, typically inside a module's `initialize()` function or its `registerModule` init callback:

```lua
Addon.commands:register({
    command = "mycommand",
    aliases = {"mc", "alias"},          -- optional
    handler = function(args)
        -- args is a table: {argName1 = value1, argName2 = value2}
    end,
    help = "Short description for help listing",
    usage = "mycommand [optionalArg]",
    args = {                             -- optional
        {name = "action", required = false, description = "What to do"}
    },
    detailedHelp = "Extended help text shown by /addon help mycommand",  -- optional
    category = "General"                 -- Groups commands in help output
})
```

### Slash Command

One slash command per addon. All functionality routes through subcommands. The slash command itself is registered in `main.lua` (see Section 1).

---

## 6. Options / Settings System

### Architecture

`core/options.lua` wraps the settings SavedVariable with getter/setter/callback/default infrastructure. UI code never reads or writes the SavedVariable directly — it goes through `Addon.options`.

```lua
-- Read a setting value
local value = Addon.options:Get("settingKey")

-- Write a setting (triggers callbacks and fires categorized events)
Addon.options:Set("settingKey", newValue)

-- Register callback for a specific key (called on every change)
Addon.options:RegisterCallback("settingKey", function(newValue, key)
    -- React to the change
end)

-- Get the default value (for reset-to-defaults functionality)
local default = Addon.options:GetDefault("settingKey")
```

### Settings Change Events

When a setting changes, the options system emits a categorized event:

```lua
events:emit("SETTING:LISTING_CHANGED", {
    name = key,
    oldValue = oldVal,
    newValue = val,
    category = "listing"
})
```

Categories map to events: `listing` → `SETTING:LISTING_CHANGED`, `circuit` → `SETTING:CIRCUIT_CHANGED`, etc.

### Blizzard Integration

The options panel registers with `Settings.RegisterCanvasLayoutCategory` (or the legacy `InterfaceOptions_AddCategory` fallback). Content is built lazily on first show.

### Single Source of Truth for Defaults

Option defaults are defined once, in `options.lua`. The `main.lua` initialization calls into the options system for the default-setting pass rather than maintaining its own separate defaults table. Two lists of defaults will diverge over time — "I set it to default but it's showing a different value" is a frustrating bug to track down when the answer is "which defaults table?"

---

## 7. Data Architecture

### Static + SavedVariable Merging

The `dataStore` module provides a generic CRUD layer where static data (shipped with the addon) merges with SavedVariable data (player-specific runtime changes). SV wins on conflicts.

```lua
-- Register an entity type (typically in the data module's init)
Addon.dataStore:registerEntityType({
    typeName = "npc",
    svName = "prefix_npc",       -- The SavedVariable global name
    staticKey = "npcs"           -- Key in Addon.data for static ship-with data
})

-- Read (returns merged static + SV — SV fields override static)
local entity = Addon.dataStore:getEntity("npc", npcId)

-- Write (stores ONLY the delta to SV, not a full copy of static data)
Addon.dataStore:updateEntity("npc", npcId, {name = "Updated Name"})

-- List all (merged view across static and SV)
local all = Addon.dataStore:listEntities("npc")
```

### Static Data Pattern

Static data files assign to `Addon.data`:

```lua
-- Static data tables live in data/ and attach to Addon.data
local MY_DB = {
    [123] = { name = "Thing", value = 42 },
}

Addon.data = Addon.data or {}
Addon.data.myThings = MY_DB

return MY_DB
```

### SavedVariable Initialization

SavedVariables are initialized with defaults on `ADDON_LOADED` (inside `main.lua`), using nil-coalescing. See the `main.lua` pattern in Section 1 for the full example.

```lua
-- Ensure the SV table exists (WoW sets it to nil on first run)
prefix_settings = prefix_settings or {}

-- Fill in defaults for any missing keys (preserves existing values)
for k, v in pairs(defaults) do
    if prefix_settings[k] == nil then
        prefix_settings[k] = v
    end
end
```

Naming conventions for SavedVariables are in Section 2.

### SavedVariable Versioning

Every SV that has structure (not just flat key-value settings) carries a `version` field. When the schema changes between development sessions, a stale SV from the previous session can cause bugs that look like logic errors but are actually schema mismatches.

During development, the migration is simple — version changed, wipe and re-init:

```lua
local CURRENT_VERSION = 3

-- Schema mismatch: wipe and start fresh
if not prefix_circuit or prefix_circuit.version ~= CURRENT_VERSION then
    prefix_circuit = createDefaultCircuitState()
    prefix_circuit.version = CURRENT_VERSION
end
```

For production addons with real users, replace the wipe with a migration chain that transforms old data to the new schema. But during development, a clean wipe is correct — it surfaces schema assumptions immediately instead of letting stale data cause confusing downstream failures.

### Export System

Data sources self-register for the export/debug window:

```lua
-- Register a data source for the export UI
Addon.exports:register("npcs", function()
    return prefix_npc
end)
```

---

## 8. Frame & UI Patterns

### Frame Creation

All frames are created in pure Lua. XML is not used for addon-defined UI — only Blizzard template inheritance happens via XML strings like `"BackdropTemplate"` or `"UIPanelCloseButton"`.

```lua
-- Anonymous frame (default — no global namespace pollution)
local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
frame:SetPoint("TOPLEFT", parent, "TOPLEFT", PADDING, -PADDING)
frame:SetSize(200, 100)
```

### Named vs Anonymous Frames

Frames default to anonymous (`nil` name). A name puts the frame into the global `_G` table, which means namespace pollution and potential conflicts with other addons. Name a frame **only** when a Blizzard API requires it.

**Must be named:**

`UISpecialFrames` requires a string name for ESC-to-close behavior. This is the most common reason to name a frame:

```lua
local frame = CreateFrame("Frame", ADDON_NAME .. "MainFrame", UIParent)
table.insert(UISpecialFrames, ADDON_NAME .. "MainFrame")
```

The `UIDropDownMenu` system uses `GetName()` internally for menu identity and open-menu tracking. Dropdown menu frames must be named.

`Settings.RegisterCanvasLayoutCategory` (Blizzard options) expects a named frame.

`UIPanelScrollFrameTemplate` creates child widgets using the `$parent` naming convention. The scroll frame only needs a name if you access those children via `_G[name .. "ScrollBar"]`. If you don't need that access, anonymous works fine:

```lua
-- Named: when you need to access the scrollbar widget directly
local sf = CreateFrame("ScrollFrame", ADDON_NAME .. "MyScroll", parent, "UIPanelScrollFrameTemplate")
local scrollBar = _G[sf:GetName() .. "ScrollBar"]
scrollBar:Hide()

-- Anonymous: when you just need scrolling behavior
local sf = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
```

**Always prefix** named frames with `ADDON_NAME` to avoid collisions with other addons or Blizzard UI.

### Anchoring

Use two-point anchoring for frames that should resize with their parent:

```lua
-- Two-point: frame stretches when parent resizes
frame:SetPoint("TOPLEFT", parent, "TOPLEFT", padding, -padding)
frame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -padding, padding)
```

Use single-point + explicit size for fixed-size elements:

```lua
-- Single-point + size: frame stays fixed regardless of parent size
frame:SetPoint("TOPLEFT", parent, "TOPLEFT", padding, -padding)
frame:SetSize(200, 100)
```

### Tooltip System

A custom tooltip module (`Addon.tooltip`) replaces direct `GameTooltip` usage for addon-generated tooltips. It provides a sequential builder API:

```lua
-- Sequential builder pattern — call show(), add content, then done()
tooltip:show(ownerFrame, {anchor = "right"})
tooltip:header("Title")
tooltip:text("Description line")
tooltip:row("Label", "Value")
tooltip:hints({"Click to do thing", "Shift-click for other thing"})
tooltip:done()  -- Finalizes layout and positions the tooltip
```

It mirrors `GameTooltip`'s backdrop and colors (for theme addon compatibility) but provides richer layout control.

### 8pt Grid System

All spacing values come from a defined scale. No arbitrary numbers.

| Name | Value | Use Case |
|------|-------|----------|
| MICRO | 2 | Hairline adjustments (rare) |
| TINY | 4 | Icon-to-text gaps |
| SMALL | 8 | Related items, list padding |
| MEDIUM | 12 | Between text lines, button padding |
| BASE | 16 | Default content padding |
| LARGE | 24 | Section separation, card padding |
| XLARGE | 32 | Major section breaks |

When in doubt, use BASE (16). Edge padding of 24 is accepted as an exception.

### Background Rules

Never use 0.8 alpha — it looks muddy. Use solid backgrounds (alpha 1.0) or very light overlays (0.1–0.3). Prefer Blizzard's dark background textures over `SetBackdropColor` hacks.

### Frame Pooling

For scrolling lists, tooltips, and any UI where the number of visible elements is much smaller than the total data set, use an object pool. In a list of 500 pets where ~15 rows are visible, creating 500 frames is expensive. A pool creates ~18 and recycles them — rows that scroll off the top get released back to the pool, rows that scroll into view acquire from the pool.

The pool utility is generic — it doesn't know or care whether it manages fontstrings, textures, or complex row frames. Each consumer creates its own pool instance with a factory function:

```lua
-- Pool utility: manages a stack of inactive frames and a factory for new ones
-- ~25 lines in core, reused by every list and tooltip in the addon

-- Tooltip creates a pool of fontstrings
local fontPool = pool:new(function(parent)
    return parent:CreateFontString(nil, "OVERLAY", "GameTooltipText")
end)

-- Pet list creates a pool of row frames
local rowPool = pool:new(function(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(28)
    -- configure icon, labels, etc.
    return row
end)

-- Usage: acquire gives you a frame (reuses hidden one, or creates new if empty)
local row = rowPool:acquire()
-- configure row for specific pet data...
row:Show()

-- When done (scrolled off screen, tooltip hidden): release returns it to pool
rowPool:release(row)
-- release() hides the frame and pushes it onto the available stack
```

The factory only runs when `acquire()` is called and the pool is empty. Once a frame exists, it's recycled forever.

---

## 9. Lua Style & Constraints

### Refer to Game Objects by ID, Never by Name

IDs are the canonical way to name a spell, item, recipe, or NPC. A name is a
display string: it is localized, it is not unique (rank tiers share a name —
two Heavy Windwool Bandages, two Forged Documents), and for items it comes
from a cache that is empty until the client has seen the item.

```lua
-- Wrong: depends on locale, the item cache, and hopes the name is unique
button:SetAttribute("spell", C_Spell.GetSpellInfo(id).name)
local recipeID = nameIndex[serviceName]

-- Right: the id is the identity
button:SetAttribute("spell", spellID)
local recipeID = select(2, tip:GetSpell())
```

This applies to secure-button attributes (`spell` takes a spell ID, `item`
takes `"item:"..id`), to lookups of every kind, and to anything stored or
compared. Resolve a name for DISPLAY at the last moment, and never resolve
back from one.

Field-earned twice in one session: a trainer service resolved by name
collided across rank tiers and produced phantom mismatches, and a tool button
armed with a spell name silently did nothing where the spell ID works.

### MoP Lua 5.1 Compatibility

No `goto` statements. No `\u{...}` unicode escapes. No `//` integer division. No bitwise operators (`&`, `|`) — use `bit.band`, `bit.bor`.

### No Unicode in Runtime Strings

WoW's Lua environment handles unicode inconsistently. Stick to ASCII for all string operations, comparisons, and pattern matching. Display strings from the API may contain unicode, but addon-generated strings must not.

### Colon Method Syntax

Public API methods on module tables use colon syntax:

```lua
function myModule:doThing()
    -- self is myModule
end
```

Internal helper functions use plain `local function` syntax:

```lua
local function helperFunction(arg)
    -- no self
end
```

### Comments

#### File Header

Every file opens with a block comment describing what it does, its dependencies, and what it exports:

```lua
--[[
  ui/circuit/circuitTracker.lua
  Circuit Progress Tracker Bar

  Provides a draggable progress tracker that displays current circuit status,
  target NPC, upcoming waypoints, and control buttons.

  Dependencies: utils, constants, circuitPersistence, circuitConstants, waypoint
  Exports: Addon.circuitTracker
]]
```

#### Function Docstrings

Public functions and non-trivial internal functions get a block comment with `@param` and `@return`:

```lua
--[[
  Get NPC location on a specific continent.
  For multi-location NPCs (vendors), finds the location matching the continent.
  Returns first location if no match found.

  @param npc table - NPC record with locations array
  @param continentID number - Target continent ID
  @return table|nil - Location { mapID, continent, x, y } or nil
]]
function location:getNpcLocationOnContinent(npc, continentID)
```

#### Inline Comments

Comments explain **why**, not **what**. If the code is clear, it needs no comment. If something looks wrong but is intentional, explain the reasoning:

```lua
-- GOOD: Explains a non-obvious design decision
-- Note: circuit is NOT declared as a dependency to avoid circular dependency.
-- The battle handler calls circuit functions at runtime (during pet battles),
-- by which point circuit is already initialized. This is safe because these
-- calls only happen via event handlers, never during module initialization.

-- GOOD: Explains an API quirk
-- HereBeDragons expects 0-1 range, our data stores 0-100
return HBD:GetZoneDistance(mapID, x / 100, y / 100, mapID2, x2 / 100, y2 / 100)

-- BAD: Restates what the code does
-- Set the width to 200
frame:SetWidth(200)

-- BAD: Change history
-- Changed from 150 to 200 on 2024-03-15
frame:SetWidth(200)

-- BAD: TODO without a plan
-- TODO: fix this later
```

#### Section Separators

Standard block dividers between logical sections of a file:

```lua
-- ============================================================================
-- SECTION NAME
-- ============================================================================
```

### Error Reporting

Three tiers of user-facing messages:

```lua
utils:debug("Only shown when debug mode is on")
utils:chat("Normal informational message")
utils:notify("Important — plays a sound")
utils:error("Something went wrong — plays error sound, red text")
```

Debug messages include source file and function name automatically via `debugstack`.

### Image References

Use numeric texture IDs, not string paths, when referencing icons programmatically. String paths are acceptable for Blizzard interface textures (`"Interface\\..."`) but icon IDs should be numbers:

```lua
icon = 132599,  -- Correct: numeric ID
icon = "Interface\\Icons\\SomeIcon",  -- Wrong for pet/spell icons
```

---

## 10. Error Handling

### Principle

If a call can legitimately fail at runtime, wrap it and handle the failure. If it shouldn't fail, let it crash — a visible error is better than silent corruption.

### Initialization Failures

Modules check their dependencies at init time and return `false` if anything is missing. The dependency system treats a `false` return as a failed module and reports it. This is a hard stop — the module doesn't partially initialize.

```lua
function myModule:initialize()
    utils = Addon.utils
    events = Addon.events

    -- Hard fail if dependencies are missing — no partial initialization
    if not utils or not events then
        print("|cff33ff99" .. ADDON_NAME .. "|r: |cffff4444myModule: Missing dependencies|r")
        return false
    end

    return true
end
```

### pcall Usage

Use `pcall` around calls that can legitimately fail: external library APIs, user-provided callbacks, `debug.getinfo`, and any function where failure is a normal runtime condition rather than a bug.

```lua
-- CORRECT: debug.getinfo can fail in some contexts
local success, result = pcall(debug.getinfo, 2, "Sn")
if success and result then
    info.filename = result.source:match("([^\\/)]+%.lua)") or "unknown"
end

-- CORRECT: User-provided validation function might error
local success, valid, errorMsg = pcall(config.validate, value)

-- WRONG: Don't wrap normal Blizzard API calls — if they fail, it's a bug
local ok, name = pcall(C_PetJournal.GetPetInfoByPetID, petID)  -- Don't do this
```

### Silent Degradation vs Loud Failure

Silent degradation is appropriate when a feature is optional and its absence doesn't affect core functionality (e.g., breed detection unavailable, TomTom not installed). Use `utils:debug()` to log it for diagnosis.

Loud failure (`utils:error()`) is appropriate when something that should work doesn't — a dependency is missing, data is corrupt, an API returns unexpected results. The user needs to know something is wrong.

Never silently swallow errors that could cause downstream corruption. If you catch an error with `pcall`, decide: can the caller recover, or does the error need to propagate?

### Global Error Handler

A custom error handler via `seterrorhandler()` captures uncaught Lua errors from the addon and logs them to a SV for post-session review. This catches errors that happen when debug mode is off, during combat, or in rapid-fire event handlers where the Blizzard error popup flashes too fast to read.

```lua
-- In core initialization, before modules init
local originalHandler = geterrorhandler()
seterrorhandler(function(err)
    local stack = debugstack(2, 5, 0)
    -- Only capture our own errors (filter by addon folder name in stack)
    if stack and stack:find(ADDON_NAME) then
        prefix_tools = prefix_tools or {}
        prefix_tools.errors = prefix_tools.errors or {}
        table.insert(prefix_tools.errors, {
            error = err,
            stack = stack,
            time = date("%H:%M:%S"),
        })
    end
    -- Always pass through to original handler (Blizzard error popup still works)
    return originalHandler(err)
end)
```

A `/addon errors` command dumps the captured errors. Built once in core, available to every addon.

---

## 11. API Boundary Conventions

### Blizzard API Access

Modules call Blizzard APIs directly — there's no global wrapper layer. However, specific patterns apply:

**Zone names**: Use `C_Map.GetMapInfo(mapID).name`, not `GetZoneName()`.
**Quest data from Questie**: Access via `startedBy`/`finishedBy` fields (not `questStarts`/`questEnds`). NPC IDs are at index `[1]` in the nested structure.
**Continent IDs**: Empirically verified for MoP Classic — Kalimdor=12, Eastern Kingdoms=13, Northrend=113, Pandaria=424, Outland=1467.
**NPC IDs**: Always integers, never strings. Enforce at storage boundaries.

### External Library Integration

Libraries live in `libs/` and are loaded via the `.toc` before addon code. Access them through their published API (e.g., `HereBeDragons` for world coordinates, `TomTom` for waypoints). Never modify library internals.

---

## 12. Development Practices

### Luacheck

Every file must pass `luacheck` with zero warnings before delivery. New WoW globals go in the project `.luacheckrc` — never use inline `--luacheck: ignore` suppressions.

### Debugging

The settings SavedVariable includes a `debugMode` flag that toggles debug output globally. File-specific debug filtering is available via `utils:setFileSpecificDebug("filename.lua")`.

Debug instrumentation for diagnosis should blanket all decision points in one comprehensive pass — never piecemeal "add one print, test, add another."

### Data Integrity

AI-sourced NPC IDs, quest IDs, and similar game data are unreliable. Always verify against Wowhead or the game client before trusting them.

Override files (like `sourceOverrides.lua`) carry **minimum data only** — nothing that can be looked up at runtime from another source (Questie, Blizzard API, etc.).

---

## 13. Shared Library Reference

These files live in the monorepo's `shared/` directory and get synced into each addon's `core/shared/` and `ui/shared/` directories via the presence-based sync script (`.lua` files only). The script also generates `files.xml` manifests from templates in the shared repo, filtered to include only files present in the addon. Any addon can drop them in. Not every addon needs every file — copy in only the ones you use, and sync keeps them current.

Three shared modules — **options**, **tabs**, **errorHandler** — hold state in memory but need to persist to SavedVariables. Each addon provides a small persistence adapter that bridges them to its SVs. See "Persistence Adapter Pattern" at the end of this section.

**Shared module audit:** Before declaring any file shared, grep it for the addon's name, abbreviation, SV prefixes, and any other addon-specific strings (e.g., for an addon called "Mobster" with SV prefix `mob_`, grep for `mob_`, `Mob`, `MOB`, `Mobster`, `MobsterMainFrame`). Every hit must be replaced with `ADDON_NAME`, `Addon.displayName`, or a setter API. This applies to code, comments, and string literals. This is a hard rule — never skip this audit.

### shared/core/

- **events.lua** — Unified pub/sub for both WoW game events (ALL_CAPS) and addon events (NAMESPACE:NAME). `subscribe/unsubscribe/emit` API, handler isolation via pcall dispatch.

- **dependencies.lua** — Module registry and dependency-ordered initialization. Modules self-register with their deps; the system topologically sorts and calls init functions in order.

- **svRegistry.lua** — Centralized SavedVariable declaration with version numbers and migration chains. Version store name is passed to `initializeAll()`, so no addon-specific hardcoding. Replaces scattered `sv = sv or {}` patterns.

- **errorHandler.lua** — Captures addon-originated errors via `seterrorhandler` into an in-memory ring buffer (max 100). Installed at file-load time to catch init errors. Adapter calls `getCapturedErrors()` to drain the buffer into the SV, then subscribes via `onError()` to persist subsequent errors.

- **stateMachine.lua** — Factory for validated, event-driven state machines. Define states, transitions, guards, and entry/exit callbacks. Transitions fire events automatically.

- **utils.lua** — Debug/notify/error logging, string truncation, table filter, debounce, coalesce, isTruthy. Chat prefix uses `Addon.displayName` (falls back to `ADDON_NAME` if not set).

- **pool.lua** — Generic object pool. `acquire(factory)` returns a reusable frame; `release(obj)` returns it to the pool. Used for lists, tooltips, or any UI where visible elements ≪ total data.

- **location.lua** — Player location and continent detection via `C_Map`. `getCurrentPlayerLocation` returns mapID/zone/subzone/x/y/continent. `coordDistance` for simple 2D distance. Contains fallback continent names for MoP — adjust per-expansion if porting.

- **options.lua** — In-memory settings store with get/set/callbacks and categorized change events (`SETTING:<CATEGORY>_CHANGED`). Addon registers defaults and category mapping via `setDefaults()` / `setCategories()`. Adapter hydrates from SV via `hydrate()` and subscribes to change events to persist.

- **commands.lua** — Slash command registration, parsing, and dispatch with aliases, args, and categorized help. Addon sets the slash prefix via `commands:setSlash("name")`. Built-in commands (help, deps) are generic; addon-specific commands register in their own file.

- **tabs.lua** — Tab system for multi-tab UI windows. Register tabs with id/name/icon/order/alwaysEnabled. Lazy content creation. Adapter hydrates initial enabled-states via `setInitialStates()` and subscribes to `TABS:STATE_CHANGED` to persist.

- **dataStore.lua** — Generic CRUD for entity types with static+SV merging. Entities have a static baseline (from data files) overlaid with player-specific deltas in SavedVariables. Modules register entity types by calling `registerEntityType({typeName, svName, staticKey})`.

- **exports/exports.lua** — Data source registry for export windows. Modules call `exports:register("name", function)` to expose their data for copy-paste export.

### shared/ui/

The sync script only syncs `.lua` files. Each `files.xml` manifest is per-addon — the addon writes its own to include only the shared UI files it uses. The `files.xml` files in the shared repo are reference copies and are never synced.

#### shared/ui/ (root)

- **dragDropMixin.lua** — Reusable drag-and-drop handlers for frame-to-frame drag operations.

- **dragFeedback.lua** — Visual feedback (borders, highlights) applied to source/target frames during drag operations.

- **escapeHandler.lua** — Full-screen ESC capture and click detection during drag operations. Addon calls `escapeHandler:setMainFrame("FrameName")` to configure which UISpecialFrame to temporarily remove during drags.

#### shared/ui/widgets/

- **menuRenderer.lua** — Core rendering engine for popup menus. Frame pooling, items with icons/checkmarks/submenus, separators, auto-close on outside click or timeout. Used by both dropdown and contextMenu.

- **dropdown.lua** — Modern dropdown widget built on menuRenderer. Standard text-only rows.

- **dropdownLegacy.lua** — Custom dropdown with rich row rendering (icons, multi-line text, custom `renderRow` callback). Use where dropdown's single-line rows aren't enough.

- **contextMenu.lua** — Thin wrapper around menuRenderer for cursor-anchored context menus. `contextMenu:show(menuDef, context)` pops up at the cursor.

- **tooltips.lua** — Custom tooltip builder with fluent API: `header(text)`, `text(s)`, `row(l, r)`, `space(px)`, `done()`. Avoids GameTooltip's layout quirks.

- **infoTip.lua** — (i) icon component. Hover shows brief tooltip; click opens expanded help panel with sections and settings hints. User closes the panel explicitly.

- **textBox.lua** — Text input with placeholder, max letters, change callbacks. Foundation for other input widgets.

- **searchBox.lua** — Text input with search icon and clear button.

- **filterTextbox.lua** — textBox variant with clear button and optional info tip, for filtering list views.

- **filterTabStrip.lua** — Horizontal tab strip for filter categories. Toggleable tabs with active/inactive states.

- **actionButton.lua** — Wraps `SecureActionButtonTemplate` for macro execution from UI (needed for protected API calls).

- **gradientButton.lua** — Styled button with gradient fill.

- **header.lua** — Section header component with title and optional controls.

- **panel.lua** — Container frame for grouping related UI content.

- **sortControl.lua** — Sort direction toggle (ascending/descending arrow).

#### shared/ui/style/

Centralized style system. Addons use style tokens instead of hardcoding colors, so the entire UI adapts to different environments.

- **style.lua** — Style registry and token API. Provides named color/spacing/font tokens that all shared widgets reference instead of hardcoded values.

- **strategy/stock.lua** — Default WoW UI style strategy. Colors and tokens matching the stock Blizzard interface.

- **strategy/elvui.lua** — ElvUI style strategy. Adapted colors and tokens for players running ElvUI.

### Addon Identity Configuration

Several shared modules need addon-specific identity to function. These are all configured at file-load time in `main.lua`, before `ADDON_LOADED` fires. Each addon substitutes its own values:

```lua
-- main.lua (file-load time, runs when the .toc loads this file)
-- Example values shown — replace with your addon's name, slash command, and frame name
Addon.displayName = "My Addon"                             -- utils.lua chat prefix
Addon.commands:setSlash("myaddon")                         -- commands.lua help text
Addon.escapeHandler:setMainFrame("MyAddonMainFrame")       -- escapeHandler.lua UISpecialFrames
Addon.persistence:configureOptions()                       -- options defaults and categories
```

`Addon.displayName` is optional — utils falls back to `ADDON_NAME` (the folder name) if it's not set. The others are required for their respective features to work correctly.

### Persistence Adapter Pattern

Shared modules hold state in memory. Each addon provides a `persistence.lua` adapter that bridges them to its SavedVariables. The adapter is ~100 lines — most of it is the defaults table for `options`.

The lifecycle:

1. **File-load time** — addon's `main.lua` calls `persistence:configureOptions()` to register defaults and categories with `options`. Also calls `commands:setSlash("myaddon")` to set the help-text prefix.

2. **ADDON_LOADED** — addon's `main.lua` calls `svRegistry:initializeAll(toolsSVName)` to create/migrate SVs, then `persistence:attach()` to hydrate shared modules and wire up persistence, then `dependency:initializeAllModules()` to initialize every registered module.

The four shared modules each expose a small API the adapter uses:

**options** — The adapter calls `setDefaults(tbl)` and `setCategories(tbl)` at file-load time, then `hydrate(sourceTable)` during attach to load initial values from the SV without firing callbacks. After attach, the adapter subscribes to `SETTING:*_CHANGED` events and mirrors the new value back to the SV.

```lua
Addon.options:setDefaults({ debugMode = false, fontSize = 14, ... })
Addon.options:setCategories({
    general = { "debugMode" },
    display = { "fontSize" },
})
-- Later, inside attach():
Addon.options:hydrate(myaddon_settings)
Addon.events:subscribe("SETTING:GENERAL_CHANGED", function(_, payload)
    myaddon_settings[payload.name] = payload.newValue
end)
```

**tabs** — The adapter calls `setInitialStates(map)` during attach to restore which tabs were enabled, then subscribes to `TABS:STATE_CHANGED` to mirror changes back.

```lua
myaddon_settings.tabs = myaddon_settings.tabs or {}
Addon.tabs:setInitialStates(myaddon_settings.tabs)
Addon.events:subscribe("TABS:STATE_CHANGED", function(_, payload)
    myaddon_settings.tabs[payload.id] = payload.enabled
end)
```

**errorHandler** — Errors captured during file-load sit in an in-memory buffer (installed by errorHandler at file-load time). During attach, the adapter drains the buffer into the SV and subscribes via `onError` to persist future errors.

```lua
myaddon_tools.errors = myaddon_tools.errors or {}
for _, entry in ipairs(Addon.errorHandler:getCapturedErrors()) do
    if #myaddon_tools.errors < 100 then
        table.insert(myaddon_tools.errors, entry)
    end
end
Addon.errorHandler:onError(function(entry)
    if #myaddon_tools.errors < 100 then
        table.insert(myaddon_tools.errors, entry)
    end
end)
```

**commands** — Not an adapter concern; the addon just calls `commands:setSlash("myaddon")` at main.lua file-load time. Addon-specific built-in commands (version, debug toggle, etc.) register from a per-addon file like `logic/builtinCommands.lua`.

### Drag-and-Drop Status

| File | Drag-and-drop? |
|------|----------------|
| events, dependencies, svRegistry, stateMachine, pool, location, dataStore, exports | Yes, no configuration needed |
| utils | Yes; optionally set `Addon.displayName` for chat prefix |
| commands | Yes; call `setSlash("name")` at file-load |
| escapeHandler | Yes; call `setMainFrame("FrameName")` at file-load |
| options, tabs, errorHandler | Yes, plus ~100-line `persistence.lua` adapter per addon |
| All other shared/ui/ (widgets/, style/, dragDropMixin, dragFeedback) | Yes, no configuration needed |
