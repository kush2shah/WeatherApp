//
//  DailyDetailView.swift
//  WeatherApp
//

import SwiftUI
import Charts

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

                    switch selection {
                    case .source:
                        hourlyTimelineSection
                        conditionsGridSection
                    case .compare:
                        comparisonSection
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

    // MARK: - Conditions Grid

    private var conditionsGridSection: some View {
        let columns = [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]

        return VStack(alignment: .leading, spacing: 12) {
            Label("Conditions", systemImage: "info.circle")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            LazyVGrid(columns: columns, spacing: 12) {
                // Sunrise/Sunset
                if let sunrise = forecast.sunrise, let sunset = forecast.sunset {
                    ConditionCell(
                        icon: "sun.horizon.fill",
                        iconColor: .orange,
                        title: "Sun",
                        value: "\(formatTime(sunrise)) - \(formatTime(sunset))"
                    )
                }

                // UV Index
                if let uv = forecast.uvIndex {
                    ConditionCell(
                        icon: "sun.max.fill",
                        iconColor: uvColor(for: uv),
                        title: "UV Index",
                        value: "\(Int(uv))",
                        subtitle: uvDescription(for: uv)
                    )
                }

                // Humidity
                if let humidity = forecast.humidity {
                    ConditionCell(
                        icon: "humidity.fill",
                        iconColor: .cyan,
                        title: "Humidity",
                        value: formatter.percentage(humidity)
                    )
                }

                // Wind
                if let wind = forecast.windSpeed {
                    ConditionCell(
                        icon: "wind",
                        iconColor: .gray,
                        title: "Wind",
                        value: formatter.wind(wind)
                    )
                }

                // Precipitation (show if chance > 10%)
                if forecast.precipitationChance > 0.1 {
                    ConditionCell(
                        icon: "cloud.rain.fill",
                        iconColor: .blue,
                        title: "Precipitation",
                        value: formatter.percentage(forecast.precipitationChance)
                    )

                    if let amount = forecast.precipitationAmount, amount > 0 {
                        ConditionCell(
                            icon: "drop.fill",
                            iconColor: .blue,
                            title: "Expected",
                            value: String(format: "%.1f mm", amount)
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal)
    }

    // MARK: - Comparison Section

    private var comparisonSection: some View {
        VStack(spacing: 20) {
            // Temperature comparison
            ComparisonChartCard(
                title: "Temperature Range",
                icon: "thermometer.medium"
            ) {
                temperatureComparisonChart
            }

            // Precipitation comparison
            ComparisonChartCard(
                title: "Precipitation Chance",
                icon: "cloud.rain"
            ) {
                precipitationComparisonChart
            }

            // Wind comparison
            ComparisonChartCard(
                title: "Wind Speed",
                icon: "wind"
            ) {
                windComparisonChart
            }
        }
        .padding(.horizontal)
    }

    private var temperatureComparisonChart: some View {
        Chart {
            ForEach(availableSources, id: \.self) { source in
                if let daily = dailyForecast(for: source) {
                    BarMark(
                        x: .value("Source", source.shortName),
                        yStart: .value("Low", daily.lowTemperature),
                        yEnd: .value("High", daily.highTemperature)
                    )
                    .foregroundStyle(colorForSource(source).gradient)
                    .cornerRadius(4)
                }
            }
        }
        .chartYAxisLabel("Temperature")
        .frame(height: 120)
    }

    private var precipitationComparisonChart: some View {
        Chart {
            ForEach(availableSources, id: \.self) { source in
                if let daily = dailyForecast(for: source) {
                    BarMark(
                        x: .value("Source", source.shortName),
                        y: .value("Chance", daily.precipitationChance * 100)
                    )
                    .foregroundStyle(colorForSource(source).gradient)
                    .cornerRadius(4)
                }
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxisLabel("%")
        .frame(height: 120)
    }

    private var windComparisonChart: some View {
        Chart {
            ForEach(availableSources, id: \.self) { source in
                if let daily = dailyForecast(for: source), let wind = daily.windSpeed {
                    BarMark(
                        x: .value("Source", source.shortName),
                        y: .value("Speed", wind * 2.237) // Convert m/s to mph
                    )
                    .foregroundStyle(colorForSource(source).gradient)
                    .cornerRadius(4)
                }
            }
        }
        .chartYAxisLabel("mph")
        .frame(height: 120)
    }

    private func dailyForecast(for source: WeatherSource) -> DailyForecast? {
        guard let weather = weatherData.weather(from: source) else { return nil }

        let calendar = Calendar.current
        return weather.daily.first { daily in
            calendar.isDate(daily.date, inSameDayAs: forecast.date)
        }
    }

    private func colorForSource(_ source: WeatherSource) -> Color {
        switch source {
        case .weatherKit: return .blue
        case .noaa: return .green
        case .openWeatherMap: return .orange
        case .tomorrowIO: return .purple
        }
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = forecast.timezone
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: date)
    }

    private func uvColor(for uv: Double) -> Color {
        switch uv {
        case 0..<3: return .green
        case 3..<6: return .yellow
        case 6..<8: return .orange
        case 8..<11: return .red
        default: return .purple
        }
    }

    private func uvDescription(for uv: Double) -> String {
        switch uv {
        case 0..<3: return "Low"
        case 3..<6: return "Moderate"
        case 6..<8: return "High"
        case 8..<11: return "Very High"
        default: return "Extreme"
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

/// Individual condition metric cell
struct ConditionCell: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    var subtitle: String? = nil

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)

            Text(value)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.quaternarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Card container for comparison charts
struct ComparisonChartCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        )
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
