# Google Weather API Reference

**Service:** `weather.googleapis.com`
**Base URL:** `https://weather.googleapis.com`
**Discovery Document:** `https://weather.googleapis.com/$discovery/rest?version=v1`

## Authentication

- Requires OAuth scope: `https://www.googleapis.com/auth/cloud-platform`
- Requires Google Cloud Platform project with billing enabled
- API key passed via standard GCP authentication mechanisms

## Available Endpoints

### 1. Current Conditions

**Endpoint:** `GET /v1/currentConditions:lookup`

Returns current weather conditions at a given location.

**Query Parameters:**
- `location` (object, required) - LatLng object with latitude/longitude
- `unitsSystem` (enum, optional) - METRIC (default) or other units
- `languageCode` (string, optional) - IETF BCP-47 language code (default: "en")

**Response Fields:**
```json
{
  "currentTime": "string (RFC 3339 timestamp)",
  "timeZone": { object },
  "weatherCondition": { object },
  "temperature": { object },
  "feelsLikeTemperature": { object },
  "dewPoint": { object },
  "heatIndex": { object },
  "windChill": { object },
  "precipitation": { object },
  "airPressure": { object },
  "wind": { object },
  "visibility": { object },
  "currentConditionsHistory": { object },
  "isDaytime": boolean,
  "relativeHumidity": integer (0-100),
  "uvIndex": integer,
  "thunderstormProbability": integer (0-100),
  "cloudCover": integer (0-100)
}
```

**CurrentConditionsHistory Fields:**
- `temperatureChange` - Current temp minus temp 24h ago
- `maxTemperature` - High in past 24h
- `minTemperature` - Low in past 24h
- `snowQpf` - Snow accumulation (24h, liquid equivalent)
- `qpf` - Precipitation accumulation (24h, liquid equivalent)

---

### 2. Daily Forecast

**Endpoint:** `GET /v1/forecast/days:lookup`

Returns up to 10 days of daily forecasts, starting from current day.

**Query Parameters:**
- `location` (object, required) - LatLng object
- `unitsSystem` (enum, optional) - METRIC (default)
- `pageSize` (integer, optional) - Max records per page: 1-10 (default: 5)
- `pageToken` (string, optional) - For pagination
- `days` (integer, optional) - Total days to fetch: 1-10 (default: 10)
- `languageCode` (string, optional) - Language code (default: "en")

**Response Fields:**
```json
{
  "forecastDays": [
    {
      "interval": { object },
      "displayDate": { year, month, day },
      "daytimeForecast": { object },
      "nighttimeForecast": { object },
      "maxTemperature": { object },
      "minTemperature": { object },
      "feelsLikeMaxTemperature": { object },
      "feelsLikeMinTemperature": { object },
      "maxHeatIndex": { object },
      "sunEvents": {
        "sunriseTime": "string (RFC 3339)",
        "sunsetTime": "string (RFC 3339)"
      },
      "moonEvents": {
        "moonriseTimes": ["string"],
        "moonsetTimes": ["string"],
        "moonPhase": "enum (MoonPhase)"
      }
    }
  ],
  "timeZone": { object },
  "nextPageToken": "string"
}
```

**Day Structure:**
- **Interval:** Day starts at 7am local, ends at 7am next day
- **daytimeForecast:** 7am-7pm local time
- **nighttimeForecast:** 7pm-7am next day local time

**ForecastDayPart Fields:**
- `weatherCondition` - Forecast condition
- `precipitation` - Forecast precipitation
- `wind` - Average direction, max speed and gust
- `iceThickness` - Accumulated ice
- `relativeHumidity` - Integer (0-100)
- `uvIndex` - Maximum UV index
- `thunderstormProbability` - Integer (0-100)
- `cloudCover` - Average percent

**Moon Phases:**
- NEW_MOON - Not illuminated
- WAXING_CRESCENT - 0-50% lit on right (NH) / left (SH)
- FIRST_QUARTER - 50.1% lit on right (NH) / left (SH)
- WAXING_GIBBOUS - 50-100% lit on right (NH) / left (SH)
- FULL_MOON - Fully illuminated
- WANING_GIBBOUS - 50-100% lit on left (NH) / right (SH)
- LAST_QUARTER - 50.1% lit on left (NH) / right (SH)
- WANING_CRESCENT - 0-50% lit on left (NH) / right (SH)

---

### 3. Hourly Forecast

**Endpoint:** `GET /v1/forecast/hours:lookup`

Returns up to 240 hours of hourly forecasts, starting from current hour.

**Query Parameters:**
- `location` (object, required) - LatLng object
- `unitsSystem` (enum, optional) - METRIC (default)
- `pageSize` (integer, optional) - Max records per page: 1-24 (default: 24)
- `pageToken` (string, optional) - For pagination
- `hours` (integer, optional) - Total hours to fetch: 1-240 (default: 240)
- `languageCode` (string, optional) - Language code (default: "en")

**Response Fields:**
```json
{
  "forecastHours": [
    {
      "interval": { object },
      "displayDateTime": { object },
      "weatherCondition": { object },
      "temperature": { object },
      "feelsLikeTemperature": { object },
      "dewPoint": { object },
      "heatIndex": { object },
      "windChill": { object },
      "wetBulbTemperature": { object },
      "precipitation": { object },
      "airPressure": { object },
      "wind": { object },
      "visibility": { object },
      "iceThickness": { object },
      "isDaytime": boolean,
      "relativeHumidity": integer (0-100),
      "uvIndex": integer,
      "thunderstormProbability": integer (0-100),
      "cloudCover": integer (0-100)
    }
  ],
  "timeZone": { object },
  "nextPageToken": "string"
}
```

**Notes:**
- Timestamps rounded down to closest hour
- `displayDateTime` includes year, month, day, hour, UTC offset
- `isDaytime` is true if interval intersects with sunrise-sunset

---

### 4. Historical Hourly Data

**Endpoint:** `GET /v1/history/hours:lookup`

Returns up to 24 hours of hourly historical weather data, starting from last hour.

**Query Parameters:**
- `location` (object, required) - LatLng object
- `unitsSystem` (enum, optional) - METRIC (default)
- `pageSize` (integer, optional) - Max records per page: 1-24 (default: 24)
- `pageToken` (string, optional) - For pagination
- `hours` (integer, optional) - Total hours to fetch: 1-24 (default: 24)
- `languageCode` (string, optional) - Language code (default: "en")

**Response Fields:**
Same structure as hourly forecast (ForecastHour), but returns `HistoryHour` objects with identical fields representing historical data instead of forecasts.

---

### 5. Public Weather Alerts

**Endpoint:** `GET /v1/publicAlerts:lookup`

Returns public weather alerts for a given location.

**Query Parameters:**
- `location` (object, required) - LatLng object
- `pageSize` (integer, optional) - Max alerts per page
- `pageToken` (string, optional) - For pagination
- `languageCode` (string, optional) - Language code (default: "en")

**Response Fields:**
```json
{
  "weatherAlerts": [
    {
      "alertId": "string",
      "alertTitle": { object (LocalizedText) },
      "eventType": "enum (WeatherEventType)",
      "areaName": "string",
      "instruction": ["string"],
      "safetyRecommendations": [
        {
          "directive": "string",
          "subtext": "string"
        }
      ],
      "timezoneOffset": "string (e.g., '-14400s')",
      "startTime": "string (RFC 3339)",
      "expirationTime": "string (RFC 3339)",
      "dataSource": {
        "publisher": "enum (Publisher)",
        "name": "string",
        "authorityUri": "string"
      },
      "polygon": "string (GeoJSON Polygon or MultiPolygon)",
      "description": "string",
      "severity": "enum (Severity)",
      "certainty": "enum (Certainty)",
      "urgency": "enum (Urgency)"
    }
  ],
  "regionCode": "string (ISO_3166-1 alpha-2)",
  "nextPageToken": "string"
}
```

**Weather Event Types:** (Sample - see full list in API docs)
- Severe: TORNADO, HURRICANE, TSUNAMI, EARTHQUAKE, VOLCANIC_ERUPTION
- Storm: BLIZZARD, ICE_STORM, THUNDERSTORM, TROPICAL_STORM
- Precipitation: FLOOD, FLASH_FLOOD, FREEZING_RAIN_EVENT
- Temperature: HEAT, COLD, FROST
- Wind: GALE, WIND_CHILL
- Environmental: WILDFIRE, DUST_STORM, FOG
- And many more...

**Severity Levels:**
- EXTREME - Extraordinary threat to life/property
- SEVERE - Significant threat
- MODERATE - Possible threat
- MINOR - Minor threat

**Certainty Levels:**
- OBSERVED - Occurring or ongoing
- VERY_LIKELY
- LIKELY (p > ~50%)
- POSSIBLE (p <= ~50%)
- UNLIKELY (p ~ 0%)

**Urgency Levels:**
- IMMEDIATE - Take action immediately
- EXPECTED - Take action soon (within next hour)
- FUTURE - Take action in near future
- PAST - No longer required

---

## Common Data Types

### LatLng Object
```json
{
  "latitude": double,
  "longitude": double
}
```

### Temperature Object
```json
{
  "value": double,
  "unit": "string (CELSIUS, FAHRENHEIT, etc.)"
}
```

### Wind Object
```json
{
  "speed": { value, unit },
  "direction": { degrees: integer },
  "gust": { value, unit }
}
```

### Precipitation Object
```json
{
  "probability": integer (0-100),
  "amount": { value, unit }
}
```

### WeatherCondition Object
```json
{
  "code": "string",
  "description": "string (localized)"
}
```

### Visibility Object
```json
{
  "value": double,
  "unit": "string"
}
```

### AirPressure Object
```json
{
  "value": double,
  "unit": "string"
}
```

---

## Units System

**Default:** METRIC

When using METRIC:
- Temperature: Celsius
- Wind speed: meters/second or km/h
- Pressure: millibars/hPa
- Visibility: kilometers
- Precipitation: millimeters

---

## Implementation Notes

### Integration Strategy

**Phase 1: Core Weather Data**
- Current conditions (`/v1/currentConditions:lookup`)
- Hourly forecasts (`/v1/forecast/hours:lookup`)
- Daily forecasts (`/v1/forecast/days:lookup`)

**Phase 2: Advanced Features**
- Historical data (`/v1/history/hours:lookup`)
- Weather alerts (`/v1/publicAlerts:lookup`)

### Field Mapping to App Domain Models

**CurrentWeather:**
- `temperature` → CurrentWeather.temperature
- `feelsLikeTemperature` → CurrentWeather.apparentTemperature
- `weatherCondition` → CurrentWeather.condition
- `relativeHumidity` → CurrentWeather.humidity (divide by 100 if needed)
- `airPressure` → CurrentWeather.pressure
- `wind.speed` → CurrentWeather.windSpeed
- `wind.direction.degrees` → CurrentWeather.windDirection
- `uvIndex` → CurrentWeather.uvIndex
- `visibility` → CurrentWeather.visibility
- `cloudCover` → CurrentWeather.cloudCover (divide by 100 if needed)
- `dewPoint` → CurrentWeather.dewPoint

**HourlyForecast:**
- `interval.startTime` → HourlyForecast.timestamp
- `temperature` → HourlyForecast.temperature
- `feelsLikeTemperature` → HourlyForecast.apparentTemperature
- `weatherCondition` → HourlyForecast.condition
- `precipitation.probability` → HourlyForecast.precipitationChance (divide by 100)
- `precipitation.amount` → HourlyForecast.precipitationAmount
- `relativeHumidity` → HourlyForecast.humidity (divide by 100)
- `wind.speed` → HourlyForecast.windSpeed
- `wind.direction.degrees` → HourlyForecast.windDirection
- `uvIndex` → HourlyForecast.uvIndex
- `cloudCover` → HourlyForecast.cloudCover (divide by 100)

**DailyForecast:**
- `displayDate` → DailyForecast.date
- `maxTemperature` → DailyForecast.highTemperature
- `minTemperature` → DailyForecast.lowTemperature
- `daytimeForecast.weatherCondition` → DailyForecast.condition
- `daytimeForecast.precipitation.probability` → DailyForecast.precipitationChance
- `sunEvents.sunriseTime` → DailyForecast.sunrise
- `sunEvents.sunsetTime` → DailyForecast.sunset
- `moonEvents.moonPhase` → DailyForecast.moonPhase
- `daytimeForecast.relativeHumidity` → DailyForecast.humidity
- `daytimeForecast.wind.speed` → DailyForecast.windSpeed
- `daytimeForecast.uvIndex` → DailyForecast.uvIndex

### Special Considerations

1. **Sunrise/Sunset Edge Cases:** In polar regions, sunrise/sunset may not occur. Check for null values.

2. **Moon Events Arrays:** Moonrise/moonset can have multiple values in polar regions. Handle arrays appropriately.

3. **Day/Night Intervals:** Google's API defines days as 7am-7am local time, not midnight-midnight.

4. **Pagination:** For large datasets, use `nextPageToken` to fetch additional pages.

5. **Humidity/Cloud Cover:** Google returns integers 0-100. Convert to 0.0-1.0 if app expects percentages.

6. **Weather Conditions:** Map Google's condition codes to app's `WeatherCondition` enum.

7. **Historical Data:** Contains same fields as forecast but represents actual observed conditions.

---

## Rate Limits & Quotas

**TODO:** Document rate limits once confirmed in GCP console.

Expected limits:
- Requests per day: TBD
- Requests per minute: TBD
- Cost per request: TBD

---

## References

- Official API Docs: https://weather.googleapis.com
- Discovery Document: https://weather.googleapis.com/$discovery/rest?version=v1
- OAuth Scopes: https://www.googleapis.com/auth/cloud-platform
- ISO Language Codes: IETF BCP-47
- Region Codes: ISO_3166-1 alpha-2
- GeoJSON Format: RFC 7946
- Timestamp Format: RFC 3339

---

**Last Updated:** 2026-01-30
**API Version:** v1
