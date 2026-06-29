
//
//  ComparisonChartView.swift
//  WeatherApp
//
//  Created by Kush Shah on 1/24/26.
//

import SwiftUI
import Charts

/// Per-source forecast chart: one line per weather source, colored with the
/// shared source palette so the chart matches the snapshot/detail cards. A
/// subtle neutral band behind the lines shows the spread across sources.
struct ComparisonChartView: View {
    let data: ComparisonData
    let metric: ComparisonMetric

    /// min/max spread band across all sources (drawn neutral, just for context)
    private var points: [UncertaintyPoint] {
        data.uncertaintyBands[metric] ?? []
    }

    private var seriesBySource: [WeatherSource: [DataPoint]] {
        data.series(for: metric)
    }

    /// Sources that actually have data for this metric, in a stable order.
    private var sourcesInOrder: [WeatherSource] {
        WeatherSource.allCases.filter { !(seriesBySource[$0]?.isEmpty ?? true) }
    }

    var body: some View {
        if sourcesInOrder.isEmpty {
            emptyState
        } else {
            chart
        }
    }

    private var chart: some View {
        Chart {
            // Neutral spread band behind the lines for context
            ForEach(points) { point in
                AreaMark(
                    x: .value("Time", point.timestamp),
                    yStart: .value("Min", point.min),
                    yEnd: .value("Max", point.max)
                )
                .foregroundStyle(.gray.opacity(0.12))
                .interpolationMethod(.catmullRom)
            }

            // One line per source, colored by the shared source palette
            ForEach(sourcesInOrder, id: \.self) { source in
                ForEach(seriesBySource[source] ?? []) { point in
                    LineMark(
                        x: .value("Time", point.timestamp),
                        y: .value(metric.rawValue, point.value),
                        series: .value("Source", source.shortName)
                    )
                    .foregroundStyle(source.color)
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
