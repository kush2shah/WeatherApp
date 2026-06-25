//
//  SettingsView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/26/26.
//

import SwiftUI

/// User settings view for unit preferences
struct SettingsView: View {
    @ObservedObject private var preferences = UserPreferences.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Temperature Section
                Section {
                    Picker("Unit", selection: $preferences.temperatureUnit) {
                        ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label("Temperature", systemImage: "thermometer.medium")
                } footer: {
                    Text("Display temperatures in \(preferences.temperatureUnit.displayName)")
                }

                // Wind Speed Section
                Section {
                    Picker("Unit", selection: $preferences.windSpeedUnit) {
                        ForEach(WindSpeedUnit.allCases, id: \.self) { unit in
                            Text(unit.symbol).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label("Wind Speed", systemImage: "wind")
                } footer: {
                    Text("Display wind speed in \(preferences.windSpeedUnit.displayName)")
                }

                // Pressure Section
                Section {
                    Picker("Unit", selection: $preferences.pressureUnit) {
                        ForEach(PressureUnit.allCases, id: \.self) { unit in
                            Text(unit.symbol).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label("Pressure", systemImage: "gauge.medium")
                } footer: {
                    Text("Display atmospheric pressure in \(preferences.pressureUnit.displayName)")
                }

                // Visibility Section
                Section {
                    Picker("Unit", selection: $preferences.visibilityUnit) {
                        ForEach(VisibilityUnit.allCases, id: \.self) { unit in
                            Text(unit.symbol).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Label("Visibility", systemImage: "eye")
                } footer: {
                    Text("Display visibility distance in \(preferences.visibilityUnit.displayName)")
                }

                // About Section
                Section {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: WeatherAttribution.appleLegalURL) {
                        HStack {
                            Label {
                                Text("Weather Data Sources")
                            } icon: {
                                Image(systemName: "apple.logo")
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.footnote)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .tint(.primary)
                } header: {
                    Label("About", systemImage: "info.circle")
                } footer: {
                    Text("Weather data is provided by Apple Weather and additional sources. Tap above to view the full list of data providers.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
