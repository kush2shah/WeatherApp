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
        ScrollView(.horizontal, showsIndicators: false) {
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
                    AxisValueLabel(format: .dateTime.hour(), centered: false)
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
            .frame(width: max(350, CGFloat(maxDataPoints) * 35), height: 250) // More compact height
            .padding(.vertical, 8)
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

    /// Calculate the maximum number of data points for sizing the chart
    private var maxDataPoints: Int {
        chartData.values.map { $0.count }.max() ?? 0
    }
}