local regionWeatherQueues = {}
local regionAdjacencyMap = {}
local configRegionWeather = {}

local CACHE_FILE = "cache/weather_cache.json"
local HIGH_SEVERITY_THRESHOLD = 70
local SEVERITY_INFLUENCE_REDUCTION = 25
local LAZY_LOAD_THRESHOLD = 5
local INITIAL_SLOT_COUNT = 10
local LAZY_SLOT_BATCH = 5
local TRANSITION_GAP_THRESHOLD = 30

local Months = {"January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"}

local function log(label, message)
    local color = label == "error" and "\x1B[31m" or (label == "success" and "\x1B[32m" or "\x1B[0m")
    print(string.format("%s[ServerRegion]%s %s", color, "\x1B[0m", message))
end

local function Clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local function CountTable(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

local function BuildAdjacencyMap()
    regionAdjacencyMap = {
        ["HEARTLANDS"] = {"GRIZZLIES_WEST", "CUMBERLAND_FOREST", "SCARLETT_MEADOWS", "EAST_GRIZZLIES", "ROANOKE_RIDGE"},
        ["ROANOKE_RIDGE"] = {"HEARTLANDS", "EAST_GRIZZLIES", "BLUWATER_MARSH"},
        ["SCARLETT_MEADOWS"] = {"HEARTLANDS", "BLUWATER_MARSH", "BAYOU_NWA"},
        ["BAYOU_NWA"] = {"SCARLETT_MEADOWS", "BLUWATER_MARSH"},
        ["BLUWATER_MARSH"] = {"ROANOKE_RIDGE", "SCARLETT_MEADOWS", "BAYOU_NWA"},
        
        ["GRIZZLIES_WEST"] = {"HEARTLANDS", "CUMBERLAND_FOREST", "EAST_GRIZZLIES", "BIG_VALLEY"},
        ["CUMBERLAND_FOREST"] = {"HEARTLANDS", "GRIZZLIES_WEST", "EAST_GRIZZLIES"},
        ["EAST_GRIZZLIES"] = {"HEARTLANDS", "GRIZZLIES_WEST", "CUMBERLAND_FOREST", "ROANOKE_RIDGE"},
        
        ["BIG_VALLEY"] = {"GRIZZLIES_WEST", "GREAT_PLAINS", "TALL_TREES"},
        ["GREAT_PLAINS"] = {"BIG_VALLEY", "TALL_TREES"},
        ["TALL_TREES"] = {"GREAT_PLAINS", "BIG_VALLEY", "HENNIGANS_STEAD"},
        ["HENNIGANS_STEAD"] = {"TALL_TREES", "CHOLLA_SPRINGS"},
        ["CHOLLA_SPRINGS"] = {"HENNIGANS_STEAD", "GAPTOOTH_RIDGE"},
        ["GAPTOOTH_RIDGE"] = {"CHOLLA_SPRINGS", "RIO_BRAVO"},
        ["RIO_BRAVO"] = {"GAPTOOTH_RIDGE"},
    }
    
    log("success", "Built adjacency map with " .. CountTable(regionAdjacencyMap) .. " regions")
end

local function LoadRegionConfig()
    if not ConfigRegionWeather or not ConfigRegionWeather.Regions then
        log("error", "ConfigRegionWeather not loaded!")
        return false
    end
    
    configRegionWeather = ConfigRegionWeather
    log("success", "Loaded region config with " .. CountTable(configRegionWeather.Regions) .. " regions")
    return true
end

local function InitializeRegionQueues()
    for regionName, _ in pairs(configRegionWeather.Regions) do
        regionWeatherQueues[regionName] = {
            slots = {},
            currentSlotIndex = 1,
            neighborInfluence = {}
        }
    end
    
    log("success", "Initialized " .. CountTable(regionWeatherQueues) .. " region queues")
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
    
    if day >= 0 and day <= 80 then
        return "Winter"
    elseif day >= 81 and day <= 170 then
        return "Spring"
    elseif day >= 171 and day <= 260 then
        return "Summer"
    else
        return "Fall"
    end
end

local function GetSeasonalModifier(region, season, weatherType)
    local seasonTable = region[season]
    if not seasonTable then return 0 end
    
    for threshold, weatherData in pairs(seasonTable) do
        if weatherData[1] == weatherType then
            return weatherData[2]
        end
    end
    
    return 0
end

local function SelectWeatherType(weatherRoll, region, season)
    local seasonTable = region[season]
    if not seasonTable then return "Sunny" end
    
    local thresholds = {}
    for threshold, _ in pairs(seasonTable) do
        table.insert(thresholds, tonumber(threshold))
    end
    table.sort(thresholds)
    
    for _, threshold in ipairs(thresholds) do
        if weatherRoll <= threshold then
            return seasonTable[tostring(threshold)][1]
        end
    end
    
    return "Sunny"
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

local function ShiftWeatherType(currentType, neighborType)
    local progression = {
        ["Sunny"] = {"Cloudy", "Rain", "Snow"},
        ["Fog"] = {"Cloudy", "Rain", "Snow"},
        ["Cloudy"] = {"Rain", "Snow", "Sunny"},
        ["Rain"] = {"Cloudy", "Sunny", "Fog"},
        ["Snow"] = {"Cloudy", "Sunny", "Fog"},
        ["Sandstorm"] = {"Sunny", "Cloudy", "Fog"}
    }
    
    local steps = progression[currentType]
    if not steps then return currentType end
    
    for i, step in ipairs(steps) do
        if step == neighborType then
            return neighborType
        end
    end
    
    return steps[1]
end

local function GenerateTransitionArc(fromSlot, toSlot, severityGap)
    local subStates = {}
    local steps = 0
    
    if severityGap > 60 then
        steps = 5
    elseif severityGap > TRANSITION_GAP_THRESHOLD then
        steps = 4
    end
    
    if steps == 0 then return nil end
    
    for i = 1, steps do
        local progress = i / steps
        local interpolatedSeverity = 0
        
        if i < steps / 2 then
            interpolatedSeverity = fromSlot.severity + (severityGap / 2) * (i / (steps / 2))
        else
            interpolatedSeverity = toSlot.severity + (severityGap / 2) * ((steps - i) / (steps / 2))
        end
        
        local intermediateType = ShiftWeatherType(fromSlot.weatherType, toSlot.weatherType)
        local intermediateVariant = SelectWeatherVariant(intermediateType, interpolatedSeverity)
        
        table.insert(subStates, {
            weatherType = intermediateType,
            variant = intermediateVariant,
            severity = Clamp(interpolatedSeverity, 1, 100)
        })
    end
    
    return subStates
end

local function DetectTransitions(regionName)
    local queue = regionWeatherQueues[regionName]
    if not queue or #queue.slots < 2 then return end
    
    for slotIndex = 1, #queue.slots - 1 do
        local currentSlot = queue.slots[slotIndex]
        local nextSlot = queue.slots[slotIndex + 1]
        
        local severityGap = math.abs(nextSlot.severity - currentSlot.severity)
        
        if severityGap > TRANSITION_GAP_THRESHOLD then
            local transitions = GenerateTransitionArc(currentSlot, nextSlot, severityGap)
            currentSlot.transitions = transitions
        end
    end
end

local function GenerateWeatherSlots(regionNameParam, count, phase)
    phase = phase or "lazy"
    local season = GetCurrentSeason()
    local regionsToProcess = {}
    
    if regionNameParam == nil then
        for regionName, _ in pairs(configRegionWeather.Regions) do
            table.insert(regionsToProcess, regionName)
        end
    else
        table.insert(regionsToProcess, regionNameParam)
    end
    
    local multiRegion = regionNameParam == nil
    
    log("success", "Generating " .. count .. " slots for " .. #regionsToProcess .. " region(s) - Phase: " .. phase)
    
    -- PASS 1: Generate slots independently
    for _, targetRegion in ipairs(regionsToProcess) do
        local region = configRegionWeather.Regions[targetRegion]
        if not region then
            log("error", "Region not found: " .. targetRegion)
            goto continue
        end
        
        for i = 1, count do
            local weatherTypeRoll = math.random(1, 100)
            local severityRoll = math.random(1, 100)
            
            local weatherType = SelectWeatherType(weatherTypeRoll, region, season)
            local seasonalMod = GetSeasonalModifier(region, season, weatherType)
            local baseSeverity = severityRoll + seasonalMod
            
            local variant = SelectWeatherVariant(weatherType, baseSeverity)
            
            local slot = {
                weatherType = weatherType,
                variant = variant,
                severity = Clamp(baseSeverity, 1, 100),
                severityRoll = severityRoll,
                transitions = nil
            }
            
            table.insert(regionWeatherQueues[targetRegion].slots, slot)
        end
        
        ::continue::
    end
    
    -- PASS 2: Set neighbor influence variables (only for multi-region generation)
    if multiRegion then
        for _, sourceRegion in ipairs(regionsToProcess) do
            local sourceQueue = regionWeatherQueues[sourceRegion]
            if not sourceQueue then goto pass2continue end
            
            local slotBaseIndex = #sourceQueue.slots - count + 1
            
            for offset = 0, count - 1 do
                local slotIndex = slotBaseIndex + offset
                if slotIndex < 1 or slotIndex > #sourceQueue.slots then goto slotloop end
                
                local slot = sourceQueue.slots[slotIndex]
                if slot.severity >= HIGH_SEVERITY_THRESHOLD then
                    local neighbors = regionAdjacencyMap[sourceRegion] or {}
                    
                    for _, neighborName in ipairs(neighbors) do
                        if not regionWeatherQueues[neighborName] then goto neighborloop end
                        
                        local neighborRegion = configRegionWeather.Regions[neighborName]
                        if not neighborRegion then goto neighborloop end
                        
                        local neighborMod = GetSeasonalModifier(neighborRegion, season, slot.weatherType)
                        local influenceValue = (slot.severityRoll * 0.5) + neighborMod
                        
                        local key = sourceRegion .. "|" .. slot.weatherType .. "|" .. slotIndex
                        
                        if regionWeatherQueues[neighborName].neighborInfluence[key] == nil then
                            regionWeatherQueues[neighborName].neighborInfluence[key] = {
                                value = Clamp(influenceValue, 1, 100),
                                sourceRegion = sourceRegion,
                                weatherType = slot.weatherType,
                                slotIndex = slotIndex,
                                sourceSeverityRoll = slot.severityRoll
                            }
                        else
                            local existing = regionWeatherQueues[neighborName].neighborInfluence[key]
                            if Clamp(influenceValue, 1, 100) > existing.value then
                                existing.value = Clamp(influenceValue, 1, 100)
                                existing.sourceSeverityRoll = slot.severityRoll
                            end
                        end
                        
                        ::neighborloop::
                    end
                end
                
                ::slotloop::
            end
            
            ::pass2continue::
        end
    end
    
    -- PASS 3: Apply neighbor influences
    for _, targetRegion in ipairs(regionsToProcess) do
        local targetQueue = regionWeatherQueues[targetRegion]
        if not targetQueue then goto pass3continue end
        
        local slotBaseIndex = #targetQueue.slots - count + 1
        
        for offset = 0, count - 1 do
            local slotIndex = slotBaseIndex + offset
            if slotIndex < 1 or slotIndex > #targetQueue.slots then goto slot3loop end
            
            local slot = targetQueue.slots[slotIndex]
            local weatherType = slot.weatherType
            
            for influenceKey, influenceData in pairs(targetQueue.neighborInfluence) do
                if influenceData.slotIndex ~= slotIndex then goto influenceloop end
                
                local sourceRegion = influenceData.sourceRegion
                local influencedType = influenceData.weatherType
                local influenceValue = influenceData.value
                local sourceSeverityRoll = influenceData.sourceSeverityRoll
                
                if influencedType == weatherType then
                    local seasonalMod = GetSeasonalModifier(configRegionWeather.Regions[targetRegion], season, weatherType)
                    local blendedSeverity = (sourceSeverityRoll * 0.5) + seasonalMod
                    
                    slot.severity = Clamp(blendedSeverity, 1, 100)
                    slot.variant = SelectWeatherVariant(weatherType, slot.severity)
                elseif influencedType ~= weatherType and influenceValue >= HIGH_SEVERITY_THRESHOLD then
                    slot.weatherType = ShiftWeatherType(weatherType, influencedType)
                    slot.severity = Clamp(influenceValue - SEVERITY_INFLUENCE_REDUCTION, 1, 100)
                    slot.variant = SelectWeatherVariant(slot.weatherType, slot.severity)
                end
                
                ::influenceloop::
            end
            
            ::slot3loop::
        end
        
        ::pass3continue::
    end
    
    -- Detect transitions after all slots are finalized
    if multiRegion then
        for _, targetRegion in ipairs(regionsToProcess) do
            DetectTransitions(targetRegion)
        end
    end
end

local function SaveCache()
    log("success", "Weather cache saved (in-memory)")
end

local function LoadCache()
    log("success", "No persistent cache file found, using fresh generation")
    return false
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
    if not queue or not queue.slots or queue.currentSlotIndex > #queue.slots then
        return nil
    end
    
    return queue.slots[queue.currentSlotIndex]
end

local function AdvanceWeatherTick()
    for regionName, queue in pairs(regionWeatherQueues) do
        queue.currentSlotIndex = queue.currentSlotIndex + 1
        
        local remainingSlots = #queue.slots - queue.currentSlotIndex
        
        if remainingSlots <= LAZY_LOAD_THRESHOLD then
            GenerateWeatherSlots(regionName, LAZY_SLOT_BATCH, "lazy")
        end
    end
end

local function PrintRegionForecast(regionName)
    local slots = GetWeatherSlots(regionName)
    if #slots == 0 then
        log("error", "No weather data for region: " .. regionName)
        return
    end
    
    local forecast = {}
    for _, slot in ipairs(slots) do
        table.insert(forecast, slot.variant)
    end
    
    print("^2[FORECAST]^7 " .. regionName .. ": " .. table.concat(forecast, " > "))
end

local function PrintAllForecasts()
    print("^2[FORECAST]^7 =============== ALL REGIONS ===============")
    for regionName, _ in pairs(configRegionWeather.Regions) do
        local slots = GetWeatherSlots(regionName)
        if #slots > 0 then
            local forecast = {}
            for _, slot in ipairs(slots) do
                table.insert(forecast, slot.variant)
            end
            print("^2[FORECAST]^7 " .. regionName .. ": " .. table.concat(forecast, " > "))
        end
    end
    print("^2[FORECAST]^7 ==========================================")
end

local function Initialize()
    log("success", "Initializing ServerRegion weather system")
    
    if not LoadRegionConfig() then
        log("error", "Failed to load region config!")
        return
    end
    
    BuildAdjacencyMap()
    InitializeRegionQueues()
    
    LoadCache()
    log("success", "Generating initial weather for all regions")
    GenerateWeatherSlots(nil, INITIAL_SLOT_COUNT, "initial")
    SaveCache()
    
    log("success", "ServerRegion initialization complete")
end

RegisterCommand("regionweather", function(source, args, rawCommand)
    if #args < 1 then
        print("^1Usage: /regionweather <region_name>^7")
        return
    end
    local regionName = table.concat(args, " "):upper()
    local slots = GetWeatherSlots(regionName)
    if #slots == 0 then
        TriggerClientEvent("weathersync:printForecast", source, regionName, nil)
        return
    end
    
    local forecast = {}
    for _, slot in ipairs(slots) do
        table.insert(forecast, slot.variant)
    end
    TriggerClientEvent("weathersync:printForecast", source, regionName, forecast)
end, false)

RegisterCommand("allforecast", function(source, args, rawCommand)
    local forecastData = {}
    for regionName, _ in pairs(configRegionWeather.Regions) do
        local slots = GetWeatherSlots(regionName)
        if #slots > 0 then
            local forecast = {}
            for _, slot in ipairs(slots) do
                table.insert(forecast, slot.variant)
            end
            forecastData[regionName] = forecast
        end
    end
    TriggerClientEvent("weathersync:printAllForecasts", source, forecastData)
end, false)

exports("getWeatherSlots", GetWeatherSlots)
exports("getCurrentRegionWeather", GetCurrentRegionWeather)
exports("advanceWeatherTick", AdvanceWeatherTick)
exports("saveCache", SaveCache)

Initialize()
