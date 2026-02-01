//
//  LocationSearchView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI
import SwiftData
import MapKit
import UIKit

/// Location search view with autocomplete
struct LocationSearchView: View {
    @State private var viewModel: SearchViewModel
    @State private var locationManager = LocationManager()
    @State private var resolvedCurrentLocation: Location?
    @State private var showLocationDeniedAlert = false
    @State private var pendingLocationSelection = false
    @Environment(\.dismiss) private var dismiss
    let onLocationSelected: (Location) -> Void

    private let geocodingService = GeocodingService()

    init(
        modelContext: ModelContext,
        onLocationSelected: @escaping (Location) -> Void
    ) {
        self._viewModel = State(initialValue: SearchViewModel(modelContext: modelContext))
        self.onLocationSelected = onLocationSelected
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.searchQuery.isEmpty {
                    currentLocationSection
                    recentSearchesSection
                } else {
                    searchResultsSection
                }
            }
            .navigationTitle("Search Location")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: Binding(
                    get: { viewModel.searchQuery },
                    set: { viewModel.updateSearchQuery($0) }
                ),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "City, zip code, or coordinates"
            )
            .onSubmit(of: .search) {
                Task {
                    await handleDirectSearch()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Location Access Denied", isPresented: $showLocationDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enable location access in Settings to use your current location.")
            }
            .onAppear {
                if locationManager.isAuthorized {
                    locationManager.requestLocation()
                }
            }
            .onChange(of: locationManager.currentLocation) { _, newLocation in
                guard let clLocation = newLocation else { return }
                Task {
                    await resolveCurrentLocation(from: clLocation)
                }
            }
            .onChange(of: locationManager.authorizationStatus) { _, newStatus in
                switch newStatus {
                case .authorizedWhenInUse, .authorizedAlways:
                    locationManager.requestLocation()
                case .denied, .restricted:
                    if pendingLocationSelection {
                        pendingLocationSelection = false
                        showLocationDeniedAlert = true
                    }
                default:
                    break
                }
            }
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var currentLocationSection: some View {
        Section {
            Button {
                handleCurrentLocationTap()
            } label: {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.blue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Location")
                            .foregroundStyle(.primary)

                        if locationManager.authorizationStatus == .denied ||
                           locationManager.authorizationStatus == .restricted {
                            Text("Location services not enabled")
                                .font(.caption)
                                .foregroundStyle(.red)
                        } else if let location = resolvedCurrentLocation {
                            Text(location.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: resolvedCurrentLocation?.id)

                    Spacer()
                }
            }
        }
    }

    @ViewBuilder
    private var recentSearchesSection: some View {
        if !viewModel.recentSearches.isEmpty {
            Section {
                ForEach(viewModel.recentSearches) { search in
                    Button {
                        handleLocationSelection(search.toDomain())
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading) {
                                Text(search.locationName)
                                    .foregroundStyle(.primary)
                                Text(search.query)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Recent Searches")
            }

            Section {
                Button(role: .destructive) {
                    viewModel.clearHistory()
                } label: {
                    Label("Clear History", systemImage: "trash")
                }
            }
        }
    }

    @ViewBuilder
    private var searchResultsSection: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if viewModel.searchResults.isEmpty {
            Text("No results found")
                .foregroundStyle(.secondary)
        } else {
            Section {
                ForEach(viewModel.searchResults, id: \.self) { completion in
                    Button {
                        Task {
                            await handleCompletionSelection(completion)
                        }
                    } label: {
                        SearchResultRow(completion: completion)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func handleCompletionSelection(_ completion: MKLocalSearchCompletion) async {
        viewModel.isLoading = true
        defer { viewModel.isLoading = false }

        do {
            let location = try await viewModel.geocodeCompletion(completion)
            handleLocationSelection(location)
        } catch {
            viewModel.error = error
        }
    }

    private func handleDirectSearch() async {
        guard !viewModel.searchQuery.isEmpty else { return }

        viewModel.isLoading = true
        defer { viewModel.isLoading = false }

        do {
            let location = try await viewModel.geocodeAddress(viewModel.searchQuery)
            handleLocationSelection(location)
        } catch {
            viewModel.error = error
        }
    }

    private func handleLocationSelection(_ location: Location) {
        onLocationSelected(location)
        dismiss()
    }

    private func handleCurrentLocationTap() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            pendingLocationSelection = true
            locationManager.requestPermission()
        case .denied, .restricted:
            showLocationDeniedAlert = true
        case .authorizedWhenInUse, .authorizedAlways:
            if let location = resolvedCurrentLocation {
                handleLocationSelection(location)
            } else {
                pendingLocationSelection = true
                locationManager.requestLocation()
            }
        @unknown default:
            break
        }
    }

    private func resolveCurrentLocation(from clLocation: CLLocation) async {
        let coordinate = Coordinate(
            latitude: clLocation.coordinate.latitude,
            longitude: clLocation.coordinate.longitude
        )
        do {
            let location = try await geocodingService.reverseGeocode(coordinate: coordinate)
            await MainActor.run {
                withAnimation {
                    resolvedCurrentLocation = location
                }
                if pendingLocationSelection {
                    pendingLocationSelection = false
                    handleLocationSelection(location)
                }
            }
        } catch {
            // Silently fail - user can still tap to retry
            await MainActor.run {
                pendingLocationSelection = false
            }
        }
    }
}
