local currentRegion = nil
local lastRegion = nil

local RegionsHash = ConfigRegionWeather and ConfigRegionWeather.RegionsHash or {}

local function GetPlayerRegion()
    local zoneHash = GetMapZoneAtCoords(GetEntityCoords(PlayerPedId()), 10)
    local regionName = RegionsHash[zoneHash]
    
    if regionName then
        return regionName
    end
    
    return lastRegion
end

RegisterNetEvent("weathersync:updateRegionalWeather")
AddEventHandler("weathersync:updateRegionalWeather", function(weatherData)
    if weatherData then
        TriggerEvent("weathersync:applyRegionalWeather", weatherData)
    end
end)

CreateThread(function()
    Wait(1000)
    
    while true do
        Wait(ConfigRegionWeather.RegionCheckInterval)
        
        currentRegion = GetPlayerRegion()
        
        if currentRegion ~= lastRegion then
            lastRegion = currentRegion
            if Config.Debug then
                print("weathersync: Player region changed to " .. tostring(currentRegion))
            end
            if currentRegion then
                TriggerServerEvent("weathersync:playerRegionChanged", currentRegion)
            end
        end
    end
end)
