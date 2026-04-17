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
    @State private var isShowingWeather = false

    var body: some View {
        NavigationStack {
            LaunchView { location in
                Task {
                    await handleLocationSelection(location)
                }
            }
            .navigationDestination(isPresented: $isShowingWeather) {
                weatherDestinationView
                    .toolbar {
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
        .onChange(of: isShowingWeather) { _, showing in
            if !showing {
                // User navigated back — reset weather state
                viewModel?.weatherData = nil
                viewModel?.selectedSource = nil
                viewModel?.error = nil
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
    private var weatherDestinationView: some View {
        if let viewModel = viewModel, let weatherData = viewModel.weatherData,
           let selectedSource = viewModel.selectedSource {
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
        } else if let error = viewModel?.error {
            errorView(error: error)
        } else {
            loadingView
        }
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

            Spacer()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()

            ProgressView()
                .controlSize(.large)

            Text("Loading weather...")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    // MARK: - Actions

    private func handleLocationSelection(_ location: Location) async {
        isShowingWeather = true
        await viewModel?.fetchWeather(for: location)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SavedLocation.self, CachedWeather.self, SearchHistory.self], inMemory: true)
}
