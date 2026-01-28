//
//  HourlyForecastCard.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Horizontal scrolling hourly forecast
struct HourlyForecastCard: View {
    let forecasts: [HourlyForecast]
    var timezone: TimeZone = .current
    var sunrise: Date? = nil
    var sunset: Date? = nil

    /// Filter forecasts to start from current hour
    private var filteredForecasts: [HourlyForecast] {
        let now = Date()
        return forecasts.filter { $0.timestamp >= now }
    }

    /// Timeline items including hourly forecasts and sun events
    private enum TimelineItem: Identifiable {
        case hour(HourlyForecast)
        case sunrise(Date)
        case sunset(Date)

        var id: String {
            switch self {
            case .hour(let h): return h.id.uuidString
            case .sunrise(let d): return "sunrise-\(d.timeIntervalSince1970)"
            case .sunset(let d): return "sunset-\(d.timeIntervalSince1970)"
            }
        }

        var sortDate: Date {
            switch self {
            case .hour(let h): return h.timestamp
            case .sunrise(let d): return d
            case .sunset(let d): return d
            }
        }
    }

    private var timelineItems: [TimelineItem] {
        let filtered = filteredForecasts.prefix(24)
        var items: [TimelineItem] = filtered.map { .hour($0) }

        guard let firstHour = filtered.first?.timestamp,
              let lastHour = filtered.last?.timestamp else {
            return items
        }

        // Add sunrise if within the visible hours
        if let sunrise = sunrise, sunrise >= firstHour && sunrise <= lastHour {
            items.append(.sunrise(sunrise))
        }

        // Add sunset if within the visible hours
        if let sunset = sunset, sunset >= firstHour && sunset <= lastHour {
            items.append(.sunset(sunset))
        }

        return items.sorted { $0.sortDate < $1.sortDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Hourly Forecast", systemImage: "clock")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 20) {
                    ForEach(timelineItems) { item in
                        switch item {
                        case .hour(let forecast):
                            HourlyForecastItem(
                                forecast: forecast,
                                timezone: timezone,
                                sunrise: sunrise,
                                sunset: sunset
                            )
                        case .sunrise(let time):
                            SunEventItem(isSunrise: true, time: time, timezone: timezone)
                        case .sunset(let time):
                            SunEventItem(isSunrise: false, time: time, timezone: timezone)
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.vertical, 20)
        .background(
            Material.ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .padding(.horizontal)
    }
}

/// Individual hourly forecast item
struct HourlyForecastItem: View {
    let forecast: HourlyForecast
    let timezone: TimeZone
    var sunrise: Date? = nil
    var sunset: Date? = nil

    private var isNight: Bool {
        guard let sunrise = sunrise, let sunset = sunset else { return false }
        return forecast.timestamp < sunrise || forecast.timestamp >= sunset
    }

    var body: some View {
        VStack(spacing: 12) {
            // Time
            Text(formattedHour)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            // Icon
            WeatherIconView(condition: forecast.condition, size: 28, isNight: isNight)
                .frame(height: 32)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)

            // Temperature
            Text(verbatim: forecast.temperature.temperatureString(unit: .fahrenheit))
                .font(.system(.callout, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            // Precip chance if significant
            if forecast.precipitationPercentage > 10 {
                Text("\(forecast.precipitationPercentage)%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.blue)
            }
        }
    }

    private var formattedHour: String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateFormat = "h a"
        return formatter.string(from: forecast.timestamp)
    }
}

/// Sunrise or sunset marker for the hourly timeline
struct SunEventItem: View {
    let isSunrise: Bool
    let time: Date
    let timezone: TimeZone

    var body: some View {
        VStack(spacing: 12) {
            // Time
            Text(formattedTime)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.orange)

            // Icon
            Image(systemName: isSunrise ? "sunrise.fill" : "sunset.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 28))
                .frame(height: 32)

            // Label
            Text(isSunrise ? "Sunrise" : "Sunset")
                .font(.system(.caption2, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.orange)
        }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateFormat = "h:mm"
        return formatter.string(from: time)
    }
}

#Preview {
    ZStack {
        Color.gray
        HourlyForecastCard(
            forecasts: [
                HourlyForecast(timestamp: Date(), temperature: 72, condition: .clear, precipitationChance: 0),
                HourlyForecast(timestamp: Date().addingTimeInterval(3600), temperature: 71, condition: .partlyCloudy, precipitationChance: 0.2),
                HourlyForecast(timestamp: Date().addingTimeInterval(7200), temperature: 70, condition: .cloudy, precipitationChance: 0.4)
            ]
        )
    }
}