# WeatherApp - Multi-API Weather Comparison

A comprehensive iOS weather app that aggregates data from multiple sources and presents beautiful, unified visualizations with clear difference highlighting.

## Features

- **Multi-API Integration**: Fetches weather data from:
  - Apple WeatherKit (primary, global)
  - Google Weather (global, optional with API key)
  - NOAA/NWS (free, US-only)
  - OpenWeatherMap (global, optional with API key)
  - Tomorrow.io (global, optional with API key)

- **Unified Data Display**: Normalizes data from all sources into a consistent domain model

- **Forecast Comparison**: Side-by-side charts using Swift Charts to visualize differences between sources

- **Contextual Search**: Search by city name, zip code, "city, state", or coordinates

- **Beautiful UI**:
  - Gradient backgrounds with animations
  - Frosted glass effects (ultra-thin material)
  - SF Symbols with multicolor rendering
  - Native iOS feel similar to Apple's Weather app

- **Smart Caching**: 1-hour cache using SwiftData

- **Location Services**: CoreLocation integration with permission handling

## Requirements

- iOS 26.0+
- Xcode 16.0+
- Swift 6.2.1+
- Apple Developer account (for WeatherKit)

## Setup

### 1. WeatherKit Configuration

WeatherKit is already enabled in the project entitlements. Ensure your Apple Developer account has:
- Active Developer Program membership
- WeatherKit enabled for your App ID

### 2. API Keys (Optional)

To enable additional weather sources, add API keys:

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Add your API keys to `.env`:
   ```bash
   # Google Weather API Key (optional)
   # Get from: Google Cloud Console
   GOOGLE_WEATHER_API_KEY=your_key_here

   # OpenWeatherMap API Key (optional)
   # Sign up at: https://openweathermap.org/api
   OWM_API_KEY=your_key_here

   # Tomorrow.io API Key (optional)
   # Sign up at: https://www.tomorrow.io/weather-api/
   TOMORROW_API_KEY=your_key_here
   ```

3. Set environment variables in Xcode:
   - Edit Scheme → Run → Arguments → Environment Variables
   - Add `GOOGLE_WEATHER_API_KEY`, `OWM_API_KEY`, and `TOMORROW_API_KEY`

**Note**: The app works with just WeatherKit and NOAA. Additional sources are optional.

### 3. Build and Run

1. Open `WeatherApp.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and run on device or simulator

## Architecture

### MVVM Pattern

```
Views (SwiftUI)
    ↓
ViewModels (@Observable)
    ↓
WeatherAggregator
    ↓
WeatherServiceProtocol implementations
    → WeatherKitService
    → GoogleWeatherService
    → NOAAWeatherService
    → OpenWeatherMapService
    → TomorrowIOService
```

### Project Structure

```
Models/
  ├── Domain/          # Unified weather models
  ├── Persistence/     # SwiftData models
  └── API/            # API-specific response models
Services/
  ├── Protocols/      # Service interfaces
  ├── Weather/        # Weather API implementations
  ├── Location/       # Location & geocoding
  └── Network/        # HTTP client
ViewModels/           # Business logic
Views/
  ├── Main/           # Primary screens
  ├── Components/     # Reusable UI
  ├── Search/         # Location search
  └── Comparison/     # Forecast comparison
Utilities/            # Extensions, helpers, constants
```

## Key Components

### Domain Models

- **WeatherData**: Unified weather data from multiple sources
- **SourcedWeatherInfo**: Weather data from a specific source
- **CurrentWeather**: Current conditions
- **HourlyForecast**: Hourly forecast data
- **DailyForecast**: Daily forecast data
- **WeatherCondition**: Unified weather condition enum with SF Symbol mappings

### Services

- **WeatherKitService**: Apple WeatherKit integration
- **GoogleWeatherService**: Google Weather API integration
- **NOAAWeatherService**: NOAA/NWS API integration
- **OpenWeatherMapService**: OpenWeatherMap API integration
- **TomorrowIOService**: Tomorrow.io API integration
- **WeatherAggregator**: Parallel fetching from all available sources
- **GeocodingService**: Location search and geocoding
- **NetworkClient**: HTTP client with retry logic

### Views

- **ContentView**: Main app container
- **WeatherMainView**: Primary weather display
- **LocationSearchView**: Search interface
- **ForecastComparisonView**: Side-by-side comparison
- **ComparisonChartView**: Overlaid line charts

## Testing Locations

- **US Location**: San Francisco, CA (37.7749, -122.4194) - Tests WeatherKit + NOAA
- **International**: London, UK (51.5074, -0.1278) - Tests WeatherKit + optional APIs
- **Zip Code**: 10001 (New York City)
- **Coordinates**: "40.7128,-74.0060" (NYC)

## API Rate Limits

- **WeatherKit**: 500,000 calls/month (Apple Developer Program)
- **Google Weather**: Varies by plan (requires Google Cloud account)
- **NOAA**: No rate limit (free, US-only)
- **OpenWeatherMap**: 1,000 calls/day (free tier)
- **Tomorrow.io**: 500 calls/day, 25 calls/hour (free tier)

## Known Limitations

- **OpenWeatherMap**: Hourly forecasts are provided in 3-hour intervals instead of true hourly data. The app displays these as-is without interpolation.

## License

This project is a demonstration app. Not for commercial use.

## Credits

Weather data provided by:
- Apple WeatherKit
- Google Weather
- NOAA National Weather Service
- OpenWeatherMap
- Tomorrow.io
