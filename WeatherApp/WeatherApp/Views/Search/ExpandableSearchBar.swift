//
//  ExpandableSearchBar.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI
import SwiftData
import MapKit
import UIKit

/// Morphing search bar that expands into a full search overlay
struct ExpandableSearchBar: View {
    @Binding var isExpanded: Bool
    @State private var viewModel: SearchViewModel
    @State private var locationManager = LocationManager()
    @State private var resolvedCurrentLocation: Location?
    @State private var showLocationDeniedAlert = false
    @State private var pendingLocationSelection = false

    let modelContext: ModelContext
    let onLocationSelected: (Location) -> Void

    private let geocodingService = GeocodingService()

    init(
        isExpanded: Binding<Bool>,
        modelContext: ModelContext,
        onLocationSelected: @escaping (Location) -> Void
    ) {
        self._isExpanded = isExpanded
        self._viewModel = State(initialValue: SearchViewModel(modelContext: modelContext))
        self.modelContext = modelContext
        self.onLocationSelected = onLocationSelected
    }

    var body: some View {
        ZStack {
            if isExpanded {
                expandedOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                compactBar
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
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
    }

    // MARK: - Compact Bar

    private var compactBar: some View {
        Button {
            withAnimation {
                isExpanded = true
            }
            triggerHaptic()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Text("Search for a city...")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                Material.ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Expanded Overlay

    private var expandedOverlay: some View {
        VStack(spacing: 0) {
            // Search header
            VStack(spacing: 12) {
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.body)
                            .foregroundStyle(.secondary)

                        TextField("Search for a city...", text: Binding(
                            get: { viewModel.searchQuery },
                            set: { viewModel.updateSearchQuery($0) }
                        ))
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .rounded))
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            Task {
                                await handleDirectSearch()
                            }
                        }

                        if !viewModel.searchQuery.isEmpty {
                            Button {
                                viewModel.updateSearchQuery("")
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                    }

                    Button("Cancel") {
                        withAnimation {
                            isExpanded = false
                            viewModel.updateSearchQuery("")
                        }
                        triggerHaptic()
                    }
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal)

            // Search content
            ScrollView {
                LazyVStack(spacing: 0) {
                    if viewModel.searchQuery.isEmpty {
                        currentLocationOption
                        recentSearchesSection
                    } else {
                        searchResultsSection
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }

    // MARK: - Current Location Option

    private var currentLocationOption: some View {
        Button {
            handleCurrentLocationTap()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "location.fill")
                        .font(.body)
                        .foregroundStyle(.blue)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Location")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)

                    if locationManager.authorizationStatus == .denied ||
                       locationManager.authorizationStatus == .restricted {
                        Text("Location services not enabled")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.red)
                    } else if let location = resolvedCurrentLocation {
                        Text(location.name)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else if locationManager.isLoading {
                        Text("Locating...")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: resolvedCurrentLocation?.id)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Searches Section

    @ViewBuilder
    private var recentSearchesSection: some View {
        if !viewModel.recentSearches.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                Text("Recent")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                ForEach(viewModel.recentSearches.prefix(5)) { search in
                    Button {
                        handleLocationSelection(search.toDomain())
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .frame(width: 40)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(search.locationName)
                                    .font(.system(.body, design: .rounded))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Text(search.query)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    viewModel.clearHistory()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "trash")
                            .font(.body)
                            .foregroundStyle(.red)
                            .frame(width: 40)

                        Text("Clear History")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.red)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Search Results Section

    @ViewBuilder
    private var searchResultsSection: some View {
        if viewModel.isLoading {
            HStack {
                Spacer()
                ProgressView()
                    .padding()
                Spacer()
            }
        } else if viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
            Text("No results found")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
                .padding()
        } else {
            ForEach(viewModel.searchResults, id: \.self) { completion in
                Button {
                    Task {
                        await handleCompletionSelection(completion)
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .frame(width: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(completion.title)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.primary)
                                .lineLimit(1)

                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
        triggerHaptic()
        withAnimation {
            isExpanded = false
            viewModel.updateSearchQuery("")
        }
        onLocationSelected(location)
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
            await MainActor.run {
                pendingLocationSelection = false
            }
        }
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack {
            ExpandableSearchBar(
                isExpanded: .constant(false),
                modelContext: try! ModelContainer(for: SavedLocation.self).mainContext,
                onLocationSelected: { _ in }
            )
            .padding()

            Spacer()
        }
    }
}
