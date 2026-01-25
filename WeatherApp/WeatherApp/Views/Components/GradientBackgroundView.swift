//
//  GradientBackgroundView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Animated gradient background that adapts to weather condition and color scheme
struct GradientBackgroundView: View {
    let condition: WeatherCondition
    @Environment(\.colorScheme) var colorScheme
    @State private var animationPhase: CGFloat = 0
    @State private var startPoint = UnitPoint.topLeading
    @State private var endPoint = UnitPoint.bottomTrailing

    var body: some View {
        ZStack {
            // Base layer to prevent flicker during transitions
            Color(gradientColors.first ?? .blue)
                .ignoresSafeArea()

            LinearGradient(
                colors: gradientColors,
                startPoint: startPoint,
                endPoint: endPoint
            )
            .hueRotation(.degrees(animationPhase))
            .ignoresSafeArea()
            .blur(radius: 20) // Soften the gradient
            .animation(.easeInOut(duration: 1.0), value: condition)
            .onAppear {
                withAnimation(.linear(duration: 15).repeatForever(autoreverses: true)) {
                    animationPhase = 10
                    startPoint = .top
                    endPoint = .bottom
                }
            }
        }
    }

    private var gradientColors: [Color] {
        Color.adaptiveWeatherBackground(for: condition, colorScheme: colorScheme)
    }
}

#Preview {
    GradientBackgroundView(condition: .clear)
}