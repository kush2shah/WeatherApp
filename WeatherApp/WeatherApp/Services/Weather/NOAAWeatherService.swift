//
//  NOAAWeatherService.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// NOAA/NWS weather service implementation
actor NOAAWeatherService: WeatherServiceProtocol {
    let source: WeatherSource = .noaa
    private let networkClient: any NetworkClientProtocol

    init(networkClient: any NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }

    nonisolated var isAvailable: Bool { true }

    nonisolated func checkAvailability(for location: Location) -> Bool {
        // NOAA only covers US territories
        // Use ISO country code for locale-independent check
        guard let isoCode = location.isoCountryCode?.uppercased() else {
            return true // Assume US if country code not specified
        }
        return isoCode == "US"
    }

    func fetchWeather(for location: Location) async throws -> SourcedWeatherInfo {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        // Step 1: Get forecast URLs from points endpoint
        let pointsURL = "https://api.weather.gov/points/\(lat),\(lon)"
        let pointsResponse: NOAAPointsResponse = try await networkClient.fetch(url: pointsURL)

        // Step 2: Fetch daily forecast
        let forecastResponse: NOAAForecastResponse = try await networkClient.fetch(
            url: pointsResponse.properties.forecast
        )

        // Step 3: Fetch hourly forecast
        let hourlyResponse: NOAAForecastResponse = try await networkClient.fetch(
            url: pointsResponse.properties.forecastHourly
        )

        return try convertToSourcedWeatherInfo(
            forecast: forecastResponse,
            hourly: hourlyResponse,
            location: location
        )
    }

    // MARK: - Private Helpers

    /// Convert NOAA responses to domain model
    private func convertToSourcedWeatherInfo(
        forecast: NOAAForecastResponse,
        hourly: NOAAForecastResponse,
        location: Location
    ) throws -> SourcedWeatherInfo {
        // Use first hourly period as current weather
        guard let currentPeriod = hourly.properties.periods.first else {
            throw APIError.serviceUnavailable
        }
        let current = convertCurrentWeather(currentPeriod)

        // Convert hourly periods
        let hourlyForecasts = hourly.properties.periods.prefix(24).map { convertHourlyForecast($0) }

        // Convert daily periods (NOAA returns day/night pairs)
        let dailyForecasts = convertDailyForecasts(forecast.properties.periods, timezone: location.timezone)

        return SourcedWeatherInfo(
            source: .noaa,
            current: current,
            hourly: Array(hourlyForecasts),
            daily: dailyForecasts
        )
    }

    /// Convert NOAA period to current weather
    private func convertCurrentWeather(_ period: NOAAPeriod) -> CurrentWeather {
        CurrentWeather(
            temperature: period.temperatureCelsius,
            apparentTemperature: period.temperatureCelsius, // NOAA doesn't provide feels-like
            condition: period.weatherCondition,
            conditionDescription: period.shortForecast,
            humidity: period.humidity ?? 0.5,
            pressure: 1013.25, // Standard pressure (not provided by NOAA)
            windSpeed: period.windSpeedValue,
            windDirection: period.windDirectionDegrees,
            uvIndex: nil,
            visibility: nil,
            cloudCover: nil,
            dewPoint: period.dewpoint?.value,
            timestamp: period.timestamp ?? Date()
        )
    }

    /// Convert NOAA period to hourly forecast
    private func convertHourlyForecast(_ period: NOAAPeriod) -> HourlyForecast {
        HourlyForecast(
            timestamp: period.timestamp ?? Date(),
            temperature: period.temperatureCelsius,
            apparentTemperature: nil,
            condition: period.weatherCondition,
            precipitationChance: period.precipitationChance,
            precipitationAmount: nil,
            humidity: period.humidity,
            windSpeed: period.windSpeedValue,
            windDirection: period.windDirectionDegrees
        )
    }

    /// Convert NOAA daily periods (combine day/night pairs)
    private func convertDailyForecasts(_ periods: [NOAAPeriod], timezone: TimeZone) -> [DailyForecast] {
        var dailyForecasts: [DailyForecast] = []
        var i = 0

        while i < periods.count {
            let period = periods[i]

            // Find matching night period
            var nightPeriod: NOAAPeriod?
            if i + 1 < periods.count && !periods[i + 1].isDaytime {
                nightPeriod = periods[i + 1]
                i += 2
            } else {
                i += 1
            }

            guard let timestamp = period.timestamp else { continue }

            let high = period.isDaytime ? period.temperatureCelsius : (nightPeriod?.temperatureCelsius ?? period.temperatureCelsius)
            let low = nightPeriod?.temperatureCelsius ?? period.temperatureCelsius

            let daily = DailyForecast(
                date: timestamp,
                timezone: timezone,
                highTemperature: max(high, low),
                lowTemperature: min(high, low),
                condition: period.weatherCondition,
                conditionDescription: period.shortForecast,
                precipitationChance: period.precipitationChance,
                precipitationAmount: nil,
                humidity: period.humidity,
                windSpeed: period.windSpeedValue
            )

            dailyForecasts.append(daily)
        }

        return dailyForecasts
    }
}
