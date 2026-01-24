//
//  OpenWeatherMapModels.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

// MARK: - Current Weather Response

struct OWMCurrentResponse: Codable {
    let weather: [OWMWeather]
    let main: OWMMain
    let wind: OWMWind
    let clouds: OWMClouds
    let dt: Int
    let sys: OWMSys?
    let visibility: Int?
}

struct OWMWeather: Codable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

struct OWMMain: Codable {
    let temp: Double
    let feelsLike: Double
    let tempMin: Double
    let tempMax: Double
    let pressure: Double
    let humidity: Double

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case humidity
    }
}

struct OWMWind: Codable {
    let speed: Double
    let deg: Double?
}

struct OWMClouds: Codable {
    let all: Double
}

struct OWMSys: Codable {
    let sunrise: Int?
    let sunset: Int?
}

// MARK: - Forecast Response

struct OWMForecastResponse: Codable {
    let list: [OWMForecastItem]
}

struct OWMForecastItem: Codable {
    let dt: Int
    let main: OWMMain
    let weather: [OWMWeather]
    let clouds: OWMClouds
    let wind: OWMWind
    let pop: Double // Probability of precipitation
    let dtTxt: String

    enum CodingKeys: String, CodingKey {
        case dt
        case main
        case weather
        case clouds
        case wind
        case pop
        case dtTxt = "dt_txt"
    }
}

// MARK: - Conversion Helpers

extension OWMWeather {
    var condition: WeatherCondition {
        // OWM weather codes: https://openweathermap.org/weather-conditions
        switch id {
        case 200...232: // Thunderstorm
            return .thunderstorm
        case 300...321: // Drizzle
            return .drizzle
        case 500...504: // Rain
            return .rain
        case 511: // Freezing rain
            return .freezingRain
        case 520...531: // Shower rain
            return .rain
        case 600...602: // Snow
            return .snow
        case 611...616: // Sleet
            return .sleet
        case 620...622: // Shower snow
            return .snow
        case 701: // Mist
            return .fog
        case 711: // Smoke
            return .smoke
        case 721: // Haze
            return .haze
        case 731, 751, 761: // Dust
            return .dust
        case 741: // Fog
            return .fog
        case 781: // Tornado
            return .tornado
        case 800: // Clear
            return .clear
        case 801: // Few clouds
            return .partlyCloudy
        case 802: // Scattered clouds
            return .partlyCloudy
        case 803: // Broken clouds
            return .cloudy
        case 804: // Overcast
            return .overcast
        default:
            return .unknown
        }
    }
}

extension OWMForecastItem {
    var timestamp: Date {
        Date(timeIntervalSince1970: TimeInterval(dt))
    }
}
