//
//  WeatherData.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// Unified weather data from multiple sources
struct WeatherData: Identifiable, Codable, Sendable {
    let id: UUID
    let location: Location
    let sources: [WeatherSource: SourcedWeatherInfo]
    let fetchedAt: Date

    init(
        id: UUID = UUID(),
        location: Location,
        sources: [WeatherSource: SourcedWeatherInfo],
        fetchedAt: Date = Date()
    ) {
        self.id = id
        self.location = location
        self.sources = sources
        self.fetchedAt = fetchedAt
    }

    /// Get weather from a specific source
    func weather(from source: WeatherSource) -> SourcedWeatherInfo? {
        sources[source]
    }

    /// Available sources for this location
    var availableSources: [WeatherSource] {
        Array(sources.keys).sorted { $0.rawValue < $1.rawValue }
    }

    /// Primary source (first available, preferring WeatherKit)
    var primarySource: WeatherSource? {
        if sources[.weatherKit] != nil {
            return .weatherKit
        }
        return availableSources.first
    }
}

/// Weather information from a specific source
struct SourcedWeatherInfo: Codable, Hashable, Sendable {
    let source: WeatherSource
    let current: CurrentWeather
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
    let attribution: String

    init(
        source: WeatherSource,
        current: CurrentWeather,
        hourly: [HourlyForecast],
        daily: [DailyForecast],
        attribution: String? = nil
    ) {
        self.source = source
        self.current = current
        self.hourly = hourly
        self.daily = daily
        self.attribution = attribution ?? source.defaultAttribution
    }
}

/// Weather data source
enum WeatherSource: String, Codable, CaseIterable, Hashable {
    case weatherKit = "Apple WeatherKit"
    case noaa = "NOAA/NWS"
    case openWeatherMap = "OpenWeatherMap"
    case tomorrowIO = "Tomorrow.io"

    /// Default attribution text for the source
    var defaultAttribution: String {
        switch self {
        case .weatherKit:
            return "Weather data provided by Apple WeatherKit"
        case .noaa:
            return "Weather data provided by NOAA National Weather Service"
        case .openWeatherMap:
            return "Weather data provided by OpenWeatherMap"
        case .tomorrowIO:
            return "Weather data provided by Tomorrow.io"
        }
    }

    /// Display name for UI
    var displayName: String {
        rawValue
    }

    /// Short name for charts
    var shortName: String {
        switch self {
        case .weatherKit:
            return "WeatherKit"
        case .noaa:
            return "NOAA"
        case .openWeatherMap:
            return "OWM"
        case .tomorrowIO:
            return "Tomorrow.io"
        }
    }
}
