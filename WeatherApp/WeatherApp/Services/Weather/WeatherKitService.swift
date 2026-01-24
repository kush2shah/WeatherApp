//
//  WeatherKitService.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation
import WeatherKit
import CoreLocation

/// WeatherKit service implementation
@MainActor
final class WeatherKitService: WeatherServiceProtocol {
    let source: WeatherSource = .weatherKit
    private let weatherService = WeatherService.shared

    var isAvailable: Bool {
        // WeatherKit is available worldwide
        true
    }

    func checkAvailability(for location: Location) -> Bool {
        isAvailable
    }

    func fetchWeather(for location: Location) async throws -> SourcedWeatherInfo {
        let clLocation = CLLocation(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )

        do {
            // Fetch current, hourly, and daily weather
            let (current, hourly, daily) = try await weatherService.weather(
                for: clLocation,
                including: .current, .hourly, .daily
            )

            return convertToDomainModel(current: current, hourly: hourly, daily: daily, location: location)
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Private Helpers

    /// Convert WeatherKit weather to domain model
    private func convertToDomainModel(
        current: WeatherKit.CurrentWeather,
        hourly: Forecast<HourWeather>,
        daily: Forecast<DayWeather>,
        location: Location
    ) -> SourcedWeatherInfo {
        let current = convertCurrentWeather(current)
        let hourly = hourly.forecast.prefix(24).map { convertHourlyForecast($0) }
        let daily = daily.forecast.prefix(10).map { convertDailyForecast($0) }

        return SourcedWeatherInfo(
            source: .weatherKit,
            current: current,
            hourly: Array(hourly),
            daily: Array(daily)
        )
    }

    /// Convert WeatherKit CurrentWeather to domain model
    private func convertCurrentWeather(_ current: WeatherKit.CurrentWeather) -> CurrentWeather {
        CurrentWeather(
            temperature: current.temperature.value,
            apparentTemperature: current.apparentTemperature.value,
            condition: convertCondition(current.condition),
            conditionDescription: current.condition.description,
            humidity: current.humidity,
            pressure: current.pressure.value,
            windSpeed: current.wind.speed.value,
            windDirection: current.wind.direction.value,
            uvIndex: Double(current.uvIndex.value),
            visibility: current.visibility.value,
            cloudCover: current.cloudCover,
            dewPoint: current.dewPoint.value,
            timestamp: current.date
        )
    }

    /// Convert WeatherKit HourForecast to domain model
    private func convertHourlyForecast(_ hourly: WeatherKit.HourWeather) -> HourlyForecast {
        HourlyForecast(
            timestamp: hourly.date,
            temperature: hourly.temperature.value,
            apparentTemperature: hourly.apparentTemperature.value,
            condition: convertCondition(hourly.condition),
            precipitationChance: hourly.precipitationChance,
            precipitationAmount: hourly.precipitationAmount.value,
            humidity: hourly.humidity,
            windSpeed: hourly.wind.speed.value,
            windDirection: hourly.wind.direction.value,
            uvIndex: Double(hourly.uvIndex.value),
            cloudCover: hourly.cloudCover
        )
    }

    /// Convert WeatherKit DayWeather to domain model
    private func convertDailyForecast(_ daily: WeatherKit.DayWeather) -> DailyForecast {
        DailyForecast(
            date: daily.date,
            highTemperature: daily.highTemperature.value,
            lowTemperature: daily.lowTemperature.value,
            condition: convertCondition(daily.condition),
            conditionDescription: daily.condition.description,
            precipitationChance: daily.precipitationChance,
            precipitationAmount: daily.precipitationAmount.value,
            sunrise: daily.sun.sunrise,
            sunset: daily.sun.sunset,
            moonPhase: nil,
            humidity: nil, // Not available in daily forecast
            windSpeed: daily.wind.speed.value,
            uvIndex: Double(daily.uvIndex.value)
        )
    }

    /// Convert WeatherKit WeatherCondition to domain WeatherCondition
    private func convertCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherCondition {
        switch condition {
        case .clear, .mostlyClear:
            return .clear
        case .partlyCloudy:
            return .partlyCloudy
        case .cloudy, .mostlyCloudy:
            return .cloudy
        case .rain:
            return .rain
        case .drizzle:
            return .drizzle
        case .heavyRain:
            return .heavyRain
        case .thunderstorms, .strongStorms:
            return .thunderstorm
        case .snow:
            return .snow
        case .flurries:
            return .lightSnow
        case .heavySnow, .blowingSnow:
            return .heavySnow
        case .sleet:
            return .sleet
        case .freezingRain, .freezingDrizzle:
            return .freezingRain
//        case .fog:
//            return .fog
        case .haze:
            return .haze
        case .windy, .breezy:
            return .wind
        case .blizzard:
            return .heavySnow
        case .frigid, .hot:
            return .clear
        case .hurricane, .tropicalStorm:
            return .hurricane
        case .hail:
            return .sleet
        case .smoky:
            return .smoke
        case .blowingDust:
            return .dust
        @unknown default:
            return .unknown
        }
    }
}
