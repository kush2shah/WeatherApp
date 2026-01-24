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
        ZStack {
            // Gradient background
            GradientBackgroundView()

            // Content
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
                                onRefresh: {
                                    await viewModel.refresh()
                                }
                            )
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
