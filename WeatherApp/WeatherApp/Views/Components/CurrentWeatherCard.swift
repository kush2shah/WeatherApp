//
//  CurrentWeatherCard.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Large current weather card with frosted glass effect
struct CurrentWeatherCard: View {
    let weather: CurrentWeather

    var body: some View {
        VStack(spacing: 16) {
            // Weather icon
            WeatherIconView(condition: weather.condition, size: 80)

            // Temperature
            Text(verbatim: weather.temperature.temperatureString(unit: .fahrenheit))
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(.primary)

            // Condition
            Text(weather.conditionDescription)
                .font(.title3)
                .foregroundStyle(.secondary)

            // Feels like
            Text(verbatim: "Feels like \(weather.apparentTemperature.temperatureString(unit: .fahrenheit))")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()
                .foregroundStyle(.primary.opacity(0.2))
                .padding(.vertical, 8)

            // Details grid
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 20
            ) {
                WeatherDetailItem(
                    icon: "humidity.fill",
                    label: "Humidity",
                    value: "\(weather.humidityPercentage)%"
                )

                WeatherDetailItem(
                    icon: "wind",
                    label: "Wind",
                    value: "\(Int(weather.windSpeedMph)) mph \(weather.windDirectionCardinal ?? "")"
                )

                WeatherDetailItem(
                    icon: "barometer",
                    label: "Pressure",
                    value: "\(Int(weather.pressure)) hPa"
                )

                if let uvIndex = weather.uvIndex {
                    WeatherDetailItem(
                        icon: "sun.max.fill",
                        label: "UV Index",
                        value: "\(Int(uvIndex))"
                    )
                }

                if let visibility = weather.visibility {
                    WeatherDetailItem(
                        icon: "eye.fill",
                        label: "Visibility",
                        value: "\(Int(visibility / 1000)) km"
                    )
                }

                if let cloudCover = weather.cloudCoverPercentage {
                    WeatherDetailItem(
                        icon: "cloud.fill",
                        label: "Cloud Cover",
                        value: "\(cloudCover)%"
                    )
                }
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
    }
}

/// Individual weather detail item
struct WeatherDetailItem: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ZStack {
        GradientBackgroundView()

        CurrentWeatherCard(
            weather: CurrentWeather(
                temperature: 20,
                apparentTemperature: 18,
                condition: .partlyCloudy,
                conditionDescription: "Partly Cloudy",
                humidity: 0.65,
                pressure: 1013,
                windSpeed: 5.5,
                windDirection: 180,
                uvIndex: 3,
                visibility: 10000,
                cloudCover: 0.4,
                dewPoint: 12,
                timestamp: Date()
            )
        )
    }
}
