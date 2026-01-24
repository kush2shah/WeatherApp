//
//  LoadingStateView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Loading state with animated weather icon
struct LoadingStateView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            // Animated weather icon
            Image(systemName: "cloud.sun.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 60))
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)

            Text("Loading weather...")
                .font(.headline)
                .foregroundStyle(.primary)

            ProgressView()
                .tint(.primary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ZStack {
        GradientBackgroundView()
        LoadingStateView()
    }
}
