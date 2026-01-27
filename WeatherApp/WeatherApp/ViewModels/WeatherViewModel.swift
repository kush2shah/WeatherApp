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
    private let cacheService: WeatherCacheService

    init(
        weatherAggregator: WeatherAggregator? = nil,
        geocodingService: GeocodingServiceProtocol? = nil,
        modelContext: ModelContext
    ) {
        self.weatherAggregator = weatherAggregator ?? WeatherAggregator()
        self.geocodingService = geocodingService ?? GeocodingService()
        self.modelContext = modelContext
        self.cacheService = WeatherCacheService(modelContext: modelContext)
    }

    /// Fetch weather for a location from all available sources
    func fetchWeather(for location: Location) async {
        isLoading = true
        error = nil

        var sources = await weatherAggregator.fetchAllAvailableWeather(for: location)

        // If fetch failed and we have a locality, try generalizing
        if sources.isEmpty, let city = location.locality {
            print("Initial fetch failed for \(location.name). Attempting to generalize to \(city)...")
            do {
                let generalizedLocation = try await geocodingService.geocode(address: city)
                sources = await weatherAggregator.fetchAllAvailableWeather(for: generalizedLocation)
                
                if !sources.isEmpty {
                    print("Generalized fetch succeeded for \(city)")
                    
                    let data = WeatherData(
                        location: generalizedLocation,
                        sources: sources
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
            sources: sources
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
        // Check if location already exists
        let descriptor = FetchDescriptor<SavedLocation>(
            predicate: #Predicate { $0.id == location.id }
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
