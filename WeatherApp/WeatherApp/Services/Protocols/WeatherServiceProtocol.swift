//
//  WeatherServiceProtocol.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation

/// Protocol for weather service implementations
protocol WeatherServiceProtocol: Sendable {
    /// The weather source this service provides
    var source: WeatherSource { get }

    /// Check if service is available for this location
    var isAvailable: Bool { get }

    /// Fetch weather data for a location
    /// - Parameter location: The location to fetch weather for
    /// - Returns: Sourced weather information
    /// - Throws: APIError if the fetch fails
    func fetchWeather(for location: Location) async throws -> SourcedWeatherInfo

    /// Check if service is available for a specific location
    /// - Parameter location: The location to check
    /// - Returns: True if service can provide data for this location
    func checkAvailability(for location: Location) -> Bool
}

/// Default implementation
extension WeatherServiceProtocol {
    var isAvailable: Bool { true }

    func checkAvailability(for location: Location) -> Bool {
        isAvailable
    }
}
