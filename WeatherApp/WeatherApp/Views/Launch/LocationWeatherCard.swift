//
//  LocationWeatherCard.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI
import SwiftData

/// Card showing saved location with weather preview
struct LocationWeatherCard: View {
    let savedLocation: SavedLocation
    let weather: SourcedWeatherInfo?
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Location info
                VStack(alignment: .leading, spacing: 4) {
                    Text(savedLocation.name)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if let locality = savedLocation.locality,
                       locality != savedLocation.name {
                        Text(locality)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else if let area = savedLocation.administrativeArea {
                        Text(area)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Weather preview
                if let weather = weather {
                    HStack(spacing: 8) {
                        WeatherIconView(condition: weather.current.condition, size: 28)

                        Text(formattedTemperature(weather.current.temperature))
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                    }
                } else {
                    // Loading state
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Material.ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("Remove Location", systemImage: "trash")
            }
        }
    }

    private func formattedTemperature(_ celsius: Double) -> String {
        let fahrenheit = celsius * 9/5 + 32
        return "\(Int(fahrenheit.rounded()))°"
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 12) {
            LocationWeatherCard(
                savedLocation: SavedLocation(
                    name: "San Francisco",
                    latitude: 37.7749,
                    longitude: -122.4194,
                    administrativeArea: "California"
                ),
                weather: nil,
                onTap: {},
                onDelete: {}
            )

            LocationWeatherCard(
                savedLocation: SavedLocation(
                    name: "New York",
                    latitude: 40.7128,
                    longitude: -74.0060,
                    locality: "Manhattan"
                ),
                weather: nil,
                onTap: {},
                onDelete: {}
            )
        }
        .padding()
    }
}
