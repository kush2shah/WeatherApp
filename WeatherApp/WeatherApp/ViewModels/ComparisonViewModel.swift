//
//  ComparisonViewModel.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation
import Observation

/// ViewModel for forecast comparison
@MainActor
@Observable
final class ComparisonViewModel {
    var selectedMetric: ComparisonMetric = .temperature
    var comparisonData: ComparisonData?

    /// Analyze weather data and calculate comparisons
    func analyzeWeatherData(_ weatherData: WeatherData) {
        var temperatures: [WeatherSource: [DataPoint]] = [:]
        var precipitation: [WeatherSource: [DataPoint]] = [:]
        var wind: [WeatherSource: [DataPoint]] = [:]
        var humidity: [WeatherSource: [DataPoint]] = [:]

        let now = Date()
        let endTime = now.addingTimeInterval(24 * 3600) // 24 hours from now

        // Extract data from each source
        for (source, weather) in weatherData.sources {
            // Filter to 24-hour time window (not count) to normalize across different intervals
            let futureHourly = weather.hourly.filter {
                $0.timestamp >= now && $0.timestamp <= endTime
            }

            // Temperature data points
            temperatures[source] = futureHourly.map { forecast in
                DataPoint(
                    timestamp: forecast.timestamp,
                    value: forecast.temperatureFahrenheit,
                    source: source
                )
            }

            // Precipitation data points
            precipitation[source] = futureHourly.map { forecast in
                DataPoint(
                    timestamp: forecast.timestamp,
                    value: Double(forecast.precipitationPercentage),
                    source: source
                )
            }

            // Wind data points
            wind[source] = futureHourly.compactMap { forecast in
                guard let windSpeed = forecast.windSpeed else { return nil }
                return DataPoint(
                    timestamp: forecast.timestamp,
                    value: windSpeed * 2.23694, // m/s to mph
                    source: source
                )
            }

            // Humidity data points
            humidity[source] = futureHourly.compactMap { forecast in
                guard let humidity = forecast.humidity else { return nil }
                return DataPoint(
                    timestamp: forecast.timestamp,
                    value: humidity * 100, // 0-1 to percentage
                    source: source
                )
            }
        }

        // Calculate variances
        let tempVariance = calculateVariance(temperatures)
        let precipDiff = calculateMaxDifference(precipitation)
        let windVar = calculateVariance(wind)

        comparisonData = ComparisonData(
            temperatures: temperatures,
            precipitation: precipitation,
            wind: wind,
            humidity: humidity,
            temperatureVariance: tempVariance,
            precipitationDifference: precipDiff,
            windVariance: windVar
        )
    }

    // MARK: - Private Helpers

    /// Calculate variance across all sources at each time point
    private func calculateVariance(_ data: [WeatherSource: [DataPoint]]) -> Double {
        guard !data.isEmpty else { return 0 }

        var maxVariance = 0.0
        let timePoints = Set(data.values.flatMap { $0.map { $0.timestamp } })

        for time in timePoints {
            let valuesAtTime = data.values.compactMap { points in
                points.first { $0.timestamp == time }?.value
            }

            guard valuesAtTime.count > 1 else { continue }

            let max = valuesAtTime.max() ?? 0
            let min = valuesAtTime.min() ?? 0
            let variance = max - min

            maxVariance = Swift.max(maxVariance, variance)
        }

        return maxVariance
    }

    /// Calculate maximum difference in precipitation predictions
    private func calculateMaxDifference(_ data: [WeatherSource: [DataPoint]]) -> Double {
        guard !data.isEmpty else { return 0 }

        var maxDiff = 0.0
        let timePoints = Set(data.values.flatMap { $0.map { $0.timestamp } })

        for time in timePoints {
            let valuesAtTime = data.values.compactMap { points in
                points.first { $0.timestamp == time }?.value
            }

            guard valuesAtTime.count > 1 else { continue }

            let max = valuesAtTime.max() ?? 0
            let min = valuesAtTime.min() ?? 0
            let diff = max - min

            maxDiff = Swift.max(maxDiff, diff)
        }

        return maxDiff
    }
}
