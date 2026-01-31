//
//  Config.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// Application configuration
enum Config {
    /// OpenWeatherMap API key
    /// Sign up at: https://openweathermap.org/api
    /// Free tier: 1,000 calls/day
    static let openWeatherMapAPIKey: String = {
        // Try environment variable first
        if let key = ProcessInfo.processInfo.environment["OWM_API_KEY"], !key.isEmpty {
            return key
        }
        // Fallback to hardcoded value (for development only - never commit this!)
        return ""
    }()

    /// Tomorrow.io API key
    /// Sign up at: https://www.tomorrow.io/weather-api/
    /// Free tier: 500 calls/day, 25 calls/hour
    static let tomorrowIOAPIKey: String = {
        // Try environment variable first
        if let key = ProcessInfo.processInfo.environment["TOMORROW_API_KEY"], !key.isEmpty {
            return key
        }
        // Fallback to hardcoded value (for development only - never commit this!)
        return ""
    }()

    /// Google Weather API key
    /// Sign up at: https://console.cloud.google.com/apis/library/weather.googleapis.com
    /// Requires: Google Cloud Platform project with billing enabled
    static let googleWeatherAPIKey: String = {
        // Try Info.plist first (GCP_API_KEY)
        if let key = Bundle.main.object(forInfoDictionaryKey: "GCP_API_KEY") as? String, !key.isEmpty {
            return key
        }
        // Fallback to environment variable
        if let key = ProcessInfo.processInfo.environment["GOOGLE_WEATHER_API_KEY"], !key.isEmpty {
            return key
        }
        // Fallback to hardcoded value (for development only - never commit this!)
        return ""
    }()

    /// Check which weather sources are enabled
    static var enabledSources: [WeatherSource] {
        var sources: [WeatherSource] = [.weatherKit, .noaa]

        if !openWeatherMapAPIKey.isEmpty {
            sources.append(.openWeatherMap)
        }

        if !googleWeatherAPIKey.isEmpty {
            sources.append(.googleWeather)
        }

        if !tomorrowIOAPIKey.isEmpty {
            sources.append(.tomorrowIO)
        }

        return sources
    }

    /// Check if a specific source is enabled
    static func isSourceEnabled(_ source: WeatherSource) -> Bool {
        enabledSources.contains(source)
    }
}
