# Current Location Button

## Overview

Add a "Current Location" option at the top of the location search view that uses GPS to fetch weather for the user's current position.

## UI States

| State | Primary Text | Secondary Text |
|-------|--------------|----------------|
| Not determined | Current Location | — |
| Authorized, waiting | Current Location | — |
| Authorized, resolved | Current Location | "San Francisco, CA" *(fades in)* |
| Denied | Current Location | "Location access denied" |

## Behavior

- **On appear:** If location permission is authorized, silently fetch GPS location in background
- **When resolved:** Reverse geocode coordinates, display location name with fade-in animation that pushes content down
- **On tap:** If location already resolved, use it immediately; otherwise request location and wait

## Implementation

### Changes to LocationSearchView

1. Add `LocationManager` as `@State` property
2. Add `GeocodingService` for reverse geocoding
3. Add `@State` for resolved `Location?`
4. Add "Current Location" section at top of list (when search query is empty)
5. On `.onAppear`, if authorized, trigger background location fetch
6. When `locationManager.currentLocation` updates, reverse geocode and animate in result

### UI Details

- Icon: `location.fill` (SF Symbol)
- Animation: `.easeInOut` for subtitle fade-in
- Denied state: Tapping shows alert with option to open Settings

## Files Modified

- `WeatherApp/Views/Search/LocationSearchView.swift`
