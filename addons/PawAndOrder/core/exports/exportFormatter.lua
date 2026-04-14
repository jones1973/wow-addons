-- core/exports/exportFormatter.lua -- Provides serialization functions to export data as Lua tables, JSON, or CSV formats without external dependencies
local _, Addon = ...

-- Syntax highlighting color scheme (WoW color codes)
local COLORS = {
    STRING = "|cFF98C379", -- Green
    NUMBER = "|cFFD19A66", -- Orange
    BOOLEAN = "|cFF56B6C2", -- Cyan
    NIL = "|cFF7F848E", -- Gray
    KEY = "|cFFE06C75", -- Red
    BRACKET = "|cFFABB2BF", -- Light gray
    BRACE = "|cFFC678DD", -- Purple
    COMMA = "|cFFABB2BF", -- Light gray
    EQUALS = "|cFF61AFEF", -- Blue
    CONSTANT = "|cFFE5C07B", -- Yellow-gold (for CONST.CONST references)
    RESET = "|r"
}

local function sortedKeys(t)
    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys)
    return keys
end

-- Strip color codes from text for copying
local function stripColors(text)
    return text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|n", "\n")
end

-- Escape WoW color codes so they display as literal text instead of formatting
local function escapeWoWColors(str)
    -- Replace | with || to escape WoW color codes
    return str:gsub("|", "||")
end

-- Safe string quoting function that avoids format string issues AND escapes WoW color codes
local function safeStringQuote(str, escapeColors)
    -- First escape WoW color codes if requested (for display version)
    if escapeColors then
        str = escapeWoWColors(str)
    end
    
    -- Then escape string quotes and control characters
    local escaped = str:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
    return "\"" .. escaped .. "\""
end

-- Magic detection: check if string is a valid Lua identifier (for simple keys)
local function isValidIdentifier(str)
    if type(str) ~= "string" then return false end
    return str:match("^[a-zA-Z_][a-zA-Z0-9_]*$") ~= nil
end

-- Magic detection: check if string looks like a constant reference (CONST.CONST)
-- Matches patterns like NPC_TYPE.TRAINER, FACTION.ALLIANCE, etc.
-- Also matches compound expressions like NPC_TYPE.STABLE_MASTER + NPC_TYPE.VENDOR
local function isConstantReference(str)
    if type(str) ~= "string" then return false end
    -- Single constant: NPC_TYPE.VENDOR
    if str:match("^[A-Z_][A-Z0-9_]*%.[A-Z_][A-Z0-9_]*$") then
        return true
    end
    -- Compound expression: NPC_TYPE.X + NPC_TYPE.Y (with optional spaces)
    -- Must be all CONST.CONST terms separated by +
    local terms = {}
    for term in str:gmatch("[^+]+") do
        term = term:match("^%s*(.-)%s*$")  -- trim whitespace
        if not term:match("^[A-Z_][A-Z0-9_]*%.[A-Z_][A-Z0-9_]*$") then
            return false
        end
        table.insert(terms, term)
    end
    return #terms >= 2
end

-- Helper to quote and colorize individual Lua values
-- Magic detection: constant references (CONST.CONST) are output unquoted
local function luaValue(v, colored)
    local vt = type(v)
    if colored == false then
        -- Plain version for copying
        if vt == "string" then
            -- Magic: detect constant references and output unquoted
            if isConstantReference(v) then
                return v
            end
            return safeStringQuote(v, false)
        elseif vt == "number" or vt == "boolean" then
            return tostring(v)
        elseif vt == "nil" then
            return "nil"
        else
            return safeStringQuote(tostring(v), false)
        end
    else
        -- Colored version for display
        if vt == "string" then
            -- Magic: detect constant references and output unquoted with special color
            if isConstantReference(v) then
                return COLORS.CONSTANT .. v .. COLORS.RESET
            end
            return COLORS.STRING .. safeStringQuote(v, true) .. COLORS.RESET
        elseif vt == "number" then
            return COLORS.NUMBER .. tostring(v) .. COLORS.RESET
        elseif vt == "boolean" then
            return COLORS.BOOLEAN .. tostring(v) .. COLORS.RESET
        elseif vt == "nil" then
            return COLORS.NIL .. "nil" .. COLORS.RESET
        else
            return COLORS.STRING .. safeStringQuote(tostring(v), true) .. COLORS.RESET
        end
    end
end

-- Check if table is a sequential array (keys are 1, 2, 3, ...)
local function isSequentialArray(t)
    if type(t) ~= "table" then return false end
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    if count == 0 then return true end  -- Empty table is an array
    for i = 1, count do
        if t[i] == nil then return false end
    end
    return true
end

-- Compact threshold: tables serialized under this length go on one line
local COMPACT_THRESHOLD = 80

-- Serialize a Lua table into a Lua table literal
-- Features:
--   - Array detection: sequential keys use { a, b, c } instead of { [1] = a, ... }
--   - Simple keys: valid identifiers use name = instead of ["name"] =
--   - Constant detection: CONST.CONST patterns output unquoted
--   - Compact mode: simple tables under COMPACT_THRESHOLD chars go on one line
local function serializeToLuaTable(t, indent, colored)
    indent = indent or ""
    colored = (colored ~= false) -- default to true
    
    local openBrace = colored and (COLORS.BRACE .. "{" .. COLORS.RESET) or "{"
    local closeBrace = colored and (COLORS.BRACE .. "}" .. COLORS.RESET) or "}"
    local equals = colored and (" " .. COLORS.EQUALS .. "=" .. COLORS.RESET .. " ") or " = "
    local comma = colored and (COLORS.COMMA .. "," .. COLORS.RESET) or ","
    local commaSpace = comma .. " "
    
    local isArray = isSequentialArray(t)
    local pad = indent .. "    "
    
    -- Build the entries
    local entries = {}
    
    if isArray then
        -- Array format: just values, no keys
        for i = 1, #t do
            local v = t[i]
            local valRep
            if type(v) == "table" then
                valRep = serializeToLuaTable(v, pad, colored)
            else
                valRep = luaValue(v, colored)
            end
            table.insert(entries, valRep)
        end
    else
        -- Map format: key = value pairs
        for _, k in ipairs(sortedKeys(t)) do
            local v = t[k]
            local keyRep
            if type(k) == "string" then
                -- Magic: use simple key syntax for valid identifiers
                if isValidIdentifier(k) then
                    if colored then
                        keyRep = COLORS.KEY .. k .. COLORS.RESET
                    else
                        keyRep = k
                    end
                else
                    -- Fall back to bracketed syntax for non-identifier strings
                    if colored then
                        keyRep = COLORS.BRACKET .. "[" .. COLORS.RESET .. COLORS.STRING .. safeStringQuote(k, true) .. COLORS.RESET .. COLORS.BRACKET .. "]" .. COLORS.RESET
                    else
                        keyRep = "[" .. safeStringQuote(k, false) .. "]"
                    end
                end
            else
                -- Numeric keys use brackets
                if colored then
                    keyRep = COLORS.BRACKET .. "[" .. COLORS.RESET .. COLORS.NUMBER .. k .. COLORS.RESET .. COLORS.BRACKET .. "]" .. COLORS.RESET
                else
                    keyRep = "[" .. k .. "]"
                end
            end
            
            local valRep
            if type(v) == "table" then
                valRep = serializeToLuaTable(v, pad, colored)
            else
                valRep = luaValue(v, colored)
            end
            
            table.insert(entries, keyRep .. equals .. valRep)
        end
    end
    
    -- Check if we can use compact (single-line) format
    -- Compact if: no nested tables AND combined length under threshold
    local hasNestedTable = false
    for _, v in pairs(t) do
        if type(v) == "table" then
            hasNestedTable = true
            break
        end
    end
    
    if not hasNestedTable and #entries > 0 then
        local compactLine = openBrace .. " " .. table.concat(entries, commaSpace) .. " " .. closeBrace
        -- Strip color codes to measure actual length
        local plainLength = #(compactLine:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
        if plainLength <= COMPACT_THRESHOLD then
            return compactLine
        end
    end
    
    -- Multi-line format
    if #entries == 0 then
        return openBrace .. closeBrace
    end
    
    local lines = {openBrace}
    for _, entry in ipairs(entries) do
        table.insert(lines, pad .. entry .. comma)
    end
    table.insert(lines, indent .. closeBrace)
    return table.concat(lines, "\n")
end

-- Simple JSON serializer with optional syntax highlighting
local function serializeToJSON(t, colored)
    colored = (colored ~= false) -- default to true
    
    local function jsonValue(v)
        local vt = type(v)
        if vt == "string" then
            -- For JSON, don't escape WoW colors since JSON isn't displayed in WoW UI
            local escaped = v:gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
            local str = "\"" .. escaped .. "\""
            return colored and (COLORS.STRING .. str .. COLORS.RESET) or str
        elseif vt == "number" then
            local str = tostring(v)
            return colored and (COLORS.NUMBER .. str .. COLORS.RESET) or str
        elseif vt == "boolean" then
            local str = tostring(v)
            return colored and (COLORS.BOOLEAN .. str .. COLORS.RESET) or str
        elseif vt == "nil" then
            return colored and (COLORS.NIL .. "null" .. COLORS.RESET) or "null"
        elseif vt == "table" then
            local isArray = true
            local maxIdx = 0
            for k,_ in pairs(v) do
                if type(k) ~= "number" then
                    isArray = false
                end
                maxIdx = math.max(maxIdx, k)
            end
            
            local items = {}
            local openBracket = colored and (COLORS.BRACKET .. "[" .. COLORS.RESET) or "["
            local closeBracket = colored and (COLORS.BRACKET .. "]" .. COLORS.RESET) or "]"
            local openBrace = colored and (COLORS.BRACE .. "{" .. COLORS.RESET) or "{"
            local closeBrace = colored and (COLORS.BRACE .. "}" .. COLORS.RESET) or "}"
            local comma = colored and (COLORS.COMMA .. "," .. COLORS.RESET) or ","
            local colon = colored and (COLORS.EQUALS .. ":" .. COLORS.RESET) or ":"
            
            if isArray then
                for i = 1, maxIdx do
                    table.insert(items, jsonValue(v[i]))
                end
                return openBracket .. table.concat(items, comma) .. closeBracket
            else
                for k, val in pairs(v) do
                    -- For JSON keys, don't escape WoW colors
                    local keyEscaped = tostring(k):gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
                    local keyStr = colored and (COLORS.KEY .. "\"" .. keyEscaped .. "\"" .. COLORS.RESET) or ("\"" .. keyEscaped .. "\"")
                    table.insert(items, keyStr .. colon .. jsonValue(val))
                end
                return openBrace .. table.concat(items, comma) .. closeBrace
            end
        else
            -- For other types converted to JSON strings, don't escape WoW colors
            local escaped = tostring(v):gsub("\\", "\\\\"):gsub("\"", "\\\""):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
            local str = "\"" .. escaped .. "\""
            return colored and (COLORS.STRING .. str .. COLORS.RESET) or str
        end
    end
    
    return jsonValue(t)
end

-- CSV serializer: two columns for key and value (no colors since CSV is plain text)
local function serializeToCSV(t)
    local lines = {"Key,Value"}
    for _, k in ipairs(sortedKeys(t)) do
        local v = t[k]
        local cell = type(v) == "table" and "\"[table]\"" or ("\"" .. tostring(v):gsub("\"", "\"\"") .. "\"")  -- Proper CSV escaping
        table.insert(lines, "\"" .. tostring(k):gsub("\"", "\"\"") .. "\"," .. cell)  -- Proper CSV escaping for keys too
    end
    return table.concat(lines, "\n")
end

-- Export the functions
Addon.exportFormatter = {
    toLuaTable = function(data, colored) return serializeToLuaTable(data, "", colored) end,
    toJSON = function(data, colored) return serializeToJSON(data, colored) end,
    toCSV = serializeToCSV,
    stripColors = stripColors
}