# App Store Readiness — Crash & Rejection Fixes

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all critical crashes, App Store rejection blockers, major UX error-handling gaps, and accessibility issues identified in the pre-submission audit.

**Architecture:** Fixes are isolated across Info.plist, the app entry point, three weather services, the comparison ViewModel/View, two location UI components, and scattered accessibility/logging improvements. No new files or abstractions needed — all changes are targeted patches in existing files.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, WeatherKit, Swift Testing

---

## Task 1: Info.plist — Privacy string, background mode, cruft

**Files:**
- Modify: `WeatherApp/WeatherApp/Info.plist`

- [ ] **Step 1: Add location privacy string, remove undeclared background mode, remove empty directions key**

Replace the entire contents of `WeatherApp/WeatherApp/Info.plist` with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CLOUD_RUN_PROXY_API_KEY</key>
	<string>$(CLOUD_RUN_PROXY_API_KEY)</string>
	<key>CLOUD_RUN_PROXY_URL</key>
	<string>$(CLOUD_RUN_PROXY_URL)</string>
	<key>GCP_API_KEY</key>
	<string>$(GCP_API_KEY)</string>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>WeatherApp uses your location to show current conditions and forecasts for where you are.</string>
	<key>OWM_API_KEY</key>
	<string>$(OWM_API_KEY)</string>
	<key>TOMORROW_API_KEY</key>
	<string>$(TOMORROW_API_KEY)</string>
</dict>
</plist>
```

- [ ] **Step 2: Build and verify no errors**

```bash
xcodebuild -project WeatherApp/WeatherApp.xcodeproj -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add WeatherApp/WeatherApp/Info.plist
git commit -m "fix: add NSLocationWhenInUseUsageDescription, remove unused background mode"
```

---

## Task 2: WeatherAppApp.swift — Graceful SwiftData failure

**Files:**
- Modify: `WeatherApp/WeatherApp/WeatherAppApp.swift`

- [ ] **Step 1: Replace fatalError with graceful init + error view**

Replace the entire file with:

```swift
//
//  WeatherAppApp.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI
import SwiftData

@main
struct WeatherAppApp: App {
    private let modelContainer: ModelContainer?

    init() {
        let schema = Schema([
            SavedLocation.self,
            CachedWeather.self,
            SearchHistory.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        modelContainer = try? ModelContainer(for: schema, configurations: [modelConfiguration])
    }

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                ContentView()
                    .modelContainer(container)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("Unable to Load App Data")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("There was a problem loading saved data. Try restarting the app. If the problem persists, reinstall WeatherApp.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding()
            }
        }
    }
}
```

- [ ] **Step 2: Build and verify**

```bash
xcodebuild -project WeatherApp/WeatherApp.xcodeproj -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add WeatherApp/WeatherApp/WeatherAppApp.swift
git commit -m "fix: replace fatalError on SwiftData init with graceful error screen"
```

---

## Task 3: WeatherKitService.swift — Remove fatalError from retry loop

**Files:**
- Modify: `WeatherApp/WeatherApp/Services/Weather/WeatherKitService.swift`

- [ ] **Step 1: Replace fatalError with a throw**

In `WeatherKitService.swift`, replace the entire `retry` function (lines 59–71):

```swift
private func retry<T>(attempts: Int, delay: Double, operation: @escaping () async throws -> T) async throws -> T {
    for i in 0..<attempts {
        do {
            return try await operation()
        } catch {
            if i == attempts - 1 {
                throw APIError.networkError(error)
            }
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
    }
    throw APIError.networkError(URLError(.timedOut))
}
```

- [ ] **Step 2: Build and verify**

```bash
xcodebuild -project WeatherApp/WeatherApp.xcodeproj -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add WeatherApp/WeatherApp/Services/Weather/WeatherKitService.swift
git commit -m "fix: replace unreachable fatalError in retry loop with throw"
```

---

## Task 4: OpenWeatherMapService.swift — Fix three force unwraps

**Files:**
- Modify: `WeatherApp/WeatherApp/Services/Weather/OpenWeatherMapService.swift`

- [ ] **Step 1: Fix force unwrap in convertCurrentWeather (line 82)**

Replace in `convertCurrentWeather`:

```swift
// BEFORE
let weatherInfo = response.weather.first!
```

```swift
// AFTER
let weatherInfo = response.weather.first ?? OWMWeather(id: 800, main: "Clear", description: "clear sky", icon: "01d")
```

- [ ] **Step 2: Fix force unwrap in convertHourlyForecast (line 102)**

Replace in `convertHourlyForecast`:

```swift
// BEFORE
let weatherInfo = item.weather.first!
```

```swift
// AFTER
let weatherInfo = item.weather.first ?? OWMWeather(id: 800, main: "Clear", description: "clear sky", icon: "01d")
```

- [ ] **Step 3: Fix force unwrap in convertDailyForecasts (line 139)**

Replace in `convertDailyForecasts`, inside the `compactMap` closure:

```swift
// BEFORE
let middayItem = dayItems[dayItems.count / 2]
let weatherInfo = middayItem.weather.first!
```

```swift
// AFTER
guard !dayItems.isEmpty else { return nil }
let middayItem = dayItems[dayItems.count / 2]
let weatherInfo = middayItem.weather.first ?? OWMWeather(id: 800, main: "Clear", description: "clear sky", icon: "01d")
```

- [ ] **Step 4: Make OWMWeather memberwise-initializable**

`OWMWeather` is a `struct` with a Codable conformance and `let` stored properties. In Swift, structs get a memberwise initializer automatically, so `OWMWeather(id:main:description:icon:)` already works. Verify by searching:

```bash
grep -n "struct OWMWeather" WeatherApp/WeatherApp/Models/API/OpenWeatherMapModels.swift
```

Expected output includes `struct OWMWeather: Codable {`

- [ ] **Step 5: Build and verify**

```bash
xcodebuild -project WeatherApp/WeatherApp.xcodeproj -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add WeatherApp/WeatherApp/Services/Weather/OpenWeatherMapService.swift
git commit -m "fix: replace force unwraps in OWM service with safe fallbacks"
```

---

## Task 5: ComparisonViewModel.swift — Fix force unwraps + add error state

**Files:**
- Modify: `WeatherApp/WeatherApp/ViewModels/ComparisonViewModel.swift`

Context: `values.min()!` and `values.max()!` appear inside a `compactMap` closure that already guards `values.count >= 2`, so they're practically safe — but the compiler has no way to know that. Replace them with nil-coalescing. Also add an `analysisError` property so the view can show failure.

- [ ] **Step 1: Add error property and make analyzeWeatherData set it on failure**

At the top of the class, after `var comparisonData: ComparisonData?`, add:

```swift
var analysisError: String?
```

Wrap the body of `analyzeWeatherData` in a do/catch to catch unexpected errors, setting `analysisError` if anything throws. The function currently doesn't throw, so this is a defensive change — just add a guard at the top that clears state:

Replace the first two lines of `analyzeWeatherData`:

```swift
// BEFORE
func analyzeWeatherData(_ weatherData: WeatherData) {
    let now = Date()
```

```swift
// AFTER
func analyzeWeatherData(_ weatherData: WeatherData) {
    analysisError = nil
    comparisonData = nil
    let now = Date()
```

And at the bottom of the function (before the closing `}`), before `comparisonData = ...` is set, wrap the assignment defensively. Find the line that sets `comparisonData`:

```swift
// BEFORE (wherever comparisonData is assigned at end of analyzeWeatherData)
comparisonData = ComparisonData(...)
```

No structural change needed here — just add the `analysisError = nil` reset at the start.

- [ ] **Step 2: Fix the two force unwraps in buildUncertaintyBands (lines 126–127)**

Replace:

```swift
let min = values.min()!
let max = values.max()!
```

With:

```swift
guard let min = values.min(), let max = values.max() else { return nil }
```

(This is inside a `compactMap` closure, so `return nil` skips the point cleanly.)

- [ ] **Step 3: Build and verify**

```bash
xcodebuild -project WeatherApp/WeatherApp.xcodeproj -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add WeatherApp/WeatherApp/ViewModels/ComparisonViewModel.swift
git commit -m "fix: safe unwraps in comparison analysis, add analysisError state"
```

---

## Task 6: ForecastComparisonView.swift — Show error state instead of infinite spinner

**Files:**
- Modify: `WeatherApp/WeatherApp/Views/Comparison/ForecastComparisonView.swift`

- [ ] **Step 1: Replace the bare ProgressView with a three-branch state**

In `ForecastComparisonView.body`, replace the `else` branch of `if let data = viewModel.comparisonData`:

```swift
// BEFORE
} else {
    ProgressView()
        .frame(maxWidth: .infinity, minHeight: 400)
}
```

```swift
// AFTER
} else if let errorMessage = viewModel.analysisError {
    VStack(spacing: 16) {
        Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 36))
            .foregroundStyle(.orange)
        Text("Unable to compare forecasts")
            .font(.headline)
        Text(errorMessage)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
        Button("Try Again") {
            viewModel.analyzeWeatherData(weatherData)
        }
        .buttonStyle(.bordered)
    }
    .frame(maxWidth: .infinity, minHeight: 400)
} else {
    ProgressView()
        .frame(maxWidth: .infinity, minHeight: 400)
}
```

- [ ] **Step 2: Build and verify**

```bash
xcodebuild -project WeatherApp/WeatherApp.xcodeproj -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add WeatherApp/WeatherApp/Views/Comparison/ForecastComparisonView.swift
git commit -m "fix: show error state in ForecastComparisonView instead of infinite spinner"
```

---

## Task 7: LocationSearchView.swift + ExpandableSearchBar.swift — Surface geocoding errors

**Files:**
- Modify: `WeatherApp/WeatherApp/Views/Search/LocationSearchView.swift`
- Modify: `WeatherApp/WeatherApp/Views/Search/ExpandableSearchBar.swift`

Both files have a `resolveCurrentLocation` function that silently swallows geocoding errors. Add a `locationError` state variable and display an alert.

- [ ] **Step 1: Add error state to LocationSearchView**

Find the `@State private var pendingLocationSelection = false` line in `LocationSearchView` and add after it:

```swift
@State private var locationError: String?
```

- [ ] **Step 2: Set the error in LocationSearchView.resolveCurrentLocation**

Replace the `catch` block in `resolveCurrentLocation`:

```swift
// BEFORE
} catch {
    // Silently fail - user can still tap to retry
    await MainActor.run {
        pendingLocationSelection = false
    }
}
```

```swift
// AFTER
} catch {
    await MainActor.run {
        pendingLocationSelection = false
        locationError = "Couldn't determine your location. Check your connection and try again."
    }
}
```

- [ ] **Step 3: Show alert for locationError in LocationSearchView**

Find the `.onAppear` or the outermost view modifier chain in `LocationSearchView.body` and add:

```swift
.alert("Location Unavailable", isPresented: Binding(
    get: { locationError != nil },
    set: { if !$0 { locationError = nil } }
)) {
    Button("OK", role: .cancel) { locationError = nil }
} message: {
    Text(locationError ?? "")
}
```

- [ ] **Step 4: Apply the same fix to ExpandableSearchBar**

In `ExpandableSearchBar`, find the `@State private var pendingLocationSelection = false` and add:

```swift
@State private var locationError: String?
```

Replace the `catch` block in `ExpandableSearchBar.resolveCurrentLocation`:

```swift
// BEFORE
} catch {
    await MainActor.run {
        pendingLocationSelection = false
    }
}
```

```swift
// AFTER
} catch {
    await MainActor.run {
        pendingLocationSelection = false
        locationError = "Couldn't determine your location. Check your connection and try again."
    }
}
```

Add the same alert modifier to `ExpandableSearchBar.body`'s outermost view.

- [ ] **Step 5: Build and verify**

```bash
xcodebuild -project WeatherApp/WeatherApp.xcodeproj -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add WeatherApp/WeatherApp/Views/Search/LocationSearchView.swift \
        WeatherApp/WeatherApp/Views/Search/ExpandableSearchBar.swift
git commit -m "fix: surface geocoding errors to user in location search views"
```

---

## Task 8: Accessibility — Labels on icon-only buttons

**Files:**
- Modify: `WeatherApp/WeatherApp/Views/Components/SourceErrorBanner.swift`
- Modify: `WeatherApp/WeatherApp/Views/Main/WeatherMainView.swift`

- [ ] **Step 1: Add label to SourceErrorBanner retry button**

In `SourceErrorBanner.swift`, the retry button uses `Image(systemName: "arrow.clockwise")` with no text. Add `.accessibilityLabel`:

```swift
// BEFORE
Button {
    onRefresh(source)
} label: {
    Image(systemName: "arrow.clockwise")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.blue)
}
.buttonStyle(.plain)
```

```swift
// AFTER
Button {
    onRefresh(source)
} label: {
    Image(systemName: "arrow.clockwise")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.blue)
}
.buttonStyle(.plain)
.accessibilityLabel("Retry \(source.shortName)")
```

- [ ] **Step 2: Add label to WeatherMainView Compare Sources button**

The Compare Sources button has a text label alongside the icon, so VoiceOver reads the text. No change needed there.

Check the back/navigation button and any other icon-only tappable elements. The source picker uses text labels (`.shortName`), so it's already accessible.

- [ ] **Step 3: Build and verify**

```bash
xcodebuild -project WeatherApp/WeatherApp.xcodeproj -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Commit**

```bash
git add WeatherApp/WeatherApp/Views/Components/SourceErrorBanner.swift
git commit -m "fix: add accessibilityLabel to icon-only retry buttons in SourceErrorBanner"
```

---

## Task 9: Wrap debug print() statements in #if DEBUG

**Files:**
- Modify: `WeatherApp/WeatherApp/Services/Weather/TomorrowIOService.swift`
- Modify: `WeatherApp/WeatherApp/Services/Weather/WeatherAggregator.swift`
- Modify: `WeatherApp/WeatherApp/Services/Weather/WeatherCacheService.swift`
- Modify: `WeatherApp/WeatherApp/Services/Weather/WeatherKitService.swift`
- Modify: `WeatherApp/WeatherApp/Services/Weather/GoogleWeatherService.swift`

All `print()` calls in these services fire in production builds, growing device logs and potentially surfacing error details. Guard them with `#if DEBUG`.

- [ ] **Step 1: TomorrowIOService.swift — wrap all prints**

In `TomorrowIOService.swift`, there are 4 print calls. Wrap each in `#if DEBUG … #endif`:

Line 34:
```swift
// BEFORE
print("[TomorrowIO] API key not configured")
```
```swift
// AFTER
#if DEBUG
print("[TomorrowIO] API key not configured")
#endif
```

Line 58:
```swift
// BEFORE
print("[TomorrowIO] Requesting: \(url)")
```
```swift
// AFTER
#if DEBUG
print("[TomorrowIO] Requesting: \(url)")
#endif
```

Line 64:
```swift
// BEFORE
print("[TomorrowIO] Received response with \(response.data.timelines.count) timelines")
```
```swift
// AFTER
#if DEBUG
print("[TomorrowIO] Received response with \(response.data.timelines.count) timelines")
#endif
```

Line 67:
```swift
// BEFORE
print("[TomorrowIO] Request failed: \(error)")
```
```swift
// AFTER
#if DEBUG
print("[TomorrowIO] Request failed: \(error)")
#endif
```

- [ ] **Step 2: WeatherAggregator.swift — wrap all prints**

Wrap each of the 7 print calls (lines 55, 58, 61, 63, 75, 80, 82) in `#if DEBUG … #endif`. Pattern:

```swift
#if DEBUG
print("...")
#endif
```

- [ ] **Step 3: WeatherCacheService.swift — wrap all prints**

Wrap the 5 print calls (lines 47, 67, 82, 102, 117) in `#if DEBUG … #endif`.

- [ ] **Step 4: WeatherKitService.swift — wrap all prints**

Wrap the 2 print calls (lines 46 multi-line, 53, 119) in `#if DEBUG … #endif`. The multi-line print:

```swift
// BEFORE
print("""
⚠️ WEATHERKIT PROVISIONING ERROR:
...
""")
```

```swift
// AFTER
#if DEBUG
print("""
⚠️ WEATHERKIT PROVISIONING ERROR:
...
""")
#endif
```

- [ ] **Step 5: GoogleWeatherService.swift — wrap the print**

```swift
// BEFORE
print("[Google Weather] API key not configured")
```
```swift
// AFTER
#if DEBUG
print("[Google Weather] API key not configured")
#endif
```

- [ ] **Step 6: Build and verify**

```bash
xcodebuild -project WeatherApp/WeatherApp.xcodeproj -scheme WeatherApp \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit**

```bash
git add WeatherApp/WeatherApp/Services/Weather/TomorrowIOService.swift \
        WeatherApp/WeatherApp/Services/Weather/WeatherAggregator.swift \
        WeatherApp/WeatherApp/Services/Weather/WeatherCacheService.swift \
        WeatherApp/WeatherApp/Services/Weather/WeatherKitService.swift \
        WeatherApp/WeatherApp/Services/Weather/GoogleWeatherService.swift
git commit -m "fix: guard all debug print() calls with #if DEBUG in weather services"
```
