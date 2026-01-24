//
//  WeatherIconView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Weather icon with SF Symbols and animations
struct WeatherIconView: View {
    let condition: WeatherCondition
    let size: CGFloat

    var body: some View {
        Image(systemName: condition.sfSymbolName)
            .symbolRenderingMode(.multicolor)
            .font(.system(size: size))
            .symbolEffect(.bounce, value: condition)
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
