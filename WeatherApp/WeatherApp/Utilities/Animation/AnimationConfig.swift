//
//  AnimationConfig.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/26/26.
//

import SwiftUI

/// Centralized animation configuration with accessibility support
struct AnimationConfig {
    /// Environment value for accessibility reduce motion
    var reduceMotion: Bool

    /// Standard animation for UI transitions
    var standard: Animation {
        reduceMotion ? .easeInOut(duration: 0.1) : .easeInOut(duration: 0.35)
    }

    /// Spring animation for interactive elements
    var spring: Animation {
        reduceMotion ? .easeInOut(duration: 0.1) : .spring(response: 0.5, dampingFraction: 0.7)
    }

    /// Gradient animation configuration
    var gradient: Animation? {
        reduceMotion ? nil : .linear(duration: 15).repeatForever(autoreverses: true)
    }

    /// Gradient transition animation
    var gradientTransition: Animation {
        reduceMotion ? .easeInOut(duration: 0.3) : .easeInOut(duration: 1.0)
    }

    /// Duration for standard animations
    var standardDuration: TimeInterval {
        reduceMotion ? 0.1 : 0.35
    }

    /// Duration for gradient animations
    var gradientDuration: TimeInterval {
        reduceMotion ? 0 : 15
    }

    /// Hue rotation amount for gradient animation
    var hueRotationAmount: Double {
        reduceMotion ? 0 : 10
    }

    /// Initialize with environment reduce motion setting
    init(reduceMotion: Bool = false) {
        self.reduceMotion = reduceMotion
    }
}

/// Environment key for animation configuration
struct AnimationConfigKey: EnvironmentKey {
    static let defaultValue = AnimationConfig()
}

extension EnvironmentValues {
    var animationConfig: AnimationConfig {
        get { self[AnimationConfigKey.self] }
        set { self[AnimationConfigKey.self] = newValue }
    }
}
