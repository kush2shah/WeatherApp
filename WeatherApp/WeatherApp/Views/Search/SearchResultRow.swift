//
//  SearchResultRow.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI
import MapKit

/// Search result row displaying location completion
struct SearchResultRow: View {
    let completion: MKLocalSearchCompletion

    var body: some View {
        HStack {
            Image(systemName: "mappin.circle.fill")
                .foregroundStyle(.blue)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(completion.title)
                    .foregroundStyle(.primary)

                if !completion.subtitle.isEmpty {
                    Text(completion.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }
}
