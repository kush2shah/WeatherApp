//
//  OpenWeatherMapService.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// OpenWeatherMap service implementation
actor OpenWeatherMapService: WeatherServiceProtocol {
    let source: WeatherSource = .openWeatherMap
    private let networkClient = NetworkClient()
    private let apiKey: String

    init(apiKey: String = Config.openWeatherMapAPIKey) {
        self.apiKey = apiKey
    }

    var isAvailable: Bool {
        !apiKey.isEmpty
    }

    func fetchWeather(for location: Location) async throws -> SourcedWeatherInfo {
        guard isAvailable else {
            throw APIError.unauthorized
        }

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let baseURL = "https://api.openweathermap.org/data/2.5"

        // Fetch current weather
        let currentURL = "\(baseURL)/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        let current: OWMCurrentResponse = try await networkClient.fetch(url: currentURL)

        // Fetch 5-day/3-hour forecast
        let forecastURL = "\(baseURL)/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric"
        let forecast: OWMForecastResponse = try await networkClient.fetch(url: forecastURL)

        return convertToSourcedWeatherInfo(
            current: current,
            forecast: forecast,
            location: location
        )
    }

    // MARK: - Private Helpers

    private func convertToSourcedWeatherInfo(
        current: OWMCurrentResponse,
        forecast: OWMForecastResponse,
        location: Location
    ) -> SourcedWeatherInfo {
        let currentWeather = convertCurrentWeather(current)

        // Hourly forecast (OWM provides 3-hour intervals)
        let hourlyForecasts = forecast.list.prefix(24).map { convertHourlyForecast($0) }

        // Daily forecast (group by day)
        let dailyForecasts = convertDailyForecasts(forecast.list, sunrise: current.sys?.sunrise, sunset: current.sys?.sunset)

        return SourcedWeatherInfo(
            source: .openWeatherMap,
            current: currentWeather,
            hourly: Array(hourlyForecasts),
            daily: dailyForecasts
        )
    }

    private func convertCurrentWeather(_ response: OWMCurrentResponse) -> CurrentWeather {
        let weatherInfo = response.weather.first!

        return CurrentWeather(
            temperature: response.main.temp,
            apparentTemperature: response.main.feelsLike,
            condition: weatherInfo.condition,
            conditionDescription: weatherInfo.description.capitalized,
            humidity: response.main.humidity / 100,
            pressure: response.main.pressure,
            windSpeed: response.wind.speed,
            windDirection: response.wind.deg,
            uvIndex: nil,
            visibility: response.visibility.map { Double($0) },
            cloudCover: response.clouds.all / 100,
            dewPoint: nil,
            timestamp: Date(timeIntervalSince1970: TimeInterval(response.dt))
        )
    }

    private func convertHourlyForecast(_ item: OWMForecastItem) -> HourlyForecast {
        let weatherInfo = item.weather.first!

        return HourlyForecast(
            timestamp: item.timestamp,
            temperature: item.main.temp,
            apparentTemperature: item.main.feelsLike,
            condition: weatherInfo.condition,
            precipitationChance: item.pop,
            precipitationAmount: nil,
            humidity: item.main.humidity / 100,
            windSpeed: item.wind.speed,
            windDirection: item.wind.deg,
            uvIndex: nil,
            cloudCover: item.clouds.all / 100
        )
    }

    private func convertDailyForecasts(
        _ items: [OWMForecastItem],
        sunrise: Int?,
        sunset: Int?
    ) -> [DailyForecast] {
        // Group by day
        let grouped = Dictionary(grouping: items) { item in
            Calendar.current.startOfDay(for: item.timestamp)
        }

        return grouped.keys.sorted().compactMap { date in
            guard let dayItems = grouped[date] else { return nil }

            let temps = dayItems.map { $0.main.temp }
            let high = temps.max() ?? 0
            let low = temps.min() ?? 0

            // Use midday forecast for condition
            let middayItem = dayItems[dayItems.count / 2]
            let weatherInfo = middayItem.weather.first!

            // Average precipitation chance
            let avgPrecip = dayItems.map { $0.pop }.reduce(0, +) / Double(dayItems.count)

            return DailyForecast(
                date: date,
                highTemperature: high,
                lowTemperature: low,
                condition: weatherInfo.condition,
                conditionDescription: weatherInfo.description.capitalized,
                precipitationChance: avgPrecip,
                precipitationAmount: nil,
                sunrise: sunrise.map { Date(timeIntervalSince1970: TimeInterval($0)) },
                sunset: sunset.map { Date(timeIntervalSince1970: TimeInterval($0)) },
                moonPhase: nil,
                humidity: middayItem.main.humidity / 100,
                windSpeed: middayItem.wind.speed,
                uvIndex: nil
            )
        }
    }
}
