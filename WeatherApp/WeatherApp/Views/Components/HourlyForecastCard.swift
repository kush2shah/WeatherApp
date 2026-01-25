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

    /// Filter forecasts to start from current hour
    private var filteredForecasts: [HourlyForecast] {
        let now = Date()
        return forecasts.filter { $0.timestamp >= now }
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
                    ForEach(filteredForecasts.prefix(24)) { forecast in
                        HourlyForecastItem(forecast: forecast, timezone: timezone)
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

    var body: some View {
        VStack(spacing: 12) {
            // Time
            Text(formattedHour)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.primary)

            // Icon
            WeatherIconView(condition: forecast.condition, size: 28)
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