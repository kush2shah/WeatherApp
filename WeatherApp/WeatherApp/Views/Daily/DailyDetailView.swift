//
//  DailyDetailView.swift
//  WeatherApp
//

import SwiftUI

/// Detail view for a single day's weather, presented as bottom sheet
struct DailyDetailView: View {
    let forecast: DailyForecast
    let weatherData: WeatherData

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSource: WeatherSource?
    @State private var showComparison = false

    private let formatter = WeatherFormatter.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            selectedSource = weatherData.primarySource
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(formatter.date(forecast.date, timezone: forecast.timezone, style: .long))
                .font(.system(.title2, design: .rounded))
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("High")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatter.temperature(forecast.highTemperature))
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.medium)
                }

                WeatherIconView(condition: forecast.condition, size: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Low")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatter.temperature(forecast.lowTemperature))
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }

            Text(forecast.conditionDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
}

#Preview {
    DailyDetailView(
        forecast: DailyForecast(
            date: Date(),
            highTemperature: 24,
            lowTemperature: 15,
            condition: .partlyCloudy,
            conditionDescription: "Partly Cloudy",
            precipitationChance: 0.2,
            sunrise: Calendar.current.date(bySettingHour: 7, minute: 15, second: 0, of: Date()),
            sunset: Calendar.current.date(bySettingHour: 17, minute: 45, second: 0, of: Date()),
            humidity: 0.65,
            windSpeed: 5.2,
            uvIndex: 6
        ),
        weatherData: WeatherData(
            location: Location(
                name: "San Francisco",
                coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194)
            ),
            sources: [:]
        )
    )
}
