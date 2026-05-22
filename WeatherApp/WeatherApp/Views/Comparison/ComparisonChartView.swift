
//
//  ComparisonChartView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI
import Charts

/// Per-source line chart showing what each weather service predicts over 24h.
struct ComparisonChartView: View {
    let data: ComparisonData
    let metric: ComparisonMetric

    private var sourcePoints: [(source: WeatherSource, points: [DataPoint])] {
        let dict: [WeatherSource: [DataPoint]]
        switch metric {
        case .temperature:   dict = data.temperatures
        case .precipitation: dict = data.precipitation
        case .wind:          dict = data.wind
        case .humidity:      dict = data.humidity
        }
        return dict
            .map { (source: $0.key, points: $0.value.sorted { $0.timestamp < $1.timestamp }) }
            .filter { !$0.points.isEmpty }
            .sorted { $0.source.displayName < $1.source.displayName }
    }

    var body: some View {
        if sourcePoints.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 10) {
                chart
                legend
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(sourcePoints, id: \.source) { entry in
                ForEach(entry.points) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value(metric.rawValue, point.value)
                    )
                    .foregroundStyle(entry.source.chartColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.primary.opacity(0.1))
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.primary.opacity(0.1))
                AxisValueLabel {
                    if let dbl = value.as(Double.self) {
                        Text("\(Int(dbl))\(metric.unit)")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartLegend(.hidden)
        .frame(height: 180)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            ForEach(sourcePoints, id: \.source) { entry in
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(entry.source.chartColor)
                        .frame(width: 16, height: 3)
                    Text(entry.source.shortName)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("Not enough data")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }
}

private extension WeatherSource {
    var chartColor: Color {
        switch self {
        case .weatherKit:     return .blue
        case .googleWeather:  return .red
        case .noaa:           return .green
        case .openWeatherMap: return .orange
        case .tomorrowIO:     return .purple
        }
    }
}
