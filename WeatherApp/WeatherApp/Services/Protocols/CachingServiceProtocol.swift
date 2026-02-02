//
//  CachingServiceProtocol.swift
//  WeatherApp
//
//  Created by Kush Shah on 2/1/26.
//

import Foundation

/// Protocol for weather caching services, enabling dependency injection and testing
@MainActor
protocol CachingServiceProtocol {
    /// Get cached weather for a location and source
    func getCachedWeather(locationId: UUID, source: WeatherSource) -> SourcedWeatherInfo?

    /// Cache weather data
    func cacheWeather(_ weather: SourcedWeatherInfo, locationId: UUID)

    /// Clear expired cache entries
    func clearExpiredCache()

    /// Clear all cache
    func clearAllCache()
}
