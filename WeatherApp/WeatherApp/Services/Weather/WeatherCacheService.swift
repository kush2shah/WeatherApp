//
//  WeatherCacheService.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation
import SwiftData

/// Service for caching weather data
@MainActor
final class WeatherCacheService: CachingServiceProtocol {
    private let modelContext: ModelContext
    private let cacheExpiration: TimeInterval

    init(
        modelContext: ModelContext,
        cacheExpiration: TimeInterval = 3600 // 1 hour
    ) {
        self.modelContext = modelContext
        self.cacheExpiration = cacheExpiration
    }

    /// Get cached weather for a location and source
    func getCachedWeather(
        locationId: UUID,
        source: WeatherSource
    ) -> SourcedWeatherInfo? {
        let now = Date()
        let descriptor = FetchDescriptor<CachedWeather>(
            predicate: #Predicate<CachedWeather> { cached in
                cached.locationId == locationId &&
                cached.source == source.rawValue &&
                cached.expiresAt > now
            }
        )

        do {
            guard let cached = try modelContext.fetch(descriptor).first,
                  let weather = cached.decode() else {
                return nil
            }

            return weather
        } catch {
            print("Failed to fetch cached weather: \(error)")
            return nil
        }
    }

    /// Cache weather data
    func cacheWeather(_ weather: SourcedWeatherInfo, locationId: UUID) {
        let cached = CachedWeather(
            locationId: locationId,
            source: weather.source,
            weatherData: weather,
            cacheExpiration: cacheExpiration
        )

        modelContext.insert(cached)

        do {
            try modelContext.save()
        } catch {
            print("Failed to cache weather: \(error)")
        }
    }

    /// Clear expired cache entries
    func clearExpiredCache() {
        let now = Date()
        let descriptor = FetchDescriptor<CachedWeather>(
            predicate: #Predicate<CachedWeather> { cached in
                cached.expiresAt <= now
            }
        )

        do {
            let expired = try modelContext.fetch(descriptor)
            for cached in expired {
                modelContext.delete(cached)
            }
            try modelContext.save()
        } catch {
            print("Failed to clear expired cache: \(error)")
        }
    }

    /// Clear all cache
    func clearAllCache() {
        let descriptor = FetchDescriptor<CachedWeather>()

        do {
            let allCached = try modelContext.fetch(descriptor)
            for cached in allCached {
                modelContext.delete(cached)
            }
            try modelContext.save()
        } catch {
            print("Failed to clear all cache: \(error)")
        }
    }
}
