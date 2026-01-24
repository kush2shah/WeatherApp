//
//  SearchHistory.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation
import SwiftData

/// Recent location searches
@Model
final class SearchHistory {
    @Attribute(.unique) var id: UUID
    var query: String
    var locationName: String
    var latitude: Double
    var longitude: Double
    var searchedAt: Date

    init(
        id: UUID = UUID(),
        query: String,
        locationName: String,
        latitude: Double,
        longitude: Double,
        searchedAt: Date = Date()
    ) {
        self.id = id
        self.query = query
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.searchedAt = searchedAt
    }

    /// Convert to domain Location
    func toDomain() -> Location {
        Location(
            id: id,
            name: locationName,
            coordinate: Coordinate(latitude: latitude, longitude: longitude)
        )
    }

    /// Create from domain Location
    static func from(_ location: Location, query: String) -> SearchHistory {
        SearchHistory(
            query: query,
            locationName: location.name,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }
}
