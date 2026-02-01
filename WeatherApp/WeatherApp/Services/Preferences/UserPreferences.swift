//
//  UserPreferences.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/26/26.
//

import SwiftUI
import Foundation
import Combine

/// User preference singleton for weather unit settings
/// Note: Unit enums are defined in Double+Temperature.swift
final class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    // Detect default locale preference
    private static var defaultTemperatureUnit: TemperatureUnit {
        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit
    }

    private static var defaultWindSpeedUnit: WindSpeedUnit {
        Locale.current.measurementSystem == .metric ? .kilometersPerHour : .milesPerHour
    }

    private static var defaultPressureUnit: PressureUnit {
        Locale.current.measurementSystem == .metric ? .hectopascals : .inchesOfMercury
    }

    private static var defaultVisibilityUnit: VisibilityUnit {
        Locale.current.measurementSystem == .metric ? .kilometers : .miles
    }

    // MARK: - Unit Preferences
    // Using @Published with manual UserDefaults to ensure ObservableObject notifications work

    @Published var temperatureUnit: TemperatureUnit {
        didSet {
            UserDefaults.standard.set(temperatureUnit.rawValue, forKey: "temperatureUnit")
        }
    }

    @Published var windSpeedUnit: WindSpeedUnit {
        didSet {
            UserDefaults.standard.set(windSpeedUnit.rawValue, forKey: "windSpeedUnit")
        }
    }

    @Published var pressureUnit: PressureUnit {
        didSet {
            UserDefaults.standard.set(pressureUnit.rawValue, forKey: "pressureUnit")
        }
    }

    @Published var visibilityUnit: VisibilityUnit {
        didSet {
            UserDefaults.standard.set(visibilityUnit.rawValue, forKey: "visibilityUnit")
        }
    }

    private init() {
        // Load from UserDefaults or use defaults
        if let tempRaw = UserDefaults.standard.string(forKey: "temperatureUnit"),
           let temp = TemperatureUnit(rawValue: tempRaw) {
            self.temperatureUnit = temp
        } else {
            self.temperatureUnit = Self.defaultTemperatureUnit
        }

        if let windRaw = UserDefaults.standard.string(forKey: "windSpeedUnit"),
           let wind = WindSpeedUnit(rawValue: windRaw) {
            self.windSpeedUnit = wind
        } else {
            self.windSpeedUnit = Self.defaultWindSpeedUnit
        }

        if let pressureRaw = UserDefaults.standard.string(forKey: "pressureUnit"),
           let pressure = PressureUnit(rawValue: pressureRaw) {
            self.pressureUnit = pressure
        } else {
            self.pressureUnit = Self.defaultPressureUnit
        }

        if let visibilityRaw = UserDefaults.standard.string(forKey: "visibilityUnit"),
           let visibility = VisibilityUnit(rawValue: visibilityRaw) {
            self.visibilityUnit = visibility
        } else {
            self.visibilityUnit = Self.defaultVisibilityUnit
        }
    }
}
