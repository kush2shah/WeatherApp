//
//  CachedWeather.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation
import SwiftData

/// Cached weather data with 1-hour expiration
@Model
final class CachedWeather {
    @Attribute(.unique) var id: UUID
    var locationId: UUID
    var source: String
    var weatherDataJSON: Data
    var cachedAt: Date
    var expiresAt: Date

    init(
        id: UUID = UUID(),
        locationId: UUID,
        source: WeatherSource,
        weatherData: SourcedWeatherInfo,
        cachedAt: Date = Date(),
        cacheExpiration: TimeInterval = 3600 // 1 hour
    ) {
        self.id = id
        self.locationId = locationId
        self.source = source.rawValue
        self.weatherDataJSON = (try? JSONEncoder().encode(weatherData)) ?? Data()
        self.cachedAt = cachedAt
        self.expiresAt = cachedAt.addingTimeInterval(cacheExpiration)
    }

    /// Check if cache is still valid
    var isValid: Bool {
        Date() < expiresAt
    }

    /// Decode cached weather data
    func decode() -> SourcedWeatherInfo? {
        try? JSONDecoder().decode(SourcedWeatherInfo.self, from: weatherDataJSON)
    }
}
