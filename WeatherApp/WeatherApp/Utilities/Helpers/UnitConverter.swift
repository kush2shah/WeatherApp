//
//  UnitConverter.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// Weather unit conversions
enum UnitConverter {
    // MARK: - Temperature

    static func celsiusToFahrenheit(_ celsius: Double) -> Double {
        celsius * 9/5 + 32
    }

    static func fahrenheitToCelsius(_ fahrenheit: Double) -> Double {
        (fahrenheit - 32) * 5/9
    }

    // MARK: - Speed

    static func metersPerSecondToMph(_ ms: Double) -> Double {
        ms * 2.23694
    }

    static func mphToMetersPerSecond(_ mph: Double) -> Double {
        mph / 2.23694
    }

    static func metersPerSecondToKph(_ ms: Double) -> Double {
        ms * 3.6
    }

    static func kphToMetersPerSecond(_ kph: Double) -> Double {
        kph / 3.6
    }

    // MARK: - Pressure

    static func hPaToInHg(_ hPa: Double) -> Double {
        hPa * 0.02953
    }

    static func inHgToHPa(_ inHg: Double) -> Double {
        inHg / 0.02953
    }

    // MARK: - Distance

    static func metersToKilometers(_ meters: Double) -> Double {
        meters / 1000
    }

    static func metersToMiles(_ meters: Double) -> Double {
        meters * 0.000621371
    }

    static func kilometersToMiles(_ km: Double) -> Double {
        km * 0.621371
    }

    static func milesToKilometers(_ miles: Double) -> Double {
        miles / 0.621371
    }

    // MARK: - Precipitation

    static func mmToInches(_ mm: Double) -> Double {
        mm * 0.0393701
    }

    static func inchesToMm(_ inches: Double) -> Double {
        inches / 0.0393701
    }
}
