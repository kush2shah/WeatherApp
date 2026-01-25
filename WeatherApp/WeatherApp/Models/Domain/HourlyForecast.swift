//
//  HourlyForecast.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// Hourly weather forecast
struct HourlyForecast: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let timestamp: Date
    let temperature: Double // Celsius
    let apparentTemperature: Double? // Celsius
    let condition: WeatherCondition
    let precipitationChance: Double // 0.0 - 1.0
    let precipitationAmount: Double? // mm
    let humidity: Double? // 0.0 - 1.0
    let windSpeed: Double? // m/s
    let windDirection: Double? // degrees
    let uvIndex: Double?
    let cloudCover: Double? // 0.0 - 1.0

    init(
        id: UUID = UUID(),
        timestamp: Date,
        temperature: Double,
        apparentTemperature: Double? = nil,
        condition: WeatherCondition,
        precipitationChance: Double = 0.0,
        precipitationAmount: Double? = nil,
        humidity: Double? = nil,
        windSpeed: Double? = nil,
        windDirection: Double? = nil,
        uvIndex: Double? = nil,
        cloudCover: Double? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.temperature = temperature
        self.apparentTemperature = apparentTemperature
        self.condition = condition
        self.precipitationChance = precipitationChance
        self.precipitationAmount = precipitationAmount
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.uvIndex = uvIndex
        self.cloudCover = cloudCover
    }

    /// Temperature in Fahrenheit
    var temperatureFahrenheit: Double {
        temperature * 9/5 + 32
    }

    /// Precipitation chance as percentage
    var precipitationPercentage: Int {
        Int(precipitationChance * 100)
    }
}
