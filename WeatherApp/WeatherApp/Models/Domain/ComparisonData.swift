
//
//  ComparisonData.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation
import SwiftUI

// MARK: - Chart Data

/// Data point for charting (legacy, kept for compatibility)
struct DataPoint: Identifiable {
    let id: UUID
    let timestamp: Date
    let value: Double
    let source: WeatherSource

    init(timestamp: Date, value: Double, source: WeatherSource) {
        self.id = UUID()
        self.timestamp = timestamp
        self.value = value
        self.source = source
    }
}

/// A time-slice showing the spread across all sources for a given metric
struct UncertaintyPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let min: Double
    let max: Double
    let mean: Double
    var spread: Double { max - min }
}

// MARK: - Insights

/// A source that is significantly diverging from the consensus
struct SourceOutlier {
    let source: WeatherSource
    let metric: String
    let deviation: Double
    let description: String  // e.g. "8° warmer than consensus"
}

/// A human-readable insight card generated from the data
struct ComparisonInsight: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
    let severity: DifferenceSeverity
}

// MARK: - Comparison Data Container

/// Full comparison data for multiple weather sources
struct ComparisonData {
    // Raw time-series per source (used by legacy code paths)
    let temperatures: [WeatherSource: [DataPoint]]
    let precipitation: [WeatherSource: [DataPoint]]
    let wind: [WeatherSource: [DataPoint]]
    let humidity: [WeatherSource: [DataPoint]]

    // Uncertainty bands: min/max/mean across all sources per time point
    let uncertaintyBands: [ComparisonMetric: [UncertaintyPoint]]

    // Analytics
    let agreementScore: Int          // 0–100, higher = more agreement
    let outliers: [SourceOutlier]
    let insights: [ComparisonInsight]
    let peakDisagreementTime: Date?
    let sourceCount: Int

    // Legacy variance fields (kept for any remaining callers)
    let temperatureVariance: Double
    let precipitationDifference: Double
    let windVariance: Double

    /// Per-source time-series for a given metric
    func series(for metric: ComparisonMetric) -> [WeatherSource: [DataPoint]] {
        switch metric {
        case .temperature:   return temperatures
        case .precipitation: return precipitation
        case .wind:          return wind
        case .humidity:      return humidity
        }
    }
}

// MARK: - Metric Type

/// Which metric is being displayed in the comparison chart
enum ComparisonMetric: String, CaseIterable, Identifiable {
    case temperature = "Temperature"
    case precipitation = "Precipitation"
    case wind = "Wind"
    case humidity = "Humidity"

    var id: String { rawValue }

    var unit: String {
        switch self {
        case .temperature:   return "°F"
        case .precipitation: return "%"
        case .wind:          return "mph"
        case .humidity:      return "%"
        }
    }

    var icon: String {
        switch self {
        case .temperature:   return "thermometer.medium"
        case .precipitation: return "cloud.rain.fill"
        case .wind:          return "wind"
        case .humidity:      return "humidity.fill"
        }
    }
}

// MARK: - Severity

/// Severity level for differences between sources
enum DifferenceSeverity {
    case low
    case medium
    case high

    var color: Color {
        switch self {
        case .low:    return .green
        case .medium: return .orange
        case .high:   return .red
        }
    }
}
