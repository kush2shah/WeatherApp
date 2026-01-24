//
//  ForecastComparisonView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Main forecast comparison view
struct ForecastComparisonView: View {
    let weatherData: WeatherData
    @State private var viewModel = ComparisonViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                GradientBackgroundView()

                // Content
                ScrollView {
                    VStack(spacing: 24) {
                        // Metric picker
                        Picker("Metric", selection: $viewModel.selectedMetric) {
                            ForEach(ComparisonMetric.allCases) { metric in
                                Text(metric.rawValue).tag(metric)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.top)

                        // Chart
                        if let comparisonData = viewModel.comparisonData {
                            ComparisonChartView(
                                data: comparisonData,
                                metric: viewModel.selectedMetric
                            )
                            .padding(.horizontal)

                            // Difference highlights
                            DifferenceHighlightView(comparisonData: comparisonData)
                                .padding(.horizontal)

                            // Source details
                            SourceDetailsView(weatherData: weatherData)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Forecast Comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(.primary)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                viewModel.analyzeWeatherData(weatherData)
            }
        }
    }
}

/// Source details section
struct SourceDetailsView: View {
    let weatherData: WeatherData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Sources")
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal)

            VStack(spacing: 12) {
                ForEach(Array(weatherData.sources.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { source in
                    if let weather = weatherData.sources[source] {
                        SourceDetailCard(source: source, weather: weather)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Individual source detail card
struct SourceDetailCard: View {
    let source: WeatherSource
    let weather: SourcedWeatherInfo

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(source.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text(verbatim: weather.current.temperature.temperatureString(unit: .fahrenheit))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Condition")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text(weather.current.conditionDescription)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Humidity")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("\(weather.current.humidityPercentage)%")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Wind")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("\(Int(weather.current.windSpeedMph)) mph")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }

            Text(weather.attribution)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
