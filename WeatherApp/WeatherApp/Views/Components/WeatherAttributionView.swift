//
//  WeatherAttributionView.swift
//  WeatherApp
//
//  Created by Kush Shah on 6/24/26.
//

import SwiftUI

/// Apple's required legal attribution page listing the other data sources that
/// contribute to Apple Weather. Per App Store Review Guideline 5.2.5 and the
/// WeatherKit attribution requirements, apps that display Apple Weather data
/// must show the Apple Weather trademark and link to this page.
enum WeatherAttribution {
    static let appleLegalURL = URL(string: "https://weatherkit.apple.com/legal-attribution.html")!
}

/// Inline attribution for a single weather source.
///
/// For Apple Weather (WeatherKit) this renders the required Apple Weather
/// trademark ( Weather) as a tappable link to Apple's legal attribution page.
/// For all other sources it renders the source's plain attribution text.
struct WeatherAttributionView: View {
    let source: WeatherSource

    var body: some View {
        if source == .weatherKit {
            HStack(spacing: 4) {
                // Apple Weather trademark (brandmark only — not a link)
                HStack(spacing: 3) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 10))
                    Text("Weather")
                }
                .foregroundStyle(.secondary)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Apple Weather")

                Text("·")
                    .foregroundStyle(.tertiary)

                // Legal attribution link
                Link("Legal", destination: WeatherAttribution.appleLegalURL)
                    .foregroundStyle(.tint)
                    .accessibilityHint("Opens Apple's legal attribution page")
            }
            .font(.system(.caption2, design: .rounded))
        } else {
            Text(source.defaultAttribution)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.tertiary)
        }
    }
}

/// Centered Apple Weather attribution footer for screens whose primary data
/// comes from Apple Weather (the launch screen, daily detail). Displays the
/// Apple Weather trademark and a tappable link to Apple's legal attribution page.
struct AppleWeatherAttributionFooter: View {
    var body: some View {
        HStack(spacing: 5) {
            // Apple Weather trademark (brandmark only — not a link)
            HStack(spacing: 4) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 11))
                Text("Weather")
                    .fontWeight(.medium)
            }
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Apple Weather")

            Text("·")
                .foregroundStyle(.tertiary)

            // Legal attribution link
            Link("Legal", destination: WeatherAttribution.appleLegalURL)
                .foregroundStyle(.tint)
                .accessibilityHint("Opens Apple's legal attribution page")
        }
        .font(.system(.caption, design: .rounded))
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    VStack(spacing: 24) {
        WeatherAttributionView(source: .weatherKit)
        WeatherAttributionView(source: .noaa)
        AppleWeatherAttributionFooter()
    }
    .padding()
}
