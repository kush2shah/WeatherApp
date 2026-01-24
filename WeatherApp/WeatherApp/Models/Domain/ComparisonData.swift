//
//  ComparisonData.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// Comparison data for multiple weather sources
struct ComparisonData {
    let temperatures: [WeatherSource: [DataPoint]]
    let precipitation: [WeatherSource: [DataPoint]]
    let wind: [WeatherSource: [DataPoint]]
    let humidity: [WeatherSource: [DataPoint]]

    /// Temperature variance across all sources
    let temperatureVariance: Double

    /// Maximum precipitation difference
    let precipitationDifference: Double

    /// Wind speed variance
    let windVariance: Double
}

/// Data point for charting
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

/// Comparison metric type
enum ComparisonMetric: String, CaseIterable, Identifiable {
    case temperature = "Temperature"
    case precipitation = "Precipitation"
    case wind = "Wind Speed"
    case humidity = "Humidity"

    var id: String { rawValue }

    var unit: String {
        switch self {
        case .temperature:
            return "°F"
        case .precipitation:
            return "%"
        case .wind:
            return "mph"
        case .humidity:
            return "%"
        }
    }
}
