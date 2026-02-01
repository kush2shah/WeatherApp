//
//  WeatherIconView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Weather icon with SF Symbols
struct WeatherIconView: View {
    let condition: WeatherCondition
    let size: CGFloat
    var isNight: Bool = false

    var body: some View {
        Image(systemName: symbolName)
            .symbolRenderingMode(.multicolor)
            .font(.system(size: size))
    }

    private var symbolName: String {
        guard isNight else { return condition.sfSymbolName }

        // Night variants for conditions that change appearance
        switch condition {
        case .clear:
            return "moon.stars.fill"
        case .partlyCloudy:
            return "cloud.moon.fill"
        case .haze:
            return "moon.haze.fill"
        default:
            return condition.sfSymbolName
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        WeatherIconView(condition: .clear, size: 60)
        WeatherIconView(condition: .rain, size: 60)
        WeatherIconView(condition: .snow, size: 60)
        WeatherIconView(condition: .thunderstorm, size: 60)
    }
    .padding()
}
