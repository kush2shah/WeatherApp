//
//  GeocodingServiceProtocol.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation
import CoreLocation

/// Protocol for geocoding services
protocol GeocodingServiceProtocol: Sendable {
    /// Geocode an address string to a location
    /// - Parameter address: Address string (city, zip code, etc.)
    /// - Returns: Location with coordinates
    /// - Throws: GeocodingError if geocoding fails
    func geocode(address: String) async throws -> Location

    /// Reverse geocode coordinates to a location
    /// - Parameter coordinate: Coordinate to reverse geocode
    /// - Returns: Location with name and metadata
    /// - Throws: GeocodingError if reverse geocoding fails
    func reverseGeocode(coordinate: Coordinate) async throws -> Location
}

/// Geocoding errors
enum GeocodingError: LocalizedError {
    case invalidAddress
    case invalidCoordinate
    case noResults
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidAddress:
            return "Invalid address format"
        case .invalidCoordinate:
            return "Invalid coordinates"
        case .noResults:
            return "No location found"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown:
            return "Unknown geocoding error"
        }
    }
}
