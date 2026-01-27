//
//  DailyDetailView.swift
//  WeatherApp
//

import SwiftUI

/// Selection state for the source picker
enum SourceSelection: Hashable {
    case source(WeatherSource)
    case compare
}

/// Detail view for a single day's weather, presented as bottom sheet
struct DailyDetailView: View {
    let forecast: DailyForecast
    let weatherData: WeatherData

    @Environment(\.dismiss) private var dismiss
    @State private var selection: SourceSelection = .compare

    private let formatter = WeatherFormatter.shared

    private var availableSources: [WeatherSource] {
        weatherData.availableSources
    }

    /// Get hourly forecasts for the selected day from the selected source
    private var hourlyForDay: [HourlyForecast] {
        guard case .source(let source) = selection,
              let weather = weatherData.weather(from: source) else {
            return []
        }

        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: forecast.date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart

        return weather.hourly.filter { hourly in
            hourly.timestamp >= dayStart && hourly.timestamp < dayEnd
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    sourcePickerSection

                    if case .source = selection {
                        hourlyTimelineSection
                    }
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
            if let primary = weatherData.primarySource {
                selection = .source(primary)
            }
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

    // MARK: - Source Picker

    private var sourcePickerSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableSources, id: \.self) { source in
                    SourcePickerButton(
                        title: source.shortName,
                        isSelected: selection == .source(source)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = .source(source)
                        }
                    }
                }

                if availableSources.count > 1 {
                    SourcePickerButton(
                        title: "Compare",
                        isSelected: selection == .compare,
                        icon: "chart.bar.xaxis"
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = .compare
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Hourly Timeline

    @ViewBuilder
    private var hourlyTimelineSection: some View {
        if !hourlyForDay.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Hourly", systemImage: "clock")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(hourlyForDay) { hour in
                            DailyHourCell(hour: hour, timezone: forecast.timezone)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal)
        }
    }
}

/// Individual hour cell for the timeline
struct DailyHourCell: View {
    let hour: HourlyForecast
    let timezone: TimeZone

    private let formatter = WeatherFormatter.shared

    var body: some View {
        VStack(spacing: 10) {
            // Time
            Text(formattedTime)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            // Icon
            WeatherIconView(condition: hour.condition, size: 24)

            // Temperature
            Text(formatter.temperature(hour.temperature))
                .font(.subheadline)
                .fontWeight(.semibold)

            // Precipitation (if any)
            if hour.precipitationChance > 0 {
                Text(formatter.percentage(hour.precipitationChance))
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            } else {
                Text(" ")
                    .font(.caption2)
            }

            // Wind
            if let wind = hour.windSpeed {
                Text(formatter.wind(wind))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 56)
        .padding(.vertical, 8)
    }

    private var formattedTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = timezone
        dateFormatter.dateFormat = "ha"
        return dateFormatter.string(from: hour.timestamp).lowercased()
    }
}

/// Pill-style button for source selection
struct SourcePickerButton: View {
    let title: String
    let isSelected: Bool
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? Color.primary.opacity(0.9)
                    : Color(.tertiarySystemFill)
            )
            .foregroundStyle(isSelected ? Color(.systemBackground) : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
