//
//  WeatherMainView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Main weather display view
struct WeatherMainView: View {
    let weatherData: WeatherData
    @Binding var selectedSource: WeatherSource
    @State private var showComparison = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Location header
                VStack(spacing: 4) {
                    Text(weatherData.location.name)
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    Text("Updated \(weatherData.fetchedAt, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top)

                // Source picker
                Picker("Source", selection: $selectedSource) {
                    ForEach(weatherData.availableSources, id: \.self) { source in
                        Text(source.shortName).tag(source)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .disabled(weatherData.availableSources.count <= 1)

                // Current weather
                if let weather = weatherData.weather(from: selectedSource) {
                    CurrentWeatherCard(weather: weather.current)

                    // Hourly forecast
                    HourlyForecastCard(
                        forecasts: weather.hourly,
                        timezone: weatherData.location.timezone
                    )

                    // Daily forecast
                    DailyForecastCard(forecasts: weather.daily)

                    // Comparison button
                    Button {
                        showComparison = true
                    } label: {
                        Label("Compare Forecasts", systemImage: "chart.line.uptrend.xyaxis")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                    .disabled(weatherData.availableSources.count <= 1)
                    .opacity(weatherData.availableSources.count <= 1 ? 0.6 : 1)

                    // Attribution
                    Text(weather.attribution)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding()
                }
            }
            .padding(.bottom, 20)
        }
        .sheet(isPresented: $showComparison) {
            ForecastComparisonView(weatherData: weatherData)
        }
    }
}
