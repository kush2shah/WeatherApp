//
//  DailyForecast.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// Daily weather forecast
struct DailyForecast: Identifiable, Hashable, Sendable {
    let id: UUID
    let date: Date
    let timezone: TimeZone
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
        timezone: TimeZone = .current,
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
        self.timezone = timezone
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
}

extension DailyForecast: Codable {
    enum CodingKeys: String, CodingKey {
        case id, date, timezoneIdentifier, highTemperature, lowTemperature
        case condition, conditionDescription, precipitationChance, precipitationAmount
        case sunrise, sunset, moonPhase, humidity, windSpeed, uvIndex
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)

        // Decode timezone from identifier
        let timezoneIdentifier = try container.decode(String.self, forKey: .timezoneIdentifier)
        timezone = TimeZone(identifier: timezoneIdentifier) ?? .current

        highTemperature = try container.decode(Double.self, forKey: .highTemperature)
        lowTemperature = try container.decode(Double.self, forKey: .lowTemperature)
        condition = try container.decode(WeatherCondition.self, forKey: .condition)
        conditionDescription = try container.decode(String.self, forKey: .conditionDescription)
        precipitationChance = try container.decode(Double.self, forKey: .precipitationChance)
        precipitationAmount = try container.decodeIfPresent(Double.self, forKey: .precipitationAmount)
        sunrise = try container.decodeIfPresent(Date.self, forKey: .sunrise)
        sunset = try container.decodeIfPresent(Date.self, forKey: .sunset)
        moonPhase = try container.decodeIfPresent(Double.self, forKey: .moonPhase)
        humidity = try container.decodeIfPresent(Double.self, forKey: .humidity)
        windSpeed = try container.decodeIfPresent(Double.self, forKey: .windSpeed)
        uvIndex = try container.decodeIfPresent(Double.self, forKey: .uvIndex)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(timezone.identifier, forKey: .timezoneIdentifier)
        try container.encode(highTemperature, forKey: .highTemperature)
        try container.encode(lowTemperature, forKey: .lowTemperature)
        try container.encode(condition, forKey: .condition)
        try container.encode(conditionDescription, forKey: .conditionDescription)
        try container.encode(precipitationChance, forKey: .precipitationChance)
        try container.encodeIfPresent(precipitationAmount, forKey: .precipitationAmount)
        try container.encodeIfPresent(sunrise, forKey: .sunrise)
        try container.encodeIfPresent(sunset, forKey: .sunset)
        try container.encodeIfPresent(moonPhase, forKey: .moonPhase)
        try container.encodeIfPresent(humidity, forKey: .humidity)
        try container.encodeIfPresent(windSpeed, forKey: .windSpeed)
        try container.encodeIfPresent(uvIndex, forKey: .uvIndex)
    }
}

// MARK: - Computed Properties
extension DailyForecast {
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

    /// Day of week in the location's timezone
    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }

    /// Short day name (Mon, Tue, etc.) in the location's timezone
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }
}
