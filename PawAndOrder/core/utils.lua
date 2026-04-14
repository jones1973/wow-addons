-- Core/utils.lua - SIMPLIFIED COLON NOTATION (NO INTERNAL PAO_ FUNCTIONS)

local ADDON_NAME, Addon = ...

-- Create the utils module table
Addon.utils = Addon.utils or {}
local utils = Addon.utils

----------------------------------------------------------
-- Global Debug and Chat System
----------------------------------------------------------

-- Debug system state
local debugSettings = {
    globalEnabled = false,
    fileSpecific = nil -- When set, only this file gets debug output
}

-- Initialize global debug from saved settings
debugSettings.globalEnabled = (pao_settings and pao_settings.debugMode) or false

----------------------------------------------------------
-- SIMPLIFIED PUBLIC API - COLON METHODS ONLY
----------------------------------------------------------

function utils:chat(message, useShortName)
    local prefix = useShortName and "|cff33ff99PAO|r" or "|cff33ff99Paw and Order|r"
    print(prefix .. " " .. message)
end

function utils:debug(message)
    if not debugSettings.globalEnabled and not debugSettings.fileSpecific then
        return
    end
    
    local info = {filename = "unknown", funcname = ""}
    
    -- Try multiple methods for stack trace (MoP compatibility)
    if debugstack then
        local stack = debugstack(2, 1, 0)
        if stack then
            local filename = stack:match("([^\\/)]+%.lua)") or "unknown"
            local funcname = stack:match("function `([^']*)'") or ""
            info = {filename = filename, funcname = funcname}
        end
    elseif debug and debug.getinfo then
        -- pcall: debug.getinfo may legitimately fail in some contexts
        local success, result = pcall(debug.getinfo, 2, "Sn")
        if success and result then
            info = {
                filename = (result.source and result.source:match("([^\\/)]+%.lua)")) or "unknown",
                funcname = result.name or ""
            }
        end
    end
    
    if debugSettings.fileSpecific then
        if info.filename ~= debugSettings.fileSpecific then
            return
        end
    end
    
    local separator = (info.funcname ~= "") and " - " or " "
    local debugMsg = info.funcname .. separator .. message
    self:chat("DEBUG: " .. debugMsg, true)
end

function utils:notify(message)
    PlaySound(814) -- just a little sound nudge when we want the user's attention
    self:chat(message)
end

function utils:error(message)
    PlaySound(882) -- just a little something's wrong sound
    self:chat("|cffff4444Error|r " .. message)
end

-- Debug system management functions
function utils:setDebugEnabled(enabled)
    debugSettings.globalEnabled = (enabled and true) or false
    debugSettings.fileSpecific = nil
end

function utils:setFileSpecificDebug(filename)
    if filename and filename ~= "" then
        debugSettings.fileSpecific = filename
        debugSettings.globalEnabled = false
        self:notify("Debug enabled for " .. filename .. ".lua only (temporary)")
    else
        debugSettings.fileSpecific = nil
    end
end

function utils:isDebugEnabled()
    return debugSettings.globalEnabled or (debugSettings.fileSpecific ~= nil)
end

function utils:getDebugSettings()
    return {
        global = debugSettings.globalEnabled,
        fileSpecific = debugSettings.fileSpecific
    }
end

----------------------------------------------------------
-- Utility Format timestamps
----------------------------------------------------------

function utils:formatTimestamp(ts)
    if type(ts) == "number" and ts > 0 then
        return date("%Y-%m-%d %H:%M", ts)
    end
    return "never"
end

-- Expose globally for legacy calls with safety checks
if not _G.FormatTimestamp then
    _G.FormatTimestamp = function(ts) return utils:formatTimestamp(ts) end
end

----------------------------------------------------------
-- Table Helpers
----------------------------------------------------------

function utils:deepCopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[self:deepCopy(orig_key, copies)] = self:deepCopy(orig_value, copies)
            end
            setmetatable(copy, self:deepCopy(getmetatable(orig), copies))
        end
    else
        copy = orig
    end
    
    return copy
end

function utils:shallowCopy(orig)
    local copy = {}
    for k, v in pairs(orig) do
        copy[k] = v
    end
    return copy
end

function utils:sorted(tbl, sortFunc)
    local keys = {}
    for k in pairs(tbl) do
        keys[#keys + 1] = k
    end
    table.sort(keys, sortFunc)
    
    local i = 0
    return function()
        i = i + 1
        local k = keys[i]
        if k then
            return k, tbl[k]
        end
    end
end

----------------------------------------------------------
-- String/Number Helpers
----------------------------------------------------------

--[[
  Strip embedded texture escape sequences from source text.
  Blizzard embeds icon paths like |TINTERFACE\\ICONS\\Achievement_...:0|t
  in sourceText which pollute substring searches.
  
  @param sourceText string - Raw source text from C_PetJournal
  @return string - Cleaned text with |T...|t sequences removed
]]
function utils:cleanSourceText(sourceText)
    if not sourceText then return "" end
    return sourceText:gsub("|[Tt][^|]*|[Tt]", "")
end

function utils:insensitiveFind(str, substr)
    str, substr = str:lower(), substr:lower()
    return str:find(substr, 1, true) ~= nil
end

function utils:formatNumber(n)
    if type(n) ~= "number" then
        return tostring(n) or ""
    end
    
    local left, num, right = tostring(n):match("(%-?%d+)%.?(%d*)(.*)")
    num = num:reverse()
    num = num:gsub("(%d%d%d)", "%1,"):reverse()
    
    if num:sub(1, 1) == "," then
        num = num:sub(2)
    end
    
    return (left or "") .. (num or "") .. (right or "")
end

function utils:equalIgnoreCase(a, b)
    if not a or not b then
        return false
    end
    return a:lower() == b:lower()
end

function utils:trim(str)
    return str and str:match("^%s*(.-)%s*$") or ""
end

--[[
  Truncate text to specified length
  Adds ellipsis (..) if text exceeds maximum length.
  
  @param text string - Text to truncate
  @param len number - Maximum length including ellipsis
  @return string - Truncated text or original if within length
]]
function utils:truncate(text, len)
    if not text then return "" end
    if string.len(text) <= len then
        return text
    end
    return string.sub(text, 1, len - 2) .. ".."
end

--[[
  Tokenize text into words, preserving quoted strings as single tokens.
  Handles both single and double quotes.
  
  @param text string - Text to tokenize
  @return table - Array of tokens
  
  Example:
    tokenize('beast "snow cub" rare') -> {"beast", '"snow cub"', "rare"}
]]
function utils:tokenize(text)
    if not text or text == "" then
        return {}
    end
    
    local tokens = {}
    local i = 1
    local len = #text
    
    while i <= len do
        -- Skip whitespace
        while i <= len and text:sub(i, i):match("%s") do
            i = i + 1
        end
        
        if i > len then break end
        
        local token = ""
        local inQuote = false
        local quoteChar = nil
        
        while i <= len do
            local char = text:sub(i, i)
            
            if inQuote then
                token = token .. char
                i = i + 1
                if char == quoteChar then
                    inQuote = false
                end
            elseif char == '"' or char == "'" then
                inQuote = true
                quoteChar = char
                token = token .. char
                i = i + 1
            elseif char:match("%s") then
                break
            else
                token = token .. char
                i = i + 1
            end
        end
        
        if token ~= "" then
            table.insert(tokens, token)
        end
    end
    
    return tokens
end

----------------------------------------------------------
-- Function Helpers
----------------------------------------------------------

--[[
  Create a debounced version of a function.
  The returned function will only execute after `delay` seconds
  of no calls. Useful for search inputs, resize handlers, etc.
  
  @param fn function - Function to debounce
  @param delay number - Delay in seconds (default 0.3)
  @return function - Debounced function
]]
function utils:debounce(fn, delay)
    delay = delay or 0.3
    local timer = nil
    
    return function(...)
        local args = {...}
        if timer then
            timer:Cancel()
        end
        timer = C_Timer.NewTimer(delay, function()
            fn(unpack(args))
            timer = nil
        end)
    end
end

----------------------------------------------------------
-- Boolean/Null Logic
----------------------------------------------------------

function utils:isTruthy(v)
    return not (v == nil or v == false)
end

function utils:coalesce(...)
    for i = 1, select("#", ...) do
        local v = select(i, ...)
        if v ~= nil then
            return v
        end
    end
end

----------------------------------------------------------
-- Collection Helpers
----------------------------------------------------------

function utils:filter(tbl, predicate)
    local out = {}
    for k, v in pairs(tbl) do
        if predicate(v, k) then
            table.insert(out, v)
        end
    end
    return out
end

-- Self-register with dependency system (no dependencies - foundational module)
if Addon.registerModule then
    Addon.registerModule("utils", {}, function()
        return true -- No initialization needed, module is ready
    end)
end

return utils