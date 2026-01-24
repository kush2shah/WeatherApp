# WeatherApp - Project Overview

## Purpose
WeatherApp is an iOS application being developed using SwiftUI and SwiftData. Currently, it's a starter project with basic SwiftData integration showing a sample Item model with CRUD operations.

## Tech Stack
- **Language**: Swift 6.2.1 (Swift language version 5.0 in project settings)
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Testing Framework**: Swift Testing (using `@Test` attribute and `#expect` API)
- **Target Platform**: iOS 26.0+
- **License**: MIT License (Copyright 2026 Kush Shah)

## Project Structure
```
WeatherApp/
├── WeatherApp/              # Main application code
│   ├── WeatherAppApp.swift  # App entry point with @main
│   ├── ContentView.swift    # Main view
│   ├── Item.swift           # SwiftData model
│   ├── Assets.xcassets/     # App assets
│   ├── Info.plist          # App configuration
│   └── WeatherApp.entitlements
├── WeatherAppTests/         # Unit tests
└── WeatherAppUITests/       # UI tests
```

## Key Components
- **WeatherAppApp**: Main app struct using SwiftData ModelContainer
- **ContentView**: NavigationSplitView showing list of Items
- **Item**: SwiftData model with timestamp property
