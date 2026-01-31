//
//  GoogleWeatherModels.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/30/26.
//

import Foundation

// MARK: - Common Types

struct GWTemperature: Codable, Sendable {
    let value: Double
    let unit: String?
}

struct GWWind: Codable, Sendable {
    let speed: GWValue?
    let direction: GWDirection?
    let gust: GWValue?
}

struct GWValue: Codable, Sendable {
    let value: Double
    let unit: String?
}

struct GWDirection: Codable, Sendable {
    let degrees: Int
}

struct GWPrecipitation: Codable, Sendable {
    let probability: Int?
    let amount: GWValue?
}

struct GWWeatherCondition: Codable, Sendable {
    let code: String
    let description: String
}

struct GWVisibility: Codable, Sendable {
    let value: Double
    let unit: String?
}

struct GWAirPressure: Codable, Sendable {
    let value: Double
    let unit: String?
}

struct GWTimeZone: Codable, Sendable {
    let id: String
    let offset: String?
}

// MARK: - Current Conditions Response

struct GWCurrentConditionsResponse: Codable, Sendable {
    let currentTime: String
    let timeZone: GWTimeZone?
    let weatherCondition: GWWeatherCondition?
    let temperature: GWTemperature?
    let feelsLikeTemperature: GWTemperature?
    let dewPoint: GWTemperature?
    let heatIndex: GWTemperature?
    let windChill: GWTemperature?
    let precipitation: GWPrecipitation?
    let airPressure: GWAirPressure?
    let wind: GWWind?
    let visibility: GWVisibility?
    let isDaytime: Bool?
    let relativeHumidity: Int?
    let uvIndex: Int?
    let thunderstormProbability: Int?
    let cloudCover: Int?
    let currentConditionsHistory: GWCurrentConditionsHistory?
}

struct GWCurrentConditionsHistory: Codable, Sendable {
    let temperatureChange: GWTemperature?
    let maxTemperature: GWTemperature?
    let minTemperature: GWTemperature?
    let snowQpf: GWValue?
    let qpf: GWValue?
}

// MARK: - Hourly Forecast Response

struct GWHourlyForecastResponse: Codable, Sendable {
    let forecastHours: [GWForecastHour]
    let timeZone: GWTimeZone?
    let nextPageToken: String?
}

struct GWForecastHour: Codable, Sendable {
    let interval: GWInterval
    let weatherCondition: GWWeatherCondition?
    let temperature: GWTemperature?
    let feelsLikeTemperature: GWTemperature?
    let dewPoint: GWTemperature?
    let heatIndex: GWTemperature?
    let windChill: GWTemperature?
    let wetBulbTemperature: GWTemperature?
    let precipitation: GWPrecipitation?
    let airPressure: GWAirPressure?
    let wind: GWWind?
    let visibility: GWVisibility?
    let isDaytime: Bool?
    let relativeHumidity: Int?
    let uvIndex: Int?
    let thunderstormProbability: Int?
    let cloudCover: Int?
    let iceThickness: GWValue?
}

struct GWInterval: Codable, Sendable {
    let startTime: String
    let endTime: String
}

// MARK: - Daily Forecast Response

struct GWDailyForecastResponse: Codable, Sendable {
    let forecastDays: [GWForecastDay]
    let timeZone: GWTimeZone?
    let nextPageToken: String?
}

struct GWForecastDay: Codable, Sendable {
    let interval: GWInterval
    let displayDate: GWDate?
    let daytimeForecast: GWForecastDayPart?
    let nighttimeForecast: GWForecastDayPart?
    let maxTemperature: GWTemperature?
    let minTemperature: GWTemperature?
    let feelsLikeMaxTemperature: GWTemperature?
    let feelsLikeMinTemperature: GWTemperature?
    let maxHeatIndex: GWTemperature?
    let sunEvents: GWSunEvents?
    let moonEvents: GWMoonEvents?
}

struct GWDate: Codable, Sendable {
    let year: Int
    let month: Int
    let day: Int
}

struct GWForecastDayPart: Codable, Sendable {
    let weatherCondition: GWWeatherCondition?
    let precipitation: GWPrecipitation?
    let wind: GWWind?
    let relativeHumidity: Int?
    let uvIndex: Int?
    let cloudCover: Int?
    let iceThickness: GWValue?
}

struct GWSunEvents: Codable, Sendable {
    let sunriseTime: String?
    let sunsetTime: String?
}

struct GWMoonEvents: Codable, Sendable {
    let moonriseTimes: [String]?
    let moonsetTimes: [String]?
    let moonPhase: String?
}
