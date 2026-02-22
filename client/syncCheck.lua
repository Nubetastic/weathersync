local syncCheckedTime = false
local syncCheckedWeather = false

CreateThread(function()
    while true do
        Wait(15000) -- Check every 15 seconds
        
        if syncEnabled then
            local now = GetGameTimer()
            local h = GetClockHours()
            local m = GetClockMinutes()

            -- Time Validation
            if timeStampTime > 0 then
                local timeDiff = math.abs((h * 60 + m) - (lastSyncedTime.hour * 60 + lastSyncedTime.minute))
                -- Wrap around 24h
                if timeDiff > 720 then timeDiff = 1440 - timeDiff end

                if timeDiff > 15 then
                    syncCheckedTime = false
                    if Config.Debug then
                        print(string.format("^1[SyncCheck] Time desync detected! Native: %02d:%02d, Synced: %02d:%02d (Diff: %d min)^7", h, m, lastSyncedTime.hour, lastSyncedTime.minute, timeDiff))
                    end
                    -- Re-apply last synced time
                    setTime(lastSyncedTime.hour, lastSyncedTime.minute, 0, 0, false)
                else
                    syncCheckedTime = true
                end
            end

            -- Weather Validation
            if timeStampWeather > 0 then
                -- Get current native weather hash
                local currentWeatherHash = GetPrevWeatherTypeHashName()
                local syncedWeatherHash = GetHashKey(lastSyncedWeather)

                if currentWeatherHash ~= syncedWeatherHash then
                    syncCheckedWeather = false
                    if Config.Debug then
                        print(string.format("^1[SyncCheck] Weather desync detected! Native Hash: %s, Synced: %s (%s)^7", tostring(currentWeatherHash), lastSyncedWeather, tostring(syncedWeatherHash)))
                    end
                    -- Trigger re-application
                    TriggerEvent("weathersync:changeWeather", lastSyncedWeather, 15.0, Config.permanentSnow)
                else
                    syncCheckedWeather = true
                end
            end

            -- Heartbeat Check (if no update for 2 minutes)
            if now - timeStampTime > 120000 or now - timeStampWeather > 120000 then
                if Config.Debug then
                    print("^3[SyncCheck] No sync update received for > 2 minutes. Requesting sync...^7")
                end
                TriggerServerEvent("weathersync:init")
            end
        end
    end
end)
