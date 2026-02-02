# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

This is an iOS project requiring Xcode. Use xcodebuildmcp tools when available.

```bash
# Build (iOS Simulator)
xcodebuild -project WeatherApp/WeatherApp.xcodeproj -scheme WeatherApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Run all tests
xcodebuild -project WeatherApp/WeatherApp.xcodeproj -scheme WeatherApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test

# Run specific test file
xcodebuild -project WeatherApp/WeatherApp.xcodeproj -scheme WeatherApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:WeatherAppTests/GoogleWeatherServiceTests test

# Clean
xcodebuild -project WeatherApp/WeatherApp.xcodeproj -scheme WeatherApp clean
```

### Weather Proxy (Go)

```bash
cd weather-proxy
go build .
go test ./...
```

## Architecture

### MVVM + Service Layer

```
Views (SwiftUI) → ViewModels (@Observable) → WeatherAggregator → WeatherServiceProtocol implementations
```

The app aggregates weather data from multiple APIs (WeatherKit, Google, NOAA, OpenWeatherMap, Tomorrow.io) and normalizes them into unified domain models.

### Key Architectural Patterns

- **WeatherAggregator**: Orchestrates parallel fetching from all enabled weather sources
- **WeatherServiceProtocol**: Common interface all weather services implement (in `Services/Protocols/`)
- **Domain Models**: API responses are normalized to `WeatherData`, `CurrentWeather`, `HourlyForecast`, `DailyForecast` (in `Models/Domain/`)
- **API Models**: Per-service Codable structs for decoding (in `Models/API/`)
- **SwiftData**: Used for caching (`CachedWeather`) and persistence (`SavedLocation`, `SearchHistory`)

### Directory Structure

```
WeatherApp/WeatherApp/
├── Models/
│   ├── Domain/         # Unified weather types (WeatherData, WeatherCondition, etc.)
│   ├── API/            # Service-specific Codable response models
│   └── Persistence/    # SwiftData models (CachedWeather, SavedLocation)
├── Services/
│   ├── Weather/        # Service implementations (WeatherKitService, GoogleWeatherService, etc.)
│   ├── Protocols/      # WeatherServiceProtocol, GeocodingServiceProtocol
│   ├── Location/       # LocationManager, GeocodingService
│   └── Network/        # NetworkClient, APIError
├── ViewModels/         # @Observable view models
└── Views/
    ├── Main/           # WeatherMainView
    ├── Launch/         # LaunchView, CurrentLocationHero
    ├── Search/         # LocationSearchView, ExpandableSearchBar
    ├── Comparison/     # ForecastComparisonView, ComparisonChartView
    ├── Daily/          # DailyDetailView
    └── Components/     # Reusable UI (cards, backgrounds, glass effects)
```

### Weather Proxy

The `weather-proxy/` directory contains a Go Cloud Run service that proxies Google Weather API requests with OAuth authentication and caching.

## Code Style

- **Swift Testing**: Use `@Test` attribute and `#expect()` assertions (not XCTest)
- **SwiftUI Previews**: Use `#Preview` macro
- **SwiftData**: Models use `@Model` macro on `final class`
- **Naming**: PascalCase for types, camelCase for functions/variables
- **Access Control**: Mark helpers as `private`

## Testing

Tests use Swift Testing framework. Test files are in `WeatherAppTests/` and `WeatherAppUITests/`.

Key test areas:
- `GoogleWeatherDecodingTests`: API response decoding
- `GoogleWeatherServiceTests`: Service integration tests
