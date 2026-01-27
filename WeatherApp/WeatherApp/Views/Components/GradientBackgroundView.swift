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
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.scenePhase) var scenePhase

    @State private var animationPhase: CGFloat = 0
    @State private var startPoint = UnitPoint.topLeading
    @State private var endPoint = UnitPoint.bottomTrailing
    @State private var isAnimating = false

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
            .blur(radius: effectiveBlurRadius)
            .animation(gradientTransitionAnimation, value: condition)
        }
        .onAppear {
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onChange(of: reduceMotion) { _, newValue in
            if newValue {
                stopAnimation()
            } else if scenePhase == .active {
                startAnimation()
            }
        }
    }

    // MARK: - Computed Properties

    private var gradientColors: [Color] {
        Color.adaptiveWeatherBackground(for: condition, colorScheme: colorScheme)
    }

    /// Blur radius adjusted for performance during animations
    private var effectiveBlurRadius: CGFloat {
        if reduceMotion {
            return 0 // No blur when reduce motion is enabled
        }
        return isAnimating ? 10 : 20 // Reduce blur during animations for performance
    }

    /// Animation for gradient transitions when condition changes
    private var gradientTransitionAnimation: Animation? {
        reduceMotion ? .easeInOut(duration: 0.3) : .easeInOut(duration: 1.0)
    }

    /// Animation for continuous gradient movement
    private var continuousAnimation: Animation? {
        guard !reduceMotion else { return nil }
        return .linear(duration: 15).repeatForever(autoreverses: true)
    }

    // MARK: - Animation Lifecycle

    /// Start the continuous animation
    private func startAnimation() {
        guard !reduceMotion, !isAnimating else { return }

        isAnimating = true
        withAnimation(continuousAnimation) {
            animationPhase = 10
            startPoint = .top
            endPoint = .bottom
        }
    }

    /// Stop the continuous animation
    private func stopAnimation() {
        guard isAnimating else { return }

        isAnimating = false
        withAnimation(.easeOut(duration: 0.3)) {
            animationPhase = 0
            startPoint = .topLeading
            endPoint = .bottomTrailing
        }
    }

    /// Handle scene phase changes (background/foreground)
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            startAnimation()
        case .inactive, .background:
            stopAnimation()
        @unknown default:
            break
        }
    }
}

#Preview {
    GradientBackgroundView(condition: .clear)
}