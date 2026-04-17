
//
//  ComparisonChartView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI
import Charts

/// Uncertainty band chart: shaded min-max area + bold consensus line.
/// Replaces the spaghetti multi-line chart with a cleaner visualization
/// that emphasizes WHERE sources disagree, not who says what.
struct ComparisonChartView: View {
    let data: ComparisonData
    let metric: ComparisonMetric

    private var points: [UncertaintyPoint] {
        data.uncertaintyBands[metric] ?? []
    }

    private var bandColor: Color {
        switch metric {
        case .temperature:   return .orange
        case .precipitation: return .blue
        case .wind:          return .teal
        case .humidity:      return .indigo
        }
    }

    var body: some View {
        if points.isEmpty {
            emptyState
        } else {
            chart
        }
    }

    private var chart: some View {
        Chart {
            // Shaded band: full spread across all sources
            ForEach(points) { point in
                AreaMark(
                    x: .value("Time", point.timestamp),
                    yStart: .value("Min", point.min),
                    yEnd: .value("Max", point.max)
                )
                .foregroundStyle(bandColor.opacity(0.18))
                .interpolationMethod(.catmullRom)
            }

            // Dashed lower bound
            ForEach(points) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Min", point.min)
                )
                .foregroundStyle(bandColor.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .interpolationMethod(.catmullRom)
            }

            // Dashed upper bound
            ForEach(points) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Max", point.max)
                )
                .foregroundStyle(bandColor.opacity(0.4))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .interpolationMethod(.catmullRom)
            }

            // Bold consensus line (mean of all sources)
            ForEach(points) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Consensus", point.mean)
                )
                .foregroundStyle(bandColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
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
        .frame(height: 200)
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
        .frame(height: 200)
    }
}
