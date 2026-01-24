# Code Style and Conventions

## File Headers
Every Swift file includes a standard header comment:
```swift
//
//  FileName.swift
//  WeatherApp
//
//  Created by Kush Shah on MM/DD/YY.
//
```

## Naming Conventions
- **Types**: PascalCase (e.g., `Item`, `ContentView`, `WeatherAppApp`)
- **Variables/Functions**: camelCase (e.g., `modelContext`, `addItem`, `deleteItems`)
- **Private functions**: Use `private` access control modifier

## SwiftUI Patterns
- Use property wrappers appropriately:
  - `@Environment` for dependency injection
  - `@Query` for SwiftData queries
  - `@Model` for SwiftData models
- Use `#Preview` macro for SwiftUI previews

## SwiftData Patterns
- Models use `@Model` macro
- Use `final class` for model classes
- Initialize ModelContainer in app struct
- Use `.modelContainer()` modifier to inject into view hierarchy

## Testing Patterns
- Use Swift Testing framework (not XCTest)
- Test functions marked with `@Test` attribute
- Use `#expect(...)` for assertions
- Import module with `@testable import WeatherApp`
- Test structs instead of classes

## Code Organization
- Entry point: Use `@main` attribute on App struct
- Helper functions: Mark as `private` and place after main view body
- Animations: Wrap state changes in `withAnimation { }`
