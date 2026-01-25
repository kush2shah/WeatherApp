//
//  TomorrowIOService.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// Tomorrow.io service implementation
actor TomorrowIOService: WeatherServiceProtocol {
    let source: WeatherSource = .tomorrowIO
    private let networkClient = NetworkClient()
    private let apiKey: String

    init(apiKey: String = Config.tomorrowIOAPIKey) {
        self.apiKey = apiKey
    }

    nonisolated var isAvailable: Bool {
        !Config.tomorrowIOAPIKey.isEmpty
    }

    nonisolated func checkAvailability(for location: Location) -> Bool {
        isAvailable
    }

    func fetchWeather(for location: Location) async throws -> SourcedWeatherInfo {
        guard isAvailable else {
            throw APIError.unauthorized
        }

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let baseURL = "https://api.tomorrow.io/v4"

        // Timeline endpoint combines current, hourly, and daily
        let fields = [
            "temperature",
            "temperatureApparent",
            "humidity",
            "windSpeed",
            "windDirection",
            "pressureSurfaceLevel",
            "uvIndex",
            "visibility",
            "cloudCover",
            "precipitationProbability",
            "weatherCode"
        ].joined(separator: ",")

        let url = "\(baseURL)/timelines?location=\(lat),\(lon)&fields=\(fields)&timesteps=current,1h,1d&apikey=\(apiKey)&units=metric"

        let response: TomorrowIOTimelineResponse = try await networkClient.fetch(url: url)

        return convertToSourcedWeatherInfo(response, location: location)
    }

    // MARK: - Private Helpers

    private func convertToSourcedWeatherInfo(
        _ response: TomorrowIOTimelineResponse,
        location: Location
    ) -> SourcedWeatherInfo {
        let timelines = response.data.timelines

        // Find current, hourly, and daily timelines
        let currentTimeline = timelines.first { $0.timestep == "current" }
        let hourlyTimeline = timelines.first { $0.timestep == "1h" }
        let dailyTimeline = timelines.first { $0.timestep == "1d" }

        // Current weather
        let current = convertCurrentWeather(currentTimeline?.intervals.first)

        // Hourly forecast
        let hourly = hourlyTimeline?.intervals.prefix(24).compactMap { convertHourlyForecast($0) } ?? []

        // Daily forecast
        let daily = dailyTimeline?.intervals.prefix(10).compactMap { convertDailyForecast($0) } ?? []

        return SourcedWeatherInfo(
            source: .tomorrowIO,
            current: current,
            hourly: Array(hourly),
            daily: Array(daily)
        )
    }

    private func convertCurrentWeather(_ interval: TomorrowIOInterval?) -> CurrentWeather {
        guard let interval = interval else {
            return CurrentWeather(
                temperature: 0,
                apparentTemperature: 0,
                condition: .unknown,
                conditionDescription: "Unknown",
                humidity: 0,
                pressure: 1013.25,
                windSpeed: 0,
                windDirection: nil,
                uvIndex: nil,
                visibility: nil,
                cloudCover: nil,
                dewPoint: nil,
                timestamp: Date()
            )
        }

        let values = interval.values

        return CurrentWeather(
            temperature: values.temperature ?? 0,
            apparentTemperature: values.temperatureApparent ?? values.temperature ?? 0,
            condition: values.condition,
            conditionDescription: values.conditionDescription,
            humidity: (values.humidity ?? 0) / 100,
            pressure: values.pressureSurfaceLevel ?? 1013.25,
            windSpeed: values.windSpeed ?? 0,
            windDirection: values.windDirection,
            uvIndex: values.uvIndex,
            visibility: values.visibility.map { $0 * 1000 }, // km to meters
            cloudCover: values.cloudCover.map { $0 / 100 },
            dewPoint: nil,
            timestamp: interval.timestamp ?? Date()
        )
    }

    private func convertHourlyForecast(_ interval: TomorrowIOInterval) -> HourlyForecast? {
        guard let timestamp = interval.timestamp else { return nil }

        let values = interval.values

        return HourlyForecast(
            timestamp: timestamp,
            temperature: values.temperature ?? 0,
            apparentTemperature: values.temperatureApparent,
            condition: values.condition,
            precipitationChance: (values.precipitationProbability ?? 0) / 100,
            precipitationAmount: nil,
            humidity: values.humidity.map { $0 / 100 },
            windSpeed: values.windSpeed,
            windDirection: values.windDirection,
            uvIndex: values.uvIndex,
            cloudCover: values.cloudCover.map { $0 / 100 }
        )
    }

    private func convertDailyForecast(_ interval: TomorrowIOInterval) -> DailyForecast? {
        guard let timestamp = interval.timestamp else { return nil }

        let values = interval.values

        // For daily forecasts, Tomorrow.io provides average values
        // We'll use temperature as both high and low (limitation of their free tier)
        let temp = values.temperature ?? 0

        return DailyForecast(
            date: timestamp,
            highTemperature: temp + 2, // Estimate
            lowTemperature: temp - 2, // Estimate
            condition: values.condition,
            conditionDescription: values.conditionDescription,
            precipitationChance: (values.precipitationProbability ?? 0) / 100,
            precipitationAmount: nil,
            sunrise: nil,
            sunset: nil,
            moonPhase: nil,
            humidity: values.humidity.map { $0 / 100 },
            windSpeed: values.windSpeed,
            uvIndex: values.uvIndex
        )
    }
}
