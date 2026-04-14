--[[
  logic/achievements/achievements.lua
  Achievement Logic and Data Management
  
  Loading Strategy (lazy-load for performance):
    1. At init: Load basic achievement info (name, icon, completed status)
    2. On category expand: Load criteria details with warm-up pass
  
  Events Emitted:
    - ACHIEVEMENTS:DATA_LOADED
    - ACHIEVEMENTS:DATA_REFRESHED
    - ACHIEVEMENTS:FILTER_CHANGED
    - ACHIEVEMENTS:CATEGORY_DETAILS_LOADED
  
  Dependencies: achievementData, events, utils
  Exports: Addon.achievementLogic
]]

local ADDON_NAME, Addon = ...

local achievementLogic = {}

-- ============================================================================
-- STATE
-- ============================================================================

local cachedAchievements = nil
local guildAchievements = nil
local detailsLoadedCategories = {}
local lastRefreshTime = 0
local initialized = false
local dataLoaded = false

-- Priming state
local primingInProgress = false
local primingComplete = false
local primingQueue = {}
local primingFrame = nil

-- Filter state (multi-select)
local statusFilters = {}
local specialtyFilters = {}
local searchText = ""

-- Module references
local achievementData, events, utils, options

-- ============================================================================
-- INTERNAL HELPERS
-- ============================================================================

local function detectPetReward(rewardText)
    if not rewardText or rewardText == "" then
        return false, nil, false
    end
    
    local petName = rewardText:match("^Reward:%s*(.+)$")
    if not petName then
        return false, nil, false
    end
    
    local speciesID, petGUID = C_PetJournal.FindPetIDByName(petName)
    
    if speciesID then
        return true, speciesID, (petGUID ~= nil)
    end
    
    -- Not a pet (could be mount, title, item, etc.) - this is expected
    return false, nil, false
end

--[[
  Load criteria details for an achievement (expensive - lazy loaded).
]]
local function loadCriteriaDetails(achievementId)
    local numCriteria = GetAchievementNumCriteria(achievementId)
    
    if not numCriteria or numCriteria == 0 then
        local _, _, _, achCompleted = GetAchievementInfo(achievementId)
        return achCompleted and 1 or 0, achCompleted and 1 or 0, 1, {}, false, 0, 0
    end
    
    -- Warm-up pass: query all criteria first to prime cache
    for i = 1, numCriteria do
        GetAchievementCriteriaInfo(achievementId, i)
    end
    
    -- Second pass: collect actual data
    local completedCriteria = 0
    local criteriaDetails = {}
    local totalQuantity = 0
    local totalRequired = 0
    
    for i = 1, numCriteria do
        local criteriaString, criteriaType, completed, quantity, reqQuantity,
              charName, flags, assetID, quantityString, criteriaID = 
              GetAchievementCriteriaInfo(achievementId, i)
        
        if completed then
            completedCriteria = completedCriteria + 1
        end
        
        -- Parse quantity from quantityString if quantity is 0 but string has data
        -- Guild achievements often need this - server sends quantityString but not quantity
        if (not quantity or quantity == 0) and quantityString and reqQuantity and reqQuantity > 0 then
            local parsedQty = quantityString:match("^(%d+)")
            if parsedQty then
                quantity = tonumber(parsedQty) or 0
            end
        end
        
        if reqQuantity and reqQuantity > 0 then
            totalQuantity = totalQuantity + (quantity or 0)
            totalRequired = totalRequired + reqQuantity
        end
        
        local speciesID = nil
        local petOwned = false
        if criteriaString and criteriaString ~= "" then
            local sID, pGUID = C_PetJournal.FindPetIDByName(criteriaString)
            if sID then
                speciesID = sID
                petOwned = (pGUID ~= nil)
            end
        end
        
        -- Check if criteria is a sub-achievement (criteriaType 8)
        local isSubAchievement = (criteriaType == 8)
        local subAchievementId = isSubAchievement and assetID or nil
        local subAchievementInfo = nil
        
        if isSubAchievement and subAchievementId then
            local subId, subName, subPoints, subCompleted, subMonth, subDay, subYear,
                  subDesc, subFlags, subIcon = GetAchievementInfo(subAchievementId)
            if subId then
                subAchievementInfo = {
                    id = subId,
                    name = subName,
                    icon = subIcon,
                    completed = subCompleted,
                    points = subPoints,
                }
            end
        end
        
        table.insert(criteriaDetails, {
            name = criteriaString,
            completed = completed,
            quantity = quantity,
            required = reqQuantity,
            quantityString = quantityString,
            speciesID = speciesID,
            petOwned = petOwned,
            isSubAchievement = isSubAchievement,
            subAchievementId = subAchievementId,
            subAchievement = subAchievementInfo,
        })
    end
    
    local progress
    local hasQuantityProgress = (totalRequired > 1)
    
    if hasQuantityProgress then
        progress = totalQuantity / totalRequired
    elseif numCriteria > 0 then
        progress = completedCriteria / numCriteria
    else
        progress = 0
    end
    
    return progress, completedCriteria, numCriteria, criteriaDetails, hasQuantityProgress, totalQuantity, totalRequired
end

--[[
  Build basic achievement data (cheap - called at init).
]]
local function buildBasicAchievementData(achievementId, categoryId)
    local id, name, points, completed, month, day, year,
          description, flags, icon, rewardText, isGuild = 
          GetAchievementInfo(achievementId)
    
    if not id or not name then return nil end
    
    local isPetReward, speciesID, userOwnsPet = detectPetReward(rewardText)
    local isTitleReward = achievementData:isTitleReward(rewardText)
    
    local completionTimestamp = nil
    if completed and month and day and year then
        completionTimestamp = time({
            year = 2000 + year,
            month = month,
            day = day,
            hour = 12,
        })
    end
    
    return {
        id = id,
        name = name,
        description = description,
        points = points,
        icon = icon,
        rewardText = rewardText,
        completed = completed,
        completionDate = completed and string.format("%d/%d/%d", month, day, year) or nil,
        completionTimestamp = completionTimestamp,
        isGuild = isGuild,
        categoryId = categoryId,
        isPetReward = isPetReward,
        isTitleReward = isTitleReward,
        speciesID = speciesID,
        userOwnsPet = userOwnsPet,
        isTracked = IsTrackedAchievement(id),
        -- Criteria details (lazy loaded)
        detailsLoaded = false,
        progress = completed and 1 or 0,
        completedCriteria = 0,
        totalCriteria = 0,
        hasQuantityProgress = false,
        totalQuantity = 0,
        totalRequired = 0,
        criteria = {},
    }
end

--[[
  Load criteria details into an existing achievement object.
]]
local function loadAchievementDetails(achievement)
    if achievement.detailsLoaded then return end
    
    local progress, completedCriteria, totalCriteria, criteriaDetails,
          hasQuantityProgress, totalQuantity, totalRequired = 
          loadCriteriaDetails(achievement.id)
    
    achievement.progress = achievement.completed and 1 or progress
    achievement.completedCriteria = completedCriteria
    achievement.totalCriteria = totalCriteria
    achievement.criteria = criteriaDetails
    achievement.hasQuantityProgress = hasQuantityProgress
    achievement.totalQuantity = totalQuantity
    achievement.totalRequired = totalRequired
    achievement.detailsLoaded = true
end

--[[
  Fetch basic achievement info for a category (no criteria).
]]
local function fetchCategoryBasicInfo(categoryId)
    local result = {
        achievements = {},
        completed = 0,
        total = 0,
    }
    
    local numAchievements = GetCategoryNumAchievements(categoryId)
    if not numAchievements or numAchievements == 0 then
        return result
    end
    
    for i = 1, numAchievements do
        local achievementId = GetAchievementInfo(categoryId, i)
        
        if achievementId then
            local achievement = buildBasicAchievementData(achievementId, categoryId)
            
            if achievement then
                table.insert(result.achievements, achievement)
                result.total = result.total + 1
                
                if achievement.completed then
                    result.completed = result.completed + 1
                end
            end
        end
    end
    
    return result
end

--[[
  Scan guild categories for achievements that reward pets.
]]
local function scanGuildPetRewardAchievements()
    local guildPetRewards = {}
    
    for _, categoryId in ipairs(achievementData.GUILD_SUBCATEGORIES) do
        local numAchievements = GetCategoryNumAchievements(categoryId)
        
        if numAchievements and numAchievements > 0 then
            for i = 1, numAchievements do
                local achievementId = GetAchievementInfo(categoryId, i)
                
                if achievementId then
                    local achievement = buildBasicAchievementData(achievementId, categoryId)
                    
                    if achievement and achievement.isPetReward then
                        table.insert(guildPetRewards, achievement)
                    end
                end
            end
        end
    end
    
    return guildPetRewards
end

local function getSubcategories()
    local subcategories = {}
    local parentId = achievementData.PET_BATTLE_CATEGORY_ID
    
    local categories = GetCategoryList()
    if not categories then return subcategories end
    
    for _, categoryId in ipairs(categories) do
        local categoryName, categoryParentId = GetCategoryInfo(categoryId)
        
        if categoryParentId == parentId then
            table.insert(subcategories, {
                id = categoryId,
                name = categoryName,
                parentId = categoryParentId,
            })
        end
    end
    
    local orderMap = {}
    for i, name in ipairs(achievementData.SUBCATEGORY_ORDER) do
        orderMap[name] = i
    end
    
    table.sort(subcategories, function(a, b)
        local orderA = orderMap[a.name] or 999
        local orderB = orderMap[b.name] or 999
        if orderA ~= orderB then
            return orderA < orderB
        end
        return a.name < b.name
    end)
    
    return subcategories
end

-- ============================================================================
-- DATA LOADING
-- ============================================================================

local function loadBasicData()
    cachedAchievements = {}
    detailsLoadedCategories = {}
    
    -- First, load "General" category from the parent Pet Battle category itself
    local parentId = achievementData.PET_BATTLE_CATEGORY_ID
    local generalData = fetchCategoryBasicInfo(parentId)
    if generalData.total > 0 then
        generalData.name = "General"
        generalData.displayName = "General"
        cachedAchievements["general"] = generalData
    end
    
    -- Then load subcategories
    local subcategories = getSubcategories()
    
    for _, subcat in ipairs(subcategories) do
        local data = fetchCategoryBasicInfo(subcat.id)
        data.name = subcat.name
        data.displayName = achievementData:getSubcategoryDisplayName(subcat.name)
        cachedAchievements[subcat.id] = data
    end
    
    guildAchievements = scanGuildPetRewardAchievements()
    
    lastRefreshTime = GetTime()
end

--[[
  Load criteria details for all achievements in a category.
  Called when a category is expanded.
]]
local function loadCategoryDetails(categoryId)
    if detailsLoadedCategories[categoryId] then
        return
    end
    
    local achievements = nil
    
    if categoryId == "guild" then
        achievements = guildAchievements
    elseif cachedAchievements[categoryId] then
        achievements = cachedAchievements[categoryId].achievements
    end
    
    if not achievements then
        return
    end
    
    local loadedCount = 0
    for _, achievement in ipairs(achievements) do
        loadAchievementDetails(achievement)
        loadedCount = loadedCount + 1
    end
    
    detailsLoadedCategories[categoryId] = true
    
    if events then
        events:emit("ACHIEVEMENTS:CATEGORY_DETAILS_LOADED", { categoryId = categoryId })
    end
end

-- ============================================================================
-- FILTERING
-- ============================================================================

local function passesFilters(ach)
    local hasStatusFilter = statusFilters.completed or statusFilters.incomplete
    if hasStatusFilter then
        local matchesStatus = false
        if statusFilters.completed and ach.completed then
            matchesStatus = true
        end
        if statusFilters.incomplete and not ach.completed then
            matchesStatus = true
        end
        if not matchesStatus then
            return false
        end
    end
    
    local hasSpecialtyFilter = specialtyFilters.rewards_pet or 
                               specialtyFilters.rewards_title or
                               specialtyFilters.has_reward or
                               specialtyFilters.unlocks_quest
    if hasSpecialtyFilter then
        local matchesSpecialty = false
        if specialtyFilters.rewards_pet and ach.isPetReward then
            matchesSpecialty = true
        end
        if specialtyFilters.rewards_title and ach.isTitleReward then
            matchesSpecialty = true
        end
        if specialtyFilters.has_reward then
            -- Has any reward (pet, title, item, or unlock)
            local hasReward = ach.rewardText and ach.rewardText ~= ""
            if hasReward then
                matchesSpecialty = true
            end
        end
        if specialtyFilters.unlocks_quest then
            -- Unlocks a quest or vendor access
            local isUnlock = achievementData and achievementData:isUnlockReward(ach.rewardText)
            if isUnlock then
                matchesSpecialty = true
            end
        end
        if not matchesSpecialty then
            return false
        end
    end
    
    if searchText and searchText ~= "" then
        local lowerSearch = string.lower(searchText)
        local lowerName = string.lower(ach.name or "")
        local lowerDesc = string.lower(ach.description or "")
        local lowerReward = string.lower(ach.rewardText or "")
        
        if not string.find(lowerName, lowerSearch, 1, true) and
           not string.find(lowerDesc, lowerSearch, 1, true) and
           not string.find(lowerReward, lowerSearch, 1, true) then
            return false
        end
    end
    
    return true
end

-- ============================================================================
-- GUILD QUANTITY ACHIEVEMENT PRIMING
-- ============================================================================

-- Guild achievements need Blizzard UI to request data from server.
-- We open the achievement frame off-screen and select each incomplete
-- guild achievement to trigger the server to send quantity data.

-- Saved state for restoring after priming
local savedFrameState = nil

local function finishPriming()
    if AchievementFrame then
        -- Restore original state
        if savedFrameState then
            AchievementFrame:ClearAllPoints()
            if savedFrameState.point then
                AchievementFrame:SetPoint(
                    savedFrameState.point,
                    savedFrameState.relativeTo,
                    savedFrameState.relativePoint,
                    savedFrameState.xOfs,
                    savedFrameState.yOfs
                )
            else
                AchievementFrame:SetPoint("CENTER")
            end
            
            if savedFrameState.wasShown then
                -- Restore selected achievement if there was one
                if savedFrameState.selectedAchievement then
                    AchievementFrame_SelectAchievement(savedFrameState.selectedAchievement)
                end
                AchievementFrame:Show()  -- Ensure visible (scripts still nil - no sound)
            else
                AchievementFrame:Hide()  -- Scripts still nil - no sound
            end
            
            -- Restore OnShow/OnHide scripts AFTER Show/Hide to prevent sounds
            if savedFrameState.onShowScript then
                AchievementFrame:SetScript("OnShow", savedFrameState.onShowScript)
            end
            if savedFrameState.onHideScript then
                AchievementFrame:SetScript("OnHide", savedFrameState.onHideScript)
            end
            
            savedFrameState = nil
        else
            AchievementFrame:Hide()
            AchievementFrame:ClearAllPoints()
            AchievementFrame:SetPoint("CENTER")
        end
    end
    primingInProgress = false
    primingComplete = true
    
    if primingFrame then
        primingFrame:UnregisterEvent("CRITERIA_UPDATE")
    end
    
    -- Refresh guild data now that server has sent it
    -- Must reset detailsLoaded flag on each achievement so they reload
    if guildAchievements then
        for _, ach in ipairs(guildAchievements) do
            ach.detailsLoaded = false
        end
    end
    if cachedAchievements then
        detailsLoadedCategories["guild"] = false
        loadCategoryDetails("guild")
    end
    
    if events then
        events:emit("ACHIEVEMENTS:PRIMING_COMPLETE")
        events:emit("ACHIEVEMENTS:DATA_REFRESHED")  -- Trigger UI update
    end
end

local function primeNextAchievement()
    if #primingQueue == 0 then
        finishPriming()
        return
    end
    
    local achievementId = table.remove(primingQueue, 1)
    AchievementFrame_SelectAchievement(achievementId, true)
end

local function onPrimingCriteriaUpdate()
    primeNextAchievement()
end

local function startGuildQuantityPriming()
    if primingComplete or primingInProgress then
        return
    end
    
    -- Build queue from ALL guild achievements (need to prime completed ones too for criteria data)
    primingQueue = {}
    if guildAchievements then
        for _, ach in ipairs(guildAchievements) do
            table.insert(primingQueue, ach.id)
        end
    end
    
    if #primingQueue == 0 then
        primingComplete = true
        return
    end
    
    primingInProgress = true
    
    -- Load Blizzard's achievement UI
    LoadAddOn("Blizzard_AchievementUI")
    
    if not AchievementFrame then
        primingInProgress = false
        return
    end
    
    -- Save current state before manipulating
    savedFrameState = {
        wasShown = AchievementFrame:IsShown(),
        selectedAchievement = AchievementFrameAchievements and 
                              AchievementFrameAchievements.selection or nil,
        onShowScript = AchievementFrame:GetScript("OnShow"),
        onHideScript = AchievementFrame:GetScript("OnHide"),
    }
    local point, relativeTo, relativePoint, xOfs, yOfs = AchievementFrame:GetPoint(1)
    if point then
        savedFrameState.point = point
        savedFrameState.relativeTo = relativeTo
        savedFrameState.relativePoint = relativePoint
        savedFrameState.xOfs = xOfs
        savedFrameState.yOfs = yOfs
    end
    
    -- Suppress OnShow/OnHide sounds during priming
    AchievementFrame:SetScript("OnShow", nil)
    AchievementFrame:SetScript("OnHide", nil)
    
    -- Create frame to listen for CRITERIA_UPDATE
    if not primingFrame then
        primingFrame = CreateFrame("Frame")
    end
    primingFrame:RegisterEvent("CRITERIA_UPDATE")
    primingFrame:SetScript("OnEvent", onPrimingCriteriaUpdate)
    
    -- Move frame off-screen and show it
    AchievementFrame:ClearAllPoints()
    AchievementFrame:SetPoint("CENTER", UIParent, "CENTER", 5000, 0)
    AchievementFrame:Show()
    
    -- Start priming first achievement
    primeNextAchievement()
end

function achievementLogic:primeGuildAchievements()
    startGuildQuantityPriming()
end

function achievementLogic:isPrimingComplete()
    return primingComplete
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

--[[
  Ensure achievement data is loaded. Call this once when achievements tab is first accessed.
  Triggers guild achievement priming after data load.
]]
function achievementLogic:ensureLoaded()
    if dataLoaded then return end
    
    loadBasicData()
    dataLoaded = true
    
    -- Start guild priming after a brief delay to let UI settle
    C_Timer.After(0.1, startGuildQuantityPriming)
end

function achievementLogic:getGroupedAchievements()
    if not cachedAchievements then return {} end
    
    local groups = {}
    
    -- Add General category first (parent achievements)
    local generalData = cachedAchievements["general"]
    if generalData and generalData.total > 0 then
        table.insert(groups, {
            id = "general",
            name = "General",
            achievements = generalData.achievements,
            completed = generalData.completed,
            total = generalData.total,
        })
    end
    
    -- Add subcategories
    local subcategories = getSubcategories()
    for _, subcat in ipairs(subcategories) do
        local data = cachedAchievements[subcat.id]
        if data then
            table.insert(groups, {
                id = subcat.id,
                name = data.displayName or data.name,
                achievements = data.achievements,
                completed = data.completed,
                total = data.total,
            })
        end
    end
    
    -- Add Guild group last
    if guildAchievements and #guildAchievements > 0 then
        local completed = 0
        for _, ach in ipairs(guildAchievements) do
            if ach.completed then
                completed = completed + 1
            end
        end
        
        table.insert(groups, {
            id = "guild",
            name = "Guild",
            achievements = guildAchievements,
            completed = completed,
            total = #guildAchievements,
            isGuildGroup = true,
        })
    end
    
    return groups
end

function achievementLogic:getFilteredAchievements()
    local groups = self:getGroupedAchievements()
    local filtered = {}
    
    for _, group in ipairs(groups) do
        local filteredAchievements = {}
        local filteredCompleted = 0
        
        for _, ach in ipairs(group.achievements) do
            if passesFilters(ach) then
                table.insert(filteredAchievements, ach)
                if ach.completed then
                    filteredCompleted = filteredCompleted + 1
                end
            end
        end
        
        -- Sort: incomplete first, then completed
        table.sort(filteredAchievements, function(a, b)
            if a.completed ~= b.completed then
                return not a.completed  -- incomplete (false) comes before completed (true)
            end
            return false  -- preserve original order within same completion status
        end)
        
        if #filteredAchievements > 0 then
            table.insert(filtered, {
                id = group.id,
                name = group.name,
                achievements = filteredAchievements,
                completed = filteredCompleted,
                total = #filteredAchievements,
                isGuildGroup = group.isGuildGroup,
            })
        end
    end
    
    return filtered
end

function achievementLogic:loadCategoryDetails(categoryId)
    loadCategoryDetails(categoryId)
end

function achievementLogic:areCategoryDetailsLoaded(categoryId)
    return detailsLoadedCategories[categoryId] == true
end

function achievementLogic:loadDetailsFor(achievement)
    loadAchievementDetails(achievement)
end

function achievementLogic:getRecentAchievements(days)
    days = days or (options and options:Get("recentAchievementDays")) or 14
    local cutoffTime = time() - (days * 24 * 60 * 60)
    local recent = {}
    
    if not cachedAchievements then return recent end
    
    for _, data in pairs(cachedAchievements) do
        for _, ach in ipairs(data.achievements) do
            if ach.completed and ach.completionTimestamp and ach.completionTimestamp >= cutoffTime then
                table.insert(recent, ach)
            end
        end
    end
    
    if guildAchievements then
        for _, ach in ipairs(guildAchievements) do
            if ach.completed and ach.completionTimestamp and ach.completionTimestamp >= cutoffTime then
                table.insert(recent, ach)
            end
        end
    end
    
    table.sort(recent, function(a, b)
        return (a.completionTimestamp or 0) > (b.completionTimestamp or 0)
    end)
    
    return recent
end

function achievementLogic:setStatusFilter(filterKey, enabled)
    statusFilters[filterKey] = enabled or nil
    
    if events then
        events:emit("ACHIEVEMENTS:FILTER_CHANGED", {
            filterType = "status",
            key = filterKey,
            enabled = enabled,
        })
    end
end

function achievementLogic:setSpecialtyFilter(filterKey, enabled)
    specialtyFilters[filterKey] = enabled or nil
    
    if events then
        events:emit("ACHIEVEMENTS:FILTER_CHANGED", {
            filterType = "specialty",
            key = filterKey,
            enabled = enabled,
        })
    end
end

function achievementLogic:getStatusFilters()
    return statusFilters
end

function achievementLogic:getSpecialtyFilters()
    return specialtyFilters
end

function achievementLogic:clearFilters()
    wipe(statusFilters)
    wipe(specialtyFilters)
    searchText = ""
    
    if events then
        events:emit("ACHIEVEMENTS:FILTER_CHANGED", { cleared = true })
    end
end

function achievementLogic:setSearchText(text)
    if searchText == text then return end
    
    searchText = text or ""
    
    if events then
        events:emit("ACHIEVEMENTS:FILTER_CHANGED", { searchText = searchText })
    end
end

function achievementLogic:getSearchText()
    return searchText
end

function achievementLogic:refresh()
    loadBasicData()
    
    if events then
        events:emit("ACHIEVEMENTS:DATA_REFRESHED", { timestamp = GetTime() })
    end
end

function achievementLogic:getAchievement(achievementId)
    if not cachedAchievements then return nil end
    
    for _, data in pairs(cachedAchievements) do
        for _, ach in ipairs(data.achievements) do
            if ach.id == achievementId then
                return ach
            end
        end
    end
    
    if guildAchievements then
        for _, ach in ipairs(guildAchievements) do
            if ach.id == achievementId then
                return ach
            end
        end
    end
    
    return nil
end

function achievementLogic:toggleTracking(achievementId)
    local isTracked = IsTrackedAchievement(achievementId)
    
    if isTracked then
        RemoveTrackedAchievement(achievementId)
    else
        local numTracked = GetNumTrackedAchievements()
        if numTracked >= achievementData.MAX_TRACKED then
            if utils then
                utils:chat("Cannot track more than " .. achievementData.MAX_TRACKED .. " achievements.")
            end
            return isTracked
        end
        AddTrackedAchievement(achievementId)
    end
    
    local ach = self:getAchievement(achievementId)
    if ach then
        ach.isTracked = not isTracked
    end
    
    return not isTracked
end

function achievementLogic:getTotalCounts()
    if not cachedAchievements then
        loadBasicData()
    end
    if not cachedAchievements then return 0, 0 end
    
    local completed = 0
    local total = 0
    
    for _, data in pairs(cachedAchievements) do
        completed = completed + data.completed
        total = total + data.total
    end
    
    if guildAchievements then
        for _, ach in ipairs(guildAchievements) do
            total = total + 1
            if ach.completed then
                completed = completed + 1
            end
        end
    end
    
    return completed, total
end

--[[
  Get counts from filtered achievements (respects current filters).
  @return number, number - completed, total (within filtered results)
]]
function achievementLogic:getFilteredCounts()
    local filtered = self:getFilteredAchievements()
    local completed = 0
    local total = 0
    
    for _, group in ipairs(filtered) do
        completed = completed + group.completed
        total = total + group.total
    end
    
    return completed, total
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

local function onAchievementEarned(event, achievementId)
    achievementLogic:refresh()
end

local function onCriteriaUpdate()
    -- Reset detailsLoaded on all guild achievements so they reload fresh
    if guildAchievements then
        for _, ach in ipairs(guildAchievements) do
            ach.detailsLoaded = false
        end
    end
    
    -- Mark categories as not loaded so next access refreshes
    for categoryId, loaded in pairs(detailsLoadedCategories) do
        if loaded then
            detailsLoadedCategories[categoryId] = false
        end
    end
    
    if events then
        events:emit("ACHIEVEMENTS:CRITERIA_UPDATED")
        events:emit("ACHIEVEMENTS:DATA_REFRESHED")
    end
end

local function onPetJournalUpdate()
    -- Pet journal loaded/updated - re-check pet rewards for guild achievements
    -- that might have failed detection earlier
    if guildAchievements then
        for _, ach in ipairs(guildAchievements) do
            if ach.isPetReward and not ach.speciesID and ach.rewardText then
                local petName = ach.rewardText:match("^Reward:%s*(.+)$")
                if petName then
                    local speciesID, petGUID = C_PetJournal.FindPetIDByName(petName)
                    if speciesID then
                        ach.speciesID = speciesID
                        ach.userOwnsPet = (petGUID ~= nil)
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function achievementLogic:initialize()
    if initialized then return true end
    
    achievementData = Addon.achievementData
    events = Addon.events
    utils = Addon.utils
    options = Addon.options
    
    if not achievementData then
        print("|cff33ff99PAO|r: |cffff4444Error - achievementLogic: achievementData not available|r")
        return false
    end
    
    if not events then
        print("|cff33ff99PAO|r: |cffff4444Error - achievementLogic: events not available|r")
        return false
    end
    
    events:subscribe("ACHIEVEMENT_EARNED", onAchievementEarned)
    events:subscribe("CRITERIA_UPDATE", onCriteriaUpdate)
    events:subscribe("PET_JOURNAL_LIST_UPDATE", onPetJournalUpdate)
    events:subscribe("TRACKED_ACHIEVEMENT_UPDATE", function()
        if cachedAchievements then
            for _, data in pairs(cachedAchievements) do
                for _, ach in ipairs(data.achievements) do
                    ach.isTracked = IsTrackedAchievement(ach.id)
                end
            end
        end
        if guildAchievements then
            for _, ach in ipairs(guildAchievements) do
                ach.isTracked = IsTrackedAchievement(ach.id)
            end
        end
    end)
    
    -- Don't load data here - defer until achievements tab is accessed
    -- This ensures pet journal is loaded for proper pet reward detection
    
    initialized = true
    return true
end

-- ============================================================================
-- MODULE REGISTRATION
-- ============================================================================

if Addon.registerModule then
    Addon.registerModule("achievementLogic", {"achievementData", "events", "utils", "options"}, function()
        return achievementLogic:initialize()
    end)
end

Addon.achievementLogic = achievementLogic
return achievementLogic