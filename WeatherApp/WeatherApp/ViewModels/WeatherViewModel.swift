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
    private var activeFetchTask: Task<Void, Never>?
    private var activeRefreshTask: Task<Void, Never>?

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
        activeFetchTask?.cancel()
        let task = Task { [weak self] in
            guard let self else { return }
            await self.performFetchWeather(for: location)
        }
        activeFetchTask = task
        await task.value
    }

    /// Refresh weather for current location
    func refresh() async {
        guard let location = weatherData?.location else { return }
        await fetchWeather(for: location)
    }

    /// Refresh weather from a specific source
    func refreshSource(_ source: WeatherSource) async {
        activeRefreshTask?.cancel()
        let task = Task { [weak self] in
            guard let self else { return }
            await self.performRefreshSource(source)
        }
        activeRefreshTask = task
        await task.value
    }

    private func performRefreshSource(_ source: WeatherSource) async {
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
            cacheService.cacheWeather(weather, locationId: location.cacheLocationId)
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

    private func performFetchWeather(for location: Location) async {
        isLoading = true
        isLoadingCached = false
        error = nil

        cacheService.clearExpiredCache()

        let cacheLocationId = location.cacheLocationId
        var cachedSources: [WeatherSource: SourcedWeatherInfo] = [:]
        for source in WeatherSource.allCases {
            if let cached = cacheService.getCachedWeather(locationId: cacheLocationId, source: source) {
                cachedSources[source] = cached
            }
        }

        if !cachedSources.isEmpty {
            let cachedData = WeatherData(
                location: location,
                sources: cachedSources
            )
            weatherData = cachedData
            if selectedSource == nil || cachedSources[selectedSource!] == nil {
                selectedSource = cachedData.primarySource
            }
            isLoadingCached = true
        }

        if Task.isCancelled { return }

        let result = await weatherAggregator.fetchAllAvailableWeather(for: location)
        var sources = result.sources
        var sourceErrors = result.errors
        var finalLocation = location

        // If fetch failed and we have a locality, try generalizing
        if sources.isEmpty, let city = location.locality {
            print("Initial fetch failed for \(location.name). Attempting to generalize to \(city)...")
            do {
                let generalizedLocation = try await geocodingService.geocode(address: city)
                let generalizedResult = await weatherAggregator.fetchAllAvailableWeather(for: generalizedLocation)
                sources = generalizedResult.sources
                sourceErrors = generalizedResult.errors
                finalLocation = generalizedLocation

                if !sources.isEmpty {
                    print("Generalized fetch succeeded for \(city)")
                }
            } catch {
                print("Failed to generalize location: \(error)")
            }
        }

        if Task.isCancelled { return }

        guard !sources.isEmpty else {
            error = APIError.serviceUnavailable
            isLoading = false
            isLoadingCached = false
            return
        }

        let data = WeatherData(
            location: finalLocation,
            sources: sources,
            sourceErrors: sourceErrors
        )

        weatherData = data
        selectedSource = data.primarySource

        // Save location and cache results
        saveLocation(finalLocation)
        let finalCacheLocationId = finalLocation.cacheLocationId
        for (_, weather) in sources {
            cacheService.cacheWeather(weather, locationId: finalCacheLocationId)
        }

        isLoading = false
        isLoadingCached = false
    }
}
