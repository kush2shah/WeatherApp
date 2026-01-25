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
            VStack(spacing: 24) {
                // Location header
                VStack(spacing: 4) {
                    Text(weatherData.location.name)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                    Text("Updated \(weatherData.fetchedAt, style: .relative) ago")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 10)

                // Source picker (Glassy segment)
                if weatherData.availableSources.count > 1 {
                    Picker("Source", selection: $selectedSource) {
                        ForEach(weatherData.availableSources, id: \.self) { source in
                            Text(source.shortName).tag(source)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                }

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
                    if weatherData.availableSources.count > 1 {
                        Button {
                            showComparison = true
                        } label: {
                            HStack {
                                Image(systemName: "chart.xyaxis.line")
                                Text("Compare Sources")
                            }
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Material.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(.horizontal, 24)
                    }

                    // Attribution
                    Text(weather.attribution)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.bottom)
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showComparison) {
            ForecastComparisonView(weatherData: weatherData)
        }
    }
}