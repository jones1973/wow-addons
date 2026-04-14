--[[
  data/leveling/levelingDefaults.lua
  Leveling Queue Defaults and Layout Constants
  
  Defines:
    - Layout constants for leveling UI components
    - Sort field options for leveling queues
    - Default queue templates
    - Schema validation helpers
  
  Dependencies: None (pure data)
  Exports: Addon.levelingDefaults
]]

local ADDON_NAME, Addon = ...

local levelingDefaults = {}

-- ============================================================================
-- LAYOUT CONSTANTS
-- Leveling-specific layout values used across leveling UI components
-- ============================================================================

levelingDefaults.LAYOUT = {
    -- Queue card dimensions
    CARD_HEIGHT = 60,
    CARD_GAP = 4,
    CARD_PADDING = 10,
    
    -- Edit form height: 10 (top pad) + 130 (to buttons) + 22 (buttons) + 10 (bottom pad) = 172
    EDIT_HEIGHT = 172,
    
    -- Edit form dimensions (calculated, not hardcoded)
    INPUT_HEIGHT = 30,
    INPUT_GAP = 10,
    LABEL_WIDTH = 70,
    BUTTON_HEIGHT = 22,
    BUTTON_WIDTH = 50,
    DROPDOWN_WIDTH = 150,
    ARROW_SIZE = 16,
    
    -- Elements
    PRIORITY_SIZE = 24,
    TOGGLE_SIZE = 20,
    COUNT_WIDTH = 45,
    
    -- Drag constants
    DRAG_SHIFT_X = -30,  -- Left shift when dragging
    AUTOSCROLL_EDGE_THRESHOLD = 30,  -- Pixels from edge to trigger scroll
    AUTOSCROLL_CARDS_PER_STEP = 2,  -- Scroll speed multiplier
    
    -- Colors
    BG_COLOR = {0.12, 0.12, 0.12, 0.85},
    CARD_BG = {0.15, 0.15, 0.18, 1},
    CARD_BG_DISABLED = {0.12, 0.12, 0.14, 1},
    CARD_BG_EDITING = {0.20, 0.18, 0.25, 1},  -- Lavender tint
    CARD_DIM_ALPHA = 0.7,  -- Alpha for non-editing cards
    HOVER_ALPHA = 0.08,
    PRIORITY_ACTIVE = {0.3, 0.5, 0.3, 1},
    PRIORITY_INACTIVE = {0.25, 0.25, 0.28, 1},
}

-- ============================================================================
-- SORT OPTIONS
-- ============================================================================

-- Available sort fields for leveling queues
-- Direction is stored separately on queue (sortDir)
levelingDefaults.SORT_FIELDS = {
    { id = "level",       text = "Level" },
    { id = "familyCount", text = "Family Count" },
    { id = "name",        text = "Name" },
    { id = "random",      text = "Random" },
}

-- Lookup by ID
levelingDefaults.SORT_BY_ID = {}
for _, sort in ipairs(levelingDefaults.SORT_FIELDS) do
    levelingDefaults.SORT_BY_ID[sort.id] = sort
end

-- Defaults
levelingDefaults.DEFAULT_SORT_FIELD = "level"
levelingDefaults.DEFAULT_SORT_DIR = "asc"

-- ============================================================================
-- DEFAULT QUEUES
-- ============================================================================

--[[
  Default queue definitions.
  Users start with these queues; can modify/delete/add.
]]
levelingDefaults.DEFAULT_QUEUES = {
    {
        id = "rare-uniques",
        name = "Rare Uniques",
        priority = 1,
        enabled = true,
        filter = "rare unique",
        sortField = "level",
        sortDir = "asc",
    },
    {
        id = "other-uniques",
        name = "Other Uniques",
        priority = 2,
        enabled = false,
        filter = "!rare unique",
        sortField = "level",
        sortDir = "asc",
    },
    {
        id = "rare-underrepresented",
        name = "Rare Underrepresented",
        priority = 3,
        enabled = true,
        filter = "rare family-bottom:3",
        sortField = "level",
        sortDir = "asc",
    },
    {
        id = "remaining-rares",
        name = "Remaining Rares",
        priority = 4,
        enabled = true,
        filter = "rare",
        sortField = "level",
        sortDir = "asc",
    },
    {
        id = "non-rare-low-underrepresented",
        name = "Non-Rare Low Level Underrepresented",
        priority = 5,
        enabled = true,
        filter = "!rare level:<10 family-bottom:3",
        sortField = "level",
        sortDir = "asc",
    },
    {
        id = "remaining-non-rare-low",
        name = "Remaining Non-Rare Low Levels",
        priority = 6,
        enabled = true,
        filter = "!rare level:<10",
        sortField = "level",
        sortDir = "asc",
    },
    {
        id = "everything-else",
        name = "Everything Else",
        priority = 7,
        enabled = true,
        filter = "",
        sortField = "level",
        sortDir = "asc",
    },
}

-- ============================================================================
-- DEFAULT SETTINGS
-- ============================================================================

levelingDefaults.DEFAULT_SETTINGS = {
    -- Future: notification preferences, display options, etc.
}

-- ============================================================================
-- QUEUE FACTORY & VALIDATION
-- ============================================================================

-- ID counter for new queues
local idCounter = 0

--[[
  Generate unique queue ID.
  @return string
]]
function levelingDefaults:generateId()
    idCounter = idCounter + 1
    return "queue-" .. tostring(os.time()) .. "-" .. tostring(idCounter)
end

--[[
  Create a new queue with defaults.
  @param overrides table - Optional field overrides
  @return table - New queue definition
]]
function levelingDefaults:createQueue(overrides)
    overrides = overrides or {}
    return {
        id = overrides.id or self:generateId(),
        name = overrides.name or "New Queue",
        priority = overrides.priority or 99,
        enabled = overrides.enabled ~= false,
        filter = overrides.filter or "",
        sortField = overrides.sortField or self.DEFAULT_SORT_FIELD,
        sortDir = overrides.sortDir or self.DEFAULT_SORT_DIR,
    }
end

--[[
  Validate queue structure.
  @param queue table
  @return boolean, string - Valid, error message
]]
function levelingDefaults:validateQueue(queue)
    if type(queue) ~= "table" then
        return false, "Queue must be a table"
    end
    if not queue.id or queue.id == "" then
        return false, "Queue must have an id"
    end
    if not queue.name or queue.name == "" then
        return false, "Queue must have a name"
    end
    if type(queue.priority) ~= "number" then
        return false, "Queue priority must be a number"
    end
    if type(queue.enabled) ~= "boolean" then
        return false, "Queue enabled must be a boolean"
    end
    if type(queue.filter) ~= "string" then
        return false, "Queue filter must be a string"
    end
    if not queue.sortField or not self.SORT_BY_ID[queue.sortField] then
        return false, "Queue sortField must be valid"
    end
    if queue.sortDir ~= "asc" and queue.sortDir ~= "desc" then
        return false, "Queue sortDir must be 'asc' or 'desc'"
    end
    return true, nil
end

--[[
  Deep copy a queue for duplication.
  @param queue table
  @return table
]]
function levelingDefaults:copyQueue(queue)
    return {
        id = self:generateId(),
        name = queue.name .. " (Copy)",
        priority = queue.priority + 1,
        enabled = queue.enabled,
        filter = queue.filter,
        sortField = queue.sortField,
        sortDir = queue.sortDir,
    }
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("levelingDefaults", {}, function()
        return true
    end)
end

Addon.levelingDefaults = levelingDefaults
return levelingDefaults