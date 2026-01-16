local regionWeatherQueues = {}
local configRegionWeather = {}
local configRegions = {}
local processedThresholds = {}
local cacheTimestamp = 0

local UPDATE_INTERVAL = 900000
local QUEUE_MAX_SIZE = 8
local HIGH_SEVERITY_THRESHOLD = 70
local INFLUENCE_MAX_DISTANCE = 3
local INFLUENCE_SEVERITY_REDUCTION = 20
local MAX_RIPPLE_PASSES = 3

local dayLength = 86400
local weekLength = 604800

local currentWeather = Config.weather
local weatherIsFrozen = Config.weatherIsFrozen
local permanentSnow = Config.permanentSnow
local currentWindDirection = Config.windDirection
local currentWindSpeed = Config.windSpeed
local windIsFrozen = Config.windIsFrozen

local function log(label, message)
    local color = label == "error" and "\x1B[31m" or (label == "success" and "\x1B[32m" or "\x1B[0m")
    print(string.format("%s[RegionWeather]%s %s", color, "\x1B[0m", message))
end

local function Clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function GetCurrentSeason()
    local time = {}
    local success, result = pcall(function()
        return exports['weathersync']:getTime()
    end)
    
    if success and result then
        time = result
    else
        time = {day = 0}
    end
    
    local day = time.day or 0
    local season

    if configRegionWeather.Hemisphere then
        if day >= 0 and day <= 80 then
            season = "Winter"
        elseif day >= 81 and day <= 170 then
            season = "Spring"
        elseif day >= 171 and day <= 260 then
            season = "Summer"
        else
            season = "Fall"
        end
    else
        if day >= 0 and day <= 80 then
            season = "Summer"
        elseif day >= 81 and day <= 170 then
            season = "Fall"
        elseif day >= 171 and day <= 260 then
            season = "Winter"
        else
            season = "Spring"
        end
    end
    
    return season
end

local function PreProcessConfigThresholds()
    for regionName, regionData in pairs(configRegionWeather.Regions) do
        processedThresholds[regionName] = {}
        
        for season, seasonData in pairs(regionData) do
            if season ~= "RegionHash" and season ~= "ZoneTypeId" and season ~= "Name" then
                local thresholds = {}
                local weathers = {}
                
                for thresholdStr, weatherData in pairs(seasonData) do
                    local threshold = tonumber(thresholdStr)
                    if threshold then
                        table.insert(thresholds, threshold)
                        weathers[threshold] = weatherData[1]
                    end
                end
                
                table.sort(thresholds)
                processedThresholds[regionName][season] = {
                    thresholds = thresholds,
                    weathers = weathers,
                    modifiers = {}
                }
                
                for thresholdStr, weatherData in pairs(seasonData) do
                    local threshold = tonumber(thresholdStr)
                    if threshold then
                        processedThresholds[regionName][season].modifiers[threshold] = weatherData[2]
                    end
                end
            end
        end
    end
    
    log("success", "Pre-processed thresholds for " .. Clamp(#processedThresholds, 1, 999) .. " regions")
end

local function SelectWeatherType(roll, region, season)
    local thresholdData = processedThresholds[region] and processedThresholds[region][season]
    if not thresholdData then return "Sunny" end
    
    for _, threshold in ipairs(thresholdData.thresholds) do
        if roll <= threshold then
            return thresholdData.weathers[threshold]
        end
    end
    
    return "Sunny"
end

local function GetSeasonalModifier(region, season, weatherType)
    local regionData = configRegionWeather.Regions[region]
    if not regionData then return 0 end
    
    local seasonTable = regionData[season]
    if not seasonTable then return 0 end
    
    for threshold, weatherData in pairs(seasonTable) do
        if tonumber(threshold) and weatherData[1] == weatherType then
            return weatherData[2]
        end
    end
    
    return 0
end

local function SelectWeatherVariant(weatherType, severity)
    local brackets = configRegionWeather.WeatherGroups[weatherType]
    if not brackets then return weatherType end
    
    local thresholds = {}
    for threshold, _ in pairs(brackets) do
        table.insert(thresholds, tonumber(threshold))
    end
    table.sort(thresholds)
    
    for _, threshold in ipairs(thresholds) do
        if severity <= threshold then
            return brackets[tostring(threshold)]
        end
    end
    
    return brackets["100"] or weatherType
end

local function InitializeRegionQueues()
    for regionName, _ in pairs(configRegionWeather.Regions) do
        regionWeatherQueues[regionName] = {
            slots = {},
            currentIndex = 1
        }
    end
    
    log("success", "Initialized " .. Clamp(#regionWeatherQueues, 1, 999) .. " region queues")
end

local function GenerateBaseWeatherSlot(regionName, season)
    local region = configRegionWeather.Regions[regionName]
    if not region then return nil end
    
    local weatherTypeRoll = math.random(1, 100)
    local severityRoll = math.random(1, 100)
    
    local weatherType = SelectWeatherType(weatherTypeRoll, regionName, season)
    local seasonalMod = GetSeasonalModifier(regionName, season, weatherType)
    local baseSeverity = severityRoll + seasonalMod
    
    baseSeverity = Clamp(baseSeverity, 1, 100)
    local variant = SelectWeatherVariant(weatherType, baseSeverity)
    
    local initialModifier = 0
    if (weatherType == "Rain" or weatherType == "Snow") and baseSeverity >= HIGH_SEVERITY_THRESHOLD then
        initialModifier = baseSeverity
    end
    
    return {
        weatherType = weatherType,
        variant = variant,
        severity = baseSeverity,
        severityRoll = severityRoll,
        initialModifier = initialModifier,
        processedModifier = nil,
        weatherUpdated = false
    }
end

local function ProcessWeatherRipple()
    local adjacency = configRegionWeather.regionAdjacencyMap
    if not adjacency then return end
    
    local passNumber = 0
    local anyModifiersApplied = true
    
    while passNumber < MAX_RIPPLE_PASSES and anyModifiersApplied do
        anyModifiersApplied = false
        local modifiersToApply = {}
        
        for regionName, queue in pairs(regionWeatherQueues) do
            local lastSlot = queue.slots[#queue.slots]
            if not lastSlot then goto nextRegion end
            
            if lastSlot.initialModifier == 0 or lastSlot.initialModifier == -1 then
                goto nextRegion
            end
            
            local neighbors = adjacency[regionName] or {}
            for _, neighborName in ipairs(neighbors) do
                local neighborQueue = regionWeatherQueues[neighborName]
                if not neighborQueue then goto nextNeighbor end
                
                local neighborSlot = neighborQueue.slots[#neighborQueue.slots]
                if not neighborSlot then goto nextNeighbor end
                
                if neighborSlot.initialModifier >= HIGH_SEVERITY_THRESHOLD then
                    goto nextNeighbor
                end
                
                if neighborSlot.initialModifier == -1 then
                    goto nextNeighbor
                end
                
                local minVal = math.floor(lastSlot.initialModifier / 2)
                local maxVal = lastSlot.initialModifier - INFLUENCE_SEVERITY_REDUCTION
                local neighborModifier = math.random(minVal, maxVal)
                neighborModifier = Clamp(neighborModifier, 0, 100)
                
                if neighborModifier > 0 then
                    if modifiersToApply[neighborName] == nil then
                        modifiersToApply[neighborName] = {}
                    end
                    table.insert(modifiersToApply[neighborName], neighborModifier)
                    anyModifiersApplied = true
                end
                
                ::nextNeighbor::
            end
            
            lastSlot.initialModifier = -1
            
            ::nextRegion::
        end
        
        for regionName, modifierList in pairs(modifiersToApply) do
            local totalModifier = 0
            for _, mod in ipairs(modifierList) do
                totalModifier = totalModifier + mod
            end
            
            local avgModifier = totalModifier / #modifierList
            local queue = regionWeatherQueues[regionName]
            if queue then
                local lastSlot = queue.slots[#queue.slots]
                if lastSlot then
                    lastSlot.processedModifier = avgModifier
                    lastSlot.weatherUpdated = true
                end
            end
        end
        
        for regionName, queue in pairs(regionWeatherQueues) do
            local lastSlot = queue.slots[#queue.slots]
            if lastSlot and lastSlot.weatherUpdated then
                local modifier = lastSlot.processedModifier
                local sourceWeatherType = "Snow"
                
                lastSlot.weatherType = sourceWeatherType
                lastSlot.severity = Clamp(modifier, 1, 100)
                lastSlot.variant = SelectWeatherVariant(sourceWeatherType, lastSlot.severity)
                lastSlot.initialModifier = -1
                lastSlot.weatherUpdated = false
                
                anyModifiersApplied = true
            end
        end
        
        passNumber = passNumber + 1
    end
end

local function UpdateCacheTimestamp()
    cacheTimestamp = os.time()
end

local function AddWeatherSlot(regionName, slot)
    local queue = regionWeatherQueues[regionName]
    if not queue then return end
    
    table.insert(queue.slots, slot)
    
    if #queue.slots > QUEUE_MAX_SIZE then
        table.remove(queue.slots, 1)
        queue.currentIndex = math.max(1, queue.currentIndex - 1)
    end
end

local function GenerateNewWeatherSlots()
    local season = GetCurrentSeason()
    
    for regionName, queue in pairs(regionWeatherQueues) do
        local baseSlot = GenerateBaseWeatherSlot(regionName, season)
        if baseSlot then
            AddWeatherSlot(regionName, baseSlot)
        end
    end
    
    ProcessWeatherRipple()
end

local function AdvanceRegionalWeather()
    for regionName, queue in pairs(regionWeatherQueues) do
        queue.currentIndex = queue.currentIndex + 1
        if queue.currentIndex > #queue.slots then
            queue.currentIndex = #queue.slots
        end
    end
    
    GenerateNewWeatherSlots()
    UpdateCacheTimestamp()
end

local function GetWeatherSlots(regionName)
    if not regionWeatherQueues[regionName] then
        log("error", "Region not found: " .. regionName)
        return {}
    end
    
    return regionWeatherQueues[regionName].slots
end

local function GetCurrentRegionWeather(regionName)
    local queue = regionWeatherQueues[regionName]
    if not queue or not queue.slots or queue.currentIndex > #queue.slots then
        return nil
    end
    
    return queue.slots[queue.currentIndex]
end

local function BuildCache()
    local cache = {
        timestamp = cacheTimestamp,
        regions = {}
    }
    
    for regionName, queue in pairs(regionWeatherQueues) do
        cache.regions[regionName] = {
            currentIndex = queue.currentIndex,
            slots = queue.slots
        }
    end
    
    return cache
end

local function ValidateConfiguration()
    if not ConfigRegionWeather or not ConfigRegionWeather.Regions then
        log("error", "ConfigRegionWeather not loaded!")
        return false
    end
    
    if not ConfigRegionWeather.regionAdjacencyMap then
        log("error", "regionAdjacencyMap not defined in ConfigRegionWeather!")
        return false
    end
    
    if not ConfigRegionWeather.WeatherGroups then
        log("error", "WeatherGroups not defined in ConfigRegionWeather!")
        return false
    end
    
    return true
end

local function Initialize()
    log("success", "Initializing regional weather system")
    
    if not ValidateConfiguration() then
        log("error", "Configuration validation failed!")
        return false
    end
    
    configRegionWeather = ConfigRegionWeather
    
    PreProcessConfigThresholds()
    InitializeRegionQueues()
    
    log("success", "Generating initial weather for all regions")
    for i = 1, 8 do
        GenerateNewWeatherSlots()
    end
    
    UpdateCacheTimestamp()
    log("success", "Regional weather system initialization complete")
    return true
end

exports("getRegionalWeather", function(regionName)
    return GetCurrentRegionWeather(regionName)
end)

exports("getRegionalWeatherSlots", function(regionName)
    return GetWeatherSlots(regionName)
end)

if Initialize() then
    Citizen.CreateThread(function()
        local lastUpdate = 0
        
        while true do
            Citizen.Wait(1000)
            
            local now = GetGameTimer()
            if now - lastUpdate >= UPDATE_INTERVAL then
                AdvanceRegionalWeather()
                lastUpdate = now
            end
        end
    end)
else
    log("error", "Failed to initialize regional weather system")
end
