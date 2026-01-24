//
//  WeatherCondition.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// Unified weather condition representation with SF Symbol mappings
enum WeatherCondition: String, Codable, CaseIterable {
    case clear
    case partlyCloudy
    case cloudy
    case overcast
    case rain
    case drizzle
    case heavyRain
    case thunderstorm
    case snow
    case lightSnow
    case heavySnow
    case sleet
    case freezingRain
    case fog
    case haze
    case wind
    case tornado
    case hurricane
    case tropical
    case dust
    case smoke
    case unknown

    /// SF Symbol name for the weather condition
    var sfSymbolName: String {
        switch self {
        case .clear:
            return "sun.max.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .cloudy:
            return "cloud.fill"
        case .overcast:
            return "smoke.fill"
        case .rain:
            return "cloud.rain.fill"
        case .drizzle:
            return "cloud.drizzle.fill"
        case .heavyRain:
            return "cloud.heavyrain.fill"
        case .thunderstorm:
            return "cloud.bolt.rain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .lightSnow:
            return "cloud.snow.fill"
        case .heavySnow:
            return "cloud.snow.fill"
        case .sleet:
            return "cloud.sleet.fill"
        case .freezingRain:
            return "cloud.sleet.fill"
        case .fog:
            return "cloud.fog.fill"
        case .haze:
            return "sun.haze.fill"
        case .wind:
            return "wind"
        case .tornado:
            return "tornado"
        case .hurricane:
            return "hurricane"
        case .tropical:
            return "tropicalstorm"
        case .dust:
            return "sun.dust.fill"
        case .smoke:
            return "smoke.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }

    /// User-friendly description
    var description: String {
        switch self {
        case .clear:
            return "Clear"
        case .partlyCloudy:
            return "Partly Cloudy"
        case .cloudy:
            return "Cloudy"
        case .overcast:
            return "Overcast"
        case .rain:
            return "Rain"
        case .drizzle:
            return "Drizzle"
        case .heavyRain:
            return "Heavy Rain"
        case .thunderstorm:
            return "Thunderstorm"
        case .snow:
            return "Snow"
        case .lightSnow:
            return "Light Snow"
        case .heavySnow:
            return "Heavy Snow"
        case .sleet:
            return "Sleet"
        case .freezingRain:
            return "Freezing Rain"
        case .fog:
            return "Fog"
        case .haze:
            return "Haze"
        case .wind:
            return "Windy"
        case .tornado:
            return "Tornado"
        case .hurricane:
            return "Hurricane"
        case .tropical:
            return "Tropical Storm"
        case .dust:
            return "Dust"
        case .smoke:
            return "Smoke"
        case .unknown:
            return "Unknown"
        }
    }
}
