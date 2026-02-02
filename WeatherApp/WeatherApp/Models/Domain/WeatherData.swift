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
    let sourceErrors: [WeatherSource: String]
    let fetchedAt: Date

    init(
        id: UUID = UUID(),
        location: Location,
        sources: [WeatherSource: SourcedWeatherInfo],
        sourceErrors: [WeatherSource: String] = [:],
        fetchedAt: Date = Date()
    ) {
        self.id = id
        self.location = location
        self.sources = sources
        self.sourceErrors = sourceErrors
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

    /// Get today's sunrise, preferring the specified source but falling back to others
    func todaySunrise(preferring source: WeatherSource) -> Date? {
        // Try preferred source first
        if let weather = sources[source],
           let sunrise = weather.daily.first?.sunrise {
            return sunrise
        }
        // Fallback: check all sources
        for availableSource in availableSources {
            if let weather = sources[availableSource],
               let sunrise = weather.daily.first?.sunrise {
                return sunrise
            }
        }
        return nil
    }

    /// Get today's sunset, preferring the specified source but falling back to others
    func todaySunset(preferring source: WeatherSource) -> Date? {
        // Try preferred source first
        if let weather = sources[source],
           let sunset = weather.daily.first?.sunset {
            return sunset
        }
        // Fallback: check all sources
        for availableSource in availableSources {
            if let weather = sources[availableSource],
               let sunset = weather.daily.first?.sunset {
                return sunset
            }
        }
        return nil
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
    case googleWeather = "Google Weather"
    case noaa = "NOAA/NWS"
    case openWeatherMap = "OpenWeatherMap"
    case tomorrowIO = "Tomorrow.io"

    /// Default attribution text for the source
    var defaultAttribution: String {
        switch self {
        case .weatherKit:
            return "Weather data provided by Apple WeatherKit"
        case .googleWeather:
            return "Weather data provided by Google Weather API"
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
            return "Apple"
        case .googleWeather:
            return "Google"
        case .noaa:
            return "NOAA"
        case .openWeatherMap:
            return "OWM"
        case .tomorrowIO:
            return "Tomorrow.io"
        }
    }
}
