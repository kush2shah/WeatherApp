//
//  SearchViewModel.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import Foundation
import MapKit
import SwiftData
import Observation

/// ViewModel for location search
@MainActor
@Observable
final class SearchViewModel: NSObject {
    var searchQuery = ""
    var searchResults: [MKLocalSearchCompletion] = []
    var recentSearches: [SearchHistory] = []
    var isLoading = false
    var error: Error?

    private let completer = MKLocalSearchCompleter()
    private let geocodingService: GeocodingService
    private let modelContext: ModelContext

    init(
        geocodingService: GeocodingService = GeocodingService(),
        modelContext: ModelContext
    ) {
        self.geocodingService = geocodingService
        self.modelContext = modelContext
        super.init()

        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
        loadRecentSearches()
    }

    /// Update search query
    func updateSearchQuery(_ query: String) {
        searchQuery = query
        if query.isEmpty {
            searchResults = []
        } else {
            completer.queryFragment = query
        }
    }

    /// Load recent searches from SwiftData
    func loadRecentSearches() {
        let descriptor = FetchDescriptor<SearchHistory>(
            sortBy: [SortDescriptor(\.searchedAt, order: .reverse)]
        )

        do {
            recentSearches = try modelContext.fetch(descriptor).prefix(10).map { $0 }
        } catch {
            print("Failed to load recent searches: \(error)")
        }
    }

    /// Geocode a search completion
    func geocodeCompletion(_ completion: MKLocalSearchCompletion) async throws -> Location {
        // Create search request from completion
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()

            guard let mapItem = response.mapItems.first else {
                throw GeocodingError.noResults
            }

            let location = locationFromMapItem(mapItem)

            // Save to search history
            saveToHistory(location: location, query: completion.title)

            return location
        } catch {
            throw GeocodingError.networkError(error)
        }
    }

    /// Geocode a direct address string (for manual input)
    func geocodeAddress(_ address: String) async throws -> Location {
        let location = try await geocodingService.geocode(address: address)
        saveToHistory(location: location, query: address)
        return location
    }

    /// Save location to search history
    private func saveToHistory(location: Location, query: String) {
        let history = SearchHistory.from(location, query: query)
        modelContext.insert(history)
        try? modelContext.save()
        loadRecentSearches()
    }

    /// Clear search history
    func clearHistory() {
        for history in recentSearches {
            modelContext.delete(history)
        }
        try? modelContext.save()
        loadRecentSearches()
    }

    // MARK: - Private Helpers

    /// Create Location from MKMapItem
    private func locationFromMapItem(_ mapItem: MKMapItem) -> Location {
        let placemark = mapItem.placemark
        let name = mapItem.name ?? [
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ]
        .compactMap { $0 }
        .joined(separator: ", ")

        return Location(
            name: name,
            coordinate: Coordinate(
                latitude: placemark.coordinate.latitude,
                longitude: placemark.coordinate.longitude
            ),
            timezone: placemark.timeZone ?? .current,
            country: placemark.country,
            administrativeArea: placemark.administrativeArea,
            locality: placemark.locality
        )
    }
}

// MARK: - MKLocalSearchCompleterDelegate

extension SearchViewModel: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        self.error = error
        searchResults = []
    }
}
