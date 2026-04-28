//
//  WeatherAppApp.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI
import SwiftData

@main
struct WeatherAppApp: App {
    private let modelContainer: ModelContainer?

    init() {
        let schema = Schema([
            SavedLocation.self,
            CachedWeather.self,
            SearchHistory.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        modelContainer = try? ModelContainer(for: schema, configurations: [modelConfiguration])
    }

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                ContentView()
                    .modelContainer(container)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("Unable to Load App Data")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("There was a problem loading saved data. Try restarting the app. If the problem persists, reinstall WeatherApp.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding()
            }
        }
    }
}
