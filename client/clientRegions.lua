local currentRegion = nil
local lastValidRegion = nil
local regionWeatherQueues = {}
local regionCheckInterval = ConfigRegionWeather.RegionCheckInterval or 250
local transitionTime = ConfigRegionWeather.TransitionTime or 15.0
local transitionInProgress = false

local function log(label, message)
    local color = label == "error" and "^1" or (label == "success" and "^2" or "^7")
    print(string.format("%s[ClientRegion]^7 %s", color, message))
end

local function GetCurrentSeason()
    local success, result = pcall(function()
        return exports['weathersync']:getTime()
    end)
    
    if success and result then
        local day = result.day or 0
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
    
    return "Winter"
end

local function GetPlayerZoneHash(zoneTypeId, coords)
    local x, y, z
    if coords then
        x, y, z = coords.x, coords.y, coords.z
    else
        local ped = PlayerPedId()
        x, y, z = table.unpack(GetEntityCoords(ped))
    end
    return Citizen.InvokeNative(0x43AD8FC02B429D33, x, y, z, zoneTypeId)
end

local function FindRegionByHash(playerZoneHash)
    if type(playerZoneHash) ~= "number" or playerZoneHash == 0 then
        return nil, nil
    end
    
    for regionKey, regionData in pairs(ConfigRegionWeather.Regions) do
        if regionData.ZoneTypeId == 10 and regionData.RegionHash == playerZoneHash then
            return regionKey, regionData
        end
    end
    
    return nil, nil
end

local function SearchNearbyForRegion(maxDistance)
    local ped = PlayerPedId()
    local baseCoords = GetEntityCoords(ped)
    local searchDistance = 50
    
    for step = 1, maxDistance / searchDistance do
        local offsets = {
            {x = searchDistance * step, y = 0},
            {x = -searchDistance * step, y = 0},
            {x = 0, y = searchDistance * step},
            {x = 0, y = -searchDistance * step},
        }
        
        for _, offset in ipairs(offsets) do
            local testCoords = {x = baseCoords.x + offset.x, y = baseCoords.y + offset.y, z = baseCoords.z}
            local zoneHash = GetPlayerZoneHash(10, testCoords)
            local regionKey, regionData = FindRegionByHash(zoneHash)
            
            if regionKey and regionData then
                if ConfigRegionWeather.Debug then
                    log("success", "Found region via nearby search: " .. regionKey)
                end
                return regionKey, regionData
            end
        end
    end
    
    return nil, nil
end

local function GetPlayerRegion()
    local playerZoneHash = GetPlayerZoneHash(10)
    local regionKey, regionData = FindRegionByHash(playerZoneHash)
    
    if regionKey and regionData then
        lastValidRegion = {key = regionKey, data = regionData}
        return regionKey, regionData
    end
    
    if lastValidRegion then
        if ConfigRegionWeather.Debug then
            log("success", "Using cached region: " .. lastValidRegion.key)
        end
        return lastValidRegion.key, lastValidRegion.data
    end
    
    regionKey, regionData = SearchNearbyForRegion(500)
    if regionKey and regionData then
        lastValidRegion = {key = regionKey, data = regionData}
        return regionKey, regionData
    end
    
    return nil, nil
end

local function PrintRegionWeatherList()
    local zoneHash = GetPlayerZoneHash(10)
    local regionKey, regionData = GetPlayerRegion()
    
    print("^2[DEBUG]^7 Zone Hash (Type 10): ^3" .. tostring(zoneHash) .. "^7")
    
    if not regionKey or not regionData then
        log("error", "Unable to determine current region")
        print("^2[DEBUG]^7 Configured regions:")
        for rKey, rData in pairs(ConfigRegionWeather.Regions) do
            print("  - " .. rKey .. ": RegionHash=" .. tostring(rData.RegionHash) .. ", ZoneTypeId=" .. tostring(rData.ZoneTypeId))
        end
        return
    end
    
    local directMatch = FindRegionByHash(zoneHash)
    if not directMatch then
        print("^2[DEBUG]^7 Status: ^3Using Cached/Nearby Region^7")
    end
    
    local season = GetCurrentSeason()
    local seasonData = regionData[season]
    
    if not seasonData then
        log("error", "No weather data for season: " .. season)
        return
    end
    
    print("^2[WeatherSync]^7 Region: ^3" .. regionData.Name .. "^7 | Season: ^3" .. season .. "^7")
    print("^2[WeatherSync]^7 Available weather:")
    
    local thresholds = {}
    for threshold, _ in pairs(seasonData) do
        table.insert(thresholds, tonumber(threshold))
    end
    table.sort(thresholds)
    
    for _, threshold in ipairs(thresholds) do
        local weatherData = seasonData[tostring(threshold)]
        local weatherType = weatherData[1]
        local tempMod = weatherData[2]
        local tempStr = tempMod >= 0 and "+" .. tempMod or tostring(tempMod)
        print("  ^2≤" .. threshold .. "%^7: ^3" .. weatherType .. "^7 (Temp: " .. tempStr .. ")")
    end
end

local function ApplyRegionalWeather(regionName, weatherGroup, weatherVariant, isRegionChange)
    if not weatherVariant then
        return
    end
    
    local isSnowyWeatherVariant = weatherGroup == "Snow"
    local transition = isRegionChange and transitionTime or 5.0
    
    if ConfigRegionWeather.Debug then
        log("success", "Applying weather: " .. weatherVariant .. " (" .. weatherGroup .. ") in region: " .. regionName .. " (transition: " .. transition .. "s)")
    end
    
    if isSnowyWeatherVariant and isRegionChange then
        TriggerEvent("weathersync:setMyWeather", weatherVariant, transition, false)
        Citizen.SetTimeout(transitionTime * 1000, function()
            TriggerEvent("weathersync:setMyWeather", weatherVariant, 0.1, true)
        end)
    else
        TriggerEvent("weathersync:setMyWeather", weatherVariant, transition, isSnowyWeatherVariant)
    end
end

local function UpdateRegionalWeather(regionName, isRegionChange)
    if not regionWeatherQueues[regionName] or #regionWeatherQueues[regionName] == 0 then
        return
    end
    
    local currentSlot = regionWeatherQueues[regionName][1]
    if currentSlot then
        ApplyRegionalWeather(regionName, currentSlot.weatherType, currentSlot.variant, isRegionChange)
    end
end

local function OnRegionalWeatherUpdate(regionName, slots)
    regionWeatherQueues[regionName] = slots
    if ConfigRegionWeather.Debug then
        log("success", "Updated weather queue for region: " .. regionName .. " with " .. #slots .. " slots")
    end
    
    if currentRegion == regionName then
        UpdateRegionalWeather(regionName, true)
    end
end

local function OnRegionChange(newRegion, oldRegion)
    if transitionInProgress then
        return
    end
    
    transitionInProgress = true
    
    if ConfigRegionWeather.Debug then
        if oldRegion then
            log("success", "Left region: " .. oldRegion)
        end
        log("success", "Entered region: " .. newRegion .. " (starting smooth transition)")
    end
    currentRegion = newRegion
    
    TriggerServerEvent("weathersync:requestRegionalWeather", newRegion)
    
    Citizen.SetTimeout(transitionTime * 1000, function()
        transitionInProgress = false
    end)
end

local function RegionCheckThread()
    while true do
        local regionKey, regionData = GetPlayerRegion()
        
        if regionKey then
            if currentRegion ~= regionKey then
                OnRegionChange(regionKey, currentRegion)
            end
        end
        
        Citizen.Wait(regionCheckInterval)
    end
end

RegisterNetEvent("weathersync:updateRegionalWeather")
AddEventHandler("weathersync:updateRegionalWeather", function(regionName, slots)
    OnRegionalWeatherUpdate(regionName, slots)
end)

RegisterNetEvent("weathersync:loadRegionalWeather", function()
    if ConfigRegionWeather.Debug then
        log("success", "Initializing regional weather system")
    end
    
    Citizen.CreateThread(function()
        Citizen.Wait(500)
        local regionKey, regionData = GetPlayerRegion()
        
        if regionKey then
            OnRegionChange(regionKey, nil)
        end
    end)
    
    Citizen.CreateThread(RegionCheckThread)
end)

Citizen.CreateThread(function()
    Citizen.Wait(1000)
    
    TriggerEvent("chat:addSuggestion", "/regionweather", "Debug: Print available weather for current region", {})
    TriggerEvent("chat:addSuggestion", "/debugregion", "Debug: Print current region and zone hash info", {})
    
    RegisterCommand("regionweather", function(source, args, rawCommand)
        PrintRegionWeatherList()
    end)
    
    RegisterCommand("debugregion", function(source, args, rawCommand)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local zoneHash = GetPlayerZoneHash(10)
        local regionKey, regionData = GetPlayerRegion()
        
        print("^2[DEBUG] Region Information:^7")
        print("  Player Coords: ^3" .. string.format("%.2f, %.2f, %.2f", pos.x, pos.y, pos.z) .. "^7")
        print("  Zone Hash (Type 10): ^3" .. tostring(zoneHash) .. "^7")
        
        if regionKey and regionData then
            print("  ^2✓ Region Detected: ^3" .. regionKey .. "^7 (" .. regionData.Name .. ")")
            print("  Region Hash: ^3" .. tostring(regionData.RegionHash) .. "^7")
            print("  Zone Type ID: ^3" .. tostring(regionData.ZoneTypeId) .. "^7")
            
            if lastValidRegion and lastValidRegion.key == regionKey then
                local directMatch = FindRegionByHash(zoneHash)
                if not directMatch then
                    print("  ^3[Using Cached Region]^7")
                end
            end
        else
            print("  ^1✗ No region detected^7")
            print("  Checking all configured regions:")
            for rKey, rData in pairs(ConfigRegionWeather.Regions) do
                print("    - " .. rKey .. ": hash=" .. tostring(rData.RegionHash) .. ", zoneType=" .. tostring(rData.ZoneTypeId))
            end
        end
    end)
    
    TriggerEvent("weathersync:loadRegionalWeather")
end)

exports("printRegionWeatherList", PrintRegionWeatherList)
exports("getCurrentRegion", function() return currentRegion end)
