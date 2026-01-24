//
//  DailyForecast.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// Daily weather forecast
struct DailyForecast: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let highTemperature: Double // Celsius
    let lowTemperature: Double // Celsius
    let condition: WeatherCondition
    let conditionDescription: String
    let precipitationChance: Double // 0.0 - 1.0
    let precipitationAmount: Double? // mm
    let sunrise: Date?
    let sunset: Date?
    let moonPhase: Double? // 0.0 - 1.0
    let humidity: Double? // 0.0 - 1.0
    let windSpeed: Double? // m/s
    let uvIndex: Double?

    init(
        id: UUID = UUID(),
        date: Date,
        highTemperature: Double,
        lowTemperature: Double,
        condition: WeatherCondition,
        conditionDescription: String,
        precipitationChance: Double = 0.0,
        precipitationAmount: Double? = nil,
        sunrise: Date? = nil,
        sunset: Date? = nil,
        moonPhase: Double? = nil,
        humidity: Double? = nil,
        windSpeed: Double? = nil,
        uvIndex: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.highTemperature = highTemperature
        self.lowTemperature = lowTemperature
        self.condition = condition
        self.conditionDescription = conditionDescription
        self.precipitationChance = precipitationChance
        self.precipitationAmount = precipitationAmount
        self.sunrise = sunrise
        self.sunset = sunset
        self.moonPhase = moonPhase
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.uvIndex = uvIndex
    }

    /// High temperature in Fahrenheit
    var highTemperatureFahrenheit: Double {
        highTemperature * 9/5 + 32
    }

    /// Low temperature in Fahrenheit
    var lowTemperatureFahrenheit: Double {
        lowTemperature * 9/5 + 32
    }

    /// Precipitation chance as percentage
    var precipitationPercentage: Int {
        Int(precipitationChance * 100)
    }

    /// Day of week
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    /// Short day name (Mon, Tue, etc.)
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}
