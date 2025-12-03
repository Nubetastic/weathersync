ConfigRegionWeather = {}

ConfigRegionWeather.Debug = false

ConfigRegionWeather.Hemisphere = true -- true = northern hemisphere, false = southern hemisphere

-- Region transition settings
ConfigRegionWeather.RegionCheckInterval = 250  -- How often to check for region changes (ms) - lower = faster detection
ConfigRegionWeather.TransitionTime = 15.0      -- Weather transition duration when crossing regions (seconds)

-- Snow accumulation settings
ConfigRegionWeather.SnowAccumulationRate = 0.05  -- How much snow level increases per update (0.0-1.0)
ConfigRegionWeather.SnowMeltRate = 0.02          -- How much snow level decreases per update (0.0-1.0)
ConfigRegionWeather.SnowUpdateInterval = 5000    -- How often to update snow levels (ms)


ConfigRegionWeather.RegionGroups = {
    ["NEW HANOVER"] = {"HEARTLANDS", "ROANOKE_RIDGE"},
    ["WEST ELIZABETH"] = {"GREAT_PLAINS", "BIG_VALLEY", "TALL_TREES"},
    ["NEW AUSTIN"] = {"HENNIGANS_STEAD", "CHOLLA_SPRINGS", "GAPTOOTH_RIDGE", "RIO_BRAVO"},
    ["LEMOYNE"] = {"SCARLETT_MEADOWS", "BAYOU_NWA", "BLUEWATER_MARSH"},
    ["AMBARINO"] = {"GRIZZLIES_EAST", "GRIZZLIES_WEST", "CUMBERLAND_FOREST"}
}


ConfigRegionWeather.WeatherGroups = {
    ["Sunny"] = {
        ["10"] = "HIGHPRESSURE",
        ["100"] = "SUNNY",
    },
    ["Cloudy"] = {
        ["10"] = "OVERCAST",
        ["80"] = "CLOUDS",
        ["100"] = "THUNDER",
    },
    ["Rain"] = {
        ["10"] = "DRIZZLE",
        ["40"] = "SHOWER",
        ["70"] = "RAIN",
        ["90"] = "THUNDERSTORM",
        ["100"] = "HURRICANE",
    },
    ["Snow"] = {
        ["10"] = "OVERCASTDARK",
        ["30"] = "SNOWLIGHT",
        ["65"] = "SNOW",
        ["75"] = "SLEET",
        ["85"] = "HAIL",	
        ["90"] = "GROUNDBLIZZARD",
        ["95"] = "BLIZZARD",
        ["100"] = "WHITEOUT",
    },
    ["Fog"] = {
        ["10"] = "MISTY",
        ["100"] = "FOG",
    },
    ["Sandstorm"] = {
        ["10"] = "SANDSTORM",
        ["100"] = "SANDSTORM",
    }
}


ConfigRegionWeather.Regions = {
    -- ============================================
    -- NEW HANOVER
    -- ============================================
    ["HEARTLANDS"] = {
        RegionHash = 131399519,
        ZoneTypeId = 10,
        Name = "Heartlands",
        Winter = {
            ["25"] = { "Sunny", 0 },
            ["50"] = { "Cloudy", 0 },
            ["60"] = { "Fog", -10 },
            ["100"] = { "Snow", 10 }
        },
        Spring = {
            ["20"] = { "Sunny", 0 },
            ["25"] = { "Cloudy", 5 },
            ["50"] = { "Rain", 0 },
            ["65"] = { "Fog", -5 },
            ["100"] = { "Cloudy", 0 }
        },
        Summer = {
            ["25"] = { "Sunny", 5 },
            ["30"] = { "Cloudy", 0 },
            ["60"] = { "Rain", 5 },
            ["75"] = { "Fog", -5 },
            ["100"] = { "Sunny", 0 }
        },
        Fall = {
            ["18"] = { "Sunny", 0 },
            ["28"] = { "Cloudy", 5 },
            ["55"] = { "Rain", 0 },
            ["70"] = { "Fog", -5 },
            ["100"] = { "Cloudy", 0 }
        },
    },
    ["ROANOKE_RIDGE"] = {
        RegionHash = 178647645,
        ZoneTypeId = 10,
        Name = "Roanoke Ridge",
        Winter = {
            ["8"] = { "Sunny", 0 },
            ["12"] = { "Cloudy", -5 },
            ["32"] = { "Snow", 5 },
            ["40"] = { "Fog", 0 },
            ["100"] = { "Snow", 10 }
        },
        Spring = {
            ["12"] = { "Sunny", -5 },
            ["18"] = { "Cloudy", 5 },
            ["50"] = { "Rain", 5 },
            ["68"] = { "Fog", 0 },
            ["100"] = { "Cloudy", 0 }
        },
        Summer = {
            ["15"] = { "Sunny", 0 },
            ["22"] = { "Cloudy", 0 },
            ["62"] = { "Rain", 10 },
            ["78"] = { "Fog", 0 },
            ["100"] = { "Sunny", -5 }
        },
        Fall = {
            ["12"] = { "Sunny", -5 },
            ["20"] = { "Cloudy", 5 },
            ["52"] = { "Rain", 5 },
            ["72"] = { "Fog", 0 },
            ["100"] = { "Cloudy", 0 }
        },
    },

    -- ============================================
    -- WEST ELIZABETH
    -- ============================================
    ["GREAT_PLAINS"] = {
        RegionHash = 476637847,
        ZoneTypeId = 10,
        Name = "Great Plains",
        Winter = {
            ["35"] = { "Sunny", 5 },
            ["55"] = { "Cloudy", 0 },
            ["70"] = { "Fog", -10 },
            ["100"] = { "Snow", 0 }
        },
        Spring = {
            ["30"] = { "Sunny", 5 },
            ["45"] = { "Cloudy", 0 },
            ["65"] = { "Rain", -5 },
            ["85"] = { "Fog", -10 },
            ["100"] = { "Cloudy", 0 }
        },
        Summer = {
            ["40"] = { "Sunny", 10 },
            ["50"] = { "Cloudy", 0 },
            ["70"] = { "Rain", -10 },
            ["85"] = { "Fog", -15 },
            ["100"] = { "Sunny", 5 }
        },
        Fall = {
            ["28"] = { "Sunny", 5 },
            ["42"] = { "Cloudy", 0 },
            ["62"] = { "Rain", -5 },
            ["80"] = { "Fog", -10 },
            ["100"] = { "Cloudy", 0 }
        },
    },
    ["BIG_VALLEY"] = {
        RegionHash = 822658194,
        ZoneTypeId = 10,
        Name = "Big Valley",
        Winter = {
            ["15"] = { "Sunny", 0 },
            ["30"] = { "Cloudy", -5 },
            ["45"] = { "Fog", 0 },
            ["100"] = { "Snow", 15 }
        },
        Spring = {
            ["15"] = { "Sunny", 0 },
            ["20"] = { "Cloudy", 5 },
            ["55"] = { "Rain", 10 },
            ["75"] = { "Fog", 0 },
            ["100"] = { "Cloudy", 0 }
        },
        Summer = {
            ["15"] = { "Sunny", 0 },
            ["22"] = { "Cloudy", 5 },
            ["65"] = { "Rain", 15 },
            ["80"] = { "Fog", 5 },
            ["100"] = { "Sunny", 0 }
        },
        Fall = {
            ["12"] = { "Sunny", 0 },
            ["20"] = { "Cloudy", 5 },
            ["58"] = { "Rain", 10 },
            ["78"] = { "Fog", 0 },
            ["100"] = { "Cloudy", 0 }
        },
    },
    ["TALL_TREES"] = {
        RegionHash = 1684533001,
        ZoneTypeId = 10,
        Name = "Tall Trees",
        Winter = {
            ["20"] = { "Sunny", 0 },
            ["35"] = { "Cloudy", -5 },
            ["50"] = { "Fog", -5 },
            ["100"] = { "Snow", 8 }
        },
        Spring = {
            ["18"] = { "Sunny", 0 },
            ["25"] = { "Cloudy", 5 },
            ["52"] = { "Rain", 5 },
            ["70"] = { "Fog", -5 },
            ["100"] = { "Cloudy", 0 }
        },
        Summer = {
            ["22"] = { "Sunny", 5 },
            ["30"] = { "Cloudy", 0 },
            ["62"] = { "Rain", 10 },
            ["78"] = { "Fog", 0 },
            ["100"] = { "Sunny", 0 }
        },
        Fall = {
            ["16"] = { "Sunny", 0 },
            ["26"] = { "Cloudy", 5 },
            ["54"] = { "Rain", 5 },
            ["74"] = { "Fog", -5 },
            ["100"] = { "Cloudy", 0 }
        },
    },

    -- ============================================
    -- NEW AUSTIN
    -- ============================================
    ["HENNIGANS_STEAD"] = {
        RegionHash = 892930832,
        ZoneTypeId = 10,
        Name = "Hennigan's Stead",
        Winter = {
            ["40"] = { "Sunny", 5 },
            ["60"] = { "Cloudy", 0 },
            ["80"] = { "Fog", -15 },
            ["100"] = { "Sunny", 10 }
        },
        Spring = {
            ["45"] = { "Sunny", 10 },
            ["58"] = { "Cloudy", 0 },
            ["75"] = { "Rain", -15 },
            ["90"] = { "Fog", -15 },
            ["100"] = { "Sunny", 5 }
        },
        Summer = {
            ["55"] = { "Sunny", 15 },
            ["68"] = { "Cloudy", 0 },
            ["82"] = { "Rain", -20 },
            ["95"] = { "Fog", -20 },
            ["100"] = { "Sunny", 10 }
        },
        Fall = {
            ["42"] = { "Sunny", 10 },
            ["60"] = { "Cloudy", 0 },
            ["76"] = { "Rain", -15 },
            ["92"] = { "Fog", -15 },
            ["100"] = { "Sunny", 5 }
        },
    },
    ["CHOLLA_SPRINGS"] = {
        RegionHash = -108848014,
        ZoneTypeId = 10,
        Name = "Cholla Springs",
        Winter = {
            ["55"] = { "Sunny", 10 },
            ["72"] = { "Cloudy", -5 },
            ["88"] = { "Fog", -20 },
            ["100"] = { "Sunny", 15 }
        },
        Spring = {
            ["60"] = { "Sunny", 15 },
            ["75"] = { "Cloudy", 0 },
            ["88"] = { "Rain", -25 },
            ["98"] = { "Fog", -20 },
            ["100"] = { "Sunny", 10 }
        },
        Summer = {
            ["70"] = { "Sunny", 20 },
            ["82"] = { "Cloudy", 0 },
            ["93"] = { "Rain", -30 },
            ["99"] = { "Fog", -25 },
            ["100"] = { "Sunny", 15 }
        },
        Fall = {
            ["58"] = { "Sunny", 15 },
            ["75"] = { "Cloudy", 0 },
            ["88"] = { "Rain", -25 },
            ["98"] = { "Fog", -20 },
            ["100"] = { "Sunny", 10 }
        },
    },
    ["GAPTOOTH_RIDGE"] = {
        RegionHash = -2066240242,
        ZoneTypeId = 10,
        Name = "Gaptooth Ridge",
        Winter = {
            ["58"] = { "Sunny", 15 },
            ["75"] = { "Cloudy", -5 },
            ["90"] = { "Fog", -20 },
            ["100"] = { "Sunny", 20 }
        },
        Spring = {
            ["65"] = { "Sunny", 20 },
            ["78"] = { "Cloudy", 0 },
            ["90"] = { "Rain", -30 },
            ["99"] = { "Fog", -20 },
            ["100"] = { "Sunny", 15 }
        },
        Summer = {
            ["75"] = { "Sunny", 25 },
            ["85"] = { "Cloudy", 0 },
            ["95"] = { "Rain", -35 },
            ["100"] = { "Fog", -25 }
        },
        Fall = {
            ["62"] = { "Sunny", 20 },
            ["78"] = { "Cloudy", 0 },
            ["90"] = { "Rain", -30 },
            ["99"] = { "Fog", -20 },
            ["100"] = { "Sunny", 15 }
        },
    },
    ["RIO_BRAVO"] = {
        RegionHash = -2145992129,
        ZoneTypeId = 10,
        Name = "Rio Bravo",
        Winter = {
            ["60"] = { "Sunny", 15 },
            ["76"] = { "Cloudy", -5 },
            ["91"] = { "Fog", -20 },
            ["100"] = { "Sunny", 20 }
        },
        Spring = {
            ["66"] = { "Sunny", 20 },
            ["79"] = { "Cloudy", 0 },
            ["91"] = { "Rain", -30 },
            ["99"] = { "Fog", -20 },
            ["100"] = { "Sunny", 15 }
        },
        Summer = {
            ["76"] = { "Sunny", 25 },
            ["86"] = { "Cloudy", 0 },
            ["96"] = { "Rain", -35 },
            ["100"] = { "Fog", -25 }
        },
        Fall = {
            ["63"] = { "Sunny", 20 },
            ["79"] = { "Cloudy", 0 },
            ["91"] = { "Rain", -30 },
            ["99"] = { "Fog", -20 },
            ["100"] = { "Sunny", 15 }
        },
    },

    -- ============================================
    -- LEMOYNE
    -- ============================================
    ["SCARLETT_MEADOWS"] = {
        RegionHash = -864275692,
        ZoneTypeId = 10,
        Name = "Scarlett Meadows",
        Winter = {
            ["25"] = { "Sunny", 0 },
            ["35"] = { "Cloudy", 0 },
            ["55"] = { "Fog", 0 },
            ["100"] = { "Snow", -5 }
        },
        Spring = {
            ["22"] = { "Sunny", -5 },
            ["28"] = { "Cloudy", 5 },
            ["55"] = { "Rain", 15 },
            ["75"] = { "Fog", 5 },
            ["100"] = { "Cloudy", 0 }
        },
        Summer = {
            ["28"] = { "Sunny", -5 },
            ["35"] = { "Cloudy", 5 },
            ["65"] = { "Rain", 20 },
            ["82"] = { "Fog", 5 },
            ["100"] = { "Sunny", -5 }
        },
        Fall = {
            ["24"] = { "Sunny", -5 },
            ["32"] = { "Cloudy", 5 },
            ["60"] = { "Rain", 15 },
            ["78"] = { "Fog", 5 },
            ["100"] = { "Cloudy", 0 }
        },
    },
    ["BAYOU_NWA"] = {
        RegionHash = 2025841068,
        ZoneTypeId = 10,
        Name = "Bayou Nwa",
        Winter = {
            ["20"] = { "Sunny", -5 },
            ["30"] = { "Cloudy", -5 },
            ["68"] = { "Fog", 10 },
            ["100"] = { "Snow", -15 }
        },
        Spring = {
            ["18"] = { "Sunny", -10 },
            ["24"] = { "Cloudy", 5 },
            ["56"] = { "Rain", 15 },
            ["80"] = { "Fog", 15 },
            ["100"] = { "Cloudy", 0 }
        },
        Summer = {
            ["20"] = { "Sunny", -10 },
            ["28"] = { "Cloudy", 5 },
            ["64"] = { "Rain", 20 },
            ["84"] = { "Fog", 20 },
            ["100"] = { "Sunny", -10 }
        },
        Fall = {
            ["18"] = { "Sunny", -10 },
            ["24"] = { "Cloudy", 5 },
            ["59"] = { "Rain", 15 },
            ["82"] = { "Fog", 15 },
            ["100"] = { "Cloudy", 0 }
        },
    },
    ["BLUEWATER_MARSH"] = {
        RegionHash = 1308232528,
        ZoneTypeId = 10,
        Name = "Bluewater Marsh",
        Winter = {
            ["20"] = { "Sunny", -5 },
            ["30"] = { "Cloudy", -5 },
            ["68"] = { "Fog", 10 },
            ["100"] = { "Snow", -15 }
        },
        Spring = {
            ["18"] = { "Sunny", -10 },
            ["25"] = { "Cloudy", 5 },
            ["57"] = { "Rain", 15 },
            ["81"] = { "Fog", 15 },
            ["100"] = { "Cloudy", 0 }
        },
        Summer = {
            ["20"] = { "Sunny", -10 },
            ["28"] = { "Cloudy", 5 },
            ["65"] = { "Rain", 20 },
            ["85"] = { "Fog", 20 },
            ["100"] = { "Sunny", -10 }
        },
        Fall = {
            ["18"] = { "Sunny", -10 },
            ["25"] = { "Cloudy", 5 },
            ["60"] = { "Rain", 15 },
            ["83"] = { "Fog", 15 },
            ["100"] = { "Cloudy", 0 }
        },
    },

    -- ============================================
    -- AMBARINO
    -- ============================================
    ["GRIZZLIES_EAST"] = {
        RegionHash = -120156735,
        ZoneTypeId = 10,
        Name = "Grizzlies East",
        Winter = {
            ["12"] = { "Sunny", -5 },
            ["18"] = { "Cloudy", -5 },
            ["50"] = { "Fog", 0 },
            ["100"] = { "Snow", 5 }
        },
        Spring = {
            ["12"] = { "Sunny", -5 },
            ["16"] = { "Cloudy", 5 },
            ["55"] = { "Rain", 20 },
            ["72"] = { "Fog", 0 },
            ["100"] = { "Cloudy", 0 }
        },
        Summer = {
            ["14"] = { "Sunny", 0 },
            ["20"] = { "Cloudy", 5 },
            ["68"] = { "Rain", 20 },
            ["82"] = { "Fog", 5 },
            ["100"] = { "Sunny", -5 }
        },
        Fall = {
            ["12"] = { "Sunny", -5 },
            ["18"] = { "Cloudy", 5 },
            ["58"] = { "Rain", 15 },
            ["75"] = { "Fog", 0 },
            ["100"] = { "Cloudy", 0 }
        },
    },
    ["GRIZZLIES_WEST"] = {
        RegionHash =  1645618177,
        ZoneTypeId = 10,
        Name = "Grizzlies West",
        Winter = {
            ["5"] = { "Sunny", -5 },
            ["8"] = { "Cloudy", -10 },
            ["20"] = { "Fog", -5 },
            ["100"] = { "Snow", 20 }
        },
        Spring = {
            ["8"] = { "Sunny", -10 },
            ["12"] = { "Cloudy", -5 },
            ["40"] = { "Snow", 15 },
            ["70"] = { "Fog", -5 },
            ["100"] = { "Rain", 5 }
        },
        Summer = {
            ["10"] = { "Sunny", -5 },
            ["15"] = { "Cloudy", 0 },
            ["55"] = { "Snow", 10 },
            ["75"] = { "Fog", 0 },
            ["100"] = { "Rain", 5 }
        },
        Fall = {
            ["8"] = { "Sunny", -10 },
            ["12"] = { "Cloudy", -5 },
            ["45"] = { "Snow", 15 },
            ["75"] = { "Fog", -5 },
            ["100"] = { "Rain", 0 }
        },
    },
    ["CUMBERLAND_FOREST"] = {
        RegionHash = 1835499550,
        ZoneTypeId = 10,
        Name = "Cumberland Forest",
        Winter = {
            ["15"] = { "Sunny", -5 },
            ["25"] = { "Cloudy", -5 },
            ["45"] = { "Fog", -5 },
            ["100"] = { "Snow", 12 }
        },
        Spring = {
            ["16"] = { "Sunny", -5 },
            ["22"] = { "Cloudy", 5 },
            ["52"] = { "Rain", 10 },
            ["70"] = { "Fog", 0 },
            ["100"] = { "Cloudy", 0 }
        },
        Summer = {
            ["20"] = { "Sunny", 5 },
            ["28"] = { "Cloudy", 0 },
            ["64"] = { "Rain", 10 },
            ["78"] = { "Fog", 0 },
            ["100"] = { "Sunny", 0 }
        },
        Fall = {
            ["16"] = { "Sunny", -5 },
            ["26"] = { "Cloudy", 5 },
            ["56"] = { "Rain", 8 },
            ["72"] = { "Fog", 0 },
            ["100"] = { "Cloudy", 0 }
        },
    },
}
