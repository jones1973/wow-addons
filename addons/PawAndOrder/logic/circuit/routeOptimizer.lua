--[[

logic/circuit/routeOptimizer.lua

Route optimization with Nearest Neighbor + k-Opt local search

Simple, fast, effective TSP solver using greedy initialization with 
exhaustive local search optimization.

Tested and proven: NN + 3-Opt gives ~10% improvement over pure NN
for typical Pandaria tamer routes (20-50 NPCs).

Uses HereBeDragons GetZoneDistance for accurate in-game yard calculations.

Dependencies: utils, location, npcUtils, HereBeDragons-2.0 (lib)
Exports: Addon.routeOptimizer

]]

local addonName, Addon = ...

Addon.routeOptimizer = {}
local routeOptimizer = Addon.routeOptimizer

-- Get HereBeDragons library
local HBD = LibStub("HereBeDragons-2.0")
if not HBD then
    error("PawAndOrder: HereBeDragons-2.0 library not found! Please ensure libs/HereBeDragons is properly loaded.")
end

-- ========== CONFIGURATION ==========
-- k-Opt value: 2, 3, 4, 5, 6, 7
-- Higher k = potentially better routes but slower
-- Recommended: 3 (excellent quality/speed balance for 20-50 NPCs)
local K_OPT_VALUE = 3

-- Maximum optimization iterations per k-Opt pass
-- 500 is more than enough for convergence on typical routes
local K_OPT_MAX_ITERATIONS = 500
-- ====================================

-- Resolve an NPC's routable location (mapID, x, y) from the locations array
-- Returns loc, npc or nil if NPC/location not found
local function resolveNpcLocation(npcId)
    local npc = Addon.npcUtils:getNpcData(npcId)
    if not npc then return nil end
    local loc = Addon.location:getNpcLocation(npc)
    if not loc or not loc.mapID then return nil end
    return loc, npc
end

-- Calculate yard distance between two map points
-- Coordinates are 0-100 scale (our standard); HBD expects 0-1
-- Returns distance in yards, or math.huge if HBD can't compute it
local function yardsBetween(mapID1, x1, y1, mapID2, x2, y2)
    local dx, dy, dz = HBD:GetZoneDistance(mapID1, x1 / 100, y1 / 100, mapID2, x2 / 100, y2 / 100)
    if not dx then return math.huge end
    return math.sqrt(dx * dx + (dy or 0) * (dy or 0) + (dz or 0) * (dz or 0))
end

--[[
Calculate total route distance including start and end points
@param route table - array of NPC IDs
@param startX, startY number - starting coordinates (0-100)
@param startMapID number - starting map ID
@param endX, endY number - ending coordinates (optional, 0-100)
@param endMapID number - ending map ID (optional)
@return number - total distance in yards
]]
function routeOptimizer:calculateRouteDistance(route, startX, startY, startMapID, endX, endY, endMapID)
    if #route == 0 then return 0 end
    
    local totalDist = 0
    local prevMapID, prevX, prevY = startMapID, startX, startY
    
    for i = 1, #route do
        local loc = resolveNpcLocation(route[i])
        if loc then
            totalDist = totalDist + yardsBetween(prevMapID, prevX, prevY, loc.mapID, loc.x, loc.y)
            prevMapID, prevX, prevY = loc.mapID, loc.x, loc.y
        end
    end
    
    if endX and endY and endMapID then
        totalDist = totalDist + yardsBetween(prevMapID, prevX, prevY, endMapID, endX, endY)
    end
    
    return totalDist
end

--[[
Reverse segment of route between indices i and j
Lua 5.1 compatible (no table.move)
@param route table - array of NPC IDs
@param i number - start index of segment to reverse
@param j number - end index of segment to reverse
@return table - new route with reversed segment
]]
local function reverseSegment(route, i, j)
    local newRoute = {}
    
    for k = 1, i - 1 do
        table.insert(newRoute, route[k])
    end
    
    for k = j, i, -1 do
        table.insert(newRoute, route[k])
    end
    
    for k = j + 1, #route do
        table.insert(newRoute, route[k])
    end
    
    return newRoute
end

--[[
Generate all combinations of k points from range [minIdx, maxIdx]
Used for exhaustive k-Opt edge checking
@param minIdx number - minimum index value
@param maxIdx number - maximum index value
@param k number - number of points to select
@return table - array of arrays, each containing k selected indices
]]
local function generateKPointCombinations(minIdx, maxIdx, k)
    local results = {}
    local current = {}
    
    local function backtrack(start, depth)
        if depth == k then
            local copy = {}
            for _, v in ipairs(current) do
                table.insert(copy, v)
            end
            table.insert(results, copy)
            return
        end
        
        for i = start, maxIdx - (k - depth - 1) do
            table.insert(current, i)
            backtrack(i + 1, depth + 1)
            table.remove(current)
        end
    end
    
    backtrack(minIdx, 0)
    return results
end

--[[
Apply k-Opt optimization with exhaustive edge checking
All k values use exhaustive search over valid edge combinations

Time complexity: O(n^k) per iteration
k=2: ~n²/2 checks per iteration
k=3: ~n³/6 checks per iteration  
k=4+: ~n^k/k! checks per iteration

@param route table - array of NPC IDs
@param startX, startY number - starting coordinates (0-100)
@param startMapID number - starting map ID
@param endX, endY number - ending coordinates (optional, 0-100)
@param endMapID number - ending map ID (optional)
@param k number - k-Opt value (2-7)
@param maxIterations number - max optimization passes
@return table - optimized route
]]
local function applyKOpt(route, startX, startY, startMapID, endX, endY, endMapID, k, maxIterations)
    if #route < 4 then return route end
    
    k = k or 3
    maxIterations = maxIterations or 500
    
    local improved = true
    local iterations = 0
    local bestRoute = Addon.utils:shallowCopy(route)
    local bestDistance = routeOptimizer:calculateRouteDistance(bestRoute, startX, startY, startMapID, endX, endY, endMapID)
    
    Addon.utils:debug(string.format("Starting %d-Opt: %.1f yards", k, bestDistance))
    
    local startTime = debugprofilestop and debugprofilestop() or 0
    
    while improved and iterations < maxIterations do
        improved = false
        iterations = iterations + 1
        
        if k == 2 then
            -- 2-Opt: Classic edge swap
            for i = 1, #bestRoute - 1 do
                for j = i + 1, #bestRoute do
                    local candidate = reverseSegment(bestRoute, i, j)
                    local dist = routeOptimizer:calculateRouteDistance(candidate, startX, startY, startMapID, endX, endY, endMapID)
                    if dist < bestDistance then
                        bestDistance = dist
                        bestRoute = candidate
                        improved = true
                    end
                end
            end
            
        elseif k == 3 then
            -- 3-Opt: Three-point reconnection
            for i = 1, #bestRoute - 2 do
                for j = i + 1, #bestRoute - 1 do
                    for m = j + 1, #bestRoute do
                        -- Try different segment reversal combinations
                        local candidates = {}
                        
                        -- Original
                        table.insert(candidates, bestRoute)
                        
                        -- Reverse first segment (i to j)
                        local c1 = {}
                        for idx = 1, i - 1 do table.insert(c1, bestRoute[idx]) end
                        for idx = j, i, -1 do table.insert(c1, bestRoute[idx]) end
                        for idx = j + 1, #bestRoute do table.insert(c1, bestRoute[idx]) end
                        table.insert(candidates, c1)
                        
                        -- Reverse second segment (j+1 to m)
                        local c2 = {}
                        for idx = 1, j do table.insert(c2, bestRoute[idx]) end
                        for idx = m, j + 1, -1 do table.insert(c2, bestRoute[idx]) end
                        for idx = m + 1, #bestRoute do table.insert(c2, bestRoute[idx]) end
                        table.insert(candidates, c2)
                        
                        -- Reverse both segments
                        local c3 = {}
                        for idx = 1, i - 1 do table.insert(c3, bestRoute[idx]) end
                        for idx = j, i, -1 do table.insert(c3, bestRoute[idx]) end
                        for idx = m, j + 1, -1 do table.insert(c3, bestRoute[idx]) end
                        for idx = m + 1, #bestRoute do table.insert(c3, bestRoute[idx]) end
                        table.insert(candidates, c3)
                        
                        for _, candidate in ipairs(candidates) do
                            if #candidate == #bestRoute then
                                local dist = routeOptimizer:calculateRouteDistance(candidate, startX, startY, startMapID, endX, endY, endMapID)
                                if dist < bestDistance then
                                    bestDistance = dist
                                    bestRoute = candidate
                                    improved = true
                                end
                            end
                        end
                    end
                end
            end
            
        else
            -- k >= 4: Generic k-Opt using combinations
            local combinations = generateKPointCombinations(1, #bestRoute, k)
            
            for _, points in ipairs(combinations) do
                -- Try reversing each possible subset of segments
                for mask = 1, (2^k) - 1 do
                    local candidate = Addon.utils:shallowCopy(bestRoute)
                    
                    -- Apply segment reversals based on mask bits
                    for bit = 1, k - 1 do
                        if bit.band(mask, 2^(bit-1)) > 0 then
                            candidate = reverseSegment(candidate, points[bit], points[bit + 1])
                        end
                    end
                    
                    -- Also try just the last segment
                    if bit.band(mask, 2^(k-1)) > 0 and points[k] < #bestRoute then
                        candidate = reverseSegment(candidate, points[k], #bestRoute)
                    end
                    
                    if #candidate == #bestRoute then
                        local dist = routeOptimizer:calculateRouteDistance(candidate, startX, startY, startMapID, endX, endY, endMapID)
                        if dist < bestDistance then
                            bestDistance = dist
                            bestRoute = candidate
                            improved = true
                        end
                    end
                end
            end
        end
    end
    
    local elapsed = debugprofilestop and (debugprofilestop() - startTime) or 0
    Addon.utils:debug(string.format("%d-Opt: %.1f yards (%d iterations, %.0fms)",
        k, bestDistance, iterations, elapsed))
    
    return bestRoute
end

--[[
Rotate route to start with NPC closest to starting position
Used for round-trip routes to minimize first leg distance
@param route table - array of NPC IDs
@param startX, startY number - starting coordinates (0-100)
@param startMapID number - starting map ID
@return table - rotated route
]]
local function rotateToNearestStart(route, startX, startY, startMapID)
    if #route <= 1 then return route end
    
    local closestIdx = 1
    local closestDist = math.huge
    
    for i, npcId in ipairs(route) do
        local loc = resolveNpcLocation(npcId)
        if loc then
            local dist = yardsBetween(startMapID, startX, startY, loc.mapID, loc.x, loc.y)
            if dist < closestDist then
                closestDist = dist
                closestIdx = i
            end
        end
    end
    
    if closestIdx == 1 then return route end
    
    local rotated = {}
    for i = closestIdx, #route do
        table.insert(rotated, route[i])
    end
    for i = 1, closestIdx - 1 do
        table.insert(rotated, route[i])
    end
    
    return rotated
end

--[[
Generate route using Nearest Neighbor greedy algorithm
This provides the initial solution for k-Opt optimization.
Exposed as public method for re-optimization percentage calculations.
@param npcIds table - array of NPC IDs
@param startX, startY number - starting coordinates (0-100)
@param startMapID number - starting map ID
@return table - route in visit order
]]
function routeOptimizer:generateNearestNeighborRoute(npcIds, startX, startY, startMapID)
    if #npcIds == 0 then return {} end
    if #npcIds == 1 then return npcIds end
    
    local route = {}
    local unvisited = {}
    for _, npcId in ipairs(npcIds) do
        unvisited[npcId] = true
    end
    
    local currentMapID, currentX, currentY = startMapID, startX, startY
    
    while next(unvisited) do
        local closestNpc = nil
        local closestDist = math.huge
        local closestLoc = nil
        
        for npcId, _ in pairs(unvisited) do
            local loc = resolveNpcLocation(npcId)
            if loc then
                local dist = yardsBetween(currentMapID, currentX, currentY, loc.mapID, loc.x, loc.y)
                if dist < closestDist then
                    closestDist = dist
                    closestNpc = npcId
                    closestLoc = loc
                end
            end
        end
        
        if closestNpc then
            table.insert(route, closestNpc)
            unvisited[closestNpc] = nil
            currentMapID, currentX, currentY = closestLoc.mapID, closestLoc.x, closestLoc.y
        else
            break
        end
    end
    
    return route
end

-- ========== MAIN ROUTING FUNCTION ==========

--[[
Generate optimized route using Nearest Neighbor + k-Opt
Main entry point for route optimization
@param npcIds table - array of NPC IDs to visit
@param startX, startY number - starting coordinates (0-100)
@param startMapID number - starting map ID
@param endX, endY number - ending coordinates (optional, 0-100)
@param endMapID number - ending map ID (optional)
@param suppressMessage boolean - optional, suppress optimization message (for re-optimization)
@return table - optimized route as array of NPC IDs
]]
function routeOptimizer:generateOptimizedRoute(npcIds, startX, startY, startMapID, endX, endY, endMapID, suppressMessage)
    if #npcIds == 0 then return {} end
    
    if #npcIds == 1 then return npcIds end
    
    if #npcIds == 2 then
        local loc1 = resolveNpcLocation(npcIds[1])
        local loc2 = resolveNpcLocation(npcIds[2])
        
        if loc1 and loc2 then
            local dist1 = yardsBetween(startMapID, startX, startY, loc1.mapID, loc1.x, loc1.y)
            local dist2 = yardsBetween(startMapID, startX, startY, loc2.mapID, loc2.x, loc2.y)
            return dist1 <= dist2 and {npcIds[1], npcIds[2]} or {npcIds[2], npcIds[1]}
        end
        
        return npcIds
    end
    
    local isRoundTrip = (endX and endY and endMapID)
    
    Addon.utils:debug(string.format("=== ROUTE OPTIMIZATION: %d NPCs from (%.1f, %.1f) mapID=%d ===",
        #npcIds, startX, startY, startMapID))
    
    Addon.utils:debug(isRoundTrip and "Route Type: ROUND-TRIP" or "Route Type: ONE-WAY")
    
    -- Show closest NPCs to start (skipped when debug off to avoid N lookups + sort)
    if Addon.utils:isDebugEnabled() then
        Addon.utils:debug("=== Closest NPCs to Start ===")
        local distancesFromStart = {}
        for _, npcId in ipairs(npcIds) do
            local loc, npc = resolveNpcLocation(npcId)
            if loc then
                local dist = yardsBetween(startMapID, startX, startY, loc.mapID, loc.x, loc.y)
                local zoneName = Addon.location:getZoneByMapID(loc.mapID)
                table.insert(distancesFromStart, {id = npcId, name = npc.name, dist = dist, zone = zoneName})
            end
        end
        table.sort(distancesFromStart, function(a, b) return a.dist < b.dist end)
        for i = 1, math.min(5, #distancesFromStart) do
            local entry = distancesFromStart[i]
            Addon.utils:debug(string.format("  #%d: %s in %s - %.1f yards",
                i, entry.name, entry.zone or "Unknown", entry.dist))
        end
    end
    
    -- Step 1: Nearest Neighbor baseline
    Addon.utils:debug("=== Step 1: Nearest Neighbor Baseline ===")
    local nnRoute = self:generateNearestNeighborRoute(npcIds, startX, startY, startMapID)
    local nnDistance = self:calculateRouteDistance(nnRoute, startX, startY, startMapID, endX, endY, endMapID)
    Addon.utils:debug(string.format("Nearest Neighbor: %.1f yards", nnDistance))
    
    -- Step 2: k-Opt optimization
    Addon.utils:debug(string.format("=== Step 2: %d-Opt Optimization ===", K_OPT_VALUE))
    local optimizedRoute = applyKOpt(nnRoute, startX, startY, startMapID, endX, endY, endMapID, K_OPT_VALUE, K_OPT_MAX_ITERATIONS)
    local optimizedDistance = self:calculateRouteDistance(optimizedRoute, startX, startY, startMapID, endX, endY, endMapID)
    
    local totalImprovement = ((nnDistance - optimizedDistance) / nnDistance) * 100
    
    -- Show user-facing message if setting enabled and not suppressed
    if not suppressMessage and Addon.options and Addon.options:Get("showCircuitOptimization") then
        Addon.utils:notify(string.format("Route optimized: %.1f%% shorter than nearest neighbor", totalImprovement))
    end
    
    Addon.utils:debug(string.format("After %d-opt: %.1f yards (%.1f%% improvement vs NN)",
        K_OPT_VALUE, optimizedDistance, totalImprovement))
    
    local finalRoute, finalDistance
    
    -- Step 3: Rotate to nearest start (round-trip only)
    if isRoundTrip then
        Addon.utils:debug("=== Step 3: Rotate to Nearest Start ===")
        finalRoute = rotateToNearestStart(optimizedRoute, startX, startY, startMapID)
        finalDistance = optimizedDistance
        
        local firstLoc, firstNpc = resolveNpcLocation(finalRoute[1])
        if firstLoc then
            local distToFirst = yardsBetween(startMapID, startX, startY, firstLoc.mapID, firstLoc.x, firstLoc.y)
            Addon.utils:debug(string.format("Starting with: %s (%.1f yards away)", firstNpc.name, distToFirst))
        end
    else
        finalRoute = optimizedRoute
        finalDistance = optimizedDistance
    end
    
    Addon.utils:debug(string.format("=== FINAL: %.1f yards total ===", finalDistance))
    
    return finalRoute
end

--[[
Group NPCs by continent for cross-continent route planning
Uses location:getNpcLocation() abstraction to get continent from NPC data.
@param npcIds table - array of NPC IDs
@return table - map of continentID to array of NPC IDs on that continent
]]
function routeOptimizer:groupNpcsByContinent(npcIds)
    local grouped = {}
    
    for _, npcId in ipairs(npcIds) do
        local npc = Addon.npcUtils:getNpcData(npcId)
        if npc then
            local loc = Addon.location:getNpcLocation(npc)
            local continent = loc and loc.continent
            if continent and continent ~= 0 then
                if not grouped[continent] then
                    grouped[continent] = {}
                end
                table.insert(grouped[continent], npcId)
            else
                Addon.utils:chat(string.format("NPC '%s' has invalid continent - skipping from route",
                    npc.name or "Unknown"))
            end
        end
    end
    
    return grouped
end

--[[
Build continent visitation queue with player's current continent first
@param npcsByContinent table - map of continentID to NPC arrays (from groupNpcsByContinent)
@param playerContinent number - continent ID where player currently is
@return table - ordered array of {continent, npcIds} entries
]]
function routeOptimizer:buildContinentQueue(npcsByContinent, playerContinent)
    local queue = {}
    
    if playerContinent and npcsByContinent[playerContinent] then
        table.insert(queue, {
            continent = playerContinent,
            npcIds = npcsByContinent[playerContinent]
        })
    end
    
    for continent, npcIds in pairs(npcsByContinent) do
        if continent ~= playerContinent then
            table.insert(queue, {
                continent = continent,
                npcIds = npcIds
            })
        end
    end
    
    return queue
end

if Addon.registerModule then
    Addon.registerModule("routeOptimizer", {"utils", "location", "npcUtils"}, function()
        return true
    end)
end