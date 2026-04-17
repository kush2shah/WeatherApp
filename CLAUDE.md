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
Views (SwiftUI) → ViewModels (@Observable @MainActor) → WeatherAggregator → WeatherServiceProtocol implementations
```

The app aggregates weather data from multiple APIs and normalizes them into unified domain models. Services are enabled conditionally based on API key availability via `Config.isSourceEnabled()`.

### Data Flow

1. **WeatherAggregator** uses `TaskGroup` to fetch from all enabled sources in parallel
2. Each service returns `SourcedWeatherInfo` (source-attributed weather data)
3. Results are collected into `WeatherData` (container for multiple sources)
4. **WeatherViewModel** manages fetch lifecycle: loads cached data first, fetches fresh data in background, falls back to city-level geocoding on failure
5. **WeatherCacheService** persists results to SwiftData with 1-hour TTL, keyed by SHA256 hash of normalized coordinates

### Service Priority (in WeatherAggregator)

1. **WeatherKit** — always enabled, preferred primary source
2. **Google Weather** — requires API key, uses Cloud Run proxy for OAuth
3. **NOAA** — always enabled, US-only (checks location availability)
4. **OpenWeatherMap** — requires API key
5. **Tomorrow.io** — requires API key

### Key Architectural Patterns

- **Protocol abstractions for testability**: `WeatherServiceProtocol`, `NetworkClientProtocol`, `GeocodingServiceProtocol`, `CachingServiceProtocol` — all inherit `Sendable`
- **NetworkClient is an actor** with exponential backoff retry (skips retries for 4xx/auth errors)
- **Config resolution order**: `Info.plist` (from xcconfig) → environment variables → fallback. Developers copy `Config-Template.xcconfig` to `Config.xcconfig` and add API keys
- **Task cancellation**: ViewModel tracks `activeFetchTask`/`activeRefreshTask` to cancel in-flight requests
- **Error tracking per source**: `sourceErrors` dict maintained alongside successful `sources` for UI display

### Directory Structure

```
WeatherApp/WeatherApp/
├── Models/
│   ├── Domain/         # WeatherData, WeatherCondition (21 cases with SF Symbol mappings), SourcedWeatherInfo
│   ├── API/            # Per-service Codable response models
│   └── Persistence/    # SwiftData models (CachedWeather with JSON-encoded weather data, SavedLocation, SearchHistory)
├── Services/
│   ├── Weather/        # Service implementations + WeatherAggregator + WeatherCacheService
│   ├── Protocols/      # Service interfaces (all Sendable)
│   ├── Location/       # LocationManager, GeocodingService (handles zip, "city,state", coords, city name)
│   └── Network/        # NetworkClient (actor), APIError enum
├── ViewModels/         # @Observable @MainActor view models
├── Views/              # SwiftUI views organized by feature
└── Utilities/          # UnitConverter, Date extensions, AnimationConfig (accessibility-aware), Color+Weather (WCAG AA gradients)
```

### Weather Proxy

The `weather-proxy/` directory contains a Go Cloud Run service that proxies Google Weather API requests with OAuth authentication and caching.

## Code Style

- **Swift Testing**: Use `@Test` attribute and `#expect()` assertions (not XCTest)
- **SwiftUI Previews**: Use `#Preview` macro
- **SwiftData**: Models use `@Model` macro on `final class`, `@Attribute(.unique)` for cache IDs
- **Naming**: PascalCase for types, camelCase for functions/variables
- **Access Control**: Mark helpers as `private`
- **Concurrency**: ViewModels are `@MainActor @Observable`. Protocols inherit `Sendable`. NetworkClient is an `actor`.
- **Accessibility**: `AnimationConfig` respects reduce-motion preferences — use it for all animations

## iOS Development Rules

- Never modify `.xcodeproj` signing, build settings, or xcconfig files unless explicitly asked
- When adding new Swift files, ensure they are added to the **main app target**, not the test target
- Make minimal, targeted changes — do not modify unrelated code or remove existing functionality
- After any code change, verify it compiles by running a build before reporting completion

## Testing

Tests use Swift Testing framework. Test files are in `WeatherAppTests/` and `WeatherAppUITests/`.

Key test areas:
- `GoogleWeatherDecodingTests`: API response decoding
- `GoogleWeatherServiceTests`: Service integration tests

Useful testing locations: San Francisco (37.7749, -122.4194) for WeatherKit + NOAA, London (51.5074, -0.1278) for international sources.
