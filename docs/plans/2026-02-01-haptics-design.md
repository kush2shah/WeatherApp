# Haptic Feedback Design

## Overview

Add rich, contextual haptic feedback throughout the WeatherApp. Haptics use a hybrid approach: functional patterns for general interactions plus weather-themed patterns that give each condition a distinct tactile signature.

## Architecture

**File:** `WeatherApp/Utilities/Haptics/HapticManager.swift`

Singleton class owning all haptic generators with semantic methods for each interaction type.

```swift
final class HapticManager {
    static let shared = HapticManager()

    private let impact = UIImpactFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    private init() {
        impact.prepare()
        selection.prepare()
    }
}
```

## Functional Patterns

Medium intensity baseline for most interactions.

| Method | Pattern | Use Case |
|--------|---------|----------|
| `selection()` | Single medium impact | Picker changes, source toggles, list selections |
| `confirm()` | Soft impact → 50ms → medium impact | Successful completions (location selected, data loaded) |
| `error()` | Triple quick rigid impacts (60ms apart) | Failed requests, permission denied |
| `refresh()` | Light impact → 80ms → soft impact | Weather data refresh complete |
| `buttonTap()` | Single light impact | General interactive buttons |
| `sheetPresented()` | Heavy impact, low intensity | Bottom sheets appearing |

## Weather-Themed Patterns

Each weather condition has a distinct tactile signature, triggered when selecting daily forecasts.

| Condition | Pattern | Sensation |
|-----------|---------|-----------|
| **Sunny/Clear** | Single crisp medium impact | Clean, bright, decisive |
| **Cloudy** | Soft impact → 40ms → softer impact | Muted, pillowy layers |
| **Rainy** | 4 quick light taps (30-50ms gaps, irregular) | Pitter-patter of raindrops |
| **Stormy** | Heavy impact → 100ms → 3 rapid rigid taps | Thunder crack then rumble |
| **Snowy** | 2 very soft impacts, 80ms apart | Gentle, quiet, muffled |
| **Windy** | Light → medium → light (40ms gaps) | Sweeping, passing through |
| **Foggy** | Single very soft, low-intensity impact | Barely there, obscured |

## Integration Points

Excludes ContentView home/launch states (handled elsewhere).

### LocationSearchView
- Current Location button tap → `buttonTap()`
- Location resolved successfully → `confirm()`
- Search result selected → `confirm()`
- Recent search selected → `selection()`
- Clear history tapped → `buttonTap()`
- Permission denied alert → `error()`

### WeatherMainView
- Source picker changed → `selection()`
- Compare Sources button → `buttonTap()`
- Weather data refresh complete → `refresh()`
- Source refresh failed → `error()`

### DailyForecastCard
- Daily row tapped → `weatherSelection(day.condition)`

### DailyDetailView
- Sheet appears → `sheetPresented()`
- Source picker button changed → `selection()`
- "Compare" mode selected → `buttonTap()`

### SettingsView
- Any picker changed → `selection()`

### ForecastComparisonView
- Metric picker changed → `selection()`

## User Settings

None for now. Haptics always enabled (respects system-level settings). May add toggle later alongside other settings.

## Implementation Notes

- Pre-initialize generators in `HapticManager.init()` for lower latency
- Use `DispatchQueue.main.asyncAfter` for multi-tap sequences
- Weather condition routing via `weatherSelection(_ condition: WeatherCondition)` method
- Fallback to `selection()` for unknown weather conditions
