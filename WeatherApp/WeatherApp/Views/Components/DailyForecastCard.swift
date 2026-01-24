//
//  DailyForecastCard.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Daily forecast card with list of days
struct DailyForecastCard: View {
    let forecasts: [DailyForecast]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("10-Day Forecast")
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.top, 16)

            VStack(spacing: 0) {
                ForEach(Array(forecasts.prefix(10).enumerated()), id: \.element.id) { index, forecast in
                    DailyForecastRow(forecast: forecast)

                    if index < min(9, forecasts.count - 1) {
                        Divider()
                            .foregroundStyle(.primary.opacity(0.2))
                            .padding(.leading, 70)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}

/// Individual daily forecast row
struct DailyForecastRow: View {
    let forecast: DailyForecast

    var body: some View {
        HStack(spacing: 12) {
            // Day
            Text(isToday ? "Today" : forecast.shortDayName)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(width: 50, alignment: .leading)

            // Icon
            WeatherIconView(condition: forecast.condition, size: 28)
                .frame(width: 40)

            // Precipitation
            if forecast.precipitationPercentage > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.caption)
                    Text("\(forecast.precipitationPercentage)%")
                        .font(.caption)
                }
                .foregroundStyle(.blue)
                .frame(width: 50)
            } else {
                Spacer()
                    .frame(width: 50)
            }

            Spacer()

            // Temperature range
            HStack(spacing: 8) {
                Text(verbatim: forecast.lowTemperature.temperatureString(unit: .fahrenheit))
                    .foregroundStyle(.tertiary)

                // Temperature bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.primary.opacity(0.2))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * temperatureRatio)
                    }
                }
                .frame(width: 60, height: 4)

                Text(verbatim: forecast.highTemperature.temperatureString(unit: .fahrenheit))
                    .foregroundStyle(.primary)
                    .fontWeight(.semibold)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(forecast.date)
    }

    private var temperatureRatio: CGFloat {
        // Simple ratio for visual effect
        let range = forecast.highTemperatureFahrenheit - forecast.lowTemperatureFahrenheit
        return min(max(range / 30, 0.3), 1.0)
    }
}

#Preview {
    ZStack {
        GradientBackgroundView()

        DailyForecastCard(
            forecasts: (0..<7).map { day in
                DailyForecast(
                    date: Calendar.current.date(byAdding: .day, value: day, to: Date())!,
                    highTemperature: Double(20 + day),
                    lowTemperature: Double(10 + day),
                    condition: .partlyCloudy,
                    conditionDescription: "Partly Cloudy",
                    precipitationChance: Double(day) * 0.1
                )
            }
        )
    }
}
