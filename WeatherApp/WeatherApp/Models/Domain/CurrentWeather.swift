//
//  CurrentWeather.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// Current weather conditions
struct CurrentWeather: Codable, Hashable, Sendable {
    let temperature: Double // Celsius
    let apparentTemperature: Double // Feels like, Celsius
    let condition: WeatherCondition
    let conditionDescription: String
    let humidity: Double // 0.0 - 1.0
    let pressure: Double // hPa
    let windSpeed: Double // m/s
    let windDirection: Double? // degrees
    let uvIndex: Double?
    let visibility: Double? // meters
    let cloudCover: Double? // 0.0 - 1.0
    let dewPoint: Double? // Celsius
    let timestamp: Date

    /// Temperature in Fahrenheit
    var temperatureFahrenheit: Double {
        celsiusToFahrenheit(temperature)
    }

    /// Apparent temperature in Fahrenheit
    var apparentTemperatureFahrenheit: Double {
        celsiusToFahrenheit(apparentTemperature)
    }

    /// Humidity as percentage (0-100)
    var humidityPercentage: Int {
        Int(humidity * 100)
    }

    /// Cloud cover as percentage (0-100)
    var cloudCoverPercentage: Int? {
        guard let cloudCover = cloudCover else { return nil }
        return Int(cloudCover * 100)
    }

    /// Wind speed in mph
    var windSpeedMph: Double {
        metersPerSecondToMph(windSpeed)
    }

    /// Wind direction as cardinal direction (N, NE, E, etc.)
    var windDirectionCardinal: String? {
        guard let direction = windDirection else { return nil }
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let index = Int((direction + 22.5) / 45.0) % 8
        return directions[index]
    }

    // MARK: - Private Helpers

    private func celsiusToFahrenheit(_ celsius: Double) -> Double {
        celsius * 9/5 + 32
    }

    private func metersPerSecondToMph(_ ms: Double) -> Double {
        ms * 2.23694
    }
}
