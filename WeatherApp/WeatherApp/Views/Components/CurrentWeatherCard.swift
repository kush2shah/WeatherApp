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
        VStack(spacing: 0) {
            // Main Info
            VStack(spacing: 4) {
                WeatherIconView(condition: weather.condition, size: 80)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2) // Added contrast shadow
                    .padding(.bottom, 8)

                Text(verbatim: weather.temperature.temperatureString(unit: .fahrenheit))
                    .font(.system(size: 96, weight: .thin, design: .rounded))
                    .foregroundStyle(.primary)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1) // Subtle text shadow
                    .tracking(-2)

                Text(weather.conditionDescription)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    // Secondary text might need contrast help too, depending on background
            }
            .padding(.vertical, 30)

            // Scrollable Detail Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    DetailItem(label: "Wind", value: "\(Int(weather.windSpeedMph)) mph", icon: "wind")
                    
                    Divider().frame(height: 30).padding(.horizontal, 16)
                    
                    DetailItem(label: "Humidity", value: "\(weather.humidityPercentage)%", icon: "humidity")

                    Divider().frame(height: 30).padding(.horizontal, 16)

                    if let uv = weather.uvIndex {
                        DetailItem(label: "UV Index", value: "\(Int(uv))", icon: "sun.max")
                        Divider().frame(height: 30).padding(.horizontal, 16)
                    }
                    
                    DetailItem(label: "Pressure", value: "\(Int(weather.pressure))", icon: "barometer")
                    
                    if let visibility = weather.visibility {
                        Divider().frame(height: 30).padding(.horizontal, 16)
                        DetailItem(label: "Vis", value: "\(Int(visibility / 1000)) km", icon: "eye")
                    }
                    
                    if let cloud = weather.cloudCoverPercentage {
                        Divider().frame(height: 30).padding(.horizontal, 16)
                        DetailItem(label: "Clouds", value: "\(cloud)%", icon: "cloud")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
            .background(
                Material.ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .padding(.horizontal, 20)
        }
    }
}

private struct DetailItem: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.primary)
                    .fixedSize() // Prevent truncation
                
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fontWeight(.medium)
            }
        }
        .frame(minWidth: 60)
    }
}

#Preview {
    ZStack {
        Color.blue
        CurrentWeatherCard(
            weather: CurrentWeather(
                temperature: 72,
                apparentTemperature: 70,
                condition: .partlyCloudy,
                conditionDescription: "Partly Cloudy",
                humidity: 0.45,
                pressure: 1012,
                windSpeed: 8,
                windDirection: 180,
                uvIndex: 5,
                visibility: 10000,
                cloudCover: 0.2,
                dewPoint: 60,
                timestamp: Date()
            )
        )
    }
}