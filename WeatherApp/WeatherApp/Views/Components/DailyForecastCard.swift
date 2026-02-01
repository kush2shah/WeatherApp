//
//  DailyForecastCard.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI

/// Daily forecast card with list of days
struct DailyForecastCard: View {
    let forecasts: [DailyForecast]
    let weatherData: WeatherData
    @State private var selectedForecast: DailyForecast?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("\(min(10, forecasts.count))-Day Forecast", systemImage: "calendar")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)

            VStack(spacing: 0) {
                let minTemp = forecasts.map { $0.lowTemperature }.min() ?? 0
                let maxTemp = forecasts.map { $0.highTemperature }.max() ?? 100
                
                ForEach(Array(forecasts.prefix(10).enumerated()), id: \.element.id) { index, forecast in
                    Button {
                        selectedForecast = forecast
                    } label: {
                        DailyForecastRow(
                            forecast: forecast,
                            minTemp: minTemp,
                            maxTemp: maxTemp
                        )
                    }
                    .buttonStyle(.plain)

                    if index < min(9, forecasts.count - 1) {
                        Divider()
                            .padding(.leading, 24)
                            .opacity(0.3)
                    }
                }
            }
        }
        .padding(.vertical, 20)
        .background(
            Material.ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .padding(.horizontal)
        .sheet(item: $selectedForecast) { forecast in
            DailyDetailView(forecast: forecast, weatherData: weatherData)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

/// Individual daily forecast row
struct DailyForecastRow: View {
    let forecast: DailyForecast
    let minTemp: Double
    let maxTemp: Double

    var body: some View {
        HStack {
            // Day
            Text(dayName)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(.primary)
                .frame(width: 60, alignment: .leading)

            // Icon
            VStack {
                WeatherIconView(condition: forecast.condition, size: 24)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                if forecast.precipitationPercentage > 20 {
                    Text("\(forecast.precipitationPercentage)%")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.blue)
                }
            }
            .frame(width: 40)

            Spacer()
            
            // Low Temp
            Text(verbatim: forecast.lowTemperature.temperatureString(unit: .fahrenheit))
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)

            // Bar
            TemperatureBar(
                low: forecast.lowTemperature,
                high: forecast.highTemperature,
                minRange: minTemp,
                maxRange: maxTemp
            )
            .frame(height: 5)
            .frame(maxWidth: 100)

            // High Temp
            Text(verbatim: forecast.highTemperature.temperatureString(unit: .fahrenheit))
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(.primary)
                .frame(width: 40, alignment: .leading)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    private var dayName: String {
        if Calendar.current.isDateInToday(forecast.date) {
            return "Today"
        }
        return forecast.shortDayName
    }
}

struct TemperatureBar: View {
    let low: Double
    let high: Double
    let minRange: Double
    let maxRange: Double
    
    var body: some View {
        GeometryReader {
            geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.1))
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width(in: geo.size.width), height: geo.size.height)
                    .offset(x: offset(in: geo.size.width))
            }
        }
    }
    
    func width(in totalWidth: CGFloat) -> CGFloat {
        let range = high - low
        let totalRange = max(maxRange - minRange, 1) // Prevent division by zero
        return totalWidth * CGFloat(range / totalRange)
    }
    
    func offset(in totalWidth: CGFloat) -> CGFloat {
        let offset = low - minRange
        let totalRange = max(maxRange - minRange, 1) // Prevent division by zero
        return totalWidth * CGFloat(offset / totalRange)
    }
}

#Preview {
    ZStack {
        Color.gray
        DailyForecastCard(
            forecasts: (0..<5).map { _ in
                DailyForecast(
                    date: Date(),
                    highTemperature: 75,
                    lowTemperature: 60,
                    condition: .partlyCloudy,
                    conditionDescription: "Partly Cloudy",
                    precipitationChance: 0.1
                )
            },
            weatherData: WeatherData(
                location: Location(name: "Preview", coordinate: Coordinate(latitude: 0, longitude: 0)),
                sources: [:]
            )
        )
    }
}