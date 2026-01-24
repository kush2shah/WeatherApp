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
enum TemperatureUnit: String, Codable {
    case celsius = "C"
    case fahrenheit = "F"

    var symbol: String {
        "°\(rawValue)"
    }
}
