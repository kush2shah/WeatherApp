//
//  LaunchView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI
import SwiftData
import CoreLocation

/// Launch screen with saved locations and expandable search
struct LaunchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedLocation.createdAt, order: .reverse) private var savedLocations: [SavedLocation]
    @State private var locationManager = LocationManager()
    @State private var isSearchExpanded = false
    @State private var currentLocationWeather: SourcedWeatherInfo?
    @State private var currentLocation: Location?
    @State private var isLoadingCurrentWeather = false
    @State private var savedLocationWeather: [UUID: SourcedWeatherInfo] = [:]

    let onLocationSelected: (Location) -> Void

    private let geocodingService = GeocodingService()
    private let weatherAggregator = WeatherAggregator()

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            ExpandableSearchBar(
                isExpanded: $isSearchExpanded,
                modelContext: modelContext,
                onLocationSelected: onLocationSelected
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .zIndex(1)

            if !isSearchExpanded {
                mainContent
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSearchExpanded)
        .onAppear {
            setupLocationManager()
            fetchWeatherForSavedLocations()
        }
        .onChange(of: locationManager.currentLocation) { _, newLocation in
            guard let clLocation = newLocation else { return }
            Task {
                await handleCurrentLocationUpdate(clLocation)
            }
        }
        .onChange(of: locationManager.authorizationStatus) { _, newStatus in
            if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
                locationManager.requestLocation()
            }
        }
        .onChange(of: savedLocations.count) { _, _ in
            fetchWeatherForSavedLocations()
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Current location hero (if authorized)
                if locationManager.isAuthorized {
                    CurrentLocationHero(
                        location: currentLocation,
                        weather: currentLocationWeather,
                        isLoading: isLoadingCurrentWeather,
                        onTap: {
                            if let location = currentLocation {
                                onLocationSelected(location)
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                } else {
                    // Welcome prompt for users without location permission
                    welcomePrompt
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }

                // Saved locations section
                if !savedLocations.isEmpty {
                    savedLocationsSection
                } else if !locationManager.isAuthorized {
                    emptyStateView
                }
            }
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Welcome Prompt

    private var welcomePrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 60))
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

            VStack(spacing: 8) {
                Text("Welcome to WeatherApp")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text("Search for a city to get started, or enable location services for local weather.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                withAnimation {
                    isSearchExpanded = true
                }
            } label: {
                Label("Search Location", systemImage: "magnifyingglass")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Material.ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            Material.ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    // MARK: - Saved Locations Section

    private var savedLocationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Saved Locations")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)

            ForEach(savedLocations) { savedLocation in
                LocationWeatherCard(
                    savedLocation: savedLocation,
                    weather: savedLocationWeather[savedLocation.id],
                    onTap: {
                        onLocationSelected(savedLocation.toDomain())
                    },
                    onDelete: {
                        deleteLocation(savedLocation)
                    }
                )
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)

            Text("No saved locations")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)

            Text("Search for cities to save them here")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Actions

    private func setupLocationManager() {
        if locationManager.isAuthorized {
            locationManager.requestLocation()
        }
    }

    private func handleCurrentLocationUpdate(_ clLocation: CLLocation) async {
        isLoadingCurrentWeather = true

        let coordinate = Coordinate(
            latitude: clLocation.coordinate.latitude,
            longitude: clLocation.coordinate.longitude
        )

        do {
            let location = try await geocodingService.reverseGeocode(coordinate: coordinate)
            await MainActor.run {
                currentLocation = location
            }

            // Fetch weather
            let result = await weatherAggregator.fetchAllAvailableWeather(for: location)
            if let primarySource = result.sources.keys.first,
               let weather = result.sources[primarySource] {
                await MainActor.run {
                    currentLocationWeather = weather
                    isLoadingCurrentWeather = false
                }
            } else {
                await MainActor.run {
                    isLoadingCurrentWeather = false
                }
            }
        } catch {
            await MainActor.run {
                isLoadingCurrentWeather = false
            }
        }
    }

    private func fetchWeatherForSavedLocations() {
        for savedLocation in savedLocations {
            // Skip if we already have weather for this location
            if savedLocationWeather[savedLocation.id] != nil { continue }

            Task {
                let location = savedLocation.toDomain()
                let result = await weatherAggregator.fetchAllAvailableWeather(for: location)
                if let primarySource = result.sources.keys.first,
                   let weather = result.sources[primarySource] {
                    await MainActor.run {
                        savedLocationWeather[savedLocation.id] = weather
                    }
                }
            }
        }
    }

    private func deleteLocation(_ location: SavedLocation) {
        withAnimation {
            savedLocationWeather.removeValue(forKey: location.id)
            modelContext.delete(location)
            try? modelContext.save()
        }
    }
}

#Preview {
    LaunchView(onLocationSelected: { _ in })
        .modelContainer(for: [SavedLocation.self, CachedWeather.self, SearchHistory.self], inMemory: true)
}
