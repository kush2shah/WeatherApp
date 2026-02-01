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
    @State private var selectedLocation: Location?
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let viewModel = viewModel, let weatherData = viewModel.weatherData {
                    if let selectedSource = viewModel.selectedSource {
                        weatherDetailView(weatherData: weatherData, selectedSource: selectedSource)
                    }
                } else if let error = viewModel?.error {
                    errorView(error: error)
                } else if viewModel?.isLoading == true {
                    loadingView
                } else {
                    // Show launch view with saved locations
                    LaunchView { location in
                        Task {
                            await handleLocationSelection(location)
                        }
                    }
                }
            }
            .toolbar {
                if viewModel?.weatherData != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            // Return to launch view
                            viewModel?.weatherData = nil
                            viewModel?.selectedSource = nil
                        } label: {
                            Label("Back", systemImage: "chevron.left")
                        }
                        .foregroundStyle(.primary)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            Button {
                                showSearch = true
                            } label: {
                                Label("Search", systemImage: "magnifyingglass")
                            }
                            .foregroundStyle(.primary)

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

    // MARK: - Subviews

    @ViewBuilder
    private func weatherDetailView(weatherData: WeatherData, selectedSource: WeatherSource) -> some View {
        WeatherMainView(
            weatherData: weatherData,
            selectedSource: Binding(
                get: { selectedSource },
                set: { viewModel?.selectedSource = $0 }
            ),
            onRefreshSource: { source in
                await viewModel?.refreshSource(source)
            }
        )
    }

    @ViewBuilder
    private func errorView(error: Error) -> some View {
        VStack(spacing: 20) {
            Spacer()

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

            HStack(spacing: 16) {
                Button {
                    viewModel?.error = nil
                    viewModel?.weatherData = nil
                } label: {
                    Label("Go Back", systemImage: "chevron.left")
                        .font(.headline)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .foregroundStyle(.primary)

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

            Spacer()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)

            Text("Loading weather...")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    // MARK: - Actions

    private func handleLocationSelection(_ location: Location) async {
        await viewModel?.fetchWeather(for: location)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SavedLocation.self, CachedWeather.self, SearchHistory.self], inMemory: true)
}
