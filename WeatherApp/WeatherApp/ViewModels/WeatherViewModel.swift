//
//  WeatherViewModel.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation
import SwiftData
import Observation

/// ViewModel for weather data management
@MainActor
@Observable
final class WeatherViewModel {
    var weatherData: WeatherData?
    var selectedSource: WeatherSource?
    var isLoading = false
    var isLoadingCached = false
    var error: Error?

    private let weatherAggregator: WeatherAggregator
    private let modelContext: ModelContext
    private let geocodingService: GeocodingServiceProtocol
    private let cacheService: any CachingServiceProtocol

    init(
        weatherAggregator: WeatherAggregator? = nil,
        geocodingService: GeocodingServiceProtocol? = nil,
        cacheService: (any CachingServiceProtocol)? = nil,
        modelContext: ModelContext
    ) {
        self.weatherAggregator = weatherAggregator ?? WeatherAggregator()
        self.geocodingService = geocodingService ?? GeocodingService()
        self.modelContext = modelContext
        self.cacheService = cacheService ?? WeatherCacheService(modelContext: modelContext)
    }

    /// Fetch weather for a location from all available sources
    func fetchWeather(for location: Location) async {
        isLoading = true
        error = nil

        let result = await weatherAggregator.fetchAllAvailableWeather(for: location)
        var sources = result.sources
        var sourceErrors = result.errors

        // If fetch failed and we have a locality, try generalizing
        if sources.isEmpty, let city = location.locality {
            print("Initial fetch failed for \(location.name). Attempting to generalize to \(city)...")
            do {
                let generalizedLocation = try await geocodingService.geocode(address: city)
                let generalizedResult = await weatherAggregator.fetchAllAvailableWeather(for: generalizedLocation)
                sources = generalizedResult.sources
                sourceErrors = generalizedResult.errors

                if !sources.isEmpty {
                    print("Generalized fetch succeeded for \(city)")

                    let data = WeatherData(
                        location: generalizedLocation,
                        sources: sources,
                        sourceErrors: sourceErrors
                    )

                    weatherData = data
                    selectedSource = data.primarySource
                    saveLocation(generalizedLocation)
                    isLoading = false
                    return
                }
            } catch {
                print("Failed to generalize location: \(error)")
            }
        }

        guard !sources.isEmpty else {
            error = APIError.serviceUnavailable
            isLoading = false
            return
        }

        let data = WeatherData(
            location: location,
            sources: sources,
            sourceErrors: sourceErrors
        )

        weatherData = data
        selectedSource = data.primarySource

        // Save location
        saveLocation(location)

        isLoading = false
    }

    /// Refresh weather for current location
    func refresh() async {
        guard let location = weatherData?.location else { return }
        await fetchWeather(for: location)
    }

    /// Refresh weather from a specific source
    func refreshSource(_ source: WeatherSource) async {
        guard let location = weatherData?.location else { return }

        do {
            print("[\(source.rawValue)] Manually refreshing...")
            let weather = try await weatherAggregator.fetchWeather(from: source, for: location)

            // Update weatherData with new source data
            var updatedSources = weatherData?.sources ?? [:]
            updatedSources[source] = weather

            var updatedErrors = weatherData?.sourceErrors ?? [:]
            updatedErrors.removeValue(forKey: source)

            weatherData = WeatherData(
                location: location,
                sources: updatedSources,
                sourceErrors: updatedErrors
            )

            print("[\(source.rawValue)] Refresh successful")
        } catch {
            print("[\(source.rawValue)] Refresh failed: \(error)")

            // Update error in weatherData
            var updatedErrors = weatherData?.sourceErrors ?? [:]
            updatedErrors[source] = error.localizedDescription

            weatherData = WeatherData(
                location: location,
                sources: weatherData?.sources ?? [:],
                sourceErrors: updatedErrors
            )
        }
    }

    /// Get current sourced weather
    var currentWeather: SourcedWeatherInfo? {
        guard let source = selectedSource,
              let weather = weatherData?.weather(from: source) else {
            return nil
        }
        return weather
    }

    // MARK: - Private Helpers

    /// Save location to SwiftData
    private func saveLocation(_ location: Location) {
        // Check if location already exists by coordinates (not UUID)
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let tolerance = 0.01 // ~1km tolerance

        let descriptor = FetchDescriptor<SavedLocation>(
            predicate: #Predicate {
                $0.latitude > lat - tolerance &&
                $0.latitude < lat + tolerance &&
                $0.longitude > lon - tolerance &&
                $0.longitude < lon + tolerance
            }
        )

        do {
            let existing = try modelContext.fetch(descriptor)
            if existing.isEmpty {
                let saved = SavedLocation.from(location)
                modelContext.insert(saved)
                try modelContext.save()
            }
        } catch {
            print("Failed to save location: \(error)")
        }
    }
}
