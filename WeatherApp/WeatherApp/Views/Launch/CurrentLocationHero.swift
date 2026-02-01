//
//  CurrentLocationHero.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Hero section displaying current location weather prominently
struct CurrentLocationHero: View {
    let location: Location?
    let weather: SourcedWeatherInfo?
    let isLoading: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                if isLoading {
                    loadingState
                } else if let weather = weather, let location = location {
                    weatherContent(weather: weather, location: location)
                } else {
                    placeholderState
                }
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(
                Material.ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .disabled(location == nil || weather == nil)
    }

    // MARK: - Subviews

    private func weatherContent(weather: SourcedWeatherInfo, location: Location) -> some View {
        VStack(spacing: 8) {
            // Current Location label
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.caption)
                Text("Current Location")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
            }
            .foregroundStyle(.secondary)

            // Location name
            Text(location.name)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)

            // Weather icon and temperature
            HStack(spacing: 16) {
                WeatherIconView(condition: weather.current.condition, size: 60)

                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedTemperature(weather.current.temperature))
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(weather.current.condition.description)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.caption)
                Text("Current Location")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
            }
            .foregroundStyle(.secondary)

            ProgressView()
                .scaleEffect(1.2)
                .padding(.vertical, 20)

            Text("Getting weather...")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    private var placeholderState: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "location.fill")
                    .font(.caption)
                Text("Current Location")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
            }
            .foregroundStyle(.secondary)

            Image(systemName: "location.slash")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
                .padding(.vertical, 8)

            Text("Location unavailable")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.tertiary)
        }
    }

    private func formattedTemperature(_ celsius: Double) -> String {
        let fahrenheit = celsius * 9/5 + 32
        return "\(Int(fahrenheit.rounded()))°"
    }
}

#Preview("With Weather") {
    ZStack {
        LinearGradient(
            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        CurrentLocationHero(
            location: Location(
                name: "San Francisco",
                coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194)
            ),
            weather: SourcedWeatherInfo(
                source: .weatherKit,
                current: CurrentWeather(
                    temperature: 18,
                    apparentTemperature: 16,
                    condition: .partlyCloudy,
                    conditionDescription: "Partly Cloudy",
                    humidity: 0.65,
                    pressure: 1013,
                    windSpeed: 5.5,
                    windDirection: 270,
                    uvIndex: 3,
                    visibility: 16000,
                    cloudCover: 0.4,
                    dewPoint: 12,
                    timestamp: Date()
                ),
                hourly: [],
                daily: []
            ),
            isLoading: false,
            onTap: {}
        )
        .padding()
    }
}

#Preview("Loading") {
    ZStack {
        LinearGradient(
            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        CurrentLocationHero(
            location: nil,
            weather: nil,
            isLoading: true,
            onTap: {}
        )
        .padding()
    }
}
