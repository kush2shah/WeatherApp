//
//  Location.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation
import CoreLocation

/// Represents a geographic location with coordinates and metadata
struct Location: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let coordinate: Coordinate
    let timezone: TimeZone
    let country: String?
    let administrativeArea: String? // State/Province
    let locality: String? // City

    init(
        id: UUID = UUID(),
        name: String,
        coordinate: Coordinate,
        timezone: TimeZone = .current,
        country: String? = nil,
        administrativeArea: String? = nil,
        locality: String? = nil
    ) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.timezone = timezone
        self.country = country
        self.administrativeArea = administrativeArea
        self.locality = locality
    }

    /// Create location from CLLocationCoordinate2D
    init(
        name: String,
        clCoordinate: CLLocationCoordinate2D,
        timezone: TimeZone = .current,
        country: String? = nil,
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
struct Coordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double

    /// Validate coordinate values
    var isValid: Bool {
        latitude >= -90 && latitude <= 90 &&
        longitude >= -180 && longitude <= 180
    }
}
