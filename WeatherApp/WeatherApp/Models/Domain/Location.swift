//
//  Location.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation
import CoreLocation
import CryptoKit

/// Represents a geographic location with coordinates and metadata
struct Location: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let name: String
    let coordinate: Coordinate
    let timezone: TimeZone
    let country: String?
    let isoCountryCode: String? // ISO 3166-1 alpha-2 (e.g., "US", "GB")
    let administrativeArea: String? // State/Province
    let locality: String? // City

    init(
        id: UUID = UUID(),
        name: String,
        coordinate: Coordinate,
        timezone: TimeZone = .current,
        country: String? = nil,
        isoCountryCode: String? = nil,
        administrativeArea: String? = nil,
        locality: String? = nil
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.timezone = timezone
        self.country = country
        self.isoCountryCode = isoCountryCode
        self.administrativeArea = administrativeArea
        self.locality = locality
    }

    /// Create location from CLLocationCoordinate2D
    init(
        name: String,
        clCoordinate: CLLocationCoordinate2D,
        timezone: TimeZone = .current,
        country: String? = nil,
        isoCountryCode: String? = nil,
        administrativeArea: String? = nil,
        locality: String? = nil
    ) {
        self.init(
            name: name,
            coordinate: Coordinate(
                latitude: clCoordinate.latitude,
                longitude: clCoordinate.longitude
            ),
            timezone: timezone,
            country: country,
            isoCountryCode: isoCountryCode,
            administrativeArea: administrativeArea,
            locality: locality
        )
    }

    /// Convert to CLLocationCoordinate2D
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
}

/// Codable coordinate representation
struct Coordinate: Codable, Hashable, Sendable {
    let latitude: Double
    let longitude: Double

    /// Validate coordinate values
    var isValid: Bool {
        latitude >= -90 && latitude <= 90 &&
        longitude >= -180 && longitude <= 180
    }
}

extension Location {
    /// Stable cache key derived from normalized coordinates.
    var cacheLocationId: UUID {
        let normalizedLat = String(format: "%.4f", coordinate.latitude)
        let normalizedLon = String(format: "%.4f", coordinate.longitude)
        let key = "\(normalizedLat),\(normalizedLon)"
        let digest = SHA256.hash(data: Data(key.utf8))
        let bytes = Array(digest)
        return UUID(
            uuid: (
                bytes[0], bytes[1], bytes[2], bytes[3],
                bytes[4], bytes[5],
                bytes[6], bytes[7],
                bytes[8], bytes[9],
                bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
            )
        )
    }
}
