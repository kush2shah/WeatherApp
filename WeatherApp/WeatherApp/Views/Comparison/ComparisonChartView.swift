//
//  ComparisonChartView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI
import Charts

/// Overlaid line chart comparing multiple weather sources
struct ComparisonChartView: View {
    let data: ComparisonData
    let metric: ComparisonMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(metric.rawValue)
                .font(.headline)
                .foregroundStyle(.primary)

            Chart {
                ForEach(Array(chartData.keys.sorted(by: { $0.rawValue < $1.rawValue })), id: \.self) { source in
                    ForEach(chartData[source] ?? []) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value(metric.rawValue, point.value)
                        )
                        .foregroundStyle(by: .value("Source", source.shortName))
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        // Add point markers for clarity
                        PointMark(
                            x: .value("Time", point.timestamp),
                            y: .value(metric.rawValue, point.value)
                        )
                        .foregroundStyle(by: .value("Source", source.shortName))
                        .symbol(by: .value("Source", source.shortName))
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.hour())
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYAxisLabel(metric.unit, position: .trailing)
            .chartLegend(position: .bottom, spacing: 12)
            .frame(height: 300)
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    /// Get chart data based on selected metric
    private var chartData: [WeatherSource: [DataPoint]] {
        switch metric {
        case .temperature:
            return data.temperatures
        case .precipitation:
            return data.precipitation
        case .wind:
            return data.wind
        case .humidity:
            return data.humidity
        }
    }
}
