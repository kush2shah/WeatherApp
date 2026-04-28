
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
    var analysisError: String?

    /// Analyze weather data and produce all comparison analytics
    func analyzeWeatherData(_ weatherData: WeatherData) {
        analysisError = nil
        comparisonData = nil
        let now = Date()
        let endTime = now.addingTimeInterval(24 * 3600)

        // Build per-source time-series for each metric
        var temperatures: [WeatherSource: [DataPoint]] = [:]
        var precipitation: [WeatherSource: [DataPoint]] = [:]
        var wind: [WeatherSource: [DataPoint]] = [:]
        var humidity: [WeatherSource: [DataPoint]] = [:]

        for (source, weather) in weatherData.sources {
            let futureHourly = weather.hourly.filter {
                $0.timestamp >= now && $0.timestamp <= endTime
            }

            temperatures[source] = futureHourly.map {
                DataPoint(timestamp: $0.timestamp, value: $0.temperatureFahrenheit, source: source)
            }
            precipitation[source] = futureHourly.map {
                DataPoint(timestamp: $0.timestamp, value: Double($0.precipitationPercentage), source: source)
            }
            wind[source] = futureHourly.compactMap {
                guard let ws = $0.windSpeed else { return nil }
                return DataPoint(timestamp: $0.timestamp, value: ws * 2.23694, source: source)
            }
            humidity[source] = futureHourly.compactMap {
                guard let h = $0.humidity else { return nil }
                return DataPoint(timestamp: $0.timestamp, value: h * 100, source: source)
            }
        }

        let allSeries: [ComparisonMetric: [WeatherSource: [DataPoint]]] = [
            .temperature: temperatures,
            .precipitation: precipitation,
            .wind: wind,
            .humidity: humidity
        ]

        // Build uncertainty bands
        let uncertaintyBands = buildUncertaintyBands(from: allSeries)

        // Legacy variances
        let tempVariance = maxSpread(temperatures)
        let precipDiff   = maxSpread(precipitation)
        let windVar      = maxSpread(wind)

        // Agreement score
        let score = calculateAgreementScore(
            tempBand: uncertaintyBands[.temperature] ?? [],
            precipBand: uncertaintyBands[.precipitation] ?? [],
            windBand: uncertaintyBands[.wind] ?? []
        )

        // Outlier detection
        let outliers = detectOutliers(from: allSeries)

        // Peak disagreement time (highest temp spread hour)
        let peakTime = uncertaintyBands[.temperature]?
            .max(by: { $0.spread < $1.spread })?.timestamp

        // Human-readable insights
        let insights = generateInsights(
            weatherData: weatherData,
            tempBand: uncertaintyBands[.temperature] ?? [],
            precipBand: uncertaintyBands[.precipitation] ?? [],
            outliers: outliers,
            agreementScore: score
        )

        comparisonData = ComparisonData(
            temperatures: temperatures,
            precipitation: precipitation,
            wind: wind,
            humidity: humidity,
            uncertaintyBands: uncertaintyBands,
            agreementScore: score,
            outliers: outliers,
            insights: insights,
            peakDisagreementTime: peakTime,
            sourceCount: weatherData.sources.count,
            temperatureVariance: tempVariance,
            precipitationDifference: precipDiff,
            windVariance: windVar
        )
    }

    // MARK: - Uncertainty Bands

    private func buildUncertaintyBands(
        from allSeries: [ComparisonMetric: [WeatherSource: [DataPoint]]]
    ) -> [ComparisonMetric: [UncertaintyPoint]] {
        var result: [ComparisonMetric: [UncertaintyPoint]] = [:]

        for (metric, sourceSeries) in allSeries {
            guard !sourceSeries.isEmpty else { continue }

            // Collect all unique timestamps
            let allTimestamps = Set(sourceSeries.values.flatMap { $0.map { $0.timestamp } })

            let points: [UncertaintyPoint] = allTimestamps.sorted().compactMap { ts in
                // Gather values from all sources at this timestamp (within ±90s tolerance)
                let values = sourceSeries.values.compactMap { series -> Double? in
                    series.min(by: { abs($0.timestamp.timeIntervalSince(ts)) < abs($1.timestamp.timeIntervalSince(ts)) })
                        .flatMap { abs($0.timestamp.timeIntervalSince(ts)) < 90 ? $0.value : nil }
                }
                guard values.count >= 2, let min = values.min(), let max = values.max() else { return nil }
                let mean = values.reduce(0, +) / Double(values.count)
                return UncertaintyPoint(timestamp: ts, min: min, max: max, mean: mean)
            }

            result[metric] = points
        }

        return result
    }

    // MARK: - Agreement Score

    private func calculateAgreementScore(
        tempBand: [UncertaintyPoint],
        precipBand: [UncertaintyPoint],
        windBand: [UncertaintyPoint]
    ) -> Int {
        func avgSpread(_ band: [UncertaintyPoint]) -> Double {
            guard !band.isEmpty else { return 0 }
            return band.map { $0.spread }.reduce(0, +) / Double(band.count)
        }

        let tempScore    = max(0.0, 1.0 - avgSpread(tempBand) / 20.0)   // 20°F = full disagreement
        let precipScore  = max(0.0, 1.0 - avgSpread(precipBand) / 100.0)
        let windScore    = max(0.0, 1.0 - avgSpread(windBand) / 30.0)   // 30 mph = full disagreement

        let weightedScore = tempScore * 0.5 + precipScore * 0.3 + windScore * 0.2
        return Int((weightedScore * 100).rounded())
    }

    // MARK: - Outlier Detection

    private func detectOutliers(
        from allSeries: [ComparisonMetric: [WeatherSource: [DataPoint]]]
    ) -> [SourceOutlier] {
        var result: [SourceOutlier] = []

        // Only check temperature and precipitation for user-facing outliers
        for metric in [ComparisonMetric.temperature, .precipitation] {
            guard let sourceSeries = allSeries[metric], sourceSeries.count >= 3 else { continue }

            // Count how many times each source is an outlier across time points
            var outlierCounts: [WeatherSource: (count: Int, totalDev: Double)] = [:]
            let allTimestamps = Set(sourceSeries.values.flatMap { $0.map { $0.timestamp } })

            for ts in allTimestamps {
                var valuesAtTime: [(source: WeatherSource, value: Double)] = []
                for (source, series) in sourceSeries {
                    if let closest = series.min(by: { abs($0.timestamp.timeIntervalSince(ts)) < abs($1.timestamp.timeIntervalSince(ts)) }),
                       abs(closest.timestamp.timeIntervalSince(ts)) < 90 {
                        valuesAtTime.append((source: source, value: closest.value))
                    }
                }
                guard valuesAtTime.count >= 3 else { continue }

                let sorted = valuesAtTime.sorted { $0.value < $1.value }
                let q1 = sorted[sorted.count / 4].value
                let q3 = sorted[(sorted.count * 3) / 4].value
                let iqr = q3 - q1
                let median = sorted[sorted.count / 2].value
                guard iqr > 0 else { continue }

                for item in valuesAtTime {
                    let dev = abs(item.value - median)
                    if dev > 1.5 * iqr {
                        var entry = outlierCounts[item.source] ?? (0, 0)
                        entry.count += 1
                        entry.totalDev += dev
                        outlierCounts[item.source] = entry
                    }
                }
            }

            // Pick the worst offender for this metric
            if let (source, stats) = outlierCounts.max(by: { $0.value.count < $1.value.count }),
               stats.count >= 3 {
                let avgDev = stats.totalDev / Double(stats.count)
                let description: String
                switch metric {
                case .temperature:
                    let dir = avgDev > 0 ? "warmer" : "cooler"
                    description = "\(String(format: "%.0f", abs(avgDev)))° \(dir) than consensus"
                case .precipitation:
                    description = "\(String(format: "%.0f", abs(avgDev)))% higher rain chance"
                default:
                    description = "diverges from consensus"
                }
                result.append(SourceOutlier(
                    source: source,
                    metric: metric.rawValue,
                    deviation: avgDev,
                    description: description
                ))
            }
        }

        return result
    }

    // MARK: - Insight Generation

    private func generateInsights(
        weatherData: WeatherData,
        tempBand: [UncertaintyPoint],
        precipBand: [UncertaintyPoint],
        outliers: [SourceOutlier],
        agreementScore: Int
    ) -> [ComparisonInsight] {
        var insights: [ComparisonInsight] = []
        let sourceCount = weatherData.sources.count

        // 1. Overall agreement headline
        if agreementScore >= 85 {
            insights.append(ComparisonInsight(
                icon: "checkmark.seal.fill",
                title: "Strong consensus",
                detail: "All \(sourceCount) sources are in close agreement for the next 24 hours.",
                severity: .low
            ))
        } else if agreementScore < 50 {
            insights.append(ComparisonInsight(
                icon: "exclamationmark.triangle.fill",
                title: "High forecast uncertainty",
                detail: "Sources disagree significantly — the actual weather is harder to predict right now.",
                severity: .high
            ))
        }

        // 2. Peak disagreement
        if let peakPoint = tempBand.max(by: { $0.spread < $1.spread }), peakPoint.spread >= 5 {
            let formatter = DateFormatter()
            formatter.dateFormat = "h a"
            let timeStr = formatter.string(from: peakPoint.timestamp)
            insights.append(ComparisonInsight(
                icon: "chart.line.uptrend.xyaxis",
                title: "Biggest split at \(timeStr)",
                detail: "Sources vary by \(String(format: "%.0f", peakPoint.spread))°F at \(timeStr) — highest disagreement of the day.",
                severity: peakPoint.spread >= 10 ? .high : .medium
            ))
        }

        // 3. Rain consensus
        let rainHours = precipBand.filter { $0.mean >= 40 }
        if !rainHours.isEmpty {
            let agreePrecip = precipBand.filter { $0.min >= 30 }
            if agreePrecip.count >= 2 {
                insights.append(ComparisonInsight(
                    icon: "cloud.rain.fill",
                    title: "Sources agree: rain likely",
                    detail: "\(sourceCount) sources predict a meaningful chance of rain.",
                    severity: .medium
                ))
            } else if rainHours.count >= 3 {
                let splitCount = precipBand.filter { $0.spread >= 30 }.count
                if splitCount >= 2 {
                    insights.append(ComparisonInsight(
                        icon: "cloud.drizzle.fill",
                        title: "Sources split on rain",
                        detail: "Some sources predict rain; others don't. Bring an umbrella just in case.",
                        severity: .medium
                    ))
                }
            }
        } else {
            let allAgreeNoPrecip = precipBand.filter { $0.max < 20 }.count
            if allAgreeNoPrecip >= precipBand.count / 2 && !precipBand.isEmpty {
                insights.append(ComparisonInsight(
                    icon: "sun.max.fill",
                    title: "Dry forecast consensus",
                    detail: "All sources agree: no significant precipitation expected.",
                    severity: .low
                ))
            }
        }

        // 4. Outlier callouts
        for outlier in outliers.prefix(1) {
            insights.append(ComparisonInsight(
                icon: "exclamationmark.circle.fill",
                title: "\(outlier.source.shortName) is the outlier",
                detail: "\(outlier.source.displayName) \(outlier.description) for \(outlier.metric.lowercased()).",
                severity: .medium
            ))
        }

        return insights
    }

    // MARK: - Legacy Helpers

    private func maxSpread(_ data: [WeatherSource: [DataPoint]]) -> Double {
        guard !data.isEmpty else { return 0 }
        var maxSpread = 0.0
        let timePoints = Set(data.values.flatMap { $0.map { $0.timestamp } })
        for time in timePoints {
            let vals = data.values.compactMap { pts in
                pts.first { $0.timestamp == time }?.value
            }
            guard vals.count > 1 else { continue }
            maxSpread = Swift.max(maxSpread, (vals.max() ?? 0) - (vals.min() ?? 0))
        }
        return maxSpread
    }
}
