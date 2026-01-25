//
//  Color+Weather.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

extension Color {
    // MARK: - Weather-specific Colors

    static let weatherClear = Color(red: 0.4, green: 0.7, blue: 1.0)
    static let weatherCloudy = Color(red: 0.5, green: 0.5, blue: 0.6)
    static let weatherRainy = Color(red: 0.3, green: 0.4, blue: 0.6)
    static let weatherSnowy = Color(red: 0.8, green: 0.9, blue: 1.0)
    static let weatherStormy = Color(red: 0.3, green: 0.3, blue: 0.4)

    // MARK: - Gradient Helpers

    /// Gradient for weather background based on condition
    static func weatherGradient(for condition: WeatherCondition) -> [Color] {
        switch condition {
        case .clear:
            return [
                Color(red: 0.2, green: 0.6, blue: 0.9),
                Color(red: 0.4, green: 0.8, blue: 1.0)
            ]
        case .partlyCloudy:
            return [
                Color(red: 0.4, green: 0.6, blue: 0.8),
                Color(red: 0.6, green: 0.8, blue: 0.9)
            ]
        case .cloudy, .overcast:
            return [
                Color(red: 0.5, green: 0.55, blue: 0.6),
                Color(red: 0.6, green: 0.65, blue: 0.7)
            ]
        case .rain, .drizzle, .heavyRain, .freezingRain:
            return [
                Color(red: 0.25, green: 0.3, blue: 0.4),
                Color(red: 0.35, green: 0.4, blue: 0.5)
            ]
        case .thunderstorm, .tropical, .hurricane, .tornado:
            return [
                Color(red: 0.15, green: 0.15, blue: 0.25),
                Color(red: 0.25, green: 0.25, blue: 0.35)
            ]
        case .snow, .lightSnow, .heavySnow, .sleet:
            return [
                Color(red: 0.65, green: 0.75, blue: 0.85),
                Color(red: 0.85, green: 0.9, blue: 0.95)
            ]
        case .fog, .haze, .dust, .smoke:
            return [
                Color(red: 0.6, green: 0.6, blue: 0.65),
                Color(red: 0.7, green: 0.7, blue: 0.75)
            ]
        case .wind:
             return [
                 Color(red: 0.4, green: 0.7, blue: 0.7),
                 Color(red: 0.5, green: 0.8, blue: 0.8)
             ]
        case .unknown:
            return [
                Color(red: 0.4, green: 0.7, blue: 1.0),
                Color(red: 0.6, green: 0.85, blue: 1.0)
            ]
        }
    }

    // MARK: - Dark Mode Support

    static func adaptiveWeatherBackground(for condition: WeatherCondition, colorScheme: ColorScheme) -> [Color] {
        let baseGradient = weatherGradient(for: condition)

        if colorScheme == .dark {
            return baseGradient.map { color in
                Color(
                    red: color.components.red * 0.4,
                    green: color.components.green * 0.4,
                    blue: color.components.blue * 0.4
                )
            }
        }

        return baseGradient
    }
}

// MARK: - Color Components Helper

extension Color {
    var components: (red: Double, green: Double, blue: Double, opacity: Double) {
        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return (0, 0, 0, 0)
        }

        return (Double(r), Double(g), Double(b), Double(a))
    }
}
