//
//  NOAAModels.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

// MARK: - Points Response

/// NOAA Points API response
struct NOAAPointsResponse: Codable {
    let properties: NOAAPointsProperties
}

struct NOAAPointsProperties: Codable {
    let forecast: String
    let forecastHourly: String
    let forecastGridData: String?
}

// MARK: - Forecast Response

/// NOAA Forecast API response (GeoJSON format)
struct NOAAForecastResponse: Codable {
    let properties: NOAAForecastProperties
}

struct NOAAForecastProperties: Codable {
    let periods: [NOAAPeriod]
}

struct NOAAPeriod: Codable {
    let number: Int
    let name: String
    let startTime: String
    let endTime: String
    let isDaytime: Bool
    let temperature: Int
    let temperatureUnit: String
    let windSpeed: String
    let windDirection: String
    let icon: String?
    let shortForecast: String
    let detailedForecast: String
    let probabilityOfPrecipitation: NOAAValue?
    let dewpoint: NOAAValue?
    let relativeHumidity: NOAAValue?
}

struct NOAAValue: Codable {
    let value: Double?
}

// MARK: - Conversion Helpers

extension NOAAPeriod {
    /// Parse ISO 8601 timestamp
    var timestamp: Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: startTime)
    }

    /// Temperature in Celsius
    var temperatureCelsius: Double {
        if temperatureUnit == "F" {
            return Double(temperature - 32) * 5 / 9
        }
        return Double(temperature)
    }

    /// Parse wind speed (format: "10 mph" or "10 to 15 mph")
    var windSpeedValue: Double {
        let components = windSpeed.split(separator: " ")
        if let first = components.first, let speed = Double(first) {
            // Convert mph to m/s
            return speed * 0.44704
        }
        return 0
    }

    /// Parse wind direction degrees
    var windDirectionDegrees: Double? {
        switch windDirection {
        case "N": return 0
        case "NNE": return 22.5
        case "NE": return 45
        case "ENE": return 67.5
        case "E": return 90
        case "ESE": return 112.5
        case "SE": return 135
        case "SSE": return 157.5
        case "S": return 180
        case "SSW": return 202.5
        case "SW": return 225
        case "WSW": return 247.5
        case "W": return 270
        case "WNW": return 292.5
        case "NW": return 315
        case "NNW": return 337.5
        default: return nil
        }
    }

    /// Map NOAA forecast description to WeatherCondition
    var weatherCondition: WeatherCondition {
        let forecast = shortForecast.lowercased()

        if forecast.contains("thunder") {
            return .thunderstorm
        } else if forecast.contains("snow") || forecast.contains("flurries") {
            if forecast.contains("heavy") {
                return .heavySnow
            } else if forecast.contains("light") {
                return .lightSnow
            }
            return .snow
        } else if forecast.contains("sleet") || forecast.contains("freezing rain") {
            return .sleet
        } else if forecast.contains("rain") {
            if forecast.contains("heavy") {
                return .heavyRain
            } else if forecast.contains("drizzle") || forecast.contains("light") {
                return .drizzle
            }
            return .rain
        } else if forecast.contains("fog") {
            return .fog
        } else if forecast.contains("haze") || forecast.contains("smoke") {
            return .haze
        } else if forecast.contains("cloud") {
            if forecast.contains("mostly cloudy") || forecast.contains("overcast") {
                return .cloudy
            } else if forecast.contains("partly") {
                return .partlyCloudy
            }
            return .cloudy
        } else if forecast.contains("clear") || forecast.contains("sunny") {
            return .clear
        } else if forecast.contains("wind") {
            return .wind
        }

        return .unknown
    }

    /// Precipitation chance (0.0 - 1.0)
    var precipitationChance: Double {
        guard let value = probabilityOfPrecipitation?.value else { return 0 }
        return value / 100.0
    }

    /// Relative humidity (0.0 - 1.0)
    var humidity: Double? {
        guard let value = relativeHumidity?.value else { return nil }
        return value / 100.0
    }
}
