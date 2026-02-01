//
//  ContentView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WeatherViewModel?
    @State private var showSearch = false

    var body: some View {
        NavigationStack {
                Group {
                    if let viewModel = viewModel, let weatherData = viewModel.weatherData {
                        if let selectedSource = viewModel.selectedSource {
                            WeatherMainView(
                                weatherData: weatherData,
                                selectedSource: Binding(
                                    get: { selectedSource },
                                    set: { viewModel.selectedSource = $0 }
                                ),
                                onRefreshSource: { source in
                                    await viewModel.refreshSource(source)
                                }
                            )
                        }
                    } else if let error = viewModel?.error {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.yellow)

                            Text("Something went wrong")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.primary)

                            Text(error.localizedDescription)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)

                            Button {
                                Task {
                                    await viewModel?.refresh()
                                }
                            } label: {
                                Label("Try Again", systemImage: "arrow.clockwise")
                                    .font(.headline)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .foregroundStyle(.primary)
                        }
                    } else if viewModel?.isLoading == true {
                        ProgressView("Loading weather...")
                            .tint(.primary)
                            .foregroundStyle(.primary)
                    } else {
                        // Show search prompt
                        VStack(spacing: 20) {
                            Image(systemName: "cloud.sun.fill")
                                .symbolRenderingMode(.multicolor)
                                .font(.system(size: 80))
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)

                            Text("Welcome to WeatherApp")
                                .font(.title)
                                .fontWeight(.bold)

                            Text("Search for a location to get started")
                                .foregroundStyle(.secondary)

                            Button {
                                showSearch = true
                            } label: {
                                Label("Search Location", systemImage: "magnifyingglass")
                                    .font(.headline)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if viewModel?.weatherData != nil {
                            Button {
                                showSearch = true
                            } label: {
                                Label("Search", systemImage: "magnifyingglass")
                            }
                            .foregroundStyle(.primary)
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        if viewModel?.weatherData != nil {
                            Button {
                                Task {
                                    await viewModel?.refresh()
                                }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            .foregroundStyle(.primary)
                            .disabled(viewModel?.isLoading == true)
                        }
                    }
                }
                .sheet(isPresented: $showSearch) {
                    LocationSearchView(modelContext: modelContext) { location in
                        Task {
                            await handleLocationSelection(location)
                        }
                    }
                }
            }
        .onAppear {
            if viewModel == nil {
                viewModel = WeatherViewModel(modelContext: modelContext)
            }
        }
    }

    private func handleLocationSelection(_ location: Location) async {
        await viewModel?.fetchWeather(for: location)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: SavedLocation.self, inMemory: true)
}
