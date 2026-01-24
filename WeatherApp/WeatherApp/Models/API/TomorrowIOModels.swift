//
//  TomorrowIOModels.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

// MARK: - Timeline Response

struct TomorrowIOTimelineResponse: Codable {
    let data: TomorrowIOData
}

struct TomorrowIOData: Codable {
    let timelines: [TomorrowIOTimeline]
}

struct TomorrowIOTimeline: Codable {
    let timestep: String
    let intervals: [TomorrowIOInterval]
}

struct TomorrowIOInterval: Codable {
    let startTime: String
    let values: TomorrowIOValues
}

struct TomorrowIOValues: Codable {
    let temperature: Double?
    let temperatureApparent: Double?
    let humidity: Double?
    let windSpeed: Double?
    let windDirection: Double?
    let pressureSurfaceLevel: Double?
    let uvIndex: Double?
    let visibility: Double?
    let cloudCover: Double?
    let precipitationProbability: Double?
    let weatherCode: Int?
}

// MARK: - Conversion Helpers

extension TomorrowIOInterval {
    var timestamp: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: startTime)
    }
}

extension TomorrowIOValues {
    /// Convert Tomorrow.io weather code to WeatherCondition
    /// https://docs.tomorrow.io/reference/data-layers-weather-codes
    var condition: WeatherCondition {
        guard let code = weatherCode else { return .unknown }

        switch code {
        case 1000: // Clear
            return .clear
        case 1001: // Cloudy
            return .cloudy
        case 1100: // Mostly Clear
            return .clear
        case 1101: // Partly Cloudy
            return .partlyCloudy
        case 1102: // Mostly Cloudy
            return .cloudy
        case 2000: // Fog
            return .fog
        case 2100: // Light Fog
            return .fog
        case 4000: // Drizzle
            return .drizzle
        case 4001: // Rain
            return .rain
        case 4200: // Light Rain
            return .drizzle
        case 4201: // Heavy Rain
            return .heavyRain
        case 5000: // Snow
            return .snow
        case 5001: // Flurries
            return .lightSnow
        case 5100: // Light Snow
            return .lightSnow
        case 5101: // Heavy Snow
            return .heavySnow
        case 6000: // Freezing Drizzle
            return .freezingRain
        case 6001: // Freezing Rain
            return .freezingRain
        case 6200: // Light Freezing Rain
            return .freezingRain
        case 6201: // Heavy Freezing Rain
            return .freezingRain
        case 7000: // Ice Pellets
            return .sleet
        case 7101: // Heavy Ice Pellets
            return .sleet
        case 7102: // Light Ice Pellets
            return .sleet
        case 8000: // Thunderstorm
            return .thunderstorm
        default:
            return .unknown
        }
    }

    var conditionDescription: String {
        guard let code = weatherCode else { return "Unknown" }

        switch code {
        case 1000: return "Clear"
        case 1001: return "Cloudy"
        case 1100: return "Mostly Clear"
        case 1101: return "Partly Cloudy"
        case 1102: return "Mostly Cloudy"
        case 2000: return "Fog"
        case 2100: return "Light Fog"
        case 4000: return "Drizzle"
        case 4001: return "Rain"
        case 4200: return "Light Rain"
        case 4201: return "Heavy Rain"
        case 5000: return "Snow"
        case 5001: return "Flurries"
        case 5100: return "Light Snow"
        case 5101: return "Heavy Snow"
        case 6000: return "Freezing Drizzle"
        case 6001: return "Freezing Rain"
        case 6200: return "Light Freezing Rain"
        case 6201: return "Heavy Freezing Rain"
        case 7000: return "Ice Pellets"
        case 7101: return "Heavy Ice Pellets"
        case 7102: return "Light Ice Pellets"
        case 8000: return "Thunderstorm"
        default: return "Unknown"
        }
    }
}
