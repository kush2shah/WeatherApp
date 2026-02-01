//
//  GoogleWeatherService.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/30/26.
//

import Foundation

/// Google Weather API service implementation
actor GoogleWeatherService: WeatherServiceProtocol {
    let source: WeatherSource = .googleWeather
    private let networkClient = NetworkClient()
    private let apiKey: String

    init(apiKey: String = Config.googleWeatherAPIKey) {
        self.apiKey = apiKey
    }

    nonisolated var isAvailable: Bool {
        !Config.cloudRunProxyURL.isEmpty && !Config.cloudRunProxyAPIKey.isEmpty
    }

    nonisolated func checkAvailability(for location: Location) -> Bool {
        isAvailable
    }

    func fetchWeather(for location: Location) async throws -> SourcedWeatherInfo {
        guard isAvailable else {
            print("[Google Weather] API key not configured")
            throw APIError.unauthorized
        }

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        // Build request URLs
        let baseURL = Config.cloudRunProxyURL
        let locationParam = "location.latitude=\(lat)&location.longitude=\(lon)"

        let currentURL = "\(baseURL)/v1/currentConditions:lookup?\(locationParam)"
        let hourlyURL = "\(baseURL)/v1/forecast/hours:lookup?\(locationParam)&hours=240"
        let dailyURL = "\(baseURL)/v1/forecast/days:lookup?\(locationParam)&days=10"

        let headers = ["X-API-Key": Config.cloudRunProxyAPIKey]

        // Fetch all endpoints in parallel
        async let currentTask: GWCurrentConditionsResponse = networkClient.fetch(url: currentURL, headers: headers)
        async let hourlyTask: GWHourlyForecastResponse = networkClient.fetch(url: hourlyURL, headers: headers)
        async let dailyTask: GWDailyForecastResponse = networkClient.fetch(url: dailyURL, headers: headers)

        let (current, hourly, daily) = try await (currentTask, hourlyTask, dailyTask)

        return convertToSourcedWeatherInfo(
            current: current,
            hourly: hourly,
            daily: daily,
            location: location
        )
    }

    // MARK: - Private Helpers

    private func convertToSourcedWeatherInfo(
        current: GWCurrentConditionsResponse,
        hourly: GWHourlyForecastResponse,
        daily: GWDailyForecastResponse,
        location: Location
    ) -> SourcedWeatherInfo {
        let currentWeather = convertCurrentWeather(current)
        let hourlyForecasts = hourly.forecastHours.compactMap { convertHourlyForecast($0) }
        let dailyForecasts = daily.forecastDays.compactMap { convertDailyForecast($0, timezone: location.timezone) }

        return SourcedWeatherInfo(
            source: .googleWeather,
            current: currentWeather,
            hourly: hourlyForecasts,
            daily: dailyForecasts
        )
    }

    private func convertCurrentWeather(_ response: GWCurrentConditionsResponse) -> CurrentWeather {
        CurrentWeather(
            temperature: response.temperature?.degrees ?? 0,
            apparentTemperature: response.feelsLikeTemperature?.degrees ?? response.temperature?.degrees ?? 0,
            condition: mapWeatherCondition(response.weatherCondition?.type),
            conditionDescription: response.weatherCondition?.description.text ?? "Unknown",
            humidity: Double(response.relativeHumidity ?? 0) / 100.0,
            pressure: response.airPressure?.meanSeaLevelMillibars ?? 1013.25,
            windSpeed: response.wind?.speed?.value ?? 0,
            windDirection: response.wind?.direction.map { Double($0.degrees) },
            uvIndex: response.uvIndex.map { Double($0) },
            visibility: response.visibility?.distance,
            cloudCover: Double(response.cloudCover ?? 0) / 100.0,
            dewPoint: response.dewPoint?.degrees,
            timestamp: parseTimestamp(response.currentTime) ?? Date()
        )
    }

    private func convertHourlyForecast(_ hour: GWForecastHour) -> HourlyForecast? {
        guard let timestamp = parseTimestamp(hour.interval.startTime) else {
            return nil
        }

        return HourlyForecast(
            timestamp: timestamp,
            temperature: hour.temperature?.degrees ?? 0,
            apparentTemperature: hour.feelsLikeTemperature?.degrees ?? hour.temperature?.degrees ?? 0,
            condition: mapWeatherCondition(hour.weatherCondition?.type),
            precipitationChance: Double(hour.precipitation?.probability?.percent ?? 0) / 100.0,
            precipitationAmount: hour.precipitation?.qpf?.quantity,
            humidity: Double(hour.relativeHumidity ?? 0) / 100.0,
            windSpeed: hour.wind?.speed?.value,
            windDirection: hour.wind?.direction.map { Double($0.degrees) },
            uvIndex: hour.uvIndex.map { Double($0) },
            cloudCover: Double(hour.cloudCover ?? 0) / 100.0
        )
    }

    private func convertDailyForecast(_ day: GWForecastDay, timezone: TimeZone) -> DailyForecast? {
        guard let displayDate = day.displayDate else {
            return nil
        }

        var components = DateComponents()
        components.year = displayDate.year
        components.month = displayDate.month
        components.day = displayDate.day
        components.timeZone = timezone

        guard let date = Calendar.current.date(from: components) else {
            return nil
        }

        return DailyForecast(
            date: date,
            timezone: timezone,
            highTemperature: day.maxTemperature?.degrees ?? 0,
            lowTemperature: day.minTemperature?.degrees ?? 0,
            condition: mapWeatherCondition(day.daytimeForecast?.weatherCondition?.type),
            conditionDescription: day.daytimeForecast?.weatherCondition?.description.text ?? "Unknown",
            precipitationChance: Double(day.daytimeForecast?.precipitation?.probability?.percent ?? 0) / 100.0,
            precipitationAmount: day.daytimeForecast?.precipitation?.qpf?.quantity,
            sunrise: day.sunEvents?.sunriseTime.flatMap(parseTimestamp),
            sunset: day.sunEvents?.sunsetTime.flatMap(parseTimestamp),
            moonPhase: mapMoonPhase(day.moonEvents?.moonPhase),
            humidity: Double(day.daytimeForecast?.relativeHumidity ?? 0) / 100.0,
            windSpeed: day.daytimeForecast?.wind?.speed?.value,
            uvIndex: day.daytimeForecast?.uvIndex.map { Double($0) }
        )
    }

    private func parseTimestamp(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Try with fractional seconds first (current conditions format)
        if let date = formatter.date(from: string) {
            return date
        }

        // Fallback: try without fractional seconds (hourly/daily format)
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }

    private func mapWeatherCondition(_ code: String?) -> WeatherCondition {
        guard let code = code?.lowercased() else {
            return .unknown
        }

        // Map Google Weather condition codes to our WeatherCondition enum
        // Reference: https://developers.google.com/maps/documentation/weather/reference/weather-condition-codes
        if code.contains("clear") || code.contains("sunny") {
            return .clear
        } else if code.contains("partly_cloudy") || code.contains("mostly_clear") {
            return .partlyCloudy
        } else if code.contains("cloudy") || code.contains("overcast") {
            return .cloudy
        } else if code.contains("fog") {
            return .fog
        } else if code.contains("haze") {
            return .haze
        } else if code.contains("drizzle") || code.contains("light_rain") {
            return .drizzle
        } else if code.contains("heavy_rain") {
            return .heavyRain
        } else if code.contains("rain") || code.contains("showers") {
            return .rain
        } else if code.contains("heavy_snow") {
            return .heavySnow
        } else if code.contains("light_snow") || code.contains("flurries") {
            return .lightSnow
        } else if code.contains("snow") {
            return .snow
        } else if code.contains("sleet") || code.contains("freezing") {
            return .sleet
        } else if code.contains("thunderstorm") || code.contains("thunder") {
            return .thunderstorm
        } else if code.contains("wind") || code.contains("breezy") {
            return .wind
        } else {
            return .unknown
        }
    }

    private func mapMoonPhase(_ phase: String?) -> Double? {
        guard let phase = phase?.lowercased() else {
            return nil
        }

        // Map Google's moon phase enum to a 0-1 value
        // 0 = new moon, 0.25 = first quarter, 0.5 = full moon, 0.75 = last quarter
        switch phase {
        case "new_moon":
            return 0.0
        case "waxing_crescent":
            return 0.125
        case "first_quarter":
            return 0.25
        case "waxing_gibbous":
            return 0.375
        case "full_moon":
            return 0.5
        case "waning_gibbous":
            return 0.625
        case "last_quarter":
            return 0.75
        case "waning_crescent":
            return 0.875
        default:
            return nil
        }
    }
}
