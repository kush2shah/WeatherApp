//
//  WeatherFormatter.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/26/26.
//

import Foundation

/// Centralized weather data formatting service
/// Single source of truth for all weather unit conversions and formatting
final class WeatherFormatter {
    static let shared = WeatherFormatter()

    private let preferences = UserPreferences.shared

    private init() {}

    // MARK: - Temperature

    /// Format temperature value according to user preferences
    /// - Parameter value: Temperature in Celsius
    /// - Returns: Formatted temperature string with unit symbol
    func temperature(_ value: Double) -> String {
        let displayValue: Double
        let unit = preferences.temperatureUnit

        switch unit {
        case .celsius:
            displayValue = value
        case .fahrenheit:
            displayValue = celsiusToFahrenheit(value)
        }

        return String(format: "%.0f%@", displayValue, unit.symbol)
    }

    /// Format temperature value as integer according to user preferences
    /// - Parameter value: Temperature in Celsius
    /// - Returns: Integer temperature with unit symbol
    func temperatureInt(_ value: Double) -> String {
        let displayValue: Double
        let unit = preferences.temperatureUnit

        switch unit {
        case .celsius:
            displayValue = value
        case .fahrenheit:
            displayValue = celsiusToFahrenheit(value)
        }

        return "\(Int(displayValue))\(unit.symbol)"
    }

    // MARK: - Wind Speed

    /// Format wind speed according to user preferences
    /// - Parameter value: Wind speed in meters per second
    /// - Returns: Formatted wind speed string with unit symbol
    func wind(_ value: Double) -> String {
        let displayValue: Double
        let unit = preferences.windSpeedUnit

        switch unit {
        case .milesPerHour:
            displayValue = metersPerSecondToMph(value)
        case .kilometersPerHour:
            displayValue = metersPerSecondToKph(value)
        case .metersPerSecond:
            displayValue = value
        }

        return String(format: "%.0f %@", displayValue, unit.symbol)
    }

    // MARK: - Pressure

    /// Format pressure according to user preferences
    /// - Parameter value: Pressure in hectopascals (hPa)
    /// - Returns: Formatted pressure string with unit symbol
    func pressure(_ value: Double) -> String {
        let displayValue: Double
        let unit = preferences.pressureUnit

        switch unit {
        case .hectopascals:
            displayValue = value
        case .inchesOfMercury:
            displayValue = hPaToInHg(value)
        }

        return String(format: "%.2f %@", displayValue, unit.symbol)
    }

    // MARK: - Visibility

    /// Format visibility according to user preferences
    /// - Parameter value: Visibility in meters
    /// - Returns: Formatted visibility string with unit symbol
    func visibility(_ value: Double) -> String {
        let displayValue: Double
        let unit = preferences.visibilityUnit

        switch unit {
        case .kilometers:
            displayValue = metersToKilometers(value)
        case .miles:
            displayValue = metersToMiles(value)
        }

        return String(format: "%.1f %@", displayValue, unit.symbol)
    }

    // MARK: - Percentage

    /// Format percentage value
    /// - Parameter value: Value between 0.0 and 1.0
    /// - Returns: Formatted percentage string
    func percentage(_ value: Double) -> String {
        let normalizedValue = min(max(value, 0.0), 1.0)
        return "\(Int(normalizedValue * 100))%"
    }

    // MARK: - Date/Time

    /// Format date with timezone
    /// - Parameters:
    ///   - date: Date to format
    ///   - timezone: Timezone for formatting
    ///   - style: Date format style (short, medium, long)
    /// - Returns: Formatted date string
    func date(_ date: Date, timezone: TimeZone, style: DateStyle = .medium) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone

        switch style {
        case .short:
            formatter.dateFormat = "EEE"
        case .medium:
            formatter.dateFormat = "EEEE"
        case .long:
            formatter.dateFormat = "EEEE, MMM d"
        case .time:
            formatter.dateFormat = "h a"
        case .fullTime:
            formatter.dateFormat = "h:mm a"
        }

        return formatter.string(from: date)
    }

    // MARK: - Private Conversion Methods

    // Temperature
    private func celsiusToFahrenheit(_ celsius: Double) -> Double {
        celsius * 9 / 5 + 32
    }

    // Wind Speed
    private func metersPerSecondToMph(_ ms: Double) -> Double {
        ms * 2.23694
    }

    private func metersPerSecondToKph(_ ms: Double) -> Double {
        ms * 3.6
    }

    // Pressure
    private func hPaToInHg(_ hPa: Double) -> Double {
        hPa * 0.02953
    }

    // Distance/Visibility
    private func metersToKilometers(_ meters: Double) -> Double {
        meters / 1000
    }

    private func metersToMiles(_ meters: Double) -> Double {
        meters * 0.000621371
    }
}

// MARK: - Date Style Enum

enum DateStyle {
    case short      // "Mon"
    case medium     // "Monday"
    case long       // "Monday, Jan 26"
    case time       // "3 PM"
    case fullTime   // "3:30 PM"
}
