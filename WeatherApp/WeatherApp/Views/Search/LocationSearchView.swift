//
//  LocationSearchView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI
import SwiftData
import MapKit

/// Location search view with autocomplete
struct LocationSearchView: View {
    @State private var viewModel: SearchViewModel
    @Environment(\.dismiss) private var dismiss
    let onLocationSelected: (Location) -> Void

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
        }
    }

    // MARK: - Subviews

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
}
