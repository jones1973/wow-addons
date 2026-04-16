-- core/dependencies.lua - Module Dependency Resolution System
local ADDONNAME, Addon = ...

-- Lazy-load utils - it doesn't exist yet at file load time
local utils = nil

-- Module registry for dependency resolution
local moduleRegistry = {}
local initializedModules = {}
local initializationInProgress = {}

-- Pre-initialized modules (load before dependency system)
local PREINIT_MODULES = {"events"}
for _, name in ipairs(PREINIT_MODULES) do
    initializedModules[name] = true
end

-- Helper function for missing dependency errors
local function reportMissingDependency(moduleName, missingDep)
    utils:error(("Module '%s' depends on missing module '%s'"):format(moduleName, missingDep))
end

-- Register a module with dependencies
function Addon.registerModule(name, dependencies, initFunc)
    if moduleRegistry[name] then
        print(string.format("|cff33ff99" .. ADDONNAME .. "|r: Module '%s' already registered", name))
        return
    end
    
    moduleRegistry[name] = {
        name = name,
        deps = dependencies or {},
        init = initFunc,
        initialized = false
    }
end

-- Detect circular dependencies using DFS
local function detectCircularDependencies(modules)
    local visited = {}
    local temp = {}
    local cycles = {}
    
    local function visit(name)
        if temp[name] then
            local cycle = name
            table.insert(cycles, "Circular dependency: " .. cycle)
            return
        end
        
        if visited[name] then return end
        
        temp[name] = true
        
        local module = modules[name]
        if module and module.deps then
            for _, dep in ipairs(module.deps) do
                if modules[dep] or initializedModules[dep] then
                    -- Module exists in registry or is pre-initialized
                    if modules[dep] then
                        visit(dep)
                    end
                else
                    reportMissingDependency(name, dep)
                end
            end
        end
        
        temp[name] = nil
        visited[name] = true
    end
    
    for moduleName in pairs(modules) do
        if not visited[moduleName] then
            visit(moduleName)
        end
    end
    
    return cycles
end

-- Topological sort for dependency-ordered initialization
local function topologicalSort(modules)
    local visited = {}
    local temp = {}
    local sorted = {}
    
    local function visit(name)
        if temp[name] then
            -- Circular dependency - skip
            return
        end
        
        if visited[name] then return end
        
        temp[name] = true
        
        local module = modules[name]
        if module and module.deps then
            for _, dep in ipairs(module.deps) do
                if modules[dep] or initializedModules[dep] then
                    -- Module exists in registry or is pre-initialized
                    if modules[dep] then
                        visit(dep)
                    end
                else
                    reportMissingDependency(name, dep)
                end
            end
        end
        
        temp[name] = nil
        visited[name] = true
        table.insert(sorted, name)
    end
    
    for moduleName in pairs(modules) do
        if not visited[moduleName] then
            visit(moduleName)
        end
    end
    
    return sorted
end

-- Initialize a single module with dependency checking
local function initModule(name)
    if initializedModules[name] then
        return true
    end
    
    if initializationInProgress[name] then
        utils:error(("Circular dependency detected during initialization of '%s'"):format(name))
        return false
    end
    
    local module = moduleRegistry[name]
    if not module then
        utils:error(("Module '%s' not found in registry"):format(name))
        return false
    end
    
    initializationInProgress[name] = true
    
    -- Check dependencies are initialized
    for _, dep in ipairs(module.deps) do
        if not initializedModules[dep] then
            utils:error(("Module '%s' dependency '%s' not yet initialized"):format(name, dep))
            initializationInProgress[name] = nil
            return false
        end
    end
    
    local success = true
    if module.init then
        local ok, result = pcall(module.init)
        if not ok then
            utils:error(("Error initializing module '%s': %s"):format(name, tostring(result)))
            success = false
        else
            success = result ~= false
        end
    end
    
    initializationInProgress[name] = nil
    
    if success then
        initializedModules[name] = true
        module.initialized = true
    end
    
    return success
end

-- Main dependency-aware initialization
local function initializeAllModules()
    -- NOW we can safely get utils reference
    utils = Addon.utils
    
    -- Check for circular dependencies
    local cycles = detectCircularDependencies(moduleRegistry)
    if #cycles > 0 then
        utils:error("Circular dependencies detected:")
        for _, cycle in ipairs(cycles) do
            utils:error("  " .. cycle)
        end
        utils:error("Initialization aborted due to circular dependencies")
        return false
    end
    
    -- Get initialization order
    local initOrder = topologicalSort(moduleRegistry)
    
    -- Initialize modules in dependency order
    local successCount = 0
    local totalCount = #initOrder
    
    for _, moduleName in ipairs(initOrder) do
        if initModule(moduleName) then
            successCount = successCount + 1
        end
    end
    
    if successCount == totalCount then
        local successMsg = ("All %d modules initialized successfully"):format(totalCount)
        utils:debug(successMsg)
        return true
    else
        local errorMsg = ("Initialization completed with errors: %d/%d modules initialized"):format(
            successCount, totalCount)
        utils:error(errorMsg)
        return false
    end
end

-- Export functions for debugging
Addon.debugDependencies = function()
    utils:chat("=== Module Registry Debug ===")
    
    -- Show pre-initialized modules
    utils:chat("Pre-initialized: " .. table.concat(PREINIT_MODULES, ", "))
    
    for name, module in pairs(moduleRegistry) do
        local status = initializedModules[name] and "✓" or "✗"
        local deps = #module.deps > 0 and table.concat(module.deps, ", ") or "none"
        utils:chat(("%s %s (deps: %s)"):format(status, name, deps))
    end
end

-- Export for main.lua to call directly and for debug access
Addon.dependency = {
    initializeAllModules = initializeAllModules,
    debugDependencies = Addon.debugDependencies
}