//
//  ForecastComparisonView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Main forecast comparison view using system patterns
struct ForecastComparisonView: View {
    let weatherData: WeatherData
    @State private var viewModel = ComparisonViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let comparisonData = viewModel.comparisonData {
                    // Chart Section
                    Section {
                        VStack(alignment: .leading, spacing: 16) {
                            Picker("Metric", selection: $viewModel.selectedMetric) {
                                ForEach(ComparisonMetric.allCases) { metric in
                                    Text(metric.rawValue).tag(metric)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            ComparisonChartView(
                                data: comparisonData,
                                metric: viewModel.selectedMetric
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                    } header: {
                        Text("Forecast Trends")
                    }

                    // Key Differences Section
                    Section {
                        DifferenceRow(
                            icon: "thermometer.medium",
                            title: "Temperature Variance",
                            value: String(format: "%.1f°", comparisonData.temperatureVariance),
                            description: "Max spread between sources",
                            severity: temperatureSeverity(for: comparisonData)
                        )

                        if comparisonData.precipitationDifference > 0 {
                            DifferenceRow(
                                icon: "cloud.rain.fill",
                                title: "Precipitation Disagreement",
                                value: String(format: "%.0f%%", comparisonData.precipitationDifference),
                                description: "Difference in rain chance",
                                severity: precipitationSeverity(for: comparisonData)
                            )
                        }

                        if comparisonData.windVariance > 0 {
                            DifferenceRow(
                                icon: "wind",
                                title: "Wind Speed Variance",
                                value: String(format: "%.1f mph", comparisonData.windVariance),
                                description: "Difference in wind speed",
                                severity: windSeverity(for: comparisonData)
                            )
                        }
                    } header: {
                        Text("Key Differences")
                    } footer: {
                        Text("Variance indicates how much the weather sources disagree.")
                    }

                    // Sources Section
                    Section("Source Details") {
                        ForEach(Array(weatherData.sources.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { source in
                            if let weather = weatherData.sources[source] {
                                SourceDetailRow(source: source, weather: weather)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Compare")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                viewModel.analyzeWeatherData(weatherData)
            }
        }
    }
    
    // MARK: - Severity Helpers
    
    private func temperatureSeverity(for data: ComparisonData) -> DifferenceSeverity {
        if data.temperatureVariance < 5 { return .low }
        else if data.temperatureVariance < 10 { return .medium }
        else { return .high }
    }

    private func precipitationSeverity(for data: ComparisonData) -> DifferenceSeverity {
        if data.precipitationDifference < 20 { return .low }
        else if data.precipitationDifference < 40 { return .medium }
        else { return .high }
    }

    private func windSeverity(for data: ComparisonData) -> DifferenceSeverity {
        if data.windVariance < 5 { return .low }
        else if data.windVariance < 15 { return .medium }
        else { return .high }
    }
}

/// Standard list row for highlighting differences
struct DifferenceRow: View {
    let icon: String
    let title: String
    let value: String
    let description: String
    let severity: DifferenceSeverity

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(severity.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(value)
                .font(.callout)
                .fontWeight(.bold)
                .foregroundStyle(severity.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(severity.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 4)
    }
}

/// Standard list row for source details
struct SourceDetailRow: View {
    let source: WeatherSource
    let weather: SourcedWeatherInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(source.displayName)
                    .font(.headline)
                Spacer()
                Text(verbatim: weather.current.temperature.temperatureString(unit: .fahrenheit))
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            HStack(spacing: 12) {
                Label(weather.current.conditionDescription, systemImage: weather.current.condition.sfSymbolName)
                Spacer()
                Label("\(Int(weather.current.humidityPercentage))%", systemImage: "humidity")
                Label("\(Int(weather.current.windSpeedMph)) mph", systemImage: "wind")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .symbolRenderingMode(.hierarchical)
        }
        .padding(.vertical, 4)
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
}
