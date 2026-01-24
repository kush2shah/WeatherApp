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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hourly Forecast")
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(forecasts.prefix(24)) { forecast in
                        HourlyForecastItem(forecast: forecast, timezone: timezone)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}

/// Individual hourly forecast item
struct HourlyForecastItem: View {
    let forecast: HourlyForecast
    let timezone: TimeZone

    var body: some View {
        VStack(spacing: 10) {
            // Time
            Text(formattedHour)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Icon
            WeatherIconView(condition: forecast.condition, size: 32)

            // Temperature
            Text(verbatim: forecast.temperature.temperatureString(unit: .fahrenheit))
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            // Precipitation
            if forecast.precipitationPercentage > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                    Text("\(forecast.precipitationPercentage)%")
                        .font(.caption2)
                }
                .foregroundStyle(.blue)
            }
        }
        .frame(width: 65)
        .padding(.vertical, 8)
    }

    private var formattedHour: String {
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.setLocalizedDateFormatFromTemplate("j")
        return formatter.string(from: forecast.timestamp)
    }
}

#Preview {
    ZStack {
        GradientBackgroundView()

        HourlyForecastCard(
            forecasts: [
                HourlyForecast(
                    timestamp: Date(),
                    temperature: 20,
                    condition: .clear,
                    precipitationChance: 0.1
                ),
                HourlyForecast(
                    timestamp: Date().addingTimeInterval(3600),
                    temperature: 19,
                    condition: .partlyCloudy,
                    precipitationChance: 0.3
                ),
                HourlyForecast(
                    timestamp: Date().addingTimeInterval(7200),
                    temperature: 18,
                    condition: .rain,
                    precipitationChance: 0.8
                ),
            ]
        )
    }
}
