//
//  SavedLocation.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation
import SwiftData

/// User's saved locations for quick access
@Model
final class SavedLocation {
    @Attribute(.unique) var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var country: String?
    var administrativeArea: String?
    var locality: String?
    var isCurrentLocation: Bool
    var order: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        country: String? = nil,
        administrativeArea: String? = nil,
        locality: String? = nil,
        isCurrentLocation: Bool = false,
        order: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.country = country
        self.administrativeArea = administrativeArea
        self.locality = locality
        self.isCurrentLocation = isCurrentLocation
        self.order = order
        self.createdAt = createdAt
    }

    /// Convert to domain Location
    func toDomain() -> Location {
        Location(
            id: id,
            name: name,
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            country: country,
            administrativeArea: administrativeArea,
            locality: locality
        )
    }

    /// Create from domain Location
    static func from(_ location: Location, order: Int = 0) -> SavedLocation {
        SavedLocation(
            id: location.id,
            name: location.name,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            country: location.country,
            administrativeArea: location.administrativeArea,
            locality: location.locality,
            order: order
        )
    }
}
