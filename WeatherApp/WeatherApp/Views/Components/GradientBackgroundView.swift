//
//  GradientBackgroundView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Animated gradient background that adapts to color scheme
struct GradientBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var animationPhase: CGFloat = 0

    var body: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .hueRotation(.degrees(animationPhase))
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: true)) {
                animationPhase = 30
            }
        }
    }

    private var gradientColors: [Color] {
        colorScheme == .dark
            ? [
                Color(red: 0.1, green: 0.1, blue: 0.2),
                Color(red: 0.2, green: 0.1, blue: 0.3)
            ]
            : [
                Color(red: 0.4, green: 0.7, blue: 1.0),
                Color(red: 0.6, green: 0.85, blue: 1.0)
            ]
    }
}

#Preview {
    GradientBackgroundView()
}
