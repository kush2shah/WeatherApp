//
//  DifferenceHighlightView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Highlights key differences between weather sources
struct DifferenceHighlightView: View {
    let comparisonData: ComparisonData

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Differences")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(spacing: 12) {
                // Temperature variance
                DifferenceCard(
                    icon: "thermometer.medium",
                    title: "Temperature Spread",
                    value: String(format: "%.1f°", comparisonData.temperatureVariance),
                    description: "Difference between highest and lowest forecast",
                    severity: temperatureSeverity
                )

                // Precipitation disagreement
                if comparisonData.precipitationDifference > 0 {
                    DifferenceCard(
                        icon: "cloud.rain.fill",
                        title: "Precipitation Disagreement",
                        value: String(format: "%.0f%%", comparisonData.precipitationDifference),
                        description: "Maximum difference in rain predictions",
                        severity: precipitationSeverity
                    )
                }

                // Wind speed variance
                if comparisonData.windVariance > 0 {
                    DifferenceCard(
                        icon: "wind",
                        title: "Wind Speed Variance",
                        value: String(format: "%.1f mph", comparisonData.windVariance),
                        description: "Variation in wind speed forecasts",
                        severity: windSeverity
                    )
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Severity Levels

    private var temperatureSeverity: DifferenceSeverity {
        if comparisonData.temperatureVariance < 5 {
            return .low
        } else if comparisonData.temperatureVariance < 10 {
            return .medium
        } else {
            return .high
        }
    }

    private var precipitationSeverity: DifferenceSeverity {
        if comparisonData.precipitationDifference < 20 {
            return .low
        } else if comparisonData.precipitationDifference < 40 {
            return .medium
        } else {
            return .high
        }
    }

    private var windSeverity: DifferenceSeverity {
        if comparisonData.windVariance < 5 {
            return .low
        } else if comparisonData.windVariance < 15 {
            return .medium
        } else {
            return .high
        }
    }
}

/// Individual difference card
struct DifferenceCard: View {
    let icon: String
    let title: String
    let value: String
    let description: String
    let severity: DifferenceSeverity

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(severity.color)
                .frame(width: 40)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            // Value
            Text(verbatim: value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(severity.color)
        }
        .padding()
        .background(severity.color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// Severity level for differences
enum DifferenceSeverity {
    case low
    case medium
    case high

    var color: Color {
        switch self {
        case .low:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .red
        }
    }

    var label: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Moderate"
        case .high:
            return "High"
        }
    }
}
