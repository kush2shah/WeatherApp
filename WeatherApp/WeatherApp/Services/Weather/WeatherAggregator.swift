//
//  WeatherAggregator.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// Aggregates weather data from multiple sources
@MainActor
final class WeatherAggregator {
    private let services: [any WeatherServiceProtocol]

    init(services: [any WeatherServiceProtocol]) {
        self.services = services
    }

    /// Convenience initializer with default services
    convenience init() {
        var services: [any WeatherServiceProtocol] = []

        // Always include WeatherKit (Priority #1)
        services.append(WeatherKitService())

        // Include Google Weather if API key is configured (Priority #2)
        if Config.isSourceEnabled(.googleWeather) {
            services.append(GoogleWeatherService())
        }

        // Always include NOAA (US only) (Priority #3)
        services.append(NOAAWeatherService())

        // Include OpenWeatherMap if API key is configured (Priority #4)
        if Config.isSourceEnabled(.openWeatherMap) {
            services.append(OpenWeatherMapService())
        }

        // Include Tomorrow.io if API key is configured (Priority #5)
        if Config.isSourceEnabled(.tomorrowIO) {
            services.append(TomorrowIOService())
        }

        self.init(services: services)
    }

    /// Fetch weather from all available sources in parallel
    func fetchAllAvailableWeather(for location: Location) async -> [WeatherSource: SourcedWeatherInfo] {
        var results: [WeatherSource: SourcedWeatherInfo] = [:]

        await withTaskGroup(of: (WeatherSource, SourcedWeatherInfo?).self) { group in
            for service in services where service.checkAvailability(for: location) {
                group.addTask {
                    do {
                        let weather = try await service.fetchWeather(for: location)
                        return (service.source, weather)
                    } catch {
                        print("[\(service.source.rawValue)] Error: \(error)")
                        return (service.source, nil)
                    }
                }
            }

            for await (source, weather) in group {
                if let weather = weather {
                    results[source] = weather
                }
            }
        }

        return results
    }

    /// Fetch weather from a specific source
    func fetchWeather(from source: WeatherSource, for location: Location) async throws -> SourcedWeatherInfo {
        guard let service = services.first(where: { $0.source == source }) else {
            throw APIError.serviceUnavailable
        }

        guard service.checkAvailability(for: location) else {
            throw APIError.serviceUnavailable
        }

        return try await service.fetchWeather(for: location)
    }
}
