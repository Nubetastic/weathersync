local currentTime = Config.time
local currentTimescale = Config.timescale
local timeIsFrozen = Config.timeIsFrozen
local maxForecast = Config.maxForecast
local syncDelay = Config.syncDelay

local playerRegions = {}

local dayLength = 86400
local weekLength = 604800

local logColors = {
	["default"] = "\x1B[0m",
	["error"] = "\x1B[31m",
	["success"] = "\x1B[32m"
}

RegisterNetEvent("weathersync:init")
RegisterNetEvent("weathersync:playerRegionChanged")
RegisterNetEvent("weathersync:requestUpdatedForecast")
RegisterNetEvent("weathersync:requestRegionForecast")
RegisterNetEvent("weathersync:requestAllForecasts")
RegisterNetEvent("weathersync:requestUpdatedAdminUi")
RegisterNetEvent("weathersync:setTime")
RegisterNetEvent("weathersync:resetTime")
RegisterNetEvent("weathersync:setTimescale")
RegisterNetEvent("weathersync:resetTimescale")
RegisterNetEvent("weathersync:setSyncDelay")
RegisterNetEvent("weathersync:resetSyncDelay")

local function contains(t, x)
	for _, v in pairs(t) do
		if v == x then
			return true
		end
	end
	return false
end

local function printMessage(target, message)
	if target and target > 0 then
		TriggerClientEvent("chat:addMessage", target, message)
	else
		print(table.concat(message.args, ": "))
	end
end

local function log(label, message)
	local color = logColors[label]

	if not color then
		color = logColors.default
	end

	print(string.format("%s[%s]%s %s", color, label, logColors.default, message))
end

local function setTime(d, h, m, s, t, f)
	TriggerClientEvent("weathersync:changeTime", -1, h, m, s, t, f)
	currentTime = DHMSToTime(d, h, m, s)
	timeIsFrozen = f
end

local function resetTime()
	currentTime = Config.time
	timeIsFrozen = Config.timeIsFrozen
end

local function getTime()
	local d, h, m, s = TimeToDHMS(currentTime)
	return {day = d, hour = h, minute = m, second = s}
end

local function setTimescale(scale)
	TriggerClientEvent("weathersync:changeTimescale", -1, scale)
	currentTimescale = scale
end

local function resetTimescale()
	currentTimescale = Config.timescale
end

local function setSyncDelay(delay)
	syncDelay = delay
end

local function resetSyncDelay()
	syncDelay = Config.syncDelay
end



local function createForecast(regionName)
	local forecast = {}
	
	if not regionName then
		return forecast
	end
	
	local success, slots = pcall(function()
		return exports['weathersync']:getRegionalWeatherSlots(regionName)
	end)
	
	if not success or not slots then
		return forecast
	end
	
	for i = 1, math.min(#slots, maxForecast) do
		local slot = slots[i]
		if slot then
			local slotStartTime = (currentTime + ((i - 1) * Config.weatherInterval)) % weekLength
			local d, h, m, s = TimeToDHMS(slotStartTime)
			table.insert(forecast, {day = d, hour = h, minute = m, second = s, weather = slot.variant or slot.weatherType, wind = 0})
		end
	end

	return forecast
end

local function syncTime(player, tick)
	-- Ensure time doesn"t wrap around when transitioning from ~23:59:59 to ~00:00:00
	local timeTransition = ((dayLength - (currentTime % dayLength) + tick) % dayLength <= tick and 0 or syncDelay)
	local day, hour, minute, second = TimeToDHMS(currentTime)
	TriggerClientEvent("weathersync:changeTime", player, hour, minute, second, timeTransition, timeIsFrozen)
end

local function syncTimescale(player)
	TriggerClientEvent("weathersync:changeTimescale", player, currentTimescale)
end

local function syncWeather(player)
	local region = playerRegions[player] or playerRegions[-1]
	if not region then return end
	
	local success, weatherData = pcall(function()
		return exports['weathersync']:getRegionalWeather(region)
	end)
	
	if success and weatherData then
		TriggerClientEvent("weathersync:updateRegionalWeather", player, weatherData)
	end
end

exports("getTime", getTime)
exports("setTime", setTime)
exports("resetTime", resetTime)
exports("setTimescale", setTimescale)
exports("resetTimescale", resetTimescale)
exports("setSyncDelay", setSyncDelay)
exports("resetSyncDelay", resetSyncDelay)
exports("getForecast", function(regionName)
	return createForecast(regionName)
end)

AddEventHandler("weathersync:setTime", setTime)
AddEventHandler("weathersync:resetTime", resetTime)
AddEventHandler("weathersync:setTimescale", setTimescale)
AddEventHandler("weathersync:resetTimescale", resetTimescale)
AddEventHandler("weathersync:setSyncDelay", setSyncDelay)
AddEventHandler("weathersync:resetSyncDelay", resetSyncDelay)

AddEventHandler("weathersync:requestUpdatedForecast", function()
	local region = playerRegions[source]
	if region then
		TriggerClientEvent("weathersync:updateForecast", source, createForecast(region))
	end
end)

AddEventHandler("weathersync:requestRegionForecast", function(regionName)
	if regionName then
		local forecast = createForecast(regionName)
		if forecast and #forecast > 0 then
			TriggerClientEvent("weathersync:receiveRegionForecast", source, regionName, forecast)
		end
	end
end)

AddEventHandler("weathersync:requestAllForecasts", function()
	local regions = ConfigRegionWeather and ConfigRegionWeather.Regions or {}
	local allForecasts = {}
	
	for regionName, _ in pairs(regions) do
		allForecasts[regionName] = createForecast(regionName)
	end
	
	TriggerClientEvent("weathersync:receiveAllForecasts", source, allForecasts)
end)

AddEventHandler("weathersync:requestUpdatedAdminUi", function()
	TriggerClientEvent("weathersync:updateAdminUi", source, currentTime, currentTimescale, syncDelay)
end)

AddEventHandler("weathersync:init", function()
	syncTime(source, 0)
	syncTimescale(source)
end)

AddEventHandler("weathersync:playerRegionChanged", function(region)
	playerRegions[source] = region
	syncWeather(source)
end)

AddEventHandler("playerDropped", function(reason)
	playerRegions[source] = nil
end)



RegisterCommand("time", function(source, args, raw)
	if #args > 0 then
		local d = tonumber(args[1]) or 0
		local h = tonumber(args[2]) or 0
		local m = tonumber(args[3]) or 0
		local s = tonumber(args[4]) or 0
		local t = tonumber(args[5]) or 0
		local f = args[6] == "1"

		setTime(d, h, m, s, t, f)
	else
		local d, h, m, s = TimeToDHMS(currentTime)
		printMessage(source, {color = {255, 255, 128}, args = {"Time", string.format("%s %.2d:%.2d:%.2d", GetDayOfWeek(d), h, m, s)}})
	end
end, true)

RegisterCommand("timescale", function(source, args, raw)
	if args[1] then
		setTimescale(tonumber(args[1]) + 0.0)
	else
		printMessage(source, {color = {255, 255, 128}, args = {"Timescale", currentTimescale}})
	end
end, true)

RegisterCommand("syncdelay", function(source, args, raw)
	if args[1] then
		setSyncDelay(tonumber(args[1]))
	else
		printMessage(source, {color = {255, 255, 128}, args = {"Sync delay", SyncDelay}})
	end
end, true)



RegisterCommand("weatherui", function(source, args, raw)
	TriggerClientEvent("weathersync:openAdminUi", source)
end, true)

RegisterCommand("weathersync", function(source, args, raw)
	TriggerClientEvent("weathersync:toggleSync", source)
end, true)

RegisterCommand("mytime", function(source, args, raw)
	local h = (args[1] and tonumber(args[1]) or 0)
	local m = (args[2] and tonumber(args[2]) or 0)
	local s = (args[3] and tonumber(args[3]) or 0)
	local t = (args[4] and tonumber(args[4]) or 0)
	TriggerClientEvent("weathersync:setMyTime", source, h, m, s, t)
end, true)

local weatherSyncCounter = 0
local weatherSyncInterval = 5

Citizen.CreateThread(function()
	while true do
		local tick

		if currentTimescale == 0 then
			tick = syncDelay / 1000

			if not timeIsFrozen then
				local now = os.date("*t", os.time() + Config.realTimeOffset)
				currentTime = now.sec + now.min * 60 + now.hour * 3600 + (now.wday - 1) * dayLength
			end
		else
			tick = currentTimescale * (syncDelay / 1000)

			if not timeIsFrozen then
				currentTime = math.floor(currentTime + tick) % weekLength
			end
		end

		syncTime(-1, tick)
		syncTimescale(-1)

		weatherSyncCounter = weatherSyncCounter + 1
		if weatherSyncCounter >= weatherSyncInterval then
			weatherSyncCounter = 0
			for playerId, _ in pairs(playerRegions) do
				syncWeather(playerId)
			end
		end

		Citizen.Wait(syncDelay)
	end
end)
