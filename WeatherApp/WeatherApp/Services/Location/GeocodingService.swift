//
//  GeocodingService.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation
import CoreLocation
import MapKit

/// Geocoding service supporting multiple input formats
actor GeocodingService: GeocodingServiceProtocol {
    private let geocoder = CLGeocoder()

    /// Geocode an address string to a location
    /// Supports formats:
    /// - Zip code: "94102"
    /// - City, State: "San Francisco, CA"
    /// - City only: "Seattle"
    /// - Coordinates: "37.7749,-122.4194"
    func geocode(address: String) async throws -> Location {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check if input is coordinates (lat,lon or lat, lon)
        if let coordinate = parseCoordinates(from: trimmed) {
            return try await reverseGeocode(coordinate: coordinate)
        }

        // Use CLGeocoder for address lookup
        do {
            let placemarks = try await geocoder.geocodeAddressString(trimmed)

            guard let placemark = placemarks.first,
                  let clLocation = placemark.location else {
                throw GeocodingError.noResults
            }

            return locationFromPlacemark(placemark, clLocation: clLocation)
        } catch {
            if let geocodingError = error as? GeocodingError {
                throw geocodingError
            }
            throw GeocodingError.networkError(error)
        }
    }

    /// Reverse geocode coordinates to a location
    func reverseGeocode(coordinate: Coordinate) async throws -> Location {
        guard coordinate.latitude >= -90 && coordinate.latitude <= 90 &&
              coordinate.longitude >= -180 && coordinate.longitude <= 180 else {
            throw GeocodingError.invalidCoordinate
        }

        let clLocation = CLLocation(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(clLocation)

            guard let placemark = placemarks.first else {
                throw GeocodingError.noResults
            }

            return locationFromPlacemark(placemark, clLocation: clLocation)
        } catch {
            if let geocodingError = error as? GeocodingError {
                throw geocodingError
            }
            throw GeocodingError.networkError(error)
        }
    }

    // MARK: - Private Helpers

    /// Parse coordinate string in format "lat,lon"
    private func parseCoordinates(from string: String) -> Coordinate? {
        let components = string.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        guard components.count == 2,
              let lat = Double(components[0]),
              let lon = Double(components[1]) else {
            return nil
        }

        let coordinate = Coordinate(latitude: lat, longitude: lon)
        return coordinate.isValid ? coordinate : nil
    }

    /// Create Location from CLPlacemark
    private func locationFromPlacemark(_ placemark: CLPlacemark, clLocation: CLLocation) -> Location {
        let name = [
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ]
        .compactMap { $0 }
        .joined(separator: ", ")

        let fallbackName = "\(clLocation.coordinate.latitude), \(clLocation.coordinate.longitude)"

        return Location(
            name: name.isEmpty ? fallbackName : name,
            coordinate: Coordinate(
                latitude: clLocation.coordinate.latitude,
                longitude: clLocation.coordinate.longitude
            ),
            timezone: placemark.timeZone ?? .current,
            country: placemark.country,
            administrativeArea: placemark.administrativeArea,
            locality: placemark.locality
        )
    }
}
