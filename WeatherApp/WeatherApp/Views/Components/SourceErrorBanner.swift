//
//  SourceErrorBanner.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/30/26.
//

import SwiftUI

/// Banner showing failed sources and their errors
struct SourceErrorBanner: View {
    let sourceErrors: [WeatherSource: String]
    let onRefresh: (WeatherSource) -> Void

    var body: some View {
        if !sourceErrors.isEmpty {
            VStack(spacing: 8) {
                ForEach(Array(sourceErrors.keys).sorted(by: { $0.rawValue < $1.rawValue }), id: \.self) { source in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.system(size: 16))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(source.shortName)
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(.primary)

                            Text(sourceErrors[source] ?? "Unknown error")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Button {
                            onRefresh(source)
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.orange.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
    }
}
