--[[
  logic/petFilters/filters/filterRecent.lua
  Recent Pet Filter
  
  Filters pets by acquisition recency.
  
  Tokens:
    - recent      -> Uses recentPetDays setting (default 14)
    - recent:7    -> Pets acquired in last 7 days
    - recent:30   -> Pets acquired in last 30 days
  
  Dependencies: filterType, filterRegistry, petAcquisitions, options
  Exports: Registers with filterRegistry
]]

local ADDON_NAME, Addon = ...

local filterType = Addon.filterType
local filterRegistry = Addon.filterRegistry

if not filterType or not filterRegistry then
  error("filterRecent: Dependencies not loaded")
end

-- Lazy-load petAcquisitions (not available at filter load time)
local function getPetAcquisitions()
  return Addon.petAcquisitions
end

-- Lazy-load options
local function getOptions()
  return Addon.options
end

--[[
  Get cutoff timestamp for recency check
  
  @param days number|nil - Days threshold (nil uses setting)
  @return number - Unix timestamp cutoff
]]
local function getCutoff(days)
  if not days then
    local options = getOptions()
    days = options and options:Get("recentPetDays") or 14
  end
  return time() - (days * 24 * 60 * 60)
end

-- Create the filter type
local recentFilter = filterType:new({
  id = "recent",
  category = "recent",
  priority = 25,  -- Check early (after rarity, before family)
  supportsNegation = true,
  logicType = "OR",
  
  -- Match "recent" or "recent:N"
  patterns = {
    "^recent:(%d+)$",  -- recent:14, recent:7
    "^recent$",        -- recent (uses setting)
  },
  
  -- Parse the days value
  parser = function(term, value, captures)
    -- Check if we have a numeric capture (from recent:N pattern)
    local num = tonumber(captures[1])
    if num then
      return num
    end
    -- No explicit days (plain "recent"), return 0 sentinel to use setting
    return 0
  end,
  
  -- Check if pet matches recency threshold
  matcher = function(pet, value)
    if not pet or not pet.petID then
      return false
    end
    
    local petAcquisitions = getPetAcquisitions()
    if not petAcquisitions then
      return false
    end
    
    -- value of 0 means use setting, otherwise use explicit days
    local days = value > 0 and value or nil
    return petAcquisitions:isRecent(pet.petID, days)
  end,
})

-- Register with the filter registry
filterRegistry:register(recentFilter)

-- Module registration
if Addon.registerModule then
  Addon.registerModule("filterRecent", {"filterType", "filterRegistry"}, function()
    return true
  end)
end

return recentFilter