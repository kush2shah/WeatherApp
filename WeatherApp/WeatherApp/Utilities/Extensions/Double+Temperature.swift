//
//  Double+Temperature.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

extension Double {
    /// Convert Celsius to Fahrenheit
    var celsiusToFahrenheit: Double {
        self * 9/5 + 32
    }

    /// Convert Fahrenheit to Celsius
    var fahrenheitToCelsius: Double {
        (self - 32) * 5/9
    }

    /// Format temperature as string with degree symbol
    func temperatureString(unit: TemperatureUnit = .fahrenheit) -> String {
        let displayTemp: Double
        switch unit {
        case .celsius:
            displayTemp = self
        case .fahrenheit:
            displayTemp = self.celsiusToFahrenheit
        }
        return "\(Int(displayTemp))°"
    }
}

/// Temperature unit preference
enum TemperatureUnit: String, CaseIterable, Codable {
    case celsius = "C"
    case fahrenheit = "F"

    var symbol: String {
        "°\(rawValue)"
    }

    var displayName: String {
        switch self {
        case .celsius: return "Celsius"
        case .fahrenheit: return "Fahrenheit"
        }
    }
}

/// Wind speed unit options
enum WindSpeedUnit: String, CaseIterable, Codable {
    case milesPerHour = "mph"
    case kilometersPerHour = "kmh"
    case metersPerSecond = "ms"

    var symbol: String {
        switch self {
        case .milesPerHour: return "mph"
        case .kilometersPerHour: return "km/h"
        case .metersPerSecond: return "m/s"
        }
    }

    var displayName: String {
        switch self {
        case .milesPerHour: return "Miles per hour"
        case .kilometersPerHour: return "Kilometers per hour"
        case .metersPerSecond: return "Meters per second"
        }
    }
}

/// Pressure unit options
enum PressureUnit: String, CaseIterable, Codable {
    case hectopascals = "hPa"
    case inchesOfMercury = "inHg"

    var symbol: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .hectopascals: return "Hectopascals"
        case .inchesOfMercury: return "Inches of Mercury"
        }
    }
}

/// Visibility unit options
enum VisibilityUnit: String, CaseIterable, Codable {
    case kilometers = "km"
    case miles = "mi"

    var symbol: String {
        rawValue
    }

    var displayName: String {
        switch self {
        case .kilometers: return "Kilometers"
        case .miles: return "Miles"
        }
    }
}
