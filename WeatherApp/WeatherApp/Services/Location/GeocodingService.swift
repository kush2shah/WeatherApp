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

        guard let request = MKGeocodingRequest(addressString: trimmed) else {
            throw GeocodingError.invalidAddress
        }

        do {
            let mapItems = try await request.mapItems
            guard let mapItem = mapItems.first else {
                throw GeocodingError.noResults
            }
            return locationFromMapItem(mapItem)
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

        guard let request = MKReverseGeocodingRequest(location: clLocation) else {
            throw GeocodingError.invalidCoordinate
        }

        do {
            let mapItems = try await request.mapItems
            guard let mapItem = mapItems.first else {
                throw GeocodingError.noResults
            }
            return locationFromMapItem(mapItem)
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

    /// Create Location from MKMapItem
    private func locationFromMapItem(_ mapItem: MKMapItem) -> Location {
        let clCoordinate = mapItem.location.coordinate
        let coordinate = Coordinate(latitude: clCoordinate.latitude, longitude: clCoordinate.longitude)
        let placemark = mapItem.placemark

        let name = [placemark.locality, placemark.administrativeArea, placemark.country]
            .compactMap { $0 }
            .joined(separator: ", ")
        let fallbackName = "\(coordinate.latitude), \(coordinate.longitude)"

        return Location(
            name: name.isEmpty ? fallbackName : name,
            coordinate: coordinate,
            timezone: placemark.timeZone ?? .current,
            country: placemark.country,
            isoCountryCode: placemark.isoCountryCode,
            administrativeArea: placemark.administrativeArea,
            locality: placemark.locality
        )
    }
}
